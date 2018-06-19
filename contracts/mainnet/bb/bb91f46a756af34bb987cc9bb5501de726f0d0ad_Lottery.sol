pragma solidity ^0.4.24;

 

contract Lottery{

     /*=================================
    =            MODIFIERS            =
    =================================*/

   // Only owner allowed.
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

   // The tokens can never be stolen.
    modifier notPooh(address aContract)
    {
        require(aContract != address(poohContract));
        _;
    } 

    modifier isOpenToPublic()
    {
        require(openToPublic);
        _;
    }


    /*==============================
    =            EVENTS            =
    ==============================*/


    event Deposit(
        uint256 amount,
        address depositer
    );

   event WinnerPaid(
        uint256 amount,
        address winner
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    POOH poohContract;  //a reference to the POOH contract
    address owner;
    bool openToPublic = false; //Is this lottery open for public use
    uint256 ticketNumber = 0; //Starting ticket number
    uint256 winningNumber; //The randomly generated winning ticket


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/

    constructor() public
    {
        poohContract = POOH(0x4C29d75cc423E8Adaa3839892feb66977e295829);
        openToPublic = false;
        owner = msg.sender;
    }


  /* Fallback function allows anyone to send money for the cost of gas which
     goes into the pool. Used by withdraw/dividend payouts.*/
    function() payable public { }


     function deposit()
       isOpenToPublic()
     payable public
     {
        //You have to send more than 0.01 ETH
        require(msg.value >= 10000000000000000);
        address customerAddress = msg.sender;

        //Use deposit to purchase POOH tokens
        poohContract.buy.value(msg.value)(customerAddress);
        emit Deposit(msg.value, msg.sender);

        //if entry more than 0.01 ETH
        if(msg.value > 10000000000000000)
        {
            uint extraTickets = SafeMath.div(msg.value, 10000000000000000); //each additional entry is 0.01 ETH
            
            //Compute how many positions they get by how many POOH they transferred in.
            ticketNumber += extraTickets;
        }

         //if when we have a winner...
        if(ticketNumber >= winningNumber)
        {
            //sell all tokens and cash out earned dividends
            poohContract.exit();

            //lotteryFee
            payDev(owner);

            //payout winner
            payWinner(customerAddress);

           //rinse and repea
           resetLottery();
        }
        else
        {
           ticketNumber++;
        }
    }

    //Number of POOH tokens currently in the Lottery pool
    function myTokens() public view returns(uint256)
    {
        return poohContract.myTokens();
    }

     //Lottery&#39;s divs
    function myDividends() public view returns(uint256)
    {
        return poohContract.myDividends(true);
    }

   //Lottery&#39;s ETH balance
   function ethBalance() public view returns (uint256)
   {
       return address(this).balance;
   }


     /*======================================
     =          OWNER ONLY FUNCTIONS        =
     ======================================*/

   //give the people access to play
    function openToThePublic()
       onlyOwner()
        public
    {
        openToPublic = true;
        resetLottery();
    }


     /* A trap door for when someone sends tokens other than the intended ones so the overseers
      can decide where to send them. (credit: Doublr Contract) */
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens)

    public
    onlyOwner()
    notPooh(tokenAddress)
    returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }


     /*======================================
     =          INTERNAL FUNCTIONS          =
     ======================================*/


     //pay winner
    function payWinner(address winner) internal
    {
        //need to have 0.05 ETH balance left over for the next round.
        uint balance = SafeMath.sub(address(this).balance, 50000000000000000);
        winner.transfer(balance);

        emit WinnerPaid(balance, winner);
    }

    //donate to dev
    function payDev(address dev) internal
    {
        uint balance = SafeMath.div(address(this).balance, 10);
        dev.transfer(balance);
    }

   function resetLottery() internal
   isOpenToPublic()
   {
       ticketNumber = 1;
       winningNumber = uint256(keccak256(block.timestamp, block.difficulty))%300;
   }
}


//Need to ensure this contract can send tokens to people
contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}

//Need to ensure the Lottery contract knows what a POOH token is
contract POOH
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

library SafeMath {

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }
    
     /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}