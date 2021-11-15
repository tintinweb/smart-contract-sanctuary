// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAvatarArtLaunchpad.sol";
import ".././core/Runnable.sol";

pragma solidity ^0.8.0;

/**
* @dev Contract allows whitelisted users to join IDO with specific project
 */
contract AvatarArtLaunchpad is Runnable, IAvatarArtLaunchpad{
    struct Round{
        uint256 startTime;
        uint256 endTime;
        uint256 maxPaymentAmount;
        uint256 lockedPercent;                  //Multipled by MULTIPLIER
        uint256 lockedDuration;                 //Unit: days
    }

    struct UnlockedToken{
        uint256 time;
        uint256 quantity;
        bool unlocked;
    }

    uint256 constant public MULTIPLIER = 1000;

    //Total IDO allocation
    uint256 public _allocation;

    //Token price compared with payment token: 1 project token = `_tokenPrice` payment token / MULTIPLIER
    uint256 public _tokenPrice;                 //Multipled by MULTIPLIER

    //Project token address
    address public _tokenAddress;

    //Payment token address
    address public _paymentTokenAddress;

    //The remaining allocation for IDO
    uint256 public _remainingAllocation;

    //IDO round list
    Round[] public _rounds;

    //Specify addresses that can buy in specific round
    mapping(uint256 => address[]) public _roundAddresses;

    //Specify payment amount has been paid to join IDO in specific round of specific account
    //Mapping: account => round => payment amount
    mapping(address => mapping(uint256 => uint256)) public _paidAmounts;

    //Specify unlocked tokens that an account owns
    //Mapping: account => list of UnlockedToken
    mapping(address => UnlockedToken[]) public _unlockedTokens;

    /**
    * @dev Constructor: Initialize properties
    * @param allocation Total of token quantity is used for IDO
    * @param tokenPrice Token price for payment token. 1 project token = `tokenPrice` / MULTIPLIER payment token
    * @param tokenAddress Project token address
    * @param paymentTokenAddress Token address that is used to buy project token
    */
    constructor(
        uint256 allocation,
        uint256 tokenPrice,
        address tokenAddress, 
        address paymentTokenAddress){
            _allocation = allocation;
            _remainingAllocation = allocation;
            _tokenPrice = tokenPrice;
            _tokenAddress = tokenAddress;
            _paymentTokenAddress = paymentTokenAddress;
    }

    /**
    * @dev Get current round
    */
    function getCurrentRound() public view returns(bool, uint256, Round memory){
        for(uint256 index = 0; index < _rounds.length; index++){
            Round memory round = _rounds[index];
            if(round.startTime <= block.timestamp && round.endTime >= block.timestamp){
                return (true, index, round);
            }
        }

        return (false, 0, Round(0, 0, 0, 0, 0));
    }

    /**
    * @dev Add IDO rounds
    */
    function addRounds(
        uint256[] memory startTimes, 
        uint256[] memory endTimes, 
        uint256[] memory maxPaymentAmounts, 
        uint256[] memory lockedPercents, 
        uint256[] memory lockedDurations) external onlyOwner{
            require(startTimes.length > 0, "addresses is empty");
            require(startTimes.length ==  endTimes.length, "Invalid argument endTimes");
            require(startTimes.length ==  maxPaymentAmounts.length, "Invalid argument maxPaymentAmounts");
            require(startTimes.length ==  lockedPercents.length, "Invalid argument lockedPercents");
            require(startTimes.length ==  lockedDurations.length, "Invalid argument lockedDurations");

            for(uint256 index = 0; index < startTimes.length; index++){
                uint256 startTime = startTimes[index];
                require(startTime > block.number, "Invalid start block");

                uint256 endTime = endTimes[index];
                require(endTime > startTime, "Invalid end block");

                _rounds.push(Round({
                    startTime: startTime,
                    endTime: endTime,
                    maxPaymentAmount: maxPaymentAmounts[index],
                    lockedPercent: lockedPercents[index],
                    lockedDuration: lockedDurations[index]
                }));
            }
    }

    /**
    * @dev Remove specific round by `roundIndex`
    */
    function removeRound(uint256 roundIndex) external onlyOwner{
        delete _rounds[roundIndex];
    }

    /**
    * @dev Add addresses to join specific round by `roundIndexs` and `accounts`
    */
    function addRoundAddresses(uint256[] memory roundIndexs, address[] memory accounts) external onlyOwner{
        require(roundIndexs.length > 0, "addresses is empty");
        require(roundIndexs.length ==  accounts.length, "Invalid argument");
        for(uint256 index = 0; index < accounts.length; index++){
            uint256 roundIndex = roundIndexs[index];
            address account = accounts[index];
            (bool existed,) = isCanBuyInRound(roundIndex, account);
            if(!existed)
                _roundAddresses[roundIndex].push(account);
        }
    }

    /**
    * @dev Remove addresses to join specific round by `roundIndexs` and `accounts`
    */
    function removeRoundAddresses(uint256[] memory roundIndexs, address[] memory accounts) external onlyOwner{
        require(roundIndexs.length > 0, "addresses is empty");
        require(roundIndexs.length ==  accounts.length, "Invalid argument");
        for(uint256 index = 0; index < accounts.length; index++){
            uint256 roundIndex = roundIndexs[index];
            address account = accounts[index];
            (bool existed, uint256 accountIndex) = isCanBuyInRound(roundIndex, account);
            if(existed)
                delete _roundAddresses[roundIndex][accountIndex];
        }
    }

    /**
    * @dev Remove all allowed addresses to join specific round by `roundIndex`
    */
    function resetRoundAddress(uint256 roundIndex) external onlyOwner{
        for(uint256 index = 0; index < _roundAddresses[roundIndex].length; index++){
            delete _roundAddresses[roundIndex][index];
        }
    }

    /**
    * @dev See {IAvatarArtLaunchpad.join}
    */
    function join(uint256 paymentAmount) external override isRunning returns(bool){
        //Validate requirements
        require(paymentAmount > 0, "paymentAmount is zero");

        //Calculate token and locked token
        uint256 tokenQuantity = paymentAmount / _tokenPrice * MULTIPLIER;
        require(tokenQuantity > 0);
        require(_remainingAllocation >= tokenQuantity, "Not enough token");
        
        (bool existed, uint256 roundIndex, Round memory round) = getCurrentRound();
        require(existed, "No round is running");
        (bool canBuy,) = isCanBuyInRound(roundIndex, _msgSender());
        require(canBuy, "You can not buy in this round");

        if(round.maxPaymentAmount > 0){
            require(
                _paidAmounts[_msgSender()][roundIndex] + paymentAmount <= round.maxPaymentAmount,
                 "Max can buy");
        }

        uint256 lockedQuantity = 0;
        if(round.lockedPercent > 0){
            lockedQuantity = tokenQuantity * round.lockedPercent / MULTIPLIER / 100;
            require(lockedQuantity > 0, "Locked quantity is zero");
            _unlockedTokens[_msgSender()].push(UnlockedToken(round.endTime + round.lockedDuration * 1 days, lockedQuantity, false));
        }

        IERC20(_paymentTokenAddress).transferFrom(_msgSender(), address(this), paymentAmount);

        uint256 availableQuantity = tokenQuantity - lockedQuantity;
        if(availableQuantity > 0)
            _unlockedTokens[_msgSender()].push(UnlockedToken(round.endTime, availableQuantity, false));

        _remainingAllocation -= tokenQuantity;
        _paidAmounts[_msgSender()][roundIndex] += paymentAmount;

        emit Joined(roundIndex, _msgSender(), tokenQuantity, _now());
        return true;
    }

    /**
    * @dev See {IAvatarArtLaunchpad.claim}
    */
    function claim() external override isRunning returns(bool){
        uint256 result = 0;
        UnlockedToken[] storage unlockedTokens = _unlockedTokens[_msgSender()];
        for(uint256 unlockTokenIndex = 0; unlockTokenIndex < unlockedTokens.length; unlockTokenIndex++){
            UnlockedToken storage unlockedToken = unlockedTokens[unlockTokenIndex];
            if(unlockedToken.time >= _now() && !unlockedToken.unlocked){
                result += unlockedToken.quantity;
                unlockedToken.unlocked = true;
            }
        }

        if(result > 0){
            IERC20(_paymentTokenAddress).transfer(_msgSender(), result);
            emit Claimed(_msgSender(), result, _now());
        }

        return true;
    }

    /**
    * @dev Get quantity of token can be claimed by specific `account` 
    */
    function getClaimableAmount(address account) external view returns(uint256){
        uint256 result = 0;
        UnlockedToken[] memory unlockedTokens = _unlockedTokens[account];
        for(uint256 unlockTokenIndex = 0; unlockTokenIndex < unlockedTokens.length; unlockTokenIndex++){
            UnlockedToken memory unlockedToken = unlockedTokens[unlockTokenIndex];
            if(unlockedToken.time >= _now() && !unlockedToken.unlocked)
                result += unlockedToken.quantity;
        }

        return result;
    }

    /**
    * @dev Withdrawal all specific token by `tokenAddress` from contract to `receipent`
    */
    function withdrawToken(address tokenAddress, address receipent) external onlyOwner returns(bool){
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(tokenAddress);
        require(balance > 0, "Zero balance");
        token.transfer(receipent, balance);
        return true;
    }

    /**
    * @dev Check whether `account` can join in `roundIndex`
    */
    function isCanBuyInRound(uint256 roundIndex, address account) public view returns(bool, uint256){
        address[] memory accounts = _roundAddresses[roundIndex];
        if(accounts.length == 0) return (false, 0);

        for(uint256 index = 0; index < accounts.length; index++){
            if(accounts[index] == account)
                return (true, index);
        }

        return (false, 0);
    }

    event Joined(uint256 roundIndex, address account, uint256 quantity, uint256 time);
    event Claimed(address account, uint256 quantity, uint256 time);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAvatarArtLaunchpad{
    /**
    * @dev User join to IDO with specific project and pay `paymentAmount` to buy project token
    * @param paymentAmount Payment token amount used to buy project token
    */
    function join(uint256 paymentAmount) external returns(bool);

    /**
    * @dev User claims project token when IDO ends
    */
    function claim() external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AvatarArtContext is Context {
    function _now() internal view returns(uint){
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AvatarArtContext.sol";

abstract contract Ownable is AvatarArtContext {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Runnable is Ownable {
    
    modifier isRunning{
        require(_isRunning, "Contract is paused");
        _;
    }
    
    bool internal _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunningStatus() external onlyOwner{
        _isRunning = !_isRunning;
    }

    function getRunningStatus() external view returns(bool){
        return _isRunning;
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

