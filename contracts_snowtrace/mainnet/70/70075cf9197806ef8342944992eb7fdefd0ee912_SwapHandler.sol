/**
 *Submitted for verification at snowtrace.io on 2022-01-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/1_Storage.sol


pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

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
}

pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/


pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/


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

    function depositWavaxRewards(
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
}
interface IReflectionERC20 {
    function teamWallet () external returns(address);
    function charityWallet() external returns(address);
    function treasuryWallet() external returns(address);
    function hodlRewardDistributor() external returns(IHODLRewardDistributor);
}

contract SwapHandler is Ownable {

    address immutable swapRouter;
    address immutable wavax;
    IReflectionERC20 immutable erc20;

    bool private _inSwap = false;

    modifier isInSwap () {
        require(!_inSwap, "SwapHandler: Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor (
        address swapRouter_,
        address wavax_
    ) {
        swapRouter = swapRouter_;
        wavax = wavax_;
        erc20 = IReflectionERC20(msg.sender);
    }

    /**
        this will swap the amounts to avax/eth and send them to the respective wallets
     */
    function swapToAvax(
        uint256 teamAmount_,
        uint256 holderAmount_,
        uint256 treasuryAmount_,
        uint256 charityAmount_
    ) isInSwap onlyOwner external {
        if (teamAmount_ > 0)
            _swap(teamAmount_, erc20.teamWallet());

        if (holderAmount_ > 0)
            _swap(holderAmount_, address(erc20.hodlRewardDistributor()));

        if (treasuryAmount_ > 0)
            _swap(treasuryAmount_, erc20.treasuryWallet());

        if (charityAmount_ > 0)
            _swap(charityAmount_, erc20.charityWallet());
    }

    /**
        swap helper function
     */
    function _swap(
        uint amount_,
        address to_
    ) internal {
        IERC20(owner()).approve(swapRouter, amount_);
        // make the swap to wavax
        address[] memory path = new address[](2);
        path[0] = owner();
        path[1] = wavax;

        // Avax AMMs use a modified uniswapv2 where the function is called
        if (block.chainid == 43114) 
            IRouter(swapRouter).swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                amount_,
                0,
                path,
                to_,
                block.timestamp + 10000
            );
        // all other chains use swapExactETH
        else
            IRouter(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount_,
                0,
                path,
                to_,
                block.timestamp + 10000
            );
        
    }
}