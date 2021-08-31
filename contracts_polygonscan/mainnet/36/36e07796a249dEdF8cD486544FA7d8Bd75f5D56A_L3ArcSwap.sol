pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libs/IERC20.sol";


contract L3ArcSwap is Ownable, ReentrancyGuard {

    address public constant feeAddress = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;

    address public constant arcadiumAddress = 0x3F374ed3C8e61A0d250f275609be2219005c021e;
    address public immutable preCZDiamondAddress;
    address public immutable preDarksideAddress;

    uint256 public constant arcSwapPresaleSize = 834686 * (10 ** 18);

    uint256 public preCZDiamondSaleINVPriceE35 = 1543664 * (10 ** 27);
    uint256 public preDarksideSaleINVPriceE35 = 12863864 * (10 ** 27);

    uint256 public preCZDiamondMaximumAvailable = (arcSwapPresaleSize * preCZDiamondSaleINVPriceE35) / 1e35;
    uint256 public preDarksideMaximumAvailable = (arcSwapPresaleSize * preDarksideSaleINVPriceE35) / 1e35;

    // We use a counter to defend against people sending pre{CZDiamond,Darkside} back
    uint256 public preCZDiamondRemaining = preCZDiamondMaximumAvailable;
    uint256 public preDarksideRemaining = preDarksideMaximumAvailable;

    uint256 public constant oneHourMatic = 1500;
    uint256 public constant presaleDuration = 71999;

    uint256 public startBlock;
    uint256 public endBlock = startBlock + presaleDuration;

    event PrePurchased(address sender, uint256 arcadiumSpent, uint256 preCZDiamondReceived, uint256 preDarksideReceived);
    event RetrieveDepreciatedArcTokens(address feeAddress, uint256 tokenAmount);
    event SaleINVPricesE35Changed(uint256 newCZDiamondSaleINVPriceE35, uint256 newDarksideSaleINVPriceE35);
    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);

    constructor(uint256 _startBlock, address _preCZDiamondAddress, address _preDarksideAddress) {
        require(block.number < _startBlock, "cannot set start block in the past!");
        require(arcadiumAddress != _preCZDiamondAddress, "arcadiumAddress cannot be equal to preCZDiamond");
        require(_preCZDiamondAddress != _preDarksideAddress, "preCZDiamond cannot be equal to preDarkside");
        require(_preCZDiamondAddress != address(0), "_preCZDiamondAddress cannot be the zero address");
        require(_preDarksideAddress != address(0), "_preDarksideAddress cannot be the zero address");

        startBlock = _startBlock;
        endBlock   = _startBlock + presaleDuration;

        preCZDiamondAddress = _preCZDiamondAddress;
        preDarksideAddress = _preDarksideAddress;
    }

    function swapArcForPresaleTokensL3(uint256 arcadiumToSwap) external nonReentrant {
        require(msg.sender != feeAddress, "fee address cannot partake in presale");
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preCZDiamondRemaining > 0 && preDarksideRemaining > 0, "No more presale tokens remaining! Come back next time!");
        require(IERC20(preCZDiamondAddress).balanceOf(address(this)) > 0, "No more PreCZDiamond left! Come back next time!");
        require(IERC20(preDarksideAddress).balanceOf(address(this)) > 0, "No more PreDarkside left! Come back next time!");
        require(arcadiumToSwap > 1e6, "not enough arcadium provided");

        uint256 originalPreCZDiamondAmount = (arcadiumToSwap * preCZDiamondSaleINVPriceE35) / 1e35;
        uint256 originalPreDarksideAmount = (arcadiumToSwap * preDarksideSaleINVPriceE35) / 1e35;

        uint256 preCZDiamondPurchaseAmount = originalPreCZDiamondAmount;
        uint256 preDarksidePurchaseAmount = originalPreDarksideAmount;

        // if we dont have enough left, give them the rest.
        if (preCZDiamondRemaining < preCZDiamondPurchaseAmount)
            preCZDiamondPurchaseAmount = preCZDiamondRemaining;

        if (preDarksideRemaining < preDarksidePurchaseAmount)
            preDarksidePurchaseAmount = preDarksideRemaining;


        require(preCZDiamondPurchaseAmount > 0, "user cannot purchase 0 preCZDiamond");
        require(preDarksidePurchaseAmount > 0, "user cannot purchase 0 preDarkside");

        // shouldn't be possible to fail these asserts.
        assert(preCZDiamondPurchaseAmount <= preCZDiamondRemaining);
        assert(preCZDiamondPurchaseAmount <= IERC20(preCZDiamondAddress).balanceOf(address(this)));

        assert(preDarksidePurchaseAmount <= preDarksideRemaining);
        assert(preDarksidePurchaseAmount <= IERC20(preDarksideAddress).balanceOf(address(this)));


        require(IERC20(preCZDiamondAddress).transfer(msg.sender, preCZDiamondPurchaseAmount), "failed sending preCZDiamond");
        require(IERC20(preDarksideAddress).transfer(msg.sender, preDarksidePurchaseAmount), "failed sending preDarkside");

        preCZDiamondRemaining = preCZDiamondRemaining - preCZDiamondPurchaseAmount;
        preDarksideRemaining = preDarksideRemaining - preDarksidePurchaseAmount;

        require(IERC20(arcadiumAddress).transferFrom(msg.sender, address(this), arcadiumToSwap), "failed to collect arcadium from user");

        emit PrePurchased(msg.sender, arcadiumToSwap, preCZDiamondPurchaseAmount, preDarksidePurchaseAmount);
    }


    function sendDepreciatedArcToFeeAddress() external onlyOwner {
        require(block.number > endBlock, "can only retrieve excess tokens after arcadium swap has ended");

        uint256 arcadiumInContract = IERC20(arcadiumAddress).balanceOf(address(this));

        if (arcadiumInContract > 0)
            IERC20(arcadiumAddress).transfer(feeAddress, arcadiumInContract);

        emit RetrieveDepreciatedArcTokens(feeAddress, arcadiumInContract);
    }

    function setSaleINVPriceE35(uint256 _newPreCZDiamondSaleINVPriceE35, uint256 _newPreDarksideSaleINVPriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourMatic * 4), "cannot change price 4 hours before start block");
        require(_newPreCZDiamondSaleINVPriceE35 >= 1 * (10 ** 32), "new CZD price is to high!");
        require(_newPreCZDiamondSaleINVPriceE35 <= 1 * (10 ** 34), "new CZD price is too low!");

        require(_newPreDarksideSaleINVPriceE35 >= 9 * (10 ** 32), "new Darkside price is to high!");
        require(_newPreDarksideSaleINVPriceE35 <= 9 * (10 ** 34), "new Darkside price is too low!");

        preCZDiamondSaleINVPriceE35 = _newPreCZDiamondSaleINVPriceE35;
        preDarksideSaleINVPriceE35 = _newPreDarksideSaleINVPriceE35;

        preCZDiamondMaximumAvailable = (arcSwapPresaleSize * preCZDiamondSaleINVPriceE35) / 1e35;
        preDarksideMaximumAvailable  = (arcSwapPresaleSize * preDarksideSaleINVPriceE35) / 1e35;

        preCZDiamondRemaining = preCZDiamondMaximumAvailable;
        preDarksideRemaining = preDarksideMaximumAvailable;

        emit SaleINVPricesE35Changed(preCZDiamondSaleINVPriceE35, preDarksideSaleINVPriceE35);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}