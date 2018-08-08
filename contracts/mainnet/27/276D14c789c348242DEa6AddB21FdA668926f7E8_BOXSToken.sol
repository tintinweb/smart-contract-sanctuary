pragma solidity ^0.4.19;

contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSub(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}


contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public  returns (bool success);
    function allowance(address _owner, address _spender) constant public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant public  returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)  public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant  public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract BOXSToken is StandardToken,SafeMath {

    // metadata
    string public constant name = "boxs.io";
    string public constant symbol = "BOXS";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    
    // total cap
    uint256 public constant tokenCreationCap = 100 * (10**8) * 10**decimals;
    // init amount
    uint256 public constant tokenCreationInit = 25 * (10**8) * 10**decimals;
    // The amount of BOXSToken that mint init
    uint256 public constant tokenMintInit = 25 * (10**8) * 10**decimals;
    
    address public initDepositAccount;
    address public mintDepositAccount;
    
    mapping (address => bool) hadDoubles;
    
    address public owner;
	modifier onlyOwner() {
		require(msg.sender == owner);
		
		_;
	}

    function BOXSToken (
        address _initFundDepositAccount,
        address _mintFundDepositAccount
        )  public {
        initDepositAccount = _initFundDepositAccount;
        mintDepositAccount = _mintFundDepositAccount;
        balances[initDepositAccount] = tokenCreationInit;
        balances[mintDepositAccount] = tokenMintInit;
        totalSupply = tokenCreationInit + tokenMintInit;
        owner=msg.sender;
    }
    
    function checkDouble(address _to) constant internal returns (bool) {
        return hadDoubles[_to];
    }
    
    function doubleBalances(address _to) public  onlyOwner returns (bool) {
        if(hadDoubles[_to] == true) return false;
        if(balances[_to] <= 0) return false;
        uint256 temptotalSupply = safeAdd(totalSupply, balances[_to]);
        if(temptotalSupply > tokenCreationCap) return false;
        balances[_to] = safeMult(balances[_to], 2);
        totalSupply = temptotalSupply;
        hadDoubles[_to] = true;
        return true;
    }
    
    function batchDoubleBalances(address[] toArray) public  onlyOwner returns (bool) {
        if(toArray.length < 1) return false;
        for(uint i = 0; i<toArray.length; i++){
            doubleBalances(toArray[i]);
        }
        return true;
    }
	
	// Do not allow direct deposits.
    function () external {
      require(0>1);
    }
	
}