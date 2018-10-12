pragma solidity 0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}  

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ClaimReward is Ownable {
    /// @dev This emits when claimReward is called
    event LogClaimReward(address indexed sender, uint256 indexed rewards);
    
    address communityFundAddress = 0x325a7A78e5da2333b475570398F27D8F4e8E9Eb3;
    address livePeerContractAddress = 0x58b6A8A3302369DAEc383334672404Ee733aB239;

    // Delegators addresses 
    address[] private delegatorAddressList;

    mapping (address => Delegator) rewardDelegators;
    // count the number of reward claimed    
    uint256 public claimCounter = 0;
    // Status of the current contract 
    bool public contractStopped = false;
    
    struct Delegator {
        address delegator;
        uint rewards;
        bool hasClaimed;
    }
    
    // Used to check contract status before executing createQuestionnaire function
    modifier haltInEmergency {
        require(!contractStopped);
        _;
    }
    
    /// @notice only the contract owner is allowed to change
    /// @dev change the contract status to pause or continue
    function toggleContractStopped() public onlyOwner {
        contractStopped = !contractStopped;
    }
    
    // @dev initialize delegator address and rewards
    function updateDelegatorRewards(address[] delegatorAddress, uint[] rewards) onlyOwner public returns (bool) {
        for (uint i=0; i<delegatorAddress.length; i++) {
            Delegator memory delegator = Delegator(delegatorAddress[i], rewards[i] * 10 ** 14 , false);
            rewardDelegators[delegatorAddress[i]] = delegator;
            delegatorAddressList.push(delegatorAddress[i]);
        }
        return true;
    }
    
    // @dev query the delegator rewards
    function checkRewards() external view returns (uint256) {
        return rewardDelegators[msg.sender].rewards;
    }
    
    // @dev transfer the reward to the delegator
    function claimRewards() external haltInEmergency returns (bool) {
        require(!rewardDelegators[msg.sender].hasClaimed);
        require(rewardDelegators[msg.sender].delegator == msg.sender);
        require((ERC20(livePeerContractAddress).balanceOf(this) - this.checkRewards()) > 0);
        require(claimCounter < this.getAllDelegatorAddress().length);
        
        rewardDelegators[msg.sender].hasClaimed = true;
        claimCounter += 1;
        ERC20(livePeerContractAddress).transfer(msg.sender, rewardDelegators[msg.sender].rewards);
        
        emit LogClaimReward(msg.sender, rewardDelegators[msg.sender].rewards);
        
        return true;
    }

    // @dev transfer those remaining LPT to the community fund address
    function activateCommunityFund() external onlyOwner returns (bool) {
        require(ERC20(livePeerContractAddress).balanceOf(this) > 0);
        ERC20(livePeerContractAddress).transfer(communityFundAddress, ERC20(livePeerContractAddress).balanceOf(this));
        return true;
    }
    
    // @dev return all delegators
    function getAllDelegatorAddress() external view returns (address[]) {
        return delegatorAddressList;  
    } 
}