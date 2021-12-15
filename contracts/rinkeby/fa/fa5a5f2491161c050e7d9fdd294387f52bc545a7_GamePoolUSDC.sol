/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/GamePoolUSDC.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.10;

struct option {
	uint value;
	uint fee;
}

struct forcedWithdrawal {
	uint40 timestamp;
	uint216 amount;
}

struct balanceChange {
	uint40 id;
	int216 balanceChange;
}

struct withdrawal {
	uint40 id;
	uint216 withdrawingBalance;
}




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/GamePoolUSDC.sol
*/
            
//    WORK IN PROGRESS

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.10;

////import "./Structs.sol";
////import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVXG_ERC20 is IERC20 {
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function increaseAllowance(address _spender, uint _value) external returns (uint finalAllowance);
	function decreaseAllowance(address _spender, uint _value) external returns (uint finalAllowance);
	function minters(address minter) external returns (bool isMinter);
	function mint(address _to, uint _value) external;
	function burn(uint _value) external;
	function addMinter(address minter) external;
	function removeMinter(address minter) external;
}

interface IPresale {
    function getTokens(uint amountPaid) external;
}

interface IGamePoolUSDC {
	// function addFundsERC20(uint _value) external;
	// function prepareWithdrawal(uint amount) external;
	// function withdrawFundsERC20() external;
	// function logGame(address playerWinner, address playerLoser, uint8 stake) external;
}


/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/GamePoolUSDC.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.10;

/**

We assume that:
- no one will ever have more than type(int128).max VXG or USDC tokens
- all operator addresses and the owner address are safe and trusted
- timestamp and the number of players are lower than type(uint40).max

 */

////import "./Interfaces.sol";
////import "./Structs.sol";

contract GamePoolUSDC is IGamePoolUSDC {
	IERC20 immutable public  USDC;
	IVXG_ERC20 immutable public VXG;
	uint immutable public withdrawalTime;

	address public owner;

	mapping (address => bool) public operators;
	mapping (address => uint) public id; // They start from 1 to distinguish from unregistered players
	mapping (uint => uint) public USDCbalances;
	mapping (uint => uint) public VXGbalances;
	mapping (uint => forcedWithdrawal) public forcedWithdrawals;
	mapping (uint => uint) public readyWithdrawals;

	address[] public account;

	modifier onlyOwner() {
		require(msg.sender == owner, "GamePoolUSDC: You must be the contract owner to use this function!");
		_;
	}

	constructor(address _VXG, address _paymentToken, uint _withdrawalTime) {
		owner = msg.sender;
		VXG = IVXG_ERC20(_VXG);
		withdrawalTime = _withdrawalTime;
		USDC = IERC20(_paymentToken);
		account.push(address(0));
	}

	function addFundsUSDC(uint _value) external {
		uint _id = id[msg.sender];
		if (_id == 0) {
			_id = account.length;
			account.push(msg.sender);
			id[msg.sender] = _id;
		}
		require(USDC.transferFrom(msg.sender, address(this), _value));
		USDCbalances[_id] += _value;
	}

	function prepareForcedWithdrawal() external {
		uint _id = id[msg.sender];
		uint _amount = USDCbalances[_id] + forcedWithdrawals[_id].amount;
		USDCbalances[_id] = 0;

		forcedWithdrawal memory w;
		w.timestamp = uint40(block.timestamp);
		w.amount = uint216(_amount);

		forcedWithdrawals[_id] = w;
	}

	function forceWithdraw() external {
		uint _id = id[msg.sender];
		require(uint40(block.timestamp) - forcedWithdrawals[_id].timestamp >= withdrawalTime, "GamePoolUSDC: Can't withdraw your tokens yet!");
		uint _amount = forcedWithdrawals[_id].amount;
		forcedWithdrawal memory w;
		forcedWithdrawals[_id] = w; // zeroing withdrawal 

		require(USDC.transfer(msg.sender, _amount));
	}

	function withdrawVXG() external {
		uint _id = id[msg.sender];
		uint balance = VXGbalances[_id];
		VXGbalances[_id] = 0;
		VXG.mint(msg.sender, balance);
	}

	function withdrawUSDC() external {
		uint _id = id[msg.sender];
		uint balance = USDCbalances[_id];
		USDCbalances[_id] = 0;
		require(USDC.transfer(msg.sender, balance));
	}

	function withdraw() external {
		uint _id = id[msg.sender];
		uint VXGbalance = VXGbalances[_id];
		VXGbalances[_id] = 0;
		VXG.mint(msg.sender, VXGbalance);

		uint USDCbalance = USDCbalances[_id];
		USDCbalances[_id] = 0;
		require(USDC.transfer(msg.sender, USDCbalance));
	}

	function transferOwnership(address newOwner) external onlyOwner{
		owner = newOwner;
	}

	function addOperator(address operator) external onlyOwner {
		operators[operator] = true;
	}

	function deleteOperator(address operator) external onlyOwner {
		operators[operator] = false;
	}

	function fetch(balanceChange[] calldata USDCbalanceChanges, balanceChange[] calldata VXGbalanceChanges, withdrawal[] calldata withdrawals) external {
		require(operators[msg.sender], "GamePoolUSDC: Only VXG operator can call this function!");
		int changeSum = 0;
		for (uint i = 0; i < USDCbalanceChanges.length; i++) {
			changeSum += USDCbalanceChanges[i].balanceChange;

			uint balance = USDCbalances[USDCbalanceChanges[i].id];
			if (USDCbalanceChanges[i].balanceChange + int216(uint216(balance)) < 0) {
				uint216 forcedValue = forcedWithdrawals[USDCbalanceChanges[i].id].amount;
				require(USDCbalanceChanges[i].balanceChange + int216(uint216(balance)) + int216(forcedValue) >= 0, "Panic: GamePoolUSDC: Not enough funds to take!");
				forcedWithdrawals[USDCbalanceChanges[i].id] = forcedWithdrawal(0, 0);
				balance += forcedValue;
			}
			USDCbalances[USDCbalanceChanges[i].id] = uint(int(int216(uint216(balance)) + USDCbalanceChanges[i].balanceChange));
		}

		require(changeSum == 0, "Panic: GamePoolUSDC: Can't burn or mint USDC within this contract!");

		for (uint i = 0; i < VXGbalanceChanges.length; i++) {
			require(VXGbalanceChanges[i].balanceChange > 0, "Panic: GamePoolUSDC: Can't decrease VXG balance on fetch!");
			VXGbalances[VXGbalanceChanges[i].id] = uint(int(VXGbalanceChanges[i].balanceChange + int216(int(VXGbalances[VXGbalanceChanges[i].id]))));
		}

		for (uint i = 0; i < withdrawals.length; i++) {
			USDCbalances[withdrawals[i].id] -= withdrawals[i].withdrawingBalance;
			readyWithdrawals[withdrawals[i].id] += withdrawals[i].withdrawingBalance;
		}
	}
}