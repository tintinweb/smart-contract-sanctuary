// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./utils/SafeMath.sol";
import "./interfaces/BEP20.sol";

/**
@title Initial token contract
@author Ronald Leon, Luis Sanchez and Luis Costa
@dev Main functions of interaction with the token
@notice Main functions of interaction with the token
*/ 
contract BgoToken is IBEP20 {
    using SafeMath for uint;

    // BEP20 variables
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;

    // General variables
    string public constant NAME = "Bipgo Token";
    string public constant SYMBOL = "BGO";
    uint8 public constant DECIMALS = 18;
    address payable public _admin;

    // External contract general variables
    uint internal _privatePreSaleAmountCap;
    uint internal _publicPreSaleAmountCap;
    address public _privatePreSaleContract;
    address public _publicPreSaleContract;
    bool public _hasPrivatePreSaleContractNotYetSet;
    bool public _hasPublicPreSaleContractNotYetSet;

    // Utility variables
    bool public _isPaused;
    mapping(address => bool) public _isPausedAddress;

    // Date variables
    uint public constant _JAN_15_2022 = 1642204800; // TGE
    uint public constant _FEB_15_2022 = 1644883200; // Month 1
    uint public constant _MAR_15_2022 = 1647302400; // Month 2
    uint public constant _APR_15_2022 = 1649980800; // Month 3
    uint public constant _MAY_15_2022 = 1652572800; // Month 4
    uint public constant _JUN_15_2022 = 1655251200; // Month 5
    uint public constant _JUL_15_2022 = 1657843200; // Month 6
    uint public constant _AUG_15_2022 = 1660521600; // Month 7
    uint public constant _SEP_15_2022 = 1663200000; // Month 8
    uint public constant _OCT_15_2022 = 1665792000; // Month 9
    uint public constant _NOV_15_2022 = 1668470400; // Month 10
    uint public constant _DEC_15_2022 = 1671062400; // Month 11
    uint public constant _JAN_15_2023 = 1673740800; // Month 12
    uint public constant _FEB_15_2023 = 1676419200; // Month 13
    uint public constant _MAR_15_2023 = 1678838400; // Month 14
    uint public constant _APR_15_2023 = 1681516800; // Month 15
    uint public constant _MAY_15_2023 = 1684108800; // Month 16
    uint public constant _JUN_15_2023 = 1686787200; // Month 17
    uint public constant _JUL_15_2023 = 1689379200; // Month 18
    uint public constant _AUG_15_2023 = 1692057600; // Month 19
    uint public constant _SEP_15_2023 = 1694736000; // Month 20
    uint public constant _OCT_15_2023 = 1697328000; // Month 21
    uint public constant _NOV_15_2023 = 1700006400; // Month 22
    uint public constant _DEC_15_2023 = 1702598400; // Month 23
    uint public constant _JAN_15_2024 = 1705276800; // Month 24
    uint public constant _FEB_15_2024 = 1707955200; // Month 25
    uint public constant _MAR_15_2024 = 1710460800; // Month 26
    uint public constant _APR_15_2024 = 1713139200; // Month 27
    uint public constant _MAY_15_2024 = 1715731200; // Month 28
    uint public constant _JUN_15_2024 = 1718409600; // Month 29
    uint public constant _JUL_15_2024 = 1721001600; // Month 30
    uint public constant _AUG_15_2024 = 1723680000; // Month 31
    uint public constant _SEP_15_2024 = 1726358400; // Month 32
    uint public constant _OCT_15_2024 = 1728950400; // Month 33
    uint public constant _NOV_15_2024 = 1731628800; // Month 34
    uint public constant _DEC_15_2024 = 1734220800; // Month 35
    uint public constant _JAN_15_2025 = 1736899200; // Month 36

    string[] public _categories; // string that represent address identities
    uint[] public _dates; // The cutoff dates that allow coin distribution
    mapping(string => uint) public _categoriesAmountCap; // The maximum amount allowed to be transfer (Category => Cap)
    mapping(string => address) public _categoriesAddress; // Address for categories (Category => Address)
    mapping(string => mapping(uint => uint)) public _coinDistribution; // Coin distribution schedule (Category => Unix Date => Amount)
    mapping(string => mapping(uint => mapping(uint => bool))) public _coinDistributionStatus;// Coin distribution schedule status, Yes = hasDistributed (Category => Unix Date => Amount => bool)

    event OutOfMoney(string category);  // emit when `_categoriesAmountCap` less than required amount.

    /** 
    @notice Function that initializes the token contract
    @dev token constructor
    */
    constructor() {
        // environment initialization
        _totalSupply = 400_000_000 * (10 ** 18);
        _privatePreSaleAmountCap = _totalSupply * 10 / 100;
        _publicPreSaleAmountCap = _totalSupply * 4 / 100;
        _hasPrivatePreSaleContractNotYetSet = true;
        _hasPublicPreSaleContractNotYetSet = true;
        //_admin = payable(0x22526C6df87feB860970164d2b11C4eF5e890072); //GNOSIS
        //_admin = payable(0x4726c4E5f21963d29361EAe579f69A1b4dadDfdE); // GNOSIS TEST
        _admin = payable(msg.sender); // Pruebas en BSC Test
        _balances[address(this)] = _totalSupply;
        
        // Add all addresses
        _categoriesAddress["Team"] = 0xdA0065A9B1E3F0F16fa9dB8Ef5B325629ACA0F74;
        _categoriesAddress["Advisors"] = 0x53fa536b3c1061960AdC21be31B7F749df8eDAd8;
        _categoriesAddress["Ecosystem"] = 0xfd2B40420A03E94109C04F960696a14d70b189a1;
        _categoriesAddress["ShareToEarn"] = 0x901F0C2c123AfD07eE6b0fAc03ec3aeAf5FCD880;
        _categoriesAddress["Liquidity"] = 0x93850a9d834682B337370F7cd93169492FA14497;

        _setDefaultValues();
        _setCoinDistribution();
    }

    /// @dev Defines the initial values of the contract
    function _setDefaultValues() private {
        // Add all categories
        _categories.push("Team");
        _categories.push("Advisors");
        _categories.push("Ecosystem");
        _categories.push("ShareToEarn");
        _categories.push("Liquidity");

        // Add all dates
        _dates.push(_JAN_15_2022);
        _dates.push(_FEB_15_2022);
        _dates.push(_MAR_15_2022);
        _dates.push(_APR_15_2022);
        _dates.push(_MAY_15_2022);
        _dates.push(_JUN_15_2022);
        _dates.push(_JUL_15_2022);
        _dates.push(_AUG_15_2022);
        _dates.push(_SEP_15_2022);
        _dates.push(_OCT_15_2022);
        _dates.push(_NOV_15_2022);
        _dates.push(_DEC_15_2022);
        _dates.push(_JAN_15_2023);
        _dates.push(_FEB_15_2023);
        _dates.push(_MAR_15_2023);
        _dates.push(_APR_15_2023);
        _dates.push(_MAY_15_2023);
        _dates.push(_JUN_15_2023);
        _dates.push(_JUL_15_2023);
        _dates.push(_AUG_15_2023);
        _dates.push(_SEP_15_2023);
        _dates.push(_OCT_15_2023);
        _dates.push(_NOV_15_2023);
        _dates.push(_DEC_15_2023);
        _dates.push(_JAN_15_2024);
        _dates.push(_FEB_15_2024);
        _dates.push(_MAR_15_2024);
        _dates.push(_APR_15_2024);
        _dates.push(_MAY_15_2024);
        _dates.push(_JUN_15_2024);
        _dates.push(_JUL_15_2024);
        _dates.push(_AUG_15_2024);
        _dates.push(_SEP_15_2024);
        _dates.push(_OCT_15_2024);
        _dates.push(_NOV_15_2024);
        _dates.push(_DEC_15_2024);
        _dates.push(_JAN_15_2025);

        // Add all amount cap
        _categoriesAmountCap['Liquidity'] = _totalSupply * 16 / 100; // 16%
        _categoriesAmountCap["Team"] = _totalSupply * 20 / 100; // 20%
        _categoriesAmountCap["Advisors"] = _totalSupply * 5 / 100; // 5%
        _categoriesAmountCap["Ecosystem"] = _totalSupply * 20 / 100; // 20%
        _categoriesAmountCap["ShareToEarn"] = _totalSupply * 25 / 100; // 25%
        
    }

    /// @dev Functions that define the token distribution
    function _setCoinDistribution() private {
        // Liquidity Distribution
        _coinDistribution["Liquidity"][_JAN_15_2022] =  _categoriesAmountCap['LiquiditY'] * 625 / 10000; // TGE 6.25%
        _coinDistribution["Liquidity"][_JAN_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 12
        _coinDistribution["Liquidity"][_FEB_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 13
        _coinDistribution["Liquidity"][_MAR_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 14
        _coinDistribution["Liquidity"][_APR_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 15
        _coinDistribution["Liquidity"][_MAY_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 16
        _coinDistribution["Liquidity"][_JUN_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 17
        _coinDistribution["Liquidity"][_JUL_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 18
        _coinDistribution["Liquidity"][_AUG_15_2023] =  _categoriesAmountCap['LiquiditY'] * 5 / 100; // 5% Month 19
        _coinDistribution["Liquidity"][_SEP_15_2023] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 20
        _coinDistribution["Liquidity"][_OCT_15_2023] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 21
        _coinDistribution["Liquidity"][_NOV_15_2023] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 22
        _coinDistribution["Liquidity"][_DEC_15_2023] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 23
        _coinDistribution["Liquidity"][_JAN_15_2024] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 24
        _coinDistribution["Liquidity"][_FEB_15_2024] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 25
        _coinDistribution["Liquidity"][_MAR_15_2024] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 26
        _coinDistribution["Liquidity"][_APR_15_2024] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 27
        _coinDistribution["Liquidity"][_MAY_15_2024] =  _categoriesAmountCap['LiquiditY'] * 375 / 10000; // 3.75% Month 28
        _coinDistribution["Liquidity"][_JUN_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 29
        _coinDistribution["Liquidity"][_JUL_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 30
        _coinDistribution["Liquidity"][_AUG_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 31
        _coinDistribution["Liquidity"][_SEP_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 32
        _coinDistribution["Liquidity"][_OCT_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 33
        _coinDistribution["Liquidity"][_NOV_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 34
        _coinDistribution["Liquidity"][_DEC_15_2024] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 35
        _coinDistribution["Liquidity"][_JAN_15_2025] =  _categoriesAmountCap['LiquiditY'] * 25 / 1000; // 2.5% Month 36
        // Team Distribution
        _coinDistribution["Team"][_JAN_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 12
        _coinDistribution["Team"][_FEB_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 13
        _coinDistribution["Team"][_MAR_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 14
        _coinDistribution["Team"][_APR_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 15
        _coinDistribution["Team"][_MAY_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 16
        _coinDistribution["Team"][_JUN_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 17
        _coinDistribution["Team"][_JUL_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 18
        _coinDistribution["Team"][_AUG_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 19
        _coinDistribution["Team"][_SEP_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 20
        _coinDistribution["Team"][_OCT_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 21
        _coinDistribution["Team"][_NOV_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 22
        _coinDistribution["Team"][_DEC_15_2023] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 23
        _coinDistribution["Team"][_JAN_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 24
        _coinDistribution["Team"][_FEB_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 25
        _coinDistribution["Team"][_MAR_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 26
        _coinDistribution["Team"][_APR_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 27
        _coinDistribution["Team"][_MAY_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 28
        _coinDistribution["Team"][_JUN_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 29
        _coinDistribution["Team"][_JUL_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 30
        _coinDistribution["Team"][_AUG_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 31
        _coinDistribution["Team"][_SEP_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 32
        _coinDistribution["Team"][_OCT_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 33
        _coinDistribution["Team"][_NOV_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 34
        _coinDistribution["Team"][_DEC_15_2024] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 35
        _coinDistribution["Team"][_JAN_15_2025] =  _categoriesAmountCap["Team"] * 4 / 100; // 4% Month 36
        // Advisor Distribution
        _coinDistribution["Advisors"][_JAN_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 12
        _coinDistribution["Advisors"][_FEB_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 13
        _coinDistribution["Advisors"][_MAR_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 14
        _coinDistribution["Advisors"][_APR_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 15
        _coinDistribution["Advisors"][_MAY_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 16
        _coinDistribution["Advisors"][_JUN_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 17
        _coinDistribution["Advisors"][_JUL_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 18
        _coinDistribution["Advisors"][_AUG_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 19
        _coinDistribution["Advisors"][_SEP_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 20
        _coinDistribution["Advisors"][_OCT_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 21
        _coinDistribution["Advisors"][_NOV_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 22
        _coinDistribution["Advisors"][_DEC_15_2023] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 23
        _coinDistribution["Advisors"][_JAN_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 24
        _coinDistribution["Advisors"][_FEB_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 25
        _coinDistribution["Advisors"][_MAR_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 26
        _coinDistribution["Advisors"][_APR_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 27
        _coinDistribution["Advisors"][_MAY_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 28
        _coinDistribution["Advisors"][_JUN_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 29
        _coinDistribution["Advisors"][_JUL_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 30
        _coinDistribution["Advisors"][_AUG_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 31
        _coinDistribution["Advisors"][_SEP_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 32
        _coinDistribution["Advisors"][_OCT_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 33
        _coinDistribution["Advisors"][_NOV_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 34
        _coinDistribution["Advisors"][_DEC_15_2024] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 35
        _coinDistribution["Advisors"][_JAN_15_2025] =  _categoriesAmountCap["Advisors"] * 4 / 100; // 4% Month 36
        // Ecosystem Distribution
        _coinDistribution["Ecosystem"][_JAN_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% TGE
        _coinDistribution["Ecosystem"][_FEB_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 1
        _coinDistribution["Ecosystem"][_MAR_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 2
        _coinDistribution["Ecosystem"][_APR_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 3
        _coinDistribution["Ecosystem"][_MAY_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 4
        _coinDistribution["Ecosystem"][_JUN_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 5
        _coinDistribution["Ecosystem"][_JUL_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 6
        _coinDistribution["Ecosystem"][_AUG_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 7
        _coinDistribution["Ecosystem"][_SEP_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 8
        _coinDistribution["Ecosystem"][_OCT_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 9
        _coinDistribution["Ecosystem"][_NOV_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 10
        _coinDistribution["Ecosystem"][_DEC_15_2022] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 11
        _coinDistribution["Ecosystem"][_JAN_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 12
        _coinDistribution["Ecosystem"][_FEB_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 13
        _coinDistribution["Ecosystem"][_MAR_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 14
        _coinDistribution["Ecosystem"][_APR_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 15
        _coinDistribution["Ecosystem"][_MAY_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 16
        _coinDistribution["Ecosystem"][_JUN_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 17
        _coinDistribution["Ecosystem"][_JUL_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 18
        _coinDistribution["Ecosystem"][_AUG_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 19
        _coinDistribution["Ecosystem"][_SEP_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 20
        _coinDistribution["Ecosystem"][_OCT_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 21
        _coinDistribution["Ecosystem"][_NOV_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 22
        _coinDistribution["Ecosystem"][_DEC_15_2023] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 23
        _coinDistribution["Ecosystem"][_JAN_15_2024] =  _categoriesAmountCap["Marketing"] * 4 / 100; // 4% Month 24
        // ShareToEarn Distribution
        _coinDistribution["ShareToEarn"][_FEB_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 5 / 100; // 5% Month 1
        _coinDistribution["ShareToEarn"][_MAR_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 5 / 100; // 5% Month 2
        _coinDistribution["ShareToEarn"][_APR_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 5 / 100; // 5% Month 3
        _coinDistribution["ShareToEarn"][_MAY_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 5 / 100; // 5% Month 4
        _coinDistribution["ShareToEarn"][_JUN_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 5 / 100; // 5% Month 5
        _coinDistribution["ShareToEarn"][_JUL_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 5 / 100; // 5% Month 6
        _coinDistribution["ShareToEarn"][_AUG_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 4% Month 7
        _coinDistribution["ShareToEarn"][_SEP_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 4% Month 8
        _coinDistribution["ShareToEarn"][_OCT_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 4% Month 9
        _coinDistribution["ShareToEarn"][_NOV_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 4% Month 10
        _coinDistribution["ShareToEarn"][_DEC_15_2022] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 4% Month 11
        _coinDistribution["ShareToEarn"][_JAN_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 4% Month 12
        _coinDistribution["ShareToEarn"][_FEB_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 4 / 100; // 3% Month 13
        _coinDistribution["ShareToEarn"][_MAR_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 3 / 100; // 3% Month 14
        _coinDistribution["ShareToEarn"][_APR_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 3 / 100; // 3% Month 15
        _coinDistribution["ShareToEarn"][_MAY_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 3 / 100; // 3% Month 16
        _coinDistribution["ShareToEarn"][_JUN_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 3 / 100; // 3% Month 17
        _coinDistribution["ShareToEarn"][_JUL_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 3 / 100; // 3% Month 18
        _coinDistribution["ShareToEarn"][_AUG_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 19
        _coinDistribution["ShareToEarn"][_SEP_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 20
        _coinDistribution["ShareToEarn"][_OCT_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 21
        _coinDistribution["ShareToEarn"][_NOV_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 22
        _coinDistribution["ShareToEarn"][_DEC_15_2023] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 23
        _coinDistribution["ShareToEarn"][_JAN_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 24
        _coinDistribution["ShareToEarn"][_FEB_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 25
        _coinDistribution["ShareToEarn"][_MAR_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 26
        _coinDistribution["ShareToEarn"][_APR_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 27
        _coinDistribution["ShareToEarn"][_MAY_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 28
        _coinDistribution["ShareToEarn"][_JUN_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 29
        _coinDistribution["ShareToEarn"][_JUL_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 30
        _coinDistribution["ShareToEarn"][_AUG_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 31
        _coinDistribution["ShareToEarn"][_SEP_15_2024] =  _categoriesAmountCap["ShareToEarn"] * 2 / 100; // 2% Month 32
    }

    /// @dev Allows the exclusive execution of the administrator
    modifier onlyAdmin() { // Is Admin?
        require(_admin == msg.sender, "Only administrator can perform this function");
        _;
    }
    
    /// @dev It allows to identify if the address of the private sale contract was established
    modifier hasPrivatePreSaleContractNotYetSet() { // Has Private PreSale Contract set?
        require(_hasPrivatePreSaleContractNotYetSet, "The private sale contract has already been set previously");
        _;
    }

    /// @dev It allows to identify if the address of the public sale contract was established
    modifier hasPublicPreSaleContractNotYetSet() { // Has Public PreSale Contract set?
        require(_hasPublicPreSaleContractNotYetSet, "The public sale contract has already been set previously");
        _;
    }

    /// @dev It allows to identify if it is the private sale contract
    modifier isPrivatePreSaleContract() { // Is preSale1 the contract that is currently interact with this contract?
        require(msg.sender == _privatePreSaleContract, "Only the private sale contract can perform this function");
        _;
    }

    /// @dev It allows to identify if it is the public sale contract
    modifier isPublicPreSaleContract() { // Is preSale2 the contract that is currently interact with this contract?
        require(msg.sender == _publicPreSaleContract, "Only the public sale contract can perform this function");
        _;
    }

    /// @dev It allows to identify if the initial contract is paused
    modifier whenPaused() { // Is pause?
        require(_isPaused, "The contract is on hold");
        _;
    }

    /// @dev It allows to identify if the initial contract is not paused
    modifier whenNotPaused() { // Is not pause? 
        require(!_isPaused, "The contract is not paused");
        _;
    }

    /** 
    @notice Allows the change of the contract administrator
    @dev Change the contract administrator
    @param admin Address of the new administrator, cannot be null
    */
    function transferOwnership(address payable admin) external onlyAdmin {
        require(admin != address(0), "The new owner cannot be a null address");
        _admin = admin;
    }

    /**
    @notice Defines the address of the private sale contract
    @dev Defines the address of the private sale contract
    @param privatePreSaleContract address of the private  sale contract
    */
    function setPrivatePreSaleContractNotYetSet(address privatePreSaleContract) external onlyAdmin hasPrivatePreSaleContractNotYetSet {
        require(privatePreSaleContract != address(0), "The Private Presale Contract cannot be a null address");
        _privatePreSaleContract = privatePreSaleContract;
        _hasPrivatePreSaleContractNotYetSet = false;
    }

    /**
    @notice Defines the address of the public sale contract
    @dev Defines the address of the public sale contract
    @param publicPreSaleContract address of the public  sale contract
    */
    function setPublicPreSaleContractNotYetSet(address publicPreSaleContract) external onlyAdmin hasPublicPreSaleContractNotYetSet {
        require(publicPreSaleContract != address(0), "The Public Presale Contract cannot be a null address");
        _publicPreSaleContract = publicPreSaleContract;
        _hasPublicPreSaleContractNotYetSet = false;
    }

    /**
    @notice It allows to obtain the total of token created
    @dev Returns the total token created
    @return Returns an integer, which represents the total token created
    */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /** 
    @notice It allows to obtain the balance of token that has an address
    @dev Returns the balance of one address
    @param account address to obtain the balance
    @return the balance of the address tokens
    */
    function balanceOf(address account) external override view returns (uint){
        return _balances[account];
    }

    /** 
    @notice Allows to transfer token to an address
    @dev Transfer token to an address
    @param recipient address to transfer
    @param amount integer, amount to transfer
    @return Boolean, true on success
    */
    function transfer(address recipient, uint amount) external virtual override returns (bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /** 
    @notice Grant usage permissions to an address
    @dev Grant usage permissions to an address
    @param owner Address of the owner of the address, cannot be null
    @param spender Address authorized to manipulate
    @return Integer
    */
    function allowance(address owner, address spender) external virtual override view returns (uint){
        return _allowances[owner][spender];
    }

    /** 
    @notice Alternative function to _transfer
    @dev Alternative function to _transfer
    @param spender Address of who receives
    @param amount Integer, amount to transfer
    @return Boolean, true on success
    */
    function approve(address spender, uint amount) external virtual override returns (bool){
        _approve(msg.sender, spender, amount);
        return true;
    }

    /** 
    @notice Allows you to transfer tokens between addresses
    @dev Transfer tokens between addresses
    @param sender Issuer address, cannot be null
    @param recipient Receiver address, cannot be null
    @param amount Integer, amount to transfer
    @return Boolean, true on success
    */
    function transferFrom(address sender, address recipient, uint amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
    @notice Increase the value in tokens to an address
    @dev Transfer tokens from the caller to the spender
    @param spender Address to whom it is going to increase, it cannot be null
    @param addedValue value to increase
    @return Boolean, true on success
    */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
    @notice Decrease the value in tokens to an address
    @dev Transfer tokens from the spender to whoever invokes the function
    @param spender Address to whom it is going to decrease, it cannot be null
    @param subtractedValue value to decrease
    @return Boolean, true on success
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /** 
    @notice Allows token transfer
    @dev Token transfer
    @param sender Address of the transferor
    @param recipient Address of who receives
    @param amount Integer, amount to transfer
    */
    function _transfer(address sender, address recipient, uint amount ) internal virtual {
        require(!_isPaused, "Token transfer while paused");
        require(!_isPausedAddress[sender], "Token transfer while paused on address");
        require(sender != address(0), "The sender cannot be a null address");
        require(recipient != address(0), "The recipient cannot be a null address");
        require(recipient != address(this), "The recipient cannot be this contract");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** 
    @notice Alternative function to _transfer
    @dev Alternative function to _transfer
    @param owner Address of the transferor
    @param spender Address of who receives
    @param amount Integer, amount to transfer
    */
    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "The owner cannot be a null address");
        require(spender != address(0), "Authorized cannot be a null address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /** 
    @notice It allows to transfer the tokens of the private sale to the buyers
    @dev Transfer the private sale tokens to buyers
    @param recipient Buyer address
    @param amount Integer, amount to transfer
    @return Boolean, true on success
    */
    function transferPrivatePresale(address recipient, uint amount) external isPrivatePreSaleContract returns (bool) {
        require(_privatePreSaleAmountCap.sub(amount) >= 0, "The quantity is greater than available");
        _privatePreSaleAmountCap = _privatePreSaleAmountCap.sub(amount);
        _transfer(address(this), recipient, amount);
        return true;
    }

    /** 
    @notice It allows to transfer the tokens of the public sale to the buyers
    @dev Transfer the public sale tokens to buyers
    @param recipient Buyer address
    @param amount Integer, amount to transfer
    @return Boolean, true on success
    */
    function transferPublicPresale(address recipient, uint amount) external isPublicPreSaleContract returns (bool) {
        require(_publicPreSaleAmountCap.sub(amount) >= 0,  "The quantity is greater than available");
        _publicPreSaleAmountCap = _publicPreSaleAmountCap.sub(amount);
        _transfer(address(this), recipient, amount);
        return true;
    }

    /** 
    @notice It allows to distribute the tokens to the categories according to established dates
    @dev Distribute the tokens to the categories according to established dates
    */
    function transferLocalCategories() external {
        for (uint i = 0; i < _categories.length; i++) {
            address categoryAddress = _categoriesAddress[_categories[i]];
            for (uint y = 0; y < _dates.length; y++) {
                uint amount = _coinDistribution[_categories[i]][_dates[y]];
                if(block.timestamp >= _dates[y]) {
                    bool hasDistributed = _coinDistributionStatus[_categories[i]][_dates[y]][amount];
                    if(!hasDistributed){
                        bool canTransfer = _categoriesTransfer(categoryAddress, amount, _categories[i]);
                        if(canTransfer)
                            _coinDistributionStatus[_categories[i]][_dates[y]][amount] = true;
                    }
                }
            }
        }
    }

    /** 
    @notice It allows to transfer tokens of the contract to the addresses of the categories
    @dev transfers contract tokens to category addresses
    @param recipient Address of the category to transfer
    @param amount Integer, amount of tokens to transfer
    @param categories String, name of the category to transfer
    */
    function _categoriesTransfer(address recipient, uint amount, string memory categories) private returns (bool){
        if (_categoriesAmountCap[categories] < amount) {
            emit OutOfMoney(categories);
            return false;
        }
        _categoriesAmountCap[categories] = _categoriesAmountCap[categories].sub(amount);
        _transfer(address(this), recipient, amount);
        return true;
    }

    /** 
    @notice Lets deactivate the contract
    @dev Deactivate the contract
    */
    function pause() external onlyAdmin whenNotPaused {
        _isPaused = true;
    }

    /** 
    @notice Allows you to reactivate the contract
    @dev Reactivate the contract
    */
    function unpause() external onlyAdmin whenPaused {
        _isPaused = false;
    }

    /** 
    @notice Allows deactivating an address
    @dev Deactivate an address
    @param sender address to deactivate
    */
    function pausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = true;
    }

    /** 
    @notice Activate an address
    @dev Activate an address
    @param sender address to activate
    */
    function unPausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = false;
    }

    /** 
    @notice Receiving token is prohibited in this contract
    @dev Token rejection
    */
    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}