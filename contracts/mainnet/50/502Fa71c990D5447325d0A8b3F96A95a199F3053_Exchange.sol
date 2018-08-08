pragma solidity ^0.4.19;

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract EthermiumAffiliates {
    mapping(address => address[]) public referrals; // mapping of affiliate address to referral addresses
    mapping(address => address) public affiliates; // mapping of referrals addresses to affiliate addresses
    mapping(address => bool) public admins; // mapping of admin accounts
    string[] public affiliateList;
    address public owner;

    function setOwner(address newOwner);
    function setAdmin(address admin, bool isAdmin) public;
    function assignReferral (address affiliate, address referral) public;

    function getAffiliateCount() returns (uint);
    function getAffiliate(address refferal) public returns (address);
    function getReferrals(address affiliate) public returns (address[]);
}

contract EthermiumTokenList {
    function isTokenInList(address tokenAddress) public constant returns (bool);
}


contract Exchange {
    function assert(bool assertion) {
        if (!assertion) throw;
    }
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    address public owner;
    mapping (address => uint256) public invalidOrder;

    event SetOwner(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }
    function getOwner() returns (address out) {
        return owner;
    }
    function invalidateOrdersBefore(address user, uint256 nonce) onlyAdmin {
        if (nonce < invalidOrder[user]) throw;
        invalidOrder[user] = nonce;
    }

    mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances

    mapping (address => bool) public admins;
    mapping (address => uint256) public lastActiveTransaction;
    mapping (bytes32 => uint256) public orderFills;
    address public feeAccount;
    uint256 public feeAffiliate; // percentage times (1 ether)
    uint256 public inactivityReleasePeriod;
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => bool) public withdrawn;
    uint256 public makerFee; // fraction * 1 ether
    uint256 public takerFee; // fraction * 1 ether
    uint256 public affiliateFee; // fraction as proportion of 1 ether
    uint256 public makerAffiliateFee; // wei deductible from makerFee
    uint256 public takerAffiliateFee; // wei deductible form takerFee

    mapping (address => address) public referrer;  // mapping of user addresses to their referrer addresses

    address public affiliateContract;
    address public tokenListContract;


    enum Errors {
        INVLID_PRICE,           // Order prices don&#39;t match
        INVLID_SIGNATURE,       // Signature is invalid
        TOKENS_DONT_MATCH,      // Maker/taker tokens don&#39;t match
        ORDER_ALREADY_FILLED,   // Order was already filled
        GAS_TOO_HIGH            // Too high gas fee
    }

    //event Order(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    //event Cancel(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(
        address takerTokenBuy, uint256 takerAmountBuy,
        address takerTokenSell, uint256 takerAmountSell,
        address maker, address indexed taker,
        uint256 makerFee, uint256 takerFee,
        uint256 makerAmountTaken, uint256 takerAmountTaken,
        bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash
    );
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance, address indexed referrerAddress);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 withdrawFee);
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee, uint256 indexed affiliateFee);
    //event AffiliateFeeChange(uint256 newAffiliateFee);
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event CancelOrder(
        bytes32 indexed cancelHash,
        bytes32 indexed orderHash,
        address indexed user,
        address tokenSell,
        uint256 amountSell,
        uint256 cancelFee
    );

    function setInactivityReleasePeriod(uint256 expiry) onlyAdmin returns (bool success) {
        if (expiry > 1000000) throw;
        inactivityReleasePeriod = expiry;
        return true;
    }

    function Exchange(address feeAccount_, uint256 makerFee_, uint256 takerFee_, uint256 affiliateFee_, address affiliateContract_, address tokenListContract_) {
        owner = msg.sender;
        feeAccount = feeAccount_;
        inactivityReleasePeriod = 100000;
        makerFee = makerFee_;
        takerFee = takerFee_;
        affiliateFee = affiliateFee_;



        makerAffiliateFee = safeMul(makerFee, affiliateFee_) / (1 ether);
        takerAffiliateFee = safeMul(takerFee, affiliateFee_) / (1 ether);

        affiliateContract = affiliateContract_;
        tokenListContract = tokenListContract_;
    }

    function setFees(uint256 makerFee_, uint256 takerFee_, uint256 affiliateFee_) onlyOwner {
        require(makerFee_ < 10 finney && takerFee_ < 10 finney);
        require(affiliateFee_ > affiliateFee);
        makerFee = makerFee_;
        takerFee = takerFee_;
        affiliateFee = affiliateFee_;
        makerAffiliateFee = safeMul(makerFee, affiliateFee_) / (1 ether);
        takerAffiliateFee = safeMul(takerFee, affiliateFee_) / (1 ether);

        FeeChange(makerFee, takerFee, affiliateFee_);
    }

    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }

    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }

    function() external {
        throw;
    }

    function depositToken(address token, uint256 amount, address referrerAddress) {
        //require(EthermiumTokenList(tokenListContract).isTokenInList(token));
        if (referrerAddress == msg.sender) referrerAddress = address(0);
        if (referrer[msg.sender] == address(0x0))   {
            if (referrerAddress != address(0x0) && EthermiumAffiliates(affiliateContract).getAffiliate(msg.sender) == address(0))
            {
                referrer[msg.sender] = referrerAddress;
                EthermiumAffiliates(affiliateContract).assignReferral(referrerAddress, msg.sender);
            }
            else
            {
                referrer[msg.sender] = EthermiumAffiliates(affiliateContract).getAffiliate(msg.sender);
            }
        }
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
        Deposit(token, msg.sender, amount, tokens[token][msg.sender], referrer[msg.sender]);
    }

    function deposit(address referrerAddress) payable {
        if (referrerAddress == msg.sender) referrerAddress = address(0);
        if (referrer[msg.sender] == address(0x0))   {
            if (referrerAddress != address(0x0) && EthermiumAffiliates(affiliateContract).getAffiliate(msg.sender) == address(0))
            {
                referrer[msg.sender] = referrerAddress;
                EthermiumAffiliates(affiliateContract).assignReferral(referrerAddress, msg.sender);
            }
            else
            {
                referrer[msg.sender] = EthermiumAffiliates(affiliateContract).getAffiliate(msg.sender);
            }
        }
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender], referrer[msg.sender]);
    }

    function withdraw(address token, uint256 amount) returns (bool success) {
        if (safeSub(block.number, lastActiveTransaction[msg.sender]) < inactivityReleasePeriod) throw;
        if (tokens[token][msg.sender] < amount) throw;
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            if (!msg.sender.send(amount)) throw;
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw;
        }
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender], 0);
    }

    function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce);
        if (withdrawn[hash]) throw;
        withdrawn[hash] = true;
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) != user) throw;
        if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;
        if (tokens[token][user] < amount) throw;
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[address(0)][user] = safeSub(tokens[address(0x0)][user], feeWithdrawal);
        //tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        tokens[address(0)][feeAccount] = safeAdd(tokens[address(0)][feeAccount], feeWithdrawal);

        //amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        if (token == address(0)) {
            if (!user.send(amount)) throw;
        } else {
            if (!Token(token).transfer(user, amount)) throw;
        }
        lastActiveTransaction[user] = block.number;
        Withdraw(token, user, amount, tokens[token][user], feeWithdrawal);
    }

    function balanceOf(address token, address user) constant returns (uint256) {
        return tokens[token][user];
    }

    struct OrderPair {
        uint256 makerAmountBuy;
        uint256 makerAmountSell;
        uint256 makerNonce;
        uint256 takerAmountBuy;
        uint256 takerAmountSell;
        uint256 takerNonce;
        uint256 takerGasFee;
        uint256 takerIsBuying;

        address makerTokenBuy;
        address makerTokenSell;
        address maker;
        address takerTokenBuy;
        address takerTokenSell;
        address taker;

        bytes32 makerOrderHash;
        bytes32 takerOrderHash;
    }

    struct TradeValues {
        uint256 qty;
        uint256 invQty;
        uint256 makerAmountTaken;
        uint256 takerAmountTaken;
        address makerReferrer;
        address takerReferrer;
    }




    function trade(
        uint8[2] v,
        bytes32[4] rs,
        uint256[8] tradeValues,
        address[6] tradeAddresses
    ) onlyAdmin returns (uint filledTakerTokenAmount)
    {

        /* tradeValues
          [0] makerAmountBuy
          [1] makerAmountSell
          [2] makerNonce
          [3] takerAmountBuy
          [4] takerAmountSell
          [5] takerNonce
          [6] takerGasFe
          [7] takerIsBuying

          tradeAddresses
          [0] makerTokenBuy
          [1] makerTokenSell
          [2] maker
          [3] takerTokenBuy
          [4] takerTokenSell
          [5] taker
        */

        OrderPair memory t  = OrderPair({
            makerAmountBuy  : tradeValues[0],
            makerAmountSell : tradeValues[1],
            makerNonce      : tradeValues[2],
            takerAmountBuy  : tradeValues[3],
            takerAmountSell : tradeValues[4],
            takerNonce      : tradeValues[5],
            takerGasFee     : tradeValues[6],
            takerIsBuying   : tradeValues[7],

            makerTokenBuy   : tradeAddresses[0],
            makerTokenSell  : tradeAddresses[1],
            maker           : tradeAddresses[2],
            takerTokenBuy   : tradeAddresses[3],
            takerTokenSell  : tradeAddresses[4],
            taker           : tradeAddresses[5],

            makerOrderHash  : keccak256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeAddresses[2]),
            takerOrderHash  : keccak256(this, tradeAddresses[3], tradeValues[3], tradeAddresses[4], tradeValues[4], tradeValues[5], tradeAddresses[5])
        });

        //bytes32 makerOrderHash = keccak256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeAddresses[2]);
        //bytes32 makerOrderHash = &#167;
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.makerOrderHash), v[0], rs[0], rs[1]) != t.maker)
        {
            LogError(uint8(Errors.INVLID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }
        //bytes32 takerOrderHash = keccak256(this, tradeAddresses[3], tradeValues[3], tradeAddresses[4], tradeValues[4], tradeValues[5], tradeAddresses[5]);
        //bytes32 takerOrderHash = keccak256(this, t.takerTokenBuy, t.takerAmountBuy, t.takerTokenSell, t.takerAmountSell, t.takerNonce, t.taker);
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.takerOrderHash), v[1], rs[2], rs[3]) != t.taker)
        {
            LogError(uint8(Errors.INVLID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

        if (t.makerTokenBuy != t.takerTokenSell || t.makerTokenSell != t.takerTokenBuy)
        {
            LogError(uint8(Errors.TOKENS_DONT_MATCH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        } // tokens don&#39;t match

        if (t.takerGasFee > 100 finney)
        {
            LogError(uint8(Errors.GAS_TOO_HIGH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        } // takerGasFee too high



        if (!(
        (t.takerIsBuying == 0 && safeMul(t.makerAmountSell, 1 ether) / t.makerAmountBuy >= safeMul(t.takerAmountBuy, 1 ether) / t.takerAmountSell)
        ||
        (t.takerIsBuying > 0 && safeMul(t.makerAmountBuy, 1 ether) / t.makerAmountSell <= safeMul(t.takerAmountSell, 1 ether) / t.takerAmountBuy)
        ))
        {
            LogError(uint8(Errors.INVLID_PRICE), t.makerOrderHash, t.takerOrderHash);
            return 0; // prices don&#39;t match
        }

        TradeValues memory tv = TradeValues({
            qty                 : 0,
            invQty              : 0,
            makerAmountTaken    : 0,
            takerAmountTaken    : 0,
            makerReferrer       : referrer[t.maker],
            takerReferrer       : referrer[t.taker]
        });

        if (tv.makerReferrer == address(0x0)) tv.makerReferrer = feeAccount;
        if (tv.takerReferrer == address(0x0)) tv.takerReferrer = feeAccount;



        // maker buy, taker sell
        if (t.takerIsBuying == 0)
        {


            tv.qty = min(safeSub(t.makerAmountBuy, orderFills[t.makerOrderHash]), safeSub(t.takerAmountSell, safeMul(orderFills[t.takerOrderHash], t.takerAmountSell) / t.takerAmountBuy));
            if (tv.qty == 0)
            {
                LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
                return 0;
            }

            tv.invQty = safeMul(tv.qty, t.makerAmountSell) / t.makerAmountBuy;

            tokens[t.makerTokenSell][t.maker]           = safeSub(tokens[t.makerTokenSell][t.maker],           tv.invQty);
            tv.makerAmountTaken                         = safeSub(tv.qty, safeMul(tv.qty, makerFee) / (1 ether));
            tokens[t.makerTokenBuy][t.maker]            = safeAdd(tokens[t.makerTokenBuy][t.maker],            tv.makerAmountTaken);
            tokens[t.makerTokenBuy][tv.makerReferrer]   = safeAdd(tokens[t.makerTokenBuy][tv.makerReferrer],   safeMul(tv.qty,    makerAffiliateFee) / (1 ether));

            tokens[t.takerTokenSell][t.taker]           = safeSub(tokens[t.takerTokenSell][t.taker],           tv.qty);
            tv.takerAmountTaken                         = safeSub(safeSub(tv.invQty, safeMul(tv.invQty, takerFee) / (1 ether)), safeMul(tv.invQty, t.takerGasFee) / (1 ether));
            tokens[t.takerTokenBuy][t.taker]            = safeAdd(tokens[t.takerTokenBuy][t.taker],            tv.takerAmountTaken);
            tokens[t.takerTokenBuy][tv.takerReferrer]   = safeAdd(tokens[t.takerTokenBuy][tv.takerReferrer],   safeMul(tv.invQty, takerAffiliateFee) / (1 ether));

            tokens[t.makerTokenBuy][feeAccount]     = safeAdd(tokens[t.makerTokenBuy][feeAccount],      safeMul(tv.qty,    safeSub(makerFee, makerAffiliateFee)) / (1 ether));
            tokens[t.takerTokenBuy][feeAccount]     = safeAdd(tokens[t.takerTokenBuy][feeAccount],      safeAdd(safeMul(tv.invQty, safeSub(takerFee, takerAffiliateFee)) / (1 ether), safeMul(tv.invQty, t.takerGasFee) / (1 ether)));


            orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.qty);
            orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], safeMul(tv.qty, t.takerAmountBuy) / t.takerAmountSell);
            lastActiveTransaction[t.maker]          = block.number;
            lastActiveTransaction[t.taker]          = block.number;

            Trade(
                t.takerTokenBuy, tv.qty,
                t.takerTokenSell, tv.invQty,
                t.maker, t.taker,
                makerFee, takerFee,
                tv.makerAmountTaken , tv.takerAmountTaken,
                t.makerOrderHash, t.takerOrderHash
            );
            return tv.qty;
        }
        // maker sell, taker buy
        else
        {

            tv.qty = min(safeSub(t.makerAmountSell,  safeMul(orderFills[t.makerOrderHash], t.makerAmountSell) / t.makerAmountBuy), safeSub(t.takerAmountBuy, orderFills[t.takerOrderHash]));
            if (tv.qty == 0)
            {
                LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
                return 0;
            }

            tv.invQty = safeMul(tv.qty, t.makerAmountBuy) / t.makerAmountSell;

            tokens[t.makerTokenSell][t.maker]           = safeSub(tokens[t.makerTokenSell][t.maker],           tv.qty);
            tv.makerAmountTaken                         = safeSub(tv.invQty, safeMul(tv.invQty, makerFee) / (1 ether));
            tokens[t.makerTokenBuy][t.maker]            = safeAdd(tokens[t.makerTokenBuy][t.maker],            tv.makerAmountTaken);
            tokens[t.makerTokenBuy][tv.makerReferrer]   = safeAdd(tokens[t.makerTokenBuy][tv.makerReferrer],   safeMul(tv.invQty, makerAffiliateFee) / (1 ether));

            tokens[t.takerTokenSell][t.taker]           = safeSub(tokens[t.takerTokenSell][t.taker],           tv.invQty);
            tv.takerAmountTaken                         = safeSub(safeSub(tv.qty,    safeMul(tv.qty, takerFee) / (1 ether)), safeMul(tv.qty, t.takerGasFee) / (1 ether));
            tokens[t.takerTokenBuy][t.taker]            = safeAdd(tokens[t.takerTokenBuy][t.taker],            tv.takerAmountTaken);
            tokens[t.takerTokenBuy][tv.takerReferrer]   = safeAdd(tokens[t.takerTokenBuy][tv.takerReferrer],   safeMul(tv.qty,    takerAffiliateFee) / (1 ether));

            tokens[t.makerTokenBuy][feeAccount]     = safeAdd(tokens[t.makerTokenBuy][feeAccount],      safeMul(tv.invQty, safeSub(makerFee, makerAffiliateFee)) / (1 ether));
            tokens[t.takerTokenBuy][feeAccount]     = safeAdd(tokens[t.takerTokenBuy][feeAccount],      safeAdd(safeMul(tv.qty,    safeSub(takerFee, takerAffiliateFee)) / (1 ether), safeMul(tv.qty, t.takerGasFee) / (1 ether)));

            orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.invQty);
            orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], tv.qty); //safeMul(qty, tradeValues[takerAmountBuy]) / tradeValues[takerAmountSell]);

            lastActiveTransaction[t.maker]          = block.number;
            lastActiveTransaction[t.taker]          = block.number;

            Trade(
                t.takerTokenBuy, tv.qty,
                t.takerTokenSell, tv.invQty,
                t.maker, t.taker,
                makerFee, takerFee,
                tv.makerAmountTaken , tv.takerAmountTaken,
                t.makerOrderHash, t.takerOrderHash
            );
            return tv.qty;
        }
    }

    function batchOrderTrade(
        uint8[2][] v,
        bytes32[4][] rs,
        uint256[8][] tradeValues,
        address[6][] tradeAddresses
    )
    {
        for (uint i = 0; i < tradeAddresses.length; i++) {
            trade(
                v[i],
                rs[i],
                tradeValues[i],
                tradeAddresses[i]
            );
        }
    }

    function cancelOrder(
		/*
		[0] orderV
		[1] cancelV
		*/
	    uint8[2] v,

		/*
		[0] orderR
		[1] orderS
		[2] cancelR
		[3] cancelS
		*/
	    bytes32[4] rs,

		/*
		[0] orderAmountBuy
		[1] orderAmountSell
		[2] orderNonce
		[3] cancelNonce
		[4] cancelFee
		*/
		uint256[5] cancelValues,

		/*
		[0] orderTokenBuy
		[1] orderTokenSell
		[2] orderUser
		[3] cancelUser
		*/
		address[4] cancelAddresses
    ) public onlyAdmin {
        // Order values should be valid and signed by order owner
        bytes32 orderHash = keccak256(
	        this, cancelAddresses[0], cancelValues[0], cancelAddresses[1],
	        cancelValues[1], cancelValues[2], cancelAddresses[2]
        );
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == cancelAddresses[2]);

        // Cancel action should be signed by cancel&#39;s initiator
        bytes32 cancelHash = keccak256(this, orderHash, cancelAddresses[3], cancelValues[3]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", cancelHash), v[1], rs[2], rs[3]) == cancelAddresses[3]);

        // Order owner should be same as cancel&#39;s initiator
        require(cancelAddresses[2] == cancelAddresses[3]);

        // Do not allow to cancel already canceled or filled orders
        require(orderFills[orderHash] != cancelValues[0]);

        // Limit cancel fee
        if (cancelValues[4] > 50 finney) {
            cancelValues[4] = 50 finney;
        }

        // Take cancel fee
        // This operation throw an error if fee amount is more than user balance
        tokens[address(0)][cancelAddresses[3]] = safeSub(tokens[address(0)][cancelAddresses[3]], cancelValues[4]);

        // Cancel order by filling it with amount buy value
        orderFills[orderHash] = cancelValues[0];

        // Emit cancel order
        CancelOrder(cancelHash, orderHash, cancelAddresses[3], cancelAddresses[1], cancelValues[1], cancelValues[4]);
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}