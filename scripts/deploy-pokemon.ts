import { ethers } from "hardhat";

async function main() {

  const Pokemon = await ethers.getContractFactory("PokemonV3");
  const pokemon = await Pokemon.deploy("NewPokemons", "NP");

  await pokemon.deployed();

  console.log(`Token succesfully deployed at address ${pokemon.address}`);
}

main();

