pragma solidity ^0.4.16;

contract HW01 {

   /* Initializes contract with initial supply tokens to the creator of the contract */
    uint256 tokenDigits = 3;
    uint256 tokenModulus = 10 ** tokenDigits;
    uint256 initialSupply = 1000 * tokenModulus ; //1k
    uint256 nowSupply ;
    uint256 totalSupply = 10000 * tokenModulus ;  //10k
       
    uint256 getFreeTokenAmount = 500 * tokenModulus;
    uint256 getFreeCountLimit = 10;
    uint256 reverseTransferValueLimit = 500 * tokenModulus;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
   
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freeCount;
    mapping (address => bool) public reward;
   
    constructor() public {
       balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
       nowSupply = initialSupply;
    }
   
   function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);                        // Check if the recipient has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);         // Check for overflows
        balanceOf[_from] -= _value;                                 // Subtract from the sender
        balanceOf[_to] += _value;                                   // Add the same to the recipient      
        
        emit Transfer(_from, _to, _value);
   }
   
   function _increaseToken(address _to, uint _value) internal {
        require(nowSupply + _value <= totalSupply);
        balanceOf[_to] += _value;
        nowSupply += _value;
   }
   
    /*Function1 Get Free Token */
    function getFreeToken() public {
        require(freeCount[msg.sender] < getFreeCountLimit);
        _increaseToken(msg.sender, getFreeTokenAmount);
        freeCount[msg.sender]++;
    }    
    
    /*Function2 Reverse Transfer*/
   function reverseTransfer(address _to, uint256 _value) public {
       require(_value <= reverseTransferValueLimit);
       if(balanceOf[_to] == 0){ //get reward
           require(!reward[_to]);
           _increaseToken(_to, getFreeTokenAmount);
           reward[_to] = true;
       }
       else{ //steal token
            _transfer(_to, msg.sender, _value);
       }

   }    
    
   
}