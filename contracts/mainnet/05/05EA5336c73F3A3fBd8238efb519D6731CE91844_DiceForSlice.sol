pragma solidity ^0.4.16;

/**
 * This contract specially developed for http://diceforslice.co
 * 
 * What is it?
 * This is a game that allows you to win an amount of ETH to your personal ethereum address.
 * The possible winning depends on your stake and on amount of ETH in the bank.
 *
 * Wanna profit?
 * Be a sponsor or referral - read more on http://diceforslice.co
 *
 * Win chances:
 * 1 dice = 1/6
 * 2 dice = 1/18
 * 3 dice = 1/36
 * 4 dice = 1/54
 * 5 dice = 1/64
 */

/**
 * @title Math
 * @dev Math operations with safety checks that throw on error. Added: random and "float" divide for numbers
 */
library Math {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function divf(int256 numerator, int256 denominator, uint256 precision) internal pure returns(int256) {
        int256 _numerator = numerator * int256(10 ** (precision + 1));
        int256 _quotient  = ((_numerator / denominator) + 5) / 10;
        return _quotient;
    }

    function percent(uint256 value, uint256 per) internal pure returns(uint256) {
        return uint256((divf(int256(value), 100, 4) * int256(per)) / 10000);
    }

    function random(uint256 nonce, int256 min, int256 max) internal view returns(int256) {
        return int256(uint256(keccak256(nonce + block.number + block.timestamp + uint256(block.coinbase))) % uint256((max - min))) + min;
    }
}


/**
 * @title Ownable
 * @dev Check contract ownable for some admin operations
 */
contract Ownable {
    address public owner;
    
    modifier onlyOwner()  { require(msg.sender == owner); _; }

    function Ownable() public {
        owner = msg.sender;
    }

    function updateContractOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


/**
 * @dev General contract
 */
contract DiceForSlice is Ownable {
    // Contract events
    event UserBet       (address user, uint8 number1, uint8 number2, uint8 number3, uint8 number4, uint8 number5);
    event DiceRoll      (uint8 number1, uint8 number2, uint8 number3, uint8 number4, uint8 number5);
    event Loser         (address loser);
    event WeHaveAWinner (address winner, uint256 amount);
    event OMGItIsJackPot(address winner);

    // Address storage for referral system
    mapping(address => uint256) private bets;

    // Sponsor data
    address private sponsor;
    uint256 private sponsorDiff  = 100000000000000000;
    uint256 public sponsorValue  = 0;

    // Nonce for more random
    uint256 private nonce        = 1;

    // Current balances of contract
    // -bank  - available reward value
    // -stock - available value for restore bank in emergency
    uint256 public bank          = 0;
    uint256 public stock         = 0;

    // Bet price
    uint256 private betPrice     = 500000000000000000;

    // Current bet split rules (in percent)
    uint8   private partBank     = 55;
    uint8   private partOwner    = 20;
    uint8   private partSponsor  = 12;
    uint8   private partStock    = 10;
    uint8   private partReferral = 3;

    // Current rewards (in percent from bank)
    uint8   private rewardOne    = 10;
    uint8   private rewardTwo    = 20;
    uint8   private rewardThree  = 30;
    uint8   private rewardFour   = 50;
    uint8   private jackPot      = 100;

    // Current number min max
    uint8   private minNumber    = 1;
    uint8   private maxNumber    = 6;

    /**
     * @dev Check is valid msg value
     */
    modifier isValidBet(uint8 reward) {
        require(msg.value == Math.percent(betPrice, reward));
        _;
    }

    /**
     * @dev Check bank not empty (empty is < betPrice eth)
     */
    modifier bankNotEmpty() {
        require(bank >= Math.percent(betPrice, rewardTwo));
        require(address(this).balance >= bank);
        _;
    }


    /**
     * @dev Special method for fill contract bank 
     */
    function fillTheBank() external payable {
        require(msg.value >= sponsorDiff);
        if (msg.value >= sponsorValue + sponsorDiff) {
            sponsorValue = msg.value;
            sponsor      = msg.sender;
        }
        bank = Math.add(bank, msg.value);
    }


    /**
     * @dev Restore value from stock
     */
    function appendStock(uint256 amount) external onlyOwner {
        require(amount > 0);
        require(stock >= amount);
        bank  = Math.add(bank,  amount);
        stock = Math.sub(stock, amount);
    }


    /**
     * @dev Get full contract balance
     */
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }


    /**
     * @dev Get random number
     */
    function getRN() internal returns(uint8) {
        // 7 is max because method sub min from max (7-1 = 6). Look in Math::random implementation
        nonce++;
        return uint8(Math.random(nonce, minNumber, maxNumber + minNumber));
    }


    /**
     * @dev Check is valid number
     */
    function isValidNumber(uint8 number) internal view returns(bool) {
        return number >= minNumber && number <= maxNumber;
    }


    /**
     * @dev Split user bet in some pieces:
     * - 55% go to bank
     * - 20% go to contract developer :)
     * - 12% go to sponsor
     * - 10% go to stock for future restores
     * - 3%  go to referral (if exists, if not - go into stock)
     */
    function splitTheBet(address referral) internal {
        uint256 _partBank     = Math.percent(msg.value, partBank);
        uint256 _partOwner    = Math.percent(msg.value, partOwner);
        uint256 _partStock    = Math.percent(msg.value, partStock);
        uint256 _partSponsor  = Math.percent(msg.value, partSponsor);
        uint256 _partReferral = Math.percent(msg.value, partReferral);
        
        bank  = Math.add(bank,  _partBank);
        stock = Math.add(stock, _partStock);
        owner.transfer(_partOwner);
        sponsor.transfer(_partSponsor);

        if (referral != address(0) && referral != msg.sender && bets[referral] > 0) {
            referral.transfer(_partReferral);
        } else {
            stock = Math.add(stock, _partReferral);
        }
    }


    /**
     * @dev Check the winner
     */
    function isWinner(uint8 required, uint8[5] numbers, uint8[5] randoms) internal pure returns(bool) {
        uint8 count = 0;
        for (uint8 i = 0; i < numbers.length; i++) {
            if (numbers[i] == 0) continue;
            for (uint8 j = 0; j < randoms.length; j++) {
                if (randoms[j] == 0) continue;
                if (randoms[j] == numbers[i]) {
                    count++;
                    delete randoms[j];
                    break;
                }
            }
        }
        return count == required;
    }


    /**
     * @dev Reward the winner
     */
    function rewardTheWinner(uint8 reward) internal {
        uint256 rewardValue = Math.percent(bank, reward);
        require(rewardValue <= getBalance());
        require(rewardValue <= bank);
        bank = Math.sub(bank, rewardValue);
        msg.sender.transfer(rewardValue);
        emit WeHaveAWinner(msg.sender, rewardValue);
    }


    /**
     * @dev Roll the dice for numbers
     */
    function rollOne(address referral, uint8 number)
    external payable isValidBet(rewardOne) bankNotEmpty {
        require(isValidNumber(number));       
        bets[msg.sender]++;

        splitTheBet(referral);

        uint8[5] memory numbers = [number,  0, 0, 0, 0];
        uint8[5] memory randoms = [getRN(), 0, 0, 0, 0];

        emit UserBet(msg.sender, number, 0, 0, 0, 0);
        emit DiceRoll(randoms[0], 0, 0, 0, 0);
        if (isWinner(1, numbers, randoms)) {
            rewardTheWinner(rewardOne);
        } else {
            emit Loser(msg.sender);
        }
    }


    function rollTwo(address referral, uint8 number1, uint8 number2)
    external payable isValidBet(rewardTwo) bankNotEmpty {
        require(isValidNumber(number1) && isValidNumber(number2));
        bets[msg.sender]++;

        splitTheBet(referral);

        uint8[5] memory numbers = [number1, number2, 0, 0, 0];
        uint8[5] memory randoms = [getRN(), getRN(), 0, 0, 0];

        emit UserBet(msg.sender, number1, number2, 0, 0, 0);
        emit DiceRoll(randoms[0], randoms[1], 0, 0, 0);
        if (isWinner(2, numbers, randoms)) {
            rewardTheWinner(rewardTwo);
        } else {
            emit Loser(msg.sender);
        }
    }


    function rollThree(address referral, uint8 number1, uint8 number2, uint8 number3)
    external payable isValidBet(rewardThree) bankNotEmpty {
        require(isValidNumber(number1) && isValidNumber(number2) && isValidNumber(number3));
        bets[msg.sender]++;

        splitTheBet(referral);

        uint8[5] memory numbers = [number1, number2, number3, 0, 0];
        uint8[5] memory randoms = [getRN(), getRN(), getRN(), 0, 0];

        emit UserBet(msg.sender, number1, number2, number3, 0, 0);
        emit DiceRoll(randoms[0], randoms[1], randoms[2], 0, 0);
        if (isWinner(3, numbers, randoms)) {
            rewardTheWinner(rewardThree);
        } else {
            emit Loser(msg.sender);
        }
    }


    function rollFour(address referral, uint8 number1, uint8 number2, uint8 number3, uint8 number4)
    external payable isValidBet(rewardFour) bankNotEmpty {
        require(isValidNumber(number1) && isValidNumber(number2) && isValidNumber(number3) && isValidNumber(number4));
        bets[msg.sender]++;

        splitTheBet(referral);

        uint8[5] memory numbers = [number1, number2, number3, number4, 0];
        uint8[5] memory randoms = [getRN(), getRN(), getRN(), getRN(), 0];

        emit UserBet(msg.sender, number1, number2, number3, number4, 0);
        emit DiceRoll(randoms[0], randoms[1], randoms[2], randoms[3], 0);
        if (isWinner(4, numbers, randoms)) {
            rewardTheWinner(rewardFour);
        } else {
            emit Loser(msg.sender);
        }
    }


    function rollFive(address referral, uint8 number1, uint8 number2, uint8 number3, uint8 number4, uint8 number5)
    external payable isValidBet(jackPot) bankNotEmpty {
        require(isValidNumber(number1) && isValidNumber(number2) && isValidNumber(number3) && isValidNumber(number4) && isValidNumber(number5));
        bets[msg.sender]++;

        splitTheBet(referral);

        uint8[5] memory numbers = [number1, number2, number3, number4, number5];
        uint8[5] memory randoms = [getRN(), getRN(), getRN(), getRN(), getRN()];

        emit UserBet(msg.sender, number1, number2, number3, number4, number5);
        emit DiceRoll(randoms[0], randoms[1], randoms[2], randoms[3], randoms[4]);
        if (isWinner(5, numbers, randoms)) {
            rewardTheWinner(jackPot);
            emit OMGItIsJackPot(msg.sender);
        } else {
            emit Loser(msg.sender);
        }
    }
}