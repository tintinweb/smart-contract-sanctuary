pragma solidity ^0.4.25;

contract Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract NescrowExchangeService {

    address owner = msg.sender;

    uint256 public feeRateLimit = 200;//100/200 = 0.5% max fee
    uint256 public takerFeeRate = 0;
    uint256 public makerFeeRate = 0;
    address public feeAddress;

    mapping (address => bool) public admins;
    mapping (bytes32 => uint256) public orderFills;
    mapping (bytes32 => uint256) public orderPaymentFills;
    mapping (bytes32 => bool) public withdrawn;
    mapping (bytes32 => bool) public transfers;
    mapping (address => mapping (address => uint256)) public balances;
    mapping (address => uint256) public tradesLocked;
    mapping (address => uint256) public disableFees;
    mapping (address => uint256) public tokenDecimals;
    mapping (address => bool) public tokenRegistered;

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    event OrderPayment(address indexed user, address spendToken, uint256 spendAmount, address indexed merchant, address merchantReceiveToken, uint256 merchantReceiveAmount);
    event TradesLock(address user);
    event TradesUnlock(address user);

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant ORDER_TYPEHASH = keccak256("Order(address fromToken,uint256 fromAmount,address toToken,uint256 toAmount,uint256 autoWithdraw,uint256 expires,uint256 nonce)");
    bytes32 constant ORDER_WITH_TIPS_TYPEHASH = keccak256("OrderWithTips(address fromToken,uint256 fromAmount,address toToken,uint256 toAmount,uint256 autoWithdraw,uint256 expires,uint256 nonce,uint256 makerTips,uint256 takerTips)");
    bytes32 constant ORDER_PAYMENT_TYPEHASH = keccak256("OrderPayment(address spendToken,uint256 spendAmount,address merchantReceiveToken,uint256 merchantReceiveAmount,address merchant,uint256 expires,uint256 nonce)");
    bytes32 constant WITHDRAWAL_TYPEHASH = keccak256("Withdrawal(address withdrawToken,uint256 amount,uint256 nonce)");
    bytes32 constant TIPS_TYPEHASH = keccak256("Tips(address tipsToken,uint256 amount,uint256 nonce)");
    bytes32 constant TRANSFER_TYPEHASH = keccak256("Transfer(address transferToken,address to,uint256 amount,uint256 nonce)");
    bytes32 DOMAIN_SEPARATOR;

    function domainHash(EIP712Domain eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            ));
    }

    constructor() public {
        DOMAIN_SEPARATOR = domainHash(EIP712Domain({
            name: "Nescrow Exchange",
            version: &#39;2&#39;,
            chainId: 1,
            verifyingContract: this
        }));

        tokenRegistered[0x0] = true;
        tokenDecimals[0x0] = 18;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function getOwner() public view returns (address out) {
        return owner;
    }

    function setAdmin(address admin, bool isAdmin) external onlyOwner {
        admins[admin] = isAdmin;
    }

    function deposit() external payable {
        uint amount = safeDiv(msg.value, 10**10);//wei to 8 decimals
        require(amount > 0);
        increaseBalance(msg.sender, address(0), amount);
    }

    function depositToken(address token, uint256 amount) external {
        require(amount > 0);
        require(safeTransferFrom(token, msg.sender, this, toTokenAmount(token, amount)));
        increaseBalance(msg.sender, token, amount);
    }

    function depositTokenByAdmin(address user, address token, uint256 amount)
        external onlyAdmin {
        require(amount > 0);
        require(safeTransferFrom(token, user, this, toTokenAmount(token, amount)));
        increaseBalance(user, token, amount);
    }

    function sendTips() external payable {
        uint amount = safeDiv(msg.value, 10**10);//wei to 8 decimals
        require(amount > 0);
        increaseBalance(feeAddress, address(0), amount);
    }

    function transferTips(address token, uint256 amount, address fromUser, uint nonce, uint8 v, bytes32 r, bytes32 s)
        external onlyAdmin {

        require(amount > 0);

        bytes32 hash = keccak256(abi.encode(TIPS_TYPEHASH, token, amount, nonce));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash)), v, r, s) == fromUser);

        require(!transfers[hash]);
        transfers[hash] = true;

        require(reduceBalance(fromUser, token, amount));
        increaseBalance(feeAddress, token, amount);
    }

    function transfer(address token, uint256 amount, address fromUser, address toUser, uint nonce, uint8 v, bytes32 r, bytes32 s)
        external onlyAdmin {

        require(amount > 0);

        bytes32 hash = keccak256(abi.encode(TRANSFER_TYPEHASH, token, toUser, amount, nonce));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash)), v, r, s) == fromUser);
        transfers[hash] = true;

        require(reduceBalance(fromUser, token, amount));
        increaseBalance(toUser, token, amount);
    }

    function withdrawByAdmin(address token, uint256 amount, address user, uint nonce, uint8 v, bytes32 r, bytes32 s)
        external onlyAdmin {

        require(amount > 0);
        bytes32 hash = keccak256(abi.encode(WITHDRAWAL_TYPEHASH, token, amount, nonce));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash)), v, r, s) == user);

        require(!withdrawn[hash]);
        withdrawn[hash] = true;

        require(reduceBalance(user, token, amount));
        require(sendToUser(user, token, amount));
    }

    function withdraw(address token, uint256 amount) external {

        require(amount > 0);
        require(tradesLocked[msg.sender] > block.number);
        require(reduceBalance(msg.sender, token, amount));

        require(sendToUser(msg.sender, token, amount));
    }

    function reduceBalance(address user, address token, uint256 amount) private returns(bool) {
        if (balances[token][user] < amount) return false;
        balances[token][user] = safeSub(balances[token][user], amount);
        return true;
    }

    function increaseBalanceOrWithdraw(address user, address token, uint256 amount, uint256 _withdraw) private returns(bool) {
        if (_withdraw == 1) {
            return sendToUser(user, token, amount);
        } else {
            return increaseBalance(user, token, amount);
        }
    }

    function increaseBalance(address user, address token, uint256 amount) private returns(bool) {
        balances[token][user] = safeAdd(balances[token][user], amount);
        return true;
    }

    function sendToUser(address user, address token, uint256 amount) private returns(bool) {
        if (token == address(0)) {
            return user.send(toTokenAmount(address(0), amount));
        } else {
            return safeTransfer(token, user, toTokenAmount(token, amount));
        }
    }

    function toTokenAmount(address token, uint256 amount) private view returns (uint256) {

        require(tokenRegistered[token]);
        uint256 decimals = token == address(0)
            ? 18
            : tokenDecimals[token];

        if (decimals == 8) {
            return amount;
        }

        if (decimals > 8) {
            return safeMul(amount, 10**(decimals - 8));
        } else {
            return safeDiv(amount, 10**(8 - decimals));
        }
    }

    function setTakerFeeRate(uint256 feeRate) external onlyAdmin {
        require(feeRate == 0 || feeRate >= feeRateLimit);
        takerFeeRate = feeRate;
    }

    function setMakerFeeRate(uint256 feeRate) external onlyAdmin {
        require(feeRate == 0 || feeRate >= feeRateLimit);
        makerFeeRate = feeRate;
    }

    function setFeeAddress(address _feeAddress) external onlyAdmin {
        require(_feeAddress != address(0));
        feeAddress = _feeAddress;
    }

    function disableFeesForUser(address user, uint256 timestamp) external onlyAdmin {
        require(timestamp > block.timestamp);
        disableFees[user] = timestamp;
    }

    function registerToken(address token, uint256 decimals) external onlyAdmin {
        require(!tokenRegistered[token]);
        tokenRegistered[token] = true;
        tokenDecimals[token] = decimals;
    }

    function tradesLock(address user) external {
        require(user == msg.sender);
        tradesLocked[user] = block.number + 20000;
        emit TradesLock(user);
    }

    function tradesUnlock(address user) external {
        require(user == msg.sender);
        tradesLocked[user] = 0;
        emit TradesUnlock(user);
    }

    function isUserMakerFeeEnabled(address user, uint256 disableFee) private view returns(bool) {
        return disableFee == 0 && makerFeeRate > 0 && disableFees[user] < block.timestamp;
    }

    function isUserTakerFeeEnabled(address user, uint256 disableFee) private view returns(bool) {
        return disableFee == 0 && takerFeeRate > 0 && disableFees[user] < block.timestamp;
    }

    function calculateRate(uint256 offerAmount, uint256 wantAmount) private pure returns(uint256) {
        return safeDiv(safeMul(10**8, wantAmount), offerAmount);
    }

    function trade(
        uint256[10] amounts,
        address[4] addresses,
        uint256[6] values,
        bytes32[4] rs
    ) external onlyAdmin {
        /**
            amounts: 0-offerAmount, 1-wantAmount, 2-orderExpires, 3-orderNonce, 4-offerAmount2, 5-wantAmount2, 6-orderExpires2, 7-orderNonce2, 8-offerAmountToFill, 9-wantAmountToFill
            addresses: 0-maker, 1-taker, 2-offerToken, 3-wantToken
            values: 2-withdrawMaker, 3-withdrawTaker, 4-disableMakerFee, 5-disableTakerFee
        */
        require(tradesLocked[addresses[0]] < block.number);
        require(block.timestamp <= amounts[2]);
        bytes32 orderHash = keccak256(abi.encode(ORDER_TYPEHASH, addresses[2], amounts[0], addresses[3], amounts[1], values[2], amounts[2], amounts[3]));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)), uint8(values[0]), rs[0], rs[1]) == addresses[0]);
        orderFills[orderHash] = safeAdd(orderFills[orderHash], amounts[8]);
        require(orderFills[orderHash] <= amounts[0]);

        require(tradesLocked[addresses[1]] < block.number);
        require(block.timestamp <= amounts[6]);
        bytes32 orderHash2 = keccak256(abi.encode(ORDER_TYPEHASH, addresses[3], amounts[4], addresses[2], amounts[5], values[3], amounts[6], amounts[7]));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash2)), uint8(values[1]), rs[2], rs[3]) == addresses[1]);

        uint256 makerRate = calculateRate(amounts[0], amounts[1]);
        uint256 takerRate = calculateRate(amounts[5], amounts[4]);
        require(makerRate <= takerRate);
        require(makerRate == calculateRate(amounts[8], amounts[9]));

        orderFills[orderHash2] = safeAdd(orderFills[orderHash2], amounts[9]);
        require(orderFills[orderHash2] <= amounts[4]);

        require(reduceBalance(addresses[0], addresses[2], amounts[8]));
        require(reduceBalance(addresses[1], addresses[3], amounts[9]));

        if (isUserMakerFeeEnabled(addresses[0], values[4])) {
            require(increaseBalanceOrWithdraw(addresses[0], addresses[3], safeSub(amounts[9], safeDiv(amounts[9], makerFeeRate)), values[2]));
            increaseBalance(feeAddress, addresses[3], safeDiv(amounts[9], makerFeeRate));
        } else {
            require(increaseBalanceOrWithdraw(addresses[0], addresses[3], amounts[9], values[2]));
        }

        if (isUserTakerFeeEnabled(addresses[1], values[5])) {
            require(increaseBalanceOrWithdraw(addresses[1], addresses[2], safeSub(amounts[8], safeDiv(amounts[8], takerFeeRate)), values[3]));
            increaseBalance(feeAddress, addresses[2], safeDiv(amounts[8], takerFeeRate));
        } else {
            require(increaseBalanceOrWithdraw(addresses[1], addresses[2], amounts[8], values[3]));
        }
    }

    function exchangeAndPay(
        uint256[10] amounts,
        address[5] addresses,
        uint256[4] values,
        bytes32[4] rs
    ) external onlyAdmin {
        /**
            amounts: 0-merchantReceiveAmount, 1-spendAmount, 2-orderExpires, 3-orderNonce, 4-offerAmount2, 5-wantAmount2, 6-orderExpires2, 7-orderNonce2, 8-offerAmountToFill, 9-wantAmountToFill
            addresses: 0-exchanger, 1-user, 2-merchantReceiveToken, 3-spendToken, 4-merchant
            values: 2-withdrawExchanger, 3-withdrawMerchant
        */
        require(tradesLocked[addresses[0]] < block.number);
        require(block.timestamp <= amounts[2]);
        bytes32 orderHash = keccak256(abi.encode(ORDER_TYPEHASH, addresses[2], amounts[0], addresses[3], amounts[1], values[3], amounts[2], amounts[3]));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)), uint8(values[0]), rs[0], rs[1]) == addresses[0]);
        orderFills[orderHash] = safeAdd(orderFills[orderHash], amounts[8]);
        require(orderFills[orderHash] <= amounts[0]);

        require(tradesLocked[addresses[1]] < block.number);
        require(block.timestamp <= amounts[6]);
        bytes32 orderHash2 = keccak256(abi.encode(ORDER_PAYMENT_TYPEHASH, addresses[3], amounts[4], addresses[2], amounts[5], addresses[4], amounts[6], amounts[7]));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash2)), uint8(values[1]), rs[2], rs[3]) == addresses[1]);

        uint256 makerRate = calculateRate(amounts[0], amounts[1]);
        uint256 takerRate = calculateRate(amounts[5], amounts[4]);
        require(makerRate <= takerRate);
        require(makerRate == calculateRate(amounts[8], amounts[9]));

        orderPaymentFills[orderHash2] = safeAdd(orderPaymentFills[orderHash2], amounts[9]);
        require(orderPaymentFills[orderHash2] <= amounts[4]);

        require(reduceBalance(addresses[0], addresses[2], amounts[8]));
        require(reduceBalance(addresses[1], addresses[3], amounts[9]));

        require(increaseBalanceOrWithdraw(addresses[0], addresses[3], amounts[9], values[2]));
        require(increaseBalanceOrWithdraw(addresses[4], addresses[2], amounts[8], values[3]));
        //    event OrderPayment(address indexed user, address spendToken, uint256 spendAmount, address indexed merchant, address merchantReceiveToken, uint256 merchantReceiveAmount);
        emit OrderPayment(addresses[1], addresses[1], amounts[9], addresses[4], addresses[2], amounts[2]);
    }

    function tradeWithTips(
        uint256[10] amounts,
        address[4] addresses,
        uint256[10] values,
        bytes32[4] rs
    ) external onlyAdmin {
        /**
            amounts: 0-offerAmount, 1-wantAmount, 2-orderExpires, 3-orderNonce, 4-offerAmount2, 5-wantAmount2, 6-orderExpires2, 7-orderNonce2, 8-offerAmountToFill, 9-wantAmountToFill
            addresses: 0-maker, 1-taker, 2-offerToken, 3-wantToken
            values: 2-withdrawMaker, 3-withdrawTaker, 4-orderMakerTips, 5-orderTakerTips, 6-orderMakerTips2, 7-orderTakerTips2, 8-disableMakerFee, 9-disableTakerFee
        */
        require(tradesLocked[addresses[0]] < block.number);
        require(block.timestamp <= amounts[2]);
        bytes32 orderHash = values[4] > 0 || values[5] > 0
            ? keccak256(abi.encode(ORDER_WITH_TIPS_TYPEHASH, addresses[2], amounts[0], addresses[3], amounts[1], values[2], amounts[2], amounts[3], values[4], values[5]))
            : keccak256(abi.encode(ORDER_TYPEHASH, addresses[2], amounts[0], addresses[3], amounts[1], values[2], amounts[2], amounts[3]));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)), uint8(values[0]), rs[0], rs[1]) == addresses[0]);
        orderFills[orderHash] = safeAdd(orderFills[orderHash], amounts[8]);
        require(orderFills[orderHash] <= amounts[0]);

        require(tradesLocked[addresses[1]] < block.number);
        require(block.timestamp <= amounts[6]);
        bytes32 orderHash2 = values[6] > 0 || values[7] > 0
            ? keccak256(abi.encode(ORDER_WITH_TIPS_TYPEHASH, addresses[3], amounts[4], addresses[2], amounts[5], values[3], amounts[6], amounts[7], values[6], values[7]))
            : keccak256(abi.encode(ORDER_TYPEHASH, addresses[3], amounts[4], addresses[2], amounts[5], values[3], amounts[6], amounts[7]));
        require(ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash2)), uint8(values[1]), rs[2], rs[3]) == addresses[1]);

        uint256 makerRate = calculateRate(amounts[0], amounts[1]);
        uint256 takerRate = calculateRate(amounts[5], amounts[4]);
        require(makerRate <= takerRate);
        require(makerRate == calculateRate(amounts[8], amounts[9]));

        orderFills[orderHash2] = safeAdd(orderFills[orderHash2], amounts[9]);
        require(orderFills[orderHash2] <= amounts[4]);

        require(reduceBalance(addresses[0], addresses[2], amounts[8]));
        require(reduceBalance(addresses[1], addresses[3], amounts[9]));

        if (values[4] > 0 && !isUserMakerFeeEnabled(addresses[0], values[8])) {
            increaseBalanceOrWithdraw(addresses[0], addresses[3], safeSub(amounts[9], safeDiv(amounts[9], values[4])), values[2]);
            increaseBalance(feeAddress, addresses[3], safeDiv(amounts[9], values[4]));
        } else if (values[4] == 0 && isUserMakerFeeEnabled(addresses[0], values[8])) {
            increaseBalanceOrWithdraw(addresses[0], addresses[3], safeSub(amounts[9], safeDiv(amounts[9], makerFeeRate)), values[2]);
            increaseBalance(feeAddress, addresses[3], safeDiv(amounts[9], makerFeeRate));
        } else if (values[4] > 0 && isUserMakerFeeEnabled(addresses[0], values[8])) {
            increaseBalanceOrWithdraw(addresses[0], addresses[3], safeSub(amounts[9], safeAdd(safeDiv(amounts[9], values[4]), safeDiv(amounts[9], makerFeeRate))), values[2]);
            increaseBalance(feeAddress, addresses[3], safeAdd(safeDiv(amounts[9], values[4]), safeDiv(amounts[9], makerFeeRate)));
        } else {
            increaseBalanceOrWithdraw(addresses[0], addresses[3], amounts[9], values[2]);
        }

        if (values[7] > 0 && !isUserTakerFeeEnabled(addresses[1], values[9])) {
            increaseBalanceOrWithdraw(addresses[1], addresses[2], safeSub(amounts[8], safeDiv(amounts[8], values[7])), values[3]);
            increaseBalance(feeAddress, addresses[2], safeDiv(amounts[8], values[7]));
        } else if (values[7] == 0 && isUserTakerFeeEnabled(addresses[1], values[9])) {
            increaseBalanceOrWithdraw(addresses[1], addresses[2], safeSub(amounts[8], safeDiv(amounts[8], takerFeeRate)), values[3]);
            increaseBalance(feeAddress, addresses[2], safeDiv(amounts[8], takerFeeRate));
        } else if (values[7] > 0 && isUserTakerFeeEnabled(addresses[1], values[9])) {
            increaseBalanceOrWithdraw(addresses[1], addresses[2], safeSub(amounts[8], safeAdd(safeDiv(amounts[8], values[7]), safeDiv(amounts[8], takerFeeRate))), values[3]);
            increaseBalance(feeAddress, addresses[2], safeAdd(safeDiv(amounts[8], values[7]), safeDiv(amounts[8], takerFeeRate)));
        } else {
            increaseBalanceOrWithdraw(addresses[1], addresses[2], amounts[8], values[3]);
        }
    }

    function() public payable {
        revert();
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value)
    private
    returns (bool success)
    {
        // A transfer is successful when &#39;call&#39; is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. &#39;call&#39; returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        // bytes4(keccak256("transfer(address,uint256)")) = 0xa9059cbb
        success = token.call(0xa9059cbb, to, value);
        return checkReturnValue(success);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
    private
    returns (bool success)
    {
        // A transferFrom is successful when &#39;call&#39; is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. &#39;call&#39; returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

//         bytes4(keccak256("transferFrom(address,address,uint256)")) = 0x23b872dd
        success = token.call(0x23b872dd, from, to, value);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
    )
    private
    pure
    returns (bool)
    {
        // A transfer/transferFrom is successful when &#39;call&#39; is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. &#39;call&#39; returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)
        if (success) {
            assembly {
                switch returndatasize()
                // Non-standard ERC20: nothing is returned so if &#39;call&#39; was successful we assume the transfer succeeded
                case 0 {
                    success := 1
                }
                // Standard ERC20: a single boolean value is returned which needs to be true
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                // None of the above: not successful
                default {
                    success := 0
                }
            }
        }
        return success;
    }
}