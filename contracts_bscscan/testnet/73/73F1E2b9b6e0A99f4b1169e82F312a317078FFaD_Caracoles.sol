/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity ^0.4.26;


contract Caracoles {
    using SafeMath for uint;
    
    /* Events */
    
    event WithdrewEarnings (address indexed player, uint ethreward);
    event ClaimedDivs (address indexed player, uint ethreward);
    event BoughtSnail (address indexed player, uint ethspent, uint snail);
    event SoldSnail (address indexed player, uint ethreward, uint snail);
    event HatchedSnail (address indexed player, uint ethspent, uint snail);
    event FedFrogking (address indexed player, uint ethreward, uint egg);
    event Ascended (address indexed player, uint ethreward, uint indexed round);
    event BecamePharaoh (address indexed player, uint indexed round);
    event NewDivs (uint ethreward);
    
    /* Constants */
    
    uint256 public GOD_TIMER_START      = 28800; //seconds, or 8 hours
	uint256 public PHARAOH_REQ_START    = 40; //number of snails to become pharaoh
    uint256 public GOD_TIMER_INTERVAL   = 10; //seconds to remove one snail from req
	uint256 public GOD_TIMER_BOOST		= 300; //seconds added to timer with new pharaoh
    uint256 public TIME_TO_HATCH_1SNAIL = 1080000; //8% daily
    uint256 public TOKEN_PRICE_FLOOR    = 0.00002 ether; //4 zeroes
    uint256 public TOKEN_PRICE_MULT     = 0.0000000001 ether; //10 zeroes
    uint256 public TOKEN_MAX_BUY        = 4 ether; //max allowed eth in one buy transaction
    uint256 public SNAIL_REQ_REF        = 100; //number of snails for ref link to be active
	
    /* Variables */
    
    //Becomes true one time to start the game
    bool public gameStarted             = false;
    
    //Used to ensure a proper game start
    address public gameOwner;
    
    //SnailGod round, amount, timer
    uint256 public godRound             = 0;
    uint256 public godPot               = 0;
    uint256 public godTimer             = 0;
    
    //Current Pharaoh
    address public pharaoh;
    
    //Last time throne was claimed or pharaohReq was computed
    uint256 public lastClaim;
    
    //Snails required to become the Pharaoh
    uint256 public pharaohReq           = PHARAOH_REQ_START;
    
    //Total number of snail tokens
    uint256 public maxSnail             = 0;
    
    //Egg sell fund
    uint256 public frogPot              = 0;
    
    //Token sell fund
    uint256 public snailPot             = 0;
    
    //Current divs per snail
    uint256 public divsPerSnail         = 0;
    	
    /* Mappings */
    
    mapping (address => uint256) public hatcherySnail;
    mapping (address => uint256) public lastHatch;
    mapping (address => uint256) public playerEarnings;
    mapping (address => uint256) public claimedDivs;
	
    /* Functions */
    
    // ACTIONS
    
    // Constructor
    // Sets msg.sender as gameOwner to start the game properly
    
    constructor() public {
        gameOwner = msg.sender;
    }

    // StartGame
    // Initialize godTimer
    // Set pharaoh and lastPharaoh as gameOwner
    // Buy tokens for value of message
    
    function StartGame() public payable {
        require(gameStarted == false);
        require(msg.sender == gameOwner);
        
        godTimer = now + GOD_TIMER_START;
        godRound = 1;
        gameStarted = true;
        pharaoh = gameOwner;
        lastClaim = now;
        BuySnail(msg.sender);
    }
    
    // WithdrawEarnings
    // Sends all player ETH earnings to his wallet
    
    function WithdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        
        uint256 _amount = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewEarnings(msg.sender, _amount);
    }
    
    // ClaimDivs
    // Sends player dividends to his playerEarnings
    // Adjusts claimable dividends
    
    function ClaimDivs() public {
        
        uint256 _playerDivs = ComputeMyDivs();
        
        if(_playerDivs > 0) {
            //Add new divs to claimed divs
            claimedDivs[msg.sender] = claimedDivs[msg.sender].add(_playerDivs);
            
            //Send divs to playerEarnings
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_playerDivs);
            
            emit ClaimedDivs(msg.sender, _playerDivs);
        }
    }
    
    // BuySnail 
    
    function BuySnail(address _ref) public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(tx.origin == msg.sender, "contracts not allowed");
        require(msg.value <= TOKEN_MAX_BUY, "maximum buy = 4 ETH");
        
        //Calculate price and resulting snails
        uint256 _snailsBought = ComputeBuy(msg.value);
        
        //Adjust player claimed divs
        claimedDivs[msg.sender] = claimedDivs[msg.sender].add(_snailsBought.mul(divsPerSnail));
        
        //Change maxSnail before new div calculation
        maxSnail = maxSnail.add(_snailsBought);
        
        //Divide incoming ETH
        PotSplit(msg.value, _ref, true);
        
        //Set last hatch to current timestamp
        lastHatch[msg.sender] = now;
        
        //Add player snails
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(_snailsBought);
        
        emit BoughtSnail(msg.sender, msg.value, _snailsBought);
    }
    
    // SellSnail
    
    function SellSnail(uint256 _tokensSold) public {
        require(gameStarted == true, "game hasn't started yet");
        require(hatcherySnail[msg.sender] >= _tokensSold, "not enough snails to sell");
        
        //Call ClaimDivs so ETH isn't blackholed
        ClaimDivs();

        //Check token price, sell price is half of current buy price
        uint256 _tokenSellPrice = ComputeTokenPrice();
        _tokenSellPrice = _tokenSellPrice.div(2);
        
        //Check maximum ETH that can be obtained = 10% of SnailPot
        uint256 _maxEth = snailPot.div(10);
        
        //Check maximum amount of tokens that can be sold
        uint256 _maxTokens = _maxEth.div(_tokenSellPrice);
        
        //Check if player tried to sell too many tokens
        if(_tokensSold > _maxTokens) {
            _tokensSold = _maxTokens;
        }
        
        //Calculate sell reward, tokens * price per token
        uint256 _sellReward = _tokensSold.mul(_tokenSellPrice);
        
        //Remove reserve ETH 
        snailPot = snailPot.sub(_sellReward);
        
        //Remove tokens
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(_tokensSold);
        maxSnail = maxSnail.sub(_tokensSold);
        
        //Adjust player claimed divs
        claimedDivs[msg.sender] = claimedDivs[msg.sender].sub(divsPerSnail.mul(_tokensSold));
        
        //Give ETH to player 
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_sellReward);
        
        emit SoldSnail(msg.sender, _sellReward, _tokensSold);
    }
    
    // HatchEgg
    // Turns player eggs into snails
    // Costs half the ETH of a normal buy
    
    function HatchEgg() public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(msg.value > 0, "need ETH to hatch eggs");
        
        //Check how many eggs the ether sent can pay for
        uint256 _tokenPrice = ComputeTokenPrice().div(2);
        uint256 _maxHatch = msg.value.div(_tokenPrice);
        
        //Check number of eggs to hatch
        uint256 _newSnail = ComputeMyEggs(msg.sender);
        
        //Multiply by token price
        uint256 _snailPrice = _tokenPrice.mul(_newSnail);
        
        //Refund any extra ether
        uint256 _ethUsed = msg.value;
                
        if (msg.value > _snailPrice) {
            uint256 _refund = msg.value.sub(_snailPrice);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_refund);
            _ethUsed = _snailPrice;
        }
        
        //Adjust new snail amount if not enough ether 
        if (msg.value < _snailPrice) {
            _newSnail = _maxHatch;
        }
        
        //Adjust player divs
        claimedDivs[msg.sender] = claimedDivs[msg.sender].add(_newSnail.mul(divsPerSnail));
        
        //Change maxSnail before div calculation
        maxSnail = maxSnail.add(_newSnail);
        
        //Divide incoming ETH 
        PotSplit(_ethUsed, msg.sender, false);
        
        //Add new snails
        lastHatch[msg.sender] = now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(_newSnail);
        
        emit HatchedSnail(msg.sender, _ethUsed, _newSnail);
    }
    
    // PotSplit
    // Called on buy and hatch
    
    function PotSplit(uint256 _msgValue, address _ref, bool _buy) private {
        
        //On token buy, 50% of the ether goes to snailpot
        //On hatch, no ether goes to the snailpot
        uint256 _eth = _msgValue;
        
        if (_buy == true) {
            _eth = _msgValue.div(2);
            snailPot = snailPot.add(_eth);
        }
        
        //20% distributed as divs (40% on hatch)
        divsPerSnail = divsPerSnail.add(_eth.mul(2).div(5).div(maxSnail));
        
        //20% to FrogPot (40% on hatch)
        frogPot = frogPot.add(_eth.mul(2).div(5));
        
        //2% to Pharaoh (4% on hatch)
        playerEarnings[pharaoh] = playerEarnings[pharaoh].add(_eth.mul(2).div(50));
        
        //2% to SnailGod pot (4% on hatch)
        godPot = godPot.add(_eth.mul(2).div(50));
        
        //Check for referrals (300 snails required)
        //Give 6% to referrer if there is one
        //Else give 6% to SnailGod pot
        //Always give 12% to SnailGod pot on hatch
        if (_ref != msg.sender && hatcherySnail[_ref] >= SNAIL_REQ_REF) {
            playerEarnings[_ref] = playerEarnings[_ref].add(_eth.mul(6).div(50));
        } else {
            godPot = godPot.add(_eth.mul(6).div(50));
        }
    }
    
    // FeedEgg
    // Sacrifices the player's eggs to the FrogPot
    // Gives ETH in return
    
    function FeedEgg() public {
        require(gameStarted == true, "game hasn't started yet");
        
        //Check number of eggs to hatch
        uint256 _eggsUsed = ComputeMyEggs(msg.sender);
        
        //Remove eggs
        lastHatch[msg.sender] = now;
        
        //Calculate ETH earned
        uint256 _reward = _eggsUsed.mul(frogPot).div(maxSnail);
        frogPot = frogPot.sub(_reward);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_reward);
        
        emit FedFrogking(msg.sender, _reward, _eggsUsed);
    }
    
    // AscendGod
    // Distributes SnailGod pot to winner, restarts timer 
    
    function AscendGod() public {
		require(gameStarted == true, "game hasn't started yet");
        require(now >= godTimer, "pharaoh hasn't ascended yet");
        
        //Reset timer and start new round 
        godTimer = now + GOD_TIMER_START;
        pharaohReq = PHARAOH_REQ_START;
        godRound = godRound.add(1);
        
        //Calculate and give reward
        uint256 _godReward = godPot.div(2);
        godPot = godPot.sub(_godReward);
        playerEarnings[pharaoh] = playerEarnings[pharaoh].add(_godReward);
        
        emit Ascended(pharaoh, _godReward, godRound);
        
        //msg.sender becomes pharaoh 
        pharaoh = msg.sender;
    }

    // BecomePharaoh
    // Sacrifices snails to become the Pharaoh
    
    function BecomePharaoh(uint256 _snails) public {
        require(gameStarted == true, "game hasn't started yet");
        require(hatcherySnail[msg.sender] >= _snails, "not enough snails in hatchery");
        
        //Run end round function if round is over
        if(now >= godTimer) {
            AscendGod();
        }
        
        //Call ClaimDivs so ETH isn't blackholed
        ClaimDivs();
        
        //Check number of snails to remove from pharaohReq
        uint256 _snailsToRemove = ComputePharaohReq();
        
        //Save claim time to lower number of snails later
        lastClaim = now;
        
        //Adjust pharaohReq
        if(pharaohReq < _snailsToRemove){
            pharaohReq = PHARAOH_REQ_START;
        } else {
            pharaohReq = pharaohReq.sub(_snailsToRemove);
            if(pharaohReq < PHARAOH_REQ_START){
                pharaohReq = PHARAOH_REQ_START;
            }
        }
        
        //Make sure player fits requirement
        if(_snails >= pharaohReq) {
            
        //Remove snails
            maxSnail = maxSnail.sub(_snails);
            hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(_snails);
            
        //Adjust msg.sender claimed dividends
            claimedDivs[msg.sender] = claimedDivs[msg.sender].sub(_snails.mul(divsPerSnail));
        
        //Add 8 minutes to timer
            godTimer = godTimer.add(GOD_TIMER_BOOST);
            
        //pharaohReq becomes the amount of snails sacrificed + 40
            pharaohReq = _snails.add(PHARAOH_REQ_START);

        //msg.sender becomes new Pharaoh
            pharaoh = msg.sender;
            
            emit BecamePharaoh(msg.sender, godRound);
        }
    }
    
    // fallback function
    // Distributes sent ETH as dividends
    
    function() public payable {
        divsPerSnail = divsPerSnail.add(msg.value.div(maxSnail));
        
        emit NewDivs(msg.value);
    }
    
    // VIEW
    
    // ComputePharaohReq
    // Returns number of snails to remove from pharaohReq
    // Snail requirement lowers by 1 every 12 seconds

    function ComputePharaohReq() public view returns(uint256) {
        uint256 _timeLeft = now.sub(lastClaim);
        uint256 _req = _timeLeft.div(GOD_TIMER_INTERVAL);
        return _req;
    }

    // ComputeTokenPrice
    // Returns ETH required to buy one snail
    // 1 snail = (T_P_FLOOR + (T_P_MULT * total amount of snails)) eth
    
    function ComputeTokenPrice() public view returns(uint256) {
        return TOKEN_PRICE_FLOOR.add(TOKEN_PRICE_MULT.mul(maxSnail));
    }
    
    // ComputeBuy
    // Returns snails bought for a given amount of ETH 
    
    function ComputeBuy(uint256 _ether) public view returns(uint256) {
        uint256 _tokenPrice = ComputeTokenPrice();
        return _ether.div(_tokenPrice);
    }
    
    // ComputeMyEggs
    // Returns eggs produced since last hatch or sacrifice
	// Egg amount can never be above current snail count
    
    function ComputeMyEggs(address adr) public view returns(uint256) {
        uint256 _eggs = now.sub(lastHatch[adr]);
        _eggs = _eggs.mul(hatcherySnail[adr]).div(TIME_TO_HATCH_1SNAIL);
        if (_eggs > hatcherySnail[adr]) {
            _eggs = hatcherySnail[adr];
        }
        return _eggs;
    }
    
    // ComputeMyDivs
    // Returns unclaimed divs for the player
    
    function ComputeMyDivs() public view returns(uint256) {
        //Calculate share of player
        uint256 _playerShare = divsPerSnail.mul(hatcherySnail[msg.sender]);
		
        //Subtract already claimed divs
    	_playerShare = _playerShare.sub(claimedDivs[msg.sender]);
        return _playerShare;
    }
    
    // GetMySnails
    // Returns player snails
    
    function GetMySnails() public view returns(uint256) {
        return hatcherySnail[msg.sender];
    }
    
    // GetMyEarnings
    // Returns player earnings
    
    function GetMyEarnings() public view returns(uint256) {
        return playerEarnings[msg.sender];
    }
    
    // GetContractBalance
    // Returns ETH in contract
    
    function GetContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}