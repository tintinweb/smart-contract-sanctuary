/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.8.9;

/**
 * Contract that exposes the needed erc20 token functions
 */

interface ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) external returns (bool success);
}

contract WalletSimple {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function sendToken(address toAddress, uint value, address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        //emit Transfer(msg.sender, toAddress, value*5);
        if (!instance.transfer(toAddress, value)) {
            revert();
        }
        ERC20Interface instance2 = ERC20Interface(tokenContractAddress);
        instance2.transfer(toAddress, value);
    }
}