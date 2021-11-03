/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity 0.8.9;


interface IContrat{
    function store(uint256 num) external;
    function retrieve() external view returns (uint256);
}

contract Contrat{
    address contractCible=0xE9e1c1CC91950C424631addbd812d960e9505b47;
    IContrat interfaceContratCible= IContrat(contractCible);
    
    function getCible() external view returns(uint){
        return interfaceContratCible.retrieve();
    }
    
    function setCible(uint num) external{
        interfaceContratCible.store(num);
    }
}