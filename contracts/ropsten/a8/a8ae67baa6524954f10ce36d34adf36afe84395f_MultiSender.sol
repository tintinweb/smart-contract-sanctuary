pragma solidity ^0.4.21;

contract SafeMathLib {

  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
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
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner =  newOwner;
  }

}

contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}


contract MultiSender is SafeMathLib, Ownable {

    uint256 _etherBalance;
    address public authorizedCaller;
    event EtherTransferred(address indexed _from, address indexed _to, uint256 indexed _value);

    //modifiers
    modifier onlyAdmins() {
        require(msg.sender == authorizedCaller || msg.sender == owner);
        _;
    }

    constructor() public
    {
        owner = msg.sender;
        authorizedCaller = msg.sender;
    }

    function changeAuthorizedCaller(address _newCaller) public onlyOwner {
        authorizedCaller = _newCaller;
    }


    function getERC20TokenBalance(address _address) public view returns (uint256)  {
        return ERC20(_address).balanceOf(this);
    }

     function getEtherBalance() public view returns (uint256)  {
        return _etherBalance;
    }

    function multisendToken(address _tokenAddress, address[] _addresses, uint256[] _values) onlyAdmins public returns (uint256) {

        uint256 i = 0;

        require(_addresses.length > 0);
        require(_addresses.length == _values.length);

        while (i < _addresses.length) {
           require(ERC20(_tokenAddress).transfer(_addresses[i], _values[i]));
           i += 1;
        }

        return i;
    }

    function multisendEther(address[] _addresses, uint256[] _values) onlyAdmins public returns (uint256) {

        uint256 i = 0;

        require(_addresses.length > 0);
        require(_addresses.length == _values.length);

        while (i < _addresses.length) {
           require(_values[i] > 1);
           _etherBalance = safeSub(_etherBalance, _values[i]);
           require(_addresses[i].send(_values[i]));
           emit EtherTransferred(this, _addresses[i], _values[i]);
           i += 1;
        }

        return i;
    }


    function () payable public {
        _etherBalance = safeAdd(_etherBalance, msg.value);
    }

}