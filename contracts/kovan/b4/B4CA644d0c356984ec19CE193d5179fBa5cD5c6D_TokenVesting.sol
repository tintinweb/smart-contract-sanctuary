// SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBEP20.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is Ownable, ReentrancyGuard{
    //using SafeERC20 for IERC20;

    struct LockSchedule{
        address  beneficiary;
        // cliff blockNumber end
        uint256  cliff;
        // periods of weekBlocks after cliff
        uint256  numberOfPeriods;
        // end block of vesting (3 months = 3*30*24*3600 e.g.)
        uint256  vestEnd;
        // amount deposited initially for this address
        uint256 amount;
        // amount of tokens released for this address
        uint256  released;
        //is this a beneficiary or custodial wallet
        bool custodian;
    }

    // address of the BEP20 token
    IBEP20 private _token;
    address AONAddress;
    uint constant monthBlocks = 30*24*60*4;
    uint constant weekBlocks = 7*24*60*4;
    mapping(address => LockSchedule) private LockSchedules;
    uint256 private LockSchedulesTotalAmount;
    uint256 internal totalUnreleasedVested;//total amount in vesting that is not released yet

    event Released(uint256 amount, address _recipient);

    /*
     * @dev Creates a vesting contract.
     * @param token_ address of the BEP20 token contract
     */
    constructor() {
        /*require(tokenAddress != address(0));
        _token = IBEP20(tokenAddress);*/
    }

    receive() external payable {}

    fallback() external payable {}

    /**
    * @dev Returns the address of the ERC20 token managed by the vesting contract.
    */
    function getToken() external view returns(address){
        return address(_token);
    }

    /**
    * @notice Creates a new vesting schedule for a beneficiary.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param _cliff block number of cliff end
    * @param _numberOfPeriods numberOfPeriods within vesting period
    * @param _amount total amount of tokens to be released at the end of the vesting
    * @param _custodian is account custodial wallet or not
    */
    function createLockSchedule(address _beneficiary, uint256 _cliff, uint256 _numberOfPeriods, uint256 _amount, bool _custodian)
        public {
        require(_msgSender() == AONAddress, "TokenVesting: must be called from AONToken Contract");
        require(_token.balanceOf(address(this)) >= totalUnreleasedVested + _amount, "TokenVesting: insufficient tokens");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_numberOfPeriods > 0, "TokenVesting: Periods must be > 0");
        LockSchedules[_beneficiary] = LockSchedule(
            _beneficiary,
            block.number + _cliff*weekBlocks,
            block.number + (_cliff+_numberOfPeriods)*weekBlocks,
            _numberOfPeriods,
            _amount,
            0, 
            _custodian
        );
        totalUnreleasedVested += _amount;
    }

    /**
    * @notice owner can withdraw amount if not accounted for by vesting.
    * @param _amount the amount to withdraw
    */
    function withdraw(uint256 _amount) public nonReentrant onlyOwner{
        require(getWithdrawableAmount() >= _amount, "TokenVesting: insufficient funds");
        (bool success, ) = AONAddress.call(abi.encodeWithSelector(bytes4(keccak256("transferFromVestingContract(address,uint256)")),_msgSender(), _amount));
        require(success, "withdraw failed");
        //_token.safeTransfer(owner(), amount);
    }

    /**
    * @notice Release amount of tokens which are vested.
    * @param _to beneficiary address
    * @param _amount the amount to release
    */
    function release(address _to,  uint256 _amount) public nonReentrant {
        require(_to != address(0), "can't send to address 0");
        LockSchedule storage lockSchedule = LockSchedules[_to];
        require(_to == lockSchedule.beneficiary, "address needs to be beneficiary");
        bool isBeneficiary = (_msgSender() == lockSchedule.beneficiary);
        bool isOwner = (_msgSender() == owner());
        require(isBeneficiary || isOwner, "TokenVesting: only beneficiary or owner can release tokens");
        uint256 vestedAmount = getBeneficiaryEligibleReleaseAmount(_to);
        require(vestedAmount >= _amount, "TokenVesting: cannot release tokens, not enough vested tokens");
        lockSchedule.released += _amount;
        //address payable beneficiaryPayable = payable(lockSchedule.beneficiary);
        totalUnreleasedVested -= _amount;
        //_token.safeTransfer(beneficiaryPayable, amount);
        (bool success, ) = AONAddress.call(abi.encodeWithSelector(bytes4(keccak256("transferFromVestingContract(address,uint256)")),_to, _amount));
        require(success, "release failed");
    }

    /**
    * @notice Returns estimated times for block releases using #blocks*15 seconds for timestamps.
    * @return the estimated unix timestamps
    */
    function getVestingTimeEstimates(address _beneficiary) public view returns(uint[] memory){
        LockSchedule memory l = LockSchedules[_beneficiary];
        require(l.beneficiary != address(0), "Schedule does not exist for this address");
        if(block.number<=l.cliff){
            uint[] memory timeStamps = new uint[](l.numberOfPeriods+1);
            timeStamps[0] = block.timestamp + 15*(l.cliff-block.number);
            for(uint i = 1; i< l.numberOfPeriods+1; i++){
                timeStamps[i] = timeStamps[i-1] + weekBlocks*15;
            } 
            return timeStamps;
        }
        else if(block.number >= l.vestEnd){
            uint[] memory timeStamps = new uint[](0);
            return timeStamps;
        }
        else{
            uint periodsAfterCliff = (block.number - l.cliff)/weekBlocks;
            uint[] memory timeStamps = new uint[](l.numberOfPeriods-periodsAfterCliff+1);
            timeStamps[0] = block.timestamp + (l.cliff + (periodsAfterCliff + 1)*weekBlocks - block.number)*15;
            for (uint j =0; j<timeStamps.length; j++){
                timeStamps[j] += timeStamps[j-1] + weekBlocks*15;
            }
            return timeStamps;
        }
    }

    /**
    * @notice Returns total amount eligible for release.
    * @return the amount available for release.
    */
    function getBeneficiaryEligibleReleaseAmount(address _beneficiary) public view returns(uint256){
        LockSchedule memory currentSchedule = LockSchedules[_beneficiary];
        require(currentSchedule.beneficiary != address(0), "Schedule does not exist for this address");
        (uint _cliff, uint _numberOfPeriods, uint _vestEnd, uint _amount, uint _released) = 
        (currentSchedule.cliff, currentSchedule.numberOfPeriods, currentSchedule.vestEnd, currentSchedule.amount, currentSchedule.released);
        if(block.number <= _cliff){return 0;}
        else if(block.number >= _vestEnd){return _amount - _released ;}
        else{
            uint periodsAfterCliff = (block.number - _cliff)/weekBlocks;
            return ((periodsAfterCliff*_amount)/_numberOfPeriods) - _released;
        }
    }

    /**
    * @dev Returns the amount of tokens that can be withdrawn by the owner.
    * @return the amount of tokens
    */
    function getWithdrawableAmount() public view returns(uint256){
        return _token.balanceOf(address(this)) - totalUnreleasedVested;
    }

    /**
    * @dev Returns the last vesting schedule for a given holder address.
    */
    function getBlockLastPeriod(address _beneficiary) public view returns(uint _lastBlock){
        LockSchedule memory l = LockSchedules[_beneficiary];
        return l.vestEnd;
    }

    function getNextBlockRelease(address _beneficiary) public view returns(uint _nextBlock){
        LockSchedule memory l = LockSchedules[_beneficiary];
        if(l.cliff == 0 || block.number<=l.cliff){
            return l.cliff;
        }
        else if(block.number >= l.vestEnd){
            return l.vestEnd;
        }
        else{
            uint periodsAfterCliff = (block.number - l.cliff)/weekBlocks;
            if(periodsAfterCliff * weekBlocks == block.number - l.cliff){
                return block.number;//hit right on a block
            }
            else{
            return l.cliff + (periodsAfterCliff+1)*weekBlocks;
            }
        }
    }

    function setAONAddress (address _AONAddress) external onlyOwner{
        require(_AONAddress != address(0));
        AONAddress = _AONAddress;
        _token = IBEP20(_AONAddress);
    }

}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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