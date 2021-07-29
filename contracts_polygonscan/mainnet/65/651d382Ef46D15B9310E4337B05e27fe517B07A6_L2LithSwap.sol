pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libs/IERC20.sol";


contract L2LithSwap is Ownable, ReentrancyGuard {

    // Burn address
    address public constant fee_address = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;

    address public constant lithAddress = 0xfE1a200637464FBC9B60Bc7AeCb9b86c0E1d486E;
    address public preMyFriendsAddress;
    address public preArcadiumAddress;

    uint256 public constant lithiumPresaleSize = (10 ** 5) * (10 ** 18);

    uint256 public preMyFriendsSaleINVPriceE35 = 25 * (10 ** 33);
    uint256 public preArcadiumSaleINVPriceE35 = 125 * (10 ** 33);

    uint256 public preMyFriendsMaximumAvailable = (lithiumPresaleSize * preMyFriendsSaleINVPriceE35) / 1e35;
    uint256 public preArcadiumMaximumAvailable = (lithiumPresaleSize * preArcadiumSaleINVPriceE35) / 1e35;

    // We use a counter to defend against people sending pre{MyFriends,Arcadium} back
    uint256 public preMyFriendsRemaining = preMyFriendsMaximumAvailable;
    uint256 public preArcadiumRemaining = preArcadiumMaximumAvailable;

    uint256 oneHourMatic = 1800;
    uint256 oneDayMatic = oneHourMatic * 24;
    uint256 twoDaysMatic = oneDayMatic * 2;

    uint256 public startBlock;
    uint256 public endBlock;

    event prePurchased(address sender, uint256 usdcSpent, uint256 preMyFriendsReceived, uint256 preArcadiumReceived);
    event startBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event saleINVPricesE35Changed(uint256 newMyFriendsSaleINVPriceE35, uint256 newArcadiumSaleINVPriceE35);

    constructor(uint256 _startBlock, address _preMyFriendsAddress, address _preArcadiumAddress) {
        require(block.number < _startBlock, "cannot set start block in the past!");
        require(lithAddress != _preMyFriendsAddress, "lithAddress cannot be equal to preArcadium");
        require(_preMyFriendsAddress != _preArcadiumAddress, "preMyFriends cannot be equal to preArcadium");
        require(_preMyFriendsAddress != address(0), "_preMyFriendsAddress cannot be the zero address");
        require(_preArcadiumAddress != address(0), "_preArcadiumAddress cannot be the zero address");

        startBlock = _startBlock;
        endBlock   = _startBlock + twoDaysMatic;
        preMyFriendsAddress = _preMyFriendsAddress;
        preArcadiumAddress = _preArcadiumAddress;
    }

    function swapLithForPresaleTokensL2(uint256 lithToSwap) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preMyFriendsRemaining > 0 && preArcadiumRemaining > 0, "No more presale tokens remaining! Come back next time!");
        require(IERC20(preMyFriendsAddress).balanceOf(address(this)) > 0, "No more PreMyFriends left! Come back next time!");
        require(IERC20(preArcadiumAddress).balanceOf(address(this)) > 0, "No more PreMyFriends left! Come back next time!");
        require(lithToSwap > 1e6, "not enough lithium provided");

        uint256 originalPreMyFriendsAmount = (lithToSwap * preMyFriendsSaleINVPriceE35) / 1e35;
        uint256 originalPreArcadiumAmount = (lithToSwap * preArcadiumSaleINVPriceE35) / 1e35;

        uint256 preMyFriendsPurchaseAmount = originalPreMyFriendsAmount;
        uint256 preArcadiumPurchaseAmount = originalPreArcadiumAmount;

        // if we dont have enough left, give them the rest.
        if (preMyFriendsRemaining < preMyFriendsPurchaseAmount)
            preMyFriendsPurchaseAmount = preMyFriendsRemaining;

        if (preArcadiumRemaining < preArcadiumPurchaseAmount)
            preArcadiumPurchaseAmount = preArcadiumRemaining;


        require(preMyFriendsPurchaseAmount > 0, "user cannot purchase 0 preMyFriends");
        require(preArcadiumPurchaseAmount > 0, "user cannot purchase 0 preArcadium");

        // shouldn't be possible to fail these asserts.
        assert(preMyFriendsPurchaseAmount <= preMyFriendsRemaining);
        assert(preMyFriendsPurchaseAmount <= IERC20(preMyFriendsAddress).balanceOf(address(this)));

        assert(preArcadiumPurchaseAmount <= preArcadiumRemaining);
        assert(preArcadiumPurchaseAmount <= IERC20(preArcadiumAddress).balanceOf(address(this)));


        require(IERC20(preMyFriendsAddress).transfer(msg.sender, preMyFriendsPurchaseAmount), "failed sending preMyFriends");
        require(IERC20(preArcadiumAddress).transfer(msg.sender, preArcadiumPurchaseAmount), "failed sending preMyFriends");

        require(IERC20(lithAddress).transferFrom(msg.sender, fee_address, lithToSwap), "failed to send lithium to fee address");

        emit prePurchased(msg.sender, lithToSwap, preMyFriendsPurchaseAmount, preArcadiumPurchaseAmount);
    }

    function setSaleINVPriceE35(uint256 _newPreMyFriendsSaleINVPriceE35, uint256 _newPreArcadiumSaleINVPriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourMatic * 4), "cannot change price 4 hours before start block");
        require(_newPreMyFriendsSaleINVPriceE35 >= 15 * (10 ** 33), "new myfriends price is to high!");
        require(_newPreMyFriendsSaleINVPriceE35 <= 25 * (10 ** 33), "new myfriends price is too low!");

        require(_newPreArcadiumSaleINVPriceE35 >= 75 * (10 ** 33), "new arcadium price is to high!");
        require(_newPreArcadiumSaleINVPriceE35 <= 125 * (10 ** 33), "new arcadium price is too low!");

        preMyFriendsSaleINVPriceE35 = _newPreMyFriendsSaleINVPriceE35;
        preArcadiumSaleINVPriceE35 = _newPreArcadiumSaleINVPriceE35;

        preMyFriendsMaximumAvailable = (lithiumPresaleSize * preMyFriendsSaleINVPriceE35) / 1e35;
        preArcadiumMaximumAvailable  = (lithiumPresaleSize * preArcadiumSaleINVPriceE35) / 1e35;

        preMyFriendsRemaining = preMyFriendsMaximumAvailable;
        preArcadiumRemaining = preArcadiumMaximumAvailable;

        emit saleINVPricesE35Changed(preMyFriendsSaleINVPriceE35, preArcadiumSaleINVPriceE35);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + twoDaysMatic;

        emit startBlockChanged(_newStartBlock, endBlock);
    }
}

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