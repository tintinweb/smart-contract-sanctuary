// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/misc/Constants.sol";
import "@solv/v2-solidity-utils/contracts/access/AdminControl.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/math/SafeMathUpgradeable.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/utils/EnumerableSetUpgradeable.sol";
import "@solv/v2-solidity-utils/contracts/math/SafeMathUpgradeable128.sol";
import "@solv/v2-solidity-utils/contracts/helpers/VNFTTransferHelper.sol";
import "@solv/v2-solidity-utils/contracts/helpers/ERC20TransferHelper.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/utils/ReentrancyGuardUpgradeable.sol";
import "@solv/v2-solver/contracts/interface/ISolver.sol";
import "./PriceManager.sol";

abstract contract OfferingMarketCore is
    PriceManager,
    AdminControl,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event AddMarket(
        address indexed voucher,
        Constants.VoucherType voucherType,
        address asset,
        uint8 decimals,
        uint16 feeRate,
        bool onlyManangerOffer
    );

    event RemoveMarket(address indexed voucher);

    event Offer(
        address indexed voucher,
        address indexed issuer,
        Offering offering
    );

    event Remove(
        address indexed issuer,
        uint24 indexed offeringId,
        address voucher,
        uint128 total,
        uint128 sold
    );

    event FixedPriceSet(
        address indexed voucher,
        uint24 indexed offeringId,
        uint8 priceType,
        uint128 lastPrice
    );

    event DecliningPriceSet(
        address indexed voucher,
        uint24 indexed offeringId,
        uint128 highest,
        uint128 lowest,
        uint32 duration,
        uint32 interval
    );

    event Traded(
        address indexed buyer,
        uint24 indexed offeringId,
        address indexed voucher,
        uint256 voucherId,
        uint24 tradeId,
        uint32 tradeTime,
        address currency,
        uint8 priceType,
        uint128 price,
        uint128 tradedUnits,
        uint256 tradedAmount,
        uint128 fee
    );

    event SetCurrency(address indexed currency, bool enable);

    event WithdrawFee(address voucher, uint256 reduceAmount);

    event NewSolver(ISolver oldSolver, ISolver newSolver);

    struct Market {
        Constants.VoucherType voucherType;
        address voucherPool;
        address asset;
        uint8 decimals;
        uint16 feeRate;
        bool onlyManangerOffer;
        bool isValid;
    }

    struct Offering {
        uint24 offeringId;
        uint32 startTime;
        uint32 endTime;
        PriceManager.PriceType priceType;
        uint128 totalUnits;
        uint128 units;
        uint128 min;
        uint128 max;
        address voucher;
        address currency;
        address issuer;
        bool useAllowList;
        bool isValid;
    }

    //key: offeringId
    mapping(uint24 => Offering) public offerings;

    //key: voucher
    mapping(address => Market) public markets;

    EnumerableSetUpgradeable.AddressSet internal _currencies;
    EnumerableSetUpgradeable.AddressSet internal _vouchers;

    //voucher => offeringId
    mapping(address => EnumerableSetUpgradeable.UintSet)
        internal _voucherOfferings;

    mapping(address => EnumerableSetUpgradeable.AddressSet)
        internal _allowAddresses;

    // managers with authorities to set allow addresses of a voucher market and offer offering
    mapping(address => EnumerableSetUpgradeable.AddressSet)
        internal _voucherManagers;

    // records of user purchased units from an order
    mapping(uint24 => mapping(address => uint128)) internal _tradeRecords;

    ISolver public solver;
    uint24 public nextOfferingId;
    uint24 public nextTradeId;

    modifier onlyVoucherManager(address voucher_) {
        require(
            msg.sender == admin ||
                _voucherManagers[voucher_].contains(msg.sender),
            "only manager"
        );
        _;
    }

    function _mintVoucher(uint24 oferingId, uint128 units)
        internal
        virtual
        returns (uint256 voucherId);

    function _refund(uint24 offeringId, uint128 units) internal virtual;

    function isSupportVoucherType(Constants.VoucherType voucherType)
        public
        virtual
        returns (bool);

    function initialize(ISolver solver_) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AdminControl.__AdminControl_init(msg.sender);
        nextOfferingId = 1;
        nextTradeId = 1;
        setSolver(solver_);
    }

    function _offer(
        address voucher_,
        address currency_,
        uint128 units_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        uint32 endTime_,
        bool useAllowList_,
        PriceManager.PriceType priceType_,
        bytes memory priceData_
    ) internal nonReentrant returns (uint24 offeringId) {
        require(
            voucher_ != address(0) && currency_ != address(0),
            "address cannot be 0"
        );
        Market memory market = markets[voucher_];
        require(market.isValid, "unsupported voucher");
        require(_currencies.contains(currency_), "unsupported currency");
        require(endTime_ > startTime_, "endTime less than startTime");

        if (market.onlyManangerOffer) {
            require(
                _voucherManagers[voucher_].contains(msg.sender),
                "only manager"
            );
        }

        if (max_ > 0) {
            require(min_ <= max_, "min > max");
        }

        uint256 err = solver.operationAllowed(
            "Offer",
            abi.encode(
                voucher_,
                msg.sender,
                currency_,
                units_,
                min_,
                max_,
                startTime_,
                endTime_,
                useAllowList_,
                priceType_,
                priceData_
            )
        );
        require(err == 0, "solver not allowed");

        offeringId = _generateNextofferingId();

        offerings[offeringId] = Offering({
            offeringId: offeringId,
            startTime: startTime_,
            endTime: endTime_,
            priceType: priceType_,
            totalUnits: units_,
            units: units_,
            min: min_,
            max: max_,
            currency: currency_,
            issuer: msg.sender,
            voucher: voucher_,
            useAllowList: useAllowList_,
            isValid: true
        });

        Offering memory offering = offerings[offeringId];

        _setPrice(offering, priceType_, priceData_);

        solver.operationVerify(
            "Offer",
            abi.encode(offering.voucher, offering.offeringId)
        );
        emit Offer(offering.voucher, offering.issuer, offering);

        return offeringId;
    }

    function _setPrice(
        Offering memory offering_,
        PriceManager.PriceType priceType_,
        bytes memory priceData_
    ) internal {
        if (priceType_ == PriceManager.PriceType.FIXED) {
            uint128 price = abi.decode(priceData_, (uint128));
            PriceManager.setFixedPrice(offering_.offeringId, price);

            emit FixedPriceSet(
                offering_.voucher,
                offering_.offeringId,
                uint8(priceType_),
                price
            );
        } else {
            (
                uint128 highest,
                uint128 lowest,
                uint32 duration,
                uint32 interval
            ) = abi.decode(priceData_, (uint128, uint128, uint32, uint32));
            PriceManager.setDecliningPrice(
                offering_.offeringId,
                offering_.startTime,
                highest,
                lowest,
                duration,
                interval
            );

            emit DecliningPriceSet(
                offering_.voucher,
                offering_.offeringId,
                highest,
                lowest,
                duration,
                interval
            );
        }
    }

    function buy(uint24 offeringId_, uint128 units_)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 amount_, uint128 fee_)
    {
        address buyer = msg.sender;
        uint128 price = getPrice(offeringId_);
        Offering storage offering = offerings[offeringId_];
        require(offering.isValid, "invalid offering");

        Market memory market = markets[offering.voucher];
        require(market.isValid, "invalid market");
        amount_ = uint256(units_).mul(uint256(price)).div(
            uint256(10**market.decimals)
        );

        if (
            offering.currency == Constants.ETH_ADDRESS &&
            offering.priceType == PriceType.DECLIINING_BY_TIME &&
            amount_ != msg.value
        ) {
            amount_ = msg.value;
            uint256 units256 = amount_.mul(uint256(10**market.decimals)).div(
                uint256(price)
            );
            require(units256 <= uint128(-1), "exceeds uint128 max");
            units_ = uint128(units256);
        }

        fee_ = _getFee(offering.voucher, amount_);

        uint256 err = solver.operationAllowed(
            "Buy",
            abi.encode(
                offering.voucher,
                offeringId_,
                buyer,
                amount_,
                units_,
                price
            )
        );
        require(err == 0, "Solver: not allowed");

        BuyParameter memory buyParameter = BuyParameter({
            buyer: buyer,
            amount: amount_,
            units: units_,
            price: price,
            fee: fee_
        });
        _buy(offering, buyParameter);
        return (amount_, fee_);
    }

    struct BuyLocalVar {
        uint256 transferInAmount;
        uint256 transferOutAmount;
    }

    struct BuyParameter {
        address buyer;
        uint256 amount;
        uint128 units;
        uint128 price;
        uint128 fee;
    }

    function _buy(Offering storage offering_, BuyParameter memory parameter_)
        internal
    {
        require(offering_.isValid, "offering invalid");
        require(offering_.units > 0, "sold out");
        require(
            block.timestamp >= offering_.startTime &&
                block.timestamp <= offering_.endTime,
            "not offering time"
        );
        if (offering_.useAllowList) {
            require(
                _allowAddresses[offering_.voucher].contains(parameter_.buyer),
                "not in allow list"
            );
        }
        if (offering_.units >= offering_.min) {
            require(parameter_.units >= offering_.min, "min amount not met");
        }
        if (offering_.max > 0) {
            uint128 purchased = _tradeRecords[offering_.offeringId][
                parameter_.buyer
            ].add(parameter_.units);
            require(purchased <= offering_.max, "exceeds purchase limit");
            _tradeRecords[offering_.offeringId][parameter_.buyer] = purchased;
        }

        offering_.units = offering_.units.sub(
            parameter_.units,
            "insufficient units for sale"
        );
        BuyLocalVar memory vars;

        vars.transferInAmount = parameter_.amount;
        vars.transferOutAmount = parameter_.amount.sub(
            parameter_.fee,
            "fee exceeds amount"
        );

        uint256 voucherId = _transferAsset(
            offering_,
            parameter_.buyer,
            vars.transferInAmount,
            parameter_.units,
            vars.transferOutAmount
        );

        solver.operationVerify(
            "Buy",
            abi.encode(
                offering_.offeringId,
                parameter_.buyer,
                parameter_.amount,
                parameter_.units,
                parameter_.fee
            )
        );

        emit Traded(
            parameter_.buyer,
            offering_.offeringId,
            offering_.voucher,
            voucherId,
            _generateNextTradeId(),
            uint32(block.timestamp),
            offering_.currency,
            uint8(offering_.priceType),
            parameter_.price,
            parameter_.units,
            parameter_.amount,
            parameter_.fee
        );
    }

    function _transferAsset(
        Offering memory offering_,
        address buyer_,
        uint256 transferInAmount_,
        uint128 transferOutUnits_,
        uint256 transferOutAmount_
    ) internal returns (uint256 voucherId) {
        ERC20TransferHelper.doTransferIn(
            offering_.currency,
            buyer_,
            transferInAmount_
        );

        voucherId = _mintVoucher(offering_.offeringId, transferOutUnits_);

        VNFTTransferHelper.doTransferOut(offering_.voucher, buyer_, voucherId);

        ERC20TransferHelper.doTransferOut(
            offering_.currency,
            payable(offering_.issuer),
            transferOutAmount_
        );
    }

    function purchasedUnits(uint24 offeringId_, address buyer_)
        external
        view
        returns (uint128)
    {
        return _tradeRecords[offeringId_][buyer_];
    }

    function remove(uint24 offeringId_) external virtual nonReentrant {
        Offering memory offering = offerings[offeringId_];
        require(offering.isValid, "invalid offering");
        require(offering.issuer == msg.sender, "only issuer");
        require(
            block.timestamp < offering.startTime ||
                block.timestamp > offering.endTime,
            "offering processing"
        );

        uint256 err = solver.operationAllowed(
            "Remove",
            abi.encode(offering.voucher, offering.offeringId, offering.issuer)
        );
        require(err == 0, "Solver: not allowed");

        _refund(offeringId_, offering.units);

        emit Remove(
            offering.issuer,
            offering.offeringId,
            offering.voucher,
            offering.totalUnits,
            offering.totalUnits - offering.units
        );
        delete offerings[offeringId_];
    }

    function _getFee(address voucher_, uint256 amount)
        internal
        view
        returns (uint128)
    {
        Market storage market = markets[voucher_];

        uint256 fee = amount.mul(uint256(market.feeRate)).div(
            uint256(Constants.FULL_PERCENTAGE)
        );
        require(fee <= uint128(-1), "Fee: exceeds uint128 max");
        return uint128(fee);
    }

    function getPrice(uint24 offeringId_)
        public
        view
        virtual
        returns (uint128)
    {
        return
            PriceManager.price(offerings[offeringId_].priceType, offeringId_);
    }

    function totalOfferingsOfvoucher(address voucher_)
        external
        view
        virtual
        returns (uint256)
    {
        return _voucherOfferings[voucher_].length();
    }

    function offeringIdOfvoucherByIndex(address voucher_, uint256 index_)
        external
        view
        virtual
        returns (uint256)
    {
        return _voucherOfferings[voucher_].at(index_);
    }

    function _generateNextofferingId() internal returns (uint24) {
        return nextOfferingId++;
    }

    function _generateNextTradeId() internal returns (uint24) {
        return nextTradeId++;
    }

    function addMarket(
        address voucher_,
        address voucherPool_,
        Constants.VoucherType voucherType_,
        address asset_,
        uint8 decimals_,
        uint16 feeRate_,
        bool onlyManangerOffer_
    ) external onlyAdmin {
        if (_vouchers.contains(voucher_)) {
            revert("already added");
        }
        require(isSupportVoucherType(voucherType_), "unsupported voucher type");
        require(feeRate_ <= Constants.FULL_PERCENTAGE, "invalid fee rate");
        markets[voucher_].voucherPool = voucherPool_;
        markets[voucher_].isValid = true;
        markets[voucher_].decimals = decimals_;
        markets[voucher_].feeRate = feeRate_;
        markets[voucher_].voucherType = voucherType_;
        markets[voucher_].asset = asset_;
        markets[voucher_].onlyManangerOffer = onlyManangerOffer_;

        _vouchers.add(voucher_);

        emit AddMarket(
            voucher_,
            voucherType_,
            asset_,
            decimals_,
            feeRate_,
            onlyManangerOffer_
        );
    }

    function removeMarket(address voucher_) external onlyAdmin {
        _vouchers.remove(voucher_);
        delete markets[voucher_];
        emit RemoveMarket(voucher_);
    }

    function setCurrency(address currency_, bool enable_) external onlyAdmin {
        if (enable_) {
            _currencies.add(currency_);
        } else {
            _currencies.remove(currency_);
        }
        emit SetCurrency(currency_, enable_);
    }

    function withdrawFee(address currency_, uint256 reduceAmount_)
        external
        onlyAdmin
    {
        ERC20TransferHelper.doTransferOut(
            currency_,
            payable(admin),
            reduceAmount_
        );
        emit WithdrawFee(currency_, reduceAmount_);
    }

    function addAllowAddress(
        address voucher_,
        address[] calldata addresses_,
        bool resetExisting_
    ) external onlyVoucherManager(voucher_) {
        require(markets[voucher_].isValid, "unsupported voucher");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[
            voucher_
        ];

        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < addresses_.length; i++) {
            set.add(addresses_[i]);
        }
    }

    function removeAllowAddress(address voucher_, address[] calldata addresses_)
        external
        onlyVoucherManager(voucher_)
    {
        require(markets[voucher_].isValid, "unsupported voucher");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[
            voucher_
        ];
        for (uint256 i = 0; i < addresses_.length; i++) {
            set.remove(addresses_[i]);
        }
    }

    function isBuyerAllowed(address voucher_, address buyer_)
        external
        view
        returns (bool)
    {
        return _allowAddresses[voucher_].contains(buyer_);
    }

    function setVoucherManager(
        address voucher_,
        address[] calldata managers_,
        bool resetExisting_
    ) external onlyAdmin {
        require(markets[voucher_].isValid, "unsupported voucher");
        EnumerableSetUpgradeable.AddressSet storage set = _voucherManagers[
            voucher_
        ];
        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < managers_.length; i++) {
            set.add(managers_[i]);
        }
    }

    function voucherManagers(address voucher_)
        external
        view
        returns (address[] memory managers_)
    {
        managers_ = new address[](_voucherManagers[voucher_].length());
        for (uint256 i = 0; i < _voucherManagers[voucher_].length(); i++) {
            managers_[i] = _voucherManagers[voucher_].at(i);
        }
    }

    function setSolver(ISolver newSolver_) public virtual onlyAdmin {
        ISolver oldSolver = solver;
        require(newSolver_.isSolver(), "invalid solver");
        solver = newSolver_;

        emit NewSolver(oldSolver, newSolver_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract PriceManager {
    enum PriceType {
        FIXED,
        DECLIINING_BY_TIME
    }

    struct DecliningPrice {
        uint128 highest; //起始价格
        uint128 lowest; //最终价格
        uint32 startTime;
        uint32 duration; //持续时间
        uint32 interval; //降价周期
    }

    //saleId => DecliningPrice
    mapping(uint24 => DecliningPrice) internal decliningPrices;
    mapping(uint24 => uint128) internal fixedPrices;

    function price(PriceType priceType_, uint24 offeringId_)
        internal
        view
        returns (uint128)
    {
        if (priceType_ == PriceType.FIXED) {
            return fixedPrices[offeringId_];
        }

        if (priceType_ == PriceType.DECLIINING_BY_TIME) {
            DecliningPrice storage price_ = decliningPrices[offeringId_];
            if (block.timestamp >= price_.startTime + price_.duration) {
                return price_.lowest;
            }
            if (block.timestamp <= price_.startTime) {
                return price_.highest;
            }

            uint256 lastPrice = price_.highest -
                ((block.timestamp - price_.startTime) / price_.interval) *
                (((price_.highest - price_.lowest) / price_.duration) *
                    price_.interval);
            uint256 price256 = lastPrice < price_.lowest
                ? price_.lowest
                : lastPrice;
            require(price256 <= uint128(-1), "price: exceeds uint128 max");

            return uint128(price256);
        }

        revert("unsupported priceType");
    }

    function setFixedPrice(uint24 offeringId_, uint128 price_) internal {
        fixedPrices[offeringId_] = price_;
    }

    function setDecliningPrice(
        uint24 offeringId_,
        uint32 startTime_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) internal {
        require(highest_ > lowest_, "highest must greater than lowest");
        require(duration_ >= interval_, "duration must greater than interval");
        decliningPrices[offeringId_].startTime = startTime_;
        decliningPrices[offeringId_].highest = highest_;
        decliningPrices[offeringId_].lowest = lowest_;
        decliningPrices[offeringId_].duration = duration_;
        decliningPrices[offeringId_].interval = interval_;
    }

    function getDecliningPrice(uint24 offeringId_)
        external
        view
        returns (
            uint128 highest,
            uint128 lowest,
            uint32 startTime,
            uint32 duration,
            uint32 interval
        )
    {
        DecliningPrice storage decliningPrice = decliningPrices[offeringId_];
        return (
            decliningPrice.highest,
            decliningPrice.lowest,
            decliningPrice.startTime,
            decliningPrice.duration,
            decliningPrice.interval
        );
    }

    function getFixedPrice(uint24 offeringId_) external view returns (uint128) {
        return fixedPrices[offeringId_];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../openzeppelin/utils/ContextUpgradeable.sol";
import "../openzeppelin/proxy/Initializable.sol";

abstract contract AdminControl is Initializable, ContextUpgradeable {

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    address public admin;
    address public pendingAdmin;

    modifier onlyAdmin() {
        require(_msgSender() == admin, "only admin");
        _;
    }

    function __AdminControl_init(address admin_) internal initializer {
        admin = admin_;
    }

    function setPendingAdmin(address newPendingAdmin_) external virtual onlyAdmin {
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin_);
        pendingAdmin = newPendingAdmin_;        
    }

    function acceptAdmin() external virtual {
        require(_msgSender() == pendingAdmin, "only pending admin");
        emit NewAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "../misc/Constants.sol";

interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    function doTransferIn(
        address underlying,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        if (underlying == Constants.ETH_ADDRESS) {
            // Sanity checks
            require(tx.origin == from || msg.sender == from, "sender mismatch");
            require(msg.value == amount, "value mismatch");

            return amount;
        } else {
            require(msg.value == 0, "don't support msg.value");
            uint256 balanceBefore = ERC20Interface(underlying).balanceOf(
                address(this)
            );
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    ERC20Interface.transferFrom.selector,
                    from,
                    address(this),
                    amount
                )
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "STF"
            );

            // Calculate the amount that was *actually* transferred
            uint256 balanceAfter = ERC20Interface(underlying).balanceOf(
                address(this)
            );
            require(
                balanceAfter >= balanceBefore,
                "TOKEN_TRANSFER_IN_OVERFLOW"
            );
            return balanceAfter - balanceBefore; // underflow already checked above, just subtract
        }
    }

    function doTransferOut(
        address underlying,
        address payable to,
        uint256 amount
    ) internal {
        if (underlying == Constants.ETH_ADDRESS) {
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "STE");
        } else {
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    ERC20Interface.transfer.selector,
                    to,
                    amount
                )
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "ST"
            );
        }
    }

    function getCashPrior(address underlying_) internal view returns (uint256) {
        if (underlying_ == Constants.ETH_ADDRESS) {
            uint256 startingBalance = sub(address(this).balance, msg.value);
            return startingBalance;
        } else {
            ERC20Interface token = ERC20Interface(underlying_);
            return token.balanceOf(address(this));
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ERC721Interface {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface VNFTInterface {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external returns (uint256 newTokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external returns (uint256 newTokenId);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units,
        bytes calldata data
    ) external;
}

library VNFTTransferHelper {
    function doTransferIn(
        address underlying,
        address from,
        uint256 tokenId
    ) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(from, address(this), tokenId);
    }

    function doTransferOut(
        address underlying,
        address to,
        uint256 tokenId
    ) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(address(this), to, tokenId);
    }

    function doTransferIn(
        address underlying,
        address from,
        uint256 tokenId,
        uint256 units
    ) internal {
        VNFTInterface token = VNFTInterface(underlying);
        token.safeTransferFrom(from, address(this), tokenId, units, "");
    }

    function doTransferOut(
        address underlying,
        address to,
        uint256 tokenId,
        uint256 units
    ) internal returns (uint256 newTokenId) {
        VNFTInterface token = VNFTInterface(underlying);
        newTokenId = token.safeTransferFrom(
            address(this),
            to,
            tokenId,
            units,
            ""
        );
    }

    function doTransferOut(
        address underlying,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units
    ) internal {
        VNFTInterface token = VNFTInterface(underlying);
        token.safeTransferFrom(
            address(this),
            to,
            tokenId,
            targetTokenId,
            units,
            ""
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable128 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        uint128 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint128 a, uint128 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "SafeMath: subtraction overflow");
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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) return 0;
        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library Constants {
    enum ClaimType {
        LINEAR,
        ONE_TIME,
        STAGED
    }

    enum VoucherType {
        STANDARD_VESTING,
        FLEXIBLE_DATE_VESTING,
        BOUNDING
    }

    uint32 internal constant FULL_PERCENTAGE = 10000;
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolver {

    event SetOperationPaused (
        address product,
        string operation,
        bool setPaused
    );


    function isSolver() external pure returns (bool);

    function setOperationPaused(address product_, string calldata operation_, bool setPaused_) external;

    function operationAllowed(string calldata operation_, bytes calldata data_) external returns (uint256);

    function operationVerify(string calldata operation_, bytes calldata data_) external returns (uint256);
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-offering-market-core/contracts/OfferingMarketCore.sol";

interface IStandardVestingVoucher {
    function mint(
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external returns (uint256 slot, uint256 voucherId);
}

interface IFlexibleDateVestingVoucher {
    function mint(
        address issuer_,
        uint8 claimType_,
        uint64 latestClaimVestingTime_,
        uint64[] calldata terms_,
        uint32[] calldata percentages_,
        uint256 vestingAmount_
    ) external returns (uint256 slot, uint256 tokenId);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract InitialVestingOfferingMarket is OfferingMarketCore {
    enum TimeType {
        LATEST_START_TIME,
        ON_BUY,
        UNDECIDED
    }

    struct MintParameter {
        Constants.ClaimType claimType;
        uint64 latestStartTime;
        TimeType timeType;
        uint64[] terms;
        uint32[] percentages;
    }

    //key: offeringId
    mapping(uint24 => MintParameter) internal _mintParameters;

    function mintParameters(uint24 offeringId_)
        external
        view
        returns (MintParameter memory)
    {
        return _mintParameters[offeringId_];
    }

    function offer(
        address voucher_,
        address currency_,
        uint128 units_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        uint32 endTime_,
        bool useAllowList_,
        PriceManager.PriceType priceType_,
        bytes calldata priceData_,
        MintParameter calldata mintParameter_
    ) external returns (uint24 offeringId) {
        Market memory market = markets[voucher_];

        if (mintParameter_.timeType == TimeType.UNDECIDED) {
            require(
                market.voucherType ==
                    Constants.VoucherType.FLEXIBLE_DATE_VESTING,
                "invalid time type"
            );
        }

        require(
            mintParameter_.terms.length == mintParameter_.percentages.length,
            "invalid terms and percentages"
        );
        // latestStartTime should not be later than 2100/01/01 00:00:00
        require(mintParameter_.latestStartTime < 4102416000, "latest start time too late");
        // number of stages should not be more than 50
        require(mintParameter_.percentages.length <= 50, "too many stages");

        uint256 sumOfPercentages = 0;
        for (uint256 i = 0; i < mintParameter_.percentages.length; i++) {
            // value of each term should not be larger than 10 years
            require(mintParameter_.terms[i] <= 315360000, "term value too large");
            // value of each percentage should not be larger than 10000
            require(mintParameter_.percentages[i] <= Constants.FULL_PERCENTAGE, "percentage value too large");
            sumOfPercentages += mintParameter_.percentages[i];
        }
        require(
            sumOfPercentages == Constants.FULL_PERCENTAGE,
            "not full percentage"
        );

        require(
            (mintParameter_.claimType == Constants.ClaimType.LINEAR &&
                mintParameter_.percentages.length == 1) ||
                (mintParameter_.claimType == Constants.ClaimType.ONE_TIME &&
                    mintParameter_.percentages.length == 1) ||
                (mintParameter_.claimType == Constants.ClaimType.STAGED &&
                    mintParameter_.percentages.length > 1),
            "invalid params"
        );

        ERC20TransferHelper.doTransferIn(market.asset, msg.sender, units_);

        offeringId = OfferingMarketCore._offer(
            voucher_,
            currency_,
            units_,
            min_,
            max_,
            startTime_,
            endTime_,
            useAllowList_,
            priceType_,
            priceData_
        );
        _mintParameters[offeringId] = mintParameter_;
    }

    function _mintVoucher(uint24 offeringId_, uint128 units_)
        internal
        virtual
        override
        returns (uint256 voucherId)
    {
        Offering memory offering = offerings[offeringId_];
        MintParameter memory parameter = _mintParameters[offeringId_];
        IERC20(markets[offering.voucher].asset).approve(
            markets[offering.voucher].voucherPool,
            units_
        );
        if (parameter.timeType != TimeType.UNDECIDED) {
            uint64 term;
            uint64[] memory maturities = new uint64[](parameter.terms.length);
            IStandardVestingVoucher vestingVoucher = IStandardVestingVoucher(
                offering.voucher
            );
            uint64 startTime = parameter.timeType == TimeType.LATEST_START_TIME
                ? parameter.latestStartTime
                : uint64(block.timestamp);

            // The values of `startTime` and `terms` are read from storage, and their values have been
            // checked before stored when offering a new IVO, so there is no need here to check the 
            // overflow of the value of `term` and `maturities`.
            for (uint256 i = 0; i < parameter.terms.length; i++) {
                term += parameter.terms[i];
                maturities[i] = startTime + term;
            }

            if (parameter.claimType == Constants.ClaimType.STAGED) {
                //standard vesting voucher: staged term should be not included terms[0]
                term -= parameter.terms[0];
            } else if (parameter.claimType == Constants.ClaimType.ONE_TIME) {
                //standard vesting voucher: one-time term should be 0
                term = 0;
            }

            (, voucherId) = vestingVoucher.mint(
                term,
                units_,
                maturities,
                parameter.percentages,
                "IVO"
            );
        } else {
            IFlexibleDateVestingVoucher offeringVoucher = IFlexibleDateVestingVoucher(
                    offering.voucher
                );
            (, voucherId) = offeringVoucher.mint(
                offering.issuer,
                uint8(parameter.claimType),
                parameter.latestStartTime,
                parameter.terms,
                parameter.percentages,
                units_
            );
        }
    }

    function _refund(uint24 offeringId_, uint128 units_)
        internal
        virtual
        override
    {
        ERC20TransferHelper.doTransferOut(
            markets[offerings[offeringId_].voucher].asset,
            payable(offerings[offeringId_].issuer),
            units_
        );
    }

    function isSupportVoucherType(Constants.VoucherType voucherType_)
        public
        pure
        override
        returns (bool)
    {
        return (voucherType_ == Constants.VoucherType.FLEXIBLE_DATE_VESTING ||
            voucherType_ == Constants.VoucherType.STANDARD_VESTING);
    }
}