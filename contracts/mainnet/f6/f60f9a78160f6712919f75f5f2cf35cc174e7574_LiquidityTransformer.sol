/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IReferral {
    function setReferrer(address farmer, address referrer) external;
    function getReferrer(address farmer) external view returns (address);
    function isValidReferrer(address referrer) external view returns (bool);
    function rndSeed(uint256 rnd) external view returns (address, bool);
}

contract LiquidityTransformer {
    uint256 public constant SECONDS_PER_DAY = 1 days;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    uint256 public constant TOTAL_RESERVE_DAYS = 50;
    uint256 public constant RESERVE_ETH_UNIT = 100 finney;

    struct DailyState {
        mapping(address => uint256) userAmount;
        mapping(address => uint256) referrerAmount;
        uint256 totalAmount;
        uint256 userCount;
    }

    struct DailyConfig{
        uint256 twap;
        uint256 dt;
    }

    DailyState[TOTAL_RESERVE_DAYS] public reserveDays;
    DailyConfig[TOTAL_RESERVE_DAYS] public configDays;

    uint256 public totalScrap;
    uint256 public launchTime;

    IReferral public iReferral;
    mapping(address => bool) private operator;

    event Reserved(uint256 indexed day, address indexed user, address indexed referer, uint256 amount);
    event Recovered(address indexed token, uint256 amount);
    event Launched(uint256 time);

    constructor() public {
        operator[msg.sender] = true;

        for (uint256 i=0; i<TOTAL_RESERVE_DAYS; i++) {
            reserveDays[i] = DailyState(0,0);
            configDays[i] = DailyConfig(0,0);
        }
    }

    modifier onlyOperator{
        require(operator[msg.sender]);
        _;
    }

    function _condition(uint256 _lteDay, uint256 _lteAmount) internal view returns (bool) {
        require(msg.value >= _lteAmount, 'DAO: the actual amount below LTE Amount');
        require(msg.value >= RESERVE_ETH_UNIT, 'DAO: LTE Amount below minimum');

        require(_lteDay < TOTAL_RESERVE_DAYS, 'DAO: incorrect LTE day');
        DailyConfig memory cfg = configDays[_lteDay];
        require(cfg.twap == 0, 'DAO: closed');

        return true;
    }

    function firstReserveRand(uint256 _lteAmount, uint256 rand) external payable {
        require(!iReferral.isValidReferrer(msg.sender), 'DAO: not first');
        require(_condition(currentDay(), _lteAmount));

        (address _referrerAddress, ) = iReferral.rndSeed(rand);
        iReferral.setReferrer(msg.sender, _referrerAddress);

        // use the current day as the LTE day for the first reserve
        _reserve(currentDay(), msg.sender);
    }

    function firstReserve(uint256 _lteAmount, address _referrerAddress) external payable {
        require(!iReferral.isValidReferrer(msg.sender), 'DAO: not first');
        require(_condition(currentDay(), _lteAmount));

        iReferral.setReferrer(msg.sender, _referrerAddress);

        // use the current day as the LTE day for the first reserve
        _reserve(currentDay(), msg.sender);
    }

    function reserve(uint256 _lteDay, uint256 _lteAmount) external payable {
        require(iReferral.isValidReferrer(msg.sender), 'DAO: the caller should be a referer');
        require(_condition(_lteDay, _lteAmount));

        _reserve(_lteDay, msg.sender);
    }

    function reserveFor(uint256 _lteDay, uint256 _lteAmount, address _beneficiaryAddress) external payable {
        require(iReferral.isValidReferrer(msg.sender), 'DAO: the caller should be a referer');
        require(_condition(_lteDay, _lteAmount));

        require(_beneficiaryAddress != address(0), 'DAO: cannot be 0');
        if (!iReferral.isValidReferrer(_beneficiaryAddress)) {
            iReferral.setReferrer(_beneficiaryAddress, msg.sender);
        }

        _reserve(_lteDay, _beneficiaryAddress);
    }

    function _reserve(uint256 _lteDay, address _userAddress) internal {
        uint256 _scrap = msg.value % RESERVE_ETH_UNIT;
        uint256 _availableAmount = msg.value - _scrap;
        totalScrap += _scrap;

        address _referrerAddress = iReferral.getReferrer(_userAddress);

        DailyState storage day = reserveDays[_lteDay];

        if (day.userAmount[_userAddress] == 0) {
            day.userCount++;
        }

        day.userAmount[_userAddress] += _availableAmount;
        day.referrerAmount[_referrerAddress] += _availableAmount;
        day.totalAmount += _availableAmount;

        emit Reserved(_lteDay, _userAddress, _referrerAddress, _availableAmount);
    }

    function userAmount(address account, uint256 day) external view returns (uint256) {
        return reserveDays[day].userAmount[account];
    }

    function referrerAmount(address account, uint256 day) external view returns (uint256) {
        return reserveDays[day].referrerAmount[account];
    }

    function userTotalAmount(address account) external view returns (uint256) {
        uint256 _totalAmount = 0;
        for(uint256 i=0; i<TOTAL_RESERVE_DAYS; i++){
            _totalAmount += reserveDays[i].userAmount[account];
        }
        return _totalAmount;
    }

    function referrerTotalAmount(address account) external view returns (uint256) {
        uint256 _totalAmount = 0;
        for(uint256 i=0; i<TOTAL_RESERVE_DAYS; i++){
            _totalAmount += reserveDays[i].referrerAmount[account];
        }
        return _totalAmount;
    }

    function currentDay() public view returns (uint256) {
        return now >= launchTime ? (now - launchTime) / SECONDS_PER_DAY : 0;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOperator {
        _safeTransfer(tokenAddress, msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function withdrawLTE(uint256 amount) external onlyOperator {
        msg.sender.transfer(amount);
    }

    function launch(uint256 time) external onlyOperator {
        require(launchTime == 0);
        require(time >= now);
        launchTime = time;

        emit Launched(launchTime);
    }

    function update(uint256[TOTAL_RESERVE_DAYS] calldata dts) external onlyOperator {
        for (uint256 i=0; i<TOTAL_RESERVE_DAYS; i++) {
            configDays[i].dt = dts[i];
        }
    }

    function twapOracle(uint256 day, uint256 twap) external onlyOperator {
        require(day < TOTAL_RESERVE_DAYS);
        DailyConfig storage cfg = configDays[day];
        cfg.twap = twap;
    }

    function setReferral(address _iReferral) external onlyOperator {
        require(_iReferral != address(0));
        iReferral = IReferral(_iReferral);
    }

    function setOperator(address payable op, bool flag) external onlyOperator {
        require(op != address(0));
        require(op != msg.sender, '!self');
        operator[op] = flag;
    }
}