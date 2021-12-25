//Arkius Public Benefit Corporation Privileged & Confidential
//SPDX-License-Identifier: None
pragma solidity 0.8.0;
pragma abicoder v2;

import './interfaces/IArkiusAttentionSeekerToken.sol';
import './interfaces/IERC20.sol';
import './interfaces/IEntity.sol';
import './interfaces/IMultiwallet.sol';
import './utils/Ownable.sol';
import './utils/ReEntrancy.sol';

/**
 * @dev CampaignContract This contract is for the Attention Seekers only.
 * 
 * Attention Seekers can create the Campaign with the help of this Contract.
 * 
 */

contract CampaignContract is Ownable, ReentrancyGuard {

    /**
     * @dev Attention Seeker Token interface instance.
     * 
     * Used to call a function from AttentionSeekerNFT,
     * which return the Attention Seeker ID of the caller.
     */
    IArkiusAttentionSeekerToken private attentionSeekerToken;

    /**
     * @dev Arkius Governance Token interface instance.
     *
     * Used to call a function from TokenContract.
     * which is used to transfer the token from the account of caller.
     */
    IERC20 private arkiusGovernanceToken;

    /**
     * @dev Entity Contract interface instance.
     *
     * Used to call a function from Entity contract.
     */
    IEntity public entityContract;

    /**
     * @dev Multiwallet Contract interface instance.
     *
     * Used to call functions from Multiwallet contract.
     */

    IMultiwalletContract private multiwallet;

    /**
     * @dev MarketplaceController Contract address.
     *
     * Used to verify if a function call is made from the Marketplace Controller.
     */
    address private marketplaceControllerContract;

    uint256 private immutable TIMESTAMP;

    /// Emitted when a campaign is created by an Attention Seeker.
    event AddCampaign(uint256 indexed id);

    /// Emitted when a user clicks on the Ad.
    event AdClicks(uint256 indexed campaignId, uint256 indexed totalClick, uint256 indexed multiwalletBalance);

    /// Emitted when Attention Seeker add funds in its campaign.
    event FundCampaign(uint256[] indexed id, uint256[] indexed campaignFunded, uint256[] replenish);

    /// Emitted when Attention Seeker deletes his campaign.
    event DeleteCampaign(address indexed owner, uint256 indexed id);

    /// Emitted when an Attention Seeker edit his campaign.
    event EditCampaign(uint256 indexed id,
                       uint256 indexed target,
                       string  indexed title,
                       string  content,
                       string  imageUrl,
                       string  destinationUrl,
                       string  metadata);
    
    
    event MarketplaceControllerUpdated(address newMarketplaceControllerAddress);
    
    event TokenUpdated(address tokenAddress);
        
    event WithdrawFunds(address msgSender, uint256 campaignID, uint256 amount);
    event AttentionSeekerTokenUpdated(address seekerAddress);
    event EntityUpdated(address entityAddress);
    event MultiwalletUpdated(address multiwalletAddress);
    event Paused(uint256 indexed id, bool value);
    
    uint256 constant INVALID = 0;

    /** Stores additional information related to the Campaign.
     * @param id                  Id of the Entity.
     * @param campaignOwner       Address of the Attention Seeker who created the Campaign.
     * @param adServed            Total number of ad serves of the camapign.
     * @param totalClick          Total Clicks made on the ad of the Campaign.
     * @param amountPerAd         Amount given to iser per ad click.
     * @param totalFunding        Total Fund added to the campaign.
     * @param multiwalletBalance  Fund left in the campaign after ad distribution.
     * @param paused              Checks if the Campaign is paused or not.
     * @param title               Title of the Campaign.
     * @param content             Description of the Campaign.
     * @param imageUrl            Url of the image of the Campaign.
     * @param destinationUrl      DestinatioinUrl of the Campaign.
     * @param metadata            Metadata of the Entity.
     * @param target              Target of the Campaign.
     */
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

    /// @dev mapping from camapign Id => camapignInfo.
    mapping(uint256 => CampaignInfo) private campaigns;

    /// @dev mapping from AttentionSeekerAddress  => Attention Seekers created Campaigns' IDs.
    mapping(address => uint256[]) private attentionSeekerCampaigns;

    /// @dev mapping from id => index of id's of camapigns created by an attention seeker.
    mapping(uint256 => uint256) private idIndexAttentionSeeker;

    /// @dev array for all Campaigns' IDs.
    uint256[] private allCampaigns;

    /// @dev mapping from id => index of id in allCampaigns.
    mapping(uint256 => uint256) private idIndexCampaign;

    /**
     * @dev initialize the AttentionSeekerContract address.
     *
     * @param attentionSeekerAddress Address of Attention Seeker Contract.
     *
     */
    constructor(IArkiusAttentionSeekerToken attentionSeekerAddress,
                IEntity                     entityContractAddress,
                IMultiwalletContract        multiwalletContractAddress,
                IERC20                      token,
                address                     multisigAddress) Ownable(multisigAddress) {

        require(address(attentionSeekerAddress)     != address(0), "Invalid Seeker Address");
        require(address(entityContractAddress)      != address(0), "Invalid Entity Address");
        require(address(multiwalletContractAddress) != address(0), "Invalid Multiwallet Address");
        require(address(token)                      != address(0), "Invalid Token Address");
        require(multisigAddress                     != address(0), "Invalid Multisig Address");

        attentionSeekerToken  = attentionSeekerAddress;
        arkiusGovernanceToken = token;
        entityContract        = entityContractAddress;
        multiwallet           = multiwalletContractAddress;
        TIMESTAMP             = block.timestamp;
    }

    modifier onlyAttentionSeeker() {
        uint256 id = attentionSeekerToken.attentionSeekerIdOf(_msgSender());
        require(id != INVALID, "Not an Attention Seeker");
        _;
    }

    modifier onlyCampaignOwner(uint256 id) {
        require(campaigns[id].campaignOwner == _msgSender(), "Caller is not the Campaign Owner");
        _;
    }

    modifier onlyMarketplaceController() {
        require(marketplaceControllerContract == _msgSender(), "Only MarketplaceController is allowed.");
        _;
    }

    function hash(address add, string memory data, uint256 timestamp) internal pure returns(uint256 hashId) {
        hashId = uint(keccak256(abi.encodePacked(add, data, timestamp)));
        return hashId;
    }

    /**
     * This function is used to create campaigns.
     * This can only be created by an Attention Seeker.
     *
     * @param timestamp      Current time in second/millisecond.
     * @param title          Title of the Campaign.
     * @param content        Description of the Campaign.
     * @param imageUrl       Url of the image of the Campaign.
     * @param destinationUrl DestinatioinUrl of the Campaign.
     * @param metadata       Metadata of the Entity.
     * @param target         Target of the Campaign.
     * @param amountPerAd    Amount given to user per ad click.
     */
    function addCampaign(uint256       timestamp,
                         string memory title,
                         string memory content,
                         string memory imageUrl,
                         string memory destinationUrl,
                         string memory metadata,
                         uint96        target,
                         uint96        amountPerAd) external onlyAttentionSeeker() {

        require(TIMESTAMP <= timestamp && timestamp <= block.timestamp, "Invalid timestamp");

        uint256 id = hash(_msgSender(), metadata, timestamp);

        require(campaigns[id].id == 0, "Id already taken");
        require(bytes(title         ).length != 0, "No title provided.");
        require(bytes(content       ).length != 0, "No content provided.");
        require(bytes(destinationUrl).length != 0, "No destinationUrl provided.");
        require(bytes(metadata      ).length != 0, "No metadata provided.");

        require(amountPerAd  > 0, "amountPerAd must be greater than 0");

        entityContract.createEntity(timestamp, title, IEntity.IEntityType.campaign, content, metadata, _msgSender());

        CampaignInfo memory campinfo = CampaignInfo( id,
                                                    _msgSender(),
                                                    0,
                                                    0,
                                                    amountPerAd,
                                                    0,
                                                    0,
                                                    false,
                                                    title,
                                                    content,
                                                    imageUrl,
                                                    destinationUrl,
                                                    metadata,
                                                    target);

        campaigns[id] = campinfo;

        attentionSeekerCampaigns[_msgSender()].push(id);
        allCampaigns.push(id);

        idIndexCampaign[id]        = allCampaigns.length;
        idIndexAttentionSeeker[id] = attentionSeekerCampaigns[_msgSender()].length;

        emit AddCampaign(id);
    }

    /**
     * Pauses the campaign so that no ads will be served from that particualr campaign.
     *
     * @param campaignID    Id of the campaign that has to be paused.
     * @param pause         true or false to pause the campaign
     */

    function setPaused(uint256 campaignID, bool pause) external onlyCampaignOwner(campaignID) {
        campaigns[campaignID].paused = pause;

        emit Paused(campaignID, pause);
    }

    /**
     * @dev Attention Seeker can fund multiple contracts in one go.
     *
     * @param id        Its an array of id. The campaigns are funded with this id's.
     * @param replenish Array of amount. Campaigns will be funded with the corresponding amount.
     *
     * Requirement :-
     *      length of `id` must be equal to length of `replenish`.
     */
    function fundCampaign(uint256[] memory id, uint256[] memory replenish) external onlyAttentionSeeker nonReentrant {

        require (id.length == replenish.length,   "Invalid input data.");
        require (address(multiwallet) != address(0), "Multiwallet not defined.");

        uint256 amount = 0;
        uint256[] memory campaignReplenished = new  uint256[](replenish.length);

        for (uint256 idx = 0; idx < replenish.length; idx++) {
            if (campaigns[id[idx]].campaignOwner == _msgSender() && replenish[idx] > 0) {

                campaigns[id[idx]].totalFunding       = campaigns[id[idx]].totalFunding + replenish[idx];
                campaigns[id[idx]].multiwalletBalance = campaigns[id[idx]].multiwalletBalance + replenish[idx];

                amount = amount + replenish[idx];

                campaignReplenished[idx] = id[idx];
            }
        }

        arkiusGovernanceToken.transferFrom(_msgSender(), address(multiwallet), amount); // To be transferred to multiwallet.
        multiwallet.multiwallet(_msgSender(), IMultiwalletContract.Recipients.attentionSeeker, amount);

        emit FundCampaign( id, campaignReplenished, replenish);
    }

    /**
     * Only the Campaign Owner who created the campaign can withdraw Funds from the campaign.
     *
     * @param campaignID    Id of the campaign from which the funds will be withdrawn.
     * @param amount        Amount that is to be withdrawn from the campaign.
     */

    function withdrawFunds(uint256 campaignID, uint256 amount) external onlyCampaignOwner(campaignID) {
        campaigns[campaignID].multiwalletBalance = campaigns[campaignID].multiwalletBalance - amount;
        campaigns[campaignID].totalFunding  = campaigns[campaignID].totalFunding - amount;
        multiwallet.unMultiwallet(_msgSender(), IMultiwalletContract.Recipients.attentionSeeker, amount);
        emit WithdrawFunds(_msgSender(), campaignID, amount);
    }

    /**
     * Only the Campaign Owner who created the campaign can Delete the campaign.
     *
     * @param id Id of the campaign that is to be deleted.
     */
    function deleteCampaign(uint id) external onlyCampaignOwner(id) nonReentrant {

        uint256 amount = campaigns[id].multiwalletBalance;

        uint256 index  = idIndexCampaign[id];
        uint256 length = allCampaigns.length - 1;

        if (index > 0) {
            allCampaigns[index - 1] = allCampaigns[length];
            idIndexCampaign[allCampaigns[length]] = index;
            idIndexCampaign[id] = 0;
            allCampaigns.pop();
        }

        index  = idIndexAttentionSeeker[id];
        length = attentionSeekerCampaigns[_msgSender()].length - 1;

        if (index > 0) {
            attentionSeekerCampaigns[_msgSender()][index - 1] =  attentionSeekerCampaigns[_msgSender()][length];
            idIndexAttentionSeeker[attentionSeekerCampaigns[_msgSender()][length]] = index;
            idIndexAttentionSeeker[id] = 0;
            attentionSeekerCampaigns[_msgSender()].pop();
        }

        delete campaigns[id];

        campaigns[id].id = id;

        entityContract.deleteEntity(id, _msgSender());

        multiwallet.unMultiwallet(_msgSender(), IMultiwalletContract.Recipients.attentionSeeker, amount);

        emit DeleteCampaign(_msgSender(), id);

    }

    /** This function is used to edit the campaigns.
     * This can only be edited by the owner of the campaign
     *
     * @param id             Id of the Entity.
     * @param target         Target of the Campaign.
     * @param title          Title of the Campaign.
     * @param content        Description of the Campaign.
     * @param imageUrl       Url of the image of the Campaign.
     * @param destinationUrl DestinatioinUrl of the Campaign.
     * @param metadata       Metadata of the Entity.
     */
    function editCampaign(uint id,
        uint target,
        string memory title,
        string memory content,
        string memory imageUrl,
        string memory destinationUrl,
        string memory metadata) external onlyAttentionSeeker onlyCampaignOwner(id) {

        if (bytes(title         ).length != 0)   campaigns[id].title          = title;
        if (bytes(content       ).length != 0)   campaigns[id].content        = content;
        if (bytes(imageUrl      ).length != 0)   campaigns[id].imageUrl       = imageUrl;
        if (bytes(destinationUrl).length != 0)   campaigns[id].destinationUrl = destinationUrl;
        if (bytes(metadata      ).length != 0)   campaigns[id].metadata       = metadata;

        campaigns[id].target = target;
        entityContract.editEntity(id, title, content, metadata, _msgSender());

        emit EditCampaign(id, target, title, content, imageUrl, destinationUrl, metadata);
    }

    /**
     * When the user clicks on the ad then the click count is increased and
     * the remaining campaign fund amount is decreased.
     * Can only be called through the Marketplace Controller.
     *
     * @param campaignID Id of the campaign of the ad.
     */
    function adClicked(uint256 campaignID) external onlyMarketplaceController nonReentrant {

        uint256 totalClick    = campaigns[campaignID].totalClick;

        campaigns[campaignID].totalClick    = totalClick + 1;

        emit AdClicks(campaignID, campaigns[campaignID].totalClick, campaigns[campaignID].multiwalletBalance);
    }
    
    function adServed(uint256 campaignID) external onlyMarketplaceController nonReentrant {
        
        uint256 amountPerAd   = campaigns[campaignID].amountPerAd;
        uint256 multiwalletBalance = campaigns[campaignID].multiwalletBalance;

        if(multiwalletBalance < amountPerAd){
             return;   
        }
        
        campaigns[campaignID].adServed = campaigns[campaignID].adServed + 1;
        campaigns[campaignID].multiwalletBalance = multiwalletBalance - amountPerAd;
    }

    /** This function is used to update the MarketplaceController Address
     *  This can only be updated by the owner of the Contract
     *
     * @param newMarketplaceControllerAddress The new contract address of the MarketplaceController.
     */
    function updateMarketplaceController(address newMarketplaceControllerAddress) external onlyOwner {
        require(newMarketplaceControllerAddress != address(0), "Invalid Address");
        marketplaceControllerContract = newMarketplaceControllerAddress;
        emit MarketplaceControllerUpdated(newMarketplaceControllerAddress);
    }

    function updateSeekerToken(IArkiusAttentionSeekerToken seekerAddress) external onlyOwner {
        require(address(seekerAddress) != address(0), "Invalid Address");
        attentionSeekerToken  = seekerAddress;
        emit AttentionSeekerTokenUpdated(address(seekerAddress));
    }

    function updateEntity(IEntity entityAddress) external onlyOwner {
        require(address(entityAddress) != address(0), "Invalid Address");
        entityContract = entityAddress;
        emit EntityUpdated(address(entityAddress));
    }

    function updateMultiwallet(IMultiwalletContract multiwalletAddress) external onlyOwner {
        require(address(multiwalletAddress) != address(0), "Invalid Address");
        multiwallet = multiwalletAddress;
        emit MultiwalletUpdated(address(multiwalletAddress));
    }

    function updateToken(IERC20 tokenAddress) external onlyOwner {
        require(address(tokenAddress) != address(0), "Invalid Address");
        arkiusGovernanceToken = tokenAddress;
        emit TokenUpdated(address(tokenAddress));
    }

    /**
     * @dev Returns all IDs of Campaigns.
     */
    function getAllCampaigns() external view returns(uint256[] memory){
        return allCampaigns;
    }

    /**
     * @dev Returns an Campaign corresponding to particular CampaignID.
     * @param id Id of the campaign.
     *
     * @return All the details of an Campaign.
     */

    function getCampaign(uint256 id) external view returns(CampaignInfo memory){
        return campaigns[id];
    }

    /**
     * Checks if the campaign is paused or not.
     *
     * @param campaignID   Check the campaign if it's paused or not.
     *
     * @return return true if the campaign is paused else return false.
     */

    function checkPaused(uint256 campaignID) external view returns(bool) {
        return campaigns[campaignID].paused;
    }

    /**
     * @dev Returns all the ID's of the Campaign created by an Attention Seeker.
     * @param attentionSeeker Address of the AttentionSeeker.
     *
     * @return All the ID's of the Campaign created by an Attention Seeker
     */

    function getAttentionSeekerCampaigns(address attentionSeeker) external view returns(uint256[] memory){
        require(attentionSeeker != address(0), "Invalid Address");
        return attentionSeekerCampaigns[attentionSeeker];
    }

    function marketPlaceContract() external view returns(address) {
        return marketplaceControllerContract;
    }

    function seekerTokenContract() external view returns(IArkiusAttentionSeekerToken) {
        return attentionSeekerToken;
    }

    function multiwalletContract() external view returns(IMultiwalletContract) {
        return multiwallet;
    }

    function tokenContract() external view returns(IERC20) {
        return arkiusGovernanceToken;
    }
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusAttentionSeekerToken {
    function attentionSeekerIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
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
pragma abicoder v2;

interface IEntity {
    enum IEntityType {product, company, campaign}
    
    struct ReturnEntity{
            uint256     id;
            address     creator;
            IEntityType entityType;
            string      title;
            string      description;
            string      metadata;
    }

    function createEntity(uint256       id,
                          string memory title,
                          IEntityType   types,
                          string memory description,
                          string memory metadata,
                          address attentionSeekerAddress) external;

    function getEntity(uint256 id) external view returns(ReturnEntity memory);

    function entityExist(uint256 id) external view returns(bool);

    function deleteEntity(uint256 id, address attentionSeekerAddress) external;

    function editEntity(uint256       id,
                        string memory title,
                        string memory description,
                        string memory metadata,
                        address attentionSeekerAddress) external;
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