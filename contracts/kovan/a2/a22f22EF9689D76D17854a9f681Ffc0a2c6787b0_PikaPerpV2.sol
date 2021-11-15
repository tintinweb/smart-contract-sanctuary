// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import './IPikaPerp.sol';
import '../token/IPika.sol';

contract PikaPerpV2 is IPikaPerp {

    // All amounts are stored with 8 decimals

    // Structs

    struct Vault {
        // 32 bytes
        uint96 cap; // Maximum capacity. 12 bytes
        uint96 balance; // 12 bytes
        uint64 staked; // Total staked by users. 8 bytes
        // 32 bytes
        uint80 lastCheckpointBalance; // Used for max drawdown. 10 bytes
        uint80 lastCheckpointTime; // Used for max drawdown. 10 bytes
        uint32 stakingPeriod; // Time required to lock stake (seconds). 4 bytes
        uint32 redemptionPeriod; // Duration for redemptions (seconds). 4 bytes
        uint32 maxDailyDrawdown; // In basis points (bps) 1000 = 10%. 4 bytes
    }

    struct Stake {
        // 32 bytes
        address owner; // 20 bytes
        uint64 amount; // 8 bytes
        uint32 timestamp; // 4 bytes
    }

    struct Product {
        // 32 bytes
        address feed; // Chainlink feed. 20 bytes
        uint72 maxLeverage; // 9 bytes
        uint16 fee; // In bps. 0.5% = 50. 2 bytes
        bool isActive; // 1 byte
        // 32 bytes
        uint64 maxExposure; // Maximum allowed long/short imbalance. 8 bytes
        uint48 openInterestLong; // 6 bytes
        uint48 openInterestShort; // 6 bytes
        uint16 interest; // For 360 days, in bps. 5.35% = 535. 2 bytes
        uint32 settlementTime; // In seconds. 4 bytes
        uint16 minTradeDuration; // In seconds. 2 bytes
        uint16 liquidationThreshold; // In bps. 8000 = 80%. 2 bytes
        uint16 liquidationBounty; // In bps. 500 = 5%. 2 bytes
        uint32 reserve; // Virtual reserve in ETH. Used to calculate slippage
    }

    struct Position {
        // 32 bytes
        uint64 productId; // 8 bytes
        uint64 leverage; // 8 bytes
        uint64 price; // 8 bytes
        uint64 margin; // 8 bytes
        // 32 bytes
        address owner; // 20 bytes
        uint80 timestamp; // 10 bytes
        bool isLong; // 1 byte
        bool isSettling; // 1 byte
        bool isPika; // 1 byte
    }

    // Variables

    address public owner; // Contract owner
    uint256 public MIN_MARGIN = 100000; // 0.001 ETH
    uint256 public nextStakeId; // Incremental
    uint256 public nextPositionId; // Incremental
    uint256 public protocolFee;  // In bps. 100 = 1%
    uint256 public reserve;  // virtual reserve in ETH
    uint256 public maxShift = 0.003e8; // max shift (shift is used adjust the price to balance the longs and shorts)
    uint256 public pikaFee = 0.005e8; // 0.5%, fee to pay when close pika position
    uint256 public pikaRewardRatio = 0.20e8; // 20%, percent of trading fee to reward pika holders
    uint256 public pikaReward; // the trading fee reward for pika holders.
    uint256 public checkBackRounds = 100; // number of rounds to check back to search for the first round with timestamp that is larger than target timestamp
    Vault private vault;
    address public pika; // The address of PIKA stablecoin.
    address payable public rewardDistributor;

    mapping(uint256 => Product) private products;
    mapping(uint256 => Stake) private stakes;
    mapping(uint256 => Position) private positions;

    // Events

    event Staked(
        uint256 stakeId,
        address indexed user,
        uint256 amount
    );
    event Redeemed(
        uint256 stakeId,
        address indexed user,
        uint256 amount,
        bool isFullRedeem
    );
    event NewPosition(
        uint256 indexed positionId,
        address indexed user,
        uint256 indexed productId,
        bool isLong,
        uint256 price,
        uint256 margin,
        uint256 leverage,
        bool isPika
    );
    event NewPositionSettled(
        uint256 indexed positionId,
        address indexed user,
        uint256 price
    );
    event AddMargin(
        uint256 indexed positionId,
        address indexed user,
        uint256 margin,
        uint256 newMargin,
        uint256 newLeverage
    );
    event ClosePosition(
        uint256 positionId,
        address indexed user,
        uint256 indexed productId,
        bool indexed isFullClose,
        uint256 price,
        uint256 entryPrice,
        uint256 margin,
        uint256 leverage,
        uint256 pnl,
        bool pnlIsNegative,
        bool wasLiquidated
    );
    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed liquidator,
        uint256 vaultReward,
        uint256 liquidatorReward
    );
    event VaultUpdated(
        Vault vault
    );
    event ProductAdded(
        uint256 productId,
        Product product
    );
    event ProductUpdated(
        uint256 productId,
        Product product
    );
    event ProtocolFeeUpdated(
        uint256 bps
    );
    event OwnerUpdated(
        address newOwner
    );
    event MintPika(
        address owner,
        uint64 amount
    );
    event BurnPika(
        address owner,
        uint64 amount
    );
    event RewardDistribute(
        address payable indexed rewardDistributor, // The distributor address to receive the trading fee reward.
        uint amount // The amount of tokens collected.
    );

    // Constructor

    constructor(address _pika) {
        owner = msg.sender;
        pika = _pika;
        vault = Vault({
        cap: 0,
        maxDailyDrawdown: 0,
        staked: 0,
        balance: 0,
        lastCheckpointBalance: 0,
        lastCheckpointTime: uint80(block.timestamp),
        stakingPeriod: uint32(30 * 24 * 3600),
        redemptionPeriod: uint32(8 * 3600)
        });
    }

    // Methods

    // Stakes msg.value in the vault
    function stake() external payable {

        uint256 amount = msg.value / 10**10; // truncate to 8 decimals

        require(amount >= MIN_MARGIN, "!margin");
        require(uint256(vault.staked) + amount <= uint256(vault.cap), "!cap");

        vault.balance += uint96(amount);
        vault.staked += uint64(amount);

        address user = msg.sender;

        nextStakeId++;
        stakes[nextStakeId] = Stake({
        owner: user,
        amount: uint64(amount),
        timestamp: uint32(block.timestamp)
        });

        emit Staked(
            nextStakeId,
            user,
            amount
        );

    }

    // Redeems amount from Stake with id = stakeId
    function redeem(
        uint256 stakeId,
        uint256 amount
    ) external {

        require(amount <= uint256(vault.staked), "!staked");

        address user = msg.sender;

        Stake storage _stake = stakes[stakeId];
        require(_stake.owner == user, "!owner");

        bool isFullRedeem = amount >= uint256(_stake.amount);
        if (isFullRedeem) {
            amount = uint256(_stake.amount);
        }

        if (user != owner) {
            uint256 timeDiff = block.timestamp - uint256(_stake.timestamp);
            require(
                (timeDiff > uint256(vault.stakingPeriod)) &&
                (timeDiff % uint256(vault.stakingPeriod)) < uint256(vault.redemptionPeriod)
            , "!period");
        }

        uint256 amountBalance = amount * uint256(vault.balance) / uint256(vault.staked);

        _stake.amount -= uint64(amount);
        vault.staked -= uint64(amount);
        vault.balance -= uint96(amountBalance);

        if (isFullRedeem) {
            delete stakes[stakeId];
        }

        payable(user).transfer(amountBalance * 10**10);

        emit Redeemed(
        stakeId,
        user,
    amountBalance,
    isFullRedeem
    );

    }

    // Opens position with margin = msg.value
    function openPosition(
        uint256 productId,
        bool isLong,
        uint256 leverage,
        bool isPika
    ) external payable {

        uint256 margin = msg.value / 10**10; // truncate to 8 decimals

        // Check params
        require(margin >= MIN_MARGIN, "!margin");
        require(leverage >= 1 * 10**8, "!leverage");

        // Check product
        Product storage product = products[productId];
        require(product.isActive, "!product-active");
        require(leverage <= uint256(product.maxLeverage), "!max-leverage");

        // Check exposure
        uint256 amount = margin * leverage / 10**8;

        if (isLong) {

            product.openInterestLong += uint48(amount);
            require(
                uint256(product.openInterestLong) <=
                uint256(product.maxExposure) + uint256(product.openInterestShort)
            , "!exposure-long");

        } else {

            product.openInterestShort += uint48(amount);
            require(
                uint256(product.openInterestShort) <=
                uint256(product.maxExposure) + uint256(product.openInterestLong)
            , "!exposure-short");

        }

        uint256 price = _calculatePriceWithFee(product.feed, uint256(product.fee), isLong, product.openInterestLong,
            product.openInterestShort, uint256(product.maxExposure), amount, 0);

        address user = msg.sender;

        nextPositionId++;

        if (isPika) {
            require(leverage == 1, "leverage not 1 when minting pika");
            positions[nextPositionId] = Position({
                owner: user,
                productId: uint64(productId),
                margin: uint64(margin),
                leverage: uint64(leverage),
                price: uint64(price),
                timestamp: uint80(block.timestamp),
                isLong: isLong,
                isSettling: true,
                isPika: true
            });
            emit NewPosition(
                nextPositionId,
                user,
                productId,
                isLong,
                price,
                margin,
                leverage,
                true
            );
        }

        positions[nextPositionId] = Position({
            owner: user,
            productId: uint64(productId),
            margin: uint64(margin),
            leverage: uint64(leverage),
            price: uint64(price),
            timestamp: uint80(block.timestamp),
            isLong: isLong,
            isSettling: true,
            isPika: false
        });

        emit NewPosition(
            nextPositionId,
            user,
            productId,
            isLong,
            price,
            margin,
            leverage,
            false
        );

    }

    // Add margin = msg.value to Position with id = positionId
    function addMargin(uint256 positionId) external payable {

        uint256 margin = msg.value / 10**10; // truncate to 8 decimals

        // Check params
        require(margin >= MIN_MARGIN, "!margin");

        // Check position
        Position storage position = positions[positionId];
        require(msg.sender == position.owner, "!owner");
        require(position.isPika == false, "pika");

        // New position params
        uint256 newMargin = uint256(position.margin) + margin;
        uint256 newLeverage = uint256(position.leverage) * uint256(position.margin) / newMargin;
        require(newLeverage >= 1 * 10**8, "!low-leverage");

        position.margin = uint64(newMargin);
        position.leverage = uint64(newLeverage);

        emit AddMargin(
            positionId,
            position.owner,
            margin,
            newMargin,
            newLeverage
        );

    }

    // Closes margin from Position with id = positionId
    function closePosition(
        uint256 positionId,
        uint256 margin,
        bool releaseMargin
    ) external {

        // Check params
        require(margin >= MIN_MARGIN, "!margin");

        // Check position
        Position storage position = positions[positionId];
        require(msg.sender == position.owner, "!owner");
        require(!position.isSettling, "!settling");

        // Check product
        Product storage product = products[uint256(position.productId)];
        require(
            block.timestamp >= uint256(position.timestamp) + uint256(product.minTradeDuration)
        , "!duration");

        bool isFullClose;
        if (margin >= uint256(position.margin)) {
            margin = uint256(position.margin);
            isFullClose = true;
        }

        uint256 price = _calculatePriceWithFee(product.feed, uint256(product.fee), !position.isLong, product.openInterestLong, product.openInterestShort,
            uint256(product.maxExposure), margin * position.leverage / 10**8, 0);


        uint256 pnl;
        bool pnlIsNegative;

        bool isLiquidatable = _checkLiquidation(position, price, uint256(product.liquidationThreshold));

        if (isLiquidatable) {
            margin = uint256(position.margin);
            pnl = uint256(position.margin);
            pnlIsNegative = true;
            isFullClose = true;
        } else {

            if (position.isLong) {
                if (price >= uint256(position.price)) {
                    pnl = margin * uint256(position.leverage) * (price - uint256(position.price)) / (uint256(position.price) * 10**8);
                } else {
                    pnl = margin * uint256(position.leverage) * (uint256(position.price) - price) / (uint256(position.price) * 10**8);
                    pnlIsNegative = true;
                }
            } else {
                if (price > uint256(position.price)) {
                    pnl = margin * uint256(position.leverage) * (price - uint256(position.price)) / (uint256(position.price) * 10**8);
                    pnlIsNegative = true;
                } else {
                    pnl = margin * uint256(position.leverage) * (uint256(position.price) - price) / (uint256(position.price) * 10**8);
                }
            }

            // Subtract interest from P/L
            uint256 interest = _calculateInterest(margin * uint256(position.leverage) / 10**8, uint256(position.timestamp), uint256(product.interest));
            if (pnlIsNegative) {
                pnl += interest;
            } else if (pnl < interest) {
                pnl = interest - pnl;
                pnlIsNegative = true;
            } else {
                pnl -= interest;
            }

            // Calculate protocol fee
            if (protocolFee > 0) {
                uint256 protocolFeeAmount = protocolFee * margin * position.leverage / 10**12;
                pikaReward += protocolFeeAmount * pikaRewardRatio / (10**8);
                protocolFeeAmount = protocolFeeAmount - pikaReward;
                payable(owner).transfer(protocolFeeAmount * 10**10);
                if (pnlIsNegative) {
                    pnl += protocolFeeAmount;
                } else if (pnl < protocolFeeAmount) {
                    pnl = protocolFeeAmount - pnl;
                    pnlIsNegative = true;
                } else {
                    pnl -= protocolFeeAmount;
                }
            }

        }

        // Checkpoint vault
        if (uint256(vault.lastCheckpointTime) < block.timestamp - 24 hours) {
            vault.lastCheckpointTime = uint80(block.timestamp);
            vault.lastCheckpointBalance = uint80(vault.balance);
        }

        // Update vault
        if (pnlIsNegative) {

            if (pnl < margin) {
                payable(position.owner).transfer((margin - pnl) * 10**10);
                vault.balance += uint96(pnl);
            } else {
                vault.balance += uint96(margin);
            }

        } else {

            if (releaseMargin) {
                // When there's not enough funds in the vault, user can choose to receive their margin without profit
                pnl = 0;
            }

            // Check vault
            require(uint256(vault.balance) >= pnl, "!vault-insufficient");
            require(
                uint256(vault.balance) - pnl >= uint256(vault.lastCheckpointBalance) * (10**4 - uint256(vault.maxDailyDrawdown)) / 10**4
            , "!max-drawdown");

            vault.balance -= uint96(pnl);

            payable(position.owner).transfer((margin + pnl) * 10**10);

        }

        if (position.isLong) {
            if (uint256(product.openInterestLong) >= margin * uint256(position.leverage) / 10**8) {
                product.openInterestLong -= uint48(margin * uint256(position.leverage) / 10**8);
            } else {
                product.openInterestLong = 0;
            }
        } else {
            if (uint256(product.openInterestShort) >= margin * uint256(position.leverage) / 10**8) {
                product.openInterestShort -= uint48(margin * uint256(position.leverage) / 10**8);
            } else {
                product.openInterestShort = 0;
            }
        }

        emit ClosePosition(
            positionId,
            position.owner,
            uint256(position.productId),
            isFullClose,
            price,
            uint256(position.price),
            margin,
            uint256(position.leverage),
            pnl,
            pnlIsNegative,
            isLiquidatable
        );

        if (isFullClose) {
            delete positions[positionId];
        } else {
            position.margin -= uint64(margin);
        }

    }

    function closePikaPosition(
        uint256 amount,
        bool releaseMargin
    ) external {
        Product storage product = products[uint256(1)]; // eth product
        uint256 price = _calculatePriceWithFee(product.feed, uint256(product.fee), true, product.openInterestLong, product.openInterestShort,
            uint256(product.maxExposure), amount / (getPrice(product.feed, 0, 0) * 10**8), 0);
        uint256 margin = amount / price;

        uint256 pnl;
        bool pnlIsNegative;

        // Subtract interest from P/L
        uint256 interest = amount * pikaFee / (10**8) * (10**4); // 0.5% interest rate

        if (pnlIsNegative) {
            pnl += interest;
        } else if (pnl < interest) {
            pnl = interest - pnl;
            pnlIsNegative = true;
        } else {
            pnl -= interest;
        }

        // Calculate protocol fee
        if (protocolFee > 0) {
            uint256 protocolFeeAmount = protocolFee * margin / 10**12;
            payable(owner).transfer(protocolFeeAmount * 10**10);
            if (pnlIsNegative) {
                pnl += protocolFeeAmount;
            } else if (pnl < protocolFeeAmount) {
                pnl = protocolFeeAmount - pnl;
                pnlIsNegative = true;
            } else {
                pnl -= protocolFeeAmount;
            }
        }

        // Checkpoint vault
        if (uint256(vault.lastCheckpointTime) < block.timestamp - 24 hours) {
            vault.lastCheckpointTime = uint80(block.timestamp);
            vault.lastCheckpointBalance = uint80(vault.balance);
        }

        // burn pika tokens
        IPika(pika).burn(msg.sender, uint64(amount));
        emit BurnPika(msg.sender, uint64(amount));

        // Update vault
        if (pnlIsNegative) {

            if (pnl < margin) {
                payable(msg.sender).transfer((margin - pnl) * 10**10);
                vault.balance += uint96(pnl);
            } else {
                vault.balance += uint96(margin);
            }

        } else {

            if (releaseMargin) {
                // When there's not enough funds in the vault, user can choose to receive their margin without profit
                pnl = 0;
            }

            // Check vault
            require(uint256(vault.balance) >= pnl, "!vault-insufficient");
            require(
                uint256(vault.balance) - pnl >= uint256(vault.lastCheckpointBalance) * (10**4 - uint256(vault.maxDailyDrawdown)) / 10**4
            , "!max-drawdown");

            vault.balance -= uint96(pnl);

            payable(msg.sender).transfer((margin + pnl) * 10**10);

        }

        if (uint256(product.openInterestShort) >= margin / 10**8) {
            product.openInterestShort -= uint48(margin / 10**8);
        } else {
            product.openInterestShort = 0;
        }


    }

    // Checks if positionIds can be settled
    function canSettlePositions(uint256[] calldata positionIds) external view returns(uint256[] memory _positionIds) {

        uint256 length = positionIds.length;
        _positionIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {

            uint256 positionId = positionIds[i];

            Position storage position = positions[positionId];

            if (position.productId == 0 || !position.isSettling) {
                continue;
            }

            Product storage product = products[uint256(position.productId)];

            uint256 price = _calculatePriceWithFee(product.feed, uint256(product.fee), position.isLong, product.openInterestLong, product.openInterestShort,
                uint256(product.maxExposure), position.margin * position.leverage / 10**8, position.timestamp);

            if (block.timestamp - uint256(position.timestamp) >= uint256(product.settlementTime) || price != uint256(position.price)) {
                _positionIds[i] = positionId;
            }

        }

        return _positionIds;

    }

    // Settles positionIds
    function settlePositions(uint256[] calldata positionIds) external {

        uint256 length = positionIds.length;

        for (uint256 i = 0; i < length; i++) {

            uint256 positionId = positionIds[i];

            Position storage position = positions[positionId];

            if (position.productId == 0 || !position.isSettling) {
                continue;
            }

            Product storage product = products[uint256(position.productId)];

            uint256 price = _calculatePriceWithFee(product.feed, uint256(product.fee), position.isLong,product.openInterestLong, product.openInterestShort,
                uint256(product.maxExposure), position.margin * position.leverage / 10**8, position.timestamp);

            if (block.timestamp - uint256(position.timestamp) >= uint256(product.settlementTime) || price != uint256(position.price)) {
                position.price = uint64(price);
                position.isSettling = false;
                position.timestamp = uint80(block.timestamp);
                if (position.isPika) {
                    uint64 amount = position.margin * position.price;
                    IPika(pika).mint(position.owner, amount * (10**10));
                    delete positions[positionId];
                    emit MintPika(
                        position.owner,
                        amount * (10**10)
                    );
                }
            }

            emit NewPositionSettled(
                positionId,
                position.owner,
                price
            );

        }

    }

    // Liquidate positionIds
    function liquidatePositions(uint256[] calldata positionIds) external {

        address liquidator = msg.sender;
        uint256 length = positionIds.length;
        uint256 totalLiquidatorReward;

        for (uint256 i = 0; i < length; i++) {

            uint256 positionId = positionIds[i];
            Position memory position = positions[positionId];

            if (position.productId == 0 || position.isSettling) {
                continue;
            }

            Product storage product = products[uint256(position.productId)];

            uint256 price = _calculatePriceWithFee(product.feed, uint256(product.fee), !position.isLong, product.openInterestLong, product.openInterestShort,
                uint256(product.maxExposure), position.margin * position.leverage / 10**8, 0);

            // Local test
            // price = 20000*10**8;

            if (_checkLiquidation(position, price, uint256(product.liquidationThreshold))) {

                uint256 vaultReward = uint256(position.margin) * (10**4 - uint256(product.liquidationBounty)) / 10**4;
                vault.balance += uint96(vaultReward);

                uint256 liquidatorReward = uint256(position.margin) - vaultReward;
                totalLiquidatorReward += liquidatorReward;

                uint256 amount = uint256(position.margin) * uint256(position.leverage) / 10**8;

                if (position.isLong) {
                    if (uint256(product.openInterestLong) >= amount) {
                        product.openInterestLong -= uint48(amount);
                    } else {
                        product.openInterestLong = 0;
                    }
                } else {
                    if (uint256(product.openInterestShort) >= amount) {
                        product.openInterestShort -= uint48(amount);
                    } else {
                        product.openInterestShort = 0;
                    }
                }

                emit ClosePosition(
                    positionId,
                    position.owner,
                    uint256(position.productId),
                    true,
                    price,
                    uint256(position.price),
                    uint256(position.margin),
                    uint256(position.leverage),
                    uint256(position.margin),
                    true,
                    true
                );

                delete positions[positionId];

                emit PositionLiquidated(
                    positionId,
                    liquidator,
                    uint256(vaultReward),
                    uint256(liquidatorReward)
                );

            }

        }

        if (totalLiquidatorReward > 0) {
            payable(liquidator).transfer(totalLiquidatorReward);
        }

    }

    function distributeReward() external override returns (uint256) {
        require(msg.sender == rewardDistributor, "sender is not rewardDistributor");
        if (pikaReward > 0) {
            uint distributedReward = pikaReward;
            pikaReward = 0;
            payable(rewardDistributor).transfer(distributedReward * 10**10);
            emit RewardDistribute(rewardDistributor, distributedReward);
            return distributedReward;
        }
        return 0;
    }

    // Getters

    function getVault() external view returns(Vault memory) {
        return vault;
    }

    function getProduct(uint256 productId) external view returns(Product memory) {
        return products[productId];
    }

    function getPositions(uint256[] calldata positionIds) external view returns(Position[] memory _positions) {
        uint256 length = positionIds.length;
        _positions = new Position[](length);
        for (uint256 i=0; i < length; i++) {
            _positions[i] = positions[positionIds[i]];
        }
        return _positions;
    }

    function getStakes(uint256[] calldata stakeIds) external view returns(Stake[] memory _stakes) {
        uint256 length = stakeIds.length;
        _stakes = new Stake[](length);
        for (uint256 i=0; i < length; i++) {
            _stakes[i] = stakes[stakeIds[i]];
        }
        return _stakes;
    }

    function getPrice(
        address feed,
        uint256 productId,
        uint256 blockTime
    ) public view returns (uint256) {

        // local test
        //return 33500 * 10**8;

        if (productId > 0) { // for client
            Product memory product = products[productId];
            feed = product.feed;
        }

        require(feed != address(0), '!feed-error');

        int price;
        uint timeStamp;
        if (blockTime == 0) { // get latest round price
            (
            ,
            price,
            ,
            timeStamp,

            ) = AggregatorV2V3Interface(feed).latestRoundData();
        } else {
            uint256 roundId = getRoundIdByTime(feed, blockTime);
            (
            ,
            price,
            ,
            timeStamp,

            ) = AggregatorV2V3Interface(feed).getRoundData(uint80(roundId));

        }


        require(price > 0, '!price');
        require(timeStamp > 0, '!timeStamp');

        uint8 decimals = AggregatorV2V3Interface(feed).decimals();

        uint256 priceToReturn;
        if (decimals != 8) {
            priceToReturn = uint256(price) * (10**8) / (10**uint256(decimals));
        } else {
            priceToReturn = uint256(price);
        }

        return priceToReturn;

    }

    /// Get the reward that has not been distributed.
    function getPendingReward() external override view returns (uint256) {
        return pikaReward;
    }

    function getRoundIdByTime(
        address feed,
        uint256 blockTime
    ) public view returns(uint256) {
        // use binary search to find the 1st round with larger timestamp than blockTime
        uint256 high = AggregatorV2V3Interface(feed).latestRound();
        // add this check since most of time blockTime is larger than latest feed update time
        if (AggregatorV2V3Interface(feed).latestTimestamp() <= blockTime) {
            return high;
        }
        uint256 low = high - checkBackRounds;
        while (low != high) {
            uint256 mid = (low + high) / 2;
            if (AggregatorV2V3Interface(feed).getTimestamp(mid) <= blockTime) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    // Internal methods

    function _calculatePriceWithFee(
        address feed,
        uint256 fee,
        bool isLong,
        uint256 openInterestLong,
        uint256 openInterestShort,
        uint256 maxExposure,
        uint256 amount,
        uint256 blockTime // if 0, calculate latest price
    ) internal view returns(uint256) {

        uint256 oraclePrice = getPrice(feed, 0, blockTime);
        int256 shift = (int256(openInterestLong) - int256(openInterestShort)) * int256(maxShift) / int256(maxExposure);

        if (isLong) {
            uint256 slippage = ((reserve * reserve / (reserve - amount) - reserve) * (10**8) / amount);
            slippage = shift >= 0 ? slippage + uint256(shift) : slippage - uint256(-1 * shift) / 2;
            uint256 price = oraclePrice * slippage / (10**8);
            return price + price * fee / 10**4;
        } else {
            uint256 slippage = ((reserve - reserve * reserve / (reserve + amount)) * (10**8) / amount);
            slippage = shift >= 0 ? slippage - uint256(shift) / 2 : slippage + uint256(-1 * shift);
            uint256 price = oraclePrice * slippage / (10**8);
            return price - price * fee / 10**4;
        }
    }

    function _calculateInterest(uint256 amount, uint256 timestamp, uint256 interest) internal view returns (uint256) {
        if (block.timestamp < timestamp + 900) return 0;
        return amount * interest * (block.timestamp - timestamp) / (10**4 * 360 days);
    }

    function _checkLiquidation(
        Position memory position,
        uint256 price,
        uint256 liquidationThreshold
    ) internal pure returns (bool) {

        uint256 liquidationPrice;

        if (position.isLong) {
            liquidationPrice = position.price - position.price * liquidationThreshold * 10**4 / uint256(position.leverage);
        } else {
            liquidationPrice = position.price + position.price * liquidationThreshold * 10**4 / uint256(position.leverage);
        }

        if (position.isLong && price <= liquidationPrice || !position.isLong && price >= liquidationPrice) {
            return true;
        } else {
            return false;
        }

    }

    // Owner methods

    function updateVault(Vault memory _vault) external onlyOwner {

        require(_vault.cap > 0, "!cap");
        require(_vault.maxDailyDrawdown > 0, "!maxDailyDrawdown");
        require(_vault.stakingPeriod > 0, "!stakingPeriod");
        require(_vault.redemptionPeriod > 0, "!redemptionPeriod");

        vault.cap = _vault.cap;
        vault.maxDailyDrawdown = _vault.maxDailyDrawdown;
        vault.stakingPeriod = _vault.stakingPeriod;
        vault.redemptionPeriod = _vault.redemptionPeriod;

        emit VaultUpdated(vault);

    }

    function addProduct(uint256 productId, Product memory _product) external onlyOwner {

        Product memory product = products[productId];
        require(product.maxLeverage == 0, "!product-exists");

        require(_product.maxLeverage > 0, "!max-leverage");
        require(_product.feed != address(0), "!feed");
        require(_product.settlementTime > 0, "!settlementTime");
        require(_product.liquidationThreshold > 0, "!liquidationThreshold");

        products[productId] = Product({
            feed: _product.feed,
            maxLeverage: _product.maxLeverage,
            fee: _product.fee,
            isActive: true,
            maxExposure: _product.maxExposure,
            openInterestLong: 0,
            openInterestShort: 0,
            interest: _product.interest,
            settlementTime: _product.settlementTime,
            minTradeDuration: _product.minTradeDuration,
            liquidationThreshold: _product.liquidationThreshold,
            liquidationBounty: _product.liquidationBounty,
            reserve: _product.reserve
        });

        emit ProductAdded(productId, products[productId]);

    }

    function updateProduct(uint256 productId, Product memory _product) external onlyOwner {

        Product storage product = products[productId];
        require(product.maxLeverage > 0, "!product-exists");

        require(_product.maxLeverage >= 1 * 10**8, "!max-leverage");
        require(_product.feed != address(0), "!feed");
        require(_product.settlementTime > 0, "!settlementTime");
        require(_product.liquidationThreshold > 0, "!liquidationThreshold");

        product.feed = _product.feed;
        product.maxLeverage = _product.maxLeverage;
        product.fee = _product.fee;
        product.isActive = _product.isActive;
        product.maxExposure = _product.maxExposure;
        product.interest = _product.interest;
        product.settlementTime = _product.settlementTime;
        product.minTradeDuration = _product.minTradeDuration;
        product.liquidationThreshold = _product.liquidationThreshold;
        product.liquidationBounty = _product.liquidationBounty;

        emit ProductUpdated(productId, product);

    }

    function setProtocolFee(uint256 bps) external onlyOwner {
        require(bps <= 100, "!too-much"); // 1% in bps
        protocolFee = bps;
        emit ProtocolFeeUpdated(protocolFee);
    }

    function setRewardDistributor(address payable newRewardDistributor) external onlyOwner {
        rewardDistributor = newRewardDistributor;
    }

    function setPikaRewardRatio(uint newPikaRewardRatio) external onlyOwner {
        pikaRewardRatio = newPikaRewardRatio;
    }

    function setPikaFee(uint newPikaFee) external onlyOwner {
        pikaFee = newPikaFee;
    }

    function setCheckBackRounds(uint newCheckBackRounds) external onlyOwner {
        checkBackRounds = newCheckBackRounds;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPikaPerp {
    // @dev Send reward to reward distributor.
    function distributeReward() external returns (uint256);

    // @dev Get the reward amount that has not been distributed.
    function getPendingReward() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPika is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function totalSupplyWithReward() external view returns (uint256);
    function balanceWithReward(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

