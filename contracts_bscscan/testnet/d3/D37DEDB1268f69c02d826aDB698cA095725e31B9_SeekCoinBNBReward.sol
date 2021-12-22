/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

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

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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
            0x5ea7D6A33D3655F661C298ac8086708148883c34
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
    IBEP20 public seekcoin;

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
        bool isTradedWithToken;
    }

    address payable public owner;
    address payable public admin;

    mapping(address => User) public users;
    uint256[] public cycles;
    uint8[15] public ref_bonuses;
    uint256 public constant INVEST_MIN_AMOUNT = 100e18;
    uint256 public constant BASE_PERCENT = 10;
    uint256[2] public REFERRAL_PERCENTS = [100, 50];
    uint256 public admin_fee = 50; // 5%
    uint256 public project_fee = 100; // 10%
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public TIME_STEP = 10 seconds;
    uint256 public pricePerToken = 1e19; // divider

    // Totals
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_deposited_tokens;
    uint256 public total_withdraw;
    uint256 public total_withdraw_tokens;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(
        address indexed addr,
        uint256 amount,
        bool _isTradedWithToken
    );
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
        require(owner == payable(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    constructor(
        address payable _owner,
        address payable _admin,
        address tokenAddress
    ) {
        owner = _owner;
        admin = _admin;
        seekcoin = IBEP20(tokenAddress);

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

    receive() external payable {
        _deposit(payable(msg.sender), msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if (
            users[_addr].upline == address(0) &&
            _upline != _addr &&
            _addr != owner &&
            (users[_upline].deposit_time > 0 || _upline == owner)
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
            users[_addr].upline != address(0) || _addr == owner,
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
        emit NewDeposit(_addr, msg.value, false);

        if (users[_addr].upline != address(0)) {
            address _upline = users[_addr].upline;
            uint256 directBonus;
            for(uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if(_upline != address(0)) {
                    // if(users[_upline].isTradedWithToken){
                    //     directBonus = usdtToTokens(getUsdt(msg.value)).mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    // } else{
                    directBonus = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[_upline].direct_bonus += directBonus;
                    // }
                    
                    _upline = users[_upline].upline;
                    emit DirectPayout(users[_addr].upline, _addr, directBonus);                                    
                }
            }
        }

        admin.transfer(msg.value.mul(admin_fee).div(PERCENTS_DIVIDER));
        owner.transfer(
            msg.value.mul(project_fee).div(PERCENTS_DIVIDER)
        );
    }

    function _depositWithToken(address _addr, uint256 _amount) private {
        require(
            users[_addr].upline != address(0) || _addr == owner,
            "No upline"
        );

        if (users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(
                users[_addr].payouts >=
                    this.maxPayoutOf(users[_addr].deposit_amount),
                "Deposit already exists"
            );

            if(!users[_addr].isTradedWithToken){
                require(
                    _amount >= getUsdt(users[_addr].deposit_amount) &&
                        _amount <=
                        cycles[
                            users[_addr].cycle > cycles.length - 1
                                ? cycles.length - 1
                                : users[_addr].cycle
                        ],
                    "Bad amount"
                );
            } else{
                require(
                    _amount >= users[_addr].deposit_amount &&
                        _amount <=
                        cycles[
                            users[_addr].cycle > cycles.length - 1
                                ? cycles.length - 1
                                : users[_addr].cycle
                        ],
                    "Bad amount"
                );
            }
            
        } else
            require(
                _amount >= INVEST_MIN_AMOUNT && _amount <= cycles[0],
                "Bad amount"
            );

        _amount = _amount.mul(10);
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].isTradedWithToken = true;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited_tokens += _amount;
        emit NewDeposit(_addr, _amount, true);

        if (users[_addr].upline != address(0)) {
            address _upline = users[_addr].upline;
            uint256 directBonus;
            for(uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if(_upline != address(0)) {
                    // if(users[_upline].isTradedWithToken){
                    directBonus = getBNB(tokenToUsdt(_amount)).mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    // } else{
                    //     directBonus = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    // }

                    users[_upline].direct_bonus += directBonus;
                    _upline = users[_upline].upline;
                    emit DirectPayout(users[_addr].upline, _addr, _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER));                                    
                }
            }
        }

        uint256 depsitingAmount = _amount
            .sub(_amount.mul(admin_fee).div(PERCENTS_DIVIDER))
            .sub(_amount.mul(project_fee).div(PERCENTS_DIVIDER));

        seekcoin.transferFrom(
            msg.sender,
            admin,
            _amount.mul(admin_fee).div(PERCENTS_DIVIDER)
        );
        seekcoin.transferFrom(
            msg.sender,
            owner,
            _amount.mul(project_fee).div(PERCENTS_DIVIDER)
        );

        seekcoin.transferFrom(msg.sender, address(this), depsitingAmount);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0)) break;

            if (users[up].referrals >= i + 1) {
                uint256 bonus = (_amount * ref_bonuses[i]) / 100;

                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function deposit(
        address _upline,
        uint256 _amount,
        bool _tradeWithCoin
    ) external payable {
        _setUpline(msg.sender, _upline);
        if (!_tradeWithCoin) {
            _amount = getUsdt(msg.value);
            _deposit(payable(msg.sender), _amount);
        } else {
            _depositWithToken(msg.sender, _amount);
        }
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
            if(users[msg.sender].isTradedWithToken){
                direct_bonus = usdtToTokens(getUsdt(direct_bonus));
            }

            if (users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

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
            if(users[msg.sender].isTradedWithToken){
                match_bonus = usdtToTokens(getUsdt(match_bonus));
            }

            if (users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            // users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].total_payouts += to_payout;

        users[msg.sender].deposit_payouts += to_payout;
        users[msg.sender].payouts += to_payout;
        // get 10% from total
        uint256 tenPercent = to_payout.div(10);
        // 60% to of 10% will distribute to unilevels.
        _refPayout(msg.sender, tenPercent.mul(6).div(10));

        to_payout = to_payout.sub(tenPercent);
        if (users[msg.sender].isTradedWithToken) {
            total_withdraw += to_payout.add(tenPercent);
            seekcoin.transfer(msg.sender, to_payout);

            // distribute 40% of 10% to admins.
            seekcoin.transfer(
                admin,
                tenPercent.mul(2).div(10)
            );
            seekcoin.transfer(
                owner,
                tenPercent.mul(2).div(10)
            );
        } else {
            total_withdraw_tokens += to_payout.add(tenPercent);
            payable(msg.sender).transfer(to_payout);

            // distribute 40% of 10% to admins.
            admin.transfer(to_payout.mul(2).div(10));
            owner.transfer(to_payout.mul(2).div(10));
        }

        emit Withdraw(msg.sender, to_payout);
        if (users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    function tokenToUsdt(uint256 _noOfTokens) public view returns(uint256) {
        return _noOfTokens.mul(1e18).div(pricePerToken);
    }

    function usdtToTokens(uint256 _usdt) public view returns(uint256) {
        return (_usdt.mul(pricePerToken)).div(1e18);
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
            payout =
                ((users[_addr].deposit_amount *
                    (block.timestamp - users[_addr].deposit_time)) /
                    TIME_STEP /
                    100) -
                users[_addr].deposit_payouts;

            if (users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function updateAdmins(address _owner, address _admin)
        public
        onlyOwner
    {
        owner = payable(_owner);
        admin = payable(_admin);
    }

    function setTokenPricePerUsdt(uint256 _price) public onlyOwner {
        pricePerToken = _price;
    }

    function updateAdminFees(uint256 _admin_fee, uint256 _project_fee)
        public
        onlyOwner
    {
        admin_fee = _admin_fee;
        project_fee = _project_fee;
    }

    function updateChainDataFeedAddress(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function withdrawBNB() public onlyOwner {
        (bool success, ) = admin.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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
            uint256 match_bonus
        )
    {
        return (
            users[_addr].upline,
            users[_addr].deposit_time,
            users[_addr].deposit_amount,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].match_bonus
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