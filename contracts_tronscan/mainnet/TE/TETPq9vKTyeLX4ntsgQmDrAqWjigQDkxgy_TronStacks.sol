//SourceUnit: TronStacks.sol

/*
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


     /$$$$$$$$                                   /$$$$$$   /$$                         /$$                
    |__  $$__/                                  /$$__  $$ | $$                        | $$                
       | $$  /$$$$$$   /$$$$$$  /$$$$$$$       | $$  \__//$$$$$$    /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$$
       | $$ /$$__  $$ /$$__  $$| $$__  $$      |  $$$$$$|_  $$_/   |____  $$ /$$_____/| $$  /$$/ /$$_____/  
       | $$| $$  \__/| $$  \ $$| $$  \ $$       \____  $$ | $$      /$$$$$$$| $$      | $$$$$$/ |  $$$$$$ 
       | $$| $$      | $$  | $$| $$  | $$       /$$  \ $$ | $$ /$$ /$$__  $$| $$      | $$_  $$  \____  $$
       | $$| $$      |  $$$$$$/| $$  | $$      |  $$$$$$/ |  $$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$ /$$$$$$$/
       |__/|__/       \______/ |__/  |__/       \______/   \___/   \_______/ \_______/|__/  \__/|_______/                                                                                           



    Website: https://tronstacks.com/
    Backup url: https://tronstacksdefi.github.io/
    Twitter: https://twitter.com/TronStacksDefi
    Telegram News: https://t.me/TronStacksOfficial
    Telegram Chat: https://t.me/TronStacksChat
    YouTube: https://www.youtube.com/channel/UC5kda5Qi_2hAavzQCeCLdUw


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity 0.5.9;

contract TronStacks{
    using SafeMath for uint256;
    
    address payable public refAddress; //base address referral
    address payable public devAddress; //developer address
    
    uint256 constant public PERCENTAGEDIV = 10000;
    uint256 constant public PRELAUNCHDAYS = 3 days; //duration of the prelaunch in days
    uint256 constant public DEVFEE = 250; //2.5% fee for developers
    uint256 constant public HOLDBONUS = 8; //0.08% for every day without withdraw
    uint256 constant public CONTRACT_PERCENTS_STEP = 1000000 trx; //1 million
    uint256[] public REFERRAL_PERCENTS = [250, 200, 150, 100, 50]; //referral 2.5%, 2%, 1.5%, 1%, 0.5% directly payed to the referred address
    uint256 constant public TIME_STEP = 1 days;
    
    Tarif[] public tarifs; 
    uint256 public totalContractDeposit;
    uint256 public totalContractWithdraw;
    uint256 public totalPlayers;
    uint256 public dateDeployment;
    
    struct Player {
        address payable referral; //who invite him
        uint256 lastWithdraw;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        Deposit[] deposits; //array of deposits
    }
    struct Deposit {
        uint256 value; //how much
        bool valid;   //false means that the user can withdraw it, true means that it's already been withdrawn
        uint256 time;   //when
        uint8 tarif;    //tarif selected, an integer that identify it
    }
    struct Tarif {
        uint256 minDeposit; //min deposit for this tarif
        uint256 maxDays; //max duration of the tarif in days
        uint256 percent; //dayly percentage
    }
    
    mapping(address => Player) private players;
    
    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    //CONSTRUCTOR
    constructor(address payable baseRef, address payable baseDev) public{
        refAddress = baseRef;
        devAddress = baseDev;
        tarifs.push(Tarif(1 trx, 150 days, 100)); //min 1trx, 150days, 1% daily 
        tarifs.push(Tarif(5000 trx, 175 days, 100)); //min 5000trx, 175days 1% daily
        tarifs.push(Tarif(20000 trx, 200 days, 100)); //min 20000trx, 200days, 1% daily 
        tarifs.push(Tarif(50000 trx, 240 days, 100)); //min 50000trx, 240days, 1% daily
        dateDeployment = block.timestamp;
    }
    
    //NEW DEPOSIt FUNCTION
    function deposit(address payable referredAdd, uint8 tarifNum)external payable{
        require (tarifNum >= 0 && tarifNum < 2, "tarifNum inesistente");
        require (msg.value >= tarifs[tarifNum].minDeposit, "you should deposit more trx for this tarif");
        
        Player storage player = players[msg.sender];
        if(dateDeployment + PRELAUNCHDAYS > block.timestamp){ //true means we are in the prelaunch
        
            devAddress.transfer(msg.value.mul(DEVFEE).div(PERCENTAGEDIV)); //developer fee payed
            refAddress.transfer(msg.value.mul(DEVFEE).div(PERCENTAGEDIV)); //referral payd (same as developer during prelaunch)
            if(player.referral == address(0)){
                player.referral = refAddress; 
            }
            emit FeePayed(msg.sender, msg.value.mul(DEVFEE+DEVFEE).div(PERCENTAGEDIV));
            if(player.deposits.length == 0){ //new user
                player.lastWithdraw = dateDeployment;  //whoever deposit during prelaunch will receive a holding bonus equal to the duration of the prelaunch
                totalPlayers += 1;
                emit Newbie(msg.sender);
            }
            player.deposits.push(Deposit(msg.value, true, (dateDeployment+PRELAUNCHDAYS), tarifNum));
            player.totalDeposit = player.totalDeposit.add(msg.value);
            totalContractDeposit = totalContractDeposit.add(msg.value);
            emit NewDeposit(msg.sender, msg.value);
        }
        else{ //prelaunch ended
            
            devAddress.transfer(msg.value.mul(DEVFEE).div(PERCENTAGEDIV));
            if(player.referral == address(0) && players[referredAdd].deposits.length > 0 && referredAdd != msg.sender){
                player.referral = referredAdd;
            }
            else if(player.referral == address(0)){
                player.referral = refAddress;
            }//assign the referral
            
            address payable upline = player.referral;
            for(uint i=0; i<REFERRAL_PERCENTS.length; i++){
                if(upline != address(0)){
                    upline.transfer(msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTAGEDIV));
                    emit RefBonus(upline, msg.sender, i, msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTAGEDIV));
                    upline = players[upline].referral;
                }
                else {
                    if(i == 0 || i == 1 || i == 3){
                        refAddress.transfer(msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTAGEDIV));
                    }
                    else{
                        devAddress.transfer(msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTAGEDIV));
                    }
                }
            }
            if(player.deposits.length == 0){ //new user
                player.lastWithdraw = block.timestamp;
                totalPlayers += 1;
                emit Newbie(msg.sender);
            }
            player.deposits.push(Deposit(msg.value, true, block.timestamp, tarifNum));
            player.totalDeposit = player.totalDeposit.add(msg.value);
            totalContractDeposit = totalContractDeposit.add(msg.value);
            emit NewDeposit(msg.sender, msg.value);
            
        }
    }
    
    //WITHDRAW FUNCTION
    function withdraw(uint256 numDeposit)external{
        require (dateDeployment + PRELAUNCHDAYS < block.timestamp, "Cannot wiwthdraw during prelaunch");
        require (players[msg.sender].deposits.length > 0, "User has no deposit");
        require (numDeposit < players[msg.sender].deposits.length, "numDeposit invalid");
        require (players[msg.sender].deposits[numDeposit].valid, "Already withdraw");
        Player storage player = players[msg.sender];
        Deposit memory dep = player.deposits[numDeposit];
        Tarif memory tar = tarifs[dep.tarif];
     
        
        uint256 totalAmount;
        uint256 userPercentRate = getPlayerPercentRate(msg.sender, numDeposit);
        uint256 duration;
        if(block.timestamp.sub(dep.time).div(TIME_STEP) >= tar.maxDays){
            duration = tar.maxDays.div(1 seconds);
        }
        else{
            duration = block.timestamp.sub(dep.time).div(1 seconds);
        }

        totalAmount = ((dep.value.mul(tar.percent.mul(duration))).div(86400)).div(PERCENTAGEDIV);
        totalAmount = totalAmount.add((((dep.value.mul(userPercentRate.mul(duration))).div(86400)).div(PERCENTAGEDIV)).div(2));
        if(totalAmount > (dep.value.mul(tar.percent.mul(tar.maxDays.div(1 days)))).div(PERCENTAGEDIV)){
            totalAmount = (dep.value.mul(tar.percent.mul(tar.maxDays.div(1 days)))).div(PERCENTAGEDIV);
        }
        require(totalAmount > 0, "User has no dividends");
        
        uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		player.lastWithdraw = block.timestamp;
		msg.sender.transfer(totalAmount);
		player.totalWithdraw = player.totalWithdraw.add(totalAmount);
		totalContractWithdraw = totalContractWithdraw.add(totalAmount);
		player.deposits[numDeposit].valid = false;
        
        emit Withdrawn(msg.sender, totalAmount);
    }
    
    
    ////GETTER FUNCTIONS
    
    function getContractBalance() public view returns (uint256) {
			return address(this).balance;
		}
	
    function getPreLaunchDuration() public view returns (uint256){
        
        return (dateDeployment + PRELAUNCHDAYS <= block.timestamp ? 0 : (dateDeployment.add(PRELAUNCHDAYS)).sub(block.timestamp));
    }

    function getPlayerHoldPercent(address playerAddress, uint256 numDeposit) external view returns (uint256) {
		if (isActive(playerAddress)) {
		    Player storage player = players[playerAddress];
            Deposit memory dep = player.deposits[numDeposit];
            uint256 timeMultiplier = 0;
            if(getPreLaunchDuration() > 0){
                timeMultiplier = PRELAUNCHDAYS;
            }
			timeMultiplier = ((timeMultiplier.add(block.timestamp)).sub(dep.time)).div(TIME_STEP);
			return (timeMultiplier * HOLDBONUS); //returned multiplied by 10000 -> return 8 instead of 0.0008
		} else {
            return 0;
        }
    }
    
    function getPlayerPercentRate(address playerAddress, uint256 numDeposit) public view returns (uint256) {
		Player storage player = players[playerAddress];
        Deposit memory dep = player.deposits[numDeposit];
		uint256 contractBalanceRate = getContractBalanceRate();
        uint256 timeMultiplier = 0;
		if (isActive(playerAddress)) {
			if(getPreLaunchDuration() > 0){
                timeMultiplier = PRELAUNCHDAYS;
            }
			timeMultiplier = ((timeMultiplier.add(block.timestamp)).sub(dep.time)).div(TIME_STEP);
			if(timeMultiplier > 125){
			    timeMultiplier = 125; //MAX 10% hold bonus
			}
			return contractBalanceRate.add(timeMultiplier * HOLDBONUS); //0.08% every day without withdrawing
		} else {
			return contractBalanceRate;
		}
	}
	
	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_PERCENTS_STEP);
        if(contractBalancePercent > 20){
            contractBalancePercent = 20; //max 2%
        }
        
		return contractBalancePercent * 10; //0.1% every 1m trx
	}
    
	function getPlayerNumberOfDeposits(address playerAddress) public view returns (uint256) {
		return players[playerAddress].deposits.length;
	}
	
	function getPlayerTotalDeposits(address playerAddress) public view returns (uint256) {
	    return players[playerAddress].totalDeposit;
	}
	function getPlayerTotalWithdraw(address playerAddress) public view returns (uint256) {
	    return players[playerAddress].totalWithdraw;
	}
	
	function isActive(address playerAddress) public view returns (bool) {
		Player storage player = players[playerAddress];

		if (player.deposits.length > 0) {
			for(uint256 i=0; i<player.deposits.length; i++){
					if(player.deposits[i].valid){
							return true;
					}
			}
		}
		return false;
	}
	
	function getTarif(uint8 tarifNum) public view returns (uint256, uint256, uint256){
	    require (tarifNum < tarifs.length, "Numero tariffa non esistente");
	    return (
	        tarifs[tarifNum].minDeposit,
	        tarifs[tarifNum].maxDays,
	        tarifs[tarifNum].percent
	    );
	}
	
	function getPlayerDepositInfo(address playerAddress, uint256 index) public view returns (uint256, bool, uint256, uint8) {
	    Player storage player = players[playerAddress];
	    return (
            player.deposits[index].value,
            player.deposits[index].valid,
            player.deposits[index].time,
            player.deposits[index].tarif
        );
	}
    
    function getPlayerDepositGain(address playerAddress, uint256 numDeposit) public view returns (uint256,  uint256, uint8, uint256) {
	    require (players[playerAddress].deposits.length > 0, "User has no deposit");
        require (numDeposit < players[playerAddress].deposits.length, "numDeposit invalid");
        require (players[playerAddress].deposits[numDeposit].valid, "Already withdraw");
	    Player storage player = players[playerAddress];
        Deposit memory dep = player.deposits[numDeposit];
        Tarif memory tar = tarifs[dep.tarif];
        
        
        uint256 totalAmount;
        uint256 userPercentRate = getPlayerPercentRate(playerAddress, numDeposit);
        
        uint256 duration;
        if(dateDeployment + PRELAUNCHDAYS < block.timestamp){
            if((block.timestamp.sub(dep.time)).div(TIME_STEP) >= tar.maxDays){
                duration = tar.maxDays.div(1 seconds);
            }
            else{
                duration = (block.timestamp.sub(dep.time)).div(1 seconds);
            }
            totalAmount = ((dep.value.mul(tar.percent.mul(duration))).div(86400)).div(PERCENTAGEDIV);
            totalAmount = totalAmount.add((((dep.value.mul(userPercentRate.mul(duration))).div(86400)).div(PERCENTAGEDIV)).div(2));
            uint256 contractBalance = address(this).balance;
            if(totalAmount > (dep.value.mul(tar.percent.mul(tar.maxDays))).div(PERCENTAGEDIV)){
            totalAmount = ((dep.value.mul(tar.percent.mul(tar.maxDays))).div(PERCENTAGEDIV));
            }
            if (contractBalance < totalAmount) {
                totalAmount = contractBalance;
            }
        }
        else{
            duration = 0;
            totalAmount = 0;
        }


        
        return(
            dep.value,
            duration,
            dep.tarif,
            totalAmount
        );
        
	}
    
    
    
}












library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}