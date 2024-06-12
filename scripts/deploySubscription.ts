import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiSubscription = await ethers.getContractFactory(
    "SamuraiSubscription"
  );

  const samuraiSubscription = await SamuraiSubscription.deploy(
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
    "0xF491e7B69E4244ad4002BC14e878a34207E38c29",
    "100",
    "15",
    // 100k xHNR
    "100000000000000000000000"
  );
  const tx = await samuraiSubscription.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
