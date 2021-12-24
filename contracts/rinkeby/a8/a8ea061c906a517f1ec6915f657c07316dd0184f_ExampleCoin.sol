pragma solidity >=0.7.0 <0.9.0;
contract ExampleCoin {
   address public minter;

   bool public publicAcivated = false;

   mapping (address => uint) public balances;
   
   event Sent(address from, address to, uint amount);



    function startSale(bool newVal) public{
        publicAcivated = newVal;
    } 

   
}