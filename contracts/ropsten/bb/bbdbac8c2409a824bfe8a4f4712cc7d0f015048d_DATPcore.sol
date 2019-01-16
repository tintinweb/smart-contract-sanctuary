pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
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

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DATPcore{
    
    using SafeMath for uint256;
    address owner = msg.sender;
    address feeToken;
    
    mapping (address => uint256) balances;
    mapping (address => bool) verifStatus;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Distr(address indexed to, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function setFeeTokenAddress(address newFeeToken) onlyOwner{
        if (newFeeToken != address(0)) {
            feeToken = newFeeToken;
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
    
    function changeVerify(address userAddress) onlyOwner {
        require(verifStatus[userAddress] == false,"User already verified");
        verifStatus[userAddress] = true;
    }
    
    function checkVerify(address userAddress) constant public returns (bool) {
        return verifStatus[userAddress];
    }
    
    struct txdata{
        address party1;
        address party2;
        address contractTokenAddress;
        string symbol;
        uint256 decimal;
        uint256 amount;
        uint256 rateInWei;
        uint256 savedEth;
        uint256 savedToken;
        bool ongoingtx;
        bool payedfee;
    }
    mapping (bytes32 => txdata) datakeeper;
    bytes32[] public datatx;
    
    struct listedToken{
        string name;
        string symbol;
        uint256 decimal;
        string introduction;
        string website;
        string logUrl;
    }
    mapping (address => listedToken) listeddata;
    address[] public tokendata;
    
    function() payable public{
        if(msg.data.length == 0){
            require(msg.data.length != 0);
        }
    }
    
    function postListed(address _contractAddress, string _names, string _symbols, uint _decimals, string _introduction, string _website, string _logoURL) onlyOwner{
        var l = listeddata[_contractAddress];
        l.name = _names;
        l.symbol = _symbols;
        l.decimal = _decimals;
        l.introduction = _introduction;
        l.website = _website;
        l.logUrl = _logoURL;
        tokendata.push(_contractAddress) -1;
    }
    
    function getTokenListed() view public returns(address[]){
        return tokendata;
    }
    
    function getTokenListedByAddress(address _contractAddress) view public returns(string, string, uint, string, string, string){
        var l = listeddata[_contractAddress];
        return(l.name,
        l.symbol,
        l.decimal,
        l.introduction,
        l.website,
        l.logUrl);
    }
    
    function postTX(address _contractAddress, string _symbols, uint256 _decimals, uint256 _amountToken, uint256 _rateTokenWei) payable public{
        uint256 datacheck= _amountToken * _rateTokenWei;
        require(verifStatus[msg.sender] = true && _amountToken > 0 && _rateTokenWei > 0 && msg.value == datacheck);
        bytes32 newtxcode = sha256(msg.sender, now);
        var u = datakeeper[newtxcode];
        u.party1 = msg.sender;
        u.contractTokenAddress = _contractAddress;
        u.symbol = _symbols;
        u.decimal = _decimals;
        u.amount = _amountToken;
        u.rateInWei = _rateTokenWei;
        u.savedEth = msg.value;
        u.ongoingtx = false;
        u.payedfee = false;
        datatx.push(newtxcode) -1;
    }
    
    function cancelTXwithCode(bytes32 _codeTXid) public{
        var u = datakeeper[_codeTXid];
        require(verifStatus[msg.sender] = true && msg.sender == u.party1 && u.ongoingtx == false && u.payedfee == false && u.party2 == 0x0000000000000000000000000000000000000000);
        u.party2 = u.party1;
        u.savedToken = 0;
        u.ongoingtx = true;
        u.payedfee = true;
        u.party1.transfer(u.savedEth);
    }
    
    function cancelOngoingTxByAdmin(bytes32 _codeTXid) onlyOwner returns (bool){
        var u = datakeeper[_codeTXid];
        require(u.ongoingtx == true && u.payedfee == false);
        ERC20 token = ERC20(u.contractTokenAddress);
        address desteth = u.party1;
        address desttoken = u.party2;
        uint256 amountToken = u.savedToken;
        uint256 wantAmount = u.savedEth;
        u.payedfee = true;
        desteth.transfer(wantAmount);
        return token.transfer(desttoken, amountToken);
    }
    
    function TXwithCode(bytes32 _codeTXid, uint _tokens) public{
        var u = datakeeper[_codeTXid];
        require(verifStatus[msg.sender] = true && u.ongoingtx == false && u.payedfee == false && u.party2 == 0x0000000000000000000000000000000000000000 && u.party2 != u.party1);
        u.party2 = msg.sender;
        u.savedToken = _tokens;
        ERC20(u.contractTokenAddress).transferFrom(msg.sender, address(this), _tokens);
        u.ongoingtx = true;
    }
    
    function payFee(bytes32 _codeTXid, uint _tokens) public returns (bool){
        var u = datakeeper[_codeTXid];
        require(u.ongoingtx == true && u.payedfee == false);
        ERC20(feeToken).transferFrom(msg.sender, address(this), _tokens);
        ERC20 token = ERC20(u.contractTokenAddress);
        address desteth = u.party2;
        address desttoken = u.party1;
        uint256 amountToken = u.savedToken;
        uint256 wantAmount = u.savedEth;
        u.payedfee = true;
        desteth.transfer(wantAmount);
        return token.transfer(desttoken, amountToken);
    }
    
    function getTX() view public returns(bytes32[]){
        return datatx;
    }
    
    function getTXwithCode(bytes32 _codeTXid) view public returns(address, address, address, string, uint256, uint256, uint256, uint256, uint256, bool, bool){
        var u = datakeeper[_codeTXid];
        return(u.party1,
        u.party2,
        u.contractTokenAddress,
        u.symbol,
        u.decimal,
        u.amount,
        u.rateInWei,
        u.savedEth,
        u.savedToken,
        u.ongoingtx,
        u.payedfee);
    }
    
    function withdrawEth(address _walletDest, uint256 _wdamount) onlyOwner {
        address dest = _walletDest;
        uint256 wantAmount = _wdamount;
        dest.transfer(wantAmount);
    }
    
    function withdrawTokens(address _tokenContract, address _walletDest, uint256 _amountT) onlyOwner returns (bool) {
        ERC20 token = ERC20(_tokenContract);
        address dest = _walletDest;
        uint amountToken = _amountT;
        return token.transfer(dest, amountToken);
    }
}