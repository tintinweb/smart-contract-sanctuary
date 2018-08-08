pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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

    string public constant name = "";
    string public constant symbol = "";
    uint8 public constant decimals = 0;
}

// Ethen Decentralized Exchange Contract
// https://ethen.io/
contract Ethen is Pausable {
    // Trade & order types
    uint public constant BUY = 1; // order type BID
    uint public constant SELL = 0; // order type ASK

    // Percent multiplier in makeFee & takeFee
    uint public FEE_MUL = 1000000;

    // x1000000, 0.5%
    uint public constant MAX_FEE = 5000;

    // Time after expiration, until order will still be valid to trade.
    //
    // All trades are signed by server so it should not be possible to trade
    // expired orders. Let&#39;s say, signing happens at the last second.
    // Some time needed for transaction to be mined. If we going to require
    // here in contract that expiration time should always be less than
    // a block.timestamp than such trades will not be successful.
    // Instead we add some reasonable time, after which order still be valid
    // to trade in contract.
    uint public expireDelay = 300;

    uint public constant MAX_EXPIRE_DELAY = 600;

    // Value of keccak256(
    //     "address Contract", "string Order", "address Token", "uint Nonce",
    //     "uint Price", "uint Amount", "uint Expire"
    // )
    // See https://github.com/ethereum/EIPs/pull/712
    bytes32 public constant ETH_SIGN_TYPED_DATA_ARGHASH =
        0x3da4a05d8449a7bc291302cce8a490cf367b98ec37200076c3f13f1f2308fd74;

    // All prices are per 1e18 tokens
    uint public constant PRICE_MUL = 1e18;

    //
    // Public State Vars
    //

    // That address gets all the fees
    address public feeCollector;

    // x1000000
    uint public makeFee = 0;

    // x1000000, 2500 == 0.25%
    uint public takeFee = 2500;

    // user address to ether balances
    mapping (address => uint) public balances;

    // user address to token address to token balance
    mapping (address => mapping (address => uint)) public tokens;

    // user => order nonce => amount filled
    mapping (address => mapping (uint => uint)) public filled;

    // user => nonce => true
    mapping (address => mapping (uint => bool)) public trades;

    // Every trade should be signed by that address
    address public signer;

    // Keep track of custom fee coefficients per user
    // 0 means user will pay no fees, 50 - only 50% of fees
    struct Coeff {
        uint8   coeff; // 0-99
        uint128 expire;
    }
    mapping (address => Coeff) public coeffs;

    // Users can pay to reduce fees
    // (duration << 8) + coeff => price
    mapping(uint => uint) public packs;

    //
    // Events
    //

    event NewMakeFee(uint makeFee);
    event NewTakeFee(uint takeFee);

    event NewFeeCoeff(address user, uint8 coeff, uint128 expire, uint price);

    event DepositEther(address user, uint amount, uint total);
    event WithdrawEther(address user, uint amount, uint total);
    event DepositToken(address user, address token, uint amount, uint total);
    event WithdrawToken(address user, address token, uint amount, uint total);

    event Cancel(
        uint8 order,
        address owner,
        uint nonce,
        address token,
        uint price,
        uint amount
    );

    event Order(
        address orderOwner,
        uint orderNonce,
        uint orderPrice,
        uint tradeTokens,
        uint orderFilled,
        uint orderOwnerFinalTokens,
        uint orderOwnerFinalEther,
        uint fees
    );

    event Trade(
        address trader,
        uint nonce,
        uint trade,
        address token,
        uint traderFinalTokens,
        uint traderFinalEther
    );

    event NotEnoughTokens(
        address owner, address token, uint shouldHaveAmount, uint actualAmount
    );
    event NotEnoughEther(
        address owner, uint shouldHaveAmount, uint actualAmount
    );

    //
    // Constructor
    //

    function Ethen(address _signer) public {
        feeCollector = msg.sender;
        signer       = _signer;
    }

    //
    // Admin Methods
    //

    function setFeeCollector(address _addr) external onlyOwner {
        feeCollector = _addr;
    }

    function setSigner(address _addr) external onlyOwner {
        signer = _addr;
    }

    function setMakeFee(uint _makeFee) external onlyOwner {
        require(_makeFee <= MAX_FEE);
        makeFee = _makeFee;
        NewMakeFee(makeFee);
    }

    function setTakeFee(uint _takeFee) external onlyOwner {
        require(_takeFee <= MAX_FEE);
        takeFee = _takeFee;
        NewTakeFee(takeFee);
    }

    function addPack(
        uint8 _coeff, uint128 _duration, uint _price
    ) external onlyOwner {
        require(_coeff < 100);
        require(_duration > 0);
        require(_price > 0);

        uint key = packKey(_coeff, _duration);
        packs[key] = _price;
    }

    function delPack(uint8 _coeff, uint128 _duration) external onlyOwner {
        uint key = packKey(_coeff, _duration);
        delete packs[key];
    }

    function setExpireDelay(uint _expireDelay) external onlyOwner {
        require(_expireDelay <= MAX_EXPIRE_DELAY);
        expireDelay = _expireDelay;
    }

    //
    // User Custom Fees
    //

    function getPack(
        uint8 _coeff, uint128 _duration
    ) public view returns (uint) {
        uint key = packKey(_coeff, _duration);
        return packs[key];
    }

    // Buys new fee coefficient for given duration of time
    function buyPack(
        uint8 _coeff, uint128 _duration
    ) external payable {
        require(now >= coeffs[msg.sender].expire);

        uint key = packKey(_coeff, _duration);
        uint price = packs[key];

        require(price > 0);
        require(msg.value == price);

        updateCoeff(msg.sender, _coeff, uint128(now) + _duration, price);

        balances[feeCollector] = SafeMath.add(
            balances[feeCollector], msg.value
        );
    }

    // Sets new fee coefficient for user
    function setCoeff(
        uint8 _coeff, uint128 _expire, uint8 _v, bytes32 _r, bytes32 _s
    ) external {
        bytes32 hash = keccak256(this, msg.sender, _coeff, _expire);
        require(ecrecover(hash, _v, _r, _s) == signer);

        require(_coeff < 100);
        require(uint(_expire) > now);
        require(uint(_expire) <= now + 35 days);

        updateCoeff(msg.sender, _coeff, _expire, 0);
    }

    //
    // User Balance Related Methods
    //

    function () external payable {
        balances[msg.sender] = SafeMath.add(balances[msg.sender], msg.value);
        DepositEther(msg.sender, msg.value, balances[msg.sender]);
    }

    function depositEther() external payable {
        balances[msg.sender] = SafeMath.add(balances[msg.sender], msg.value);
        DepositEther(msg.sender, msg.value, balances[msg.sender]);
    }

    function withdrawEther(uint _amount) external {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        msg.sender.transfer(_amount);
        WithdrawEther(msg.sender, _amount, balances[msg.sender]);
    }

    function depositToken(address _token, uint _amount) external {
        require(ERC20(_token).transferFrom(msg.sender, this, _amount));
        tokens[msg.sender][_token] = SafeMath.add(
            tokens[msg.sender][_token], _amount
        );
        DepositToken(msg.sender, _token, _amount, tokens[msg.sender][_token]);
    }

    function withdrawToken(address _token, uint _amount) external {
        tokens[msg.sender][_token] = SafeMath.sub(
            tokens[msg.sender][_token], _amount
        );
        require(ERC20(_token).transfer(msg.sender, _amount));
        WithdrawToken(msg.sender, _token, _amount, tokens[msg.sender][_token]);
    }

    //
    // User Trade Methods
    //

    // Fills order so it cant be executed later
    function cancel(
        uint8   _order, // BUY for bid orders or SELL for ask orders
        address _token,
        uint    _nonce,
        uint    _price, // Price per 1e18 (PRICE_MUL) tokens
        uint    _amount,
        uint    _expire,
        uint    _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_order == BUY || _order == SELL);

        if (now > _expire + expireDelay) {
            // already expired
            return;
        }

        getVerifiedHash(
            msg.sender,
            _order, _token, _nonce, _price, _amount, _expire,
            _v, _r, _s
        );

        filled[msg.sender][_nonce] = _amount;

        Cancel(_order, msg.sender, _nonce, _token, _price, _amount);
    }

    // Does trade, places order
    // Argument hell because of "Stack to deep" errors.
    function trade(
        // _nums[0] 1=BUY, 0=SELL
        // _nums[1] trade.nonce
        // _nums[2] trade.v
        // _nums[3] trade.expire
        // _nums[4] order[0].nonce              First order should have
        // _nums[5] order[0].price              best available price
        // _nums[6] order[0].amount
        // _nums[7] order[0].expire
        // _nums[8] order[0].v
        // _nums[9] order[0].tradeAmount
        // ...
        // _nums[6N-2] order[N-1].nonce         N -> 6N+4
        // _nums[6N-1] order[N-1].price         N -> 6N+5
        // _nums[6N]   order[N-1].amount        N -> 6N+6
        // _nums[6N+1] order[N-1].expire        N -> 6N+7
        // _nums[6N+2] order[N-1].v             N -> 6N+8
        // _nums[6N+3] order[N-1].tradeAmount   N -> 6N+9
        uint[] _nums,
        // _addrs[0] token
        // _addrs[1] order[0].owner
        // ...
        // _addrs[N] order[N-1].owner           N -> N+1
        address[] _addrs,
        // _rss[0] trade.r
        // _rss[1] trade.s
        // _rss[2] order[0].r
        // _rss[3] order[0].s
        // ...
        // _rss[2N]   order[N-1].r              N -> 2N+2
        // _rss[2N+1] order[N-1].s              N -> 2N+3
        bytes32[] _rss
    ) public whenNotPaused {
        // number of orders
        uint N = _addrs.length - 1;

        require(_nums.length == 6*N+4);
        require(_rss.length == 2*N+2);

        // Type of trade
        // _nums[0] BUY or SELL
        require(_nums[0] == BUY || _nums[0] == SELL);

        // _nums[2] placeOrder.nonce
        saveNonce(_nums[1]);

        // _nums[3] trade.expire
        require(now <= _nums[3]);

        // Start building hash signed by server
        // _nums[0] BUY or SELL
        // _addrs[0] token
        // _nums[1] nonce
        // _nums[3] trade.expire
        bytes32 tradeHash = keccak256(
            this, msg.sender, uint8(_nums[0]), _addrs[0], _nums[1], _nums[3]
        );

        // Hash of an order signed by its owner
        bytes32 orderHash;

        for (uint i = 0; i < N; i++) {
            checkExpiration(i, _nums);

            orderHash = verifyOrder(i, _nums, _addrs, _rss);

            // _nums[6N+3] order[N-1].tradeAmount   N -> 6N+9
            tradeHash = keccak256(tradeHash, orderHash, _nums[6*i+9]);

            tradeOrder(i, _nums, _addrs);
        }

        checkTradeSignature(tradeHash, _nums, _rss);

        sendTradeEvent(_nums, _addrs);
    }

    //
    // Private
    //

    function saveNonce(uint _nonce) private {
        require(trades[msg.sender][_nonce] == false);
        trades[msg.sender][_nonce] = true;
    }

    // Throws error if order is expired
    function checkExpiration(
        uint _i, // order number
        uint[] _nums
    ) private view {
        // _nums[6N+1] order[N-1].expire        N -> 6N+7
        require(now <= _nums[6*_i+7] + expireDelay);
    }

    // Returns hash of order `_i`, signed by its owner
    function verifyOrder(
        uint _i, // order number
        uint[] _nums,
        address[] _addrs,
        bytes32[] _rss
    ) private view returns (bytes32 _orderHash) {
        // _nums[0] BUY or SELL
        // User is buying orders, that are selling, and vice versa
        uint8 order = _nums[0] == BUY ? uint8(SELL) : uint8(BUY);

        // _addrs[N] order[N-1].owner       N -> N+1
        // _addrs[0] token
        address owner = _addrs[_i+1];
        address token = _addrs[0];

        // _nums[6N-2] order[N-1].nonce         N -> 6N+4
        // _nums[6N-1] order[N-1].price         N -> 6N+5
        // _nums[6N]   order[N-1].amount        N -> 6N+6
        // _nums[6N+1] order[N-1].expire        N -> 6N+7
        uint nonce = _nums[6*_i+4];
        uint price = _nums[6*_i+5];
        uint amount = _nums[6*_i+6];
        uint expire = _nums[6*_i+7];

        // _nums[6N+2] order[N-1].v             N -> 6N+8
        // _rss[2N]   order[N-1].r              N -> 2N+2
        // _rss[2N+1] order[N-1].s              N -> 2N+3
        uint v = _nums[6*_i+8];
        bytes32 r = _rss[2*_i+2];
        bytes32 s = _rss[2*_i+3];

        _orderHash = getVerifiedHash(
            owner,
            order, token, nonce, price, amount,
            expire, v, r, s
        );
    }

    // Returns number of traded tokens
    function tradeOrder(
        uint _i, // order number
        uint[] _nums,
        address[] _addrs
    ) private {
        // _nums[0] BUY or SELL
        // _addrs[0] token
        // _addrs[N] order[N-1].owner           N -> N+1
        // _nums[6N-2] order[N-1].nonce         N -> 6N+4
        // _nums[6N-1] order[N-1].price         N -> 6N+5
        // _nums[6N]   order[N-1].amount        N -> 6N+6
        // _nums[6N+3] order[N-1].tradeAmount   N -> 6N+9
        executeOrder(
            _nums[0],
            _addrs[0],
            _addrs[_i+1],
            _nums[6*_i+4],
            _nums[6*_i+5],
            _nums[6*_i+6],
            _nums[6*_i+9]
        );
    }

    function checkTradeSignature(
        bytes32 _tradeHash,
        uint[] _nums,
        bytes32[] _rss
    ) private view {
        // _nums[2] trade.v
        // _rss[0] trade.r
        // _rss[1] trade.s
        require(ecrecover(
            _tradeHash, uint8(_nums[2]), _rss[0], _rss[1]
        ) == signer);
    }

    function sendTradeEvent(
        uint[] _nums, address[] _addrs
    ) private {
        // _nums[1] nonce
        // _nums[0] BUY or SELL
        // _addrs[0] token
        Trade(
            msg.sender, _nums[1], _nums[0], _addrs[0],
            tokens[msg.sender][_addrs[0]], balances[msg.sender]
        );
    }

    // Executes no more than _tradeAmount tokens from order
    function executeOrder(
        uint    _trade,
        address _token,
        address _orderOwner,
        uint    _orderNonce,
        uint    _orderPrice,
        uint    _orderAmount,
        uint    _tradeAmount
    ) private {
        var (tradeTokens, tradeEther) = getTradeParameters(
            _trade, _token, _orderOwner, _orderNonce, _orderPrice,
            _orderAmount, _tradeAmount
        );

        filled[_orderOwner][_orderNonce] = SafeMath.add(
            filled[_orderOwner][_orderNonce],
            tradeTokens
        );

        // Sanity check: orders should never overfill
        require(filled[_orderOwner][_orderNonce] <= _orderAmount);

        uint makeFees = getFees(tradeEther, makeFee, _orderOwner);
        uint takeFees = getFees(tradeEther, takeFee, msg.sender);

        swap(
            _trade, _token, _orderOwner, tradeTokens, tradeEther,
            makeFees, takeFees
        );

        balances[feeCollector] = SafeMath.add(
            balances[feeCollector],
            SafeMath.add(takeFees, makeFees)
        );

        sendOrderEvent(
            _orderOwner, _orderNonce, _orderPrice, tradeTokens,
            _token, SafeMath.add(takeFees, makeFees)
        );
    }

    function swap(
        uint _trade,
        address _token,
        address _orderOwner,
        uint _tradeTokens,
        uint _tradeEther,
        uint _makeFees,
        uint _takeFees
    ) private {
        if (_trade == BUY) {
            tokens[msg.sender][_token] = SafeMath.add(
                tokens[msg.sender][_token], _tradeTokens
            );
            tokens[_orderOwner][_token] = SafeMath.sub(
                tokens[_orderOwner][_token], _tradeTokens
            );
            balances[msg.sender] = SafeMath.sub(
                balances[msg.sender], SafeMath.add(_tradeEther, _takeFees)
            );
            balances[_orderOwner] = SafeMath.add(
                balances[_orderOwner], SafeMath.sub(_tradeEther, _makeFees)
            );
        } else {
            tokens[msg.sender][_token] = SafeMath.sub(
                tokens[msg.sender][_token], _tradeTokens
            );
            tokens[_orderOwner][_token] = SafeMath.add(
                tokens[_orderOwner][_token], _tradeTokens
            );
            balances[msg.sender] = SafeMath.add(
                balances[msg.sender], SafeMath.sub(_tradeEther, _takeFees)
            );
            balances[_orderOwner] = SafeMath.sub(
                balances[_orderOwner], SafeMath.add(_tradeEther, _makeFees)
            );
        }
    }

    function sendOrderEvent(
        address _orderOwner,
        uint _orderNonce,
        uint _orderPrice,
        uint _tradeTokens,
        address _token,
        uint _fees
    ) private {
        Order(
            _orderOwner,
            _orderNonce,
            _orderPrice,
            _tradeTokens,
            filled[_orderOwner][_orderNonce],
            tokens[_orderOwner][_token],
            balances[_orderOwner],
            _fees
        );
    }

    // Returns number of tokens that could be traded and its total price
    function getTradeParameters(
        uint _trade, address _token, address _orderOwner,
        uint _orderNonce, uint _orderPrice, uint _orderAmount, uint _tradeAmount
    ) private returns (uint _tokens, uint _totalPrice) {
        // remains on order
        _tokens = SafeMath.sub(
            _orderAmount, filled[_orderOwner][_orderNonce]
        );

        // trade no more than needed
        if (_tokens > _tradeAmount) {
            _tokens = _tradeAmount;
        }

        if (_trade == BUY) {
            // ask owner has less tokens than it is on ask
            if (_tokens > tokens[_orderOwner][_token]) {
                NotEnoughTokens(
                    _orderOwner, _token, _tokens, tokens[_orderOwner][_token]
                );
                _tokens = tokens[_orderOwner][_token];
            }
        } else {
            // not possible to sell more tokens than sender has
            if (_tokens > tokens[msg.sender][_token]) {
                NotEnoughTokens(
                    msg.sender, _token, _tokens, tokens[msg.sender][_token]
                );
                _tokens = tokens[msg.sender][_token];
            }
        }

        uint shouldHave = getPrice(_tokens, _orderPrice);

        uint spendable;
        if (_trade == BUY) {
            // max ether sender can spent
            spendable = reversePercent(
                balances[msg.sender],
                applyCoeff(takeFee, msg.sender)
            );
        } else {
            // max ether bid owner can spent
            spendable = reversePercent(
                balances[_orderOwner],
                applyCoeff(makeFee, _orderOwner)
            );
        }

        if (shouldHave <= spendable) {
            // everyone have needed amount of tokens & ether
            _totalPrice = shouldHave;
            return;
        }

        // less price -> less tokens
        _tokens = SafeMath.div(
            SafeMath.mul(spendable, PRICE_MUL), _orderPrice
        );
        _totalPrice = getPrice(_tokens, _orderPrice);

        if (_trade == BUY) {
            NotEnoughEther(
                msg.sender,
                addFees(shouldHave, applyCoeff(takeFee, msg.sender)),
                _totalPrice
            );
        } else {
            NotEnoughEther(
                _orderOwner,
                addFees(shouldHave, applyCoeff(makeFee, _orderOwner)),
                _totalPrice
            );
        }
    }

    // Returns price of _tokens
    // _orderPrice is price per 1e18 tokens
    function getPrice(
        uint _tokens, uint _orderPrice
    ) private pure returns (uint) {
        return SafeMath.div(
            SafeMath.mul(_tokens, _orderPrice), PRICE_MUL
        );
    }

    function getFees(
        uint _eth, uint _fee, address _payer
    ) private view returns (uint) {
        // _eth * (_fee / FEE_MUL)
        return SafeMath.div(
            SafeMath.mul(_eth, applyCoeff(_fee, _payer)),
            FEE_MUL
        );
    }

    function applyCoeff(uint _fees, address _user) private view returns (uint) {
        if (now >= coeffs[_user].expire) {
            return _fees;
        }
        return SafeMath.div(
            SafeMath.mul(_fees, coeffs[_user].coeff), 100
        );
    }

    function addFees(uint _eth, uint _fee) private view returns (uint) {
        // _eth * (1 + _fee / FEE_MUL)
        return SafeMath.div(
            SafeMath.mul(_eth, SafeMath.add(FEE_MUL, _fee)),
            FEE_MUL
        );
    }

    function subFees(uint _eth, uint _fee) private view returns (uint) {
        // _eth * (1 - _fee / FEE_MUL)
        return SafeMath.div(
            SafeMath.mul(_eth, SafeMath.sub(FEE_MUL, _fee)),
            FEE_MUL
        );
    }

    // Returns maximum ether that can be spent if percent _fee will be added
    function reversePercent(
        uint _balance, uint _fee
    ) private view returns (uint) {
        // _trade + _fees = _balance
        // _trade * (1 + _fee / FEE_MUL) = _balance
        // _trade = _balance * FEE_MUL / (FEE_MUL + _fee)
        return SafeMath.div(
            SafeMath.mul(_balance, FEE_MUL),
            SafeMath.add(FEE_MUL, _fee)
        );
    }

    // Gets hash of an order, like it is done in `eth_signTypedData`
    // See https://github.com/ethereum/EIPs/pull/712
    function hashOrderTyped(
        uint8 _order, address _token, uint _nonce, uint _price, uint _amount,
        uint _expire
    ) private view returns (bytes32) {
        require(_order == BUY || _order == SELL);
        return keccak256(
            ETH_SIGN_TYPED_DATA_ARGHASH,
            keccak256(
                this,
                _order == BUY ? "BUY" : "SELL",
                _token,
                _nonce,
                _price,
                _amount,
                _expire
            )
        );
    }

    // Gets hash of an order for `eth_sign`
    function hashOrder(
        uint8 _order, address _token, uint _nonce, uint _price, uint _amount,
        uint _expire
    ) private view returns (bytes32) {
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            keccak256(this, _order, _token, _nonce, _price, _amount, _expire)
        );
    }

    // Returns hash of an order
    // Reverts if signature is incorrect
    function getVerifiedHash(
        address _signer,
        uint8 _order, address _token,
        uint _nonce, uint _price, uint _amount, uint _expire,
        uint _v, bytes32 _r, bytes32 _s
    ) private view returns (bytes32 _hash) {
        if (_v < 1000) {
            _hash = hashOrderTyped(
                _order, _token, _nonce, _price, _amount, _expire
            );
            require(ecrecover(_hash, uint8(_v), _r, _s) == _signer);
        } else {
            _hash = hashOrder(
                _order, _token, _nonce, _price, _amount, _expire
            );
            require(ecrecover(_hash, uint8(_v - 1000), _r, _s) == _signer);
        }
    }

    function packKey(
        uint8 _coeff, uint128 _duration
    ) private pure returns (uint) {
        return (uint(_duration) << 8) + uint(_coeff);
    }

    function updateCoeff(
        address _user, uint8 _coeff, uint128 _expire, uint price
    ) private {
        coeffs[_user] = Coeff(_coeff, _expire);
        NewFeeCoeff(_user, _coeff, _expire, price);
    }
}