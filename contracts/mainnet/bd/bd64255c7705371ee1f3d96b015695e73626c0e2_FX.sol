/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity ^0.4.26;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  modifier onlyPayloadSize(uint numWords){
    assert(msg.data.length >= numWords * 32 + 4);
    _;
  }
}

contract Token{ // ERC20 standard

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

}

contract StandardToken is Token, SafeMath{

    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success){
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success){
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance){
        return balances[_owner];
    }
    
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool success){
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success){
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    // this creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}

contract FX is StandardToken {
    

    // public variables of the token

    string public constant name = "1 Forex Coin";
    string public constant symbol = "1FX";
    uint256 public constant decimals = 18;
    
    // reachable if max amount raised
   


    address mainWallet;


    modifier onlyMainWallet{
        require(msg.sender == mainWallet);
        _;
    }

    function FX() public {
        totalSupply = 600000000e18;
        mainWallet = msg.sender;
        balances[mainWallet] = totalSupply;
        
    }

    modifier onlyOwner() {
    require(msg.sender == mainWallet);
    _;
  }

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(mainWallet, newOwner);
    balances[newOwner]=balances[mainWallet];
    balances[mainWallet] = 0;
    mainWallet = newOwner;
  }

    function sendBatchCS(address[] _recipients, uint[] _values) external returns (bool) {
        require(_recipients.length == _values.length);

        uint senderBalance = balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            if(msg.sender != _recipients[i]){
                senderBalance = senderBalance - value;
                balances[to] += value;
            }
		     Transfer(msg.sender, to, value);
        }
        balances[msg.sender] = senderBalance;
        return true;
    } 
}