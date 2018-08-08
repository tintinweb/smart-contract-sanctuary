pragma solidity ^0.4.24;


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


/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param info The contact information to attach to the contract.
    */
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}


/**
 *  @title MonethaUsers
 *
 *  MonethaUsers stores basic user information, i.e. his nickname and reputation score
 */
contract MonethaUsers is Contactable {
    
    string constant VERSION = "0.1";
    
    struct User {
        string name;
        uint256 starScore;
        uint256 reputationScore;
        uint256 signedDealsCount;
    }
    mapping (address => User) public users;
    event UpdatedSignedDealsCount(address indexed _userAddress, uint256 _newSignedDealsCount);
    event UpdatedStarScore(address indexed _userAddress, uint256 _newStarScore);
    event UpdatedReputationScore(address indexed _userAddress, uint256 _newReputationScore);
    event UpdatedName(address indexed _userAddress, string _newName);
    event UpdatedTrustScore(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore);
    event UserRegistered(address indexed _userAddress, string _name, uint256 _starScore, uint256 _reputationScore, uint256 _signedDealsCount);
    event UpdatedUserDetails(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore, uint256 _newSignedDealsCount);
    event UpdatedUser(address indexed _userAddress, string _name, uint256 _newStarScore, uint256 _newReputationScore, uint256 _newSignedDealsCount);
    /**
     *  registerUser associates a Monetha user&#39;s ethereum address with his nickname and trust score
     *  @param _userAddress address of user&#39;s wallet
     *  @param _name corresponds to use&#39;s nickname
     *  @param _starScore represents user&#39;s star score
     *  @param _reputationScore represents user&#39;s reputation score
     *  @param _signedDealsCount represents user&#39;s signed deal count
     */
    function registerUser(address _userAddress, string _name, uint256 _starScore, uint256 _reputationScore, uint256 _signedDealsCount)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.name = _name;
        user.starScore = _starScore;
        user.reputationScore = _reputationScore;
        user.signedDealsCount = _signedDealsCount;
        emit UserRegistered(_userAddress, _name, _starScore, _reputationScore, _signedDealsCount);
    }
    /**
     *  updateStarScore updates the star score of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedStars represents user&#39;s new star score
     */
    function updateStarScore(address _userAddress, uint256 _updatedStars)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.starScore = _updatedStars;
        emit UpdatedStarScore(_userAddress, _updatedStars);
    }
    /**
     *  updateStarScoreInBulk updates the star score of Monetha users in bulk
     */
    function updateStarScoreInBulk(address[] _userAddresses, uint256[] _starScores)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);
        for (uint16 i = 0; i < _userAddresses.length; i++) {
            User storage user = users[_userAddresses[i]];
            user.starScore = _starScores[i];
            emit UpdatedStarScore(_userAddresses[i], _starScores[i]);
        }
    }
    /**
     *  updateReputationScore updates the reputation score of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedReputation represents user&#39;s new reputation score
     */
    function updateReputationScore(address _userAddress, uint256 _updatedReputation)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.reputationScore = _updatedReputation;
        emit UpdatedReputationScore(_userAddress, _updatedReputation);
    }
    /**
     *  updateReputationScoreInBulk updates the reputation score of a Monetha users in bulk
     */
    function updateReputationScoreInBulk(address[] _userAddresses, uint256[] _reputationScores)
        external onlyOwner
    {
        require(_userAddresses.length == _reputationScores.length);
        for (uint16 i = 0; i < _userAddresses.length; i++) {
            User storage user = users[_userAddresses[i]];
            user.reputationScore = _reputationScores[i];
            emit UpdatedReputationScore(_userAddresses[i],  _reputationScores[i]);
        }
    }
    /**
     *  updateTrustScore updates the trust score of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedStars represents user&#39;s new star score
     *  @param _updatedReputation represents user&#39;s new reputation score
     */
    function updateTrustScore(address _userAddress, uint256 _updatedStars, uint256 _updatedReputation)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.starScore = _updatedStars;
        user.reputationScore = _updatedReputation;
        emit UpdatedTrustScore(_userAddress, _updatedStars, _updatedReputation);
    }
     /**
     *  updateTrustScoreInBulk updates the trust score of Monetha users in bulk
     */
    function updateTrustScoreInBulk(address[] _userAddresses, uint256[] _starScores, uint256[] _reputationScores)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);
        require(_userAddresses.length == _reputationScores.length);
        for (uint16 i = 0; i < _userAddresses.length; i++) {
            User storage user = users[_userAddresses[i]];
            user.starScore = _starScores[i];
            user.reputationScore = _reputationScores[i];
            emit UpdatedTrustScore(_userAddresses[i], _starScores[i], _reputationScores[i]);
        }
    }
    /**
     *  updateSignedDealsCount updates the star score of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedSignedDeals represents user&#39;s new signed deals
     */
    function updateSignedDealsCount(address _userAddress, uint256 _updatedSignedDeals)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.signedDealsCount = _updatedSignedDeals;
        emit UpdatedSignedDealsCount(_userAddress, _updatedSignedDeals);
    }
    /**
     *  updateUserDetailsInBulk updates the trust score and signed deals countof Monetha users in bulk
     */
    function updateUserDetailsInBulk(address[] _userAddresses, uint256[] _starScores, uint256[] _reputationScores, uint256[] _signedDealsCount)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);
        require(_userAddresses.length == _reputationScores.length);
        require(_userAddresses.length == _signedDealsCount.length);
        for (uint16 i = 0; i < _userAddresses.length; i++) {
            User storage user = users[_userAddresses[i]];
            user.starScore = _starScores[i];
            user.reputationScore = _reputationScores[i];
            user.signedDealsCount = _signedDealsCount[i];
            emit UpdatedUserDetails(_userAddresses[i], _starScores[i], _reputationScores[i], _signedDealsCount[i]);
        }
    }
    /**
     *  updateName updates the name of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedName represents user&#39;s new nick name
     */
    function updateName(address _userAddress, string _updatedName)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.name = _updatedName;
        emit UpdatedName(_userAddress, _updatedName);
    }
    function updateUser(address _userAddress, string _updatedName, uint256 _updatedStarScore, uint256 _updatedReputationScore, uint256 _updatedSignedDealsCount)
        external onlyOwner
    {
        User storage user = users[_userAddress];
        user.name = _updatedName;
        user.starScore = _updatedStarScore;
        user.reputationScore = _updatedReputationScore;
        user.signedDealsCount = _updatedSignedDealsCount;
        emit UpdatedUser(_userAddress, _updatedName, _updatedStarScore, _updatedReputationScore, _updatedSignedDealsCount);
    }
}