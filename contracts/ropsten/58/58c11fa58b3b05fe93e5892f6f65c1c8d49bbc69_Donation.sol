/**
 *Submitted for verification at Etherscan.io on 2021-10-27
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

// File: Donation1.1.sol


pragma solidity ^0.8.0;



contract Donation is Ownable {
    
    address public immutable ADMIN;
    
    struct Campaign {               // grouped attributes
        string name;
        string description;
        uint duration;
        uint goal;
        uint raised;
        bool completed;
    }
    
    
    mapping(uint => Campaign) public campaigns;        //mapping from uint to Campaign attributes (id to Campaign)
    uint256 campaignIndex = 0;
    
    constructor() {
        ADMIN = payable(msg.sender);        
    }
    
    modifier onlyAdmin {
        require(msg.sender == ADMIN, "Only admin can call this function");
        _;
    }
    
    
    // Create campaign (only Admin can create campaigns)
    function createCampaign(
        string memory _name, string memory _description, 
        uint _duration, uint _goal
        ) public onlyAdmin {
            
            bool completed = false;
            uint raised = 0;
            campaignIndex += 1;
            
            campaigns[campaignIndex] = Campaign(_name, _description, _duration + block.timestamp, _goal, raised, completed);
            
        }
    
    
    //Function for donation 
    function donate(uint _index) public payable {
        
        require (block.timestamp < campaigns[_index].duration, "Campaign Failed!");
        require(campaigns[_index].raised < campaigns[_index].goal,"Goal achieved");
        
        campaigns[_index].raised += msg.value;
        
        if (campaigns[_index].raised + msg.value > campaigns[_index].goal) {     
            
            uint _amount =  campaigns[_index].raised - campaigns[_index].goal;
            campaigns[_index].raised -= _amount;
            campaigns[_index].completed = true;
            payable(msg.sender).call{value: _amount};
        } else if (campaigns[_index].raised == campaigns[_index].goal) campaigns[_index].completed = true;
        
    }

}