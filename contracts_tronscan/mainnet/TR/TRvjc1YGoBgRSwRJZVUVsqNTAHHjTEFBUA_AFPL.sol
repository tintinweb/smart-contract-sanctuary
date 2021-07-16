//SourceUnit: afpl_token.sol

pragma solidity ^0.4.25;

interface ITRC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
    
    //function decimals() external view returns (uint8);
}

interface IApproveAndCallFallback {
    function receiveApproval(address _from, uint _value, address _token, bytes _data) external;
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


contract AFPL is ITRC20, Ownable {
    using SafeMath for uint;

    string public symbol = "AFPL";
    string public name = "AFPL";
    uint8 constant public decimals = 8;
    uint private _totalSupply = 5000000 * 10 ** uint(decimals);

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allow;
    mapping(address => bool) private _whiteList;

    constructor () public {
        _balance[msg.sender] = _totalSupply;
        _whiteList[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// management
    bool authorizeMode = false;

    function setAuthorizeMode(bool state) public onlyOwner {
        authorizeMode = state;
    }

    function authorizeTransfer(address addr, bool ok) public onlyOwner {
        _whiteList[addr] = ok;
    }

    function check(address from, address to) internal view returns (bool) {
        if (!authorizeMode) {
            return true;
        }
        return (_whiteList[from] || _whiteList[to]);
    }
    
    function() external payable {
        revert();
    }
    
    function adminWithdraw(address addr) public onlyOwner {
        require(address(0) != addr && address(this).balance > 0);
        addr.transfer(address(this).balance);
    }

    uint private rate = 10000;
    uint public base = 10000;
    function rebase(uint _rate) public onlyOwner {
        require(_rate > 0);
        rate = _rate;
    }
    
    function increaseTotalSupply(uint amount) public onlyOwner {
        uint _amount = amount * base / rate;
        _totalSupply = _totalSupply.add(_amount);
        _balance[owner] = _balance[owner].add(_amount);
    }
    
    /// end management
    

    /// TRC20 IF
    function totalSupply () public view returns (uint) {
        return _totalSupply * rate / base;
    }

    function balanceOf(address owner) external view returns (uint) {
        return _balance[owner] * rate / base;
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allow[owner][spender] * rate / base;
    }

    function transfer(address to, uint value) external returns (bool) {
        require(check(msg.sender, to));
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        require(spender != address(0));
        require(check(msg.sender, spender));
        
        uint _value = value * base / rate;

        _allow[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(check(msg.sender, to));
        
        uint _value = value * base / rate;

        _allow[from][msg.sender] = _allow[from][msg.sender].sub(_value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allow[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        require(spender != address(0));
        require(check(msg.sender, spender));
        
        uint _value = addedValue * base / rate;

        _allow[msg.sender][spender] = _allow[msg.sender][spender].add(_value);
        emit Approval(msg.sender, spender, _allow[msg.sender][spender] * rate / base);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        require(spender != address(0));
        require(check(msg.sender, spender));
        
        uint _value = subtractedValue * base / rate;

        _allow[msg.sender][spender] = _allow[msg.sender][spender].sub(_value);
        emit Approval(msg.sender, spender, _allow[msg.sender][spender] * rate / base);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        require(to != address(0));
        
        uint _value = value * base / rate;

        _balance[from] = _balance[from].sub(_value);
        _balance[to] = _balance[to].add(_value);
        emit Transfer(from, to, value);
    }

    function burn(uint value) external {
        uint _value = value * base / rate;
        _totalSupply = _totalSupply.sub(_value);
        _balance[msg.sender] = _balance[msg.sender].sub(_value);
        emit Transfer(msg.sender, address(0), value);
    }

    function approveAndCall(address spender, uint value, bytes data) external returns (bool) {
        require(check(msg.sender, spender));
        
        uint _value = value * base / rate;

        _allow[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, value);
        IApproveAndCallFallback(spender).receiveApproval(msg.sender, value, address(this), data);
        return true;
    }

    function transferAnyTRC20Token(address tokenAddress, uint value) external onlyOwner returns (bool) {
        return ITRC20(tokenAddress).transfer(owner, value);
    }
}