/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

/// SurplusAuctionHouse.sol

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
    function coinBalance(address) virtual external view returns (uint256);
    function approveSAFEModification(address) virtual external;
    function denySAFEModification(address) virtual external;
}
abstract contract TokenLike {
    function approve(address, uint256) virtual public returns (bool);
    function balanceOf(address) virtual public view returns (uint256);
    function move(address,address,uint256) virtual external;
    function burn(address,uint256) virtual external;
}

/*
   This thing lets you auction some coins in return for protocol tokens that are then burnt
*/

contract BurningSurplusAuctionHouse {
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
        require(authorizedAccounts[msg.sender] == 1, "BurningSurplusAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size (how many protocol tokens are offered per system coins sold)
        uint256 bidAmount;                                                            // [wad]
        // How many system coins are sold in an auction
        uint256 amountToSell;                                                         // [rad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                            // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                      // [unix epoch time]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike public safeEngine;
    // Protocol token address
    TokenLike      public protocolToken;

    uint256  constant ONE = 1.00E18;                                                  // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidIncrease = 1.05E18;                                          // [wad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                          // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                    // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // Whether the contract is settled or not
    uint256  public   contractEnabled;

    bytes32 public constant AUCTION_HOUSE_TYPE   = bytes32("SURPLUS");
    bytes32 public constant SURPLUS_AUCTION_TYPE = bytes32("BURNING");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event RestartAuction(uint256 id, uint256 auctionDeadline);
    event IncreaseBidSize(uint256 id, address highBidder, uint256 amountToBuy, uint256 bid, uint256 bidExpiry);
    event StartAuction(
        uint256 indexed id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 auctionDeadline
    );
    event SettleAuction(uint256 indexed id);
    event DisableContract();
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, address highBidder, uint256 bidAmount);

    // --- Init ---
    constructor(address safeEngine_, address protocolToken_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike(safeEngine_);
        protocolToken = TokenLike(protocolToken_);
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "BurningSurplusAuctionHouse/add-uint48-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "BurningSurplusAuctionHouse/mul-overflow");
    }

    // --- Admin ---
    /**
     * @notice Modify auction parameters
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "bidIncrease") bidIncrease = data;
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else revert("BurningSurplusAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Auction ---
    /**
     * @notice Start a new surplus auction
     * @param amountToSell Total amount of system coins to sell (rad)
     * @param initialBid Initial protocol token bid (wad)
     */
    function startAuction(uint256 amountToSell, uint256 initialBid) external isAuthorized returns (uint256 id) {
        require(contractEnabled == 1, "BurningSurplusAuctionHouse/contract-not-enabled");
        require(auctionsStarted < uint256(-1), "BurningSurplusAuctionHouse/overflow");
        id = ++auctionsStarted;

        bids[id].bidAmount = initialBid;
        bids[id].amountToSell = amountToSell;
        bids[id].highBidder = msg.sender;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);

        safeEngine.transferInternalCoins(msg.sender, address(this), amountToSell);

        emit StartAuction(id, auctionsStarted, amountToSell, initialBid, bids[id].auctionDeadline);
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(bids[id].auctionDeadline < now, "BurningSurplusAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "BurningSurplusAuctionHouse/bid-already-placed");
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        emit RestartAuction(id, bids[id].auctionDeadline);
    }
    /**
     * @notice Submit a higher protocol token bid for the same amount of system coins
     * @param id ID of the auction you want to submit the bid for
     * @param amountToBuy Amount of system coins to buy (rad)
     * @param bid New bid submitted (wad)
     */
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external {
        require(contractEnabled == 1, "BurningSurplusAuctionHouse/contract-not-enabled");
        require(bids[id].highBidder != address(0), "BurningSurplusAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "BurningSurplusAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "BurningSurplusAuctionHouse/auction-already-expired");

        require(amountToBuy == bids[id].amountToSell, "BurningSurplusAuctionHouse/amounts-not-matching");
        require(bid > bids[id].bidAmount, "BurningSurplusAuctionHouse/bid-not-higher");
        require(multiply(bid, ONE) >= multiply(bidIncrease, bids[id].bidAmount), "BurningSurplusAuctionHouse/insufficient-increase");

        if (msg.sender != bids[id].highBidder) {
            protocolToken.move(msg.sender, bids[id].highBidder, bids[id].bidAmount);
            bids[id].highBidder = msg.sender;
        }
        protocolToken.move(msg.sender, address(this), bid - bids[id].bidAmount);

        bids[id].bidAmount = bid;
        bids[id].bidExpiry = addUint48(uint48(now), bidDuration);

        emit IncreaseBidSize(id, msg.sender, amountToBuy, bid, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(contractEnabled == 1, "BurningSurplusAuctionHouse/contract-not-enabled");
        require(bids[id].bidExpiry != 0 && (bids[id].bidExpiry < now || bids[id].auctionDeadline < now), "BurningSurplusAuctionHouse/not-finished");
        safeEngine.transferInternalCoins(address(this), bids[id].highBidder, bids[id].amountToSell);
        protocolToken.burn(address(this), bids[id].bidAmount);
        delete bids[id];
        emit SettleAuction(id);
    }
    /**
    * @notice Disable the auction house (usually called by AccountingEngine)
    **/
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        safeEngine.transferInternalCoins(address(this), msg.sender, safeEngine.coinBalance(address(this)));
        emit DisableContract();
    }
    /**
     * @notice Terminate an auction prematurely.
     * @param id ID of the auction to settle/terminate
     */
    function terminateAuctionPrematurely(uint256 id) external {
        require(contractEnabled == 0, "BurningSurplusAuctionHouse/contract-still-enabled");
        require(bids[id].highBidder != address(0), "BurningSurplusAuctionHouse/high-bidder-not-set");
        protocolToken.move(address(this), bids[id].highBidder, bids[id].bidAmount);
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].highBidder, bids[id].bidAmount);
        delete bids[id];
    }
}