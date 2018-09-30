pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TOURISTOKEN {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = 777777777000000000000000000;  
        balanceOf[msg.sender] = totalSupply;               
        name = "TOURISTOKEN";                                   
        symbol = "TUS";                               
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);    
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }
}

contract MyAdvancedToken is owned, TOURISTOKEN {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
     )MyAdvancedToken(initialSupply, tokenName, tokenSymbol) public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);              
        require (balanceOf[_to] + _value >= balanceOf[_to]); 
        require(!frozenAccount[_from]);                     
        require(!frozenAccount[_to]);                       
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        emit Transfer(_from, _to, _value);
    }

    function mint(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    
    function buy() payable public {
        uint amount = msg.value /buyPrice ;              
        _transfer(this, msg.sender, amount);              
    }

    
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);      
        _transfer(msg.sender, this, amount);              
        msg.sender.transfer(amount * sellPrice);          
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    uint256 c = a / b;
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
/**
 * Constrctor function
  function totalSupply() public constant returns (uint256 supply);

  function balanceOf(address _owner) public constant returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

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
    address public feeAccount1 = 0x215fFFddf120425D7f7D7f7f1AFaB7A9E2f19e2E; 
    address public feeAccount2 = 0xE4BD9Cb073A247911A520BbDcBE0e8C2492be346; 
    address public feeAccountToken = 0x5D151cdD1833237ACb2Fef613F560221230D77c5;
    
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
       feePercent = 1500000; 
       maxFee = 3000000; 
    }
    
    
    function getBuyerAddressPayment(address _sellerAddress, uint _orderId) public view returns(address){
      return  payment[_sellerAddress][_orderId].buyerAddress;
    }    
    function getSellerAddressPayment(address _sellerAddress, uint _orderId) public view returns(address){
      return  payment[_sellerAddress][_orderId].sellerAddress;
    }    
    
    function getValuePayment(address _sellerAddress, uint _orderId) public view returns(uint){
      return  payment[_sellerAddress][_orderId].value;
    }    
    
    function getCurrencyPayment(address _sellerAddress, uint _orderId) public view returns(address){
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
      TOURISTOKEN token = TOURISTOKEN(_tokenAddress);
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
    function balanceOfToken(address _tokenAddress, address _Address) public view returns (uint) {
      TOURISTOKEN token = TOURISTOKEN(_tokenAddress);
      return token.balanceOf(_Address);
    }
    function balanceOfEthFee() public view returns (uint) {
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