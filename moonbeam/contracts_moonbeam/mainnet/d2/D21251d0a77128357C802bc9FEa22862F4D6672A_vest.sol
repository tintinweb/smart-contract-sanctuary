/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-10
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/Owner.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


pragma solidity ^0.8.0;
contract vest is Owner, ReentrancyGuard {

    struct agreement {
        uint256 duration;
        uint256 amount;
        uint256 lastClaim;
        address token;
        bool exists;
    }

    mapping (address => agreement) public agreements;

    function makeAgreement (address _recipient, uint256 _amount, uint256 _nBlocks, address _token) public isOwner {
        require(!agreements[_recipient].exists, "user already has an agreement");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        agreements[_recipient] = agreement(
            _nBlocks,
            _amount, 
            block.number, 
            _token,
            true
        );
    }

    function changeDuration (uint256 _newDuration, address _recipient) public isOwner {
        require(agreements[_recipient].exists, "agreement doesnt exist");
        agreements[_recipient].duration = _newDuration;
    }

    function addToAmount (uint256 _AmountToAdd, address _recipient) public isOwner {
        require(agreements[_recipient].exists, "agreement doesnt exist");
        IERC20(agreements[_recipient].token).transferFrom(msg.sender, address(this), _AmountToAdd);
        agreements[_recipient].amount = agreements[_recipient].amount + _AmountToAdd;
    }

    function removeFromAmount (uint256 _AmountToRemove, address _recipient) public isOwner {
        require(agreements[_recipient].amount >= _AmountToRemove, "cannot remove more than user is recieving");
        agreements[_recipient].amount = agreements[_recipient].amount - _AmountToRemove;
        IERC20(agreements[_recipient].token).transfer(msg.sender, _AmountToRemove);
    }

    function topUpContract (address _token, uint256 _amount) public isOwner {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function claim () public nonReentrant {
        require (agreements[msg.sender].exists, "You have no agreement");
        require (agreements[msg.sender].amount <= IERC20(agreements[msg.sender].token).balanceOf(address(this)), "contract needs to be topped up");
        uint256 _lastClaim = agreements[msg.sender].lastClaim;
        uint256 _blocksSinceLast = block.number - _lastClaim;
        uint256 _duration = agreements[msg.sender].duration;
        if (_blocksSinceLast >= _duration) {
            uint256 _claimable = agreements[msg.sender].amount;
            agreements[msg.sender].duration = 0;
            agreements[msg.sender].amount = 0;
            agreements[msg.sender].exists = false;
            agreements[msg.sender].lastClaim = block.number;
            IERC20(agreements[msg.sender].token).transfer(msg.sender, _claimable);
        } else {
            uint256 _percentVested = ( _blocksSinceLast * 1000000000000000000 ) / _duration; 
            uint256 _claimable = (agreements[msg.sender].amount * _percentVested) / 1000000000000000000; 
            agreements[msg.sender].duration = agreements[msg.sender].duration - _blocksSinceLast;
            agreements[msg.sender].amount = agreements[msg.sender].amount - _claimable;
            agreements[msg.sender].lastClaim = block.number;
            IERC20(agreements[msg.sender].token).transfer(msg.sender, _claimable);
        }
    }

}