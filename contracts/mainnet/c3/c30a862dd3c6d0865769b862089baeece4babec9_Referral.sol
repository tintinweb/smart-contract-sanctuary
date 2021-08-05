/*
@website https://boogie.finance
@authors Boogie
*/
pragma solidity ^0.6.12;

import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './BOOGIE.sol';
import './Bar.sol';

//250k tokens are trustlessly minted at Bar and then sent here to be distributed as referral/recruitment incentives
contract Referral {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The BOOGIE TOKEN!
    BOOGIE public boogie;
     // The Bar contract
    Bar public bar;

    // Max number of people that can be referred
    // Referral rewards are limited by the # of tokens sent to this contract anyway
    // Also, not having a max referral # prevents people from signing up and never claiming to prevent others from claiming rewards
    // It is possible that the contract could run dry, but the website will have a check for that
    //uint256 internal constant MAX_REFERRALS = 2500;
    // Reward for being referred by someone
    uint256 internal constant REFERRAL_REWARD = 50 * 10**18;
    // Commission reward for recruiting people
    uint256 internal constant COMMISSION_REWARD = 50 * 10**18;
    // Min amount of tokens that need to be claimed in order to claim REFERRAL_REWARD
    uint256 internal constant MIN_CLAIM_FOR_REFERRAL = 500 * 10**18;


    // Mapping of address -> person who referred that address
    mapping(address => address) public referredBy;
    // Whether an address has referred anyone
    mapping(address => bool) public hasReferred;
    // Whether an address has claimed the tokens from being referred
    mapping(address => bool) public claimedReferredTokens;
    // Number of pending referral rewards from recruiting people that have claimed tokens with claimTokensFromBeingReferred() 
    mapping(address => uint256) public pendingReferralRewards;
    // Number of people an address has recruited
    mapping(address => uint256) public numRecruited;
    // Total number of people recruited
    uint256 numPeopleReferred = 0;

    constructor(
        BOOGIE _boogie,
        Bar _bar
    ) public {
        boogie = _boogie;
        bar = _bar;
    }

    // Internal function to safely transfer BOOGIE in case there is a rounding error
    function _safeBoogieTransfer(address _to, uint256 _amount) internal {
        uint256 boogieBalance = boogie.balanceOf(address(this));
        if (_amount > boogieBalance) _amount = boogieBalance;
        boogie.transfer(_to, _amount);
    }

    function getNumPeopleRecruitedBy(address _user) public view returns(uint256) {
        return numRecruited[_user];
    }

    // Returns whether the user has any pending rewards from recruiting users that farmed enough tokens to claim tokens from claimTokensFromBeingReferred() 
    function getNumPendingReferralRewards(address _user) public view returns(uint256) {
        return pendingReferralRewards[_user];
    }

    // Returns whether the user has claimed the one-time reward for being referred
    function hasClaimedTokensFromBeingReferred(address _user) public view returns(bool) {
        return claimedReferredTokens[_user];
    }

    // Returns the person who recruited the sender
    function getReferrer(address _user) public view returns(address) {
        return referredBy[_user];
    }

    function getReferralDataFor(address _user) public view returns (address, bool, uint256, uint256, uint256) {
        return (referredBy[_user], claimedReferredTokens[_user], numRecruited[_user], pendingReferralRewards[_user], numPeopleReferred);
    }

    // Claims the one-time reward for being referred after farming enough tokens
    function claimTokensFromBeingReferred() public {
        require(msg.sender == tx.origin, "no contracts");
        require(referredBy[msg.sender] != address(0), "not referred by anyone");
        require(claimedReferredTokens[msg.sender] == false, "already claimed");

        uint256 totalClaimedAmount = bar.getTotalNumTokensClaimed(msg.sender);

        require(totalClaimedAmount >= MIN_CLAIM_FOR_REFERRAL, "insufficient tokens claimed");

        address referrer = referredBy[msg.sender];
        claimedReferredTokens[msg.sender] = true;
        pendingReferralRewards[referrer] += 1;
        _safeBoogieTransfer(msg.sender, REFERRAL_REWARD);
    }

    function claimRecruitmentRewards() public {
        require(msg.sender == tx.origin, "no contracts");
        require(pendingReferralRewards[msg.sender] > 0, "no rewards to claim");
        uint256 numPending = pendingReferralRewards[msg.sender];
        uint256 rewardAmt = numPending.mul(COMMISSION_REWARD);

        pendingReferralRewards[msg.sender] = 0;
        _safeBoogieTransfer(msg.sender, rewardAmt);
    }

    // Records that _referrer recruited msg.sender, and that _referrer has recruited someone
    // Any user that has recruited someone cannot be referred by someone else
    function refer(address _referrer) public {
        require(msg.sender == tx.origin, "no contracts");
        require(referredBy[msg.sender] == address(0), "already referred by someone");
        require(!hasReferred[msg.sender], "already referred someone"); //to prevent person A from referring person B and then person B referring person A
        require(_referrer != msg.sender, "cannot refer self");
        require(_referrer != address(0), "cannot refer null address");
        //require(numPeopleReferred < MAX_REFERRALS, "referral limit reached");
        
        numPeopleReferred.add(1);
        numRecruited[_referrer] += 1;
        referredBy[msg.sender] = _referrer;
        hasReferred[_referrer] = true;
    }
}