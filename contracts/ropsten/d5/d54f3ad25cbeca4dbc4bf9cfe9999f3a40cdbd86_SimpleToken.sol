pragma solidity ^0.5.0;

import "./Initializable.sol";

import "./ERC20.sol";
import "./ERC20Detailed.sol";


/**
 * @title SimpleToken
 */
contract SimpleToken is Initializable, ERC20, ERC20Detailed {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) public initializer {
        ERC20Detailed.initialize(name,symbol,decimals);
        totalSupply = totalSupply * 10**uint256(decimals);
        ERC20.initialize(totalSupply);
    }
}