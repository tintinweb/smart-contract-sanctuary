/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: Donation.sol


pragma solidity ^0.8.0;

   // @title Create smart contract for donation platform
   // @author Djordje Dubovina
  //  @notice You can use this contract for only the most basic simulation
  //  @dev All function are implemented without side effects


contract Donation is Ownable {
    
    //event Deposit( address indexed sender, uint256 amt );
    event LogDeposit(address sender, uint amt);
    event LogRefund(address receiver, uint amt);
    
    //mapping(address => uint256) donor;
        
    struct Campaign {
        string campaignName;
        string campaignDesc;
        uint256 campaignGoal;       // in wei
        uint256 campaignDeadline;
        bool campaignCompleted;
        uint256 campaignRaised;     // in wei
 
    }
    
    uint256 numCampaigns;
    mapping (uint256 => Campaign) public campaigns;
    address nftAddress;
    mapping(address => uint) balances;
    
    uint campaignRaised = 0;
    bool isCompleted = false;

  //  @notice Create new campaigns, every campaign have to contain: campaign name, description, goal
  //  @dev Only contract owner can create new camapigns
  //  @param campaignName, campaignDesc, campaignGoal, campaignDeadline, campaignCompleted, campaignRaised
  //  @return Created camapings   
    
    function newCampaign(
        string memory _campaignName, string memory _campaignDesc, 
        uint256 _campaignDeadline, uint256 _campaignGoal) onlyOwner public returns (uint256 campaignID) {
            
            require(bytes(_campaignName).length !=0 && bytes(_campaignDesc).length !=0, "Campaign name and description can't be empty!");
            require(_campaignGoal > 0, "Goal amount have to greather than zero !");
            
            campaignID = numCampaigns +=1;
            //Campaign storage camp = campaigns[campaignID];
            //camp.campaignName = _campaignName;
            //camp.campaignDesc = _campaignDesc;
           // camp.campaignGoal = _campaignGoal;
            //camp.campaignDeadline = _campaignDeadline + block.timestamp;
            
            
            campaigns[campaignID] = Campaign(
                  _campaignName, _campaignDesc, _campaignGoal, _campaignDeadline + block.timestamp, isCompleted, campaignRaised);
        }

  //  @notice If you want to donate please can choose ID of campaign
  // @dev If a raised amount is greater than the campaign goal after the transaction, the donor gets an excess of raised amount.
  //  @param campaignID
  //  @return Created campaigns with columns: campaignName(str), campaignDesc(str), campaignGoal(int), campaignDeadline(int), campaignCompleted(bool), campaignRaised(int)

    function donatePlease(uint256 _campaignID) public payable {
        Campaign storage camp = campaigns[_campaignID];
        
        require (block.timestamp < camp.campaignDeadline, "Campaign Failed!");
        require(camp.campaignRaised < camp.campaignGoal,"Goal achieved");
        require(msg.value > 0, 'Donation sholud be greather than zero.');
        
        balances[msg.sender] += msg.value;
        emit LogDeposit(msg.sender, msg.value);
        
        camp.campaignRaised = camp.campaignRaised +=  msg.value;
        
        if (camp.campaignRaised >= camp.campaignGoal) {
            camp.campaignCompleted = true;
            uint256 _amountRequested = camp.campaignRaised - camp.campaignGoal;
            camp.campaignRaised -= _amountRequested; 
            
            require(_amountRequested > 0);
            balances[msg.sender] -= _amountRequested;
            emit LogRefund(msg.sender, _amountRequested);
            payable(msg.sender).transfer(_amountRequested);
        }
    }
    
    function ContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    }