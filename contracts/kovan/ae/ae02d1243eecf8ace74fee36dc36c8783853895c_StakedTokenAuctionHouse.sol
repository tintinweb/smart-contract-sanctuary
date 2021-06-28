/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

/// StakedTokenAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function transferInternalCoins(address,address,uint256) virtual external;
    function createUnbackedDebt(address,address,uint256) virtual external;
}
abstract contract TokenLike {
    function transferFrom(address,address,uint256) virtual external returns (bool);
}
abstract contract AccountingEngineLike {
    function totalOnAuctionDebt() virtual public returns (uint256);
    function cancelAuctionedDebtWithSurplus(uint256) virtual external;
}

/*
* This thing lets you auction a token in exchange for system coins that are then used to settle bad debt
*/
contract StakedTokenAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "StakedTokenAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size
        uint256 bidAmount;                                                        // [rad]
        // How many staked tokens are sold in an auction
        uint256 amountToSell;                                                     // [wad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                        // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                  // [unix epoch time]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike public safeEngine;
    // Staked token address
    TokenLike public stakedToken;
    // Accounting engine
    address public accountingEngine;
    // Token burner contract
    address public tokenBurner;

    uint256  constant ONE = 1.00E18;                                              // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidIncrease = 1.05E18;                                      // [wad]
    // Decrease in the min bid in case no one bid before
    uint256  public   minBidDecrease = 0.95E18;                                   // [wad]
    // The lowest possible value for the minimum bid
    uint256  public   minBid = 1;                                                 // [rad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                      // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // Accumulator for all debt auctions currently not settled
    uint256  public   activeStakedTokenAuctions;
    // Flag that indicates whether the contract is still enabled or not
    uint256  public   contractEnabled;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("STAKED_TOKEN");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event StartAuction(
      uint256 indexed id,
      uint256 auctionsStarted,
      uint256 amountToSell,
      uint256 amountToBid,
      address indexed incomeReceiver,
      uint256 indexed auctionDeadline,
      uint256 activeStakedTokenAuctions
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event RestartAuction(uint256 indexed id, uint256 minBid, uint256 auctionDeadline);
    event IncreaseBidSize(uint256 id, address highBidder, uint256 amountToBuy, uint256 bid, uint256 bidExpiry);
    event SettleAuction(uint256 indexed id, uint256 bid);
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, address highBidder, uint256 bidAmount, uint256 activeStakedTokenAuctions);
    event DisableContract(address sender);

    // --- Init ---
    constructor(address safeEngine_, address stakedToken_) public {
        require(safeEngine_ != address(0x0), "StakedTokenAuctionHouse/invalid_safe_engine");
        require(stakedToken_ != address(0x0), "StakedTokenAuctionHouse/invalid_token");
        authorizedAccounts[msg.sender] = 1;
        safeEngine      = SAFEEngineLike(safeEngine_);
        stakedToken     = TokenLike(stakedToken_);
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "StakedTokenAuctionHouse/add-uint48-overflow");
    }
    function addUint256(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "StakedTokenAuctionHouse/add-uint256-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "StakedTokenAuctionHouse/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "StakedTokenAuctionHouse/mul-overflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }
    
    
    
    
    // 0x746f6b656e4275726e6572000000000000000000000000000000000000000000
    // 0x6c00000000000000000000000000000000000000000000000000000000000000
    
    
    

    // --- Admin ---
    /**
     * @notice Modify auction parameters
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(data > 0, "StakedTokenAuctionHouse/null-data");

        if (parameter == "bidIncrease") {
          require(data > ONE, "StakedTokenAuctionHouse/invalid-bid-increase");
          bidIncrease = data;
        }
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else if (parameter == "minBidDecrease") {
          require(data < ONE, "StakedTokenAuctionHouse/invalid-min-bid-decrease");
          minBidDecrease = data;
        }
        else if (parameter == "minBid") {
          minBid = data;
        }
        else revert("StakedTokenAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an address parameter
     * @param parameter The name of the oracle contract modified
     * @param addr New contract address
     */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(contractEnabled == 1, "StakedTokenAuctionHouse/contract-not-enabled");
        if (parameter == "accountingEngine") accountingEngine = addr;
        else if (parameter == "tokenBurner") tokenBurner = addr;
        else revert("StakedTokenAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Auction ---
    /**
     * @notice Start a new staked token auction
     * @param amountToSell Amount of staked tokens to sell (wad)
     */
    function startAuction(
        uint256 amountToSell,
        uint256 systemCoinsRequested
    ) external isAuthorized returns (uint256 id) {
        require(contractEnabled == 1, "StakedTokenAuctionHouse/contract-not-enabled");
        require(auctionsStarted < uint256(-1), "StakedTokenAuctionHouse/overflow");
        require(accountingEngine != address(0), "StakedTokenAuctionHouse/null-accounting-engine");
        require(both(amountToSell > 0, systemCoinsRequested > 0), "StakedTokenAuctionHouse/null-amounts");
        require(systemCoinsRequested <= uint256(-1) / ONE, "StakedTokenAuctionHouse/large-sys-coin-request");

        id = ++auctionsStarted;

        bids[id].amountToSell     = amountToSell;
        bids[id].bidAmount        = systemCoinsRequested;
        bids[id].highBidder       = address(0);
        bids[id].auctionDeadline  = addUint48(uint48(now), totalAuctionLength);

        activeStakedTokenAuctions = addUint256(activeStakedTokenAuctions, 1);

        // get staked tokens
        require(stakedToken.transferFrom(msg.sender, address(this), amountToSell), "StakedTokenAuctionHouse/cannot-transfer-staked-tokens");

        emit StartAuction(
          id, auctionsStarted, amountToSell, systemCoinsRequested, accountingEngine, bids[id].auctionDeadline, activeStakedTokenAuctions
        );
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(id <= auctionsStarted, "StakedTokenAuctionHouse/auction-never-started");
        require(bids[id].auctionDeadline < now, "StakedTokenAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "StakedTokenAuctionHouse/bid-already-placed");

        uint256 newMinBid        = multiply(minBidDecrease, bids[id].bidAmount) / ONE;
        newMinBid                = (newMinBid < minBid) ? minBid : newMinBid;

        bids[id].bidAmount       = newMinBid;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);

        emit RestartAuction(id, newMinBid, bids[id].auctionDeadline);
    }
    /**
     * @notice Submit a higher system coin bid for the same amount of staked tokens
     * @param id ID of the auction you want to submit the bid for
     * @param amountToBuy Amount of staked tokens to buy (wad)
     * @param bid New bid submitted (rad)
     */
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external {
        require(contractEnabled == 1, "StakedTokenAuctionHouse/contract-not-enabled");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "StakedTokenAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "StakedTokenAuctionHouse/auction-already-expired");

        require(amountToBuy == bids[id].amountToSell, "StakedTokenAuctionHouse/not-matching-amount-bought");
        require(bid > bids[id].bidAmount, "StakedTokenAuctionHouse/bid-not-higher");
        require(multiply(bid, ONE) > multiply(bidIncrease, bids[id].bidAmount), "StakedTokenAuctionHouse/insufficient-increase");

        if (bids[id].highBidder == msg.sender) {
            safeEngine.transferInternalCoins(msg.sender, address(this), subtract(bid, bids[id].bidAmount));
        } else {
            safeEngine.transferInternalCoins(msg.sender, address(this), bid);
            if (bids[id].highBidder != address(0)) // not first bid
                safeEngine.transferInternalCoins(address(this), bids[id].highBidder, bids[id].bidAmount);

            bids[id].highBidder = msg.sender;
        }

        bids[id].bidAmount  = bid;
        bids[id].bidExpiry  = addUint48(uint48(now), bidDuration);

        emit IncreaseBidSize(id, msg.sender, amountToBuy, bid, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(contractEnabled == 1, "StakedTokenAuctionHouse/not-live");
        require(both(bids[id].bidExpiry != 0, either(bids[id].bidExpiry < now, bids[id].auctionDeadline < now)), "StakedTokenAuctionHouse/not-finished");

        // get the bid, the amount to sell and the high bidder
        uint256 bid          = bids[id].bidAmount;
        uint256 amountToSell = bids[id].amountToSell;
        address highBidder   = bids[id].highBidder;

        // clear storage
        activeStakedTokenAuctions = subtract(activeStakedTokenAuctions, 1);
        delete bids[id];

        // transfer the surplus to the accounting engine
        safeEngine.transferInternalCoins(address(this), accountingEngine, bid);

        // clear as much bad debt as possible
        uint256 totalOnAuctionDebt = AccountingEngineLike(accountingEngine).totalOnAuctionDebt();
        AccountingEngineLike(accountingEngine).cancelAuctionedDebtWithSurplus(minimum(bid, totalOnAuctionDebt));

        // transfer staked tokens to the high bidder
        stakedToken.transferFrom(address(this), highBidder, amountToSell);

        emit SettleAuction(id, activeStakedTokenAuctions);
    }

    // --- Shutdown ---
    /**
    * @notice Disable the auction house
    */
    function disableContract() external isAuthorized {
        contractEnabled  = 0;
        emit DisableContract(msg.sender);
    }
    /**
     * @notice Terminate an auction prematurely
     * @param id ID of the auction to terminate
     */
    function terminateAuctionPrematurely(uint256 id) external {
        require(contractEnabled == 0, "StakedTokenAuctionHouse/contract-still-enabled");
        require(bids[id].highBidder != address(0), "StakedTokenAuctionHouse/high-bidder-not-set");

        // decrease amount of active auctions
        activeStakedTokenAuctions = subtract(activeStakedTokenAuctions, 1);

        // send the system coin bid back to the high bidder in case there was at least one bid
        safeEngine.transferInternalCoins(address(this), bids[id].highBidder, bids[id].bidAmount);

        // send the staked tokens to the token burner
        stakedToken.transferFrom(address(this), tokenBurner, bids[id].amountToSell);

        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].highBidder, bids[id].bidAmount, activeStakedTokenAuctions);
        delete bids[id];
    }
}