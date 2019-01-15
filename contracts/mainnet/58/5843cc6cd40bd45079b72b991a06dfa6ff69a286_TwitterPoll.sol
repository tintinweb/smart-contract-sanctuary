pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

contract Ownable {
  address private _owner;

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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract TwitterPoll is Ownable {
  using ConcatLib for string[];
  string public question;
  string[] public yesVotes;
  string[] public noVotes;

  constructor(string memory _question) public {
    question = _question;
  }

  function submitVotes(string[] memory _yesVotes, string[] memory _noVotes) public onlyOwner() {
    yesVotes.concat(_yesVotes);
    noVotes.concat(_noVotes);
  }

  function getYesVotes() public view returns (string[] memory){
    return yesVotes;
  }

  function getNoVotes() public view returns (string[] memory){
    return noVotes;
  }
}

library ConcatLib {
  function concat(string[] storage _preBytes, string[] memory _postBytes) internal  {
    for (uint i=0; i < _postBytes.length; i++) {
      _preBytes.push(_postBytes[i]);
    }
  }
}