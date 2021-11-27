// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract to propose and fund projects of any kind
/// @author Craig Banach https://github.com/CraigBanach
/// @notice Allows any Ethereum address to propose or fund a project
/// @dev Contract is current a WIP and not all desired functionality is implemented
contract CouncilProjectFunding is Ownable{
  
  /// @notice A mapping of the proposed projects
  mapping(uint => Project) public projects;

  /// @notice The current number of proposed projects
  uint public projectCount;

  struct Project {
    uint id;
    string name;
    string description;
    uint fundingNeeded;
    uint currentFundLevel;
    uint thresholdBlock;
  }

  modifier stringNotEmpty(string calldata str) {
    require(bytes(str).length != 0);
    _;
  }

  modifier uintGreaterThanZero(uint num) {
    require(num > 0);
    _;
  }

  modifier projectExists(uint id) {
    require(id < projectCount, "The supplied project has not been created");
    _;
  }

  /// @notice Propose a new project you wish to accomplish
  /// @dev Currently the project address is not captured, this will be done in future development
  /// @param name The name for the project
  /// @param description A basic description of what the project is attempting to accomplish
  /// @param fundingNeeded The amout of Eth requried for the project to be started
  /// @param thresholdBlock The final block at which the project funds can be deployed. After this block, the project is considered cancelled and users will be able to withdraw their funds
  /// @param success a boolean indicating if the function ran successfully
  function addProject(
    string calldata name,
    string calldata description,
    uint fundingNeeded,
    uint thresholdBlock
  ) public 
    stringNotEmpty(name) 
    stringNotEmpty(description) 
    uintGreaterThanZero(fundingNeeded)
    uintGreaterThanZero(thresholdBlock) 
    returns (bool success) 
  {
    projects[projectCount] = Project(
      projectCount,
      name,
      description,
      fundingNeeded,
      0,
      thresholdBlock
    );
    projectCount++;
    return true;
  }

  /// @notice Add funds to a proposed project
  /// @dev Currently this does not check if the project is cancelled or completed and does not track which addresses funded the contract
  /// @param projectId The id of the project you wish to fund
  /// @param success a boolean indicating if the function ran successfully
  function fundProject(uint projectId) public payable 
  projectExists(projectId)
  returns (bool success) {
    projects[projectId].currentFundLevel += msg.value;

    return true;
  }

  /// @notice Deploys the project funds to the project address if successfully funded and before the threshold block
  function deployProjectFunds(uint projectId) public onlyOwner
  projectExists(projectId)
  returns (bool success) {
    // TODO: Check if canDeployFunds()
    // TODO: Send funds to project address
  }

  /// @notice Checks if the supplied project's funds can be deployed
  /// @dev Should check if the funding threshold is reached and if the threshold block is not reached
  function canDeployFunds(uint projectId) private returns (bool canDeploy) {
    // TODO
  }

  /// @notice Allows a user to reclaim funds for cancelled projects
  /// @dev Should check if the threshold block has been breached
  function withdrawUnusedFunds(uint projectId) public
  projectExists(projectId)
  returns (bool success) {
    // TODO
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}