// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/ICustomERC20.sol";

contract SwapHandler is Ownable {

    address immutable swapRouter;
    address immutable wbnb;

    ICustomERC20 erc20;

    bool private _inSwap = false;

    uint256 public totalToHoldersInERC20;

    modifier isInSwap () {
        require(!_inSwap, "SwapHandler: Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    receive() external payable {}

    constructor (
        address swapRouter_,
        address wrappedNativeToken_
    ) {
        swapRouter = swapRouter_;
        wbnb = wrappedNativeToken_;
        erc20 = ICustomERC20(msg.sender);
    }

    /**
        this will swap the amounts to avax/eth/bnb/matic and send them to the respective wallets
     */
    function swapToNativeWrappedToken(
        uint256 autoLPAmount_,
        uint256 holderAmount_,
        uint256 marketingAmount_,
        uint256 buybackAmount_,
        uint256 devAmount_
    ) isInSwap onlyOwner external {
        IERC20(owner()).approve(swapRouter, IERC20(owner()).balanceOf(address(this)));

        if (autoLPAmount_ > 0) {
            uint256 half = autoLPAmount_ / 2;
            _swap(half, address(this));
            // swap half
            _createLP(autoLPAmount_ - half);
        }

        if (marketingAmount_ > 0) {
            // transfer to marketing wallet
            IERC20(owner()).transfer(erc20.marketingWallet(), marketingAmount_);
        }

        if (buybackAmount_ > 0) {
            // transfer to buybackWallet wallet
            IERC20(owner()).transfer(erc20.buybackWallet(), buybackAmount_);
        }
        if (devAmount_ > 0) {
            // transfer to marketing wallet
            IERC20(owner()).transfer(erc20.devWallet(), devAmount_);
        }
        if (holderAmount_ > 0) {
            totalToHoldersInERC20 += IERC20(owner()).balanceOf(address(this));
            _swap(
                IERC20(owner()).balanceOf(address(this)),
                address(erc20.hodlRewardDistributor())
            );
            // Does not matter if it fails because it should not 
            address(erc20.hodlRewardDistributor()).call{value : address(this).balance}("");
        }
    }

    /**
        swap helper function
     */
    function _swap(
        uint amount_,
        address to_
    ) internal {
        // make the swap to wrappedNativeToken
        address[] memory path = new address[](2);
        path[0] = owner();
        path[1] = wbnb;

        IRouter(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_,
            0,
            path,
            to_,
            block.timestamp + 10000
        );

    }


    function _createLP(uint256 erc20Amount_) internal {
        IRouter(swapRouter).addLiquidityETH{value : address(this).balance}(
            owner(),
            erc20Amount_,
            0,
            0,
            erc20.autoLPWallet(),
            block.timestamp + 10000
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
        erc20 = ICustomERC20(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

interface IRouter {
    function factory() external returns (address);
    /**
        for AMMs that cloned uni without changes to functions names
    */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    /**
        for joe AMM that cloned uni and changed functions names
    */
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken,uint256 amountAVAX,uint256 liquidity);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import '../data/ShareHolder.sol';

interface IHODLRewardDistributor {

    function excludedFromRewards(
        address wallet_
    ) external view returns (bool);

    function pending(
        address sharholderAddress_
    ) external view returns (uint256 pendingAmount);

    function totalPending () external view returns (uint256 );

    function shareHolderInfo (
        address shareHoldr_
    ) external view returns(ShareHolder memory);

    function depositWrappedNativeTokenRewards(
        uint256 amount_
    ) external;

    function setShare(
        address sharholderAddress_,
        uint256 amount_
    ) external;

    function excludeFromRewards (
        address shareHolderToBeExcluded_ 
    ) external;

    function includeInRewards(
        address shareHolderToBeIncluded_
    ) external;

    function claimPending(
        address sharholderAddress_
    ) external;

    function owner() external returns(address);
    
    function batchProcessClaims(uint256 gas) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import "./IHODLRewardDistributor.sol";

interface ICustomERC20 {
    function autoLPWallet () external returns(address);
    function marketingWallet() external returns(address);
    function buybackWallet() external returns(address);
    function devWallet() external returns(address);
    function hodlRewardDistributor() external returns(IHODLRewardDistributor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

struct ShareHolder {
    uint256 shares;
    uint256 rewardDebt;
    uint256 claimed;
    uint256 pending;
}