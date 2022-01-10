// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Interfaces.sol";

contract VXG is IVXG {
	uint version; // = 0;

	address public owner;

	uint public totalSupply;

	mapping (address => uint) private balances;
	mapping (address => mapping (address => uint)) private allowances;
	mapping (address => bool) public minters;

	address immutable private initializerAddress;

	constructor() {
		initializerAddress = msg.sender;
		initialize();
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "VXG Token: You must be the contract owner to use this function!");
		_;
	}

	function initialize() public {
		require(msg.sender == initializerAddress, "VXG Token: Access denied!");
		require(version == 0, "VXG Token: Trying to initialize from a wrong version!");
		version = 1;
		owner = msg.sender;
	}

	// INTERNAL FUNCTIONS

	function _transfer(address _from, address _to, uint _value) internal {
		balances[_from] -= _value;
		balances[_to] += _value;
		emit Transfer(_from, _to, _value);
	}

	function _approve(address _owner, address _spender, uint _value) internal {
		allowances[_owner][_spender] = _value;
		emit Approval(_owner, _spender, _value);
	}

	function _mint(address _to, uint _amount) internal {
		balances[_to] += _amount;
		totalSupply += _amount;
		emit Transfer(address(0), _to, _amount);
	}

	function _burn(address _from, uint _amount) internal {
		balances[_from] -= _amount;
		totalSupply -= _amount;
		emit Transfer(_from, address(0), _amount);
	}

	// EXTERNAL FUNCTIONS

	function name() external pure returns (string memory) {
		return "Venture X Gaming testnet token 0x0003";
	}

	function symbol() external pure returns (string memory) {
		return "VXG-0x0003";
	}

	function decimals() external pure returns (uint8) {
		return 18;
	}

	function balanceOf(address _owner) external view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) external returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
		_approve(_from, _to, allowances[_from][msg.sender] - _value);
		_transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) external returns (bool success) {
		_approve(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	function increaseAllowance(address _spender, uint _value) external returns (uint finalAllowance) {
		finalAllowance = allowances[msg.sender][_spender] + _value;
		_approve(msg.sender, _spender, finalAllowance);
	}

	function decreaseAllowance(address _spender, uint _value) external returns (uint finalAllowance) {
		uint _allowance = allowances[msg.sender][_spender];
		unchecked {
			finalAllowance = _allowance > _value ? _allowance - _value : 0;
		}
		_approve(msg.sender, _spender, finalAllowance);
		return finalAllowance;
	}

	function mint(address _to, uint _value) external {
		require(minters[msg.sender], "VXG Token: You need to be a minter to use this function!");
		_mint(_to, _value);
	}

	function burn(uint _value) external {
		_burn(msg.sender, _value);
	}

	// MODERATOR FUNCTIONS

	function transferOwnership(address newOwner) external onlyOwner {
		owner = newOwner;
		emit OwnershipTransferred(msg.sender, newOwner);
	}

	function addMinter(address minter) onlyOwner external {
		minters[minter] = true;
		emit MinterAdded(minter);
	}

	function removeMinter(address minter) onlyOwner external {
		minters[minter] = false;
		emit MinterRemoved(minter);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

struct option {
	uint value;
	uint fee;
}

struct forcedWithdrawal {
	uint40 timestamp;
	uint216 amount;
}

struct balanceChange {
	address addr;
	int balance_change;
}

struct withdrawal {
	address addr;
	uint withdrawing_balance;
}

interface IVXG is IERC20Metadata {
	function increaseAllowance(address _spender, uint _value) external returns (uint finalAllowance);
	function decreaseAllowance(address _spender, uint _value) external returns (uint finalAllowance);
	function minters(address minter) external returns (bool isMinter);
	function mint(address _to, uint _value) external;
	function burn(uint _value) external;
	function addMinter(address minter) external;
	function removeMinter(address minter) external;

	event MinterAdded(address indexed minter);
	event MinterRemoved(address indexed minter);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IPresale {
    function getTokens(uint amountPaid) external;
}

interface IGamePoolUSDC {
	function depositFundsUSDC(uint _value) external;
	function prepareForcedWithdrawal() external;
	function forceWithdraw() external;
	function withdrawVXG() external;
	function withdrawUSDC() external;
	function withdraw() external;
	function transferOwnership(address newOwner) external;
	function addOperator(address operator) external;
	function removeOperator(address operator) external;
	function fetch(
		balanceChange[] calldata USDCbalanceChanges,
		balanceChange[] calldata VXGbalanceChanges,
		withdrawal[] calldata withdrawals
	) external;

	function USDC() external view returns (IERC20 USDC);
	function VXG() external view returns (IVXG VXG);
	function withdrawalTime() external view returns (uint withdrawalTime);
	function owner() external view returns (address owner);

	function operators(address who) external view returns (bool isOperator);
	function USDCbalance(address account) external view returns (uint balance);
	function VXGbalance(address account) external view returns (uint balance);
	function forcedWithdrawalOf(address account) external view returns (forcedWithdrawal memory withdrawal);
	function readyWithdrawalOf(address account) external view returns (uint readyWithdrawal);

	event Fetch(
		balanceChange[] USDCbalanceChanges,
		balanceChange[] VXGbalanceChanges,
		withdrawal[] withdrawals
	);
	event ForcedWithdrawalRequested(address indexed who, uint value);
	event ForcedWithdrawalPerformed(address indexed who, uint value);
	event WithdrawalAllowed(address indexed who, uint value);
	event USDCWithdrawal(address indexed who, uint value);
	event VXGWithdrawal(address indexed who, uint value);
	event FundsDeposited(address indexed who, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event OperatorAdded(address indexed operator);
	event OperatorRemoved(address indexed operator);
}

interface IRinkebyUSDC is IERC20Metadata {
	function mint(address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
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