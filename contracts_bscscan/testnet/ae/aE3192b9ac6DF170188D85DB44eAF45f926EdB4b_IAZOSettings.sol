//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

/*
 * ApeSwapFinance 
 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com    
 * Twitter:         https://twitter.com/ape_swap 
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

/// @title IAZO settings
/// @author ApeSwapFinance
/// @notice Settings for new IAZOs
contract IAZOSettings {

    struct Settings {
        address ADMIN_ADDRESS;
        address payable FEE_ADDRESS;
        address BURN_ADDRESS;
        uint256 BASE_FEE; // base fee percentage
        uint256 MAX_BASE_FEE; // max base fee percentage
        uint256 IAZO_TOKEN_FEE; // base fee percentage
        uint256 MAX_IAZO_TOKEN_FEE; // max base fee percentage
        uint256 NATIVE_CREATION_FEE; // fee to generate a IAZO contract on the platform
        uint256 MIN_IAZO_LENGTH; // minimum iazo active seconds
        uint256 MAX_IAZO_LENGTH; // maximum iazo active seconds
        uint256 MIN_LOCK_PERIOD;
        uint256 MIN_LIQUIDITY_PERCENT;
    }

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event UpdateFeeAddress(address indexed previousFeeAddress, address indexed newFeeAddress);
    event UpdateFees(uint256 previousBaseFee, uint256 newBaseFee, uint256 previousIAZOTokenFee, uint256 newIAZOTokenFee, uint256 previousETHFee, uint256 newETHFee);
    event UpdateMinIAZOLength(uint256 previousMinLength, uint256 newMinLength);
    event UpdateMaxIAZOLength(uint256 previousMaxLength, uint256 newMaxLength);
    event UpdateMinLockPeriod(uint256 previousMinLockPeriod, uint256 newMinLockPeriod);
    event UpdateMinLiquidityPercent(uint256 previousMinLiquidityPercent, uint256 newMinLiquidityPercent);
    event UpdateBurnAddress(address previousBurnAddress, address newBurnAddress);

    Settings public SETTINGS;

    bool constant public isIAZOSettings = true;
    
    constructor(address admin, address feeAddress) {
        // Percentages are multiplied by 1000
        SETTINGS.ADMIN_ADDRESS = admin;     
        SETTINGS.BASE_FEE = 50;                     // .05 (5%) - initial base fee %
        SETTINGS.MAX_BASE_FEE = 300;                // .30 (30%) - max base fee %
        SETTINGS.IAZO_TOKEN_FEE = 50;               // .05 (5%) - initial iazo fee %
        SETTINGS.MAX_IAZO_TOKEN_FEE = 300;          // .30 (30%) - max iazo fee %
        SETTINGS.NATIVE_CREATION_FEE = 1e18;        // 1 native token(s)
        SETTINGS.FEE_ADDRESS = payable(feeAddress); 
        SETTINGS.MIN_IAZO_LENGTH = 43200;           // 12 hrs (in seconds)
        SETTINGS.MAX_IAZO_LENGTH = 1814000;         // 3 weeks (in seconds) 
        SETTINGS.MIN_LOCK_PERIOD = 2419000;         // 28 days (in seconds)
        SETTINGS.MIN_LIQUIDITY_PERCENT = 300;       // .30 (30%) of raise matched with IAZO tokens
        SETTINGS.BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    }

    modifier onlyAdmin {
        require(
            msg.sender == SETTINGS.ADMIN_ADDRESS,
            "not called by admin"
        );
        _;
    }

    function getAdminAddress() external view returns (address) {
        return SETTINGS.ADMIN_ADDRESS;
    }

    function isAdmin(address toCheck) external view returns (bool) {
        return SETTINGS.ADMIN_ADDRESS == toCheck;
    }

    function getMaxIAZOLength() external view returns (uint256) {
        return SETTINGS.MAX_IAZO_LENGTH;
    }

    function getMinIAZOLength() external view returns (uint256) {
        return SETTINGS.MIN_IAZO_LENGTH;
    }
    
    function getBaseFee() external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }

    function getIAZOTokenFee() external view returns (uint256) {
        return SETTINGS.IAZO_TOKEN_FEE;
    }

    function getMaxBaseFee() external view returns (uint256) {
        return SETTINGS.MAX_BASE_FEE;
    }

    function getMaxIAZOTokenFee() external view returns (uint256) {
        return SETTINGS.MAX_IAZO_TOKEN_FEE;
    }
    
    function getNativeCreationFee() external view returns (uint256) {
        return SETTINGS.NATIVE_CREATION_FEE;
    }

    function getMinLockPeriod() external view returns (uint256) {
        return SETTINGS.MIN_LOCK_PERIOD;
    }

    function getMinLiquidityPercent() external view returns (uint256) {
        return SETTINGS.MIN_LIQUIDITY_PERCENT;
    }
    
    function getFeeAddress() external view returns (address payable) {
        return SETTINGS.FEE_ADDRESS;
    }

    function getBurnAddress() external view returns (address) {
        return SETTINGS.BURN_ADDRESS;
    }

    function setAdminAddress(address _address) external onlyAdmin {
        address previousAdmin = SETTINGS.ADMIN_ADDRESS;
        SETTINGS.ADMIN_ADDRESS = _address;
        emit AdminTransferred(previousAdmin, SETTINGS.ADMIN_ADDRESS);
    }
    
    function setFeeAddress(address payable _address) external onlyAdmin {
        address previousFeeAddress = SETTINGS.FEE_ADDRESS;
        SETTINGS.FEE_ADDRESS = _address;
        emit UpdateFeeAddress(previousFeeAddress, SETTINGS.FEE_ADDRESS);
    }
    
    function setFees(uint256 _baseFee, uint256 _iazoTokenFee, uint256 _nativeCreationFee) external onlyAdmin {
        require(_baseFee <= SETTINGS.MAX_BASE_FEE, "base fee over max allowable");
        uint256 previousBaseFee = SETTINGS.BASE_FEE;
        SETTINGS.BASE_FEE = _baseFee;

        require(_iazoTokenFee <= SETTINGS.MAX_IAZO_TOKEN_FEE, "IAZO token fee over max allowable");
        uint256 previousIAZOTokenFee = SETTINGS.IAZO_TOKEN_FEE;
        SETTINGS.IAZO_TOKEN_FEE = _iazoTokenFee;

        uint256 previousETHFee = SETTINGS.NATIVE_CREATION_FEE;
        SETTINGS.NATIVE_CREATION_FEE = _nativeCreationFee;
        emit UpdateFees(previousBaseFee, SETTINGS.BASE_FEE, previousIAZOTokenFee, SETTINGS.IAZO_TOKEN_FEE, previousETHFee, SETTINGS.NATIVE_CREATION_FEE);
    }

    function setMaxIAZOLength(uint256 _maxLength) external onlyAdmin {
        require(_maxLength >= SETTINGS.MIN_IAZO_LENGTH);
        uint256 previousMaxLength = SETTINGS.MAX_IAZO_LENGTH;
        SETTINGS.MAX_IAZO_LENGTH = _maxLength;
        emit UpdateMaxIAZOLength(previousMaxLength, SETTINGS.MAX_IAZO_LENGTH);
    }  

    function setMinIAZOLength(uint256 _minLength) external onlyAdmin {
        require(_minLength <= SETTINGS.MAX_IAZO_LENGTH);
        uint256 previousMinLength = SETTINGS.MIN_IAZO_LENGTH;
        SETTINGS.MIN_IAZO_LENGTH = _minLength;
        emit UpdateMinIAZOLength(previousMinLength, SETTINGS.MIN_IAZO_LENGTH);
    }   

    function setMinLockPeriod(uint256 _minLockPeriod) external onlyAdmin {
        uint256 previousMinLockPeriod = SETTINGS.MIN_LOCK_PERIOD;
        SETTINGS.MIN_LOCK_PERIOD = _minLockPeriod;
        emit UpdateMinLockPeriod(previousMinLockPeriod, SETTINGS.MIN_LOCK_PERIOD);
    }

    function setMinLiquidityPercent(uint256 _minLiquidityPercent) external onlyAdmin {
        uint256 previousMinLiquidityPercent = SETTINGS.MIN_LIQUIDITY_PERCENT;
        SETTINGS.MIN_LIQUIDITY_PERCENT = _minLiquidityPercent;
        emit UpdateMinLiquidityPercent(previousMinLiquidityPercent, SETTINGS.MIN_LIQUIDITY_PERCENT);
    }    

    function setBurnAddress(address _burnAddress) external onlyAdmin {
        address previousBurnAddress = SETTINGS.BURN_ADDRESS;
        SETTINGS.BURN_ADDRESS = _burnAddress;
        emit UpdateBurnAddress(previousBurnAddress, SETTINGS.BURN_ADDRESS);
    }   
}

