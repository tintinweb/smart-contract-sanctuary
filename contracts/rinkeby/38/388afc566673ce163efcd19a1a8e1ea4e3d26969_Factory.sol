pragma solidity ^0.4.15;

contract Factory {

   
    event ContractInstantiation(address sender, address instantiation);

    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;


    function getInstantiationCount(address creator)
        public
        constant
        returns (uint)
    {
        return instantiations[creator].length;
    }

 
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}