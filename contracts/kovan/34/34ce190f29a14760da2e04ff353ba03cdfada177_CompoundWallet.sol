/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity ^0.6.0;

interface CEtherInterface{
    function totalSupply() external view returns (uint);
}


contract CompoundWallet{
    address public cEtherAddress = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    
    
    function readTotalSupply() public view returns(uint256){
        CEtherInterface cEther = CEtherInterface(cEtherAddress);
        return cEther.totalSupply();
    }
}