// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/Ownable.sol";

interface token {
    function transfer(address to, uint256 amout) external;
}

contract Presell is Ownable {
    
    address payable beneficiary;
    address payable burnAddress;
    
    uint256 public presellGoal;
    uint256 public totalPresell;
    uint256 public tokenPrice;
    uint256 public deadline;
    uint256 public lastSellReceive;
    uint256 public tokenBalanceinPresell;
    uint256 public claimTime;
    uint256 public startPresell;
    
    bool public tokenBalanceSet;
    bool public presellClosed;
    
    token public tokenReward;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) balanceOfToken;
    
    
    constructor (uint _startPresell,uint256 goalAmountInBROOM, uint256 presellDuration, uint256 priceOfEachRewardToken, address rewardTokenAddress, address payable _beneficiary ,address payable _burnAddress) {
        beneficiary = _beneficiary;
        presellGoal = goalAmountInBROOM * 1e18;
        totalPresell = 0;
        tokenBalanceSet = false;
        startPresell = _startPresell;
        deadline = startPresell + presellDuration * 1 days;
        tokenPrice = priceOfEachRewardToken; //500000000000000000 initial Start Price
        tokenReward = token(rewardTokenAddress);
        presellClosed = false;
        burnAddress = _burnAddress;
    }
    
    function updatePriceToken(uint priceUpdate) public onlyOwner {
        tokenPrice = priceUpdate;
    }
    
    function getBalanceToken(address _address) public view returns(uint256){
        return balanceOfToken[_address];
    }

    function transfer(uint256 _value) external payable onlyOwner {
        beneficiary.transfer(_value);
    }
    
    function setBalanceToken(uint256 _setBalanceToken) public onlyOwner {
        require(!tokenBalanceSet);
        tokenBalanceinPresell = _setBalanceToken * 1 ether;
        tokenBalanceSet = true;
    }
    

    modifier afterDeadline() {
        if (block.timestamp >= deadline) {
            presellClosed = true ;
            claimTime = deadline + 1 days;
        }
        if (totalPresell >= 15000 * 1 ether && totalPresell <= 25000 * 1 ether) {
            updatePriceToken(750000000000000000);
        }
        if (totalPresell >= 25000 * 1 ether) {
            updatePriceToken(1000000000000000000);
        }

        _;
    }

    function checkGoalReached() internal afterDeadline {
        if (totalPresell >= presellGoal) {
            presellClosed = true;
        }
    }

    function burnTokenNotSell() public onlyOwner {
        require(presellClosed);
        tokenReward.transfer(burnAddress, tokenBalanceinPresell);
    }

    function sendTokenSale() public afterDeadline {
        require(presellClosed);
        require(block.timestamp >= claimTime);
        tokenReward.transfer(msg.sender, balanceOfToken[msg.sender]);
    }
    
    
    fallback () external payable {
        require(!presellClosed);
        require(block.timestamp >= startPresell);
        require(totalPresell + (msg.value / tokenPrice) <= presellGoal == true);
        require(msg.value >= 1 ether);
        require(msg.value + balanceOf[msg.sender] <= (200 * 1e18) == true);
        uint256 amout = msg.value;
        balanceOf[msg.sender] += amout;
        totalPresell += (msg.value / tokenPrice) * 1 ether;
        balanceOfToken[msg.sender] += (msg.value / tokenPrice) * 1 ether;
        tokenBalanceinPresell -= (msg.value / tokenPrice) * 1 ether;
        lastSellReceive = msg.value;
        beneficiary.transfer(address(this).balance);
        checkGoalReached();
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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