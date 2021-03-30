/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    function decimals() public view returns (uint256 digits);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract Ellufa {
    struct User {
        uint256 cycle;
        uint256 total_deposits;
        uint256 max_earnings;
        uint256 earnings_left;
        uint256 total_withdrawl;
        uint256 profitpayout;
        uint256 total_profitpayout;
        uint256 stakingpayout;
        uint256 total_stakingpayout;
        uint8 leader_status;
    }

    struct Merchant {
        uint256 total_payout;
        uint8 status;
    }

    struct Package {
        uint8 status;
        uint8 maxPayout;
    }

    using SafeMath for uint256;
    address payable public owner;
    address payable public companyaddress;
    address payable public usdt_address;

    address public node_address;

    uint256 public total_depositcount = 0;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_payout;
    uint256 public total_profit;
    uint256 public current_profit;
    uint256 public total_staked;
    uint256 public current_staked;
    uint8 public phaseversion;
    uint8 public tokendebit; // If disable its wont debit 20%
    uint256 public min_withdrawal; // Before live change to 6 digit
    uint8 public staking_status;
    uint8 public merchant_status;
    uint256 public multiplier;
    address public elft_address;
    uint8 public token_transfer_status;
    uint256 public token_price;
    uint8 public token_share;

    mapping(address => User) public users;

    mapping(address => Merchant) public merchants;

    mapping(uint256 => Package) public packages;

    event NewDeposit(address indexed addr, uint256 amount);
    event PayoutEvent(address indexed addr, uint256 payout, uint256 staking);
    event WithdrawEvent(address indexed addr, uint256 amount, uint256 service);
    event StakingEvent(address indexed addr, uint256 amount);
    event MerchantEvent(address indexed addr, uint256 amount);
    event ELFTTranEvent(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        multiplier = 1000000;

        companyaddress = 0xFE31Bf2345A531dD2A8E6c5444070248698171BF;

        usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        phaseversion = 1;

        tokendebit = 1;

        min_withdrawal = 100 * multiplier;

        staking_status = 0;

        merchant_status = 0;

        token_share = 20;

        packages[1000 * multiplier].status = 1;
        packages[1000 * multiplier].maxPayout = 2;
    }

    function initDeposit() external {
        ERC20 tc = ERC20(usdt_address);

        require(users[msg.sender].earnings_left == 0, "MAX CAP NOT REACHED");

        require(
            tc.allowance(msg.sender, address(this)) > 0,
            "USDT APPROVAL FAILED"
        );

        uint256 _amount = tc.allowance(msg.sender, address(this));

        require(
            tc.transferFrom(msg.sender, address(this), _amount),
            "DEBIT FROM USDT FAILED"
        );

    
        uint256 company_fee = _amount.div(100).mul(10);

        tc.transfer(companyaddress, company_fee);

        uint256 token_fee = _amount.div(100).mul(token_share);

        if (tokendebit == 1) {
            tc.transfer(companyaddress, token_fee);
        } else {
            //Phase 2 Added to staking
            users[msg.sender].stakingpayout = users[msg.sender]
                .stakingpayout
                .add(token_fee);

            users[msg.sender].total_stakingpayout = users[msg.sender]
                .total_stakingpayout
                .add(token_fee);

            total_staked = total_staked.add(token_fee);
            current_staked = current_staked.add(token_fee);
        }

        uint256 mxpayout = maxPayoutof(_amount);

        users[msg.sender].cycle++;
        total_depositcount++;
        total_deposited += _amount;
        users[msg.sender].total_deposits += _amount;
        users[msg.sender].max_earnings += mxpayout;
        users[msg.sender].earnings_left += mxpayout;

        emit NewDeposit(msg.sender, _amount);

        
    }

    function maxPayoutof(uint256 _amount) private view returns (uint256) {
        uint8 maxtimes = packages[_amount].maxPayout;

        return _amount * maxtimes;
    }

    function addNodeAddress(address _addr) external {
        require(msg.sender == owner, "OWNER ONLY");

        node_address = _addr;
    }

    function addPayout(address _addr, uint256 amount) external {
        require(
            msg.sender == owner || msg.sender == node_address,
            "PRIVILAGED USER ONLY"
        );

        if (users[_addr].leader_status == 0)
            require(users[_addr].earnings_left >= amount, "MAX PAYOUT REACHED");

        total_payout = total_payout.add(amount);

        uint256 _profit = amount.div(100).mul(80);

        uint256 _staked = amount.div(100).mul(20);

        total_profit = total_profit.add(_profit);
        current_profit = current_profit.add(_profit);

        total_staked = total_staked.add(_staked);
        current_staked = current_staked.add(_staked);

        if (users[_addr].leader_status == 0)
            users[_addr].earnings_left -= amount;

        users[_addr].profitpayout += _profit;
        users[_addr].total_profitpayout += _profit;
        users[_addr].stakingpayout += _staked;
        users[_addr].total_stakingpayout += _staked;

        emit PayoutEvent(
            _addr,
            amount.div(100).mul(80),
            amount.div(100).mul(20)
        );
    }

    function withdraw(uint256 _amount) external {
        require(
            users[msg.sender].profitpayout >= min_withdrawal,
            "MIN 100 USDT"
        );

        require(users[msg.sender].profitpayout >= _amount, "NOT ENOUGH MONEY");

        require(_amount >= min_withdrawal, "MIN 100 USDT");

        ERC20 tc = ERC20(usdt_address);

        tc.transfer(msg.sender, _amount.div(100).mul(95));
        tc.transfer(companyaddress, _amount.div(100).mul(5));

        users[msg.sender].total_withdrawl = users[msg.sender]
            .total_withdrawl
            .add(_amount);

        total_withdraw = total_withdraw.add(_amount);

        current_profit = current_profit.sub(_amount);

        emit WithdrawEvent(
            msg.sender,
            _amount.div(100).mul(95),
            _amount.div(100).mul(5)
        );

        users[msg.sender].profitpayout = users[msg.sender].profitpayout.sub(
            _amount
        );
    }

    function investStaking(uint256 amount) external {
        require(staking_status == 1, "STAKING NOT ENABLED");

        require(
            users[msg.sender].stakingpayout >= amount,
            "NOT ENOUGH STAKING AMOUNT"
        );

        current_staked = current_staked.sub(amount);
        users[msg.sender].stakingpayout = users[msg.sender].stakingpayout.sub(
            amount
        );

        ERC20 tc = ERC20(usdt_address);
        tc.transfer(companyaddress, amount);

        emit StakingEvent(msg.sender, amount);

        if (token_transfer_status == 1) {
            ERC20 elft = ERC20(elft_address);

            uint256 return_token = amount.div(token_price).mul(multiplier);

            elft.transfer(msg.sender, return_token);

            emit ELFTTranEvent(msg.sender, amount);
        }
    }

    function addMerchant(address _addr) external {
        require(msg.sender == owner, "OWNER ONLY");

        merchants[_addr].status = 1;
    }

    function payMerchant(address _addr, uint256 _amount) external {
        require(merchant_status == 1, "MERCHANT NOT ENABLED");

        require(merchants[_addr].status == 1, "ADDRESS NOT AVAILABLE");

        require(
            users[msg.sender].stakingpayout >= _amount,
            "NOT ENOUGH BALANCE"
        );

        current_staked = current_staked.sub(_amount);
        users[msg.sender].stakingpayout = users[msg.sender].stakingpayout.sub(
            _amount
        );

        merchants[_addr].total_payout = merchants[_addr].total_payout.add(
            _amount
        );

        ERC20 tc = ERC20(usdt_address);
        tc.transfer(_addr, _amount);

        emit MerchantEvent(msg.sender, _amount);
    }

    function addPackage(uint256 _amount, uint8 _maxpayout) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_maxpayout >= 2, "MINIMUM 2 TIMES RETURN");

        packages[_amount * multiplier].status = 1;
        packages[_amount * multiplier].maxPayout = _maxpayout;
    }

    function addLeaderAddress(address _address) public {
        require(msg.sender == owner, "OWNER ONLY");

        users[_address].leader_status = 1;
    }

    function addELFTAddress(address _address) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_address != address(0), "VALUID ADDRESS REQUIRED");

        elft_address = _address;

        token_transfer_status = 1;
    }

    function addTokenPrice(uint256 _value) public {
        //6 Decimal
        require(
            msg.sender == owner || msg.sender == node_address,
            "PRIVILAGED USER ONLY"
        );

        token_price = _value;
    }

    function updateTokenShares(uint8 _value) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_value >= 0, "MUST HIGHER THAN 0");

        token_share = _value;
    }

    function enablePhase2() public {
        require(msg.sender == owner, "OWNER ONLY");

        phaseversion = 2;

        tokendebit = 2;

        staking_status = 1;

        merchant_status = 1;
    }
}