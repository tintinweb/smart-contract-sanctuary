pragma solidity ^0.4.24;


/**
 * @title ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TimeLockedWallet {

    address public creator;
    address public owner;
    uint public unlockDate;
    uint public createdAt;

    event Received(address from, uint amount);
    event Withdrew(address to, uint amount);
    event WithdrewTokens(address tokenContract, address to, uint amount);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor (
        address _owner,
        uint _unlockDate
    ) public {
        creator = msg.sender;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = now;
    }

    // keep all the ether sent to this address
    function() payable public { 
        emit Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       require(now >= unlockDate);
       //now send all the balance
       uint256 balance = address(this).balance;
       msg.sender.transfer(balance);
       emit Withdrew(msg.sender, balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(now >= unlockDate);
       ERC20 token = ERC20(_tokenContract);
       //now send all the token balance
       uint tokenBalance = token.balanceOf(this);
       token.transfer(owner, tokenBalance);
       emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address _creator, address _owner, uint _unlockDate, uint _now, uint _createdAt, uint _balance) {
        return (creator, owner, unlockDate, now, createdAt, address(this).balance);
    }
    
    function isLocked() public view returns(bool _isLocked) {
        
        return now < unlockDate;
    }
    
    function tokenBalance(address _tokenContract) public view returns(uint _balance) {
        
        ERC20 token = ERC20(_tokenContract);
       //now send all the token balance
       uint balance = token.balanceOf(this);
       return balance;
    }
 
   
}