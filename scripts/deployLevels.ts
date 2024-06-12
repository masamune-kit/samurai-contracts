import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiLevels = await ethers.getContractFactory("SamuraiLevels");
  const samuraiLevels = await SamuraiLevels.deploy(
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
    "20000000000000000000",
    "20"
  );
  const tx = await samuraiLevels.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
