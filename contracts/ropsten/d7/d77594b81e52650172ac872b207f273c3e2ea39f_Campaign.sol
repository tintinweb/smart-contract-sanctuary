pragma solidity ^0.4.11;

interface ERC20Token {
  function balanceOf(address _owner) public view returns (uint256);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }
}

contract Campaign is Ownable, SafeMath {

  uint256 public cid;
  string public name;
  uint256 public startTime;
  uint256 public endTime;

  uint8 public rewardType; // 0：无奖励，保留  1：奖励erc20 token  2：奖励erc721 token
  address public rewardTokenContract;
  uint256 public rewardAmountPerClaim; //unit with decimals
  uint256 public totalRewardAmount; //

  string public metaUrl;

  mapping(address => string) public rewardedRecords;
  uint256 public claimedAmount; // amount of claimed
  bool public rewardGoalReached = false;

  bool public paused = false;

  constructor(
    uint256 _cid,
    string _name,
    uint256 _startTime,
    uint256 _endTime,
    uint8 _rewardType,
    address _rewardTokenContract,
    uint256 _rewardAmountPerClaim,
    uint256 _totalRewardAmount,
    string _metaUrl
    ) {
    cid = _cid;
    name = _name;
    startTime = _startTime;
    endTime = _endTime;
    rewardType = _rewardType;
    rewardTokenContract = _rewardTokenContract;
    rewardAmountPerClaim = _rewardAmountPerClaim;
    totalRewardAmount = _totalRewardAmount;
    metaUrl = _metaUrl;
  }



  /// @dev Modifier to allow actions only when the contract IS NOT paused
  modifier whenNotPaused() {
      require(!paused);
      _;
  }

  /// @dev Modifier to allow actions only when the contract IS paused
  modifier whenPaused {
      require(paused);
      _;
  }

  function pause() public whenNotPaused onlyOwner {
      paused = true;
  }

  function unpause() public whenPaused onlyOwner {
      // can&#39;t unpause if contract was upgraded
      paused = false;
  }


  modifier onlyOpening() {
    require(!paused);
    require ( now >= startTime && now <= endTime
      && !rewardGoalReached);

    // check balance
      _;
  }

  function isOpening() public view returns (bool) {
    
  }

  function updateMeta(uint256 _newStartTime, uint256 _newEndTime, string _newMetaUrl) returns (bool) {
    require(_newEndTime > _newStartTime);

    startTime = _newStartTime;
    endTime = _newEndTime;
    metaUrl = _newMetaUrl;

    emit UpdateMeta(_newMetaUrl);
    return true;
  }

  function claimReward(address _owner, string _reason) public onlyOpening returns (bool) {
    require(_owner != address(0));

    bool result = false;
    if (rewardType == 1) {
      result = _claimReward20(_owner, _reason);
    }
    else if (rewardType == 2) {
      result = _claimReward721(_owner, _reason);
    }
    else {
      result = _claimRewardBlank(_owner, _reason);
    }

    if (result) {
      rewardedRecords[_owner] = _reason;
      emit ClaimReward(_owner, _reason);

      claimedAmount = safeAdd(claimedAmount, rewardAmountPerClaim);

      if (claimedAmount >= totalRewardAmount) {
        rewardGoalReached = true;
        emit GoalReached();
      }
    }
  }

  function _claimReward20(address _owner, string _reason) internal returns (bool) {
    ERC20Token token = ERC20Token(rewardTokenContract);
    require(token.transfer(_owner, rewardAmountPerClaim));

    return true;
  }

  function _claimReward721(address _owner, string _reason) internal returns (bool) {
    // TODO  mint erc721 token
    return true;
  }

  function _claimRewardBlank(address _owner, string _reason) internal returns (bool) {
    return true;
  }

  /// Withdraw erc20 tokens
  function refundTokens(address _recipient, address _token) public onlyOwner {
    require(_recipient != address(0));
    require(_token != address(0));

    ERC20Token token = ERC20Token(_token);
    uint256 balance = token.balanceOf(this);
    require(token.transfer(_recipient, balance));
  }

  /// Withdraw ethers
  function refundEther(address _recipient) public onlyOwner {
    require(_recipient != address(0));

    uint256 balance = address(this).balance;
    require(balance > 0);
    _recipient.transfer(balance);
  }

  event UpdateMeta(string _meta);
  event ClaimReward(address indexed _owner, string _reason);
  event GoalReached();
}