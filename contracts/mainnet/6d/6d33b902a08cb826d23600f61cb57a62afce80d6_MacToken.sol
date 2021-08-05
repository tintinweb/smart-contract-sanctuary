pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./Pausable.sol";


contract MacToken is Context, ERC20, Pausable {
    
    uint256 private _cap;
    
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 cap) ERC20(name,symbol,decimals) public {
         require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        require(!paused(), "ERC20Pausable: token transfer while paused");

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    
    function mint(address account, uint256 amount) public virtual {
        _mint(account, amount);
    }
    
    function pause() public virtual {
        super._pause();
    }

    function unpause() public virtual {
        super._unpause();
    }

}





