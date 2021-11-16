/**
 *Submitted for verification at snowtrace.io on 2021-11-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;



interface TokenInterface {
    // ERC20 functions
    function decimals() external view  returns(uint8);
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
}


contract FundzTokenSale  {
    address owner;
    uint256 price;
    TokenInterface TokenContract; // Interface variable
    uint256 public tokensSold; // Cumulative sold tokens
    
    event Sold(address indexed buyer, uint256 amount);
    
    modifier onlyOwner() {
         require(msg.sender == owner, "Owner Only!");
        _;
    }
    
    constructor(uint256 _price, address _addressContract) public {
        
        owner = msg.sender;
        price = _price;
        
        // FUNDZ Token Interface
        TokenContract = TokenInterface(_addressContract);
    }
    
    
  //SAFU Maths
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  
    function priceinWeis() public view  returns (uint256) {
    return price;
  }
  
 
    function setPrice(uint256 _newprice) public onlyOwner() {
    price = _newprice;
  }
  
  
   function etherBalance() public view onlyOwner() returns (uint256)  {
    return address(this).balance;
  }
  
   function tokenBalance() public view onlyOwner() returns (uint256)  {
    return TokenContract.balanceOf(address(this));
  }
  

  function buy(uint256 tokens) public payable {
        
        // Amount paid is equal to the price x the amount of FUNDZ tokens purchased
        require(msg.value == mul(price, tokens)); 
        
        // When calling the original transfer function we have to indicate the amount with the zeros of the decimals.
        uint256 amountwithzeros = mul(tokens, uint256(10) ** TokenContract.decimals());
        
        // Check that the sale contract has the tokens that user wants to buy
        require(TokenContract.balanceOf(address(this)) >= amountwithzeros); //address(this) direccion de nuestro contrato
        
        // Carry out the transfer with a require for greater security
        require(TokenContract.transfer(msg.sender, amountwithzeros)); // introducimos la cantidad escalada.
        
         // Add sale to total
        tokensSold += tokens; // @notice, we use the quantity without the sum of the zeros of the decimals.
        
        emit Sold(msg.sender, tokens);
        
    }
    
    
    // Function that liquidates the contract so that no more can be sold
    function endSold() public  onlyOwner() {
        
        // Compensation of balances. 
        require(TokenContract.transfer(owner, TokenContract.balanceOf(address(this))));
        msg.sender.transfer(address(this).balance);
       
    }
    

}