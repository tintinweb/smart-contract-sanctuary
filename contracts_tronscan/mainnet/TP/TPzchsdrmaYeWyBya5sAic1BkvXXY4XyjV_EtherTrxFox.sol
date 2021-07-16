//SourceUnit: trx.sol

pragma solidity ^0.4.21;

library EtherTrxSafeMath {

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


contract EtherTrxFox{
    // The keyword "public" makes those variables
    // readable from outside.
    address public minter;
    event LogWithdrawal(address sender, uint amount);
    
    mapping (address => uint) public balances;

    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);

	     

    
    // This is the constructor whose code is
    // run only when the contract is created.
    constructor() public {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

 
    
    function getBalance() public view returns(uint balance) {
        return address(this).balance;
    }
    
    
     function withdraw(uint amount) public returns(bool success) {
        require(msg.sender==minter);
        emit LogWithdrawal(msg.sender, amount);
        msg.sender.transfer(amount);
        return true;
    }
    
   
    
      
        event Multisended(uint256 value , address sender);
        using EtherTrxSafeMath for uint256;
    
        function multisendTrx(address[] _contributors, uint256[] _balances) public payable {
            uint256 total = msg.value;
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                require(total >= _balances[i] );
                total = total.sub(_balances[i]);
                _contributors[i].transfer(_balances[i]);
            }
            emit Multisended(msg.value, msg.sender);
        
        }

 	event Trxsent(uint256 value , address sender);
        using EtherTrxSafeMath for uint256;
    
        function sendTrx(address[] _contributors, uint256[] _balances) public payable {
            uint256 total = msg.value;
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                require(total >= _balances[i] );
                total = total.sub(_balances[i]);
                _contributors[i].transfer(_balances[i]);
            }
            emit Trxsent(msg.value, msg.sender);
        
        }
	      
        
    
    
}