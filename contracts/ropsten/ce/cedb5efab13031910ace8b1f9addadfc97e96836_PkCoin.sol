/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

pragma solidity 0.6.6;

contract PkCoin{

    
    function getBalance(address addr) public view returns(int256)
    {
        return int256(addr.balance);
    }
    
    function investment(address payable addr)payable public 
    {
        addr.transfer(.005 ether);
    }
    
    
}