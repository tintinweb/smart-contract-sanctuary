/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title NameRegistry allows users  give unique names to their accounts
 * @notice This contract manages writing and reading unique names by account owners with setName () and readName ()
 * @author typhoonese
 */

interface INameRegistry {
  /**
    EVENTS
     */
  event NameGiven(address _from, string _newName);

  /**
    SETTERS
     */

  /** 
    @notice setName associates a name to msg.sender
    @param _newName: value of the account name 
    @notice successful transaction emits NameGiven event
   */
  function setName(string calldata _newName) external;

  /**
    GETTERS
     */

  /**
    @notice readName returns the name of an account
    @return _name :name of the account
    */
  function readName() external view returns (string memory _name);
}

/**
 * @title StringUtils can be used for string utils
 * @notice This library can concatenate two strings
 * @author typhoonese
 */

library StringUtils {
  /**
   * @notice concatenate can concatenate two strings
   * @param _firstString is the first string in concatenation
   * @param _secondString is the second string in concatenation
   * @return the concatenation of _firstString and _secondString
   */
  function concatenate(string memory _firstString, string memory _secondString) internal pure returns (string memory) {
    return string(abi.encodePacked(_firstString, _secondString));
  }
}

pragma solidity ^0.8.9;

/**
 * @title NameRegistry allows users  give unique names to their accounts
 * @notice This contract manages writing and reading unique names by account owners with setName () and readName ()
 * @author typhoonese
 */

contract NameRegistry is INameRegistry {
  using StringUtils for string;
  /**
  MODIFIERS
   */

  //@notice CheckEmptyName validates that an empty string cannot be given to an account name
  //@param _newName name requested for an account
  modifier CheckEmptyName(string memory _newName) {
    require(!(bytes(_newName).length == 0), emptyStringErrMsg);
    _;
  }

  //@notice CheckUniqueName validates whether the _newName is taken
  //@param _newName name requested for an account
  modifier CheckUniqueName(string memory _newName) {
    require(!isNameTaken[_newName], notUniqueNameErrMsg.concatenate(_newName));
    _;
  }

  /**
  ERROR MESSAGES
   */
  //@notice emptyStringErrMsg sets the error message when an empty string is requested for an account
  string private emptyStringErrMsg = 'Try another name. Account name cannot be an empty string.';
  //@notice notUniqueNameErrMsg sets the error message when a taken name is requested for anotehr account
  string private notUniqueNameErrMsg = 'Try another name. Following account name is taken : ';

  /**
  STATE VARIABLES
   */
  //@notice accountToName maps msg.sender to a unique name
  mapping(address => string) private accountToName;
  //@notice isNameTaken mapes name to bool (taken if true)
  mapping(string => bool) private isNameTaken;

  /**
    SETTERS
     */

  /** 
    @notice setName associates a name to msg.sender and releases an existing name from msg.sender
    @param _newName: value of the account name 
    @notice successful transaction emits NameGiven event
   */
  function setName(string calldata _newName) public override CheckEmptyName(_newName) CheckUniqueName(_newName) {
    _releaseName();
    _setName(_newName);
    emit NameGiven(msg.sender, _newName);
  }

  /**
    GETTERS
     */

  /**
    @notice readName returns the name of an account
    @return _name :name of the account
    */
  function readName() public view override returns (string memory _name) {
    return _readName();
  }

  /**
    PRIVATE FUNCTIONS
     */

  /** 
    @notice _setName associates a name to msg.sender
    @notice called by setName()
    @param _newName: value of the account name 
   */
  function _setName(string calldata _newName) private {
    isNameTaken[_newName] = true;
    accountToName[msg.sender] = _newName;
  }

  /** 
    @notice _releaseName releases msg.sender's existing name
    @notice called by setName()
   */
  function _releaseName() private {
    if (!(bytes(accountToName[msg.sender]).length == 0)) {
      isNameTaken[accountToName[msg.sender]] = false;
    }
  }

  /**
    @notice _readName returns the name of an account
    @notice called by readName()
    @return _name :name of the account
    */
  function _readName() private view returns (string memory _name) {
    return accountToName[msg.sender];
  }
}