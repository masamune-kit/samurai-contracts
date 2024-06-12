import { ethers } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const VexHNR = await ethers.getContractFactory("vexHNR");

  const vexHNR = await VexHNR.deploy();
  const tx = await vexHNR.deployed();

  const Vaults = await ethers.getContractFactory("SamuraiVaults");
  const vaults = await Vaults.deploy(
    "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
    vexHNR.address,
    100000,
    1,
    1300,
    100,
    5000000
  );
  const tx2 = await vaults.deployed();

  console.log("Deploy completed: ", tx.address);
  console.log("Vaults: ", tx2.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
