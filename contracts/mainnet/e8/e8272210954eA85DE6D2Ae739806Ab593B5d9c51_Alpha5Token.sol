pragma solidity ^0.5.0;

import "./ERC20Capped.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Alpha5Token is ERC20Detailed, ERC20Capped, ERC20Burnable{

      //We inherited the ERC20Detailed 
      constructor () public 
        ERC20Detailed("Alpha5Token", "A5T", 18)
        ERC20Capped(50000000*(10**18)){
      }
}