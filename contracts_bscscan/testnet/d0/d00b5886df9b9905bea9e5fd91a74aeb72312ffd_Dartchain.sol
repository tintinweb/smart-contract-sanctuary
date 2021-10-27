/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

/**
 *Official Contract Code of Dart Chain.
*/


pragma solidity >=0.4.26;

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

contract Dartchain is BEP20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping (address => bool) public Claimed; 

    string public constant name = "Dart Chain";
    string public constant symbol = "DART";
    uint public constant decimals = 8;
    uint public deadline = now + 2 * 1 days;
    uint public round2 = now + 2 * 1 days;
    uint public round1 = now + 2 * 1 days;
    
    uint256 public totalSupply = 54972896533499374e8;
    uint256 public totalDistributed;
    uint256 public airdropDistributed;
    uint256 public airdropCap = 15000000000000000e8;
    uint256 public constant  requestMinimum = 0.01 ether;
    uint256 public tokensPerEth = 10000000000000e8;
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint public target0drop = 30000;
    uint public progress0drop = 0;
    uint256 public dropAmount= 500000000e8;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Airdrop(address indexed _owner, uint _amount, uint _balance);
    event DropAmountUpdated(uint _airdropAmount);
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
        uint256 teamFund = 5000000000000000e8;
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
    
     function updateAirdropAmount(uint _airdropAmount) public onlyOwner {        
        dropAmount = _airdropAmount;
        emit DropAmountUpdated(_airdropAmount);
    }
      
       
       function SpecDistributeAirdrop(address _participant) onlyOwner external {  
          
           
        Distribute(_participant, dropAmount);
    }
    
       
       
    function tokenSale(address _refer) public payable returns (bool success){
    uint256 tokens = 0;
    uint256 bonus = 0.5 ether / 1 ;
   
    tokens = tokensPerEth.mul(msg.value) / 1 ether;
    
   
    
    if(msg.value >= bonus){
        distr(msg.sender, tokens);
    }
    
    if(msg.sender != _refer ){
      
      distr(_refer,tokens);
    }
    distr( msg.sender, tokens);
    
    return true;
  }
       
    function refAirdrop(address _refer) public returns (bool success) {
       
        
        

        if (airdropDistributed >= airdropCap) {
            distributionFinished = true;
        }
        
        
         if(msg.sender != _refer && balanceOf(_refer) != 0 && balanceOf(msg.sender) == 0  ){
             
             distr( _refer, dropAmount / 2);
             airdropDistributed = airdropDistributed.add(dropAmount/2);
         }
         if(msg.sender != _refer && balanceOf(_refer) != 0 && balanceOf(msg.sender) == 0){
             airdropDistributed = airdropDistributed.add(dropAmount);
          distr( msg.sender, dropAmount);
         }
   return true;
  }
       
       
         
         
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {

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