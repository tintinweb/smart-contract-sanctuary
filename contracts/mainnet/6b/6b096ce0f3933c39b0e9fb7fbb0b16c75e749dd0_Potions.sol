pragma solidity ^0.4.24;

 

contract Potions{

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
    modifier notBIT(address aContract)
    {
        require(aContract != address(BITcontract));
        _;
    } 

    modifier isOpenToPublic()
    {
        require(openToPublic);
        _;
    }

    modifier onlyRealPeople()
    {
          require (msg.sender == tx.origin);
        _;
    }
    
    
    /*==============================
    =            EVENTS            =
    ==============================*/


   event WinnerPaid(
        uint256 amount,
        address winner
    );

    event TransactionDetails(
    uint256 chosenNumber,
    uint256 winningNumber
    );

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    BIT BITcontract;  //a reference to the 8thereum contract
    address owner;
    bool openToPublic = false; 
    uint256 winningNumber; //The randomly generated number(this changes with every transaction)
    mapping(address => uint256) paidPlayers;


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/

    constructor() public
    {
        BITcontract = BIT(0x79a92e3E07eB9Dad756214e7B6D8ba982c2141A5); //8thereum contract
        openToPublic = false;
        owner = msg.sender;
    }

     function start(uint256 choice)
       isOpenToPublic()
       onlyRealPeople()
      public returns(bool)
     {
        bool didYouWin = false;
        uint256 tokensTransferred = getTokensPaidToGame(msg.sender);

        // When you transfer a token to the contract, there is a 1 coin difference until you enter the next if statement
        if( tokensTransferred > paidPlayers[msg.sender]) //can&#39;t play if you don&#39;t pay
        {
            paidPlayers[msg.sender] = tokensTransferred;
        }
        else
        {
            revert();
        }
       
        winningNumber = uint256(keccak256(blockhash(block.number-1), choice,  msg.sender))%5 +1;//choose random number
       
         //if when we have a winner...
        if(choice == winningNumber)
        {   
            uint256 tokensToWinner = (BITBalanceOf(address(this)) / 2);
           //payout winner
           BITcontract.transfer(msg.sender, tokensToWinner);
           emit WinnerPaid(tokensToWinner, msg.sender);
           didYouWin = true;
        }
        
        emit TransactionDetails(choice, winningNumber);
        return didYouWin;
        
    }

    function BITBalanceOf(address someAddress) public view returns(uint256)
    {
        return BITcontract.balanceOf(someAddress);
    }
    
    function getTokensPaidToGame(address customerAddress) public view returns (uint256)
    {
       return BITcontract.gamePlayers(address(this), customerAddress);
    }

    function winnersPot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return balance / 2;
    }

    function BITWhaleBalance() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(address(0x1570c19151305162e2391e956F74509D4f566d42));
       return balance;
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
    }


     /* A trap door for when someone sends tokens other than the intended ones so the overseers
      can decide where to send them. (credit: Doublr Contract) */
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens)
    public
    onlyOwner()
    notBIT(tokenAddress)
    returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }

}


contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}  

//Need to ensure the Lottery contract knows what a test token is
contract BIT
{
    function transfer(address, uint256) public returns(bool);
    mapping(address => mapping(address => uint256)) public gamePlayers;
    function balanceOf(address customerAddress) public view returns(uint256);
}