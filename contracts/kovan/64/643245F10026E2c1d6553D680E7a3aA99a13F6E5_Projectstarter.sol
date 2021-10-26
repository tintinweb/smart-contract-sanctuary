/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: Project

//contract template for initiating a project
contract Project is Ownable {
    mapping(address => uint256) public userDeposit;
    //variable for projectname

    
    string projectName;
    //variable for projectstarter (EOA projectstarter)
    address payable projectStarter;
    //starttime of fundingperiod (is this necessary?)
    uint256 fundingStartTime;
    //endtime of fundingperiod
    uint256 fundingEndTime;
    //Targetamount for funding
    uint256 fundTarget;
    //current balance of the project
    uint256 currentBalance;
    //starttime of projectperiod (starting after fundingperiod)
    uint256 projectStartTime;
    //endtime of the project
    uint256 projectEndTime;
    //is the project initialized succesful?
    bool isInitialized;
    //amount of supporter
    uint256 amountUser;

    //put owner in constructor to use for initializing project
    constructor(
        string memory _projectName, 
        address payable _projectStarter, 
        uint256 _fundingEndTime, 
        uint256 _fundTarget, 
        uint256 _projectEndTime
        ) {

        projectName = _projectName;
        projectStarter = _projectStarter;
        fundingEndTime = _fundingEndTime;
        fundTarget = _fundTarget;
        projectEndTime = _projectEndTime;
        isInitialized = true;
        
    }

    //q: correct use of constructor?
    //q: double use of setting owner?


    function deposit(uint256 amount) public payable{
        require(fundingEndTime > block.timestamp, "Funding ended");
        require(currentBalance + amount < fundTarget, "amount higher than fund target");

        userDeposit[msg.sender] += amount;
        currentBalance += amount;
    }

    //q: how to make storage of amounts that have been deposited before, to see if amount is greater than fundTarget - previous deposits
    //q: re-entrancy guard necessary?

    //emergency function to stop the funding (and stop the project)
    function stopProject() public onlyOwner {
        fundingEndTime = block.timestamp;
        projectEndTime = block.timestamp;
    }

    //q: proper use of block.timestamp?

    function detailsProject() public view returns (string memory Name,  address Starter, uint256 Target, uint256 Balance){
        Name = projectName;
        Starter = projectStarter;
        Target = fundTarget;
        Balance = currentBalance;
        return (Name, Starter, Target, Balance);
    } 

    //How to see these variables when calling function?

    //function for returning the funds
    function withdrawFunds() public returns(bool success) {   
        require(userDeposit[msg.sender] >= 0);// guards up front
        amountUser = userDeposit[msg.sender];
        userDeposit[msg.sender] -= userDeposit[msg.sender];         // optimistic accounting
        payable(msg.sender).transfer(amountUser);            // transfer
        return true;
        }
 

    function payOut(uint amount) public returns(bool success) {
        require(msg.sender == projectStarter);
        require(fundingEndTime < block.timestamp);
        
        uint fundAmount = currentBalance;
        currentBalance = 0;
        projectStarter.transfer(amount);
        return true;
    }


}

// File: Projectstarter.sol

contract Projectstarter is Ownable {
    address newAddress;
    Project[] public projects;
    event ProjectCreated(address newAddress);
    function createProject(
        string memory _projectName, 
        address payable _projectStarter, 
        uint256 _fundingEndTime, 
        uint256 _fundTarget, 
        uint256 _projectEndTime)
        public onlyOwner {
        Project project = new Project(
            _projectName, 
            _projectStarter,
            _fundingEndTime,
            _fundTarget,
            _projectEndTime            
        );
        projects.push(project);
        emit ProjectCreated(newAddress);
    }
}