// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.11;
import "Ownable.sol";

contract WLAllocation is Ownable {
    struct ERC20Allocation {
        uint256 allocation;  // user's reserved allocation
        uint256 used;        // 
    }

    
    mapping(address => bool) public trustedOperators;
    
    // mpp from user to tokenaddress to allocation
    mapping(address => mapping(address => ERC20Allocation)) public userAllocation;

    constructor () {
        trustedOperators[msg.sender] = true;
    }

    function increaseAllocation(address _user, address _erc20, uint256 _increment) public {
        require(trustedOperators[msg.sender], "Trusted operators only");
        userAllocation[_user][_erc20].allocation += _increment;
    }

    function decreaseAllocation(address _user, address _erc20, uint256 _decrement) public {
        require(trustedOperators[msg.sender], "Trusted operators only");
        require(
            userAllocation[_user][_erc20].allocation - _decrement >= userAllocation[_user][_erc20].used,
            "Cant set less then used"
        );
        userAllocation[_user][_erc20].allocation -= _decrement;
    }

    function increaseAllocationBatch(
        address[] calldata _users, 
        address _erc20, 
        uint256[] calldata _increments
    ) external 
    {
        require(trustedOperators[msg.sender], "Trusted operators only");
        require(_users.length == _increments.length, "Non equal arrays");
        for (uint256 i = 0; i < _users.length; i ++){
            userAllocation[_users[i]][_erc20].allocation += _increments[i];
        }

    }

    function decreaseAllocationBatch(
        address[] calldata _users, 
        address _erc20, 
        uint256[] calldata _decrements
    ) external 
    {
        require(trustedOperators[msg.sender], "Trusted operators only");
        require(_users.length == _decrements.length, "Non equal arrays");
        for (uint256 i = 0; i < _users.length; i ++){
            require(
                userAllocation[_users[i]][_erc20].allocation - _decrements[i] >= userAllocation[_users[i]][_erc20].used,
                "Cant set less then used"
            );
            userAllocation[_users[i]][_erc20].allocation -= _decrements[i];
        }
    }

    function spendAllocation(address _user, address _erc20, uint256 _amount) public returns (bool){
        require(trustedOperators[msg.sender], "Trusted operators only");
        require(
            userAllocation[_user][_erc20].used + _amount <= userAllocation[_user][_erc20].allocation,
            "Cant spend more then allocated"
        );
        userAllocation[_user][_erc20].used += _amount;
    }

    function availableAllocation(address _user, address _erc20) public view returns (uint256 allocation) {
        allocation = userAllocation[_user][_erc20].allocation - userAllocation[_user][_erc20].used;
    } 
    ////////////////////////////////////////////////
    //   Admin functions                         ///
    ////////////////////////////////////////////////
    function setOperator(address _operator, bool _isValid) external {
        trustedOperators[_operator] = _isValid;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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