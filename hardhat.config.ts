import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv'; 
// import "@openzeppelin/hardhat-upgrades";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.13",
  networks: {
    hardhat: {
      accounts: {
        mnemonic: process.env.MNEMONIC,
        count: 10,
        accountsBalance: "10000000000000000000000000",
      },
      forking: {
        url: process.env.GOERLI_URL || '',
      },
      chainId: 5
    },
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: process.env.DEV_PRIVKEY ? [process.env.DEV_PRIVKEY, process.env.ANOTHER_PRIVKEY as string]: [],
    },
    mumbai: {
      url: process.env.MUMBAI_URL,
      accounts: process.env.DEV_PRIVKEY ? [process.env.DEV_PRIVKEY]: [],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

export default config;