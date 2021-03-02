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
    
    address minter;
    
    mapping(address => uint256) balances;

    string public constant _name = "Five Buck Token";
    string public constant _symbol = "5ive";
    uint8 public constant _decimals = 18;
    uint256 _totalSupply = 500000000*(10**_decimals);
  
    constructor() ERC20(_name,_symbol,_decimals, _totalSupply)
    {
       balances[msg.sender] = _totalSupply;
       emit Transfer(address(0), msg.sender, _totalSupply);
    }
  
    function mint(uint256 amount) public
    {
      require(msg.sender == owner);
      _mint(owner, amount);
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