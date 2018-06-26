pragma solidity ^0.4.17;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
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
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public pure returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


/*
    owned 是一个管理者
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address _prevOwner, address _newOwner);

    /**
     * 初始化构造函数
     */
    function Owned() public {
        owner = msg.sender;
    }

    /**
     * 判断当前合约调用者是否是管理员
     */
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    /**
     * 指派一个新的管理员
     * @param  _newOwner address 新的管理员帐户地址
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract IToken {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public pure returns (string) {}
    function symbol() public pure returns (string) {}
    function decimals() public pure returns (uint8) {}
    function totalSupply() public pure returns (uint256) {}
    function balanceOf(address _owner) public pure returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public pure returns (uint256) { _owner; _spender; }

    function _transfer(address _from, address _to, uint256 _value) internal;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);

}


contract Token is IToken, Owned, Utils {
    /* 公共变量 */
    string public standard = &#39;&#39;;
    string public name = &#39;&#39;; //代币名称
    string public symbol = &#39;&#39;; //代币符号比如&#39;$&#39;
    uint8 public decimals = 0;  //代币单位
    uint256 public totalSupply = 0; //代币总量

    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* 在区块链上创建一个事件，用以通知客户端*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //设置允许用户支付最大金额通知

    function Token() public 
    {
        name = &#39;MCNC健康树&#39;;
        symbol = &#39;MCNC&#39;;
        decimals = 8;
        totalSupply = 2000000000 * 10 ** uint256(decimals);

        balanceOf[owner] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value)
      internal
      validAddress(_from)
      validAddress(_to)
    {

      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      uint previousBalances = safeAdd(balanceOf[_from], balanceOf[_to]);
      balanceOf[_from] = safeSub(balanceOf[_from], _value);
      balanceOf[_to] += safeAdd(balanceOf[_to], _value);

      emit Transfer(_from, _to, _value);

      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }

    function transfer(address _to, uint256 _value)
      public
      validAddress(_to)
      returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool)
    {
        //检查发送者是否拥有足够余额支出的设置
        require(_value <= allowance[_from][msg.sender]);   // Check allowance

        allowance[_from][msg.sender] -= safeSub(allowance[_from][msg.sender], _value);

        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {

        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract IMCNC {

    function _transfer(address _from, address _to, uint256 _value) internal;
    function freezeAccount(address target, bool freeze) public;
}


contract SmartToken is Owned, Token {

    string public version = &#39;1.0&#39;;

    event NewSmartToken(address _token);

    function SmartToken()
        public
        Token ()
    {
        emit NewSmartToken(address(this));
    }

}


contract MCNC is IMCNC, Token {

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);


    function MCNC()
      public
      Token ()
    {
        emit NewSmartToken(address(this));
    }


    function _transfer(address _from, address _to, uint _value)
        validAddress(_from)
        validAddress(_to)
        internal
    {
        require (balanceOf[_from] > _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);

        //通知任何监听该交易的客户端
        emit Transfer(_from, _to, _value);

    }

    function freezeAccount(address target, bool freeze)
        validAddress(target)
        public
        onlyOwner
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}