// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistryInterface Interface
 */
interface IRegistry {
	function logic(address logicAddr) external view returns (bool);

	function implementation(bytes32 key) external view returns (address);

	function notAllowed(address erc20) external view returns (bool);

	function deployWallet() external returns (address);

	function wallets(address user) external view returns (address);

	function getFee() external view returns (uint256);

	function feeRecipient() external view returns (address);

	function memoryAddr() external view returns (address);

	function distributionContract(address token)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {
	event LogMint(address indexed erc20, uint256 tokenAmt);
	event LogRedeem(address indexed erc20, uint256 tokenAmt);
	event LogBorrow(address indexed erc20, uint256 tokenAmt);
	event LogPayback(address indexed erc20, uint256 tokenAmt);
	event LogDeposit(address indexed erc20, uint256 tokenAmt);
	event LogWithdraw(address indexed erc20, uint256 tokenAmt);
	event LogSwap(address indexed src, address indexed dest, uint256 amount);
	event LogLiquidityAdd(
		address indexed tokenA,
		address indexed tokenB,
		uint256 amountA,
		uint256 amountB
	);
	event LogLiquidityRemove(
		address indexed tokenA,
		address indexed tokenB,
		uint256 amountA,
		uint256 amountB
	);
	event VaultDeposit(address indexed erc20, uint256 tokenAmt);
	event VaultWithdraw(address indexed erc20, uint256 tokenAmt);
	event VaultClaim(address indexed erc20, uint256 tokenAmt);
	event DelegateAdded(address delegate);
	event DelegateRemoved(address delegate);

	function executeMetaTransaction(bytes memory sign, bytes memory data)
		external;

	function execute(address[] calldata targets, bytes[] calldata datas)
		external
		payable;

	function owner() external view returns (address);

	function registry() external view returns (address);

	function DELEGATE_ROLE() external view returns (bytes32);

	function hasRole(bytes32, address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRegistry.sol";
import "../interfaces/IWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferLogic {
	event LogDeposit(address indexed erc20, uint256 tokenAmt);
	event LogWithdraw(address indexed erc20, uint256 tokenAmt);

	/**
	 * @dev get ethereum address
	 */
	function getAddressETH() public pure returns (address eth) {
		eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	}

	/**
	 * @dev Deposit ERC20 from user
	 * @dev user must approve token transfer first
	 */
	function deposit(address erc20, uint256 amount) external payable {
		require(amount > 0, "ZERO-AMOUNT");
		if (erc20 != getAddressETH()) {
			IERC20(erc20).transferFrom(msg.sender, address(this), amount);
		}

		emit LogDeposit(erc20, amount);
	}

	/**
	 * @dev Withdraw ETH/ERC20 to user
	 */
	function withdraw(address erc20, uint256 amount) external {
		address registry = IWallet(address(this)).registry();
		bool isNotAllowed = IRegistry(registry).notAllowed(erc20);

		require(!isNotAllowed, "Token withdraw not allowed");
		uint256 withdrawAmt = amount;

		if (erc20 == getAddressETH()) {
			uint256 srcBal = address(this).balance;
			if (amount > srcBal) {
				withdrawAmt = srcBal;
			}
			payable(msg.sender).transfer(withdrawAmt);
		} else {
			IERC20 erc20Contract = IERC20(erc20);
			uint256 srcBal = erc20Contract.balanceOf(address(this));
			if (amount > srcBal) {
				withdrawAmt = srcBal;
			}
			erc20Contract.transfer(msg.sender, withdrawAmt);
		}

		emit LogWithdraw(erc20, amount);
	}

	/**
	 * @dev Remove ERC20 approval to certain target
	 */
	function removeApproval(address erc20, address target) external {
		if (erc20 != getAddressETH()) {
			IERC20(erc20).approve(target, 0);
		}
	}
}