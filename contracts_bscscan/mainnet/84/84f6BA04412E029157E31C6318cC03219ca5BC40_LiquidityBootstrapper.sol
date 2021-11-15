// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IUniswapV2Router02.sol";

interface IVBT is IERC20 {
    function unlock() external;

    function stakedCake() external view returns (address);
}

interface IStakedCake is IERC20 {
    function depositAndMint(uint256 underlyingAmount) external;
}

contract LiquidityBootstrapper is Ownable, ReentrancyGuard {
    IUniswapV2Router02 constant uniswap = IUniswapV2Router02(0x3309f91A094626A98c2CC580A8c232081CF246b7);
    address weth = uniswap.WETH();

    IVBT public VBT = IVBT(address(0));
    IERC20 cake = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IStakedCake scake;

    bool public isStopped = false;
    bool public isRefundEnabled = false;
    bool public distStarted = false;
    bool public disableAddrCaps = false;

    uint256 startTime = 0;
    uint256 public timePrivsale = 15 minutes;

    uint256 public tokensBought = 0;

    bool public teamClaimed = false;
    bool public saleFinalized = false;

    uint256 constant hardCap = 390 ether;
    uint256 constant maxAddrCap = 4 ether;

    uint256 constant tokensPerETH = 100;
    uint256 constant listingPriceTokensPerETH = 110;
    uint256 constant DEVFEE = 1000;
    uint256 constant DIVISOR = 10000;

    uint256 public ethSent;
    uint256 public refundTime;

    mapping(address => uint256) public ethSpent;
    mapping(address => bool) public PRIVLIST;

    constructor(address[] memory privListAddrs) {
        refundTime = block.timestamp + 1 days;
        PRIVLIST[msg.sender] = true;
        batchAddWhitelisted(privListAddrs);
    }

    receive() external payable {
        buyTokens();
    }

    function enableRefunds() external onlyOwner nonReentrant {
        isRefundEnabled = true;
        isStopped = true;
    }

    function batchAddWhitelisted(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            PRIVLIST[addrs[i]] = true;
        }
    }

    function isPrivPhase() public view returns (bool) {
        return block.timestamp < startTime + timePrivsale;
    }

    function getRequiredAllocationOfTokens() public pure returns (uint256) {
        uint256 saleTokens = hardCap * tokensPerETH;
        uint256 fee = (hardCap * DEVFEE) / DIVISOR;
        uint256 remainingAfterfee = hardCap - fee;
        uint256 listingTokens = remainingAfterfee * listingPriceTokensPerETH;
        return listingTokens + saleTokens;
    }

    function getRefund() external nonReentrant {
        require(!saleFinalized);
        // Refund should be enabled by the owner OR 7 days passed
        require(isRefundEnabled || block.timestamp >= refundTime, "Cannot refund");
        address payable user = payable(msg.sender);
        uint256 amount = ethSpent[user];
        ethSpent[user] = 0;
        user.transfer(amount);
    }

    function setToken(address addr) public onlyOwner nonReentrant {
        VBT = IVBT(addr);
        scake = IStakedCake(VBT.stakedCake());
        //Stake the cake in scake
        cake.approve(address(scake), type(uint256).max);
    }

    function setPrivatesaleDuration(uint256 newDuration) public onlyOwner {
        timePrivsale = newDuration;
    }

    function startDistribution() external onlyOwner {
        startTime = block.timestamp;
        distStarted = true;
    }

    function pauseDistribution() external onlyOwner {
        distStarted = false;
    }

    function toggleAddrCaps() external onlyOwner {
        disableAddrCaps = !disableAddrCaps;
    }

    function buyTokens() public payable nonReentrant {
        require(msg.sender == tx.origin, "No contract allowed");
        require(distStarted == true, "!distStarted");
        require(VBT != IVBT(address(0)), "!VBT");
        require(PRIVLIST[msg.sender] || !isPrivPhase(), "privsale unauth");
        require(!isStopped, "stopped");
        if (!disableAddrCaps) {
            require(msg.value <= maxAddrCap, ">maxaddrcap");
        }
        require(ethSent < hardCap, "Hard cap reaches");
        require(msg.value + ethSent <= hardCap, "Hardcap will be reached");
        require(ethSpent[msg.sender] + msg.value <= maxAddrCap, "You cannot buy more");

        uint256 tokens = msg.value * (tokensPerETH);
        require(VBT.balanceOf(address(this)) >= tokens, "Not enough tokens in the contract");

        ethSpent[msg.sender] += msg.value;
        tokensBought += tokens;
        ethSent += msg.value;
        VBT.transfer(msg.sender, tokens);
    }

    function userEthSpenttInDistribution(address user) external view returns (uint256) {
        return ethSpent[user];
    }

    function claimTeamFeeAndAddLiquidity() external onlyOwner {
        require(!teamClaimed);
        uint256 amountETH = (address(this).balance * (DEVFEE)) / DIVISOR;
        payable(owner()).transfer(amountETH);

        addLiquidity();
        teamClaimed = true;
    }

    function getTokenOutPath(address _token_in, address _token_out) internal view returns (address[] memory _path) {
        bool is_weth = _token_in == address(weth) || _token_out == address(weth);
        _path = new address[](is_weth ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth) {
            _path[1] = _token_out;
        } else {
            _path[1] = address(weth);
            _path[2] = _token_out;
        }
    }

    function addLiquidity() internal {
        //Calculate bugets where 50% is in bnb and other part is swapped to cake,then deposited to scake and added to scake-coin liq
        uint256 BNBRaised = address(this).balance;
        uint256 cakeBudget = (BNBRaised * 5000) / DIVISOR;
        BNBRaised -= cakeBudget;

        uint256 tokensForUniswap = BNBRaised * listingPriceTokensPerETH;
        uint256 tokensForSCakePair = (tokensForUniswap * 5000) / DIVISOR;
        tokensForUniswap -= tokensForSCakePair;

        VBT.unlock();

        VBT.approve(address(uniswap), tokensForUniswap);
        uniswap.addLiquidityETH{value: BNBRaised}(address(VBT), tokensForUniswap, tokensForUniswap, BNBRaised, owner(), block.timestamp);

        //Convert the remaining amount to CAKE
        uint256 cakeReturned = uniswap.swapExactETHForTokens{value: cakeBudget}(
            0,
            getTokenOutPath(weth, address(cake)),
            address(this),
            block.timestamp
        )[1];

        //Deposit to scake and add scake-token liquidity to uniswap
        scake.depositAndMint(cakeReturned);

        VBT.approve(address(uniswap), tokensForSCakePair);
        scake.approve(address(uniswap), cakeReturned);

        uniswap.addLiquidity(
            address(VBT),
            address(scake),
            tokensForSCakePair,
            cakeReturned,
            tokensForSCakePair,
            cakeReturned,
            owner(),
            block.timestamp
        );

        uint256 tokensExcess = VBT.balanceOf(address(this));
        uint256 cakeExcess = cake.balanceOf(address(this));
        uint256 bnbExcess = address(this).balance;

        //Send what remains to owner
        if (tokensExcess > 0) VBT.transfer(owner(), tokensExcess);
        if (cakeExcess > 0) cake.transfer(owner(), cakeExcess);
        if (bnbExcess > 0) payable(owner()).transfer(bnbExcess);

        saleFinalized = true;
        if (!isStopped) isStopped = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool sendFromRouter
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

