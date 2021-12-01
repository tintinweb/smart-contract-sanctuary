/**
 *Submitted for verification at BscScan.com on 2021-12-01
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

interface IERC202 {
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

contract WRCP2 is IERC20 {

    using SafeMath for uint256;
    address public _oldTokenContractAddress=0xA4dF2c2f42b30F8B3129F6d8663B005286406a29; 
    IERC202 public tokenContract;
    uint256 private constant _multiply = 1_000_000_000_000_000_000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private  _totalSupply = 125_575_000 * _multiply;

    string public constant name = "Warcrypt";
    string public constant symbol = "WRCP2";

    uint8 public constant decimals = 18;
    address payable public _admin;

    // Presale Details
    address public _presale1Contract; //Presale1 contract address
    address public _presale2Contract; //Presale2 contract address
    uint256 public _presale1AmountCap = 2_575_000 * _multiply; //Presale1 Amount Cap
    bool public _isPresale1NotYetSet = true; //Is Presale1 not yet set?
    uint256 public presaleRate = uint256(3); // 3 % additional @ presale purchase

    // Swapping Details
    uint256 public _swapTokenAmountCap = 15_000_000 * _multiply; //Swap Token from Old Contract to New
    uint256 public swapRate = uint256(3); // 3 % additional reward when swapping 
    address public deadAddress; //Burn token address

    bool public _isPaused;
    mapping(address => bool) public _isPausedAddress;

    // Warcrypt Date Allocation

    uint256 public constant _11_08_2021 = 1636329600; //November 08, 2021
    uint256 public constant _12_06_2021 = 1638748800; //December 06, 2021

    uint256 public constant _01_03_2022 = 1641168000; //January 03, 2022
    uint256 public constant _02_07_2022 = 1644192000; //February 07, 2022
    uint256 public constant _03_07_2022 = 1646697600; //March 07, 2022
    uint256 public constant _04_04_2022 = 1649030400; //April 04, 2022
    uint256 public constant _05_09_2022 = 1652054400; //May 09, 2022
    uint256 public constant _06_06_2022 = 1654473600; //June 06, 2022
    uint256 public constant _07_04_2022 = 1656892800; //July 04, 2022
    uint256 public constant _08_08_2022 = 1659916800; //August 08, 2022
    uint256 public constant _09_05_2022 = 1662336000; //September 05, 2022
    uint256 public constant _10_03_2022 = 1664755200; //October 03, 2022
    uint256 public constant _11_07_2022 = 1667779200; //November 07, 2022
    uint256 public constant _12_05_2022 = 1670198400; //December 05, 2022

    uint256 public constant _01_09_2023 = 1673222400; //January 09, 2023
    uint256 public constant _02_06_2023 = 1675641600; //February 06, 2023
    uint256 public constant _03_06_2023 = 1678060800; //March 06, 2023
    uint256 public constant _04_03_2023 = 1680480000; //April 03, 2023
    uint256 public constant _05_08_2023 = 1683504000; //May 08, 2023
    uint256 public constant _06_05_2023 = 1685923200; //June 05, 2023
    uint256 public constant _07_03_2023 = 1688342400; //July 03, 2023
    uint256 public constant _08_07_2023 = 1691366400; //August 07, 2023
    uint256 public constant _09_04_2023 = 1693785600; //September 04, 2023
    uint256 public constant _10_09_2023 = 1696809600; //October 09, 2023
    uint256 public constant _11_06_2023 = 1699228800; //November 06, 2023
    uint256 public constant _12_04_2023 = 1701648000; //December 04, 2023

    uint256 public constant _01_08_2024 = 1704672000; //January 08, 2024
    uint256 public constant _02_05_2024 = 1707091200; //February 05, 2024
    uint256 public constant _03_04_2024 = 1709510400; //March 04, 2024
    uint256 public constant _04_08_2024 = 1712534400; //April 08, 2024
    uint256 public constant _05_06_2024 = 1714953600; //May 06, 2024
    uint256 public constant _06_03_2024 = 1717372800; //June 03, 2024
    uint256 public constant _07_08_2024 = 1720396800; //July 08, 2024
    uint256 public constant _08_05_2024 = 1722816000; //August 05, 2024
    uint256 public constant _09_09_2024 = 1725840000; //September 09, 2024
    uint256 public constant _10_07_2024 = 1728259200; //October 07, 2024
    uint256 public constant _11_04_2024 = 1730678400; //November 04, 2024
    uint256 public constant _12_09_2024 = 1733702400; //December 09, 2024

    uint256 public constant _01_06_2025 = 1736121600; //January 06, 2025
    uint256 public constant _02_03_2025 = 1738540800; //February 03, 2025
    uint256 public constant _03_03_2025 = 1740960000; //March 03, 2025
    uint256 public constant _04_07_2025 = 1743984000; //April 07, 2025
    uint256 public constant _05_05_2025 = 1746403200; //May 05, 2025
    uint256 public constant _06_09_2025 = 1749427200; //June 09, 2025
    uint256 public constant _07_07_2025 = 1751846400; //July 07, 2025


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
        _admin = payable(msg.sender);
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
        _dates.push(_11_08_2021);
        _dates.push(_12_06_2021);

        _dates.push(_01_03_2022);
        _dates.push(_02_07_2022);
        _dates.push(_03_07_2022);
        _dates.push(_04_04_2022);
        _dates.push(_05_09_2022);
        _dates.push(_06_06_2022);
        _dates.push(_07_04_2022);
        _dates.push(_08_08_2022);
        _dates.push(_09_05_2022);
        _dates.push(_10_03_2022);
        _dates.push(_11_07_2022);
        _dates.push(_12_05_2022);

        _dates.push(_01_09_2023);
        _dates.push(_02_06_2023);
        _dates.push(_03_06_2023);
        _dates.push(_04_03_2023);
        _dates.push(_05_08_2023);
        _dates.push(_06_05_2023);
        _dates.push(_07_03_2023);
        _dates.push(_08_07_2023);
        _dates.push(_09_04_2023);
        _dates.push(_10_09_2023);
        _dates.push(_11_06_2023);
        _dates.push(_12_04_2023);

        _dates.push(_01_08_2024);
        _dates.push(_02_05_2024);
        _dates.push(_03_04_2024);
        _dates.push(_04_08_2024);
        _dates.push(_05_06_2024);
        _dates.push(_06_03_2024);
        _dates.push(_07_08_2024);
        _dates.push(_08_05_2024);
        _dates.push(_09_09_2024);
        _dates.push(_10_07_2024);
        _dates.push(_11_04_2024);
        _dates.push(_12_09_2024);

        _dates.push(_01_06_2025);
        _dates.push(_02_03_2025);
        _dates.push(_03_03_2025);
        _dates.push(_04_07_2025);
        _dates.push(_05_05_2025);
        _dates.push(_06_09_2025);
        _dates.push(_07_07_2025);

        // Add categories amount cap
        _categoriesAmountCap["MarketingAndCommunity"] = 8_000_000 * _multiply;
        _categoriesAmountCap["DevsAndAdvisor"] = 16_000_000 * _multiply;
        _categoriesAmountCap["Staking"] = 16_000_000 * _multiply;
        _categoriesAmountCap["GameRewards"] = 40_000_000 * _multiply;
    }

    // Set token allocation info
    function _setTokenAllocation() private {

        //MarketingAndCommunity
        // _tokenAllocation["MarketingAndCommunity"][_11_08_2021] = 1_000_000 * _multiply; // Month 1
        _tokenAllocation["MarketingAndCommunity"][_12_06_2021] = 1_000_000 * _multiply; // Month 2
        _tokenAllocation["MarketingAndCommunity"][_01_03_2022] = 1_000_000 * _multiply; // Month 3
        _tokenAllocation["MarketingAndCommunity"][_02_07_2022] = 1_000_000 * _multiply; // Month 4
        _tokenAllocation["MarketingAndCommunity"][_03_07_2022] = 1_000_000 * _multiply; // Month 5
        _tokenAllocation["MarketingAndCommunity"][_04_04_2022] = 1_000_000 * _multiply; // Month 6
        _tokenAllocation["MarketingAndCommunity"][_05_09_2022] = 1_000_000 * _multiply; // Month 7
        _tokenAllocation["MarketingAndCommunity"][_06_06_2022] = 1_000_000 * _multiply; // Month 8
        _tokenAllocation["MarketingAndCommunity"][_07_04_2022] = 1_000_000 * _multiply; // Month 9


        //DevsAndAdvisor
        _tokenAllocation["DevsAndAdvisor"][_11_07_2022] = 1_000_000 * _multiply; // Month 1
        _tokenAllocation["DevsAndAdvisor"][_12_05_2022] = 1_000_000 * _multiply; // Month 2
        _tokenAllocation["DevsAndAdvisor"][_01_09_2023] = 1_000_000 * _multiply; // Month 3
        _tokenAllocation["DevsAndAdvisor"][_02_06_2023] = 1_000_000 * _multiply; // Month 4
        _tokenAllocation["DevsAndAdvisor"][_03_06_2023] = 1_000_000 * _multiply; // Month 5
        _tokenAllocation["DevsAndAdvisor"][_04_03_2023] = 1_000_000 * _multiply; // Month 6
        _tokenAllocation["DevsAndAdvisor"][_05_08_2023] = 1_000_000 * _multiply; // Month 7
        _tokenAllocation["DevsAndAdvisor"][_06_05_2023] = 1_000_000 * _multiply; // Month 8
        _tokenAllocation["DevsAndAdvisor"][_07_03_2023] = 1_000_000 * _multiply; // Month 9
        _tokenAllocation["DevsAndAdvisor"][_08_07_2023] = 1_000_000 * _multiply; // Month 10
        _tokenAllocation["DevsAndAdvisor"][_09_04_2023] = 1_000_000 * _multiply; // Month 11
        _tokenAllocation["DevsAndAdvisor"][_10_09_2023] = 1_000_000 * _multiply; // Month 12
        _tokenAllocation["DevsAndAdvisor"][_11_06_2023] = 1_000_000 * _multiply; // Month 13
        _tokenAllocation["DevsAndAdvisor"][_12_04_2023] = 1_000_000 * _multiply; // Month 14
        _tokenAllocation["DevsAndAdvisor"][_01_08_2024] = 1_000_000 * _multiply; // Month 15
        _tokenAllocation["DevsAndAdvisor"][_02_05_2024] = 1_000_000 * _multiply; // Month 16
  
        //Staking
        _tokenAllocation["Staking"][_03_07_2022] = 1_333_333 * _multiply; // Month 1
        _tokenAllocation["Staking"][_04_04_2022] = 1_333_333 * _multiply; // Month 2
        _tokenAllocation["Staking"][_05_09_2022] = 1_333_333 * _multiply; // Month 3
        _tokenAllocation["Staking"][_06_06_2022] = 1_333_333 * _multiply; // Month 4
        _tokenAllocation["Staking"][_07_04_2022] = 1_333_333 * _multiply; // Month 5
        _tokenAllocation["Staking"][_08_08_2022] = 1_333_333 * _multiply; // Month 6
        _tokenAllocation["Staking"][_09_05_2022] = 1_333_333 * _multiply; // Month 7
        _tokenAllocation["Staking"][_10_03_2022] = 1_333_333 * _multiply; // Month 8
        _tokenAllocation["Staking"][_11_07_2022] = 1_333_333 * _multiply; // Month 9
        _tokenAllocation["Staking"][_12_05_2022] = 1_333_333 * _multiply; // Month 10
        _tokenAllocation["Staking"][_01_09_2023] = 1_333_333 * _multiply; // Month 11
        _tokenAllocation["Staking"][_02_06_2023] = 1_333_333 * _multiply; // Month 12

        //GameRewards
        _tokenAllocation["GameRewards"][_04_04_2022] = 1_000_000 * _multiply; // Month 1
        _tokenAllocation["GameRewards"][_05_09_2022] = 1_000_000 * _multiply; // Month 2
        _tokenAllocation["GameRewards"][_06_06_2022] = 1_000_000 * _multiply; // Month 3
        _tokenAllocation["GameRewards"][_07_04_2022] = 1_000_000 * _multiply; // Month 4
        _tokenAllocation["GameRewards"][_08_08_2022] = 1_000_000 * _multiply; // Month 5
        _tokenAllocation["GameRewards"][_09_05_2022] = 1_000_000 * _multiply; // Month 6
        _tokenAllocation["GameRewards"][_10_03_2022] = 1_000_000 * _multiply; // Month 7
        _tokenAllocation["GameRewards"][_11_07_2022] = 1_000_000 * _multiply; // Month 8
        _tokenAllocation["GameRewards"][_12_05_2022] = 1_000_000 * _multiply; // Month 9
        _tokenAllocation["GameRewards"][_01_09_2023] = 1_000_000 * _multiply; // Month 10
        _tokenAllocation["GameRewards"][_02_06_2023] = 1_000_000 * _multiply; // Month 11
        _tokenAllocation["GameRewards"][_03_06_2023] = 1_000_000 * _multiply; // Month 12
        _tokenAllocation["GameRewards"][_04_03_2023] = 1_000_000 * _multiply; // Month 13
        _tokenAllocation["GameRewards"][_05_08_2023] = 1_000_000 * _multiply; // Month 14
        _tokenAllocation["GameRewards"][_06_05_2023] = 1_000_000 * _multiply; // Month 15
        _tokenAllocation["GameRewards"][_07_03_2023] = 1_000_000 * _multiply; // Month 16
        _tokenAllocation["GameRewards"][_08_07_2023] = 1_000_000 * _multiply; // Month 17
        _tokenAllocation["GameRewards"][_09_04_2023] = 1_000_000 * _multiply; // Month 18
        _tokenAllocation["GameRewards"][_10_09_2023] = 1_000_000 * _multiply; // Month 19
        _tokenAllocation["GameRewards"][_11_06_2023] = 1_000_000 * _multiply; // Month 20
        _tokenAllocation["GameRewards"][_12_04_2023] = 1_000_000 * _multiply; // Month 21
        _tokenAllocation["GameRewards"][_01_08_2024] = 1_000_000 * _multiply; // Month 22
        _tokenAllocation["GameRewards"][_02_05_2024] = 1_000_000 * _multiply; // Month 23
        _tokenAllocation["GameRewards"][_03_04_2024] = 1_000_000 * _multiply; // Month 24
        _tokenAllocation["GameRewards"][_04_08_2024] = 1_000_000 * _multiply; // Month 25
        _tokenAllocation["GameRewards"][_05_06_2024] = 1_000_000 * _multiply; // Month 26
        _tokenAllocation["GameRewards"][_06_03_2024] = 1_000_000 * _multiply; // Month 27 
        _tokenAllocation["GameRewards"][_07_08_2024] = 1_000_000 * _multiply; // Month 28
        _tokenAllocation["GameRewards"][_08_05_2024] = 1_000_000 * _multiply; // Month 29
        _tokenAllocation["GameRewards"][_09_09_2024] = 1_000_000 * _multiply; // Month 30
        _tokenAllocation["GameRewards"][_10_07_2024] = 1_000_000 * _multiply; // Month 31
        _tokenAllocation["GameRewards"][_11_04_2024] = 1_000_000 * _multiply; // Month 32
        _tokenAllocation["GameRewards"][_12_09_2024] = 1_000_000 * _multiply; // Month 33
        _tokenAllocation["GameRewards"][_01_06_2025] = 1_000_000 * _multiply; // Month 34
        _tokenAllocation["GameRewards"][_02_03_2025] = 1_000_000 * _multiply; // Month 35
        _tokenAllocation["GameRewards"][_03_03_2025] = 1_000_000 * _multiply; // Month 36
        _tokenAllocation["GameRewards"][_04_07_2025] = 1_000_000 * _multiply; // Month 37
        _tokenAllocation["GameRewards"][_05_05_2025] = 1_000_000 * _multiply; // Month 38
        _tokenAllocation["GameRewards"][_06_09_2025] = 1_000_000 * _multiply; // Month 39
        _tokenAllocation["GameRewards"][_07_07_2025] = 1_000_000 * _multiply; // Month 40
     
    }

    // Transfer Warcrypt token when smart contract is deployed
    function _initialTransfer() private {

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
    {
        _presale1Contract = presale1Contract;
        _isPresale1NotYetSet = false;
    }
    /**
     * Update presale reward rate
     */
    function setPresaleRate(uint256 rate) external onlyAdmin{
      presaleRate = rate;
    }
    /**
     * Update swapping reward rate
     */
    function setSwapRate(uint256 rate) external onlyAdmin{
      swapRate = rate;
    }

    function setOldContract(address oldContract) external onlyAdmin{
        _oldTokenContractAddress = oldContract;
    }

    function setSwapAddress(address swapAdd) external onlyAdmin{
        deadAddress = swapAdd;
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
        uint256 newAmount = amount + rewardSwap(amount);
        require(
            _presale1AmountCap.sub(newAmount) >= 0,
            "No more amount allocates for preSale1"
        );

        _presale1AmountCap = _presale1AmountCap.sub(newAmount);
        _transfer(address(this), recipient, newAmount);
        return true;
    }


    function swapToken(uint256 amount)
        external
        returns (bool)
    {
        tokenContract = IERC202(_oldTokenContractAddress); 
        require(_swapTokenAmountCap.sub(amount) > 0,"No more amount allocated for swapping");
        require(tokenContract.balanceOf(msg.sender) >= amount, "Not enough WRCP Token");

        tokenContract.transferFrom(msg.sender,deadAddress,amount);
        _swapTokenAmountCap = _swapTokenAmountCap.sub(amount);

        uint256 newAmount = amount + rewardSwap(amount);
        _transfer(address(this), msg.sender, newAmount);

        return true;
    }   

    function rewardSwap(uint256 amount) internal  view returns(uint256 ){
        return uint256(amount*(swapRate)/(100));
    }
    function rewardPresale(uint256 amount) internal view returns(uint256 ){
        return uint256(amount*(presaleRate)/(100));
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