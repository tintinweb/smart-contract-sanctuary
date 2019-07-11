pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title HelloWorld
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract HelloWorld is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public
        ERC20Detailed("HelloWorld", "1024", 0) {
        _mint(msg.sender, 1024 * 42); // 1024 * 42
      }
      
      
    function mint() public returns (bool) {
        if (balanceOf(msg.sender) == 0) {
         _mint(msg.sender, 1024);
        }
        
        return true;
    }
}