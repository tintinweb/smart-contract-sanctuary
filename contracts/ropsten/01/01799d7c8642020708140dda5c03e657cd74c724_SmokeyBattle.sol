pragma solidity ^0.4.24;


contract SmokeyBattle {

    struct Smokeymon {
        string name;
        uint8 attackPower;
        uint8 health;
        address owner;
    }


    Smokeymon[] public pokemon;

    function makeSmokeymon(string _name,  uint8 _attackPower) public returns (uint){
        Smokeymon memory p = Smokeymon( _name, _attackPower, 255, msg.sender);
        pokemon.push(p);
        return pokemon.length;
    }



    modifier pokemonValid(uint index) {
        require(index < pokemon.length, &#39;Smokeymon does not exist&#39;);
        require(pokemon[index].health > 0, "Your pokemon is dead bruhh");
        _;
    }


    function attack(uint source, uint target)
        public
        pokemonValid(source)
        pokemonValid(target)
    {

        Smokeymon storage sourceSmokeymon = pokemon[source];
        Smokeymon storage targetSmokeymon = pokemon[target];

        require(sourceSmokeymon.owner == msg.sender, "You don&#39;t own this pokeymans");

        uint8 clampedPower = sourceSmokeymon.attackPower >= targetSmokeymon.health
        ? targetSmokeymon.health
        : sourceSmokeymon.attackPower;

        targetSmokeymon.health -= clampedPower;
    }

}