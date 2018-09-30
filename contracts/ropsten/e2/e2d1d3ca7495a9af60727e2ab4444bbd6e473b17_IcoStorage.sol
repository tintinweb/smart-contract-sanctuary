pragma solidity ^0.4.24;


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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract IcoStorage is Ownable {

    struct Project {
        bool isValue; // We now can know this is an initialized struct
        string name; // ICO company name
        address tokenAddress; // Token&#39;s smart contract address
        bool active;    // if true, this contract can be shown
    }

    mapping(address => Project) public projects;
    address[] public projectsAccts;

    function createProject(
        string _name,
        address _icoContractAddress,
        address _tokenAddress
    ) public onlyOwner returns (bool) {
        Project storage project  = projects[_icoContractAddress]; // Create new project

        project.isValue = true; // project is initilaized and not empty
        project.name = _name;
        project.tokenAddress = _tokenAddress;
        project.active = true;

        projectsAccts.push(_icoContractAddress);

        return true;
    }

    function getProject(address _icoContractAddress) public view returns (string, address, bool) {
        require(projects[_icoContractAddress].isValue);

        return (
            projects[_icoContractAddress].name,
            projects[_icoContractAddress].tokenAddress,
            projects[_icoContractAddress].active
        );
    }

    function activateProject(address _icoContractAddress) public onlyOwner returns (bool) {
        Project storage project  = projects[_icoContractAddress];
        require(project.isValue); // Check project exists

        project.active = true;

        return true;
    }

    function deactivateProject(address _icoContractAddress) public onlyOwner returns (bool) {
        Project storage project  = projects[_icoContractAddress];
        require(project.isValue); // Check project exists

        project.active = false;

        return false;
    }

    function getProjects() public view returns (address[]) {
        return projectsAccts;
    }

    function countProjects() public view returns (uint256) {
        return projectsAccts.length;
    }
}