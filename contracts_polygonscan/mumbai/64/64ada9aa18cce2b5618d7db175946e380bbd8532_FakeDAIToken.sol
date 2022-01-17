pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";

/**
 * @dev Test ERC20 token that allows any one mint new tokens.
 */
contract FakeDAIToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function mint(address account, uint256 amount) public returns (bool) {
        ERC20._mint(account, amount + 1);
        return true;
    }
}