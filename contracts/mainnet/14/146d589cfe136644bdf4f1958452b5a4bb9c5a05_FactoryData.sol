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
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



contract Token {
    function balanceOf(address _owner) public constant returns (uint256);
}

contract FactoryData is Ownable {
    using SafeMath for uint256;
    struct CP {
        string refNumber;
        string name;
        mapping(address => bool) factories;
    }

    uint256 blocksquareFee = 20;
    uint256 networkReserveFundFee = 50;
    uint256 cpFee = 15;
    uint256 firstBuyersFee = 15;

    /* Mappings */
    mapping(address => mapping(address => bool)) whitelisted;
    mapping(string => address) countryFactory;
    mapping(address => bool) memberOfBS;
    mapping(address => uint256) requiredBST;
    mapping(address => CP) CPs;
    mapping(address => address) noFeeTransfersAccounts;
    mapping(address => bool) prestigeAddress;
    Token BST;

    /**
    * Constructor function
    *
    * Initializes contract.
    **/
    constructor() public {
        memberOfBS[msg.sender] = true;
        owner = msg.sender;
        BST = Token(0x509A38b7a1cC0dcd83Aa9d06214663D9eC7c7F4a);
    }

    /**
    * Add factory
    *
    * Owner can add factory for country
    *
    * @param _country Name of country
    * @param _factory Address of factory
    **/
    function addFactory(string _country, address _factory) public onlyOwner {
        countryFactory[_country] = _factory;
    }

    /**
    * @dev add member to blocksquare group
    * @param _member Address of member to add
    **/
    function addMemberToBS(address _member) public onlyOwner {
        memberOfBS[_member] = true;
    }

    /**
    * @dev add new certified partner
    * @param _cp Wallet address of certified partner
    * @param _refNumber Reference number of certified partner
    * @param _name Name of certified partner
    **/
    function createCP(address _cp, string _refNumber, string _name) public onlyOwner {
        CP memory cp = CP(_refNumber, _name);
        CPs[_cp] = cp;
    }

    /**
    * @dev add allowance to create buildings in country to certified partner
    * @param _cp Wallet address of certified partner
    * @param _factory Factory address
    **/
    function addFactoryToCP(address _cp, address _factory) public onlyOwner {
        CP storage cp = CPs[_cp];
        cp.factories[_factory] = true;
    }

    /**
    * @dev remove allowance to create buildings in country from certified partner
    * @param _cp Wallet address of certified partner
    * @param _factory Factory address
    **/
    function removeCP(address _cp, address _factory) public onlyOwner {
        CP storage cp = CPs[_cp];
        cp.factories[_factory] = false;
    }

    /**
    * @dev connect two addresses so that they can send BSPT without fee
    * @param _from First address
    * @param _to Second address
    **/
    function addNoFeeAddress(address[] _from, address[] _to) public onlyOwner {
        require(_from.length == _to.length);
        for (uint256 i = 0; i < _from.length; i++) {
            noFeeTransfersAccounts[_from[i]] = _to[i];
            noFeeTransfersAccounts[_to[i]] = _from[i];
        }
    }

    /**
    * @dev change BTS requirement for buying BSPT
    * @param _factory Address of factory
    * @param _amount Amount of required tokens
    **/
    function changeBSTRequirement(address _factory, uint256 _amount) public onlyOwner {
        requiredBST[_factory] = _amount * 10 ** 18;
    }

    /**
    * @dev add addresses to whitelist for factory
    * @param _factory Address of factory
    * @param _addresses Array of addresses to whitelist
    **/
    function addToWhitelist(address _factory, address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_factory][_addresses[i]] = true;
        }
    }

    /**
    * @dev remove address from whitelist
    * @param _factory Address of factory
    * @param _user Address of user
    **/
    function removeFromWhitelist(address _factory, address _user) public onlyOwner {
        whitelisted[_factory][_user] = false;
    }

    function changeFees(uint256 _network, uint256 _blocksquare, uint256 _cp, uint256 _firstBuyers) public onlyOwner {
        require(_network.add(_blocksquare).add(_cp).add(_firstBuyers) == 100);
        blocksquareFee = _network;
        networkReserveFundFee = _blocksquare;
        cpFee = _cp;
        firstBuyersFee = _firstBuyers;
    }

    function changePrestige(address _owner) public onlyOwner {
        prestigeAddress[_owner] = !prestigeAddress[_owner];
    }

    /**
    * @dev check if address is whitelisted for factory
    * @param _factory Address of factory
    * @param _user Address of user
    * @return True if user is whitelisted for given factory, false instead
    **/
    function isWhitelisted(address _factory, address _user) public constant returns (bool) {
        return whitelisted[_factory][_user];
    }

    /**
    * @dev get factory address for given country
    * @param _country Name of country
    * @return Address of factory
    **/
    function getFactoryForCountry(string _country) public constant returns (address) {
        return countryFactory[_country];
    }

    /**
    * @dev check if address is member of Blocksquare
    * @param _member Address of member
    * @return True if member is member of Blocksquare, false instead
    **/
    function isBS(address _member) public constant returns (bool) {
        return memberOfBS[_member];
    }

    /**
    * @dev check if address has enough BST to buy BSPT
    * @param _factory Address of factory
    * @param _address Address of BST owner
    * @return True if address has enough BST, false instead
    **/
    function hasEnoughBST(address _factory, address _address) constant public returns (bool) {
        return BST.balanceOf(_address) >= requiredBST[_factory];
    }

    /**
    * @dev amount of BST required to buy BSPT
    * @param _factory Address of factory
    * @return Amount of BST required
    **/
    function amountOfBSTRequired(address _factory) constant public returns (uint256) {
        return requiredBST[_factory];
    }

    /**
    * @dev check if certified partner can create new building in factory
    * @param _cp Wallet address of certified partner
    * @param _factory Factory address
    * @return True if certified partner can create buildings, false instead
    **/
    function canCPCreateInFactory(address _cp, address _factory) constant public returns (bool) {
        return CPs[_cp].factories[_factory];
    }

    /**
    * @dev get info about certified partner
    * @param _cp Wallet address of certified partner
    * @return Certified partner&#39;s reference number and name
    **/
    function getCP(address _cp) constant public returns (string, string) {
        return (CPs[_cp].refNumber, CPs[_cp].name);
    }

    /**
    * @dev check if two address can send BSPT without fee;
    * @param _from From address
    * @param _to To address
    * @return True if addresses can send BSPT without fee between them, false instead
    **/
    function canMakeNoFeeTransfer(address _from, address _to) constant public returns (bool) {
        return noFeeTransfersAccounts[_from] == _to;
    }

    function getNetworkFee() public constant returns (uint256) {
        return networkReserveFundFee;
    }

    function getBlocksquareFee() public constant returns (uint256) {
        return blocksquareFee;
    }

    function getCPFee() public constant returns (uint256) {
        return cpFee;
    }

    function getFirstBuyersFee() public constant returns (uint256) {
        return firstBuyersFee;
    }

    function hasPrestige(address _owner) public constant returns(bool) {
        return prestigeAddress[_owner];
    }
}