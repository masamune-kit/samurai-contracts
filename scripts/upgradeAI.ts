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

  const SamuraiAI = await ethers.getContractFactory("SamuraiAI");
  const samuraiAI = await upgrades.upgradeProxy(
    "0xC07A823d24abf78d2A9107A5b105FE44f6436101",
    SamuraiAI as ContractFactory
  );
  await samuraiAI.deployed();
  console.log(
    "Implementation: ",
    await upgrades.erc1967.getImplementationAddress(samuraiAI.address)
  );
  console.log(
    "Admin Address: ",
    await upgrades.erc1967.getAdminAddress(samuraiAI.address)
  );
  console.log("Samurai AI deployed to:", samuraiAI.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
