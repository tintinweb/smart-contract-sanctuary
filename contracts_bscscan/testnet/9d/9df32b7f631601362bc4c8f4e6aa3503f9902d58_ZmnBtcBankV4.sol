// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../lib/SafeMath16.sol";
import "../lib/SafeBEP20.sol";
import "../utils/ArrayUniqueUint256.sol";

contract ZmnBtcBankV4 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMath16 for uint16;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    event NewRate(uint256 rate);
    event Borrow(address indexed borrower, uint256 amountCollateralZmn);
    event Repay(
        address indexed borrower,
        uint256 amountCollateralZmn,
        uint256 amountBorrowBtcb
    );

    // =========================================
    // =========================================
    // =========================================
    // V1

    struct RateHistory {
        uint256 rate; // Rate for lending btcb by using zmn
        uint256 circulateZmn;
        uint256 accIncomingBtcb;
        uint256 accBorrowingBtcb;
        uint256 accRepaidBtcb;
        uint256 ongoingBorrowingBtcb;
        uint256 accRedeemFeeZmn;
        uint256 accTransactionFeeZmn;
        uint256 accOverdueCollateralZmn;
        uint256 epoch;
    }

    struct Profile {
        uint16 redeemFeeBP; // Lending fee in basis points
        uint256 transactionFee; // Transaction fee in wei
        uint256 period; // Block period to repay the loan
        bool enable; // Enable for borrow?
    }

    struct LoanAgreement {
        uint256 loanId;
        address borrower;
        uint256 profile; // Lending profile
        uint256 startTime; // Epoch time in second
        uint256 endTime; // Epoch time in second
        uint256 amountCollateralZmn; // Amount of zmn as collateral
        uint256 amountBorrowBtcb; // Amount of borrowing BTCB
        uint256 amountRedeemFeeZmn; // Amount of redeem fee
        uint256 amountTransactionFeeZmn; // Amount of transaction fee
        uint16 status; // 0: Ongoing, 1: End without repay BTCB, 2: End with repay BTCB
    }

    // The ZMINE TOKEN!
    IBEP20 public zmn;

    // The BTCB TOKEN!
    IBEP20 public btcb;

    // Min and max
    uint256 public minCollateralZmnAmount;
    uint256 public maxCollateralZmnAmount;

    // Lending rate
    RateHistory[] public rates;

    // Temporary data for calculation
    RateHistory public calcRate;

    // Lending profile.
    Profile[] public profiles;

    // Loan agreement
    // index as _loanId
    LoanAgreement[] public loanAgreements;

    // List of loan agreement for each user
    mapping(address => uint256[]) loanAgreementsByUser;
    // Ongoing loan agreement of all users
    // for update agreement status
    // calculate zmn avaialable for burn before update rate.
    ArrayUniqueUint256 loanAgreementsWithOngoingStatus;

    // Addresses
    address public redeemFeeAddress;
    address public transactionFeeAddress;
    address public overdueCollateralAddress;

    // =========================================
    // =========================================
    // =========================================
    // V2

    uint256 public newVariableInV2;

    // =========================================
    // =========================================
    // =========================================
    // V3

    event BorrowV3(
        address indexed borrower,
        uint256 pid,
        uint256 loanId,
        uint256 amountCollateralZmn,
        uint256 amountBorrowBtcb
    );

    event RepayV3(
        address indexed borrower,
        uint256 loanId,
        uint256 amountCollateralZmn,
        uint256 amountBorrowBtcb
    );

    // =========================================
    // =========================================
    // =========================================
    // V4

    bool public paused;

    // =========================================
    // =========================================
    // =========================================
    // Upgradeable

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        IBEP20 _zmn,
        IBEP20 _btcb,
        address _redeemFeeAddress,
        address _transactionFeeAddress,
        address _overdueCollateralAddress
    ) public initializer {
        __Ownable_init();
        zmn = _zmn;
        btcb = _btcb;

        minCollateralZmnAmount = 10000 ether;
        maxCollateralZmnAmount = 100000 ether;

        // Addresses
        redeemFeeAddress = _redeemFeeAddress;
        transactionFeeAddress = _transactionFeeAddress;
        overdueCollateralAddress = _overdueCollateralAddress;

        // create contract instance
        loanAgreementsWithOngoingStatus = new ArrayUniqueUint256();
    }

    // ======================
    // ======================

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    // ======================
    // ======================
    // migration

    function manualAddRate(
        uint256 _rate,
        uint256 _circulateZmn,
        uint256 _accIncomingBtcb,
        uint256 _accBorrowingBtcb,
        uint256 _accRepaidBtcb,
        uint256 _ongoingBorrowingBtcb,
        uint256 _accRedeemFeeZmn,
        uint256 _accTransactionFeeZmn,
        uint256 _accOverdueCollateralZmn
    ) public onlyOwner {
        RateHistory memory _r = RateHistory({
            rate: _rate,
            circulateZmn: _circulateZmn,
            accRedeemFeeZmn: _accRedeemFeeZmn,
            accTransactionFeeZmn: _accTransactionFeeZmn,
            accOverdueCollateralZmn: _accOverdueCollateralZmn,
            accIncomingBtcb: _accIncomingBtcb,
            accBorrowingBtcb: _accBorrowingBtcb,
            accRepaidBtcb: _accRepaidBtcb,
            ongoingBorrowingBtcb: _ongoingBorrowingBtcb,
            epoch: block.timestamp
        });
        rates.push(_r);

        // update calc rate
        RateHistory memory _calcRate;
        _calcRate.accRedeemFeeZmn = _r.accRedeemFeeZmn;
        _calcRate.accTransactionFeeZmn = _r.accTransactionFeeZmn;
        _calcRate.accOverdueCollateralZmn = _r.accOverdueCollateralZmn;
        _calcRate.accBorrowingBtcb = _r.accBorrowingBtcb;
        _calcRate.accRepaidBtcb = _r.accRepaidBtcb;
        _calcRate.ongoingBorrowingBtcb = _r.ongoingBorrowingBtcb;
        calcRate = _calcRate;
    }

    function manualEditHistoryRate(
        uint256 _index,
        uint256 _rate,
        uint256 _circulateZmn,
        uint256 _accIncomingBtcb,
        uint256 _accBorrowingBtcb,
        uint256 _accRepaidBtcb,
        uint256 _ongoingBorrowingBtcb,
        uint256 _accRedeemFeeZmn,
        uint256 _accTransactionFeeZmn,
        uint256 _accOverdueCollateralZmn
    ) public onlyOwner {
        // not allow to edit current rate
        require(_index < rates.length - 1);
        RateHistory storage _r = rates[_index];
        _r.rate = _rate;
        _r.circulateZmn = _circulateZmn;
        _r.accIncomingBtcb = _accIncomingBtcb;
        _r.accBorrowingBtcb = _accBorrowingBtcb;
        _r.accRepaidBtcb = _accRepaidBtcb;
        _r.ongoingBorrowingBtcb = _ongoingBorrowingBtcb;
        _r.accRedeemFeeZmn = _accRedeemFeeZmn;
        _r.accTransactionFeeZmn = _accTransactionFeeZmn;
        _r.accOverdueCollateralZmn = _accOverdueCollateralZmn;
    }

    // ======================
    // ======================
    // profile

    function addProfile(
        uint16 _redeemFeeBP,
        uint256 _transactionFee,
        uint256 _period,
        bool _enable
    ) public onlyOwner {
        require(_redeemFeeBP <= 10000, "Invalid redeemFeeBP basis points");
        profiles.push(
            Profile({
                redeemFeeBP: _redeemFeeBP,
                transactionFee: _transactionFee,
                period: _period,
                enable: _enable
            })
        );
    }

    function setProfile(
        uint256 _pid,
        uint16 _redeemFeeBP,
        uint256 _period,
        bool _enable
    ) public onlyOwner {
        require(_pid < profiles.length, "Profile does not found");
        require(_redeemFeeBP <= 10000, "Invalid redeemFeeBP basis points");
        profiles[_pid].redeemFeeBP = _redeemFeeBP;
        profiles[_pid].period = _period;
        profiles[_pid].enable = _enable;
    }

    function profilesLength() external view returns (uint256) {
        return profiles.length;
    }

    // ======================
    // ======================
    // rate

    function previewRate(uint256 _circulateZmn, uint256 _accIncomingBtcb)
        public
        view
        returns (RateHistory memory)
    {
        uint256 availableBtcb = _accIncomingBtcb
            .add(calcRate.accRepaidBtcb)
            .sub(calcRate.accBorrowingBtcb)
            .add(calcRate.ongoingBorrowingBtcb);

        uint256 _calcRate = availableBtcb.mul(1e18).div(_circulateZmn);

        RateHistory memory _rate = RateHistory({
            rate: _calcRate,
            circulateZmn: _circulateZmn,
            accRedeemFeeZmn: calcRate.accRedeemFeeZmn,
            accTransactionFeeZmn: calcRate.accTransactionFeeZmn,
            accOverdueCollateralZmn: calcRate.accOverdueCollateralZmn,
            accIncomingBtcb: _accIncomingBtcb,
            accBorrowingBtcb: calcRate.accBorrowingBtcb,
            accRepaidBtcb: calcRate.accRepaidBtcb,
            ongoingBorrowingBtcb: calcRate.ongoingBorrowingBtcb,
            epoch: block.timestamp
        });
        return _rate;
    }

    function addRate(uint256 _circulateZmn, uint256 _accIncomingBtcb)
        public
        onlyOwner
    {
        RateHistory memory _rate = previewRate(_circulateZmn, _accIncomingBtcb);
        rates.push(_rate);
    }

    function getRate() public view returns (uint256) {
        RateHistory memory _rate = rates[rates.length - 1];
        return _rate.rate;
    }

    function ratesLength() external view returns (uint256) {
        return rates.length;
    }

    // ======================
    // ======================
    // Loan agreements

    function loanAgreementsLength() external view returns (uint256) {
        return loanAgreements.length;
    }

    function loanAgreementsByUserLength(address _user)
        external
        view
        returns (uint256)
    {
        uint256[] memory _list = loanAgreementsByUser[_user];
        return _list.length;
    }

    function loanAgreementsWithOngoingStatusLength()
        external
        view
        returns (uint256)
    {
        return loanAgreementsWithOngoingStatus.length();
    }

    function getLoanAgreements(uint256 _loanId)
        external
        view
        returns (LoanAgreement memory)
    {
        return loanAgreements[_loanId];
    }

    function getLoanAgreementsByUser(address _user, uint256 _index)
        external
        view
        returns (LoanAgreement memory)
    {
        uint256[] memory _list = loanAgreementsByUser[_user];
        uint256 _loanId = _list[_index];
        return loanAgreements[_loanId];
    }

    function getLoanAgreementsWithOngoingStatus(uint256 _index)
        external
        view
        returns (LoanAgreement memory)
    {
        uint256 _loanId = loanAgreementsWithOngoingStatus.get(_index);
        return loanAgreements[_loanId];
    }

    function setMinCollateralZmnAmount(uint256 _minCollateralZmnAmount)
        public
        onlyOwner
    {
        require(
            _minCollateralZmnAmount <= maxCollateralZmnAmount,
            "More than max value"
        );
        require(
            _minCollateralZmnAmount % (10000 ether) == 0,
            "Must be a multiplier of 10000"
        );
        minCollateralZmnAmount = _minCollateralZmnAmount;
    }

    function setMaxCollateralZmnAmount(uint256 _maxCollateralZmnAmount)
        public
        onlyOwner
    {
        require(
            _maxCollateralZmnAmount >= minCollateralZmnAmount,
            "Less than min value"
        );
        require(
            _maxCollateralZmnAmount % (10000 ether) == 0,
            "Must be a multiplier of 10000"
        );
        maxCollateralZmnAmount = _maxCollateralZmnAmount;
    }

    // ======================
    // ======================

    // return
    // ** amountIn (amount of zmn to transfer)
    // amountOut (amount of btcb to transfer)
    // redeemFee
    // transactionFee
    function _previewBorrow(uint256 _pid, uint256 _amountCollateralZmn)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Profile memory profile = profiles[_pid];

        // redeem fee
        uint256 redeemFee = 0;
        if (profile.redeemFeeBP > 0) {
            redeemFee = _amountCollateralZmn.mul(profile.redeemFeeBP).div(
                10000
            );
        }

        // amount of btcb to transfer
        uint256 amountOut = _amountCollateralZmn.mul(getRate()).div(1e18);
        // use exactly 8 digit
        amountOut = amountOut.div(1e10).mul(1e10);
        return (amountOut, redeemFee, profile.transactionFee);
    }

    function previewBorrow(uint256 _pid, uint256 _amountCollateralZmn)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (
            _amountCollateralZmn < minCollateralZmnAmount ||
            _amountCollateralZmn > maxCollateralZmnAmount
        ) {
            return (0, 0, 0);
        }

        if (_amountCollateralZmn % (10000 ether) != 0) {
            return (0, 0, 0);
        }

        Profile memory profile = profiles[_pid];
        if (!profile.enable) {
            return (0, 0, 0);
        }
        return _previewBorrow(_pid, _amountCollateralZmn);
    }

    function borrow(
        uint256 _pid,
        uint256 _amountCollateralZmn,
        uint256 _minAmountOut
    ) public whenNotPaused {
        require(
            _amountCollateralZmn >= minCollateralZmnAmount,
            "Minimum amount of collateral ZMN"
        );

        require(
            _amountCollateralZmn <= maxCollateralZmnAmount,
            "Maximum amount of collateral ZMN"
        );

        require(
            _amountCollateralZmn % (10000 ether) == 0,
            "Must be a multiplier of 10000"
        );

        Profile memory profile = profiles[_pid];
        require(profile.enable, "Lending profile has been suspended");

        uint16 _status = (profile.period == 0) ? 1 : 0;

        // calculate
        (
            uint256 amountOut,
            uint256 redeemFee,
            uint256 transactionFee
        ) = _previewBorrow(_pid, _amountCollateralZmn);
        require(amountOut >= _minAmountOut, "Min amountOut");

        if (_status == 1) {
            // no repayment
            // automatically set to overdue
            zmn.safeTransferFrom(
                address(msg.sender),
                address(overdueCollateralAddress),
                _amountCollateralZmn
            );
        } else {
            // transfer zmn from borrower as collateral
            zmn.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amountCollateralZmn
            );
        }

        if (redeemFee > 0) {
            zmn.safeTransferFrom(
                address(msg.sender),
                address(redeemFeeAddress),
                redeemFee
            );
        }
        if (transactionFee > 0) {
            zmn.safeTransferFrom(
                address(msg.sender),
                address(transactionFeeAddress),
                transactionFee
            );
        }

        // send btcb to borrower
        btcb.safeTransfer(address(msg.sender), amountOut);

        // create loan agreement
        uint256 _loanId = loanAgreements.length;
        LoanAgreement memory _loanAgreement = LoanAgreement({
            loanId: _loanId,
            borrower: msg.sender,
            profile: _pid,
            startTime: block.timestamp,
            endTime: block.timestamp.add(profile.period),
            amountCollateralZmn: _amountCollateralZmn,
            amountRedeemFeeZmn: redeemFee,
            amountTransactionFeeZmn: profile.transactionFee,
            amountBorrowBtcb: amountOut,
            status: _status
        });

        // add to list
        loanAgreements.push(_loanAgreement);

        // add to user list
        uint256[] storage _loanAgreementsByUser = loanAgreementsByUser[
            msg.sender
        ];
        _loanAgreementsByUser.push(_loanId);

        // update calc information
        if (redeemFee > 0) {
            calcRate.accRedeemFeeZmn = calcRate.accRedeemFeeZmn.add(redeemFee);
        }
        if (profile.transactionFee > 0) {
            calcRate.accTransactionFeeZmn = calcRate.accTransactionFeeZmn.add(
                profile.transactionFee
            );
        }
        calcRate.accBorrowingBtcb = calcRate.accBorrowingBtcb.add(amountOut);

        if (_status == 1) {
            // no repayment
            // automatically set to overdue
            calcRate.accOverdueCollateralZmn = calcRate
                .accOverdueCollateralZmn
                .add(_amountCollateralZmn);
        } else {
            // add to ongoing list
            loanAgreementsWithOngoingStatus.add(_loanId);

            calcRate.ongoingBorrowingBtcb = calcRate.ongoingBorrowingBtcb.add(
                amountOut
            );
        }

        emit BorrowV3(
            address(msg.sender),
            _pid,
            _loanId,
            _amountCollateralZmn,
            amountOut
        );
    }

    // Repay the loan
    // Allow user to pay for other users. The collateral zmn will be returned back to the borrower.
    function _repay(uint256 _loanId, uint256 _confirmAmountIn) internal {
        require(_loanId < loanAgreements.length, "No loan agreement");
        update(_loanId);
        LoanAgreement storage _loanAgreement = loanAgreements[_loanId];
        require(_loanAgreement.status == 0, "Loan agreement ended");
        require(
            _confirmAmountIn == _loanAgreement.amountBorrowBtcb,
            "Confirm the amount does not match"
        );

        // transfer BTCB to contract
        btcb.safeTransferFrom(
            address(msg.sender),
            address(this),
            _loanAgreement.amountBorrowBtcb
        );

        // transfer ZMN back to borrower
        zmn.safeTransfer(
            _loanAgreement.borrower,
            _loanAgreement.amountCollateralZmn
        );

        // End with loan repayment
        _loanAgreement.status = 2;

        // remove from ongoing
        loanAgreementsWithOngoingStatus.deleteByValue(_loanId);

        // update calc information
        calcRate.accRepaidBtcb = calcRate.accRepaidBtcb.add(
            _loanAgreement.amountBorrowBtcb
        );
        calcRate.ongoingBorrowingBtcb = calcRate.ongoingBorrowingBtcb.sub(
            _loanAgreement.amountBorrowBtcb
        );

        emit RepayV3(
            address(msg.sender),
            _loanId,
            _loanAgreement.amountCollateralZmn,
            _loanAgreement.amountBorrowBtcb
        );
    }

    function repay(uint256 _loanId, uint256 _confirmAmountIn)
        public
        whenNotPaused
    {
        LoanAgreement memory _loanAgreement = loanAgreements[_loanId];
        require(_loanAgreement.borrower == address(msg.sender), "Not borrower");
        _repay(_loanId, _confirmAmountIn);
    }

    function repayFor(uint256 _loanId, uint256 _confirmAmountIn)
        public
        whenNotPaused
    {
        LoanAgreement memory _loanAgreement = loanAgreements[_loanId];
        require(
            _loanAgreement.borrower != address(msg.sender),
            "Repay for others"
        );
        _repay(_loanId, _confirmAmountIn);
    }

    // ======================
    // ======================

    function update(uint256 _loanId) public whenNotPaused {
        require(_loanId < loanAgreements.length, "No loan agreement");
        LoanAgreement storage _loanAgreement = loanAgreements[_loanId];
        if (_loanAgreement.status == 0) {
            if (block.timestamp > _loanAgreement.endTime) {
                // End without repay BTCB (overdue)
                _loanAgreement.status = 1;

                // remove from ongoing
                loanAgreementsWithOngoingStatus.deleteByValue(_loanId);

                // update calc information
                calcRate.accOverdueCollateralZmn = calcRate
                    .accOverdueCollateralZmn
                    .add(_loanAgreement.amountCollateralZmn);

                calcRate.ongoingBorrowingBtcb = calcRate
                    .ongoingBorrowingBtcb
                    .sub(_loanAgreement.amountBorrowBtcb);

                // transfer collateral ZMN to overdue address
                // waiting for burn
                zmn.safeTransfer(
                    address(overdueCollateralAddress),
                    _loanAgreement.amountCollateralZmn
                );
            }
        }
    }

    function massUpdateOngoing() public whenNotPaused {
        uint256 len = loanAgreementsWithOngoingStatus.length();
        if (len > 0) {
            // loop backward
            for (uint256 i = len; i > 0; i--) {
                uint256 _loanId = loanAgreementsWithOngoingStatus.get(i - 1);
                update(_loanId);
            }
        }
    }

    // Withdraw BTCB and ZMN to safe wallet. EMERGENCY ONLY.
    function emergencyWithdrawToOwner() public onlyOwner {
        // transfter all zmn to owner
        uint256 balanceOfZmn = zmn.balanceOf(address(this));
        if (balanceOfZmn > 0) {
            zmn.safeTransfer(address(msg.sender), balanceOfZmn);
        }

        // transfter all btcb to owner
        uint256 balanceOfBtcb = btcb.balanceOf(address(this));
        if (balanceOfBtcb > 0) {
            btcb.safeTransfer(address(msg.sender), balanceOfBtcb);
        }
    }

    // Set address by the owner.
    function setRedeemFeeAddress(address _redeemFeeAddress) public onlyOwner {
        redeemFeeAddress = _redeemFeeAddress;
    }

    function setTransactionFeeAddress(address _transactionFeeAddress)
        public
        onlyOwner
    {
        transactionFeeAddress = _transactionFeeAddress;
    }

    function setOverdueCollateralAddress(address _overdueCollateralAddress)
        public
        onlyOwner
    {
        overdueCollateralAddress = _overdueCollateralAddress;
    }

    // ======================
    // ======================
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

library SafeMath16 {
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "../interface/IBEP20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ArrayUniqueUint256 {
    // array of value
    uint256[] _array;

    // value to indice (start from 1)
    mapping(uint256 => uint256) public mapValueToIndex;

    function add(uint256 _val) public returns (uint256) {
        require(mapValueToIndex[_val] == 0, "Value is existed.");

        // add to array
        _array.push(_val);

        // store index into map
        // index number start from 1
        uint256 _index = _array.length;
        mapValueToIndex[_val] = _index;

        // return length of array
        return _array.length;
    }

    function deleteByValue(uint256 _val) public returns (uint256) {
        require(mapValueToIndex[_val] > 0, "Value does not existed.");
        uint256 _index = mapValueToIndex[_val];

        // index number start from 1
        require((_index - 1) < _array.length);

        // swap
        if (_index != _array.length) {
            // swap last to index
            _array[(_index - 1)] = _array[_array.length - 1];
            // update map
            mapValueToIndex[_array[(_index - 1)]] = _index;
        }
        // remove last
        _array.pop();

        // remove from map
        delete mapValueToIndex[_val];

        // return length of array
        return _array.length;
    }

    function containValue(uint256 _val) public view returns (bool) {
        return (mapValueToIndex[_val] > 0);
    }

    function length() public view returns (uint256) {
        return _array.length;
    }

    function get(uint256 i) public view returns (uint256) {
        return _array[i];
    }

    function toArray() public view returns (uint256[] memory) {
        return _array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

