pragma solidity 0.6.0;

import "./SafeMath.sol";

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount)
  external
  returns (bool);

  function allowance(address owner, address spender)
  external
  view
  returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint value
  );
}

contract MoniToken is IERC20 {
  using SafeMath for uint;

  // ERC20 variables
  mapping(address => uint) private _balances;
  mapping(address => mapping(address => uint)) private _allowances;
  uint private _totalSupply = 270_000_000 * 1_000_000_000_000_000_000;

  // General variables
  string public constant name = "Monsta Infinite Token";
  string public constant symbol = "MONI";
  uint8 public constant decimals = 18;
  address payable public _admin;

  // External contract general variables
  uint _preSale1AmountCap = 540_000 * 1_000_000_000_000_000_000;
  uint _preSale2AmountCap = 7_560_000 * 1_000_000_000_000_000_000;
  address public _preSale1Contract;
  address public _preSale2Contract;
  bool public _hasPreSale1ContractNotYetSet = true;
  bool public _hasPreSale2ContractNotYetSet = true;

  // Utility variables
  bool public _isPaused;
  mapping(address => bool) public _isPausedAddress;

  // Date variables
  uint public constant _Sep_16_2021_1800 = 1_631_815_200; // TGE
  uint public constant _Sep_23_2021 = 1_632_355_200; // 1 Week
  uint public constant _Sep_30_2021 = 1_632_960_000; // 2 Week
  uint public constant _Oct_16_2021 = 1_634_342_400; // Month 2
  uint public constant _Nov_16_2021 = 1_637_020_800; // Month 3
  uint public constant _Dec_16_2021 = 1_639_612_800; // Month 4
  uint public constant _Jan_16_2022 = 1_642_291_200; // Month 5
  uint public constant _Feb_16_2022 = 1_644_969_600; // Month 6
  uint public constant _Mar_16_2022 = 1_647_388_800; // Month 7
  uint public constant _Apr_16_2022 = 1_650_067_200; // Month 8
  uint public constant _May_16_2022 = 1_652_659_200; // Month 9
  uint public constant _Jun_16_2022 = 1_655_337_600; // Month 10
  uint public constant _Jul_16_2022 = 1_657_929_600; // Month 11
  uint public constant _Aug_16_2022 = 1_660_608_000; // Month 12
  uint public constant _Sep_16_2022 = 1_663_286_400; // Month 13
  uint public constant _Oct_16_2022 = 1_665_878_400; // Month 14
  uint public constant _Nov_16_2022 = 1_668_556_800; // Month 15
  uint public constant _Dec_16_2022 = 1_671_148_800; // Month 16
  uint public constant _Jan_16_2023 = 1_673_827_200; // Month 17
  uint public constant _Feb_16_2023 = 1_676_505_600; // Month 18
  uint public constant _Mar_16_2023 = 1_678_924_800; // Month 19
  uint public constant _Apr_16_2023 = 1_681_603_200; // Month 20
  uint public constant _May_16_2023 = 1_684_195_200; // Month 21
  uint public constant _Jun_16_2023 = 1_686_873_600; // Month 22
  uint public constant _Jul_16_2023 = 1_689_465_600; // Month 23
  uint public constant _Aug_16_2023 = 1_692_144_000; // Month 24
  uint public constant _Sep_16_2023 = 1_694_822_400; // Month 25
  uint public constant _Oct_16_2023 = 1_697_414_400; // Month 26
  uint public constant _Nov_16_2023 = 1_700_092_800; // Month 27
  uint public constant _Dec_16_2023 = 1_702_684_800; // Month 28
  uint public constant _Jan_16_2024 = 1_705_363_200; // Month 29
  uint public constant _Feb_16_2024 = 1_708_041_600; // Month 30
  uint public constant _Mar_16_2024 = 1_710_547_200; // Month 31
  uint public constant _Apr_16_2024 = 1_713_225_600; // Month 32
  uint public constant _May_16_2024 = 1_715_817_600; // Month 33
  uint public constant _Jun_16_2024 = 1_718_496_000; // Month 34
  uint public constant _Jul_16_2024 = 1_721_088_000; // Month 35
  uint public constant _Aug_16_2024 = 1_723_766_400; // Month 36
  uint public constant _Sep_16_2024 = 1_726_444_800; // Month 37
  uint public constant _Oct_16_2024 = 1_729_036_800; // Month 38
  uint public constant _Nov_16_2024 = 1_731_715_200; // Month 39
  uint public constant _Dec_16_2024 = 1_734_307_200; // Month 40
  uint public constant _Jan_16_2025 = 1_736_985_600; // Month 41
  uint public constant _Feb_16_2025 = 1_739_664_000; // Month 42
  uint public constant _Mar_16_2025 = 1_742_083_200; // Month 43
  uint public constant _Apr_16_2025 = 1_744_761_600; // Month 44
  uint public constant _May_16_2025 = 1_747_353_600; // Month 45
  uint public constant _Jun_16_2025 = 1_750_032_000; // Month 46
  uint public constant _Jul_16_2025 = 1_752_624_000; // Month 47
  uint public constant _Aug_16_2025 = 1_755_302_400; // Month 48
  uint public constant _Sep_16_2025 = 1_757_980_800; // Month 49
  uint public constant _Oct_16_2025 = 1_760_572_800; // Month 50
  uint public constant _Nov_16_2025 = 1_763_251_200; // Month 51
  uint public constant _Dec_16_2025 = 1_765_843_200; // Month 52
  uint public constant _Jan_16_2026 = 1_768_521_600; // Month 53
  uint public constant _Feb_16_2026 = 1_771_200_000; // Month 54
  uint public constant _Mar_16_2026 = 1_773_619_200; // Month 55
  uint public constant _Apr_16_2026 = 1_776_297_600; // Month 56
  uint public constant _May_16_2026 = 1_778_889_600; // Month 57
  uint public constant _Jun_16_2026 = 1_781_568_000; // Month 58
  uint public constant _Jul_16_2026 = 1_784_160_000; // Month 59
  uint public constant _Aug_16_2026 = 1_786_838_400; // Month 60

  string[] public _categories; // String that represent address identities
  uint[] public _dates; // The cutoff dates that allow coin distribution
  mapping(string => uint) public _categoriesAmountCap; // The maximum amount allowed to be transfer (Category => Cap)
  mapping(string => address) public _categoriesAddress; // Address for categories (Category => Address)
  mapping(string => mapping(uint => uint)) public _coinDistribution; // Coin distribution schedule (Category => Unix Date => Amount)
  mapping(string => mapping(uint => mapping(uint => bool))) public _coinDistributionStatus;// Coin distribution schedule status, Yes = hasDistributed (Category => Unix Date => Amount => bool)

  event OutOfMoney(string category);  // emit when `_categoriesAmountCap` less than required amount.

  constructor(
     address advisorAddress,
     address teamAddress,
     address marketingAddress,
     address ecosystemFundAddress,
     address gameplayAddress,
     address stakingAddress
      ) public {
    _admin = msg.sender;
    _balances[address(this)] = _totalSupply;
    
    // Add all addresses
    _categoriesAddress['Advisors'] = advisorAddress;
    _categoriesAddress['Team'] = teamAddress;
    _categoriesAddress['Marketing'] = marketingAddress;
    _categoriesAddress['EcosystemFund'] = ecosystemFundAddress;
    _categoriesAddress['Gameplay'] = gameplayAddress;
    _categoriesAddress['Staking'] = stakingAddress;
    
    _setDefaultValues();
    _setCoinDistribution();
    _initialTransfer(); // Send to privateSale, IDO, liquidity, bLaunchpad
  }

  function _setDefaultValues() private {
    // Add all categories
    _categories.push('Advisors');
    _categories.push('Team');
    _categories.push('Marketing');
    _categories.push('EcosystemFund');
    _categories.push('Gameplay');
    _categories.push('Staking');

    // Add all dates
    _dates.push(_Sep_16_2021_1800);
    _dates.push(_Sep_23_2021);
    _dates.push(_Sep_30_2021);
    _dates.push(_Oct_16_2021);
    _dates.push(_Nov_16_2021);
    _dates.push(_Dec_16_2021);
    _dates.push(_Jan_16_2022);
    _dates.push(_Feb_16_2022);
    _dates.push(_Mar_16_2022);
    _dates.push(_Apr_16_2022);
    _dates.push(_May_16_2022);
    _dates.push(_Jun_16_2022);
    _dates.push(_Jul_16_2022);
    _dates.push(_Aug_16_2022);
    _dates.push(_Sep_16_2022);
    _dates.push(_Oct_16_2022);
    _dates.push(_Nov_16_2022);
    _dates.push(_Dec_16_2022);
    _dates.push(_Jan_16_2023);
    _dates.push(_Feb_16_2023);
    _dates.push(_Mar_16_2023);
    _dates.push(_Apr_16_2023);
    _dates.push(_May_16_2023);
    _dates.push(_Jun_16_2023);
    _dates.push(_Jul_16_2023);
    _dates.push(_Aug_16_2023);
    _dates.push(_Sep_16_2023);
    _dates.push(_Oct_16_2023);
    _dates.push(_Nov_16_2023);
    _dates.push(_Dec_16_2023);
    _dates.push(_Jan_16_2024);
    _dates.push(_Feb_16_2024);
    _dates.push(_Mar_16_2024);
    _dates.push(_Apr_16_2024);
    _dates.push(_May_16_2024);
    _dates.push(_Jun_16_2024);
    _dates.push(_Jul_16_2024);
    _dates.push(_Aug_16_2024);
    _dates.push(_Sep_16_2024);
    _dates.push(_Oct_16_2024);
    _dates.push(_Nov_16_2024);
    _dates.push(_Dec_16_2024);
    _dates.push(_Jan_16_2025);
    _dates.push(_Feb_16_2025);
    _dates.push(_Mar_16_2025);
    _dates.push(_Apr_16_2025);
    _dates.push(_May_16_2025);
    _dates.push(_Jun_16_2025);
    _dates.push(_Jul_16_2025);
    _dates.push(_Aug_16_2025);
    _dates.push(_Sep_16_2025);
    _dates.push(_Oct_16_2025);
    _dates.push(_Nov_16_2025);
    _dates.push(_Dec_16_2025);
    _dates.push(_Jan_16_2026);
    _dates.push(_Feb_16_2026);
    _dates.push(_Mar_16_2026);
    _dates.push(_Apr_16_2026);
    _dates.push(_May_16_2026);
    _dates.push(_Jun_16_2026);
    _dates.push(_Jul_16_2026);
    _dates.push(_Aug_16_2026);

    // Add all amount cap
    _categoriesAmountCap['Advisors'] = 13_500_000 * 1_000_000_000_000_000_000;
    _categoriesAmountCap['Team'] = 43_200_000 * 1_000_000_000_000_000_000;
    _categoriesAmountCap['Marketing'] = 24_300_000 * 1_000_000_000_000_000_000;
    _categoriesAmountCap['EcosystemFund'] = 13_500_000 * 1_000_000_000_000_000_000;
    _categoriesAmountCap['Gameplay'] = 67_500_000 * 1_000_000_000_000_000_000;
    _categoriesAmountCap['Staking'] = 64_800_000 * 1_000_000_000_000_000_000;
  }


   // Set coin distribution info
   // For eg: _coinDistribution['Advisors'][_Sep_16_2022] = 281_250  * 1_000_000_000_000_000_000;
   // Means: 281,250 amount will be distributed to Advisors’ address after Sep_16_2022
  function _setCoinDistribution() private {
    _coinDistribution['Advisors'][_Sep_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 13
    _coinDistribution['Advisors'][_Oct_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 14
    _coinDistribution['Advisors'][_Nov_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 15
    _coinDistribution['Advisors'][_Dec_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 16
    _coinDistribution['Advisors'][_Jan_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 17
    _coinDistribution['Advisors'][_Feb_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 18
    _coinDistribution['Advisors'][_Mar_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 19
    _coinDistribution['Advisors'][_Apr_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 20
    _coinDistribution['Advisors'][_May_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 21
    _coinDistribution['Advisors'][_Jun_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 22
    _coinDistribution['Advisors'][_Jul_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 23
    _coinDistribution['Advisors'][_Aug_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 24
    _coinDistribution['Advisors'][_Sep_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 25
    _coinDistribution['Advisors'][_Oct_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 26
    _coinDistribution['Advisors'][_Nov_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 27
    _coinDistribution['Advisors'][_Dec_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 28
    _coinDistribution['Advisors'][_Jan_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 29
    _coinDistribution['Advisors'][_Feb_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 30
    _coinDistribution['Advisors'][_Mar_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 31
    _coinDistribution['Advisors'][_Apr_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 32
    _coinDistribution['Advisors'][_May_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 33
    _coinDistribution['Advisors'][_Jun_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 34
    _coinDistribution['Advisors'][_Jul_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 35
    _coinDistribution['Advisors'][_Aug_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 36
    _coinDistribution['Advisors'][_Sep_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 37
    _coinDistribution['Advisors'][_Oct_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 38
    _coinDistribution['Advisors'][_Nov_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 39
    _coinDistribution['Advisors'][_Dec_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 40
    _coinDistribution['Advisors'][_Jan_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 41
    _coinDistribution['Advisors'][_Feb_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 42
    _coinDistribution['Advisors'][_Mar_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 43
    _coinDistribution['Advisors'][_Apr_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 44
    _coinDistribution['Advisors'][_May_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 45
    _coinDistribution['Advisors'][_Jun_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 46
    _coinDistribution['Advisors'][_Jul_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 47
    _coinDistribution['Advisors'][_Aug_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 48
    _coinDistribution['Advisors'][_Sep_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 49
    _coinDistribution['Advisors'][_Oct_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 50
    _coinDistribution['Advisors'][_Nov_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 51
    _coinDistribution['Advisors'][_Dec_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 52
    _coinDistribution['Advisors'][_Jan_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 53
    _coinDistribution['Advisors'][_Feb_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 54
    _coinDistribution['Advisors'][_Mar_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 55
    _coinDistribution['Advisors'][_Apr_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 56
    _coinDistribution['Advisors'][_May_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 57
    _coinDistribution['Advisors'][_Jun_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 58
    _coinDistribution['Advisors'][_Jul_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 59
    _coinDistribution['Advisors'][_Aug_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 60
    _coinDistribution['Team'][_Sep_16_2022]=  900_000  * 1_000_000_000_000_000_000; // Month 13
    _coinDistribution['Team'][_Oct_16_2022]=  900_000  * 1_000_000_000_000_000_000; // Month 14
    _coinDistribution['Team'][_Nov_16_2022]=  900_000  * 1_000_000_000_000_000_000; // Month 15
    _coinDistribution['Team'][_Dec_16_2022]=  900_000  * 1_000_000_000_000_000_000; // Month 16
    _coinDistribution['Team'][_Jan_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 17
    _coinDistribution['Team'][_Feb_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 18
    _coinDistribution['Team'][_Mar_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 19
    _coinDistribution['Team'][_Apr_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 20
    _coinDistribution['Team'][_May_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 21
    _coinDistribution['Team'][_Jun_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 22
    _coinDistribution['Team'][_Jul_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 23
    _coinDistribution['Team'][_Aug_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 24
    _coinDistribution['Team'][_Sep_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 25
    _coinDistribution['Team'][_Oct_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 26
    _coinDistribution['Team'][_Nov_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 27
    _coinDistribution['Team'][_Dec_16_2023]=  900_000  * 1_000_000_000_000_000_000; // Month 28
    _coinDistribution['Team'][_Jan_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 29
    _coinDistribution['Team'][_Feb_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 30
    _coinDistribution['Team'][_Mar_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 31
    _coinDistribution['Team'][_Apr_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 32
    _coinDistribution['Team'][_May_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 33
    _coinDistribution['Team'][_Jun_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 34
    _coinDistribution['Team'][_Jul_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 35
    _coinDistribution['Team'][_Aug_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 36
    _coinDistribution['Team'][_Sep_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 37
    _coinDistribution['Team'][_Oct_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 38
    _coinDistribution['Team'][_Nov_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 39
    _coinDistribution['Team'][_Dec_16_2024]=  900_000  * 1_000_000_000_000_000_000; // Month 40
    _coinDistribution['Team'][_Jan_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 41
    _coinDistribution['Team'][_Feb_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 42
    _coinDistribution['Team'][_Mar_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 43
    _coinDistribution['Team'][_Apr_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 44
    _coinDistribution['Team'][_May_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 45
    _coinDistribution['Team'][_Jun_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 46
    _coinDistribution['Team'][_Jul_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 47
    _coinDistribution['Team'][_Aug_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 48
    _coinDistribution['Team'][_Sep_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 49
    _coinDistribution['Team'][_Oct_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 50
    _coinDistribution['Team'][_Nov_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 51
    _coinDistribution['Team'][_Dec_16_2025]=  900_000  * 1_000_000_000_000_000_000; // Month 52
    _coinDistribution['Team'][_Jan_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 53
    _coinDistribution['Team'][_Feb_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 54
    _coinDistribution['Team'][_Mar_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 55
    _coinDistribution['Team'][_Apr_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 56
    _coinDistribution['Team'][_May_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 57
    _coinDistribution['Team'][_Jun_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 58
    _coinDistribution['Team'][_Jul_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 59
    _coinDistribution['Team'][_Aug_16_2026]=  900_000  * 1_000_000_000_000_000_000; // Month 60
    _coinDistribution['Marketing'][_Sep_16_2021_1800]=  675_000  * 1_000_000_000_000_000_000; // TGE
    _coinDistribution['Marketing'][_Oct_16_2021]=  675_000  * 1_000_000_000_000_000_000; // Month 2
    _coinDistribution['Marketing'][_Nov_16_2021]=  675_000  * 1_000_000_000_000_000_000; // Month 3
    _coinDistribution['Marketing'][_Dec_16_2021]=  675_000  * 1_000_000_000_000_000_000; // Month 4
    _coinDistribution['Marketing'][_Jan_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 5
    _coinDistribution['Marketing'][_Feb_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 6
    _coinDistribution['Marketing'][_Mar_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 7
    _coinDistribution['Marketing'][_Apr_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 8
    _coinDistribution['Marketing'][_May_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 9
    _coinDistribution['Marketing'][_Jun_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 10
    _coinDistribution['Marketing'][_Jul_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 11
    _coinDistribution['Marketing'][_Aug_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 12
    _coinDistribution['Marketing'][_Sep_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 13
    _coinDistribution['Marketing'][_Oct_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 14
    _coinDistribution['Marketing'][_Nov_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 15
    _coinDistribution['Marketing'][_Dec_16_2022]=  675_000  * 1_000_000_000_000_000_000; // Month 16
    _coinDistribution['Marketing'][_Jan_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 17
    _coinDistribution['Marketing'][_Feb_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 18
    _coinDistribution['Marketing'][_Mar_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 19
    _coinDistribution['Marketing'][_Apr_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 20
    _coinDistribution['Marketing'][_May_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 21
    _coinDistribution['Marketing'][_Jun_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 22
    _coinDistribution['Marketing'][_Jul_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 23
    _coinDistribution['Marketing'][_Aug_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 24
    _coinDistribution['Marketing'][_Sep_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 25
    _coinDistribution['Marketing'][_Oct_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 26
    _coinDistribution['Marketing'][_Nov_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 27
    _coinDistribution['Marketing'][_Dec_16_2023]=  675_000  * 1_000_000_000_000_000_000; // Month 28
    _coinDistribution['Marketing'][_Jan_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 29
    _coinDistribution['Marketing'][_Feb_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 30
    _coinDistribution['Marketing'][_Mar_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 31
    _coinDistribution['Marketing'][_Apr_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 32
    _coinDistribution['Marketing'][_May_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 33
    _coinDistribution['Marketing'][_Jun_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 34
    _coinDistribution['Marketing'][_Jul_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 35
    _coinDistribution['Marketing'][_Aug_16_2024]=  675_000  * 1_000_000_000_000_000_000; // Month 36
    _coinDistribution['EcosystemFund'][_Sep_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 13
    _coinDistribution['EcosystemFund'][_Oct_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 14
    _coinDistribution['EcosystemFund'][_Nov_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 15
    _coinDistribution['EcosystemFund'][_Dec_16_2022]=  281_250  * 1_000_000_000_000_000_000; // Month 16
    _coinDistribution['EcosystemFund'][_Jan_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 17
    _coinDistribution['EcosystemFund'][_Feb_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 18
    _coinDistribution['EcosystemFund'][_Mar_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 19
    _coinDistribution['EcosystemFund'][_Apr_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 20
    _coinDistribution['EcosystemFund'][_May_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 21
    _coinDistribution['EcosystemFund'][_Jun_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 22
    _coinDistribution['EcosystemFund'][_Jul_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 23
    _coinDistribution['EcosystemFund'][_Aug_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 24
    _coinDistribution['EcosystemFund'][_Sep_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 25
    _coinDistribution['EcosystemFund'][_Oct_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 26
    _coinDistribution['EcosystemFund'][_Nov_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 27
    _coinDistribution['EcosystemFund'][_Dec_16_2023]=  281_250  * 1_000_000_000_000_000_000; // Month 28
    _coinDistribution['EcosystemFund'][_Jan_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 29
    _coinDistribution['EcosystemFund'][_Feb_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 30
    _coinDistribution['EcosystemFund'][_Mar_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 31
    _coinDistribution['EcosystemFund'][_Apr_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 32
    _coinDistribution['EcosystemFund'][_May_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 33
    _coinDistribution['EcosystemFund'][_Jun_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 34
    _coinDistribution['EcosystemFund'][_Jul_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 35
    _coinDistribution['EcosystemFund'][_Aug_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 36
    _coinDistribution['EcosystemFund'][_Sep_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 37
    _coinDistribution['EcosystemFund'][_Oct_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 38
    _coinDistribution['EcosystemFund'][_Nov_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 39
    _coinDistribution['EcosystemFund'][_Dec_16_2024]=  281_250  * 1_000_000_000_000_000_000; // Month 40
    _coinDistribution['EcosystemFund'][_Jan_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 41
    _coinDistribution['EcosystemFund'][_Feb_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 42
    _coinDistribution['EcosystemFund'][_Mar_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 43
    _coinDistribution['EcosystemFund'][_Apr_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 44
    _coinDistribution['EcosystemFund'][_May_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 45
    _coinDistribution['EcosystemFund'][_Jun_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 46
    _coinDistribution['EcosystemFund'][_Jul_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 47
    _coinDistribution['EcosystemFund'][_Aug_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 48
    _coinDistribution['EcosystemFund'][_Sep_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 49
    _coinDistribution['EcosystemFund'][_Oct_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 50
    _coinDistribution['EcosystemFund'][_Nov_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 51
    _coinDistribution['EcosystemFund'][_Dec_16_2025]=  281_250  * 1_000_000_000_000_000_000; // Month 52
    _coinDistribution['EcosystemFund'][_Jan_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 53
    _coinDistribution['EcosystemFund'][_Feb_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 54
    _coinDistribution['EcosystemFund'][_Mar_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 55
    _coinDistribution['EcosystemFund'][_Apr_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 56
    _coinDistribution['EcosystemFund'][_May_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 57
    _coinDistribution['EcosystemFund'][_Jun_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 58
    _coinDistribution['EcosystemFund'][_Jul_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 59
    _coinDistribution['EcosystemFund'][_Aug_16_2026]=  281_250  * 1_000_000_000_000_000_000; // Month 60
    _coinDistribution['Gameplay'][_Mar_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 7
    _coinDistribution['Gameplay'][_Apr_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 8
    _coinDistribution['Gameplay'][_May_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 9
    _coinDistribution['Gameplay'][_Jun_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 10
    _coinDistribution['Gameplay'][_Jul_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 11
    _coinDistribution['Gameplay'][_Aug_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 12
    _coinDistribution['Gameplay'][_Sep_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 13
    _coinDistribution['Gameplay'][_Oct_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 14
    _coinDistribution['Gameplay'][_Nov_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 15
    _coinDistribution['Gameplay'][_Dec_16_2022]=  1_250_000  * 1_000_000_000_000_000_000; // Month 16
    _coinDistribution['Gameplay'][_Jan_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 17
    _coinDistribution['Gameplay'][_Feb_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 18
    _coinDistribution['Gameplay'][_Mar_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 19
    _coinDistribution['Gameplay'][_Apr_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 20
    _coinDistribution['Gameplay'][_May_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 21
    _coinDistribution['Gameplay'][_Jun_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 22
    _coinDistribution['Gameplay'][_Jul_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 23
    _coinDistribution['Gameplay'][_Aug_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 24
    _coinDistribution['Gameplay'][_Sep_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 25
    _coinDistribution['Gameplay'][_Oct_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 26
    _coinDistribution['Gameplay'][_Nov_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 27
    _coinDistribution['Gameplay'][_Dec_16_2023]=  1_250_000  * 1_000_000_000_000_000_000; // Month 28
    _coinDistribution['Gameplay'][_Jan_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 29
    _coinDistribution['Gameplay'][_Feb_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 30
    _coinDistribution['Gameplay'][_Mar_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 31
    _coinDistribution['Gameplay'][_Apr_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 32
    _coinDistribution['Gameplay'][_May_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 33
    _coinDistribution['Gameplay'][_Jun_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 34
    _coinDistribution['Gameplay'][_Jul_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 35
    _coinDistribution['Gameplay'][_Aug_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 36
    _coinDistribution['Gameplay'][_Sep_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 37
    _coinDistribution['Gameplay'][_Oct_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 38
    _coinDistribution['Gameplay'][_Nov_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 39
    _coinDistribution['Gameplay'][_Dec_16_2024]=  1_250_000  * 1_000_000_000_000_000_000; // Month 40
    _coinDistribution['Gameplay'][_Jan_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 41
    _coinDistribution['Gameplay'][_Feb_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 42
    _coinDistribution['Gameplay'][_Mar_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 43
    _coinDistribution['Gameplay'][_Apr_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 44
    _coinDistribution['Gameplay'][_May_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 45
    _coinDistribution['Gameplay'][_Jun_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 46
    _coinDistribution['Gameplay'][_Jul_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 47
    _coinDistribution['Gameplay'][_Aug_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 48
    _coinDistribution['Gameplay'][_Sep_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 49
    _coinDistribution['Gameplay'][_Oct_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 50
    _coinDistribution['Gameplay'][_Nov_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 51
    _coinDistribution['Gameplay'][_Dec_16_2025]=  1_250_000  * 1_000_000_000_000_000_000; // Month 52
    _coinDistribution['Gameplay'][_Jan_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 53
    _coinDistribution['Gameplay'][_Feb_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 54
    _coinDistribution['Gameplay'][_Mar_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 55
    _coinDistribution['Gameplay'][_Apr_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 56
    _coinDistribution['Gameplay'][_May_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 57
    _coinDistribution['Gameplay'][_Jun_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 58
    _coinDistribution['Gameplay'][_Jul_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 59
    _coinDistribution['Gameplay'][_Aug_16_2026]=  1_250_000  * 1_000_000_000_000_000_000; // Month 60
    _coinDistribution['Staking'][_Mar_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 7
    _coinDistribution['Staking'][_Apr_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 8
    _coinDistribution['Staking'][_May_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 9
    _coinDistribution['Staking'][_Jun_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 10
    _coinDistribution['Staking'][_Jul_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 11
    _coinDistribution['Staking'][_Aug_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 12
    _coinDistribution['Staking'][_Sep_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 13
    _coinDistribution['Staking'][_Oct_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 14
    _coinDistribution['Staking'][_Nov_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 15
    _coinDistribution['Staking'][_Dec_16_2022]=  1_200_000  * 1_000_000_000_000_000_000; // Month 16
    _coinDistribution['Staking'][_Jan_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 17
    _coinDistribution['Staking'][_Feb_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 18
    _coinDistribution['Staking'][_Mar_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 19
    _coinDistribution['Staking'][_Apr_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 20
    _coinDistribution['Staking'][_May_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 21
    _coinDistribution['Staking'][_Jun_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 22
    _coinDistribution['Staking'][_Jul_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 23
    _coinDistribution['Staking'][_Aug_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 24
    _coinDistribution['Staking'][_Sep_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 25
    _coinDistribution['Staking'][_Oct_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 26
    _coinDistribution['Staking'][_Nov_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 27
    _coinDistribution['Staking'][_Dec_16_2023]=  1_200_000  * 1_000_000_000_000_000_000; // Month 28
    _coinDistribution['Staking'][_Jan_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 29
    _coinDistribution['Staking'][_Feb_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 30
    _coinDistribution['Staking'][_Mar_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 31
    _coinDistribution['Staking'][_Apr_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 32
    _coinDistribution['Staking'][_May_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 33
    _coinDistribution['Staking'][_Jun_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 34
    _coinDistribution['Staking'][_Jul_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 35
    _coinDistribution['Staking'][_Aug_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 36
    _coinDistribution['Staking'][_Sep_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 37
    _coinDistribution['Staking'][_Oct_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 38
    _coinDistribution['Staking'][_Nov_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 39
    _coinDistribution['Staking'][_Dec_16_2024]=  1_200_000  * 1_000_000_000_000_000_000; // Month 40
    _coinDistribution['Staking'][_Jan_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 41
    _coinDistribution['Staking'][_Feb_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 42
    _coinDistribution['Staking'][_Mar_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 43
    _coinDistribution['Staking'][_Apr_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 44
    _coinDistribution['Staking'][_May_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 45
    _coinDistribution['Staking'][_Jun_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 46
    _coinDistribution['Staking'][_Jul_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 47
    _coinDistribution['Staking'][_Aug_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 48
    _coinDistribution['Staking'][_Sep_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 49
    _coinDistribution['Staking'][_Oct_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 50
    _coinDistribution['Staking'][_Nov_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 51
    _coinDistribution['Staking'][_Dec_16_2025]=  1_200_000  * 1_000_000_000_000_000_000; // Month 52
    _coinDistribution['Staking'][_Jan_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 53
    _coinDistribution['Staking'][_Feb_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 54
    _coinDistribution['Staking'][_Mar_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 55
    _coinDistribution['Staking'][_Apr_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 56
    _coinDistribution['Staking'][_May_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 57
    _coinDistribution['Staking'][_Jun_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 58
    _coinDistribution['Staking'][_Jul_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 59
    _coinDistribution['Staking'][_Aug_16_2026]=  1_200_000  * 1_000_000_000_000_000_000; // Month 60
  }

  /**
   * Transfer to 4 addresses when contract are created 
   */
  function _initialTransfer() private{
    _transfer(address(this), 0x467db17EbC0FB29510a63B31332446C92DFF44fE, 16_200_000 * 1_000_000_000_000_000_000); // PrivateSale
    _transfer(address(this), 0xDC6FC5e0111dBdC6111AdF2ca11B7C4F234d49C6, 2_700_000 * 1_000_000_000_000_000_000); // IDO
    _transfer(address(this), 0x9CC234DE2CF4b0C9a1C64Bb3E4f96d6aa1176698, 2_700_000 * 1_000_000_000_000_000_000); // Liquidity
    _transfer(address(this), 0xA71B91f139Fc59C22b4c7DC91CDFdaadAEB10E0C, 13_500_000 * 1_000_000_000_000_000_000); // BLaunchPad
  }

  /**
   * Modifiers
   */
  modifier onlyAdmin() { // Is Admin?
    require(_admin == msg.sender);
    _;
  }

  modifier hasPreSale1ContractNotYetSet() { // Has preSale1 Contract set?
    require(_hasPreSale1ContractNotYetSet);
    _;
  }

  modifier hasPreSale2ContractNotYetSet() { // Has preSale2 Contract set?
    require(_hasPreSale2ContractNotYetSet);
    _;
  }

  modifier isPreSale1Contract() { // Is preSale1 the contract that is currently interact with this contract?
    require(msg.sender == _preSale1Contract);
    _;
  }

  modifier isPreSale2Contract() { // Is preSale2 the contract that is currently interact with this contract?
    require(msg.sender == _preSale2Contract);
    _;
  }

  modifier whenPaused() { // Is pause?
    require(_isPaused, "Pausable: not paused Erc20");
    _;
  }

  modifier whenNotPaused() { // Is not pause? 
    require(!_isPaused, "Pausable: paused Erc20");
    _;
  }

  // Transfer ownernship
  function transferOwnership(address payable admin) external onlyAdmin {
    require(admin != address(0), "Zero address");
    _admin = admin;
  }

  /**
   * Update external contract functions
   */
  function setPreSale1ContractNotYetSet(address preSale1Contract) external onlyAdmin hasPreSale1ContractNotYetSet {
    require(preSale1Contract != address(0), "Zero address");
    _preSale1Contract = preSale1Contract;
    _hasPreSale1ContractNotYetSet = false;
  }

  function setPreSale2ContractNotYetSet(address preSale2Contract) external onlyAdmin hasPreSale2ContractNotYetSet {
    require(preSale2Contract != address(0), "Zero address");
    _preSale2Contract = preSale2Contract;
    _hasPreSale2ContractNotYetSet = false;
  }

  /**
   * ERC20 functions
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint){
    return _balances[account];
  }

  function transfer(address recipient, uint amount) external virtual override returns (bool){
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external virtual override view returns (uint){
    return _allowances[owner][spender];
  }

  function approve(address spender, uint amount) external virtual override returns (bool){
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint amount) external virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
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
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  function _transfer(address sender, address recipient, uint amount ) internal virtual {
    require(!_isPaused, "ERC20Pausable: token transfer while paused");
    require(!_isPausedAddress[sender], "ERC20Pausable: token transfer while paused on address");
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(recipient != address(this), "ERC20: transfer to the token contract address");

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * External contract transfer functions
   */
  // Allow preSale1 external contract to trigger transfer function
  function transferPresale1(address recipient, uint amount) external isPreSale1Contract returns (bool) {
    require(_preSale1AmountCap.sub(amount) >= 0, 'No more amount allocates for preSale1');
    _preSale1AmountCap = _preSale1AmountCap.sub(amount);
    _transfer(address(this), recipient, amount);
    return true;
  }

  // Allow preSale2 external contract to trigger transfer function
  function transferPresale2(address recipient, uint amount) external isPreSale2Contract returns (bool) {
    require(_preSale2AmountCap.sub(amount) >= 0,  'No more amount allocates for preSale2');
    _preSale2AmountCap = _preSale2AmountCap.sub(amount);
    _transfer(address(this), recipient, amount);
    return true;
  }

  /**
   * Local contract categories transfer function
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

            if(canTransfer){
              _coinDistributionStatus[_categories[i]][_dates[y]][amount] = true;
            }
          }
        }
      }
    }
  }

  function _categoriesTransfer(address recipient, uint amount, string memory categories) private returns (bool){
    if (_categoriesAmountCap[categories] < amount) {
      emit OutOfMoney(categories);
      return false;
    }
    _categoriesAmountCap[categories] = _categoriesAmountCap[categories].sub(amount);
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