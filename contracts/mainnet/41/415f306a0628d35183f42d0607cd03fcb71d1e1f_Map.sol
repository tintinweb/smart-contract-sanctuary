pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function resetTimer(string _kingdomKey);
}

contract PullPayment {
  using SafeMath for uint256;
  mapping(address => uint256) public payments;
  uint256 public totalPayments;
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];
    require(payment != 0);
    require(this.balance >= payment);
    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;
    assert(payee.send(payment));
  }
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Destructible is Ownable {
  function Destructible() public payable { }
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract ReentrancyGuard {
  bool private reentrancy_lock = false;
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }
}

contract Map is PullPayment, Destructible, ReentrancyGuard {
    using SafeMath for uint256;
    
    // STRUCTS

    struct Transaction {
        string kingdomKey;
        address compensationAddress;
        uint buyingPrice;
        uint compensation;
        uint jackpotContribution;
        uint date;
    }

    struct Kingdom {
        string title;
        string key;
        uint kingdomTier;
        uint kingdomType;
        uint minimumPrice; 
        uint lastTransaction;
        uint transactionCount;
        uint returnPrice;
        address owner;
        bool locked;
    }

    struct Jackpot {
        address winner;
        uint balance;
    }

    // struct RoundPoints {
    //     mapping(address => uint) points;
    // }

    struct Round {
        Jackpot jackpot1;
        Jackpot jackpot2;
        Jackpot jackpot3;
        Jackpot jackpot4;
        Jackpot jackpot5;

        mapping(string => bool) kingdomsCreated;
        mapping(address => uint) nbKingdoms;
        mapping(address => uint) nbTransactions;
        mapping(address => uint) nbKingdomsType1;
        mapping(address => uint) nbKingdomsType2;
        mapping(address => uint) nbKingdomsType3;
        mapping(address => uint) nbKingdomsType4;
        mapping(address => uint) nbKingdomsType5;

        uint startTime;
        uint endTime;

        mapping(string => uint) kingdomsKeys;
        mapping(address => uint) scores;

    }


    Kingdom[] public kingdoms;
    Transaction[] public kingdomTransactions;
    uint public currentRound;
    address public bookerAddress;
    
    mapping(uint => Round) rounds;
    mapping(address => uint) lastTransaction;

    uint constant public ACTION_TAX = 0.02 ether;
    uint constant public STARTING_CLAIM_PRICE_WEI = 0.03 ether;
    uint constant MAXIMUM_CLAIM_PRICE_WEI = 800 ether;
    uint constant KINGDOM_MULTIPLIER = 20;
    uint constant TEAM_COMMISSION_RATIO = 10;
    uint constant JACKPOT_COMMISSION_RATIO = 10;

    // MODIFIERS

    modifier checkKingdomCap(address _owner, uint _kingdomType) {
        if (_kingdomType == 1) {
            require((rounds[currentRound].nbKingdomsType1[_owner] + 1) < 9);
        } else if (_kingdomType == 2) {
            require((rounds[currentRound].nbKingdomsType2[_owner] + 1) < 9);
        } else if (_kingdomType == 3) {
            require((rounds[currentRound].nbKingdomsType3[_owner] + 1) < 9);
        } else if (_kingdomType == 4) {
            require((rounds[currentRound].nbKingdomsType4[_owner] + 1) < 9);
        } else if (_kingdomType == 5) {
            require((rounds[currentRound].nbKingdomsType5[_owner] + 1) < 9);
        }
        _;
    }

    modifier onlyForRemainingKingdoms() {
        uint remainingKingdoms = getRemainingKingdoms();
        require(remainingKingdoms > kingdoms.length);
        _;
    }

    modifier checkKingdomExistence(string key) {
        require(rounds[currentRound].kingdomsCreated[key] == true);
        _;
    }

    modifier checkIsNotLocked(string kingdomKey) {
        require(kingdoms[rounds[currentRound].kingdomsKeys[kingdomKey]].locked != true);
        _;
    }

    modifier checkIsClosed() {
        require(now >= rounds[currentRound].endTime);
        _;
    }

    modifier onlyKingdomOwner(string _key, address _sender) {
        require (kingdoms[rounds[currentRound].kingdomsKeys[_key]].owner == _sender);
        _;
    }
    
    // ERC20 
    address public woodAddress;
    ERC20Basic woodInterface;
    // ERC20Basic rock;
    // ERC20Basic 

    // EVENTS

    event LandCreatedEvent(string kingdomKey, address monarchAddress);
    event LandPurchasedEvent(string kingdomKey, address monarchAddress);

    //
    //  CONTRACT CONSTRUCTOR
    //
    function Map(address _bookerAddress, address _woodAddress, uint _startTime, uint _endTime) {
        bookerAddress = _bookerAddress;
        woodAddress = _woodAddress;
        woodInterface = ERC20Basic(_woodAddress);
        currentRound = 1;
        rounds[currentRound] = Round(Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), 0, 0);
        rounds[currentRound].jackpot1 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot2 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot3 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot4 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot5 = Jackpot(address(0), 0);
        rounds[currentRound].startTime = _startTime;
        rounds[currentRound].endTime = _endTime;
     }

    function () { }

    function setWoodAddress (address _woodAddress) public onlyOwner  {
        woodAddress = _woodAddress;
        woodInterface = ERC20Basic(_woodAddress);
    }

    function getRemainingKingdoms() public view returns (uint nb) {
        for (uint i = 1; i < 8; i++) {
            if (now < rounds[currentRound].startTime + (i * 12 hours)) {
                uint result = (10 * i);
                if (result > 100) { 
                    return 100; 
                } else {
                    return result;
                }
            }
        }
    }

    //
    //  This is the main function. It is called to buy a kingdom
    //
    function purchaseKingdom(string _key, string _title, bool _locked) public 
    payable 
    nonReentrant()
    checkKingdomExistence(_key)
    checkIsNotLocked(_key)
    {
        require(now < rounds[currentRound].endTime);
        Round storage round = rounds[currentRound];
        uint kingdomId = round.kingdomsKeys[_key];
        Kingdom storage kingdom = kingdoms[kingdomId];
        require((kingdom.kingdomTier + 1) < 6);
        uint requiredPrice = kingdom.minimumPrice;
        if (_locked == true) {
            requiredPrice = requiredPrice.add(ACTION_TAX);
        }

        require (msg.value >= requiredPrice);
        uint jackpotCommission = (msg.value).sub(kingdom.returnPrice);

        if (kingdom.returnPrice > 0) {
            round.nbKingdoms[kingdom.owner]--;
            if (kingdom.kingdomType == 1) {
                round.nbKingdomsType1[kingdom.owner]--;
            } else if (kingdom.kingdomType == 2) {
                round.nbKingdomsType2[kingdom.owner]--;
            } else if (kingdom.kingdomType == 3) {
                round.nbKingdomsType3[kingdom.owner]--;
            } else if (kingdom.kingdomType == 4) {
                round.nbKingdomsType4[kingdom.owner]--;
            } else if (kingdom.kingdomType == 5) {
                round.nbKingdomsType5[kingdom.owner]--;
            }
            compensateLatestMonarch(kingdom.lastTransaction, kingdom.returnPrice);
        }
        
        
        // woodInterface.resetTimer(_key);

        kingdom.kingdomTier++;
        kingdom.title = _title;

        if (kingdom.kingdomTier == 5) {
            kingdom.returnPrice = 0;
            kingdom.minimumPrice = 5 ether;
        } else if (kingdom.kingdomTier == 2) {
            kingdom.returnPrice = 0.1125 ether;
            kingdom.minimumPrice = 0.27 ether;
        } else if (kingdom.kingdomTier == 3) {
            kingdom.returnPrice = 0.3375 ether;
            kingdom.minimumPrice = 0.81 ether;
        } else if (kingdom.kingdomTier == 4) {
            kingdom.returnPrice = 1.0125 ether;
            kingdom.minimumPrice = 2.43 ether;
        }
        
        kingdom.owner = msg.sender;
        kingdom.locked = _locked;

        uint transactionId = kingdomTransactions.push(Transaction("", msg.sender, msg.value, 0, jackpotCommission, now)) - 1;
        kingdomTransactions[transactionId].kingdomKey = _key;
        kingdom.transactionCount++;
        kingdom.lastTransaction = transactionId;
        lastTransaction[msg.sender] = now;

        setNewJackpot(kingdom.kingdomType, jackpotCommission, msg.sender);
        LandPurchasedEvent(_key, msg.sender);
    }

    function setNewJackpot(uint kingdomType, uint jackpotSplitted, address sender) internal {
        rounds[currentRound].nbTransactions[sender]++;
        rounds[currentRound].nbKingdoms[sender]++;
        if (kingdomType == 1) {
            rounds[currentRound].nbKingdomsType1[sender]++;
            rounds[currentRound].jackpot1.balance = rounds[currentRound].jackpot1.balance.add(jackpotSplitted);
        } else if (kingdomType == 2) {
            rounds[currentRound].nbKingdomsType2[sender]++;
            rounds[currentRound].jackpot2.balance = rounds[currentRound].jackpot2.balance.add(jackpotSplitted);
        } else if (kingdomType == 3) {
            rounds[currentRound].nbKingdomsType3[sender]++;
            rounds[currentRound].jackpot3.balance = rounds[currentRound].jackpot3.balance.add(jackpotSplitted);
        } else if (kingdomType == 4) {
            rounds[currentRound].nbKingdomsType4[sender]++;
            rounds[currentRound].jackpot4.balance = rounds[currentRound].jackpot4.balance.add(jackpotSplitted);
        } else if (kingdomType == 5) {
            rounds[currentRound].nbKingdomsType5[sender]++;
            rounds[currentRound].jackpot5.balance = rounds[currentRound].jackpot5.balance.add(jackpotSplitted);
        }
    }

    function setLock(string _key, bool _locked) public payable checkKingdomExistence(_key) onlyKingdomOwner(_key, msg.sender) {
        if (_locked == true) { require(msg.value >= ACTION_TAX); }
        kingdoms[rounds[currentRound].kingdomsKeys[_key]].locked = _locked;
        if (msg.value > 0) { asyncSend(bookerAddress, msg.value); }
    }

    function giveKingdom(address owner, string _key, string _title, uint _type) onlyOwner() public {
        require(_type > 0);
        require(_type < 6);
        require(rounds[currentRound].kingdomsCreated[_key] == false);
        uint kingdomId = kingdoms.push(Kingdom("", "", 1, _type, 0, 0, 1, 0.02 ether, address(0), false)) - 1;
        kingdoms[kingdomId].title = _title;
        kingdoms[kingdomId].owner = owner;
        kingdoms[kingdomId].key = _key;
        kingdoms[kingdomId].minimumPrice = 0.03 ether;
        kingdoms[kingdomId].locked = false;
        rounds[currentRound].kingdomsKeys[_key] = kingdomId;
        rounds[currentRound].kingdomsCreated[_key] = true;
        uint transactionId = kingdomTransactions.push(Transaction("", msg.sender, 0.01 ether, 0, 0, now)) - 1;
        kingdomTransactions[transactionId].kingdomKey = _key;
        kingdoms[kingdomId].lastTransaction = transactionId;
    }

    //
    //  User can call this function to generate new kingdoms (within the limits of available land)
    //
    function createKingdom(string _key, string _title, uint _type, bool _locked) checkKingdomCap(msg.sender, _type) onlyForRemainingKingdoms() public payable {
        require(now < rounds[currentRound].endTime);
        require(_type > 0);
        require(_type < 6);
        uint basePrice = STARTING_CLAIM_PRICE_WEI;
        uint requiredPrice = basePrice;
        if (_locked == true) { requiredPrice = requiredPrice.add(ACTION_TAX); }
        require(msg.value >= requiredPrice);
        Round storage round = rounds[currentRound];
        require(round.kingdomsCreated[_key] == false);

        uint refundPrice = 0.0375 ether; // (STARTING_CLAIM_PRICE_WEI.mul(125)).div(100);
        uint nextMinimumPrice = 0.09 ether; // STARTING_CLAIM_PRICE_WEI.add(STARTING_CLAIM_PRICE_WEI.mul(2));

        uint kingdomId = kingdoms.push(Kingdom("", "", 1, 0, 0, 0, 1, refundPrice, address(0), false)) - 1;
        
        kingdoms[kingdomId].kingdomType = _type;
        kingdoms[kingdomId].title = _title;
        kingdoms[kingdomId].owner = msg.sender;
        kingdoms[kingdomId].key = _key;
        kingdoms[kingdomId].minimumPrice = nextMinimumPrice;
        kingdoms[kingdomId].locked = _locked;

        round.kingdomsKeys[_key] = kingdomId;
        round.kingdomsCreated[_key] = true;
        
        if(_locked == true) {
            asyncSend(bookerAddress, ACTION_TAX);
        }

        uint transactionId = kingdomTransactions.push(Transaction("", msg.sender, msg.value, 0, basePrice, now)) - 1;
        kingdomTransactions[transactionId].kingdomKey = _key;
        kingdoms[kingdomId].lastTransaction = transactionId;
        lastTransaction[msg.sender] = now;

        setNewJackpot(_type, basePrice, msg.sender);
        LandCreatedEvent(_key, msg.sender);
    }

    //
    //  Send transaction to compensate the previous owner
    //
    function compensateLatestMonarch(uint lastTransaction, uint compensationWei) internal {
        address compensationAddress = kingdomTransactions[lastTransaction].compensationAddress;
        kingdomTransactions[lastTransaction].compensation = compensationWei;
        asyncSend(compensationAddress, compensationWei);
    }

    //
    //  This function may be useful to force withdraw if user never come back to get his money
    //
    function forceWithdrawPayments(address payee) public onlyOwner {
        uint256 payment = payments[payee];
        require(payment != 0);
        require(this.balance >= payment);
        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;
        assert(payee.send(payment));
    }

    function getStartTime() public view returns (uint startTime) {
        return rounds[currentRound].startTime;
    }

    function getEndTime() public view returns (uint endTime) {
        return rounds[currentRound].endTime;
    }

    function payJackpot1() internal checkIsClosed() {
        address winner = getWinner(1);
        if (rounds[currentRound].jackpot1.balance > 0 && winner != address(0)) {
            require(this.balance >= rounds[currentRound].jackpot1.balance);
            rounds[currentRound].jackpot1.winner = winner;
            uint teamComission = (rounds[currentRound].jackpot1.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            bookerAddress.transfer(teamComission);
            uint jackpot = rounds[currentRound].jackpot1.balance.sub(teamComission);
            asyncSend(winner, jackpot);
            rounds[currentRound].jackpot1.balance = 0;
        }
    }

    function payJackpot2() internal checkIsClosed() {
        address winner = getWinner(2);
        if (rounds[currentRound].jackpot2.balance > 0 && winner != address(0)) {
            require(this.balance >= rounds[currentRound].jackpot2.balance);
            rounds[currentRound].jackpot2.winner = winner;
            uint teamComission = (rounds[currentRound].jackpot2.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            bookerAddress.transfer(teamComission);
            uint jackpot = rounds[currentRound].jackpot2.balance.sub(teamComission);
            asyncSend(winner, jackpot);
            rounds[currentRound].jackpot2.balance = 0;
        }
    }

    function payJackpot3() internal checkIsClosed() {
        address winner = getWinner(3);
        if (rounds[currentRound].jackpot3.balance > 0 && winner != address(0)) {
            require(this.balance >= rounds[currentRound].jackpot3.balance);
            rounds[currentRound].jackpot3.winner = winner;
            uint teamComission = (rounds[currentRound].jackpot3.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            bookerAddress.transfer(teamComission);
            uint jackpot = rounds[currentRound].jackpot3.balance.sub(teamComission);
            asyncSend(winner, jackpot);
            rounds[currentRound].jackpot3.balance = 0;
        }
    }

    function payJackpot4() internal checkIsClosed() {
        address winner = getWinner(4);
        if (rounds[currentRound].jackpot4.balance > 0 && winner != address(0)) {
            require(this.balance >= rounds[currentRound].jackpot4.balance);
            rounds[currentRound].jackpot4.winner = winner;
            uint teamComission = (rounds[currentRound].jackpot4.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            bookerAddress.transfer(teamComission);
            uint jackpot = rounds[currentRound].jackpot4.balance.sub(teamComission);
            asyncSend(winner, jackpot);
            rounds[currentRound].jackpot4.balance = 0;
        }
    }

    function payJackpot5() internal checkIsClosed() {
        address winner = getWinner(5);
        if (rounds[currentRound].jackpot5.balance > 0 && winner != address(0)) {
            require(this.balance >= rounds[currentRound].jackpot5.balance);
            rounds[currentRound].jackpot5.winner = winner;
            uint teamComission = (rounds[currentRound].jackpot5.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            bookerAddress.transfer(teamComission);
            uint jackpot = rounds[currentRound].jackpot5.balance.sub(teamComission);
            asyncSend(winner, jackpot);
            rounds[currentRound].jackpot5.balance = 0;
        }
    }

    //
    //  After time expiration, owner can call this function to activate the next round of the game
    //
    function activateNextRound(uint _startTime) public checkIsClosed() {
        payJackpot1();
        payJackpot2();
        payJackpot3();
        payJackpot4();
        payJackpot5();

        currentRound++;
        rounds[currentRound] = Round(Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), 0, 0);
        rounds[currentRound].startTime = _startTime;
        rounds[currentRound].endTime = _startTime + 7 days;
        delete kingdoms;
        delete kingdomTransactions;
    }

    // GETTER AND SETTER FUNCTIONS

    function getKingdomCount() public view returns (uint kingdomCount) {
        return kingdoms.length;
    }

    function getJackpot(uint _nb) public view returns (address winner, uint balance) {
        if (_nb == 1) {
            return (getWinner(1), rounds[currentRound].jackpot1.balance);
        } else if (_nb == 2) {
            return (getWinner(2), rounds[currentRound].jackpot2.balance);
        } else if (_nb == 3) {
            return (getWinner(3), rounds[currentRound].jackpot3.balance);
        } else if (_nb == 4) {
            return (getWinner(4), rounds[currentRound].jackpot4.balance);
        } else if (_nb == 5) {
            return (getWinner(5), rounds[currentRound].jackpot5.balance);
        }
    }

    function getKingdomType(string _kingdomKey) public view returns (uint kingdomType) {
        return kingdoms[rounds[currentRound].kingdomsKeys[_kingdomKey]].kingdomType;
    }

    function getKingdomOwner(string _kingdomKey) public view returns (address owner) {
        return kingdoms[rounds[currentRound].kingdomsKeys[_kingdomKey]].owner;
    }

    function getKingdomInformations(string _kingdomKey) public view returns (string title, uint minimumPrice, uint lastTransaction, uint transactionCount, address currentOwner, uint kingdomType, bool locked) {
        uint kingdomId = rounds[currentRound].kingdomsKeys[_kingdomKey];
        Kingdom storage kingdom = kingdoms[kingdomId];
        return (kingdom.title, kingdom.minimumPrice, kingdom.lastTransaction, kingdom.transactionCount, kingdom.owner, kingdom.kingdomType, kingdom.locked);
    }
 
    // function upgradeTier(string _key) public {
    //     // require(now < rounds[currentRound].endTime);
    //     Round storage round = rounds[currentRound];
    //     uint kingdomId = round.kingdomsKeys[_key];
    //     Kingdom storage kingdom = kingdoms[kingdomId];
    //     uint wood = woodInterface.balanceOf(kingdom.owner);
    //     require(wood >= 1);
    //     kingdom.kingdomTier++;
    // }

    function getWinner(uint _type) public returns (address winner) {
        require(_type > 0);
        require(_type < 6);

        address addr;
        uint maxPoints = 0;
        Round storage round = rounds[currentRound];

        for (uint index = 0; index < kingdoms.length; index++) {
            if (_type == kingdoms[index].kingdomType) {
                address userAddress = kingdoms[index].owner;
                if(kingdoms[index].kingdomTier == 1) {
                    round.scores[msg.sender] = round.scores[msg.sender] + 1;
                } else if(kingdoms[index].kingdomTier == 2) {
                    round.scores[msg.sender] = round.scores[msg.sender] + 3;
                } else if (kingdoms[index].kingdomTier == 3) {
                    round.scores[msg.sender] = round.scores[msg.sender] + 5;
                } else if (kingdoms[index].kingdomTier == 4) {
                    round.scores[msg.sender] = round.scores[msg.sender] + 8;
                } else if (kingdoms[index].kingdomTier == 5) {
                    round.scores[msg.sender] = round.scores[msg.sender] + 13;
                }
                
                if(round.scores[msg.sender] == maxPoints) {
                    if(lastTransaction[userAddress] < lastTransaction[winner]) {
                        addr = userAddress;
                    }
                } else if (round.scores[msg.sender] > maxPoints) {
                    maxPoints = round.scores[msg.sender];
                    addr = userAddress;
                }
            }
        }
        return addr;
    }
}