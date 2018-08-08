pragma solidity ^0.4.24;

contract BettingInterface {
    // place a bet on a coin(horse) lockBetting
    function placeBet(bytes32 horse) external payable;
    // method to claim the reward amount
    function claim_reward() external;

    mapping (bytes32 => bool) public winner_horse;
    
    function checkReward() external constant returns (uint);
}

/**
 * @dev Allows to bet on a race and receive future tokens used to withdraw winnings
*/
contract HorseFutures {
    
    event Claimed(address indexed Race, uint256 Count);
    event Selling(bytes32 Id, uint256 Amount, uint256 Price, address indexed Race, bytes32 Horse, address indexed Owner);
    event Buying(bytes32 Id, uint256 Amount, uint256 Price, address indexed Race, bytes32 Horse, address indexed Owner);
    event Canceled(bytes32 Id, address indexed Owner,address indexed Race);
    event Bought(bytes32 Id, uint256 Amount, address indexed Owner, address indexed Race);
    event Sold(bytes32 Id, uint256 Amount, address indexed Owner, address indexed Race);
    event BetPlaced(address indexed EthAddr, address indexed Race);
    
    struct Offer
    {
        uint256 Amount;
        bytes32 Horse;
        uint256 Price;
        address Race;
        bool BuyType;
    }
    
    mapping(address => mapping(address => mapping(bytes32 => uint256))) ClaimTokens;
    mapping(address => mapping (bytes32 => uint256)) TotalTokensCoinRace;
    mapping(address => bool) ClaimedRaces;
    
    mapping(address => uint256) toDistributeRace;
    //market
    mapping(bytes32 => Offer) market;
    mapping(bytes32 => address) owner;
    mapping(address => uint256) public marketBalance;
    
    function placeBet(bytes32 horse, address race) external payable
    _validRace(race) {
        BettingInterface raceContract = BettingInterface(race);
        raceContract.placeBet.value(msg.value)(horse);
        uint256 c = uint256(msg.value / 1 finney);
        ClaimTokens[msg.sender][race][horse] += c;
        TotalTokensCoinRace[race][horse] += c;

        emit BetPlaced(msg.sender, race);
    }
    
    function getOwnedAndTotalTokens(bytes32 horse, address race) external view
    _validRace(race) 
    returns(uint256,uint256) {
        return (ClaimTokens[msg.sender][race][horse],TotalTokensCoinRace[race][horse]);
    }

    // required for the claimed ether to be transfered here
    function() public payable { }
    
    function claim(address race) external
    _validRace(race) {
        BettingInterface raceContract = BettingInterface(race);
        if(!ClaimedRaces[race]) {
            toDistributeRace[race] = raceContract.checkReward();
            raceContract.claim_reward();
            ClaimedRaces[race] = true;
        }

        uint256 totalWinningTokens = 0;
        uint256 ownedWinningTokens = 0;

        bool btcWin = raceContract.winner_horse(bytes32("BTC"));
        bool ltcWin = raceContract.winner_horse(bytes32("LTC"));
        bool ethWin = raceContract.winner_horse(bytes32("ETH"));

        if(btcWin)
        {
            totalWinningTokens += TotalTokensCoinRace[race][bytes32("BTC")];
            ownedWinningTokens += ClaimTokens[msg.sender][race][bytes32("BTC")];
            ClaimTokens[msg.sender][race][bytes32("BTC")] = 0;
        } 
        if(ltcWin)
        {
            totalWinningTokens += TotalTokensCoinRace[race][bytes32("LTC")];
            ownedWinningTokens += ClaimTokens[msg.sender][race][bytes32("LTC")];
            ClaimTokens[msg.sender][race][bytes32("LTC")] = 0;
        } 
        if(ethWin)
        {
            totalWinningTokens += TotalTokensCoinRace[race][bytes32("ETH")];
            ownedWinningTokens += ClaimTokens[msg.sender][race][bytes32("ETH")];
            ClaimTokens[msg.sender][race][bytes32("ETH")] = 0;
        }

        uint256 claimerCut = toDistributeRace[race] / totalWinningTokens * ownedWinningTokens;
        
        msg.sender.transfer(claimerCut);
        
        emit Claimed(race, claimerCut);
    }
    
    function sellOffer(uint256 amount, uint256 price, address race, bytes32 horse) external
    _validRace(race) 
    _validHorse(horse)
    returns (bytes32) {
        uint256 ownedAmount = ClaimTokens[msg.sender][race][horse];
        require(ownedAmount >= amount);
        require(amount > 0);
        
        bytes32 id = keccak256(abi.encodePacked(amount,price,race,horse,true,block.timestamp));
        require(owner[id] == address(0)); //must not already exist
        
        Offer storage newOffer = market[id];
        
        newOffer.Amount = amount;
        newOffer.Horse = horse;
        newOffer.Price = price;
        newOffer.Race = race;
        newOffer.BuyType = false;
        
        ClaimTokens[msg.sender][race][horse] -= amount;
        owner[id] = msg.sender;
        
        emit Selling(id,amount,price,race,horse,msg.sender);
        
        return id;
    }

    function getOffer(bytes32 id) external view returns(uint256,bytes32,uint256,address,bool) {
        Offer memory off = market[id];
        return (off.Amount,off.Horse,off.Price,off.Race,off.BuyType);
    }
    
    function buyOffer(uint256 amount, uint256 price, address race, bytes32 horse) external payable
    _validRace(race) 
    _validHorse(horse)
    returns (bytes32) {
        require(amount > 0);
        require(price > 0);
        require(msg.value == price * amount);
        bytes32 id = keccak256(abi.encodePacked(amount,price,race,horse,false,block.timestamp));
        require(owner[id] == address(0)); //must not already exist
        
        Offer storage newOffer = market[id];
        
        newOffer.Amount = amount;
        newOffer.Horse = horse;
        newOffer.Price = price;
        newOffer.Race = race;
        newOffer.BuyType = true;
        owner[id] = msg.sender;
        
        emit Buying(id,amount,price,race,horse,msg.sender);
        
        return id;
    }
    
    function cancelOrder(bytes32 id) external {
        require(owner[id] == msg.sender);
        
        Offer memory off = market[id];
        if(off.BuyType) {
            msg.sender.transfer(off.Amount * off.Price);
        }
        else {
            ClaimTokens[msg.sender][off.Race][off.Horse] += off.Amount;
        }
        

        emit Canceled(id,msg.sender,off.Race);
        delete market[id];
        delete owner[id];
    }
    
    function buy(bytes32 id, uint256 amount) external payable {
        require(owner[id] != address(0));
        require(owner[id] != msg.sender);
        Offer storage off = market[id];
        require(!off.BuyType);
        require(amount <= off.Amount);
        uint256 cost = off.Price * amount;
        require(msg.value >= cost);
        
        ClaimTokens[msg.sender][off.Race][off.Horse] += amount;
        marketBalance[owner[id]] += msg.value;

        emit Bought(id,amount,msg.sender, off.Race);
        
        if(off.Amount == amount)
        {
            delete market[id];
            delete owner[id];
        }
        else
        {
            off.Amount -= amount;
        }
    }

    function sell(bytes32 id, uint256 amount) external {
        require(owner[id] != address(0));
        require(owner[id] != msg.sender);
        Offer storage off = market[id];
        require(off.BuyType);
        require(amount <= off.Amount);
        
        uint256 cost = amount * off.Price;
        ClaimTokens[msg.sender][off.Race][off.Horse] -= amount;
        ClaimTokens[owner[id]][off.Race][off.Horse] += amount;
        marketBalance[owner[id]] -= cost;
        marketBalance[msg.sender] += cost;

        emit Sold(id,amount,msg.sender,off.Race);
        
        if(off.Amount == amount)
        {
            delete market[id];
            delete owner[id];
        }
        else
        {
            off.Amount -= amount;
        }
    }
    
    function withdraw() external {
        msg.sender.transfer(marketBalance[msg.sender]);
        marketBalance[msg.sender] = 0;
    }
    
    modifier _validRace(address race) {
        require(race != address(0));
        _;
    }

    modifier _validHorse(bytes32 horse) {
        require(horse == bytes32("BTC") || horse == bytes32("ETH") || horse == bytes32("LTC"));
        _;
    }
    
}