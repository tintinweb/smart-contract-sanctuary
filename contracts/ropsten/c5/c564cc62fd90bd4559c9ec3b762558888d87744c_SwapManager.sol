pragma solidity 0.7.4;

interface ISwapManager {
    function buyBackAndLiquify() external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface ISwapRouter {
    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

pragma solidity 0.7.4;

import "./ISwapRouter.sol";
import "./ISwapManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapManager is ISwapManager, Ownable {
    address public routerAddr = address(0);
    address public pairAddr = address(0);
    IERC20 public paymentToken;
    bool private inSwap;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapRouterChanged(address swapRouterAddr);
    event SwapPairChanged(address swapPairAddr);
    event SwapAndLiquify(uint256 bnbAmount, uint256 tokenAmount);

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    /**
    @dev To receive dust ETH, if any, from Router when doing addLiquidityETH
     */
    receive() external payable {}

    function buyBackAndLiquify() external payable override {
        if (!inSwap) {
            _buyBackAndLiquify();
        }
    }

    function setSwapRouterAndPair(address _routerAddr, address _pairAddr)
        external
        onlyOwner()
    {
        routerAddr = _routerAddr;
        pairAddr = _pairAddr;
        emit SwapRouterChanged(routerAddr);
        emit SwapPairChanged(pairAddr);
    }

    function withdraw() external onlyOwner() {
        (bool sent, bytes memory data) = owner().call{
            value: address(this).balance
        }("");
        require(sent, "Failed to withdraw");
    }

    function _buyBackAndLiquify() private lockTheSwap {
        ISwapRouter swapRouter = ISwapRouter(routerAddr);
        uint256 half = msg.value / 2;
        uint256 otherHalf = msg.value - half;
        uint256 oldTokenBalance = paymentToken.balanceOf(address(this));
        _swapBNBForTokens(half, swapRouter);
        uint256 addedTokenAmount = paymentToken.balanceOf(address(this)) -
            oldTokenBalance;
        _addLiquidity(otherHalf, addedTokenAmount, swapRouter);
    }

    function _swapBNBForTokens(uint256 amount, ISwapRouter swapRouter) private {
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(paymentToken);

        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function _addLiquidity(
        uint256 bnbAmount,
        uint256 tokenAmount,
        ISwapRouter swapRouter
    ) private {
        paymentToken.approve(routerAddr, tokenAmount);
        (uint256 amountToken, uint256 amountETH, ) = swapRouter.addLiquidityETH{
            value: bnbAmount
        }(
            address(paymentToken),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            0x000000000000000000000000000000000000dEaD, // Burn LP
            block.timestamp
        );
        emit SwapAndLiquify(amountETH, amountToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}