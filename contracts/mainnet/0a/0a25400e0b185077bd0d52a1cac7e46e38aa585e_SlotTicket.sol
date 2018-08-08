pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
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
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of. 
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardMintableToken is ERC20, BasicToken, Ownable {

    mapping (address => mapping (address => uint256)) allowed;
  
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifing the amount of tokens still avaible for the spender.
    */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
  
   /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount); // so it is displayed properly on EtherScan
        return true;
    }
    
    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}

/**
 * @title Slot Ticket
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract SlotTicket is StandardMintableToken {

    string public name = "Slot Ticket";
    uint8 public decimals = 0;
    string public symbol = "TICKET";
    string public version = "0.6";

    function destroy() onlyOwner {
        // Transfer Eth to owner and terminate contract
        selfdestruct(owner);
    }
}

/**  
 *  @title Slot
 *  @dev every participant has an account index, the winners are picked from here
 *  all winners are picked in order from the single random int 
 *  needs to be cleared after every game 
 */
     
contract Slot is Ownable {
    using SafeMath for uint256;

    uint8   constant public SIZE =           100;        // size of the lottery
    uint32  constant public JACKPOT_CHANCE = 1000000;    // one in a million
    uint32  constant public INACTIVITY =     160000;     // blocks after which refunds can be claimed
    uint256 constant public PRICE =          100 finney;
    uint256 constant public JACK_DIST =      249 finney;
    uint256 constant public DIV_DIST =       249 finney;
    uint256 constant public GAS_REFUND =     2 finney;

    /* 
    *  every participant has an account index, the winners are picked from here
    *  all winners are picked in order from the single random int 
    *  needs to be cleared after every game
    */
    mapping (uint => mapping (uint => address)) public participants; // game number => counter => address
    SlotTicket public ticket; // this is a receipt for the ticket, it wont affect the prize distribution
    uint256 public jackpotAmount;
    uint256 public gameNumber;
    uint256 public gameStartedAt;
    address public fund; // address to send dividends
    uint256[8] public prizes = [4 ether, 
                                2 ether,
                                1 ether, 
                                500 finney, 
                                500 finney, 
                                500 finney, 
                                500 finney, 
                                500 finney];
    uint256 counter;

    event ParticipantAdded(address indexed _participant, uint256 indexed _game, uint256 indexed _number);
    event PrizeAwarded(uint256 indexed _game , address indexed _winner, uint256 indexed _amount);
    event JackpotAwarded(uint256 indexed _game, address indexed _winner, uint256 indexed _amount);
    event GameRefunded(uint256 _game);

    function Slot(address _fundAddress) payable { // address _ticketAddress
        // ticket = SlotTicket(_ticketAddress); // still need to change owner
        ticket = new SlotTicket();
        fund = _fundAddress;

        jackpotAmount = msg.value;
        gameNumber = 0;
        counter = 0;
        gameStartedAt = block.number;
    }

    function() payable {
        // fallback function to buy tickets
        buyTicketsFor(msg.sender);
    }

    function buyTicketsFor(address _beneficiary) public payable {
        require(_beneficiary != 0x0);
        require(msg.value >= PRICE);

        // calculate number of tickets, issue tokens and add participant
        // every (PRICE) buys a ticket, the rest is returned
        uint256 change = msg.value%PRICE;
        uint256 numberOfTickets = msg.value.sub(change).div(PRICE);
        ticket.mint(_beneficiary, numberOfTickets);
        addParticipant(_beneficiary, numberOfTickets);

        // Return change to msg.sender
        msg.sender.transfer(change);
    }

    /* private functions */

    function addParticipant(address _participant, uint256 _numberOfTickets) private {
        // if number of tickets exceeds the size of the game, tickets are added to next game

        for (uint256 i = 0; i < _numberOfTickets; i++) {
            // using gameNumber instead of counter/SIZE since games can be cancelled
            participants[gameNumber][counter%SIZE] = _participant; 
            ParticipantAdded(_participant, gameNumber, counter%SIZE);

            // msg.sender triggers the drawing of lots
            if (++counter%SIZE == 0) {
                awardPrizes();
                // Split the rest, increase game number
                distributeRemaining();
                increaseGame();
            }
            // loop continues if there are more tickets
        }
    }
    
    function awardPrizes() private {
        // get the winning number, no need to hash, since it is a deterministical function anyway
        uint256 winnerIndex = uint256(block.blockhash(block.number-1))%SIZE;

        // get jackpot winner, hash result of last two digit number (index) with 4 preceding zeroes will win
        uint256 jackpotNumber = uint256(block.blockhash(block.number-1))%JACKPOT_CHANCE;
        if (winnerIndex == jackpotNumber) {
            distributeJackpot(winnerIndex);
        }

        // loop throught the prizes 
        for (uint8 i = 0; i < prizes.length; i++) {
            // GAS: 21000 Paid for every transaction. (prizes.length)
            participants[gameNumber][winnerIndex%SIZE].transfer(prizes[i]); // msg.sender pays the gas, he&#39;s refunded later, % to wrap around
            PrizeAwarded(gameNumber, participants[gameNumber][winnerIndex%SIZE], prizes[i]);

            // increment index to the next winner to receive the next prize
            winnerIndex++;
        }
    }

    function distributeJackpot(uint256 _winnerIndex) private {
        uint256 amount = jackpotAmount;
        jackpotAmount = 0; // later on in the code sequence funds will be added

        participants[gameNumber][_winnerIndex].transfer(amount);
        JackpotAwarded(gameNumber,  participants[gameNumber][_winnerIndex], amount);
    }

    function distributeRemaining() private {
        // GAS: 21000 Paid for every transaction. (3)
        jackpotAmount = jackpotAmount.add(JACK_DIST);   // add to jackpot
        fund.transfer(DIV_DIST);                        // *cash register sound* dividends are paid to SLOT token owners
        msg.sender.transfer(GAS_REFUND);                // repay gas to msg.sender
    }

    function increaseGame() private {
        gameNumber++;
        gameStartedAt = block.number;
    }

    // public functions

    function spotsLeft() public constant returns (uint8 spots) {
        return SIZE - uint8(counter%SIZE);
    }

    function refundGameAfterLongInactivity() public {
        require(block.number.sub(gameStartedAt) >= INACTIVITY);
        require(counter%SIZE != 0); // nothing to refund
        // refunds for everybody can be requested after the game has gone (INACTIVITY) blocks without a conclusion
        
        // Checks-Effects-Interactions pattern to avoid re-entrancy
        uint256 _size = counter%SIZE; // not counter.size, but modulus of SIZE
        counter -= _size;

        for (uint8 i = 0; i < _size; i++) {
            // GAS: default 21000 paid for every transaction.
            participants[gameNumber][i].transfer(PRICE);
        }

        GameRefunded(gameNumber);
        increaseGame();
    }

    function destroy() public onlyOwner {
        require(jackpotAmount < 25 ether);

        // Transfer Ether funds to owner and terminate contract
        // It would be unfair to allow ourselves to destroy a contract with more than 25 ether and claim the jackpot,
        // lower than that we would consider it still a beta (any Ether would be transfered to the newer contract)

        ticket.destroy();
        selfdestruct(owner);
    }
    
    function changeTicketOwner(address _newOwner) public onlyOwner {
        // in case of new contract, old token can still be used
        // the token contract owner is the slot contract itself
        ticket.transferOwnership(_newOwner);
    }
    
    function changeFund(address _newFund) public onlyOwner {
        fund = _newFund;
    }
    
    function changeTicket(address _newTicket) public onlyOwner {
        ticket = SlotTicket(_newTicket); // still need to change owner to work
    }
}