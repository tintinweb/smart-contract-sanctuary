//SourceUnit: Tron.sol

/*
███████╗██╗██╗██████╗░░█████╗░████████╗
██╔════╝██║██║██╔══██╗██╔══██╗╚══██╔══╝
█████╗░░██║██║██████╦╝██║░░██║░░░██║░░░
██╔══╝░░██║██║██╔══██╗██║░░██║░░░██║░░░
██║░░░░░██║██║██████╦╝╚█████╔╝░░░██║░░░
╚═╝░░░░░╚═╝╚═╝╚═════╝░░╚════╝░░░░╚═╝░░░
*/

pragma solidity ^0.5.0;
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
   

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface TRC20 {
    function basisPointsRate() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

contract FiibotContract is Ownable {
    using SafeMath for uint256;

    event Deposit(address indexed addr, uint8 package, uint256 value);
    event Withdraw(address indexed addr, uint8 package, uint256 value);
    event Subscriptions(address indexed addr, uint8 package, bool subscribed);
    event PoolWalletChange(address oldAddress, address newAddress);
    event NewFee(uint256 fee);

    event ProfitUpdate(
        uint256 indexed blockNum,
        int16 percentageL,
        int16 percentageM,
        int16 percentageH
    );

    mapping(address => uint256[4]) private userBalances;
    mapping(address => uint256) private depositIndex;

    struct profit {
        int16 low;
        int16 medium;
        int16 high;
    }

    profit[500] public profits;

    struct profitIndex {
        uint16 start;
        uint16 finish;
    }

    profitIndex public index = profitIndex(0, 1);

    TRC20 private USDT;

    uint256[3] public subscribers;

    uint256 public fee;

    uint256 private poolWalletBalance = 0;
    address public poolWallet;
    address private backendAddress;

    modifier checkPackage(uint8 _package) {
        require(_package < 3, "Error: Unknown package/wallet");
        _;
    }

    modifier checkWallet(uint8 _wid) {
        require(_wid < 4, "Error: Unknown package/wallet");
        _;
    }

    constructor(
        address _pool,
        address _backend,
        address _token
    ) public {
        //TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t
        USDT = TRC20(_token);
        subscribers = [0, 0, 0];
        poolWallet = _pool;
        backendAddress = _backend;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit NewFee(_fee);
    }

    function changePoolWallet(address _addr) external onlyOwner {
        address prev = poolWallet;
        poolWallet = _addr;
        emit PoolWalletChange(prev, _addr);
    }

    function changeBackendAddress(address _addr) external onlyOwner {
        backendAddress = _addr;
    }

    function calculateROI(address _addr) public view returns (uint256) {
       uint256 _baseROI = userBalances[_addr][3];
        for (uint8 j = 0; j < 3; j++) {
            uint256 _base = userBalances[_addr][j];
            if (_base == 0) continue;
            int256 _prof = 0;
            for (
                uint256 i = depositIndex[_addr];
                ((index.finish > index.start && i < index.finish) ||
                    (index.finish < index.start &&
                        (i > index.start || i < index.finish)));
                i++
            ) {
                if (j == 0) _prof += profits[i].low;
                else if (j == 1) _prof += profits[i].medium;
                else _prof += profits[i].high;
            }
            if (_prof < 0) {
                _baseROI -= (_base * uint256(-_prof)).div(10000);
            } else {
                _baseROI += (_base * uint256(_prof)).div(10000);
            }
        }
        return _baseROI;
    }


    function balance(address _addr, uint8 _wid)
        public
        view
        checkWallet(_wid)
        returns (uint256)
    {
        return userBalances[_addr][_wid];
    }
    
    function subscriptions_amount(address _addr)
        external
        view
        returns (
            uint256 low,
            uint256 medium,
            uint256 high,
            uint256 roi
        )
    {
        return (
            userBalances[_addr][0],
            userBalances[_addr][1],
            userBalances[_addr][2],
            calculateROI(_addr)
        );
    }

    function subscriptions(address _addr)
        external
        view
        returns (
            bool low,
            bool medium,
            bool high
        )
    {
        return (
            balance(_addr, 0) > 0,
            balance(_addr, 1) > 0,
            balance(_addr, 2) > 0
        );
    }

    function deposit(uint8 _package, uint256 _value)
        external
        checkPackage(_package)
    {
        USDT.transferFrom(msg.sender, poolWallet, _value);
        uint256 depfee = (_value.mul(USDT.basisPointsRate())).div(10000);
        uint256 actualValue = _value.sub(depfee);
        uint256 currentBalance = userBalances[msg.sender][_package];
        if (currentBalance == 0) {
            subscribers[_package] = subscribers[_package].add(1);
            emit Subscriptions(msg.sender, _package, true);
        }
        userBalances[msg.sender][3] = calculateROI(msg.sender);
        depositIndex[msg.sender] = index.finish;
        userBalances[msg.sender][_package] = currentBalance.add(actualValue);
        poolWalletBalance = poolWalletBalance.add(actualValue);
        emit Deposit(msg.sender, _package, _value);
    }

    function transferCommission(
        address _addr,
        uint8 _dst,
        uint256 _value
    ) external checkPackage(_dst) {
        require(msg.sender == backendAddress);
        uint256 currentBalance = userBalances[_addr][_dst];
        if (currentBalance == 0) {
            subscribers[_dst] = subscribers[_dst].add(1);
            emit Subscriptions(_addr, _dst, true);
        }
        userBalances[_addr][3] = calculateROI(_addr);
        depositIndex[_addr] = index.finish;
        userBalances[_addr][_dst] = currentBalance.add(_value);
    }

    function withdrawCommission(address _addr, uint256 _value) external {
        require(msg.sender == backendAddress);
        USDT.transferFrom(poolWallet, _addr, _value.sub(fee));
        poolWalletBalance = poolWalletBalance.sub(_value.sub(fee));
        emit Withdraw(_addr, 4, _value);
    }

    function transfer(
        uint8 _src,
        uint8 _dst,
        uint256 _value
    ) external checkPackage(_dst) {
        require(_src <= 3, "Error: Source can only be <= 3");
        uint256 currentBalance = userBalances[msg.sender][_dst];
        if (currentBalance == 0) {
            subscribers[_dst] = subscribers[_dst].add(1);
            emit Subscriptions(msg.sender, _dst, true);
        }
        
        userBalances[msg.sender][3] = calculateROI(msg.sender);
        userBalances[msg.sender][_src] = userBalances[msg.sender][_src].sub(
            _value
        );
        depositIndex[msg.sender] = index.finish;
        userBalances[msg.sender][_dst] = currentBalance.add(_value);
        emit Deposit(msg.sender, _dst, _value);
    }

    function withdraw(
        address _addr,
        uint8 _wid,
        uint256 _value
    ) external onlyOwner checkWallet(_wid) {
        USDT.transferFrom(poolWallet, _addr, _value.sub(fee));
        if (_wid < 4) {
            userBalances[_addr][3] = calculateROI(_addr);
        }
        depositIndex[_addr] = index.finish;
        userBalances[_addr][_wid] = userBalances[_addr][_wid].sub(_value);
        poolWalletBalance = poolWalletBalance.sub(_value.sub(fee));
        if (userBalances[_addr][_wid] == 0 && _wid < 3) {
            subscribers[_wid] = subscribers[_wid].sub(1);
            emit Subscriptions(_addr, _wid, false);
        }
        emit Withdraw(_addr, _wid, _value);
    }

    function updateUser(address _addr) external onlyOwner {
        userBalances[_addr][3] = calculateROI(_addr);
        depositIndex[_addr] = index.finish;
    }

    function withdrawBatch(
        address[] calldata _addr,
        uint8[] calldata _wid,
        uint256[] calldata _value
    ) external onlyOwner {
        for (uint8 i = 0; i < _addr.length; i++) {
            if (_wid[i] < 5) {
                USDT.transferFrom(poolWallet, _addr[i], _value[i].sub(fee));
                if (_wid[i] < 3) {
                    userBalances[msg.sender][3] = calculateROI(msg.sender);
                }
                userBalances[_addr[i]][_wid[i]] = userBalances[_addr[i]][
                    _wid[i]
                ]
                    .sub(_value[i]);
                depositIndex[msg.sender] = index.finish;
                poolWalletBalance = poolWalletBalance.sub(_value[i].sub(fee));
                if (userBalances[_addr[i]][_wid[i]] == 0 && _wid[i] < 3) {
                    subscribers[_wid[i]] = subscribers[_wid[i]].sub(1);
                    emit Subscriptions(_addr[i], _wid[i], false);
                }
                emit Withdraw(_addr[i], _wid[i], _value[i]);
            }
        }
    }

    function setProfit(
        int16 _percentageL,
        int16 _percentageM,
        int16 _percentageH
    ) external onlyOwner {
        profits[index.finish] = profit(
            _percentageL,
            _percentageM,
            _percentageH
        );
        index.finish = (index.finish + 1) % 500;
        if (index.finish == index.start) {
            index.start = (index.start + 1) % 500;
        }
        emit ProfitUpdate(
            block.number,
            _percentageL,
            _percentageM,
            _percentageH
        );
    }

    
}