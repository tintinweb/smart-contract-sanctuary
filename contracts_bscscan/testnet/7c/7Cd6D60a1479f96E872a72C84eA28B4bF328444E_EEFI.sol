/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity 0.4.25;

contract EEFI {
    using SafeMath for uint256;
    IBEP20 public token;
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
        uint256 j_time;
        uint256 gi_bonus;
         uint256 total_gi_bonus;
        uint256 dividends;
        //uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
        mapping(uint8 => uint256) levelBusiness;
    }

    address public owner;
    uint256[] public GI_PERCENT = [90,80,70,60,50,40,20,10,10,10];
 

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public withdrawFee;
    uint256 public releaseTime = 1598104800;//1598104800
    uint8[] public ref_bonuses; // 1 => 1%

    uint256 gi_bonus;

    Tarif[] public tarifs;
    mapping(address => Player) public players;
   

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(IBEP20 tokenAdd) public {
        owner = msg.sender;
        //stakingAddress = _stakingAddress;
        token = tokenAdd;

        //days , total return percentage//min invest
        tarifs.push(Tarif(365, 18000,500));//0.5 //oo//50
        tarifs.push(Tarif(365, 27400,1000)); //0.75//00//75
      
        
        ref_bonuses.push(100);
  
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

           // players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;
            token.transfer(up,bonus);
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
                 players[_upline].levelBusiness[i] += amount;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
        
         else
             {
                _upline = players[_addr].upline;
            for( i = 0; i < GI_PERCENT.length; i++) {
                     players[_upline].levelBusiness[i] += amount;
                    _upline = players[_upline].upline;
                    if(_upline == address(0)) break;
                }
        }
        
    }

   function deposit(uint8 _tarif, address _upline, uint256 token_quantity) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(token_quantity >= tarifs[_tarif].min_inv, "Less Then the min investment");
        //require(value_to_check <= tarifs[_tarif].max_inv, "more Then the max investment");
        require(now >= releaseTime, "not open yet");
        
        token.transferFrom(msg.sender, address(this), token_quantity);
        Player storage player = players[msg.sender];

        _setUpline(msg.sender, _upline,token_quantity);
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: token_quantity,
            totalWithdraw: 0,
            time: uint256(block.timestamp) 
        }));
        

        player.total_invested += token_quantity;
        player.j_time =  uint256(block.timestamp);
        invested += token_quantity;

        _refPayout(msg.sender, token_quantity);


     // token.transfer(owner,token_quantity.mul(10).div(100));
      
        emit NewDeposit(msg.sender, token_quantity, _tarif);
    }

function withdraw() payable external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);
        require(player.dividends > 0 || player.gi_bonus > 0 , "Zero amount");
        uint256 amount = player.dividends.mul(80).div(100)  + player.gi_bonus;
          require(amount > 10 * 10 ** 18,'Less then the min withdrawl'); //10$
          

        _send_gi(msg.sender,player.dividends);
        player.dividends = 0;
        player.gi_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        emit Withdraw(msg.sender, amount);
        token.transfer(msg.sender,amount);
       
       
    }


    function _send_gi(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        _amount = _amount.mul(20).div(100);
        
           uint256 wfee = _amount.mul(44).div(1000);
            token.transfer(owner,wfee);

        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            if(up == address(0)) break;

           
                uint256 bonus = _amount * GI_PERCENT[i] / 1000;
                players[up].gi_bonus += bonus;
                players[up].total_gi_bonus += bonus;
                gi_bonus += bonus;
           
            up = players[up].upline;
           
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
            _structurebusiness[i] =  player.levelBusiness[i];
           
        }

        return (_structure,_structurebusiness);
    }
    


    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
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