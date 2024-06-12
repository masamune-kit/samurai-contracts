import { ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const WXHNR = await ethers.getContractFactory("wxHNR");
  const wxHNR = await upgrades.deployProxy(WXHNR as ContractFactory, {
    initializer: "initialize",
  });
  await wxHNR.deployed();
  console.log("wxHNR Deployed!");
  console.log("TransferProxy wxHNR Contract deployed to:", wxHNR.address);
  console.log(
    "Implementation Contract: ",
    await upgrades.erc1967.getImplementationAddress(wxHNR.address)
  );
  console.log(
    "ProxyAdmin Contract: ",
    await upgrades.erc1967.getAdminAddress(wxHNR.address)
  );

  const ZenGarden = await ethers.getContractFactory("ZenGarden");
  const zenGarden = await ZenGarden.deploy(
    wxHNR.address,
    ethers.utils.parseEther("5000000").toString(),
    // blocks per day
    "77000",
    "365"
  );
  const tx = await zenGarden.deployed();
  console.log("ZenGarden completed: ", tx.address);

  const Receiver = await ethers.getContractFactory("SamuraiMultichainReceiver");
  const receiver = await Receiver.deploy(wxHNR.address);
  const tx2 = await receiver.deployed();
  console.log("Receiver completed: ", tx2.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
