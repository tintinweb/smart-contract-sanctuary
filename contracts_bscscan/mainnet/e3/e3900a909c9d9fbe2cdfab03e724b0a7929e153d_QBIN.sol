/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/**
 * SPDX-License-Identifier: MIT
 */ 


 pragma solidity ^0.4.18;



contract ERC20 {
    function transfer(address _to, uint256 _value)public returns(bool);
    function balanceOf(address tokenOwner)public view returns(uint balance);
    function transferFrom(address from, address to, uint tokens)public returns(bool success);

}

contract QBIN {

      ERC20 public token;

        function SimpleAirdrop(address _tokenAddr) public {
        token = ERC20(_tokenAddr);
}

  function getAirdrop() public {
    token.transfer(msg.sender, 100000000000000000000); //8 decimals token
  }
}