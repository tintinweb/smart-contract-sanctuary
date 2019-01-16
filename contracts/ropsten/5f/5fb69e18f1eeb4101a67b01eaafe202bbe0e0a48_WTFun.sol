//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                           $$$            $$$$$$$$$$$$$$                                                      // 
//      $$$                 $$$$      $$$$$$$$$$$$      $   $$$$$$$$$$$$$$                                      // 
//     $$$$                 $$$    $$$$$$$  $$$            $$$$$$$$                                             // 
//     $$$        $$        $$$     $$      $$$            $$$                                                  // 
//    $$$        $$$       $$$$            $$$            $$$               $$       $$$       $$$   $$$$       // 
//   $$$        $$$        $$$             $$$            $$$              $$$       $$$      $$$$$$$$$$$$$     //
//  $$$$       $$$$       $$$             $$$            $$$    $$$$$      $$$      $$$$     $$$$$$    $$$      //
//  $$$       $$$$$      $$$              $$$           $$$$$$$$$$$$$     $$$       $$$      $$$$      $$$      //
// $$$       $$$$$      $$$              $$$           $$$$$$            $$$$      $$$$     $$$       $$$       //
// $$$     $$$ $$$$    $$$               $$$           $$$$              $$$      $$$$$    $$$       $$$$       //
//$$$$   $$$$   $$$   $$$               $$$            $$$               $$$    $$$$$$$    $$$       $$$        // 
// $$$$$$$$      $$$$$$                 $$$            $$$                $$$$$$$   $$$    $$$      $$$         //
// $$$$$$                                              $$                   $$$                                 //
//                                                                                                              //
// website: https://wt2.fun                                                                                     //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.4.24;

contract WTFun{
	// bet condition
	uint constant MIN_BET = 0.01 ether;
	uint constant MAX_BET = 20000 ether;
	uint constant MAX_BET_PROFIT = 100000 ether;
	uint constant MIN_JPOT_BET = 0.1 ether;
	uint constant JPOT_MODULO = 5000;
	uint constant BONUS_PERCENT_JPOT= 5;
	uint constant BET_EXPIRATION_BLOCKS = 250;	

	// bet odds
	uint constant BAC_ODDS = 1985;
	uint constant G8_ODDS = 788;
	uint constant RACE_ODDS = 788;
	uint constant NUM_THOUSAND = 1000;
	uint constant NUM_HUNDRED = 100;
	uint constant TWO_XBIT_MASK = 0x11;
	uint constant EIGHT_XBIT_MASK = 0x11111111;
	uint constant HEXBASE = 16;

	// round constant
	uint constant PROFIT_BASE = 10 ** 25;
//testing	//uint constant INVEST_BASE = 100 ether;
	uint constant INVEST_BASE = 2 ether;
	uint constant ONE_MIN_INVEST = 0.05 ether;
	uint constant ONE_MAX_INVEST = 20 ether;
	uint constant ROUND_MAX_RECORD = 5;
	uint constant PROFIT_PERCENT_INVESTORS = 80;
	uint constant PROFIT_PERCENT_DEV = 20;
	uint constant BONUS_PERCENT_PROMOTER = 3;
	uint constant ROUND_AMAN_LIMIT = 10;

	// role
	address public randomPromiseSign;	// a door : pair of (key,door) ensure randomness. 
	address public drawer;				// service: draw a bet	
	address public manager;				// WTFUn  : manage dev and drawer account, no privileage.
	address public dev;					// WTFun  : only receive round profit, no privilege.
	
	// Bet data
	struct Bet {
        uint8 choice;
        uint40 placeBlockNumber;
        uint amount;
        uint betMask;
		address player; 
	}	

	// investor info in this round
	struct Investor{
		OneInvest[] investinfo; 
		uint gotProfit;
	}

	// runtime per invest info
	struct OneInvest{
		uint amount;
		uint joinProfit;
	}

	// promoter info
	struct Promoter{
		uint bonus;
		uint gotBonus;
	}

	// jackpot winner
	struct JpotWinner{
		address winner;	
		uint winTime;
		uint amount;	
	}


	// Invest & promote round 
	struct Round{
		uint round;					// round counter
		uint minInvest;				// min invest,see whitepaper
		uint maxInvest;				// max invest,see whitepaper
		uint invest;				// runtime invest amoount 
		uint profit;				// runtime profit
		uint profitDivBeginTime;    // time record to div profit
		uint profitWithdrawTime;	// meet withdraw time
		uint numOfInvestor;			// num of investor
		uint numOfPromoter;			// num of promoter
		uint profitPromoter;		// profit of promoter
		JpotWinner jpotWinner;		// the newest one jpotWinner in this round
		uint devGotProfit;			// dev taken profit
		mapping (address => Investor) investors;		// investors info in this round
		mapping (address => Promoter) promoters;		// promoters info in this round
	}

	uint public maxBetProfit;
	mapping (uint => Bet) public bets;
	Round[] public rounds;
	mapping (address => address ) public player2Promoter;

	// bet event
	event PayFail(address payee,uint256 amount);
	event PaySucc(address payee,uint256 amount);
	event PayJackpot(address winner,uint256 amount);
	event Commit(uint256 commit);
	event ResultChoice3(uint8[] result);

	// invest & promote event
	event InvestSucc(address _investor,uint256 amount,uint256 joinProfit);
	event PayInvestorSucc(address _investor,uint256 amount);
	event PayInvestorFail(address _investor,uint256 amount);
	event PayPromoterSucc(address _promoter ,uint256 amount);
	event PayPromoterFail(address _promoter ,uint256 amount);
	event PayDevSucc(address _dev,uint256 amount);
	event PayDevFail(address _dev,uint256 amount);

	constructor () public {
		drawer = msg.sender;
		dev = msg.sender;
		manager = msg.sender;
		randomPromiseSign = msg.sender;

		maxBetProfit = MAX_BET_PROFIT;
		rounds.length++;
		updateRound();
	}


	modifier onlyDrawer{
		require ( msg.sender == drawer || msg.sender == manager, "OnlyDrawer access deny" );
		_;
	}

	modifier onlyDev{
		require ( msg.sender == dev || msg.sender == manager, "OnlyDev access deny" );
		_;
	}


	function newManager(address _newManager) external {
		require(msg.sender == manager ,"only manager");
		manager = _newManager;
	}

	function newDrawer(address _drawer) external onlyDrawer{
		drawer = _drawer;
	}

	function newDev(address _dev) external onlyDev{
		dev = _dev;
	}

	function setRandomSign(address _randomSign ) external onlyDrawer{
		randomPromiseSign = _randomSign;
	}

	function setMaxProfit(uint _maxProfit) public onlyDrawer{
		maxBetProfit = _maxProfit;
	}

	function () public payable{}


	function makeBet(uint betMask,uint choice,uint betBlock, uint commitLastBlock,uint commit,bytes32 r,bytes32 s,address promoter) external payable{
        // Check that the bet is in &#39;clean&#39; state.
        Bet storage bet = bets[commit];
        require (bet.player == address(0), "Bet can&#39;t reuse");

        // Validate input data ranges.
        uint amount = msg.value;
        require (choice >= 1 && choice <= 3, "Only 3 game");
        require (amount >= MIN_BET && amount <= MAX_BET, "Amount out of range.");
		require (maxBetProfit > 0 , &#39;Bet closed&#39;);

        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
		require ( ecrecover(signatureHash, 27, r, s) == randomPromiseSign, "ECDSA signature is not valid.");

		address player = msg.sender;

		// bind player to promoter
		if( (promoter != address(0x0)) && (player2Promoter[player] == address(0x0)) ){
			player2Promoter[player] = promoter;
		}

		emit Commit(commit);

        bet.choice = uint8(choice);
        bet.placeBlockNumber = uint40(betBlock);
        bet.amount = amount;
        bet.betMask = betMask;
        bet.player = player;
	}

    function settleBet(uint reveal, bytes32 blockHash) external onlyDrawer {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number > placeBlockNumber, "SettleBet in the same block as placeBet, or before.");
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can&#39;t be queried by EVM.");
		require ( blockhash(placeBlockNumber) == blockHash , "blockhash not equal" );

        uint amount = bet.amount;
        uint choice = bet.choice;
		uint betMask = bet.betMask;
        address player = bet.player;

        // Check that bet is in &#39;active&#39; state.
        require (amount != 0, "Bet had been drawn.");
		require( 1 <= choice && choice <= 3, "Wrong choice");

        // Move bet into &#39;processed&#39; state already.
        bet.amount = 0;

        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockHash));
        uint8[] memory result = getResult(entropy,choice);

		uint gameWin = getWin(choice,amount,betMask,result);

		uint jpotWin;
        if (amount >= MIN_JPOT_BET) {
            uint jpotRng = (uint(entropy) / choice) % JPOT_MODULO;

            if (jpotRng == 0) {
				Round storage round = rounds[rounds.length-1];
				if( round.profit > PROFIT_BASE ) {
					jpotWin = (round.profit - PROFIT_BASE) * BONUS_PERCENT_JPOT / NUM_HUNDRED;
				}
            }
        }

        // Log jackpot win.
        if (jpotWin > 0) {
			Round storage rnd = rounds[rounds.length-1];
			rnd.jpotWinner.winner = player;
			rnd.jpotWinner.amount = jpotWin;
			rnd.jpotWinner.winTime = now;

            emit PayJackpot(player, jpotWin);
        }

		if( choice == 3 ) emit ResultChoice3(result);

		// promtoter bonus
		recordPromoterBonus(player, amount);

		// round profit
		recordRoundProfit(amount, gameWin+jpotWin);

        // Send the funds to gambler.
        sendFunds(player, gameWin + jpotWin == 0 ? 1 wei : gameWin + jpotWin, gameWin);
	}

	// validate bet , avoid gas leak attack
	function getBetInfo( uint commit ) public view returns(uint betMask, uint amount) {
        Bet storage bet = bets[commit];
		betMask = bet.betMask;
		amount = bet.amount;
	}

	function getWin(uint choice, uint amount, uint betMask, uint8 []result) private pure returns(uint gameWin){
		uint avgAmount = getAvgAmount( betMask, amount);
        if( choice == 1){
            if( ((HEXBASE ** (result[0]%2)) & ( betMask & TWO_XBIT_MASK )) != 0 ) gameWin = (avgAmount * BAC_ODDS / NUM_THOUSAND);
        }else if( choice == 2){
            if( ((HEXBASE ** (result[0]-1)) & (betMask & EIGHT_XBIT_MASK)) != 0 ) gameWin = (avgAmount * G8_ODDS / NUM_HUNDRED);
        }else if( choice == 3){
			require( result.length == 8,&#39;Result not enough&#39;);
            for(uint8 i = 0; i<result.length;i++){
                if( ((HEXBASE ** i) & ((betMask >> (result[i]-1)*32) & EIGHT_XBIT_MASK)) != 0) gameWin += (avgAmount * RACE_ODDS / NUM_HUNDRED);
            }
        }
	}
	
	function getResult( bytes32 entropy ,uint choice) private pure returns(uint8 []result){
		uint8 numopen;
		result = new uint8[](8);
		uint8 counter = 0;
        for( uint8 i = 252;i>0;i-=4){
            uint8 value = uint8((entropy>> i) & 0xff) % 8;
            uint8 bit = uint8(2**value);
            if( (bit & numopen) == 0 ){
                numopen |= bit;
                result[counter] = (value+1);
				counter++;
            }
            
            if( counter==1 && ((choice == 1) || (choice == 2)) )break;
            if( counter==8 && choice == 3)break;
        }
	}

	function getAvgAmount(uint betMask,uint amount) private pure returns(uint avgAmount){
        uint8 betCount = 0;
        for(uint8 i=0;i<64;i++){
            if( (betMask & (HEXBASE ** i)) != 0 ) betCount++;
        }
        
        avgAmount = amount / betCount;
    }	

    function sendFunds(address player, uint amount, uint successLogAmount) private {
        if (player.send(amount)) {
            emit PaySucc(player, successLogAmount);
        } else {
            emit PayFail(player, amount);
        }
    }

	function updateRound() private{
		Round storage rd2Check = rounds[rounds.length-1];
		uint preWithdrawTime = rd2Check.profitWithdrawTime;
		if( (preWithdrawTime != 0) && (now >= preWithdrawTime) ){
			rounds.length++;
			rd2Check = rounds[rounds.length-1];
		}

		// init round
		if( rd2Check.round == 0 ){
			uint totalRounds = rounds.length;
			rd2Check.round = totalRounds;
			rd2Check.minInvest = (totalRounds * INVEST_BASE) ;
			rd2Check.maxInvest = (totalRounds * INVEST_BASE * 2);
			rd2Check.profit = PROFIT_BASE;
		}	

		// start withdraw timer
		if( (rd2Check.profitWithdrawTime == 0) && (rd2Check.invest > rd2Check.minInvest) ){
			uint time = now;
			rd2Check.profitDivBeginTime = time;

//testing 			//rd2Check.profitWithdrawTime = now + 1 weeks;
			rd2Check.profitWithdrawTime = time  + 3 minutes;
		}
	}

	function recordPromoterBonus (address player, uint amount) private {
		Round storage round = rounds[rounds.length-1];
		address promoterAddr = player2Promoter[player];
		if( promoterAddr != address(0x0) ){
			if( round.promoters[promoterAddr].bonus == 0 ) round.numOfPromoter++;

			uint bonus = (amount * BONUS_PERCENT_PROMOTER / NUM_THOUSAND );
			round.promoters[promoterAddr].bonus += bonus;
			round.profitPromoter += bonus;
			round.profit -= bonus;
		}
	}

	function recordRoundProfit(uint amount, uint gameWin) private{
		Round storage round = rounds[rounds.length-1];
		if( gameWin > amount ) {
			round.profit -= (gameWin-amount);
		}else{
			round.profit += (amount-gameWin);

			if( gameWin == 0 ) round.profit -= 1 wei;
		}
	}


	function _withdrawInvestor(address payee,uint amount) private{
        if (payee.send(amount)) {
            emit PayInvestorSucc(payee, amount);
        } else {
            emit PayInvestorFail(payee, amount);
        }
	}

	function _withdrawPromoter(address payee,uint amount) private{
        if (payee.send(amount)) {
            emit PayPromoterSucc(payee, amount);
        } else {
            emit PayPromoterFail(payee, amount);
        }
	}

	function _withdrawDev(address payee,uint amount) private{
        if (payee.send(amount)) {
            emit PayDevSucc(payee, amount);
        } else {
            emit PayDevFail(payee, amount);
        }
	}

	function Invest() public payable{
		updateRound();

		uint amount = msg.value;
		address investAddr = msg.sender;
		Round storage rnd = rounds[rounds.length-1];
		Investor storage investor = rnd.investors[investAddr];

		require( (ONE_MIN_INVEST <= amount) && (amount <= ONE_MAX_INVEST), &#39;invalid invest amount&#39; );
		require( (rnd.invest + amount) <= rnd.maxInvest, &#39;invest of a round out of range&#39; );
		require( investor.investinfo.length < ROUND_AMAN_LIMIT, &#39;person 10 invest times limited in a round&#39; );

		if( investor.investinfo.length == 0 ) {
			rnd.numOfInvestor++;
		}

		uint investThisRound = 0;
		for( uint i=0;i<investor.investinfo.length;i++ ){
			investThisRound += investor.investinfo[i].amount;
		}
		investThisRound += amount;

		// address invest in this round check
		require( ((ONE_MIN_INVEST <= investThisRound) && (investThisRound <= ONE_MAX_INVEST)), &#39;person 20 eth limit in a round&#39; );

		uint profit = rnd.profit;
		OneInvest memory newInvest;
		newInvest.amount = amount;
		newInvest.joinProfit = (profit > PROFIT_BASE) ? profit : PROFIT_BASE;
		investor.investinfo.push(newInvest);

		rnd.invest += amount;

		updateRound();
		emit InvestSucc(investAddr,amount,profit);
	}

	function calProfitDev( Round storage round ) private returns(uint devRoundProfit) {
		uint roundProfit = round.profit;
		if( roundProfit > PROFIT_BASE ) {
			devRoundProfit = (roundProfit - PROFIT_BASE) * PROFIT_PERCENT_DEV / NUM_HUNDRED;
			if( round.devGotProfit == 0 && (devRoundProfit > round.devGotProfit) ) {
				round.devGotProfit = devRoundProfit;
			}else{
				devRoundProfit = 0;
			}
		}
	}

	// write
	function calcProfitInvestor(address payee, Round storage round) private returns(uint payeeRoundProfit){
		Investor storage investor = round.investors[payee];
		for( uint j=0; j < investor.investinfo.length; j++ ){
			uint amount  = investor.investinfo[j].amount;
			uint joinProfit = investor.investinfo[j].joinProfit;
			uint roundProfit = round.profit;
			uint roundInvest = round.invest;

			if( roundProfit >= joinProfit ) {
				payeeRoundProfit += (amount + (amount * (roundProfit - joinProfit)*PROFIT_PERCENT_INVESTORS/NUM_HUNDRED/roundInvest) );
			}else{
				uint loseProfit = (amount * (joinProfit - roundProfit)/roundInvest);
				payeeRoundProfit += ((amount > loseProfit) ? (amount - loseProfit) : 0);
			} 
		}

		if( (investor.gotProfit == 0) && (payeeRoundProfit > 0) ){
			investor.gotProfit = payeeRoundProfit;
		}else{
			payeeRoundProfit = 0;
		}
	}

	// read
	function calcProfitInvestorForRead(address payee, uint roundIdx) public view returns(uint payeeRoundProfit){
		Round storage round = rounds[roundIdx];
		Investor storage investor = round.investors[payee];
		for( uint j=0; j < investor.investinfo.length; j++ ){
			uint amount  = investor.investinfo[j].amount;
			uint joinProfit = investor.investinfo[j].joinProfit;
			uint roundProfit = round.profit;
			uint roundInvest = round.invest;

			if( roundProfit >= joinProfit ) {
				payeeRoundProfit += (amount + (amount * (roundProfit - joinProfit)*PROFIT_PERCENT_INVESTORS/NUM_HUNDRED/roundInvest) );
			}else{
				uint loseProfit = (amount * (joinProfit - roundProfit)/roundInvest);
				payeeRoundProfit += ((amount > loseProfit) ? (amount - loseProfit) : 0);
			} 
		}

		if( payeeRoundProfit >= investor.gotProfit ) {
			payeeRoundProfit = payeeRoundProfit - investor.gotProfit;
		}
	}

	// write
	function calLast5RoundProfit(uint roundLength) private returns(uint profitInvest5Round, uint profitPromoter5Round, uint profitDev5Round) {
		uint beginRound = ((roundLength > ROUND_MAX_RECORD) ? (roundLength-ROUND_MAX_RECORD-1) : (0));
		uint endRound = roundLength-2;
		address payee = msg.sender;
		for( uint i=beginRound; i<=endRound; i++ ){
			Round storage round = rounds[i];

			// investor 
			// capital + profit
			profitInvest5Round += calcProfitInvestor(payee, round);

			// promoter bonus	
			Promoter storage promoter = round.promoters[payee];
			uint bonus = promoter.bonus;
			uint gotBonus = promoter.gotBonus;
			if( bonus > gotBonus ) {
				profitPromoter5Round += (bonus-gotBonus);
				promoter.gotBonus = bonus;
			}

			// dev profit
			if( payee == dev ) {
				profitDev5Round += calProfitDev(round);
			}
		}
	}

	//read
	function calLast5RoundProfitForRead(uint roundLength ) public view returns(uint profitInvest5Round, uint profitPromoter5Round) {
		uint beginRound = ((roundLength > ROUND_MAX_RECORD) ? (roundLength-ROUND_MAX_RECORD-1) : (0));
		uint endRound = roundLength-2;
		address payee = msg.sender;
		for( uint i=beginRound; i<=endRound; i++ ){
			Round storage round = rounds[i];

			// investor 
			// capital + profit
			profitInvest5Round += calcProfitInvestorForRead(payee, i);
			
			// promoter bonus	
			Promoter memory promoter = round.promoters[payee];
			uint bonus = promoter.bonus;
			uint gotBonus = promoter.gotBonus;
			if( bonus > gotBonus ) {
				profitPromoter5Round += (bonus-gotBonus);
			}
		}
	}


	function withdraw() public {
		updateRound();

		uint roundLength = rounds.length;
		require(roundLength >= 2, &#39;not enough round&#39;);
		uint profitInvest5Round = 0;
		uint profitPromoter5Round = 0;
		uint profitDev5Round = 0;
		address payee = msg.sender;

		(profitInvest5Round, profitPromoter5Round, profitDev5Round) = calLast5RoundProfit(roundLength);

		if( profitInvest5Round > 0 ){
			_withdrawInvestor(payee, profitInvest5Round);
		}

		if( profitPromoter5Round > 0 ){
			_withdrawPromoter(payee, profitPromoter5Round);
		}

		if( payee == dev && profitDev5Round > 0 ){
			_withdrawDev(dev, profitDev5Round);
		}
	}


	function investInfo() public view returns(uint round, uint minInvest, uint maxInvest, uint invest, uint profit, uint nowTime, uint profitDivBeginTime, uint profitWithdrawTime,uint numOfInvestor){
		Round storage rnd = rounds[rounds.length-1];
		round = rnd.round;	
		minInvest = rnd.minInvest;
		maxInvest = rnd.maxInvest;
		invest = rnd.invest;
		profit = (rnd.profit > PROFIT_BASE) ? (rnd.profit-PROFIT_BASE) : 0 ;
		nowTime = now;
		profitDivBeginTime = rnd.profitDivBeginTime;
		profitWithdrawTime = rnd.profitWithdrawTime;
		numOfInvestor = rnd.numOfInvestor;
	}

	function promoterInfo() public view returns(uint numOfPromoter, uint profitPromoter){
		Round storage rnd = rounds[rounds.length - 1];
		numOfPromoter = rnd.numOfPromoter;
		profitPromoter = rnd.profitPromoter;
	}

	function personalInfo() public view returns(uint investThisRound, uint promoteThisRound, uint profitInvest5Round, uint profitPromoter5Round){
		Round storage rnd = rounds[rounds.length-1];
		address boss = msg.sender;
		Investor storage investor = rnd.investors[boss];
		for( uint i=0;i<investor.investinfo.length;i++ ){
			investThisRound += investor.investinfo[i].amount;
		}

		promoteThisRound = rnd.promoters[boss].bonus;

		uint roundLength = rounds.length;
		if( roundLength >= 2 ) {
			(profitInvest5Round, profitPromoter5Round) = calLast5RoundProfitForRead(roundLength);
		}
	}

	function jpotInfo() public view returns(address winner, uint amount, uint winTime, uint jpotSize) {
		Round storage rnd = rounds[rounds.length - 1];
		winner = rnd.jpotWinner.winner;
		amount = rnd.jpotWinner.amount;
		winTime = rnd.jpotWinner.winTime;
		if( rnd.profit > PROFIT_BASE ) {
			jpotSize = (rnd.profit - PROFIT_BASE) * BONUS_PERCENT_JPOT / NUM_HUNDRED;
		}
	}
}