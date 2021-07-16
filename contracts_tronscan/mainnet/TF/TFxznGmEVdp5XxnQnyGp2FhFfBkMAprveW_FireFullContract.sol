//SourceUnit: FireFullContract.sol

pragma solidity ^0.5.3;

contract Ownable {
  mapping(address => bool) public owners;
  address public creater;
  constructor() public {
    owners[msg.sender] = true;
    creater = msg.sender;
  }
  modifier onlyOwner() {
    require(owners[msg.sender] == true,'Permission denied');
    _;
  }
  modifier onlyCreater() {
    require(creater == msg.sender,'Permission denied');
    _;
  }
  function addOwnership(address _newOwner) public onlyOwner {
    owners[_newOwner] = true;
  }
  function delOwnership(address _newOwner) public onlyOwner {
    owners[_newOwner] = false;
  }
}
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint _a, uint _b) internal pure returns (uint c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b,'mul error');
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint _a, uint _b) internal pure returns (uint) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint _a, uint _b) internal pure returns (uint) {
    require(_b <= _a,'sub error');
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint _a, uint _b) internal pure returns (uint c) {
    c = _a + _b;
    require(c >= _a,'add error');
    return c;
  }
}

interface FirePowerToken {
    function saleScale() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint) ;
    function burn(address _from, uint _value) external returns (bool);
    function totalSupply() external view returns (uint);
    function getSP(address _account) view external returns(bool,uint,uint);
}
contract FFGModel{
    struct playerObj{
        bool state;
        bool joinState;
        uint input;
        uint output;
        uint nomalMax;
        uint totalProfit;
        uint nomalProfit;
        uint teamProfit;
        uint jackpotProfit;
        uint contractBalance;
        address[] invit;
        uint[] recommand;
        uint teamJoin;
        bool isSP;
    }
    
    struct jackpotObj{
        uint pool;
        uint water;
        uint scale;
    }
    struct superPlayerObj{
        bool isActive;
        uint profit;
        uint profitFlag;
        uint teamPlayers;
    }
}
contract FFGConfig is FFGModel{
    address public firePowerContract = 0xD0F8eB83a6917092f37CfC5ae3c9eaD3624854fd;
    FirePowerToken internal token = FirePowerToken(firePowerContract);
    uint public periods = 1;
    uint public totalJoin = 0;
    uint public sedimentaryAsset = 0;
    uint public playerCounter = 0;
    uint public minJoinAmount = 2000 trx;
    uint[] public rewardScale = new uint[](10);
    uint public jackpotIndex = 1;
    uint public nomalListIndex = 0;
    bool public contractState = false;
    address[] public nomalList = new address[](5);
    address payable[] public retainAddress = new address payable[](2);
    event WithdrawEvent(address indexed _player,uint _amount,uint time);
    event InvitEvent(address indexed _from,address _player,uint time);
    event JoinEvent(address indexed _player,uint _joinAmount,uint time);
    event ProfitEvent(address indexed _player,uint _rewardAmount,uint time);
    event TeamRewardEvent(address indexed _player,address _invit,uint _level, uint _rewardAmount,uint time);
    event PrizeEvent(address indexed _player,uint _jackpot,uint _prize,uint _amount,uint time);
    event SuperPlayerEvent(address indexed _player,uint _total,uint _amount,uint time);
    event leaveContractEvent(address indexed _player,uint _output,uint time);

    mapping(uint=>jackpotObj) public jackpot;
    mapping(address => superPlayerObj) public superPlayerList;
    mapping(address => playerObj) public players;
    mapping(uint => address) public joinPlayerList;

    function periodsLimit() public view returns(uint){
        if(periods == 1){
            return 50000 trx;
        }else if(periods == 2){
            return 100000 trx;
        }else{
            return 200000 trx;
        }
    }
    function joinScale() public view returns(uint){
        if(periods == 1){
            return 26;
        }else if(periods == 2){
            return 30;
        }else{
            return 36;
        }
    }
    modifier isHuman() {
        address _addr = msg.sender;
        uint _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
}

contract FireFullContract is FFGConfig,Ownable{
    using SafeMath for uint;
    function join() payable external{
        require(contractState,'Contract Not Start');
        require(msg.value <= periodsLimit(),'Period Maxmum limit exceeded');
        require(msg.value >= minJoinAmount,'Period Minimum limit exceeded');
        require(players[msg.sender].state,'Please bind the recommender in advance');
        
        uint scale = joinScale();
        uint profit = msg.value.mul(scale).div(10);
        uint ticketScale = token.saleScale();
        uint ticket = msg.value.mul(100).div(ticketScale);
        uint tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance >= ticket,'ticket not enough');
        
        contractReward(msg.value.mul(35).div(100));
        
        
        joinPlayerList[playerCounter] = msg.sender;
        playerCounter = playerCounter + 1;
        
        
        totalJoin = totalJoin.add(msg.value);
        
        if(nomalListIndex < 5){
            nomalList[nomalListIndex] = msg.sender;
            nomalListIndex++;
        }
        
        playerObj memory player = players[msg.sender];
        if(player.joinState == true){
            require(player.input.add(msg.value) <= periodsLimit(),'Period Maxmum limit exceeded');
            uint _scale = player.output.mul(10).div(player.input);
            player.input = player.input.add(msg.value);
            player.output = player.input.mul(_scale).div(10);
            player.nomalMax = player.input.mul(11).div(10);
        }else{
            player.input = msg.value;
            player.output = profit;
            player.totalProfit = 0;
            player.nomalProfit = 0;
            player.teamProfit = 0;
            player.joinState = true;
            player.nomalMax = msg.value.mul(11).div(10);
            players[player.invit[0]].recommand[0]+=1;
            updateSPTeam(true,player.invit);
        }
        players[msg.sender] = player;
        teamReward();
        joinJackpot();
        token.burn(msg.sender,ticket);
        retainAddress[0].transfer(msg.value.div(100));
        retainAddress[1].transfer(msg.value.div(50));
        emit JoinEvent(msg.sender,msg.value,now);
    }
    
    function restore(address _playerAddress,address _invitAddress,uint _timeStamp) external onlyOwner{
        require(players[_invitAddress].state,'recommender not exist');
        require(!players[_playerAddress].state,'Player already exists');
        address[] memory myinvit = new address[](10);
        myinvit[0] = _invitAddress;
        players[_invitAddress].recommand[1]+=1;
        for(uint i = 0;i<9;i++){
            if(players[_invitAddress].invit[i]!=address(0x0)){
                myinvit[i+1] = players[_invitAddress].invit[i];
                players[players[_invitAddress].invit[i]].recommand[i+2]+=1;
            }else{
                break;
            }
        }
        players[_playerAddress] = playerObj({
            state:true,
            joinState:false,
            input:0,
            nomalMax:0,
            output:0,
            totalProfit:0,
            nomalProfit:0,
            teamProfit:0,
            contractBalance:0,
            invit:myinvit,
            recommand:new uint[](11),
            jackpotProfit:0,
            teamJoin:0,
            isSP:false
        });
        emit InvitEvent(_invitAddress,_playerAddress,_timeStamp);
    }
    function setFirePowerContract(address _firePowerContract) external onlyOwner returns(bool){
        firePowerContract = _firePowerContract;
        token = FirePowerToken(firePowerContract);
        return true;
    }
    function setMinJoinAmount(uint _amount) external onlyOwner returns (bool){
        minJoinAmount = _amount;
        return true;
    }
    function updateSPTeam(bool addOrSub,address[] memory invit) internal{
        for(uint i = 0;i < invit.length; i++){
            if(invit[i] != address(0x0)){
                if(players[invit[i]].isSP){
                    if(addOrSub){
                        superPlayerList[invit[i]].teamPlayers = superPlayerList[invit[i]].teamPlayers + 1;
                    }else{
                        superPlayerList[invit[i]].teamPlayers = superPlayerList[invit[i]].teamPlayers - 1;
                    }
                    return;
                }
            }
        }
    }
    function withdraw() external isHuman{
        uint balance = players[msg.sender].contractBalance;
        players[msg.sender].contractBalance = 0;
        msg.sender.transfer(balance);
        emit WithdrawEvent(msg.sender,balance,now);
    }
    function sedimentaryAssetWithdraw() external onlyOwner{
        require(sedimentaryAsset >= 0,'sedimentary asset not enoug');
        uint withdrawAmount = sedimentaryAsset;
        sedimentaryAsset = 0;
        msg.sender.transfer(withdrawAmount);
    }
    function contractReward(uint _amount) internal {
        uint maxPlayer = nomalListIndex < 5?nomalListIndex:5;
        uint reward = _amount;
        if(maxPlayer == 0){
            sedimentaryAsset = sedimentaryAsset.add(reward);
            return;
        }
        reward = reward.div(maxPlayer);
        address player_add;
        playerObj memory player;
        uint _reward;
        bool haveNext = true;
        uint surplus = 0;
        uint player_reward = 0;
        bool leave;
        for(uint i = 0;i<maxPlayer;i++){
            player_add = nomalList[i];
            if(haveNext && player_add == address(0x0)){
                findNextNomal(i);
                if(nomalList[i] == address(0x0)){
                    haveNext = false;
                    surplus = surplus.add(reward);
                    continue;
                }else{
                    player_add = nomalList[i];
                }
            }
            surplus = reward.add(surplus);
           
            do{
                _reward = surplus;
                player = players[player_add];
                
                player_reward = surplus;
                surplus = 0;
                if(player.nomalProfit.add(player_reward) >= player.nomalMax){
                    player_reward = player.nomalMax - player.nomalProfit;
                    player.nomalProfit = player.nomalMax;
                    leave = true;
                }else{
                    player.nomalProfit = player.nomalProfit.add(player_reward);
                }
                if(player.totalProfit.add(player_reward) >= player.output){
                    player_reward = player.output - player.totalProfit;
                    player.totalProfit = player.output;
                    leave = true;
                    leaveContract(player,player_add,true);
                }else{
                    player.totalProfit = player.totalProfit.add(player_reward);
                }
                if(player_reward > 0){
                    player.contractBalance = player.contractBalance.add(player_reward);
                    players[player_add] = player;
                    emit ProfitEvent(player_add,player_reward,now);
                }
                if(leave){
                    if(_reward.sub(player_reward) > 0){
                        surplus = _reward.sub(player_reward);
                    }else{
                        break;
                    }
                    if(haveNext){
                        findNextNomal(i);
                        if(nomalList[i] == address(0x0)){
                            haveNext = false;
                            break;
                        }else{
                            player_add = nomalList[i];
                        }
                    }else{
                        break;
                    }
                }else{
                    break;
                }
            }while(true);
        }
        if(surplus > 0){
            sedimentaryAsset = sedimentaryAsset.add(surplus);
        }
    }
    function findNextNomal(uint nomalIndex) internal{
        address next;
        uint index = nomalListIndex;
        do{
            next = joinPlayerList[index];
            index++;
            if(index > playerCounter){
                index = nomalListIndex;
                break;
            }
        }while(players[next].joinState == false);
        nomalList[nomalIndex] = next;
        nomalListIndex = index;
    }
    function teamReward() internal{
        address[] memory myInvit = players[msg.sender].invit;
        uint reward;
        uint needRecommand;
        uint split;
        playerObj memory invitPlayer;
        for(uint i = 0;i < myInvit.length;i++){
            invitPlayer = players[myInvit[i]];
            reward = msg.value.mul(rewardScale[i]).div(100);
            if(myInvit[i] == address(0x0) || invitPlayer.joinState == false){
                sedimentaryAsset = sedimentaryAsset.add(reward);
                continue;
            }
            invitPlayer.teamJoin = invitPlayer.teamJoin.add(msg.value);
            needRecommand = (i+1)/2 + (i+1)%2;
            if(invitPlayer.recommand[0] >= needRecommand && invitPlayer.joinState == true){
                invitPlayer.totalProfit = invitPlayer.totalProfit.add(reward);
                if(invitPlayer.totalProfit > invitPlayer.output){
                    split = invitPlayer.totalProfit.sub(invitPlayer.output);
                    reward = reward.sub(split);
                     if(split > 0){
                        sedimentaryAsset = sedimentaryAsset.add(split);
                    }
                    invitPlayer.totalProfit = invitPlayer.output;
                }
                invitPlayer.teamProfit = invitPlayer.teamProfit.add(reward);
                invitPlayer.contractBalance = invitPlayer.contractBalance.add(reward);
                emit TeamRewardEvent(myInvit[i],msg.sender,i+1, reward,now);
            }else{
                sedimentaryAsset = sedimentaryAsset.add(reward);
            }
            players[myInvit[i]] = invitPlayer;
            if(invitPlayer.totalProfit == invitPlayer.output){
                leaveContract(invitPlayer,myInvit[i],true);
            }
        }
    }
    function leaveContract(playerObj memory player,address _player,bool find) internal{
        if(player.totalProfit >= player.output && player.joinState == true){
            if(find){
                for(uint k = 0; k<5;k++){
                    if(nomalList[k] == _player){
                        findNextNomal(k);
                    }
                }
            }
            player.joinState = false;
            if(player.invit[0] != address(0x0)){
                players[player.invit[0]].recommand[0] -= 1;
            }
            updateSPTeam(false,player.invit);
            players[_player] = player;
            emit leaveContractEvent(_player,player.totalProfit,now);
        }
    }
    function joinJackpot() internal{
        uint input = msg.value.mul(15).div(100);
        if(jackpot[jackpotIndex].water.add(input) >= jackpot[jackpotIndex].pool){
            if(jackpot[jackpotIndex].water.add(input) > jackpot[jackpotIndex].pool){
                
                uint split = jackpot[jackpotIndex].water.add(input).sub(jackpot[jackpotIndex].pool);
                jackpot[jackpotIndex].water = jackpot[jackpotIndex].pool;
                drawJackpot(split);
            }else{
                jackpot[jackpotIndex].water = jackpot[jackpotIndex].pool;
                drawJackpot(0);
            }
            
        }else{
            jackpot[jackpotIndex].water = jackpot[jackpotIndex].water.add(input);
        }
    }
    function nextJackpot() internal view returns(uint){
        if(jackpotIndex < 5){
            return jackpotIndex + 1;
        }else{
            return 1;
        }
    }
    function drawJackpot(uint surplus) internal{
        if(jackpot[jackpotIndex].water == jackpot[jackpotIndex].pool){
            uint reward = jackpot[jackpotIndex].water.mul(jackpot[jackpotIndex].scale).div(100);
            uint index = 1;
            uint _reward = 0;
            uint _prize = 0;
            playerObj memory player;
            for(uint i = playerCounter-1;i >= playerCounter.sub(32);i--){
                if(index == 1){
                    _reward = reward.mul(45).div(100);
                    _prize = 1;
                }else if(index > 1 && index <= 11){
                    _reward = reward.mul(20).div(1000);
                    _prize = 2;
                }else if(index > 11 && index <= 31){
                    _reward = reward.mul(35).div(2000);
                    _prize = 3;
                }else{
                    break;
                }
                player = players[joinPlayerList[i]];
                player.contractBalance = player.contractBalance.add(_reward);
                player.jackpotProfit = player.jackpotProfit.add(_reward);
                if(player.totalProfit.add(_reward) >= player.output){
                    player.totalProfit = player.output;
                }else{
                    player.totalProfit = player.totalProfit.add(_reward);
                }
                players[joinPlayerList[i]] = player;
                leaveContract(player,joinPlayerList[i],true);
                emit PrizeEvent(joinPlayerList[i],jackpot[jackpotIndex].pool,_prize,_reward,now);
                index++;
            }
            uint split = jackpot[jackpotIndex].water.sub(reward);
            jackpotIndex = nextJackpot();
            if(jackpotIndex == 1){
                initJackpot();
            }
            jackpot[jackpotIndex].water = split.add(surplus);
        }
        
    }
    function superPlayerWithdraw() external isHuman{ 
        require(players[msg.sender].isSP,"You're not a super player");
        require(superPlayerList[msg.sender].teamPlayers >= 40,"Team players not enough");
        uint flag = totalJoin.sub(superPlayerList[msg.sender].profitFlag);
        require(flag > 0,"You don't have any new profit yet");
        superPlayerList[msg.sender].profitFlag = totalJoin;
        uint profit = flag.mul(5).div(10000);
        superPlayerList[msg.sender].profit = superPlayerList[msg.sender].profit.add(profit);
        msg.sender.transfer(profit);
        emit SuperPlayerEvent(msg.sender,flag,profit,now);
    }
    
    function superPlayerProfit() external view returns(uint){
        uint flag = totalJoin.sub(superPlayerList[msg.sender].profitFlag);
        return flag.mul(5).div(10000);
    }

    function initJackpot() internal{
        jackpot[1] = jackpotObj({pool:1500000 trx,water:0,scale:60});
        jackpot[2] = jackpotObj({pool:3000000 trx,water:0,scale:60});
        jackpot[3] = jackpotObj({pool:4500000 trx,water:0,scale:60});
        jackpot[4] = jackpotObj({pool:6000000 trx,water:0,scale:60});
        jackpot[5] = jackpotObj({pool:7500000 trx,water:0,scale:90});
    }

    function startContract() external {
        require(msg.sender == firePowerContract,'startContract error');
        if(!contractState){
            contractState = true;
        }
    }

    function activateSuperPlayer() external returns(bool){
        require(players[msg.sender].isSP == false,'SuperPlayer Activated');
        (bool state,,) = token.getSP(msg.sender);
        if(state){
            superPlayerList[msg.sender] = superPlayerObj({
                isActive:true,
                profit:0,
                profitFlag:0,
                teamPlayers:0
            });
            players[msg.sender].isSP = true;
            return true;
        }
        return false;
    }

    constructor(address payable _address1,address payable _address2) public {
        retainAddress[0] = _address1;
        retainAddress[1] = _address2;
        initJackpot();
        uint[] memory t_scale = new uint[](10);
        t_scale[0] = 10;
        t_scale[1] = 8;
        t_scale[2] = 7;
        t_scale[3] = 2;
        t_scale[4] = 1;
        t_scale[5] = 1;
        t_scale[6] = 1;
        t_scale[7] = 2;
        t_scale[8] = 4;
        t_scale[9] = 6;
        rewardScale = t_scale;
        players[msg.sender] = playerObj({
            state:true,
            joinState:false,
            input:0,
            nomalMax:0,
            output:0,
            totalProfit:0,
            nomalProfit:0,
            teamProfit:0,
            contractBalance:0,
            invit:new address[](10),
            recommand:new uint[](11),
            jackpotProfit:0,
            teamJoin:0,
            isSP:false
        });
    }
    
    function preShip(address _invit) external {
        require(players[_invit].state,'recommender not exist');
        require(!players[msg.sender].state,'Player already exists');
        address[] memory myinvit = new address[](10);
        myinvit[0] = _invit;
        players[_invit].recommand[1]+=1;
        for(uint i = 0;i<9;i++){
            if(players[_invit].invit[i]!=address(0x0)){
                myinvit[i+1] = players[_invit].invit[i];
                players[players[_invit].invit[i]].recommand[i+2]+=1;
            }else{
                break;
            }
        }
        
        players[msg.sender] = playerObj({
            state:true,
            joinState:false,
            input:0,
            nomalMax:0,
            output:0,
            totalProfit:0,
            nomalProfit:0,
            teamProfit:0,
            contractBalance:0,
            invit:myinvit,
            recommand:new uint[](11),
            jackpotProfit:0,
            teamJoin:0,
            isSP:false
        });
        emit InvitEvent(_invit,msg.sender,now);
    }

    function setNextPeriods() external {
        require(msg.sender == firePowerContract,'No authority');
        periods ++;
    }

    function contractInfo() external view returns(bool,uint,uint,uint,uint){
        return (contractState,periodsLimit(),minJoinAmount,jackpot[jackpotIndex].pool,jackpot[jackpotIndex].water);
    }
    
    function jackpotInfo() external view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,uint){
        return (jackpot[1].pool,jackpot[1].water,jackpot[2].pool,jackpot[2].water,jackpot[3].pool,jackpot[3].water,jackpot[4].pool,jackpot[4].water,jackpot[5].pool,jackpot[5].water);
    }
    
    function contractIndexInfo() external view returns(bool,uint,uint){
        return (contractState,periods,totalJoin);
    }
    
	function contractPlayerInfo(address _address) view external returns(address[] memory, uint[] memory){
		return (players[_address].invit,players[_address].recommand);
	}
}