pragma solidity ^0.4.24;

/*
* Zethell.
*
* Written June 2018 for Zethr (https://www.zethr.io) by Norsefire.
* Special thanks to oguzhanox and Etherguy for assistance with debugging.
*
*/

contract ZTHReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ZTHInterface {
    function transfer(address _to, uint _value) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
}

contract Zethell is ZTHReceivingContract {
    using SafeMath for uint;

    address private owner;
    address private bankroll;

    // How much of the current token balance is reserved as the house take?
    uint    private houseTake;
    
    // How many tokens are currently being played for? (Remember, this is winner takes all)
    uint    public tokensInPlay;
    
    // The token balance of the entire contract.
    uint    public contractBalance;
    
    // Which address is currently winning?
    address public currentWinner;

    // What time did the most recent clock reset happen?
    uint    public gameStarted;
    
    // What time will the game end if the clock isn&#39;t reset?
    uint    public gameEnds;
    
    // Is betting allowed? (Administrative function, in the event of unforeseen bugs)
    bool    public gameActive;

    address private ZTHTKNADDR;
    address private ZTHBANKROLL;
    ZTHInterface private     ZTHTKN;

    mapping (uint => bool) validTokenBet;
    mapping (uint => uint) tokenToTimer;

    // Fire an event whenever the clock runs out and a winner is determined.
    event GameEnded(
        address winner,
        uint tokensWon,
        uint timeOfWin
    );

    // Might as well notify everyone when the house takes its cut out.
    event HouseRetrievedTake(
        uint timeTaken,
        uint tokensWithdrawn
    );

    // Fire an event whenever someone places a bet.
    event TokensWagered(
        address _wagerer,
        uint _wagered,
        uint _newExpiry
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

    constructor(address ZethrAddress, address BankrollAddress) public {

        // Set Zethr & Bankroll address from constructor params
        ZTHTKNADDR = ZethrAddress;
        ZTHBANKROLL = BankrollAddress;

        // Set starting variables
        owner         = msg.sender;
        bankroll      = ZTHBANKROLL;
        currentWinner = ZTHBANKROLL;

        // Approve "infinite" token transfer to the bankroll, as part of Zethr game requirements.
        ZTHTKN = ZTHInterface(ZTHTKNADDR);
        ZTHTKN.approve(ZTHBANKROLL, 2**256 - 1);

        // To start with, we only allow bets of 5, 10, 25 or 50 ZTH.
        validTokenBet[5e18]  = true;
        validTokenBet[10e18] = true;
        validTokenBet[25e18] = true;
        validTokenBet[50e18] = true;

        // Logarithmically decreasing time &#39;bonus&#39; associated with higher amounts of ZTH staked.
        tokenToTimer[5e18]  = 24 hours;
        tokenToTimer[10e18] = 18 hours;
        tokenToTimer[25e18] = 10 hours;
        tokenToTimer[50e18] = 6 hours;
        
        // Set the initial timers to contract genesis.
        gameStarted = now;
        gameEnds    = now;
        gameActive  = true;
    }
    
    // Zethr dividends gained are sent to Bankroll later
    function() public payable {  }

    // If the contract receives tokens, bundle them up in a struct and fire them over to _stakeTokens for validation.
    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes /* _data */) public returns (bool){
        TKN memory          _tkn;
        _tkn.sender       = _from;
        _tkn.value        = _value;
        _stakeTokens(_tkn);
        return true;
    }

    // First, we check to see if the tokens are ZTH tokens. If not, we revert the transaction.
    // Next - if the game has already ended (i.e. your bet was too late and the clock ran out)
    //   the staked tokens from the previous game are transferred to the winner, the timers are
    //   reset, and the game begins anew.
    // If you&#39;re simply resetting the clock, the timers are reset accordingly and you are designated
    //   the current winner. A 1% cut will be taken for the house, and the rest deposited in the prize
    //   pool which everyone will be playing for. No second place prizes here!
    function _stakeTokens(TKN _tkn) private {
   
        require(gameActive); 
        require(_zthToken(msg.sender));
        require(validTokenBet[_tkn.value]);
        
        if (now > gameEnds) { _settleAndRestart(); }

        address _customerAddress = _tkn.sender;
        uint    _wagered         = _tkn.value;

        uint rightNow      = now;
        uint timePurchased = tokenToTimer[_tkn.value];
        uint newGameEnd    = rightNow.add(timePurchased);

        gameStarted   = rightNow;
        gameEnds      = newGameEnd;
        currentWinner = _customerAddress;

        contractBalance = contractBalance.add(_wagered);
        uint houseCut   = _wagered.div(100);
        uint toAdd      = _wagered.sub(houseCut);
        houseTake       = houseTake.add(houseCut);
        tokensInPlay    = tokensInPlay.add(toAdd);

        emit TokensWagered(_customerAddress, _wagered, newGameEnd);

    }

    // In the event of a game restart, subtract the tokens which were being played for from the balance,
    //   transfer them to the winner (if the number of tokens is greater than zero: sly edge case).
    // If there is *somehow* any Ether in the contract - again, please don&#39;t - it is transferred to the
    //   bankroll and reinvested into Zethr at the standard 33% rate.
    function _settleAndRestart() private {
        gameActive      = false;
        uint payment = tokensInPlay/2;
        contractBalance = contractBalance.sub(payment);

        if (tokensInPlay > 0) { ZTHTKN.transfer(currentWinner, payment);
            if (address(this).balance > 0){
                ZTHBANKROLL.transfer(address(this).balance);
            }}

        emit GameEnded(currentWinner, payment, now);

        // Reset values.
        tokensInPlay  = tokensInPlay.sub(payment);
        gameActive    = true;
    }

    // How many tokens are in the contract overall?
    function balanceOf() public view returns (uint) {
        return contractBalance;
    }

    // Administrative function for adding a new token-time pair, should there be demand.
    function addTokenTime(uint _tokenAmount, uint _timeBought) public onlyOwner {
        validTokenBet[_tokenAmount] = true;
        tokenToTimer[_tokenAmount]  = _timeBought;
    }

    // Administrative function to REMOVE a token-time pair, should one fall out of use. 
    function removeTokenTime(uint _tokenAmount) public onlyOwner {
        validTokenBet[_tokenAmount] = false;
        tokenToTimer[_tokenAmount]  = 232 days;
    }

    // Function to pull out the house cut to the bankroll if required (i.e. to seed other games).
    function retrieveHouseTake() public onlyOwnerOrBankroll {
        uint toTake = houseTake;
        houseTake = 0;
        contractBalance = contractBalance.sub(toTake);
        ZTHTKN.transfer(bankroll, toTake);

        emit HouseRetrievedTake(now, toTake);
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