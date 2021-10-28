/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// File: contracts/bulk.sol

pragma solidity ^0.4.24;

interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address tokenOwner)  external returns (uint balance);

}
contract Bulksender{
   function bulksendToken(IERC20 _token, address[] _to, uint256[] _values) public  
   {
      require(_to.length == _values.length);
      for (uint256 i = 0; i < _to.length; i++) {
         _token.transferFrom(msg.sender, _to[i], _values[i]);
    }
  }
}