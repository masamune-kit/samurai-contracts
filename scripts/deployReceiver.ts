import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiMultichainReceiver = await ethers.getContractFactory(
    "SamuraiMultichainReceiver"
  );

  const samuraiMultichainReceiver = await SamuraiMultichainReceiver.deploy(
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478"
  );
  const tx = await samuraiMultichainReceiver.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
