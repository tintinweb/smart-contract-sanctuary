/**
 *Submitted for verification at polygonscan.com on 2022-01-07
*/

pragma solidity ^0.5.9;



contract Crocodile_Finance{
    uint public totalInvested;
    uint public totalWithdrawn;
    uint public totalRefferalPayout;
    uint public totalInvestors;
    uint private minDepositSize = 5000000; //5 MATIC Min Deposit Size
    uint private maxDepositSize = 100000000000; //100,000 MATIC Max Deposit Size Per Invest
    uint private profitRate = 12; //12% Daily ROI
    uint private devCommission = 5; //5% Developer Commission
    uint private devEarn;
    uint private releaseTime = 1612945800;

    address payable owner;

    struct Player{
        uint256 P_totalDeposit;
        uint256 P_totalWithdrawn;
        uint256 P_refferalPayout;
        uint256 refferalReward;
        Deposit[] deposits;
        uint count;
        address payable affFrom;
    }
    struct Deposit{
        uint256 amount;
        uint256 time;
        uint256 tmp;
        uint256 withdrawn;
        uint plan_totalProfit;
        bool active;
    }

    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;
    }

    function deposit(address payable _affAddr, uint plan) public payable returns(bool){
        require(now >= releaseTime, "Not Launched Yet!");
        require(msg.value >= minDepositSize);
        require(maxDepositSize >= msg.value);
        require(msg.sender != _affAddr,"Can Not Refer Yourself");
        uint256 active_days;
        uint totalReturn;
        if(plan == 1){totalReturn = 120; active_days = 10 days;
        }else if(plan == 2){totalReturn = 180; active_days = 15 days;
        }else if(plan == 3){totalReturn = 240; active_days = 20 days;
        }else if(plan == 4){totalReturn = 300; active_days = 25 days;
        }else{revert();}
        Player storage player = players[msg.sender];
        if(players[msg.sender].P_totalDeposit > 0){
            players[msg.sender].count += 1;
        }else{
            player.affFrom = _affAddr;
            players[msg.sender].count= 1;
            totalInvestors++;
        }
        uint depositAmount = msg.value;
        devEarn += getPercent(depositAmount,devCommission);
        distributeRef(msg.value, players[msg.sender].affFrom);
        totalInvested += depositAmount;
        players[msg.sender].P_totalDeposit += depositAmount;
        
        players[msg.sender].deposits.push(Deposit({
            amount: msg.value,
            time: now,
            tmp: now + (active_days * 1 days),
            withdrawn: 0,
            plan_totalProfit: totalReturn,
            active: true
        }));
        
        return true;
    }
    
    function withdraw() public returns(bool){
        require(now >= releaseTime, "not time yet!");
        Player storage player = players[msg.sender];
        require(players[msg.sender].P_totalDeposit > 0 ,'You need to deposit first.');
        uint profit = GetProfit(msg.sender);
        require(profit< address(this).balance, 'Not enough system balance.');
        require(profit> 0, 'Nothing to withdraw');
        
        uint pft = 0;
        uint por;
        uint secPassed;
        uint maxProfit;
        uint plan_pft;
        for(uint8 i = 0; i < players[msg.sender].count; i++) {
            if(player.deposits[i].active){
               secPassed = now-player.deposits[i].time;
               por = getPercent(player.deposits[i].amount,profitRate);        
               if(now >= player.deposits[i].tmp){
                   maxProfit = player.deposits[i].plan_totalProfit;
                   pft += getPercent(player.deposits[i].amount,maxProfit) - player.deposits[i].withdrawn;
                   player.deposits[i].time = now;
                   player.deposits[i].withdrawn = getPercent(player.deposits[i].amount,maxProfit);
                   player.deposits[i].active = false;
                }else{
                    plan_pft = (secPassed*(por/24/60/60));
                    pft += plan_pft;
                    player.deposits[i].time = now;
                    player.deposits[i].withdrawn += plan_pft;
                }
            }
        }
        players[msg.sender].P_totalWithdrawn += pft;
        totalWithdrawn += pft;
        msg.sender.transfer(pft);
        return(true);
    }

    function withdraw_refferal() public returns(bool){
        require(players[msg.sender].refferalReward< address(this).balance, 'Not enough system balance.');
        require(players[msg.sender].P_totalDeposit > 0 ,'You need to deposit first.');
        uint reward = players[msg.sender].refferalReward;
        players[msg.sender].refferalReward = 0;
        players[msg.sender].P_refferalPayout += reward;
        totalRefferalPayout += reward;
        msg.sender.transfer(reward);
        return true;
    }

    function developerCommission() public returns(bool){
        require(msg.sender == owner);
        require(devEarn< address(this).balance, 'Not enough system balance.');
        owner.transfer(devEarn);
        devEarn = 0;
        return true;
    }
    
    function distributeRef(uint256 _trx, address payable _affFrom) private{
        address payable _affAddr1 = _affFrom;
        address payable _affAddr2 = players[_affAddr1].affFrom;
        address payable _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;
        if (_affAddr1 != address(0)) {
            _affRewards = getPercent(_trx,5);
            players[_affAddr1].refferalReward += _affRewards;
        }
        if (_affAddr2 != address(0)) {
            _affRewards = getPercent(_trx,3);
            players[_affAddr2].refferalReward += _affRewards;
        }
        if (_affAddr3 != address(0)) {
            _affRewards = getPercent(_trx,2);
            players[_affAddr3].refferalReward += _affRewards;
        }
    }

    function GetProfit(address _addr) public view returns(uint) {
        Player storage player = players[_addr];
        uint pft;
        uint por;
        uint secPassed;
        uint maxProfit;
        for(uint8 i = 0; i < players[msg.sender].count; i++) {
            if(player.deposits[i].active){
               secPassed = now-player.deposits[i].time;
               por = getPercent(player.deposits[i].amount,profitRate);        
               if(now >= player.deposits[i].tmp){
                   maxProfit = player.deposits[i].plan_totalProfit;
                   pft += getPercent(player.deposits[i].amount,maxProfit) - player.deposits[i].withdrawn;
                }else{
                    pft += (secPassed*(por/24/60/60));
                }
            }
        }
        return pft;
    }

    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint vald;
        vald = (_val * _percent) / 100 ;
        return vald;
    }

    function details() public view returns(uint,uint,uint,uint,uint,uint){
        return (totalInvested,totalInvestors,totalWithdrawn,totalRefferalPayout,minDepositSize,maxDepositSize);
    }

    function datas() public view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint[] memory,uint[] memory,bool[] memory){
        uint256 [] memory amount = new uint256[](players[msg.sender].count);
        uint256[] memory time = new uint256[](players[msg.sender].count);
        uint256[] memory withdrawn = new uint256[](players[msg.sender].count);
        uint256[] memory tmp = new uint256[](players[msg.sender].count);
        uint[] memory plan_totalProfit = new uint[](players[msg.sender].count);
        uint256[] memory pos = new uint256[](players[msg.sender].count);
        bool[] memory active = new bool[](players[msg.sender].count);
        uint p =0;
        for (uint i=0; i<players[msg.sender].deposits.length ;i++){
            if(players[msg.sender].deposits[i].amount > 0){
                amount[p] = players[msg.sender].deposits[i].amount;
                time[p] = players[msg.sender].deposits[i].time;
                tmp[p] = players[msg.sender].deposits[i].tmp;
                withdrawn[p] = players[msg.sender].deposits[i].withdrawn;
                plan_totalProfit[p] = players[msg.sender].deposits[i].plan_totalProfit;
                active[p] = players[msg.sender].deposits[i].active;
                pos[p] = i;
                p++;
            }
        }
        return (amount,time,tmp,withdrawn,plan_totalProfit,pos,active);
    }

}