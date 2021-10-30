/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Cad.sol



/*

- check all types of visibility for variables and functions 

- function to revoke approval

- set variable for requiredNb of Approvals -> setter + getter

- getter + setter for Request variables?

- restrictions on token to buy (ex: no ETH etc) ?

*/

pragma solidity ^0.8.0;




contract Cad is Ownable {

	struct S_Requests {
		uint id;
		address applicant;
		address token;
		uint amountToBuy;
		string message;
		address[] approvals;
		bool approved;
	}

	S_Requests[] private allRequests;
	address[] private whitelist;
	uint private nbWhitelist;

	mapping(address => uint) private wlBalances;

	IUniswapV2Router02 private router;

	event AddToWhitelist(address userAddress);
	event RemoveFromWhitelist(address userAddress);
	event DepositFunds(address userAddress, uint amount);
	event WithdrawFunds(address userAddress, uint amount);
	event RequestBuy(uint id, address applicant, address token, uint amountToBuy, string message);
	event ApproveRequest(uint id, address userAddress);
	event FinalizeRequest(uint id);

	/////////////////////////////////////

	// use setter + getter in the future or mappings to store all DEX
	constructor(address routerAddress) {
		router = IUniswapV2Router02(routerAddress);
	}

	/////////////////////////////////////

	modifier onlyWhitelist() {
		require(isWhitelisted(_msgSender()) == true, "Address isn't whitelisted");
		_;
	}

	modifier onlyValidId(uint id) {
		require(id < allRequests.length && id >= 0, "Invalid request ID");
		_;
	}
	
	/////////////////////////////////////

	function getWhitelistedAddresses() public view returns (address[] memory) {
		return whitelist;
	}

	function getNbWhitelist() public view returns (uint) {
		return nbWhitelist;
	}

	function getAddrBalance(address userAddress) public view returns (uint) {
		return wlBalances[userAddress];
	}

	function getRequestInfo(uint id) public view returns (uint, address, address, uint, string memory, address[] memory, bool) {
		return (allRequests[id].id, allRequests[id].applicant, allRequests[id].token, allRequests[id].amountToBuy, allRequests[id].message, allRequests[id].approvals, allRequests[id].approved);
	}

	// useless function? Better to use return values from getRequestInfo?
	function getApprovedStatus(uint id) private view returns (bool) {
		// CHANGE THIS VALUE !!!
		// CHANGE THIS VALUE !!!
		if (allRequests[id].approvals.length >= 0)
			return true;
		return false;
	}

	function getContractBalance() private view returns (uint) {
		return address(this).balance;
	}

	function setNbWhitelist(uint newNbWhitelist) private {
		nbWhitelist = newNbWhitelist;
	}

	function setAddrBalance(address userAddress, uint amount) private {
		wlBalances[userAddress] = amount;
	}

	/////////////////////////////////////

	function addToWhitelist(address userAddress) public onlyOwner {
		require(isWhitelisted(userAddress) == false, "Already whitelisted");
		whitelist.push(userAddress);
		setNbWhitelist(getNbWhitelist() + 1);
		emit AddToWhitelist(userAddress);
	}

	function removeFromWhitelist(address userAddress) public onlyOwner {
		require(isWhitelisted(userAddress) == true, "Not whitelisted");
		for (uint i = 0; i < getNbWhitelist(); i++) {
			if (whitelist[i] == userAddress)
				whitelist[i] = whitelist[getNbWhitelist() - 1];
		}
		whitelist.pop();
		setNbWhitelist(getNbWhitelist() - 1);
		emit RemoveFromWhitelist(userAddress);
	}

	function isWhitelisted(address userAddress) public view returns (bool) {
		for (uint i = 0; i < getNbWhitelist(); i++) {
			if (whitelist[i] == userAddress)
				return true;
		}
		return false;
	}

	/////////////////////////////////////

	function depositFunds() payable public onlyWhitelist {
		setAddrBalance(_msgSender(), getAddrBalance(_msgSender()) + msg.value);
		emit DepositFunds(_msgSender(), msg.value);
	}

	function withdrawFunds(uint amount) public onlyWhitelist {
		require(amount <= getAddrBalance(_msgSender()), "Balance too low");
		payable(_msgSender()).transfer(amount);
		setAddrBalance(_msgSender(), getAddrBalance(_msgSender()) - amount);
		emit WithdrawFunds(_msgSender(), amount);
	}

	/////////////////////////////////////

	function requestBuy(address token, uint amountToBuy, string memory message) public onlyWhitelist {
		S_Requests memory newRequest = S_Requests(allRequests.length, _msgSender(), token, amountToBuy, message, new address[](0), false);
		allRequests.push(newRequest);
		emit RequestBuy(allRequests.length, _msgSender(), token, amountToBuy, message);
	}

	function approveRequest(uint id) public onlyWhitelist onlyValidId(id) {
		require(_msgSender() != allRequests[id].applicant, "Applicant can't approve his own request");
		require(checkAlreadyApproved(id, _msgSender()) == false, "This address has already approved");
		allRequests[id].approvals.push(_msgSender());
		emit ApproveRequest(id, _msgSender());
	}

	function checkAlreadyApproved(uint id, address userAddress) private view returns (bool) {
		for (uint i = 0; i < allRequests[id].approvals.length; i++) {
			if (allRequests[id].approvals[i] == userAddress)
				return true;
		}
		return false;
	}

	function finalizeRequestAndBuy(uint id) public onlyWhitelist onlyValidId(id) {
		require(getContractBalance() >= allRequests[id].amountToBuy, "Contract balance is too low");
		require(getApprovedStatus(id) == true, "Not enough approvals");
		routerTransfer(allRequests[id].token, allRequests[id].amountToBuy);
		allRequests[id].approved = true;
		emit FinalizeRequest(id);
	}

	function routerTransfer(address token, uint buyAmount) public onlyWhitelist {
		address[] memory path = new address[](2);
        path[0] = token;
		path[1] = router.WETH();

		IERC20 entryToken = IERC20(token);
		entryToken.approve(address(router), 115792089237316195423570985008687907853269984665640564039457584007913129639935);

		// msg.sender should have already given the router an allowance of at least amountIn on the input token.
        router.swapExactTokensForTokens(buyAmount, 0, path, address(this), block.timestamp + 300); // remove + 300 ?
	}

}