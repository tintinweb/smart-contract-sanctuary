//SourceUnit: DoublersTron.sol

pragma solidity >=0.5.8;

contract DoublersTron {
    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 20000000;
    uint private maxDepositSize = 5000000000;
    uint private divisor = 100;
    uint private devCommission = 10;
    uint private rate = 200;      
    uint private releaseTime=1610035200;
    uint public constant veces=1;
    address payable owner;
    struct Deposit{
        uint256 amount;
        uint256 time;
        uint256 tmp;
        uint256 profit;
        uint per;
    }
    struct Player {
        address usadr;
        uint256 trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        Deposit [veces] deposits;
        uint cant;
        address payable affFrom;
        uint256 aff1sum;       //1 Level Referral Commission
        
    }
    mapping(address => Player) public players;
    constructor() public {
      owner = msg.sender;
    }
    function register(address _addr, address payable _affAddr) private{
        Player storage player = players[_addr];
        player.affFrom = _affAddr;
        address _affAddr1 = _affAddr;
        players[_affAddr1].aff1sum += 1;
        
    }
    function deposit(address payable _affAddr) public payable  returns(bool){
        require(now >= releaseTime, "not time yet!");
        require(msg.value >= minDepositSize);
        require(msg.value <= maxDepositSize);
        require(msg.sender != _affAddr,"can not refer to yourself");
        if(players[msg.sender].cant == veces){
            return false;
        }
        uint depositAmount = msg.value;
        if(players[msg.sender].usadr == msg.sender && players[msg.sender].trxDeposit > 0){
            register(msg.sender, _affAddr);
            players[msg.sender].cant += 1;
        }
        else{
            register(msg.sender, _affAddr);
            players[msg.sender].cant= 1;
            players[msg.sender].usadr = msg.sender;
            totalPlayers++;
        }
        distributeRef(msg.value, players[msg.sender].affFrom);
        totalInvested += depositAmount;
        players[msg.sender].time = now;
        players[msg.sender].trxDeposit += depositAmount;
        uint pos = players[msg.sender].deposits.length;
        uint p = (pos-(players[msg.sender].cant-1))-1;
        if(players[msg.sender].deposits[p].amount >0){
            uint pa = p+(players[msg.sender].cant-1);
            if(players[msg.sender].deposits[pa].amount > 0){
                uint t =1;
                for(uint i=0 ; i< pos;i++){
                    uint r = pa-t;
                    if(players[msg.sender].deposits[r].amount ==0){
                        players[msg.sender].deposits[r] = Deposit(msg.value,now,now+ 20 hours,0,rate);
                        return true;
                    }
                    t++;
                }
            }else{
                players[msg.sender].deposits[pa] = Deposit(msg.value,now,now + 20 hours,0,rate);
                return true;
            }
        }else{
            players[msg.sender].deposits[p] = Deposit(msg.value,now,now+ 20 hours,0,rate);
            return true;
        }
    }
    function withdraw(uint pos) public returns(uint256){
        require(now >= releaseTime, "not time yet!");
        Player storage player = players[msg.sender];
        require(player.deposits[pos].amount > 0 ,'you have already withdraw everything.');
        uint por;
        uint pft;
        por = getPercent(player.deposits[pos].amount,rate);
        if( player.deposits[pos].tmp < now){
            uint secPassed2 = player.deposits[pos].tmp-player.deposits[pos].time;
            pft = (secPassed2*(por/20/60/60));
            require(pft< address(this).balance, 'not balance system');
            player.deposits[pos].time =0;
            player.deposits[pos].profit =0;
            player.deposits[pos].amount =0;
            player.deposits[pos].tmp =0;
            player.cant -=1;
            uint devEarn = getPercent(pft,devCommission);
            owner.transfer(devEarn);
            msg.sender.transfer(pft);
            return pft;
        }else{
            uint secPassed = now-player.deposits[pos].time;
            pft = (secPassed*(por/20/60/60));
            require(pft< address(this).balance, 'not balance system');
            player.deposits[pos].time =now;
            player.interestProfit += pft;
            player.deposits[pos].profit += pft;
            uint devEarn = getPercent(pft,devCommission);
            owner.transfer(devEarn);
            msg.sender.transfer(pft);
            return pft;
        }
        
    }
    function distributeRef(uint256 _trx, address payable _affFrom) private{
        address payable _affAddr1 = _affFrom;
        uint256 _affRewards = 0;
        if (_affAddr1 != address(0)) {
            _affRewards = getPercent(_trx,10);
            players[_affAddr1].affRewards += _affRewards;
            _affAddr1.transfer(_affRewards);
            totalPayout += _affRewards; 
        }
        
        
    }
    function details() public view returns(uint,uint,uint,uint,uint,uint){
        return (totalInvested,totalPlayers,totalPayout,players[msg.sender].cant,rate,minDepositSize);
    }
    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint vald;
        vald = (_val * _percent) / 100 ;
        return vald;
    }
    function datas() public view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint[] memory,uint[] memory){
        uint256 [] memory amount = new uint256[](players[msg.sender].cant);
        uint256[] memory time = new uint256[](players[msg.sender].cant);
        uint256[] memory profit = new uint256[](players[msg.sender].cant);
        uint256[] memory tmp = new uint256[](players[msg.sender].cant);
        uint256[] memory pos = new uint256[](players[msg.sender].cant);
        uint256[] memory per = new uint256[](players[msg.sender].cant);
        uint p =0;
        for (uint i=0; i<players[msg.sender].deposits.length ;i++){
            if(players[msg.sender].deposits[i].amount > 0){
                amount[p] = players[msg.sender].deposits[i].amount;
                time[p] = players[msg.sender].deposits[i].time;
                tmp[p] = players[msg.sender].deposits[i].tmp;
                profit[p] = players[msg.sender].deposits[i].profit;
                pos[p] = i;
                per[p] = rate;
                p++;
            }
        }
        return (amount,time,tmp,profit,pos,per);
    }
    function getTime()public view returns(uint){
        return releaseTime;
    }
    function getHistory() public view returns(uint256,uint,uint){
        Player storage player = players[msg.sender];
        return (player.trxDeposit,player.interestProfit,player.affRewards);
    }
    
   
}