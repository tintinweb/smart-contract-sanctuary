//Arkius Public Benefit Corporation Privileged & Confidential
// SPDX-License-Identifier: None
pragma solidity 0.8.0;
pragma abicoder v2;

import "./interfaces/IArkiusMembershipToken.sol";
import "./interfaces/IArkiusCertifierToken.sol";
import "./interfaces/IArkiusAttentionSeekerToken.sol";
import "./interfaces/ICampaignContract.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IMultiwallet.sol";
import "./utils/Ownable.sol";
import "./utils/ReEntrancy.sol";

/**
 * @dev MarketplaceControllerContract
 *  It controls distribution of rewards to Members, Certifiers, and Arkius.
 */
contract MarketplaceController is Ownable, ReentrancyGuard {

    /**
     * @dev CampaignContract instance.
     *
     * Used to call functions from CampaignContract.
     */
    ICampaignContract private campaignContract;

    /**
     * @dev Arkius Governance Token interface instance
     *
     * Used to call a function from TokenContract
     * which is used to transfer the token from the account of caller
     */
    IERC20 private arkiusGovernanceToken;

    /**
     * @dev Multiwallet Contract instance.
     *
     * Used to call functions from Multiwallet Contract.
     */
    IMultiwalletContract multiwallet;

    uint256 private immutable TIMESTAMP;

    /**
     * @dev enum to hold recipient information.
     *
     * rewardShare holds the proportion of rewards which each recipient will recieve.
     */

    enum Recipients { member, certifier, attentionSeeker, treasury, devfund, arkiusPBCLicense }

    enum AdStatus   { served, clicked, expired }

    /* Recipients List
    0   Member
    1   Certifier
    2   Attention Seeker
    3   Treasury
    4   Devfund
    5   Arkius PBC License
    */

    address public treasuryAddress;
    address public devfundAddress;
    address public pbcLicenseAddress;

    /// @dev Rewards Share which every type of Recipient will get.
    mapping(Recipients => uint256) public rewardShare;
    uint256 public totalShare;

    /// @dev Precision value to be used in calculations.
    uint256 constant private PRECISION = 10**18;

    struct Ad {
        uint256     adId;      //campaignId + memberId + servingTimestamp
        uint256     campaignId;
        uint256     timestamp;
        AdStatus    status;
        address     member;
        address[]   certifiers;
    }

    // @dev Mapping to store all ads corresponding to their IDs.
    mapping (uint256 => Ad) ads;

    // @dev Array to store all adIDs.
    uint256[] adIds;

    // @dev Mapping to store calculated rewards for all certifiers corresponding to their Ad Ids.
    mapping (uint256 => mapping(Recipients => mapping(address => uint256))) rewards;

    /// Emitted when a single ad is served.
    event AdServed(address indexed member, uint256 indexed campaignId, uint256 indexed adId);

    /// Emitted when a single ad is clicked.
    event AdClicked(uint256 indexed campaignId);

    /// Emitted when a single ad is expired.
    event AdExpired(uint256 indexed campaignId);

    event RewardShareUpdated(Recipients recipient, uint256 share, uint256 totalShare);

    event PBCAddressUpdated(address newPBCLicense);

    event DevFundAddressUpdated(address newDevfund);

    event TreasuryAddressUpdated(address newTreasury);

    event MultiwalletUpdated(address multiwalletAddress);

    event TokenContractUpdated(address tokenAddress);

    event CampaignContractUpdated(address campaign);
    

    /**
     * @dev Initialize the addresses of AttentionSeekerNFT, MembershipNFT, CertifierNFT, TokenContract, & Entity contract.
     *
     * @param tokenContract            Address of the Token contract.
     * @param campaignContractAddress  Address of the Campaign contract.
     * @param multiwalletContract      Address of the Multiwallet contract.
     */
    constructor(IERC20                tokenContract,
                ICampaignContract     campaignContractAddress,
                IMultiwalletContract  multiwalletContract,
                address               multisigAddress) Ownable (multisigAddress) {

        require(address(tokenContract)           != address(0), "Invalid Token address.");
        require(address(campaignContractAddress) != address(0), "Invalid Campaign address.");
        require(address(multiwalletContract)     != address(0), "Invalid Multiwallet address.");
        require(multisigAddress                  != address(0), "Invalid Multisig address.");
        arkiusGovernanceToken  = tokenContract;
        campaignContract       = campaignContractAddress;
        multiwallet            = multiwalletContract;
        TIMESTAMP              = block.timestamp;
    }

    function hash(address add, uint256 data, uint256 timestamp) internal pure returns(uint256 hashId) {
        hashId = uint(keccak256(abi.encodePacked(add, data, timestamp)));
        return hashId;
    }

    /**
     * @dev Internal functions to calculate and update multiwallet balance for when a single ad is served.
     * Removed require statements, so that the entire batch call doesn't fail, because of one.
     * Events will be emitted only for successful ones.
     *
     * @param member           Address of the Member who clicked on the Ad.
     * @param timestamp        Current time in second/millisecond.
     * @param campaignID       Id of the Campaign.
     * @param certifiers       Addresses of all the certifiers whose certifications were used.
     * @param certifierWeights Number of calls made to each certifier.
     * 
     */
    function adServed(address          member,
                      uint256          timestamp,
                      uint256          campaignID,
                      address[] memory certifiers,
                      uint256[] memory certifierWeights) internal {

        if(!(TIMESTAMP <= timestamp && timestamp <= block.timestamp)){
            return;
        }

        uint256 adId = hash(member, campaignID, timestamp);

        Ad memory newAd = ads[adId];

        if(newAd.timestamp  != 0){
            return;
        }

        if(certifiers.length != certifierWeights.length){
            return;
        }

        ICampaignContract.CampaignInfo memory campaign = campaignContract.getCampaign(campaignID);

        if (campaign.paused) {
            return;
        }

        if (campaign.multiwalletBalance < campaign.amountPerAd) {
            return;
        }

        if(multiwallet.multiwalletBalance(IMultiwalletContract.Recipients.attentionSeeker, campaign.campaignOwner) < campaign.amountPerAd){
            return;
        }

        newAd.adId       = adId;
        newAd.timestamp  = timestamp;
        newAd.campaignId = campaignID;
        newAd.status     = AdStatus.served;
        newAd.member     = member;

        ads[adId]       = newAd;
        adIds.push(adId);


        uint256 memberRewards   = (campaign.amountPerAd * rewardShare[Recipients.member]) / totalShare;
        rewards[adId][Recipients.member][member] = memberRewards;

        adServedUpdate(campaign, adId, certifiers, certifierWeights, memberRewards);
        
        campaignContract.adServed(campaignID);

        emit AdServed(member, campaignID, adId);
    }


    function adServedUpdate(ICampaignContract.CampaignInfo  memory campaign,
                            uint256                                adId,
                            address[]                       memory certifiers,
                            uint256[]                       memory certifierWeights,
                            uint256                                memberRewards) internal {


        uint256 certifierRewards = (campaign.amountPerAd * rewardShare[Recipients.certifier]) / totalShare;
        uint256 rewardsLeftovers = certifierRewards;


        uint256 totalCertifierWeight = 0;
        uint256 idx                  = 0;

        for (idx = 0; idx < certifierWeights.length; idx++) {
            totalCertifierWeight = totalCertifierWeight + certifierWeights[idx];
        }

        for (idx = 0; idx < certifiers.length; idx++) {
            uint256 certifierReward = (certifierWeights[idx] * certifierRewards * PRECISION) / (totalCertifierWeight * PRECISION);

            rewards[adId][Recipients.certifier][certifiers[idx]] = certifierReward;
            rewardsLeftovers = rewardsLeftovers - certifierReward;
        }

        ads[adId].certifiers = certifiers;


        rewardsLeftovers = rewardsLeftovers + (campaign.amountPerAd - (memberRewards + certifierRewards));

        uint256 recipientRewards = (campaign.amountPerAd * rewardShare[Recipients.treasury]) / totalShare;
        rewards[adId][Recipients.treasury][treasuryAddress] = recipientRewards;
        rewardsLeftovers = rewardsLeftovers - recipientRewards;

        recipientRewards = (campaign.amountPerAd * rewardShare[Recipients.devfund]) / totalShare;
        rewards[adId][Recipients.devfund][devfundAddress] = recipientRewards;
        rewardsLeftovers = rewardsLeftovers - recipientRewards;

        recipientRewards = (campaign.amountPerAd * rewardShare[Recipients.arkiusPBCLicense]) / totalShare;
        rewards[adId][Recipients.arkiusPBCLicense][pbcLicenseAddress] = recipientRewards;
        rewardsLeftovers = rewardsLeftovers - recipientRewards;

        rewards[adId][Recipients.treasury][treasuryAddress] = rewards[adId][Recipients.treasury][treasuryAddress] + rewardsLeftovers;

    }


    /**
     * @dev Batch function to calculate and update multiwallet balance for multiple clicks on multiple campaigns at once.
     *
     * @param members           Addresses of the members who clicked on the Ads.
     * @param timestamps        Current time in seconds.
     * @param campaignIDs       IDs of the Campaigns.
     * @param certifiers        Addresses of all the certifiers whose certifications were used.
     * @param certifierWeights  No. of calls made to each certifier.
     */
    function adServedBatch(address[]   memory members,
                           uint256[]   memory timestamps,
                           uint256[]   memory campaignIDs,
                           address[][] memory certifiers,
                           uint256[][] memory certifierWeights) onlyOwner nonReentrant external  {

        for (uint256 idx=0; idx<members.length; idx++) {
            adServed(members[idx], timestamps[idx], campaignIDs[idx], certifiers[idx], certifierWeights[idx]);
        }
    }


    /**
     * @dev Internal function to calculate and update multiwallet balance for a single click on a single campaign.
     *
     * @param adId       Id of the Ad.
     */
    function adClicked(uint256 adId) internal {
        Ad memory ad = ads[adId];
        if(ad.status != AdStatus.served){
            return;
        }

        ICampaignContract.CampaignInfo memory campaign = campaignContract.getCampaign(ad.campaignId);

        multiwallet.multiwalletTransfer(campaign.campaignOwner,
                                IMultiwalletContract.Recipients.attentionSeeker,
                                ad.member,
                                IMultiwalletContract.Recipients.member,
                                rewards[adId][Recipients.member][ad.member]);

        for(uint idx=0; idx < ad.certifiers.length; idx++){
                multiwallet.multiwalletTransfer(campaign.campaignOwner,
                                        IMultiwalletContract.Recipients.attentionSeeker,
                                        ad.certifiers[idx],
                                        IMultiwalletContract.Recipients.certifier,
                                        rewards[adId][Recipients.certifier][ad.certifiers[idx]]);
        }

        multiwallet.multiwalletTransfer(campaign.campaignOwner,
                                IMultiwalletContract.Recipients.attentionSeeker,
                                devfundAddress,
                                IMultiwalletContract.Recipients.devfund,
                                rewards[adId][Recipients.devfund][devfundAddress]);

        multiwallet.multiwalletTransfer(campaign.campaignOwner,
                                IMultiwalletContract.Recipients.attentionSeeker,
                                pbcLicenseAddress,
                                IMultiwalletContract.Recipients.arkiusPBCLicense,
                                rewards[adId][Recipients.arkiusPBCLicense][pbcLicenseAddress]);

        multiwallet.multiwalletTransfer(campaign.campaignOwner,
                                IMultiwalletContract.Recipients.attentionSeeker,
                                treasuryAddress,
                                IMultiwalletContract.Recipients.treasury,
                                rewards[adId][Recipients.treasury][treasuryAddress]);

        ads[adId].status = AdStatus.clicked;
        campaignContract.adClicked(ad.campaignId);

        emit AdClicked(adId);
    }

    /**
     * @dev Batch function to calculate and update multiwallet balance for multiple clicks on multiple ads at once.
     *
     * @param ids       IDs of the Ads.
     */
    function adClickedBatch(uint256[] memory ids) onlyOwner nonReentrant external  {

        for (uint256 idx=0; idx<ids.length; idx++) {
            adClicked(adIds[idx]);
        }
    }


    /**
     * @dev Internal function to calculate and de-multiwallet balance for an expired ad campaign.
     *
     * @param adId                  Id of the Campaign.
     * @param cutPercentNumerator   Numerator of percentage amount to be deducted.
     * @param cutPercentDenominator Denominator of percentage amount to be deducted.
     */
    function adExpired(uint256 adId, uint256 cutPercentNumerator, uint256 cutPercentDenominator) internal {
        Ad memory ad = ads[adId];
        if(ad.status != AdStatus.served){
            return;
        }
        // require(ad._timestamp.add(m_expirationTime) <= block.timestamp, "Ad not expired.");

        ICampaignContract.CampaignInfo memory campaign = campaignContract.getCampaign(ad.campaignId);

        uint256 cutAmount = (campaign.amountPerAd * cutPercentNumerator * PRECISION) / (cutPercentDenominator * PRECISION);

        multiwallet.multiwalletTransfer(campaign.campaignOwner, IMultiwalletContract.Recipients.attentionSeeker, treasuryAddress, IMultiwalletContract.Recipients.treasury, cutAmount);
        multiwallet.deMultiwallet(campaign.campaignOwner, IMultiwalletContract.Recipients.attentionSeeker, campaign.amountPerAd - cutAmount);

        ads[adId].status = AdStatus.expired;
        emit AdExpired(adId);
    }

    /**
     * @dev OnlyOwner function to calculate and de-multiwallet balances for  expired ad-campaigns.
     *
     * @param ids                  Ids of the Campaign.
     * @param cutPercentNumerator   Numerator of percentage amount to be deducted.
     * @param cutPercentDenominator Denominator of percentage amount to be deducted.
     */
    function adExpiredBatch(uint256[] memory ids, uint256 cutPercentNumerator, uint256 cutPercentDenominator) onlyOwner nonReentrant external  {
        for (uint256 idx=0; idx<ids.length; idx++) {
            adExpired(adIds[idx], cutPercentNumerator, cutPercentDenominator);
        }
    }

    /**
     * @dev Update multiwallet contract address.
     *
     * @param multiwalletAddress        Address of the new multiwallet contract.
     */
    function updateMultiwalletContract(IMultiwalletContract multiwalletAddress) onlyOwner external {
        require(address(multiwalletAddress) != address(0), "Invalid Multiwallet address.");
        multiwallet = multiwalletAddress;
        emit MultiwalletUpdated(address(multiwalletAddress));
    }

    /**
     * @dev Update Treasury address.
     *
     * @param newTreasury        Address of the new treasury.
     */
    function updateTreasuryAddress(address newTreasury) onlyOwner external {
        require(newTreasury != address(0), "Invalid address.");
        treasuryAddress = newTreasury;
        emit TreasuryAddressUpdated(newTreasury);
    }

    /**
     * @dev Update DevFund address.
     *
     * @param newDevfund        Address of the new devfund.
     */
    function updateDevfundAddress(address newDevfund) onlyOwner external {
        require(newDevfund != address(0), "Invalid address.");
        devfundAddress = newDevfund;
        emit DevFundAddressUpdated(newDevfund);
    }

    /**
     * @dev Update PBC License address.
     *
     * @param newPBCLicense        Address of the new PBC License.
     */
    function updatePBCAddress(address newPBCLicense) onlyOwner external {
        require(newPBCLicense != address(0), "Invalid address.");
        pbcLicenseAddress = newPBCLicense;
        emit PBCAddressUpdated(newPBCLicense);
    }

    /**
     * @dev Update RewardShare for given recipient.
     *
     * @param recipient    Type of the recipient.
     * @param share        Reward Share Amount of the recipient.
     */
    function updateRewardShare(Recipients recipient, uint256 share) onlyOwner external {
        totalShare = totalShare - rewardShare[recipient];
        rewardShare[recipient] = share;
        totalShare = totalShare + share;
        emit RewardShareUpdated(recipient, share, totalShare);
    }

    function updateTokenAddress(IERC20 token) external onlyOwner {
        require(address(token) != address(0), "Invalid address.");
        arkiusGovernanceToken = token;
        emit TokenContractUpdated(address(token));
    }

    function updateCampaignAddress(ICampaignContract campaign) external onlyOwner {
        require(address(campaign) != address(0), "Invalid address.");
        campaignContract = campaign;
        emit CampaignContractUpdated(address(campaign));
    }

    function MultiwalletContract() external view returns(IMultiwalletContract) {
        return multiwallet;
    }

    function campaignAddress() external view returns(ICampaignContract) {
        return campaignContract;
    }

    function governanceToken() external view returns(IERC20) {
        return arkiusGovernanceToken;
    }

    function precision() external pure returns(uint256) {
        return PRECISION;
    }

    function getAllAdIDs() external view returns(uint256[] memory) {
        return adIds;
    }

    function getAd(uint256 adId) external view returns(Ad memory) {
        return ads[adId];
    }

    function checkEarnedRewards(uint256 adId, Recipients recipient, address receiver) external view returns(uint256) {
        return rewards[adId][recipient][receiver];
    }

}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusMembershipToken {
    function memberIdOf(address owner) external view returns (uint256);
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusCertifierToken {
    function certifierIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusAttentionSeekerToken {
    function attentionSeekerIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface ICampaignContract {
    
    struct CampaignInfo {
        uint256  id;
        address  campaignOwner;
        uint256  adServed;
        uint256  totalClick;
        uint256  amountPerAd;
        uint256  totalFunding;
        uint256  multiwalletBalance;
        bool     paused;
        string   title;
        string   content;
        string   imageUrl;
        string   destinationUrl;
        string   metadata;
        uint256  target;
    }

    function adClicked(uint256 campaignId) external;

    function getCampaign(uint id) external view returns(CampaignInfo memory);
    
    function adServed(uint256 campaignID) external;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.0;

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
     * @dev Returns the amount of locked tokens owned by `account`.
     */
    function lockedBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`, and unlocks it.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferUnlock(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. The amount is also unlocked.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFromUnlock(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(address account, uint256 amount) external;

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

//SPDX-License-Identifier:None
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

interface IMultiwalletContract{


    struct Multiwallet{
        uint256 memberID;
        uint256 eventID;
        uint256 amount;
        uint32  timestamp;
        string  reasonMetadata;
    }

    enum Recipients { member, certifier, attentionSeeker, treasury, devfund, arkiusPBCLicense }


    function multiwalletBalance(Recipients mType, address mAddress) external returns (uint);

    function multiwallet(address mAddress, Recipients mtype, uint256 amount) external;

    function deMultiwallet(address mAddress, Recipients mtype, uint256 amount) external;

    function unMultiwallet(address mAddress, Recipients mtype, uint256 amount) external;

    function claimRewards() external;

    function multiwalletTransfer(address fromAddress, Recipients fromType, address toAddress, Recipients toType, uint256 amount) external ;

}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipNominated(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address multisig) {
        _owner = multisig;
        emit OwnershipTransferred(address(0), multisig);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Nominate new Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        _nominatedOwner = newOwner;
        emit OwnershipNominated(_owner,newOwner);
    }

    /**
     * @dev Nominated Owner can accept the Ownership of the contract.
     * Can only be called by the nominated owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _nominatedOwner, "Ownable: You must be nominated before you can accept ownership");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
        _nominatedOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private _status;
    
    constructor () {
        _status = NOT_ENTERED;
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
        require(_status != ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

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
abstract contract Context {

    /// Empty constructor, to prevent people from mistakenly deploying
    /// an instance of this contract, which should be used via inheritance.

    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {

        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}