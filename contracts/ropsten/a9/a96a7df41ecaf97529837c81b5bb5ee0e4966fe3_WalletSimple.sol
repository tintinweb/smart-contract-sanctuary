/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.4.14;

/**
 * Contract that exposes the needed erc20 token functions
 */

contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract WalletSimple {
    function sendToken(address toAddress, uint value, address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        if (!instance.transfer(toAddress, value)) {
            revert();
        }
    }
}