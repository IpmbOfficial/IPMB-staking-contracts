// SPDX-License-Identifier: MIT

/**
 *
 *  @title: IPMB Staking Pools
 *  @date: 25-September-2024
 *  @version: 1.9
 *  @author: IPMB Dev Team
 */

import "./IERC20.sol";
import "./Ownable.sol";
import "./IPriceFeed.sol";

pragma solidity ^0.8.19;

contract IPMBStaking is Ownable {

    // pool structure

    struct poolStr {
        uint256 poolID;
        string poolName;
        uint256 duration;
        uint256 amount;
        uint256 discount;
        uint256 lockDuration;
        uint256 poolMax;
        bool status;
    }

    // address pool data structure

    struct addressStr {
        uint256 amount;
        uint256 dateDeposit;
        uint256 epoch;
        uint256 ipmbPrice;
        uint256 goldPrice;
    }

    // mappings declaration

    mapping (address => bool) public admin;
    mapping (address => bool) public authority;
    mapping (address => bool) public blacklist;
    mapping (uint256 => poolStr) public poolsRegistry;
    mapping (address => bool) public kycAddress;
    mapping (address => mapping (uint256 => uint256)) public addressCounter;
    mapping (address => mapping (uint256 => uint256[])) public addressArray;
    mapping (address => mapping (uint256 => mapping (uint256 => addressStr))) public addressDataNew;

    
    // variables declaration

    uint256 public nextpoolCounter;
    uint256 public withdrawalDuration;
    address public ipmbAddress;
    IPriceFeed public priceFeedAddress;
    address public gemContract;
    uint256 blackPeriod;

    // modifiers

    modifier onlyAdmin() {
        require(admin[msg.sender] == true, "Not allowed");
        _;
    }

    modifier onlyAuthority() {
        require(admin[msg.sender] == true || authority[msg.sender] == true, "Not allowed");
        _;
    }

    // events

    event poolRegistration(uint256 indexed poolId);
    event poolDeposit(uint256 indexed poolId, address indexed addr, uint256 indexed index, uint256 amount);
    event poolWithdrawal(uint256 indexed poolId, address indexed addr, uint256 indexed index, uint256 amount);
    event blacklistWithdrawal(uint256 indexed poolId, address indexed addr, uint256 indexed index, uint256 amount);
    event poolResetAfterMinting(uint256 indexed poolId, address indexed addr, uint256 indexed index);

    // constructor

    constructor (address _ipmbAddress, address _priceFeedAddress, uint256 _blackPeriod) {
        admin[msg.sender] = true;
        ipmbAddress = _ipmbAddress;
        nextpoolCounter = 1;
        priceFeedAddress = IPriceFeed(_priceFeedAddress);
        blackPeriod = _blackPeriod;
    }

    // function to register a Pool

    function registerPool(string memory _poolName, uint256 _duration, uint256 _discount, uint256 _amount, uint256 _lockDuration, uint256 _poolMax) public onlyAdmin {
        require(_duration > 0 && _amount > 0 , "err");
        require(_discount >= 2 && _discount <= 20);
        uint256 poolID = nextpoolCounter;
        poolsRegistry[poolID].poolID = poolID;
        poolsRegistry[poolID].poolName = _poolName;
        poolsRegistry[poolID].duration = _duration;
        poolsRegistry[poolID].amount = _amount;
        poolsRegistry[poolID].discount = _discount;
        poolsRegistry[poolID].lockDuration = _lockDuration;
        poolsRegistry[poolID].poolMax = _poolMax;
        poolsRegistry[poolID].status = true;
        emit poolRegistration(poolID);
        nextpoolCounter = nextpoolCounter + 1;
    }

    // function to deposit funds

    function depositPool(uint256 _poolID) public {
        require(kycAddress[msg.sender] == true, "No KYC");
        require(blacklist[msg.sender] == false, "Address is blacklisted");
        require(poolsRegistry[_poolID].poolMax > addressArray[msg.sender][_poolID].length, "Already deposited max times");
        require(poolsRegistry[_poolID].status == true, "Pool is inactive");
        require(IERC20(ipmbAddress).balanceOf(msg.sender) >= poolsRegistry[_poolID].amount, "Your ERC20 balance is not enough");
        (uint256 epoch, uint256 ipmbPrice, uint256 goldPrice, ,) = priceFeedAddress.getLatestPrices();
        uint256 count = addressCounter[msg.sender][_poolID];
        addressDataNew[msg.sender][_poolID][count].amount = poolsRegistry[_poolID].amount;
        addressDataNew[msg.sender][_poolID][count].dateDeposit = block.timestamp;
        addressDataNew[msg.sender][_poolID][count].epoch = epoch;
        addressDataNew[msg.sender][_poolID][count].ipmbPrice = ipmbPrice;
        addressDataNew[msg.sender][_poolID][count].goldPrice = goldPrice;
        addressArray[msg.sender][_poolID].push(count);
        addressCounter[msg.sender][_poolID]++;
        IERC20(ipmbAddress).transferFrom(msg.sender, address(this), poolsRegistry[_poolID].amount);
        emit poolDeposit(_poolID, msg.sender, count, poolsRegistry[_poolID].amount);
    }

    // function to withdrawl deposit amounts

    function withdrawalPool(uint256 _poolID, uint256 _index) public {
        require(blacklist[msg.sender] == false, "Address is blacklisted");
        require(addressDataNew[msg.sender][_poolID][_index].amount == poolsRegistry[_poolID].amount, "No deposit");
        require(block.timestamp >= addressDataNew[msg.sender][_poolID][_index].dateDeposit + poolsRegistry[_poolID].lockDuration, "Time has not passed");
        uint256 amount = addressDataNew[msg.sender][_poolID][_index].amount;
        addressDataNew[msg.sender][_poolID][_index].amount = 0;
        addressDataNew[msg.sender][_poolID][_index].dateDeposit = 0;
        addressDataNew[msg.sender][_poolID][_index].epoch = 0;
        addressDataNew[msg.sender][_poolID][_index].ipmbPrice = 0;
        addressDataNew[msg.sender][_poolID][_index].goldPrice = 0;
        for (uint256 i = 0; i < addressArray[msg.sender][_poolID].length; i++) {
            if (_index == addressArray[msg.sender][_poolID][i]) {
                addressArray[msg.sender][_poolID][i] = addressArray[msg.sender][_poolID][addressArray[msg.sender][_poolID].length-1];
                addressArray[msg.sender][_poolID].pop();
            }
        }
        IERC20(ipmbAddress).transfer(msg.sender, amount);
        emit poolWithdrawal(_poolID, msg.sender, _index, amount);
    }

    // function to update pool data

    function updatePoolData(uint256 _poolID, uint256 _poolMax, bool status) public onlyAdmin {
        poolsRegistry[_poolID].poolMax = _poolMax;
        poolsRegistry[_poolID].status = status;
    }

    // function to update address pool details after nft minting

    function updateAddressPool(address _address, uint256 _poolID, uint256 _index) public {
        require(msg.sender == gemContract, "Not allowed");
        addressDataNew[_address][_poolID][_index].amount = 0;
        addressDataNew[_address][_poolID][_index].dateDeposit = 0;
        addressDataNew[_address][_poolID][_index].epoch = 0;
        addressDataNew[_address][_poolID][_index].ipmbPrice = 0;
        addressDataNew[_address][_poolID][_index].goldPrice = 0;
        emit poolResetAfterMinting(_poolID, _address, _index);
    }

    // function to register an admin

    function addAdmin(address _address, bool _status) public onlyOwner {
        admin[_address] = _status;
    }

    // function to register an authority

    function addAuthority(address _address, bool _status) public onlyOwner {
        authority[_address] = _status;
    }

    // function to blacklist

    function addBlacklist(address _address, bool _status) public onlyAuthority {
        blacklist[_address] = _status;
    }

    // function to set GeMNFTs contract

    function setgemContract(address _address) public onlyOwner {
        gemContract = _address;
    }

    // function to update prices contract admin

    function updatePricesContract(address _address) public onlyOwner {
        priceFeedAddress = IPriceFeed(_address);
    }

    // function to approve gemContract

    function approveGemContract(uint256 _amount) public onlyAdmin {
        IERC20(ipmbAddress).approve(gemContract, _amount);
    }

    // function to modify the time that the blacklist funds can be withdrawl

    function changeBlackPeriod(uint256 _blackPeriod) public onlyAdmin {
        blackPeriod = _blackPeriod;
    }

    // function to update address kyc status

    function updateKYCAddress(address _address, bool _status) public onlyAdmin {
        kycAddress[_address] = _status;
    }

    // function to update address kyc status

    function updateKYCAddressBatch(address[] memory _address, bool[] memory _status) public onlyAdmin {
        for (uint256 i = 0; i < _address.length; i++) {
            kycAddress[_address[i]] = _status[i];
        }
    }

    // function to withdrawl blacklist amount

    function blacklistAddressWithdrawalPool(address _receiver, address _address, uint256 _poolID, uint256 _index) public onlyOwner {
        require(blacklist[_address] == true, "Address is not blacklisted");
        require(addressDataNew[_address][_poolID][_index].amount == poolsRegistry[_poolID].amount, "No deposit");
        require(block.timestamp >= addressDataNew[_address][_poolID][_index].dateDeposit + blackPeriod, "Time has not passed");
        uint256 amount = addressDataNew[_address][_poolID][_index].amount;
        addressDataNew[_address][_poolID][_index].amount = 0;
        addressDataNew[_address][_poolID][_index].dateDeposit = 0;
        addressDataNew[_address][_poolID][_index].epoch = 0;
        addressDataNew[_address][_poolID][_index].ipmbPrice = 0;
        addressDataNew[_address][_poolID][_index].goldPrice = 0;
        IERC20(ipmbAddress).transfer(_receiver, amount);
        emit blacklistWithdrawal(_poolID, _address, _index, amount);
    }

    // retrieve discount

    function getDiscount(uint256 _poolID, address _address, uint256 _index) public view returns (uint256) {
        if ((addressDataNew[_address][_poolID][_index].amount == poolsRegistry[_poolID].amount) && (block.timestamp >= addressDataNew[_address][_poolID][_index].dateDeposit + poolsRegistry[_poolID].duration)) {
            return poolsRegistry[_poolID].discount;
        } else {
            return 0;
        }
    }

    // retrieve pool info

    function poolInfo(uint256 _poolID) public view returns (uint256, string memory, uint256, uint256, uint256, uint256, bool) {
        return (poolsRegistry[_poolID].poolID, poolsRegistry[_poolID].poolName, poolsRegistry[_poolID].duration, poolsRegistry[_poolID].amount, poolsRegistry[_poolID].discount, poolsRegistry[_poolID].lockDuration, poolsRegistry[_poolID].status);
    }

    // retrieve pool price

    function poolPrice(uint256 _poolID) public view returns (uint256) {
        return (poolsRegistry[_poolID].amount);
    }

    // retrieve pool status

    function poolStatus(uint256 _poolID) public view returns (bool) {
        return (poolsRegistry[_poolID].status);
    }

    // retrieve deposit amount

    function poolAmountPerAddress(uint256 _poolID, address _address, uint256 _index) public view returns (uint256) {
        return (addressDataNew[_address][_poolID][_index].amount);
    }

    // retrieve deposit amount

    function poolDataPerAddress(uint256 _poolID, address _address, uint256 _index) public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (addressDataNew[_address][_poolID][_index].amount, addressDataNew[_address][_poolID][_index].dateDeposit, addressDataNew[_address][_poolID][_index].epoch, addressDataNew[_address][_poolID][_index].ipmbPrice, addressDataNew[_address][_poolID][_index].goldPrice);
    }

    // retrieve deposit date

    function poolDepositDatePerAddress(uint256 _poolID, address _address, uint256 _index) public view returns (uint256) {
        return (addressDataNew[_address][_poolID][_index].dateDeposit);
    }

    // retrieve ipmb price at pool deposit

    function poolIPMBPricePerAddress(uint256 _poolID, address _address, uint256 _index) public view returns (uint256) {
        return (addressDataNew[_address][_poolID][_index].ipmbPrice);
    }

    // retrieve gold price at pool deposit

    function poolGoldPricePerAddress(uint256 _poolID, address _address, uint256 _index) public view returns (uint256) {
        return (addressDataNew[_address][_poolID][_index].goldPrice);
    }

    // retrieve epoch at pool deposit

    function poolEpochPerAddress(uint256 _poolID, address _address, uint256 _index) public view returns (uint256) {
        return (addressDataNew[_address][_poolID][_index].epoch);
    }

    // retrieve KYC address status

    function retrieveKYCStatus(address _address) public view returns (bool) {
        return (kycAddress[_address]);
    }

    // retrieve the deposit indeces per address per pool

    function retrieveAddressArrayPool(address _address, uint256 _pool) public view returns (uint256[] memory) {
        return (addressArray[_address][_pool]);
    }

    // retrieve counter per address per pool

    function retrieveAddressCounterPool(address _address, uint256 _pool) public view returns (uint256) {
        return (addressCounter[_address][_pool]);
    }

    // retrieve blacklist status

    function retrieveBlackListStatus(address _address) public view returns (bool) {
        return (blacklist[_address]);
    }

}