// import { ethers } from "hardhat";

// async function main() {
//   const [signer, acc2] = await ethers.getSigners();
//   const pokemon = await ethers.getContractAt(
//     "PokemonV3",
//     "0xeFa97fbB9540b69f0b269CB9a79F42BC8569352F",
//     signer
//   );

// //   const tx = await pokemon.mint();
// //   console.log(tx.hash);

//     // const tx2 = await pokemon.connect(acc2).mint();
//     // console.log(tx2.hash);
    
//     // const tx3 = await pokemon.connect(acc2).requestBattle(2, signer.address, 1);
//     // await ethers.provider.getTransactionReceipt(tx3.hash)
    
//     const tx4 = await pokemon.connect(signer).acceptBattle(1, 2);
//     console.log("tx4: ", tx4);
    
//     while (true) {
//         console.log(await pokemon.randomNumber());
        
//     }
//     // await ethers.provider.getTransactionReceipt(tx3.hash)/
//     // console.log(await pokemon.randomNumber());  
    
    
// }
// main();
