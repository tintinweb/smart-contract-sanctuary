pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract IERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    
    function allowance(address _owner, address _spender) public view returns (uint256);

}

contract IERC20Extend is IERC20 {

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool);

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool);
}

contract TokenomyFaucet is IERC20Extend {

    using SafeMath for uint256;

    // ************ 变量 **************
    string public name = "Tokenomy";
    string public symbol = "TEO";
    uint8 public constant decimals = 18;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 private total = 1000000000 * decimalFactor;
    

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    // ************ 变量 **************

    // 构造函数
    constructor () public {

        _balances[msg.sender] = total;

        emit Transfer(address(0), msg.sender, total);
    }

    function totalSupply() public view returns (uint256){
        return total;
    }

    function balanceOf(address who) public view returns (uint256){
        return _balances[who];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool){

        require(to != address(0), "Invalid address");

        require(_balances[msg.sender] >= value, "Insufficient tokens transferable");

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool){

        require(_balances[msg.sender] >= value, "Insufficient tokens approval");

        _allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0), "Invalid address");
        require(_balances[from] >= value, "Insufficient tokens transferable");
        require(_allowed[from][msg.sender] >= value, "Insufficient tokens allowable");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);

        return true;
    }

    function increaseApproval(address spender, uint256 value) public returns(bool) {

        require(_balances[msg.sender] >= value, "Insufficient tokens approval");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    function decreaseApproval(address spender, uint256 value) public returns(bool){

        uint256 oldApproval = _allowed[msg.sender][spender];

        if(oldApproval > value){
            _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(value);
        }else {
            _allowed[msg.sender][spender] = 0;
        }

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }


    /**
        非ERC20标准
     */
    function getToken(address recipient, uint256 amount) public returns(bool){
        require(amount <= 100000 * decimalFactor, "Amount should not allowed");
        require(recipient != address(0), "Invalid address");

        _balances[recipient] = _balances[recipient].add(amount);
        total = total.add(amount);
        emit Transfer(address(0), recipient, amount);

        return true;
    }
}