/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts\IStakerHEXMarket.sol

pragma solidity ^0.8.0;

interface IStakerHEXMarket {
    function addListing(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external;

    function addEarning(uint40 stakeId, uint256 heartsEarned) external;
}

// File: contracts\StakerHEXMarket.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract StakerHEXMarket is IStakerHEXMarket {
    IERC20 hexContract;
    address minter;

    constructor(address _hex, address _minter) {
        hexContract = IERC20(_hex);
        minter = _minter;
    }

    struct ShareOwner {
        bool earningClaimed;
        uint256 sharesOwned;
    }

    struct ShareListing {
        // set once
        address supplier;
        uint72 heartsStaked;
        uint72 sharesTotal;
        // available for sale
        uint72 sharesAvailable;
        mapping(address => ShareOwner) shareOwners;
        // earnings to be paid
        uint256 heartsEarned; // size
    }

    mapping(uint40 => ShareListing) public shareListings;

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    event AddListing(uint40 stakeId, uint72 shares);

    function addListing(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external override onlyMinter {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal == 0, "listing for stakeId must not exist");

        listing.supplier = supplier;
        listing.heartsStaked = stakedHearts;
        listing.sharesTotal = stakeShares;
        listing.sharesAvailable = stakeShares;

        emit AddListing(stakeId, stakeShares);
    }

    event AddEarning(uint40 stakeId, uint256 heartsEarned);

    function addEarning(uint40 stakeId, uint256 heartsEarned)
        external
        override
        onlyMinter
    {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal > 0, "listing for stakeId must exist");

        listing.heartsEarned = heartsEarned;

        emit AddEarning(stakeId, heartsEarned);
    }

    event BuyShares(uint40 stakeId, uint256 heartsPaid, uint72 sharesPurchased);

    function buyShares(uint40 stakeId, uint72 sharesPurchased) external {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal > 0, "stakeId not found");
        require(listing.sharesAvailable > 0, "no shares available");
        require(
            sharesPurchased <= listing.sharesAvailable,
            "not enough shares available"
        );

        uint256 heartsOwed =
            (sharesPurchased * listing.heartsStaked) / listing.sharesTotal;
        require(heartsOwed > 0, "must cost more than 1 heart");
        require(
            hexContract.balanceOf(msg.sender) >= heartsOwed,
            "not enough hearts to afford shares"
        );

        hexContract.transferFrom(msg.sender, listing.supplier, heartsOwed);
        listing.shareOwners[msg.sender].sharesOwned += sharesPurchased;

        emit BuyShares(stakeId, heartsOwed, sharesPurchased);
    }

    event ClaimEarning(uint40 stakeId, uint256 heartsClaimed);

    function claimEarning(uint40 stakeId) external {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal > 0, "stakeId not found");

        ShareOwner storage owner = listing.shareOwners[msg.sender];
        require(
            owner.earningClaimed == false,
            "earning has already been claimed"
        );
        require(owner.sharesOwned > 0, "no shares owned for stake");

        owner.earningClaimed = true;
        uint256 heartsOwed =
            (listing.heartsEarned * owner.sharesOwned) / listing.sharesTotal;
        require(heartsOwed > 0, "no hearts owed");

        //transfer from minter to sender
        hexContract.transferFrom(minter, msg.sender, heartsOwed);

        emit ClaimEarning(stakeId, heartsOwed);
    }
}