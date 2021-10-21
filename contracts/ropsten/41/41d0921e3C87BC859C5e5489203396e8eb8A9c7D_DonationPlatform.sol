/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

//SPDX-License-Identifier:MIT
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

// File: contracts/Donation2.sol


pragma solidity ^0.8.0;
/// @title DonationPlatform 
/// @author Aleksandar 
/// @notice Can only be used for the most basic simulation
/// @dev So far didnt spot any errors


contract DonationPlatform is Ownable {
    
    
    /// @notice Grouping campaign attributes
    struct Campaign {
        uint256 id;
        string name;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 raised;
        bool isComplete;
    }
    
    
    /// @notice Campaign count so that the index of campaigns starts with 1
    uint256 campaignCount = 0;
    mapping (uint => Campaign) public campaigns;
        
    
    /// @notice addingCampaign and storing it
    function addCampaign(
        string memory name, string memory description,
        uint goal, uint deadline
        )
        public onlyOwner {
        uint raised = 0;
        bool isComplete = false;
        campaignCount +=1;
        campaigns[campaignCount] = Campaign(campaignCount, name, description, goal,deadline + block.timestamp, raised, isComplete);
    }
    
    
    /// @notice Donate function if the donations exceed goal it returns the extra funds to the sender
    function donate(uint id) payable public {
        require(block.timestamp < campaigns[id].deadline, "Campaign is over!");
        require(!(campaigns[id].isComplete), "The goal was already achieved!");

        campaigns[id].raised += msg.value;

        if (campaigns[id].raised + msg.value > campaigns[id].goal) {
            uint _amount = campaigns[id].raised - campaigns[id].goal;
            campaigns[id].raised -= _amount;
            campaigns[id].isComplete = true;
            (bool success, ) = msg.sender.call{value:_amount}("");
        require(success, "Transfer failed.");
        } else if (campaigns[id].raised == campaigns[id].goal) campaigns[id].isComplete = true;
    }
}