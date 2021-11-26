// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract GFB is ERC20, ERC20Detailed {

    address private _owner;

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }


    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("GFB", "GFB", 18) {
        _owner = _msgSender();
        _mint(0xf05bd190d922055417438F8B903642aA259364F9, 1000000000 * (10 ** uint256(decimals())));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}