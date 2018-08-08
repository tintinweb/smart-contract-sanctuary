pragma solidity ^0.4.20;

contract ERC20Interface {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Interface {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint a, uint b) internal pure returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
  address public ownerWallet;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    ownerWallet = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == ownerWallet);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(ownerWallet, newOwner);
    ownerWallet = newOwner;
  }

}

contract Token is StandardToken, SafeMath, Ownable {

    function withDecimals(uint number, uint decimals)
        internal
        pure
        returns (uint)
    {
        return mul(number, pow(10, decimals));
    }

}

contract Apen is Token {

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;A1.1&#39;; 
    uint256 public unitsPerEth;     
    uint256 public maxApenSell;         
    uint256 public totalEthPos;  
    address public ownerWallet;           

    function Apen() public {
        decimals = 18;   
        totalSupply = withDecimals(21000000, decimals); 
        balances[msg.sender] = totalSupply;  
        maxApenSell = div(totalSupply, 2);         
        name = "Apen";                                             
        symbol = "APEN";                                 
        unitsPerEth = 1000;                           
    }

    function() public payable{
        
        uint256 amount = mul(msg.value, unitsPerEth);
        require(balances[ownerWallet] >= amount);
        require(balances[ownerWallet] >= maxApenSell);

        balances[ownerWallet] = sub(balances[ownerWallet], amount);
        maxApenSell = sub(maxApenSell, amount);
        balances[msg.sender] = add(balances[msg.sender], amount);

        Transfer(ownerWallet, msg.sender, amount);

        totalEthPos = add(totalEthPos, msg.value);

        ownerWallet.transfer(msg.value);                               
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

}