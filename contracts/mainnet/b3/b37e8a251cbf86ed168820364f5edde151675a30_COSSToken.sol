pragma solidity ^0.4.16;

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/**
    COSS Token implementation
*/
contract COSSToken is IERC20Token, SafeMath {
    string public standard = &#39;COSS&#39;;
    string public name = &#39;COSS&#39;;
    string public symbol = &#39;COSS&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply = 54359820;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) public revenueShareList;
    mapping (address => string) public revenueShareCurrency;
    mapping (address => uint256) public revenueShareDistribution;

    uint256 public decimalMultiplier = 1000000000000000000;
    uint256 public icoSold = 9359820;
    address public revenueShareOwnerAddress;
    address public icoWalletAddress = 0xbf7aa06109ce182203ee3805614736fe18dead43;
    address public teamWalletAddress = 0x552b3f0c1747cfefc726bc669bd4fde2d20f9cf2;
    address public affiliateProgramWalletAddress = 0xd30e8e92ee0cc95a7fefb5eafdd0deb678ab41d7;
    address public shareholdersWalletAddress = 0x56a8330345e75bafbb17443889e19302ba528e7c;    

    /**
        @dev constructor
    */
    function COSSToken() {
        revenueShareOwnerAddress = msg.sender;
        balanceOf[revenueShareOwnerAddress] = safeMul(icoSold,decimalMultiplier);
        balanceOf[teamWalletAddress] = safeMul(30000000,decimalMultiplier);
        balanceOf[affiliateProgramWalletAddress] = safeMul(10000000,decimalMultiplier);
        balanceOf[shareholdersWalletAddress] = safeMul(5000000,decimalMultiplier);
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    function activateRevenueShareReference(uint256 _revenueShareItem) {
        revenueShareList[msg.sender] = _revenueShareItem;
    }

    function addRevenueShareCurrency(address _currencyAddress,string _currencyName) {
        if (msg.sender == revenueShareOwnerAddress) {
            revenueShareCurrency[_currencyAddress] = _currencyName;
            revenueShareDistribution[_currencyAddress] = 0;
        }
    }

    function saveRevenueShareDistribution(address _currencyAddress, uint256 _value) {
        if (msg.sender == revenueShareOwnerAddress) {
            revenueShareDistribution[_currencyAddress] = safeAdd(revenueShareDistribution[_currencyAddress], _value);
        }
    }

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn&#39;t
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn&#39;t
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn&#39;t
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}