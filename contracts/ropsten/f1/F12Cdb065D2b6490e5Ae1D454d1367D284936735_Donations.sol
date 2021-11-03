/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/Donations.sol


pragma solidity ^0.8.4;


contract Donations is Ownable {
    struct Campaign {
        string name;
        string description;
        uint timeGoal;
        uint moneyGoal;
        uint moneyReceived;
        address payable beneficiary;
    }

    uint campaignsTotal;
    mapping(uint => Campaign) campaigns;

    event campaignCreation(uint campaignId, Campaign campaign);
    event donation(address fromAddress, address campaignAddress, uint donationAmount);

    modifier onlyIfNewCampaignInputValid(uint timeGoal, uint moneyGoal) {
        if(timeGoal <= block.timestamp){
            revert InvalidCampaignEndTime();
        }
        if(moneyGoal <= 0) {
            revert InvalidCampaignDonationGoal();
        }
        _;
    }

    modifier onlyIfDonationValid(uint campaignId) {
        if(campaignId > campaignsTotal) {
            revert NotFoundCampaign();
        }
        if(msg.value <= 0 || !isDonationAmountAllowed(campaignId)) {
            revert InvalidDonationAmount();
        }
        if(campaigns[campaignId].beneficiary == msg.sender) {
            revert NotAllowedDonation();
        }
        if(isCampaginClosed(campaignId)) {
            revert NotActiveCampaign();
        }
        _;
    }

    /**
     * @notice Invalid campaign end time. The campaign end time must be in future.
     */
    error InvalidCampaignEndTime();

    /**
     * @notice Invalid campaign donation goal. The campaign money goal must be at least 1 wei.
     */
    error InvalidCampaignDonationGoal();

    /**
     * @notice Campaign is not found. The desired campaign does not exist.
     */
    error NotFoundCampaign();

    /**
     * @notice Invalid donation amount. The donation must be at least 1 wei, and below campaign donation goal.
     */
    error InvalidDonationAmount();

    /**
     * @notice Donation is not allowed. The campagin self donation is not allowed.
     */
    error NotAllowedDonation();

    /**
     * @notice Campaign is closed. The money goal reached or end time exceeded.
     */
    error NotActiveCampaign();


    constructor() {}

    /**
     * @notice Create a new campaign, allowed to the contract owner.
     * @param campaignAddress The donation address of the new campaign.
     * @param name The name of the new campaign.
     * @param descripton Brief description of the new campaign.
     * @param timeGoal The end time of the new campaign.
     * @param moneyGoal The donation goal of a new campaign, in wei.
     */
    function addNewCampaign(address payable campaignAddress, string memory name, string memory descripton, uint timeGoal, uint moneyGoal) external onlyOwner onlyIfNewCampaignInputValid(timeGoal, moneyGoal){
        Campaign memory campaign = Campaign(name, descripton, timeGoal, moneyGoal, 0, campaignAddress);
        campaigns[campaignsTotal] = campaign;

        emit campaignCreation(campaignsTotal++, campaign);
    }

    /**
     * @notice Place donation in ether for the given campaign id.
     * @param campaignId The id of the campaign for a donation.
     */
    function donate(uint campaignId) external payable onlyIfDonationValid(campaignId){
        campaigns[campaignId].moneyReceived += msg.value;

        emit donation(msg.sender, campaigns[campaignId].beneficiary, msg.value);
    }

    /**
     * @notice Get the information for the given campaign id.
     * @param campaignId The id of the campaign for a donation.
     * @return campaign The information - name, description, end time, money goal, money received, and address
     */
    function getCampaign(uint campaignId) external view returns(Campaign memory campaign) {
        return campaigns[campaignId];
    }

    /**
     * @dev Check the maximum allowed donation amount for the given campaign.
     * @param campaignId The id of the campaign for a donation.
     * @return allowed The boolean value depends on the maximum allowed donation.
     */
    function isDonationAmountAllowed(uint campaignId) private view returns (bool allowed) {
        Campaign memory campaign = campaigns[campaignId];
        uint maximumAllowedAmount = campaign.moneyGoal - campaign.moneyReceived;
        return msg.value <= maximumAllowedAmount ? true : false;
    }

    /**
     * @dev Check if the given campaign is closed.
     * @param campaignId The id of the campaign for a donation.
     * @return closed The boolean value regarding if campaign is active.
     */
    function isCampaginClosed(uint campaignId) private view returns (bool closed) {
        Campaign memory campaign = campaigns[campaignId];
        return campaign.timeGoal <= block.timestamp || (campaign.moneyGoal == campaign.moneyReceived);
    }
}