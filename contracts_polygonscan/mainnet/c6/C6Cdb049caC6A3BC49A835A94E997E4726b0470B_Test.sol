//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./QuickSwapTrader.sol";
import "./Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Test is Ownable, QuickSwapTrader {



    constructor()
    {
        transferOwnership(msg.sender);
    }

    function deposit() external payable 
    {

    }

    function getBalance() view external returns(uint256)
    {
        return address(this).balance;
    }

    function getUSDCBalance() view external returns(uint256)
    {
        return IERC20(PolygonTokens.usdc).balanceOf(address(this));
    }

    function getWMATICBalance() view external returns(uint256)
    {
        return IERC20(PolygonTokens.wmatic).balanceOf(address(this));
    }

    function swap(uint256 _amount) external onlyOwner
    {
        _swapToken(kPolygonToken.wmatic, kPolygonToken.usdc, _amount);
    }

    function swapByAddress(address _inTokenAddress, address _outTokenAddress, uint256 _amount) external onlyOwner
    {
        _swapTokenByAddress(_inTokenAddress, _outTokenAddress, _amount);
    }

    function withdraw() external
    {
        payable(owner()).transfer(address(this).balance);
    }

    function transferTokens(address _tokenAddress) external onlyOwner
    {
        // Used for "rescue" tokens
        IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IQuickswapV2Router02.sol";
import "./Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QuickSwapTrader {

    mapping(address => TradingToken) private tokens;

    IQuickswapV2Router02 private quickswapV2Router02 = IQuickswapV2Router02(PolygonContracts.quickswapV2Router02);

    constructor()
    {
        
    }

    function _swapToken(kPolygonToken _inToken, kPolygonToken _outToken, uint256 _amount) internal
    {
        _swapTokenByAddress(PolygonTokens.getTokenAddress(_inToken), PolygonTokens.getTokenAddress(_outToken), _amount);
    }

    function _swapTokenByAddress(address _inTokenAddress, address _outTokenAddress, uint256 _amount) internal
    {
        if (_amount == 0)
        {
            return;
        }

        _approveSpending(_inTokenAddress);

        uint256 _inBalance = tokens[_inTokenAddress].token.balanceOf(address(this));

        require(_inBalance >= _amount, "Not enough tokens available for swap");

        address[] memory path = new address[](2);
        path[0] = _inTokenAddress;
        path[1] = _outTokenAddress;

        uint256[] memory amountsOut = quickswapV2Router02.getAmountsOut(
            _amount,
            path
        );


        uint256 minAmount = amountsOut[1] - _calculateOnePercent(amountsOut[1]); // 1% slippage
        address receiver = address(this);

        quickswapV2Router02.swapExactTokensForTokens(
            _amount,
            minAmount,
            path,
            receiver,
            block.timestamp
        );
    }


    function _approveSpending(address _tokenAddress) private
    {
        if (_spendingIsApproved(_tokenAddress))
        {
            return;
        }

        tokens[_tokenAddress].token = IERC20(_tokenAddress);
        tokens[_tokenAddress].tokenAddress = _tokenAddress;
        tokens[_tokenAddress].network = kNetwork.polygon;

        bool succeeded = tokens[_tokenAddress].token.approve(address(quickswapV2Router02), MAX_INT);

        tokens[_tokenAddress].spendingIsApproved = true;
    }

    function _spendingIsApproved(address _tokenAddress) private view returns(bool)
    {
        return tokens[_tokenAddress].spendingIsApproved;
    }

    function _calculateOnePercent(uint amount) private pure returns(uint)
    {
        // Return 1% of amount
        uint _100 = 100e18;
        uint _1 = 1e18;

        return ((amount * _1) / _100);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

uint256 constant MAX_INT = type(uint256).max;

enum kNetwork
{
    polygon
}

struct TradingToken {
    IERC20 token;
    address tokenAddress;
    bool spendingIsApproved;
    kNetwork network;
}

enum kPolygonToken
{
    wmatic,
    usdc
}

library PolygonTokens {

    address constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    function getTokenAddress(kPolygonToken token) internal pure returns(address)
    {
        if (token == kPolygonToken.wmatic)
        {
            return wmatic;
        }
        if (token == kPolygonToken.usdc)
        {
            return usdc;
        }

        revert("The address of the token provided is unkown.");
    }

    function getTokenName(kPolygonToken token) internal pure returns(string memory)
    {
        if (token == kPolygonToken.wmatic)
        {
            return "WMATIC";
        }
        if (token == kPolygonToken.usdc)
        {
            return "USDC";
        }

        revert("The name of the token provided is unkown.");
    }

}

library PolygonContracts {

    address constant quickswapV2Router02 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IQuickswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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