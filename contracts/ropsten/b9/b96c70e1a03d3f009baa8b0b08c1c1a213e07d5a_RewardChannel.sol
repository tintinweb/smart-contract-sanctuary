pragma solidity ^0.4.21;

// Reward Channel contract

interface token {
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _owner) external constant returns (uint balance);
}

contract RewardChannel {
    address public owner = msg.sender;
    address public faucet;

    struct Recipient {
        bool rewarded;
        uint latestEntryBlock;
    }

    struct Channel {
        bool started;
        uint capacity;
        uint headcount;
        uint blockInterval;
        mapping (address => Recipient) recipients;
    }

    mapping(bytes32 => Channel) public channels;

    token public tokenReward;

    event ChannelCreated(bytes32 indexed channelId, uint256 capacity);
    event ParticipantRewarded(bytes32 indexed channelId, address indexed user, uint256 value);

    modifier onlyBy(address _account) {require(msg.sender == _account); _;}

    function RewardChannel( address addressOfTokenUsedAsReward, address faucetAddress) public {
        faucet = faucetAddress;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    function() payable public {}

    // channel id 
    // keccak256((address channelFunder, string model, uint capacity))

    function createChannel(bytes32 _channelId, uint _capacity, uint _blockInterval) payable
      onlyBy(faucet)
      public
    {
        Channel storage channel = channels[_channelId];
        require(!channel.started);
        channel.started = true;
        channel.blockInterval = _blockInterval;
        channel.capacity = _capacity;
        channels[_channelId] = channel;
        emit ChannelCreated(_channelId, _capacity);
    }

    function reward(address _user, bytes32 _channelId, uint rewardBlock)
      onlyBy(faucet)
      public
    {
        Channel storage _channel = channels[_channelId];
        Recipient storage _recipient = _channel.recipients[_user];
        require(rewardBlock - _recipient.latestEntryBlock > _channel.blockInterval);
        require(_channel.headcount < _channel.capacity);
        _channel.headcount += 1;
        _recipient.rewarded = true;
        _recipient.latestEntryBlock = block.number;
        uint tokenRewardAmount = 1 ether;
        tokenReward.transfer(_user, tokenRewardAmount);
        emit ParticipantRewarded(_channelId, _user, tokenRewardAmount);
    }

    // function reward(bytes32 h, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _channelId, uint amount)
    //   onlyIfSolvent()
    //   public
    // {
    //     address signer = ecrecover(h, _v, _r, _s);

    //     require(signer == faucet);


    //     bytes32 proof = keccak256(faucet, _channelId, amount);
    //     require(proof == h);

    //     Channel storage _channel = channels[_channelId];
    //     Recipient storage _recipient = _channel.recipients[msg.sender];
    //     require(!_recipient.rewarded && _channel.headcount < _channel.capacity);
    //     _channel.headcount += 1;
    //     numberOfParticipants += 1;
    //     _recipient.rewarded = true;
    //     uint tokenRewardAmount = 1 ether * amount;
    //     tokenReward.transfer(msg.sender, tokenRewardAmount);
    //     ParticipantRewarded(_channelId, msg.sender, tokenRewardAmount);
    // }

    // function verifyHash(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) 
    //   public
    //   pure
    //   returns (address) 
    // {
    // //   bytes32 channelData = keccak256(_hash, _h);
    //     address signer = ecrecover(_hash, _v, _r, _s);
    //     return signer;
    // }

    function withdraw()
      onlyBy(owner)
      public
    {
        address contractAddress = this;
        owner.transfer(contractAddress.balance);
    }

    function destroy() onlyBy(owner) public {
        selfdestruct(this);
    }
}