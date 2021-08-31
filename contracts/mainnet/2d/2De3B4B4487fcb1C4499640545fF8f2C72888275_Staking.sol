/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Staking {
    address public owner;

    IERC20 public constant mainToken = IERC20(0x9D0B65a76274645B29e4cc41B8f23081fA09f4A3);
    IERC20 public constant boostToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IUniswapV2Pair private constant WETH_USDTPair = IUniswapV2Pair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);
    IUniswapV2Pair private constant LIME_WETHPair = IUniswapV2Pair(0xa9C511Bc021a039d5a39b95511840A7f2bB66C15);

    uint256 private requiredUSDT = 0;
    uint256 private limit = 10000000000;

    event TransferOwnership(address owner, address _newOwner);
    event Staked(address _client, uint256 period, uint256 limeAmount, uint256 usdtAmount, bool Stacked);
    event Unstaked(address _client, uint256 period, uint256 limeAmount, uint256 usdtAmount, bool Unstacked);
    event Returned(address _client, uint256 limeAmount);
    event ReturnedByOwner(address _client, uint256 limeAmount);
    event LimitIsUpdated(uint256 _newLimit);

    modifier restricted() {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), 'Invalid address: should not be 0x0');
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    struct Stake {
        uint256 start;
        uint256 period;
        uint256 LIMEAmount;
        uint256 USDTAmount;
    }
    uint256[] private periods;
    uint256[] private amounts;
    uint256[][] private rates;
    address[] private users;

    mapping(address => bool) private isStaker;
    mapping(address => Stake[]) private userStakesInfo;
    mapping(address => Stake) public stakes;

    function stake(uint8 _period, uint8 _amount) public {
        require(stakes[msg.sender].start == 0, 'Already staking');
        require(_period < periods.length, 'Invalid period');
        require(_amount < amounts.length, 'Invalid amount!');
        uint256 limeAmount = amounts[_amount] * 1e18;
        uint256 stakingPeriod = periods[_period] * 86400;
        uint256 limeBonusAmount = (limeAmount * rates[_period][_amount]) / 1e3;
        uint256 usdtAmount = getUSDTPrice(limeBonusAmount);
        require(requiredUSDT + usdtAmount <= limit, 'USDT limit exceeded, connect with owner');
        require(mainToken.transferFrom(msg.sender, address(this), limeAmount), 'Transfer is failed check your wallet balance');
        stakes[msg.sender] = Stake({start: block.timestamp, period: stakingPeriod, LIMEAmount: limeAmount, USDTAmount: usdtAmount});
        userStakesInfo[msg.sender].push(stakes[msg.sender]);
        requiredUSDT += usdtAmount;
        if (!isStaker[msg.sender]) {
            users.push(msg.sender);
            isStaker[msg.sender] = true;
        }
        emit Staked(msg.sender, stakingPeriod, limeAmount, usdtAmount, true);
    }

    function unstake() public {
        require(stakes[msg.sender].start != 0, 'Not staking!');
        Stake storage _s = stakes[msg.sender];
        require(block.timestamp >= _s.start + _s.period, 'Period not passed yet');
        require(mainToken.transfer(msg.sender, _s.LIMEAmount), 'Transfer failed, check contract balance');
        require(boostToken.transfer(msg.sender, _s.USDTAmount), 'Transfer failed, check contract balance');
        requiredUSDT -= _s.USDTAmount;
        emit Unstaked(msg.sender, _s.period, _s.LIMEAmount, _s.USDTAmount, true);
        delete stakes[msg.sender];
    }

    function getUSDTPrice(uint256 _amount) public view returns (uint256) {
        (uint256 ml, uint256 me, ) = LIME_WETHPair.getReserves();
        (uint256 ne, uint256 nu, ) = WETH_USDTPair.getReserves();
        return (_amount * me * nu) / (ml * ne);
    }

    function returnLimebyOwner(address _client) public restricted {
        require(stakes[_client].start != 0, 'Not staking!');
        Stake storage _s = stakes[_client];
        require(mainToken.transfer(_client, _s.LIMEAmount), 'Transfer failed, check contract balance');
        requiredUSDT -= _s.USDTAmount;
        emit ReturnedByOwner(_client, _s.LIMEAmount);
        delete stakes[_client];
    }

    function getBoostBalance() public view restricted returns (uint256, uint256) {
        return (boostToken.balanceOf(address(this)), requiredUSDT);
    }

    function dispenseUSDT(address _to, uint256 _amount) public restricted {
        require(_to != address(0), "Address can't be 0x0");
        require(_amount > 0, 'Amount must be > 0');
        require(_amount <= boostToken.balanceOf(address(this)), 'Contract balance is not enough');
        require(boostToken.transfer(_to, _amount), 'transferFailed');
    }

    function updateLimit(uint256 _newLimit) public restricted {
        limit = _newLimit;
        emit LimitIsUpdated(_newLimit);
    }

    function getLimit() public view restricted returns (uint256) {
        return limit;
    }

    function returnLime() public {
        require(stakes[msg.sender].start != 0, 'Not staking!');
        Stake storage _s = stakes[msg.sender];
        require(mainToken.transfer(msg.sender, _s.LIMEAmount), 'Transfer failed, check contract balance');
        requiredUSDT -= _s.USDTAmount;
        emit Returned(msg.sender, _s.LIMEAmount);
        delete stakes[msg.sender];
    }

    function setAmountsByArray(uint256[] memory _array) public restricted {
        amounts = _array;
    }

    function setPeriodsByArray(uint256[] memory _array) public restricted {
        periods = _array;
    }

    function setRatesByArray(uint256[][] memory _array) public restricted {
        rates = _array;
    }

    function setItemToRates(
        uint256 _row,
        uint256 _col,
        uint256 _value
    ) public restricted {
        uint256 length = rates.length;
        if (_row >= length) for (uint256 i = 0; i <= _row - length; i++) rates.push();
        length = rates[_row].length;
        if (_col >= length) for (uint256 i = 0; i <= _col - length; i++) rates[_row].push();
        rates[_row][_col] = _value;
    }

    function removeItemFromRates(uint256 _row, uint256 _col) public restricted {
        require(rates.length > 0, 'Array is empty!');
        require(_row < rates.length, 'Index _row is out of bounds!');
        require(rates[_row].length > 0, 'Array row is empty!');
        require(_col < rates[_row].length, 'Index _col is out of bounds!');
        for (uint256 i = _col; i < rates[_row].length - 1; i++) rates[_row][i] = rates[_row][i + 1];
        rates[_row].pop();
    }

    function initDefaultValues() public restricted {
        periods = [90, 180, 360];
        amounts = [20000, 60000, 120000, 260000, 510000, 900000];
        rates = [[26, 28, 30, 32, 34, 36], [65, 70, 75, 80, 85, 90], [162, 169, 176, 183, 190, 197]];
    }

    function getInfos() public view returns (uint256[] memory _amounts, uint256[] memory _periods, uint256[][] memory _rates) {
        _amounts = amounts;
        _periods = periods;
        _rates = rates;
    }

    function getCurrentStakes() public view restricted returns (address[] memory list, Stake[] memory s) {
        list = users;
        s = new Stake[](users.length);
        for (uint256 i = 0; i < users.length; i++) s[i] = stakes[users[i]];
    }

    function getUserStakesInfo(address _user) public view restricted returns (Stake[] memory) {
        return userStakesInfo[_user];
    }

    function getUsers() public view restricted returns (address[] memory) {
        return users;
    }

    constructor() {
        owner = msg.sender;
        initDefaultValues();
    }
}