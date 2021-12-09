// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@universe/marketplace/contracts/interfaces/IRoyaltiesProvider.sol";
import "@universe/marketplace/contracts/lib/LibPart.sol";
import "./IUniverseAuctionHouse.sol";

contract UniverseAuctionHouse is IUniverseAuctionHouse, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public totalAuctions;
    uint256 public maxNumberOfSlotsPerAuction;
    uint256 public royaltyFeeBps;
    uint256 public nftSlotLimit;
    address payable public daoAddress;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint256) public auctionsRevenue;
    mapping(address => uint256) public royaltiesReserve;
    mapping(address => bool) public supportedBidTokens;

    IRoyaltiesProvider public royaltiesRegistry;
    address private constant GUARD = address(1);

    event LogERC721Deposit(
        address depositor,
        address tokenAddress,
        uint256 tokenId,
        uint256 auctionId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    );

    event LogERC721Withdrawal(
        address depositor,
        address tokenAddress,
        uint256 tokenId,
        uint256 auctionId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    );

    event LogAuctionCreated(
        uint256 auctionId,
        address auctionOwner,
        uint256 numberOfSlots,
        uint256 startTime,
        uint256 endTime,
        uint256 resetTimer
    );

    event LogBidSubmitted(
        address sender,
        uint256 auctionId,
        uint256 currentBid,
        uint256 totalBid
    );

    event LogBidWithdrawal(
        address recipient, 
        uint256 auctionId, 
        uint256 amount
    );

    event LogBidMatched(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 slotReservePrice,
        uint256 winningBidAmount,
        address winner
    );

    event LogAuctionExtended(
        uint256 auctionId, 
        uint256 endTime
    );

    event LogAuctionCanceled(
        uint256 auctionId
    );

    event LogAuctionRevenueWithdrawal(
        address recipient,
        uint256 auctionId,
        uint256 amount
    );

    event LogERC721RewardsClaim(
        address claimer,
        uint256 auctionId,
        uint256 slotIndex
    );

    event LogRoyaltiesWithdrawal(
        uint256 amount, 
        address to, 
        address token
    );

    event LogSlotRevenueCaptured(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount,
        address bidToken
    );

    event LogAuctionFinalized(
        uint256 auctionId
    );

    modifier onlyExistingAuction(uint256 auctionId) {
        require(auctionId > 0 && auctionId <= totalAuctions, "Auction doesn't exist");
        _;
    }

    modifier onlyAuctionStarted(uint256 auctionId) {
        require(auctions[auctionId].startTime < block.timestamp, "Auction hasn't started");
        _;
    }

    modifier onlyAuctionNotStarted(uint256 auctionId) {
        require(auctions[auctionId].startTime > block.timestamp, "Auction has started");
        _;
    }

    modifier onlyAuctionNotCanceled(uint256 auctionId) {
        require(!auctions[auctionId].isCanceled, "Auction is canceled");
        _;
    }

    modifier onlyAuctionCanceled(uint256 auctionId) {
        require(auctions[auctionId].isCanceled, "Auction not canceled");
        _;
    }

    modifier onlyAuctionOwner(uint256 auctionId) {
        require(auctions[auctionId].auctionOwner == msg.sender, "Only auction owner");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Not called from the dao");
        _;
    }

    function __UniverseAuctionHouse_init(
        uint256 _maxNumberOfSlotsPerAuction,
        uint256 _nftSlotLimit,
        uint256 _royaltyFeeBps,
        address payable _daoAddress,
        address[] memory _supportedBidTokens,
        IRoyaltiesProvider _royaltiesRegistry
    ) external initializer {
        __ERC721Holder_init();
        __ReentrancyGuard_init();
        
        maxNumberOfSlotsPerAuction = _maxNumberOfSlotsPerAuction;
        nftSlotLimit = _nftSlotLimit;
        royaltyFeeBps = _royaltyFeeBps;
        daoAddress = _daoAddress;
        royaltiesRegistry = _royaltiesRegistry;

        for (uint256 i = 0; i < _supportedBidTokens.length; i += 1) {
            supportedBidTokens[_supportedBidTokens[i]] = true;
        }
        supportedBidTokens[address(0)] = true;
    }

    function createAuction(AuctionConfig calldata config) external override returns (uint256) {
        uint256 currentTime = block.timestamp;

        require(
            currentTime < config.startTime &&
                config.startTime < config.endTime &&
                config.resetTimer > 0,
            "Wrong time config"
        );
        require(
            config.numberOfSlots > 0 && config.numberOfSlots <= maxNumberOfSlotsPerAuction,
            "Slots out of bound"
        );
        require(supportedBidTokens[config.bidToken], "Bid token not supported");
        require(
            config.minimumReserveValues.length == 0 ||
                config.numberOfSlots == config.minimumReserveValues.length,
            "Incorrect number of slots"
        );
        // Ensure minimum reserve values are lower for descending slot numbers
        for (uint256 i = 1; i < config.minimumReserveValues.length; i += 1) {
            require(config.minimumReserveValues[i - 1] >= config.minimumReserveValues[i], "Invalid reserve value") ;
        }

        uint256 auctionId = totalAuctions.add(1);

        auctions[auctionId].auctionOwner = msg.sender;
        auctions[auctionId].startTime = config.startTime;
        auctions[auctionId].endTime = config.endTime;
        auctions[auctionId].resetTimer = config.resetTimer;
        auctions[auctionId].numberOfSlots = config.numberOfSlots;

        auctions[auctionId].bidToken = config.bidToken;
        auctions[auctionId].nextBidders[GUARD] = GUARD;

        for (uint256 j = 0; j < config.minimumReserveValues.length; j += 1) {
            auctions[auctionId].slots[j + 1].reservePrice = config.minimumReserveValues[j];
        }

        uint256 checkSum = 0;
        for (uint256 k = 0; k < config.paymentSplits.length; k += 1) {
            require(config.paymentSplits[k].recipient != address(0), "Recipient should be present");
            require(config.paymentSplits[k].value != 0, "Fee value should be positive");
            checkSum += config.paymentSplits[k].value;
            auctions[auctionId].paymentSplits.push(config.paymentSplits[k]);
        }
        require(checkSum < 10000, "Splits should be less than 100%");

        totalAuctions = auctionId;

        emit LogAuctionCreated(
            auctionId,
            msg.sender,
            config.numberOfSlots,
            config.startTime,
            config.endTime,
            config.resetTimer
        );

        return auctionId;
    }

    function batchDepositToAuction(
        uint256 auctionId,
        uint256[] calldata slotIndices,
        ERC721[][] calldata tokens
    )
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionNotStarted(auctionId)
        onlyAuctionNotCanceled(auctionId)
    {
        Auction storage auction = auctions[auctionId];

        require(slotIndices.length <= auction.numberOfSlots && 
                slotIndices.length <= 10 && 
                slotIndices.length == tokens.length, "Incorrect auction slots");

        for (uint256 i = 0; i < slotIndices.length; i += 1) {
            require(tokens[i].length <= 5, "Max 5 NFTs could be transferred");
            depositERC721(auctionId, slotIndices[i], tokens[i]);
        }

    }

    function ethBid(uint256 auctionId)
        external
        payable
        override
        onlyExistingAuction(auctionId)
        onlyAuctionStarted(auctionId)
        onlyAuctionNotCanceled(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        require(block.timestamp < auction.endTime, "Auction has ended");
        require(auction.totalDepositedERC721s > 0 && msg.value > 0, "Invalid bid");

        uint256 bidderCurrentBalance = auction.bidBalance[msg.sender];

        // Check if this is first time bidding
        if (bidderCurrentBalance == 0) {
            // If total bids are less than total slots, add bid without checking if the bid is within the winning slots (isWinningBid())
            if (auction.numberOfBids < auction.numberOfSlots) {
                addBid(auctionId, msg.sender, msg.value);

                // Check if slots are filled (we have more bids than slots)
            } else if (auction.numberOfBids >= auction.numberOfSlots) {
                // If slots are filled, check if the bid is within the winning slots
                require(isWinningBid(auctionId, msg.value), "Bid should be winnning");

                // Add bid only if it is within the winning slots
                addBid(auctionId, msg.sender, msg.value);
                if (auction.endTime.sub(block.timestamp) < auction.resetTimer) {
                    // Extend the auction if the remaining time is less than the reset timer
                    extendAuction(auctionId);
                }
            }
            // Check if the user has previously submitted bids
        } else if (bidderCurrentBalance > 0) {
            // Find which is the next highest bidder balance and ensure the incremented bid is bigger
            address previousBidder = _findPreviousBidder(auctionId, msg.sender);
            require(
                msg.value.add(bidderCurrentBalance) > auction.bidBalance[previousBidder],
                "Bid should be > next highest bid"
            );

            // If total bids are less than total slots update the bid directly
            if (auction.numberOfBids < auction.numberOfSlots) {
                updateBid(auctionId, msg.sender, bidderCurrentBalance.add(msg.value));

                // If slots are filled, check if the current bidder balance + the new amount will be withing the winning slots
            } else if (auction.numberOfBids >= auction.numberOfSlots) {
                require(
                    isWinningBid(auctionId, bidderCurrentBalance.add(msg.value)),
                    "Bid should be winnning"
                );

                // Update the bid if the new incremented balance falls within the winning slots
                updateBid(auctionId, msg.sender, bidderCurrentBalance.add(msg.value));
                if (auction.endTime.sub(block.timestamp) < auction.resetTimer) {
                    // Extend the auction if the remaining time is less than the reset timer
                    extendAuction(auctionId);
                }
            }
        }
    }

    function withdrawEthBid(uint256 auctionId)
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionStarted(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        address payable recipient = msg.sender;
        uint256 amount = auction.bidBalance[recipient];

        require(auction.numberOfBids > auction.numberOfSlots, "Can't withdraw bid");
        require(canWithdrawBid(auctionId, recipient), "Can't withdraw bid");

        removeBid(auctionId, recipient);
        emit LogBidWithdrawal(recipient, auctionId, amount);

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed");

    }

    function erc20Bid(uint256 auctionId, uint256 amount)
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionStarted(auctionId)
        onlyAuctionNotCanceled(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        require(block.timestamp < auction.endTime, "Auction has ended");
        require(auction.totalDepositedERC721s > 0 && amount > 0, "Invalid bid");

        IERC20Upgradeable bidToken = IERC20Upgradeable(auction.bidToken);

        uint256 bidderCurrentBalance = auction.bidBalance[msg.sender];

        // Check if this is first time bidding
        if (bidderCurrentBalance == 0) {
            // If total bids are less than total slots, add bid without checking if the bid is within the winning slots (isWinningBid())
            if (auction.numberOfBids < auction.numberOfSlots) {
                require(
                    bidToken.transferFrom(msg.sender, address(this), amount),
                    "Failed"
                );
                addBid(auctionId, msg.sender, amount);

                // Check if slots are filled (if we have more bids than slots)
            } else if (auction.numberOfBids >= auction.numberOfSlots) {
                // If slots are filled, check if the bid is within the winning slots
                require(isWinningBid(auctionId, amount), "Bid should be winnning");
                require(
                    bidToken.transferFrom(msg.sender, address(this), amount),
                    "Failed"
                );

                // Add bid only if it is within the winning slots
                addBid(auctionId, msg.sender, amount);

                if (auction.endTime.sub(block.timestamp) < auction.resetTimer) {
                    // Extend the auction if the remaining time is less than the reset timer
                    extendAuction(auctionId);
                }
            }
            // Check if the user has previously submitted bids
        } else if (bidderCurrentBalance > 0) {
            // Find which is the next highest bidder balance and ensure the incremented bid is bigger
            address previousBidder = _findPreviousBidder(auctionId, msg.sender);
            require(
                amount.add(bidderCurrentBalance) > auction.bidBalance[previousBidder],
                "Bid should be > next highest bid"
            );

            // If total bids are less than total slots update the bid directly
            if (auction.numberOfBids < auction.numberOfSlots) {
                require(
                    bidToken.transferFrom(msg.sender, address(this), amount),
                    "Failed"
                );
                updateBid(auctionId, msg.sender, bidderCurrentBalance.add(amount));

                // If slots are filled, check if the current bidder balance + the new amount will be withing the winning slots
            } else if (auction.numberOfBids >= auction.numberOfSlots) {
                require(
                    isWinningBid(auctionId, bidderCurrentBalance.add(amount)),
                    "Bid should be winnning"
                );
                require(
                    bidToken.transferFrom(msg.sender, address(this), amount),
                    "Failed"
                );
                // Update the bid if the new incremented balance falls within the winning slots
                updateBid(auctionId, msg.sender, bidderCurrentBalance.add(amount));

                if (auction.endTime.sub(block.timestamp) < auction.resetTimer) {
                    // Extend the auction if the remaining time is less than the reset timer
                    extendAuction(auctionId);
                }
            }
        }
    }

    function withdrawERC20Bid(uint256 auctionId)
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionStarted(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        address sender = msg.sender;
        uint256 amount = auction.bidBalance[sender];

        require(auction.numberOfBids > auction.numberOfSlots, "Can't withdraw bid");
        require(canWithdrawBid(auctionId, sender), "Can't withdraw bid");

        removeBid(auctionId, sender);
        IERC20Upgradeable bidToken = IERC20Upgradeable(auction.bidToken);

        emit LogBidWithdrawal(sender, auctionId, amount);

        require(bidToken.transfer(sender, amount), "Failed");

    }

    function withdrawERC721FromNonWinningSlot(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount
    )
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionStarted(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        Slot storage nonWinningSlot = auction.slots[slotIndex];

        uint256 totalDeposited = nonWinningSlot.totalDepositedNfts;
        uint256 totalWithdrawn = nonWinningSlot.totalWithdrawnNfts;

        require(!nonWinningSlot.reservePriceReached, "Reserve price met");

        require(auction.isFinalized, "Auction should be finalized");
        require(amount <= 40, "Can't withdraw more than 40");
        require(amount <= totalDeposited.sub(totalWithdrawn), "Not enough available");

        for (uint256 i = totalWithdrawn; i < amount.add(totalWithdrawn); i += 1) {
            _withdrawERC721FromNonWinningSlot(auctionId, slotIndex, (i + 1));
        }

    }

    function finalizeAuction(uint256 auctionId)
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionNotCanceled(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        require(
            block.timestamp > auction.endTime && !auction.isFinalized,
            "Auction not finished"
        );

        address[] memory bidders;
        uint256 lastAwardedIndex = 0;

        // Get top bidders for the auction, according to the number of slots
        if (auction.numberOfBids > auction.numberOfSlots) {
            bidders = getTopBidders(auctionId, auction.numberOfSlots);
        } else {
            bidders = getTopBidders(auctionId, auction.numberOfBids);
        }

        // Award the slots by checking the highest bidders and minimum reserve values
        // Upper bound for bidders.length is maxNumberOfSlotsPerAuction
        for (uint256 i = 0; i < bidders.length; i += 1) {
            for (
                lastAwardedIndex;
                lastAwardedIndex < auction.numberOfSlots;
                lastAwardedIndex += 1
            ) {
                if (
                    auction.bidBalance[bidders[i]] >=
                    auction.slots[lastAwardedIndex + 1].reservePrice
                ) {
                    auction.slots[lastAwardedIndex + 1].reservePriceReached = true;
                    auction.slots[lastAwardedIndex + 1].winningBidAmount = auction.bidBalance[
                        bidders[i]
                    ];
                    auction.slots[lastAwardedIndex + 1].winner = bidders[i];
                    auction.winners[lastAwardedIndex + 1] = bidders[i];

                    emit LogBidMatched(
                        auctionId,
                        lastAwardedIndex + 1,
                        auction.slots[lastAwardedIndex + 1].reservePrice,
                        auction.slots[lastAwardedIndex + 1].winningBidAmount,
                        auction.slots[lastAwardedIndex + 1].winner
                    );

                    lastAwardedIndex += 1;

                    break;
                }
            }
        }

        auction.isFinalized = true;

        emit LogAuctionFinalized(auctionId);

    }

    function captureSlotRevenue(uint256 auctionId, uint256 slotIndex)
        public
        override
        onlyExistingAuction(auctionId)
        onlyAuctionNotCanceled(auctionId)
    {
        Auction storage auction = auctions[auctionId];

        require(auction.isFinalized && !auction.slots[slotIndex].revenueCaptured, "Not finalized/Already captured");
        require(auction.numberOfSlots >= slotIndex && slotIndex > 0, "Non-existing slot");

        uint256 slotRevenue = auction.bidBalance[auction.slots[slotIndex].winner];
        uint256 _secondarySaleFeesForSlot;

        // Calculate the auction revenue from sold slots and reset bid balances
        if (auction.slots[slotIndex].reservePriceReached) {
            auctionsRevenue[auctionId] = auctionsRevenue[auctionId].add(slotRevenue);
            auction.bidBalance[auction.slots[slotIndex].winner] = 0;

            // Calculate the amount accounted for secondary sale fees
            if (auction.slots[slotIndex].totalDepositedNfts > 0 && auction.slots[slotIndex].winningBidAmount > 0) {
                _secondarySaleFeesForSlot = calculateSecondarySaleFees(
                    auctionId,
                    (slotIndex)
                );
                auctionsRevenue[auctionId] = auctionsRevenue[auctionId].sub(
                    _secondarySaleFeesForSlot
                );
            }
        }

        // Calculate DAO fee and deduct from auction revenue
        uint256 _royaltyFee = royaltyFeeBps.mul(slotRevenue).div(10000);
        auctionsRevenue[auctionId] = auctionsRevenue[auctionId].sub(_royaltyFee);
        royaltiesReserve[auction.bidToken] = royaltiesReserve[auction.bidToken].add(_royaltyFee);
        auction.slots[slotIndex].revenueCaptured = true;

        emit LogSlotRevenueCaptured(
            auctionId,
            slotIndex,
            slotRevenue.sub(_secondarySaleFeesForSlot).sub(_royaltyFee),
            auction.bidToken
        );

    }

    function captureSlotRevenueRange(
        uint256 auctionId,
        uint256 startSlotIndex,
        uint256 endSlotIndex
    )
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionNotCanceled(auctionId)
    {
        require(
            startSlotIndex >= 1 && endSlotIndex <= auctions[auctionId].numberOfSlots,
            "Slots out of bound"
        );
        for (uint256 i = startSlotIndex; i <= endSlotIndex; i += 1) {
            captureSlotRevenue(auctionId, i);
        }
    }

    function cancelAuction(uint256 auctionId)
        external
        override
        onlyExistingAuction(auctionId)
        onlyAuctionNotStarted(auctionId)
        onlyAuctionNotCanceled(auctionId)
        onlyAuctionOwner(auctionId)
    {
        auctions[auctionId].isCanceled = true;

        emit LogAuctionCanceled(auctionId);

    }

    function distributeCapturedAuctionRevenue(uint256 auctionId)
        external
        override
        onlyExistingAuction(auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        require(auction.isFinalized, "Not finalized");

        uint256 amountToWithdraw = auctionsRevenue[auctionId];
        require(amountToWithdraw > 0, "Amount is 0");

        uint256 value = amountToWithdraw;
        uint256 paymentSplitsPaid;

        auctionsRevenue[auctionId] = 0;

        emit LogAuctionRevenueWithdrawal(
            auction.auctionOwner,
            auctionId,
            amountToWithdraw
        );

        // Distribute the payment splits to the respective recipients
        for (uint256 i = 0; i < auction.paymentSplits.length && i < 5; i += 1) {
            Fee memory interimFee = subFee(
                value,
                amountToWithdraw.mul(auction.paymentSplits[i].value).div(10000)
            );
            value = interimFee.remainingValue;
            paymentSplitsPaid = paymentSplitsPaid.add(interimFee.feeValue);

            if (auction.bidToken == address(0) && interimFee.feeValue > 0) {
                (bool success, ) = auction.paymentSplits[i].recipient.call{value: interimFee.feeValue}("");
                require(success, "Failed");
            }

            if (auction.bidToken != address(0) && interimFee.feeValue > 0) {
                IERC20Upgradeable token = IERC20Upgradeable(auction.bidToken);
                require(
                    token.transfer(
                        address(auction.paymentSplits[i].recipient),
                        interimFee.feeValue
                    ),
                    "Failed"
                );
            }
        }

        // Distribute the remaining revenue to the auction owner
        if (auction.bidToken == address(0)) {
            (bool success, ) = payable(auction.auctionOwner).call{value: amountToWithdraw.sub(paymentSplitsPaid)}("");
            require(success, "Failed");
        }

        if (auction.bidToken != address(0)) {
            IERC20Upgradeable bidToken = IERC20Upgradeable(auction.bidToken);
            require(
                bidToken.transfer(auction.auctionOwner, amountToWithdraw.sub(paymentSplitsPaid)),
                "Failed"
            );
        }

    }

    function claimERC721Rewards(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount
    ) external override nonReentrant {
        address claimer = msg.sender;

        Auction storage auction = auctions[auctionId];
        Slot storage winningSlot = auction.slots[slotIndex];

        uint256 totalDeposited = winningSlot.totalDepositedNfts;
        uint256 totalWithdrawn = winningSlot.totalWithdrawnNfts;

        require(auction.isFinalized && winningSlot.revenueCaptured, "Not finalized");
        require(auction.winners[slotIndex] == claimer, "Only winner can claim");
        require(winningSlot.reservePriceReached, "Reserve price not met");

        require(amount <= 40, "More than 40 NFTs");
        require(amount <= totalDeposited.sub(totalWithdrawn), "Can't claim more than available");

        emit LogERC721RewardsClaim(claimer, auctionId, slotIndex);

        for (uint256 i = totalWithdrawn; i < amount.add(totalWithdrawn); i += 1) {
            DepositedERC721 memory nftForWithdrawal = winningSlot.depositedNfts[i + 1];

            auction.totalWithdrawnERC721s = auction.totalWithdrawnERC721s.add(1);
            auction.slots[slotIndex].totalWithdrawnNfts = auction
            .slots[slotIndex]
            .totalWithdrawnNfts
            .add(1);

            if (nftForWithdrawal.tokenId != 0) {
                IERC721Upgradeable(nftForWithdrawal.tokenAddress).safeTransferFrom(
                    address(this),
                    claimer,
                    nftForWithdrawal.tokenId
                );
            }
        }

    }

    function distributeSecondarySaleFees(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) external override nonReentrant {
        Auction storage auction = auctions[auctionId];
        Slot storage slot = auction.slots[slotIndex];
        DepositedERC721 storage nft = slot.depositedNfts[nftSlotIndex];

        require(nft.hasSecondarySaleFees && !nft.feesPaid, "Not supported/Fees already paid");
        require(slot.revenueCaptured, "Slot revenue not captured");

        uint256 averageERC721SalePrice = slot.winningBidAmount.div(slot.totalDepositedNfts);

        LibPart.Part[] memory fees = royaltiesRegistry.getRoyalties(nft.tokenAddress, nft.tokenId);
        uint256 value = averageERC721SalePrice;
        nft.feesPaid = true;

        for (uint256 i = 0; i < fees.length && i < 5; i += 1) {
            Fee memory interimFee = subFee(value, averageERC721SalePrice.mul(fees[i].value).div(10000));
            value = interimFee.remainingValue;

            if (auction.bidToken == address(0) && interimFee.feeValue > 0) {
                (bool success, ) = (fees[i].account).call{value: interimFee.feeValue}("");
                require(success, "Failed");
            }

            if (auction.bidToken != address(0) && interimFee.feeValue > 0) {
                IERC20Upgradeable token = IERC20Upgradeable(auction.bidToken);
                require(
                    token.transfer(address(fees[i].account), interimFee.feeValue),
                    "Failed"
                );
            }
        }

    }

    function distributeRoyalties(address token)
        external
        override
        onlyDAO
        nonReentrant
        returns (uint256)
    {
        uint256 amountToWithdraw = royaltiesReserve[token];
        require(amountToWithdraw > 0, "Amount is 0");

        royaltiesReserve[token] = 0;

        emit LogRoyaltiesWithdrawal(amountToWithdraw, daoAddress, token);

        if (token == address(0)) {
            (bool success, ) = payable(daoAddress).call{value: amountToWithdraw}("");
            require(success, "Failed");
        }

        if (token != address(0)) {
            IERC20Upgradeable erc20token = IERC20Upgradeable(token);
            require(erc20token.transfer(daoAddress, amountToWithdraw), "Failed");
        }

        return amountToWithdraw;
    }

    function setRoyaltyFeeBps(uint256 _royaltyFeeBps) external override onlyDAO returns (uint256) {
        royaltyFeeBps = _royaltyFeeBps;
        return royaltyFeeBps;
    }

    function setNftSlotLimit(uint256 _nftSlotLimit) external override onlyDAO returns (uint256) {
        nftSlotLimit = _nftSlotLimit;
        return nftSlotLimit;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider _royaltiesRegistry) external override onlyDAO returns (IRoyaltiesProvider) {
        royaltiesRegistry = _royaltiesRegistry;
        return royaltiesRegistry;
    }

    function setSupportedBidToken(address erc20token, bool value)
        external
        override
        onlyDAO
        returns (address, bool)
    {
        supportedBidTokens[erc20token] = value;
        return (erc20token, value);
    }

    function getDepositedNftsInSlot(uint256 auctionId, uint256 slotIndex)
        external
        view
        override
        returns (DepositedERC721[] memory)
    {
        uint256 nftsInSlot = auctions[auctionId].slots[slotIndex].totalDepositedNfts;

        DepositedERC721[] memory nfts = new DepositedERC721[](nftsInSlot);

        for (uint256 i = 0; i < nftsInSlot; i += 1) {
            nfts[i] = auctions[auctionId].slots[slotIndex].depositedNfts[i + 1];
        }
        return nfts;
    }

    function getSlotInfo(uint256 auctionId, uint256 slotIndex)
        external
        view
        override
        returns (SlotInfo memory)
    {
        Slot storage slot = auctions[auctionId].slots[slotIndex];
        SlotInfo memory slotInfo = SlotInfo(
            slot.totalDepositedNfts,
            slot.totalWithdrawnNfts,
            slot.reservePrice,
            slot.winningBidAmount,
            slot.reservePriceReached,
            slot.revenueCaptured,
            slot.winner
        );
        return slotInfo;
    }

    function getSlotWinner(uint256 auctionId, uint256 slotIndex)
        external
        view
        override
        returns (address)
    {
        return auctions[auctionId].winners[slotIndex];
    }

    function getBidderBalance(uint256 auctionId, address bidder)
        external
        view
        override
        returns (uint256)
    {
        return auctions[auctionId].bidBalance[bidder];
    }

    function getMinimumReservePriceForSlot(uint256 auctionId, uint256 slotIndex)
        external
        view
        override
        returns (uint256)
    {
        return auctions[auctionId].slots[slotIndex].reservePrice;
    }

    function depositERC721(
        uint256 auctionId,
        uint256 slotIndex,
        ERC721[] calldata tokens
    )
        public
        override
        onlyExistingAuction(auctionId)
        onlyAuctionNotStarted(auctionId)
        onlyAuctionNotCanceled(auctionId)
        nonReentrant
        returns (uint256[] memory)
    {
        uint256[] memory nftSlotIndexes = new uint256[](tokens.length);

        require(msg.sender == auctions[auctionId].auctionOwner, "Not allowed to deposit");
        require(
            auctions[auctionId].numberOfSlots >= slotIndex && slotIndex > 0,
            "Non-existing slot"
        );
        require((tokens.length <= 40), "Can't deposit more than 40");
        require(
            (auctions[auctionId].slots[slotIndex].totalDepositedNfts + tokens.length <= nftSlotLimit),
            "Slot limit exceeded"
        );

        // Ensure previous slot has depoited NFTs, so there is no case where there is an empty slot between non-empty slots
        if (slotIndex > 1) {
            require(auctions[auctionId].slots[slotIndex - 1].totalDepositedNfts > 0, "Previous slot is empty");
        }

        for (uint256 i = 0; i < tokens.length; i += 1) {
            nftSlotIndexes[i] = _depositERC721(
                auctionId,
                slotIndex,
                tokens[i].tokenId,
                tokens[i].tokenAddress
            );
        }

        return nftSlotIndexes;
    }

    function withdrawDepositedERC721(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount
    ) public override onlyExistingAuction(auctionId) onlyAuctionCanceled(auctionId) nonReentrant {

        Auction storage auction = auctions[auctionId];
        Slot storage slot = auction.slots[slotIndex];

        uint256 totalDeposited = slot.totalDepositedNfts;
        uint256 totalWithdrawn = slot.totalWithdrawnNfts;

        require(amount <= 40, "Can't withdraw more than 40");
        require(amount <= totalDeposited.sub(totalWithdrawn), "Not enough available");

        for (uint256 i = totalWithdrawn; i < amount.add(totalWithdrawn); i += 1) {
            _withdrawDepositedERC721(auctionId, slotIndex, (i + 1));
        }

    }

    function getTopBidders(uint256 auctionId, uint256 n)
        public
        view
        override
        returns (address[] memory)
    {
        require(n <= auctions[auctionId].numberOfBids, "N should be lower");
        address[] memory biddersList = new address[](n);
        address currentAddress = auctions[auctionId].nextBidders[GUARD];
        for (uint256 i = 0; i < n; ++i) {
            biddersList[i] = currentAddress;
            currentAddress = auctions[auctionId].nextBidders[currentAddress];
        }

        return biddersList;
    }

    function isWinningBid(uint256 auctionId, uint256 bid) public view override returns (bool) {
        address[] memory bidders = getTopBidders(auctionId, auctions[auctionId].numberOfSlots);
        uint256 lowestEligibleBid = auctions[auctionId].bidBalance[bidders[bidders.length - 1]];
        return (bid > lowestEligibleBid);
    }

    function canWithdrawBid(uint256 auctionId, address bidder) public view override returns (bool) {
        address[] memory bidders = getTopBidders(auctionId, auctions[auctionId].numberOfSlots);
        bool canWithdraw = true;

        for (uint256 i = 0; i < bidders.length; i+=1) {
            if (bidders[i] == bidder) {
                canWithdraw = false;
            }
        }

        return canWithdraw;
    }

    function _depositERC721(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 tokenId,
        address tokenAddress
    ) internal returns (uint256) {

        DepositedERC721 memory item = DepositedERC721({
            tokenId: tokenId,
            tokenAddress: tokenAddress,
            depositor: msg.sender,
            hasSecondarySaleFees: royaltiesRegistry.getRoyalties(tokenAddress, tokenId).length > 0,
            feesPaid: false
        });

        IERC721Upgradeable(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 nftSlotIndex = auctions[auctionId].slots[slotIndex].totalDepositedNfts.add(1);

        auctions[auctionId].slots[slotIndex].depositedNfts[nftSlotIndex] = item;
        auctions[auctionId].slots[slotIndex].totalDepositedNfts = nftSlotIndex;
        auctions[auctionId].totalDepositedERC721s = auctions[auctionId].totalDepositedERC721s.add(
            1
        );

        emit LogERC721Deposit(
            msg.sender,
            tokenAddress,
            tokenId,
            auctionId,
            slotIndex,
            nftSlotIndex
        );

        return nftSlotIndex;
    }

    function _withdrawERC721FromNonWinningSlot(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) internal {
        Auction storage auction = auctions[auctionId];
        DepositedERC721 memory nftForWithdrawal = auction.slots[slotIndex].depositedNfts[
            nftSlotIndex
        ];

        require(msg.sender == nftForWithdrawal.depositor, "Only depositor can withdraw");

        auction.totalWithdrawnERC721s = auction.totalWithdrawnERC721s.add(1);
        auction.slots[slotIndex].totalWithdrawnNfts = auction
        .slots[slotIndex]
        .totalWithdrawnNfts
        .add(1);

        emit LogERC721Withdrawal(
            msg.sender,
            nftForWithdrawal.tokenAddress,
            nftForWithdrawal.tokenId,
            auctionId,
            slotIndex,
            nftSlotIndex
        );

        IERC721Upgradeable(nftForWithdrawal.tokenAddress).safeTransferFrom(
            address(this),
            nftForWithdrawal.depositor,
            nftForWithdrawal.tokenId
        );

    }

    function _withdrawDepositedERC721(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) internal {
        Auction storage auction = auctions[auctionId];
        DepositedERC721 memory nftForWithdrawal = auction.slots[slotIndex].depositedNfts[
            nftSlotIndex
        ];

        require(msg.sender == nftForWithdrawal.depositor, "Only depositor can withdraw");

        delete auction.slots[slotIndex].depositedNfts[nftSlotIndex];

        auction.totalWithdrawnERC721s = auction.totalWithdrawnERC721s.add(1);
        auction.totalDepositedERC721s = auction.totalDepositedERC721s.sub(1);
        auction.slots[slotIndex].totalWithdrawnNfts = auction
        .slots[slotIndex]
        .totalWithdrawnNfts
        .add(1);

        emit LogERC721Withdrawal(
            msg.sender,
            nftForWithdrawal.tokenAddress,
            nftForWithdrawal.tokenId,
            auctionId,
            slotIndex,
            nftSlotIndex
        );

        IERC721Upgradeable(nftForWithdrawal.tokenAddress).safeTransferFrom(
            address(this),
            nftForWithdrawal.depositor,
            nftForWithdrawal.tokenId
        );

    }

    function extendAuction(uint256 auctionId) internal {
        Auction storage auction = auctions[auctionId];

        uint256 resetTimer = auction.resetTimer;
        auction.endTime = auction.endTime.add(resetTimer);

        emit LogAuctionExtended(auctionId, auction.endTime);

    }

    function addBid(
        uint256 auctionId,
        address bidder,
        uint256 bid
    ) internal {
        require(
            auctions[auctionId].nextBidders[bidder] == address(0),
            "Next bidder should be address 0"
        );
        address index = _findIndex(auctionId, bid);
        auctions[auctionId].bidBalance[bidder] = bid;
        auctions[auctionId].nextBidders[bidder] = auctions[auctionId].nextBidders[index];
        auctions[auctionId].nextBidders[index] = bidder;
        auctions[auctionId].numberOfBids += 1;

        emit LogBidSubmitted(
            bidder,
            auctionId,
            bid,
            auctions[auctionId].bidBalance[bidder]
        );
    }

    function removeBid(uint256 auctionId, address bidder) internal {
        require(auctions[auctionId].nextBidders[bidder] != address(0), "Address 0 provided");
        address previousBidder = _findPreviousBidder(auctionId, bidder);
        auctions[auctionId].nextBidders[previousBidder] = auctions[auctionId].nextBidders[bidder];
        auctions[auctionId].nextBidders[bidder] = address(0);
        auctions[auctionId].bidBalance[bidder] = 0;
        auctions[auctionId].numberOfBids -= 1;
    }

    function updateBid(
        uint256 auctionId,
        address bidder,
        uint256 newValue
    ) internal {
        require(auctions[auctionId].nextBidders[bidder] != address(0), "Address 0 provided");
        removeBid(auctionId, bidder);
        addBid(auctionId, bidder, newValue);
    }

    function calculateSecondarySaleFees(uint256 auctionId, uint256 slotIndex)
        internal
        returns (uint256)
    {
        Slot storage slot = auctions[auctionId].slots[slotIndex];

        uint256 averageERC721SalePrice = slot.winningBidAmount.div(slot.totalDepositedNfts);
        uint256 totalFeesPayableForSlot = 0;

        for (uint256 i = 0; i < slot.totalDepositedNfts; i += 1) {
            DepositedERC721 memory nft = slot.depositedNfts[i + 1];

            if (nft.hasSecondarySaleFees) {
                LibPart.Part[] memory fees = royaltiesRegistry.getRoyalties(nft.tokenAddress, nft.tokenId);
                uint256 value = averageERC721SalePrice;

                for (uint256 j = 0; j < fees.length && j < 5; j += 1) {
                    Fee memory interimFee = subFee(
                        value,
                        averageERC721SalePrice.mul(fees[j].value).div(10000)
                    );
                    value = interimFee.remainingValue;
                    totalFeesPayableForSlot = totalFeesPayableForSlot.add(interimFee.feeValue);
                }
            }
        }

        return totalFeesPayableForSlot;
    }

    function _verifyIndex(
        uint256 auctionId,
        address previousBidder,
        uint256 newValue,
        address nextBidder
    ) internal view returns (bool) {
        return
            (previousBidder == GUARD ||
                auctions[auctionId].bidBalance[previousBidder] >= newValue) &&
            (nextBidder == GUARD || newValue > auctions[auctionId].bidBalance[nextBidder]);
    }

    function _findIndex(uint256 auctionId, uint256 newValue) internal view returns (address) {
        address addressToInsertAfter = GUARD;
        while (true) {
            if (
                _verifyIndex(
                    auctionId,
                    addressToInsertAfter,
                    newValue,
                    auctions[auctionId].nextBidders[addressToInsertAfter]
                )
            ) return addressToInsertAfter;
            addressToInsertAfter = auctions[auctionId].nextBidders[addressToInsertAfter];
        }
    }

    function _isPreviousBidder(
        uint256 auctionId,
        address bidder,
        address previousBidder
    ) internal view returns (bool) {
        return auctions[auctionId].nextBidders[previousBidder] == bidder;
    }

    function _findPreviousBidder(uint256 auctionId, address bidder)
        internal
        view
        returns (address)
    {
        address currentAddress = GUARD;
        while (auctions[auctionId].nextBidders[currentAddress] != GUARD) {
            if (_isPreviousBidder(auctionId, bidder, currentAddress)) return currentAddress;
            currentAddress = auctions[auctionId].nextBidders[currentAddress];
        }
        return address(0);
    }

    function subFee(uint256 value, uint256 fee) internal pure returns (Fee memory interimFee) {
        if (value > fee) {
            interimFee.remainingValue = value - fee;
            interimFee.feeValue = fee;
        } else {
            interimFee.remainingValue = 0;
            interimFee.feeValue = value;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
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

pragma solidity >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

import "../lib/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@universe/marketplace/contracts/interfaces/IRoyaltiesProvider.sol";

/// @title Users bid to this contract in order to win a slot with deposited ERC721 tokens.
/// @notice This interface should be implemented by the Auction contract
/// @dev This interface should be implemented by the Auction contract
interface IUniverseAuctionHouse {
    struct Auction {
        address auctionOwner;
        uint256 startTime;
        uint256 endTime;
        uint256 resetTimer;
        uint256 numberOfSlots;
        uint256 numberOfBids;
        bool isCanceled;
        address bidToken;
        bool isFinalized;
        uint256 totalDepositedERC721s;
        uint256 totalWithdrawnERC721s;
        mapping(uint256 => Slot) slots;
        mapping(address => uint256) bidBalance;
        mapping(address => address) nextBidders;
        mapping(uint256 => address) winners;
        PaymentSplit[] paymentSplits;
    }

    struct Slot {
        uint256 totalDepositedNfts;
        uint256 totalWithdrawnNfts;
        uint256 reservePrice;
        uint256 winningBidAmount;
        bool reservePriceReached;
        bool revenueCaptured;
        address winner;
        mapping(uint256 => DepositedERC721) depositedNfts;
    }

    struct SlotInfo {
        uint256 totalDepositedNfts;
        uint256 totalWithdrawnNfts;
        uint256 reservePrice;
        uint256 winningBidAmount;
        bool reservePriceReached;
        bool revenueCaptured;
        address winner;
    }

    struct ERC721 {
        uint256 tokenId;
        address tokenAddress;
    }

    struct DepositedERC721 {
        address tokenAddress;
        uint256 tokenId;
        address depositor;
        bool hasSecondarySaleFees;
        bool feesPaid;
    }

    struct Fee {
        uint256 remainingValue;
        uint256 feeValue;
    }

    struct AuctionConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 resetTimer;
        uint256 numberOfSlots;
        address bidToken;
        uint256[] minimumReserveValues;
        PaymentSplit[] paymentSplits;
    }

    struct PaymentSplit {
        address payable recipient;
        uint256 value;
    }

    /// @notice Create an auction with initial parameters
    /// @param config Auction configuration
    /// @dev config.startTime The start of the auction
    /// @dev config.endTime End of the auction
    /// @dev config.resetTimer Reset timer in seconds
    /// @dev config.numberOfSlots The number of slots which the auction will have
    /// @dev config.bidToken Address of the token used for bidding - can be address(0)
    /// @dev config.minimumReserveValues Minimum reserve values for each slot, starting from 1st. Leave empty if no minimum reserve
    /// @dev config.paymentSplits Array of payment splits which will be distributed after auction ends
    function createAuction(AuctionConfig calldata config) external returns (uint256);

    /// @notice Deposit ERC721 assets to the specified Auction
    /// @param auctionId The auction id
    /// @param slotIndices Array of slot indexes
    /// @param tokens Array of ERC721 arrays
    function batchDepositToAuction(
        uint256 auctionId,
        uint256[] calldata slotIndices,
        ERC721[][] calldata tokens
    ) external;

    /// @notice Sends a bid (ETH) to the specified auciton
    /// @param auctionId The auction id
    function ethBid(uint256 auctionId) external payable;

    /// @notice Withdraws the eth bid amount after auction is finalized and bid is non winning
    /// @param auctionId The auction id
    function withdrawEthBid(uint256 auctionId) external;

    /// @notice Sends a bid (ERC20) to the specified auciton
    /// @param auctionId The auction id
    function erc20Bid(uint256 auctionId, uint256 amount) external;

    /// @notice Withdraws the bid amount after auction is finialized and bid is non winning
    /// @param auctionId The auction id
    function withdrawERC20Bid(uint256 auctionId) external;

    /// @notice Withdraws the deposited ERC721s if the reserve price is not reached
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    /// @param amount The amount which should be withdrawn
    function withdrawERC721FromNonWinningSlot(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount
    ) external;

    /// @notice Calculates and sets the auction winners for all slots
    /// @param auctionId The auction id
    function finalizeAuction(uint256 auctionId) external;

    /// @notice Captures the slot revenue and deductible fees/royalties once the auction is finalized
    /// @param auctionId The auction id
    /// @param slotIndex The slotIndex
    function captureSlotRevenue(uint256 auctionId, uint256 slotIndex) external;

    /// @notice Captures a range of the slots revenue and deductible fees/royalties once the auction is finalized. Should be used for slots with lower amount of NFTs.
    /// @param auctionId The auction id
    /// @param startSlotIndex The start slotIndex
    /// @param endSlotIndex The end slotIndex
    function captureSlotRevenueRange(uint256 auctionId, uint256 startSlotIndex, uint256 endSlotIndex) external;

    /// @notice Cancels an auction which has not started yet
    /// @param auctionId The auction id
    function cancelAuction(uint256 auctionId) external;

    /// @notice Withdraws the captured revenue from the auction to the auction owner. Can be called multiple times after captureSlotRevenue has been called.
    /// @param auctionId The auction id
    function distributeCapturedAuctionRevenue(uint256 auctionId) external;

    /// @notice Claims and distributes the NFTs from a winning slot
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    /// @param amount The amount which should be withdrawn
    function claimERC721Rewards(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount
    ) external;

    /// @notice Gets the minimum reserve price for auciton slot
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    /// @param nftSlotIndex The nft slot index
    function distributeSecondarySaleFees(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) external;

    /// @notice Withdraws the aggregated royalites amount of specific token to a specified address
    /// @param token The address of the token to withdraw
    function distributeRoyalties(address token) external returns(uint256);

    /// @notice Sets the percentage of the royalty which wil be kept from each sale
    /// @param royaltyFeeBps The royalty percentage in Basis points (1000 - 10%)
    function setRoyaltyFeeBps(uint256 royaltyFeeBps) external returns(uint256);

    /// @notice Sets the NFT slot limit for auction
    /// @param nftSlotLimit The royalty percentage
    function setNftSlotLimit(uint256 nftSlotLimit) external returns(uint256);

    /// @notice Sets the RoyaltiesRegistry
    /// @param royaltiesRegistry The royalties registry address
    function setRoyaltiesRegistry(IRoyaltiesProvider royaltiesRegistry) external returns (IRoyaltiesProvider);

    /// @notice Modifies whether a token is supported for bidding
    /// @param erc20token The erc20 token
    /// @param value True or false
    function setSupportedBidToken(address erc20token, bool value) external returns (address, bool);

    /// @notice Gets deposited erc721s for slot
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    function getDepositedNftsInSlot(uint256 auctionId, uint256 slotIndex)
        external
        view
        returns (DepositedERC721[] memory);

    /// @notice Gets slot winner for particular auction
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    function getSlotWinner(uint256 auctionId, uint256 slotIndex) external view returns (address);

    /// @notice Gets slot info for particular auction
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    function getSlotInfo(uint256 auctionId, uint256 slotIndex) external view returns (SlotInfo memory);

    /// @notice Gets the bidder total bids in auction
    /// @param auctionId The auction id
    /// @param bidder The address of the bidder
    function getBidderBalance(uint256 auctionId, address bidder) external view returns (uint256);

    /// @notice Gets the minimum reserve price for auciton slot
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    function getMinimumReservePriceForSlot(uint256 auctionId, uint256 slotIndex)
        external
        view
        returns (uint256);

    /// @notice Deposit ERC721 assets to the specified Auction
    /// @param auctionId The auction id
    /// @param slotIndex Index of the slot
    /// @param tokens Array of ERC721 objects
    function depositERC721(
        uint256 auctionId,
        uint256 slotIndex,
        ERC721[] calldata tokens
    ) external returns (uint256[] memory);

    /// @notice Withdraws the deposited ERC721 before an auction has started
    /// @param auctionId The auction id
    /// @param slotIndex The slot index
    /// @param amount The amount which should be withdrawn
    function withdrawDepositedERC721(
        uint256 auctionId,
        uint256 slotIndex,
        uint256 amount
    ) external;

    /// @notice Gets the top N bidders in auction
    /// @param auctionId The auction id
    /// @param n The top n bidders
    function getTopBidders(uint256 auctionId, uint256 n) external view returns (address[] memory);

    /// @notice Checks if bid amount is currently a winning bid in specific auciton
    /// @param auctionId The auction id
    /// @param bid The bid amount
    function isWinningBid(uint256 auctionId, uint256 bid) external view returns (bool);

    /// @notice Checks if a submitted bid can be withdrawn
    /// @param auctionId The auction id
    /// @param bidder The address of the bidder
    function canWithdrawBid(uint256 auctionId, address bidder) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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