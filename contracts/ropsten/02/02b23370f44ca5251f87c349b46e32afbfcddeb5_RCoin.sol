pragma solidity ^0.4.25;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
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
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public  view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        require(balances[_to] + _value >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] > _value);
        require(allowed[msg.sender][_spender] + _value > _value);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract RCoin is StandardToken, SafeMath {

    // metadata
    string public constant name = "Room Token";
    string public constant symbol = "RCT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // final ether transfered address
    address private ethFundDeposit;  
    //address of RCT foundation
    address private rctFundDeposit; 
    // crowdsale parameters
    bool public isFinalized; 
    // 1eth = 6400            
    uint256 public constant tokenExchangeRate = 6400; 
    // total marketcap
    uint256 private constant tokenCreationCap =  1500 * (10**6) * 10**decimals;
    // token selling goal
    uint256 private constant tokenCreationMin =  675 * (10**6) * 10**decimals;
   // token to be trasfered for RCT foundation
    uint256 private constant rctFund = 500 * (10**6) * 10**decimals; 
    //contract creation time 
    uint256 public  startTime;
    // contract period
    uint256 public constant contractPeriod = (60 * 60 * 24 * 365 * 2);
    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateRCT(address indexed _to, uint256 _value);

    modifier times_up(){
        require(now - startTime < contractPeriod);
        _;
    }
    // constructor
    constructor(address _ethFundDeposit, address _rctFundDeposit) public
    {
        isFinalized = false;                 
        ethFundDeposit = _ethFundDeposit;
        totalSupply = rctFund;
        rctFundDeposit = _rctFundDeposit;
        balances[rctFundDeposit] = rctFund;
        startTime = now;    
        emit CreateRCT(rctFundDeposit, rctFund);  
    }

    function createTokens()   payable external times_up{
        require(!isFinalized, "Contract finalized");
        require((msg.value != 0), "value should be grater then Zero");

        uint256 tokens = safeMult(msg.value, tokenExchangeRate); 
        uint256 checkedSupply = safeAdd(totalSupply, tokens);   
        require(tokenCreationCap > checkedSupply);    
        totalSupply = checkedSupply;
        balances[msg.sender] += tokens;  
        emit CreateRCT(msg.sender, tokens);  
    }

    function finalize() external {
        require(!isFinalized);
        require(msg.sender == ethFundDeposit,"you don&#39;t have permission to call this"); 
        require(totalSupply > tokenCreationMin);  
        isFinalized = true;
        ethFundDeposit.transfer(address(this).balance); 
    }

    function refund() external {
        require(!isFinalized,"Project finalized can&#39;t refund") ;                      
        require(totalSupply < tokenCreationMin,"reached min target can&#39;t refund");
        uint256 RCTVal = balances[msg.sender];
        require(RCTVal != 0);
        balances[msg.sender] = 0;
        totalSupply = safeSubtract(totalSupply, RCTVal); 
        uint256 ethVal = RCTVal / tokenExchangeRate;    
        emit LogRefund(msg.sender, ethVal);              
        msg.sender.transfer(ethVal);     
    }

}