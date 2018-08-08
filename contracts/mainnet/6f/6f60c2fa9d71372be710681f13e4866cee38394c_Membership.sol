pragma solidity ^0.4.21;

// zeppelin-solidity: 1.9.0

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Membership is Ownable {
  using SafeMath for uint;

  mapping(address => bool) public isAdmin;
  mapping(address => uint) public userToMemberIndex;
  mapping(uint => uint[]) public tierToMemberIndexes;

  struct Member {
    address addr;
    uint tier;
    uint tierIndex;
    uint memberIndex;
  }

  Member[] private members;

  event NewMember(address user, uint tier);
  event UpdatedMemberTier(address user, uint oldTier, uint newTier);
  event RemovedMember(address user, uint tier);

  modifier onlyAdmin() {
    require(isAdmin[msg.sender]);
    _;
  }

  modifier isValidTier(uint _tier) {
    require(_tier >= 1 && _tier <= 4);
    _;
  }

  modifier notTryingToChangeFromTier1(address _user, uint _tier) {
    require(members[userToMemberIndex[_user]].tier != _tier);
    _;
  }


  modifier isMember(address _user) {
    require(userToMemberIndex[_user] != 0);
    _;
  }

  modifier isValidAddr(address _trgt) {
    require(_trgt != address(0));
    _;
  }

  constructor() public {
    Member memory member = Member(address(0), 0, 0, 0);
    members.push(member);
  }

  function addAdmin(address _user)
    external
    onlyOwner
  {
    isAdmin[_user] = true;
  }

  function removeMember(address _user)
    external
    onlyAdmin
    isValidAddr(_user)
    isMember(_user)
  {
    uint index = userToMemberIndex[_user];
    require(index != 0);

    Member memory removingMember = members[index];

    uint tier = removingMember.tier;

    uint lastTierIndex = tierToMemberIndexes[removingMember.tier].length - 1;
    uint lastTierMemberIndex = tierToMemberIndexes[removingMember.tier][lastTierIndex];
    Member storage lastTierMember = members[lastTierMemberIndex];
    lastTierMember.tierIndex = removingMember.tierIndex;
    tierToMemberIndexes[removingMember.tier][removingMember.tierIndex] = lastTierMember.memberIndex;
    tierToMemberIndexes[removingMember.tier].length--;

    Member storage lastMember = members[members.length - 1];
    if (lastMember.addr != removingMember.addr) {
      userToMemberIndex[lastMember.addr] = removingMember.memberIndex;
      tierToMemberIndexes[lastMember.tier][lastMember.tierIndex] = removingMember.memberIndex;
      lastMember.memberIndex = removingMember.memberIndex;
      members[removingMember.memberIndex] = lastMember;
    }
    userToMemberIndex[removingMember.addr] = 0;
    members.length--;

    emit RemovedMember(_user, tier);
  }

  function addNewMember(address _user, uint _tier)
    internal
  {
    // it&#39;s a new member
    uint memberIndex = members.length; // + 1; // add 1 to keep index 0 unoccupied
    uint tierIndex = tierToMemberIndexes[_tier].length;

    Member memory newMember = Member(_user, _tier, tierIndex, memberIndex);

    members.push(newMember);
    userToMemberIndex[_user] = memberIndex;
    tierToMemberIndexes[_tier].push(memberIndex);

    emit NewMember(_user, _tier);
  }

  function updateExistingMember(address _user, uint _newTier)
    internal
  {
    // this user is a member in another tier, remove him from that tier,
    // and add him to the new tier
    Member storage existingMember = members[userToMemberIndex[_user]];

    uint oldTier = existingMember.tier;
    uint tierIndex = existingMember.tierIndex;
    uint lastTierIndex = tierToMemberIndexes[oldTier].length - 1;

    if (tierToMemberIndexes[oldTier].length > 1 && tierIndex != lastTierIndex) {
      Member storage lastMember = members[tierToMemberIndexes[oldTier][lastTierIndex]];
      tierToMemberIndexes[oldTier][tierIndex] = lastMember.memberIndex;
      lastMember.tierIndex = tierIndex;
    }

    tierToMemberIndexes[oldTier].length--;
    tierToMemberIndexes[_newTier].push(existingMember.memberIndex);

    existingMember.tier = _newTier;
    existingMember.tierIndex = tierToMemberIndexes[_newTier].length - 1;

    emit UpdatedMemberTier(_user, oldTier, _newTier);
  }

  function setMemberTier(address _user, uint _tier)
    external
    onlyAdmin
    isValidAddr(_user)
    isValidTier(_tier)
  {
    if (userToMemberIndex[_user] == 0) {
      addNewMember(_user, _tier);
    } else {
      uint currentTier = members[userToMemberIndex[_user]].tier;
      if (currentTier != _tier) {
        // user&#39;s in tier 1 are lifetime tier 1 users
        require(currentTier != 1);

        updateExistingMember(_user, _tier);
      }
    }
  }

  function getTierOfMember(address _user)
    external
    view
    returns (uint)
  {
    return members[userToMemberIndex[_user]].tier;
  }

  function getMembersOfTier(uint _tier)
    external
    view
    returns (address[])
  {
    address[] memory addressesOfTier = new address[](tierToMemberIndexes[_tier].length);

    for (uint i = 0; i < tierToMemberIndexes[_tier].length; i++) {
      addressesOfTier[i] = members[tierToMemberIndexes[_tier][i]].addr;
    }

    return addressesOfTier;
  }

  function getMembersOfTierCount(uint _tier)
    external
    view
    returns (uint)
  {
    return tierToMemberIndexes[_tier].length;
  }

  function getMembersCount()
    external
    view
    returns (uint)
  {
    if (members.length == 0) {
      return 0;
    } else {
      // remove sentinel at index zero from count
      return members.length - 1;
    }
  }

  function getMemberByIdx(uint _idx)
    external
    view
    returns (address, uint)
  {
    Member memory member = members[_idx];

    return (member.addr, member.tier);
  }

  function isUserMember(address _user)
    external
    view
    returns (bool)
  {
    return userToMemberIndex[_user] != 0;
  }

  function getMemberIdxOfUser(address _user)
    external
    view
    returns (uint)
  {
    return userToMemberIndex[_user];
  }
}