pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/ownership/Contactable.sol

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable{

    string public contactInformation;

    /**
     * @dev Allows the owner to set a string with their contact information.
     * @param info The contact information to attach to the contract.
     */
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

// File: contracts/MonethaUsers.sol

/**
 *  @title MonethaUsers
 *
 *  MonethaUsers stores basic user information, i.e. his nickname and reputation score
 */
contract MonethaUsers is Contactable {

    using SafeMath for uint256;

    string constant VERSION = "0.1";

    struct User {
        string name;
        uint256 starScore;
        uint256 reputationScore;
        uint256 signedDealsCount;
        string nickname;
        bool isVerified;
    }

    mapping (address => User) public users;

    event UpdatedSignedDealsCount(address indexed _userAddress, uint256 _newSignedDealsCount);
    event UpdatedStarScore(address indexed _userAddress, uint256 _newStarScore);
    event UpdatedReputationScore(address indexed _userAddress, uint256 _newReputationScore);
    event UpdatedNickname(address indexed _userAddress, string _newNickname);
    event UpdatedIsVerified(address indexed _userAddress, bool _newIsVerified);
    event UpdatedName(address indexed _userAddress, string _newName);
    event UpdatedTrustScore(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore);
    event UserRegistered(address indexed _userAddress, string _name, uint256 _starScore, uint256 _reputationScore, uint256 _signedDealsCount, string _nickname, bool _isVerified);
    event UpdatedUserDetails(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore, uint256 _newSignedDealsCount, bool _newIsVerified);
    event UpdatedUser(address indexed _userAddress, string _name, uint256 _newStarScore, uint256 _newReputationScore, uint256 _newSignedDealsCount, string _newNickname, bool _newIsVerified);

    /**
     *  registerUser associates a Monetha user&#39;s ethereum address with his nickname and trust score
     *  @param _userAddress address of user&#39;s wallet
     *  @param _name corresponds to use&#39;s nickname
     *  @param _starScore represents user&#39;s star score
     *  @param _reputationScore represents user&#39;s reputation score
     *  @param _signedDealsCount represents user&#39;s signed deal count
     *  @param _nickname represents user&#39;s nickname
     *  @param _isVerified represents whether user is verified (KYC&#39;ed)
     */
    function registerUser(address _userAddress, string _name, uint256 _starScore, uint256 _reputationScore, uint256 _signedDealsCount, string _nickname, bool _isVerified)
        external onlyOwner
    {
        User storage user = users[_userAddress];

        user.name = _name;
        user.starScore = _starScore;
        user.reputationScore = _reputationScore;
        user.signedDealsCount = _signedDealsCount;
        user.nickname = _nickname;
        user.isVerified = _isVerified;

        emit UserRegistered(_userAddress, _name, _starScore, _reputationScore, _signedDealsCount, _nickname, _isVerified);
    }

    /**
     *  updateStarScore updates the star score of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedStars represents user&#39;s new star score
     */
    function updateStarScore(address _userAddress, uint256 _updatedStars)
        external onlyOwner
    {
        users[_userAddress].starScore = _updatedStars;

        emit UpdatedStarScore(_userAddress, _updatedStars);
    }

    /**
     *  updateStarScoreInBulk updates the star score of Monetha users in bulk
     */
    function updateStarScoreInBulk(address[] _userAddresses, uint256[] _starScores)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].starScore = _starScores[i];

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
        users[_userAddress].reputationScore = _updatedReputation;

        emit UpdatedReputationScore(_userAddress, _updatedReputation);
    }

    /**
     *  updateReputationScoreInBulk updates the reputation score of a Monetha users in bulk
     */
    function updateReputationScoreInBulk(address[] _userAddresses, uint256[] _reputationScores)
        external onlyOwner
    {
        require(_userAddresses.length == _reputationScores.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].reputationScore = _reputationScores[i];

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
        users[_userAddress].starScore = _updatedStars;
        users[_userAddress].reputationScore = _updatedReputation;

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

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].starScore = _starScores[i];
            users[_userAddresses[i]].reputationScore = _reputationScores[i];

            emit UpdatedTrustScore(_userAddresses[i], _starScores[i], _reputationScores[i]);
        }
    }

    /**
     *  updateSignedDealsCount updates the signed deals count of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedSignedDeals represents user&#39;s new signed deals count
     */
    function updateSignedDealsCount(address _userAddress, uint256 _updatedSignedDeals)
        external onlyOwner
    {
        users[_userAddress].signedDealsCount = _updatedSignedDeals;

        emit UpdatedSignedDealsCount(_userAddress, _updatedSignedDeals);
    }

    /**
     *  updateSignedDealsCountInBulk updates the signed deals count of Monetha users in bulk
     */
    function updateSignedDealsCountInBulk(address[] _userAddresses, uint256[] _updatedSignedDeals)
        external onlyOwner
    {
        require(_userAddresses.length == _updatedSignedDeals.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].signedDealsCount = _updatedSignedDeals[i];

            emit UpdatedSignedDealsCount(_userAddresses[i], _updatedSignedDeals[i]);
        }
    }

    /**
     *  updateNickname updates user&#39;s nickname
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedNickname represents user&#39;s new nickname
     */
    function updateNickname(address _userAddress, string _updatedNickname)
        external onlyOwner
    {
        users[_userAddress].nickname = _updatedNickname;

        emit UpdatedNickname(_userAddress, _updatedNickname);
    }

    /**
     *  updateIsVerified updates user&#39;s verified status
     *  @param _userAddress address of user&#39;s wallet
     *  @param _isVerified represents user&#39;s new verification status
     */
    function updateIsVerified(address _userAddress, bool _isVerified)
        external onlyOwner
    {
        users[_userAddress].isVerified = _isVerified;

        emit UpdatedIsVerified(_userAddress, _isVerified);
    }

    /**
     *  updateIsVerifiedInBulk updates nicknames of Monetha users in bulk
     */
    function updateIsVerifiedInBulk(address[] _userAddresses, bool[] _updatedIsVerfied)
        external onlyOwner
    {
        require(_userAddresses.length == _updatedIsVerfied.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].isVerified = _updatedIsVerfied[i];

            emit UpdatedIsVerified(_userAddresses[i], _updatedIsVerfied[i]);
        }
    }

    /**
     *  updateUserDetailsInBulk updates details of Monetha users in bulk
     */
    function updateUserDetailsInBulk(address[] _userAddresses, uint256[] _starScores, uint256[] _reputationScores, uint256[] _signedDealsCount, bool[] _isVerified)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);
        require(_userAddresses.length == _reputationScores.length);
        require(_userAddresses.length == _signedDealsCount.length);
        require(_userAddresses.length == _isVerified.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].starScore = _starScores[i];
            users[_userAddresses[i]].reputationScore = _reputationScores[i];
            users[_userAddresses[i]].signedDealsCount = _signedDealsCount[i];
            users[_userAddresses[i]].isVerified = _isVerified[i];

            emit UpdatedUserDetails(_userAddresses[i], _starScores[i], _reputationScores[i], _signedDealsCount[i], _isVerified[i]);
        }
    }

    /**
     *  updateName updates the name of a Monetha user
     *  @param _userAddress address of user&#39;s wallet
     *  @param _updatedName represents user&#39;s new name
     */
    function updateName(address _userAddress, string _updatedName)
        external onlyOwner
    {
        users[_userAddress].name = _updatedName;

        emit UpdatedName(_userAddress, _updatedName);
    }

    /**
     *  updateUser updates single user details
     */
    function updateUser(address _userAddress, string _updatedName, uint256 _updatedStarScore, uint256 _updatedReputationScore, uint256 _updatedSignedDealsCount, string _updatedNickname, bool _updatedIsVerified)
        external onlyOwner
    {
        users[_userAddress].name = _updatedName;
        users[_userAddress].starScore = _updatedStarScore;
        users[_userAddress].reputationScore = _updatedReputationScore;
        users[_userAddress].signedDealsCount = _updatedSignedDealsCount;
        users[_userAddress].nickname = _updatedNickname;
        users[_userAddress].isVerified = _updatedIsVerified;

        emit UpdatedUser(_userAddress, _updatedName, _updatedStarScore, _updatedReputationScore, _updatedSignedDealsCount, _updatedNickname, _updatedIsVerified);
    }
}