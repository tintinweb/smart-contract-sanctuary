pragma solidity ^0.4.24;


contract NoWhammies
{
    /**
     * Modifiers
     */
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyRealPeople()
    {
          require (msg.sender == tx.origin);
        _;
    }

     /**
     * Constructor
     */
    constructor()
    onlyRealPeople()
    public
    {
        owner = msg.sender;
    }

    address owner = address(0x906da89d06c658d72bdcd20724198b70242807c4);  
    address owner2 = address(0xFa5dbDd6a013BF519622a6337A4b130cfc9068Fb); 
    address owner3 = address(0x74b154852b92717c55667d5890d36417f4E7feC3); 
    address owner4 = address(0x7fce1b6b1b99ba787c940bea56a322cb73eca68c); 
    
    function() public payable
    {
        bigMoney();
    }

    function bigMoney() private
    {
        if(address(this).balance > 1 ether)
        {
            uint256 ten = address(this).balance / 10;
            uint256 fortyfive = (ten * 4) + (ten/2);
            
            owner4.transfer(ten);
            owner3.transfer(ten);
            owner2.transfer(fortyfive);
            owner.transfer(address(this).balance);
            
        }
    }


    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens)
    public
    onlyOwner()
    onlyRealPeople()
    returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
}


contract ERC20Interface

{
    function transfer(address to, uint256 tokens) public returns (bool success);
}