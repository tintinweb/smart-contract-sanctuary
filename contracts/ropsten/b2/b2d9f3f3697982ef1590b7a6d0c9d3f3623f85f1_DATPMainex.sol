pragma solidity ^0.4.25;

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

contract DATPMainex {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => bool) verifStatus;
    mapping (address => mapping (address => uint256)) allowed;
    
    struct txdata{
        address party1;
        address party2;
        address contractTokenAddress;
        uint256 amountTokenBuy;
        uint256 rateTokenBuy;
        uint256 savedEth;
        uint256 savedToken;
        uint256 deadline;
        bool txClear;
        bool feePayed;
    }
    
    mapping (bytes32 => txdata) datakeeper;
    bytes32[] public datatx;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function changeVerify(address userAddress) onlyOwner public {
        require(verifStatus[userAddress] == false,"User already verified");
        verifStatus[userAddress] = true;
    }
    
    function checkVerify(address userAddress) constant public returns (bool) {
        return verifStatus[userAddress];
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
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

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
    
    function () payable public{
    }
    
    function postTX(address _contractAddress, uint256 _amountToken, uint256 _rateToken) payable public returns(bytes32){
        require(verifStatus[msg.sender] = true);
        uint256 check = _rateToken * (_amountToken / 1000000000);
        require(msg.value == check, "Sended ethereum not same with required.");
        require(_rateToken > 0 && _amountToken > 0);
        bytes32 newtxcode = sha256(msg.sender, now);
        txdata memory u = datakeeper[newtxcode];
        u.party1 = msg.sender;
        u.contractTokenAddress = _contractAddress;
        u.amountTokenBuy = _amountToken;
        u.rateTokenBuy = _rateToken;
        u.savedEth  = msg.value;
        u.deadline = now + 1 days;
        u.txClear = false;
        u.feePayed = false;
        datatx.push(newtxcode) -1;
        return newtxcode;
    }
    
    function getTX() view public returns(bytes32[]){
        return datatx;
    }
    
    function getTXdatabyCode(bytes32 _codeTXid) view public returns (address,address,address,uint256,uint256,uint256,uint256,uint256,bool,bool){
        txdata memory u = datakeeper[_codeTXid];
        return(u.party1,
        u.party2,
        u.contractTokenAddress,
        u.amountTokenBuy,
        u.rateTokenBuy,
        u.savedEth,
        u.savedToken,
        u.deadline,
        u.txClear,
        u.feePayed);
    }
    
    function TXwithCode(bytes32 _codeTXid) payable public{
        require(verifStatus[msg.sender] = true);
        txdata memory u = datakeeper[_codeTXid];
        u.party2 = msg.sender;
        u.savedToken  = msg.value;
        u.txClear = true;
        require(u.txClear = false, "Some people got this transaction.");
        require(msg.sender != u.party1, "Same wallet detected.");
        require(u.amountTokenBuy == u.savedToken, "Sended token not same with required.");
        datatx.push(_codeTXid) -1;
    }
    
    function payFee(bytes32 _codeTXid) payable public{
        txdata memory u = datakeeper[_codeTXid];
        ForeignToken token = ForeignToken(u.contractTokenAddress);
        ForeignToken datp = ForeignToken(0x813b428aF3920226E059B68A62e4c04933D4eA7a);
        u.feePayed = true;
        require(msg.value >= datp.balanceOf(500e8), "Fee amount not accepted");
        datatx.push(_codeTXid) -1;
        token.transfer(u.party1, u.savedToken);
        transfer(u.party2, u.savedEth);
    }

    function withdrawEth(address _walletDest, uint256 _wdamount) onlyOwner public {
        address dest = _walletDest;
        uint256 wantAmount = _wdamount;
        transfer(dest, wantAmount);
    }
    
    function withdrawTokens(address _tokenContract, address _walletDest, uint256 _amountT) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        address dest = _walletDest;
        uint amountToken = _amountT;
        return token.transfer(dest, amountToken);
    }
}