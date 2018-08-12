pragma solidity ^0.4.24;

contract Provino{
    
    event Prova(uint256 uno, uint256 due, uint256 tre, uint256 quattro);
    event Prova2(uint256 uno, uint256 due, uint256 tre, uint256 quattro, uint256 cinque);
    event Prova3(address indexed add, uint256[] uno);
    
    function prova() external
    {
        emit Prova(1,2,3,4);
    }
    
    function prova2()
    external
    {
        emit Prova2(1,2,3,4,5);
    }
    
    function prova3(uint256[] uno)
    external
    {
        emit Prova3(msg.sender, uno);
    }
    
}