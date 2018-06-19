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