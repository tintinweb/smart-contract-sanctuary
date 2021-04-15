// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract TestGeode is Ownable {
    // contract state
    uint256 public someInt;
    uint256[] public someIntArr;
    string public someStr;
    bool public someBool;

    // protocol state
    mapping(address => bool) public validators;

    // modifier to verify caller is a Geode-approved address.
    modifier onlyValidator() {
        require(validators[msg.sender], 'Geode Caller only');
        _;
    }

    // setters

    /**
     * Function to authorize or revoke validator.
     * @param _validator - the input address
     * @param _assignPrivilege - true - to grant authorization, false - to revoke authorization
     */
    function modifyValidator(address _validator, bool _assignPrivilege)
        public
        onlyOwner()
    {
        validators[_validator] = _assignPrivilege;
    }

    function setOneInt(uint256 _x) public onlyValidator() {
        someInt = _x;
    }

    function setMultipleInt(uint256[] memory _arr) public onlyValidator() {
        someIntArr = _arr;
    }

    function setStr(string memory _str) public onlyValidator() {
        someStr = _str;
    }

    function setBool(bool _b) public onlyValidator() {
        someBool = _b;
    }

    function setBoolThenStr(bool _isBool, string memory _str)
        public
        onlyValidator()
    {
        someBool = _isBool;
        someStr = _str;
    }

    function setOneIntThenBool(uint256 _x, bool _b) public onlyValidator() {
        someInt = _x;
        someBool = _b;
    }

    function setOneIntThenStr(uint256 _x, string memory _str)
        public
        onlyValidator()
    {
        someInt = _x;
        someStr = _str;
    }

    function setMultIntThenBool(uint256[] memory _arr, bool _b)
        public
        onlyValidator()
    {
        someIntArr = _arr;
        someBool = _b;
    }

    function setMultIntThenStr(uint256[] memory _arr, string memory _str)
        public
        onlyValidator()
    {
        someIntArr = _arr;
        someStr = _str;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}