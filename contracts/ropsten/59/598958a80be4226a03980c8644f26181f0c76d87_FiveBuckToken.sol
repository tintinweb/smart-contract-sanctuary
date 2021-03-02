// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Template token that can be purchased
 * @dev World's smallest crowd sale
 */
contract FiveBuckToken is ERC20, Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;

    string public constant _name = "Five Buck Token";
    string public constant _symbol = "5ive";
    uint256 _initalSupply = 500000000*(10**18);
  
    constructor() ERC20(_name,_symbol)
    {
       _mint(owner(), _initalSupply);
    }
  
    // Mints the amount of Token to the Owner-address (Only callable from the owner)
    function mint(uint256 amount) public
    {
      require(msg.sender == owner());
      _mint(owner(), amount);
    }
    
    // Burns the amount in the ETH BurnAddress (Only callable from the owner)
    function burn(uint256 amount) public
    {
      require(msg.sender == owner());
      _burn(owner(), amount);
    }
    
    // Make sure this contract cannot receive ETH.
    fallback() external payable 
    {
        revert("The contract cannot receive ETH payments.");
    }

    receive() external payable 
    {
        revert("The contract cannot receive ETH payments.");
    }
}