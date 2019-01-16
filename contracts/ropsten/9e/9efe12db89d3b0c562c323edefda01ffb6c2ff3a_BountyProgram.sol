pragma solidity ^0.4.25;
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface SimpleBountyInterface {
    
    function createBounty(address _owner, string _task) public payable;
    function updateTask(address _bountyAddress, string _task) public;
    function addReward(address _bountyAddress) public payable;
    function addWinner(address _bountyAddress, address _winner) public;
    function removeWinner(address _bountyAddress, address _addressToRemove) public;
    function claimReward(address _bountyAddress, uint _amt, address _destAddress) public;
    function completeBounty(address _bountyAddress) public;
    function isWinner(address _bountyAddress, address _winner) public view returns (bool);
    function getTask(address _bountyAddress) public view returns (string);
    function getRewardAmount(address _bountyAddress) public view returns (uint);
    
}
 
contract BountyProgram is SimpleBountyInterface {
   
    using SafeMath for uint;
   
    struct Bounty {
        string task;
        uint reward;
        mapping(address=>bool) winners;
        address owner;
        address creator;
    }
   
    modifier bountyExists(address _bountyAddress) {
        require(exists[_bountyAddress]);
        _;
    }
   
    modifier onlyOwner(address _bountyAddress) {
        require(msg.sender == bounties[_bountyAddress].owner || msg.sender == bounties[_bountyAddress].creator);
        _;
    }
   
    mapping(address=>Bounty) public bounties; // For simplicity sake, every address can only have 1 bounty.
    mapping(address=>bool) public completed;
    mapping(address=>bool) public exists;
 
    function createBounty(address _owner, string _task) public payable {
        if(exists[_owner]) {
            require(completed[_owner]);
            bounties[_owner] = Bounty({task: _task, reward: msg.value, owner: _owner, creator: msg.sender});
            completed[_owner] = false;
        } else {
            exists[_owner] = true;
            bounties[_owner] = Bounty({task: _task, reward: msg.value, owner: _owner, creator: msg.sender});
        }
    }
   
    function updateTask(address _bountyAddress, string _task) public bountyExists(_bountyAddress) onlyOwner(_bountyAddress) {
        bounties[_bountyAddress].task = _task;
    }
   
    function addReward(address _bountyAddress) public payable bountyExists(_bountyAddress) {
        bounties[_bountyAddress].reward = bounties[_bountyAddress].reward.add(msg.value);
    }
   
    function addWinner(address _bountyAddress, address _winner) public bountyExists(_bountyAddress) onlyOwner(_bountyAddress) {
        bounties[_bountyAddress].winners[_winner] = true;
    }
 
   
    function removeWinner(address _bountyAddress, address _addressToRemove) public bountyExists(_bountyAddress) onlyOwner(_bountyAddress) {
        bounties[_bountyAddress].winners[_addressToRemove] = false;
    }
   
    function claimReward(address _bountyAddress, uint _amt, address _destAddress) public bountyExists(_bountyAddress) {
        require(bounties[_bountyAddress].winners[_destAddress]);
        require(bounties[_bountyAddress].reward >= _amt);
        bounties[_bountyAddress].reward = bounties[_bountyAddress].reward.sub(_amt);
        _destAddress.transfer(_amt);
    }
   
    function completeBounty(address _bountyAddress) public bountyExists(_bountyAddress) onlyOwner(_bountyAddress) {
        completed[_bountyAddress] = true;
    }
   
    function isWinner(address _bountyAddress, address _winner) public view bountyExists(_bountyAddress) returns (bool) {
        return bounties[_bountyAddress].winners[_winner];
    }
   
    function getTask(address _bountyAddress) public view bountyExists(_bountyAddress) returns (string) {
        return bounties[_bountyAddress].task;
    }
   
    function getRewardAmount(address _bountyAddress) public view bountyExists(_bountyAddress) returns (uint) {
        return bounties[_bountyAddress].reward;
    }
   
}