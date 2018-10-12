pragma solidity ^0.4.24;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/RVContractDB.sol

contract RVContractDB is Ownable {
    uint private TYPE_CROWDSALE = 1;
    uint private TYPE_TOKEN = 2;
    uint private TYPE_MULTISIGWALLET = 3;

    struct UserContract {
        address ownerAddress;
        address contractAddress;
        uint contractType;
        string contractName;
        bool isUse;
    }

    address[] public crowdsale_contract;

    mapping (address => UserContract[]) public userContract;

    event ContractAddtion();
    event ContractRemoval();

    modifier hasContract(address _ownerAddress) {
        require(userContract[_ownerAddress].length > 0, "The address has no contracts.");
        _;
    }

    function addContract(address _contractAddress, uint _contractType, string _contractName) public {
        userContract[msg.sender].push(UserContract({
            ownerAddress : msg.sender,
            contractAddress : _contractAddress,
            contractType : _contractType,
            contractName : _contractName,
            isUse : true
        }));

        if (_contractType == TYPE_CROWDSALE) {
            crowdsale_contract.push(_contractAddress);
        }

        emit ContractAddtion();
    }

    function removeContract(address _contractAddress) public hasContract(msg.sender) {
        for (uint i=0 ; i<userContract[msg.sender].length ; i++) {
            if( userContract[msg.sender][i].contractAddress == _contractAddress ) {
                userContract[msg.sender][i].isUse = false;
            }
        }

        emit ContractRemoval();
    }

    function getUserContract(address _ownerAddress, uint index) public view hasContract(_ownerAddress) returns (address, uint, bool, string) {
        require(index < userContract[_ownerAddress].length, "");

        return (userContract[_ownerAddress][index].contractAddress, userContract[_ownerAddress][index].contractType, userContract[_ownerAddress][index].isUse, userContract[_ownerAddress][index].contractName);
    }

    function getUserContractCount(address _ownerAddress) public view returns (uint) {
        return userContract[_ownerAddress].length;
    }
}