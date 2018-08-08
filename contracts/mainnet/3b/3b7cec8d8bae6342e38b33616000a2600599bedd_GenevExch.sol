pragma solidity ^0.4.23;


contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}


contract Token {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    uint8 public decimals;
    string public name;
}


contract StandardToken is Token {

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract ReserveToken is StandardToken, SafeMath {

    address public minter;

    constructor() public {
        minter = msg.sender;
    }

    function create(address account, uint amount) public {
        if (msg.sender != minter) revert();
        balances[account] = safeAdd(balances[account], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

    function destroy(address account, uint amount) public {
        if (msg.sender != minter) revert();
        if (balances[account] < amount) revert();
        balances[account] = safeSub(balances[account], amount);
        totalSupply = safeSub(totalSupply, amount);
    }
}


contract AccountLevels {
    //given a user, returns an account level
    //0 = regular user (pays take fee and make fee)
    //1 = market maker silver (pays take fee, no make fee, gets rebate)
    //2 = market maker gold (pays take fee, no make fee, gets entire counterparty&#39;s take fee as rebate)
    function accountLevel(address user) public constant returns(uint);
}


contract AccountLevelsTest is AccountLevels {

    mapping (address => uint) public accountLevels;

    function setAccountLevel(address user, uint level) public {
        accountLevels[user] = level;
    }

    function accountLevel(address user) public constant returns(uint) {
        return accountLevels[user];
    }

}


contract GenevExch is SafeMath {

    address public admin; //the admin address
    address public feeAccount; //the account that will receive fees
    address public accountLevelsAddr; //the address of the AccountLevels contract
    uint public feeMake; //percentage times (1 ether)
    uint public feeTake; //percentage times (1 ether)
    uint public feeRebate; //percentage times (1 ether)
    mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

    mapping (address => bool) public whiteListERC20;
    mapping (address => bool) public whiteListERC223;

    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    
    modifier onlyAdmin() {
        require(msg.sender==admin);
        _;
    }

    // Constructor

    constructor(
        address admin_, 
        address feeAccount_, 
        address accountLevelsAddr_, 
        uint feeMake_, 
        uint feeTake_, 
        uint feeRebate_) public {

        admin = admin_;
        feeAccount = feeAccount_;
        accountLevelsAddr = accountLevelsAddr_;
        feeMake = feeMake_;
        feeTake = feeTake_;
        feeRebate = feeRebate_;
    }

    function() public {
        revert();
    }

    // Admin functions

    function changeAdmin(address admin_) public onlyAdmin {
        admin = admin_;
    }

    function changeAccountLevelsAddr(address accountLevelsAddr_) public onlyAdmin {
        accountLevelsAddr = accountLevelsAddr_;
    }

    function changeFeeAccount(address feeAccount_) public onlyAdmin {
        feeAccount = feeAccount_;
    }

    function changeFeeMake(uint feeMake_) public onlyAdmin {
        feeMake = feeMake_;
    }

    function changeFeeTake(uint feeTake_) public onlyAdmin {
        if (feeTake_ < feeRebate) revert();
        feeTake = feeTake_;
    }

    function changeFeeRebate(uint feeRebate_) public onlyAdmin {
        if (feeRebate_ > feeTake) revert();
        feeRebate = feeRebate_;
    }

    // Whitelists for ERC20 or ERC223 tokens

    function setBlackListERC20(address _token) public onlyAdmin {
        whiteListERC20[_token] = false;
    }
    function setWhiteListERC20(address _token) public onlyAdmin {
        whiteListERC20[_token] = true;
    }
    function setBlackListERC223(address _token) public onlyAdmin {
        whiteListERC223[_token] = false;
    }
    function setWhiteListERC223(address _token) public onlyAdmin {
        whiteListERC223[_token] = true;
    }

    // Public functions

    function deposit() public payable { // Deposit Ethers
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public { // Deposit ERC223 tokens
        if (_value==0) revert();
        require(whiteListERC223[msg.sender]);
        tokens[msg.sender][_from] = safeAdd(tokens[msg.sender][_from], _value);
        emit Deposit(msg.sender, _from, _value, tokens[msg.sender][_from]);
     }

    function depositToken(address token, uint amount) public { // Deposit ERC20 tokens
        if (amount==0) revert();
        require(whiteListERC20[token]);
        if (!Token(token).transferFrom(msg.sender, this, amount)) revert();
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdraw(uint amount) public { // Withdraw ethers
        if (tokens[0][msg.sender] < amount) revert();
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
        msg.sender.transfer(amount);
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public { // Withdraw tokens
        require(whiteListERC20[token] || whiteListERC223[token]);
        if (tokens[token][msg.sender] < amount) revert();
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        require (Token(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) public constant returns (uint) {
        return tokens[token][user];
    }

    // Exchange specific functions

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orders[msg.sender][hash] = true;
        emit Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
        //amount is in amountGet terms
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(
            (orders[user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) &&
            block.number <= expires &&
            safeAdd(orderFills[user][hash], amount) <= amountGet
        )) revert();
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
        emit Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
    }

    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
        uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
        uint feeRebateXfer = 0;

        if (accountLevelsAddr != 0x0) {
            uint accountLevel = AccountLevels(accountLevelsAddr).accountLevel(user);
            if (accountLevel==1) feeRebateXfer = safeMul(amount, feeRebate) / (1 ether);
            if (accountLevel==2) feeRebateXfer = feeTakeXfer;
        }

        tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
        tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(safeAdd(amount, feeRebateXfer), feeMakeXfer));
        tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeSub(safeAdd(feeMakeXfer, feeTakeXfer), feeRebateXfer));
        tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
        tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
    }

    function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public constant returns(bool) {
        if (!(
            tokens[tokenGet][sender] >= amount &&
            availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
        )) return false;
        return true;
    }

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(
            (orders[user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) &&
            block.number <= expires
        )) return 0;
        uint available1 = safeSub(amountGet, orderFills[user][hash]);
        uint available2 = safeMul(tokens[tokenGive][user], amountGet) / amountGive;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFills[user][hash];
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(orders[msg.sender][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == msg.sender)) revert();
        orderFills[msg.sender][hash] = amountGet;
        emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }
    
}