pragma solidity ^0.4.20;

/*

author : RNDM (Discord RNDM#3033)
Write me if you need coding service
My Ethereum address : 0x13373FEdb7f8dF156E5718303897Fae2d363Cc96

Description tl;dr :
Simple trustless lottery with entries
After the contract reaches a certain amount of ethereum or when the owner calls "payWinnerManually()"
a winner gets calculated/drawed and paid out (10% fee for token giveaways).

*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = 0xc42559F88481e1Df90f64e5E9f7d7C6A34da5691;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract Lottery is Ownable {

    // The tokens can never be stolen
    modifier secCheck(address aContract) {
        require(aContract != address(contractCall));
        _;
    }

    /**
    * Events
    */

    event BoughtTicket(uint256 amount, address customer, uint yourEntry);
    event WinnerPaid(uint256 amount, address winner);


    /**
    * Data
    */

    _Contract contractCall;  // a reference to the contract
    address[] public entries; // array with entries
    uint256 entryCounter; // counter for the entries
    uint256 public automaticThreshold; // automatic Threshold to close the lottery and pay the winner
    uint256 public ticketPrice = 10 finney; // the price per lottery ticket (0.01 eth)
    




    constructor() public {
        contractCall = _Contract(0x05215FCE25902366480696F38C3093e31DBCE69A);
        automaticThreshold = 56; // 56 tickets 
        ticketPrice = 10 finney; // 10finney = 0.01 eth
        entryCounter = 0;
    }

    // If you send money directly to the contract it gets treated like a donation
    function() payable public {
    }


    function buyTickets() payable public {
        //You have to send at least ticketPrice to get one entry
        require(msg.value >= ticketPrice);

        address customerAddress = msg.sender;
        //Use deposit to purchase _Contract tokens
        contractCall.buy.value(msg.value)(customerAddress);
        // add customer to the entry list
        if (entryCounter == (entries.length)) {
            entries.push(customerAddress);
            }
        else {
            entries[entryCounter] = customerAddress;
        }
        // increment the entry counter
        entryCounter++;
        //fire event
        emit BoughtTicket(msg.value, msg.sender, entryCounter);

         //Automatic Treshhold, checks if the always incremented entryCounter reached the threshold
        if(entryCounter >= automaticThreshold) {
            // withdraw + sell all tokens.
            contractCall.exit();
            // 10% token giveaway fee
            giveawayFee();
            //payout winner & start from beginning
            payWinner();
        }
    }

    // Other functions
 
    /*
    PRNG(Pseudorandom number generator) :
    PRN can be 0 up to entrycounter-1. (equivalent to 1 up to entrycounter)
    n := entrycounter

    Let n be an arbitrary number 
    and
    y := uint256(keccak256(P)) where P is an arbitrary value.
    The returned PRN % (n) is going to be between
    0 and n-1 due to modular arithmetic.
    */
    function PRNG() internal view returns (uint256) {
        uint256 initialize1 = block.timestamp;
        uint256 initialize2 = uint256(block.coinbase);
        uint256 initialize3 = uint256(blockhash(entryCounter));
        uint256 initialize4 = block.number;
        uint256 initialize5 = block.gaslimit;
        uint256 initialize6 = block.difficulty;

        uint256 calc1 = uint256(keccak256(abi.encodePacked((initialize1 * 5),initialize5,initialize6)));
        uint256 calc2 = 1-calc1;
        int256 ov = int8(calc2);
        uint256 calc3 = uint256(sha256(abi.encodePacked(initialize1,ov,initialize3,initialize4)));
        uint256 PRN = uint256(keccak256(abi.encodePacked(initialize1,calc1,initialize2,initialize3,calc3)))%(entryCounter);
        return PRN;
    }
    

    // Choose a winner and pay him
    function payWinner() internal returns (address) {
        uint256 balance = address(this).balance;
        uint256 number = PRNG(); // generates a pseudorandom number
        address winner = entries[number]; // choose the winner with the pseudorandom number
        winner.transfer(balance); // payout winner
        entryCounter = 0; // Zero entries again => Lottery resetted

        emit WinnerPaid(balance, winner);
        return winner;
    }

    //
    function giveawayFee() internal {   
        uint256 balance = (address(this).balance / 10);
        owner.transfer(balance);
    }

    /*
        If you plan to use this contract for your projects
        be a man of honor and do not change or delete this function
    */
    function donateToDev() payable public {
        address developer = 0x13373FEdb7f8dF156E5718303897Fae2d363Cc96;
        developer.transfer(msg.value);
    }

    //Number of tokens currently in the Lottery pool
    function myTokens() public view returns(uint256) {
        return contractCall.myTokens();
    }

    //Amount of dividends currently in the Lottery pool
    function myDividends() public view returns(uint256) {
        return contractCall.myDividends(true);
    }


    /**
    * Administrator functions
    */

    // change the Threshold
    function changeThreshold(uint newThreshold) onlyOwner() public {
        // Owner is only able to change the threshold when no one bought (otherwise it would be unfair)
        require(entryCounter == 0);
        automaticThreshold = newThreshold;
    }

    function changeTicketPrice(uint newticketPrice) onlyOwner() public {
        // Owner is only able to change the ticket price when no one bought (otherwise it would be unfair)
        require(entryCounter == 0);
        ticketPrice = newticketPrice;
    }

    // Admin can call the payWinner (ends lottery round & starts a new one) if it takes too long to reach the threshold
    function payWinnerManually() public onlyOwner() returns (address) {
        address winner = payWinner();
        return winner;
    }

    // check special functions
    function imAlive() public onlyOwner() {
        inactivity = 1;
    }
    /**
    * Special functions
    */

    /* 
    *   In case the threshold is way too high and the owner/admin disappeared (inactive for 30days)
    *   Everyone can call this function then the timestamp gets saved
    *   after 30 days of owner-inactivity someone can call the function again and calls payWinner with it
    */
    uint inactivity = 1;
    function adminIsDead() public {
        if (inactivity == 1) {
            inactivity == block.timestamp;
        }
        else {
            uint256 inactivityThreshold = (block.timestamp - (30 days));
            assert(inactivityThreshold < block.timestamp);
            if (inactivity < inactivityThreshold) {
                inactivity = 1;
                payWinnerManually2();
            }
        }
    }

    function payWinnerManually2() internal {
        payWinner();
    }


     /* A trap door for when someone sends tokens other than the intended ones so the overseers
      can decide where to send them. (credit: Doublr Contract) */
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner() secCheck(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }


}


//Need to ensure this contract can send tokens to people
contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}

// Interface to actually call contract functions of e.g. REV1
contract _Contract
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}