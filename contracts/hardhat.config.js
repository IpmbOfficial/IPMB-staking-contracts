require("@nomicfoundation/hardhat-toolbox")
require("hardhat-gas-reporter")

module.exports = {
  paths: {
    sources: "./smart-contracts",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.26",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
    ],
  },
  gasReporter: {
    enabled: true,
  },
}
