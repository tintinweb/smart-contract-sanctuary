/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT;

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

// File: Donation2.sol


pragma solidity 0.8.7;



contract Donacija2 is Ownable {
    
    address public immutable ADMIN;
    
    struct Campaign {
        string campaignName;
        string campaignDescription;
        uint campaignDuration;
        uint campaignGoal;
        uint campaignRaised;
        bool campaignCompleted;
    }
    
    Campaign [] public campaign;  
    
    constructor() {
        ADMIN = payable(msg.sender);
    }
    
    modifier onlyAdmin {
        require(msg.sender == ADMIN, "Not admin");
        _;
    }
    
    function create(
        string memory _campaignName, string memory _campaignDescription, 
        uint _campaignDuration, uint _campaignGoal) 
        public onlyAdmin {
            
        uint campaignRaised = 0;
        bool campaignCompleted = false;
        
        campaign.push(Campaign({campaignName: _campaignName, campaignDescription: _campaignDescription, 
        campaignGoal: _campaignGoal, campaignDuration: _campaignDuration + block.timestamp, campaignRaised:campaignRaised,
        campaignCompleted: campaignCompleted
            
        }));
    }    
    
    
    function donate(uint _id) public payable {
       // require(block.timestamp > campaign[_id].campaignDuration,"Campaign Done !");
        require(campaign[_id].campaignRaised < campaign[_id].campaignGoal,"Goal achieved");
        
        if (campaign[_id].campaignRaised == campaign[_id].campaignGoal) campaign[_id].campaignCompleted = true;
        else if (campaign[_id].campaignRaised > campaign[_id].campaignGoal) {
            
            uint _amount = campaign[_id].campaignRaised - campaign[_id].campaignGoal;
            campaign[_id].campaignRaised -= _amount;
            campaign[_id].campaignCompleted = true;
            payable(msg.sender).call{value: _amount};
            
        }
    }
    
}