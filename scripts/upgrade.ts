// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import type { ContractFactory } from "ethers";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Upgrading contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const HonourNodes = await ethers.getContractFactory("HonourNodes");
  const honourNodes = await upgrades.upgradeProxy(
    "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
    HonourNodes as ContractFactory
  );
  await honourNodes.deployed();
  console.log(
    "Implementation: ",
    await upgrades.erc1967.getImplementationAddress(honourNodes.address)
  );
  console.log(
    "Admin Address: ",
    await upgrades.erc1967.getAdminAddress(honourNodes.address)
  );
  console.log("HonourNodes deployed to:", honourNodes.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
