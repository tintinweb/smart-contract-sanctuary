pragma solidity ^0.4.14;

contract BountyBG {

    address public owner;

    uint256 public bountyCount = 0;
    uint256 public minBounty = 10 finney;
    uint256 public bountyFee = 2 finney;
    uint256 public bountyFeeCount = 0;
    uint256 public bountyBeneficiariesCount = 2;
    uint256 public bountyDuration = 30 hours;

    mapping(uint256 => Bounty) bountyAt;

    event BountyStatus(string _msg, uint256 _id, address _from, uint256 _amount);
    event RewardStatus(string _msg, uint256 _id, address _to, uint256 _amount);
    event ErrorStatus(string _msg, uint256 _id, address _to, uint256 _amount);

    struct Bounty {
        uint256 id;
        address owner;
        uint256 bounty;
        uint256 remainingBounty;
        uint256 startTime;
        uint256 endTime;
        bool ended;
        bool retracted;
    }

    function BountyBG() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // BLOCKGEEKS ACTIONS

    function withdrawFee(uint256 _amount) external onlyOwner {
        require(_amount <= bountyFeeCount);
        bountyFeeCount -= _amount;
        owner.transfer(_amount);
    }

    function setBountyDuration(uint256 _bountyDuration) external onlyOwner {
        bountyDuration = _bountyDuration;
    }

    function setMinBounty(uint256 _minBounty) external onlyOwner {
        minBounty = _minBounty;
    }

    function setBountyBeneficiariesCount(uint256 _bountyBeneficiariesCount) external onlyOwner {
        bountyBeneficiariesCount = _bountyBeneficiariesCount;
    }

    function rewardUsers(uint256 _bountyId, address[] _users, uint256[] _rewards) external onlyOwner {
        Bounty storage bounty = bountyAt[_bountyId];
        require(
            !bounty.ended &&
            !bounty.retracted &&
            bounty.startTime + bountyDuration > block.timestamp &&
            _users.length > 0 &&
            _users.length <= bountyBeneficiariesCount &&
            _users.length == _rewards.length
        );





        bounty.ended = true;
        bounty.endTime = block.timestamp;
        uint256 currentRewards = 0;
        for (uint8 i = 0; i < _rewards.length; i++) {
            currentRewards += _rewards[i];
        }





        require(bounty.bounty >= currentRewards);

        for (i = 0; i < _users.length; i++) {
            _users[i].transfer(_rewards[i]);
            RewardStatus("Reward sent", bounty.id, _users[i], _rewards[i]);
            /* if (_users[i].send(_rewards[i])) {
                bounty.remainingBounty -= _rewards[i];
                RewardStatus(&#39;Reward sent&#39;, bounty.id, _users[i], _rewards[i]);
            } else {
                ErrorStatus(&#39;Error in reward&#39;, bounty.id, _users[i], _rewards[i]);
            } */
        }
    }

    function rewardUser(uint256 _bountyId, address _user, uint256 _reward) external onlyOwner {
        Bounty storage bounty = bountyAt[_bountyId];
        require(bounty.remainingBounty >= _reward);
        bounty.remainingBounty -= _reward;

        bounty.ended = true;
        bounty.endTime = block.timestamp;
        
        _user.transfer(_reward);
        RewardStatus(&#39;Reward sent&#39;, bounty.id, _user, _reward);
    }

    // USER ACTIONS TRIGGERED BY METAMASK

    function createBounty(uint256 _bountyId) external payable {
        require(
            msg.value >= minBounty + bountyFee
        );
        Bounty storage bounty = bountyAt[_bountyId];
        require(bounty.id == 0);
        bountyCount++;
        bounty.id = _bountyId;
        bounty.bounty = msg.value - bountyFee;
        bounty.remainingBounty = bounty.bounty;
        bountyFeeCount += bountyFee;
        bounty.startTime = block.timestamp;
        bounty.owner = msg.sender;
        BountyStatus(&#39;Bounty submitted&#39;, bounty.id, msg.sender, msg.value);
    }

    function cancelBounty(uint256 _bountyId) external {
        Bounty storage bounty = bountyAt[_bountyId];
        require(
            msg.sender == bounty.owner &&
            !bounty.ended &&
            !bounty.retracted &&
            bounty.owner == msg.sender &&
            bounty.startTime + bountyDuration < block.timestamp
        );
        bounty.ended = true;
        bounty.retracted = true;
        bounty.owner.transfer(bounty.bounty);
        BountyStatus(&#39;Bounty was canceled&#39;, bounty.id, msg.sender, bounty.bounty);
    }


    // CUSTOM GETTERS

    function getBalance() external view returns (uint256) {
        return this.balance;
    }

    function getBounty(uint256 _bountyId) external view
    returns (uint256, address, uint256, uint256, uint256, uint256, bool, bool) {
        Bounty memory bounty = bountyAt[_bountyId];
        return (
            bounty.id,
            bounty.owner,
            bounty.bounty,
            bounty.remainingBounty,
            bounty.startTime,
            bounty.endTime,
            bounty.ended,
            bounty.retracted
        );
    }

}