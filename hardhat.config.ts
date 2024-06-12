import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const [PRIVATE_KEY, PRIVATE_KEY_DISTRIBUTION_POOL, PRIVATE_KEY_FUTURE_POOL] = [
  process.env.PRIVATE_KEY,
  process.env.PRIVATE_KEY_DISTRIBUTION_POOL,
  process.env.PRIVATE_KEY_FUTURE_POOL,
];

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    mainnet: {
      url: `https://rpc.ftm.tools/`,
      chainId: 250,
      gasPrice: 150000000000,
      gas: "auto",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    testnet: {
      url: `https://rpc.testnet.fantom.network/`,
      chainId: 4002,
      accounts: [
        `0x${PRIVATE_KEY}`,
        `0x${PRIVATE_KEY_DISTRIBUTION_POOL}`,
        `0x${PRIVATE_KEY_FUTURE_POOL}`,
      ],
      gasPrice: 3000000000,
      gas: "auto",
    },
    ethnet: {
      url: `https://rpc.ankr.com/eth`,
      chainId: 1,
      gasPrice: 20000000000,
      gas: "auto",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    bscnet: {
      url: `https://bsc-dataseed1.binance.org/`,
      chainId: 56,
      gasPrice: 10000000000,
      gas: "auto",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    avaxnet: {
      url: `https://api.avax.network/ext/bc/C/rpc`,
      chainId: 43114,
      gasPrice: 30000000000,
      gas: "auto",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    maticnet: {
      url: `https://polygon-rpc.com`,
      chainId: 137,
      gasPrice: 180000000000,
      gas: "auto",
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
  },
};

export default config;
