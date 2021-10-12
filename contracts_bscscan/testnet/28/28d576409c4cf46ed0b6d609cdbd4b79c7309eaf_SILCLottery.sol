/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

pragma solidity ^0.4.8;


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
pragma solidity ^0.4.0;

// import './Ownable.sol';
/*
 * Contactable token
 * Basic version of a contactable contract
 */
contract Contactable is Ownable{

     string public contactInformation;

     function setContactInformation(string info) onlyOwner{
         contactInformation = info;
     }

}
pragma solidity ^0.4.8;


// import "../ownership/Ownable.sol";


/*
 * Killable
 * Base contract that can be killed by owner. All funds in contract will be sent to the owner.
 */
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}
pragma solidity ^0.4.8;


/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

pragma solidity ^0.4.8;


/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}



pragma solidity ^0.4.8;

// import 'zeppelin/ownership/Ownable.sol';        // set specific function for owner only
// import 'zeppelin/ownership/Contactable.sol';    // contract has contact info
// import 'zeppelin/lifecycle/Killable.sol';       // contract may be killed
// import 'zeppelin/SafeMath.sol';                 // safe mathematics functions
// import 'zeppelin/token/ERC20.sol';              // ERC20 interface





/// @title General Token Lottery
/// @author Riaan F Venter~ RFVenter~ <[email protected]>
contract SILCLottery is Ownable, SafeMath, Killable {

    event BetPlaced(address _player, uint8 _number1, uint8 _number2, uint8 _number3, uint8 _number4, uint _value);
    event RollCompleted(uint8 _number1,
                        uint8 _number2, 
                        uint8 _number3, 
                        uint8 _number4, 
                        uint _totalWinnings);
    event PlayerWon(address _player, uint _value);
    event PayoutDone(uint _totalWinnings);

    // represents one bet made by a player
    struct bet {
        address player;             // the player that makes a bet
        uint tokensPlaced;          // the amount of tokens the player placed for the bet
        uint8[4] numbers;           // the selected power numbers that the player selected
        uint ratioIndex;            // the index of the payout ratios list item, relevant for this bet
        uint timestamp;             // timestamp that this bet was made
        uint rollIndex;             // the index of the roll that this bet is for
        uint winAmount;             // in the event of a win this will be the amount
    }

    // the set ratios in case of winning 1, 2, 3 or 4 correct numbers
    struct ratio {
        uint number1;               // multiples of payouts (based on 2 decimals)
        uint number2;               // multiples of payouts (based on 2 decimals)
        uint number3;               // multiples of payouts (based on 2 decimals)
        uint number4;               // multiples of payouts (based on 2 decimals)
        uint timestamp;             // timestamp that these payout ratios where set
    }

    // represents a roll
    struct roll {
        uint8 number1;              // the winning numbers generated based on the random seed
        uint8 number2;              // the winning numbers generated based on the random seed
        uint8 number3;              // the winning numbers generated based on the random seed
        uint8 number4;              // the winning numbers generated based on the random seed
        string seed;                // the seed that was used
        uint totalWinnings;         // the grand total of all winners for this roll
        uint timestamp;             // timestamp that this roll was generated
    }

    bet[] public bets;              // history of all bets done
    ratio[] public ratios;          // history of all set ratios

    bytes32[] public hashedSeeds;   // list of hashes to prove that the seeds are pre-generated

    roll[] public rolls;            // history of all rolls
    roll public lastRoll;
    uint public nextRollIndex;      // the index for the first bet for the next roll
    uint public nextPayoutIndex;    // index of the next payout (for winners)
    bool public payoutPending;

    uint public minimumBet;         // the minimum bet allowed
    uint public maximumBet;         // the maximum bet allowed
    address public tokenAddress;    // address of the token being used for this lottery
    ERC20 private token;

    string public codeAuthor = "Riaan Francois Venter <[email protected]>"; 

    /// @notice the init function that is run automatically when contract is created
    function HMLottery() {
        owner = msg.sender;         // set the owner of this contract to the creator of the contract
        minimumBet = 100;           // set the minimum bet
        maximumBet = 500;           // set the maximum bet
        ratio memory nextRatio;     // create ratios for specific payouts based on how many balls won

        // at these payout ratios the game pays out 50% tokens taken in (based on probability)
        nextRatio.number1 = 3200;
        nextRatio.number2 = 819200;
        nextRatio.number3 = 209715200;
        nextRatio.number4 = 53687091200;  
        nextRatio.timestamp = now;  // timestamp
        ratios.push(nextRatio);     // set the payout ratio

        nextRollIndex = 0;          // initialize the list index
        nextPayoutIndex = 0;        // initialize the list index

        // put one hash in for the next draw
        hashedSeeds.push(0xd126d9ba76874eeae0e9706d1303194952377059e8d72424b4da996c0d4e0c7f);

        payoutPending = false;      // gate for controlling if some functions may run or not
    }

    /// @notice sets the ratios that will be used to multiply winnings based on correct numbers
    /// @notice !!!(based on 2 decimal precision [to select a multiple of 23.5 specify 2350])
    /// @param _number1 The number to multiply with in case the player has one lucky number (div 100)
    /// @param _number2 The number to multiply with in case the player has two lucky numbers (div 100)
    /// @param _number3 The number to multiply with in case the player has three lucky numbers (div 100)
    /// @param _number4 The number to multiply with in case the player has four lucky numbers (div 100)
    function setPayoutRatios(uint _number1, uint _number2, uint _number3, uint _number4) external onlyOwner {
        ratio memory nextRatio;

        nextRatio.number1 = _number1;
        nextRatio.number2 = _number2;
        nextRatio.number3 = _number3;
        nextRatio.number4 = _number4;
        nextRatio.timestamp = now;
        ratios.push(nextRatio);
    }

    /// @notice sets the minimum bet allowed
    /// @param _minimumBet minimum bet allowed
    function setMinimumBet(uint _minimumBet) external onlyOwner {
        minimumBet = _minimumBet;
    }

    /// @notice sets the maximum bet allowed
    /// @param _maximumBet maximum bet allowed
    function setMaximumBet(uint _maximumBet) external onlyOwner {
        maximumBet = _maximumBet;
    }

    /// @notice sets the token that is to be used for this Lottery
    /// @param _token The address of the ERC20 token
    function setToken(address _token) external onlyOwner returns (bool) {     
        tokenAddress = _token;
        token = ERC20(tokenAddress);
    }

    /// @notice Starts a random number generator based on the valid seed. When calling this function the next seed's hash must also be specified. This is to ensure that seed is predetermined which means its impossible for the owner of the contract to cheat. Each existing bet is checked to see if it has won and if so how much. RollCompleted event is fired with the lucky numbers and the total winning for this roll.
    /// @param _seed The string that is to be used as the seed for the random generator
    /// @param _nextHashedSeed The hash of the next roll's seed
    /// @return whether the transfer was successful or not
    function rollNumbers(string _seed, bytes32 _nextHashedSeed) external onlyOwner returns (bool) {
        // check if the last payout was done
        if (payoutPending) return false;

        // make sure the given seed is correct for the next seedHash
        if (hashedSeeds[hashedSeeds.length-1] != sha3(_seed)) return false;

        // create the random number based on seed
        bytes20 combinedRand = ripemd160(_seed);
       
        uint8[4] memory numbers; 
        uint8 i = 0;
        while (i < 4) {
            numbers[i] = uint8(combinedRand);      // same as '= combinedRand % 256;'
            combinedRand >>= 8;                    // same as combinedRand /= 256;
            for (uint8 j = 0; j < i; j++) {       // is newly picked val in a set?
                if (numbers[j] == numbers[i]) {    // if true then break to while loop and look for another Num[i]
                    i--;
                    break;
                }
            }
            i++;
        }
        // check all bets to see who won and how much, tally up the grand total
        uint totalWinnings = 0;

        for (uint b = nextRollIndex; b < bets.length; b++) {
            uint8 correctNumbers = 0;
            for (uint8 k = 0; k < 4; k++) {
                for (uint8 l = 0; l < 4; l++) {
                    if (bets[b].numbers[k] == numbers[l]) correctNumbers++;
                }
            }
            // very important to divide by 100 because the payout ratios have 2 decimal precision
            uint multiple;
            if (correctNumbers > 0) {
                if (correctNumbers == 1) {
                    multiple = ratios[bets[b].ratioIndex].number1 / 100;
                }
                else if (correctNumbers == 2) {
                    multiple = ratios[bets[b].ratioIndex].number2 / 100;
                }
                else if (correctNumbers == 3) {
                    multiple = ratios[bets[b].ratioIndex].number3 / 100;
                }
                else if (correctNumbers == 4) {
                    multiple = ratios[bets[b].ratioIndex].number4 / 100;
                }
                bets[b].winAmount = bets[b].tokensPlaced * multiple;          
                PlayerWon(bets[b].player, bets[b].winAmount);
                totalWinnings += bets[b].winAmount;
            }
            else bets[b].winAmount = 0;
        }

        // add a new roll with the numbers
        roll memory newRoll;
        newRoll.number1 = numbers[0];
        newRoll.number2 = numbers[1];
        newRoll.number3 = numbers[2];
        newRoll.number4 = numbers[3];
        newRoll.seed = _seed;
        newRoll.totalWinnings = totalWinnings;
        newRoll.timestamp = now;
        rolls.push(newRoll);
        lastRoll = newRoll;

        // move the nextRollIndex to end of the bets list
        nextRollIndex = bets.length;

        RollCompleted(numbers[0], numbers[1], numbers[2], numbers[3], totalWinnings);

        hashedSeeds.push(_nextHashedSeed);  // add the next Hashed Seed for the next draw
        payoutPending = true;
        payOut();
        return true;
    }

    /// @notice Pays each lucky bet and sets the game ready for the next roll. There must be enough tokens allocated to this contract so that it has sufficient funds to pay out the winners. PayoutDone event is fired containing the total payout
    /// @return whether the transfer was successful or not
    function payOut() onlyOwner returns (bool) {
        // check if the last payout was done
        if (!payoutPending) return false;

        // check if there is enough tokens in reserve to pay these players back
        if (token.balanceOf(this) < lastRoll.totalWinnings) return false;
   
        uint totalPayout;

        // payout each winner
        for (var p = nextPayoutIndex; p < nextRollIndex; p++) {
            if (bets[p].winAmount > 0) {
                token.transfer(bets[p].player, bets[p].winAmount);
                nextPayoutIndex++;                                  // move the nextPayoutIndex on
                totalPayout += bets[p].winAmount;
            }
        }
        payoutPending = false;
        PayoutDone(totalPayout);
        return true;
    }

    /// @notice Drains the remaining tokens back to the owner of the lottery
    /// @return whether the transfer was successful or not
    function drain() external onlyOwner returns (bool) {
        return token.transfer(owner, token.balanceOf(this));    
    }

    //// PUBLIC interface

    /// @notice this is to place a new bet. Before a bet can be places the user must ensure that they have called the approve function on the token. This will enable this lottery contract to deduct (transfer) the specified tokens for the next bet.
    /// @param _number1 1st number for the bet
    /// @param _number2 2nd number for the bet
    /// @param _number3 3rd number for the bet
    /// @param _number4 4th number for the bet
    /// @param _value the number of tokens to place for this bet
    /// @return whether the transfer was successful or not
    function placeBet(uint8 _number1, uint8 _number2, uint8 _number3, uint8 _number4, uint _value) external returns (bool) {

        // check that the bet is within the min and max bet limits
        if ((_value < minimumBet) || (_value > maximumBet)) return false;

        // make sure that make sure that all numbers are different from each other!
        if (_number1 == _number2 || _number1 == _number3 || _number1 == _number4 ||
            _number2 == _number3 || _number2 == _number4 ||
            _number3 == _number4) return false;

        // transfer the required tokens to this contract
        if (!token.transferFrom(msg.sender, this, _value)) return false;

        // tokens transfered so can now create a new bet
        bet memory newBet;
        newBet.player = msg.sender;
        newBet.tokensPlaced = _value;
        newBet.numbers = [_number1, _number2, _number3, _number4];
        newBet.ratioIndex = ratios.length - 1;
        newBet.timestamp = now;

        // place it into the bets list
        bets.push(newBet);

        BetPlaced(msg.sender, _number1, _number2, _number3, _number4, _value);
        return true;
    }

    ///////// test functions, there are used for the unit testing and are not meant for production
    
//     function testBetsLength() constant returns (uint) {
//         return bets.length;
//     }

//     function testLastRoll() constant returns (uint8 number1,
//                                               uint8 number2,
//                                               uint8 number3,
//                                               uint8 number4,
//                                               uint totalWinnings) {
//         return (lastRoll.number1, lastRoll.number2, lastRoll.number3, lastRoll.number4, lastRoll.totalWinnings);
//     }

//     function testReturnBet(uint index) constant returns (address player, 
//                                                      uint tokensPlaced, 
//                                                      uint8 number1,
//                                                      uint8 number2,
//                                                      uint8 number3,
//                                                      uint8 number4,
//                                                      uint ratioIndex,
//                                                      uint timestamp,
//                                                      uint rollIndex,
//                                                      uint winAmount) {
//         bet outBet = bets[index];
//         return (outBet.player, outBet.tokensPlaced, outBet.numbers[0], outBet.numbers[1], outBet.numbers[2], outBet.numbers[3], outBet.ratioIndex, outBet.timestamp, outBet.rollIndex, outBet.winAmount);
//     }
// // 
//     // since the real rollNumbers function uses random generation its difficult to test, this function simulates the real function with the same code but injects selected winning numbers
//     function testRollNumbers(uint8 number1, uint8 number2, uint8 number3, uint8 number4) external onlyOwner returns (bool) {
       
//         uint8[4] memory numbers = [number1, number2, number3, number4]; 

//         // check all bets to see who won and how much, tally up the grand total
//         uint totalWinnings = 0;

//         for (uint b = nextRollIndex; b < bets.length; b++) {
//             uint8 correctNumbers = 0;
//             for (uint8 k = 0; k < 4; k++) {
//                 for (uint8 l = 0; l < 4; l++) {
//                     if (bets[b].numbers[k] == numbers[l]) correctNumbers++;
//                 }
//             }
//             uint multiple;
//             if (correctNumbers > 0) {
//                 if (correctNumbers == 1) {
//                     multiple = ratios[bets[b].ratioIndex].number1 / 100;
//                 }
//                 else if (correctNumbers == 2) {
//                     multiple = ratios[bets[b].ratioIndex].number2 / 100;
//                 }
//                 else if (correctNumbers == 3) {
//                     multiple = ratios[bets[b].ratioIndex].number3 / 100;
//                 }
//                 else if (correctNumbers == 4) {
//                     multiple = ratios[bets[b].ratioIndex].number4 / 100;
//                 }
//                 bets[b].winAmount = bets[b].tokensPlaced * multiple;          
//                 PlayerWon(bets[b].player, bets[b].winAmount);
//                 totalWinnings += bets[b].winAmount;
//             }
//             else bets[b].winAmount = 0;
//         }



//         // add a new roll with the numbers
//         roll memory newRoll = roll(numbers[0], numbers[1], numbers[2], numbers[3], "rstrst", totalWinnings, now);
//         rolls.push(newRoll);
//         lastRoll = newRoll;

//         // move the nextRollIndex to end of the bets list
//         nextRollIndex = bets.length;

//         RollCompleted(numbers[0], numbers[1], numbers[2], numbers[3], totalWinnings);

//         hashedSeeds.push(0xd126d9ba76874eeae0e9706d1303194952377059e8d72424b4da996c0d4e0c7f);  // add the next Hashed Seed for the next draw
//         payoutPending = true;
//         return true;
//     }
    

}