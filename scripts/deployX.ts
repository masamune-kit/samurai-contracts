// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import type { ContractFactory } from "ethers";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const XHNR = await ethers.getContractFactory("xHNR");
  const xHNR = await upgrades.deployProxy(XHNR as ContractFactory, {
    initializer: "initialize",
  });
  await xHNR.deployed();
  console.log("xHNR Deployed!");

  // approve the spendings
  console.log("TransferProxy xHNR Contract deployed to:", xHNR.address);
  console.log(
    "Implementation Contract: ",
    await upgrades.erc1967.getImplementationAddress(xHNR.address)
  );
  console.log(
    "ProxyAdmin Contract: ",
    await upgrades.erc1967.getAdminAddress(xHNR.address)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
