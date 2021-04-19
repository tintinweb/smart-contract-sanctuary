/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
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
}

// File: contracts\IHEX.sol


pragma solidity ^0.8.0;

interface IHEX {
    function allocatedSupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function dailyData(uint256)
        external
        view
        returns (
            uint72 dayPayoutTotal,
            uint72 dayStakeSharesTotal,
            uint56 dayUnclaimedSatoshisTotal
        );

    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);

    function dailyDataUpdate(uint256 beforeDay) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function globalInfo() external view returns (uint256[13] memory);

    function globals()
        external
        view
        returns (
            uint72 lockedHeartsTotal,
            uint72 nextStakeSharesTotal,
            uint40 shareRate,
            uint72 stakePenaltyTotal,
            uint16 dailyDataCount,
            uint72 stakeSharesTotal,
            uint40 latestStakeId,
            uint128 claimStats
        );

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function stakeCount(address stakerAddr) external view returns (uint256);

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external;

    function stakeLists(address, uint256)
        external
        view
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay,
            bool isAutoStake
        );

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)
        external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts\StakerHEXPool.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;



contract StakerHEXPool is Ownable {
    IHEX hexContract;

    constructor(address payable _hex) {
        hexContract = IHEX(_hex);
    }

    struct ShareOwner {
        bool payoutClaimed;
        uint256 sharesOwned;
    }

    struct ShareListing {
        address creatorAddress;
        uint256 heartsStaked;
        uint256 sharesTotal;
        uint256 unlockDay;
        uint256 sharesAvailable;
        uint256 heartsPayoutTotal;
        mapping(address => ShareOwner) shareOwners;
    }

    mapping(uint40 => ShareListing) public shareListings;

    event MintShares(uint256 stakeId, uint256 shares, uint256 unlockDay);

    function mintShares(uint256 newStakedHearts, uint256 newStakedDays)
        external
        onlyOwner
    {
        // transfer hex to pool contract
        hexContract.transferFrom(msg.sender, address(this), newStakedHearts);

        // open stake
        uint256 prevShares = hexContract.globalInfo()[1];
        hexContract.stakeStart(newStakedHearts, newStakedDays);

        // load stake info
        uint256[13] memory globalInfo = hexContract.globalInfo();
        uint256 newShares = globalInfo[1];
        uint40 stakeId = uint40(globalInfo[6]);
        uint256 shares = newShares - prevShares;
        uint256 currentDay = hexContract.currentDay();
        uint256 unlockDay = currentDay + 1 + newStakedDays;

        // create new share listing
        ShareListing storage listing = shareListings[stakeId];
        listing.creatorAddress = msg.sender;
        listing.heartsStaked = newStakedHearts;
        listing.sharesTotal = shares;
        listing.unlockDay = unlockDay;
        listing.sharesAvailable = shares;
        listing.heartsPayoutTotal = 0;

        emit MintShares(stakeId, shares, unlockDay);
    }

    function mintPayouts(
        uint256[] calldata stakeIndexes,
        uint40[] calldata stakeIds
    ) external {
        require(
            stakeIndexes.length == stakeIds.length,
            "input array lengths must match"
        );

        uint256 payoutCount = stakeIds.length;
        for (uint256 i = 0; i < payoutCount; i++) {
            mintPayout(stakeIndexes[i], stakeIds[i]);
        }
    }

    event MintPayout(uint256 stakeId, uint256 hearts);

    function mintPayout(uint256 stakeIndex, uint40 stakeId) public {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal > 0, "stakeId not found");

        uint256 currentDay = hexContract.currentDay();
        require(currentDay >= listing.unlockDay, "stake not matured");

        // end stake
        uint256 prevHearts = hexContract.balanceOf(address(this));
        hexContract.stakeEnd(stakeIndex, stakeId);
        uint256 newHearts = hexContract.balanceOf(address(this));

        // update payout on listing
        listing.heartsPayoutTotal = newHearts - prevHearts;

        emit MintPayout(stakeId, listing.heartsPayoutTotal);
    }

    event BuyShares(
        uint256 stakeId,
        uint256 heartsPaid,
        uint256 sharesPurchased
    );

    function buyShares(uint40 stakeId, uint256 sharesPurchased) external {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal > 0, "stakeId not found");
        require(listing.sharesAvailable > 0, "no shares available");
        require(
            sharesPurchased <= listing.sharesAvailable,
            "not enough shares available"
        );

        uint256 heartsForShares =
            (sharesPurchased * listing.heartsStaked) / listing.sharesTotal;
        require(heartsForShares > 0, "must cost more than 1 heart");
        require(
            hexContract.balanceOf(msg.sender) >= heartsForShares,
            "not enough hearts to afford shares"
        );

        hexContract.transferFrom(
            msg.sender,
            listing.creatorAddress,
            heartsForShares
        );
        listing.shareOwners[msg.sender].sharesOwned += sharesPurchased;

        emit BuyShares(stakeId, heartsForShares, sharesPurchased);
    }

    event ClaimPayout(uint256 stakeId, uint256 heartsClaimed);

    function claimPayout(uint40 stakeId) external {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.sharesTotal > 0, "stakeId not found");

        ShareOwner storage owner = listing.shareOwners[msg.sender];
        require(
            owner.payoutClaimed == false,
            "payout has already been claimed"
        );
        require(owner.sharesOwned > 0, "no shares owned for stake");

        owner.payoutClaimed = true;
        uint256 heartsOwed =
            (listing.heartsPayoutTotal * owner.sharesOwned) /
                listing.sharesTotal;
        require(heartsOwed > 0, "no hearts owed");

        hexContract.transfer(msg.sender, heartsOwed);

        emit ClaimPayout(stakeId, heartsOwed);
    }
}