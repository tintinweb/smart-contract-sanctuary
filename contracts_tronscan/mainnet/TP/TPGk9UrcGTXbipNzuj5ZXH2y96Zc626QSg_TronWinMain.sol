//SourceUnit: TronWinMain.sol

pragma solidity^0.4.25;

/**
*
*
*  Telegram: https://t.me/TronWinApp
*  Discord: https://discord.gg/uJhnKcE
*  Email: support (at) tronwin.app
*
* PLAY NOW: https://tronwin.app/
*  
*
* --- COPYRIGHT ----------------------------------------------------------------
* 
*   This source code is provided for verification and audit purposes only and 
*   no license of re-use is granted.
*   
*   (C) Copyright 2019 TronWin - A FutureConcepts Production
*   
*   
*   Sub-license, white-label, solidity, Eth, Tron, Tomo development enquiries 
*   please contact support (at) tronwin.app
*   
*   
* PLAY NOW: https://tronwin.app/
* 
*/



library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Percent {

  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}




interface TronWinVault {
    function gamingFundPayment(address _to, uint _amnt, bool isTokenFundsEligible) external;
    function receiveExternalGameFund(bool isTokenFundsEligible) external payable;
    function getGameFund() external view returns (uint256);
    function get24hrTokenFund() external view returns (uint256);
    function maxShockDrop() external view returns (uint256);
    function tokenFundPayment(uint _tokenDay, address _to, uint _amnt) external;
    function processPlayerPlay(address _player, uint _amnt) external;
    function applyFundsAsTokenEligible(uint _amnt) external;
}

contract TronWinMain {
    
    using SafeMath for uint256;
    using Percent for Percent.percent;



    // Events
    // event_type
    // 0 = investment, 1 = reinvestment, 2 = vault won, 3 = external trx dist, 
    // 4 = vanityname purchased, 5 referral earned, 6 new round leader,
    // 7 = new silver bankers card bought, 8 == new gold bankers card bought, 9 == new platinum bankers card bought
    // 10 = highest player vault prize won
    // 11 = random vault prize won
    event Action (
        uint16 indexed event_type,
        address indexed from,
        address to,
        uint256     amnt, 
        string      data,
        uint256     timestamp
        );




    address owner;
    address devAddress;




    struct Player {
        uint256 totalInvestment;
        uint256 startTime;
        uint256 totalWithdrawn;
        uint256 totalDivsLocked;
        uint256 lastActivity;
    }
    mapping (address => Player) investmentPlayers;
    address[] public players;


    uint256 totalInvestors;


    // jackpot clock runs for 1hr
    // resets every MIN_JACKPOT_INVESTMENT
    // at end of period:
    //  leader wins: 40% of pot
    //  highest investor wins 30%
    //  random investor wins 20%
    //  10% seeds next jackpot
    uint256 public MIN_JACKPOT_INVESTMENT = 1000000000; //1000 trx
    uint256 public roundDuration = (1 hours); 
    uint256 internal roundSeed = 0;

    Percent.percent private m_roundJackpotWinnerShare = Percent.percent(40,100);
    Percent.percent private m_roundJackpotHighestShare = Percent.percent(30,100);
    Percent.percent private m_roundJackpotRandomShare = Percent.percent(20,100);
    Percent.percent private m_roundJackpotSeedShare = Percent.percent(10,100);

    // settings
    uint256 public STARTING_KEY_PRICE = 5000000; // 5 trx
    uint256 public minInvestment = STARTING_KEY_PRICE;
    uint256 public maxInvestment = STARTING_KEY_PRICE * 10000;
    
    
/*
85% gameFund
3% vault
3% Ref or TWN holders
2% bankers cards
--- 0.25% = silver
--- 0.5% = gold
--- 1.25% = platinum
---
5% Dev Fund
2% TWN holders
*/






    Percent.percent private m_investorsPercent = Percent.percent(85, 100); // dividend split
    Percent.percent private m_currentRoundJackpotPercent = Percent.percent(3, 100);

    Percent.percent private m_bankersSilverPercent = Percent.percent(25, 10000); // correct
    Percent.percent private m_bankersGoldPercent = Percent.percent(5, 1000); // correct
    Percent.percent private m_bankersPlatinumPercent = Percent.percent(125, 10000); // correct

    
    Percent.percent private m_refPercent = Percent.percent(3, 100);    
    Percent.percent private m_devMarketingPercent = Percent.percent(5, 100); // dev + marketing
    Percent.percent private m_twnHoldersPercent = Percent.percent(2, 100);


    Percent.percent private m_dailyInterest = Percent.percent(333,1000);



    Percent.percent private m_bankersResaleMultipler = Percent.percent(200,100);
    Percent.percent private m_bankersResaleOwnerShare = Percent.percent(55,100);


    
    
    struct GameRound {
        uint totalInvested;        
        uint jackpot;

        uint softDeadline;
        uint price;
        address lastInvestor;
        uint highestInvested;
        address highestInvestor;
        bool finalized;
        mapping (address => uint) roundInvested;
        mapping (address => bool) playerHasMinForJackpot;
        uint startTime;
    }

    
    struct Vault {
        uint totalReturns; // Total balance = returns + referral returns + jackpots/bonus Prize 
        uint refReturns; // how much of the total is from referrals
        uint totalInvested; // NEW
    }


    uint256 public VANITY_PRICE    = 100000000;// 100 trx; 
    mapping(bytes32 => address) public listVanityAddress; // key is vanity of address
    mapping(address => PlayerVanity) public playersVanity;
    struct PlayerVanity {
        string vanity;
        bool vanityStatus;
    }



    uint public bankersSilverPrice = 100000000; //100 trx;
    uint public bankersGoldPrice = 100000000; //100 trx;
    uint public bankersPlatinumPrice = 100000000; //100 trx;
    uint public bankersSilverStartTime;
    uint public bankersGoldStartTime;
    uint public bankersPlatinumStartTime;
    address public bankersSilverOwner;
    address public bankersGoldOwner;
    address public bankersPlatinumOwner;

    uint public bankersSilverCardHalfLife = 1 days;
    uint public bankersGoldCardHalfLife = 3 days;
    uint public bankersPlatinumCardHalfLife = 5 days;



    
    address[] public playersVanityAddressList;
    function playersVanityAddressListLen() public view returns (uint) {
        return playersVanityAddressList.length;
    }
    function playersVanityByID(uint _id) public view returns (address _addr, string memory _vanity) {
        _addr = playersVanityAddressList[_id];
        _vanity = playersVanity[_addr].vanity;
    }




    uint256 public trx_distributed;
    uint256 public trx_invested;



    mapping(uint => address[]) playersInCurrentRound;
    mapping(uint => address[]) playersInCurrentRoundWithMinPlay;


    modifier validPlayer() {
        require(msg.sender == tx.origin);
        _;
    }



    function getRoundPlayersInRound(uint round) public view returns(address[] memory) {
        return playersInCurrentRound[round];
    }
    function getRoundPlayersRoundInvested(uint round, address player) public view returns(uint) {
        return rounds[round].roundInvested[player];
    }

    mapping (address => Vault) vaults;


    uint public latestRoundID;// the first round has an ID of 0
    GameRound[] rounds;




    bool public gamePaused = false;
    bool public limitedReferralsMode = false; 


    mapping(address => bool) private m_referrals; // we only pay out on the first set of referrals
    
    
    // Game vars

    
    

    
    // Main stats:
    uint public gameFund;
    uint public totalJackpotsWon = 0;

    

    uint public totalEarningsGenerated = 0;
    uint public totalDistributedReturns = 0;

    uint public totalBankersProfit = 0;

    
    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notOnPause() {
        require(gamePaused == false, "Game Paused");
        _;
    }
    



    // mainnet TDzhXaqzr2CU5PmFsCqZ5TH3UKntTzGNhb
    TronWinVault tronwinVault_I = TronWinVault(0x2c28Bb4d8Efb42aC8cf8a3f56Faa1eDAA50B0d26);

    constructor() public {

        owner = address(msg.sender);
        devAddress = owner;
        

        
        rounds.length++;
        
        latestRoundID = 0;

        rounds[0].lastInvestor = address(0);
        rounds[0].highestInvestor = address(0);
        rounds[0].highestInvested = 0;
        rounds[0].price = STARTING_KEY_PRICE;

        rounds[0].softDeadline = now + roundDuration;

        rounds[0].jackpot = 0;

        rounds[0].startTime = now;

        bankersSilverOwner = 0xcE1F19A47e4A91DCC0C32953e2EC7713924e3373; //TUm5TTFpTVN54HwcL63pP1fDM6fquJWC8s
        bankersGoldOwner = 0xEd600882765Cdc03848D7aC58DFe401E176BdeED; //TXcLC2ez5ot7eXcVGzMewkcs8mUZyKEH1y;
        bankersPlatinumOwner = 0x30a938218b6e7a23fA9a0A3fE61B1A48B7Da8d52 ; //TEQW9pwHCNjThSsnAFf1z1QpPvXLxAirrv
        
        bankersSilverStartTime = now + bankersSilverCardHalfLife;
        bankersGoldStartTime = now + bankersGoldCardHalfLife;
        bankersPlatinumStartTime = now + bankersPlatinumCardHalfLife;

        bankersSilverPrice = 200000000;
        bankersGoldPrice = 102400000000; 
        bankersPlatinumPrice = 102400000000;
    }


    function() external {   
    }
    function pay() public payable {
    }






    function investorInfo(address investor) external view
    returns(uint invested, uint totalWithdrawn, uint totalReturns, uint refReturns, uint divs, uint divsLocked) 
    {
        invested = investmentPlayers[investor].totalInvestment;
        totalWithdrawn = investmentPlayers[investor].totalWithdrawn;
        totalReturns = vaults[investor].totalReturns;
        refReturns = vaults[investor].refReturns;
        divs = getDividends(investor);
        divsLocked = investmentPlayers[investor].totalDivsLocked;
    }




    function roundInfoInGame(uint roundID) external view 
        returns(
            address leader, 
            address highestInvestor,
            uint highestInvested,
            uint jackpot,  
            uint totalInvested,
            bool finalized,
            uint startTime,
            string memory leader_vanity,
            uint softDeadline
        )
    {   


        
        leader = rounds[roundID].lastInvestor;
        highestInvestor = rounds[roundID].highestInvestor;
        highestInvested = rounds[roundID].highestInvested;
        leader_vanity = playersVanity[leader].vanity;

        totalInvested = rounds[roundID].totalInvested;

        jackpot = rounds[roundID].jackpot;
        
        finalized = rounds[roundID].finalized;

        startTime = rounds[roundID].startTime;

        softDeadline = rounds[roundID].softDeadline;

    } 


    function getBankersSilverPrice() public view returns (uint) {
        uint _bankersSilverPrice;
        if(bankersSilverStartTime + bankersSilverCardHalfLife > now)
            return bankersSilverPrice;

        uint _silverDivider = (now - bankersSilverStartTime) / bankersSilverCardHalfLife;
        uint c;
        if(_silverDivider > 0){
            _bankersSilverPrice = bankersSilverPrice;
            for(c=0; c< _silverDivider;c++){
                _bankersSilverPrice = _bankersSilverPrice /2;
                if(_bankersSilverPrice < 100000000) {
                    _bankersSilverPrice = 100000000;
                    break;
                }
            }
        } else {
            _bankersSilverPrice = bankersSilverPrice;
        }
        return _bankersSilverPrice;
    }
    function getBankersGoldPrice() public view returns (uint) {
        uint _bankersGoldPrice;
        if(bankersGoldStartTime + bankersGoldCardHalfLife > now)
            return bankersGoldPrice;

        uint _goldDivider = (now - bankersGoldStartTime) / bankersGoldCardHalfLife;
        uint c;
        if(_goldDivider > 0){
            _bankersGoldPrice = bankersGoldPrice;
            for(c=0; c< _goldDivider;c++){
                _bankersGoldPrice = _bankersGoldPrice /2;
                if(_bankersGoldPrice < 100000000) {
                    _bankersGoldPrice = 100000000;
                    break;
                }
            }
        } else {
            _bankersGoldPrice = _bankersGoldPrice;
        }
        return _bankersGoldPrice;
    }
    function getBankersPlatinumPrice() public view returns (uint) {
        uint _bankersPlatinumPrice;
        if(bankersPlatinumStartTime + bankersPlatinumCardHalfLife > now)
            return bankersPlatinumPrice;

        uint _platinumDivider = (now - bankersPlatinumStartTime) / bankersPlatinumCardHalfLife;
        uint c;
        if(_platinumDivider > 0){
            _bankersPlatinumPrice = bankersPlatinumPrice;
            for(c=0; c< _platinumDivider;c++){
                _bankersPlatinumPrice = _bankersPlatinumPrice /2;
                if(_bankersPlatinumPrice < 100000000) {
                    _bankersPlatinumPrice = 100000000;
                    break;
                }
            }
        } else {
            _bankersPlatinumPrice = _bankersPlatinumPrice;
        }
        return _bankersPlatinumPrice;
    }

    function bankerCardsInfo() external view returns (
            uint _bankersSilverPrice,
            uint _bankersGoldPrice,
            uint _bankersPlatinumPrice,
            uint _bankersSilverStartTime,
            uint _bankersGoldStartTime,
            uint _bankersPlatinumStartTime,
            address _bankersSilverOwner,
            address _bankersGoldOwner,
            address _bankersPlatinumOwner,
            uint _bankersSilverCardHalfLife,
            uint _bankersGoldCardHalfLife,
            uint _bankersPlatinumCardHalfLife
        )
    {

        _bankersSilverPrice = getBankersSilverPrice();
        

        _bankersGoldPrice = getBankersGoldPrice();
        _bankersPlatinumPrice = getBankersPlatinumPrice();

        _bankersSilverStartTime = bankersSilverStartTime;
        _bankersGoldStartTime = bankersGoldStartTime;
        _bankersPlatinumStartTime = bankersPlatinumStartTime;
        _bankersSilverOwner = bankersSilverOwner;
        _bankersGoldOwner = bankersGoldOwner;
        _bankersPlatinumOwner = bankersPlatinumOwner;
        _bankersSilverCardHalfLife = bankersSilverCardHalfLife;
        _bankersGoldCardHalfLife = bankersGoldCardHalfLife;
        _bankersPlatinumCardHalfLife = bankersPlatinumCardHalfLife;
    }

        
    function roundKeyPrice(uint roundID) external view returns(uint) {
        return rounds[roundID].price;
    }
    







    function playerReturns(address investor) public view validPlayer 
    returns (uint totalReturns, uint refReturns) 
    {
        totalReturns = vaults[investor].totalReturns;
        refReturns = vaults[investor].refReturns;
    }

    function withdrawReturns() public validPlayer {
        transferPlayerDivs(msg.sender);

        // add in any locked divs...
        vaults[msg.sender].totalReturns = vaults[msg.sender].totalReturns.add(investmentPlayers[msg.sender].totalDivsLocked);
        

        require(vaults[msg.sender].totalReturns > 0, "Nothing to withdraw!");

        uint256 _totalReturns = vaults[msg.sender].totalReturns; // includes referral bonus

        vaults[msg.sender].totalReturns = 0;
        vaults[msg.sender].refReturns = 0;
        investmentPlayers[msg.sender].totalDivsLocked = 0;
        investmentPlayers[msg.sender].totalWithdrawn = investmentPlayers[msg.sender].totalWithdrawn.add(_totalReturns);
        tronwinVault_I.gamingFundPayment(msg.sender,_totalReturns, false);

    }


    function transferPlayerDivs(address _player) internal {
        uint256 _divs = getDividends(_player);
        if(_divs == 0)
            return;

        investmentPlayers[_player].lastActivity = now;
        investmentPlayers[_player].totalDivsLocked = investmentPlayers[_player].totalDivsLocked.add(_divs);
    }



    
    function finalizeLastRound() public {
        GameRound storage rnd = rounds[latestRoundID];
        _finalizeRound(rnd);
    }


    function finalizeAndRestart(address _referer) public payable validPlayer {
        finalizeLastRound();
        startNewRound(_referer);
    }
    
    
    function startNewRound(address _referer) public payable validPlayer {
        
        require(rounds[latestRoundID].finalized, "Previous round not finalized");
        require(rounds[latestRoundID].softDeadline < now, "Previous round still running");
        


        uint _rID = rounds.length++; // first round is 0
        GameRound storage rnd = rounds[_rID];
        latestRoundID = _rID;

        rnd.lastInvestor = address(0);
        rnd.highestInvestor = address(0);
        rnd.highestInvested = 0;
        rnd.price = STARTING_KEY_PRICE;
        rnd.startTime = now;
        rnd.softDeadline = now + roundDuration;

        

        if(rounds[latestRoundID].roundInvested[msg.sender] > 0) {
        } else {
            playersInCurrentRound[latestRoundID].push(msg.sender);
        }


        rnd.jackpot = roundSeed;
        roundSeed = 0;
        // need to reinvest any divs first...
        transferPlayerDivs(msg.sender);
        _purchase(rnd, msg.value, _referer, true);
        emit Action(0, msg.sender, address(0), msg.value, "", now);

    }

    function buyBankersCard(uint _cardType) public validPlayer payable {
        address _prevOwner;
        uint _prevOwnersShare;
        if(_cardType == 0) {
            // silver


            require(msg.value >=  getBankersSilverPrice(), "Not enough TRX!");
            
            tronwinVault_I.receiveExternalGameFund.value(msg.value)(true);

            _prevOwner = bankersSilverOwner;


            if(_prevOwner == address(0)){
            } else {
                _prevOwnersShare = m_bankersResaleOwnerShare.mul(msg.value);
                //_prevOwner.transfer(_prevOwnersShare);
                tronwinVault_I.gamingFundPayment(_prevOwner,_prevOwnersShare, true);

                totalBankersProfit = totalBankersProfit.add(_prevOwnersShare);
            }
            gameFund = gameFund.add(msg.value.sub(_prevOwnersShare));



            if(bankersSilverStartTime + bankersSilverCardHalfLife < now) {
                // halflife it...
                bankersSilverPrice = getBankersSilverPrice();
            }

            bankersSilverOwner = msg.sender;
            bankersSilverPrice = m_bankersResaleMultipler.mul(bankersSilverPrice);
            bankersSilverStartTime = now;

            // Mine TWN tokens...
            tronwinVault_I.processPlayerPlay(msg.sender,msg.value);

            emit Action (
                7,
                _prevOwner,
                msg.sender,
                msg.value, 
                "",
                now
                );
            return;
        }

        if(_cardType == 1) {
            // gold

            require(msg.value >= getBankersGoldPrice(), "Not enough TRX!");
            tronwinVault_I.receiveExternalGameFund.value(msg.value)(true);
            

            _prevOwner = bankersGoldOwner;

            if(_prevOwner == address(0)){
            } else {
                _prevOwnersShare = m_bankersResaleOwnerShare.mul(msg.value);
                //_prevOwner.transfer(_prevOwnersShare);
                tronwinVault_I.gamingFundPayment(_prevOwner,_prevOwnersShare, true);

                totalBankersProfit = totalBankersProfit.add(_prevOwnersShare);

            }
            gameFund = gameFund.add(msg.value.sub(_prevOwnersShare));


            if(bankersGoldStartTime + bankersGoldCardHalfLife < now) {
                // halflife it...
                bankersGoldPrice = getBankersGoldPrice();
            }

            bankersGoldOwner = msg.sender;
            bankersGoldPrice = m_bankersResaleMultipler.mul(bankersGoldPrice);
            bankersGoldStartTime = now;

            // Mine TWN tokens...
            tronwinVault_I.processPlayerPlay(msg.sender,msg.value);

            emit Action (
                8,
                _prevOwner,
                msg.sender,
                msg.value, 
                "",
                now
                );
            return;
        }

        if(_cardType == 2) {
            // platinum

            require(msg.value >= getBankersPlatinumPrice(), "Not enough TRX!");
            tronwinVault_I.receiveExternalGameFund.value(msg.value)(true);

            _prevOwner = bankersPlatinumOwner;

            if(_prevOwner == address(0)){
            } else {
                _prevOwnersShare = m_bankersResaleOwnerShare.mul(msg.value);
                //_prevOwner.transfer(_prevOwnersShare);
                tronwinVault_I.gamingFundPayment(_prevOwner,_prevOwnersShare, true);

                totalBankersProfit = totalBankersProfit.add(_prevOwnersShare);
            }
            gameFund = gameFund.add(msg.value.sub(_prevOwnersShare));


            if(bankersPlatinumStartTime + bankersPlatinumCardHalfLife < now) {
                // halflife it...
                bankersPlatinumPrice = getBankersPlatinumPrice();
            }


            bankersPlatinumOwner = msg.sender;
            bankersPlatinumPrice = m_bankersResaleMultipler.mul(bankersPlatinumPrice);
            bankersPlatinumStartTime = now;

            // Mine TWN tokens...
            tronwinVault_I.processPlayerPlay(msg.sender,msg.value);

            emit Action (
                9,
                _prevOwner,
                msg.sender,
                msg.value, 
                "",
                now
                );
            return;
        }

    }

    function reinvestFull() public validPlayer  {        
        GameRound storage rnd = rounds[latestRoundID];
        

        // need to reinvest any divs first...
        transferPlayerDivs(msg.sender);

        // add in any lockedDivs
        vaults[msg.sender].totalReturns = vaults[msg.sender].totalReturns.add(investmentPlayers[msg.sender].totalDivsLocked);

        uint value = vaults[msg.sender].totalReturns;

        require(value > 0, "Can't spend what you don't have");

        vaults[msg.sender].totalReturns = 0;
        vaults[msg.sender].refReturns = 0;
        investmentPlayers[msg.sender].totalDivsLocked = 0;
        investmentPlayers[msg.sender].totalWithdrawn = investmentPlayers[msg.sender].totalWithdrawn.add(value);

        if(rounds[latestRoundID].roundInvested[msg.sender] > 0) {
        } else {
            playersInCurrentRound[latestRoundID].push(msg.sender);
        }
        
        _purchase(rnd, value, address(0), false);
        emit Action(1, msg.sender, address(0), value, "", now);
    }

    function reinvestReturns(uint value, address ref) public validPlayer  {        
        GameRound storage rnd = rounds[latestRoundID];
        

        // need to reinvest any divs first...
        transferPlayerDivs(msg.sender);


        require(
                vaults[msg.sender].totalReturns.add(investmentPlayers[msg.sender].totalDivsLocked) >= value, 
                "Can't spend what you don't have");


        // spend locked divs first...
        if(value > investmentPlayers[msg.sender].totalDivsLocked) {

            

            vaults[msg.sender].totalReturns = vaults[msg.sender].totalReturns.sub(value.sub(investmentPlayers[msg.sender].totalDivsLocked));
            vaults[msg.sender].refReturns = min(vaults[msg.sender].refReturns, vaults[msg.sender].totalReturns);

            investmentPlayers[msg.sender].totalDivsLocked = 0;

        } else {

            investmentPlayers[msg.sender].totalDivsLocked = investmentPlayers[msg.sender].totalDivsLocked.sub(value);
        
        }




        if(rounds[latestRoundID].roundInvested[msg.sender] > 0) {

        } else {
            playersInCurrentRound[latestRoundID].push(msg.sender);
        }

        
        _purchase(rnd, value, ref, false);
        emit Action(1, msg.sender, address(0), value, "", now);
    }

    function invest(address _referer) public payable notOnPause validPlayer {
        require(msg.value >= minInvestment);
        if(rounds.length > 0) {
            GameRound storage rnd = rounds[latestRoundID];   


            if(rounds[latestRoundID].roundInvested[msg.sender] > 0) {

            } else {
                playersInCurrentRound[latestRoundID].push(msg.sender);
            }

            // need to reinvest any divs first...
            transferPlayerDivs(msg.sender);

            _purchase(rnd, msg.value, _referer, true);
            emit Action(0, msg.sender, address(0), msg.value, "", now);

        } else {
            revert("Not yet started");
        }
        
    }

    function _purchase(GameRound storage rnd, uint value, address referer, bool isNewInvestment) internal  {
        require(now >= rnd.startTime, "Round not started!");
        require(rnd.softDeadline >= now, "After deadline!");
        require(value >= rnd.price, "Not enough TRX!");


        rnd.totalInvested = rnd.totalInvested.add(value);
        trx_invested = trx_invested.add(value);


        if(investmentPlayers[msg.sender].startTime == 0) {
            // first investment
            totalInvestors++;
            investmentPlayers[msg.sender].startTime = now;
            players.push(msg.sender);
        }
        investmentPlayers[msg.sender].totalInvestment = 
            investmentPlayers[msg.sender].totalInvestment.add(value);

        investmentPlayers[msg.sender].lastActivity = now;
        
        if(value >= MIN_JACKPOT_INVESTMENT) {

            // mark as met current min amount for jackpot play

            if(rounds[latestRoundID].playerHasMinForJackpot[msg.sender] == true) {
            } else {
                playersInCurrentRoundWithMinPlay[latestRoundID].push(msg.sender);
                rounds[latestRoundID].playerHasMinForJackpot[msg.sender] = true;
            }


            if(rnd.lastInvestor == msg.sender) {
            } else {
                emit Action(6,msg.sender,address(0),value,"",now);
            }


            rnd.softDeadline = now + roundDuration;
            rnd.lastInvestor = msg.sender;


            if(value > rnd.highestInvested) {
                rnd.highestInvested = value;
                rnd.highestInvestor = msg.sender;
            }

        }

        rnd.roundInvested[msg.sender] = rnd.roundInvested[msg.sender].add(value);

        _splitRevenue(rnd, value, referer, isNewInvestment);

        // Mine TWN tokens...
        tronwinVault_I.processPlayerPlay(msg.sender,value);
    }



    function _splitRevenue(GameRound storage rnd, uint value, address ref, bool _isNewInvestment) internal {
        if(_isNewInvestment == true){
            // transfer the funds to the vault...
            tronwinVault_I.receiveExternalGameFund.value(value)(false); // isnt profit back towards this game!

        }

        uint _tokenEligible = m_twnHoldersPercent.mul(value);


        uint dev_value = value.sub(_tokenEligible);

        uint roundReturns = m_investorsPercent.mul(value); // how much to pay in dividends to players
        dev_value = dev_value.sub(roundReturns);

        uint _referralEarning =  m_refPercent.mul(value);
        dev_value = dev_value.sub(_referralEarning);


        if(ref != address(0x0) && ref != msg.sender) {
            
            if(
                (!m_referrals[msg.sender] && limitedReferralsMode == true)
                ||
                limitedReferralsMode == false

                ) {

                vaults[ref].totalReturns = vaults[ref].totalReturns.add(_referralEarning);
                vaults[ref].refReturns = vaults[ref].refReturns.add(_referralEarning);
                
                m_referrals[msg.sender] = true;

                emit Action (5, msg.sender, ref, _referralEarning, "", now);

            } else {
                // no referrer - goes to TWN holders!
                _tokenEligible = _tokenEligible.add(_referralEarning);
            }

        } else {
            // no referrer - goes to TWN holders!
            _tokenEligible = _tokenEligible.add(_referralEarning);
        }

        tronwinVault_I.applyFundsAsTokenEligible(_tokenEligible);
        

        uint bankersSilverOwnerShare;
        uint bankersGoldOwnerShare;
        uint bankersPlatinumOwnerShare;

        if(bankersSilverOwner != address(0)) {
            bankersSilverOwnerShare = m_bankersSilverPercent.mul(value);
            dev_value = dev_value.sub(bankersSilverOwnerShare);

            investmentPlayers[bankersSilverOwner].totalDivsLocked = investmentPlayers[bankersSilverOwner].totalDivsLocked.add(bankersSilverOwnerShare);
            totalBankersProfit = totalBankersProfit.add(bankersSilverOwnerShare);
        }

        if(bankersGoldOwner != address(0)) {
            bankersGoldOwnerShare = m_bankersGoldPercent.mul(value);
            dev_value = dev_value.sub(bankersGoldOwnerShare);

            investmentPlayers[bankersGoldOwner].totalDivsLocked = investmentPlayers[bankersGoldOwner].totalDivsLocked.add(bankersGoldOwnerShare);

            totalBankersProfit = totalBankersProfit.add(bankersGoldOwnerShare);
        }

        if(bankersPlatinumOwner != address(0)) {
            bankersPlatinumOwnerShare = m_bankersPlatinumPercent.mul(value);
            dev_value = dev_value.sub(bankersPlatinumOwnerShare);

            investmentPlayers[bankersPlatinumOwner].totalDivsLocked = investmentPlayers[bankersPlatinumOwner].totalDivsLocked.add(bankersPlatinumOwnerShare);

            totalBankersProfit = totalBankersProfit.add(bankersPlatinumOwnerShare);
        }

        
        gameFund = gameFund.add(roundReturns);

        rnd.jackpot = rnd.jackpot.add(m_currentRoundJackpotPercent.mul(value));

        dev_value = dev_value.sub(m_currentRoundJackpotPercent.mul(value));

        tronwinVault_I.gamingFundPayment(devAddress,dev_value, false);
    }


    function getDividends(address _address) public view returns (uint256) {

        uint256 minsSinceInvestment = now.sub(investmentPlayers[_address].lastActivity).div(1 minutes);

        // 3.33% of their total investment = how much players earn each day
        uint256 percent = m_dailyInterest.mul(investmentPlayers[_address].totalInvestment); 

        // show it in minutes since last investment...
        uint256 balance = percent.mul(minsSinceInvestment).div(14400);

        //return balance;
        return balance;
    }




    function getTotalDivs() public view returns (uint256) {
        uint _totalDivs;
        for(uint c=0; c< totalInvestors; c++) {
            _totalDivs = _totalDivs.add(investmentPlayers[players[c]].totalWithdrawn);
            _totalDivs = _totalDivs.add(investmentPlayers[players[c]].totalDivsLocked);
            _totalDivs = _totalDivs.add(getDividends(players[c]));
        }
        return _totalDivs;
    }





    // jackpot clock runs for 1hr
    // resets every MIN_JACKPOT_INVESTMENT
    // at end of period:
    //  leader wins: 40% of pot
    //  highest investor wins 30%
    //  random investor wins 20%
    //  10% seeds next jackpot

    function _finalizeRound(GameRound storage rnd) internal {
        require(!rnd.finalized, "Already finalized!");
        require(rnd.softDeadline < now, "Round still running!");


        // find vault winner

        if(rnd.jackpot > 0){

            if(rnd.lastInvestor == address(0)) {
                // house win takes 5%
                // rest goes to div pot!
                //devAddress.transfer(m_devMarketingPercent.mul(rnd.jackpot));
                tronwinVault_I.gamingFundPayment(devAddress,m_devMarketingPercent.mul(rnd.jackpot), false);
                gameFund = gameFund.add(rnd.jackpot.sub(m_devMarketingPercent.mul(rnd.jackpot)));
            } else {


                // last investor takes 40%
                vaults[rnd.lastInvestor].totalReturns = 
                    vaults[rnd.lastInvestor].totalReturns.add(m_roundJackpotWinnerShare.mul(rnd.jackpot));

                emit Action(2, rnd.lastInvestor, address(0), 
                    rnd.jackpot
                    ,"", now);

                // highest investor takes 30%...
                vaults[rnd.highestInvestor].totalReturns = 
                    vaults[rnd.highestInvestor].totalReturns.add(
                                    m_roundJackpotHighestShare.mul(rnd.jackpot)
                                                                );


                emit Action(10, rnd.highestInvestor, address(0), 
                    m_roundJackpotHighestShare.mul(rnd.jackpot)
                    ,"", now);

                // random player takes 20%
                // choose random from playersInCurrentRound[latestRoundID][]
                // 
                uint _max = playersInCurrentRoundWithMinPlay[latestRoundID].length;
                uint _r = (uint(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 200), block.timestamp))) % _max);

                vaults[playersInCurrentRoundWithMinPlay[latestRoundID][_r]].totalReturns = 
                    vaults[playersInCurrentRoundWithMinPlay[latestRoundID][_r]].totalReturns.add(
                                    m_roundJackpotRandomShare.mul(rnd.jackpot)
                                                                );
                emit Action(11, playersInCurrentRoundWithMinPlay[latestRoundID][_r], address(0), 
                    m_roundJackpotRandomShare.mul(rnd.jackpot)
                    ,"", now);

                // next round seed = 10%
                roundSeed = roundSeed.add(m_roundJackpotSeedShare.mul(rnd.jackpot));
                
    



                totalJackpotsWon = totalJackpotsWon.add(rnd.jackpot);
                
            }

            totalEarningsGenerated = totalEarningsGenerated.add(rnd.jackpot);





        }
        rnd.finalized = true;
    }




    /**
    * Action by vanity
    * Vanity referral links (Show vanity in cardholder box)
    */
    function buyVanity(string memory _vanity) public payable validPlayer {
        tronwinVault_I.receiveExternalGameFund.value(msg.value)(true);
        /*--------------------- validate --------------------------------*/
        require(msg.value >= VANITY_PRICE);
        require(isVanityExisted(_vanity) == false);
        /*--------------------- handle --------------------------------*/

        if(playersVanity[msg.sender].vanityStatus == false) {
            playersVanityAddressList.push(msg.sender);
        }


        playersVanity[msg.sender].vanity = _vanity;
        playersVanity[msg.sender].vanityStatus = true;
        // update list vanity address
        listVanityAddress[convertStringToBytes32(_vanity)] = msg.sender;
        /*--------------------- event --------------------------------*/

        //devAddress.transfer(msg.value);
        tronwinVault_I.gamingFundPayment(devAddress, m_devMarketingPercent.mul(msg.value), true);


        emit Action(4, msg.sender, address(0), msg.value, _vanity, now);
    }




    function isVanityExisted(string memory _vanity) public view returns(bool) {
        if (listVanityAddress[convertStringToBytes32(_vanity)] != address(0)) {
          return true; 
        }
        return false;
    }
    function convertStringToBytes32(string memory key) private pure returns (bytes32 ret) {
        if (bytes(key).length > 32) {
          revert();
        }

        assembly {
          ret := mload(add(key, 32))
        }
    }
    function vanityToAddress(string memory _vanity) public view returns(address) {
      return listVanityAddress[convertStringToBytes32(_vanity)];
    }
    function addressToVanity(address _player) public view returns(string memory) {
      return playersVanity[_player].vanity;
    }



    
    // Owner only functions    
    function p_setNewOwners(uint16 _type, address _addr) public onlyOwner {
        if(_type==0){
            owner = _addr;
        }
        if(_type==1){
            devAddress = _addr;    
        }
    }







    function p_setMinInvestment(uint _minInvestment) public onlyOwner {
        minInvestment = _minInvestment;
    }
    function p_setMaxInvestment(uint _maxInvestment) public onlyOwner {
        maxInvestment = _maxInvestment;
    }
    function p_setGamePaused(bool _gamePaused) public onlyOwner {
        gamePaused = _gamePaused;
    }
    function p_incSoftDeadline() public onlyOwner {
        require(gamePaused == true);
        rounds[latestRoundID].softDeadline = now + roundDuration;
    }
    function p_setRoundDuration(uint256 _roundDuration) public onlyOwner {
        roundDuration = _roundDuration;
    }
    function p_setRoundStartTime(uint256 _round, uint256 _startTime) public onlyOwner {
        rounds[_round].startTime = _startTime;
    }

    function p_setLimitedReferralsMode(bool _limitedReferralsMode) public onlyOwner {
        limitedReferralsMode = _limitedReferralsMode;
    }





    function p_settings(uint _type, uint _val, uint _val2) public onlyOwner {

        if(_type==1)
            STARTING_KEY_PRICE = _val;
        if(_type==2)
            MIN_JACKPOT_INVESTMENT = _val;

        if(_type==20){
            m_currentRoundJackpotPercent = Percent.percent(_val, _val2);
        }

        if(_type==24){
            m_investorsPercent = Percent.percent(_val, _val2);
        }

        if(_type==28){
            m_devMarketingPercent = Percent.percent(_val, _val2);
        }
        if(_type==29){
            m_refPercent = Percent.percent(_val, _val2);
        }
        if(_type==30){
            VANITY_PRICE = _val;
        }
        if(_type==31){
            bankersSilverPrice = _val;
        }
        if(_type==32){
            bankersGoldPrice = _val;
        }
        if(_type==33) {
            bankersPlatinumPrice = _val;
        }
        if(_type==34) {
            bankersSilverStartTime = _val;
        }
        if(_type==35) {
            bankersGoldStartTime = _val;
        }
        if(_type==36) {
            bankersPlatinumStartTime = _val;
        }
        if(_type==37) {
            bankersPlatinumStartTime = _val;
        }
        if(_type==38) {
            bankersSilverCardHalfLife = _val;
        }
        if(_type==39) {
            bankersGoldCardHalfLife = _val;
        }
        if(_type==40) {
            bankersPlatinumCardHalfLife = _val;
        }
        if(_type==41) {
            m_bankersResaleMultipler = Percent.percent(_val,_val2);
        }
        if(_type==42) {
            m_bankersResaleOwnerShare = Percent.percent(_val,_val2);
        }
        if(_type==43) {
            m_bankersSilverPercent = Percent.percent(_val, _val2);
        }
        if(_type==44) {
            m_bankersGoldPercent = Percent.percent(_val, _val2);
        }
        if(_type==45) {
            m_bankersPlatinumPercent = Percent.percent(_val, _val2);
        }

        if(_type==46) {
            m_roundJackpotWinnerShare = Percent.percent(_val,_val2);
        }
        if(_type==47) {
            m_roundJackpotHighestShare = Percent.percent(_val,_val2);
        }
        if(_type==48) {
            m_roundJackpotRandomShare = Percent.percent(_val,_val2);
        }
        if(_type==49) {
            m_roundJackpotSeedShare = Percent.percent(_val,_val2);
        }


    }

    function updateVault(address _addr) public onlyOwner {
        tronwinVault_I = TronWinVault(_addr);
    }



    function updateTWNshare(uint _val, uint _val2) public onlyOwner {
        m_twnHoldersPercent = Percent.percent(_val,_val2);
    }



    function getContractBalance() internal view returns (uint) {
      return address(this).balance;
    }



    // Util functions
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }



    
    uint op;
    function gameOp() external {
        op++;
    }






}