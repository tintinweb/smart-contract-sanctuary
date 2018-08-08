pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error For CHRTY Tokens And Ethereum
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() public constant returns (uint256 supply);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public constant returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}
contract Gateway is Ownable{
    using SafeMath for uint;
    address public feeAccount1 = 0x455f19F16ee2f3F487fb498A24E3F69f78E8Ec14; //the account1 that will receive fees
    address public feeAccount2 = 0x07fe839AD214433B764ca17290Ee966106B7b3C1; //the account2 that will receive fees
    address public feeAccountToken = 0xAc159594c06bD64928199B0F4D6D801C447d51D2; //the account that will receive fees tokens
    
    struct BuyInfo {
      address buyerAddress; 
      address sellerAddress;
      uint value;
      address currency;
    }
    
    mapping(address => mapping(uint => BuyInfo)) public payment;
   
    uint balanceFee;
    uint public feePercent;
    uint public maxFee;
    constructor() public{
       feePercent = 1500000; // decimals 6. 1.5% fee by default
       maxFee = 3000000; // fee can not exceed 3%
    }
    
    
    function getBuyerAddressPayment(address _sellerAddress, uint _orderId) public constant returns(address){
      return  payment[_sellerAddress][_orderId].buyerAddress;
    }    
    function getSellerAddressPayment(address _sellerAddress, uint _orderId) public constant returns(address){
      return  payment[_sellerAddress][_orderId].sellerAddress;
    }    
    
    function getValuePayment(address _sellerAddress, uint _orderId) public constant returns(uint){
      return  payment[_sellerAddress][_orderId].value;
    }    
    
    function getCurrencyPayment(address _sellerAddress, uint _orderId) public constant returns(address){
      return  payment[_sellerAddress][_orderId].currency;
    }
    
    
    function setFeeAccount1(address _feeAccount1) onlyOwner public{
      feeAccount1 = _feeAccount1;  
    }
    function setFeeAccount2(address _feeAccount2) onlyOwner public{
      feeAccount2 = _feeAccount2;  
    }
    function setFeeAccountToken(address _feeAccountToken) onlyOwner public{
      feeAccountToken = _feeAccountToken;  
    }    
    function setFeePercent(uint _feePercent) onlyOwner public{
      require(_feePercent <= maxFee);
      feePercent = _feePercent;  
    }    
    function payToken(address _tokenAddress, address _sellerAddress, uint _orderId,  uint _value) public returns (bool success){
      require(_tokenAddress != address(0));
      require(_sellerAddress != address(0)); 
      require(_value > 0);
      Token token = Token(_tokenAddress);
      require(token.allowance(msg.sender, this) >= _value);
      token.transferFrom(msg.sender, feeAccountToken, _value.mul(feePercent).div(100000000));
      token.transferFrom(msg.sender, _sellerAddress, _value.sub(_value.mul(feePercent).div(100000000)));
      payment[_sellerAddress][_orderId] = BuyInfo(msg.sender, _sellerAddress, _value, _tokenAddress);
      success = true;
    }
    function payEth(address _sellerAddress, uint _orderId, uint _value) internal returns  (bool success){
      require(_sellerAddress != address(0)); 
      require(_value > 0);
      uint fee = _value.mul(feePercent).div(100000000);
      _sellerAddress.transfer(_value.sub(fee));
      balanceFee = balanceFee.add(fee);
      payment[_sellerAddress][_orderId] = BuyInfo(msg.sender, _sellerAddress, _value, 0x0000000000000000000000000000000000000001);    
      success = true;
    }
    function transferFee() onlyOwner public{
      uint valfee1 = balanceFee.div(2);
      feeAccount1.transfer(valfee1);
      balanceFee = balanceFee.sub(valfee1);
      feeAccount2.transfer(balanceFee);
      balanceFee = 0;
    }
    function balanceOfToken(address _tokenAddress, address _Address) public constant returns (uint) {
      Token token = Token(_tokenAddress);
      return token.balanceOf(_Address);
    }
    function balanceOfEthFee() public constant returns (uint) {
      return balanceFee;
    }
    function bytesToAddress(bytes source) internal pure returns(address) {
      uint result;
      uint mul = 1;
      for(uint i = 20; i > 0; i--) {
        result += uint8(source[i-1])*mul;
        mul = mul*256;
      }
      return address(result);
    }
    function() external payable {
      require(msg.data.length == 20); 
      require(msg.value > 99999999999);
      address sellerAddress = bytesToAddress(bytes(msg.data));
      uint value = msg.value.div(10000000000).mul(10000000000);
      uint orderId = msg.value.sub(value);
      balanceFee = balanceFee.add(orderId);
      payEth(sellerAddress, orderId, value);
  }
}