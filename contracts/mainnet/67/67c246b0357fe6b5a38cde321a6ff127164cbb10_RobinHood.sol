pragma solidity ^0.4.21;

// WARNING. The examples used in the formulas in the comments are the right formulas. However, they are not implemented like this to prevent overflows. 
// The formulas in the contract do work the same as in the comments. 

// NOTE: In part two of the contract, the DIVIDEND is explained. 
// The dividend has a very easy implementation
// the price of the token rise when bought.
// when it&#39;s sold, price will decrease with 50% of rate of price bought
// if you sell, you will sell all tokens, and you have thus to buy in at higher price
// make sure you hold dividend for a long time.

contract RobinHood{
    // Owner of this contract
    address public owner;
    
    // % of dev fee (can be set to 0,1,2,3,4,5 %);
    uint8 devFee = 5;
    // Users who want to create their own Robin Hood tower have to pay this. Can be reset to any value.
    uint256 public amountToCreate = 20000000000000000;
    
    // If this is false, you cannot use the contract. It can be opened by owner. After that, it cannot be closed anymore.
    // If it is not open, you cannot interact with the contract.
    bool public open = false;
    
    event TowerCreated(uint256 id);
    event TowerBought(uint256 id);
    event TowerWon(uint256 id);

    // Tower struct. 
    struct Tower{
        //Timer in seconds: Base time for how long the new owner of the Tower has to wait until he can pay the amount.
        uint32 timer; 
        // Timestamp: if this is 0, the contract does not run. If it runs it is set to the blockchain timestamp. 
        // If Timestamp + GetTime() > Blockchain timestamp the user will be paid out  by the person who tries to buy the tower OR the user can decide to buy himself.
        uint256 timestamp;
        // Payout of the amount in percent. Ranges from 0 - 10000. Here 0 is 0 % and 10000 is 100%.
        // This percentage of amount is paid to owner of tower. 
        // The other part of amount stays in Tower and can be collected by new people.
        // However, if the amount is larger or equal than the minPrice, the Tower will immediately change the timestamp and move on.
        // This means that the owner of the tower does not change, and can possibly collect the amount more times, if no one buys!!
        uint16 payout; 
        // Price increasate, ranged again from 0-10000 (0 = 0%, 10000 = 100%), which decides how much the price increases if someone buys the tower.
        // Ex: 5000 means that if the price is 1 ETH and if someone buys it, then the new price is 1 * (1 + 5000/10000) = 1.5 ETH.
        uint16 priceIncrease; // priceIncrease in percent (same)
        // Price, which can be checked to see how much the tower costs. Initially set to minPrice.
        uint256 price;
        // Amount which the Tower has to pay to the owner.
        uint256 amount; 
        // Min Price: the minimum price in wei. Is also the setting to make the contract move on if someone has been paid (if amount >= minPrice);
        // The minimum price is 1 szabo, maximum price is 1 ether. Both are included in the range.
        uint256 minPrice; 
        // If you create a contract (not developer) then you are allowed to set a fee which you will get from people who buy your Tower.
        // Ranged again from 0 -> 10000,  but the maximum value is 2500 (25%) minimum is 0 (0%).
        // Developer is not allowed to set creatorFee.
        uint16 creatorFee; 
        // This is the amount, in wei, to set at which amount the time necessary to wait will reduce by half.
        // If this is set to 0, this option is not allowed and the time delta is always the same.
        // The minimum wait time is 5 minutes.
        // The time to wait is calculated by: Tower.time * (Tower.amountToHalfTime / (Tower.amount + Tower.amountToHalfTime)
        uint256 amountToHalfTime; 
        // If someone wins, the price is reduced by this. The new price is calculated by:
        // Tower.price = max(Tower.price * Tower.minPriceAfterWin/10000, Tower.minPrice);
        // Again, this value is ranged from 0 (0%) to 10000 (100%), all values allowed.
        // Note that price will always be the minimum price or higher.
        // If this is set to 0, price will always be set back to new price.
        // If it is set to 10000, the price will NOT change!
        uint16 minPriceAfterWin; // also in percent. 
        // Address of the creator of this tower. Used to pay creatorFee. Developer will not receive creatorFee because his creatorFee is automatically set to 0.
        address creator;
        // The current owner of this Tower. If he owns it for longer than getTime() of this Tower, he will receive his portion of the amount in the Tower.
        address owner;
        // You can add a quote to troll your fellow friends. Hopefully they won&#39;t buy your tower!
        string quote;
    }
    
   
    // Mapping of all towers, indexed by ID. Starting at 0. 
    mapping(uint256 => Tower) public Towers;
    
    // Take track of at what position we insert the Tower. 
    uint256 public next_tower_index=0;

    // Check if contract is open. 
    // If value is send and contract is not open, it is reverted and you will get it back. 
    // Note that if contract is open it cannot be closed anymore.
    modifier onlyOpen(){
        if (open){
            _;
        }
        else{
            revert();
        }
    }
    
    // Check if owner or if contract is open. This works for the AddTower function so owner (developer) can already add Towers. 
    // Note that if contract is open it cannot be closed anymore. 
    // If value is send it will be reverted if you are not owner or the contract is not open. 
    modifier onlyOpenOrOwner(){
        if (open || msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }
    
    // Functions only for owner (developer)
    // If you send something to a owner function you will get your ethers back via revert. 
    modifier onlyOwner(){
        if (msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }
    
    
    // Constructor. 
    // Setups 4 towers. 
    function RobinHood() public{
        // Log contract developer
        owner = msg.sender;
    
        
        
        // FIRST tower. (ID = 0)
        // Robin Hood has to climb a tower!
        // 10 minutes time range!
        // 90% payout of the amount 
        // 30% price increase 
        // Timer halfs at 5 ETH. This is a lot, but realize that this high value is choosen because the timer cannot shrink to fast. 
        // At 5 ETH the limit is only 5 minutes, the minimum!
        // Minimum price is 2 finney. 
        // Price reduces 90% (100% - 10%) after someone has won the tower!
        // 0% creator fee. 
       
       
        AddTower(600, 9000, 3000, 5000000000000000000, 2000000000000000, 1000, 0);
    
    
        // SECOND tower (ID = 1)
        // Robin Hood has to search a house!
        // 10 minutes tme range 
        // 50% payout 
        // 1.5% price increase 
        // Timer halfs at 2.5 ETH (also a lot, but at this time then timer is minimum (5 min))
        // Price is 4 finney
        // Price is reduced to 4 finney if won 
        // 0% fee 
        
        AddTower(600, 5000,150 , 2500000000000000000, 4000000000000000, 0, 0);
  
        // THIRD tower. (ID = 2)
        // Robin Hood has to explore a forest!
        // 1 hour time range!
        // 50% payout of the amount 
        // 10% price increase 
        // Timer halfs at 1 ETH. 
        // Minimum price is 5 finney. 
        // Price reduces 50% (100% - 50%) after someone has won the tower!
        // 0% creator fee. 
        AddTower(3600, 5000, 1000, (1000000000000000000), 5000000000000000, 5000, 0);

        // FOURTH tower. (ID = 3)
        // Robin Hood has to cross a sea to an island!
        // 1 day time range!
        // 75% payout of the amount 
        // 20% price increase 
        // Timer halfs at 2 ETH.
        // Minimum price is 10 finney. 
        // Price reduces 75% (100% - 25%) after someone has won the tower!
        // 0% creator fee. 
        AddTower(86400, 7500, 2000, (2000000000000000000), 10000000000000000, 2500, 0);
         

  
        // FIFTH tower (ID = 4)
        // Robin Hood has to fly with a rocket to a nearby asteroid!
        // 1 week time range!
        // 75% payout of the amount 
        // 25% price increase 
        // Timer halfs at 2.5 ETH.
        // Minimum price is 50 finney. 
        // Price reduces 100% (100% - 0%) after someone has won the tower!
        // 0% creator fee. 
        AddTower(604800, 7500, 2500, (2500000000000000000), 50000000000000000, 0, 0);
    }
    
    // Developer (owner) can open game 
    // Open can only be set true once, can never be set false again. 
    function OpenGame() public onlyOwner{
        open = true;
    }
    
    // Developer can change fee. 
    // DevFee is only a simple int, so can  be 0,1,2,3,4,5 
    // Fee has to be less or equal to 5, otherwise it is reverted. 
    function ChangeFee(uint8 _fee) public onlyOwner{
        require(_fee <= 5);
        devFee = _fee;
    }
    
    // Developer change amount price to add tower. 
    function ChangeAmountPrice(uint256 _newPrice) public onlyOwner{
        amountToCreate = _newPrice;
    }
    
    // Add Tower. Only possible if you are developer OR if contract is open. 
    // If you want to buy a tower, you have to pay amountToCreate (= wei) to developer. 
    // The default value is 0.02 ETH.
    // You can check the price (in wei) either on site or by reading the contract on etherscan.
    
    // _timer: Timer in seconds for how long someone has to wait before he wins the tower. This is constant and will not be changed. 
    // If you set _amountToHalfTime to nonzero, getTimer will reduce less amounts (minimum 300 seconds, maximum _timer) from the formula Tower.time * (Tower.amountToHalfTime / (Tower.amount + Tower.amountToHalfTime) 
    // _timer has to be between 300 seconds ( 5 minutes) and maximally 366 days (366*24*60*60) (which is maximally one year);
    
    //_payout: number between 0-10000, is a pecent: 0% = 0, 100% = 10000. Sets how much percentage of the Tower.amount is paid to Tower.owner if he wins. 
    // The rest of the amount of that tower which stays over will be kept inside the tower, up for a new round. 
    // If someone wins and amount is more than the minPrice, timestamp is set to the blockchain timer and new round is started without changing the owner of the Tower!
    
    // _priceIncrease: number between 0-10000, is a pecent: 0% = 0, 100% = 10000. Sets how much percentage the price will increase. Note that "100%" is always added. 
    // If you set it at 5000 (which is 50%) then the total increase of price is 150%. So if someone buys tower for price at 1 ETH, the new price is then 1.5 ETH. 
    
    // _amountToHalfTime: number of Wei which sets how much Wei you need in order to reduce the time necessary to hold tower to win for 50%.
    // Formula used is Tower.time * (Tower.amountToHalfTime / (Tower.amount + Tower.amountToHalfTime) to calculate the time necessary.
    // If you set 0, then this formula is not used and Tower.time is always returned.
    // Due to overflows the minimum amount (which is reasonable) is still 1/1000 finney. 
    // Do not make this number extremely high. 
    
    // _minPrice: amount of Wei which the starting price of the Tower is. Minimum is 1/1000 finney, max is 1 ETH. 
    // This is also the check value to see if the round moves on after someone has won. If amount >= minPrice then the timestamp will be upgraded and a new round will start
    // Of course that is after paying the owner of this tower. The owner of the tower does not change. He can win multiple times, in theory. 
    
    // _minPriceAfterWin: number between 0-10000, is a pecent: 0% = 0, 100% = 10000. After someone wins, the new price of the game is calculated.
    // This is done by doing Tower.price * (Tower.minPriceAfterWin) / 10000; 
    // If Tower.price is now less than Tower.minPrice then the Tower.price will be set to Tower.minPrice.

    // _creatorFee: number between 0-10000, is a pecent: 0% = 0, 100% = 10000. Maximum is 2500 (25%), with 2500 included. 
    // If you create a tower, you can set this value. If people pay the tower, then this percentage of the price is taken and is sent to you.
    // The rest, after subtracting the dev fee, will be put into Tower.amount. 
    
    function AddTower(uint32 _timer, uint16 _payout, uint16 _priceIncrease, uint256 _amountToHalfTime, uint256 _minPrice, uint16 _minPriceAfterWin, uint16 _creatorFee) public payable onlyOpenOrOwner returns (uint256) {
        require (_timer >= 300); // Need at least 5 minutes
        require (_timer <= 31622400);
        require (_payout >= 0 && _payout <= 10000);
        require (_priceIncrease >= 0 && _priceIncrease <= 10000);
        require (_minPriceAfterWin >= 0 && _minPriceAfterWin <= 10000);
       //amount to half time can be everything, but has to be 0 OR 1000000000000 due to division rules
        require(_amountToHalfTime == 0 || _amountToHalfTime >= 1000000000000);
        require(_creatorFee >= 0 && _creatorFee <= 2500);
        require(_minPrice >= (1 szabo) && _minPrice <= (1 ether));
        if (msg.sender == owner){
            // If owner make sure creator fee is 0.
            _creatorFee = 0;
            if (msg.value > 0){
                owner.transfer(msg.value);
            }
        }
        else{
            if (msg.value >= amountToCreate){
                uint256 toDiv = (mul(amountToCreate, tokenDividend))/100;
                uint256 left = sub(amountToCreate, toDiv);
                owner.transfer(left);
                addDividend(toDiv);
                processBuyAmount(amountToCreate);
            }
            else{
                revert(); // not enough ETH send.
            }
            uint256 diff = sub(msg.value, amountToCreate);
            // If you send to much, you will get rest back.
            // Might be case if amountToCreate is transferred and this is not seen. 
            if (diff >= 0){
                msg.sender.transfer(diff);
            }
        }
   
        // Check latest values. 

        
        // Create tower. 
        var NewTower = Tower(_timer, 0, _payout, _priceIncrease, _minPrice, 0, _minPrice, _creatorFee, _amountToHalfTime, _minPriceAfterWin, msg.sender, msg.sender, "");
        
        // Insert this into array. 
        Towers[next_tower_index] = NewTower;
        
        // Emit TowerCreated event. 
        emit TowerCreated(next_tower_index);
        
        // Upgrade index for next tower.
        next_tower_index = add(next_tower_index, 1);
        return (next_tower_index - 1);
    }
    
    // getTimer of TowerID to see how much time (in seconds) you need to win that tower. 
    // only works if contract is open. 
    // id = tower id (note that "first tower" has ID 0 into the mapping)
    function getTimer(uint256 _id) public onlyOpen returns (uint256)  {
        require(_id < next_tower_index);
        var UsedTower = Towers[_id];
        //unsigned long long int pr =  totalPriceHalf/((total)/1000000000000+ totalPriceHalf/1000000000000);    
        // No half time? Return tower.
        if (UsedTower.amountToHalfTime == 0){
            return UsedTower.timer;
        }
        
        uint256 var2 = UsedTower.amountToHalfTime;
        uint256 var3 = add(UsedTower.amount / 1000000000000, UsedTower.amountToHalfTime / 1000000000000);
        
        
       if (var2 == 0 && var3 == 0){
           // exception, both are zero!? Weird, return timer.
           return UsedTower.timer;
       }
       

       
       uint256 target = (mul(UsedTower.timer, var2/var3 )/1000000000000);
       
       // Warning, if for some reason the calculation get super low, it will return 300, which is the absolute minimum.
       //This prevents users from winning because people don&#39;t have enough time to edit gas, which would be unfair.
       if (target < 300){
           return 300;
       }
       
       return target;
    }
    
    // Internal payout function. 
    function Payout_intern(uint256 _id) internal {
        //payout.
        
        var UsedTower = Towers[_id];
        // Calculate how much has to be paid. 
        uint256 Paid = mul(UsedTower.amount, UsedTower.payout) / 10000;
        
        // Remove paid from amount. 
        UsedTower.amount = sub(UsedTower.amount, Paid);
        
        // Send this Paid amount to owner. 
        UsedTower.owner.transfer(Paid);
        
        // Calculate new price. 
        uint256 newPrice = (UsedTower.price * UsedTower.minPriceAfterWin)/10000;
        
        // Check if lower than minPrice; if yes, set it to minPrice. 
        if (newPrice < UsedTower.minPrice){
            newPrice = UsedTower.minPrice;
        }
        
        // Upgrade tower price. 
        UsedTower.price = newPrice;
        
         // Will we move on with game?
        if (UsedTower.amount > UsedTower.minPrice){
            // RESTART game. OWNER STAYS SAME 
            UsedTower.timestamp = block.timestamp;
        }
        else{
            // amount too low. do not restart.
            UsedTower.timestamp = 0;
        }
    
        // Emit TowerWon event. 
        emit TowerWon(_id);
    }
    
    
    // TakePrize, can be called by everyone if contract is open.
    // Usually owner of tower can call this. 
    // Note that if you are too late because someone else paid it, then this person will pay you. 
    // There is no way to cheat that.
    // id = tower id. (id&#39;s start with 0, not 1!)
    function TakePrize(uint256 _id) public onlyOpen{
        require(_id < next_tower_index);
        var UsedTower = Towers[_id];
        require(UsedTower.timestamp > 0); // otherwise game has not started.
        var Timing = getTimer(_id);
        if (block.timestamp > (add(UsedTower.timestamp,  Timing))){
            Payout_intern(_id);
        }
        else{
            revert();
        }
    }
    
    // Shoot the previous Robin Hood! 
    // If you want, you can also buy your own tower again. This might be used to extract leftovers into the amount. 
    
    // _id = tower id   (starts at 0 for first tower);
    // _quote is optional: you can upload a quote to troll your enemies.
    function ShootRobinHood(uint256 _id, string _quote) public payable onlyOpen{
        require(_id < next_tower_index);
        var UsedTower = Towers[_id];
        var Timing = getTimer(_id);
    
        // Check if game has started and if we are too late. If yes, we pay out and return. 
        if (UsedTower.timestamp != 0 && block.timestamp > (add(UsedTower.timestamp,  Timing))){
            Payout_intern(_id);
            // We will not buy, give tokens back. 
            if (msg.value > 0){
                msg.sender.transfer(msg.value);
            }
            return;
        }
        
        // Check if enough price. 
        require(msg.value >= UsedTower.price);
        // Tower can still be bought, great. 
        
        uint256 devFee_used = (mul( UsedTower.price, 5))/100;
        uint256 creatorFee = (mul(UsedTower.creatorFee, UsedTower.price)) / 10000;
        uint256 divFee = (mul(UsedTower.price,  tokenDividend)) / 100;
        
        // Add dividend
        addDividend(divFee);
        // Buy div tokens 
        processBuyAmount(UsedTower.price);
        
        // Calculate what we put into amount (ToPay)
        
        uint256 ToPay = sub(sub(UsedTower.price, devFee_used), creatorFee);
        
        //Pay creator the creator fee. 
        uint256 diff = sub(msg.value, UsedTower.price);
        if (creatorFee != 0){
            UsedTower.creator.transfer(creatorFee);
        }
        // Did you send too much? Get back difference. 
        if (diff > 0){
            msg.sender.transfer(diff); 
        }
        
        // Pay dev. 
        owner.transfer(devFee_used);
        
        // Change results. 
        // Set timestamp to current time. 
        UsedTower.timestamp = block.timestamp;
        // Set you as owner 
        UsedTower.owner = msg.sender;
        // Set (or reset) quote 
        UsedTower.quote = _quote;
        // Add ToPay to amount, which you can earn if you win. 
        UsedTower.amount = add(UsedTower.amount, sub(ToPay, divFee));
        // Upgrade price of tower
        UsedTower.price = (UsedTower.price * (10000 + UsedTower.priceIncrease)) / 10000;
        
        // Emit TowerBought event 
        emit TowerBought(_id);
    }
    

    
    
    
    
    // Not interesting, safe math functions
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
         return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
   }

   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
    
    
    // START OF DIVIDEND PART


    // total number of tokens
    uint256 public numTokens;
    // amount of dividend in pool 
    uint256 public ethDividendAmount;
    // 15 szabo start price per token 
    uint256 constant public tokenStartPrice = 1000000000000;
    // 1 szabo increase per token 
    uint256 constant public tokenIncrease = 100000000000;
    
    // token price tracker. 
    uint256 public tokenPrice = tokenStartPrice;
    
    // percentage token dividend 
    uint8 constant public tokenDividend = 5;
    
    // token scale factor to make sure math is correct.
    uint256 constant public tokenScaleFactor = 1000;
    
    // address link to how much token that address has 
    mapping(address => uint256) public tokensPerAddress;
    //mapping(address => uint256) public payments;
    
    
    // add dividend to pool
    function addDividend(uint256 amt) internal {
        ethDividendAmount = ethDividendAmount + amt;
    }
    
    // get how much tokens you get for amount 
    // bah area calculation results in a quadratic equation
    // i hate square roots in solidity
    function getNumTokens(uint256 amt) internal  returns (uint256){
        uint256 a = tokenIncrease;
        uint256 b = 2*tokenPrice - tokenIncrease;
      //  var c = -2*amt;
        uint256 D = b*b + 8*a*amt;
        uint256 sqrtD = tokenScaleFactor*sqrt(D);
        //uint256 (sqrtD - b) / (2*a);
        return (sqrtD - (b * tokenScaleFactor)) / (2*a);
    }
    
    // buy tokens, only being called from robinhood. 
    function processBuyAmount(uint256 amt) internal {
        uint256 tokens = getNumTokens(amt );
        tokensPerAddress[msg.sender] = add(tokensPerAddress[msg.sender], tokens);

        
        numTokens = add(numTokens, tokens);
        //uint256 tokens_normscale = tokens;
        //pushuint(tokens);
        
        // check new price.
        
        //tokenPrice = tokenPrice + (( (tokens * tokens ) + tokens) / 2) * tokenIncrease;
        
       tokenPrice = add(tokenPrice , ((mul(tokenIncrease, tokens))/tokenScaleFactor));

    }
    
    // sell ALL your tokens to claim your dividend 
    function sellTokens() public {
        uint256 tokens = tokensPerAddress[msg.sender];
        if (tokens > 0 && numTokens >= tokens){
            // get amount of tokens: 
            uint256 usetk = numTokens;
            uint256 amt = 0;
            if (numTokens > 0){
             amt = (mul(tokens, ethDividendAmount))/numTokens ;
            }
            if (numTokens < tokens){
                usetk = tokens;
            }
            
            // update price. 
            
            uint256 nPrice = (sub(tokenPrice, ((mul(tokenIncrease, tokens))/ (2*tokenScaleFactor)))) ;
            
            if (nPrice < tokenStartPrice){
                nPrice = tokenStartPrice;
            }
            tokenPrice = nPrice; 
            
            // update tokens 
            
            tokensPerAddress[msg.sender] = 0; 
            
            // update total tokens 
            
            if (tokens <= numTokens){
                numTokens = numTokens - tokens; 
            }
            else{
                numTokens = 0;
            }
            
            
            // update dividend 
            
            if (amt <= ethDividendAmount){
                ethDividendAmount = ethDividendAmount - amt;
            }
            else{
                ethDividendAmount = 0;
            }
            
            // pay 
            
            if (amt > 0){
                msg.sender.transfer(amt);
            }
        }
    }
    
    // square root function, taken from ethereum stack exchange 
    function sqrt(uint x) internal returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    
}