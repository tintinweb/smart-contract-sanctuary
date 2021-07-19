//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ICO is Ownable {

    IERC20 public sigil;
    uint public price;
    uint public softcap;
    uint public hardcap;
    uint public minSale;
    uint public saleStart;
    uint public saleEnd;
    uint public collected;

    // EVENTS

    event Sale(address indexed buyer, uint valueBought, uint valueGiven);

    event PriceSet(uint price);

    event HardcapSet(uint hardcap);

    event MinSaleSet(uint minSale);

    event SaleStartSet(uint saleStart);

    event SaleEndSet(uint saleEnd);

    // CONSTRUCTOR

    constructor(
        address sigil_, 
        uint price_, 
        uint softcap_,
        uint hardcap_, 
        uint minSale_, 
        uint saleStart_, 
        uint saleEnd_
    ) Ownable() {
        require(saleEnd_ > saleStart_, "Sale end should be greater than sale start");

        sigil = IERC20(sigil_);
        price = price_;
        softcap = softcap_;
        hardcap = hardcap_;
        minSale = minSale_;
        saleStart = saleStart_;
        saleEnd = saleEnd_;
    }

    // PUBLIC FUNCTIONS 

    function buy() external payable {
        require(msg.value >= minSale, "Can't buy for less than minSale");
        require(collected + msg.value <= hardcap, "Sale overflows hardcap");
        require(block.number >= saleStart, "Sale hasn't started yet");
        require(block.number <= saleEnd, "Sale has finished already");

        collected += msg.value;
        uint sigilValue = msg.value * price / 10**18;
        sigil.transfer(msg.sender, sigilValue);

        emit Sale(msg.sender, sigilValue, msg.value);
    }

    // RESTRICTED FUNCTIONS

    function setPrice(uint price_) external onlyOwner {
        price = price_;
        emit PriceSet(price);
    }

    function setHardcap(uint hardcap_) external onlyOwner {
        hardcap = hardcap_;
        emit HardcapSet(hardcap);
    }

    function setMinSale(uint minSale_) external onlyOwner {
        minSale = minSale_;
        emit MinSaleSet(minSale);
    }

    function setSaleStart(uint saleStart_) external onlyOwner {
        require(saleStart_ > block.number, "Sale start should be in future");
        require(saleStart_ < saleEnd, "Sale start should be before sale end");
        saleStart = saleStart_;
        emit SaleStartSet(saleStart);
    }

    function setSaleEnd(uint saleEnd_) external onlyOwner {
        require(saleEnd_ > block.number, "Sale end should be in future");
        require(saleEnd_ > saleStart, "Sale end should be after sale start");
        saleEnd = saleEnd_;
        emit SaleEndSet(saleEnd);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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