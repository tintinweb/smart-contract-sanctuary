pragma solidity ^0.4.23;

contract Dice {
    using SafeMath for uint;

    uint private randNonce;
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

    uint constant MIN_JACKPOT_BET = 0.1 ether;
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;

    // There is minimum and maximum bets.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

    uint constant MAX_MODULO = 100;

    uint constant MAX_MASK_MODULO = 40;
    // This is a check on bet mask overflow.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    address public owner;
    // Adjustable max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit = 2 ether;

    // Accumulated jackpot fund.
    uint public jackpotSize;

    bool public gameActive = true;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount);
    event JackpotPayment(address indexed beneficiary, uint amount);
    event LogBet(address indexed gambler, uint amount, uint betMask, uint modulo, uint rollUnder, uint result, uint canWin, uint diceWin, uint jackpotWin);

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier gameIsActive {
        require(gameActive == true);
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function() public payable {
    }

    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require(_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

    function setGameActive(bool value) public onlyOwner {
        gameActive = value;
    }

    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require(increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize.add(increaseAmount) <= address(this).balance, "Not enough funds.");
        jackpotSize = jackpotSize.add(increaseAmount);
    }

    // Funds withdrawal to cover costs of dice2.win operation.
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize.add(withdrawAmount) <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

    function placeBet(uint betMask, uint modulo) public payable gameIsActive {
        uint amount = msg.value;
        address gambler = msg.sender;
        require(modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require(amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // roll
            require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

        // Winning amount and jackpot increase.
        uint diceWinAmount;
        uint jackpotFee;

        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        // Enforce max profit limit.
        require(diceWinAmount <= amount.add(maxProfit), "maxProfit limit violation.");

        jackpotSize = jackpotSize.add(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require(jackpotSize <= address(this).balance, "Cannot afford to lose this bet.");

        uint dice = random(modulo);

        uint diceWin = 0;
        uint jackpotWin = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** dice) & betMask != 0) {
                diceWin = diceWinAmount;
            }

        } else {
            // For roll
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }

        }

        if (amount >= MIN_JACKPOT_BET) {
            uint jackpotRng = random(JACKPOT_MODULO);
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }
        // Log jackpot win.
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

        uint allReward = diceWin.add(jackpotWin);
        emit LogBet(gambler, amount, betMask, modulo, rollUnder, dice, diceWinAmount, diceWin, jackpotWin);

        if (allReward > 0) {
            sendFunds(gambler, allReward, diceWin);
        }
    }


    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");
        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;
        uint houseEdge = amount.mul(HOUSE_EDGE_PERCENT).div(100);
        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
        require(houseEdge.add(jackpotFee) <= amount, "Bet doesn&#39;t even cover house edge.");
        winAmount = (amount.sub(houseEdge).sub(jackpotFee)).mul(modulo).div(rollUnder);
    }

    // Helper routine to process the payment.
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    function random(uint upper) private returns (uint) {
        uint value = (uint)(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number).add(randNonce)
            )));
        randNonce = randNonce.add(3);
        return (value % upper);
    }

}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}