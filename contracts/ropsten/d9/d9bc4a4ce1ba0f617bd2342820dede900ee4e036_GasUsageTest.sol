pragma solidity ^0.4.24;

// <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0f756a7f7f6a636661227c6063666b667b764f3e213e3f213f">[email&#160;protected]</a> from NPM

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

contract GasUsageTest is Ownable {

    struct Access {
        string userId;
        string accessToken;
        uint256 timestamp;
    }

    struct Closing {
        string userId;
        uint256 timestamp;
        string fileId;
        string fileChecksum;
    }

    Access[] public accessIndex;
    Closing[] public closingIndex;

    event AccessEvent(string userId, string accessToken, uint256 timestamp);
    event CloseFile(string userId, uint256 timestamp, string fileId, string fileChecksum);

    function logAccess(string _userId, string _accessToken, uint256 _timestamp) public onlyOwner {
        emit AccessEvent(_userId, _accessToken, _timestamp);
    }

    function registerLog(string _userId, string _accessToken, uint256 _timestamp) public onlyOwner {
        accessIndex.push(Access(_userId, _accessToken, _timestamp));
    }

    function logFileClosing(string _userId, uint256 _timestamp, string _fileId, string _fileChecksum) public onlyOwner {
        emit CloseFile(_userId, _timestamp, _fileId, _fileChecksum);
    }

    function registerFileClosing(string _userId, uint256 _timestamp, string _fileId, string _fileChecksum) public onlyOwner {
        closingIndex.push(Closing(_userId, _timestamp, _fileId, _fileChecksum));
    }

}