// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CollectionContract is Initializable {
    address payable public arbitrator;
    address payable public owner;
    bytes16 public collectionId;
    uint256 public allowWithdrawTime;
    struct Payment {
        uint256 amount;
        address token;
        address purchaser;
        bool paid;
        uint256 paidAt;
        bool arbitrated;
        bool arbitrationExecuted;
        bool withdrawed;
    }
    struct CouponCode {
        bytes16 couponUUID;
        uint256 issuedAt;
        uint256 expiredAt;
        address creatorAddress;
        Payment payment;
    }
    mapping(bytes16 => CouponCode) public couponCodes;
    mapping(address => bytes16[]) public ownerCoupons;

    event CouponCreated(
        bytes16 coupondUUID,
        uint256 issuedAt,
        uint256 expiredAt,
        address creatorAddress,
        address token,
        uint256 amount
    );
    event ConfirmPayment(address buyer, bytes16 couponUUID, uint256 paidAt);
    event Withdraw(address to, bytes16[] couponUUIDS);
    event ExecuteArbitration(bytes16 couponUUID, string side);
    event Arbitrated(bytes16 couponUUID);

    // Define who is seller of this collection
    // Define token payment for collection
    // Assign arbitrator
    function initialize(
        address _arbitrator,
        address _owner,
        bytes16 _collectionId,
        uint256 _allowWithdrawTime
    ) public payable initializer {
        require(arbitrator == address(0), "Non valid action");
        arbitrator = payable(_arbitrator);
        owner = payable(_owner);
        collectionId = _collectionId;
        allowWithdrawTime = _allowWithdrawTime;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Not Owner");
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
        bytes16 _couponUUID,
        uint256 _issuedAt,
        uint256 _expiredAt,
        uint256 _amount,
        address _token
    ) public {
        require(_couponUUID.length != 0, "invalid_coupon_uuid");
        require(
            couponCodes[_couponUUID].couponUUID == bytes16(0),
            "This couponUUID is existed"
        );
        require(_amount > 0, "invalid amount");
        {
            Payment memory _payment;
            CouponCode memory _couponCode;
            _payment.paid = false;
            _payment.arbitrated = false;
            _payment.arbitrationExecuted = false;
            _payment.withdrawed = false;
            _payment.amount = _amount;
            _payment.purchaser = address(0);
            _payment.paidAt = 0;
            _payment.token = _token;
            _couponCode.couponUUID = _couponUUID;
            _couponCode.payment = _payment;
            _couponCode.creatorAddress = msg.sender;
            _couponCode.expiredAt = _expiredAt;
            couponCodes[_couponUUID] = _couponCode;
        }
        ownerCoupons[msg.sender].push(_couponUUID);
        emit CouponCreated(
            _couponUUID,
            couponCodes[_couponUUID].issuedAt,
            couponCodes[_couponUUID].expiredAt,
            couponCodes[_couponUUID].creatorAddress,
            couponCodes[_couponUUID].payment.token,
            couponCodes[_couponUUID].payment.amount
        );
    }

    // Create multiple coupons
    function createCoupons(
        bytes16[] memory _couponUUIDs,
        uint256[] memory _issuedAts,
        uint256[] memory _expiredAts,
        uint256[] memory _amounts,
        address[] memory _tokens
    ) public {
        require(
            _couponUUIDs.length == _expiredAts.length &&
                _expiredAts.length == _amounts.length &&
                _couponUUIDs.length == _issuedAts.length &&
                _couponUUIDs.length == _tokens.length,
            "Invalid input data"
        );
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            createCoupon(
                _couponUUIDs[i],
                _issuedAts[i],
                _expiredAts[i],
                _amounts[i],
                _tokens[i]
            );
        }
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
    function confirmPayment(bytes16[] memory _couponUUIDs) public payable {
        uint256 total_value = msg.value;
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            bytes16 _couponUUID = _couponUUIDs[i];
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
            if (couponCodes[_couponUUID].payment.token == address(0)) {
                require(
                    total_value >= couponCodes[_couponUUID].payment.amount,
                    "invalid_balance"
                );
                total_value =
                    total_value -
                    couponCodes[_couponUUID].payment.amount;
            } else {
                IERC20 token = IERC20(couponCodes[_couponUUID].payment.token);
                require(
                    token.allowance(msg.sender, address(this)) >=
                        couponCodes[_couponUUID].payment.amount,
                    "invalid_balance"
                );
                token.transferFrom(
                    msg.sender,
                    address(this),
                    couponCodes[_couponUUID].payment.amount
                );
            }
            couponCodes[_couponUUID].payment.purchaser = msg.sender;
            couponCodes[_couponUUID].payment.paid = true;
            couponCodes[_couponUUID].payment.paidAt = block.timestamp;
            emit ConfirmPayment(
                msg.sender,
                couponCodes[_couponUUID].couponUUID,
                couponCodes[_couponUUID].payment.paidAt
            );
        }
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
    function withdrawableAmount(bytes16 _couponUUID)
        public
        view
        returns (uint256 totalAmount, address token)
    {
        {
            CouponCode memory _couponCode = couponCodes[_couponUUID];
            require(_couponCode.payment.paid == true, "not_paid");
            require(_couponCode.creatorAddress == msg.sender, "not_creater");
            require(_couponCode.payment.arbitrated == false, "atribating");
            require(_couponCode.payment.withdrawed == false, "withdrawed");
            require(
                _couponCode.payment.paidAt + allowWithdrawTime <=
                    block.timestamp,
                "waiting_allow_time"
            );
            totalAmount = _couponCode.payment.amount;
            token = _couponCode.payment.token;
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
    function withdrawTo(address _to, bytes16[] memory _couponUUIDs) public {
        require(_to != address(0), "address cant be 0");
        bytes16[] memory withdrawedCoupons = new bytes16[](_couponUUIDs.length);
        uint8 count = 0;
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            if (
                (couponCodes[_couponUUIDs[i]].payment.paid == true) &&
                (couponCodes[_couponUUIDs[i]].creatorAddress == msg.sender) &&
                (couponCodes[_couponUUIDs[i]].payment.paidAt +
                    allowWithdrawTime <=
                    block.timestamp) &&
                (couponCodes[_couponUUIDs[i]].payment.arbitrated == false) &&
                (couponCodes[_couponUUIDs[i]].payment.withdrawed == false)
            ) {
                if (couponCodes[_couponUUIDs[i]].payment.token == address(0)) {
                    require(
                        address(this).balance >=
                            couponCodes[_couponUUIDs[i]].payment.amount,
                        "invalid_balance"
                    );
                    payable(_to).transfer(
                        couponCodes[_couponUUIDs[i]].payment.amount
                    );
                } else {
                    IERC20 token = IERC20(
                        couponCodes[_couponUUIDs[i]].payment.token
                    );
                    require(
                        token.balanceOf(address(this)) >=
                            couponCodes[_couponUUIDs[i]].payment.amount,
                        "invalid_balance"
                    );
                    token.transfer(
                        _to,
                        couponCodes[_couponUUIDs[i]].payment.amount
                    );
                }

                couponCodes[_couponUUIDs[i]].payment.withdrawed = true;
                withdrawedCoupons[count] = _couponUUIDs[i];
                count += 1;
            }
        }
        emit Withdraw(_to, withdrawedCoupons);
    }

    // Buyer can request arbitration
    // require msg.sender must be purchaser of coupon
    // require coupon wasn't arbitrated before
    // require coupon was paid by purchaser, make arbitration to prevent seller withdraw
    function buyerArbitrate(bytes16[] memory _couponUUIDs) public {
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            bytes16 _couponUUID = _couponUUIDs[i];
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
    }

    // Execute arbitration by arbitrator
    // Arbitrator can execute arbitration with 2 option: seller - buyer
    // Execute for seller: give tokens to seller address
    // Execute for buyer: refund tokens to buyer address
    // Event:
    // ExecuteArbitration(bytes16 _couponUUID, string side)
    function executeArbitration(
        bytes16[] memory _couponUUIDs,
        string memory side
    ) public isArbitrator {
        for (uint256 i = 0; i < _couponUUIDs.length; i++) {
            bytes16 _couponUUID = _couponUUIDs[i];
            require(
                couponCodes[_couponUUID].payment.arbitrated == true,
                "this coupon wasn't arbitrated"
            );
            require(
                couponCodes[_couponUUID].payment.arbitrationExecuted == false,
                "this arbitration was executed"
            );
            IERC20 token = IERC20(couponCodes[_couponUUID].payment.token);
            if (keccak256(bytes(side)) == keccak256(bytes("seller"))) {
                token.transfer(
                    couponCodes[_couponUUID].creatorAddress,
                    couponCodes[_couponUUID].payment.amount
                );
                couponCodes[_couponUUID].payment.arbitrationExecuted = true;
                couponCodes[_couponUUID].payment.withdrawed = true;
            } else if (keccak256(bytes(side)) == keccak256(bytes("buyer"))) {
                token.transfer(
                    couponCodes[_couponUUID].payment.purchaser,
                    couponCodes[_couponUUID].payment.amount
                );
                couponCodes[_couponUUID].payment.arbitrationExecuted = true;
                couponCodes[_couponUUID].payment.withdrawed = true;
            }

            emit ExecuteArbitration(_couponUUID, side);
        }
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

