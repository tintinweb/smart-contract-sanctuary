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

import "../token/ERC20/extensions/IERC20Metadata.sol";

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

//SPDX-License-Identifier: UNLICENSED
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity ^0.8.10;
//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PointSystem is Ownable {

    IERC20Metadata public MNG; //Token contract address
    IERC20Metadata private constant USDT =
        IERC20Metadata(0x77c21c770Db1156e271a3516F89380BA53D594FA); //USDT on binance chain

    mapping(address => mapping(uint8 => uint256)) private userPoints; //Mapping to store points
    mapping(address => uint256) private userUSDT;
    mapping(address => uint256) private userMNG;
    IUniswapV2Router02 public pancakeV2Router;
    uint256[50] public ratio = [10, 15, 20, 25, 30, 35, 40, 45, 50]; //Ratio store

    mapping(address => bool) public isAuthorised; //authrised user for points to token transfer

    event PointsBought(
        uint256 token,
        uint8 ratio,
        uint256 points,
        address user
    );
    event RatioChanged(uint8 ratioSelector, uint256 ratioValue);
    event PointsSold(uint256 USDTAmount, uint256 MNGReceived);
    event TokensConverted(uint256 amount, uint256 receivedUSDT);
    event PointsRedeem(
        uint256[] USDTAmount,
        uint256[] MNGReceived,
        address[] user
    );

    constructor(IERC20Metadata _MNG) {
        MNG = _MNG;
        pancakeV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        USDT.approve(address(pancakeV2Router), ~uint256(0)); //Huge approval
        MNG.approve(address(pancakeV2Router), ~uint256(0));
        isAuthorised[msg.sender] = true;
    }

    receive() external payable {}

    /*
    Function to buy points using token
    
    tokenAmount = Amount of token you want to spend
    ratioSelector = On which ratio you want to receive points

    **Important! You must approve tokens before calling this function
    Approve this contract to spend MNG tokens on your behalf

*/
    function buyPoints(uint256 tokenAmount, uint8 ratioSelector) external {
        MNG.transferFrom(msg.sender, address(this), tokenAmount);

        uint256 points = (tokenAmount * ratio[ratioSelector]) / 10**MNG.decimals();
        userPoints[msg.sender][ratioSelector] += points;

        require(
            userPoints[msg.sender][ratioSelector] >= points,
            "Not enough points"
        );
        userPoints[msg.sender][ratioSelector] -= points;

        uint256 initBalanceUSDT = USDT.balanceOf(address(this));
        swapTokensForTokens(address(MNG), address(USDT), tokenAmount);
        uint256 receivedUSDT = USDT.balanceOf(address(this)) - initBalanceUSDT;

        userUSDT[msg.sender] = receivedUSDT;
        userMNG[msg.sender] = tokenAmount;

        emit TokensConverted(tokenAmount, receivedUSDT);
        emit PointsBought(tokenAmount, ratioSelector, points, msg.sender);
    }

    /*
     * Function to sell points in bulk
     *
     * Important - totalAmount should be total of all values in amountsUSDT array
     *
     */
    function sellPointsBulk(
        address[] memory users,
        uint256[] memory amountsUSDT,
        uint256 totalAmount
    ) external {
        require(isAuthorised[msg.sender], "You are not authorised");
        require(
            USDT.balanceOf(address(this)) >= totalAmount,
            "Not enough USDT to sell"
        );
        uint256 len = users.length;
        uint256[] memory amountReceived = new uint256[](len);
        uint256 amount;

        require(len == amountsUSDT.length, "Invalid input");

        //Only single swap and distributes amount according to each users share
        uint256 initBalanceMNG = MNG.balanceOf(address(this));
        swapTokensForTokens(address(USDT), address(MNG), totalAmount);
        uint256 receivedMNG = MNG.balanceOf(address(this)) - initBalanceMNG;

        for (uint256 i = 0; i < len; i++) {
            amount = (receivedMNG * amountsUSDT[i]) / totalAmount; //Calculating share of each user
            MNG.transfer(users[i], amount);
            amountReceived[i] = amount;
        }

        emit PointsRedeem(amountsUSDT, amountReceived, users);
    }

    // Internal function to swap tokens for tokens in pancakeswap

    function swapTokensForTokens(
        address sent,
        address received,
        uint256 tokenAmount
    ) private {
        address[] memory path = new address[](3);
        path[0] = sent;
        path[1] = pancakeV2Router.WETH();
        path[2] = received;

        // make the swap
        pancakeV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Owner view function to see anyones point balance in each ratio
    function getPoints(address addr) external view returns (uint256, uint256) {
        return (userUSDT[addr], userMNG[addr]);
    }

    // Can be called to withdraw any tokens send to this contract. Including MNG token!
    function transferAnyBEP20(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function transferStuckBNB(address _to, uint256 _amount) external onlyOwner {
        payable(_to).transfer(_amount);
    }

    // To modify ratio system. Maximum 50 ratio allowed
    function modifyRatio(uint8 ratioSelector, uint256 ratioValue)
        external
        onlyOwner
    {
        ratio[ratioSelector] = ratioValue;
        emit RatioChanged(ratioSelector, ratioValue);
    }

    function addAuthorised(address _address) external onlyOwner {
        isAuthorised[_address] = true;
    }

    function removeAuthorised(address _address) external onlyOwner {
        isAuthorised[_address] = false;
    }
}