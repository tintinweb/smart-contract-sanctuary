pragma solidity ^0.4.24;

contract Owned {
    address public aOwner;
    address public coOwner1;
    address public coOwner2;

    constructor() public {
        aOwner = msg.sender;
        coOwner1 = msg.sender;
        coOwner2 = msg.sender;
    }

    /* Modifiers */
    modifier onlyOwner {
        require(msg.sender == aOwner || msg.sender == coOwner1 || msg.sender == coOwner2);
        _;
    }

    function setCoOwner1(address _coOwner) public onlyOwner {
      coOwner1 = _coOwner;
    }

    function setCoOwner2(address _coOwner) public onlyOwner {
      coOwner2 = _coOwner;
    }
}


contract XEther is Owned {
    /* Structurs and variables */
    uint256 public totalInvestmentAmount = 0;
    uint256 public ownerFeePercent = 50; // 5%
    uint256 public investorsFeePercent = 130; // 13%

    uint256 public curIteration = 1;

    uint256 public depositsCount = 0;
    uint256 public investorsCount = 1;

    uint256 public bankAmount = 0;
    uint256 public feeAmount = 0;

    uint256 public toGwei = 1000000000; // or 1e9, helper vars
    uint256 public minDepositAmount = 20000000; // minimum deposit
    uint256 public minLotteryAmount = 100000000; // minimum to participate in lottery
    uint256 public minInvestmentAmount = 5 ether; // min for investment

    bool public isWipeAllowed = true; // wipe only if bank almost became empty
    uint256 public investorsCountLimit = 7; // maximum investors
    uint256 public lastTransaction = now;

    // Stage variables
    uint256 private stageStartTime = now;
    uint private currentStage = 1;
    uint private stageTime = 86400; // time of stage in minutes
    uint private stageMin = 0;
    uint private stageMax = 72;

    // lottery
    uint256 public jackpotBalance = 0;
    uint256 public jackpotPercent = 20; // 2%

    uint256 _seed;

    // Deposits mapping
    mapping(uint256 => address) public depContractidToAddress;
    mapping(uint256 => uint256) public depContractidToAmount;
    mapping(uint256 => bool) public depContractidToLottery;

    // Investors mapping
    mapping(uint256 => address) public investorsAddress;
    mapping(uint256 => uint256) public investorsInvested;
    mapping(uint256 => uint256) public investorsComissionPercent;
    mapping(uint256 => uint256) public investorsEarned;

    /* Events */
    event EvDebug (
        uint amount
    );

    /* New income transaction*/
    event EvNewDeposit (
        uint256 iteration,
        uint256 bankAmount,
        uint256 index,
        address sender,
        uint256 amount,
        uint256 multiplier,
        uint256 time
    );

    /* New investment added */
    event EvNewInvestment (
        uint256 iteration,
        uint256 bankAmount,
        uint256 index,
        address sender,
        uint256 amount,
        uint256[] investorsFee
    );

    /* Collect investors earned, when some one get payment */
    event EvInvestorsComission (
        uint256 iteration,
        uint256[] investorsComission
    );

    /* Bank amount increased */
    event EvUpdateBankAmount (
        uint256 iteration,
        uint256 deposited,
        uint256 balance
    );

    /* Payout for deposit */
    event EvDepositPayout (
        uint256 iteration,
        uint256 bankAmount,
        uint256 index,
        address receiver,
        uint256 amount,
        uint256 fee,
        uint256 jackpotBalance
    );

    /* newIteration */
    event EvNewIteration (
        uint256 iteration
    );

    /* No more funds in the bank, need actions (e.g. new iteration) */
    event EvBankBecomeEmpty (
        uint256 iteration,
        uint256 index,
        address receiver,
        uint256 payoutAmount,
        uint256 bankAmount
    );

    /* Investor get payment */
    event EvInvestorPayout (
        uint256 iteration,
        uint256 bankAmount,
        uint256 index,
        uint256 amount,
        bool status
    );

    /* Investors get payment */
    event EvInvestorsPayout (
        uint256 iteration,
        uint256 bankAmount,
        uint256[] payouts,
        bool[] statuses
    );

    /* New stage - time of withdraw is tapered */
    event EvStageChanged (
        uint256 iteration,
        uint timeDiff,
        uint stage
    );

    /* Lottery numbers */
    event EvLotteryWin (
        uint256 iteration,
        uint256 contractId,
        address winer,
        uint256 amount
    );

    /* Check address with code*/
    event EvConfimAddress (
        address sender,
        bytes16 code
    );

    /* Lottery numbers */
    event EvLotteryNumbers (
        uint256 iteration,
        uint256 index,
        uint256[] lotteryNumbers
    );

    /* Manually update Jackpot amount */
    event EvUpdateJackpot (
        uint256 iteration,
        uint256 amount,
        uint256 balance
    );

    /*---------- constructor ------------*/
    constructor() public {
        investorsAddress[0] = aOwner;
        investorsInvested[0] = 0;
        investorsComissionPercent[0] = 0;
        investorsEarned[0] = 0;
    }

    /*--------------- public methods -----------------*/
    function() public payable {
        require(msg.value > 0 && msg.sender != address(0));

        uint256 amount = msg.value / toGwei; // convert to gwei

        if (amount >= minDepositAmount) {
            lastTransaction = block.timestamp;
            newDeposit(msg.sender, amount);
        }
        else {
            bankAmount += amount;
        }
    }

    function newIteration() public onlyOwner {
        require(isWipeAllowed);

        payoutInvestors();

        investorsInvested[0] = 0;
        investorsCount = 1;

        totalInvestmentAmount = 0;
        bankAmount = 0;
        feeAmount = 0;
        depositsCount = 0;

        // Stage vars update
        currentStage = 1;
        stageStartTime = now;
        stageMin = 0;
        stageMax = 72;

        curIteration += 1;

        emit EvNewIteration(curIteration);

        uint256 realBalance = address(this).balance - (jackpotBalance * toGwei);
        if (realBalance > 0) {
          aOwner.transfer(realBalance);
        }
    }

    function updateBankAmount() public onlyOwner payable {
        require(msg.value > 0 && msg.sender != address(0));

        uint256 amount = msg.value / toGwei;

        isWipeAllowed = false;

        bankAmount += amount;
        totalInvestmentAmount += amount;

        emit EvUpdateBankAmount(curIteration, amount, bankAmount);

        recalcInvestorsFee(msg.sender, amount);
    }

    function newInvestment() public payable {
        require(msg.value >= minInvestmentAmount && msg.sender != address(0));

        address sender = msg.sender;
        uint256 investmentAmount = msg.value / toGwei; // convert to gwei

        addInvestment(sender, investmentAmount);
    }

    /* Payout */
    function depositPayout(uint depositIndex, uint pAmount) public onlyOwner returns(bool) {
        require(depositIndex < depositsCount && depositIndex >= 0 && depContractidToAmount[depositIndex] > 0);
        require(pAmount <= 5);

        uint256 payoutAmount = depContractidToAmount[depositIndex];
        payoutAmount += (payoutAmount * pAmount) / 100;

        if (payoutAmount > bankAmount) {
            isWipeAllowed = true;
            // event payment not enaught bank amount
            emit EvBankBecomeEmpty(curIteration, depositIndex, depContractidToAddress[depositIndex], payoutAmount, bankAmount);
            return false;
        }

        uint256 ownerComission = (payoutAmount * ownerFeePercent) / 1000;
        investorsEarned[0] += ownerComission;

        uint256 addToJackpot = (payoutAmount * jackpotPercent) / 1000;
        jackpotBalance += addToJackpot;

        uint256 investorsComission = (payoutAmount * investorsFeePercent) / 1000;

        uint256 payoutComission = ownerComission + addToJackpot + investorsComission;

        uint256 paymentAmount = payoutAmount - payoutComission;

        bankAmount -= payoutAmount;
        feeAmount += ownerComission + investorsComission;

        emit EvDepositPayout(curIteration, bankAmount, depositIndex, depContractidToAddress[depositIndex], paymentAmount, payoutComission, jackpotBalance);

        updateInvestorsComission(investorsComission);

        depContractidToAmount[depositIndex] = 0;

        paymentAmount *= toGwei; // get back to wei
        depContractidToAddress[depositIndex].transfer(paymentAmount);

        if (depContractidToLottery[depositIndex]) {
            lottery(depContractidToAddress[depositIndex], depositIndex);
        }

        return true;
    }

    /* Payout to investors */
    function payoutInvestors() public {
        uint256 paymentAmount = 0;
        bool isSuccess = false;

        uint256[] memory payouts = new uint256[](investorsCount);
        bool[] memory statuses = new bool[](investorsCount);

        uint256 mFeeAmount = feeAmount;
        uint256 iteration = curIteration;

        for (uint256 i = 0; i < investorsCount; i++) {
            uint256 iEarned = investorsEarned[i];
            if (iEarned == 0) {
                continue;
            }
            paymentAmount = iEarned * toGwei; // get back to wei

            mFeeAmount -= iEarned;
            investorsEarned[i] = 0;

            isSuccess = investorsAddress[i].send(paymentAmount);
            payouts[i] = iEarned;
            statuses[i] = isSuccess;


        }
        emit EvInvestorsPayout(iteration, bankAmount, payouts, statuses);

        feeAmount = mFeeAmount;
    }

    /* Payout to investor */
    function payoutInvestor(uint256 investorId) public {
        require (investorId < investorsCount && investorsEarned[investorId] > 0);

        uint256 paymentAmount = investorsEarned[investorId] * toGwei; // get back to wei
        feeAmount -= investorsEarned[investorId];
        investorsEarned[investorId] = 0;

        bool isSuccess = investorsAddress[investorId].send(paymentAmount);

        emit EvInvestorPayout(curIteration, bankAmount, investorId, paymentAmount, isSuccess);
    }

    /* Helper function to check sender */
    function confirmAddress(bytes16 code) public {
        emit EvConfimAddress(msg.sender, code);
    }

    /* Show depositers and investors info */
    function depositInfo(uint256 contractId) view public returns(address _address, uint256 _amount, bool _participateInLottery) {
      return (depContractidToAddress[contractId], depContractidToAmount[contractId] * toGwei, depContractidToLottery[contractId]);
    }

    /* Show investors info by id */
    function investorInfo(uint256 contractId) view public returns(
        address _address, uint256 _invested, uint256 _comissionPercent, uint256 earned
    )
    {
      return (investorsAddress[contractId], investorsInvested[contractId] * toGwei,
        investorsComissionPercent[contractId], investorsEarned[contractId] * toGwei);
    }

    function showBankAmount() view public returns(uint256 _bankAmount) {
      return bankAmount * toGwei;
    }

    function showInvestorsComission() view public returns(uint256 _investorsComission) {
      return feeAmount * toGwei;
    }

    function showJackpotBalance() view public returns(uint256 _jackpotBalance) {
      return jackpotBalance * toGwei;
    }

    function showStats() view public returns(
        uint256 _ownerFeePercent, uint256 _investorsFeePercent, uint256 _jackpotPercent,
        uint256 _minDepositAmount, uint256 _minLotteryAmount,uint256 _minInvestmentAmount,
        string info
      )
    {
      return (ownerFeePercent, investorsFeePercent, jackpotPercent,
        minDepositAmount * toGwei, minLotteryAmount * toGwei, minInvestmentAmount,
        &#39;To get real percentages divide them to 10&#39;);
    }

    /* Function to change variables */
    function updateJackpotBalance() public onlyOwner payable {
        require(msg.value > 0 && msg.sender != address(0));
        jackpotBalance += msg.value / toGwei;
        emit EvUpdateJackpot(curIteration, msg.value, jackpotBalance);
    }

    /* Allow withdraw jackpot only if there are no transactions more then month*/
    function withdrawJackpotBalance(uint amount) public onlyOwner {
        require(jackpotBalance >= amount / toGwei && msg.sender != address(0));
        // withdraw jacpot if no one dont play more then month
        require(now - lastTransaction > 4 weeks);

        uint256 tmpJP = amount / toGwei;
        jackpotBalance -= tmpJP;

        // Lottery payment
        aOwner.transfer(amount);
        emit EvUpdateJackpot(curIteration, amount, jackpotBalance);
    }

    /*--------------- private methods -----------------*/
    function newDeposit(address _address, uint depositAmount) private {
        uint256 randMulti = random(100) + 200;
        uint256 rndX = random(1480);
        uint256 _time = getRandomTime(rndX);

        // Check is depositer hit the bonus number. Else return old multiplier.
        randMulti = checkForBonuses(rndX, randMulti);

        uint256 contractid = depositsCount;

        depContractidToAddress[contractid] = _address;
        depContractidToAmount[contractid] = (depositAmount * randMulti) / 100;
        depContractidToLottery[contractid] = depositAmount >= minLotteryAmount;

        depositsCount++;

        bankAmount += depositAmount;

        emit EvNewDeposit(curIteration, bankAmount, contractid, _address, depositAmount, randMulti, _time);
    }

    function addInvestment(address sender, uint256 investmentAmount) private {
        require( (totalInvestmentAmount < totalInvestmentAmount + investmentAmount) && (bankAmount < bankAmount + investmentAmount) );
        totalInvestmentAmount += investmentAmount;
        bankAmount += investmentAmount;

        recalcInvestorsFee(sender, investmentAmount);
    }

    function recalcInvestorsFee(address sender, uint256 investmentAmount) private {
        uint256 investorIndex = 0;
        bool isNewInvestor = true;
        uint256 investorFeePercent = 0;
        uint256[] memory investorsFee = new uint256[](investorsCount+1);

        for (uint256 i = 0; i < investorsCount; i++) {
            if (investorsAddress[i] == sender) {
                investorIndex = i;
                isNewInvestor = false;
                investorsInvested[i] += investmentAmount;
            }

            investorFeePercent = percent(investorsInvested[i], totalInvestmentAmount, 3);
            investorsComissionPercent[i] = investorFeePercent;
            investorsFee[i] = investorFeePercent;
        }

        if (isNewInvestor) {
            if (investorsCount > investorsCountLimit) revert(); // Limit investors count

            investorFeePercent = percent(investmentAmount, totalInvestmentAmount, 3);
            investorIndex = investorsCount;

            investorsAddress[investorIndex] = sender;
            investorsInvested[investorIndex] = investmentAmount;
            investorsComissionPercent[investorIndex] = investorFeePercent;

            investorsEarned[investorIndex] = 0;
            investorsFee[investorIndex] = investorFeePercent;

            investorsCount++;
        }

        emit EvNewInvestment(curIteration, bankAmount, investorIndex, sender, investmentAmount, investorsFee);
    }

    function updateInvestorsComission(uint256 amount) private {
        uint256 investorsTotalIncome = 0;
        uint256[] memory investorsComission = new uint256[](investorsCount);

        for (uint256 i = 1; i < investorsCount; i++) {
            uint256 investorIncome = (amount * investorsComissionPercent[i]) / 1000;

            investorsEarned[i] += investorIncome;
            investorsComission[i] = investorsEarned[i];

            investorsTotalIncome += investorIncome;
        }

        investorsEarned[0] += amount - investorsTotalIncome;

        emit EvInvestorsComission(curIteration, investorsComission);
    }

    function percent(uint numerator, uint denominator, uint precision) private pure returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;

        return (_quotient);
    }

    function random(uint numMax) private returns (uint256 result) {
        _seed = uint256(keccak256(abi.encodePacked(
            _seed,
            blockhash(block.number - 1),
            block.coinbase,
            block.difficulty
        )));

        return _seed % numMax;
    }

    function getRandomTime(uint num) private returns (uint256 result) {
        uint rndHours = random(68) + 4;
        result = 72 - (2 ** ((num + 240) / 60) + 240) % rndHours;
        checkStageCondition();
        result = numStageRecalc(result);

        return (result < 4) ? 4 : result;
    }

    function checkForBonuses(uint256 number, uint256 multiplier) private pure returns (uint256 newMultiplier) {
        if (number == 8) return 1000;
        if (number == 12) return 900;
        if (number == 25) return 800;
        if (number == 37) return 700;
        if (number == 42) return 600;
        if (number == 51) return 500;
        if (number == 63 || number == 65 || number == 67) {
            return 400;
        }

        return multiplier;
    }

    /*
    * Check for time of current stage, in case of timeDiff bigger then stage time
    * new stage states set.
    */
    function checkStageCondition() private {
        uint timeDiff = now - stageStartTime;

        if (timeDiff > stageTime && currentStage < 3) {
            currentStage++;
            stageMin += 10;
            stageMax -= 10;
            stageStartTime = now;
            emit EvStageChanged(curIteration, timeDiff, currentStage);
        }
    }

    /*
    * Recalculate hours regarding current stage and counting chance of bonus.
    */
    function numStageRecalc(uint256 curHours) private returns (uint256 result) {
        uint chance = random(110) + 1;
        if (currentStage > 1 && chance % 9 != 0) {
            if (curHours > stageMax) return stageMax;
            if (curHours < stageMin) return stageMin;
        }

        return curHours;
    }

    /*
    * Lottery main function
    */
    function lottery(address sender, uint256 index) private {
        bool lotteryWin = false;
        uint256[] memory lotteryNumbers = new uint256[](7);

        (lotteryWin, lotteryNumbers) = randomizerLottery(blockhash(block.number - 1), sender);

        emit EvLotteryNumbers(curIteration, index, lotteryNumbers);

        if (lotteryWin) {
          emit EvLotteryWin(curIteration, index, sender, jackpotBalance);
          uint256 tmpJP = jackpotBalance * toGwei; // get back to wei
          jackpotBalance = 0;

          // Lottery payment
          sender.transfer(tmpJP);
        }
    }

    /*
    * Lottery generator numbers by given hash.
    */
    function randomizerLottery(bytes32 hash, address sender) private returns(bool, uint256[] memory) {
        uint256[] memory lotteryNumbers = new uint256[](7);
        bytes32 userHash  = keccak256(abi.encodePacked(
            hash,
            sender,
            random(999)
        ));
        bool win = true;

        for (uint i = 0; i < 7; i++) {
            uint position = i + random(1);
            bytes1 charAtPos = charAt(userHash, position);
            uint8 firstNums = getLastN(charAtPos, 4);
            uint firstNumInt = uint(firstNums);

            if (firstNumInt > 9) {
                firstNumInt = 16 - firstNumInt;
            }

            lotteryNumbers[i] = firstNumInt;

            if (firstNums != 7) {
                win = false;
            }
        }

        return (win, lotteryNumbers);
    }

    function charAt(bytes32 b, uint char) private pure returns (bytes1) {
        return bytes1(uint8(uint(b) / (2**((31 - char) * 8))));
    }

    function getLastN(bytes1 a, uint8 n) private pure returns (uint8) {
        uint8 lastN = uint8(a) % uint8(2) ** n;
        return lastN;
    }
}