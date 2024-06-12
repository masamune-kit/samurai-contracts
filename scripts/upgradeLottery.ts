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

  const SamuraiLottery = await ethers.getContractFactory("SamuraiLottery");
  const samuraiLottery = await upgrades.upgradeProxy(
    "0xE2E1096Ae5eA96cB5Da185e750d973AB8c60dc75",
    SamuraiLottery as ContractFactory
  );
  await samuraiLottery.deployed();
  console.log(
    "Implementation: ",
    await upgrades.erc1967.getImplementationAddress(samuraiLottery.address)
  );
  console.log(
    "Admin Address: ",
    await upgrades.erc1967.getAdminAddress(samuraiLottery.address)
  );
  console.log("SamuraiLottery deployed to:", samuraiLottery.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
