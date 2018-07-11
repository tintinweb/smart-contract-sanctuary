pragma solidity ^0.4.24;

 

contract Kman{

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


   event WinnerPaid
   (
        uint256 amount,
        address winner
    );
    

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    BIT BITcontract;  //a reference to the 8thereum contract
    address owner;
    bool openToPublic = false; 
    uint256 devFee;


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/

    constructor() public
    {
        BITcontract = BIT(0x645f0c9695F2B970E623aE29538FdB1A67bd6b6E); //8thereum contract
        openToPublic = false;
        owner = msg.sender;
    }


    function BITBalanceOf(address someAddress) public view returns(uint256)
    {
        return BITcontract.balanceOf(someAddress);
    }
    
    function getTokensPaidToGame(address customerAddress) public view returns (uint256)
    {
       return BITcontract.gamePlayers(address(this), customerAddress);
    }

    function firstPlacePot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return balance / 4;
    }
    
    function secondPlacePot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return (balance * 15)/ 100;
    }
    
    function thirdPlacePot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return balance / 10;
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

    //Pay tournament winners
    function PayWinners(address first, address second, address third) 
    public 
    isOpenToPublic()
    onlyRealPeople() 
    onlyOwner()
    {
        uint256 balance = BITBalanceOf(this);
        devFee = balance / 20;
        balance -= devFee;
        uint256 firstPlace = balance / 4;
        uint256 secondPlace = (balance * 15)/ 100;
        uint256 thirdPlace = (balance / 10);
        
        BITcontract.transfer(first, firstPlace);
        BITcontract.transfer(second, secondPlace); 
        BITcontract.transfer(third, thirdPlace);
        BITcontract.transfer(owner, devFee);
        
        
        emit WinnerPaid(firstPlace, first);
        emit WinnerPaid(secondPlace, second);
        emit WinnerPaid(thirdPlace, third);
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