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
    address[] public entityList;

    struct ProjectAttribute {
        uint256 projectID;
        bool isActive;
        
        uint256 upVotes;
        uint256 downVotes;
        uint256 medVotes;

        string ProjectName;
        string ProjectSymbol;
        string ProjectLogo;
        string ProjectWebsite;
        string ProjectTelegram;
        string ProjectTwitter;
        address ProjectAddress;
        address ProjectManager;
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
      ProjectStore[_projectAddress].upVotes += _votesCount;
      return true;
  }
    function downVoteProject(uint256 _votesCount, address _projectAddress) public nonReentrant returns (bool){
      require(isMemberValid(msg.sender), "You are not yet a Manager");
      require(isActive(_projectAddress), "This project is not active");
      require(memberPoolContract.getUserVotes(msg.sender) > 0, "You dont have any Votes left");
      
      
      memberPoolContract.spendVotes(_votesCount);
      ProjectStore[_projectAddress].downVotes += _votesCount;
      return true;
  }
    function medVoteProject(uint256 _votesCount, address _projectAddress) public nonReentrant returns (bool){
      require(isMemberValid(msg.sender), "You are not yet a Manager");
      require(isActive(_projectAddress), "This project is not active");
      require(memberPoolContract.getUserVotes(msg.sender) > 0, "You dont have any Votes left");
      
      
      memberPoolContract.spendVotes(_votesCount);
      ProjectStore[_projectAddress].medVotes += _votesCount;
      return true;
  }

    function isActive(address requestedAddress) public view returns (bool isIndeed) {
        return ProjectStore[requestedAddress].isActive;
    }

    function getProjectNameByAddress(address requestedAddress) public view returns (string memory isUsername) {
        return ProjectStore[requestedAddress].ProjectName;
    }

    function getProjectsCount() public view returns (uint256 entityCount) {
        return entityList.length;
    }

    function setProjectState(address _projectAddress, bool _state) public {
        require(Managers[msg.sender], "You are not yet a Manager");
        ProjectStore[_projectAddress].isActive = _state;
    }

    function changeManagerState(address _account, bool _state) external onlyOwner {
        Managers[_account] = _state;
    }

    //Project has to be initalized from a Manager, can be later edited only from the ProjectManager
    function addProject(string memory _projectName, string memory _projectSymbol,string memory _projectLogo, string memory _projectWebsite, string memory _projectTelegram, string memory _projectTwitter, address _projectAddress, address _projectManager) public {
        require(Managers[msg.sender], "You are not yet a Manager");
        require(ProjectStore[msg.sender].ProjectAddress != _projectAddress, "You already have a project");

        ProjectStore[_projectAddress].projectID = getProjectsCount();
        ProjectStore[_projectAddress].isActive = true;
        ProjectStore[_projectAddress].ProjectName = _projectName;
        ProjectStore[_projectAddress].ProjectSymbol = _projectSymbol;
        ProjectStore[_projectAddress].ProjectLogo = _projectLogo;
        ProjectStore[_projectAddress].ProjectWebsite = _projectWebsite;
        ProjectStore[_projectAddress].ProjectTelegram = _projectTelegram;
        ProjectStore[_projectAddress].ProjectTwitter = _projectTwitter;
        ProjectStore[_projectAddress].ProjectAddress = _projectAddress;
        ProjectStore[_projectAddress].ProjectManager = _projectManager;

        entityList.push(_projectAddress);
    }

    function editProject(string memory _projectName, string memory _projectSymbol,string memory _projectLogo, string memory _projectWebsite, string memory _projectTelegram, string memory _projectTwitter, address _projectAddress) public {
        require(ProjectStore[_projectAddress].ProjectManager == msg.sender, "You are not the Manager of this project");

        ProjectStore[_projectAddress].ProjectName = _projectName;
        ProjectStore[_projectAddress].ProjectSymbol = _projectSymbol;
        ProjectStore[_projectAddress].ProjectLogo = _projectLogo;
        ProjectStore[_projectAddress].ProjectWebsite = _projectWebsite;
        ProjectStore[_projectAddress].ProjectTelegram = _projectTelegram;
        ProjectStore[_projectAddress].ProjectTwitter = _projectTwitter;
    }
    
    function getVotesPerProject(address _requestedProject) external view returns(uint256,uint256,uint256){
        require(isActive(_requestedProject), "This Project is not active");
        
        return (ProjectStore[_requestedProject].upVotes, ProjectStore[_requestedProject].downVotes,ProjectStore[_requestedProject].medVotes);
        
    }
    function getAllActiveProjectsData() external view returns (uint256[] memory, string[] memory,string[] memory, string[] memory, string[] memory, string[] memory, string[] memory, address[] memory) {
        uint256[] memory isProjectID = new uint256[](entityList.length);
        string[] memory nameProject = new string[](entityList.length);
        string[] memory symbolProject = new string[](entityList.length);
        string[] memory logoProject = new string[](entityList.length);
        string[] memory websiteProject = new string[](entityList.length);
        string[] memory telegramProject = new string[](entityList.length);
        string[] memory twitterProject = new string[](entityList.length);
        address[] memory addressProject = new address[](entityList.length);


        for (uint i = 0; i < entityList.length; i++) {
            if (isActive(entityList[i])) {
                isProjectID[i] = ProjectStore[entityList[i]].projectID;
                nameProject[i] = ProjectStore[entityList[i]].ProjectName;
                symbolProject[i] = ProjectStore[entityList[i]].ProjectSymbol;
                logoProject[i] = ProjectStore[entityList[i]].ProjectLogo;
                websiteProject[i] = ProjectStore[entityList[i]].ProjectWebsite;
                telegramProject[i] = ProjectStore[entityList[i]].ProjectTelegram;
                twitterProject[i] = ProjectStore[entityList[i]].ProjectTwitter;
                addressProject[i] = ProjectStore[entityList[i]].ProjectAddress;}
        }

        return (isProjectID, nameProject, symbolProject,logoProject, websiteProject, telegramProject, twitterProject, addressProject);}


    receive() external payable {
        revert ();
    }
}