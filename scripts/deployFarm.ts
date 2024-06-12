import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const ZenGarden = await ethers.getContractFactory("ZenGarden");
  const zenGarden = await ZenGarden.deploy(
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
    ethers.utils.parseEther("5000000").toString(),
    "77000",
    "365"
  );
  const tx = await zenGarden.deployed();

  console.log("Deploy completed: ", tx.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
