pragma solidity ^0.4.25;

/**
 * @title SafeMath
 */
library SafeMath { 
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    } 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    } 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    } 
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AltcoinToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ICNToken is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    

    string public constant name = "INDOCHAIN";
    string public constant symbol = "ICN";
    uint public constant decimals = 8;
    
    uint256 public totalSupply = 7000000000e8;
    uint256 public totalDistributed = 0;        
    uint256 public tokensPerEth =  30000;  
    uint256 public tokensPer2Eth = 35000;  
    uint256 public tokensPer3Eth = 40000;
    uint256 public startPase = 1541548800;
    uint public maxPhase1 = 875000000e8;
    uint public maxPhase2 = 1750000000e8;
    uint public maxPhase3 = 2625000000e8;
    uint public currentPhase = 0;
    uint public soldPhase1 = 0;
    uint public soldPhase2 = 0;
    uint public soldPhase3 = 0;
    uint256 public pase1 = startPase + 1 * 30 days;
    uint256 public pase2 = pase1 + 1 * 30 days;
    uint256 public pase3 = pase2 + 1 * 30 days;
    uint256 public constant minContribution = 1 ether / 1000;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event StartPaseUpdated(uint256 _time);
    event TokensPerEthUpdated(uint _tokensPerEth);
    event TokensPerEth2Updated(uint _tokensPerEth);
    event TokensPerEth3Updated(uint _tokensPerEth);
    event MaxPhase1Updated(uint _maxPhase1);
    event MaxPhase2Updated(uint _maxPhase2);
    event MaxPhase3Updated(uint _maxPhase3);
     
    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        uint256 devTokens = 1610000000e8;
        distr(owner, devTokens);
    }
     
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( totalDistributed < totalSupply );
        
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        // log
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }

    function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }
    
    function () external payable {
        getTokens();
     }
    
    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 sold = 0;
        
        require( msg.value >= minContribution );

        require( msg.value > 0 );
        
        require( now > startPase && now < pase3);
        
        if(now > startPase && now < pase1 && soldPhase1 <= maxPhase1 ){
            tokens = msg.value / tokensPerEth;
        }else if(now >= pase1 && now < pase2 && soldPhase2 <= maxPhase2 ){
            tokens = msg.value / tokensPer2Eth;
        }else if(now >= pase2 && now < pase3 && soldPhase3 <= maxPhase3 ){
            tokens = msg.value / tokensPer3Eth;
        }
                
        address investor = msg.sender;
        
        if (tokens > 0) {
            if(now > startPase && now <= pase1 && soldPhase1 <= maxPhase1 ){
                sold = soldPhase1 + tokens;
                require(sold + tokens <= maxPhase1);
                soldPhase1 += tokens;
            }else if(now > pase1 && now <= pase2 && soldPhase2 <= maxPhase2 ){
                sold = soldPhase2 + tokens;
                require(sold + tokens <= maxPhase2);
                soldPhase2 += tokens;
            }else if(now > pase2 && now <= pase3 && soldPhase3 <= maxPhase3 ){
                sold = soldPhase3 + tokens;
                require(sold + tokens <= maxPhase3);
                soldPhase3 += tokens;
            }
            
            distr(investor, tokens);
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        AltcoinToken t = AltcoinToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawAltcoinTokens(address _tokenContract) onlyOwner public returns (bool) {
        AltcoinToken token = AltcoinToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
    function updateTokens2PerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPer2Eth = _tokensPerEth;
        emit TokensPerEth2Updated(_tokensPerEth);
    }
    function updateTokens3PerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPer3Eth = _tokensPerEth;
        emit TokensPerEth3Updated(_tokensPerEth);
    }
    
    
    function updateMaxPhase1(uint _maxPhase1) public onlyOwner {        
        maxPhase1 = _maxPhase1;
        emit MaxPhase1Updated(_maxPhase1);
    }
    function updateMaxPhase2(uint _maxPhase2) public onlyOwner {        
        maxPhase2 = _maxPhase2;
        emit MaxPhase2Updated(_maxPhase2);
    }
    function updateMaxPhase3(uint _maxPhase3) public onlyOwner {        
        maxPhase3 = _maxPhase3;
        emit MaxPhase3Updated(_maxPhase3);
    }
    function updateStartPhase(uint256 _time) public onlyOwner {        
        startPase = _time;
        pase1 = startPase + 1 * 30 days;
        pase2 = pase1 + 1 * 30 days;
        pase3 = pase2 + 1 * 30 days;
        emit StartPaseUpdated(_time);
    }
}