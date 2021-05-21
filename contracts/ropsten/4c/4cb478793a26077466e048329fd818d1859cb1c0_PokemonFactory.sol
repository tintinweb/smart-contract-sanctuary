// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Pokemon.sol";

contract PokemonFactory {
    Pokemon[] public pokemons;
    
    

    function create(address _owner, string memory _model) public {
        Pokemon pokemon = new Pokemon(_owner, _model);
        pokemons.push(pokemon);
    }

    function createAndSendEther(address _owner, string memory _model)
        public
        payable
    {
        Pokemon pokemon = (new Pokemon){value: msg.value}(_owner, _model);
        pokemons.push(pokemon);
    }

    function getCar(uint _index)
        public
        view
        returns (address owner, string memory model, uint balance)
    {
        Pokemon pokemon = pokemons[_index];

        return (pokemon.owner(), pokemon.model(), address(pokemon).balance);
    }
}