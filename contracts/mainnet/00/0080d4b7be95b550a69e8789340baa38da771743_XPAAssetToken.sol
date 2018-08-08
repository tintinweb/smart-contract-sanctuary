pragma solidity ^0.4.21;

interface Token {
    function totalSupply() constant external returns (uint256 ts);
    function balanceOf(address _owner) constant external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface Baliv {
    function getPrice(address fromToken_, address toToken_) external view returns(uint256);
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract SafeMath {
    function safeAdd(uint x, uint y)
        internal
        pure
    returns(uint) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSub(uint x, uint y)
        internal
        pure
    returns(uint) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMul(uint x, uint y)
        internal
        pure
    returns(uint) {
        uint z = x * y;
        require((x == 0) || (z / x == y));
        return z;
    }
    
    function safeDiv(uint x, uint y)
        internal
        pure
    returns(uint) {
        require(y > 0);
        return x / y;
    }

    function random(uint N, uint salt)
        internal
        view
    returns(uint) {
        bytes32 hash = keccak256(block.number, msg.sender, salt);
        return uint(hash) % N;
    }
}

contract Authorization {
    mapping(address => bool) internal authbook;
    address[] public operators;
    address public owner;
    bool public powerStatus = true;
    function Authorization()
        public
        payable
    {
        owner = msg.sender;
        assignOperator(msg.sender);
    }
    modifier onlyOwner
    {
        assert(msg.sender == owner);
        _;
    }
    modifier onlyOperator
    {
        assert(checkOperator(msg.sender));
        _;
    }
    modifier onlyActive
    {
        assert(powerStatus);
        _;
    }
    function powerSwitch(
        bool onOff_
    )
        public
        onlyOperator
    {
        powerStatus = onOff_;
    }
    function transferOwnership(address newOwner_)
        onlyOwner
        public
    {
        owner = newOwner_;
    }
    
    function assignOperator(address user_)
        public
        onlyOwner
    {
        if(user_ != address(0) && !authbook[user_]) {
            authbook[user_] = true;
            operators.push(user_);
        }
    }
    
    function dismissOperator(address user_)
        public
        onlyOwner
    {
        delete authbook[user_];
        for(uint i = 0; i < operators.length; i++) {
            if(operators[i] == user_) {
                operators[i] = operators[operators.length - 1];
                operators.length -= 1;
            }
        }
    }

    function checkOperator(address user_)
        public
        view
    returns(bool) {
        return authbook[user_];
    }
}

contract StandardToken is SafeMath {
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Issue(address indexed _to, uint256 indexed _value);
    event Burn(address indexed _from, uint256 indexed _value);

    /* constructure */
    function StandardToken() public payable {}

    /* Send coins */
    function transfer(
        address to_,
        uint256 amount_
    )
        public
    returns(bool success) {
        if(balances[msg.sender] >= amount_ && amount_ > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], amount_);
            balances[to_] = safeAdd(balances[to_], amount_);
            emit Transfer(msg.sender, to_, amount_);
            return true;
        } else {
            return false;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public returns(bool success) {
        if(balances[from_] >= amount_ && allowed[from_][msg.sender] >= amount_ && amount_ > 0) {
            balances[to_] = safeAdd(balances[to_], amount_);
            balances[from_] = safeSub(balances[from_], amount_);
            allowed[from_][msg.sender] = safeSub(allowed[from_][msg.sender], amount_);
            emit Transfer(from_, to_, amount_);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(
        address _owner
    )
        constant
        public
    returns (uint256 balance) {
        return balances[_owner];
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(
        address _spender,
        uint256 _value
    )
        public
    returns (bool success) {
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    )
        public
    returns (bool success) {    
        if (approve(_spender, _value)) {
            TokenRecipient(_spender).receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract XPAAssetToken is StandardToken, Authorization {
    // metadata
    address[] public burners;
    string public name;
    string public symbol;
    uint256 public defaultExchangeRate;
    uint256 public constant decimals = 18;

    // constructor
    function XPAAssetToken(
        string symbol_,
        string name_,
        uint256 defaultExchangeRate_
    )
        public
    {
        totalSupply = 0;
        symbol = symbol_;
        name = name_;
        defaultExchangeRate = defaultExchangeRate_ > 0 ? defaultExchangeRate_ : 0.01 ether;
    }

    function transferOwnership(
        address newOwner_
    )
        onlyOwner
        public
    {
        owner = newOwner_;
    }

    function create(
        address user_,
        uint256 amount_
    )
        public
        onlyOperator
    returns(bool success) {
        if(amount_ > 0 && user_ != address(0)) {
            totalSupply = safeAdd(totalSupply, amount_);
            balances[user_] = safeAdd(balances[user_], amount_);
            emit Issue(owner, amount_);
            emit Transfer(owner, user_, amount_);
            return true;
        }
    }

    function burn(
        uint256 amount_
    )
        public
    returns(bool success) {
        require(allowToBurn(msg.sender));
        if(amount_ > 0 && balances[msg.sender] >= amount_) {
            balances[msg.sender] = safeSub(balances[msg.sender], amount_);
            totalSupply = safeSub(totalSupply, amount_);
            emit Transfer(msg.sender, owner, amount_);
            emit Burn(owner, amount_);
            return true;
        }
    }

    function burnFrom(
        address user_,
        uint256 amount_
    )
        public
    returns(bool success) {
        require(allowToBurn(msg.sender));
        if(balances[user_] >= amount_ && allowed[user_][msg.sender] >= amount_ && amount_ > 0) {
            balances[user_] = safeSub(balances[user_], amount_);
            totalSupply = safeSub(totalSupply, amount_);
            allowed[user_][msg.sender] = safeSub(allowed[user_][msg.sender], amount_);
            emit Transfer(user_, owner, amount_);
            emit Burn(owner, amount_);
            return true;
        }
    }

    function getDefaultExchangeRate(
    )
        public
        view
    returns(uint256) {
        return defaultExchangeRate;
    }

    function getSymbol(
    )
        public
        view
    returns(bytes32) {
        return keccak256(symbol);
    }

    function assignBurner(
        address account_
    )
        public
        onlyOperator
    {
        require(account_ != address(0));
        for(uint256 i = 0; i < burners.length; i++) {
            if(burners[i] == account_) {
                return;
            }
        }
        burners.push(account_);
    }

    function dismissBunner(
        address account_
    )
        public
        onlyOperator
    {
        require(account_ != address(0));
        for(uint256 i = 0; i < burners.length; i++) {
            if(burners[i] == account_) {
                burners[i] = burners[burners.length - 1];
                burners.length -= 1;
            }
        }
    }

    function allowToBurn(
        address account_
    )
        public
        view
    returns(bool) {
        if(checkOperator(account_)) {
            return true;
        }
        for(uint256 i = 0; i < burners.length; i++) {
            if(burners[i] == account_) {
                return true;
            }
        }
    }
}

contract TokenFactory is Authorization {
    string public version = "0.5.0";

    event eNominatingExchange(address);
    event eNominatingXPAAssets(address);
    event eNominatingETHAssets(address);
    event eCancelNominatingExchange(address);
    event eCancelNominatingXPAAssets(address);
    event eCancelNominatingETHAssets(address);
    event eChangeExchange(address, address);
    event eChangeXPAAssets(address, address);
    event eChangeETHAssets(address, address);
    event eAddFundAccount(address);
    event eRemoveFundAccount(address);

    address[] public assetTokens;
    address[] public fundAccounts;
    address public exchange = 0x008ea74569c1b9bbb13780114b6b5e93396910070a;
    address public exchangeOldVersion = 0x0013b4b9c415213bb2d0a5d692b6f2e787b927c211;
    address public XPAAssets = address(0);
    address public ETHAssets = address(0);
    address public candidateXPAAssets = address(0);
    address public candidateETHAssets = address(0);
    address public candidateExchange = address(0);
    uint256 public candidateTillXPAAssets = 0;
    uint256 public candidateTillETHAssets = 0;
    uint256 public candidateTillExchange = 0;
    address public XPA = 0x0090528aeb3a2b736b780fd1b6c478bb7e1d643170;
    address public ETH = address(0);

     /* constructor */
    function TokenFactory(
        address XPAAddr, 
        address balivAddr
    ) public {
        XPA = XPAAddr;
        exchange = balivAddr;
    }

    function createToken(
        string symbol_,
        string name_,
        uint256 defaultExchangeRate_
    )
        public
    returns(address) {
        require(msg.sender == XPAAssets);
        bool tokenRepeat = false;
        address newAsset;
        for(uint256 i = 0; i < assetTokens.length; i++) {
            if(XPAAssetToken(assetTokens[i]).getSymbol() == keccak256(symbol_)){
                tokenRepeat = true;
                newAsset = assetTokens[i];
                break;
            }
        }
        if(!tokenRepeat){
            newAsset = new XPAAssetToken(symbol_, name_, defaultExchangeRate_);
            XPAAssetToken(newAsset).assignOperator(XPAAssets);
            XPAAssetToken(newAsset).assignOperator(ETHAssets);
            for(uint256 j = 0; j < fundAccounts.length; j++) {
                XPAAssetToken(newAsset).assignBurner(fundAccounts[j]);
            }
            assetTokens.push(newAsset);
        }
        return newAsset;
    }

    // set to candadite, after 7 days set to exchange, set again after 7 days
    function setExchange(
        address exchange_
    )
        public
        onlyOperator
    {
        require(
            exchange_ != address(0)
        );
        if(
            exchange_ == exchange &&
            candidateExchange != address(0)
        ) {
            emit eCancelNominatingExchange(candidateExchange);
            candidateExchange = address(0);
            candidateTillExchange = 0;
        } else if(
            exchange == address(0)
        ) {
            // initial value
            emit eChangeExchange(address(0), exchange_);
            exchange = exchange_;
            exchangeOldVersion = exchange_;
        } else if(
            exchange_ != candidateExchange &&
            candidateTillExchange + 86400 * 7 < block.timestamp
        ) {
            // set to candadite
            emit eNominatingExchange(exchange_);
            candidateExchange = exchange_;
            candidateTillExchange = block.timestamp + 86400 * 7;
        } else if(
            exchange_ == candidateExchange &&
            candidateTillExchange < block.timestamp
        ) {
            // set to exchange
            emit eChangeExchange(exchange, candidateExchange);
            exchangeOldVersion = exchange;
            exchange = candidateExchange;
            candidateExchange = address(0);
        }
    }

    function setXPAAssets(
        address XPAAssets_
    )
        public
        onlyOperator
    {
        require(
            XPAAssets_ != address(0)
        );
        if(
            XPAAssets_ == XPAAssets &&
            candidateXPAAssets != address(0)
        ) {
            emit eCancelNominatingXPAAssets(candidateXPAAssets);
            candidateXPAAssets = address(0);
            candidateTillXPAAssets = 0;
        } else if(
            XPAAssets == address(0)
        ) {
            // initial value
            emit eChangeXPAAssets(address(0), XPAAssets_);
            XPAAssets = XPAAssets_;
        } else if(
            XPAAssets_ != candidateXPAAssets &&
            candidateTillXPAAssets + 86400 * 7 < block.timestamp
        ) {
            // set to candadite
            emit eNominatingXPAAssets(XPAAssets_);
            candidateXPAAssets = XPAAssets_;
            candidateTillXPAAssets = block.timestamp + 86400 * 7;
        } else if(
            XPAAssets_ == candidateXPAAssets &&
            candidateTillXPAAssets < block.timestamp
        ) {
            // set to XPAAssets
            emit eChangeXPAAssets(XPAAssets, candidateXPAAssets);
            dismissTokenOperator(XPAAssets);
            assignTokenOperator(candidateXPAAssets);
            XPAAssets = candidateXPAAssets;
            candidateXPAAssets = address(0);
        }
    }

    function setETHAssets(
        address ETHAssets_
    )
        public
        onlyOperator
    {
        require(
            ETHAssets_ != address(0)
        );
        if(
            ETHAssets_ == ETHAssets &&
            candidateETHAssets != address(0)
        ) {
            emit eCancelNominatingETHAssets(candidateETHAssets);
            candidateETHAssets = address(0);
            candidateTillETHAssets = 0;
        } else if(
            ETHAssets == address(0)
        ) {
            // initial value
            ETHAssets = ETHAssets_;
        } else if(
            ETHAssets_ != candidateETHAssets &&
            candidateTillETHAssets + 86400 * 7 < block.timestamp
        ) {
            // set to candadite
            emit eNominatingETHAssets(ETHAssets_);
            candidateETHAssets = ETHAssets_;
            candidateTillETHAssets = block.timestamp + 86400 * 7;
        } else if(
            ETHAssets_ == candidateETHAssets &&
            candidateTillETHAssets < block.timestamp
        ) {
            // set to ETHAssets
            emit eChangeETHAssets(ETHAssets, candidateETHAssets);
            dismissTokenOperator(ETHAssets);
            assignTokenOperator(candidateETHAssets);
            ETHAssets = candidateETHAssets;
            candidateETHAssets = address(0);
        }
    }

    function addFundAccount(
        address account_
    )
        public
        onlyOperator
    {
        require(account_ != address(0));
        for(uint256 i = 0; i < fundAccounts.length; i++) {
            if(fundAccounts[i] == account_) {
                return;
            }
        }
        for(uint256 j = 0; j < assetTokens.length; j++) {
            XPAAssetToken(assetTokens[i]).assignBurner(account_);
        }
        emit eAddFundAccount(account_);
        fundAccounts.push(account_);
    }

    function removeFundAccount(
        address account_
    )
        public
        onlyOperator
    {
        require(account_ != address(0));
        uint256 i = 0;
        uint256 j = 0;
        for(i = 0; i < fundAccounts.length; i++) {
            if(fundAccounts[i] == account_) {
                for(j = 0; j < assetTokens.length; j++) {
                    XPAAssetToken(assetTokens[i]).dismissBunner(account_);
                }
                fundAccounts[i] = fundAccounts[fundAccounts.length - 1];
                fundAccounts.length -= 1;
            }
        }
    }

    function getPrice(
        address token_
    ) 
        public
        view
    returns(uint256) {
        uint256 currPrice = Baliv(exchange).getPrice(XPA, token_);
        if(currPrice == 0) {
            currPrice = XPAAssetToken(token_).getDefaultExchangeRate();
        }
        return currPrice;
    }

    function getAssetLength(
    )
        public
        view
    returns(uint256) {
        return assetTokens.length;
    }

    function getAssetToken(
        uint256 index_
    )
        public
        view
    returns(address) {
        return assetTokens[index_];
    }

    function assignTokenOperator(address user_)
        internal
    {
        if(user_ != address(0)) {
            for(uint256 i = 0; i < assetTokens.length; i++) {
                XPAAssetToken(assetTokens[i]).assignOperator(user_);
            }
        }
    }
    
    function dismissTokenOperator(address user_)
        internal
    {
        if(user_ != address(0)) {
            for(uint256 i = 0; i < assetTokens.length; i++) {
                XPAAssetToken(assetTokens[i]).dismissOperator(user_);
            }
        }
    }
}