//SourceUnit: 发20币合约.sol

pragma solidity ^0.4.24;

interface IGOCToken {
    function transferAndFreeze(address receiver, uint256 amount) external returns (bool);
    function transfer(address receiver, uint256 amount) external returns (bool);
    function balanceOf(address receiver) external view returns (uint256);
}

contract Basic {
    uint256 constant public precision = 1000000;
    uint256 constant public yi = 100000000;
    uint256 constant public daySec = 24 * 60 * 60;
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        _assert(b > 0);
        uint256 c = a / b;
        _assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        _assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _assert(c >= a && c >= b);
        return c;
    }

    function _assert(bool assertion) internal pure {
        if (!assertion) {
            revert();
        }
    }
}

contract GOCToken is Basic, SafeMath {
    string public name = "newbie";         //  token name
    string public symbol = "NBB";       //  token symbol
    uint8 constant public decimals = 6; //  token digit
    mapping(address => uint256)  public balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public frozenBalance;
    mapping(address => uint256) public frozenTime;
    uint256 public unfreezeTime;

    uint256 constant public totalSupply = 100 * yi * precision;
    bool public stopped = false;

    address owner = 0x0;
    mapping(address => uint256) internal gameMaster;
    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert(!stopped);
        _;
    }

    constructor () public{
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }

    function transfer(address to, uint256 value) isRunning public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferAndFreeze(address to, uint256 value) isRunning public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(frozenBalance[to] + value >= frozenBalance[to]);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        frozenBalance[to] = safeAdd(frozenBalance[to], value);
        emit TransferAndFreeze(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) isRunning public returns (bool success) {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowed[from][msg.sender] >= value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        balanceOf[from] = safeSub(balanceOf[from], value);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) isRunning public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address master, address spender) public view returns (uint256 remaining) {
        return allowed[master][spender];
    }

    function stop() isOwner public {
        stopped = true;
    }

    function start() isOwner public {
        stopped = false;
    }

    function setName(string _name) isOwner public {
        name = _name;
    }

    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        balanceOf[0x0] += value;
        emit Transfer(msg.sender, 0x0, value);
    }
    
    function setUnfreezeTime(uint256 _unfreezeTime) public {
        unfreezeTime = _unfreezeTime;
        emit SetUnfreezeTime(unfreezeTime);
    }

    function freeze(uint256 value) isRunning public {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        frozenBalance[msg.sender] += value;
        frozenTime[msg.sender] = now;
        emit Freeze(msg.sender, value);
    }

    function unfreeze() isRunning public {
        require(frozenBalance[msg.sender] > 0);
        require(now > unfreezeTime);
        uint256 value = frozenBalance[msg.sender];
        balanceOf[msg.sender] += value;
        frozenBalance[msg.sender] = 0;
        
        emit Unfreeze(msg.sender, value);
    }
    
    
    
    
    
    

    function withdraw(address addr, uint256 amount) public isOwner {
        addr.transfer(amount);
        emit WithDraw(addr, amount);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferAndFreeze(address indexed from, address indexed to, uint256 value);
    event WithDraw(address _addr, uint256 _amount);
    event Freeze(address addr, uint256 value);
    event SetUnfreezeTime(uint256 value);
    event Unfreeze(address addr, uint256 value);
}

contract GOCTokenCrowdFund is Basic, SafeMath {
    IGOCToken public gocToken;

    bool public saleGoalReached = false;  //Reached  sale goal?
    uint256 constant saleGoal = 20 * yi * precision;
    uint256 public saled = 0;
    mapping(address => uint256) public saledInfo;

    address public owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier saleNotFinished {
        assert(saleGoalReached == false);
        _;
    }

    constructor (address _gocTokenAddress) public {
        owner = msg.sender;
        gocToken = IGOCToken(_gocTokenAddress);
    }

    function tokenSale() saleNotFinished public payable {
        require(msg.value >= 1000000 && msg.value <= 100 * yi * precision);
        uint256 amount = msg.value;
        uint256 price = 10;
        uint256 newSale = safeMul(amount, price);

        require(safeAdd(saled, newSale) <= saleGoal);

        saledInfo[msg.sender] += newSale;
        saled += newSale;

        gocToken.transferAndFreeze(msg.sender, newSale);
        if (saled >= saleGoal) {
            saleGoalReached = true;
        }
        emit Sale(msg.sender, newSale);
    } 

    function withdraw(uint256 value, uint256 tokenValue) public isOwner {
        if (value > 0) {
            owner.transfer(value);
        }
        if (tokenValue > 0) {
            gocToken.transfer(msg.sender, tokenValue);
        }
    }

    event Sale(address addr, uint256 value);
}