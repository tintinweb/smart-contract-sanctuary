//SourceUnit: BitsoTRX.sol

pragma solidity ^0.5.10;


// ██████╗░██╗████████╗░██████╗░█████╗░
// ██╔══██╗██║╚══██╔══╝██╔════╝██╔══██╗
// ██████╦╝██║░░░██║░░░╚█████╗░██║░░██║
// ██╔══██╗██║░░░██║░░░░╚═══██╗██║░░██║
// ██████╦╝██║░░░██║░░░██████╔╝╚█████╔╝
// ╚═════╝░╚═╝░░░╚═╝░░░╚═════╝░░╚════╝░
//
// ░█████╗░░█████╗░███╗░░░███╗██████╗░░█████╗░███╗░░██╗██╗░░░██╗
// ██╔══██╗██╔══██╗████╗░████║██╔══██╗██╔══██╗████╗░██║╚██╗░██╔╝
// ██║░░╚═╝██║░░██║██╔████╔██║██████╔╝███████║██╔██╗██║░╚████╔╝░
// ██║░░██╗██║░░██║██║╚██╔╝██║██╔═══╝░██╔══██║██║╚████║░░╚██╔╝░░
// ╚█████╔╝╚█████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██║░╚███║░░░██║░░░
// ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░

contract Bitso_TRX{
    uint public totalInvested;
    uint public totalWithdrawn;
    uint public totalInvestors;
    uint private minDepositSize = 10000000; //10 TRX Min Deposit Size

    uint private devCommission = 5; // 5% Developer Commission
    uint private developmetFund = 30; // 30% of the fund is used for network growth.
    bool private releaseSwitch = false;

    address payable owner;

    struct Player{
        uint256 P_totalDeposit;
        uint256 P_totalWithdrawn;
        uint256 referalReward;
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
        uint plan_days;
        bool active;
    }

    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;
    }

    function deposit(address payable _affAddr, uint plan) public payable returns(bool){
        uint depositAmount = msg.value;
        require(releaseSwitch, "Not Launched Yet!");
        require(depositAmount >= minDepositSize);
        require(msg.sender != _affAddr,"Can Not Refer Yourself");
        uint plan_d;
        uint totalReturn;
        if(plan == 1){totalReturn = 112; plan_d = 180;
        }else if(plan == 2){totalReturn = 148; plan_d = 360;
        }else if(plan == 3){totalReturn = 244; plan_d = 720;
        }else{revert();}
        if(players[msg.sender].P_totalDeposit > 0){
            players[msg.sender].count += 1;
        }else{
            players[msg.sender].affFrom = _affAddr;
            players[msg.sender].count= 1;
            totalInvestors++;
        }

        uint256 commission = getPercent(depositAmount,devCommission + developmetFund);
        owner.transfer(commission);
        distributeRef(depositAmount, players[msg.sender].affFrom);

        totalInvested += depositAmount;
        players[msg.sender].P_totalDeposit += depositAmount;
        
        players[msg.sender].deposits.push(Deposit({
            amount: depositAmount,
            time: now,
            tmp: now + (plan_d * 3600 * 24),
            withdrawn: 0,
            plan_totalProfit: totalReturn,
            plan_days: plan_d,
            active: true
        }));
        
        return true;
    }
    
    function withdraw() public returns(bool){
        require(releaseSwitch, "Not launched yet!");
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
        for(uint8 i = 0; i < player.count; i++) {
            if(player.deposits[i].active){
               secPassed = now-player.deposits[i].time;
               por = getPercent(player.deposits[i].amount,player.deposits[i].plan_totalProfit);        
               if(now >= player.deposits[i].tmp){
                   maxProfit = player.deposits[i].plan_totalProfit;
                   pft += getPercent(player.deposits[i].amount,maxProfit) - player.deposits[i].withdrawn;
                   player.deposits[i].time = now;
                   player.deposits[i].withdrawn = getPercent(player.deposits[i].amount,maxProfit);
                   player.deposits[i].active = false;
                }else{
                    pft += ((secPassed*por / player.deposits[i].plan_days)/24/60/60);
                    player.deposits[i].time = now;
                    player.deposits[i].withdrawn += plan_pft;
                }
            }
        }
        if(player.P_totalDeposit >= 100000000){
            pft += player.referalReward;
            player.referalReward = 0;
        }
        player.P_totalWithdrawn += pft;

        totalWithdrawn += pft;
        msg.sender.transfer(pft);
        return(true);
    }
    
    function distributeRef(uint256 _trx, address payable _affFrom) private{
        address payable _affAddr1 = _affFrom;
        address payable _affAddr2 = players[_affAddr1].affFrom;
        address payable _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;
        if (_affAddr1 != address(0) && players[_affAddr1].P_totalDeposit >= 100000000) {
            _affRewards = getPercent(_trx,5);
            players[_affAddr1].referalReward += _affRewards;
        }
        if (_affAddr2 != address(0) && players[_affAddr2].P_totalDeposit >= 100000000) {
            _affRewards = getPercent(_trx,3);
            players[_affAddr2].referalReward += _affRewards;
        }
        if (_affAddr3 != address(0) && players[_affAddr3].P_totalDeposit >= 100000000) {
            _affRewards = getPercent(_trx,2);
            players[_affAddr3].referalReward += _affRewards;
        }
    }

    function GetProfit(address _addr) public view returns(uint) {
        Player storage player = players[_addr];
        uint pft;
        uint por;
        uint secPassed;
        uint maxProfit;
        for(uint8 i = 0; i < player.count; i++) {
            if(player.deposits[i].active){
               secPassed = now-player.deposits[i].time;
               por = getPercent(player.deposits[i].amount,player.deposits[i].plan_totalProfit);        
               if(now >= player.deposits[i].tmp){
                   maxProfit = player.deposits[i].plan_totalProfit;
                   pft += getPercent(player.deposits[i].amount,maxProfit) - player.deposits[i].withdrawn;
                }else{
                    pft += ((secPassed*por / player.deposits[i].plan_days)/24/60/60);
                }
            }
        }
        if(player.P_totalDeposit >= 100000000){
            pft += player.referalReward;
        }
        return pft;
    }

    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint vald;
        vald = (_val * _percent) / 100 ;
        return vald;
    }

    function details() public view returns(uint,uint,uint,uint){
        return (totalInvested,totalInvestors,totalWithdrawn,minDepositSize);
    }

    function activate() public returns(bool){
        require(!releaseSwitch, "Contract already active");
        require(msg.sender == owner, "Only owner can call this function");

        releaseSwitch = true;
        return true;
    }

    function datas() public view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint[] memory, uint[] memory,uint[] memory){
        uint256 [] memory amount = new uint256[](players[msg.sender].count);
        uint256[] memory time = new uint256[](players[msg.sender].count);
        uint256[] memory withdrawn = new uint256[](players[msg.sender].count);
        uint256[] memory tmp = new uint256[](players[msg.sender].count);
        uint[] memory plan_totalProfit = new uint[](players[msg.sender].count);
        uint[] memory plan_days = new uint[](players[msg.sender].count);
        uint256[] memory pos = new uint256[](players[msg.sender].count);
        uint p =0;
        for (uint i=0; i<players[msg.sender].deposits.length ;i++){
            if(players[msg.sender].deposits[i].amount > 0 && players[msg.sender].deposits[i].active == true){
                amount[p] = players[msg.sender].deposits[i].amount;
                time[p] = players[msg.sender].deposits[i].time;
                tmp[p] = players[msg.sender].deposits[i].tmp;
                withdrawn[p] = players[msg.sender].deposits[i].withdrawn;
                plan_totalProfit[p] = players[msg.sender].deposits[i].plan_totalProfit;
                plan_days[p] = players[msg.sender].deposits[i].plan_days;
                pos[p] = i;
                p++;
            }
        }
        return (amount,time,tmp,withdrawn,plan_totalProfit,plan_days,pos);
    }
}