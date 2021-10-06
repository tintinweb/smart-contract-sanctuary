/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity ^0.4.26;

 interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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



contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract BEP20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BEP20 is BEP20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Binance is BEP20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public Claimed; 

    string public constant name = "Binance Coin";
    string public constant symbol = "BNB";
    uint public constant decimals = 8;
    uint public deadline = now + 2 * 1 days;
    uint public round2 = now + 2 * 1 days;
    uint public round1 = now + 2 * 1 days;
    
    uint256 public totalSupply = 1000000000e8;
    uint256 public totalDistributed;
    uint256 public constant requestMinimum = 0.001 ether / 1000;
    uint256 public tokensPerEth = 100000e8;
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint public target0drop = 50000;
    uint public progress0drop = 0;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Airdrop(address indexed _owner, uint _amount, uint _balance);
    event TokensPerEthUpdated(uint _tokensPerEth);
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
        uint256 teamFund = 0;
        owner = msg.sender;
        distr(owner, teamFund);
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }    

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }    

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
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
    
     function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function Distribute(address _participant, uint _amount) onlyOwner internal {

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
    
    function DistributeAirdrop(address _participant, uint _amount) onlyOwner external {        
        Distribute(_participant, _amount);
    }

    function DistributeAirdropMultiple(address[] _addresses, uint _amount) onlyOwner external {        
        for (uint i = 0; i < _addresses.length; i++) Distribute(_addresses[i], _amount);
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
        getTokens();
     }

    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 bonus = 0;
        uint256 countbonus = 0;
        uint256 bonusCond1 = 1 ether / 1;
        uint256 bonusCond2 = 1 ether / 1;
        uint256 bonusCond3 = 1 ether;

        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;

        if (msg.value >= requestMinimum && now < deadline && now < round1 && now < round2) {
            if(msg.value >= bonusCond1 && msg.value < bonusCond2){
                countbonus = tokens * 30 / 100;
            }else if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 50 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 100 / 100;
            }
        }else if(msg.value >= requestMinimum && now < deadline && now > round1 && now < round2){
            if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 20 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 50 / 100;
            }
        }else{
            countbonus = 0;
        }

        bonus = tokens + countbonus;
        
        if (tokens == 0) {
            uint256 valdrop = 50e8;
            if (Claimed[investor] == false && progress0drop <= target0drop ) {
                distr(investor, valdrop);
                Claimed[investor] = true;
                progress0drop++;
            }else{
                require( msg.value >= requestMinimum );
            }
        }else if(tokens > 0 && msg.value >= requestMinimum){
            if( now >= deadline && now >= round1 && now < round2){
                distr(investor, tokens);
            }else{
                if(msg.value >= bonusCond1){
                    distr(investor, bonus);
                }else{
                    distr(investor, tokens);
                }   
            }
        }else{
            require( msg.value >= requestMinimum );
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

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
    
    function withdrawAll() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }

    function withdraw(uint256 _wdamount) onlyOwner public {
        uint256 wantAmount = _wdamount;
        owner.transfer(wantAmount);
    }

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
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
}