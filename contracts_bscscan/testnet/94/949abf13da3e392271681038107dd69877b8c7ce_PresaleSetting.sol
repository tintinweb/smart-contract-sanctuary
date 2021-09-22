// SPDX-License-Identifier: UNLICENSED

// WETH = WBNB
// ETH = BNB
// ALl Percent Will be divided with 1000
// ALl time unit is second and timestamp
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

contract PresaleSetting is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private WHITELIST_TOKEN_ADDRESS;
    mapping(address => uint256) public WHITELIST_TOKEN_BALANCE;
    EnumerableSet.AddressSet private LIST_REFERER;
    EnumerableSet.AddressSet private LIST_BASE_TOKEN;

    struct Setting {
        uint256 BASE_FEE_PERCENT;
        uint256 TOKEN_FEE_PERCENT;
        address payable BASE_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        uint256 CREATION_FEE; // fee to generate a presale contract on the platform
        uint256 FIRST_ROUND_LENGTH; // length of round 1 in seconds
        uint256 MAX_PRESALE_LENGTH; // maximum seconds between start and end time
        uint256 MIN_LIQUIDITY_PERCENT;
        address payable ADMIN_ADDRESS;
        uint256 MIN_LOCK_PERIOD;
        uint256 MAX_SUCCESS_TO_LIQUIDITY;
        address WRAP_TOKEN_ADDRESS;
        address DEX_LOCKER_ADDRESS;
    }

    struct ZeroRound {
        address TOKEN_ADDRESS;
        uint256 TOKEN_AMOUNT;
        uint256 PERCENT; // Percent Of Hard Cap
        uint256 FINISH_BEFORE_FIRST_ROUND; // second before first round start
    }

    struct Referer {
        uint256 LEVEL_NUMBER;
        address TOKEN_ADDRESS;
        uint256[] LEVEL_AMOUNT;
        uint256[] LEVEL_PERCENT;
    }

    Setting public SETTING;
    ZeroRound public ZERO_ROUND;
    Referer public REFERER_INFO;

    constructor() {
        // SETTING
        SETTING.BASE_FEE_PERCENT = 18;
        SETTING.TOKEN_FEE_PERCENT = 18;
        SETTING.BASE_FEE_ADDRESS = payable(msg.sender);
        SETTING.TOKEN_FEE_ADDRESS = payable(msg.sender);
        SETTING.CREATION_FEE = 1e18;
        SETTING.FIRST_ROUND_LENGTH = 3600;
        SETTING.MAX_PRESALE_LENGTH = 1209600;
        SETTING.MIN_LIQUIDITY_PERCENT = 300;
        SETTING.ADMIN_ADDRESS = payable(msg.sender);
        SETTING.MIN_LOCK_PERIOD = 4 weeks;
        SETTING.MAX_SUCCESS_TO_LIQUIDITY = 2 days;
        SETTING.WRAP_TOKEN_ADDRESS = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
        SETTING.DEX_LOCKER_ADDRESS = address(0xe741ad412f44532FedBC358D04C17b9446335BaA);

        // ZERO_ROUND
        ZERO_ROUND.TOKEN_ADDRESS = address(0);
        ZERO_ROUND.TOKEN_AMOUNT = 0;
        ZERO_ROUND.PERCENT = 300;
        ZERO_ROUND.FINISH_BEFORE_FIRST_ROUND = 600;

        // REFERER LEVEL
        REFERER_INFO.TOKEN_ADDRESS = address(0);
        REFERER_INFO.LEVEL_NUMBER = 4;
        REFERER_INFO.LEVEL_AMOUNT = [0, 1e6 * (10 ** 8), 2e6 * (10 ** 8), 5e6 * (10 ** 8)];
        REFERER_INFO.LEVEL_PERCENT = [100, 200, 300, 500];

    }

    // SETTING MAIN INFO
    function getSettingInfo() external view returns (
        uint256 baseFeePercent,
        uint256 tokenFeePercent,
        uint256 creationFee,
        uint256 firstRoundLength,
        uint256 maxPresaleLength,
        uint256 minLiquidityPercent,
        uint256 minLockPeriod,
        uint256 maxSuccessToLiquidity
    ) {
        return (
        SETTING.BASE_FEE_PERCENT,
        SETTING.TOKEN_FEE_PERCENT,
        SETTING.CREATION_FEE,
        SETTING.FIRST_ROUND_LENGTH,
        SETTING.MAX_PRESALE_LENGTH,
        SETTING.MIN_LIQUIDITY_PERCENT,
        SETTING.MIN_LOCK_PERIOD,
        SETTING.MAX_SUCCESS_TO_LIQUIDITY
        );
    }

    function setSettingInfo(
        uint256 baseFeePercent,
        uint256 tokenFeePercent,
        uint256 creationFee,
        uint256 firstRoundLength,
        uint256 maxPresaleLength,
        uint256 minLiquidityPercent,
        uint256 minLockPeriod,
        uint256 maxSuccessToLiquidity
    ) external onlyOwner {
        require(baseFeePercent <= 1000, 'PRESALE SETTING: INVALID BASE FEE PERCENT');
        require(tokenFeePercent <= 1000, 'PRESALE SETTING: INVALID TOKEN FEE PERCENT');
        require(minLiquidityPercent >= 300 && minLiquidityPercent <= 1000, 'PRESALE SETTING: INVALID MIN LIQUIDITY PERCENT');

        SETTING.BASE_FEE_PERCENT = baseFeePercent;
        SETTING.TOKEN_FEE_PERCENT = tokenFeePercent;
        SETTING.CREATION_FEE = creationFee;
        SETTING.FIRST_ROUND_LENGTH = firstRoundLength;
        SETTING.MAX_PRESALE_LENGTH = maxPresaleLength;
        SETTING.MIN_LIQUIDITY_PERCENT = minLiquidityPercent;
        SETTING.MIN_LOCK_PERIOD = minLockPeriod;
        SETTING.MAX_SUCCESS_TO_LIQUIDITY = maxSuccessToLiquidity;

    }

    // SETTING ADDRESS
    function getSettingAddress() external view returns (
        address baseFeeAddress,
        address tokenFeeAddress,
        address adminAddress,
        address wrapTokenAddress,
        address dexLockerAddress
    ) {
        return (
        SETTING.BASE_FEE_ADDRESS,
        SETTING.TOKEN_FEE_ADDRESS,
        SETTING.ADMIN_ADDRESS,
        SETTING.WRAP_TOKEN_ADDRESS,
        SETTING.DEX_LOCKER_ADDRESS
        );
    }

    function setSettingAddress(
        address baseFeeAddress,
        address tokenFeeAddress,
        address adminAddress,
        address wrapTokenAddress,
        address dexLockerAddress
    ) external onlyOwner {
        SETTING.BASE_FEE_ADDRESS = payable(baseFeeAddress);
        SETTING.TOKEN_FEE_ADDRESS = payable(tokenFeeAddress);
        SETTING.ADMIN_ADDRESS = payable(adminAddress);
        SETTING.WRAP_TOKEN_ADDRESS = wrapTokenAddress;
        SETTING.DEX_LOCKER_ADDRESS = dexLockerAddress;

    }

    // BASE FEE PERCENT
    function getBaseFeePercent() external view returns (uint256) {
        return SETTING.BASE_FEE_PERCENT;
    }

    function setBaseFeePercent(uint256 _baseFeePercent) external onlyOwner {
        require(_baseFeePercent <= 1000, 'PRESALE SETTING: INVALID BASE FEE PERCENT');
        SETTING.BASE_FEE_PERCENT = _baseFeePercent;
    }

    // TOKEN FEE PERCENT
    function getTokenFeePercent() external view returns (uint256) {
        return SETTING.TOKEN_FEE_PERCENT;
    }

    function setTokenFeePercent(uint256 _tokenFeePercent) external onlyOwner {
        require(_tokenFeePercent <= 1000, 'PRESALE SETTING: INVALID TOKEN FEE PERCENT');
        SETTING.TOKEN_FEE_PERCENT = _tokenFeePercent;
    }

    // CREATION FEE
    function getCreationFee() external view returns (uint256) {
        return SETTING.CREATION_FEE;
    }

    function setCreationFee(uint256 _creationFee) external onlyOwner {
        SETTING.CREATION_FEE = _creationFee;
    }

    // FEES
    function getFees() external view returns (uint256 baseFeePercent, uint256 tokenFeePercent, uint256 creationFee) {
        return (SETTING.BASE_FEE_PERCENT, SETTING.TOKEN_FEE_PERCENT, SETTING.CREATION_FEE);
    }

    function setFees(uint256 _baseFeePercent, uint256 _tokenFeePercent, uint256 _creationFee) external onlyOwner {
        require(_baseFeePercent <= 1000, 'PRESALE SETTING: INVALID BASE FEE PERCENT');
        require(_tokenFeePercent <= 1000, 'PRESALE SETTING: INVALID TOKEN FEE PERCENT');
        SETTING.BASE_FEE_PERCENT = _baseFeePercent;
        SETTING.TOKEN_FEE_PERCENT = _tokenFeePercent;
        SETTING.CREATION_FEE = _creationFee;
    }

    // BASE FEE ADDRESS
    function getBaseFeeAddress() external view returns (address payable) {
        return SETTING.BASE_FEE_ADDRESS;
    }

    function setBaseFeeAddress(address payable _baseFeeAddress) external onlyOwner {
        SETTING.BASE_FEE_ADDRESS = _baseFeeAddress;
    }

    // TOKEN FEE ADDRESS
    function getTokenFeeAddress() external view returns (address payable) {
        return SETTING.TOKEN_FEE_ADDRESS;
    }

    function setTokenFeeAddress(address payable _tokenFeeAddress) external onlyOwner {
        SETTING.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }

    // FEE ADDRESSES
    function getFeeAddresses() external view returns (address baseFeeAddress, address tokenFeeAddress) {
        return (SETTING.BASE_FEE_ADDRESS, SETTING.TOKEN_FEE_ADDRESS);
    }

    function setFeeAddresses(address payable _baseFeeAddress, address payable _tokenFeeAddress) external onlyOwner {
        SETTING.BASE_FEE_ADDRESS = payable(_baseFeeAddress);
        SETTING.TOKEN_FEE_ADDRESS = payable(_tokenFeeAddress);
    }

    // FIRST ROUND LENGTH
    function getFirstRoundLength() external view returns (uint256) {
        return SETTING.FIRST_ROUND_LENGTH;
    }

    function setFirstRoundLength(uint256 _firstRoundLength) external onlyOwner {
        SETTING.FIRST_ROUND_LENGTH = _firstRoundLength;
    }

    // MAX PRESALE LENGTH
    function getMaxPresaleLength() external view returns (uint256) {
        return SETTING.MAX_PRESALE_LENGTH;
    }

    function setMaxPresaleLength(uint256 _maxLength) external onlyOwner {
        SETTING.MAX_PRESALE_LENGTH = _maxLength;
    }

    // MIN LIQUIDITY PERCENT
    function getMinLiquidityPercent() external view returns (uint256) {
        return SETTING.MIN_LIQUIDITY_PERCENT;
    }

    function setMinLiquidityPercent(uint256 _minLiquidityPercent) external onlyOwner {
        require(_minLiquidityPercent >= 300 && _minLiquidityPercent <= 1000, 'PRESALE SETTING: INVALID MIN LIQUIDITY PERCENT');
        SETTING.MIN_LIQUIDITY_PERCENT = _minLiquidityPercent;
    }

    // ADMIN ADDRESS
    function getAdminAddress() external view returns (address){
        return SETTING.ADMIN_ADDRESS;
    }

    function setAdminAddress(address payable _adminAddress) external onlyOwner {
        SETTING.ADMIN_ADDRESS = _adminAddress;
    }

    // MIN LOCK PERIOD
    function getMinLockPeriod() external view returns (uint256){
        return SETTING.MIN_LOCK_PERIOD;
    }

    function setMinLockPeriod(uint256 _time) external onlyOwner {
        require(_time >= 4 weeks, 'PRESALE SETTING: INVALID LOCK PERIOD');
        SETTING.MIN_LOCK_PERIOD = _time;
    }

    // MAX SUCCESS TO LIQUIDITY
    function getMaxSuccessToLiquidity() external view returns (uint256){
        return SETTING.MAX_SUCCESS_TO_LIQUIDITY;
    }

    function setMaxSuccessToLiquidity(uint256 _time) external onlyOwner {
        require(_time <= 2 days, 'PRESALE SETTING: INVALID MAX SUCCESS TO LIQUIDITY');
        SETTING.MAX_SUCCESS_TO_LIQUIDITY = _time;
    }

    // WRAP TOKEN ADDRESS
    function getWrapTokenAddress() external view returns (address){
        return SETTING.WRAP_TOKEN_ADDRESS;
    }

    function setWrapTokenAddress(address _wrapTokenAddress) external onlyOwner {
        require(_wrapTokenAddress != address(0), 'PRESALE SETTING: INVALID WRAP TOKEN ADDRESS');
        SETTING.WRAP_TOKEN_ADDRESS = _wrapTokenAddress;
    }

    // DEX LOCKER ADDRESS
    function getDexLockerAddress() external view returns (address){
        return SETTING.DEX_LOCKER_ADDRESS;
    }

    function setDexLockerAddress(address _dexLockerAddress) external onlyOwner {
        require(_dexLockerAddress != address(0), 'PRESALE SETTING: INVALID DEX LOCKER ADDRESS');
        SETTING.DEX_LOCKER_ADDRESS = _dexLockerAddress;
    }

    // ZERO ROUND TOKEN ADDRESS
    function getZeroRoundTokenAddress() external view returns (address){
        return ZERO_ROUND.TOKEN_ADDRESS;
    }

    function setZeroRoundTokenAddress(address _tokenAddress) external onlyOwner {
        ZERO_ROUND.TOKEN_ADDRESS = _tokenAddress;
    }

    // ZERO ROUND TOKEN AMOUNT
    function getZeroRoundTokenAmount() external view returns (uint256){
        return ZERO_ROUND.TOKEN_AMOUNT;
    }

    function setZeroRoundTokenAmount(uint256 _tokenAmount) external onlyOwner {
        ZERO_ROUND.TOKEN_AMOUNT = _tokenAmount;
    }

    // ZERO ROUND TOKEN PERCENT
    function getZeroRoundPercent() external view returns (uint256){
        return ZERO_ROUND.PERCENT;
    }

    function setZeroRoundPercent(uint256 _percent) external onlyOwner {
        require(_percent <= 1000, 'PRESALE SETTING: INVALID PERCENT');
        ZERO_ROUND.PERCENT = _percent;
    }

    // ZERO ROUND FINISH BEFORE FIRST ROUND
    function getFinishBeforeFirstRound() external view returns (uint256){
        return ZERO_ROUND.FINISH_BEFORE_FIRST_ROUND;
    }

    function setFinishBeforeFirstRound(uint256 finishBeforeFirstRound) external onlyOwner {
        ZERO_ROUND.FINISH_BEFORE_FIRST_ROUND = finishBeforeFirstRound;
    }

    // ZERO ROUND
    function getZeroRound() external view returns (address tokenAddress, uint256 tokenAmount, uint256 percent, uint256 finishBeforeFirstRound){
        return (ZERO_ROUND.TOKEN_ADDRESS, ZERO_ROUND.TOKEN_AMOUNT, ZERO_ROUND.PERCENT, ZERO_ROUND.FINISH_BEFORE_FIRST_ROUND);
    }

    function setZeroRound(address tokenAddress, uint256 tokenAmount, uint256 percent, uint256 finishBeforeFirstRound) external onlyOwner {
        ZERO_ROUND.TOKEN_ADDRESS = tokenAddress;
        ZERO_ROUND.TOKEN_AMOUNT = tokenAmount;
        ZERO_ROUND.PERCENT = percent;
        ZERO_ROUND.FINISH_BEFORE_FIRST_ROUND = finishBeforeFirstRound;
    }

    // LIST REFERER
    function updateReferer(address payable _referer, bool _allow) external onlyOwner {
        if (_allow) {
            LIST_REFERER.add(_referer);
        } else {
            LIST_REFERER.remove(_referer);
        }
    }

    function getRefererLength() public view returns (uint256) {
        return LIST_REFERER.length();
    }

    function getRefererAtIndex(uint256 _index) external view returns (address) {
        return LIST_REFERER.at(_index);
    }

    function refererIsValid(address _referer) external view returns (bool) {
        return LIST_REFERER.contains(_referer);
    }

    // WHITELIST TOKEN
    function updateWhitelistToken(address _token, uint256 _holdAmount, bool _allow) external onlyOwner {
        if (_allow) {
            WHITELIST_TOKEN_ADDRESS.add(_token);
        } else {
            WHITELIST_TOKEN_ADDRESS.remove(_token);
            _holdAmount = 0;
        }
        WHITELIST_TOKEN_BALANCE[_token] = _holdAmount;
    }

    // Remember to manage number of whitelist token due to gas cost
    function userHoldSufficientFirstRoundToken(address _user) external view returns (bool) {
        if (whitelistTokenLength() == 0) {
            return true;
        }
        for (uint256 i = 0; i < whitelistTokenLength(); i++) {
            (address tokenAddress, uint256 amountHold) = getWhitelistTokenAtIndex(i);
            if (IERC20(tokenAddress).balanceOf(_user) >= amountHold) {
                return true;
            }
        }
        return false;
    }

    function getWhitelistTokenAtIndex(uint256 _index) public view returns (address, uint256) {
        address tokenAddress = WHITELIST_TOKEN_ADDRESS.at(_index);
        return (tokenAddress, WHITELIST_TOKEN_BALANCE[tokenAddress]);
    }

    function whitelistTokenLength() public view returns (uint256) {
        return WHITELIST_TOKEN_ADDRESS.length();
    }

    // REFERER
    function getReferer() external view returns (address tokenAddress, uint256 levelNumber, uint256[] memory levelAmount, uint256[] memory levelPercent){
        return (REFERER_INFO.TOKEN_ADDRESS, REFERER_INFO.LEVEL_NUMBER, REFERER_INFO.LEVEL_AMOUNT, REFERER_INFO.LEVEL_PERCENT);
    }

    function setReferer(address tokenAddress, uint256 levelNumber, uint256[] memory levelAmount, uint256[] memory levelPercent) external onlyOwner {
        require(levelAmount.length == levelNumber && levelPercent.length == levelNumber, 'PRESALE SETTING: INVALID DATA');

        if (levelNumber == 0) {
            delete REFERER_INFO.LEVEL_AMOUNT;
            delete REFERER_INFO.LEVEL_PERCENT;
        }

        REFERER_INFO.TOKEN_ADDRESS = tokenAddress;
        REFERER_INFO.LEVEL_NUMBER = levelNumber;
        REFERER_INFO.LEVEL_AMOUNT = levelAmount;
        REFERER_INFO.LEVEL_PERCENT = levelPercent;
    }

    function getRefererPercent(address _user) external view returns (uint256) {
        if (getRefererLength() == 0 || REFERER_INFO.LEVEL_NUMBER == 0) {
            return 0;
        }

        uint256 percent = 0;
        for (uint256 i = 0; i < REFERER_INFO.LEVEL_NUMBER; i++) {
            if (IERC20(REFERER_INFO.TOKEN_ADDRESS).balanceOf(_user) >= REFERER_INFO.LEVEL_AMOUNT[i]) {
                percent = REFERER_INFO.LEVEL_PERCENT[i];
            } else {
                break;
            }
        }
        return percent;
    }

    // LIST BASE TOKEN
    function updateBaseToken(address _baseToken, bool _allow) external onlyOwner {
        if (_allow) {
            LIST_BASE_TOKEN.add(_baseToken);
        } else {
            LIST_BASE_TOKEN.remove(_baseToken);
        }
    }

    function getListBaseTokenLength() external view returns (uint256) {
        return LIST_BASE_TOKEN.length();
    }

    function getBaseTokenAtIndex(uint256 _index) external view returns (address) {
        return LIST_BASE_TOKEN.at(_index);
    }

    function baseTokenIsValid(address _baseToken) external view returns (bool) {
        return LIST_BASE_TOKEN.contains(_baseToken);
    }

}