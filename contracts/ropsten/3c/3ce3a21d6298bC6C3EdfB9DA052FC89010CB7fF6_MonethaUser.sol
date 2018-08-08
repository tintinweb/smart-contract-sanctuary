pragma solidity ^0.4.23;

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
 *  @title MonethaUser
 *
 *  MonethaUser stores basic user information, i.e. his nickname and reputation score
 */
contract MonethaUser is Contactable {
    struct User {
        string name;
        uint256 starScore;
        uint256 reputationScore;
    }

    mapping (address => User) public users;

    event UpdatedStarScore(address indexed _userAddress, uint256 _newStarScore);
    event UpdatedReputationScore(address indexed _userAddress, uint256 _newReputationScore);
    event UpdatedName(address indexed _userAddress, string _newName);
    event UpdatedTrustScore(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore);
    event UserRegistered(address indexed _userAddress, string _name, uint256 _starScore, uint256 _reputationScore);

    /**
     *  registerUser associates a Monetha user&#39;s ethereum address with his nickname and trust score
     *  @param _userAddress address of user&#39;s wallet
     *  @param _name corresponds to use&#39;s nickname
     *  @param _starScore represents user&#39;s star score
     *  @param _reputationScore represents user&#39;s reputation score
     */
    function registerUser(address _userAddress, string _name, uint256 _starScore, uint256 _reputationScore)
        external onlyOwner
    {
        User storage user = users[_userAddress];

        user.name = _name;
        user.starScore = _starScore;
        user.reputationScore = _reputationScore;

        emit UserRegistered(_userAddress, _name, _starScore, _reputationScore);
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
}