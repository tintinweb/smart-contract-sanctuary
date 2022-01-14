/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IBEP20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: BSC Testnet
     * Aggregator: BUSD / ETH
     * Address: 0x5ea7D6A33D3655F661C298ac8086708148883c34
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}

contract SeekCoinBNBReward is PriceConsumerV3 {
    using SafeMath for uint256;

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 remaining_bonus;
    }

    address payable public owner1;
    address payable public owner2;
    address payable public owner3;

    mapping(address => User) public users;
    uint256[] public cycles;
    uint8[15] public ref_bonuses;
    uint256 public constant INVEST_MIN_AMOUNT = 100e18;
    uint256 public constant BASE_PERCENT = 10;
    uint256[2] public REFERRAL_PERCENTS = [100, 50];
    uint256 public owners_fee = 50; // 5%
    uint256 public owner3_fee = 100; // 10%
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public TIME_STEP = 24 hours;

    // Totals
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event MatchPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    modifier onlyOwner() {
        require(
            owner3 == payable(msg.sender),
            "Ownable: caller is not the owner"
        );
        _;
    }

    constructor(
        address payable _owner1,
        address payable _owner2,
        address payable _owner3
    ) {
        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;

        for (uint256 i = 0; i < ref_bonuses.length; i++) {
            if (i < 10) {
                ref_bonuses[i] = 6;
            } else {
                ref_bonuses[i] = 8;
            }
        }

        cycles.push(5000e18);
        cycles.push(10000e18);
        cycles.push(20000e18);
        cycles.push(40000e18);
    }

    function getBNB(uint256 _value) public view returns (uint256) {
        return (uint256(getLatestPrice()).mul(_value)).div(1e18);
    }

    function getUsdt(uint256 _value) public view returns (uint256) {
        return (_value.mul(1e18).div(uint256(getLatestPrice())));
    }

    receive() external payable {}

    function _setUpline(address _addr, address _upline) private {
        if (
            users[_addr].upline == address(0) &&
            _upline != _addr &&
            _addr != owner3 &&
            (users[_upline].deposit_time > 0 || _upline == owner3)
        ) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            total_users++;

            for (uint8 i = 0; i < ref_bonuses.length; i++) {
                if (_upline == address(0)) break;

                users[_upline].total_structure++;
                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address payable _addr, uint256 _amount) private {
        require(
            users[_addr].upline != address(0) || _addr == owner3,
            "No upline"
        );

        if (users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(
                users[_addr].payouts >=
                    this.maxPayoutOf(users[_addr].deposit_amount),
                "Deposit already exists"
            );

            require(
                msg.value >= users[_addr].deposit_amount &&
                    _amount <=
                    cycles[
                        users[_addr].cycle > cycles.length - 1
                            ? cycles.length - 1
                            : users[_addr].cycle
                    ],
                "Bad amount"
            );
        } else
            require(
                _amount >= INVEST_MIN_AMOUNT && _amount <= cycles[0],
                "Bad amount"
            );

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = msg.value;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += msg.value;

        total_deposited += msg.value;
        emit NewDeposit(_addr, msg.value);

        // if (users[_addr].upline != address(0)) {
        address _upline = users[_addr].upline;
        for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (_upline != address(0)) {
                users[_upline].direct_bonus += msg
                    .value
                    .mul(REFERRAL_PERCENTS[i])
                    .div(PERCENTS_DIVIDER);
                _upline = users[_upline].upline;
                emit DirectPayout(
                    users[_addr].upline,
                    _addr,
                    msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER)
                );
            } else {
                owner3.transfer(
                    msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER)
                );
                emit DirectPayout(
                    users[_addr].upline,
                    owner3,
                    msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER)
                );
            }
        }
        // }

        owner1.transfer(
            (msg.value.mul(owners_fee).div(PERCENTS_DIVIDER)).div(2)
        );
        owner2.transfer(
            (msg.value.mul(owners_fee).div(PERCENTS_DIVIDER)).div(2)
        );
        owner3.transfer(msg.value.mul(owner3_fee).div(PERCENTS_DIVIDER));
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            // if (up == address(0)) break;

            if (users[up].referrals >= i + 1 || users[up].referrals >= 10) {
                uint256 bonus = (_amount * ref_bonuses[i]) / 100;

                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            } else {
                uint256 bonus = (_amount * ref_bonuses[i]) / 100;
                payable(owner3).transfer(bonus);
                emit MatchPayout(owner3, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function deposit(address _upline) external payable {
        _setUpline(msg.sender, _upline);

        uint256 _amount = getUsdt(msg.value);
        _deposit(payable(msg.sender), _amount);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if (to_payout > 0) {
            if (users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }
        }

        // Direct payout
        if (
            users[msg.sender].payouts < max_payout &&
            users[msg.sender].direct_bonus > 0
        ) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            // if (users[msg.sender].payouts + direct_bonus > max_payout) {
            //     direct_bonus = max_payout - users[msg.sender].payouts;
            // }

            users[msg.sender].direct_bonus -= direct_bonus;
            // users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Match payout
        if (
            users[msg.sender].payouts < max_payout &&
            users[msg.sender].match_bonus > 0
        ) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            // if (users[msg.sender].payouts + match_bonus > max_payout) {
            //     match_bonus = max_payout - users[msg.sender].payouts;
            // }

            users[msg.sender].match_bonus -= match_bonus;
            // users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        // Remaining
        to_payout += users[msg.sender].remaining_bonus;
        users[msg.sender].remaining_bonus = 0;

        require(to_payout > 0, "Zero payout");

        if (users[msg.sender].payouts + to_payout > max_payout) {
            users[msg.sender].remaining_bonus =
                to_payout -
                (max_payout - users[msg.sender].payouts);
            to_payout = max_payout - users[msg.sender].payouts;
        }

        // 6% to distribute to unilevels.
        _refPayout(msg.sender, to_payout.mul(6).div(100));

        // distribute 4% to admins.
        owner1.transfer(to_payout.mul(2).div(100));
        owner2.transfer(to_payout.mul(2).div(100));

        payable(msg.sender).transfer(to_payout.mul(90).div(100));
        total_withdraw += to_payout;
        users[msg.sender].total_payouts += to_payout;
        users[msg.sender].deposit_payouts += to_payout;
        users[msg.sender].payouts += to_payout;
        users[msg.sender].deposit_time = block.timestamp;

        emit Withdraw(msg.sender, to_payout);
        if (users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    function maxPayoutOf(uint256 _amount) external pure returns (uint256) {
        return (_amount * 21) / 10;
    }

    function payoutOf(address _addr)
        external
        view
        returns (uint256 payout, uint256 max_payout)
    {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if (users[_addr].deposit_payouts < max_payout) {
            payout = ((users[_addr].deposit_amount *
                (block.timestamp - users[_addr].deposit_time)) /
                TIME_STEP /
                100);

            if (users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function syncData(
        address userAdd,
        address ref,
        uint256[12] memory userData
    ) external onlyOwner {
        users[userAdd].upline = ref;
        users[userAdd].cycle = userData[0];
        users[userAdd].referrals = userData[1];
        users[userAdd].payouts = userData[2];
        users[userAdd].direct_bonus = userData[3];
        users[userAdd].match_bonus = userData[4];
        users[userAdd].deposit_amount = userData[5];
        users[userAdd].deposit_payouts = userData[6];
        users[userAdd].deposit_time = userData[7];
        users[userAdd].total_deposits = userData[8];
        users[userAdd].total_payouts = userData[9];
        users[userAdd].total_structure = userData[10];
        users[userAdd].remaining_bonus = userData[11];
    }

    function updateAdmins(
        address _owner1,
        address _owner2,
        address _owner3
    ) public onlyOwner {
        owner1 = payable(_owner1);
        owner2 = payable(_owner2);
        owner3 = payable(_owner3);
    }

    function updateAdminFees(uint256 _owner3_fee, uint256 _owners_fee)
        public
        onlyOwner
    {
        owner3_fee = _owner3_fee;
        owners_fee = _owners_fee;
    }

    function updateChainDataFeedAddress(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function updateTimeStep(uint256 duration) public onlyOwner {
        TIME_STEP = duration;
    }

    /*
        Only external call
    */
    function userInfo(address _addr)
        external
        view
        returns (
            address upline,
            uint256 deposit_time,
            uint256 deposit_amount,
            uint256 payouts,
            uint256 direct_bonus,
            uint256 match_bonus,
            uint256 remaining_bonus
        )
    {
        return (
            users[_addr].upline,
            users[_addr].deposit_time,
            users[_addr].deposit_amount,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].match_bonus,
            users[_addr].remaining_bonus
        );
    }

    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 referrals,
            uint256 total_deposits,
            uint256 total_payouts,
            uint256 total_structure
        )
    {
        return (
            users[_addr].referrals,
            users[_addr].total_deposits,
            users[_addr].total_payouts,
            users[_addr].total_structure
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdraw
        )
    {
        return (total_users, total_deposited, total_withdraw);
    }

    function getContractBalance() public view returns (uint256) {
        return (address(this).balance);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}