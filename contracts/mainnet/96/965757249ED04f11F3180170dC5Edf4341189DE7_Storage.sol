pragma solidity 0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

pragma solidity 0.4.11;

contract Storage is Ownable {
    struct Crate {
        mapping(bytes32 => uint256) uints;
        mapping(bytes32 => address) addresses;
        mapping(bytes32 => bool) bools;
        mapping(address => uint256) bals;
    }

    mapping(bytes32 => Crate) crates;

    function setUInt(bytes32 _crate, bytes32 _key, uint256 _value) onlyOwner {
        crates[_crate].uints[_key] = _value;
    }

    function getUInt(bytes32 _crate, bytes32 _key) constant returns(uint256) {
        return crates[_crate].uints[_key];
    }

    function setAddress(bytes32 _crate, bytes32 _key, address _value) onlyOwner {
        crates[_crate].addresses[_key] = _value;
    }

    function getAddress(bytes32 _crate, bytes32 _key) constant returns(address) {
        return crates[_crate].addresses[_key];
    }

    function setBool(bytes32 _crate, bytes32 _key, bool _value) onlyOwner {
        crates[_crate].bools[_key] = _value;
    }

    function getBool(bytes32 _crate, bytes32 _key) constant returns(bool) {
        return crates[_crate].bools[_key];
    }

    function setBal(bytes32 _crate, address _key, uint256 _value) onlyOwner {
        crates[_crate].bals[_key] = _value;
    }

    function getBal(bytes32 _crate, address _key) constant returns(uint256) {
        return crates[_crate].bals[_key];
    }
}