// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICryptoPunks.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IStableCoin.sol";

/**
 * NFT lending vault
 * Owner: dao address
 */
contract NFTVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event PositionOpened(address owner, uint256 index);
    event Borrowed(address owner, uint256 index, uint256 amount);
    event Repaid(address owner, uint256 index, uint256 amount);
    event PositionClosed(address owner, uint256 index);
    event Liquidated(address liquidator, address owner, uint256 index);
    event Repurchased(address owner, uint256 index);

    enum PunkType {
        FLOOR,
        APE,
        ALIENS,
        CUSTOM
    }

    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtInterest;
        uint256 debtInterestBurn;
        uint256 debtUpdatedAt;
        bool liquidated;
    }

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    uint256 constant SECS_YEAR = 86400 * 365;

    address public stablecoin;
    address public cryptopunks;

    address public oracle;

    Rate public debtInterestApr;
    Rate public creditLimitRate;
    Rate public liquidationLimitRate;
    Rate public organizationFeeRate;
    Rate public insurancePurchaseRate;
    Rate public insuranceLiquidationPenaltyRate;
    uint256 public compoundingIntervalSecs;

    mapping(uint256 => Position) private positions;
    mapping(uint256 => address) public positionOwner;

    uint256 public totalPositions;

    uint256 public borrowAmountCap;
    uint256 public totalBorrowAmount;

    uint256 public ethPriceUSD;
    mapping(PunkType => uint256) public punkTypeValueETH;
    mapping(uint256 => uint256) public punkValueETH;
    mapping(uint256 => PunkType) public punkTypes;

    uint256 public tickCursor;
    uint256 public tickChunkSize;

    uint256 public totalFeeCollected;
    uint256 public feeCollectedAt;

    modifier validPunkIndex(uint256 punkIndex) {
        require(punkIndex < 10000, "invalid_punk");
        _;
    }

    constructor(
        address _stablecoin,
        address _cryptopunks,
        address _oracle,
        uint16[] memory aliens,
        uint16[] memory apes,
        uint256 _borrowAmountCap
    ) Ownable() ReentrancyGuard() {
        tickCursor = 0;
        tickChunkSize = 500;

        stablecoin = _stablecoin;
        cryptopunks = _cryptopunks;
        oracle = _oracle;

        debtInterestApr = Rate(2, 100); // 2%
        creditLimitRate = Rate(32, 100); // 32%
        liquidationLimitRate = Rate(33, 100); // 33%
        organizationFeeRate = Rate(5, 1000); // 0.5%
        insurancePurchaseRate = Rate(1, 100); // 1%
        insuranceLiquidationPenaltyRate = Rate(25, 100); // 25%
        compoundingIntervalSecs = 3600; // 1 hour

        // default values (in eth) for punk types
        punkTypeValueETH[PunkType.FLOOR] = 50 * 10**18;
        punkTypeValueETH[PunkType.APE] = 2000 * 10**18;
        punkTypeValueETH[PunkType.ALIENS] = 4000 * 10**18;

        // update price oracle
        _updateOracle();

        // define aliens
        for (uint16 i = 0; i < aliens.length; i++) {
            punkTypes[aliens[i]] = PunkType.ALIENS;
        }

        // define apes
        for (uint16 i = 0; i < apes.length; i++) {
            punkTypes[apes[i]] = PunkType.APE;
        }

        borrowAmountCap = _borrowAmountCap;
    }

    function _updateOracle() internal {
        IOracle(oracle).update();
        ethPriceUSD = IOracle(oracle).eth_usd_18();
    }

    function updateOracle() external {
        _updateOracle();
    }

    function setTickChunkSize(uint256 _tickChunkSize) external onlyOwner {
        tickChunkSize = _tickChunkSize;
    }

    function setBorrowAmountCap(uint256 _borrowAmountCap) external onlyOwner {
        borrowAmountCap = _borrowAmountCap;
    }

    function setDebtInterestApr(Rate memory _debtInterestApr)
        external
        onlyOwner
    {
        debtInterestApr = _debtInterestApr;
    }

    function setCreditLimitRate(Rate memory _creditLimitRate)
        external
        onlyOwner
    {
        creditLimitRate = _creditLimitRate;

        // if credit limit is higher than liquidation limit
        if (
            _creditLimitRate.numerator * liquidationLimitRate.denominator >
            liquidationLimitRate.numerator * _creditLimitRate.denominator
        ) {
            liquidationLimitRate = _creditLimitRate;
        }
    }

    function setLiquidationLimitRate(Rate memory _liquidationLimitRate)
        external
        onlyOwner
    {
        liquidationLimitRate = _liquidationLimitRate;

        // if credit limit is higher than liquidation limit
        if (
            creditLimitRate.numerator * _liquidationLimitRate.denominator >
            _liquidationLimitRate.numerator * creditLimitRate.denominator
        ) {
            creditLimitRate = _liquidationLimitRate;
        }
    }

    function setOrganizationFeeRate(Rate memory _organizationFeeRate)
        external
        onlyOwner
    {
        organizationFeeRate = _organizationFeeRate;
    }

    function setInsurancePurchaseRate(Rate memory _insurancePurchaseRate)
        external
        onlyOwner
    {
        insurancePurchaseRate = _insurancePurchaseRate;
    }

    function setInsuranceLiquidationPenaltyRate(
        Rate memory _insuranceLiquidationPenaltyRate
    ) external onlyOwner {
        insuranceLiquidationPenaltyRate = _insuranceLiquidationPenaltyRate;
    }

    function setCompoundingIntervalSecs(uint256 _compoundingIntervalSecs)
        external
        onlyOwner
    {
        compoundingIntervalSecs = _compoundingIntervalSecs;
    }

    function setPunkType(uint256 _punkIndex, PunkType _type)
        external
        validPunkIndex(_punkIndex)
        onlyOwner
    {
        punkTypes[_punkIndex] = _type;
    }

    function setPunkTypeValueETH(PunkType _type, uint256 _amountETH)
        external
        onlyOwner
    {
        require(punkTypeValueETH[_type] > 0, "invalid_punkType");

        punkTypeValueETH[_type] = _amountETH;
    }

    function setPunkValueETH(uint256 _punkIndex, uint256 _amountETH)
        external
        validPunkIndex(_punkIndex)
        onlyOwner
    {
        punkTypes[_punkIndex] = PunkType.CUSTOM;
        punkValueETH[_punkIndex] = _amountETH;
    }

    function _getPunkValueETH(uint256 _punkIndex)
        internal
        view
        returns (uint256)
    {
        PunkType punkType = punkTypes[_punkIndex];
        return
            punkType == PunkType.CUSTOM
                ? punkValueETH[_punkIndex]
                : punkTypeValueETH[punkType];
    }

    function _getPunkValueUSD(uint256 _punkIndex)
        internal
        view
        returns (uint256)
    {
        uint256 punk_value = _getPunkValueETH(_punkIndex);
        return (punk_value * ethPriceUSD) / 10**18;
    }

    function _getPunkOwner(uint256 _punkIndex) internal view returns (address) {
        return ICryptoPunks(cryptopunks).punkIndexToAddress(_punkIndex);
    }

    struct PunkInfo {
        uint256 index;
        PunkType punkType;
        address owner;
        uint256 punkValueETH;
        uint256 punkValueUSD;
    }

    function getPunkInfo(uint256 _punkIndex)
        external
        view
        returns (PunkInfo memory punkInfo)
    {
        punkInfo = PunkInfo(
            _punkIndex,
            punkTypes[_punkIndex],
            _getPunkOwner(_punkIndex),
            _getPunkValueETH(_punkIndex),
            _getPunkValueUSD(_punkIndex)
        );
    }

    function _getCreditLimit(uint256 _punkIndex)
        internal
        view
        returns (uint256 collateralValue)
    {
        uint256 asset_value = _getPunkValueUSD(_punkIndex);
        collateralValue =
            (asset_value * creditLimitRate.numerator) /
            creditLimitRate.denominator;
    }

    function _getLiquidationLimit(uint256 _punkIndex)
        internal
        view
        returns (uint256 collateralValue)
    {
        uint256 asset_value = _getPunkValueUSD(_punkIndex);
        collateralValue =
            (asset_value * liquidationLimitRate.numerator) /
            liquidationLimitRate.denominator;
    }

    function _getDebtInterest(uint256 _punkIndex)
        internal
        view
        returns (uint256 debtInterest)
    {
        Position memory position = positions[_punkIndex];

        // check if there is debt
        if (position.debtPrincipal > 0) {
            uint256 timeDifferenceSecs = (block.timestamp -
                position.debtUpdatedAt);

            debtInterest = position.debtInterest;
            if (timeDifferenceSecs > compoundingIntervalSecs) {
                uint256 totalDebt = position.debtPrincipal +
                    position.debtInterest;
                uint256 interestPerYear = (totalDebt *
                    debtInterestApr.numerator) / debtInterestApr.denominator;
                uint256 interestPerSec = interestPerYear / SECS_YEAR;

                debtInterest += (timeDifferenceSecs * interestPerSec);
            }
        }
    }

    function _updateDebtInterest(uint256 _punkIndex) internal {
        uint256 debtInterest = _getDebtInterest(_punkIndex);
        if (positions[_punkIndex].debtUpdatedAt < feeCollectedAt) {
            positions[_punkIndex].debtInterestBurn = positions[_punkIndex]
                .debtInterest;
            positions[_punkIndex].debtUpdatedAt = block.timestamp;
        }
        if (positions[_punkIndex].debtInterest != debtInterest) {
            totalFeeCollected +=
                debtInterest -
                positions[_punkIndex].debtInterest;
            positions[_punkIndex].debtInterest += debtInterest;
            positions[_punkIndex].debtUpdatedAt = block.timestamp;
        }
    }

    struct PositionPreview {
        address owner;
        uint256 punkIndex;
        PunkType punkType;
        uint256 punkValueUSD;
        Rate debtInterestApr;
        Rate creditLimitRate;
        Rate liquidationLimitRate;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 creditLimit;
        uint256 debtPrincipal;
        uint256 debtInterest;
        BorrowType borrowType;
        bool liquidatable;
        bool liquidated;
    }

    function showPosition(uint256 _punkIndex)
        external
        view
        validPunkIndex(_punkIndex)
        returns (PositionPreview memory preview)
    {
        address posOwner = positionOwner[_punkIndex];
        require(posOwner != address(0), "position_not_exist");

        uint256 debtPrincipal = positions[_punkIndex].debtPrincipal;
        uint256 debtInterest = positions[_punkIndex].debtInterest;
        preview = PositionPreview(
            posOwner,
            _punkIndex,
            punkTypes[_punkIndex],
            _getPunkValueUSD(_punkIndex),
            debtInterestApr,
            creditLimitRate,
            liquidationLimitRate,
            organizationFeeRate,
            insurancePurchaseRate,
            insuranceLiquidationPenaltyRate,
            _getCreditLimit(_punkIndex),
            debtPrincipal,
            debtInterest,
            positions[_punkIndex].borrowType,
            debtPrincipal + debtInterest >= _getLiquidationLimit(_punkIndex),
            positions[_punkIndex].liquidated
        );
    }

    function openPosition(uint256 _punkIndex)
        external
        validPunkIndex(_punkIndex)
    {
        require(msg.sender == _getPunkOwner(_punkIndex), "punk_not_owned");
        require(
            positionOwner[_punkIndex] == address(0),
            "position_already_exists"
        );

        positions[_punkIndex] = Position({
            borrowType: BorrowType.NOT_CONFIRMED,
            debtPrincipal: 0,
            debtInterest: 0,
            debtInterestBurn: 0,
            debtUpdatedAt: 0,
            liquidated: false
        });
        positionOwner[_punkIndex] = msg.sender;
        totalPositions++;

        emit PositionOpened(msg.sender, _punkIndex);
    }

    function borrow(
        uint256 _punkIndex,
        uint256 _amount,
        bool _useInsurance
    ) external validPunkIndex(_punkIndex) nonReentrant {
        require(msg.sender == positionOwner[_punkIndex], "unauthorized");
        require(
            _getPunkOwner(_punkIndex) == address(this),
            "punk_not_deposited"
        );
        require(totalBorrowAmount + _amount <= borrowAmountCap, "debt_cap");

        Position memory position = positions[_punkIndex];
        require(!position.liquidated, "liquidated");
        require(
            position.borrowType == BorrowType.NOT_CONFIRMED ||
                (position.borrowType == BorrowType.USE_INSURANCE &&
                    _useInsurance) ||
                (position.borrowType == BorrowType.NON_INSURANCE &&
                    !_useInsurance),
            "invalid_insurance_mode"
        );

        uint256 creditLimit = _getCreditLimit(_punkIndex);

        uint256 totalDebt = position.debtPrincipal + position.debtInterest;
        require(totalDebt + _amount <= creditLimit, "insufficient_credit");

        uint256 organizationFee = (_amount * organizationFeeRate.numerator) /
            organizationFeeRate.denominator;

        // mint stablecoin
        if (position.borrowType == BorrowType.USE_INSURANCE || _useInsurance) {
            uint256 feeAmount = ((_amount * insurancePurchaseRate.numerator) /
                insurancePurchaseRate.denominator) + organizationFee;
            // insurance & organization fee amount to dao
            IStableCoin(stablecoin).mint(owner(), feeAmount);
            // remaining amount to user
            IStableCoin(stablecoin).mint(msg.sender, _amount - feeAmount);
        } else {
            // organization fee amount to dao
            IStableCoin(stablecoin).mint(owner(), organizationFee);
            IStableCoin(stablecoin).mint(msg.sender, _amount - organizationFee);
        }

        if (position.borrowType == BorrowType.NOT_CONFIRMED) {
            positions[_punkIndex].borrowType = _useInsurance
                ? BorrowType.USE_INSURANCE
                : BorrowType.NON_INSURANCE;
        }

        positions[_punkIndex].debtPrincipal += _amount;
        totalBorrowAmount += _amount;
        if (totalDebt == 0) {
            positions[_punkIndex].debtUpdatedAt = block.timestamp;
        }

        emit Borrowed(msg.sender, _punkIndex, _amount);
    }

    function repay(uint256 _punkIndex, uint256 _amount)
        external
        validPunkIndex(_punkIndex)
        nonReentrant
    {
        require(msg.sender == positionOwner[_punkIndex], "unauthorized");
        require(
            _getPunkOwner(_punkIndex) == address(this),
            "punk_not_deposited"
        );

        require(!positions[_punkIndex].liquidated, "liquidated");

        Position storage position = positions[_punkIndex];
        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = position.debtInterest;
        uint256 totalDebt = debtPrincipal + debtInterest;

        require(debtPrincipal + debtInterest > 0, "position_not_borrowed");

        _amount = _amount > totalDebt ? totalDebt : _amount;

        // send payment to nftVault
        IERC20(stablecoin).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 paidInterest = 0;
        // pay interest
        if (_amount < debtInterest) {
            paidInterest = _amount;
            position.debtInterest = debtInterest - paidInterest;
        } else {
            paidInterest = debtInterest;
            position.debtInterest = 0;
        }
        uint256 paidPrincipal = _amount - paidInterest;
        // pay principal
        if (paidPrincipal > 0) {
            position.debtPrincipal = debtPrincipal - paidPrincipal;
            totalBorrowAmount -= paidPrincipal;
        }

        // transfer interest to dao
        if (paidInterest > 0) {
            uint256 burnInterest = paidInterest < position.debtInterestBurn
                ? paidInterest
                : position.debtInterestBurn;

            if (burnInterest > 0) {
                IStableCoin(stablecoin).burn(burnInterest);
                position.debtInterestBurn -= paidInterest;
            }

            IERC20(stablecoin).safeTransfer(
                owner(),
                paidInterest - burnInterest
            );
        }

        // burn principal payment
        if (paidPrincipal > 0) {
            IStableCoin(stablecoin).burn(paidPrincipal);
        }

        emit Repaid(msg.sender, _punkIndex, _amount);
    }

    function closePosition(uint256 _punkIndex)
        external
        validPunkIndex(_punkIndex)
    {
        Position memory position = positions[_punkIndex];
        require(msg.sender == positionOwner[_punkIndex], "unauthorized");
        require(
            position.debtPrincipal + position.debtInterest == 0,
            "position_not_repaid"
        );

        positionOwner[_punkIndex] = address(0);
        totalPositions--;

        // transfer punk back to owner if punk was deposited
        if (_getPunkOwner(_punkIndex) == address(this)) {
            ICryptoPunks(cryptopunks).transferPunk(msg.sender, _punkIndex);
        }

        emit PositionClosed(msg.sender, _punkIndex);
    }

    function liquidate(uint256 _punkIndex)
        external
        onlyOwner
        validPunkIndex(_punkIndex)
        nonReentrant
    {
        require(positionOwner[_punkIndex] != address(0), "position_not_exist");
        require(
            _getPunkOwner(_punkIndex) == address(this),
            "punk_not_deposited"
        );

        address posOwner = positionOwner[_punkIndex];
        require(!positions[_punkIndex].liquidated, "liquidated");

        Position memory position = positions[_punkIndex];
        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = position.debtInterest;
        uint256 debtInterestBurn = position.debtInterestBurn;

        require(debtPrincipal + debtInterest > 0, "position_not_borrowed");
        require(
            debtPrincipal + debtInterest >= _getLiquidationLimit(_punkIndex),
            "position_not_liquidatable"
        );

        uint256 totalDebt = debtPrincipal + debtInterest;

        // receive stablecoin from liquidator
        IERC20(stablecoin).safeTransferFrom(
            msg.sender,
            address(this),
            totalDebt
        );

        // transfer interest to dao
        if (debtInterest > 0) {
            IStableCoin(stablecoin).burn(debtInterestBurn);
            IERC20(stablecoin).safeTransfer(
                owner(),
                debtInterest - debtInterestBurn
            );
        }

        // burn principal payment
        if (debtPrincipal > 0) {
            totalBorrowAmount -= debtPrincipal;
            IStableCoin(stablecoin).burn(debtPrincipal);
            positions[_punkIndex].debtInterestBurn = 0;
        }

        if (position.borrowType == BorrowType.USE_INSURANCE) {
            positions[_punkIndex].liquidated = true;
        } else {
            // transfer punk to liquidator
            ICryptoPunks(cryptopunks).transferPunk(msg.sender, _punkIndex);
            positionOwner[_punkIndex] = address(0);
        }

        emit Liquidated(msg.sender, posOwner, _punkIndex);
    }

    function repurchase(uint256 _punkIndex)
        external
        validPunkIndex(_punkIndex)
    {
        Position memory position = positions[_punkIndex];
        require(msg.sender == positionOwner[_punkIndex], "unauthorized");
        require(position.liquidated, "not_liquidated");
        require(
            position.borrowType == BorrowType.USE_INSURANCE,
            "non_insurance"
        );

        uint256 punk_value = _getPunkValueUSD(_punkIndex);
        uint256 debtPrincipal = position.debtPrincipal;
        uint256 fee = position.debtInterest +
            (punk_value * insuranceLiquidationPenaltyRate.numerator) /
            insuranceLiquidationPenaltyRate.denominator;

        // receive stablecoin from user
        IERC20(stablecoin).safeTransferFrom(
            msg.sender,
            address(this),
            debtPrincipal + fee
        );

        // transfer liquiation fee + interest to dao
        if (fee > 0) {
            IERC20(stablecoin).safeTransfer(owner(), fee);
        }

        // burn principal payment
        if (debtPrincipal > 0) {
            IStableCoin(stablecoin).burn(debtPrincipal);
        }

        // transfer punk to user
        ICryptoPunks(cryptopunks).transferPunk(msg.sender, _punkIndex);
        positionOwner[_punkIndex] = address(0);

        emit Repurchased(msg.sender, _punkIndex);
    }

    function tick() external returns (uint256) {
        _updateOracle();

        if (tickCursor > 9999) tickCursor = 0;

        uint256 found = 0;

        for (uint256 i = 0; i < tickChunkSize; i++) {
            uint256 _punkIndex = tickCursor;
            tickCursor++;

            if (_punkIndex > 9999) {
                tickCursor = 0;
                continue;
            }

            if (positionOwner[_punkIndex] == address(0)) {
                continue;
            }

            if (positions[_punkIndex].liquidated) {
                continue;
            }

            found++;

            _updateDebtInterest(_punkIndex);
        }

        return found;
    }

    function collect() external nonReentrant {
        IStableCoin(stablecoin).mint(owner(), totalFeeCollected);
        totalFeeCollected = 0;
        feeCollectedAt = block.timestamp;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICryptoPunks {
    function transferPunk(address _to, uint256 _punkIndex) external;

    function punkIndexToAddress(uint256 _punkIndex)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOracle {
    function update() external returns (bool);

    function eth_usd() external view returns (int128);

    function eth_usd_18() external view returns (uint256);

    function last_update_time() external view returns (uint256);

    function last_update_remote() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableCoin is IERC20 {
    function mint(address _to, uint256 _value) external;

    function burn(uint256 _value) external;

    function burnFrom(address _from, uint256 _value) external;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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