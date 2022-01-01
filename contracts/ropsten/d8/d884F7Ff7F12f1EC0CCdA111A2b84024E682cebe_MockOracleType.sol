/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/oracletype/MockOracleType.sol

pragma solidity >=0.4.21 <0.6.0;



contract MockOracleType is Ownable{
  string public name;
  mapping (string => uint256) prices;
 
  constructor() public{
    name = "Mock Oracle Type";
  }
  function get_asset_price(string memory _name) public view returns(uint256){
    return prices[_name];
  }
  function add_or_set_asset(string memory _name, uint256 _price) public onlyOwner{
      prices[_name] = _price;
  }
  function getPriceDecimal() public pure returns(uint256){
    return 1e18;
  }
}

contract MockOracleTypeFactory {
  event CreateMockOracleType(address addr);

  function newMockOracleType() public returns(address){
    MockOracleType vt = new MockOracleType();
    emit CreateMockOracleType(address(vt));
    vt.transferOwnership(msg.sender);
    return address(vt);
  }
}