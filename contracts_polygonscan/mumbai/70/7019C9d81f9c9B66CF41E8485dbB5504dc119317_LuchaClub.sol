/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



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


// File contracts/tier/ITier.sol


/// @title ITier
/// Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing ITier:
/// - MUST represent held tiers with the `Tier` enum.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the block each tier has been continuously held since encoded as `uint32`.
///   - The encoded tiers start at ONE; ZERO is implied if no tier has ever been held.
///   - Tier ZERO is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the block data is erased for that tier and will be set if/when the tier is regained to the new block.
///   - If the historical block information is not available the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
/// - SHOULD implement `setTier`.
///   - Contracts SHOULD revert with `SET_TIER` error if they cannot meaningfully set a tier directly.
///     For example a contract that can only derive a membership tier by reading the state of an external contract cannot set tiers.
///   - Contracts implementing `setTier` SHOULD error with `SET_ZERO_TIER` if `Tier.ZERO` is being set.
/// - MUST emit `TierChange` when `setTier` successfully writes a new tier.
///   - Contracts that cannot meaningfully set a tier are exempt.
interface ITier {
    /// 9 Possible tiers.
    /// Fits nicely as uint32 in uint256 which is helpful for internal storage concerns.
    /// 8 tiers can be achieved, ZERO is the tier when no tier has been achieved.
    enum Tier {
        ZERO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT
    }

    /// Every time a Tier changes we log start and end Tier against the account.
    /// This MAY NOT be emitted if reports are being read from the state of an external contract.
    event TierChange(
        address indexed account,
        Tier indexed startTier,
        Tier indexed endTier
    );

    /// Updates the tier of an account.
    ///
    /// The implementing contract is responsible for all checks and state changes required to set the tier.
    /// For example, taking/refunding funds/NFTs etc.
    ///
    /// Contracts may disallow directly setting tiers, preferring to derive reports from other onchain data.
    /// In this case they should `revert("SET_TIER");`.
    ///
    /// @param account Account to change the tier for.
    /// @param endTier Tier after the change.
    /// @param data Arbitrary input to disambiguate ownership (e.g. NFTs to lock).
    function setTier(
        address account,
        Tier endTier,
        bytes memory data
    )
        external;

    /// Returns the earliest block the account has held each tier for continuously.
    /// This is encoded as a uint256 with blocks represented as 8x concatenated u32.
    /// I.e. Each 4 bytes of the uint256 represents a u32 tier start time.
    /// The low bits represent low tiers and high bits the high tiers.
    /// Implementing contracts should return 0xFFFFFFFF for lost & never-held tiers.
    ///
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256);
}


// File contracts/tier/ValueTier.sol


/// @title ValueTier
///
/// A contract that is `ValueTier` expects to derive tiers from explicit values.
/// For example an address must send or hold an amount of something to reach a given tier.
/// Anything with predefined values that map to tiers can be a `ValueTier`.
///
/// Note that `ValueTier` does NOT implement `ITier`.
/// `ValueTier` does include state however, to track the `tierValues` so is not a library.
contract ValueTier {
    uint256[5] public tierValues;

    /// Set the `tierValues` on construction to be referenced immutably.
    constructor(uint256[5] memory tierValues_) {
        tierValues = tierValues_;
    }

    /// Complements the default solidity accessor for `tierValues`.
    /// Returns all the values in a list rather than requiring an index be specified.
    /// @return The immutable `tierValues`.
    function getTierValues() external view returns(uint256[5] memory) {
        return tierValues;
    }

    /// Converts a Tier to the minimum value it requires.
    /// Tier ZERO is always value 0 as it is the fallback.
    function tierToValue(ITier.Tier tier_) internal view returns(uint256) {
        return tier_ > ITier.Tier.ZERO ? tierValues[uint256(tier_) - 1] : 0;
    }

    /// Converts a value to the maximum Tier it qualifies for.
    function valueToTier(uint256 value_) internal view returns(ITier.Tier) {
        for (uint256 i = 0; i < 8; i++) {
            if (value_ < tierValues[i]) {
                return ITier.Tier(i);
            }
        }
        return ITier.Tier.EIGHT;
    }
}


// File contracts/LuchaClub.sol

contract LuchaClub is ValueTier, Ownable{

    mapping(address => uint256) membersTierList;
    mapping(address => bool) approvedAddresses;

    modifier onlyMembers(){
        require(
            membersTierList[msg.sender] > 0 || 
            approvedAddresses[msg.sender] == true, 
            "You dont have approval to get this information"
        );
        _;
    } 

    constructor(uint256[5] memory tierValues_) ValueTier(tierValues_){
       /**@dev the club owner starts having the greatest possible tier in the club*/
        membersTierList[msg.sender] = tierValues_[4];
    }

    function changeMemberTier(address _account, uint256 tierValue) public onlyOwner returns(bool){
        membersTierList[_account] = tierValue;
        return true;
    }

    function getMemberTier(address _account) public view onlyMembers returns(uint256){
        return membersTierList[_account];
    }

    function approve(address _account) public onlyOwner{
        require(_account != address(0), "This is not a valid addess");
        approvedAddresses[_account] = true;
    }

    function isMember(address _account) public view onlyMembers returns (bool){
        if(membersTierList[_account] > 0){
            return true;
        }
        return false;
    }

    function isApproved(address _account) public view returns (bool){
        return approvedAddresses[_account];
    } 

}