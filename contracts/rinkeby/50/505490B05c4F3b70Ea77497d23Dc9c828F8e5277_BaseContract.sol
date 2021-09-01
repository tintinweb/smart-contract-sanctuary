// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./CollectionContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
contract BaseContract is Ownable, Initializable {
    mapping(address => bool) public arbitrators;
    uint256 allowWithdrawTime;
    mapping(bytes16 => address) public collections;

    event CollectionCreated(address collectionAddress, bytes16 collectionId, address sender, uint256 blockNumber);

    constructor() {
        arbitrators[msg.sender] = true;
        allowWithdrawTime = 2 days;
    }

    function initialize() public initializer {
        arbitrators[msg.sender] = true;
        allowWithdrawTime = 2 days;
    }

    modifier isArbitrator() {
        require(arbitrators[msg.sender] == true, "You are not arbitrator");
        _;
    }

    // Remove arbitrator
    function removeArbitrator(address arbitrator) public onlyOwner {
        arbitrators[arbitrator] = false;
    }

    // Add arbitrator
    function addArbitrator(address arbitrator) public onlyOwner {
        arbitrators[arbitrator] = true;
    }

    // Update allowWithdrawTime
    // All new collection will receive this value
    // Parameter: 
    // time: timeStamp in second
    // Example: 
    // setAllowWithdrawTime(1626238816)
    function setAllowWithdrawTime(uint256 time) public onlyOwner {
        require(time > 0, "Invalid time");
        allowWithdrawTime = time;
    }

    // Create new CollectionContract for seller who is msg.sender
    // parameters:
    // _id: colletionUUID which is gotten from db
    // token: payment token address, it's should be a ERC20 token
    // Event:
    // CollectionCreated(address collectionAddress, address sender, uint256 blockNumber);
    function createCollection(bytes16 _id, IERC20 token) public {
        require(collections[_id] == address(0), "collection id existed");
        CollectionContract collectionContract = new CollectionContract();
        collectionContract.initialize(address(this), _id, payable(msg.sender), token, allowWithdrawTime);
        collections[_id] = address(collectionContract);
        emit CollectionCreated(address(collectionContract), _id, tx.origin, block.number);
    }


    // delegate call to CollectionContract from BaseContract
    // Should change CollectionContract to ICollectionContract (interface in the future)
    function setAllowWithdrawTimeForCollection(address payable collectionAddress, uint256 time) public isArbitrator {
        require(time > 0, "Invalid time");
        CollectionContract(collectionAddress).setAllowWithdrawTime(time);
    }

    // delegate call to CollectionContract from BaseContract
    // Should change CollectionContract to ICollectionContract (interface in the future)
    function executeArbitration(address payable collectionAddress, bytes16 _couponUUID, string memory side) public isArbitrator {
        CollectionContract(collectionAddress).executeArbitration(_couponUUID, side);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CollectionContract is Initializable {
    address payable public arbitrator;
    address payable public seller;
    bytes16 public collectionId;
    IERC20 public token;
    uint256 public allowWithdrawTime;
    struct Payment {
        uint256 amount;
        address purchaser;
        bool paid;
        uint256 paidAt;
        bool arbitrated;
        bool arbitrationExecuted;
        bool withdrawed;
    }
    struct CouponCode {
        bytes16 couponUUID;
        uint256 expiredAt;
        Payment payment;
    }
    mapping(bytes16 => CouponCode) public couponCodes;

    event CouponCreated(CouponCode couponCode);
    event ConfirmPayment(address buyer, bytes16 couponUUID, uint256 paidAt);
    event Withdraw(address to, uint256 amount, bytes16[] couponUUIDS);
    event ExecuteArbitration(bytes16 couponUUID, string side);
    event Arbitrated(bytes16 couponUUID);

    // Define who is seller of this collection
    // Define token payment for collection
    // Assign arbitrator
    function initialize(
        address owner,
        bytes16 _collectionId,
        address payable _seller,
        IERC20 _token,
        uint256 _allowWithdrawTime
    ) public payable initializer {
        require(arbitrator == address(0), "Non valid action");
        arbitrator = payable(owner);
        collectionId = _collectionId;
        seller = _seller;
        token = _token;
        allowWithdrawTime = _allowWithdrawTime;
    }

    modifier isSeller() {
        require(msg.sender == seller, "Not Seller");
        _;
    }

    modifier isArbitrator() {
        require(msg.sender == arbitrator, "Not arbitrator");
        _;
    }

    // validate couponCode Data when create coupon
    modifier validateCouponCodeData(CouponCode memory _couponCode) {
        require(
            _couponCode.couponUUID.length != 0,
            "Valid Coupon: uuid cant be 0"
        );
        _;
    }

    // validate couponCode payment Data when create coupon
    modifier validatePaymentData(Payment memory _payment) {
        require(_payment.amount != 0, "Valid Payment: amount cant be 0");
        _;
    }

    function createCoupons() public {}

    // Arbitrator can set withdraw time
    function setAllowWithdrawTime(uint256 time) public isArbitrator {
        allowWithdrawTime = time;
    }

    // Create new coupon with couponUUID
    // require couponUUID isn't existed before
    // parameters:
    // couponUUID: id of coupon
    // _couponCode: couponCode data
    // _payment: _payment information (amount)
    function createCoupon(
        bytes16 couponUUID,
        CouponCode memory _couponCode,
        Payment memory _payment
    )
        public
        validateCouponCodeData(_couponCode)
        validatePaymentData(_payment)
        isSeller
    {
        require(
            couponCodes[couponUUID].couponUUID == bytes16(0),
            "This couponUUID is existed"
        );
        require(couponUUID == _couponCode.couponUUID, "Not same coupon uuid");
        _payment.paid = false;
        _payment.arbitrated = false;
        _payment.arbitrationExecuted = false;
        _payment.withdrawed = false;
        _couponCode.payment = _payment;
        couponCodes[couponUUID] = _couponCode;
        emit CouponCreated(_couponCode);
    }

    // Buyer confirm payment after apply
    // require msg sender must be buyer
    // require payment wasn't paid
    // require approvel(buyer, collectionAddres) >= amount of coupon
    //
    // Parameter:
    // _couponUUID: coupon id
    // Event:
    // ConfirmPayment(buyer, couponUUID, couponUUID, paidAt);
    function confirmPayment(bytes16 _couponUUID) public {
        require(
            couponCodes[_couponUUID].couponUUID != bytes16(0),
            "This couponUUID isn't existed"
        );
        require(
            couponCodes[_couponUUID].payment.purchaser == address(0),
            "this coupon was paid by buyer"
        );
        require(
            couponCodes[_couponUUID].payment.paid == false,
            "This coupon was paid"
        );
        require(
            (couponCodes[_couponUUID].expiredAt != 0) &&
                (couponCodes[_couponUUID].expiredAt > block.timestamp),
            "This coupon was expired"
        );
        require(
            token.allowance(msg.sender, address(this)) >=
                couponCodes[_couponUUID].payment.amount,
            "Allowance not enough"
        );
        token.transferFrom(
            msg.sender,
            address(this),
            couponCodes[_couponUUID].payment.amount
        );
        couponCodes[_couponUUID].payment.purchaser = msg.sender;
        couponCodes[_couponUUID].payment.paid = true;
        couponCodes[_couponUUID].payment.paidAt = block.timestamp;
        emit ConfirmPayment(
            msg.sender,
            couponCodes[_couponUUID].couponUUID,
            couponCodes[_couponUUID].payment.paidAt
        );
    }

    // Check coupon paid or not
    // paramters:
    // _couponUUID: coupon id
    // return: bool paid
    function checkPaid(bytes16 _couponUUID) public view returns (bool paid) {
        paid = couponCodes[_couponUUID].payment.paid;
    }

    // Seller check total amount can withdraw
    // require payment made before 2 days, wasn't arbitrated to be withdrawed
    // msg.sender must be seller
    // Parameters:
    // _couponUUIDs: list coupon id need to check
    function withdrawableAmount(bytes16[] memory _couponUUIDs)
        public
        view
        isSeller
        returns (uint256 totalAmount)
    {
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            if (
                (couponCodes[_couponUUIDs[i]].payment.paid == true) &&
                (couponCodes[_couponUUIDs[i]].payment.arbitrated == false) &&
                (couponCodes[_couponUUIDs[i]].payment.withdrawed == false) &&
                (couponCodes[_couponUUIDs[i]].payment.paidAt +
                    allowWithdrawTime <=
                    block.timestamp)
            ) {
                totalAmount += couponCodes[_couponUUIDs[i]].payment.amount;
            }
        }
    }

    // Seller withdraw to specified address
    // require _to not be address(0)
    // require total amount must be larger than 0
    // parameters:
    // _to: to address
    // _couponUUIDs: list of coupon ids
    // Event:
    // Withdraw(to, amount);
    function withdrawTo(address _to, bytes16[] memory _couponUUIDs)
        public
        isSeller
        returns (uint256 totalAmount)
    {
        require(_to != address(0), "address cant be 0");
        bytes16[] memory withdrawedCoupons = new bytes16[](_couponUUIDs.length);
        uint8 count = 0;
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            if (
                (couponCodes[_couponUUIDs[i]].payment.paid == true) &&
                (couponCodes[_couponUUIDs[i]].payment.paidAt +
                    allowWithdrawTime <=
                    block.timestamp) &&
                (couponCodes[_couponUUIDs[i]].payment.arbitrated == false) &&
                (couponCodes[_couponUUIDs[i]].payment.withdrawed == false)
            ) {
                totalAmount += couponCodes[_couponUUIDs[i]].payment.amount;
                couponCodes[_couponUUIDs[i]].payment.withdrawed = true;
                withdrawedCoupons[count] = _couponUUIDs[i];
                count += 1;
            }
        }
        require(
            token.balanceOf(address(this)) >= totalAmount,
            "Collection balance insufficient"
        );
        require(totalAmount > 0, "Your withdrawable is 0");
        token.transfer(_to, totalAmount);
        emit Withdraw(_to, totalAmount, withdrawedCoupons);
    }

    // Buyer can request arbitration
    // require msg.sender must be purchaser of coupon
    // require coupon wasn't arbitrated before
    // require coupon was paid by purchaser, make arbitration to prevent seller withdraw
    function buyerArbitrate(bytes16 _couponUUID) public {
        require(
            msg.sender == couponCodes[_couponUUID].payment.purchaser,
            "You aren't buyer of this coupon"
        );
        require(
            couponCodes[_couponUUID].payment.arbitrated == false,
            "this coupon was arbitrated"
        );
        require(
            couponCodes[_couponUUID].payment.paid == true,
            "You can't request arbitration before pay"
        );
        require(
            couponCodes[_couponUUID].payment.withdrawed == false,
            "You can't request arbitration a withdrawed coupon"
        );
        couponCodes[_couponUUID].payment.arbitrated = true;
        emit Arbitrated(_couponUUID);
    }

    // Execute arbitration by arbitrator
    // Arbitrator can execute arbitration with 2 option: seller - buyer
    // Execute for seller: give tokens to seller address
    // Execute for buyer: refund tokens to buyer address
    // Event:
    // ExecuteArbitration(bytes16 _couponUUID, string side)
    function executeArbitration(bytes16 _couponUUID, string memory side)
        public
        isArbitrator
    {
        require(
            couponCodes[_couponUUID].payment.arbitrated == true,
            "this coupon wasn't arbitrated"
        );
        require(
            couponCodes[_couponUUID].payment.arbitrationExecuted == false,
            "this arbitration was executed"
        );
        if (keccak256(bytes(side)) == keccak256(bytes("seller"))) {
            token.transfer(seller, couponCodes[_couponUUID].payment.amount);
            couponCodes[_couponUUID].payment.arbitrationExecuted = true;
        } else if (keccak256(bytes(side)) == keccak256(bytes("buyer"))) {
            token.transfer(
                couponCodes[_couponUUID].payment.purchaser,
                couponCodes[_couponUUID].payment.amount
            );
            couponCodes[_couponUUID].payment.arbitrationExecuted = true;
        }

        emit ExecuteArbitration(_couponUUID, side);
    }

    receive() external payable {}

    fallback() external payable {
        // console.log("non function");
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
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

{
  "optimizer": {
    "enabled": true,
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