/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

pragma solidity >=0.8.0;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner ;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor()  {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract Special_LockingContract_V1 is Ownable {
    using SafeMath for uint;
    
    // token contract address
    address public constant tokenAddress = 0xF334E3A78a03A56972f98f75C8B1c10A69f3426B;
    
    uint256 public tokens = 0;
    uint256 public current_withdraw = 1 ;
    
    uint256 public constant number_withdraws = 54;
    uint256 public constant period_time = 3 minutes;
    
    uint256 public timing ;
    uint256 public amount_per_withdraw = 0;
    uint256 public amount_already_out = 0;
    

    function getNumPeriods() public view returns(uint){
        uint _numIntervals;
        if(tokens == 0 || timing == 0){
            _numIntervals = 0;
        }else{
            
                _numIntervals = (block.timestamp.sub(timing)).div(period_time);
                
                if(_numIntervals > number_withdraws){
                    _numIntervals = number_withdraws;
                }
        }

        return _numIntervals;
    }
    

    function getTiming()  public view returns (uint256){
        return block.timestamp.sub(timing);
    }
    
    function deposit(uint amountToStake) public onlyOwner returns (bool){
        require( tokens == 0, "Cannot deposit more Tokens");
        require( amountToStake > 0, "Cannot deposit  Tokens");
        
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        
        amount_per_withdraw = amountToStake.div(number_withdraws);
        
        tokens = amountToStake;
        
        timing = block.timestamp;
        return true;
        }
    
    function withdraw() public onlyOwner returns(bool){
        require( tokens >  0, "No tokens left");
        require(current_withdraw <= getNumPeriods() , "Not yet");
        
        current_withdraw = current_withdraw.add(1);
        
        require(Token(tokenAddress).transfer(owner, amount_per_withdraw), "Could not transfer tokens.");
        tokens = tokens.sub(amount_per_withdraw);
        amount_already_out = amount_already_out.add(amount_per_withdraw);
        
        return true;
        
        }
    }