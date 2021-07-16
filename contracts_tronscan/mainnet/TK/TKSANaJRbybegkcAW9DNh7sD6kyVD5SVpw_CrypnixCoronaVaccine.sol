//SourceUnit: CrypnixCoronaVaccine.sol

pragma solidity 0.5.8;

contract CrypnixCoronaVaccine
{
    using SafeMath for uint;

    event Deposit(address account, uint amount, uint coins);
    event Withdraw(address account, uint amount, uint coins);

    struct Account
    {
        bool started;
        uint fund_total;
        uint fund_rate;
        uint fund_updated_at;
        uint total_deposits;
        uint total_withdrawals;
        address referrer;
        mapping(uint => uint) referrals;
        mapping(uint => uint) upgrades;
    }

    address private _owner;
    mapping(address => Account) private _accounts;

    uint private _total_deposits;
    uint private _total_withdrawals;
    uint private _total_accounts;

    uint private DEPOSIT_MULTIPLIER = 1000;
    uint private WITHDRAW_MULTIPLIER = 2000;
    uint private UPGRADE_MULTIPLIER = 1000000000;
    uint private RATE_MULTIPLIER = 100000;
    uint private MAX_UPGRADE_LEVEL = 100;
    uint private MAX_BONUS = 20;

    uint[3] private REFERRAL_BONUSES = [5, 3, 2];
    uint[4] private BASE_UPGRADES = [5, 10, 15, 20];

    constructor() public
    {
        _owner = msg.sender;
        _accounts[_owner].started = true;
        _accounts[_owner].referrer = _owner;
    }

    function deposit(address ref) public payable
    {
        require(msg.value > 0, "");

        updateReferrer(msg.sender, ref);

        address referrer = _accounts[msg.sender].referrer;
        address parent_referrer = _accounts[referrer].referrer;
        address grand_parent_referrer = _accounts[parent_referrer].referrer;

        uint coins = msg.value.mul(DEPOSIT_MULTIPLIER);
        uint bonus = getBonus(msg.value);

        _accounts[msg.sender].fund_total = _accounts[msg.sender].fund_total.add(coins.add(bonus));
        _accounts[msg.sender].total_deposits = _accounts[msg.sender].total_deposits.add(msg.value);
        _total_deposits = _total_deposits.add(msg.value);

        _accounts[_owner].fund_total = _accounts[_owner].fund_total.add(coins.mul(MAX_BONUS).div(100));
        _accounts[referrer].fund_total = _accounts[referrer].fund_total.add(coins.mul(REFERRAL_BONUSES[0]).div(100));
        _accounts[parent_referrer].fund_total = _accounts[parent_referrer].fund_total.add(coins.mul(REFERRAL_BONUSES[1]).div(100));
        _accounts[grand_parent_referrer].fund_total = _accounts[grand_parent_referrer].fund_total.add(coins.mul(REFERRAL_BONUSES[2]).div(100));

        emit Deposit(msg.sender, msg.value, coins);
    }

    function withdraw(uint amount) public
    {
        updateFunds(msg.sender);

        uint coins_required = amount.mul(WITHDRAW_MULTIPLIER);

        require(_accounts[msg.sender].fund_total >= coins_required, "");
        require(amount <= address(this).balance, "");

        _accounts[msg.sender].fund_total = _accounts[msg.sender].fund_total.sub(coins_required);
        _accounts[msg.sender].total_withdrawals = _accounts[msg.sender].total_withdrawals.add(amount);
        _total_withdrawals = _total_withdrawals.add(amount);

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount, coins_required);
    }

    function upgrade(uint feature) public
    {
        require(feature <= 3, "");
        require(_accounts[msg.sender].upgrades[feature] < MAX_UPGRADE_LEVEL, "");

        updateFunds(msg.sender);

        uint next_level = _accounts[msg.sender].upgrades[feature].add(1);
        uint coins_required = BASE_UPGRADES[feature].mul(next_level).mul(next_level.add(1)).mul(UPGRADE_MULTIPLIER).div(2);

        require(_accounts[msg.sender].fund_total >= coins_required, "");

        _accounts[msg.sender].upgrades[feature] = next_level;
        _accounts[msg.sender].fund_total = _accounts[msg.sender].fund_total.sub(coins_required);

        uint rate_increase = coins_required.div(((MAX_UPGRADE_LEVEL.mul(2)).sub(next_level)).mul(RATE_MULTIPLIER));
        _accounts[msg.sender].fund_rate = _accounts[msg.sender].fund_rate.add(rate_increase);
    }

    function updateReferrer(address account, address ref) private
    {
        if (!_accounts[account].started) {
            address referrer = _owner;
            if(ref != address(0) && ref != account && _accounts[ref].started){
                referrer = ref;
            }

            address parent_referrer = _accounts[referrer].referrer;
            address grand_parent_referrer = _accounts[parent_referrer].referrer;

            _accounts[account].started = true;
            _accounts[account].referrer = referrer;
            _total_accounts = _total_accounts.add(1);

            _accounts[referrer].referrals[0] = _accounts[referrer].referrals[0].add(1);
            _accounts[parent_referrer].referrals[1] = _accounts[parent_referrer].referrals[1].add(1);
            _accounts[grand_parent_referrer].referrals[2] = _accounts[grand_parent_referrer].referrals[2].add(1);
        }
    }

    function updateFunds(address account) private
    {
        uint last_updated = _accounts[account].fund_updated_at;
        if (last_updated == 0) {
            last_updated = getTimestamp();
        }

        uint time_diff = getTimestamp().sub(last_updated);
        uint coins = time_diff.mul(_accounts[account].fund_rate);

        _accounts[account].fund_total = _accounts[account].fund_total.add(coins);
        _accounts[account].fund_updated_at = getTimestamp();
    }

    function getAccount(address account) public view returns (bool, address, uint[12] memory)
    {
        return (
            _accounts[account].started,
            _accounts[account].referrer,
            [
                _accounts[account].fund_total,
                _accounts[account].fund_rate,
                _accounts[account].fund_updated_at,
                _accounts[account].total_deposits,
                _accounts[account].total_withdrawals,
                _accounts[account].referrals[0],
                _accounts[account].referrals[1],
                _accounts[account].referrals[2],
                _accounts[account].upgrades[0],
                _accounts[account].upgrades[1],
                _accounts[account].upgrades[2],
                _accounts[account].upgrades[3]
            ]
        );
    }

    function getStatus() public view returns (uint[3] memory)
    {
        return [
            _total_deposits,
            _total_withdrawals,
            _total_accounts
        ];
    }

    function getOwner() public view returns (address)
    {
        return _owner;
    }

    function getTimestamp() public view returns (uint)
    {
        return block.timestamp;
    }

    function getBonus(uint amount) public view returns (uint)
    {
        uint bonus = 0;

        if (amount < 1000000000){
            bonus = 1;
        } else if (amount < 10000000000){
            bonus = 3;
        } else if (amount < 100000000000){
            bonus = 6;
        } else {
            bonus = 10;
        }

        return amount.mul(DEPOSIT_MULTIPLIER).mul(bonus).div(100);
    }
}

library SafeMath
{
    function mul(uint a, uint b) internal pure returns (uint)
    {
        if (a == 0)
        {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint)
    {
        require(b > 0, "");
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint)
    {
        require(b <= a, "");
        uint c = a - b;
        return c;
    }

    function add(uint a, uint b) internal pure returns (uint)
    {
        uint c = a + b;
        require(c >= a, "");
        return c;
    }
}