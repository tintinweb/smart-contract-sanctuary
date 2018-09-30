pragma solidity ^0.4.24;



/**
 * @title ERC20Interface
 * @dev ERC20 interface
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title StandardToken
 * @dev ERC20 implementation
 */
contract StandardToken is ERC20Interface {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[_to] + _value >= balances[_to]);
        require(_to != 0x0);
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_to] + _value >= balances[_to]);
        require(_to != 0x0);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title Ownable
 * @dev The Ownable contract provides basic authorization control
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title BaseToken
 * @dev BaseToken Token Smart Contract
 */
contract BaseToken is StandardToken, SafeMath, Ownable {

    function withDecimals(uint number, uint decimals)
        internal
        pure
        returns (uint)
    {
        return mul(number, pow(10, decimals));
    }

}

/**
 * @title ApproveAndCallFallBack
 * @dev Contract function to receive approval and execute function in one call, borrowed from MiniMeToken
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
 * @title Dainet
 * @dev Dainet Token Smart Contract
 */
contract Dainet is BaseToken {

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;1.0&#39;; 
    uint256 public unitsPerEth;     
    uint256 public maxDainSell;         
    uint256 public totalEthPos;           
    uint256 public minimalEthPos;   

    constructor() public {
        decimals = 18;   
        totalSupply = withDecimals(130000000, decimals); 
        balances[msg.sender] = totalSupply;  
        emit Transfer(address(0), msg.sender, totalSupply);
        maxDainSell = div(totalSupply, 2);         
        name = "Dainet";                                             
        symbol = "DAIN";                                 
        unitsPerEth = 1300;                           
    }

    function() public payable{
        
        uint256 amount = mul(msg.value, unitsPerEth);
        require(balances[owner] >= amount);
        require(balances[owner] >= maxDainSell);

        balances[owner] = sub(balances[owner], amount);
        maxDainSell = sub(maxDainSell, amount);
        balances[msg.sender] = add(balances[msg.sender], amount);
        emit Transfer(owner, msg.sender, amount);
        
        totalEthPos = add(totalEthPos, msg.value);

        owner.transfer(msg.value);                               
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function changeUnitsPerEth(uint256 newValue) public onlyOwner {
        unitsPerEth = newValue;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}