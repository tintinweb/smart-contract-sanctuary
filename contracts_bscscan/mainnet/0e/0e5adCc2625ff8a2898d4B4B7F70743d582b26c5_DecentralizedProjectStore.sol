/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}
interface MemberStorage {
    function isMember(address requestedAddress) external view returns(bool);
    function getUserNameByAddress(address requestedAddress) external view returns(uint256);
    function isBlacklisted(address requestedAddress) external view returns(bool);
    function getUserVotes(address requestedAddress) external view returns(uint256);
    function spendVotes(uint256 _amount) external;
}


contract DecentralizedProjectStore is Ownable,ReentrancyGuard {
    
    //Map for the Managers to change data of their own project
    mapping(address => bool) public Managers;
    MemberStorage memberPoolContract;

    mapping(address => ProjectAttribute) public ProjectStore;

    struct ProjectAttribute {
        bool isActive;
                
        uint256 upVotes;
        uint256 downVotes;
        uint256 medVotes;

        address ProjectAddress;

    }

    constructor(address _memberPoolContract) {
        Managers[msg.sender] = true;
        memberPoolContract = MemberStorage(_memberPoolContract);
    }
    
    function isMemberValid(address requestedAddress) public view returns(bool isIndeed) {
      return memberPoolContract.isMember(requestedAddress);
  }
    function getIsBlacklisted(address requestedAddress)public view returns(bool isIndeed) {
       return memberPoolContract.isBlacklisted(requestedAddress);
  }
  
  function upVoteProject(uint256 _votesCount, address _projectAddress) public nonReentrant returns (bool){
      require(isMemberValid(msg.sender), "You are not yet a Manager");
      require(isActive(_projectAddress), "This project is not active");
      require(memberPoolContract.getUserVotes(msg.sender) > 0, "You dont have any Votes left");
      
      
      memberPoolContract.spendVotes(_votesCount);
      ProjectStore[_projectAddress].isActive = true;
      ProjectStore[_projectAddress].upVotes += _votesCount;
      return true;
  }
    function downVoteProject(uint256 _votesCount, address _projectAddress) public nonReentrant returns (bool){
      require(isMemberValid(msg.sender), "You are not yet a Manager");
      require(isActive(_projectAddress), "This project is not active");
      require(memberPoolContract.getUserVotes(msg.sender) > 0, "You dont have any Votes left");
      
      
      memberPoolContract.spendVotes(_votesCount);
      ProjectStore[_projectAddress].isActive = true;
      ProjectStore[_projectAddress].downVotes += _votesCount;
      return true;
  }
    function medVoteProject(uint256 _votesCount, address _projectAddress) public nonReentrant returns (bool){
      require(isMemberValid(msg.sender), "You are not yet a Manager");
      require(isActive(_projectAddress), "This project is not active");
      require(memberPoolContract.getUserVotes(msg.sender) > 0, "You dont have any Votes left");
      
      
      memberPoolContract.spendVotes(_votesCount);
      ProjectStore[_projectAddress].isActive = true;
      ProjectStore[_projectAddress].medVotes += _votesCount;
      return true;
  }

    function isActive(address requestedAddress) public view returns (bool isIndeed) {
        return ProjectStore[requestedAddress].isActive;
    }

    function setProjectState(address _projectAddress, bool _state) public {
        require(Managers[msg.sender], "You are not yet a Manager");
        ProjectStore[_projectAddress].isActive = _state;
    }

    function changeManagerState(address _account, bool _state) external onlyOwner {
        Managers[_account] = _state;
    }


    function getVotesPerProject(address _requestedProject) external view returns(uint256,uint256,uint256){
        require(isActive(_requestedProject), "This Project is not active");
        
        return (ProjectStore[_requestedProject].upVotes, ProjectStore[_requestedProject].downVotes,ProjectStore[_requestedProject].medVotes);
        
    }


    receive() external payable {
        revert ();
    }
}