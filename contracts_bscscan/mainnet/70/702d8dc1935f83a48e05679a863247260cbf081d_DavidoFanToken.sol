// SPDX-License-Identifier: MIT
pragma solidity =0.7.0;
import "./BEP20Pausable.sol";
import "./BEP20.sol";
import "./IBEP20.sol";

import "./SafeMath.sol";
import "./SafeBEP20.sol";

contract DavidoFanToken is BEP20Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 private _price;

    constructor() BEP20("Davido Fan Token", "DVDO", 9, 1000000000000000000000) {}

    function withdrawTokens() public virtual onlyOwner{
        address contractAddress = address(this);
        uint tokenBalance = balanceOf(contractAddress);
        _transfer(contractAddress,owner,tokenBalance);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {BEP20-_burn} and {BEP20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            "BEP20: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function withdraw(address tokenAddress) external onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
    }


}