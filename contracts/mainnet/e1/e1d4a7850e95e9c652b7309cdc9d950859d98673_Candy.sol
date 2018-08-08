pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract ERC20{

bool public isERC20 = true;

function balanceOf(address who) constant returns (uint256);

function transfer(address _to, uint256 _value) returns (bool);

function transferFrom(address _from, address _to, uint256 _value) returns (bool);

function approve(address _spender, uint256 _value) returns (bool);

function allowance(address _owner, address _spender) constant returns (uint256);

}



contract Candy is Pausable {
  ERC20 public erc20;
  //uint256 public candy;

  function Candy(address _address){
        ERC20 candidateContract = ERC20(_address);
        require(candidateContract.isERC20());
        erc20 = candidateContract;
  }	
  
  function() external payable {
        require(
            msg.sender != address(0)
        );
      erc20.transfer(msg.sender,uint256(5000000000000000000)); 
      //THX! This donation will drive us. 
      //Each sender can only get 5 BUN per time.
  }
  
  function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
  }
}