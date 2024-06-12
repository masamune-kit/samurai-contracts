import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiLevelsV2 = await ethers.getContractFactory("SamuraiLevelsV2");
  const samuraiLevelsV2 = await SamuraiLevelsV2.deploy(
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
    "0xF491e7B69E4244ad4002BC14e878a34207E38c29",
    "20000000000000000000",
    "20",
    "10",
    "100"
  );
  const tx = await samuraiLevelsV2.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
