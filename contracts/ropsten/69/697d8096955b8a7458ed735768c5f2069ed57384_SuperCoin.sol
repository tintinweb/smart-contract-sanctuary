pragma solidity ^0.4.2;

contract SuperCoin {

 uint256 private _totalSupply = 1000000;
 mapping(address => uint256) private _balances;

 event Transfer(address indexed _from, address indexed _to, uint256 _value); function name() public pure returns (string) {
   return &#39;Super Coin from Zainan&#39;;
 }

 function symbol() public pure returns (string) {
   return &#39;SUPERCOIN&#39;;
 }

 function decimals() public pure returns (uint8) {
   return 0;
 }

 constructor() public {
   _balances[msg.sender] = _totalSupply;
 }

 function totalSupply() public view returns (uint256) {
   return _totalSupply;
 }

 function balanceOf(address owner) public view returns (uint256) {
   return _balances[owner];
 }

 function transfer(address to, uint256 value) public returns (bool) {
   require(_balances[msg.sender] >= value);
   _balances[msg.sender] -= value;
   _balances[to] += value;
   return true;
 }
}