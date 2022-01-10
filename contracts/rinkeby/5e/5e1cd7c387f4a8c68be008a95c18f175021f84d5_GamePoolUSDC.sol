// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**

We assume that:
- no one will ever have more than type(int216).max VXG or USDC tokens
- all operator addresses and the owner address are safely managed and trusted
- timestamp is lower than type(uint40).max

*/

import "./Interfaces.sol";

contract GamePoolUSDC is IGamePoolUSDC {
	uint version; // = 0;

	IERC20 immutable public USDC;
	IVXG immutable public VXG;
	uint immutable public withdrawalTime;
	uint private inNonReentrantFunction;

	address public owner;

	mapping (address => bool) public operators;
	mapping (address => uint) public USDCbalance;
	mapping (address => uint) public VXGbalance;
	mapping (address => forcedWithdrawal) private forcedWithdrawals;
	mapping (address => uint) private readyWithdrawals;

	address immutable private initializerAddress;

	modifier onlyOwner() {
		require(msg.sender == owner, "GamePoolUSDC: You must be the contract owner to use this function!");
		_;
	}

	modifier nonReentrant() {
		uint desiredState = inNonReentrantFunction + 1;
		inNonReentrantFunction = desiredState;
		_;
		require(inNonReentrantFunction == desiredState, "GamePoolUSDC: Reentrancy not allowed!");
	}

	constructor(address _VXG, address _USDC, uint _withdrawalTime) {
		initializerAddress = msg.sender;
		VXG = IVXG(_VXG);
		USDC = IERC20(_USDC);
		withdrawalTime = _withdrawalTime;
		initialize();
	}

	function initialize() public {
		require(msg.sender == initializerAddress, "GamePoolUSDC: Access denied!s");
		require(version == 0, "GamePoolUSDC: Trying to initialize from a wrong version!");
		version = 1;
		owner = msg.sender;
	}

	function forcedWithdrawalOf(address account) external view returns (forcedWithdrawal memory w) {
		w = forcedWithdrawals[account];
	}

	function readyWithdrawalOf(address account) external view returns (uint readyWithdrawal) {
		return readyWithdrawals[account];
	}

	function depositFundsUSDC(uint _value) external {
		require(USDC.transferFrom(msg.sender, address(this), _value), "GamePoolUSDC: transferFrom(...) failed!");
		USDCbalance[msg.sender] += _value;

		emit FundsDeposited(msg.sender, _value);
	}

	function prepareForcedWithdrawal() external {
		uint _amount = USDCbalance[msg.sender];
		// 1 is left not to force the operator to pay larger gas fees when cancelling forced withdrawals
		// the operator makes the forcedWithdrawal slot zero and receives the refund
		// the zeroness of USDCbalance[addr] doesn't change during cancellation
		require(_amount > 1, "GamePoolUSDC: Not enough funds!");
		_amount = _amount + forcedWithdrawals[msg.sender].amount - 1;
		USDCbalance[msg.sender] = 1;

		forcedWithdrawal memory w;
		w.timestamp = uint40(block.timestamp);
		w.amount = uint216(_amount);

		forcedWithdrawals[msg.sender] = w;

		emit ForcedWithdrawalRequested(msg.sender, _amount);
	}

	function forceWithdraw() external {
		require(uint40(block.timestamp) - forcedWithdrawals[msg.sender].timestamp >= withdrawalTime, "GamePoolUSDC: Can't withdraw your tokens yet!");
		uint _amount = forcedWithdrawals[msg.sender].amount;
		forcedWithdrawal memory w;
		forcedWithdrawals[msg.sender] = w; // zeroing withdrawal

		require(USDC.transfer(msg.sender, _amount), "GamePoolUSDC: transfer(...) failed!");

		emit ForcedWithdrawalPerformed(msg.sender, _amount);
	}

	function withdrawVXG() public {
		uint _amount = VXGbalance[msg.sender];
		VXGbalance[msg.sender] = 0;
		VXG.mint(msg.sender, _amount);

		emit VXGWithdrawal(msg.sender, _amount);
	}

	function withdrawUSDC() public {
		uint _amount = readyWithdrawals[msg.sender];
		readyWithdrawals[msg.sender] = 0;
		require(USDC.transfer(msg.sender, _amount), "GamePoolUSDC: transfer(...) failed!");

		emit USDCWithdrawal(msg.sender, _amount);
	}

	function withdraw() external {
		withdrawVXG();
		withdrawUSDC();
	}

	function transferOwnership(address newOwner) external onlyOwner{
		require(newOwner != address(0), "GamePoolUSDC: Can't transfer ownership to address(0)!");
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	function addOperator(address operator) external onlyOwner {
		operators[operator] = true;
		emit OperatorAdded(operator);
	}

	function removeOperator(address operator) external onlyOwner {
		operators[operator] = false;
		emit OperatorRemoved(operator);
	}

	function fetch(
		balanceChange[] calldata USDCbalanceChanges,
		balanceChange[] calldata VXGbalanceChanges,
		withdrawal[] calldata withdrawals
	) nonReentrant external {
		require(operators[msg.sender], "GamePoolUSDC: Only VXG operator can call this function!");
		int changeSum = 0;
		for (uint i = 0; i < USDCbalanceChanges.length; i++) {
			changeSum += USDCbalanceChanges[i].balance_change;

			uint balance = USDCbalance[USDCbalanceChanges[i].addr];
			if (USDCbalanceChanges[i].balance_change + int(balance) < 0) {
				uint forcedValue = forcedWithdrawals[USDCbalanceChanges[i].addr].amount;
				require(USDCbalanceChanges[i].balance_change + int(balance) + int(forcedValue) >= 0, "Panic! GamePoolUSDC: Not enough funds to take!");
				forcedWithdrawals[USDCbalanceChanges[i].addr] = forcedWithdrawal(0, 0);
				balance += forcedValue;
			}
			USDCbalance[USDCbalanceChanges[i].addr] = uint(int(balance) + USDCbalanceChanges[i].balance_change);
		}

		require(changeSum == 0, "Panic! GamePoolUSDC: Can't burn or mint USDC within this contract!");

		for (uint i = 0; i < VXGbalanceChanges.length; i++) {
			require(VXGbalanceChanges[i].balance_change > 0, "Panic! GamePoolUSDC: Can't decrease VXG balance on fetch!");
			VXGbalance[VXGbalanceChanges[i].addr] = uint(int(VXGbalanceChanges[i].balance_change + int216(int(VXGbalance[VXGbalanceChanges[i].addr]))));
		}

		for (uint i = 0; i < withdrawals.length; i++) {
			USDCbalance[withdrawals[i].addr] -= withdrawals[i].withdrawing_balance;
			readyWithdrawals[withdrawals[i].addr] += withdrawals[i].withdrawing_balance;

			emit WithdrawalAllowed(withdrawals[i].addr, withdrawals[i].withdrawing_balance);
		}

		emit Fetch(USDCbalanceChanges, VXGbalanceChanges, withdrawals);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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