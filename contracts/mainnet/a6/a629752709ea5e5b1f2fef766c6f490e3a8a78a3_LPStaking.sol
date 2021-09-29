/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Staking
 * @author gotbit
 */

interface IERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address who) external view returns (uint256 balance);

    function transfer(address to, uint256 value) external returns (bool trans1);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool trans);
}

interface ILP is IERC20 {
    function token0() external view returns (IERC20);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

contract OwnableAndWhitelistble {
    address public owner;
    mapping(address => bool) internal whitelist;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WhitelistAdded(address indexed sender, address indexed whitelistUser);
    event WhitelistRemoved(address indexed sender, address indexed whitelistUser);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "You cant transfer ownerships to address 0x0");
        require(newOwner != owner, "You cant transfer ownerships to yourself");
        emit OwnershipTransferred(owner, newOwner);
        whitelist[owner] = false;
        whitelist[newOwner] = true;
        owner = newOwner;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Only whitelist users can call this function");
        _;
    }

    function addToWhitelist(address newWhitelistUser) external onlyOwner {
        require(newWhitelistUser != address(0), "You cant add to whitelist address 0x0");
        emit WhitelistAdded(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = true;
    }

    function removeFromWhitelist(address newWhitelistUser) external onlyOwner {
        require(whitelist[newWhitelistUser], "You cant remove from whitelist");
        emit WhitelistRemoved(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = false;
    }
}

contract LPStaking is OwnableAndWhitelistble {
    struct Stake {
        uint256 amount;
        uint256 startStaking;
        uint256 lastHarvest;
        uint256 bonus;
        uint256 boost;
    }

    IERC20 mainToken;
    address dividends;

    uint256 public rate = 888;
    uint256 public lowRate = 70;
    uint256 public alpha = 1111;
    uint256 public betta = 1;

    mapping(ILP => uint256) public pools;
    mapping(ILP => mapping(address => bool)) public userIncludes;
    mapping(ILP => address[]) public users;

    uint256 public constant cutoff = 48 hours;
    uint256 public constant beforeCutoff = 15;
    uint256 public constant afterCutoff = 10;

    mapping(ILP => bool) public isPermittedLP;
    mapping(address => mapping(ILP => Stake)) public stakes;

    event Staked(address indexed who, ILP indexed lpToken, uint256 amount, uint256 startTime);
    event AddedAmount(address indexed who, ILP indexed lpToken, uint256 amount);
    event Harvested(address indexed who, ILP indexed lpToken, uint256 value, uint256 toDividends);
    event Unstaked(address indexed who, ILP indexed lpToken, uint256 amount);
    event Boosted(address indexed who, ILP indexed lpToken, uint256 boost);
    event SettedPermisionLPToken(ILP indexed lpToken, bool perm);

    event SettedAlpha(address indexed sender, uint256 alpha);
    event SettedBetta(address indexed sender, uint256 betta);
    event SettedLowRate(address indexed sender, uint256 lowRate);
    event SettedDividends(address indexed sender, address indexed dividends);

    constructor(
        address _owner,
        IERC20 _token,
        address _dividends
    ) {
        owner = _owner;
        whitelist[_owner] = true;
        mainToken = _token;
        dividends = _dividends;
    }

    function stake(ILP _lpToken, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater then zero");
        require(stakes[msg.sender][_lpToken].startStaking == 0, "You have already staked");
        require(isPermittedLP[_lpToken], "You cant stake those LP tokens");

        require(_lpToken.balanceOf(msg.sender) >= _amount, "You dont enough LP tokens");
        require(_lpToken.transferFrom(msg.sender, address(this), _amount), "Transfer issues");

        addBonuses(_lpToken, _amount);

        pools[_lpToken] += _amount;

        stakes[msg.sender][_lpToken] = Stake({
            amount: _amount,
            startStaking: block.timestamp,
            lastHarvest: block.timestamp,
            bonus: 0,
            boost: 0
        });

        addUser(msg.sender, _lpToken);

        emit Staked(msg.sender, _lpToken, _amount, block.timestamp);
    }

    function addAmount(uint256 _amount, ILP _lpToken) external {
        require(_amount > 0, "Amount must be greater then zero");
        require(stakes[msg.sender][_lpToken].startStaking != 0, "You dont have stake");
        require(isPermittedLP[_lpToken], "You cant stake those LP tokens");

        require(_lpToken.balanceOf(msg.sender) >= _amount, "You dont have enough LP tokens");
        require(_lpToken.transferFrom(msg.sender, address(this), _amount), "Transfer issues");

        addBonuses(_lpToken, _amount);

        pools[_lpToken] += _amount;

        stakes[msg.sender][_lpToken].amount += _amount;

        emit AddedAmount(msg.sender, _lpToken, _amount);
    }

    function harvest(ILP _lpToken) public {
        require(stakes[msg.sender][_lpToken].startStaking != 0, "You dont have stake");

        (uint256 _value, uint256 _toDividends) = harvested(msg.sender, _lpToken);
        require(mainToken.balanceOf(address(this)) >= (_value + _toDividends), "Contract doesnt have enough DES");

        stakes[msg.sender][_lpToken].lastHarvest = block.timestamp;
        stakes[msg.sender][_lpToken].bonus = 0;

        require(mainToken.transfer(msg.sender, _value), "Transfer issues");
        require(mainToken.transfer(dividends, _toDividends), "Transfer issues");

        emit Harvested(msg.sender, _lpToken, _value, _toDividends);
    }

    function harvestedRaw(
        address _who,
        ILP _lpToken,
        uint256 _pool,
        uint256 _time
    ) public view returns (uint256 _value, uint256 _toDividends) {
        require(stakes[_who][_lpToken].startStaking != 0, "You dont have stake");

        if (stakes[_who][_lpToken].lastHarvest == 0) return (0, 0);
        Stake memory _stake = stakes[_who][_lpToken];

        uint256 _timePassed = _time - _stake.lastHarvest;
        uint256 _percentDiv = _timePassed < cutoff ? beforeCutoff : afterCutoff;

        uint256 _rewardInLP = (_stake.amount * _timePassed * (getRawRate(_pool) + _stake.boost)) /
            (100 * (365 days)) +
            _stake.bonus;
        uint256 _toDivInLP = (_rewardInLP * _percentDiv) / 100;

        uint256 _rewardInToken = LPtoToken(_lpToken, _rewardInLP);
        uint256 _toDivInToken = LPtoToken(_lpToken, _toDivInLP);

        return (_rewardInToken - _toDivInToken, _toDivInToken);
    }

    function LPtoToken(ILP _lpToken, uint256 _amountLP) public view returns (uint256) {
        uint256 _totalSupply = _lpToken.totalSupply();
        (uint112 r0, uint112 r1, ) = _lpToken.getReserves();
        if (mainToken == _lpToken.token0()) return (2 * r0 * _amountLP) / _totalSupply;
        return (2 * r1 * _amountLP) / _totalSupply;
    }

    function harvested(address _who, ILP _lpToken) public view returns (uint256 _value, uint256 _toDividends) {
        return harvestedRaw(_who, _lpToken, pools[_lpToken], block.timestamp);
    }

    function getRawRate(uint256 _pool) internal view returns (uint256 _rate) {
        return ((rate - lowRate) * alpha * 1e18) / (_pool * betta + alpha * 1e18) + lowRate;
    }

    function getRate(ILP _lpToken) external view returns (uint256 _rate) {
        return getRawRate(pools[_lpToken]);
    }

    function unstake(ILP _lpToken) public {
        require(stakes[msg.sender][_lpToken].startStaking != 0, "You dont have stake");

        harvest(_lpToken);

        uint256 _amount = stakes[msg.sender][_lpToken].amount;

        require(_lpToken.balanceOf(address(this)) >= _amount, "Contract doesnt have enough DES");

        delete stakes[msg.sender][_lpToken];

        removeUser(msg.sender, _lpToken);

        require(_lpToken.transfer(msg.sender, _amount), "Transfer issues");

        emit Unstaked(msg.sender, _lpToken, _amount);
    }

    function addUser(address _user, ILP _lpToken) internal returns (bool _status) {
        users[_lpToken].push(_user);
        userIncludes[_lpToken][_user] = true;
        return true;
    }

    function removeUser(address _user, ILP _lpToken) internal returns (bool _status) {
        uint256 _length = users[_lpToken].length;
        address[] memory _users = users[_lpToken];

        for (uint256 i = 0; i < _length; i++) {
            if (_users[i] == _user) {
                users[_lpToken][i] = _users[_length - 1];
                users[_lpToken].pop();
                userIncludes[_lpToken][_user] = false;
                return true;
            }
        }
        return false;
    }

    function addBonuses(ILP _lpToken, uint256 _amount) internal {
        uint256 _length = users[_lpToken].length;
        address[] memory _users = users[_lpToken];

        uint256 _oldPool = pools[_lpToken];
        uint256 _newPool = _oldPool + _amount;
        for (uint256 i = 0; i < _length; i++) {
            if (userIncludes[_lpToken][_users[i]]) {
                (uint256 _oldVal, ) = harvestedRaw(_users[i], _lpToken, _oldPool, block.timestamp);
                (uint256 _newVal, ) = harvestedRaw(_users[i], _lpToken, _newPool, block.timestamp);
                stakes[_users[i]][_lpToken].bonus += _oldVal - _newVal;
            }
        }
    }

    function getUsers(ILP _lpToken) public view returns (address[] memory) {
        return users[_lpToken];
    }

    function getStake(address _user, ILP _lpToken) external view returns (Stake memory) {
        return stakes[_user][_lpToken];
    }

    function setBoost(
        address _for,
        ILP _lpToken,
        uint256 _boost
    ) external onlyWhitelist {
        stakes[_for][_lpToken].boost = _boost;
        emit Boosted(_for, _lpToken, _boost);
    }

    function setDividends(address _newDividends) external onlyOwner {
        dividends = _newDividends;
        emit SettedDividends(msg.sender, _newDividends);
    }

    function setAlpha(uint256 _alpha) external onlyOwner {
        require(_alpha > 0, "Alpha is incorrect");
        alpha = _alpha;
        emit SettedAlpha(msg.sender, _alpha);
    }

    function setBetta(uint256 _betta) external onlyOwner {
        require(_betta >= 1, "Betta is incorrect");
        betta = _betta;
        emit SettedBetta(msg.sender, _betta);
    }

    function setLowRate(uint256 _lowRate) external onlyOwner {
        lowRate = _lowRate;
        emit SettedLowRate(msg.sender, _lowRate);
    }

    function setPermissionLP(ILP _lpToken, bool _perm) external onlyOwner {
        isPermittedLP[_lpToken] = _perm;
        emit SettedPermisionLPToken(_lpToken, _perm);
    }
}