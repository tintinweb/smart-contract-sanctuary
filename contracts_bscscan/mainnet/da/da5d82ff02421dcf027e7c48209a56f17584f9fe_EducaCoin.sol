/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity 0.5.3;

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if(a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;

        return c;
    }
}

contract Ownable {
    address payable public owner;
    
    event OwnershipTransferred(address newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public  {
        require(newOwner != address(0));

        owner = newOwner;
        emit OwnershipTransferred(owner);
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BasicToken is ERC20 {
    using SafeMath for uint;

    

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowed;

    

    function balanceOf(address tokenOwner) view public returns (uint balance) {
        return _balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool) {
        require(_balances[msg.sender] >= tokens);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function approve(address spender, uint tokens) public returns (bool) {
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#approve (see NOTE)
        require (tokens == 0 && _allowed[msg.sender][spender] == 0);

        _allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender) view public returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        require(_allowed[from][msg.sender] >= tokens);
        require(_balances[from] >= tokens);
        require(to != address(0));

        uint _allowance = _allowed[from][msg.sender];

        _balances[from] = _balances[from].sub(tokens);
        _balances[to] = _balances[to].add(tokens);
        _allowed[from][msg.sender] = _allowance.sub(tokens);

        emit Transfer(from, to, tokens);

        return true;
    }
}



contract EducaCoin is Ownable, BasicToken {
      string public constant name = "Pro Educa Coin";
    string public constant symbol = "EDUCA";
    uint8 public constant decimals = 18;
    uint internal _totalSupply = 0;
    uint internal _maximumSupply = 50000 * 10 ** 18;
    uint internal _referral_fee = 5;

    mapping (uint => mapping (address => uint)) internal _ico_participant;
    mapping (uint => mapping (address => uint)) internal _ico_maxbuy;
    
    
    // ---> New ICO Variables
    uint public round = 0;
    uint public launchPrice = 6000000000000000;
    uint public launchPrice_discount = 6000000000000000;
    bool public ico = false;
    uint256 public ico_deadline;
    uint public subscribe_percentual;
    
    
   
    

    

    
    // ---> Events
    event BoughtTokens(address indexed to, uint256 value);
    event Rounds(uint indexed emit_newRound, uint256 emit_new_supply_limit, uint256 emit_deadline, uint256 emit_value, uint256 emit_discount_value, uint256 emit_subscribe);
    event BoughtReferral(address indexed to, uint256 value, address indexed referralAddress); 
  
   
   // ---> GETs
  
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function getLaunchPrice() public view returns(uint){
        return launchPrice;
    }
    function getLaunchDiscountPrice() public view returns(uint){
        return launchPrice_discount;
    }
    function getMaximumSupply() public view returns(uint256){
        return _maximumSupply;
    }
    function getIcoDeadline() public view returns(uint256){
        return ico_deadline;
    }
    function getIco() public view returns(bool){
        return ico;
    }
    function getSubPercentual() public view returns(uint){
        return subscribe_percentual;
    }
    function getMaxBuy() public view returns (uint) {
        return _ico_maxbuy[round][msg.sender];
    }
    function getIcoParticipant() public view returns (uint) {
        return _ico_participant[round][msg.sender];
    }
    function getRound() public view returns (uint) {
        return round;
    }
    
    
    // ---> Principal Functions
    
   
    function updateReferralFee(uint new_referral_fee) public onlyOwner{
        _referral_fee=new_referral_fee;
    }
    
    
    function newico(uint256 new_supply_limit, uint256 deadline, uint256 value, uint256 discount_value, uint256 subscribe) public onlyOwner {
    round++;
    _maximumSupply = new_supply_limit;
    launchPrice = value;
    launchPrice_discount = discount_value;
    ico = true;
    ico_deadline = now + deadline;
    subscribe_percentual = subscribe;
    
    emit Rounds(round, new_supply_limit, deadline, value, discount_value, subscribe);
  
        
        
    }
    
   
   
    
    function buy() public payable {
   
    
    // define qual fluxo seguir: 1 = normal, 2 = com desconto
    if(ico == true){
        uint8 fluxo;
        if(ico_deadline < now){
            ico = false;
            
        }
        if(_ico_participant[round][msg.sender] == 1){
            fluxo=1;
            }else{
                if(_balances[msg.sender] > 0){
                // _ico_participant[round][msg.sender] = 1;
                    if(_ico_maxbuy[round][msg.sender] > 0){
                    fluxo=2;        
                    }else{
                    uint256 max_buy = _balances[msg.sender] * subscribe_percentual;
                    _ico_maxbuy[round][msg.sender] = max_buy.div(100);
                    fluxo=2;        
                    }
                }else{
                _ico_participant[round][msg.sender] = 1;
                fluxo=1;
                }
            }
        
            if(fluxo == 1){
            require(_maximumSupply >= _totalSupply, "Quantity ordered exceeds token supply limit");
            uint256 weiAmount = msg.value; // DIVIDIR PELAS DECIMAIS DO TOKEN
            uint256 tokens = weiAmount.div(launchPrice);
            tokens = tokens * 10 ** 18;
            _totalSupply = _totalSupply.add(tokens); // Increment raised amount
            owner.transfer(msg.value);// Send money to owner
            _balances[msg.sender] = _balances[msg.sender].add(tokens);
            
            emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
            }else{
                
            uint256 weiAmount = msg.value; // DIVIDIR PELAS DECIMAIS DO TOKEN
            uint256 tokens = weiAmount.div(launchPrice_discount);
            tokens = tokens * 10 ** 18;
            
            
                if(tokens <= _ico_maxbuy[round][msg.sender]){
                
                _totalSupply = _totalSupply.add(tokens); // Increment raised amount
        
                owner.transfer(msg.value);// Send money to owner
                _balances[msg.sender] = _balances[msg.sender].add(tokens);
                
        
                emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
            
                _ico_maxbuy[round][msg.sender]=_ico_maxbuy[round][msg.sender].sub(tokens);
            
                if(_ico_maxbuy[round][msg.sender] == 0){
                    _ico_participant[round][msg.sender] = 1;
                }
            
               
                    
                }else{
                uint256 utilizado = launchPrice_discount * _ico_maxbuy[round][msg.sender];
                uint256 troco_tokens = msg.value - utilizado ;
                 _totalSupply = _totalSupply.add(_ico_maxbuy[round][msg.sender]); // Increment raised amount
        
            owner.transfer(msg.value);// Send money to owner
            _balances[msg.sender] = _balances[msg.sender].add(_ico_maxbuy[round][msg.sender]);
            
        
            emit BoughtTokens(msg.sender, _ico_maxbuy[round][msg.sender]); // log event onto the blockchain
            
            tokens = troco_tokens.div(launchPrice);
            tokens = tokens * 10 ** 18;
            _totalSupply = _totalSupply.add(tokens); // Increment raised amount
        
            //owner.transfer(msg.value);// Send money to owner
            _balances[msg.sender] = _balances[msg.sender].add(tokens);
            
        
            emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
        
            _ico_maxbuy[round][msg.sender]=0;
            _ico_participant[round][msg.sender] = 1;
        
            
                }
                
                    
                    
            }
        
        
        
    }else{
    require(_maximumSupply >= _totalSupply, "Quantity ordered exceeds token supply limit");
    uint256 weiAmount = msg.value; // DIVIDIR PELAS DECIMAIS DO TOKEN
    uint256 tokens = weiAmount.div(launchPrice);
    tokens = tokens * 10 ** 18;
    
    
    _totalSupply = _totalSupply.add(tokens); // Increment raised amount
    
    owner.transfer(msg.value);// Send money to owner
    _balances[msg.sender] = _balances[msg.sender].add(tokens);
    
    
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    
   
    }
    }
    
    
    
    
        function referralbuy(address payable referral) public payable {
   
    
     // define qual fluxo seguir: 1 = normal, 2 = com desconto
    if(ico == true){
        uint8 fluxo;
        if(ico_deadline < now){
            ico = false;
            
        }
        if(_ico_participant[round][msg.sender] == 1){
            fluxo=1;
            }else{
                if(_balances[msg.sender] > 0){
                // _ico_participant[round][msg.sender] = 1;
                    if(_ico_maxbuy[round][msg.sender] > 0){
                    fluxo=2;        
                    }else{
                    uint256 max_buy = _balances[msg.sender] * subscribe_percentual;
                    _ico_maxbuy[round][msg.sender] = max_buy.div(100);
                    fluxo=2;        
                    }
                }else{
                _ico_participant[round][msg.sender] = 1;
                fluxo=1;
                }
            }
        
            if(fluxo == 1){
            require(_maximumSupply >= _totalSupply, "Quantity ordered exceeds token supply limit");
            uint256 weiAmount = msg.value; // DIVIDIR PELAS DECIMAIS DO TOKEN
            uint256 tokens = weiAmount.div(launchPrice);
            tokens = tokens * 10 ** 18;
            
            
            _totalSupply = _totalSupply.add(tokens); // Increment raised amount
     uint fracao = tokens.div(100);
    uint fracao5 = fracao.mul(_referral_fee);
    _totalSupply = _totalSupply.add(fracao5); // Increment raised amount
    
    owner.transfer(msg.value);// Send money to owner
    _balances[msg.sender] = _balances[msg.sender].add(tokens);
    _balances[referral] = _balances[referral].add(fracao5);
    
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    emit BoughtReferral(msg.sender, fracao5, referral); // log event onto the blockchain
            
            
           
            }else{
                
            uint256 weiAmount = msg.value; // DIVIDIR PELAS DECIMAIS DO TOKEN
            uint256 tokens = weiAmount.div(launchPrice_discount);
            tokens = tokens * 10 ** 18;
            
            
                if(tokens <= _ico_maxbuy[round][msg.sender]){
                
                _totalSupply = _totalSupply.add(tokens); // Increment raised amount
        
                owner.transfer(msg.value);// Send money to owner
                _balances[msg.sender] = _balances[msg.sender].add(tokens);
                
        
                emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
            
                _ico_maxbuy[round][msg.sender]=_ico_maxbuy[round][msg.sender].sub(tokens);
            
                if(_ico_maxbuy[round][msg.sender] == 0){
                    _ico_participant[round][msg.sender] = 1;
                }
            
               
                    
                }else{
                uint256 utilizado = launchPrice_discount * _ico_maxbuy[round][msg.sender];
                uint256 troco_tokens = msg.value - utilizado ;
                 _totalSupply = _totalSupply.add(_ico_maxbuy[round][msg.sender]); // Increment raised amount
        
            owner.transfer(msg.value);// Send money to owner
            _balances[msg.sender] = _balances[msg.sender].add(_ico_maxbuy[round][msg.sender]);
            
        
            emit BoughtTokens(msg.sender, _ico_maxbuy[round][msg.sender]); // log event onto the blockchain
            
            tokens = troco_tokens.div(launchPrice);
            tokens = tokens * 10 ** 18;
            _totalSupply = _totalSupply.add(tokens); // Increment raised amount
        
            
            _balances[msg.sender] = _balances[msg.sender].add(tokens);
            
        
            emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
        
            _ico_maxbuy[round][msg.sender]=0;
            _ico_participant[round][msg.sender] = 1;
        
            
                }
                
                    
                    
            }
        
        
    }else{
    require(_maximumSupply >= _totalSupply, "Quantity ordered exceeds token supply limit");
    uint256 weiAmount = msg.value; // DIVIDIR PELAS DECIMAIS DO TOKEN
    uint256 tokens = weiAmount.div(launchPrice);
    tokens = tokens * 10 ** 18;
    
    
    _totalSupply = _totalSupply.add(tokens); // Increment raised amount
     uint fracao = tokens.div(100);
    uint fracao5 = fracao.mul(_referral_fee);
    _totalSupply = _totalSupply.add(fracao5); // Increment raised amount
    
    owner.transfer(msg.value);// Send money to owner
    _balances[msg.sender] = _balances[msg.sender].add(tokens);
    _balances[referral] = _balances[referral].add(fracao5);
    
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    emit BoughtReferral(msg.sender, fracao5, referral); // log event onto the blockchain
   
    }
    }
    
    

 

}