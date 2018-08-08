pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract PropertyClubICO is Ownable {
    uint256 public constant minLimit = 0.4 ether;
    bool public isFinished;
    mapping (address => uint256) public balanceOf;
    uint256 public totalRaised;
    
    
    event Deposit(address indexed _from, uint _value);
    
    constructor() public {
        isFinished = false;
    }
    
    function () public payable {
        deposit();
    }
    
    function deposit() public payable {
        require(msg.value >= minLimit && !isFinished);
        
        owner.transfer(msg.value);
        balanceOf[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function finishICO() onlyOwner public {
        isFinished = true;
    }
    
}