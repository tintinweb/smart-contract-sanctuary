/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor () {
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

//////////////////////////////////////////////////
// CUSTOM LOGIC STARTS HERE, PURE OZ CODE ABOVE //
//////////////////////////////////////////////////

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20L is IERC20 {
    function transferLocked(address recipient, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops) external returns (bool);
}

contract LockedQANX is Ownable {

    // THE CONTRACT ADDRESS OF QANX AND USDT
    IERC20L private _qanx = IERC20L(0xAAA7A10a8ee237ea61E8AC46C50A8Db8bCC1baaa);
    IERC20  private _usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // THIS REPRESENTS AN OFFER'S PROPERTIES GIVEN TO A BUYER
    struct Offer {
        uint256 qanxAmount;     // HOW MANY QANX TOKENS ARE OFFERED FOR SALE
        uint256 usdtAmount;     // HOW MUCH USDT TO SEND TO CLAIM THE OFFERED TOKENS
        uint32 claimableHours;  // UNTIL WHEN THIS OFFER IS CLAIMABLE FROM NOW (HOURS)
        uint32 hardLockUntil;   // UNTIL WHEN THE BOUGHT TOKENS WILL BE LOCKED
        uint32 softLockUntil;   // UNTIL WHEN THE BOUGHT TOKENS WILL BE GRADUALLY RELEASED
        uint8 allowedHops;      // HOW MANY FURTHER TRANSFERS ARE ALLOWED
    }

    // THIS MAPS THE BUYER ADDRESSES TO THE OFFERS GIVEN TO THEM
    mapping (address => Offer) public offers;

    // MAKE AN OFFER TO A BUYER
    function makeOffer(
        address _toBuyer,
        uint256 _qanxAmount,
        uint256 _usdtAmount,
        uint32 _claimableHours,
        uint32 _hardLockUntil,
        uint32 _softLockUntil,
        uint8 _allowedHops) public onlyOwner {
        
        // IF ABOVE CONDITIONS WERE MET, REGISTER OFFER
        offers[_toBuyer] = Offer({
            qanxAmount: _qanxAmount * (10 ** 18),   // QANX TOKEN HAS 18 DECIMALS
            usdtAmount: _usdtAmount * (10 ** 6),    // USDT TOKEN HAS 6  DECIMALS
            claimableHours: uint32(block.timestamp + _claimableHours * 3600),
            hardLockUntil: _hardLockUntil,
            softLockUntil: _softLockUntil,
            allowedHops: _allowedHops
        });
    }

    // NON-CLAIMED OFFERS CAN BE CANCELLED
    function cancelOffer(address _ofBuyer) public onlyOwner {

        // REMOVE BUYER'S OFFER FROM MAPPING
        delete offers[_ofBuyer];
    }

    // BUYERS NEED TO SEND A ZERO ETH TX TO SWAP USDT -> QANX
    receive() external payable {

        // ONLY ZERO ETH PAYMENT ACCEPTED
        require(msg.value == 0, "You must not send ETH!");

        // OFFER MUST BE STILL CLAIMABLE
        require(offers[_msgSender()].claimableHours > block.timestamp, "Offer expired!");

        // MAKE SURE THIS CONTRACT CAN SEND ENOUGH QANX TO BUYER
        uint256 qanxAllowance = _qanx.allowance(owner(), address(this));
        require(offers[_msgSender()].qanxAmount <= qanxAllowance);

        // REQUIRE THAT BUYER HAS APPROVED CORRECT USDT PURCHASE PRICE
        uint256 usdtAllowance = _usdt.allowance(_msgSender(), address(this));
        require(offers[_msgSender()].usdtAmount == usdtAllowance, "Incorrect purchase price approved");

        // TRANSFER USDT FROM BUYER TO THIS CONTRACT
        _usdt.transferFrom(_msgSender(), address(this), usdtAllowance);

        // TRANSFER UNLOCKED QANX TO THIS CONTRACT
        _qanx.transferFrom(owner(), address(this), offers[_msgSender()].qanxAmount);
        _qanx.transferLocked(
            _msgSender(),
            offers[_msgSender()].qanxAmount,
            offers[_msgSender()].hardLockUntil,
            offers[_msgSender()].softLockUntil,
            offers[_msgSender()].allowedHops
        );

        // REMOVE BUYER'S OFFER FROM MAPPING
        delete offers[_msgSender()];
    }

    // SELLER CAN CLAIM THE AMOUNT PAID BY THE BUYER
    function claimPurchasePrice(address _beneficiary) public onlyOwner {
        _usdt.transfer(_beneficiary, _usdt.balanceOf(address(this)));
    }
}