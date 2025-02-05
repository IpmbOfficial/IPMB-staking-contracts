# GPRO Staking Contract

This repository contains the Solidity smart contract **GPROStaking**, developed by the IPMB Dev Team, designed to implement the staking service for "GoldPro." The contract includes features like pool registration, staking, multi-deposit support, KYC compliance, and blacklist management.

## Features

### 1. **Pool Management**
- Admins can register staking pools with the following parameters:
  - **Pool Name**: The name of the staking pool.
  - **Duration**: The duration for which tokens are staked.
  - **Amount**: The staking amount required per deposit.
  - **Discount**: Discount rate for staked tokens.
  - **Lock Duration**: Minimum time before withdrawals.
  - **Pool Max**: Maximum deposits allowed per user.
  - **Status**: Active or inactive pool status.

### 2. **Staking Mechanism**
- Users can:
  - Stake tokens in registered pools.
  - Perform multiple deposits with the `multiDepositPool` function.
  - Withdraw staked tokens after the lock duration using the `withdrawalPool` function.

### 3. **Blacklist and KYC Management**
- KYC compliance is mandatory for staking.
- Blacklisted users are restricted from staking, and their funds can be recovered by the contract owner after a configurable period.

### 4. **Integration with Price Feeds**
- Fetches real-time prices for GoldPro and gold from an external price feed contract.

### 5. **Role-Based Access Control**
- Roles include:
  - **Admin**: Registers pools, manages roles, and updates configurations.
  - **Authority**: Manages blacklist operations.

### 6. **Event Logging**
- Emits events for all major actions to facilitate tracking and debugging.

---

## Contract Details

### **Mappings**
- `poolsRegistry`: Stores all registered pool details.
- `addressDataNew`: Stores user-specific staking details.
- `blacklist`: Tracks blacklisted addresses.
- `kycAddress`: Tracks KYC-compliant addresses.

### **Structs**
- `poolStr`: Defines the structure of a staking pool.
- `addressStr`: Defines user-specific staking metadata.

### **Key Functions**

#### **Pool Management**
- `registerPool`: Create a new staking pool.
- `updatePoolData`: Update an existing pool's parameters.

#### **Staking and Withdrawal**
- `depositPool`: Stake tokens in a pool.
- `multiDepositPool`: Stake tokens in multiple pools or multiple times.
- `withdrawalPool`: Withdraw staked tokens after the lock duration.

#### **Admin and Role Management**
- `addAdmin`: Add or remove an admin.
- `addAuthority`: Add or remove an authority.
- `addBlacklist`: Add or remove a user from the blacklist.

#### **KYC Management**
- `updateKYCAddress`: Update the KYC status of an address.
- `updateKYCAddressBatch`: Batch update KYC statuses for multiple addresses.

---

## Deployment

### Prerequisites
1. Solidity version: `^0.8.19`
2. ERC20 token contract (e.g., "GoldPro")
3. External price feed contract implementing the `IPriceFeed` interface

### Steps
1. Deploy the contract with the following parameters:
   - `_goldProAddress`: Address of the ERC20 token contract.
   - `_priceFeedAddress`: Address of the price feed contract.
   - `_blackPeriod`: Duration after which blacklisted funds can be withdrawn.

2. Configure pools using the `registerPool` function.
3. Assign roles to admins and authorities.

---

## Usage

### Naming scheme for the pools

```solidity
GEM<category>-<duration>-<discount%>-<round> e.g., GEM1-3M-2%-1
```

### Example Commands
#### Register a Pool
```solidity

0	_poolName	string	GEM1-3M-2%-1
1	_duration	uint256	7884000
2	_discount	uint256	2
3	_amount	uint256	1000000000000000000
4	_lockDuration	uint256	1209600
5	_poolMax	uint256	25

registerPool("GEM1-3M-2%-1", 7884000, 2, 1000000000000000000, 1209600, 25);
```

#### Stake Tokens
```solidity
depositPool(1);
```

#### Batch Update KYC Status
```solidity
updateKYCAddressBatch([address1, address2], [true, false]);
```

## Polygon PoS - Mainnet

*GoldPRO Token (GPRO) - v0.7:* [0xACe7eb41D6BAd44907cdA84A122F052c74cB7826](https://polygonscan.com/address/0xACe7eb41D6BAd44907cdA84A122F052c74cB7826)

*Price Feed Contract - v2.3:* [0x82cA437D8cf216fFACea208c3D8B04F0bfDD922D](https://polygonscan.com/address/0x82cA437D8cf216fFACea208c3D8B04F0bfDD922D)

*IPMB Staking Contract - v2.6:* [0x97015969398A4f0DeB2021a7FC457a5a3B8B3A93](https://polygonscan.com/address/0x97015969398A4f0DeB2021a7FC457a5a3B8B3A93)

## Polygon PoS - Amoy Testnet

*IPMB Token (IPMBT) - v0.4:* [0xFF22c94FFb6bB5d1DF18bEb5fd1dFE7583D3B214](https://amoy.polygonscan.com/address/0xff22c94ffb6bb5d1df18beb5fd1dfe7583d3b214)

*Price Feed Contract - v2.2:* [0xB2F7243b6C5f3A3660941BB77bf82D274E664587](https://www.oklink.com/amoy/address/0xB2F7243b6C5f3A3660941BB77bf82D274E664587)

*IPMB Staking Contract - v2.5:* [0xdB886f0a75DFd735118B201C3426a1fA40180e2d](https://amoy.polygonscan.com/address/0xdB886f0a75DFd735118B201C3426a1fA40180e2d)

## Tests

1. Download the github repo
2. Open command prompt and navigate to the [contracts & tests](https://github.com/IpmbOfficial/IPMB-staking-contracts/tree/main/contracts-tests)
3. Install hardhat using `npm i`
4. Compile smart contracts using `npx hardhat compile`
  - If you get `Error HH502` then please upgrade to the laetst hardhat - `npm up hardhat`
5. Run the tests that exist within the test folder using `npx hardhat test`
