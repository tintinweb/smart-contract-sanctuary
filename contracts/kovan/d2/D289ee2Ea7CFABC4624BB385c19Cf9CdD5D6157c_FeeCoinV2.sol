// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";


// NOTE testing fees
// It works, but like shit, I cant use it on uniswap
contract FeeCoinV2 is IERC20, IERC20Metadata {
	
	mapping (address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	
	string private _name;
	string private _symbol;
	uint8 private _decimals = 18;
	uint256 private _totalSupply;
	uint256 private _txFee = 5; // 5%

	address public burnAddress = 0x000000000000000000000000000000000000dEaD;
	
	constructor(string memory name_, string memory symbol_, uint256 supply_) {
		_name = name_;
		_symbol = symbol_;
		_mint(msg.sender, supply_);
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}
	
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(
		address owner, address spender
	) external view override returns (uint256) {
		return _allowances[owner][spender];
	}
	
	// NOTE why its an override?
	function approve(
		address spender, uint256 amount
	) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
	) external override returns (bool) {
		_transfer(sender, recipient, amount);
		uint256 currentAllowance = _allowances[sender][msg.sender];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, msg.sender, currentAllowance - amount);
		}
		return true;
	}

	function increaseAllowance(
		address spender, uint256 addedValue
	) public virtual returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
		address spender, uint256 subtractedValue
	) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

// IMPLEMENT THE TX FEE -------------------------------------------------------------
// I think that "the blockchain" detects if you have made an tx with the event Transfer
// so theres no need for complicated logic: you can do the tx fee in any way.
	function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
		_zeroAddressChecks(sender, recipient);
		uint256 fee = getFee(amount);
		_pureTransfer(sender, recipient, amount - fee);
		_burnFee(sender, recipient, fee);
        //_afterTokenTransfer(sender, recipient, amount);
    }

	
	// Test if all this modularization works on dexes
	function _zeroAddressChecks(
		address sender, address recipient
	) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
	}

	function getFee(
		uint256 amountTransacted
	) public returns(uint256) {
		return (amountTransacted * _txFee)/100;
	}

	function _pureTransfer(
        address sender,
        address recipient,
        uint256 amount
	) internal virtual {
		uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[sender] = senderBalance - amount;
		}
		_balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

	}
// ---------------------------------------------------------------------------------

	function _burnFee(
		address sender,
		address recipient,
		uint256 fee
	) internal virtual {
		_pureTransfer(sender, burnAddress, fee);
	}

	function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "ERC20: mint to the zero address");
		_totalSupply += amount;
		_balances[to] += amount;
		emit Transfer(burnAddress, to, amount);
	}

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	

	
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}