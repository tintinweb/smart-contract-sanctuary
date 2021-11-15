// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 /$$$$$$$   /$$$$$$  /$$   /$$  /$$$$$$  /$$   /$$  /$$$$$$         /$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$$
| $$__  $$ /$$__  $$| $$$ | $$ /$$__  $$| $$$ | $$ /$$__  $$       /$$__  $$ /$$__  $$| $$  /$$/| $$_____/
| $$  \ $$| $$  \ $$| $$$$| $$| $$  \ $$| $$$$| $$| $$  \ $$      | $$  \__/| $$  \ $$| $$ /$$/ | $$      
| $$$$$$$ | $$$$$$$$| $$ $$ $$| $$$$$$$$| $$ $$ $$| $$$$$$$$      | $$      | $$$$$$$$| $$$$$/  | $$$$$   
| $$__  $$| $$__  $$| $$  $$$$| $$__  $$| $$  $$$$| $$__  $$      | $$      | $$__  $$| $$  $$  | $$__/   
| $$  \ $$| $$  | $$| $$\  $$$| $$  | $$| $$\  $$$| $$  | $$      | $$    $$| $$  | $$| $$\  $$ | $$      
| $$$$$$$/| $$  | $$| $$ \  $$| $$  | $$| $$ \  $$| $$  | $$      |  $$$$$$/| $$  | $$| $$ \  $$| $$$$$$$$
|_______/ |__/  |__/|__/  \__/|__/  |__/|__/  \__/|__/  |__/       \______/ |__/  |__/|__/  \__/|________/

This is our multisender beta for deploy Banacake only
*/                                                                                                         
                                                                                                          
                                                                                                          

import '../dependencies/Ownable.sol';
import '../dependencies/IERC20.sol';

contract MultiSender is Ownable{
    mapping(address => address) public ownerOfToken;
    address public tokenAddress;
    IERC20 token;
    mapping(address => uint256) public holdersAmount;
    mapping(address => uint256) public holdersAmountLeft;
    uint256 public timeFirstUnlock = 1631462400;
    uint256 public timeSecondUnlock = 1631484000;
    uint256 public timeThirdsUnlock = 1631505600;
    bool public isClaimable = true;

    function setClaimable(bool newState) public onlyOwner {
        isClaimable = newState;
    }

    function setTokenAddress(address newTokenAddress) public onlyOwner {
        tokenAddress = newTokenAddress;
        token = IERC20(newTokenAddress);
    }

    function addHolder(address newHolder, uint256 newAmount) public onlyOwner {
        require(holdersAmount[newHolder] == 0);
        holdersAmount[newHolder] = newAmount;
        holdersAmountLeft[newHolder] = newAmount;
    }

    function addHolders( address[] calldata newHolders,uint256[] calldata newAmount) public onlyOwner {
        for(uint256 i; i < newHolders.length;i++){
            addHolder(newHolders[i], newAmount[i]);
        }
    }

    function removeHolder(address oldHolder) public onlyOwner {
        holdersAmount[oldHolder] = 0;
        holdersAmountLeft[oldHolder] = 0;
    }

    function updateHolder(address newHolder, uint256 newAmount) public onlyOwner {
        holdersAmount[newHolder] = newAmount;
        holdersAmountLeft[newHolder] = newAmount;
    }

    function claim() public {
        require(isClaimable, 'The claim is actually offline');
        require(tokenAddress != address(0x0), 'Token isnt set');
        require(holdersAmountLeft[msg.sender] > 0);
        uint256 amountKeep = holdersAmountLeft[msg.sender];
        uint256 part = holdersAmount[msg.sender] / 4;
        if(block.timestamp > timeThirdsUnlock){
            amountKeep = 0;
        }
        else if (block.timestamp > timeSecondUnlock) {
            amountKeep = part;
        }
        else if (block.timestamp > timeFirstUnlock){
            amountKeep = part*2;
        }
        uint256 amount = holdersAmountLeft[msg.sender] - amountKeep;
        require(amount > 0);
        token.transfer(msg.sender, amount);
        holdersAmountLeft[msg.sender] = holdersAmountLeft[msg.sender] - amount;
    }

    function setTimer(uint256 first, uint256 second, uint256 third) public onlyOwner {
        timeFirstUnlock = first;
        timeSecondUnlock = second;
        timeThirdsUnlock = third;
    }

    function getTimestamp() view public returns(uint256) {
        return block.timestamp;
    }

    function withdrawAmount() public onlyOwner {
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Context.sol';

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

