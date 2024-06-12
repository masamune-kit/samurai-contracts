import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiTrade = await ethers.getContractFactory("SamuraiTrade");

  const samuraiTrade = await SamuraiTrade.deploy(
    ethers.utils.parseEther("545").toString(),
    ethers.utils.parseEther("515").toString(),
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478"
  );
  const tx = await samuraiTrade.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
