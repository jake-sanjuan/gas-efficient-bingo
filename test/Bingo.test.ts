import {ethers} from "hardhat";
import {expect} from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Bingo, TestERC20 } from "../typechain-types";

describe("Test Bingo", () => {
  let deployer: SignerWithAddress;
  let player1: SignerWithAddress;

  let bingo: Bingo;
  let token: TestERC20;

  before(async () => {
    [
      deployer,
      player1
    ] = await ethers.getSigners();
    
    token = await (await ethers.getContractFactory("TestERC20")).deploy("Test Token", "TT") as TestERC20;
    bingo = await (await ethers.getContractFactory("Bingo")).deploy(
      ethers.utils.parseEther('1'),
      10, 
      0,
      token.address
    ) as Bingo;
  });

  describe("createGame()", async() => {
    it("Logging gas estimate", async () => {
      console.log(await bingo.connect(deployer).estimateGas.createGame(1));
    });

    it("Function runs properly", async () => {
      await expect(bingo.connect(deployer).createGame(1)).to.not.be.reverted;
    });

    it("Checking variables in storage", async () => {
      const gameInfo = await bingo.gameInfo(1);
      expect(gameInfo.gameInitBlock).to.be.gt(0);
      expect(gameInfo.lastTurnBlock).to.be.gt(0);
    });
  });

  describe("joinGame()", () => {
    before(async () => {
      await token.mint(player1.address, ethers.utils.parseEther('10'));
      await token.connect(player1).approve(bingo.address, ethers.utils.parseEther('10'))
    });

    it("Logging gas estimate", async () => {
      console.log(await bingo.connect(player1).estimateGas.joinGame(1));
    });

    it("Function runs properly", async () => {
      await expect(bingo.connect(player1).joinGame(1)).to.not.be.reverted;
    });

    it("Checking variables in storage", async () => {
      const playerStruct = await bingo.playersByGameIdx(1, 0);
      
      expect(await token.balanceOf(bingo.address)).to.equal(ethers.utils.parseEther('1'));
      expect(playerStruct.boardAndAddress).to.not.equal(ethers.constants.HashZero);
      expect(playerStruct.coveredSpots).to.equal(ethers.constants.HashZero);
    });
  });

  describe("draw()", () => {
    it("Function runs properly", async () => {
      await expect(bingo.connect(deployer).draw(1)).to.not.be.reverted;
    });

    it("Checking variables in storage", async () => {
      const storageBefore = await bingo.playersByGameIdx(1, 0);

      // Draw until we get a true
      for(let i = 0; i < 6; i++) {
        await bingo.connect(deployer).draw(1);
      }
      // Wait for storage write
      const gasEstimate = await bingo.connect(deployer).estimateGas.draw(1);
      console.log("Gas estimate: ", gasEstimate);

      await bingo.connect(deployer).draw(1);

      const storageAfter = await bingo.playersByGameIdx(1, 0);

      expect(storageAfter.coveredSpots).to.not.equal(ethers.constants.AddressZero);
      expect(storageAfter.boardAndAddress).to.equal(storageBefore.boardAndAddress);
    });
  });

  describe("bingo()", () => {
    it("Transfers rewards properly", async () => {
      // Can be done with hardhat_setStorageAt, this was quicker for now
      for (let i = 0; i < 400; i++) {
        await bingo.connect(deployer).draw(1);
      }

      // Estimate gas here when full function will pass
      const gasEstimate = await bingo.connect(player1).estimateGas.bingo(1, 10, 0);
      console.log("Gas estimate: ", gasEstimate);

      await bingo.connect(player1).bingo(1, 10, 0);

      expect(await token.balanceOf(bingo.address)).to.equal(0);
      expect(await token.balanceOf(player1.address)).to.equal(ethers.utils.parseEther('10'))
    });
  });
});