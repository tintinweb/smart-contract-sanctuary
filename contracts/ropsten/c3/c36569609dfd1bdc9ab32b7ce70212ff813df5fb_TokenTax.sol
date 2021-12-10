/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;
 contract TokenTax{
        constructor( uint256 _qty) public{
            tsupply=_qty;
            balances[msg.sender]=tsupply;
            Name="Tech";
            Number=0;
            Symbol="TTX";
        }
     string Name;
     function name() public view returns(string memory){
         return Name;
     }
     string Symbol;
      function symbol() public view returns(string memory){
          return Symbol;
     }
     uint8 Number;
      function decimals() public view returns(uint8){
          return Number;
     }
     uint256 tsupply;
      function totalSupply() public view returns(uint256){
          return tsupply;
     }
     mapping(address=>uint256)balances;
     function balanceOf(address _owner) public view returns(uint256 balance){
         return balances[_owner];
     }
     event Transfer(address indexed _from,address indexed _to,uint256 _value);
     function transfer(address _to,uint _value) public  returns(bool sucess){
         balances[msg.sender]-= _value;
         balances[_to]+=_value;
         emit Transfer(msg.sender,_to,_value);
         return true;
         
     }
 }