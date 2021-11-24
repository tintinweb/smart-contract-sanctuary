/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.3/contracts/utils/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.3/contracts/access/Ownable.sol



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

// File: contracts/Donation.sol



pragma solidity ^0.8.0;


/// @title Contract for donations
/// @author Marko Curuvija
contract Donation is Ownable {
    struct Campaign {
        address payable campaignOwner;
        string name;
        string description;
        uint dateGoal;
        uint priceGoal;
        uint amount;
        mapping(address => uint) donators;
    }

    uint campaignId;
    mapping(uint => Campaign) public campaigns;

    function createCampaign(address payable _campaignOwner, string memory _name, string memory _description, uint _dateGoal, uint _priceGoal) external onlyOwner {
        Campaign storage campaign = campaigns[campaignId++];
        campaign.campaignOwner = _campaignOwner;
        campaign.name = _name;
        campaign.description = _description;
        campaign.dateGoal = _dateGoal;
        campaign.priceGoal = _priceGoal;
    }

    function donate(uint _campaignId) public payable {
        campaigns[_campaignId].amount += msg.value;
        campaigns[_campaignId].donators[msg.sender] += msg.value;
    }

    function withdraw(uint _campaignId) public {
        require(msg.sender == campaigns[_campaignId].campaignOwner, "Only campaign owner can withdraw donations");
        uint valueToWithdraw = campaigns[_campaignId].amount;
        campaigns[_campaignId].amount = 0;
        (bool sent, ) = msg.sender.call{value: valueToWithdraw}("");
        require(sent, "Failed to send Ether");
    }
}