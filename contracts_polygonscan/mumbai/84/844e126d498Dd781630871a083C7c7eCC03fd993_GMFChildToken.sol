// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract GMFChildToken is ERC20, Ownable {

    // keeping it for checking, whether deposit being called by valid address or not
    address public childChainManagerProxy;

    address public feeAddress;
    uint16 public feePercent;

    constructor(address _childChainManagerProxy, address _feeAddress, uint16 _feePercent) ERC20("GemFi.vip", "GMF") {
        childChainManagerProxy = _childChainManagerProxy;
        feeAddress = _feeAddress;
        feePercent = _feePercent;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        uint256 fee = amount * feePercent / 10000;
        _transfer(_msgSender(), feeAddress, fee);
        _burn(_msgSender(), amount - fee);
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "GMFToken: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        uint256 fee = amount * feePercent / 10000;
        _transfer(_msgSender(), feeAddress, fee);
        _burn(account, amount);
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner {
        require(newChildChainManagerProxy != address(0), "GMFToken: Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateFeePercent(uint16 _percent) external onlyOwner {
        require(_percent <= 600, "GMFToken: input value is more than 6%");
        require(_percent >= 100, "GMFToken: Input value is less than 1%");
        feePercent = _percent;
    }

    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "GMFToken: You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

}