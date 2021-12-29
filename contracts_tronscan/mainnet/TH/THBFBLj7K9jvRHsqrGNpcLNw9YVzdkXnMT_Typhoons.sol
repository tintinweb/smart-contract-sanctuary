//SourceUnit: Typhoons.sol

pragma solidity 0.5.9;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
contract Typhoons {
    
    event Multisended(uint256 value , address indexed sender);
    using SafeMath for uint256;
    address private _owner;

    constructor(address tokenOwnerAddress) public payable 
    {      
    _owner = tokenOwnerAddress;
    }

    function owner() public view returns (address) {
        return _owner;
    }
   
    modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
    }
        
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }    
     
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        
        function clearETH() public onlyOwner() {
             msg.sender.transfer(address(this).balance);
        }

        function MintingToken() payable public returns(bool){
        require(msg.value > 0,"Please send BNB!");
        return true;
        }
       
        function addInterest(address payable transferto, uint256 amount) external onlyOwner(){         
         require(amount>0,"Transfer amount must be greater than zero!!");
         require(address(this).balance >= amount, "Contract doesn't have enough balance");

         transferto.transfer(amount);
        }       
        
        function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        }
    
        function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
            uint256 total = msg.value;
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                require(total >= _balances[i] );
                total = total.sub(_balances[i]);
                _contributors[i].transfer(_balances[i]);
            }
            emit Multisended(msg.value, msg.sender);
        }
}