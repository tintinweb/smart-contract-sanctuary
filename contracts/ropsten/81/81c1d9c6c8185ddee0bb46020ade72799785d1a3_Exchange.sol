pragma solidity ^0.4.16;

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) external returns (bool);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface EIP777 {
    function name() external constant returns (string);
    function symbol() external constant returns (string);
    function granularity() external constant returns (uint256);
    function totalSupply() external constant returns (uint256);
    function balanceOf(address owner) external constant returns (uint256);

    function send(address to, uint256 value) external;
    function send(address to, uint256 value, bytes userData) external;

    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function isOperatorFor(address operator, address tokenHolder) external constant returns (bool);
    function operatorSend(address from, address to, uint256 value, bytes userData, bytes operatorData) external;

    event Sent(address indexed from, address indexed to, uint256 value, address indexed operator, bytes userData, bytes operatorData);
    event Minted(address indexed to, uint256 amount, address indexed operator, bytes operatorData);
    event Burnt(address indexed from, uint256 value);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface ERC223 {
    function transfer(address target, uint256 amount, bytes data) external returns (bool);
}

interface InterfaceImplementationRegistry {
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) external;
}

interface DepositReceiver {
    function deposit(address target) external payable returns (bool);
    function depositToken(address token, address target, uint256 amount) external returns (bool);
}

library BytesToAddress {
    function toAddress(bytes _address) internal pure returns (address) {
        if (_address.length < 20) return address(0);
        uint160 m = 0;
        uint160 b = 0;
        for (uint8 i = 0; i < 20; i++) {
            m *= 256;
            b = uint160(_address[i]);
            m += (b);
        }
        return address(m);
    }
}

library AddressToBytes {
    function toBytes(address a) internal pure returns (bytes b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }
}

contract DepositProxy {
    using AddressToBytes for address;
    address public beneficiary;
    address public exchange;
    event Deposit(address token, uint256 amount);
    function DepositProxy(address _exchange, address _beneficiary) public {
        exchange = _exchange;
        beneficiary = _beneficiary;
        registerEIP777Interface();
    }
    function tokenFallback(address /* sender */, uint256 amount, bytes /* data */) public {
        require(ERC223(msg.sender).transfer(exchange, amount, beneficiary.toBytes()));
        Deposit(msg.sender, amount);
    }
    function tokensReceived(address /* from */, address to, uint256 amount, bytes /* userData */, address /* operator */, bytes /* operatorData */) public {
        require(to == address(this));
        EIP777(msg.sender).send(exchange, amount, beneficiary.toBytes());
        Deposit(msg.sender, amount);
    }
    function approveAndDeposit(address token, uint256 amount) internal {
        require(Token(token).approve(exchange, amount));
        require(DepositReceiver(exchange).depositToken(token, beneficiary, amount));
        Deposit(token, amount);
    }
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes /* _data */) public {
        require(_token == msg.sender);
        require(Token(_token).transferFrom(_from, this, _tokens));
        approveAndDeposit(_token, _tokens);
    }
    function depositAll(address token) public {
        approveAndDeposit(token, Token(token).balanceOf(this));
    }
    function registerEIP777Interface() internal {
        InterfaceImplementationRegistry(0x9aA513f1294c8f1B254bA1188991B4cc2EFE1D3B).setInterfaceImplementer(this, keccak256("ITokenRecipient"), this);
    }
    function () external payable {
        DepositReceiver(exchange).deposit.value(msg.value)(beneficiary);
        Deposit(0x0, msg.value);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }
}

contract Owned {
    address public owner;
    function Owned() public {
        owner = msg.sender;
    }
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address newOwner) public onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }
}

contract Exchange is Owned {
    using BytesToAddress for bytes;
    using SafeMath for uint256;
    uint256 constant public INACTIVITY_CAP = 1e6;
    mapping (address => uint256) public invalidOrder;
    event ProxyCreated(address beneficiary, address proxyAddress);
    function createDepositProxy(address target) public returns (address) {
        if (target == 0x0) target = msg.sender;
        address dp = address(new DepositProxy(this, target));
        ProxyCreated(target, address(dp));
        return address(dp);
    }
    function invalidateOrdersBefore(address user, uint256 nonce) public onlyAdmin {
        require(nonce >= invalidOrder[user]);
        invalidOrder[user] = nonce;
        lastActiveTransaction[user] = block.number;
    }

    mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances

    mapping (address => bool) public admins;
    mapping (address => uint256) public lastActiveTransaction;
    struct InactivityOverride {
        bool isActive;
        uint256 blocks;
    }
    mapping (address => InactivityOverride) public inactivityReleaseOverride;
    mapping (bytes32 => uint256) public orderFills;
    address public feeAccount;
    uint256 public inactivityReleasePeriod = 100000;
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => bool) public withdrawn;
    mapping (bytes32 => bool) public transferred;
    mapping (address => uint256) public protectedFunds;
    mapping (address => bool) public thirdPartyDepositorDisabled;
    event Trade(address tokenBuy, address tokenSell, address maker, address taker, uint256 amountBuy, uint256 amountSell, bytes32 orderHash, bytes32 tradeHash);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Cancel(address user, bytes32 orderHash, uint256 nonce);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Transfer(address token, address recipient);
    event InactivityReset(address user);

    modifier underInactivityCap(uint256 blocks) {
        require(blocks <= INACTIVITY_CAP);
        _;
    }

//    function setInactivityReleasePeriod(uint256 expiry) public onlyOwner underInactivityCap(expiry) returns (bool) {
//        inactivityReleasePeriod = expiry;
//        return true;
//    }

//    function setInactivityReleasePeriodForToken(address token, bool isActive, uint256 blocks) public onlyOwner underInactivityCap(blocks) returns (bool) {
//        inactivityReleaseOverride[token].isActive = isActive;
//        inactivityReleaseOverride[token].blocks = blocks;
//        return true;
//    }

    modifier eligibleForRelease(address user, address token) {
        require(block.number.sub(lastActiveTransaction[user]) >= (inactivityReleaseOverride[token].isActive ? inactivityReleaseOverride[token].blocks : inactivityReleasePeriod));
        _;
    }

//    function resetInactivityTimer() public returns (bool) {
//        lastActiveTransaction[msg.sender] = block.number;
//        InactivityReset(msg.sender);
//        return true;
//    }

    function Exchange(address feeAccount_) public {
        feeAccount = feeAccount_;
        //registerEIP777Interface();
    }

    function setFeeAccount(address feeAccount_) public onlyOwner returns (bool) {
        feeAccount = feeAccount_;
        return true;
    }

//    function setThirdPartyDepositorDisabled(bool disabled) external returns (bool) {
//        thirdPartyDepositorDisabled[msg.sender] = disabled;
//        return true;
//    }

//    function withdrawUnprotectedFunds(address token, address target, uint256 amount, bool isEIP777) public onlyOwner returns (bool) {
//        require(Token(token).balanceOf(this).sub(protectedFunds[token]) >= amount);
//        if (isEIP777) EIP777(token).send(target, amount);
//        else require(Token(token).transfer(target, amount));
//        return true;
//    }

    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function depositToken(address token, address target, uint256 amount) public returns (bool) {
        if (target == 0x0) target = msg.sender;
        require(acceptDeposit(token, target, amount));
        require(Token(token).transferFrom(msg.sender, this, amount));
        return true;
    }

    function acceptDeposit(address token, address target, uint256 amount) internal returns (bool) {
        require(!thirdPartyDepositorDisabled[msg.sender] || msg.sender == target);
        tokens[token][target] = tokens[token][target].add(amount);
        protectedFunds[token] = protectedFunds[token].add(amount);
        lastActiveTransaction[target] = block.number;
        Deposit(token, target, amount, tokens[token][target]);
        return true;
    }

    function deposit(address target) public payable returns (bool) {
        if (target == 0x0) target = msg.sender;
        require(acceptDeposit(0x0, target, msg.value));
        return true;
    }

    function tokenFallback(address target, uint256 amount, bytes data) public {
        address beneficiary = data.toAddress();
        if (beneficiary != 0x0) target = beneficiary;
        require(acceptDeposit(msg.sender, target, amount));
    }

    function receiveApproval(address _from, uint256 _tokens, address _token, bytes /* _data */) public {
        require(_token == msg.sender);
        require(Token(_token).transferFrom(_from, this, _tokens));
        require(acceptDeposit(_token, _from, _tokens));
    }

    function tokensReceived(address from, address to, uint256 amount, bytes userData, address /* operator */, bytes /* operatorData */) public {
        require(to == address(this));
        address beneficiary = userData.toAddress();
        if (beneficiary != 0x0) from = beneficiary;
        require(acceptDeposit(msg.sender, from, amount));
    }

    function registerEIP777Interface() internal {
        InterfaceImplementationRegistry(0x9aA513f1294c8f1B254bA1188991B4cc2EFE1D3B).setInterfaceImplementer(this, keccak256("ITokenRecipient"), this);
    }

    function withdraw(address token, address target, uint256 amount) public eligibleForRelease(msg.sender, token) returns (bool) {
        if (target == 0x0) target = msg.sender;
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        protectedFunds[token] = protectedFunds[token].sub(amount);
        if (token == address(0)) require(target.send(amount));
        else require(Token(token).transfer(target, amount));
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }

//    function withdrawEIP777(address token, address target, uint256 amount) public eligibleForRelease(msg.sender, token) returns (bool) {
//        if (target == 0x0) target = msg.sender;
//        require(tokens[token][msg.sender] >= amount);
//        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
//        amount = amount.sub(amount % EIP777(token).granularity());
//        protectedFunds[token] = protectedFunds[token].sub(amount);
//        EIP777(token).send(target, amount);
//        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
//        return true;
//    }

//    function validateWithdrawalSignature(address token, uint256 amount, address user, address target, bool authorizeArbitraryFee, uint256 nonce, uint8 v, bytes32 r, bytes32 s) internal returns (bool) {
//        bytes32 hash = keccak256(this, token, amount, user, target, authorizeArbitraryFee, nonce);
//        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
//        require(!withdrawn[hash]);
//        withdrawn[hash] = true;
//        return true;
//    }

//    function adminWithdraw(address token, uint256 amount, address user, address target, bool authorizeArbitraryFee, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) public onlyAdmin returns (bool) {
//        require(validateWithdrawalSignature(token, amount, user, target, authorizeArbitraryFee, nonce, v, r, s));
//        if (target == 0x0) target = user;
//        if (feeWithdrawal > 100 finney && !authorizeArbitraryFee) feeWithdrawal = 100 finney;
//        require(feeWithdrawal <= 1 ether);
//        require(tokens[token][user] >= amount);
//        tokens[token][user] = tokens[token][user].sub(amount);
//        uint256 fee = feeWithdrawal.mul(amount) / 1 ether;
//        tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
//        amount = amount.sub(fee);
//        protectedFunds[token] = protectedFunds[token].sub(amount);
//        if (token == address(0)) require(target.send(amount));
//        else require(Token(token).transfer(target, amount));
//        lastActiveTransaction[user] = block.number;
//        return true;
//    }
//    function adminWithdrawEIP777(address token, uint256 amount, address user, address target, bool authorizeArbitraryFee, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) public onlyAdmin returns (bool) {
//        require(validateWithdrawalSignature(token, amount, user, target, authorizeArbitraryFee, nonce, v, r, s));
//        if (target == 0x0) target = user;
//        if (feeWithdrawal > 100 finney && !authorizeArbitraryFee) feeWithdrawal = 100 finney;
//        require(feeWithdrawal <= 1 ether);
//        require(tokens[token][user] >= amount);
//        tokens[token][user] = tokens[token][user].sub(amount);
//        uint256 fee = feeWithdrawal.mul(amount) / 1 ether;
//        tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
//        amount = amount.sub(fee);
//        amount = amount.sub(amount % EIP777(token).granularity());
//        protectedFunds[token] = protectedFunds[token].sub(amount);
//        EIP777(token).send(target, amount);
//        lastActiveTransaction[user] = block.number;
//        return true;
//    }
    function transfer(address token, uint256 amount, address user, address target, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeTransfer) public onlyAdmin returns (bool success) {
        require(target != 0x0);
        bytes32 hash = keccak256("\x19IDEX Signed Transfer:\n32", keccak256(this, token, amount, user, target, nonce));
        require(!transferred[hash]);
        transferred[hash] = true;
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        if (feeTransfer > 100 finney) feeTransfer = 100 finney;
        require(tokens[token][user] >= amount);
        tokens[token][user] = tokens[token][user].sub(amount);
        uint256 fee = feeTransfer.mul(amount) / 1 ether;
        tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
        amount = amount.sub(fee);
        tokens[token][target] = tokens[token][target].add(amount);
        lastActiveTransaction[user] = block.number;
        lastActiveTransaction[target] = block.number;
        Transfer(token, target);
        return true;
    }
    function trade(uint256[12] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) public onlyAdmin returns (bool) {
        /* amountBuy is in makerAmountBuy terms */
        /* tradeValues
           [0] makerAmountBuy
           [1] makerAmountSell
           [2] makerExpires
           [3] makerNonce
           [4] takerAmountBuy
           [5] takerAmountSell
           [6] takerExpires
           [7] takerNonce
           [8] feeMake
           [9] feeTake
           [10] amountBuy
           [11] amountSell
         tradeAddressses
           [0] tokenBuy
           [1] tokenSell
           [2] maker
           [3] taker
         */
        uint256 price = tradeValues[10].mul(1 ether) / tradeValues[11];
        require(price >= tradeValues[0].mul(1 ether) / tradeValues[1]);
        require(price >= tradeValues[5].mul(1 ether) / tradeValues[4]);
        require(block.number < tradeValues[2]);
        require(block.number < tradeValues[6]);
        require(invalidOrder[tradeAddresses[2]] <= tradeValues[3]);
        require(invalidOrder[tradeAddresses[3]] <= tradeValues[7]);
        bytes32 orderHash = keccak256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeValues[3], tradeAddresses[2]);
        bytes32 tradeHash = keccak256(this, tradeAddresses[1], tradeValues[4], tradeAddresses[0], tradeValues[5], tradeValues[6], tradeValues[7], tradeAddresses[3]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == tradeAddresses[2]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) == tradeAddresses[3]);
        if (tradeValues[6] > 10 finney) tradeValues[8] = 10 finney;
        if (tradeValues[7] > 1 ether) tradeValues[9] = 1 ether;
        require(orderFills[orderHash].add(tradeValues[10]) <= tradeValues[0]);
        require(orderFills[tradeHash].add(tradeValues[11]) <= tradeValues[4]);
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[10]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= tradeValues[11]);
        tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[10]);
        uint256 makerFee = tradeValues[10].mul(tradeValues[8]) / 1 ether;
        tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].add(tradeValues[10].sub(makerFee));
        tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(makerFee);
        tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(tradeValues[11]);
        uint256 takerFee = tradeValues[9].mul(tradeValues[11]) / 1 ether;
        tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].add(tradeValues[11].sub(takerFee));
        tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add(takerFee);
        orderFills[orderHash] = orderFills[orderHash].add(tradeValues[10]);
        orderFills[tradeHash] = orderFills[tradeHash].add(tradeValues[11]);
        lastActiveTransaction[tradeAddresses[2]] = block.number;
        lastActiveTransaction[tradeAddresses[3]] = block.number;
        Trade(tradeAddresses[0], tradeAddresses[1], tradeAddresses[2], tradeAddresses[3], tradeValues[10], tradeValues[11], orderHash, tradeHash);
        return true;
    }

    function cancel(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address user, uint256 nonce, uint256 expires, uint8 v, bytes32 r, bytes32 s) public onlyAdmin returns (bool) {
        bytes32 orderHash = keccak256(this, tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce, user);
        bytes32 hash = keccak256("\x19IDEX Signed Cancel:\n32", orderHash);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        orderFills[orderHash] = amountBuy;
        Cancel(user, orderHash, nonce);
        return true;
    }

    function() external {
        revert();
    }
}