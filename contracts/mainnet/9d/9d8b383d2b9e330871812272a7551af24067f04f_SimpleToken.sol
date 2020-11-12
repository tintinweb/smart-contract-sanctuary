pragma solidity ^0.6.0;
 
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
 
contract SimpleToken is ERC20, ERC20Detailed, ERC20Burnable {
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 *  1000000000000000000;

    constructor () public ERC20Detailed("Cardinate", "CDN", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
