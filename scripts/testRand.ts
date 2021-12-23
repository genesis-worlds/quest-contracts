import { solidity } from "ethereum-waffle";
import chai from "chai";
import { MockRandom  } from "../typechain";
import { deployContract } from "../helper/deployer";

chai.use(solidity);
const { assert, expect } = chai;

async function main() {
    const rand = <MockRandom>await deployContract("MockRandom");
    await rand.commit();
    const tx = await rand.reveal();
    const receipt = await tx.wait();
    console.log(receipt.events![0].args![0]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
