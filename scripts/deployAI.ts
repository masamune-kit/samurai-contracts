// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import type { ContractFactory } from "ethers";

async function main() {
  const [deployer, _distributionPool, _a, _b, manager] =
    await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiAI = await ethers.getContractFactory("SamuraiAI");

  const samuraiAI = await upgrades.deployProxy(
    SamuraiAI as ContractFactory,
    [
      "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
      "0xF491e7B69E4244ad4002BC14e878a34207E38c29",
      manager.address,
    ],
    { initializer: "initialize" }
  );
  await samuraiAI.deployed();
  console.log("Samurai AI Deployed!");

  console.log(
    "TransferProxy SamuraiAI Contract deployed to:",
    samuraiAI.address
  );
  console.log(
    "Implementation Contract: ",
    await upgrades.erc1967.getImplementationAddress(samuraiAI.address)
  );
  console.log(
    "ProxyAdmin Contract: ",
    await upgrades.erc1967.getAdminAddress(samuraiAI.address)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
