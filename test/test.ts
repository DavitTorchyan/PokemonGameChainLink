// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { time } from "@nomicfoundation/hardhat-network-helpers";
// import { BigNumber } from "ethers";

// describe("PokemonV3", function () {

//     async function deployTokenFixture() {

//         const [owner, acc1, acc2, acc3] = await ethers.getSigners();
//         const NftFactory = await ethers.getContractFactory("PokemonV3");
//         const name = "NewPokemons";
//         const symbol = "NP"
//         const nft = await NftFactory.deploy(8459, name, symbol);


//         return { nft, owner, acc1, acc2, acc3, name, symbol };
//     }

//     describe("Dna", () => {
//         it("Should show dna of a pokemon correctly.", async () => {
//             const { nft, acc1, acc2 } = await loadFixture(deployTokenFixture);
//             await nft.connect(acc1).mint();
//             await nft.connect(acc2).mint();
                                           
//         })
//     })



// })