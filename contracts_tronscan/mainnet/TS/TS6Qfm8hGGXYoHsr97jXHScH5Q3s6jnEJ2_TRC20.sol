//SourceUnit: token.sol

pragma solidity ^0.5.8;

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;
    address public owner;
    address public exchangePairAddr;
    bool public isAllBurn;
    mapping(address => bool) public managers;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;
    uint256 public _threshold;
    uint256 public _thresholdLevel;
    uint256 public _maxDis;
    uint256 public _minDis;
    bool public _pairDirection;

    string public constant name = "YIDA";
    string public constant symbol = "YIDA";
    uint8 public constant decimals = 6;

    uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));

    bool public saleFlage; // true
    mapping(address => bool) public fromWhiteList;
    mapping(address => bool) public toWhiteList;
    mapping(address => bool) public toSSString;
    address[] public toFristWhietListArr;
    uint256 public startTime;
    uint256 public DURATION = 15 minutes;
    uint256 public limitAmount = 2000 * 1e6;
    mapping(address => bool) public toSSSWhitSaleFlage;
    bool public checkTime;
    address public supperAddr;

    address public teamAddr;

    uint256 public teamRate;


    constructor() public {
        owner = msg.sender;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function pairRate() public view returns (uint256) {
        if (_pairDirection) {
            if (_totalSupply <= _threshold) {
                return _minDis;
            }
            return
            _maxDis.sub(
                INITIAL_SUPPLY.sub(_totalSupply).div(_thresholdLevel).div(
                    10 ** uint256(decimals)
                )
            );
        } else {
            if (INITIAL_SUPPLY <= _totalSupply) {
                return _minDis;
            }
            return
            _minDis.add(
                INITIAL_SUPPLY.sub(_totalSupply).div(_thresholdLevel).div(
                    10 ** uint256(decimals)
                )
            );
        }
    }

    function checkDirection() private {
        if (_totalSupply <= _threshold || _totalSupply > INITIAL_SUPPLY) {
            _pairDirection = !_pairDirection;
        }
    }

    function setThreshold(uint256 threshold) public onlyManager {
        _threshold = threshold;
    }

    function setThresholdLevel(uint256 level) public onlyManager {
        _thresholdLevel = level;
    }

    function setMaxDis(uint256 dis) public onlyManager {
        _maxDis = dis;
    }

    function setExchangePairAddr(address addr) public onlyManager {
        exchangePairAddr = addr;
    }

    function setMinDis(uint256 dis) public onlyManager {
        _minDis = dis;
    }

    function setTeamRate(uint256 rate) public onlyManager {
        teamRate = rate;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender)
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        require(checkTransfer(from, to, value), "not right transfer");


        if (from == exchangePairAddr || to == exchangePairAddr || isAllBurn) {
            checkDirection();
            uint256 cRate = pairRate();
            uint256 affect = value.mul(cRate).div(100);
            if (_pairDirection) {
                value = value.add(affect);
                _totalSupply = _totalSupply.add(affect);
            } else {
                value = value.sub(affect);
                _totalSupply = _totalSupply.sub(affect);
            }
        }


        uint256 teamReward = value.mul(teamRate).div(100);
        _balances[teamAddr] = _balances[teamAddr].add(teamReward);
        _balances[to] = _balances[to].add(value.sub(teamReward));
        emit Transfer(from, to, value.sub(teamReward));
    }

    function checkTransfer(address from, address to, uint256 value) internal returns (bool){
        if (from == supperAddr) {
            return true;
        }
        if (!saleFlage) {

            if (now >= startTime + DURATION) {
                return true;
            }
            if (fromWhiteList[from]) {
                uint256 len = toFristWhietListArr.length;
                uint256 totalSale;
                for (uint256 i = 0; i < len; i++) {
                    if (toSSSWhitSaleFlage[toFristWhietListArr[i]]) {
                        totalSale++;
                    }
                }
                if (totalSale == len) {
                    //
                    if (toWhiteList[to]) {
                        if (value > limitAmount) {
                            return false;
                        } else {
                            return true;
                        }
                    } else {
                        return false;
                    }
                } else {
                    if (toSSString[to]) {
                        toSSSWhitSaleFlage[to] = true;
                        return true;
                    } else {
                        return false;
                    }
                }

            }
        }
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _threshold = (10 ** uint256(decimals)).mul(80000);
        _thresholdLevel = 5000;
        _maxDis = 5;
        _minDis = 2;
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function addManager(address _mAddr) public {
        require(msg.sender == owner, "!governance");
        managers[_mAddr] = true;
    }

    function setDURATION(uint256 time) public onlyManager {
        DURATION = time;
    }

    function setSaleFlage(bool startSale) public onlyManager {
        saleFlage = startSale;
    }

    function setIsAllBurn(bool isAll) public onlyManager {
        isAllBurn = isAll;
    }

    function setStartTime(uint256 _time) public onlyManager {
        startTime = _time;
    }

    function setLimitAmount(uint256 limit) public onlyManager {
        limitAmount = limit;
    }

    function setToWhiteList(address to, bool isAdd, bool isFirst) public onlyManager {
        if (isFirst) {
            if (isAdd) {
                toSSString[to] = true;
                toFristWhietListArr.push(to);
            } else {
                toSSString[to] = false;
                uint256 len = toFristWhietListArr.length;
                for (uint256 i = 0; i < len; i++) {
                    if (toFristWhietListArr[i] == to) {
                        delete toFristWhietListArr[i];
                        toFristWhietListArr.length--;
                    }
                }
            }
        } else {
            if (isAdd) {
                toWhiteList[to] = true;
            } else {
                toWhiteList[to] = false;
            }
        }

    }

    function checkTimeFalge(bool ischeckTime) public onlyManager {
        checkTime = ischeckTime;
    }

    function setFromWhiteList(address from, bool isAdd) public onlyManager {
        if (isAdd) {
            fromWhiteList[from] = true;
        } else {
            fromWhiteList[from] = false;
        }
    }

    function setSupperAddr(address supper) public onlyManager {
        supperAddr = supper;
    }


    function setTeamAddr(address tAddr) public onlyManager {
        teamAddr = tAddr;
    }


    function removeManager(address _mAddr) public {
        require(msg.sender == owner, "!governance");
        managers[_mAddr] = false;
    }

    modifier onlyManager{
        require(managers[msg.sender], "only managers");
        _;
    }


}