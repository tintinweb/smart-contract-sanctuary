/**
 *Submitted for verification at polygonscan.com on 2021-08-30
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File contracts/cards/IUnlockRegistry.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IUnlockRegistry {
    
    event LiquidityContribution(
        address indexed from,
        uint256 indexed tokenId,
        uint256 amount
    );
    
    struct LiquidityInfo {
        uint256 total;
        address[] senders;
        mapping(address => uint256) index;
        mapping(address => uint256) contributions;
    }

    function getContributorsFor(uint256 _tokenId) external view returns (
        address[] memory senders
    );

    function getSenderContributionFor(address _sender, uint256 _tokenId) external view returns (
        uint256 contribution
    );

    function clearContributorsFor(uint256 _tokenId) external;

    function addContribution(
        uint256 _tokenId, 
        address _sender, 
        uint256 _amount,
        uint256 _tokenIdMaxAmount
    ) 
        external returns (uint256 refund, bool contributionCompleted);
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/commons/OperationManaged.sol


pragma solidity ^0.8.0;

contract OperationManaged is Ownable {

    constructor() Ownable() {}

    // Manager allowed address
    address private operationManager;

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyOperationManager() {
        require(msg.sender == operationManager, "caller is not allowed");
        _;
    }

    /**
     * @dev Sets the operation manager of the contract.
     * @param _manager address
     */
    function setOperationManager(address _manager) external onlyOwner {
        operationManager = _manager;
    }
}


// File contracts/cards/UnlockRegistry.sol


pragma solidity ^0.8.0;


contract UnlockRegistry is OperationManaged, IUnlockRegistry {
    
    // mapping for liquidity contributors
    mapping(uint256 => LiquidityInfo) private liquidityContributors;

    function _removeFromMapping(
        LiquidityInfo storage t, 
        address _sender
    ) 
        private 
    {
        // remove from array 
        uint256 index = t.index[_sender];
        
        // remove last and place it in current deleted item
        address lastItem = t.senders[t.senders.length - 1];

        // set last item in place of deleted
        t.senders[index] = lastItem;
        t.senders.pop();

        // update index map
        t.index[lastItem] = index; 
        
        // delete removed address from index map
        delete t.index[_msgSender()];

        // remove previous contribution
        t.total -= t.contributions[_sender];
    }

    function _addToMapping(
        LiquidityInfo storage t,
        address _sender, 
        uint256 _amount
    ) 
        private
    {
        // save contributor address 
        t.contributions[_sender] = _amount;
        t.index[_sender] = t.senders.length;
        
        // add contributor to senders list
        t.senders.push(_sender);

        // add to total 
        t.total += _amount;
    }

    function getContributorsFor(uint256 _tokenId) 
        external 
        view
        override 
        returns (address[] memory) 
    {    
        return liquidityContributors[_tokenId].senders;
    }
    
    function getSenderContributionFor(address _sender, uint256 _tokenId) 
        external 
        view
        override 
        returns (uint256 contribution) 
    {
        return liquidityContributors[_tokenId].contributions[_sender];  
    }

    function clearContributorsFor(uint256 _tokenId) external override onlyOperationManager {
        delete liquidityContributors[_tokenId];
    }

    /**
     * Adds contribution to unlock
     * @param _tokenId tokenId to liquidate
     * @param _sender sender of the contribution
     * @param _amount liquidity provided to contribution
     * @param _tokenIdMaxAmount min amount fot the asset thats needed to unlock
     */
    function addContribution(
        uint256 _tokenId, 
        address _sender, 
        uint256 _amount,
        uint256 _tokenIdMaxAmount
    ) 
        external override onlyOperationManager returns (uint256, bool) 
    {
        LiquidityInfo storage t = liquidityContributors[_tokenId];

        // refund prev contribution
        uint256 refund = t.contributions[_sender];
        
        if (refund > 0) {
            _removeFromMapping(t, _sender);
        }

        // checks if total amount > max allowed and refund 
        uint256 postContribution = t.total + _amount;

        if (postContribution > _tokenIdMaxAmount) {
            refund += postContribution - _tokenIdMaxAmount;
            _amount = _tokenIdMaxAmount - t.total;
        }

        _addToMapping(t, _sender, _amount);

        emit LiquidityContribution(_sender, _tokenId, _amount);

        // return if contribution is completed
        return (refund, t.total == _tokenIdMaxAmount);
    }
}