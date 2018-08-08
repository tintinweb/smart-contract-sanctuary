pragma solidity 0.4.24;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
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

contract EtherDEX {
    using SafeMath for uint;

    address public admin; //the admin address
    address public feeAccount; //the account that will receive fees
    uint public feeMake; //percentage times (1 ether)
    uint public feeTake; //percentage times (1 ether)
    mapping(address => mapping(address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping(address => mapping(bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping(address => mapping(bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

    address public previousContract;
    address public nextContract;
    bool public isContractDeprecated;
    uint public contractVersion;

    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event FundsMigrated(address user);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(address admin_, address feeAccount_, uint feeMake_, uint feeTake_, address _previousContract) public {
        admin = admin_;
        feeAccount = feeAccount_;
        feeMake = feeMake_;
        feeTake = feeTake_;
        previousContract = _previousContract;
        isContractDeprecated = false;

        //count new contract version if it&#39;s not the first
        if (previousContract != address(0)) {
            contractVersion = EtherDEX(previousContract).contractVersion() + 1;
        } else {
            contractVersion = 1;
        }
    }

    function() public payable {
        revert("Cannot send ETH directly to the Contract");
    }

    function changeAdmin(address admin_) public onlyAdmin {
        admin = admin_;
    }

    function changeFeeAccount(address feeAccount_) public onlyAdmin {
        require(feeAccount_ != address(0));
        feeAccount = feeAccount_;
    }

    function changeFeeMake(uint feeMake_) public onlyAdmin {
        if (feeMake_ > feeMake) revert("New fee cannot be higher than the old one");
        feeMake = feeMake_;
    }

    function changeFeeTake(uint feeTake_) public onlyAdmin {
        if (feeTake_ > feeTake) revert("New fee cannot be higher than the old one");
        feeTake = feeTake_;
    }

    function deprecate(bool deprecated_, address nextContract_) public onlyAdmin {
        isContractDeprecated = deprecated_;
        nextContract = nextContract_;
    }

    function deposit() public payable {
        tokens[0][msg.sender] = SafeMath.add(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint amount) public {
        if (tokens[0][msg.sender] < amount) revert("Cannot withdraw more than you have");
        tokens[0][msg.sender] = SafeMath.sub(tokens[0][msg.sender], amount);
        msg.sender.transfer(amount);
        //or .send() and check if https://ethereum.stackexchange.com/a/38642
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        //remember to call ERC20Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        if (token == 0) revert("Cannot deposit ETH with depositToken method");
        if (!ERC20(token).transferFrom(msg.sender, this, amount)) revert("You didn&#39;t call approve method on Token contract");
        tokens[token][msg.sender] = SafeMath.add(tokens[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        if (token == 0) revert("Cannot withdraw ETH with withdrawToken method");
        if (tokens[token][msg.sender] < amount) revert("Cannot withdraw more than you have");
        tokens[token][msg.sender] = SafeMath.sub(tokens[token][msg.sender], amount);
        if (!ERC20(token).transfer(msg.sender, amount)) revert("Error while transfering tokens");
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        orders[msg.sender][hash] = true;
        emit Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
        //amount is in amountGet terms
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        if (!(
        (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == user) &&
        block.number <= expires &&
        SafeMath.add(orderFills[user][hash], amount) <= amountGet
        ))  revert("Validation error or order expired or not enough volume to trade");
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = SafeMath.add(orderFills[user][hash], amount);
        emit Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
    }

    function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public view returns (bool) {
        return (tokens[tokenGet][sender] >= amount && availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount);
    }

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns (uint) {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        if (!((orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == user) && block.number <= expires)) return 0;
        uint available1 = SafeMath.sub(amountGet, orderFills[user][hash]);
        uint available2 = SafeMath.mul(tokens[tokenGive][user], amountGet) / amountGive;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns (uint) {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        return orderFills[user][hash];
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        if (!(orders[msg.sender][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == msg.sender)) revert("Validation error");
        orderFills[msg.sender][hash] = amountGet;
        emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }

    function migrateFunds(address[] tokens_) public {
        // Get the latest successor in the chain
        require(nextContract != address(0));
        EtherDEX newExchange = findNewExchangeContract();

        // Ether
        migrateEther(newExchange);

        // Tokens
        migrateTokens(newExchange, tokens_);

        emit FundsMigrated(msg.sender);
    }

    function depositEtherForUser(address _user) public payable {
        require(!isContractDeprecated);
        require(_user != address(0));
        require(msg.value > 0);
        EtherDEX caller = EtherDEX(msg.sender);
        require(caller.contractVersion() > 0); // Make sure it&#39;s an exchange account
        tokens[0][_user] = tokens[0][_user].add(msg.value);
    }

    function depositTokenForUser(address _token, uint _amount, address _user) public {
        require(!isContractDeprecated);
        require(_token != address(0));
        require(_user != address(0));
        require(_amount > 0);
        EtherDEX caller = EtherDEX(msg.sender);
        require(caller.contractVersion() > 0); // Make sure it&#39;s an exchange account
        if (!ERC20(_token).transferFrom(msg.sender, this, _amount)) {
            revert();
        }
        tokens[_token][_user] = tokens[_token][_user].add(_amount);
    }

    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        uint feeMakeXfer = SafeMath.mul(amount, feeMake) / (1 ether);
        uint feeTakeXfer = SafeMath.mul(amount, feeTake) / (1 ether);

        tokens[tokenGet][msg.sender] = SafeMath.sub(tokens[tokenGet][msg.sender], SafeMath.add(amount, feeTakeXfer));
        tokens[tokenGet][user] = SafeMath.add(tokens[tokenGet][user], SafeMath.sub(amount, feeMakeXfer));
        tokens[tokenGet][feeAccount] = SafeMath.add(tokens[tokenGet][feeAccount], SafeMath.add(feeMakeXfer, feeTakeXfer));
        tokens[tokenGive][user] = SafeMath.sub(tokens[tokenGive][user], SafeMath.mul(amountGive, amount) / amountGet);
        tokens[tokenGive][msg.sender] = SafeMath.add(tokens[tokenGive][msg.sender], SafeMath.mul(amountGive, amount) / amountGet);
    }

    function findNewExchangeContract() private view returns (EtherDEX) {
        EtherDEX newExchange = EtherDEX(nextContract);
        for (uint16 n = 0; n < 20; n++) {// We will look past 20 contracts in the future
            address nextContract_ = newExchange.nextContract();
            if (nextContract_ == address(this)) {// Circular succession
                revert();
            }
            if (nextContract_ == address(0)) {// We reached the newest, stop
                break;
            }
            newExchange = EtherDEX(nextContract_);
        }
        return newExchange;
    }

    function migrateEther(EtherDEX newExchange) private {
        uint etherAmount = tokens[0][msg.sender];
        if (etherAmount > 0) {
            tokens[0][msg.sender] = 0;
            newExchange.depositEtherForUser.value(etherAmount)(msg.sender);
        }
    }

    function migrateTokens(EtherDEX newExchange, address[] tokens_) private {
        for (uint16 n = 0; n < tokens_.length; n++) {
            address token = tokens_[n];
            require(token != address(0));
            // 0 = Ether, we handle it above
            uint tokenAmount = tokens[token][msg.sender];
            if (tokenAmount == 0) {
                continue;
            }
            if (!ERC20(token).approve(newExchange, tokenAmount)) {
                revert();
            }
            tokens[token][msg.sender] = 0;
            newExchange.depositTokenForUser(token, tokenAmount, msg.sender);
        }
    }
}