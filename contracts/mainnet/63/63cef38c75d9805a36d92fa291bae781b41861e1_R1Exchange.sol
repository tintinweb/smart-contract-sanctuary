///auto-generated single file for verifying contract on etherscan
pragma solidity ^0.4.20;

contract SafeMath {

    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract R1Exchange is SafeMath, Ownable {
    mapping(address => bool) public admins;
    mapping(address => bool) public feeAccounts;
    // mapping(token address => mapping(owner address => mapping(channelId uint => uint256))) public tokenList;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public tokenList;
    // mapping(owner address =>  mapping(orderHash bytes32 => uint256)) public tokenList;
    mapping(address => mapping(bytes32 => uint256)) public orderFilled;//tokens filled
    mapping(bytes32 => bool) public withdrawn;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public withdrawAllowance;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public applyList;//withdraw apply list
    mapping(address => mapping(address => mapping(uint256 => uint))) public latestApply;//save the latest apply timestamp
    // mapping(owner address => mapping(channelId uint => nonce uint256))) public canceled;
    mapping(address => mapping(uint256 => uint)) public canceled;
    string public constant version = &#39;2.0.0&#39;;
    uint public applyWait = 1 days;
    uint public feeRate = 10;
    bool public withdrawEnabled = false;
    bool public stop = false;
    uint256 private DEFAULT_CHANNEL_ID = 0;
    bool public depositToEnabled = true;
    bool public transferEnabled = false;
    bool public changeChannelEnabled = false;
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 channelId);
    event DepositTo(address indexed token, address indexed from, address indexed user, uint256 amount, uint256 balance, uint256 channelId);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 channelId);
    event ApplyWithdraw(address indexed token, address indexed user, uint256 amount, uint256 time, uint256 channelId);
    event ApproveWithdraw(address indexed token, address indexed user, uint256 channelId);
    event Trade(address indexed maker, address indexed taker, uint256 amount, uint256 makerFee, uint256 takerFee, uint256 makerNonce, uint256 takerNonce);
    event InnerTransfer(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 balance, uint256 channelId);
    event ChangeChannel(address indexed token, address indexed user, uint256 amount, uint256 fromChannelId, uint256 toChannelId);
    event BatchCancel(uint256 count, uint256 channelId);
    modifier onlyAdmin {
        require(admins[msg.sender]);
        _;
    }
    modifier isWithdrawEnabled {
        require(withdrawEnabled);
        _;
    }
    modifier isFeeAccount(address fa) {
        require(feeAccounts[fa]);
        _;
    }
    modifier notStop() {
        require(!stop);
        _;
    }
    modifier isDepositToEnabled() {
        require(depositToEnabled);
        _;
    }
    modifier isTransferEnabled() {
        require(transferEnabled);
        _;
    }
    modifier isChangeChannelEnabled() {
        require(changeChannelEnabled);
        _;
    }
    function() public {
        revert();
    }
    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        require(admin != 0);
        admins[admin] = isAdmin;
    }
    function setFeeAccount(address acc, bool asFee) public onlyOwner {
        require(acc != 0);
        feeAccounts[acc] = asFee;
    }
    function enableWithdraw(bool enabled) public onlyOwner {
        withdrawEnabled = enabled;
    }
    function enableDepositTo(bool enabled) public onlyOwner {
        depositToEnabled = enabled;
    }
    function enableTransfer(bool enabled) public onlyOwner {
        transferEnabled = enabled;
    }
    function enableChangeChannel(bool enabled) public onlyOwner {
        changeChannelEnabled = enabled;
    }
    function changeLockTime(uint lock) public onlyOwner {
        require(lock <= 7 days);
        applyWait = lock;
    }
    function changeFeeRate(uint fr) public onlyOwner {
        //max fee rate MUST <=10%
        require(fr >= 10);
        feeRate = fr;
    }
    function stopTrade() public onlyOwner {
        stop = true;
    }
    /**
    * cancel the order that before nonce.
    **/
    function batchCancel(address[] users, uint256[] nonces, uint256 channelId) public onlyAdmin {
        require(users.length == nonces.length);
        uint256 count = 0;
        for (uint i = 0; i < users.length; i++) {
            require(nonces[i] >= canceled[users[i]][channelId]);
            canceled[users[i]][channelId] = nonces[i];
            count++;
        }
        BatchCancel(count, channelId);
    }
    function deposit(uint256 channelId) public payable {
        tokenList[0][msg.sender][channelId] = safeAdd(tokenList[0][msg.sender][channelId], msg.value);
        Deposit(0, msg.sender, msg.value, tokenList[0][msg.sender][channelId], channelId);
    }
    function depositToken(address token, uint256 amount, uint256 channelId) public {
        require(token != 0);
        tokenList[token][msg.sender][channelId] = safeAdd(tokenList[token][msg.sender][channelId], amount);
        require(Token(token).transferFrom(msg.sender, this, amount));
        Deposit(token, msg.sender, amount, tokenList[token][msg.sender][channelId], channelId);
    }
    function depositTo(address to, uint256 channelId) public payable isDepositToEnabled {
        require(to != 0 && msg.value > 0);
        tokenList[0][to][channelId] = safeAdd(tokenList[0][to][channelId], msg.value);
        DepositTo(0, msg.sender, to, msg.value, tokenList[0][to][channelId], channelId);
    }
    function depositTokenTo(address token, address to, uint256 amount, uint256 channelId) public isDepositToEnabled {
        require(token != 0 && to != 0 && amount > 0);
        tokenList[token][to][channelId] = safeAdd(tokenList[token][to][channelId], amount);
        require(Token(token).transferFrom(msg.sender, this, amount));
        DepositTo(token, msg.sender, to, amount, tokenList[token][to][channelId], channelId);
    }
    function batchDepositTokenTo(address[] token, address[] to, uint256[] amount, uint256 channelId) public isDepositToEnabled {
        require(to.length == amount.length && to.length <= 200);
        for (uint i = 0; i < to.length; i++) {
            depositTokenTo(token[i], to[i], amount[i], channelId);
        }
    }
    function innerTransfer(address token, address to, uint256 amount, uint256 channelId) public isTransferEnabled {
        require(to != 0);
        require(amount <= tokenList[token][msg.sender][channelId]);
        tokenList[token][msg.sender][channelId] = safeSub(tokenList[token][msg.sender][channelId], amount);
        tokenList[token][to][channelId] = safeAdd(tokenList[token][to][channelId], amount);
        InnerTransfer(token, msg.sender, to, amount, tokenList[token][msg.sender][channelId], channelId);
    }
    function batchInnerTransfer(address[] token, address[] to, uint256[] amount, uint256 channelId) public isTransferEnabled {
        require(to.length == amount.length && to.length <= 200);
        for (uint i = 0; i < to.length; i++) {
            innerTransfer(token[i], to[i], amount[i], channelId);
        }
    }
    function changeChannel(address token, uint256 amount, uint256 fromChannelId, uint256 toChannelId) public isChangeChannelEnabled {
        require(amount <= tokenList[token][msg.sender][fromChannelId]);
        tokenList[token][msg.sender][fromChannelId] = safeSub(tokenList[token][msg.sender][fromChannelId], amount);
        tokenList[token][msg.sender][toChannelId] = safeAdd(tokenList[token][msg.sender][toChannelId], amount);
        ChangeChannel(token, msg.sender, amount, fromChannelId, toChannelId);
    }
    function batchChangeChannel(address[] token, uint256[] amount, uint256 fromChannelId, uint256 toChannelId) public isChangeChannelEnabled {
        require(token.length == amount.length && amount.length <= 200);
        for (uint i = 0; i < amount.length; i++) {
            changeChannel(token[i], amount[i], fromChannelId, toChannelId);
        }
    }
    function applyWithdraw(address token, uint256 amount, uint256 channelId) public {
        uint256 apply = safeAdd(applyList[token][msg.sender][channelId], amount);
        require(safeAdd(apply, withdrawAllowance[token][msg.sender][channelId]) <= tokenList[token][msg.sender][channelId]);
        applyList[token][msg.sender][channelId] = apply;
        latestApply[token][msg.sender][channelId] = block.timestamp;
        ApplyWithdraw(token, msg.sender, amount, block.timestamp, channelId);
    }
    /**
    * approve user&#39;s withdraw application
    **/
    function approveWithdraw(address token, address user, uint256 channelId) public onlyAdmin {
        withdrawAllowance[token][user][channelId] = safeAdd(withdrawAllowance[token][user][channelId], applyList[token][user][channelId]);
        applyList[token][user][channelId] = 0;
        latestApply[token][user][channelId] = 0;
        ApproveWithdraw(token, user, channelId);
    }
    /**
    * user&#39;s withdraw will success in two cases:
    *    1. when the admin calls the approveWithdraw function;
    * or 2. when the lock time has passed since the application;
    **/
    function withdraw(address token, uint256 amount, uint256 channelId) public {
        require(amount <= tokenList[token][msg.sender][channelId]);
        if (amount > withdrawAllowance[token][msg.sender][channelId]) {
            //withdraw wait over time
            require(latestApply[token][msg.sender][channelId] != 0 && safeSub(block.timestamp, latestApply[token][msg.sender][channelId]) > applyWait);
            withdrawAllowance[token][msg.sender][channelId] = safeAdd(withdrawAllowance[token][msg.sender][channelId], applyList[token][msg.sender][channelId]);
            applyList[token][msg.sender][channelId] = 0;
        }
        require(amount <= withdrawAllowance[token][msg.sender][channelId]);
        withdrawAllowance[token][msg.sender][channelId] = safeSub(withdrawAllowance[token][msg.sender][channelId], amount);
        tokenList[token][msg.sender][channelId] = safeSub(tokenList[token][msg.sender][channelId], amount);
        latestApply[token][msg.sender][channelId] = 0;
        if (token == 0) {//withdraw ether
            require(msg.sender.send(amount));
        } else {//withdraw token
            require(Token(token).transfer(msg.sender, amount));
        }
        Withdraw(token, msg.sender, amount, tokenList[token][msg.sender][channelId], channelId);
    }
    /**
    * withdraw directly when withdrawEnabled=true
    **/
    function withdrawNoLimit(address token, uint256 amount, uint256 channelId) public isWithdrawEnabled {
        require(amount <= tokenList[token][msg.sender][channelId]);
        tokenList[token][msg.sender][channelId] = safeSub(tokenList[token][msg.sender][channelId], amount);
        if (token == 0) {//withdraw ether
            require(msg.sender.send(amount));
        } else {//withdraw token
            require(Token(token).transfer(msg.sender, amount));
        }
        Withdraw(token, msg.sender, amount, tokenList[token][msg.sender][channelId], channelId);
    }
    struct AdminWithdrawParam {
        address user;
        address token;
        address feeAccount;
        address channelFeeAccount;
        uint256 amount;
        uint256 nonce;
        uint256 fee;
        uint256 channelFee;
        uint256 channelId;
    }
    /**
    * admin withdraw according to user&#39;s signed withdraw info
    * PARAMS:
    * addresses:
    * [0] user
    * [1] token
    * [2] feeAccount
    * [3] channelFeeAccount
    * values:
    * [0] amount
    * [1] nonce
    * [2] fee
    * [3] channelFee
    * [4] channelId
    **/
    function adminWithdraw(address[4] addresses, uint256[5] values, uint8 v, bytes32 r, bytes32 s)
    public
    onlyAdmin
    isFeeAccount(addresses[2])
    {
        AdminWithdrawParam memory param = AdminWithdrawParam({
            user : addresses[0],
            token : addresses[1],
            feeAccount : addresses[2],
            channelFeeAccount : addresses[3],
            amount : values[0],
            nonce : values[1],
            fee : values[2],
            channelFee : values[3],
            channelId : values[4]
            });
        require(param.amount <= tokenList[param.token][param.user][param.channelId]);
        param.fee = checkFee(param.amount, param.fee);
        param.channelFee = checkFee(param.amount, param.channelFee);
        bytes32 hash = keccak256(this, param.user, param.token, param.amount, param.nonce, param.channelFeeAccount, param.channelId);
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == param.user);
        tokenList[param.token][param.user][param.channelId] = safeSub(tokenList[param.token][param.user][param.channelId], param.amount);
        tokenList[param.token][param.feeAccount][DEFAULT_CHANNEL_ID] = safeAdd(tokenList[param.token][param.feeAccount][DEFAULT_CHANNEL_ID], param.fee);
        tokenList[param.token][param.channelFeeAccount][param.channelId] = safeAdd(tokenList[param.token][param.channelFeeAccount][param.channelId], param.channelFee);
        param.amount = safeSub(param.amount, param.fee);
        param.amount = safeSub(param.amount, param.channelFee);
        if (param.token == 0) {//withdraw ether
            require(param.user.send(param.amount));
        } else {//withdraw token
            require(Token(param.token).transfer(param.user, param.amount));
        }
        Withdraw(param.token, param.user, param.amount, tokenList[param.token][param.user][param.channelId], param.channelId);
    }
    function checkFee(uint256 amount, uint256 fee) private returns (uint256){
        uint256 maxFee = fee;
        if (safeMul(fee, feeRate) > amount) {
            maxFee = amount / feeRate;
        }
        return maxFee;
    }
    function getOrderHash(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address base, uint256 expires, uint256 nonce, address feeToken, address channelFeeAccount, uint256 channelId) public view returns (bytes32) {
        return keccak256(this, tokenBuy, amountBuy, tokenSell, amountSell, base, expires, nonce, feeToken, channelFeeAccount, channelId);
    }
    function balanceOf(address token, address user, uint256 channelId) public constant returns (uint256) {
        return tokenList[token][user][channelId];
    }
    struct Order {
        address tokenBuy;
        address tokenSell;
        uint256 amountBuy;
        uint256 amountSell;
        address user;
        uint256 fee;
        uint256 expires;
        uint256 nonce;
        bytes32 orderHash;
        address baseToken;
        address feeToken;//0:default;others:payed with erc-20 token
        address channelFeeAccount;
        uint256 channelFee;
        uint256 channelId;
    }
    /**
    * swap maker and taker&#39;s tokens according to their signed order info.
    *
    * PARAMS:
    * addresses:
    * [0]:maker tokenBuy
    * [1]:taker tokenBuy
    * [2]:maker tokenSell
    * [3]:taker tokenSell
    * [4]:maker user
    * [5]:taker user
    * [6]:maker baseTokenAddr .default:0 ,then baseToken is ETH
    * [7]:taker baseTokenAddr .default:0 ,then baseToken is ETH
    * [8]:maker feeToken .
    * [9]:taker feeToken .
    * [10]:feeAccount
    * [11]:makerChannelAccount
    * [12]:takerChannelAccount
    * values:
    * [0]:maker amountBuy
    * [1]:taker amountBuy
    * [2]:maker amountSell
    * [3]:taker amountSell
    * [4]:maker fee
    * [5]:taker fee
    * [6]:maker expires
    * [7]:taker expires
    * [8]:maker nonce
    * [9]:taker nonce
    * [10]:tradeAmount of token
    * [11]:makerChannelFee
    * [12]:takerChannelFee
    * [13]:makerChannelId
    * [14]:takerChannelId
    * v,r,s:maker and taker&#39;s signature
    **/
    function trade(
        address[13] addresses,
        uint256[15] values,
        uint8[2] v,
        bytes32[2] r,
        bytes32[2] s
    ) public
    onlyAdmin
    isFeeAccount(addresses[10])
    notStop
    {
        Order memory makerOrder = Order({
            tokenBuy : addresses[0],
            tokenSell : addresses[2],
            user : addresses[4],
            amountBuy : values[0],
            amountSell : values[2],
            fee : values[4],
            expires : values[6],
            nonce : values[8],
            orderHash : 0,
            baseToken : addresses[6],
            feeToken : addresses[8],
            channelFeeAccount : addresses[11],
            channelFee : values[11],
            channelId : values[13]
            });
        Order memory takerOrder = Order({
            tokenBuy : addresses[1],
            tokenSell : addresses[3],
            user : addresses[5],
            amountBuy : values[1],
            amountSell : values[3],
            fee : values[5],
            expires : values[7],
            nonce : values[9],
            orderHash : 0,
            baseToken : addresses[7],
            feeToken : addresses[9],
            channelFeeAccount : addresses[12],
            channelFee : values[12],
            channelId : values[14]
            });
        uint256 tradeAmount = values[10];
        //check expires
        require(makerOrder.expires >= block.number && takerOrder.expires >= block.number);
        //check order nonce canceled
        require(makerOrder.nonce >= canceled[makerOrder.user][makerOrder.channelId] && takerOrder.nonce >= canceled[takerOrder.user][takerOrder.channelId]);
        //make sure both is the same trade pair
        require(makerOrder.baseToken == takerOrder.baseToken && makerOrder.tokenBuy == takerOrder.tokenSell && makerOrder.tokenSell == takerOrder.tokenBuy);
        require(takerOrder.baseToken == takerOrder.tokenBuy || takerOrder.baseToken == takerOrder.tokenSell);
        makerOrder.orderHash = getOrderHash(makerOrder.tokenBuy, makerOrder.amountBuy, makerOrder.tokenSell, makerOrder.amountSell, makerOrder.baseToken, makerOrder.expires, makerOrder.nonce, makerOrder.feeToken, makerOrder.channelFeeAccount, makerOrder.channelId);
        takerOrder.orderHash = getOrderHash(takerOrder.tokenBuy, takerOrder.amountBuy, takerOrder.tokenSell, takerOrder.amountSell, takerOrder.baseToken, takerOrder.expires, takerOrder.nonce, takerOrder.feeToken, takerOrder.channelFeeAccount, takerOrder.channelId);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", makerOrder.orderHash), v[0], r[0], s[0]) == makerOrder.user);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", takerOrder.orderHash), v[1], r[1], s[1]) == takerOrder.user);
        balance(makerOrder, takerOrder, addresses[10], tradeAmount);
        //event
        Trade(makerOrder.user, takerOrder.user, tradeAmount, makerOrder.fee, takerOrder.fee, makerOrder.nonce, takerOrder.nonce);
    }
    function balance(Order makerOrder, Order takerOrder, address feeAccount, uint256 tradeAmount) internal {
        ///check the price meets the condition.
        ///match condition: (makerOrder.amountSell*takerOrder.amountSell)/(makerOrder.amountBuy*takerOrder.amountBuy) >=1
        require(safeMul(makerOrder.amountSell, takerOrder.amountSell) >= safeMul(makerOrder.amountBuy, takerOrder.amountBuy));
        ///If the price is ok,always use maker&#39;s price first!
        uint256 takerBuy = 0;
        uint256 takerSell = 0;
        if (takerOrder.baseToken == takerOrder.tokenBuy) {
            //taker sell tokens
            uint256 makerAmount = safeSub(makerOrder.amountBuy, orderFilled[makerOrder.user][makerOrder.orderHash]);
            uint256 takerAmount = safeSub(takerOrder.amountSell, orderFilled[takerOrder.user][takerOrder.orderHash]);
            require(tradeAmount > 0 && tradeAmount <= makerAmount && tradeAmount <= takerAmount);
            takerSell = tradeAmount;
            takerBuy = safeMul(makerOrder.amountSell, takerSell) / makerOrder.amountBuy;
            orderFilled[takerOrder.user][takerOrder.orderHash] = safeAdd(orderFilled[takerOrder.user][takerOrder.orderHash], takerSell);
            orderFilled[makerOrder.user][makerOrder.orderHash] = safeAdd(orderFilled[makerOrder.user][makerOrder.orderHash], takerSell);
        } else {
            // taker buy tokens
            takerAmount = safeSub(takerOrder.amountBuy, orderFilled[takerOrder.user][takerOrder.orderHash]);
            makerAmount = safeSub(makerOrder.amountSell, orderFilled[makerOrder.user][makerOrder.orderHash]);
            require(tradeAmount > 0 && tradeAmount <= makerAmount && tradeAmount <= takerAmount);
            takerBuy = tradeAmount;
            takerSell = safeMul(makerOrder.amountBuy, takerBuy) / makerOrder.amountSell;
            orderFilled[takerOrder.user][takerOrder.orderHash] = safeAdd(orderFilled[takerOrder.user][takerOrder.orderHash], takerBuy);
            orderFilled[makerOrder.user][makerOrder.orderHash] = safeAdd(orderFilled[makerOrder.user][makerOrder.orderHash], takerBuy);
        }
        //taker give tokens
        tokenList[takerOrder.tokenSell][takerOrder.user][takerOrder.channelId] = safeSub(tokenList[takerOrder.tokenSell][takerOrder.user][takerOrder.channelId], takerSell);
        //taker get tokens
        tokenList[takerOrder.tokenBuy][takerOrder.user][takerOrder.channelId] = safeAdd(tokenList[takerOrder.tokenBuy][takerOrder.user][takerOrder.channelId], takerBuy);
        //maker give tokens
        tokenList[makerOrder.tokenSell][makerOrder.user][makerOrder.channelId] = safeSub(tokenList[makerOrder.tokenSell][makerOrder.user][makerOrder.channelId], takerBuy);
        //maker get tokens
        tokenList[makerOrder.tokenBuy][makerOrder.user][makerOrder.channelId] = safeAdd(tokenList[makerOrder.tokenBuy][makerOrder.user][makerOrder.channelId], takerSell);
        chargeFee(makerOrder, feeAccount, takerSell);
        chargeFee(takerOrder, feeAccount, takerBuy);
    }
    ///charge fees.fee can be payed as other erc20 token or the tokens that user get
    ///returns:fees to reduce from the user&#39;s tokenBuy
    function chargeFee(Order order, address feeAccount, uint256 amountBuy) internal returns (uint256){
        uint256 totalFee = 0;
        if (order.feeToken != 0) {
            ///use erc-20 token as fee .
            //make sure the user has enough tokens
            totalFee = safeAdd(order.fee, order.channelFee);
            require(totalFee <= tokenList[order.feeToken][order.user][order.channelId]);
            tokenList[order.feeToken][feeAccount][DEFAULT_CHANNEL_ID] = safeAdd(tokenList[order.feeToken][feeAccount][DEFAULT_CHANNEL_ID], order.fee);
            tokenList[order.feeToken][order.channelFeeAccount][order.channelId] = safeAdd(tokenList[order.feeToken][order.channelFeeAccount][order.channelId], order.channelFee);
            tokenList[order.feeToken][order.user][order.channelId] = safeSub(tokenList[order.feeToken][order.user][order.channelId], totalFee);
        } else {
            order.fee = checkFee(amountBuy, order.fee);
            order.channelFee = checkFee(amountBuy, order.channelFee);
            totalFee = safeAdd(order.fee, order.channelFee);
            tokenList[order.tokenBuy][feeAccount][DEFAULT_CHANNEL_ID] = safeAdd(tokenList[order.tokenBuy][feeAccount][DEFAULT_CHANNEL_ID], order.fee);
            tokenList[order.tokenBuy][order.channelFeeAccount][order.channelId] = safeAdd(tokenList[order.tokenBuy][order.channelFeeAccount][order.channelId], order.channelFee);
            tokenList[order.tokenBuy][order.user][order.channelId] = safeSub(tokenList[order.tokenBuy][order.user][order.channelId], totalFee);
        }
    }
    function batchTrade(
        address[13][] addresses,
        uint256[15][] values,
        uint8[2][] v,
        bytes32[2][] r,
        bytes32[2][] s
    ) public onlyAdmin {
        for (uint i = 0; i < addresses.length; i++) {
            trade(addresses[i], values[i], v[i], r[i], s[i]);
        }
    }
    ///help to refund token to users.this method is called when contract needs updating
    function refund(address user, address[] tokens, uint256[] channelIds) public onlyAdmin {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            for (uint j = 0; j < channelIds.length; j++) {
                uint256 channelId = channelIds[j];
                uint256 amount = tokenList[token][user][channelId];
                if (amount > 0) {
                    tokenList[token][user][channelId] = 0;
                    if (token == 0) {//withdraw ether
                        require(user.send(amount));
                    } else {//withdraw token
                        require(Token(token).transfer(user, amount));
                    }
                    Withdraw(token, user, amount, tokenList[token][user][channelId], channelId);
                }
            }
        }
    }
}