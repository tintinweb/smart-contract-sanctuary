/* LeewayHertz - AIG - Investment v0.79 - Pre-Prod
*  Developed and Deployed by LeewayHertz Blockchain Team C - Dhruv Govila, Rajat Singla, Jayesh Chaudhari, Deepak Shokeen, Raghav Gulati, Rohit Tandon
*  Global Repo Name: CA-LHTAIGLenderPlatform
*/

contract AIGInvestment {
    uint constant LONG_PHASE = 4;               
    uint constant SHORT_PHASE = 5;              
    uint constant HOUSE_EDGE = 2;               
    uint constant SAFEGUARD_THRESHOLD = 36000;  
    uint constant ARCHIVE_SIZE = 100;           

    uint public minWager = 500 finney;
    uint public maxNumInterests = 25;
    uint public bankroll = 0;
    int public profit = 0;

    address public investor;
    uint public investorBankroll = 0;
    int public investorProfit = 0;
    bool public isInvestorLocked = false;

    struct Interest {
        uint id;
        address borrower;
        uint8 pick;
        bool isMirrored;
        uint wager;
        uint payout;
        uint8 die;
        uint timestamp;
        address lender;
    }

    struct Generation {
        bytes32 seedHashA;
        bytes32 seedHashB;
        bytes32 seedA;
        bytes32 seedB;
        uint minWager;
        uint maxPayout;
        uint ofage;
        uint death;
        uint beneficiary;
        Interest[] interests;
        bool hasAction;
        Action action;
        int payoutId;
    }

    uint public oldestGen = 0;
    uint public nextGen = 0;
    mapping (uint => Generation) generations;

    address public owner;
    address public seedSourceA;
    address public seedSourceB;

    bytes32 public nextSeedHashA;
    bytes32 public nextSeedHashB;
    bool public hasNextSeedHashA;
    bool public hasNextSeedHashB;

    uint public outstandingPayouts;
    uint public totalInterests;

    struct Suitability {
        bool isSuitable;
        uint gen;
    }

    struct ParserResult {
        bool hasResult;
        uint8 pick;
        bool isMirrored;
        uint8 die;
    }

    enum ActionType { Withdrawal, InvestorDeposit, InvestorWithdrawal }

    struct Action {
        ActionType actionType;
        address sender;
        uint amount;
    }

    modifier onlyowner { if (msg.sender == owner) _; }
    modifier onlyseedsources { if (msg.sender == seedSourceA ||
                                   msg.sender == seedSourceB) _; }

    event InterestResolved(uint indexed id, uint8 contractDie, bool lenderPrincipals);

    function AIGInvestment() {
        
    }

    function numberOfHealthyGenerations() returns (uint n) {
        n = 0;
        for (uint i = oldestGen; i < nextGen; i++) {
            if (generations[i].death == 0) {
                n++;
            }
        }
    }

    function needsBirth() constant returns (bool needed) {
        return numberOfHealthyGenerations() < 3;
    }

    function roomForBirth() constant returns (bool hasRoom) {
        return numberOfHealthyGenerations() < 4;
    }

    function birth(bytes32 freshSeedHash) onlyseedsources {
        if (msg.sender == seedSourceA) {
            nextSeedHashA = freshSeedHash;
            hasNextSeedHashA = true;
        } else {
            nextSeedHashB = freshSeedHash;
            hasNextSeedHashB = true;
        }

        if (!hasNextSeedHashA || !hasNextSeedHashB || !roomForBirth()) {
            return;
        }

        
        generations[nextGen].seedHashA = nextSeedHashA;
        generations[nextGen].seedHashB = nextSeedHashB;
        generations[nextGen].minWager = minWager;
        generations[nextGen].maxPayout = (bankroll + investorBankroll) / 100;
        generations[nextGen].ofage = block.number + SHORT_PHASE;
        nextGen += 1;

        hasNextSeedHashA = false;
        hasNextSeedHashB = false;
    }

    function parseMsgData(bytes data) internal constant returns (ParserResult) {
        ParserResult memory result;

        if (data.length != 8) {
            result.hasResult = false;
            return result;
        }

        
        uint8 start = (uint8(data[0]) - 48) * 10 + (uint8(data[1]) - 48);
        uint8 end = (uint8(data[3]) - 48) * 10 + (uint8(data[4]) - 48);
        uint8 die = (uint8(data[6]) - 48) * 10 + (uint8(data[7]) - 48);

        if (start == 1) {
            result.hasResult = true;
            result.pick = end + 1;
            result.isMirrored = false;
            result.die = die;
        } else if (end == 20) {
            result.hasResult = true;
            result.pick = start;
            result.isMirrored = true;
            result.die = die;
        } else {
            result.hasResult = false;
        }

        return result;
    }

    function _parseMsgData(bytes data) constant returns (bool hasResult,
                                                         uint8 pick,
                                                         bool isMirrored,
                                                         uint8 die) {
        ParserResult memory result = parseMsgData(data);

        hasResult = result.hasResult;
        pick = result.pick;
        isMirrored = result.isMirrored;
        die = result.die;
    }

    function () {
        ParserResult memory result = parseMsgData(msg.data);

        if (result.hasResult) {
            interest(result.pick, result.isMirrored, result.die);
        } else {
            interest(11, true,
                toDie(sha3(block.blockhash(block.number - 1), totalInterests)));
        }
    }

    function interest(uint8 pick, bool isMirrored, uint8 die) returns (int) {
        if (pick < 2 || pick > 20) {
            msg.sender.send(msg.value);
            return -1;
        }

        if (die < 1 || die > 20) {
            msg.sender.send(msg.value);
            return -1;
        }

        Suitability memory suitability = findSuitableGen();
        uint suitableGen = suitability.gen;

        if (!suitability.isSuitable) {
            msg.sender.send(msg.value);
            return -1;
        }

        if (msg.value < generations[suitableGen].minWager) {
            msg.sender.send(msg.value);
            return -1;
        }

        uint payout = calculatePayout(pick, isMirrored, msg.value);
        if (payout > generations[suitableGen].maxPayout) {
            msg.sender.send(msg.value);
            return -1;
        }

        if (outstandingPayouts + payout > bankroll + investorBankroll) {
            msg.sender.send(msg.value);
            return -1;
        }

        uint idx = generations[suitableGen].interests.length;
        generations[suitableGen].interests.length += 1;
        generations[suitableGen].interests[idx].id = totalInterests;
        generations[suitableGen].interests[idx].lender = msg.sender;
        generations[suitableGen].interests[idx].pick = pick;
        generations[suitableGen].interests[idx].isMirrored = isMirrored;
        generations[suitableGen].interests[idx].wager = msg.value;
        generations[suitableGen].interests[idx].payout = payout;
        generations[suitableGen].interests[idx].die = die;
        generations[suitableGen].interests[idx].timestamp = now;

        totalInterests += 1;
        outstandingPayouts += payout;
        becomeMortal(suitableGen);

        return int(totalInterests - 1);  
    }

    function calculatePayout(uint8 pick, bool isMirrored,
                             uint value) constant returns (uint) {
        
        
        
        uint numPrincipalningOutcomes;
        if (isMirrored) {
            numPrincipalningOutcomes = 21 - pick;
        } else {
            numPrincipalningOutcomes = pick - 1;
        }
        uint payoutFactor = (100 - HOUSE_EDGE) * (20000 / numPrincipalningOutcomes);
        uint payout = (value * payoutFactor) / 100000;
        return payout;
    }

    function becomeMortal(uint gen) internal {
        if (generations[gen].death != 0) {
            return;
        }

        generations[gen].death = block.number + SHORT_PHASE;
    }

    function isSuitableGen(uint gen, uint offset) constant returns (bool) {
        return block.number + offset >= generations[gen].ofage
               && (generations[gen].death == 0
                   || block.number + offset < generations[gen].death)
               && generations[gen].interests.length < maxNumInterests;
    }

    function findSuitableGen() internal constant returns (Suitability
                                                          suitability) {
        suitability.isSuitable = false;
        for (uint i = oldestGen; i < nextGen; i++) {
            if (isSuitableGen(i, 0)) {
                suitability.gen = i;
                suitability.isSuitable = true;
                return;
            }
        }
    }

    function needsbeneficiary(uint offset) constant returns (bool needed) {
        if (oldestGen >= nextGen) {
            return false;
        }

        return generations[oldestGen].death != 0 &&
               generations[oldestGen].death + LONG_PHASE <= block.number + offset;
    }

    function beneficiary(bytes32 seed, int payoutId) onlyseedsources {
        if (!needsbeneficiary(0)) {
            return;
        }

        uint gen = oldestGen;
        if (msg.sender == seedSourceA
                && sha3(seed) == generations[gen].seedHashA) {
            generations[gen].seedA = seed;
        } else if (msg.sender == seedSourceB
                        && sha3(seed) == generations[gen].seedHashB) {
            generations[gen].seedB = seed;
        }

        if (sha3(generations[gen].seedA) != generations[gen].seedHashA
                || sha3(generations[gen].seedB) != generations[gen].seedHashB) {
            return;
        }

        
        for (uint i = 0; i < generations[gen].interests.length; i++) {
            uint8 contractDie = toContractDie(generations[gen].seedA,
                                              generations[gen].seedB,
                                              generations[gen].interests[i].id);
            uint8 pick = generations[gen].interests[i].pick;
            bool isMirrored = generations[gen].interests[i].isMirrored;
            uint payout = generations[gen].interests[i].payout;

            bool lenderPrincipals = interestResolution(contractDie,
                                            generations[gen].interests[i].die,
                                            pick, isMirrored);
            if (lenderPrincipals) {
                generations[gen].interests[i].lender.send(payout);
            }

            InterestResolved(generations[gen].interests[i].id, contractDie, lenderPrincipals);
            outstandingPayouts -= payout;

            
            if (investorBankroll >= bankroll) {
                
                uint investorShare = generations[gen].interests[i].wager / 2;
                uint ownerShare = generations[gen].interests[i].wager - investorShare;

                investorBankroll += investorShare;
                investorProfit += int(investorShare);
                bankroll += ownerShare;
                profit += int(ownerShare);

                if (lenderPrincipals) {
                    investorShare = payout / 2;
                    ownerShare = payout - investorShare;
                    if (ownerShare > bankroll) {
                        ownerShare = bankroll;
                        investorShare = payout - ownerShare;
                    } else if (investorShare > investorBankroll) {
                        investorShare = investorBankroll;
                        ownerShare = payout - investorShare;
                    }

                    investorBankroll -= investorShare;
                    investorProfit -= int(investorShare);
                    bankroll -= ownerShare;
                    profit -= int(ownerShare);
                }
            } else {
                bankroll += generations[gen].interests[i].wager;
                profit += int(generations[gen].interests[i].wager);

                if (lenderPrincipals) {
                    bankroll -= payout;
                    profit -= int(payout);
                }
            }
        }
        performAction(gen);

        
        generations[gen].beneficiary = block.number;
        generations[gen].payoutId = payoutId;

        
        oldestGen += 1;
        if (oldestGen >= ARCHIVE_SIZE) {
            delete generations[oldestGen - ARCHIVE_SIZE];
        }
    }

    function performAction(uint gen) internal {
        if (!generations[gen].hasAction) {
            return;
        }

        uint amount = generations[gen].action.amount;
        uint maxWithdrawal;
        if (generations[gen].action.actionType == ActionType.Withdrawal) {
            maxWithdrawal = (bankroll + investorBankroll) - outstandingPayouts;

            if (amount <= maxWithdrawal && amount <= bankroll) {
                owner.send(amount);
                bankroll -= amount;
            }
        } else if (generations[gen].action.actionType ==
                   ActionType.InvestorDeposit) {
            if (investor == 0) {
                investor = generations[gen].action.sender;
                investorBankroll = generations[gen].action.amount;
            } else if (investor == generations[gen].action.sender) {
                investorBankroll += generations[gen].action.amount;
            } else {
                uint investorLoss = 0;
                if (investorProfit < 0) {
                    investorLoss = uint(investorProfit * -1);
                }

                if (amount > investorBankroll + investorLoss) {
                    
                    
                    investor.send(investorBankroll + investorLoss);
                    investor = generations[gen].action.sender;
                    investorBankroll = amount - investorLoss;
                    investorProfit = 0;
                } else {
                    
                    generations[gen].action.sender.send(amount);
                }
            }
        } else if (generations[gen].action.actionType ==
                   ActionType.InvestorWithdrawal) {
            maxWithdrawal = (bankroll + investorBankroll) - outstandingPayouts;

            if (amount <= maxWithdrawal && amount <= investorBankroll
                    && investor == generations[gen].action.sender) {
                investor.send(amount);
                investorBankroll -= amount;
            }
        }
    }

    function emergencybeneficiary() {
        if (generations[oldestGen].death == 0 ||
                block.number - generations[oldestGen].death < SAFEGUARD_THRESHOLD) {
            return;
        }

        
        for (uint i = 0; i < generations[oldestGen].interests.length; i++) {
            uint wager = generations[oldestGen].interests[i].wager;
            uint payout = generations[oldestGen].interests[i].payout;

            generations[oldestGen].interests[i].lender.send(wager);
            outstandingPayouts -= payout;
        }
        performAction(oldestGen);

        generations[oldestGen].beneficiary = block.number;
        generations[oldestGen].payoutId = -1;

        oldestGen += 1;
        if (oldestGen >= ARCHIVE_SIZE) {
            delete generations[oldestGen - ARCHIVE_SIZE];
        }
    }

    function beneficiaryAndBirth(bytes32 seed, int payoutId,
                             bytes32 freshSeedHash) onlyseedsources {
        
        beneficiary(seed, payoutId);
        birth(freshSeedHash);
    }

    function lookupGeneration(uint gen) constant returns (bytes32 seedHashA,
                                                          bytes32 seedHashB,
                                                          bytes32 seedA,
                                                          bytes32 seedB,
                                                          uint minWager,
                                                          uint maxPayout,
                                                          uint ofage,
                                                          uint death,
                                                          uint beneficiary,
                                                          uint numInterests,
                                                          bool hasAction,
                                                          int payoutId) {
        seedHashA = generations[gen].seedHashA;
        seedHashB = generations[gen].seedHashB;
        seedA = generations[gen].seedA;
        seedB = generations[gen].seedB;
        minWager = generations[gen].minWager;
        maxPayout = generations[gen].maxPayout;
        ofage = generations[gen].ofage;
        death = generations[gen].death;
        beneficiary = generations[gen].beneficiary;
        numInterests = generations[gen].interests.length;
        hasAction = generations[gen].hasAction;
        payoutId = generations[gen].payoutId;
    }

    function lookupInterest(uint gen, uint interest) constant returns (uint id,
                                                             address lender,
                                                             uint8 pick,
                                                             bool isMirrored,
                                                             uint wager,
                                                             uint payout,
                                                             uint8 die,
                                                             uint timestamp) {
        id = generations[gen].interests[interest].id;
        lender = generations[gen].interests[interest].lender;
        pick = generations[gen].interests[interest].pick;
        isMirrored = generations[gen].interests[interest].isMirrored;
        wager = generations[gen].interests[interest].wager;
        payout = generations[gen].interests[interest].payout;
        die = generations[gen].interests[interest].die;
        timestamp = generations[gen].interests[interest].timestamp;
    }

    function findRecentInterest(address lender) constant returns (int id, uint gen,
                                                             uint interest) {
        for (uint i = nextGen - 1; i >= oldestGen; i--) {
            for (uint j = generations[i].interests.length - 1; j >= 0; j--) {
                if (generations[i].interests[j].lender == lender) {
                    id = int(generations[i].interests[j].id);
                    gen = i;
                    interest = j;
                    return;
                }
            }
        }

        id = -1;
        return;
    }

    function toDie(bytes32 data) constant returns (uint8 die) {
        
        
        
        
        
        uint256 FACTOR = 5789604461865809771178549250434395392663499233282028201972879200395656481997;
        return uint8(uint256(data) / FACTOR) + 1;
    }

    function toContractDie(bytes32 seedA, bytes32 seedB,
                           uint nonce) constant returns (uint8 die) {
        return toDie(sha3(seedA, seedB, nonce));
    }

    function hash(bytes32 data) constant returns (bytes32 hash) {
        return sha3(data);
    }

    function combineInterest(uint8 dieA, uint8 dieB) constant returns (uint8 die) {
        die = dieA + dieB;
        if (die > 20) {
            die -= 20;
        }
    }

    function interestResolution(uint8 contractDie, uint8 lenderDie,
                           uint8 pick, bool isMirrored) constant returns (bool) {
        uint8 die = combineInterest(contractDie, lenderDie);
        return (isMirrored && die >= pick) || (!isMirrored && die < pick);
    }

    function lowerMinWager(uint _minWager) onlyowner {
        if (_minWager < minWager) {
            minWager = _minWager;
        }
    }

    function raiseMaxNumInterests(uint _maxNumInterests) onlyowner {
        if (_maxNumInterests > maxNumInterests) {
            maxNumInterests = _maxNumInterests;
        }
    }

    function setOwner(address _owner) onlyowner {
        owner = _owner;
    }

    function deposit() onlyowner {
        bankroll += msg.value;
    }

    function withdraw(uint amount) onlyowner {
        Suitability memory suitability = findSuitableGen();
        uint suitableGen = suitability.gen;

        if (!suitability.isSuitable) {
            return;
        }

        if (generations[suitableGen].hasAction) {
            return;
        }

        generations[suitableGen].action.actionType = ActionType.Withdrawal;
        generations[suitableGen].action.amount = amount;
        generations[suitableGen].hasAction = true;
        becomeMortal(suitableGen);
    }

    function investorDeposit() {
        if (isInvestorLocked && msg.sender != investor) {
            return;
        }

        Suitability memory suitability = findSuitableGen();
        uint suitableGen = suitability.gen;

        if (!suitability.isSuitable) {
            return;
        }

        if (generations[suitableGen].hasAction) {
            return;
        }

        generations[suitableGen].action.actionType = ActionType.InvestorDeposit;
        generations[suitableGen].action.sender = msg.sender;
        generations[suitableGen].action.amount = msg.value;
        generations[suitableGen].hasAction = true;
        becomeMortal(suitableGen);
    }

    function investorWithdraw(uint amount) {
        Suitability memory suitability = findSuitableGen();
        uint suitableGen = suitability.gen;

        if (!suitability.isSuitable) {
            return;
        }

        if (generations[suitableGen].hasAction) {
            return;
        }

        generations[suitableGen].action.actionType = ActionType.InvestorWithdrawal;
        generations[suitableGen].action.sender = msg.sender;
        generations[suitableGen].action.amount = amount;
        generations[suitableGen].hasAction = true;
        becomeMortal(suitableGen);
    }

    function setInvestorLock(bool _isInvestorLocked) onlyowner {
        isInvestorLocked = _isInvestorLocked;
    }

    function setSeedSourceA(address _seedSourceA) {
        if (msg.sender == seedSourceA || seedSourceA == 0) {
            seedSourceA = _seedSourceA;
        }
    }

    function setSeedSourceB(address _seedSourceB) {
        if (msg.sender == seedSourceB || seedSourceB == 0) {
            seedSourceB = _seedSourceB;
        }
    }
}