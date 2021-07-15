// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CollectionContract is Initializable {
    address payable public arbitrator;
    address payable public seller;
    string public collectionId;
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
        uint256 nonce;
        string couponUUID;
        uint256 expiredAt;
        Payment payment;
    }
    mapping(uint256 => CouponCode) couponCodes;

    event ConfirmPayment(address buyer, uint256 nonce, string couponUUID, uint256 paidAt);
    event Withdraw(address to, uint256 amount);
    event ExecuteArbitration(uint256 nonce, string side);
    // Define who is seller of this collection
    // Define token payment for collection
    // Assign arbitrator
    function initialize(
        address owner,
        string memory _collectionId,
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
        require(_couponCode.nonce != 0, "Valid Coupon: nonce cant be 0");
        require(bytes(_couponCode.couponUUID).length != 0, "Valid Coupon: uuid cant be 0");
        _;
    }

    // validate couponCode payment Data when create coupon
    modifier validatePaymentData(Payment memory _payment) {
        require(_payment.amount != 0, "Valid Payment: amount cant be 0");
        _;
    }

    function createCoupons() public {}

    // Get coupon info by nonce
    function getCoupon(uint256 _nonce) external view returns(CouponCode memory couponCode) {
        couponCode = couponCodes[_nonce];
    }

    // Arbitrator can set withdraw time
    function setAllowWithdrawTime(uint256 time) public isArbitrator {
        allowWithdrawTime = time;
    }

    // Create new coupon with nonce
    // require nonce isn't existed before
    // parameters:
    // nonce: id of coupon
    // _couponCode: couponCode data
    // _payment: _payment information (amount)
    function createCoupon(
        uint256 nonce,
        CouponCode memory _couponCode,
        Payment memory _payment) public
        validateCouponCodeData(_couponCode)
        validatePaymentData(_payment) isSeller {
            require(bytes(couponCodes[nonce].couponUUID).length == 0, "This nonce is existed");
            _payment.paid = false;
            _payment.arbitrated = false;
            _payment.arbitrationExecuted = false;
            _payment.withdrawed = false;
            _couponCode.payment = _payment;
            couponCodes[nonce] = _couponCode;
    }

    // Buyer confirm payment after apply
    // require msg sender must be buyer
    // require payment wasn't paid
    // require approvel(buyer, collectionAddres) >= amount of coupon
    //
    // Parameter:
    // _nonce: coupon id
    // Event:
    // ConfirmPayment(buyer, nonce, couponUUID, paidAt);
    function confirmPayment(uint256 _nonce) public {
        // require(msg.sender == couponCodes[_nonce].payment.purchaser, "You are not buyer");
        require(bytes(couponCodes[_nonce].couponUUID).length != 0, "This nonce isn't existed");
        require(couponCodes[_nonce].payment.purchaser == address(0), "this coupon was paid by buyer");
        require(couponCodes[_nonce].payment.paid == false, "This coupon was paid");
        require((couponCodes[_nonce].expiredAt != 0) && (couponCodes[_nonce].expiredAt > block.timestamp), "This coupon was expired");
        require(token.allowance(msg.sender, address(this)) >= couponCodes[_nonce].payment.amount, "Allowance not enough");
        token.transferFrom(msg.sender, address(this), couponCodes[_nonce].payment.amount);
        couponCodes[_nonce].payment.purchaser = msg.sender;
        couponCodes[_nonce].payment.paid = true;
        couponCodes[_nonce].payment.paidAt = block.timestamp;
        emit ConfirmPayment(msg.sender, _nonce, couponCodes[_nonce].couponUUID, couponCodes[_nonce].payment.paidAt);
    }

    // Check coupon paid or not
    // paramters:
    // _nonce: coupon id
    // return: bool paid
    function checkPaid(uint256 _nonce) public view returns(bool paid) {
        paid = couponCodes[_nonce].payment.paid;
    }

    // Seller check total amount can withdraw
    // require payment made before 2 days, wasn't arbitrated to be withdrawed
    // msg.sender must be seller
    // Parameters:
    // _nonces: list coupon id need to check
    function withdrawableAmount(uint256[] memory _nonces) public isSeller view returns(uint256 totalAmount){
        for(uint i = 0; i < _nonces.length; i++) {
            if ((couponCodes[_nonces[i]].payment.paid == true) &&
            (couponCodes[_nonces[i]].payment.arbitrated == false) &&
            (couponCodes[_nonces[i]].payment.withdrawed == false) &&
            (couponCodes[_nonces[i]].payment.paidAt + allowWithdrawTime <= block.timestamp)) {
                totalAmount += couponCodes[_nonces[i]].payment.amount;
            }
        }
    }

    // Seller withdraw to specified address
    // require _to not be address(0)
    // require total amount must be larger than 0
    // parameters:
    // _to: to address
    // _nonces: list of coupon ids
    // Event:
    // Withdraw(to, amount);
    function withdrawTo(address _to, uint256[] memory _nonces) public isSeller returns(uint256 totalAmount){
        require(_to != address(0), "address cant be 0");
        for(uint i = 0; i < _nonces.length; i++) {
            if ((couponCodes[_nonces[i]].payment.paid == true) &&
            (couponCodes[_nonces[i]].payment.paidAt + allowWithdrawTime <= block.timestamp ) &&
            (couponCodes[_nonces[i]].payment.arbitrated == false) && 
            (couponCodes[_nonces[i]].payment.withdrawed == false)) {
                totalAmount += couponCodes[_nonces[i]].payment.amount;
                couponCodes[_nonces[i]].payment.withdrawed = true;
            }
        }
        require(token.balanceOf(address(this)) >= totalAmount, "Collection balance insufficient");
        require(totalAmount > 0, "Your withdrawable is 0");
        token.transfer(_to, totalAmount);
        emit Withdraw(_to, totalAmount);
    }

    // Buyer can request arbitration
    // require msg.sender must be purchaser of coupon
    // require coupon wasn't arbitrated before
    // require coupon was paid by purchaser, make arbitration to prevent seller withdraw
    function buyerArbitrate(uint256 _nonce) public {
        require(msg.sender == couponCodes[_nonce].payment.purchaser, "You aren't buyer of this coupon");
        require(couponCodes[_nonce].payment.arbitrated == false, "this coupon was arbitrated");
        require(couponCodes[_nonce].payment.paid == true, "You can't request arbitration before pay");
        require(couponCodes[_nonce].payment.withdrawed == false, "You can't request arbitration a withdrawed coupon");
        couponCodes[_nonce].payment.arbitrated = true;
    }

    // Execute arbitration by arbitrator
    // Arbitrator can execute arbitration with 2 option: seller - buyer
    // Execute for seller: give tokens to seller address
    // Execute for buyer: refund tokens to buyer address
    // Event:
    // ExecuteArbitration(uint256 nonce, string side)
    function executeArbitration(uint256 _nonce, string memory side) public isArbitrator {
        require(couponCodes[_nonce].payment.arbitrated == true, "this coupon wasn't arbitrated");
        require(couponCodes[_nonce].payment.arbitrationExecuted == false, "this arbitration was executed");
        if (keccak256(bytes(side)) == keccak256(bytes("seller"))) {
            token.transfer(seller, couponCodes[_nonce].payment.amount);
            couponCodes[_nonce].payment.arbitrationExecuted = true;
        } else if (keccak256(bytes(side)) == keccak256(bytes("buyer"))) {
            token.transfer(couponCodes[_nonce].payment.purchaser, couponCodes[_nonce].payment.amount);
            couponCodes[_nonce].payment.arbitrationExecuted = true;
        }

        emit ExecuteArbitration(_nonce, side);
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

// solhint-disable-next-line compiler-version
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