pragma solidity ^0.4.10;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract TheMoneyFightToken {
    
    enum betStatus{Running,Pending,Done}
    
    address public owner = msg.sender;
    
    uint gamesIndex = 0;
    
    
    uint public constant LOSER_LOCK_TIME = 4 weeks;
    bool public purchasingAllowed = false;
    
    mapping (uint => Game) games;
    mapping (uint => Result) results;
    mapping (uint => Option[]) gameOptions;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalContribution = 0;
    uint256 public cap = 10000000000000000000000;
   
    
    uint256 public totalSupply = 0;
    
    event gameStarted(string gameName,uint id, uint options,uint endTime);
    event gameFinished(uint gameId,uint winningOption, uint256 totalBets, uint256 totalBetsForWinningOption);
    event betAdded(uint gameId,uint option, address ownerAddress, uint256 value);
    event Redeem(uint gameId,uint option,bool winner, address ownerAddress, uint256 reward);
    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
    struct Option{
        mapping (address=>uint256) status;
    }
    
    struct Game{
        betStatus status;
        mapping (uint => uint256) totalBets;
        uint256 total;
        uint endTime;
        uint finishTime;
    }
    
    struct Result{
        uint winningOption;
        uint locktime;
        uint256 betTotal;
        uint256 winningOptionTotal;
    }
    
    modifier only_owner() {
		if (msg.sender != owner) throw;
		_;
	}
	
	modifier canRedeem(uint gameId){
	    if(games[gameId].status != betStatus.Done) throw;
	    _;
	}
	
	modifier etherCapNotReached(uint256 _contribution) {
        assert(safeAdd(totalContribution, _contribution) <= cap);
        _;
    }
	
	function canBet(uint gameId) returns(bool success){
	    bool running = now < games[gameId].finishTime;
	    bool statusOk =  games[gameId].status == betStatus.Running;
	    if(statusOk && !running) {
	        games[gameId].status = betStatus.Pending; 
	        statusOk = false;
	    }
	    return running && statusOk;
	} 
	
   function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
   }
   
   function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
     assert(b > 0);
     uint c = a / b;
     assert(a == b * c + a % b);
     return c;
    }
    


    function name() constant returns (string) { return "The Money Fight"; }
    function symbol() constant returns (string) { return "MFT"; }
    function decimals() constant returns (uint8) { return 18; }
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { throw; }

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { throw; }

        if (_value == 0) { return false; }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    } 
    
    function createGame(string name,uint opts,uint endTime) only_owner { 
        uint currGame = ++gamesIndex;
        games[currGame] = Game(betStatus.Running, 0 , 0, endTime);
        for(uint i = 0 ; i < opts ; i++ ){
            gameOptions[currGame].push(Option());
        }
        gameStarted(name,currGame,opts,endTime);
    }
    
    function predictWinner(uint game, uint option, uint256 _value) {
        Game curr = games[game];
        betStatus status = curr.status;
        uint256 fromBalance = balances[msg.sender];
        bool sufficientFunds =  fromBalance >= _value;
        if (_value > 0 && sufficientFunds && canBet(game)) {
            balances[msg.sender] -= _value;
            gameOptions[game][option].status[msg.sender]= _value;
            curr.totalBets[option] += _value;
            curr.total += _value;
            betAdded(game,option,msg.sender,_value);
        }
    }
    
    function redeem(uint game, uint256 option) canRedeem(game) {
            bool won = results[game].winningOption == option;
            if(!won){
                uint256 val =gameOptions[game][option].status[msg.sender];
                if(val > 0 && results[game].locktime < now){
                    gameOptions[game][option].status[msg.sender] = 0;
                    balances[msg.sender] += val;
                    Redeem(game,option,false,msg.sender,val);
                }
            } else {
                uint256 total = calculatePrize(msg.sender,game,option);
                if(total > 0){
                    uint256 value = gameOptions[game][option].status[msg.sender];
                    gameOptions[game][option].status[msg.sender] = 0;
                    totalSupply += (total - value);
                    balances[msg.sender] += total;
                    Redeem(game,option,true,msg.sender,total);
                }
            }
    }
    
    function calculatePrize(address sender, uint game,uint option) internal returns (uint256 val){
        uint256 value = gameOptions[game][option].status[sender];
        if(value > 0){
            uint256 total =safeDiv(safeMul(results[game].betTotal,value),results[game].winningOptionTotal);
            return total;
        }
        return 0;
    }
    
    
    function finishGame(uint game, uint winOption) only_owner {
       Game curr = games[game];
       curr.status = betStatus.Done;  
       results[game] = Result(winOption, now + LOSER_LOCK_TIME, curr.total, curr.totalBets[winOption]); 
       gameFinished(game, winOption, curr.total, curr.totalBets[winOption]);
    }
    
    function drain(uint256 bal) only_owner {
		if (!owner.send(bal)) throw;
	}
	
	function getTotalPrediction(uint game, uint option) public constant returns (uint256 total,uint256 totalOption){
	    Game curr = games[game];
	    return (curr.total, curr.totalBets[option]);
	}
	
    function getPrediction(uint game, uint o) returns (uint256 bet) {
        return gameOptions[game][o].status[msg.sender];
    }
    
    function withdrawForeignTokens(address _tokenContract) only_owner returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    } 
   
    function enablePurchasing() only_owner {
        purchasingAllowed = true;
    }

    function disablePurchasing() only_owner{
        purchasingAllowed = false;
    }
    function() payable etherCapNotReached(msg.value) {
        if (!purchasingAllowed) { throw; }
        
        if (msg.value == 0) { return; }

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = msg.value * 100;

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }
    
}