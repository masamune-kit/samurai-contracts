import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiRelease = await ethers.getContractFactory("SamuraiRelease");

  const samuraiRelease = await SamuraiRelease.deploy(
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3"
  );
  const tx = await samuraiRelease.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
