/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity 0.5.3;

contract Math {

/* Constants */

    //string constant public VERSION = "Math 0.2.3";
    uint constant NULL = 0;
    bool constant LT = false;
    bool constant GT = true;
    // No type bool <-> int type conversion in solidity :~(
    uint constant iTRUE = 1;
    uint constant iFALSE = 0;
    uint constant iPOS = 1;
    uint constant iZERO = 0;
    uint constant iNEG = uint(-1);


/* Modifiers */

/* Functions */
    
    // @dev Parametric comparator for > or <
    // !_sym returns a < b
    // _sym  returns a > b
    function cmp (uint a, uint b, bool _sym) internal pure returns (bool)
    {
        return (a!=b) && ((a < b) != _sym);
    }

    /// @dev Parametric comparator for >= or <=
    /// !_sym returns a <= b
    /// _sym  returns a >= b
    function cmpEq (uint a, uint b, bool _sym) internal pure returns (bool)
    {
        return (a==b) || ((a < b) != _sym);
    }
    
    /// Trichotomous comparator
    /// a < b returns -1
    /// a == b returns 0
    /// a > b returns 1
/*    function triCmp(uint a, uint b) internal pure returns (bool)
    {
        uint c = a - b;
        return c & c & (0 - 1);
    }
    
    function nSign(uint a) internal pure returns (uint)
    {
        return a & 2^255;
    }
    
    function neg(uint a) internal pure returns (uint) {
        return 0 - a;
    }
*/    
    function safeMul(uint a, uint b) internal pure returns (uint)
    {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint)
    {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint)
    {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }
}

/*
file:   LibCLL.sol
ver:    0.3.4
updated:20-Apr-2018
author: Darryl Morris 
contributors: terraflops
email:  o0ragman0o AT gmail.com

A Solidity library for implementing a data indexing regime using
a circular linked list.

This library provisions lookup, navigation and key/index storage
functionality which can be used in conjunction with an array or mapping.

NOTICE: This library uses internal functions only and so cannot be compiled
and deployed independently from its calling contract.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.
*/

// LibCLL using `uint` keys
library LibCLLu {

    //string constant public VERSION = "LibCLLu 0.3.4";
    uint constant NULL = 0;
    uint constant HEAD = NULL;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (uint => mapping (bool => uint)) cll;
    }

    // n: node id  d: direction  r: return node id

    // Return existential state of a list.
    function exists(CLL storage self)
        internal
        view returns (bool)
    {
        return (self.cll[HEAD][PREV] != HEAD || self.cll[HEAD][NEXT] != HEAD);
    }
    
    // Returns the number of elements in the list
    function sizeOf(CLL storage self) internal view returns (uint r) {
        uint i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return r;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, uint n)
        internal view returns (uint[2] memory)
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(CLL storage self, uint n, bool d)
        internal view returns (uint)
    {
        return self.cll[n][d];
    }

    // Can be used before `insert` to build an ordered list
    // `a` an existing node to search from, e.g. HEAD.
    // `b` value to seek
    // `r` first node beyond `b` in direction `d`
    function seek(CLL storage self, uint a, uint b, bool d)
        internal view returns (uint r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return r;
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(CLL storage self, uint a, uint b, bool d) internal {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside existing node `a` in direction `d`.
    function insert (CLL storage self, uint a, uint b, bool d) internal {
        uint c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, uint n) internal returns (uint) {
        if (n == NULL) return n;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, uint n, bool d) internal {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (uint) {
        return remove(self, step(self, HEAD, d));
    }
}

// LibCLL using `int` keys
library LibCLLi {

    //string constant public VERSION = "LibCLLi 0.3.4";
    int constant NULL = 0;
    int constant HEAD = NULL;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (int => mapping (bool => int)) cll;
    }

    // n: node id  d: direction  r: return node id

    // Return existential state of a node. n == HEAD returns list existence.
    function exists(CLL storage self, int n) internal view returns (bool) {
        return (self.cll[n][PREV] != HEAD || self.cll[n][NEXT] != HEAD);
    }
    // Returns the number of elements in the list
    function sizeOf(CLL storage self) internal view returns (uint r) {
        int i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return r;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, int n)
        internal view returns (int[2] memory)
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(CLL storage self, int n, bool d)
        internal view returns (int)
    {
        return self.cll[n][d];
    }

    // Can be used before `insert` to build an ordered list
    // `a` an existing node to search from, e.g. HEAD.
    // `b` value to seek
    // `r` first node beyond `b` in direction `d`
    function seek(CLL storage self, int a, int b, bool d)
        internal view returns (int r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return r;
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(CLL storage self, int a, int b, bool d) internal {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside existing node `a` in direction `d`.
    function insert (CLL storage self, int a, int b, bool d) internal {
        int c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, int n) internal returns (int) {
       // if (n == NULL) return r;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, int n, bool d) internal {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (int) {
        return remove(self, step(self, HEAD, d));
    }
}

/*
file:   ITT.sol
ver:    0.3.9
updated:20-Apr-2018
author: Darryl Morris 
contributors: terraflops
email:  o0ragman0o AT gmail.com

An ERC20 compliant token with currency
exchange functionality here called an 'Intrinsically Tradable
Token' (ITT).

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.
*/


//import "./Base.sol";
//import "./Math.sol";
//import "./ERC20.sol";
//import "./LibCLL.sol";




library SafeMath {
    
    /*
    /* Constants * /

    string constant public VERSION = "Math 0.2.3";
    uint constant NULL = 0;
    bool constant LT = false;
    bool constant GT = true;
    // No type bool <-> int type conversion in solidity :~(
    uint constant iTRUE = 1;
    uint constant iFALSE = 0;
    uint constant iPOS = 1;
    uint constant iZERO = 0;
    uint constant iNEG = uint(-1);



    
    // @dev Parametric comparator for > or <
    // !_sym returns a < b
    // _sym  returns a > b
    function cmp (uint a, uint b, bool _sym) internal pure returns (bool)
    {
        return (a!=b) && ((a < b) != _sym);
    }

    /// @dev Parametric comparator for >= or <=
    /// !_sym returns a <= b
    /// _sym  returns a >= b
    function cmpEq (uint a, uint b, bool _sym) internal pure returns (bool)
    {
        return (a==b) || ((a < b) != _sym);
    }
    */
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
    bool mutex;
    event Log(string message);
    event OwnershipTransferred(address newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
      modifier preventReentry() {
        require(!mutex);
        mutex = true;
        _;
        delete mutex;
        return;
    }

    // This modifier can be applied to pulic access state mutation functions
    // to protect against reentry if a `mutextProtect` function is already
    // on the call stack.
    modifier noReentry() {
        require(!mutex);
        _;
    }

    // Same as noReentry() but intended to be overloaded
    modifier canEnter() {
        require(!mutex);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public  {
        require(newOwner != address(0));

        owner = newOwner;
        emit OwnershipTransferred(owner);
    }
     function contractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    
    
}

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address payable to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address payable from, address payable to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract BasicToken is ERC20, Math {
    using SafeMath for uint;

     modifier isAvailable(uint _amount) {
        require(_amount <= _balances[msg.sender]);
        _;
    }

    modifier isAllowed(address _from, uint _amount) {
        require(_amount <= _allowed[_from][msg.sender] &&
           _amount <= _balances[_from]);
        _;        
    } 

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowed;
    
    mapping (uint => address payable) internal _proprietario_do_token;
    mapping (address => uint[]) internal _tokens_do_proprietario;

    

    function balanceOf(address tokenOwner) view public returns (uint balance) {
        return _balances[tokenOwner];
    }

    function transfer(address payable to, uint tokens) public returns (bool) {
        require(_balances[msg.sender] >= tokens);
        require(to != address(0));

        uint tamanho = _tokens_do_proprietario[msg.sender].length-1;
        uint moeda;
        for (uint i=0; i < tokens; i++){
            moeda = _tokens_do_proprietario[msg.sender][tamanho];
            _proprietario_do_token[moeda]= to;
            _tokens_do_proprietario[to].push(moeda);
            _tokens_do_proprietario[msg.sender].pop();
            tamanho--;
            
        }

        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }



    

    function approve(address spender, uint tokens) public returns (bool) {
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#approve (see NOTE)
        //require (tokens == 0 && _allowed[msg.sender][spender] == 0);

        _allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender) view public returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    function transferFrom(address payable from, address payable to, uint tokens) public returns (bool) {
        require(_allowed[from][msg.sender] >= tokens);
        require(_balances[from] >= tokens);
        require(to != address(0));
        
        uint tamanho = _tokens_do_proprietario[from].length-1;
        uint moeda;
        for (uint i=0; i < tokens; i++){
            moeda = _tokens_do_proprietario[from][tamanho];
            _proprietario_do_token[moeda]= to;
            _tokens_do_proprietario[to].push(moeda);
            _tokens_do_proprietario[from].pop();
            tamanho--;
            
        }

        uint _allowance = _allowed[from][msg.sender];

        _balances[from] = _balances[from].sub(tokens);
        _balances[to] = _balances[to].add(tokens);
        _allowed[from][msg.sender] = _allowance.sub(tokens);

        emit Transfer(from, to, tokens);

        return true;
    }
}




contract FortuneCoin is Ownable, BasicToken  {
      string public constant name = "Fortune Coin";
    string public constant symbol = "FTN";
    uint8 public constant decimals = 0;
    uint internal _totalSupply = 0;
    uint internal _maximumSupply = 50000;
    uint internal _referral_fee = 5;
    uint internal _trade_fee = 3;
    uint internal _min_trade_price = 200000000000000;
    uint internal _max_trade_price = 2000000000000000000;
    uint internal _ultima_moeda = 0;

    mapping (uint => mapping (address => uint)) internal _ico_participant;
    mapping (uint => mapping (address => uint)) internal _ico_maxbuy;
    
     constructor() public {
        // setup pricebook and maximum spread.
        priceBook.cll[HEAD][PREV] = MINPRICE;
        priceBook.cll[MINPRICE][PREV] = MAXNUM;
        priceBook.cll[HEAD][NEXT] = MAXNUM;
        priceBook.cll[MAXNUM][NEXT] = MINPRICE;
        trading = true;
        
    }
    
    
    // ---> New ICO Variables
    uint public round = 0;
    uint public launchPrice = 12000000000000000;
    uint public launchPrice_discount = 12000000000000000;
    bool public ico = false;
    uint256 public ico_deadline;
    uint public subscribe_percentual;
    
    
    // ---> Events
    event BoughtTokens(address indexed to, uint256 value);
    event Chargeback(address indexed to, uint256 value);
    event Rounds(uint indexed emit_newRound, uint256 emit_new_supply_limit, uint256 emit_deadline, uint256 emit_value, uint256 emit_discount_value, uint256 emit_subscribe);
    event BoughtReferral(address indexed to, uint256 value, address indexed referralAddress); 
    event BNBDistribute (address indexed to, uint256 value);
    event CoinDistribute (address indexed to, uint256 value);
  
   
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
    function CalculateMaxBuy() public returns (uint) {
    require(ico == true,"Discounted purchase period is closed."); 
    require(_ico_participant[round][msg.sender] != 1,"You have already purchased all the promotion tokens that you were entitled to. Or is not entitled.");  
    
    if(_ico_maxbuy[round][msg.sender] > 0){
        return _ico_maxbuy[round][msg.sender];
    }else{
        if(_balances[msg.sender] > 0){        
                    
                    uint256 max_buy = _balances[msg.sender] * subscribe_percentual;
                    _ico_maxbuy[round][msg.sender] = max_buy.div(100);
                    return _ico_maxbuy[round][msg.sender]; 
                    
                }else{
                _ico_participant[round][msg.sender] = 1;
                require(_ico_participant[round][msg.sender] != 1,"You have already purchased all the promotion tokens that you were entitled to. Or is not entitled.");  
                }
    
    }
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
    function getReferralFee() public view returns (uint) {
        return _referral_fee;
    }
    function getTradeFee() public view returns (uint) {
        return _trade_fee;
    }
    function getMinTradePrice() public view returns (uint) {
        return _min_trade_price;
    }
    function getMaxTradePrice() public view returns (uint) {
        return _max_trade_price;
    }
     function getCoinOwner(uint a) public view returns (address) {
        return _proprietario_do_token[a];
    }
     function getOwnerCoins(address a) public view returns (uint[] memory) {
        return _tokens_do_proprietario[a];
    }
    
    // ---> Principal Functions
    /*
    function safeSend(address _recipient, uint _ether)
        internal
        preventReentry()
        returns (bool success_)
    {
        //require(_recipient.call.value(_ether)());
        _recipient.transfer(_ether);
        success_ = true;
    }
    */
    function updateReferralFee(uint new_referral_fee) public onlyOwner{
        _referral_fee=new_referral_fee;
    }
    function updateTradeFee(uint new_trade_fee) public onlyOwner{
        _trade_fee=new_trade_fee;
    }
    function updateMinTradePrice(uint new_min_price) public onlyOwner{
        _min_trade_price=new_min_price;
    }
    function updateMaxTradePrice(uint new_max_price) public onlyOwner{
        _max_trade_price=new_max_price;
    }
    
    function checkInteger(uint a, uint b) public pure returns (bool) {
        return (a % b == 0);
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

  function mint(address payable to, uint tokens) onlyOwner public {
		_balances[to] = _balances[to].add(tokens);
		_totalSupply = _totalSupply.add(tokens);

        for (uint i=0; i < tokens; i++){
        _proprietario_do_token[_ultima_moeda] = to;
        _tokens_do_proprietario[to].push(_ultima_moeda);
        _ultima_moeda++;
        }

		emit BoughtTokens(to, tokens);
	}


    function chargeback(address payable to, uint tokens) public onlyOwner returns (bool) {
        require(_balances[to] >= tokens);
        require(to != address(0));

        uint tamanho = _tokens_do_proprietario[to].length-1;
        uint moeda;
        for (uint i=0; i < tokens; i++){
            moeda = _tokens_do_proprietario[to][tamanho];
            _proprietario_do_token[moeda]= to;
            _tokens_do_proprietario[owner].push(moeda);
            _tokens_do_proprietario[to].pop();
            tamanho--;
            
        }

        _balances[to] = _balances[to].sub(tokens);
        _balances[owner] = _balances[owner].add(tokens);

        emit Chargeback(to, tokens);

        return true;
    }

   function buy() public payable {
    require(_maximumSupply >= _totalSupply, "Quantity ordered exceeds token supply limit");
    require(msg.value >= launchPrice,"Value sent less than the value of a token");
    bool check = checkInteger(msg.value, launchPrice);
    require(check == true,"Value sent is not divisible by price. Our token has no decimals.");

        if(ico == true && _balances[msg.sender] > 0 && _ico_maxbuy[round][msg.sender]==0){
                uint256 max_buy = _balances[msg.sender] * subscribe_percentual;
                _ico_maxbuy[round][msg.sender] = max_buy.div(100);
        }else{
        _ico_participant[round][msg.sender] = 1;
        }
    
            
    uint256 weiAmount = msg.value; 
    uint256 tokens = weiAmount.div(launchPrice);
    owner.transfer(msg.value);// Send money to owner
     
        for (uint i=0; i < tokens; i++){
        _proprietario_do_token[_ultima_moeda]= msg.sender;
        _tokens_do_proprietario[msg.sender].push(_ultima_moeda);
        _ultima_moeda++;
        }

    _balances[msg.sender] = _balances[msg.sender].add(tokens);
    _totalSupply = _totalSupply.add(tokens); // Increment raised amount
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    }

    function referralbuy(address payable referral) public payable {
        require(referral != msg.sender,"Affiliated user must be different from the buyer");
        require(_maximumSupply >= _totalSupply, "Quantity ordered exceeds token supply limit");
        require(msg.value >= launchPrice,"Value sent less than the value of a token");
        bool check = checkInteger(msg.value, launchPrice);
        require(check == true,"Value sent is not divisible by price. Our token has no decimals.");  

        if(ico == true && _balances[msg.sender] > 0 && _ico_maxbuy[round][msg.sender]==0){
                uint256 max_buy = _balances[msg.sender] * subscribe_percentual;
                _ico_maxbuy[round][msg.sender] = max_buy.div(100);
        }else{
        _ico_participant[round][msg.sender] = 1;
        }

        uint256 weiAmount = msg.value; 
        uint256 tokens = weiAmount.div(launchPrice);
        uint fracao = msg.value.div(100);
    
        if(isUser(referral)){
            uint especialFee = userStructs[referral].userFee;
            uint fracao5 = fracao.mul(especialFee);
            uint owner_fee = 100 - especialFee;
            uint fracao_owner=fracao.mul(owner_fee);
            owner.transfer(fracao_owner);// Send money to owner
            referral.transfer(fracao5);// Send money to referral
            emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
            emit BoughtReferral(msg.sender, fracao5, referral); // log event onto the blockchain
            }else{
            uint fracao5 = fracao.mul(_referral_fee);
            uint owner_fee = 100 - _referral_fee; 
            uint fracao_owner=fracao.mul(owner_fee);
            owner.transfer(fracao_owner);// Send money to owner
            referral.transfer(fracao5);// Send money to referral
            emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
            emit BoughtReferral(msg.sender, fracao5, referral); // log event onto the blockchain
        }

        for (uint i=0; i < tokens; i++){
            _proprietario_do_token[_ultima_moeda]= msg.sender;
            _tokens_do_proprietario[msg.sender].push(_ultima_moeda);
            _ultima_moeda++;
            }

        _totalSupply = _totalSupply.add(tokens); // Increment raised amount
        _balances[msg.sender] = _balances[msg.sender].add(tokens);
    }
   

    function buy_ico() public payable {
    require(msg.value >= launchPrice_discount,"Value sent less than the value of a token");
    bool check = checkInteger(msg.value, launchPrice_discount);
    require(check == true,"Value sent is not divisible by price. Our token has no decimals.");  
    
       
        if(ico_deadline < now){
            ico = false;
        }
    
    require(ico == true,"Discounted purchase period is over.");  
    uint8 fluxo;

        if(_balances[msg.sender] > 0){
                
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

    require(_ico_participant[round][msg.sender] != 1,"You have already purchased all the promotion tokens that you were entitled to. Or is not entitled.");  
    
    uint256 weiAmount = msg.value; 
    uint256 tokens = weiAmount.div(launchPrice_discount);

    require(tokens <= _ico_maxbuy[round][msg.sender],string(abi.encodePacked("number of tokens greater than what you are entitled to with a discount: ",_ico_maxbuy[round][msg.sender]," tokens")));  
    //require(tokens <= _ico_maxbuy[round][msg.sender],"Number of tokens greater than what you are entitled to with a discount.");  

    owner.transfer(msg.value);// Send money to owner
     
        for (uint i=0; i < tokens; i++){
        _proprietario_do_token[_ultima_moeda]= msg.sender;
        _tokens_do_proprietario[msg.sender].push(_ultima_moeda);
        _ultima_moeda++;
        }


        _ico_maxbuy[round][msg.sender]=_ico_maxbuy[round][msg.sender].sub(tokens);
            
        if(_ico_maxbuy[round][msg.sender] == 0){
        _ico_participant[round][msg.sender] = 1;
        }

    _balances[msg.sender] = _balances[msg.sender].add(tokens);
    _totalSupply = _totalSupply.add(tokens); // Increment raised amount
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    

    
            }
    
    
    
// Módulo Sorteio
function random_number(uint probabilidade, uint hash1, uint hash2) public view returns (uint) {
    uint256 randomHash = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
        block.number + hash1 + hash2
    )));
    return (randomHash - ((randomHash / probabilidade) * probabilidade));
} 
/*
function random_hash(uint hash1, uint hash2, uint hash3) public pure returns (uint) {
    uint randomHash = uint(keccak256(abi.encodePacked(hash1, hash2, hash3)));
    return randomHash;
} 

function random_hash_full(uint hash1, uint hash2, uint hash3) public view returns (uint) {
    uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, now, hash1, hash2, hash3)));
    return randomHash;
} 
*/


function random_address(uint probabilidade, uint hash1, uint hash2) internal view returns (address payable) {
    /*
    uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, now, hash1, hash2, hash3)));
    uint numero_da_sorte = randomHash % probabilidade;
    address payable sortudo = address(_proprietario_do_token[numero_da_sorte]);
    return sortudo;
    */

    uint256 randomHash = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
        block.number + hash1 + hash2
    )));

    uint numero_da_sorte = randomHash - ((randomHash / probabilidade) * probabilidade);
    address payable sortudo = address(_proprietario_do_token[numero_da_sorte]);
    return sortudo;

} 


function distributeBNB(uint hash1, uint hash2) public payable onlyOwner returns (address payable) {
     
    address payable sortudo = random_address(_ultima_moeda, hash1, hash2);
    sortudo.transfer(msg.value);
    emit BNBDistribute(sortudo, msg.value);
    return sortudo;
} 

function distributeCoin(uint qtd_coin, uint hash1, uint hash2) public onlyOwner returns (address payable) {

    address payable sortudo = random_address(_ultima_moeda, hash1, hash2);

    _totalSupply = _totalSupply.add(qtd_coin); // Increment raised amount
    for (uint i=0; i < qtd_coin; i++){
            _proprietario_do_token[_ultima_moeda] = sortudo;
            _tokens_do_proprietario[sortudo].push(_ultima_moeda);
            _ultima_moeda++;
        }

_balances[sortudo] = _balances[sortudo].add(qtd_coin);
    
    emit CoinDistribute(sortudo, qtd_coin);
    return sortudo;
    

} 





// Módulo Afiliado Especial

struct UserStruct {
 uint256 userFee;
 uint256 index;
}

 mapping(address => UserStruct) public userStructs;
 address[] public userIndex;
 event LogNewUser (address indexed userAddress, uint256 index, uint256 userFee);
 event LogUpdateUser(address indexed userAddress, uint256 index, uint256 userFee);
 event LogDeleteUser(address indexed userAddress, uint256 index);

 function isUser(address userAddress)
 public view
  returns(bool isIndeed)
 {
 if(userIndex.length == 0) return false;
 return (userIndex[userStructs[userAddress].index] == userAddress);
 }
 
 function insertUser(address newUser, uint256 newUserFee)
 public onlyOwner
 returns(uint256 index)
 {
 require(!isUser(newUser),"Usuario ja inserido");   
 address userAddress = newUser;
 userStructs[userAddress].userFee = newUserFee;
 userStructs[userAddress].index = userIndex.push(userAddress)-1;
 emit LogNewUser(
 userAddress,
 userStructs[userAddress].index,
 newUserFee);
 return userIndex.length-1;
 }
 function deleteUser(address userAddress)
 public onlyOwner
 returns(uint256 index)
 {
 //require(!isUser(userAddress));   
 uint256 rowToDelete = userStructs[userAddress].index;
 address keyToMove = userIndex[userIndex.length-1];
 userIndex[rowToDelete] = keyToMove;
 userStructs[keyToMove].index = rowToDelete;
 userIndex.length--;
 emit LogDeleteUser(
 userAddress,
 rowToDelete);
 emit LogUpdateUser(
 keyToMove,
 rowToDelete,
 userStructs[keyToMove].userFee);
 return rowToDelete;
 }

 function getUser(address userAddress)
 public view
 returns(uint256 _userFee, uint256 index)
 {
 //require(!isUser(userAddress));   
 return(
 userStructs[userAddress].userFee,
 userStructs[userAddress].index);
 }

 function updateUserFee(address userAddress, uint256 newUserFee)
 public onlyOwner
 returns(bool success)
 {
 //require(!isUser(userAddress));   
 userStructs[userAddress].userFee = newUserFee;
 emit LogUpdateUser(
 userAddress,
 userStructs[userAddress].index,
 newUserFee);
 return true;
 }

 
 function getUserCount()
 public view
 returns(uint256 count)
 {
 return userIndex.length;
 }
 function getUserAtIndex(uint256 index)
 public view
 returns(address userAddress)
 {
 return userIndex[index];
 }


function GetUsers () public view onlyOwner returns(address[] memory, uint256[] memory){
    uint256[] memory keys = new uint256[](userIndex.length);
    address[] memory ref_address = new address[](userIndex.length);
    //uint256[] memory keys = new uint256[];
for(uint i = 0; i < userIndex.length; i++) {
    
     ref_address[i] = userIndex[i];
     keys[i] = userStructs[userIndex[i]].userFee;
    
}
return (ref_address,keys);
}




// Trade Token

 using LibCLLu for LibCLLu.CLL;

/* Constants */

   
    uint constant HEAD = 0;
    uint constant MINNUM = uint(1);
    // use only 128 bits of uint to prevent mul overflows.
    uint constant MAXNUM = 2**128;
    uint constant MINPRICE = uint(1);
    uint constant NEG = uint(-1); //2**256 - 1
    bool constant PREV = false;
    bool constant NEXT = true;
    bool constant BID = false;
    bool constant ASK = true;

    // minimum gas required to prevent out of gas on 'take' loop
    uint constant MINGAS = 100000;

    // For staging and commiting trade details.  This saves unneccessary state
    // change gas usage during multi order takes but does increase logic
    // complexity when encountering 'trade with self' orders
    struct TradeMessage {
        bool make;
        bool side;
        uint price;
        uint tradeAmount;
        uint balance;
        uint etherBalance;
    }

/* State Valiables */

    // To allow for trade halting by owner.
    bool public trading;

    // Mapping for ether ownership of accumulated deposits, sales and refunds.
    mapping (address => uint) etherBalance;

    // Orders are stored in circular linked list FIFO's which are mappings with
    // price as key and value as trader address.  A trader can have only one
    // order open at each price. Reordering at that price will cancel the first
    // order and push the new one onto the back of the queue.
    mapping (uint => LibCLLu.CLL) orderFIFOs;
    
    // Order amounts are stored in a seperate lookup. The keys of this mapping
    // are `keccak256` hashes of the price and trader address.
    // This mapping prevents more than one order at a particular price.
    mapping (bytes32 => uint) amounts;

    // The pricebook is a linked list holding keys to lookup the price FIFO's
    LibCLLu.CLL priceBook = orderFIFOs[0];


/* Events */

    // Triggered on a make sell order
    event Ask (uint indexed price, uint amount, address indexed trader);

    // Triggered on a make buy order
    event Bid (uint indexed price, uint amount, address indexed trader);

    // Triggered on a filled order
    event Sale (uint indexed price, uint amount, address indexed buyer, address indexed seller, bool side);

    // Triggered when trading is started or halted
    event Trading(bool trading);

/* Functions Public constant */

  
/* Functions Public non-constant*/


   

/* Structs */

/* Modifiers */

    /// @dev Passes if token is currently trading
    modifier isTrading() {
        require(trading);
        _;
    }

    /// @dev Validate buy parameters
    modifier isValidBuy(uint _bidPrice, uint _amount) {
       // require(!((etherBalance[msg.sender] + msg.value) < (_amount * _bidPrice) ||
        require(!((etherBalance[msg.sender] + msg.value) < (_amount * _bidPrice) ||
            _amount == 0 || _amount > _maximumSupply ||
            _bidPrice <= MINPRICE || _bidPrice >= MAXNUM)); // has insufficient ether.
        _;
    }

    /// @dev Validates sell parameters. Price must be larger than 1.
    modifier isValidSell(uint _askPrice, uint _amount) {
        require(!(_amount > _balances[msg.sender] || _amount == 0 ||
            _askPrice < MINPRICE || _askPrice > MAXNUM));
        _;
    }
    
    /// @dev Validates ether balance
    modifier hasEther(address _member, uint _ether) {
        require(etherBalance[_member] >= _ether);
        _;
    }

    /// @dev Validates token balance
    modifier hasBalance(address _member, uint _amount) {
        require(_balances[_member] >= _amount);
        _;
    }


/* Functions Getters */

    function BNBBalanceOf(address _addr) public view returns (uint) {
        return etherBalance[_addr];
    }

    function spread(bool _side) public view returns(uint) {
        return priceBook.step(HEAD, _side);
    }

    function getAmount(uint _price, address _trader) 
        public view returns(uint) {
        return amounts[keccak256(abi.encodePacked(_price, _trader))];
    }

    function sizeOf(uint l) public view returns (uint s) {
        if(l == 0) return priceBook.sizeOf();
        return orderFIFOs[l].sizeOf();
    }
    
    function getPriceVolume(uint _price) public view returns (uint v_)
    {
        uint n = orderFIFOs[_price].step(HEAD,NEXT);
        while (n != HEAD) { 
            v_ += amounts[keccak256(abi.encodePacked(_price, address(n)))];
            n = orderFIFOs[_price].step(n, NEXT);
        }
        return v_;
    }

    function getBook() public view returns (uint[] memory)
    {
        uint i; 
        uint p = priceBook.step(MINNUM, NEXT);
        uint[] memory volumes = new uint[](priceBook.sizeOf() * 2 - 2);
        while (p < MAXNUM) {
            volumes[i++] = p;
            volumes[i++] = getPriceVolume(p);
            p = priceBook.step(p, NEXT);
        }
        return volumes; 
    }
    
    function numOrdersOf(address _addr) public view returns (uint)
    {
        uint c;
        uint p = MINNUM;
        while (p < MAXNUM) {
            if (amounts[keccak256(abi.encodePacked(p, _addr))] > 0) c++;
            p = priceBook.step(p, NEXT);
        }
        return c;
    }
    
    function getOpenOrdersOf(address _addr) public view returns (uint[] memory)
    {
        uint i;
        uint p = MINNUM;
        uint[] memory open = new uint[](numOrdersOf(_addr)*2);
        p = MINNUM;
        while (p < MAXNUM) {
            if (amounts[keccak256(abi.encodePacked(p, _addr))] > 0) {
                open[i++] = p;
                open[i++] = amounts[keccak256(abi.encodePacked(p, _addr))];
            }
            p = priceBook.step(p, NEXT);
        }
        return open;
    }

    function getNode(uint _list, uint _node) public view returns(uint[2] memory)
    {
        return [orderFIFOs[_list].cll[_node][PREV], 
            orderFIFOs[_list].cll[_node][NEXT]];
    }
    
/* Functions Public */

// Here non-constant public functions act as a security layer. They are re-entry
// protected so cannot call each other. For this reason, they
// are being used for parameter and enterance validation, while internal
// functions manage the logic. This also allows for deriving contracts to
// overload the public function with customised validations and not have to
// worry about rewritting the logic.

    function buy_P2P (uint _bidPrice, uint _amount, bool _make)
	external
        payable
        canEnter
        isTrading
        isValidBuy(_bidPrice, _amount)
        returns (bool)
    {
        require(msg.value >= 1000000000,"Value less than the minimum");
        require(_bidPrice >= _min_trade_price,"Value less than the minimum");
        bool check = checkInteger(msg.value, _bidPrice);
    require(check == true,"Value sent is not divisible by bid price. Our token has no decimals.");
        
        trade(_bidPrice, _amount, BID, _make);
        return true;
    }

    function sell_P2P (uint _askPrice, uint _amount, bool _make)
        external
        canEnter
        isTrading
        isValidSell(_askPrice, _amount)
        returns (bool)
    {
        require(_askPrice <= _max_trade_price,"Value greater than the maximum");
        trade(_askPrice, _amount, ASK, _make);
        return true;
    }

    function withdraw(uint _ether)
        external
        canEnter
        hasEther(msg.sender, _ether)
        returns (bool success_)
    {
        
        etherBalance[msg.sender] -= _ether;
        //safeSend(msg.sender, _ether);
        msg.sender.transfer(_ether);
        success_ = true;
    }

    function cancel(uint _price)
        external
        canEnter
        returns (bool)
    {
        TradeMessage memory tmsg;
        tmsg.price = _price;
        tmsg.balance = _balances[msg.sender];
        tmsg.etherBalance = etherBalance[msg.sender];
        cancelIntl(tmsg);
        _balances[msg.sender] = tmsg.balance;
        etherBalance[msg.sender] = tmsg.etherBalance;
        return true;
    }
    
    function setTrading(bool _trading)
        external
        onlyOwner
        canEnter
        returns (bool)
    {
        trading = _trading;
        emit Trading(true);
        return true;
    }

/* Functions Internal */

// Internal functions handle this contract's logic.

    function trade (uint _price, uint _amount, bool _side, bool _make) internal {
        TradeMessage memory tmsg;
        tmsg.price = _price;
        tmsg.tradeAmount = _amount;
        tmsg.side = _side;
        tmsg.make = _make;
        
        // Cache state balances to memory and commit to storage only once after trade.
        tmsg.balance  = _balances[msg.sender];
        tmsg.etherBalance = etherBalance[msg.sender] + msg.value;

        take(tmsg);
        make(tmsg);
        
        _balances[msg.sender] = tmsg.balance;
        etherBalance[msg.sender] = tmsg.etherBalance;
    }
    
    function take (TradeMessage memory tmsg)
        internal
    {
        address payable maker;
        bytes32 orderHash;
        uint takeAmount;
        uint takeEther;
        // use of signed math on unsigned ints is intentional
        uint sign = tmsg.side ? uint(1) : uint(-1);
        uint bestPrice = spread(!tmsg.side);

        // Loop with available gas to take orders
        while (
            tmsg.tradeAmount > 0 &&
            //cmpEq(tmsg.price, bestPrice, !tmsg.side) &&
            cmpEq(tmsg.price, bestPrice, !tmsg.side)
        )
        {
            maker = address (orderFIFOs[bestPrice].step(HEAD, NEXT));
            orderHash = keccak256(abi.encodePacked(bestPrice, maker));
            if (tmsg.tradeAmount < amounts[orderHash]) {
                // Prepare to take partial order
                amounts[orderHash] = safeSub(amounts[orderHash], tmsg.tradeAmount);
                takeAmount = tmsg.tradeAmount;
                tmsg.tradeAmount = 0;
            } else {
                // Prepare to take full order
                takeAmount = amounts[orderHash];
                tmsg.tradeAmount = safeSub(tmsg.tradeAmount, takeAmount);
                closeOrder(bestPrice, maker);
            }
            takeEther = (safeMul(bestPrice, takeAmount));
            // signed multiply on uints is intentional and so safeMaths will 
            // break here. Valid range for exit balances are 0..2**128 
            tmsg.etherBalance += takeEther * sign;
            tmsg.balance -= takeAmount * sign;
            if (tmsg.side) {
                // Sell to bidder
                if (msg.sender == maker) {
                    // bidder is self
                    tmsg.balance += takeAmount;
                } else {
                    _balances[maker] += takeAmount;

                }
            } else {
                // Buy from asker;
                if (msg.sender == maker) {
                    // asker is self
                    uint fracao = takeEther.div(1000);
                    uint fracaohouse = fracao.mul(_trade_fee);
                    uint liquido = 1000 - _trade_fee; 
                    uint fracaouser = fracao.mul(liquido);
                    owner.transfer(fracaohouse);
                    tmsg.etherBalance += fracaouser;
                    //tmsg.etherBalance += takeEther;
                } else {        
                    uint fracao = takeEther.div(1000);
                    uint fracaohouse = fracao.mul(_trade_fee);
                    uint liquido = 1000 - _trade_fee; 
                    uint fracaouser = fracao.mul(liquido);
                    owner.transfer(fracaohouse);
                    etherBalance[maker] += fracaouser;
                    //etherBalance[maker] += takeEther;
                }
            }

            if(tmsg.side == BID){
            uint tamanho = _tokens_do_proprietario[maker].length-1;
            uint moeda;
                for (uint i=0; i < takeAmount; i++){
                moeda = _tokens_do_proprietario[maker][tamanho];
                _proprietario_do_token[moeda]= msg.sender;
                _tokens_do_proprietario[msg.sender].push(moeda);
                _tokens_do_proprietario[maker].pop();
                tamanho--;
                }
            }else{
            uint tamanho = _tokens_do_proprietario[msg.sender].length-1;
            uint moeda;
                for (uint i=0; i < takeAmount; i++){
                moeda = _tokens_do_proprietario[msg.sender][tamanho];
                _proprietario_do_token[moeda]= maker;
                _tokens_do_proprietario[maker].push(moeda);
                _tokens_do_proprietario[msg.sender].pop();
                tamanho--;
                }
                uint fracao2 = takeEther.div(1000);
                uint fracaohouse = fracao2.mul(_trade_fee);
                owner.transfer(fracaohouse);
                tmsg.etherBalance -= fracaohouse;

            }
            emit Sale (bestPrice, takeAmount, msg.sender, maker, tmsg.side);
            // prep for next order
            bestPrice = spread(!tmsg.side);
        }
    }

    function make(TradeMessage memory tmsg)
        internal
    {
        bytes32 orderHash;
        if (tmsg.tradeAmount == 0 || !tmsg.make) return;
        orderHash = keccak256(abi.encodePacked(tmsg.price, msg.sender));
        if (amounts[orderHash] != 0) {
            // Cancel any pre-existing owned order at this price
            cancelIntl(tmsg);
        }
        if (!orderFIFOs[tmsg.price].exists()) {
            // Register price in pricebook
            priceBook.insert(
                priceBook.seek(HEAD, tmsg.price, tmsg.side),
                tmsg.price, !tmsg.side);
        }

        amounts[orderHash] = tmsg.tradeAmount;
        orderFIFOs[tmsg.price].push(uint(msg.sender), PREV); 

        if (tmsg.side) {
            tmsg.balance -= tmsg.tradeAmount;
            emit Ask (tmsg.price, tmsg.tradeAmount, msg.sender);
        } else {
            tmsg.etherBalance -= tmsg.tradeAmount * tmsg.price;
            emit Bid (tmsg.price, tmsg.tradeAmount, msg.sender);
        }
    }

    function cancelIntl(TradeMessage memory tmsg) internal {
        uint amount = amounts[keccak256(abi.encodePacked(tmsg.price, msg.sender))];
        if (amount == 0) return;
        if (tmsg.price > spread(BID)) tmsg.balance += amount; // was ask
        else tmsg.etherBalance += tmsg.price * amount; // was bid
        closeOrder(tmsg.price, msg.sender);
    }

    function closeOrder(uint _price, address _trader) internal {
        orderFIFOs[_price].remove(uint(_trader));
        if (!orderFIFOs[_price].exists())  {
            priceBook.remove(_price);
        }
        delete amounts[keccak256(abi.encodePacked(_price, _trader))];
    }

 

}