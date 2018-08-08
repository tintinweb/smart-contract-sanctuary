pragma solidity ^0.4.24;

/*
* Zlots.
*
* Written August 2018 by the Zethr team for zethr.io.
*
* Initial code framework written by Norsefire.
*
* Rolling Odds:
*   55.1%  - Lose
*   26.24% - 1.5x Multiplier - Two unmatched pyramids
*   12.24% - 2.5x Multiplier - Two matching pyramids
*    4.08% - 1x   Multiplier - Three unmatched pyramids
*    2.04% - 8x   Multiplier - Three matching pyramids
*    0.29% - 25x  Multiplier - Z T H Jackpot
*
*/

contract ZTHReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ZTHInterface {
    function transfer(address _to, uint _value) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
}

contract Zlots is ZTHReceivingContract {
    using SafeMath for uint;

    address private owner;
    address private bankroll;

    // How many bets have been made?
    uint  totalSpins;
    uint  totalZTHWagered;

    // How many ZTH are in the contract?
    uint contractBalance;

    // Is betting allowed? (Administrative function, in the event of unforeseen bugs)
    bool    public gameActive;

    address private ZTHTKNADDR;
    address private ZTHBANKROLL;
    ZTHInterface private     ZTHTKN;

    mapping (uint => bool) validTokenBet;

    // Might as well notify everyone when the house takes its cut out.
    event HouseRetrievedTake(
        uint timeTaken,
        uint tokensWithdrawn
    );

    // Fire an event whenever someone places a bet.
    event TokensWagered(
        address _wagerer,
        uint _wagered
    );

    event LogResult(
        address _wagerer,
        uint _result,
        uint _profit,
        uint _wagered,
        bool _win
    );

    event Loss(
        address _wagerer
    );

    event Jackpot(
        address _wagerer
    );

    event EightXMultiplier(
        address _wagerer
    );

    event ReturnBet(
        address _wagerer
    );

    event TwoAndAHalfXMultiplier(
        address _wagerer
    );

    event OneAndAHalfXMultiplier(
        address _wagerer
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBankroll {
        require(msg.sender == bankroll);
        _;
    }

    modifier onlyOwnerOrBankroll {
        require(msg.sender == owner || msg.sender == bankroll);
        _;
    }

    // Requires game to be currently active
    modifier gameIsActive {
        require(gameActive == true);
        _;
    }

    constructor(address ZethrAddress, address BankrollAddress) public {

        // Set Zethr & Bankroll address from constructor params
        ZTHTKNADDR = ZethrAddress;
        ZTHBANKROLL = BankrollAddress;

        // Set starting variables
        owner         = msg.sender;
        bankroll      = ZTHBANKROLL;

        // Approve "infinite" token transfer to the bankroll, as part of Zethr game requirements.
        ZTHTKN = ZTHInterface(ZTHTKNADDR);
        ZTHTKN.approve(ZTHBANKROLL, 2**256 - 1);
        
        // For testing purposes. This is to be deleted on go-live. (see testingSelfDestruct)
        ZTHTKN.approve(owner, 2**256 - 1);

        // To start with, we only allow spins of 5, 10, 25 or 50 ZTH.
        validTokenBet[5e18]  = true;
        validTokenBet[10e18] = true;
        validTokenBet[25e18] = true;
        validTokenBet[50e18] = true;

        gameActive  = true;
    }

    // Zethr dividends gained are accumulated and sent to bankroll manually
    function() public payable {  }

    // If the contract receives tokens, bundle them up in a struct and fire them over to _stakeTokens for validation.
    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes /* _data */) public returns (bool){
        TKN memory          _tkn;
        _tkn.sender       = _from;
        _tkn.value        = _value;
        _spinTokens(_tkn);
        return true;
    }

    struct playerSpin {
        uint200 tokenValue; // Token value in uint
        uint48 blockn;      // Block number 48 bits
    }

    // Mapping because a player can do one spin at a time
    mapping(address => playerSpin) public playerSpins;

    // Execute spin.
    function _spinTokens(TKN _tkn) private {

        require(gameActive);
        require(_zthToken(msg.sender));
        require(validTokenBet[_tkn.value]);
        require(jackpotGuard(_tkn.value));

        require(_tkn.value < ((2 ** 200) - 1));   // Smaller than the storage of 1 uint200;
        require(block.number < ((2 ** 48) - 1));  // Current block number smaller than storage of 1 uint48

        address _customerAddress = _tkn.sender;
        uint    _wagered         = _tkn.value;

        playerSpin memory spin = playerSpins[_tkn.sender];

        contractBalance = contractBalance.add(_wagered);

        // Cannot spin twice in one block
        require(block.number != spin.blockn);

        // If there exists a spin, finish it
        if (spin.blockn != 0) {
          _finishSpin(_tkn.sender);
        }

        // Set struct block number and token value
        spin.blockn = uint48(block.number);
        spin.tokenValue = uint200(_wagered);

        // Store the roll struct - 20k gas.
        playerSpins[_tkn.sender] = spin;

        // Increment total number of spins
        totalSpins += 1;

        // Total wagered
        totalZTHWagered += _wagered;

        emit TokensWagered(_customerAddress, _wagered);

    }

     // Finish the current spin of a player, if they have one
    function finishSpin() public
        gameIsActive
        returns (uint)
    {
      return _finishSpin(msg.sender);
    }

    /*
    * Pay winners, update contract balance, send rewards where applicable.
    */
    function _finishSpin(address target)
        private returns (uint)
    {
        playerSpin memory spin = playerSpins[target];

        require(spin.tokenValue > 0); // No re-entrancy
        require(spin.blockn != block.number);

        uint profit = 0;

        // If the block is more than 255 blocks old, we can&#39;t get the result
        // Also, if the result has already happened, fail as well
        uint result;
        if (block.number - spin.blockn > 255) {
          result = 9999; // Can&#39;t win: default to largest number
        } else {

          // Generate a result - random based ONLY on a past block (future when submitted).
          // Case statement barrier numbers defined by the current payment schema at the top of the contract.
          result = random(10000, spin.blockn, target);
        }

        if (result > 4489) {
          // Player has lost.
          emit Loss(target);
          emit LogResult(target, result, profit, spin.tokenValue, false);
        } else {
            if (result < 29) {
                // Player has won the 25x jackpot
                profit = SafeMath.mul(spin.tokenValue, 25);
                emit Jackpot(target);

            } else {
                if (result < 233) {
                    // Player has won a 8x multiplier
                    profit = SafeMath.mul(spin.tokenValue, 8);
                    emit EightXMultiplier(target);
                } else {

                    if (result < 641) {
                        // Player has won their wager back
                        profit = spin.tokenValue;
                        emit ReturnBet(target);
                    } else {
                        if (result < 1865) {
                            // Player has won a 2.5x multiplier
                            profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 25), 10);
                            emit TwoAndAHalfXMultiplier(target);
                        } else {
                            // Player has won a 1.5x multiplier (result lies between 1865 and 4489
                            profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 15), 10);
                            emit OneAndAHalfXMultiplier(target);
                        }
                    }
                }
            }
            emit LogResult(target, result, profit, spin.tokenValue, true);
            contractBalance = contractBalance.sub(profit);
            ZTHTKN.transfer(target, profit);
        }
        playerSpins[target] = playerSpin(uint200(0), uint48(0));
        return result;
    }

    // This sounds like a draconian function, but it actually just ensures that the contract has enough to pay out
    // a jackpot at the rate you&#39;ve selected (i.e. 1250 ZTH for jackpot on a 50 ZTH roll).
    // We do this by making sure that 25* your wager is no less than 50% of the amount currently held by the contract.
    // If not, you&#39;re going to have to use lower betting amounts, we&#39;re afraid!
    function jackpotGuard(uint _wager)
        public
        view
        returns (bool)
    {
        uint maxProfit = SafeMath.mul(_wager, 25);
        uint halfContractBalance = SafeMath.div(contractBalance, 2);
        return (maxProfit <= halfContractBalance);
    }

    // Returns a random number using a specified block number
    // Always use a FUTURE block number.
    function maxRandom(uint blockn, address entropy) public view returns (uint256 randomNumber) {
    return uint256(keccak256(
        abi.encodePacked(
        blockhash(blockn),
        entropy)
      ));
    }

    // Random helper
    function random(uint256 upper, uint256 blockn, address entropy) internal view returns (uint256 randomNumber) {
    return maxRandom(blockn, entropy) % upper;
    }

    // How many tokens are in the contract overall?
    function balanceOf() public view returns (uint) {
        return contractBalance;
    }

    function addNewBetAmount(uint _tokenAmount)
        public
        onlyOwner
    {
        validTokenBet[_tokenAmount] = true;
    }

    // If, for any reason, betting needs to be paused (very unlikely), this will freeze all bets.
    function pauseGame() public onlyOwner {
        gameActive = false;
    }

    // The converse of the above, resuming betting if a freeze had been put in place.
    function resumeGame() public onlyOwner {
        gameActive = true;
    }

    // Administrative function to change the owner of the contract.
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // Administrative function to change the Zethr bankroll contract, should the need arise.
    function changeBankroll(address _newBankroll) public onlyOwner {
        bankroll = _newBankroll;
    }

    // Any dividends acquired by this contract is automatically triggered.
    function divertDividendsToBankroll()
        public
        onlyOwner
    {
        bankroll.transfer(address(this).balance);
    }

    function testingSelfDestruct()
        public
        onlyOwner
    {
        // Give me back my testing tokens :)
        ZTHTKN.transfer(owner, contractBalance);
        selfdestruct(owner);
    }
    
    // Is the address that the token has come from actually ZTH?
    function _zthToken(address _tokenContract) private view returns (bool) {
       return _tokenContract == ZTHTKNADDR;
    }
}

// And here&#39;s the boring bit.

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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