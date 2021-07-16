//SourceUnit: TronMatesSaver.sol

pragma solidity ^0.5.8;

contract TronMatesSaver {

    using SafeMath for uint;

    event OnDeposit(address account, uint amount);
    event OnWithdraw(address account, uint amount);

    struct Account {
        bool exist;
        uint total_deposited;
        uint total_withdrawn;
        uint total_referred;
        uint last_paid_timestamp;
        uint[] deposit_amounts;
        uint[] deposit_timestamps;
        address payable referrer;
    }

    address payable private _owner;
    
    uint private _start;
    uint private _total_deposited;
    uint private _total_players;

    mapping(address => Account) private _accounts;

    uint private MULTIPLIER = 10**18;
    uint private MIN_DEPOSIT = 10 * 10**6;
    uint private MAX_DEPOSIT = 100000 * 10**6;
    uint private BASE_INTEREST_RATE = 4 * 10**6;
    uint private BONUS_INTEREST_RATE = 10**6;

    constructor() public {
        _owner = msg.sender;
        _accounts[_owner].exist = true;
        _accounts[_owner].referrer = _owner;
        _start = 1602676800;
    }

    function deposit(address payable ref) public payable {
        require(msg.sender != _owner, "");
        require(msg.value >= MIN_DEPOSIT, "");
        require(msg.value <= MAX_DEPOSIT, "");
        require(_start < block.timestamp, "");

        if (!_accounts[msg.sender].exist) {
            address payable referrer = _owner;
            if (ref != address(0) && ref != msg.sender && _accounts[ref].exist) {
                referrer = ref;
            }

            _accounts[msg.sender].exist = true;
            _accounts[msg.sender].referrer = referrer;
            _accounts[msg.sender].last_paid_timestamp = block.timestamp;
            _total_players = _total_players.add(1);
        }

        address payable referrer_1 = _accounts[msg.sender].referrer;
        address payable referrer_2 = _accounts[referrer_1].referrer;

        _owner.transfer(msg.value.mul(10).div(100));
        referrer_1.transfer(msg.value.mul(5).div(100));
        referrer_2.transfer(msg.value.mul(5).div(100));
        
        _total_deposited = _total_deposited.add(msg.value);
        _accounts[msg.sender].total_deposited = _accounts[msg.sender].total_deposited.add(msg.value);
        _accounts[referrer_1].total_referred = _accounts[referrer_1].total_referred.add(msg.value);
        _accounts[referrer_2].total_referred = _accounts[referrer_2].total_referred.add(msg.value);

        _accounts[msg.sender].deposit_amounts.push(msg.value);
        _accounts[msg.sender].deposit_timestamps.push(block.timestamp);

        emit OnDeposit(msg.sender, msg.value);
    }

    function withdraw() public {
        uint balance = getAccountBalance(msg.sender);
        _accounts[msg.sender].last_paid_timestamp = block.timestamp;

        if (balance > 0) {
            msg.sender.transfer(balance);
            _accounts[msg.sender].total_withdrawn = _accounts[msg.sender].total_withdrawn.add(balance);
            
            emit OnWithdraw(msg.sender, balance);
        }
    }

    function getStatus() public view returns (uint, uint, uint, uint) {
        return (
            _start,
            _total_players,
            _total_deposited,
            address(this).balance
        );
    }

    function getAccount(address account) public view returns (bool, address, uint[8] memory) {
        return (
            _accounts[account].exist,
            _accounts[account].referrer,
            [
                _accounts[account].total_deposited,
                _accounts[account].total_withdrawn,
                _accounts[account].total_referred,
                getAccountBalance(account),
                getAccountDepositBonus(account),
                getAccountReferralBonus(account),
                getAccountHoldBonus(account),
                getAccountInterestRate(account)
            ]
        );
    }

    function getAccountBalance(address account) private view returns (uint)
    {
        uint rate  = getAccountInterestRate(account);
        uint balance = 0;
        uint last_paid = _accounts[account].last_paid_timestamp;

        for (uint i = 0; i < _accounts[account].deposit_amounts.length; i++) {
            uint start = _accounts[account].deposit_timestamps[i];
            uint from = (last_paid >= start) ? last_paid : start;
            uint to = block.timestamp;
            
            if (start > 0 && from < to) {
                uint amount = _accounts[account].deposit_amounts[i];
                balance = balance.add(amount.mul(MULTIPLIER).mul(rate).mul(to.sub(from)).div(100 days));
            }
        }

        balance = balance.div(MULTIPLIER).div(BONUS_INTEREST_RATE);

        uint contract_balance = address(this).balance;
        if (balance > contract_balance) {
            balance = contract_balance;
        }

        return balance;
    }

    function getAccountInterestRate(address account) private view returns (uint)
    {
        uint max = BASE_INTEREST_RATE.mul(2);
        uint rate = BASE_INTEREST_RATE.add(getAccountDepositBonus(account)).add(getAccountReferralBonus(account)).add(getAccountHoldBonus(account));

        if (rate > max) {
            rate = max;
        }

        return rate;
    }

    function getAccountDepositBonus(address account) private view returns (uint)
    {
        return _accounts[account].total_deposited.div(BONUS_INTEREST_RATE);
    }

    function getAccountReferralBonus(address account) private view returns (uint)
    {
        return _accounts[account].total_referred.div(BONUS_INTEREST_RATE);
    }

    function getAccountHoldBonus(address account) private view returns (uint)
    {
        uint bonus = 0;
        if (_accounts[account].last_paid_timestamp > 0) {
            bonus = block.timestamp.sub(_accounts[account].last_paid_timestamp);
        }

        return bonus;
    }
}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint)
    {
        if (a == 0) {
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