pragma solidity ^0.4.24;

// File: contracts/socialtrading/libs/LibUserInfo.sol

contract LibUserInfo {
  struct Following {
    address leader;
    uint percentage; // percentage (100 = 100%)
    uint index;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/socialtrading/interfaces/ISocialTrading.sol

contract ISocialTrading is Ownable {

  /**
   * @dev Follow leader to copy trade.
   */
  function follow(address _leader, uint8 _percentage) external;

  /**
   * @dev UnFollow leader to stop copy trade.
   */
  function unfollow(address _leader) external;

  /**
  * Friends - we refer to "friends" as the users that a specific user follows (e.g., following).
  */
  function getFriends(address _user) public view returns (address[]);

  /**
  * Followers - refers to the users that follow a specific user.
  */
  function getFollowers(address _user) public view returns (address[]);
}

// File: contracts/socialtrading/SocialTrading.sol

contract SocialTrading is ISocialTrading {
  mapping(address => mapping(address => LibUserInfo.Following)) public followerToLeaders; // Following list
  mapping(address => address[]) public followerToLeadersIndex; // Following list
  mapping(address => mapping(address => uint8)) public leaderToFollowers;
  mapping(address => address[]) public leaderToFollowersIndex; // Follower list

  event Follow(address indexed leader, address indexed follower, uint percentage);
  event UnFollow(address indexed leader, address indexed follower);

  function() public {
    revert();
  }

  /**
   * @dev Follow leader to copy trade.
   */
  function follow(address _leader, uint8 _percentage) external {
    require(getCurrentPercentage(msg.sender) + _percentage <= 100, "Following percentage more than 100%.");
    uint8 index = uint8(followerToLeadersIndex[msg.sender].push(_leader) - 1);
    followerToLeaders[msg.sender][_leader] = LibUserInfo.Following(
      _leader,
      _percentage,
      index
    );

    uint8 index2 = uint8(leaderToFollowersIndex[_leader].push(msg.sender) - 1);
    leaderToFollowers[_leader][msg.sender] = index2;
    emit Follow(_leader, msg.sender, _percentage);
  }

  /**
   * @dev UnFollow leader to stop copy trade.
   */
  function unfollow(address _leader) external {
    _unfollow(msg.sender, _leader);
  }

  function _unfollow(address _follower, address _leader) private {
    uint8 rowToDelete = uint8(followerToLeaders[_follower][_leader].index);
    address keyToMove = followerToLeadersIndex[_follower][followerToLeadersIndex[_follower].length - 1];
    followerToLeadersIndex[_follower][rowToDelete] = keyToMove;
    followerToLeaders[_follower][keyToMove].index = rowToDelete;
    followerToLeadersIndex[_follower].length -= 1;

    uint8 rowToDelete2 = uint8(leaderToFollowers[_leader][_follower]);
    address keyToMove2 = leaderToFollowersIndex[_leader][leaderToFollowersIndex[_leader].length - 1];
    leaderToFollowersIndex[_leader][rowToDelete2] = keyToMove2;
    leaderToFollowers[_leader][keyToMove2] = rowToDelete2;
    leaderToFollowersIndex[_leader].length -= 1;
    emit UnFollow(_leader, _follower);
  }

  function getFriends(address _user) public view returns (address[]) {
    address[] memory result = new address[](followerToLeadersIndex[_user].length);
    uint counter = 0;
    for (uint i = 0; i < followerToLeadersIndex[_user].length; i++) {
      result[counter] = followerToLeadersIndex[_user][i];
      counter++;
    }
    return result;
  }

  function getFollowers(address _user) public view returns (address[]) {
    address[] memory result = new address[](leaderToFollowersIndex[_user].length);
    uint counter = 0;
    for (uint i = 0; i < leaderToFollowersIndex[_user].length; i++) {
      result[counter] = leaderToFollowersIndex[_user][i];
      counter++;
    }
    return result;
  }

  function getCurrentPercentage(address _user) internal returns (uint) {
    uint sum = 0;
    for (uint i = 0; i < followerToLeadersIndex[_user].length; i++) {
      address leader = followerToLeadersIndex[_user][i];
      sum += followerToLeaders[_user][leader].percentage;
    }
    return sum;
  }
}