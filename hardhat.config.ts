import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
		hardhat: {
			chainId: 1,
			forking: {
				blockNumber: 15000000,
				url: "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY
			},
			hardfork: "london"
		}
  }
};

export default config;
