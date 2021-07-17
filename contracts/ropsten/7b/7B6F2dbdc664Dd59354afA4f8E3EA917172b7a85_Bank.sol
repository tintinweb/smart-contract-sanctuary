/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

pragma solidity ^0.4.26;


library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
}


contract Ownable {
    // address public owner;
    address[] public list_owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        list_owner.push(msg.sender);
    }
    
    modifier onlyListOwner() {
        bool checkower = false;
        for(uint i=0 ; i<list_owner.length ; i++){
            if(list_owner[i] == msg.sender){
                checkower = true;
            }
            if(checkower){
                break;
            }
        }
        require(checkower, "Address is not onwer");
        _;
    }
    
    function addowner(address newOwner) public onlyListOwner{
        if(list_owner.length < 5){
            list_owner.push(newOwner);
        }
    }
  
    function transferOwnership(address newOwner) public onlyListOwner {
        for(uint i=0 ; i<list_owner.length ; i++){
            if(list_owner[i] == msg.sender){
                list_owner[i] = newOwner;
                break;
            }
        }
    }
}

contract ERC20 {
   function totalSupply() public constant returns (uint totalSupply) {}
    
  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) external returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) external returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) external returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}







contract TokenStandard is Ownable,ERC20{   
    using SafeMath for uint256;
    uint256 public totalSupply;
    // Balances for each account
    mapping(address => uint256) balances;
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
 
 
 
    // Get totalSupply of the token 
    function totalSupply() public view returns (uint256 totalSupply) {
        return totalSupply;
    }
    
    // Get the token balance for account `tokenOwner`
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _value) external returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } 
        else {
            return false;
        }
    }
    
    // Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    
    // Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
     
}



contract Bank is TokenStandard {
    using SafeMath for uint256;
    string public constant name = "BROWN";
    string public constant symbol = "BROWN";
    uint8 public constant decimals = 18;
    
    
    
    uint256 private rate;
    uint256 public fee = 10000000000000000; //fee 1%  //retio 0.01
    uint256 public timelock = 604800 seconds;
    address[] accounts_user;
    
     
    event DepositMade(address indexed accounts, uint amount);
    event WithdrawMade(address indexed accounts, uint amount);
    event SystemWithdrawMade(address indexed accounts, uint amount);
    event SystemDepositMade(address indexed accounts, uint amount);

     
     
    function deposit() public payable returns (uint){
        if(0 == balances[msg.sender]){
            accounts_user.push(msg.sender);
        }
         
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit DepositMade(msg.sender,msg.value);
        return balances[msg.sender];
    }
     
    function withdraw(uint amount) public payable returns (uint){
        require(balances[msg.sender] >= amount, "Balance is not enought");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        uint withdraw_fee = amount.mul(fee);
        amount = amount.sub(withdraw_fee);
        msg.sender.transfer(amount); //  require(amount <= address(this).balance);   auto check
        //  msg.sender.Send(amount); //  require(amount <= address(this).balance);   not check
        
        emit WithdrawMade(msg.sender,amount);
        return balances[msg.sender];
    }
     
    function systemBalance() public view returns (uint){
        return address(this).balance;
    }
     
    function userBalance() public view returns (uint){
        return balances[msg.sender];
    }
     
    function systemWithdraw(uint amount) public onlyListOwner() returns (uint){
        require(systemBalance() >= amount, "Balance in system not enought");
        msg.sender.transfer(amount);
        emit SystemDepositMade(msg.sender,amount);
        return systemBalance();
    }
     
    function systemDeposit(uint amount) public onlyListOwner() payable returns (uint){
        emit SystemDepositMade(msg.sender,amount);
        return systemBalance();
    }
}