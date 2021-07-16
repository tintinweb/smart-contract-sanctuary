//SourceUnit: TronDesire.sol


/**
 
* Tron Desire
* https://trondesire.io/
* 
**/
pragma solidity >= 0.5.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}

contract TronDesire {
    using SafeMath for uint256;
    event Multisended(uint256 value , address sender);

    event Deposit(uint256 value , address sender, address referal);
    event Transfer(uint256 value, address reciever);


     address payable public owner;
    

    constructor() public {
      owner = msg.sender;
    }


    function multisendEther(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }


     function deposit(address _referral) public payable {
    
        
    }



     // Function to transfer trx from this contract to address from input
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        
        (bool success, ) = _to.call.value(_amount)("");
        require(success, "Failed to send trx");
        
    }


     modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }
    
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
    
    


     // Function to withdraw all trx from this contract.
    function withdraw(uint amount) public {
        // get the amount of trx stored in this contract 
        (bool success, ) = owner.call.value(amount)("");
        require(success, "Failed to send trx");
    }


     function get_balance() public view returns (uint) {
        return address(this).balance;
    }



    
   


  

    
   


}