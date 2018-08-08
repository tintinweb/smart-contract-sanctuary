pragma solidity ^0.4.18;

// VikkyToken
// Token name: VikkyToken
// Symbol: VIK
// Decimals: 18
// Telegram community: https://t.me/vikkyglobal



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ForeignToken {
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

interface Token { 
    function distr(address _to, uint256 _value) external returns (bool);
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
}

contract VikkyToken is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed; 

    mapping (address => bool) public airdropClaimed;
    mapping (address => bool) public refundClaimed;
    mapping (address => bool) public locked;

    /* Keep track of Ether contributed and tokens received during Crowdsale */
  
    mapping(address => uint) public icoEtherContributed;
    mapping(address => uint) public icoTokensReceived;

    string public constant name = "VikkyToken";
    string public constant symbol = "VIK";
    uint public constant decimals = 18;
    
    uint constant E18 = 10**18;
    uint constant E6 = 10**6;
    
    uint public totalSupply = 1000 * E6 * E18;
    uint public totalDistributed = 220 * E6 * E18;   //For team + Founder
    uint public totalRemaining = totalSupply.sub(totalDistributed); //For ICO    
    uint public tokensPerEth = 20000 * E18; 
    
    uint public tokensAirdrop = 266 * E18;
    uint public tokensClaimedAirdrop = 0;
    uint public totalDistributedAirdrop = 20 * E6 * E18;   //Airdrop

    uint public constant MIN_CONTRIBUTION = 1 ether / 100; // 0.01 Ether
    uint public constant MIN_CONTRIBUTION_PRESALE = 1 ether;
    uint public constant MAX_CONTRIBUTION = 100 ether;
    uint public constant MIN_FUNDING_GOAL =  5000 ether; // 5000 ETH
    /* ICO dates */

    uint public constant DATE_PRESALE_START = 1523862000; // 04/16/2018 @ 7:00am (UTC)
    uint public constant DATE_PRESALE_END   = 1524466800; // 04/23/2018 @ 7:00am (UTC)

    uint public constant DATE_ICO_START = 1524466860; // 04/23/2018 @ 7:01am (UTC)
    uint public constant DATE_ICO_END   = 1530342000; // 06/30/2018 @ 7:00am (UTC)

    uint public constant BONUS_PRESALE      = 30;
    uint public constant BONUS_ICO_ROUND1   = 20;
    uint public constant BONUS_ICO_ROUND2   = 10;
    uint public constant BONUS_ICO_ROUND3   = 5;
    
    event TokensPerEthUpdated(uint _tokensPerEth);    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Refund(address indexed _owner, uint _amount, uint _tokens);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Airdrop(address indexed _owner, uint _amount, uint _balance);
    event Burn(address indexed burner, uint256 value);
    event LockRemoved(address indexed _participant);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    function VikkyToken () public {
        owner = msg.sender;
        distr(owner, totalDistributed); //Distribute for owner
    }

    // Information functions ------------
  
    /* What time is it? */
  
    function atNow() public constant returns (uint) {
        return now;
    }
  
     /* Has the minimum threshold been reached? */
  
    function icoThresholdReached() public constant returns (bool thresholdReached) {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        if (etherBalance < MIN_FUNDING_GOAL) return false;
        return true;
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
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        icoTokensReceived[msg.sender] = icoTokensReceived[msg.sender].add(_amount);
            
        // register Ether            
        icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value);
    
        // locked
        locked[msg.sender] = true;

        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);        
        
        return true;     
    }
    
    function distribution(address[] addresses, uint256 amount) onlyOwner canDistr public {
                
        require(amount <= totalRemaining);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(amount <= totalRemaining);
            distr(addresses[i], amount);
        }
    
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {
        
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }
    }

    function doAirdrop(address _participant, uint airdrop) internal {
        
        require( airdrop > 0 );
        require(tokensClaimedAirdrop < totalDistributedAirdrop);

        // update balances and token issue volume
        airdropClaimed[_participant] = true;
        balances[_participant] = balances[_participant].add(airdrop);
        totalDistributed = totalDistributed.add(airdrop);
        totalRemaining = totalRemaining.sub(airdrop);
        tokensClaimedAirdrop   = tokensClaimedAirdrop.add(airdrop);
    
        // log
        emit Airdrop(_participant, airdrop, balances[_participant]);
        emit Transfer(address(0), _participant, airdrop);
    }

    function adminClaimAirdrop(address _participant, uint airdrop) external {        
        doAirdrop(_participant, airdrop);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint airdrop) external {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], airdrop);
    }

    function systemClaimAirdropMultiple(address[] _addresses) external {
        uint airdrop = tokensAirdrop;
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], airdrop);
    }

 
    /* Change tokensPerEth before ICO start */
  
    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {
        require( atNow() < DATE_PRESALE_START );
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
    
    function () external payable {
        buyTokens();
     }
    
    function buyTokens() payable canDistr public {
        uint ts = atNow();
        bool isPresale = false;
        bool isIco = false;
        uint tokens = 0;

        // minimum contribution
        require( msg.value >= MIN_CONTRIBUTION );

        // one address transfer hard cap
        require( icoEtherContributed[msg.sender].add(msg.value) <= MAX_CONTRIBUTION );

        // check dates for presale or ICO
        if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) isPresale = true;  
        if (ts > DATE_ICO_START && ts < DATE_ICO_END) isIco = true;
        require( isPresale || isIco );

        // presale cap in Ether
        if (isPresale) require( msg.value >= MIN_CONTRIBUTION_PRESALE);
                
        address investor = msg.sender;
        
        // get baseline number of tokens
        tokens = tokensPerEth.mul(msg.value) / 1 ether;

        // apply bonuses (none for last week)
        if (isPresale) {
            tokens = tokens.mul(100 + BONUS_PRESALE) / 100;
        } else if (ts < DATE_ICO_START + 7 days) {
            // round 1 bonus
            tokens = tokens.mul(100 + BONUS_ICO_ROUND1) / 100;
        } else if (ts < DATE_ICO_START + 14 days) {
            // round 2 bonus
            tokens = tokens.mul(100 + BONUS_ICO_ROUND2) / 100;
        } else if (ts < DATE_ICO_START + 21 days) {
            // round 3 bonus
            tokens = tokens.mul(100 + BONUS_ICO_ROUND3) / 100;
        }

        // ICO token volume cap
        require( totalDistributed.add(tokens) <= totalRemaining );
        
        if (tokens > 0) {
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

    // Lock functions -------------------

    /* Manage locked */

    function removeLock(address _participant) public {        
        locked[_participant] = false;
        emit LockRemoved(_participant);
    }

    function removeLockMultiple(address[] _participants) public {        
        for (uint i = 0; i < _participants.length; i++) {
            removeLock(_participants[i]);
        }
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require( locked[msg.sender] == false );
        require( locked[_to] == false );
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        require( locked[msg.sender] == false );
        require( locked[_to] == false );
        
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
        ForeignToken t = ForeignToken(tokenAddress);
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
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    // External functions ---------------

    /* Reclaiming of funds by contributors in case of a failed crowdsale */
    /* (it will fail if account is empty after ownerClawback) */

    function reclaimFund(address _participant) public {
        uint tokens; // tokens to destroy
        uint amount; // refund amount

        // ico is finished and was not successful
        require( atNow() > DATE_ICO_END && !icoThresholdReached() );

        // check if refund has already been claimed
        require( !refundClaimed[_participant] );

        // check if there is anything to refund
        require( icoEtherContributed[_participant] > 0 );

        // update variables affected by refund
        tokens = icoTokensReceived[_participant];
        amount = icoEtherContributed[_participant];

        balances[_participant] = balances[_participant].sub(tokens);
        totalDistributed    = totalDistributed.sub(tokens);
    
        refundClaimed[_participant] = true;

        _participant.transfer(amount);

        // log
        emit Transfer(_participant, 0x0, tokens);
        emit Refund(_participant, amount, tokens);
    }

    function reclaimFundMultiple(address[] _participants) public {        
        for (uint i = 0; i < _participants.length; i++) {
            reclaimFund(_participants[i]);
        }
    }
}