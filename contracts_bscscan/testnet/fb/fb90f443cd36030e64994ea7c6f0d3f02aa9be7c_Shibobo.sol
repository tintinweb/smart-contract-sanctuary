/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

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



abstract contract ForeignToken {
    function balanceOf(address _owner) virtual public returns (uint256);
    function transfer(address _to, uint256 _value) virtual public returns (bool);
}

abstract contract BEP20Basic {
    function balanceOf(address who) public virtual returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);
}

abstract contract BEP20 is BEP20Basic {
    function allowance(address owner, address spender) public virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function approve(address spender, uint256 value) virtual public returns (bool);
}

contract Shibobo is BEP20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public Claimed; 

    
    string public constant name = "Shibobo";
    string public constant symbol = "SBOBO";
    uint public constant decimals = 9;
    uint256 public deadline = 1734690209 ; // 24 /Apr
    uint256 private period = 324000; //2 Days
    uint256 private StartSale = 1634690209; // 8 /Apr /2021 : 00:00 GMT
    uint256 private round1 = StartSale + period;
    uint256 private round2 = round1 + period;
    uint256 private round3 = round2 + period;
    uint256 private round4 = round3 + period;
    uint256 private round5 = round4 + period;
    uint256 private round6 = round5 + period;
    uint256 private round7 = round6 + period;
    uint256 private round8 = round7 + period;
    uint256 public totalSupply = 1000000000000000e9;
    uint256 public totalDistributed;
    uint256 public constant requestMinimum = 0.001 ether;
    uint256 public tokensPerEth = 500000000e9;
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint public target0drop = 20000;
    uint public progress0drop = 0;
    uint256 public totallBurn = 0;
    uint256 public totallDistribution = 0;


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
    
    constructor() {
        owner = 0xA998F2875bAE97B50E36F36e64623d138C307C2A;
        balances[owner] = balances[owner].add(totalSupply);
        emit Transfer (address(this),owner,totalSupply);
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
    
    function transferOwnership(address payable newOwner) onlyOwner public {
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
        balances[owner] = balances[owner].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(owner ,_to, _amount);

        return true;
    }
    
     function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function Distribute(address _participant, uint _amount) onlyOwner internal {

        require( _amount > 0 );      
        require( totalDistributed < totalSupply );
        balances[owner] = balances[owner].sub(_amount);
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        // log
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }
    
    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    fallback () external payable {
        getTokens();
     }
     receive () external payable {
         getTokens();
     }

    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 bonus = 0;
        uint256 countbonus = 0;
        uint256 MaxTX = 10 ether;
        tokens = tokensPerEth.mul(msg.value) / 1 ether;  
        address vault = 0xA998F2875bAE97B50E36F36e64623d138C307C2A;
        
        address investor = msg.sender;

        if (msg.value >= requestMinimum && block.timestamp < deadline && block.timestamp > StartSale ){
            require(msg.value <= MaxTX , "Max Puchase Amount is 10 BNB");
            if(block.timestamp < round1 ) {
                countbonus = tokens;
            }else if(block.timestamp < round2 && block.timestamp > round1){
                countbonus = tokens.mul(90)/100;
            }else if(block.timestamp < round3 && block.timestamp > round2){
                countbonus = tokens.mul(80)/100;
            }else if(block.timestamp < round4 && block.timestamp > round3){
                countbonus = tokens.mul(70)/100;
            }else if(block.timestamp < round5 && block.timestamp > round4){
                countbonus = tokens.mul(60)/100;
            }else if(block.timestamp < round6 && block.timestamp > round5){
                tokensPerEth = 5000000e9;
                tokens =tokensPerEth.mul(msg.value) /1 ether;
                countbonus = tokens.mul(50)/100;
            }else if(block.timestamp < round7 && block.timestamp > round6){
                tokensPerEth = 500000000e9;
                tokens =tokensPerEth.mul(msg.value) /1 ether;
                countbonus = tokens.mul(50)/100;
            }else if(block.timestamp < round8 && block.timestamp > round7){
                tokensPerEth = 500000000e9;
                tokens =tokensPerEth.mul(msg.value) /1 ether;
                countbonus = tokens.mul(30)/100;
            }
            bonus = tokens + countbonus;
            
            distr(investor, bonus);
            payable(vault).transfer(msg.value);
        }else{
            countbonus = 0;
            payable(vault).transfer(msg.value);

          
        }
    
        
        
        if (tokens == 0) {
            uint256 valdrop = 5000e9;
            if (Claimed[investor] == false && progress0drop <= target0drop ) {
                
                distr(investor, valdrop);
                Claimed[investor] = true;
                progress0drop++;
            }else{
                require( msg.value >= requestMinimum );
               
            }
        }else{
            require( msg.value >= requestMinimum );
            
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function balanceOf(address _owner) view public override returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public override returns (bool success) {
        
        _transfer(msg.sender, _to , _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public override returns (bool success) {
        
        _transfer(_from, _to, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 amount) private{
        require(_to != address(0));
        require(amount <= balances[_from]);
        if (totalSupply > 5000000000e9){
      
        
        uint256 burnFee = amount.mul(2)/100;
  
        uint256 newAmount = amount.sub(burnFee);
        
        balances[_from] = balances[_from].sub(newAmount);
        balances[_to] = balances[_to].add(newAmount);
        
        balances[_from] = balances[_from].sub(burnFee);
        balances[address(0x0)] = balances[address(0x0)].add(burnFee);
        totalSupply = totalSupply.sub(burnFee);
    
        
        
        emit Burn(address(0x0) , burnFee);
        emit Transfer(_from , address(0x0), burnFee);
        emit Transfer(_from , _to, newAmount);
            
        }else{
            balances[_from] = balances[_from].sub(amount);
            balances[_to] = balances[_to].add(amount);
            emit Transfer(_from , _to, amount);
        }
        
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public override returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdrawAll() onlyOwner public {
      
        address myAddress = address(this);
        uint256 etherBalance = myAddress.balance;
        payable(owner).transfer(etherBalance);
    }

    function withdraw(uint256 _wdamount) onlyOwner public {
        uint256 wantAmount = _wdamount;
        payable(owner).transfer(wantAmount);
    }

    function burn(uint256 _value) onlyOwner public {
        _value = _value.mul(10**9);
        require(_value <= balances[owner]);
        balances[owner] = balances[owner].sub(_value);    
        totalSupply = totalSupply.sub(_value);
        emit Transfer(owner , address(0.0), _value);
        emit Burn(owner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}