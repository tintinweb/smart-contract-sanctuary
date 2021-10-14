/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.4.24;


interface IERC721 {

    function claim(uint value)  external returns (uint balance);
    function transferFrom(address from,address to,uint256 tokenId) external;

}
contract Bulkmint{

  function bulkmint(IERC721 _token, uint256[] _values) public  
   {

      for (uint256 i = 0; i < _values.length; i++) {
          _token.claim(_values[i]);
          _token.transferFrom(address(this),msg.sender,_values[i]);
    }
    }
}