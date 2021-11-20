/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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

contract LoaToken is IERC20 {
    uint private constant eighteen_decimals_value = 1_000_000_000_000_000_000;
    // ERC20 variables
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply = 1_000_000_000 * eighteen_decimals_value;

    // General variables
    string public constant name = "League Of Ancients";
    string public constant symbol = "LOA";
    uint8 public constant decimals = 18;
    address public _admin;

    // External contract general variables
    uint _preSaleAmountCap = 2_000_000 * eighteen_decimals_value;
    address public _preSaleContract;
    bool public _hasPreSaleContractNotYetSet = true;

    // Utility variables
    bool public _isPaused;
    mapping(address => bool) public _isPausedAddress;

    // Daily date variable
    uint public constant _DEC_12_2021 = 1_639_267_200; // first day

    // Monthly date variables
    uint public constant _Apr_12_2022 = 1_649_721_600;
    uint public constant _May_12_2022 = 1_652_313_600;
    uint public constant _Jun_12_2022 = 1_654_992_000;
    uint public constant _Jul_12_2022 = 1_657_584_000;
    uint public constant _Aug_12_2022 = 1_660_262_400;
    uint public constant _Sep_12_2022 = 1_662_940_800;
    uint public constant _Oct_12_2022 = 1_665_532_800;
    uint public constant _Nov_12_2022 = 1_668_211_200;
    uint public constant _Dec_12_2022 = 1_670_803_200;
    uint public constant _Jan_12_2023 = 1_673_481_600;
    uint public constant _Feb_12_2023 = 1_676_160_000;
    uint public constant _Mar_12_2023 = 1_678_579_200;
    uint public constant _Apr_12_2023 = 1_681_257_600;
    uint public constant _May_12_2023 = 1_683_849_600;
    uint public constant _Jun_12_2023 = 1_686_528_000;
    uint public constant _Jul_12_2023 = 1_689_120_000;
    uint public constant _Aug_12_2023 = 1_691_798_400;
    uint public constant _Sep_12_2023 = 1_694_476_800;
    uint public constant _Oct_12_2023 = 1_697_068_800;
    uint public constant _Nov_12_2023 = 1_699_747_200;
    uint public constant _Dec_12_2023 = 1_702_339_200;
    uint public constant _Jan_12_2024 = 1_705_017_600;
    uint public constant _Feb_12_2024 = 1_707_696_000;
    uint public constant _Mar_12_2024 = 1_710_201_600;
    uint public constant _Apr_12_2024 = 1_712_880_000;
    uint public constant _May_12_2024 = 1_715_472_000;
    uint public constant _Jun_12_2024 = 1_718_150_400;
    uint public constant _Jul_12_2024 = 1_720_742_400;
    uint public constant _Aug_12_2024 = 1_723_420_800;
    uint public constant _Sep_12_2024 = 1_726_099_200;
    uint public constant _Oct_12_2024 = 1_728_691_200;
    uint public constant _Nov_12_2024 = 1_731_369_600;
    uint public constant _Dec_12_2024 = 1_733_961_600;
    uint public constant _Jan_12_2025 = 1_736_640_000;
    uint public constant _Feb_12_2025 = 1_739_318_400;
    uint public constant _Mar_12_2025 = 1_741_737_600;
    uint public constant _Apr_12_2025 = 1_744_416_000;
    uint public constant _May_12_2025 = 1_747_008_000;
    uint public constant _Jun_12_2025 = 1_749_686_400;
    uint public constant _Jul_12_2025 = 1_752_278_400;
    uint public constant _Aug_12_2025 = 1_754_956_800;
    uint public constant _Sep_12_2025 = 1_757_635_200;
    uint public constant _Oct_12_2025 = 1_760_227_200;
    uint public constant _Nov_12_2025 = 1_762_905_600;
    uint public constant _Dec_12_2025 = 1_765_497_600;
    uint public constant _Jan_12_2026 = 1_768_176_000;
    uint public constant _Feb_12_2026 = 1_770_854_400;
    uint public constant _Mar_12_2026 = 1_773_273_600;
    uint public constant _Apr_12_2026 = 1_775_952_000;
    uint public constant _May_12_2026 = 1_778_544_000;
    uint public constant _Jun_12_2026 = 1_781_222_400;
    uint public constant _Jul_12_2026 = 1_783_814_400;
    uint public constant _Aug_12_2026 = 1_786_492_800;
    uint public constant _Sep_12_2026 = 1_789_171_200;
    uint public constant _Oct_12_2026 = 1_791_763_200;
    uint public constant _Nov_12_2026 = 1_794_441_600;
    uint public constant _Dec_12_2026 = 1_797_033_600;

    uint[] public _monthlyDates; // The cutoff monthly dates that allow coin distribution
    mapping(string => uint) public _categoriesAmountCap; // The maximum amount allowed to be transfer (Category => Cap)
    mapping(string => address) public _categoriesAddress; // Address for categories (Category => Address)
    //mapping(string => mapping(uint => uint)) public _dailyCoinDistribution; // Daily coin distribution schedule (Category => Unix Date => Amount)
    mapping(string => mapping(uint => uint)) public _monthlyCoinDistribution; // Monthly coin distribution schedule (Category => Unix Date => Amount)

    uint public _dailyIndex;
    mapping(string => uint) public _dailyCategoryIndex;

    event OutOfMoney(string category);  // emit when `_categoriesAmountCap` less than required amount.

    constructor() {
        _admin = msg.sender;
        _balances[address(this)] = _totalSupply;

        // Add all addresses
        _categoriesAddress['Advisors1'] = 0x1603D3434EE2524A2FaDdab60e95e1bD5BA76F4B;
        _categoriesAddress['Advisors2'] = 0xdD24FF868adbE8EaE203C9F1DF5E3A12081fc1DB;
        _categoriesAddress['Advisors3'] = 0x359106314706b046DB9b097674178617f12A1D3F;
        _categoriesAddress['Advisors4'] = 0x036007a6778E77A0cF94352631A6Ab344d313870;
        _categoriesAddress['Team'] = 0xC1344ab0a8f8abD173c43ad848E78164B5D4BC61;
        _categoriesAddress['Marketing'] = 0xe60035673BAFDaD24C5B14E9556F5793dFFb3362;
        _categoriesAddress['EcosystemFund'] = 0xf481B312D6c4ddED5f9651DF6625E28b22815932;
        _categoriesAddress['PlayToEarn'] = 0xA94db241cf64aaE7A4D1f8C7cCcb346927831CFB;
        _categoriesAddress['Staking'] = 0xd19BE18E232b879F400502E3bD91c01648EDa7f2;
        _categoriesAddress['NFTStaking'] = 0xF8378354e4c09722a588630f86AB25b0c095179E;
        _setDefaultValues();
        _initialTransfer();
        _setMonthlyDistribution();
        //_setMonthlyDistributionTesting();
    }

//    constructor(
//        address advisors1Address,
//        address advisors2Address,
//        address advisors3Address,
//        address advisors4Address,
//        address teamAddress,
//        address marketingAddress,
//        address ecosystemFundAddress,
//        address playToEarnAddress,
//        address stakingAddress,
//        address nftStakingAddress
//    ) {
//        _admin = msg.sender;
//        _balances[address(this)] = _totalSupply;
//
//        // Add all addresses
//        _categoriesAddress['Advisors1'] = advisors1Address;
//        _categoriesAddress['Advisors2'] = advisors2Address;
//        _categoriesAddress['Advisors3'] = advisors3Address;
//        _categoriesAddress['Advisors4'] = advisors4Address;
//        _categoriesAddress['Team'] = teamAddress;
//        _categoriesAddress['Marketing'] = marketingAddress;
//        _categoriesAddress['EcosystemFund'] = ecosystemFundAddress;
//        _categoriesAddress['PlayToEarn'] = playToEarnAddress;
//        _categoriesAddress['Staking'] = stakingAddress;
//        _categoriesAddress['NFTStaking'] = nftStakingAddress;
//        _setDefaultValues();
//        _initialTransfer();
//        //_setMonthlyDistribution();
//        _setMonthlyDistributionTesting();
//    }

    function _setDefaultValues() private {
        // Add all monthly dates
        _monthlyDates.push(_Apr_12_2022);
        _monthlyDates.push(_May_12_2022);
        _monthlyDates.push(_Jun_12_2022);
        _monthlyDates.push(_Jul_12_2022);
        _monthlyDates.push(_Aug_12_2022);
        _monthlyDates.push(_Sep_12_2022);
        _monthlyDates.push(_Oct_12_2022);
        _monthlyDates.push(_Nov_12_2022);
        _monthlyDates.push(_Dec_12_2022);
        _monthlyDates.push(_Jan_12_2023);
        _monthlyDates.push(_Feb_12_2023);
        _monthlyDates.push(_Mar_12_2023);
        _monthlyDates.push(_Apr_12_2023);
        _monthlyDates.push(_May_12_2023);
        _monthlyDates.push(_Jun_12_2023);
        _monthlyDates.push(_Jul_12_2023);
        _monthlyDates.push(_Aug_12_2023);
        _monthlyDates.push(_Sep_12_2023);
        _monthlyDates.push(_Oct_12_2023);
        _monthlyDates.push(_Nov_12_2023);
        _monthlyDates.push(_Dec_12_2023);
        _monthlyDates.push(_Jan_12_2024);
        _monthlyDates.push(_Feb_12_2024);
        _monthlyDates.push(_Mar_12_2024);
        _monthlyDates.push(_Apr_12_2024);
        _monthlyDates.push(_May_12_2024);
        _monthlyDates.push(_Jun_12_2024);
        _monthlyDates.push(_Jul_12_2024);
        _monthlyDates.push(_Aug_12_2024);
        _monthlyDates.push(_Sep_12_2024);
        _monthlyDates.push(_Oct_12_2024);
        _monthlyDates.push(_Nov_12_2024);
        _monthlyDates.push(_Dec_12_2024);
        _monthlyDates.push(_Jan_12_2025);
        _monthlyDates.push(_Feb_12_2025);
        _monthlyDates.push(_Mar_12_2025);
        _monthlyDates.push(_Apr_12_2025);
        _monthlyDates.push(_May_12_2025);
        _monthlyDates.push(_Jun_12_2025);
        _monthlyDates.push(_Jul_12_2025);
        _monthlyDates.push(_Aug_12_2025);
        _monthlyDates.push(_Sep_12_2025);
        _monthlyDates.push(_Oct_12_2025);
        _monthlyDates.push(_Nov_12_2025);
        _monthlyDates.push(_Dec_12_2025);
        _monthlyDates.push(_Jan_12_2026);
        _monthlyDates.push(_Feb_12_2026);
        _monthlyDates.push(_Mar_12_2026);
        _monthlyDates.push(_Apr_12_2026);
        _monthlyDates.push(_May_12_2026);
        _monthlyDates.push(_Jun_12_2026);
        _monthlyDates.push(_Jul_12_2026);
        _monthlyDates.push(_Aug_12_2026);
        _monthlyDates.push(_Sep_12_2026);
        _monthlyDates.push(_Oct_12_2026);
        _monthlyDates.push(_Nov_12_2026);
        _monthlyDates.push(_Dec_12_2026);

        // Add all amount cap
        _categoriesAmountCap['Advisors1'] = 10_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['Advisors2'] = 10_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['Advisors3'] = 10_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['Advisors4'] = 10_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['Team'] = 200_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['Marketing'] = 50_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['EcosystemFund'] = 30_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['NFTStaking'] = 80_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['Staking'] = 150_000_000 * eighteen_decimals_value;
        _categoriesAmountCap['PlayToEarn'] = 250_000_000 * eighteen_decimals_value;
    }
    /*
        function setDailyDistribution(uint number) external onlyAdmin {
            uint i = _dailyIndex;
            uint last = i + number;
            if(last > 1827) last = 1827;

            for (; i < last; i++) {
                uint date = _DEC_12_2021 + 86400 * i;

                if(i < 1826){
                    _dailyCoinDistribution['Advisors1'][date] = 5_476 * eighteen_decimals_value;
                    _dailyCoinDistribution['Advisors2'][date] = 5_476 * eighteen_decimals_value;
                    _dailyCoinDistribution['Advisors3'][date] = 5_476 * eighteen_decimals_value;
                    _dailyCoinDistribution['Advisors4'][date] = 5_476 * eighteen_decimals_value;
                    _dailyCoinDistribution['Team'][date] = 109_529 * eighteen_decimals_value;
                }

                if(i == 1826) {
                    date = _DEC_12_2021 + 86400 * 1826;
                    _dailyCoinDistribution['Advisors1'][date] = 824 * eighteen_decimals_value;
                    _dailyCoinDistribution['Advisors2'][date] = 824 * eighteen_decimals_value;
                    _dailyCoinDistribution['Advisors3'][date] = 824 * eighteen_decimals_value;
                    _dailyCoinDistribution['Advisors4'][date] = 824 * eighteen_decimals_value;
                    _dailyCoinDistribution['Team'][date] = 46;
                }

                if(i < 1095){
                    date = _DEC_12_2021 + 86400 * i;
                    _dailyCoinDistribution['Marketing'][date] = 45_662 * eighteen_decimals_value;
                }

                if(i == 1095){
                    date = _DEC_12_2021 + 86400 * 1095;
                    _dailyCoinDistribution['Marketing'][date] = 110 * eighteen_decimals_value;
                }
            }

            _dailyIndex = i;
        }
    */
    function _setMonthlyDistribution() private {
        _monthlyCoinDistribution['EcosystemFund'][_Jul_12_2022] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Aug_12_2022] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Sep_12_2022] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Oct_12_2022] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Nov_12_2022] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Dec_12_2022] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jan_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Feb_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Mar_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Apr_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_May_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jun_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jul_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Aug_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Sep_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Oct_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Nov_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Dec_12_2023] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jan_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Feb_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Mar_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Apr_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_May_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jun_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jul_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Aug_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Sep_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Oct_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Nov_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Dec_12_2024] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jan_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Feb_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Mar_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Apr_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_May_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jun_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jul_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Aug_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Sep_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Oct_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Nov_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Dec_12_2025] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jan_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Feb_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Mar_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Apr_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_May_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jun_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Jul_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Aug_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Sep_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Oct_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Nov_12_2026] = 555555 * eighteen_decimals_value;
        _monthlyCoinDistribution['EcosystemFund'][_Dec_12_2026] = 555585 * eighteen_decimals_value;
        _monthlyCoinDistribution['NFTStaking'][_Apr_12_2022] = 40000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['NFTStaking'][_Apr_12_2023] = 40000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_May_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jun_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jul_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Aug_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Sep_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Oct_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Nov_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Dec_12_2022] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jan_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Feb_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Mar_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Apr_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_May_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jun_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jul_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Aug_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Sep_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Oct_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Nov_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Dec_12_2023] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jan_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Feb_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Mar_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Apr_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_May_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jun_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jul_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Aug_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Sep_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Oct_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Nov_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Dec_12_2024] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jan_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Feb_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Mar_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Apr_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_May_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jun_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jul_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Aug_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Sep_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Oct_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Nov_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Dec_12_2025] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jan_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Feb_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Mar_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Apr_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_May_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jun_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Jul_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Aug_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Sep_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Oct_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Nov_12_2026] = 2678571 * eighteen_decimals_value;
        _monthlyCoinDistribution['Staking'][_Dec_12_2026] = 2678595 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Nov_12_2022] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Dec_12_2022] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jan_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Feb_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Mar_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Apr_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_May_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jun_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jul_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Aug_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Sep_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Oct_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Nov_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Dec_12_2023] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jan_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Feb_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Mar_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Apr_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_May_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jun_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jul_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Aug_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Sep_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Oct_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Nov_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Dec_12_2024] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jan_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Feb_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Mar_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Apr_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_May_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jun_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jul_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Aug_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Sep_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Oct_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Nov_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Dec_12_2025] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jan_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Feb_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Mar_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Apr_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_May_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jun_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Jul_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Aug_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Sep_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Oct_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Nov_12_2026] = 5000000 * eighteen_decimals_value;
        _monthlyCoinDistribution['PlayToEarn'][_Dec_12_2026] = 5000000 * eighteen_decimals_value;
    }

//    function _setMonthlyDistributionTesting() private {
//        _monthlyCoinDistribution['EcosystemFund'][_Jul_12_2022]=555555 * eighteen_decimals_value; // Day 213
//        _monthlyCoinDistribution['EcosystemFund'][_Aug_12_2022]=555555 * eighteen_decimals_value; // Day 244
//        _monthlyCoinDistribution['EcosystemFund'][_Sep_12_2022]=555555 * eighteen_decimals_value; // Day 275
//        _monthlyCoinDistribution['EcosystemFund'][_Oct_12_2022]=555555 * eighteen_decimals_value; // Day 305
//        _monthlyCoinDistribution['EcosystemFund'][_Dec_12_2026]=555585 * eighteen_decimals_value; // Day 367
//        _monthlyCoinDistribution['NFTStaking'][_Apr_12_2022] = 40000000 * eighteen_decimals_value;
//        _monthlyCoinDistribution['NFTStaking'][_Apr_12_2023] = 40000000 * eighteen_decimals_value;
//        _monthlyCoinDistribution['Staking'][_May_12_2022] = 2678571 * eighteen_decimals_value;
//        _monthlyCoinDistribution['Staking'][_Jun_12_2022] = 2678571 * eighteen_decimals_value;
//        _monthlyCoinDistribution['Staking'][_Jul_12_2022] = 2678571 * eighteen_decimals_value;
//        _monthlyCoinDistribution['Staking'][_Aug_12_2022] = 2678571 * eighteen_decimals_value;
//        _monthlyCoinDistribution['Staking'][_Sep_12_2022] = 2678571 * eighteen_decimals_value;
//        _monthlyCoinDistribution['PlayToEarn'][_Nov_12_2022] = 5000000 * eighteen_decimals_value;
//        _monthlyCoinDistribution['PlayToEarn'][_Dec_12_2022] = 5000000 * eighteen_decimals_value;
//        _monthlyCoinDistribution['PlayToEarn'][_Jan_12_2023] = 5000000 * eighteen_decimals_value;
//        _monthlyCoinDistribution['PlayToEarn'][_Feb_12_2023] = 5000000 * eighteen_decimals_value;
//    }
    /**
     * Transfer to 5 addresses when contract are created
     */
    function _initialTransfer() private{
        _transfer(address(this), 0x88f1412a3bBb4CDE458e16E9d919D2E2c044E259, 100_000_000 * eighteen_decimals_value); // Private Sale
        _transfer(address(this), 0x037049BCE97457e12c2Ba389623532175d942768, 18_000_000 * eighteen_decimals_value); // NFT Sale
        _transfer(address(this), 0x7dfEf096A4A84C76A4d456b096d4fcd6Cf09dFCc, 20_000_000 * eighteen_decimals_value); // Community
        _transfer(address(this), 0x62541f748aCCc888ae25091d71DffAF605cEAB99, 10_000_000 * eighteen_decimals_value); // Liquidity
        _transfer(address(this), 0x1cf7bfE0bfA35d9a0b92f4Ba359Ac74bD9f29EF8, 50_000_000 * eighteen_decimals_value); // CEX Reserve
    }

    /**
     * Modifiers
     */
    modifier onlyAdmin() { // Is Admin?
        require(_admin == msg.sender);
        _;
    }

    modifier hasPreSaleContractNotYetSet() { // Has preSale Contract set?
        require(_hasPreSaleContractNotYetSet);
        _;
    }

    modifier isPreSaleContract() { // Is preSale the contract that is currently interact with this contract?
        require(msg.sender == _preSaleContract);
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
    function setPreSaleContractNotYetSet(address preSaleContract) external onlyAdmin hasPreSaleContractNotYetSet {
        require(preSaleContract != address(0), "Zero address");
        _preSaleContract = preSaleContract;
        _hasPreSaleContractNotYetSet = false;
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender]-amount);
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint amount ) internal virtual {
        require(!_isPaused, "ERC20Pausable: token transfer while paused");
        require(!_isPausedAddress[sender], "ERC20Pausable: token transfer while paused on address");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(recipient != address(this), "ERC20: transfer to the token contract address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
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
     * Allow preSale external contract to trigger transfer function
     */

    function transferPresale(address recipient, uint amount) external isPreSaleContract returns (bool) {
        require(_preSaleAmountCap >= amount, 'No more amount allocates for preSale');
        _preSaleAmountCap = _preSaleAmountCap - amount;
        _transfer(address(this), recipient, amount);
        return true;
    }

    /**
     * Daily transfer
     * For advisors1, advisors2, advisors3, advisors4, team and marketing.
     */
    function dailyTransfer() external {
        require(block.timestamp >= _DEC_12_2021, "Too early for daily transfer");
        string memory category = '';
        uint dailyDistribution;

        if(_categoriesAddress['Advisors1'] == msg.sender){
            category = 'Advisors1';
            dailyDistribution = 5_476 * eighteen_decimals_value;
        } else if(_categoriesAddress['Advisors2'] == msg.sender){
            category = 'Advisors2';
            dailyDistribution = 5_476 * eighteen_decimals_value;
        } else if(_categoriesAddress['Advisors3'] == msg.sender){
            category = 'Advisors3';
            dailyDistribution = 5_476 * eighteen_decimals_value;
        } else if(_categoriesAddress['Advisors4'] == msg.sender){
            category = 'Advisors4';
            dailyDistribution = 5_476 * eighteen_decimals_value;
        } else if(_categoriesAddress['Team'] == msg.sender){
            category = 'Team';
            dailyDistribution = 109_529 * eighteen_decimals_value;
        } else if(_categoriesAddress['Marketing'] == msg.sender){
            category = 'Marketing';
            dailyDistribution = 45_662 * eighteen_decimals_value;
        }

        require(bytes(category).length > 0, 'Invalid sender address for daily transfer');

        uint amountLeft = _categoriesAmountCap[category];
        require (amountLeft > 0, "All amount was paid");
        uint maxDayToPay = amountLeft / dailyDistribution; // number of days that may be paid with dailyDistribution amount
        uint day = (block.timestamp - _DEC_12_2021) / 86400 + 1; // number of days to pay
        uint unpaidDays = day - _dailyCategoryIndex[category];  // number of days to pay - already paid days
        if (unpaidDays > maxDayToPay + 1) unpaidDays = maxDayToPay + 1;
        uint amount = unpaidDays * dailyDistribution;  // total amount to pay for passed days
        if (amount > amountLeft) amount = amountLeft;   // transfer all tokens that left
        if (amount > 0) {
            bool canTransfer = _categoriesTransfer(msg.sender, amount, category);
            if(canTransfer) {
                _dailyCategoryIndex[category] = day;    // store last paid day
            }
        }
    }

    /**
     * Monthly transfer
     * For EcosystemFund, PlayToEarn, Staking and NftStaking.
     */
    function monthlyTransfer() external {
        string memory category = '';

        if(_categoriesAddress['EcosystemFund'] == msg.sender){
            category = 'EcosystemFund';
        } else if(_categoriesAddress['PlayToEarn'] == msg.sender){
            category = 'PlayToEarn';
        } else if(_categoriesAddress['Staking'] == msg.sender){
            category = 'Staking';
        } else if(_categoriesAddress['NFTStaking'] == msg.sender){
            category = 'NFTStaking';
        }

        require(bytes(category).length > 0, 'Invalid sender address for monthly transfer');

        for (uint y = 0; y < _monthlyDates.length; y++) {
            if(block.timestamp >= _monthlyDates[y]) {
                uint amount = _monthlyCoinDistribution[category][_monthlyDates[y]];
                if(amount > 0){
                    bool canTransfer = _categoriesTransfer(msg.sender, amount, category);

                    if(canTransfer){
                        _monthlyCoinDistribution[category][_monthlyDates[y]]= 0;
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
        _categoriesAmountCap[categories] = _categoriesAmountCap[categories] - amount;
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