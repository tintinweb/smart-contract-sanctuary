//holly shit this web compiler is fucking awesome ! 
pragma solidity ^0.5.2;

contract SimpleStorage{
    uint public storedData;
    string public  WalletAddress;
    address public myEtherWallAddr;
    
    
    function setStore(uint x,string memory WA) public
    {
        storedData=x;
        WalletAddress=WA;
    }
    
     function  getStore() public returns (uint)
    {
        return storedData;
    }
  
    function  getWalletAddress() public  returns (string memory)
    {
        return WalletAddress;
    }

}