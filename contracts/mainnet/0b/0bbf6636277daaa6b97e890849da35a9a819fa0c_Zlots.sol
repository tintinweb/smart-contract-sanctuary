pragma solidity ^0.4.24;

/*
* Zlots.
*
* Written August 2018 by the Zethr team for zethr.io.
*
* Initial code framework written by Norsefire.
*
* Rolling Odds:
*   52.33%	Lose	
*   35.64%	Two Matching Icons
*       - 5.09% : 2x    Multiplier [Two White Pyramids]
*       - 5.09% : 2.5x  Multiplier [Two Gold  Pyramids]
*       - 5.09% : 2.32x Multiplier [Two &#39;Z&#39; Symbols]
*       - 5.09% : 2.32x Multiplier [Two &#39;T&#39; Symbols]
*       - 5.09% : 2.32x Multiplier [Two &#39;H&#39; Symbols]
*       - 5.09% : 3.5x  Multiplier [Two Green Pyramids]
*       - 5.09% : 3.75x Multiplier [Two Ether Icons]
*   6.79%	One Of Each Pyramid
*       - 1.5x  Multiplier
*   2.94%	One Moon Icon
*       - 12.5x Multiplier
*   1.98%	Three Matching Icons
*       - 0.28% : 20x   Multiplier [Three White Pyramids]
*       - 0.28% : 20x   Multiplier [Three Gold  Pyramids]
*       - 0.28% : 25x   Multiplier [Three &#39;Z&#39; Symbols]
*       - 0.28% : 25x   Multiplier [Three &#39;T&#39; Symbols]
*       - 0.28% : 25x   Multiplier [Three &#39;H&#39; Symbols]
*       - 0.28% : 40x   Multiplier [Three Green Pyramids]
*       - 0.28% : 50x   Multiplier [Three Ether Icons]
*   0.28%	Z T H Prize
*       - 23.2x Multiplier
*   0.03%	Two Moon Icons
*       - 232x  Multiplier
*   0.0001%	Three Moon Grand Jackpot
*       - 500x  Multiplier
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
        uint _category,
        bool _win
    );

    // Result announcement events (to dictate UI output!)
    event Loss(address _wagerer, uint _block);                  // Category 0
    event ThreeMoonJackpot(address _wagerer, uint _block);      // Category 1
    event TwoMoonPrize(address _wagerer, uint _block);          // Category 2
    event ZTHJackpot(address _wagerer, uint _block);            // Category 3
    event ThreeZSymbols(address _wagerer, uint _block);         // Category 4
    event ThreeTSymbols(address _wagerer, uint _block);         // Category 5
    event ThreeHSymbols(address _wagerer, uint _block);         // Category 6
    event ThreeEtherIcons(address _wagerer, uint _block);       // Category 7
    event ThreeGreenPyramids(address _wagerer, uint _block);    // Category 8
    event ThreeGoldPyramids(address _wagerer, uint _block);     // Category 9
    event ThreeWhitePyramids(address _wagerer, uint _block);    // Category 10
    event OneMoonPrize(address _wagerer, uint _block);          // Category 11
    event OneOfEachPyramidPrize(address _wagerer, uint _block); // Category 12
    event TwoZSymbols(address _wagerer, uint _block);           // Category 13
    event TwoTSymbols(address _wagerer, uint _block);           // Category 14
    event TwoHSymbols(address _wagerer, uint _block);           // Category 15
    event TwoEtherIcons(address _wagerer, uint _block);         // Category 16
    event TwoGreenPyramids(address _wagerer, uint _block);      // Category 17
    event TwoGoldPyramids(address _wagerer, uint _block);       // Category 18
    event TwoWhitePyramids(address _wagerer, uint _block);      // Category 19
    
    event SpinConcluded(address _wagerer, uint _block);         // Debug event

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

    // If the contract receives tokens, bundle them up in a struct and fire them over to _spinTokens for validation.
    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes /* _data */) public returns (bool){
        if (_from == bankroll) {
          // Update the contract balance
          contractBalance = contractBalance.add(_value);    
          return true;
        } else {
            TKN memory          _tkn;
            _tkn.sender       = _from;
            _tkn.value        = _value;
            _spinTokens(_tkn);
            return true;
        }
    }

    struct playerSpin {
        uint200 tokenValue; // Token value in uint
        uint56 blockn;      // Block number 48 bits
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
        require(block.number < ((2 ** 56) - 1));  // Current block number smaller than storage of 1 uint56

        address _customerAddress = _tkn.sender;
        uint    _wagered         = _tkn.value;

        playerSpin memory spin = playerSpins[_tkn.sender];

        //contractBalance = contractBalance.add(_wagered);

        // Cannot spin twice in one block
        require(block.number != spin.blockn);

        // If there exists a spin, finish it
        if (spin.blockn != 0) {
          _finishSpin(_tkn.sender);
        }

        // Set struct block number and token value
        spin.blockn = uint56(block.number);
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
        uint category = 0;

        // If the block is more than 255 blocks old, we can&#39;t get the result
        // Also, if the result has already happened, fail as well
        uint result;
        if (block.number - spin.blockn > 255) {
          result = 999999; // Can&#39;t win: default to largest number
        } else {

          // Generate a result - random based ONLY on a past block (future when submitted).
          // Case statement barrier numbers defined by the current payment schema at the top of the contract.
          result = random(1000000, spin.blockn, target);
        }

        if (result > 476661) {
          // Player has lost.
          contractBalance = contractBalance.add(spin.tokenValue);
          emit Loss(target, spin.blockn);
          emit LogResult(target, result, profit, spin.tokenValue, category, false);
        } else {
            if (result < 1) {
                // Player has won the three-moon mega jackpot!
                profit = SafeMath.mul(spin.tokenValue, 500);
                category = 1;
                emit ThreeMoonJackpot(target, spin.blockn);
            } else 
                if (result < 298) {
                    // Player has won a two-moon prize!
                    profit = SafeMath.mul(spin.tokenValue, 232);
                    category = 2;
                    emit TwoMoonPrize(target, spin.blockn);
            } else 
                if (result < 3127) {
                    // Player has won the Z T H jackpot!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232), 10);
                    category = 3;
                    emit ZTHJackpot(target, spin.blockn);
                    
            } else 
                if (result < 5956) {
                    // Player has won a three Z symbol prize
                    profit = SafeMath.mul(spin.tokenValue, 25);
                    category = 4;
                    emit ThreeZSymbols(target, spin.blockn);
            } else 
                if (result < 8785) {
                    // Player has won a three T symbol prize
                    profit = SafeMath.mul(spin.tokenValue, 25);
                    category = 5;
                    emit ThreeTSymbols(target, spin.blockn);
            } else 
                if (result < 11614) {
                    // Player has won a three H symbol prize
                    profit = SafeMath.mul(spin.tokenValue, 25);
                    category = 6;
                    emit ThreeHSymbols(target, spin.blockn);
            } else 
                if (result < 14443) {
                    // Player has won a three Ether icon prize
                    profit = SafeMath.mul(spin.tokenValue, 50);
                    category = 7;
                    emit ThreeEtherIcons(target, spin.blockn);
            } else 
                if (result < 17272) {
                    // Player has won a three green pyramid prize
                    profit = SafeMath.mul(spin.tokenValue, 40);
                    category = 8;
                    emit ThreeGreenPyramids(target, spin.blockn);
            } else 
                if (result < 20101) {
                    // Player has won a three gold pyramid prize
                    profit = SafeMath.mul(spin.tokenValue, 20);
                    category = 9;
                    emit ThreeGoldPyramids(target, spin.blockn);
            } else 
                if (result < 22929) {
                    // Player has won a three white pyramid prize
                    profit = SafeMath.mul(spin.tokenValue, 20);
                    category = 10;
                    emit ThreeWhitePyramids(target, spin.blockn);
            } else 
                if (result < 52332) {
                    // Player has won a one moon prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 125),10);
                    category = 11;
                    emit OneMoonPrize(target, spin.blockn);
            } else 
                if (result < 120225) {
                    // Player has won a each-coloured-pyramid prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 15),10);
                    category = 12;
                    emit OneOfEachPyramidPrize(target, spin.blockn);
            } else 
                if (result < 171146) {
                    // Player has won a two Z symbol prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232),100);
                    category = 13;
                    emit TwoZSymbols(target, spin.blockn);
            } else 
                if (result < 222067) {
                    // Player has won a two T symbol prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232),100);
                    category = 14;
                    emit TwoTSymbols(target, spin.blockn);
            } else 
                if (result < 272988) {
                    // Player has won a two H symbol prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232),100);
                    category = 15;
                    emit TwoHSymbols(target, spin.blockn);
            } else 
                if (result < 323909) {
                    // Player has won a two Ether icon prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 375),100);
                    category = 16;
                    emit TwoEtherIcons(target, spin.blockn);
            } else 
                if (result < 374830) {
                    // Player has won a two green pyramid prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 35),10);
                    category = 17;
                    emit TwoGreenPyramids(target, spin.blockn);
            } else 
                if (result < 425751) {
                    // Player has won a two gold pyramid prize!
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 225),100);
                    category = 18;
                    emit TwoGoldPyramids(target, spin.blockn);
            } else {
                    // Player has won a two white pyramid prize!
                    profit = SafeMath.mul(spin.tokenValue, 2);
                    category = 19;
                    emit TwoWhitePyramids(target, spin.blockn);
            }

            emit LogResult(target, result, profit, spin.tokenValue, category, true);
            contractBalance = contractBalance.sub(profit);
            ZTHTKN.transfer(target, profit);
          }
            
        //Reset playerSpin to default values.
        playerSpins[target] = playerSpin(uint200(0), uint56(0));
        emit SpinConcluded(target, spin.blockn);
        return result;
    }   

    // This sounds like a draconian function, but it actually just ensures that the contract has enough to pay out
    // a jackpot at the rate you&#39;ve selected (i.e. 5,000 ZTH for three-moon jackpot on a 10 ZTH roll).
    // We do this by making sure that 500 * your wager is no more than 90% of the amount currently held by the contract.
    // If not, you&#39;re going to have to use lower betting amounts, we&#39;re afraid!
    function jackpotGuard(uint _wager)
        private
        view
        returns (bool)
    {
        uint maxProfit = SafeMath.mul(_wager, 500);
        uint ninetyContractBalance = SafeMath.mul(SafeMath.div(contractBalance, 10), 9);
        return (maxProfit <= ninetyContractBalance);
    }

    // Returns a random number using a specified block number
    // Always use a FUTURE block number.
    function maxRandom(uint blockn, address entropy) private view returns (uint256 randomNumber) {
    return uint256(keccak256(
        abi.encodePacked(
        address(this),
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

    function divertDividendsToBankroll()
        public
        onlyOwner
    {
        bankroll.transfer(address(this).balance);
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