pragma solidity ^0.5.0;

import "./ERC20.sol";

contract TOKEN is ERC20, ERC20Detailed { constructor () public ERC20Detailed("Embrace", "EMX", 8) 

{ _mint(msg.sender, 80000000 * (10 ** uint256(decimals()))); }}