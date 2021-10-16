/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Warcrypt is IERC20 {

    using SafeMath for uint256;

    uint256 private _multiply = 1_000_000_000_000_000_000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 200_000_000 * _multiply;

    string public constant name = "Warcrypt";
    string public constant symbol = "WRCP";
    uint8 public constant decimals = 18;
    address payable public _admin;

    // Presale Details
    address public _presale1Contract; //Presale1 contract address
    address public _presale2Contract; //Presale2 contract address
    uint256 public _presale1AmountCap = 30_000_000 * _multiply; //Presale1 Amount Cap
    uint256 public _presale2AmountCap = 60_000_000 * _multiply; //Presale2 Amount Cap
    bool public _isPresale1NotYetSet = true; //Is Presale1 not yet set?
    bool public _isPresale2NotYetSet = true; //Is Presale2 not yet set?

    bool public _isPaused;
    mapping(address => bool) public _isPausedAddress;

    // Warcrypt Date Allocation
    uint256 public constant _01_01_2022 = 1640995200; //January 1,2022
    uint256 public constant _02_01_2022 = 1643673600; //February 1, 2022

    uint256 public constant _10_18_2021 = 1634515200; //October 18, 2021
    uint256 public constant _10_25_2021 = 1635120000; //October 25, 2021

    uint256 public constant _11_01_2021 = 1635724800; //November 01, 2021
    uint256 public constant _11_08_2021 = 1636329600; //November 08, 2021
    uint256 public constant _11_15_2021 = 1636934400; //November 15, 2021
    uint256 public constant _11_22_2021 = 1637539200; //November 22, 2021
    uint256 public constant _11_29_2021 = 1638144000; //November 29, 2021

    uint256 public constant _12_06_2021 = 1638748800; //December 06, 2021
    uint256 public constant _12_13_2021 = 1639353600; //December 13, 2021
    uint256 public constant _12_20_2021 = 1639958400; //December 20, 2021
    uint256 public constant _12_27_2021 = 1640563200; //December 27, 2021

    uint256 public constant _01_03_2022 = 1641168000; //January 03, 2022
    uint256 public constant _01_10_2022 = 1641772800; //January 10, 2022
    uint256 public constant _01_17_2022 = 1642377600; //January 17, 2022
    uint256 public constant _01_24_2022 = 1642982400; //January 24, 2022
    uint256 public constant _01_31_2022 = 1643587200; //January 31, 2022

    uint256 public constant _02_07_2022 = 1644192000; //February 07, 2022
    uint256 public constant _02_14_2022 = 1644796800; //February 14, 2022
    uint256 public constant _02_21_2022 = 1645401600; //February 21, 2022
    uint256 public constant _02_28_2022 = 1646006400; //February 28, 2022

    uint256 public constant _03_07_2022 = 1646611200; //March 07, 2022
    uint256 public constant _03_14_2022 = 1647216000; //March 14, 2022
    uint256 public constant _03_21_2022 = 1647820800; //March 21, 2022
    uint256 public constant _03_28_2022 = 1648425600; //March 28, 2022

    uint256 public constant _04_04_2022 = 1649030400; //April 04, 2022
    uint256 public constant _04_11_2022 = 1649635200; //April 11, 2022
    uint256 public constant _04_18_2022 = 1650240000; //April 18, 2022
    uint256 public constant _04_25_2022 = 1650844800; //April 25, 2022

    uint256 public constant _05_02_2022 = 1651449600; //May 02, 2022
    uint256 public constant _05_09_2022 = 1652054400; //May 09, 2022
    uint256 public constant _05_16_2022 = 1652659200; //May 16, 2022
    uint256 public constant _05_23_2022 = 1653264000; //May 23, 2022
    uint256 public constant _05_30_2022 = 1653868800; //May 30, 2022

    uint256 public constant _06_06_2022 = 1654473600; //June 06, 2022
    uint256 public constant _06_13_2022 = 1655078400; //June 13, 2022
    uint256 public constant _06_20_2022 = 1655683200; //June 20, 2022
    uint256 public constant _06_27_2022 = 1656288000; //June 27, 2022

    uint256 public constant _07_04_2022 = 1656892800; //July 04, 2022
    uint256 public constant _07_11_2022 = 1657497600; //July 11, 2022
    uint256 public constant _07_18_2022 = 1658102400; //July 18, 2022
    uint256 public constant _07_25_2022 = 1658707200; //July 25, 2022

    uint256 public constant _08_01_2022 = 1659312000; //August 01, 2022
    uint256 public constant _08_08_2022 = 1659916800; //August 08, 2022
    uint256 public constant _08_15_2022 = 1660521600; //August 15, 2022
    uint256 public constant _08_22_2022 = 1661126400; //August 22, 2022
    uint256 public constant _08_29_2022 = 1661731200; //August 29, 2022

    uint256 public constant _09_05_2022 = 1662336000; //September 05, 2022
    uint256 public constant _09_12_2022 = 1662940800; //September 12, 2022
    uint256 public constant _09_19_2022 = 1663545600; //September 19, 2022
    uint256 public constant _09_26_2022 = 1664150400; //September 26, 2022

    uint256 public constant _10_03_2022 = 1664755200; //October 03, 2022
    uint256 public constant _10_10_2022 = 1665360000; //October 10, 2022
    uint256 public constant _10_17_2022 = 1665964800; //October 17, 2022
    uint256 public constant _10_24_2022 = 1666569600; //October 24, 2022
    uint256 public constant _10_31_2022 = 1667174400; //October 31, 2022

    uint256 public constant _11_07_2022 = 1667779200; //November 7, 2022
    uint256 public constant _11_14_2022 = 1668384000; //November 14, 2022

    string[] public _categories; // Addresses
    uint256[] public _dates; // Dates Warcrypt token allocation
    mapping(string => uint256) public _categoriesAmountCap; // Mapping for allowing Warcrypt token to be transfer
    mapping(string => address) public _categoriesAddress; // Mapping for addresses
    mapping(string => mapping(uint256 => uint256)) public _tokenAllocation; // Warcrypt token allocation schedule
    mapping(string => mapping(uint256 => mapping(uint256 => bool)))
        public _tokenAllocationStatus; // Warcrypt token allocation schedule status, True = has allocated

    event OutOfMoney(string category); // emit when _categoriesAmountCap less than required amount.

    //Warcrypt token category addresses
    address private constant _MarketingAndCommunity = 0xb7a4458F64F3C08B24f637e056c1c70Cf916A6C2;
    address private constant _DevsAndAdvisor = 0x8DA1810990bB4E5c0f8aB502F4f79fC9Fcb9d755;
    address private constant _Staking = 0xC7e23FE59374b759c009EaeDB9823968091317EF;
    address private constant _GameRewards = 0x4b295d6b17D75789E4C7843f03d1A347ca024675;
    address private constant _PrivateSale = 0xe6d8B5161c233bd008C38E34cdA20B6ec44b60b8;
    address private constant _IDO = 0xE7ebd3Ee95C602FE6F4A269b9E098b06E236b40D;
    address private constant _Liquidity = 0x1d31D9F8b0491c14070f6c3b3dB6ea0DD62DB49d;
    address private constant _BLaunchPad = 0xf741b321c3b3f03814E00F3f5Ecd6298D4d6eEA2;

                         
    constructor()  {
        _admin = msg.sender;
        _balances[address(this)] = _totalSupply;

        _categoriesAddress["MarketingAndCommunity"] = _MarketingAndCommunity;
        _categoriesAddress["DevsAndAdvisor"] = _DevsAndAdvisor;
        _categoriesAddress["Staking"] = _Staking;
        _categoriesAddress["GameRewards"] = _GameRewards;
        _categoriesAddress["PrivateSale"] = _PrivateSale;
        _categoriesAddress["IDO"] = _IDO;
        _categoriesAddress["Liquidity"] = _Liquidity;
        _categoriesAddress["BLaunchPad"] = _BLaunchPad;

        _setDefaultValues();
        _setTokenAllocation();
        _initialTransfer(); // Send token to marketingAndCommunity, privateSale, IDO, liquidity, bLaunchpad
    }

    function _setDefaultValues() private {
        // Add all categories
        _categories.push("MarketingAndCommunity");
        _categories.push("DevsAndAdvisor");
        _categories.push("Staking");
        _categories.push("GameRewards");
        _categories.push("PrivateSale");
        _categories.push("IDO");
        _categories.push("Liquidity");
        _categories.push("BLaunchPad");

        // Add all dates
        _dates.push(_01_01_2022);
        _dates.push(_02_01_2022);

        _dates.push(_10_18_2021);
        _dates.push(_10_25_2021);

        _dates.push(_11_01_2021);
        _dates.push(_11_08_2021);
        _dates.push(_11_15_2021);
        _dates.push(_11_22_2021);
        _dates.push(_11_29_2021);

        _dates.push(_12_06_2021);
        _dates.push(_12_13_2021);
        _dates.push(_12_20_2021);
        _dates.push(_12_27_2021);

        _dates.push(_01_03_2022);
        _dates.push(_01_10_2022);
        _dates.push(_01_17_2022);
        _dates.push(_01_24_2022);
        _dates.push(_01_31_2022);

        _dates.push(_02_07_2022);
        _dates.push(_02_14_2022);
        _dates.push(_02_21_2022);
        _dates.push(_02_28_2022);

        _dates.push(_03_07_2022);
        _dates.push(_03_14_2022);
        _dates.push(_03_21_2022);
        _dates.push(_03_28_2022);

        _dates.push(_04_04_2022);
        _dates.push(_04_11_2022);
        _dates.push(_04_18_2022);
        _dates.push(_04_25_2022);

        _dates.push(_05_02_2022);
        _dates.push(_05_09_2022);
        _dates.push(_05_16_2022);
        _dates.push(_05_23_2022);
        _dates.push(_05_30_2022);

        _dates.push(_06_06_2022);
        _dates.push(_06_13_2022);
        _dates.push(_06_20_2022);
        _dates.push(_06_27_2022);

        _dates.push(_07_04_2022);
        _dates.push(_07_11_2022);
        _dates.push(_07_18_2022);
        _dates.push(_07_25_2022);

        _dates.push(_08_01_2022);
        _dates.push(_08_08_2022);
        _dates.push(_08_15_2022);
        _dates.push(_08_22_2022);
        _dates.push(_08_29_2022);

        _dates.push(_09_05_2022);
        _dates.push(_09_12_2022);
        _dates.push(_09_19_2022);
        _dates.push(_09_26_2022);

        _dates.push(_10_03_2022);
        _dates.push(_10_10_2022);
        _dates.push(_10_17_2022);
        _dates.push(_10_24_2022);
        _dates.push(_10_31_2022);

        _dates.push(_11_07_2022);
        _dates.push(_11_14_2022);


        // Add categories amount cap
        _categoriesAmountCap["MarketingAndCommunity"] = 10_000_000 * _multiply;
        _categoriesAmountCap["DevsAndAdvisor"] = 16_000_000 * _multiply;
        _categoriesAmountCap["Staking"] = 16_000_000 * _multiply;
        _categoriesAmountCap["GameRewards"] = 40_000_000 * _multiply;
        _categoriesAmountCap["PrivateSale"] = 10_000_000 * _multiply;
        _categoriesAmountCap["IDO"] = 4_000_000 * _multiply;
        _categoriesAmountCap["Liquidity"] = 4_000_000 * _multiply;
        _categoriesAmountCap["BLaunchPad"] = 10_000_000 * _multiply;
    }

    // Set token allocation info
    function _setTokenAllocation() private {
        _tokenAllocation["Staking"][_01_01_2022] = 16_000_000 * _multiply;
        _tokenAllocation["IDO"][_01_01_2022] = 40_000_000 * _multiply;
        _tokenAllocation["GameRewards"][_02_01_2022] = 40_000_000 * _multiply;

        _tokenAllocation["DevsAndAdvisor"][_10_18_2021] = 280_701 * _multiply; // Week 1
        _tokenAllocation["DevsAndAdvisor"][_10_25_2021] = 280_701 * _multiply; // Week 2
        _tokenAllocation["DevsAndAdvisor"][_11_01_2021] = 280_701 * _multiply; // Week 3
        _tokenAllocation["DevsAndAdvisor"][_11_08_2021] = 280_701 * _multiply; // Week 4
        _tokenAllocation["DevsAndAdvisor"][_11_15_2021] = 280_701 * _multiply; // Week 5
        _tokenAllocation["DevsAndAdvisor"][_11_22_2021] = 280_701 * _multiply; // Week 6
        _tokenAllocation["DevsAndAdvisor"][_11_29_2021] = 280_701 * _multiply; // Week 7
        _tokenAllocation["DevsAndAdvisor"][_12_06_2021] = 280_701 * _multiply; // Week 8
        _tokenAllocation["DevsAndAdvisor"][_12_13_2021] = 280_701 * _multiply; // Week 9
        _tokenAllocation["DevsAndAdvisor"][_12_20_2021] = 280_701 * _multiply; // Week 10
        _tokenAllocation["DevsAndAdvisor"][_12_27_2021] = 280_701 * _multiply; // Week 11
        _tokenAllocation["DevsAndAdvisor"][_01_03_2022] = 280_701 * _multiply; // Week 12
        _tokenAllocation["DevsAndAdvisor"][_01_10_2022] = 280_701 * _multiply; // Week 13
        _tokenAllocation["DevsAndAdvisor"][_01_17_2022] = 280_701 * _multiply; // Week 14
        _tokenAllocation["DevsAndAdvisor"][_01_24_2022] = 280_701 * _multiply; // Week 15
        _tokenAllocation["DevsAndAdvisor"][_01_31_2022] = 280_701 * _multiply; // Week 16
        _tokenAllocation["DevsAndAdvisor"][_02_07_2022] = 280_701 * _multiply; // Week 17
        _tokenAllocation["DevsAndAdvisor"][_02_14_2022] = 280_701 * _multiply; // Week 18
        _tokenAllocation["DevsAndAdvisor"][_02_21_2022] = 280_701 * _multiply; // Week 19
        _tokenAllocation["DevsAndAdvisor"][_02_28_2022] = 280_701 * _multiply; // Week 20
        _tokenAllocation["DevsAndAdvisor"][_03_07_2022] = 280_701 * _multiply; // Week 21
        _tokenAllocation["DevsAndAdvisor"][_03_14_2022] = 280_701 * _multiply; // Week 22
        _tokenAllocation["DevsAndAdvisor"][_03_21_2022] = 280_701 * _multiply; // Week 23
        _tokenAllocation["DevsAndAdvisor"][_03_28_2022] = 280_701 * _multiply; // Week 24
        _tokenAllocation["DevsAndAdvisor"][_04_04_2022] = 280_701 * _multiply; // Week 25
        _tokenAllocation["DevsAndAdvisor"][_04_11_2022] = 280_701 * _multiply; // Week 26
        _tokenAllocation["DevsAndAdvisor"][_04_18_2022] = 280_701 * _multiply; // Week 27
        _tokenAllocation["DevsAndAdvisor"][_04_25_2022] = 280_701 * _multiply; // Week 28
        _tokenAllocation["DevsAndAdvisor"][_05_02_2022] = 280_701 * _multiply; // Week 29
        _tokenAllocation["DevsAndAdvisor"][_05_09_2022] = 280_701 * _multiply; // Week 30
        _tokenAllocation["DevsAndAdvisor"][_05_16_2022] = 280_701 * _multiply; // Week 31
        _tokenAllocation["DevsAndAdvisor"][_05_23_2022] = 280_701 * _multiply; // Week 32
        _tokenAllocation["DevsAndAdvisor"][_05_30_2022] = 280_701 * _multiply; // Week 33
        _tokenAllocation["DevsAndAdvisor"][_06_06_2022] = 280_701 * _multiply; // Week 34
        _tokenAllocation["DevsAndAdvisor"][_06_13_2022] = 280_701 * _multiply; // Week 35
        _tokenAllocation["DevsAndAdvisor"][_06_20_2022] = 280_701 * _multiply; // Week 36
        _tokenAllocation["DevsAndAdvisor"][_06_27_2022] = 280_701 * _multiply; // Week 37
        _tokenAllocation["DevsAndAdvisor"][_07_04_2022] = 280_701 * _multiply; // Week 38
        _tokenAllocation["DevsAndAdvisor"][_07_11_2022] = 280_701 * _multiply; // Week 39
        _tokenAllocation["DevsAndAdvisor"][_07_18_2022] = 280_701 * _multiply; // Week 40
        _tokenAllocation["DevsAndAdvisor"][_07_25_2022] = 280_701 * _multiply; // Week 41
        _tokenAllocation["DevsAndAdvisor"][_08_01_2022] = 280_701 * _multiply; // Week 42
        _tokenAllocation["DevsAndAdvisor"][_08_08_2022] = 280_701 * _multiply; // Week 43
        _tokenAllocation["DevsAndAdvisor"][_08_15_2022] = 280_701 * _multiply; // Week 44
        _tokenAllocation["DevsAndAdvisor"][_08_22_2022] = 280_701 * _multiply; // Week 45
        _tokenAllocation["DevsAndAdvisor"][_08_29_2022] = 280_701 * _multiply; // Week 46
        _tokenAllocation["DevsAndAdvisor"][_09_05_2022] = 280_701 * _multiply; // Week 47
        _tokenAllocation["DevsAndAdvisor"][_09_12_2022] = 280_701 * _multiply; // Week 48
        _tokenAllocation["DevsAndAdvisor"][_09_19_2022] = 280_701 * _multiply; // Week 49
        _tokenAllocation["DevsAndAdvisor"][_09_26_2022] = 280_701 * _multiply; // Week 50
        _tokenAllocation["DevsAndAdvisor"][_10_03_2022] = 280_701 * _multiply; // Week 51
        _tokenAllocation["DevsAndAdvisor"][_10_10_2022] = 280_701 * _multiply; // Week 52
        _tokenAllocation["DevsAndAdvisor"][_10_17_2022] = 280_701 * _multiply; // Week 53
        _tokenAllocation["DevsAndAdvisor"][_10_24_2022] = 280_701 * _multiply; // Week 54
        _tokenAllocation["DevsAndAdvisor"][_10_31_2022] = 280_701 * _multiply; // Week 55
        _tokenAllocation["DevsAndAdvisor"][_11_07_2022] = 280_701 * _multiply; // Week 56
        _tokenAllocation["DevsAndAdvisor"][_11_14_2022] = 280_701 * _multiply; // Week 57  

        _tokenAllocation["MarketingAndCommunity"][_10_18_2021] = 300_000 * _multiply; // Week 1
        _tokenAllocation["MarketingAndCommunity"][_10_25_2021] = 300_000 * _multiply; // Week 2
        _tokenAllocation["MarketingAndCommunity"][_11_01_2021] = 300_000 * _multiply; // Week 3
        _tokenAllocation["MarketingAndCommunity"][_11_08_2021] = 300_000 * _multiply; // Week 4
        _tokenAllocation["MarketingAndCommunity"][_11_15_2021] = 300_000 * _multiply; // Week 5
        _tokenAllocation["MarketingAndCommunity"][_11_22_2021] = 300_000 * _multiply; // Week 6
        _tokenAllocation["MarketingAndCommunity"][_11_29_2021] = 300_000 * _multiply; // Week 7
        _tokenAllocation["MarketingAndCommunity"][_12_06_2021] = 300_000 * _multiply; // Week 8
        _tokenAllocation["MarketingAndCommunity"][_12_13_2021] = 300_000 * _multiply; // Week 9
        _tokenAllocation["MarketingAndCommunity"][_12_20_2021] = 300_000 * _multiply; // Week 10
        _tokenAllocation["MarketingAndCommunity"][_12_27_2021] = 300_000 * _multiply; // Week 11
        _tokenAllocation["MarketingAndCommunity"][_01_03_2022] = 300_000 * _multiply; // Week 12
        _tokenAllocation["MarketingAndCommunity"][_01_10_2022] = 300_000 * _multiply; // Week 13
        _tokenAllocation["MarketingAndCommunity"][_01_17_2022] = 300_000 * _multiply; // Week 14
        _tokenAllocation["MarketingAndCommunity"][_01_24_2022] = 300_000 * _multiply; // Week 15
        _tokenAllocation["MarketingAndCommunity"][_01_31_2022] = 300_000 * _multiply; // Week 16
        _tokenAllocation["MarketingAndCommunity"][_02_07_2022] = 300_000 * _multiply; // Week 17
        _tokenAllocation["MarketingAndCommunity"][_02_14_2022] = 300_000 * _multiply; // Week 18
        _tokenAllocation["MarketingAndCommunity"][_02_21_2022] = 300_000 * _multiply; // Week 19
        _tokenAllocation["MarketingAndCommunity"][_02_28_2022] = 300_000 * _multiply; // Week 20
        _tokenAllocation["MarketingAndCommunity"][_03_07_2022] = 300_000 * _multiply; // Week 21
        _tokenAllocation["MarketingAndCommunity"][_03_14_2022] = 300_000 * _multiply; // Week 22
        _tokenAllocation["MarketingAndCommunity"][_03_21_2022] = 300_000 * _multiply; // Week 23
        _tokenAllocation["MarketingAndCommunity"][_03_28_2022] = 300_000 * _multiply; // Week 24
        _tokenAllocation["MarketingAndCommunity"][_04_04_2022] = 300_000 * _multiply; // Week 25
        _tokenAllocation["MarketingAndCommunity"][_04_11_2022] = 300_000 * _multiply; // Week 26
        _tokenAllocation["MarketingAndCommunity"][_04_18_2022] = 300_000 * _multiply; // Week 27
        _tokenAllocation["MarketingAndCommunity"][_04_25_2022] = 300_000 * _multiply; // Week 28
        _tokenAllocation["MarketingAndCommunity"][_05_02_2022] = 300_000 * _multiply; // Week 29
        _tokenAllocation["MarketingAndCommunity"][_05_09_2022] = 300_000 * _multiply; // Week 30      
    }

    // Transfer Warcrypt token when smart contract is deployed
    function _initialTransfer() private {

        // MarketingAndCommunity
        _transfer(address(this),_categoriesAddress["MarketingAndCommunity"], 1_000_000 * _multiply);      

        // PrivateSale
        _transfer(address(this),_categoriesAddress["PrivateSale"], 10_000_000 * _multiply);

        // IDO
        _transfer(address(this),_categoriesAddress["IDO"], 4_000_000 * _multiply);

        // Liquidity
        _transfer(address(this),_categoriesAddress["Liquidity"], 4_000_000 * _multiply);

        // BLaunchPad
        _transfer(address(this),_categoriesAddress["BLaunchPad"], 10_000_000 * _multiply
        );
    }

    /**
     * Modifiers
     */
    modifier onlyAdmin() {
        // Is Admin?
        require(_admin == msg.sender);
        _;
    }

    modifier isPresale1NotYetSet() {
        // is presale1 set?
        require(_isPresale1NotYetSet);
        _;
    }

    modifier isPresale2NotYetSet() {
        // is presale2 set?
        require(_isPresale2NotYetSet);
        _;
    }

    modifier isPresale1Contract() {
        // Is presale1 the contract that is currently interact with this contract?
        require(msg.sender == _presale1Contract);
        _;
    }

    modifier isPresale2Contract() {
        // Is presale2 the contract that is currently interact with this contract?
        require(msg.sender == _presale2Contract);
        _;
    }

    modifier whenPaused() {
        // Is pause?
        require(_isPaused, "Pausable: not paused Erc20");
        _;
    }

    modifier whenNotPaused() {
        // Is not pause?
        require(!_isPaused, "Pausable: paused Erc20");
        _;
    }

    // Transfer ownernship
    function transferOwnership(address payable admin) external onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }

    /**
     * Update presale contracts
     */
    function setPresale1NotYetSet(address presale1Contract)
        external
        onlyAdmin
        isPresale1NotYetSet
    {
        require(presale1Contract != address(0), "Zero address");
        _presale1Contract = presale1Contract;
        _isPresale1NotYetSet = false;
    }

    function setPresale2NotYetSet(address presale2Contract)
        external
        onlyAdmin
        isPresale2NotYetSet
    {
        require(presale2Contract != address(0), "Zero address");
        _presale2Contract = presale2Contract;
        _isPresale2NotYetSet = false;
    }

    /**
     * ERC20 functions
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    /**
     * @dev Automically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Automically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(!_isPaused, "ERC20Pausable: token transfer while paused");
        require(
            !_isPausedAddress[sender],
            "ERC20Pausable: token transfer while paused on address"
        );
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            recipient != address(this),
            "ERC20: transfer to the token contract address"
        );

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * External contract transfer functions
     */
    // Allow presale1 external contract to trigger transfer function
    function transferPresale1(address recipient, uint256 amount)
        external
        isPresale1Contract
        returns (bool)
    {
        require(
            _presale1AmountCap.sub(amount) >= 0,
            "No more amount allocates for preSale1"
        );
        _presale1AmountCap = _presale1AmountCap.sub(amount);
        _transfer(address(this), recipient, amount);
        return true;
    }

    // Allow presale2 external contract to trigger transfer function
    function transferPresale2(address recipient, uint256 amount)
        external
        isPresale2Contract
        returns (bool)
    {
        require(
            _presale2AmountCap.sub(amount) >= 0,
            "No more amount allocates for preSale2"
        );
        _presale2AmountCap = _presale2AmountCap.sub(amount);
        _transfer(address(this), recipient, amount);
        return true;
    }

    // Transfer Warcrypt token to categories
    function transferLocalCategories() external {
        for (uint256 i = 0; i < _categories.length; i++) {
            address categoryAddress = _categoriesAddress[_categories[i]];

            for (uint256 y = 0; y < _dates.length; y++) {
                uint256 amount = _tokenAllocation[_categories[i]][_dates[y]];

                if (block.timestamp >= _dates[y]) {
                    bool hasDistributed = _tokenAllocationStatus[
                        _categories[i]
                    ][_dates[y]][amount];

                    if (!hasDistributed) {
                        bool canTransfer = _categoriesTransfer(
                            categoryAddress,
                            amount,
                            _categories[i]
                        );

                        if (canTransfer) {
                            _tokenAllocationStatus[_categories[i]][_dates[y]][
                                amount
                            ] = true;
                        }
                    }
                }
            }
        }
    }

    function _categoriesTransfer(
        address recipient,
        uint256 amount,
        string memory categories
    ) private returns (bool) {
        if (_categoriesAmountCap[categories] < amount) {
            emit OutOfMoney(categories);
            return false;
        }
        _categoriesAmountCap[categories] = _categoriesAmountCap[categories].sub(
            amount
        );
        _transfer(address(this), recipient, amount);
        return true;
    }

    function pause() external onlyAdmin whenNotPaused {
        _isPaused = true;
    }

    function unpause() external onlyAdmin whenPaused {
        _isPaused = false;
    }

    function pausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = true;
    }

    function unPausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = false;
    }

    receive() external payable {
        revert();
    }
}