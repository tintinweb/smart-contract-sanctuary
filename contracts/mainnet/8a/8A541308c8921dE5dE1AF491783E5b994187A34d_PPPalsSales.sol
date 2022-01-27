// SPDX-License-Identifier: MIT
// Made by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
  _____  _____  _____        _       _____    _____         _      ______ 
 |  __ \|  __ \|  __ \ /\   | |     / ____|  / ____|  /\   | |    |  ____|
 | |__) | |__) | |__) /  \  | |    | (___   | (___   /  \  | |    | |__   
 |  ___/|  ___/|  ___/ /\ \ | |     \___ \   \___ \ / /\ \ | |    |  __|  
 | |    | |    | |  / ____ \| |____ ____) |  ____) / ____ \| |____| |____ 
 |_|    |_|    |_| /_/    \_\______|_____/  |_____/_/    \_\______|______|
                                                                                                                                                    
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract IPPPals {
    /** ERC-721 INTERFACE */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** CUSTOM INTERFACE */
    function mintTo(uint256 amount, address _to) external {}
}

abstract contract IBAMBOO is IERC20 {
    function burn(address _from, uint256 _amount) external {}
}

contract PPPalsSales is Ownable {
    IPPPals public pppals;

    /** MINT OPTIONS */
    uint256 public maxSupply = 6363;
    uint256 public maxPPPalsPerWallet = 20;
    uint256 public minted = 0;

    /** FLAGS */
    bool public isFrozen = false;
    bool public isSaleOpen = false;

    /** MAPPINGS  */
    mapping(address => uint256) public mintsPerAddress;

    /** BAMBOO */
    IBAMBOO public BAMBOO;
    uint256 public BAMBOOPrice = 250 * 10**18;

    /** MODIFIERS */
    modifier notFrozen() {
        require(!isFrozen, "CONTRACT FROZEN");
        _;
    }

    modifier checkMintBAMBOO(uint256 amount) {
        require(isSaleOpen, "SALE CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(amount + mintsPerAddress[msg.sender] <= maxPPPalsPerWallet, "CANNOT MINT MORE THAN 20 PPPALS");
        require(minted + amount <= maxSupply, "MAX PPPALS MINTED");
        require(BAMBOO.balanceOf(msg.sender) >= BAMBOOPrice * amount, "NOT ENOUGH $BAMBOO TO BURN");
        _;
    }

    constructor(
        address _pppalsaddress,
        address _BAMBOOAddress
    ) Ownable() {
        pppals = IPPPals(_pppalsaddress);
        BAMBOO = IBAMBOO(_BAMBOOAddress);
    }
 
    function mintWithBAMBOO(uint256 amount) external checkMintBAMBOO(amount) {
        minted = minted + amount;
        mintsPerAddress[_msgSender()] = mintsPerAddress[_msgSender()] + amount;
        BAMBOO.burn(msg.sender, BAMBOOPrice * amount);
        pppals.mintTo(amount, _msgSender());
    }

    /** OWNER */

    function freezeContract() external onlyOwner {
        isFrozen = true;
    }

    function setPPPals(address _pppalsAddress) external onlyOwner notFrozen {
        pppals = IPPPals(_pppalsAddress);
    }

    function setBAMBOO(address _BAMBOOAddress) external onlyOwner notFrozen {
        BAMBOO = IBAMBOO(_BAMBOOAddress);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner notFrozen {
        maxSupply = newMaxSupply;
    }

    function setMaxMintesPerWallet(uint256 newMaxPerWallet) external onlyOwner notFrozen {
        maxPPPalsPerWallet = newMaxPerWallet;
    }

    function setBAMBOOPrice(uint256 newMintPrice) external onlyOwner notFrozen {
        BAMBOOPrice = newMintPrice;
    }  

    function setSaleStatus(bool newStatus) external onlyOwner notFrozen {
        isSaleOpen = newStatus;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAllBAMBOO() external onlyOwner {
        BAMBOO.transfer(owner(), BAMBOO.balanceOf(owner()));
    }
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