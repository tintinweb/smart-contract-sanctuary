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

    struct Round {
        Jackpot globalJackpot;
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
    }

    Kingdom[] public kingdoms;
    Transaction[] public kingdomTransactions;
    uint public currentRound;
    address public bookerAddress;
    
    mapping(uint => Round) rounds;

    uint constant public ACTION_TAX = 0.02 ether;
    uint constant public STARTING_CLAIM_PRICE_WEI = 0.05 ether;
    uint constant MAXIMUM_CLAIM_PRICE_WEI = 800 ether;
    uint constant KINGDOM_MULTIPLIER = 20;
    uint constant TEAM_COMMISSION_RATIO = 10;
    uint constant JACKPOT_COMMISSION_RATIO = 10;

    // MODIFIERS

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
    
    // EVENTS

    event LandCreatedEvent(string kingdomKey, address monarchAddress);
    event LandPurchasedEvent(string kingdomKey, address monarchAddress);

    //
    //  CONTRACT CONSTRUCTOR
    //
    function Map(address _bookerAddress, uint _startTime) {
        bookerAddress = _bookerAddress;
        currentRound = 1;
        rounds[currentRound] = Round(Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), 0, 0);
        rounds[currentRound].jackpot1 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot2 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot3 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot4 = Jackpot(address(0), 0);
        rounds[currentRound].jackpot5 = Jackpot(address(0), 0);
        rounds[currentRound].startTime = _startTime;
        rounds[currentRound].endTime = _startTime + 7 days;
        rounds[currentRound].globalJackpot = Jackpot(address(0), 0);
     }

    function () { }

    function getRemainingKingdoms() public view returns (uint nb) {
        for (uint i = 1; i < 8; i++) {
            if (now < rounds[currentRound].startTime + (i * 1 days)) {
                uint result = (10 * i);
                if (result > 70) { 
                    return 70; 
                } else {
                    return result;
                }
            }
        }
    }

    function setTypedJackpotWinner(address _user, uint _type) internal {
        if (_type == 1) {
            if (rounds[currentRound].jackpot1.winner == address(0)) {
                rounds[currentRound].jackpot1.winner = _user;
            } else if (rounds[currentRound].nbKingdomsType1[_user] >= rounds[currentRound].nbKingdomsType1[rounds[currentRound].jackpot1.winner]) {
                rounds[currentRound].jackpot1.winner = _user;
            }
        } else if (_type == 2) {
            if (rounds[currentRound].jackpot2.winner == address(0)) {
                rounds[currentRound].jackpot2.winner = _user;
            } else if (rounds[currentRound].nbKingdomsType2[_user] >= rounds[currentRound].nbKingdomsType2[rounds[currentRound].jackpot2.winner]) {
                rounds[currentRound].jackpot2.winner = _user;
            }
        } else if (_type == 3) {
            if (rounds[currentRound].jackpot3.winner == address(0)) {
                rounds[currentRound].jackpot3.winner = _user;
            } else if (rounds[currentRound].nbKingdomsType3[_user] >= rounds[currentRound].nbKingdomsType3[rounds[currentRound].jackpot3.winner]) {
                rounds[currentRound].jackpot3.winner = _user;
            }
        } else if (_type == 4) {
            if (rounds[currentRound].jackpot4.winner == address(0)) {
                rounds[currentRound].jackpot4.winner = _user;
            } else if (rounds[currentRound].nbKingdomsType4[_user] >= rounds[currentRound].nbKingdomsType4[rounds[currentRound].jackpot4.winner]) {
                rounds[currentRound].jackpot4.winner = _user;
            }
        } else if (_type == 5) {
            if (rounds[currentRound].jackpot5.winner == address(0)) {
                rounds[currentRound].jackpot5.winner = _user;
            } else if (rounds[currentRound].nbKingdomsType5[_user] >= rounds[currentRound].nbKingdomsType5[rounds[currentRound].jackpot5.winner]) {
                rounds[currentRound].jackpot5.winner = _user;
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
        
        uint jackpotSplitted = jackpotCommission.mul(50).div(100);
        round.globalJackpot.balance = round.globalJackpot.balance.add(jackpotSplitted);

        kingdom.kingdomTier++;
        kingdom.title = _title;

        if (kingdom.kingdomTier == 5) {
            kingdom.returnPrice = 0;
        } else {
            kingdom.returnPrice = kingdom.minimumPrice.mul(2);
            kingdom.minimumPrice = kingdom.minimumPrice.add(kingdom.minimumPrice.mul(2));
        }

        kingdom.owner = msg.sender;
        kingdom.locked = _locked;

        uint transactionId = kingdomTransactions.push(Transaction("", msg.sender, msg.value, 0, jackpotSplitted)) - 1;
        kingdomTransactions[transactionId].kingdomKey = _key;
        kingdom.transactionCount++;
        kingdom.lastTransaction = transactionId;
        
        setNewJackpot(kingdom.kingdomType, jackpotSplitted, msg.sender);
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
        setNewWinner(msg.sender, kingdomType);
    }

    function setLock(string _key, bool _locked) public payable checkKingdomExistence(_key) onlyKingdomOwner(_key, msg.sender) {
        if (_locked == true) { require(msg.value >= ACTION_TAX); }
        kingdoms[rounds[currentRound].kingdomsKeys[_key]].locked = _locked;
        if (msg.value > 0) { asyncSend(bookerAddress, msg.value); }
    }

    // function setNbKingdomsType(uint kingdomType, address sender, bool increment) internal {
    //     if (kingdomType == 1) {
    //         if (increment == true) {
    //             rounds[currentRound].nbKingdomsType1[sender]++;
    //         } else {
    //             rounds[currentRound].nbKingdomsType1[sender]--;
    //         }
    //     } else if (kingdomType == 2) {
    //         if (increment == true) {
    //             rounds[currentRound].nbKingdomsType2[sender]++;
    //         } else {
    //             rounds[currentRound].nbKingdomsType2[sender]--;
    //         }
    //     } else if (kingdomType == 3) {
    //         if (increment == true) {
    //             rounds[currentRound].nbKingdomsType3[sender]++;
    //         } else {
    //             rounds[currentRound].nbKingdomsType3[sender]--;
    //         }
    //     } else if (kingdomType == 4) {
    //         if (increment == true) {
    //             rounds[currentRound].nbKingdomsType4[sender]++;
    //         } else {
    //             rounds[currentRound].nbKingdomsType4[sender]--;
    //         }
    //     } else if (kingdomType == 5) {
    //         if (increment == true) {
    //             rounds[currentRound].nbKingdomsType5[sender]++;
    //         } else {
    //             rounds[currentRound].nbKingdomsType5[sender]--;
    //         }
    //     }
    // }

    // function upgradeKingdomType(string _key, uint _type) public payable checkKingdomExistence(_key) onlyKingdomOwner(_key, msg.sender) {
    //     require(msg.value >= ACTION_TAX);
    //     require(_type > 0);
    //     require(_type < 6);
    //     require(kingdoms[rounds[currentRound].kingdomsKeys[_key]].owner == msg.sender);
    //     uint kingdomType = kingdoms[rounds[currentRound].kingdomsKeys[_key]].kingdomType;
    //     setNbKingdomsType(kingdomType, msg.sender, false);

        
    //     setNbKingdomsType(_type, msg.sender, true);
    //     setTypedJackpotWinner(msg.sender, _type);

    //     kingdoms[rounds[currentRound].kingdomsKeys[_key]].kingdomType = _type;
    //     asyncSend(bookerAddress, msg.value);
    // }

    //
    //  User can call this function to generate new kingdoms (within the limits of available land)
    //
    function createKingdom(address owner, string _key, string _title, uint _type, bool _locked) onlyForRemainingKingdoms() public payable {
        require(now < rounds[currentRound].endTime);
        require(_type > 0);
        require(_type < 6);
        uint basePrice = STARTING_CLAIM_PRICE_WEI;
        uint requiredPrice = basePrice;
        if (_locked == true) { requiredPrice = requiredPrice.add(ACTION_TAX); }
        require(msg.value >= requiredPrice);
        require(rounds[currentRound].kingdomsCreated[_key] == false);
        uint refundPrice = STARTING_CLAIM_PRICE_WEI.mul(2);
        uint nextMinimumPrice = STARTING_CLAIM_PRICE_WEI.add(refundPrice);
        uint kingdomId = kingdoms.push(Kingdom("", "", 1, _type, 0, 0, 1, refundPrice, address(0), false)) - 1;
        
        kingdoms[kingdomId].title = _title;
        kingdoms[kingdomId].owner = owner;
        kingdoms[kingdomId].key = _key;
        kingdoms[kingdomId].minimumPrice = nextMinimumPrice;
        kingdoms[kingdomId].locked = _locked;

        rounds[currentRound].kingdomsKeys[_key] = kingdomId;
        rounds[currentRound].kingdomsCreated[_key] = true;
        
        uint jackpotSplitted = requiredPrice.mul(50).div(100);
        rounds[currentRound].globalJackpot.balance = rounds[currentRound].globalJackpot.balance.add(jackpotSplitted);

        uint transactionId = kingdomTransactions.push(Transaction("", msg.sender, msg.value, 0, jackpotSplitted)) - 1;
        kingdomTransactions[transactionId].kingdomKey = _key;
        kingdoms[kingdomId].lastTransaction = transactionId;
       
        setNewJackpot(_type, jackpotSplitted, msg.sender);
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

    function payJackpot(uint _type) public checkIsClosed() {
        Round storage finishedRound = rounds[currentRound];
        if (_type == 1 && finishedRound.jackpot1.winner != address(0) && finishedRound.jackpot1.balance > 0) {
            require(this.balance >= finishedRound.jackpot1.balance);
            uint jackpot1TeamComission = (finishedRound.jackpot1.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            asyncSend(bookerAddress, jackpot1TeamComission);
            asyncSend(finishedRound.jackpot1.winner, finishedRound.jackpot1.balance.sub(jackpot1TeamComission));
            finishedRound.jackpot1.balance = 0;
        } else if (_type == 2 && finishedRound.jackpot2.winner != address(0) && finishedRound.jackpot2.balance > 0) {
            require(this.balance >= finishedRound.jackpot2.balance);
            uint jackpot2TeamComission = (finishedRound.jackpot2.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            asyncSend(bookerAddress, jackpot2TeamComission);
            asyncSend(finishedRound.jackpot2.winner, finishedRound.jackpot2.balance.sub(jackpot2TeamComission));
            finishedRound.jackpot2.balance = 0;
        } else if (_type == 3 && finishedRound.jackpot3.winner != address(0) && finishedRound.jackpot3.balance > 0) {
            require(this.balance >= finishedRound.jackpot3.balance);
            uint jackpot3TeamComission = (finishedRound.jackpot3.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            asyncSend(bookerAddress, jackpot3TeamComission);
            asyncSend(finishedRound.jackpot3.winner, finishedRound.jackpot3.balance.sub(jackpot3TeamComission));
            finishedRound.jackpot3.balance = 0;
        } else if (_type == 4 && finishedRound.jackpot4.winner != address(0) && finishedRound.jackpot4.balance > 0) {
            require(this.balance >= finishedRound.jackpot4.balance);
            uint jackpot4TeamComission = (finishedRound.jackpot4.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            asyncSend(bookerAddress, jackpot4TeamComission);
            asyncSend(finishedRound.jackpot4.winner, finishedRound.jackpot4.balance.sub(jackpot4TeamComission));
            finishedRound.jackpot4.balance = 0;
        } else if (_type == 5 && finishedRound.jackpot5.winner != address(0) && finishedRound.jackpot5.balance > 0) {
            require(this.balance >= finishedRound.jackpot5.balance);
            uint jackpot5TeamComission = (finishedRound.jackpot5.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            asyncSend(bookerAddress, jackpot5TeamComission);
            asyncSend(finishedRound.jackpot5.winner, finishedRound.jackpot5.balance.sub(jackpot5TeamComission));
            finishedRound.jackpot5.balance = 0;
        }

        if (finishedRound.globalJackpot.winner != address(0) && finishedRound.globalJackpot.balance > 0) {
            require(this.balance >= finishedRound.globalJackpot.balance);
            uint globalTeamComission = (finishedRound.globalJackpot.balance.mul(TEAM_COMMISSION_RATIO)).div(100);
            asyncSend(bookerAddress, globalTeamComission);
            asyncSend(finishedRound.globalJackpot.winner, finishedRound.globalJackpot.balance.sub(globalTeamComission));
            finishedRound.globalJackpot.balance = 0;
        }
    }

    //
    //  After time expiration, owner can call this function to activate the next round of the game
    //
    function activateNextRound() public checkIsClosed() {
        Round storage finishedRound = rounds[currentRound];
        require(finishedRound.globalJackpot.balance == 0);
        require(finishedRound.jackpot5.balance == 0);
        require(finishedRound.jackpot4.balance == 0);
        require(finishedRound.jackpot3.balance == 0);
        require(finishedRound.jackpot2.balance == 0);
        require(finishedRound.jackpot1.balance == 0);
        currentRound++;
        rounds[currentRound] = Round(Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), Jackpot(address(0), 0), 0, 0);
        rounds[currentRound].startTime = now;
        rounds[currentRound].endTime = now + 7 days;
        delete kingdoms;
        delete kingdomTransactions;
    }

    // GETTER AND SETTER FUNCTIONS

    function setNewWinner(address _sender, uint _type) internal {
        if (rounds[currentRound].globalJackpot.winner == address(0)) {
            rounds[currentRound].globalJackpot.winner = _sender;
        } else {
            if (rounds[currentRound].nbKingdoms[_sender] == rounds[currentRound].nbKingdoms[rounds[currentRound].globalJackpot.winner]) {
                if (rounds[currentRound].nbTransactions[_sender] > rounds[currentRound].nbTransactions[rounds[currentRound].globalJackpot.winner]) {
                    rounds[currentRound].globalJackpot.winner = _sender;
                }
            } else if (rounds[currentRound].nbKingdoms[_sender] > rounds[currentRound].nbKingdoms[rounds[currentRound].globalJackpot.winner]) {
                rounds[currentRound].globalJackpot.winner = _sender;
            }
        }
        setTypedJackpotWinner(_sender, _type);
    }

    function getJackpot(uint _nb) public view returns (address winner, uint balance, uint winnerCap) {
        Round storage round = rounds[currentRound];
        if (_nb == 1) {
            return (round.jackpot1.winner, round.jackpot1.balance, round.nbKingdomsType1[round.jackpot1.winner]);
        } else if (_nb == 2) {
            return (round.jackpot2.winner, round.jackpot2.balance, round.nbKingdomsType2[round.jackpot2.winner]);
        } else if (_nb == 3) {
            return (round.jackpot3.winner, round.jackpot3.balance, round.nbKingdomsType3[round.jackpot3.winner]);
        } else if (_nb == 4) {
            return (round.jackpot4.winner, round.jackpot4.balance, round.nbKingdomsType4[round.jackpot4.winner]);
        } else if (_nb == 5) {
            return (round.jackpot5.winner, round.jackpot5.balance, round.nbKingdomsType5[round.jackpot5.winner]);
        } else {
            return (round.globalJackpot.winner, round.globalJackpot.balance, round.nbKingdoms[round.globalJackpot.winner]);
        }
    }

    function getKingdomCount() public view returns (uint kingdomCount) {
        return kingdoms.length;
    }

    function getKingdomInformations(string kingdomKey) public view returns (string title, uint minimumPrice, uint lastTransaction, uint transactionCount, address currentOwner, bool locked) {
        uint kingdomId = rounds[currentRound].kingdomsKeys[kingdomKey];
        Kingdom storage kingdom = kingdoms[kingdomId];
        return (kingdom.title, kingdom.minimumPrice, kingdom.lastTransaction, kingdom.transactionCount, kingdom.owner, kingdom.locked);
    }

}