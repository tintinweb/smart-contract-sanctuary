/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

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

// File: Daijobu.sol



/*

- check all types of visibility for variables and functions 

- function to revoke approval -> me no comprendo ????

- restrictions on token to buy (ex: no ETH etc) ?

- need to multiply approve * WL addresses

- use WETH/WBNB/WFTM instead of stablecoin? Lower gas? Ask community

- setter/getter slippage ?

*/

pragma solidity ^0.8.0;




contract Daijobu is Ownable {

	struct S_Requests {
		uint id;
		address applicant;
		address tokenToBuy;
		uint buyAmount;
		string routerName;
		string message;
		address[] approvals;
		bool approved;
	}

	S_Requests[] private allRequests;

	address[] private whitelist;
	uint private nbWhitelist;

	uint private requiredNbApprovals;

	mapping(address => uint) private balances;

	IERC20 private depositToken;

	mapping(string => IUniswapV2Router02) private routers;
	string[] private routersNames;

	event AddToWhitelist(address userAddress);
	event RemoveFromWhitelist(address userAddress);
	event DepositFunds(address userAddress, uint amount);
	event WithdrawFunds(address userAddress, uint amount);
	event BuyRequest(uint id, address applicant, address tokenToBuy, uint buyAmount, string message);
	event ApproveRequest(uint id, address userAddress);
	event FinalizeRequest(uint id);

	/////////////////////////////////////

	modifier onlyWhitelist() {
		require(isWhitelisted(_msgSender()) != -1, "Address isn't whitelisted.");
		_;
	}

	modifier onlyValidId(uint id) {
		require(id < allRequests.length && id >= 0, "Invalid request ID.");
		_;
	}

	/////////////////////////////////////

	constructor(address depositTokenAddress) {
		depositToken = IERC20(depositTokenAddress);
		setRequiredNbApprovals(2);
	}

	/////////////////////////////////////

	function getRequestInfo(uint id) public view returns (S_Requests memory) {
		return allRequests[id];
	}

	function getWhitelistAddress(uint i) private view returns (address) {
		return whitelist[i];
	}

	function getWhitelistAddresses() public view returns (address[] memory) {
		return whitelist;
	}

	function getNbWhitelist() private view returns (uint) {
		return nbWhitelist;
	}

	function getRequiredNbApprovals() public view returns (uint) {
		return requiredNbApprovals;
	}

	function getAddressBalance(address userAddress) public view returns (uint) {
		return balances[userAddress];
	}

	function getRouter(string memory routerName) private view returns (IUniswapV2Router02) {
		return routers[routerName];
	}

	function getRoutersNames() public view returns (string[] memory) {
		return routersNames;
	}

	// useless function? Better to use return values from getRequestInfo?
	function getApprovedStatus(uint id) private view returns (bool) {
		if (allRequests[id].approvals.length >= getRequiredNbApprovals())
			return true;
		return false;
	}

	/*
	function getContractBalance() private view returns (uint) {
		return address(this).balance;
	}
	*/

	/////////////////////////////////////

	// useless -> only used once
	function setWhitelistAddress(uint i, address userAddress) private {
		whitelist[i] = userAddress;
	}

	function setNbWhitelist(uint newNbWhitelist) private {
		nbWhitelist = newNbWhitelist;
	}

	function setRequiredNbApprovals(uint _requiredNbApprovals) public onlyOwner {
		requiredNbApprovals = _requiredNbApprovals;
	}

	function setAddressBalance(address userAddress, uint newBalance) private {
		balances[userAddress] = newBalance;
	}

	function setRouter(string memory routerName, address routerAddress) public onlyOwner {
		require(address(getRouter(routerName)) == address(0), "Router already exists.");
		routers[routerName] = IUniswapV2Router02(routerAddress);
		routersNames.push(routerName);
	}

	/////////////////////////////////////

	function addToWhitelist(address userAddress) public onlyOwner {
		require(isWhitelisted(userAddress) == -1, "Already whitelisted.");
		whitelist.push(userAddress);
		setNbWhitelist(getNbWhitelist() + 1);
		emit AddToWhitelist(userAddress);
	}

	function removeFromWhitelist(address userAddress) public onlyOwner {
		int index = isWhitelisted(userAddress);
		if (index != -1) {
			withdrawFundsRemovedFromWl(userAddress, getAddressBalance(userAddress));
			setWhitelistAddress(uint(index), getWhitelistAddress(getNbWhitelist() - 1));
			whitelist.pop();
			setNbWhitelist(getNbWhitelist() - 1);
			emit RemoveFromWhitelist(userAddress);
		}
	}

	function isWhitelisted(address userAddress) private view returns (int) {
		for (uint i = 0; i < getNbWhitelist(); i++) {
			if (getWhitelistAddress(i) == userAddress)
				return int(i);
		}
		return -1;
	}

	/////////////////////////////////////

	/*
	function depositFunds() payable public onlyWhitelist {
		setAddrBalance(_msgSender(), getAddrBalance(_msgSender()) + msg.value);
		emit DepositFunds(_msgSender(), msg.value);
	}
	*/

	/*
	function withdrawFunds(uint amount) public onlyWhitelist {
		require(amount <= getAddrBalance(_msgSender()), "Balance too low");
		payable(_msgSender()).transfer(amount);
		setAddrBalance(_msgSender(), getAddrBalance(_msgSender()) - amount);
		emit WithdrawFunds(_msgSender(), amount);
	}
	*/

	// user has to manually approve the fundsToken before calling this!!
	function depositFunds(uint amount) public onlyWhitelist {
		depositToken.transferFrom(_msgSender(), address(this), amount);
		setAddressBalance(_msgSender(), getAddressBalance(_msgSender()) + amount);
		emit DepositFunds(_msgSender(), amount);
	}

	function withdrawFunds(uint amount) public onlyWhitelist {
		require(amount <= getAddressBalance(_msgSender()), "Can't withdraw more than your balance.");
		depositToken.transfer(_msgSender(), amount);
		setAddressBalance(_msgSender(), getAddressBalance(_msgSender()) - amount);
		emit WithdrawFunds(_msgSender(), amount);
	}

	function withdrawFundsRemovedFromWl(address userAddress, uint amount) private onlyOwner {
		depositToken.transfer(userAddress, amount);
		setAddressBalance(userAddress, getAddressBalance(userAddress) - amount);
		// emit WithdrawFunds(_msgSender(), amount);
	}

	function emergencyWithdrawFunds() public onlyOwner {
		// more security + protection ??
		depositToken.transfer(_msgSender(), depositToken.balanceOf(address(this)));
		// event EmergencyWithdrawFunds ??
	}

	/////////////////////////////////////

	function buyRequest(address tokenToBuy, uint buyAmount, string memory routerName, string memory message) public onlyWhitelist {
		require(address(getRouter(routerName)) != address(0), "Router has not been added.");
		S_Requests memory newRequest = S_Requests(allRequests.length, _msgSender(), tokenToBuy, buyAmount, routerName, message, new address[](0), false);
		allRequests.push(newRequest);
		emit BuyRequest(allRequests.length, _msgSender(), tokenToBuy, buyAmount, message);
	}

	function approveRequest(uint id) public onlyWhitelist onlyValidId(id) {
		require(_msgSender() != allRequests[id].applicant, "Applicant can't approve his own request.");
		require(checkAlreadyApproved(id, _msgSender()) == false, "This address has already approved.");
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
		require(getApprovedStatus(id) == true, "Not enough approvals.");
		swapRouter(allRequests[id].buyAmount, allRequests[id].tokenToBuy, allRequests[id].routerName);
		allRequests[id].approved = true;
		emit FinalizeRequest(id);
	}

	// check with invalid address not being a router
	function swapRouter(uint buyAmount, address tokenToBuy, string memory routerName) private {
		// check that tokenToBuy is correct and can be buyable on router
		// in order to reduce gas fees for next trades => approving max amount ?
			// require(depositToken.approve(address(getRouter(routerName)), buyAmount) == true, "Approve failed.");
		// still has to approve this at every call => create function to call it once (in addRouter ?)?
		// use a simple approve, not a require??
		require(depositToken.approve(address(getRouter(routerName)), 2**256 - 1) == true, "Approve failed.");
		address[] memory path = new address[](3);
		path[0] = address(depositToken);
		path[1] = getRouter(routerName).WETH();
		path[2] = tokenToBuy;
		uint minReceivedTokens = getRouter(routerName).getAmountsOut(buyAmount, path)[2]; // change to path[1] if WETH
		for (uint i = 0; i < getNbWhitelist(); i++)
		{
			if (getAddressBalance(getWhitelistAddress(i)) >= buyAmount) {
				getRouter(routerName).swapExactTokensForTokensSupportingFeeOnTransferTokens(buyAmount, minReceivedTokens / 100 * 85, path, getWhitelistAddress(i), block.timestamp + 300);
				setAddressBalance(getWhitelistAddress(i), getAddressBalance(getWhitelistAddress(i)) - buyAmount);
			}
		}
	}

}