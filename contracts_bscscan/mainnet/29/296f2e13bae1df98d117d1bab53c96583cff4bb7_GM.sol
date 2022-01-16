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
contract GM is ERC20, ERC20Detailed {
    
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

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("GM", "GM", 18) {
        _owner = _msgSender();
        _mint(0x646FDd409051E5196de21990895746B43eb8D750, 3000000000 * (10 ** uint256(decimals())));
    }
    
}