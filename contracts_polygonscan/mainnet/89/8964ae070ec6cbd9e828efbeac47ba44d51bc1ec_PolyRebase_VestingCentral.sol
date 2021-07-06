/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT

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


/**
 * @title Controllers
 * @dev admin only access restriction, extends OpenZeppelin Ownable.
 */
contract Controllers is Ownable{

    // Contract controllers
    address private _admin;

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        address msgSender = _msgSender();
        _admin = msgSender;
        emit NewAdmin(address(0), msgSender);
    }

    /**
     * @dev modifier for admin only functions.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "admin only!");
        _;
    }

    /**
     * @dev modifier for owner or admin only functions.
     */
    modifier onlyControllers() {
        require((owner() == _msgSender()) || (admin() == _msgSender()), "controller only!");
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Assigns new admin.
     * @param _newAdmin address of new admin
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        // Check for non 0 address
        require(_newAdmin != address(0), "admin can not be zero address");
        emit NewAdmin(_admin, _newAdmin);
        _admin = _newAdmin;
    }
}

/**
 * @title PolyRebase_VestingCentral
 * @dev Simple vesting scheme with staircase release schedule & multiple member participation.
 */
contract PolyRebase_VestingCentral is Controllers {

    // VestingCentral configs.
    address public vToken;
    bool public vDissolvable;
    bool public vActive;
    uint public vStart;
    uint public vEnd;
    uint public vPeriod;
    uint public vInstallments;
    uint public vReleased;
    uint public vMembers;
    uint public vSharesTotal;

    // Member config
    struct mConfig {
        address payable account;
        uint shares;
    }

    // member configs of all participating members
    mConfig[] private mConfigs;

    // Vesting Events.
    event Initialized(uint start, uint end, uint period);
    event MemberAdded(address account, uint shares);
    event MemberRemoved(address account);
    event Released(uint amount, uint members);
    event Locked(uint timestamp, uint end);
    event Dissolved(address account, uint returned);

    /**
     * @dev Constructor initialization.
     */
    constructor() {
        vActive = false;
    }

    /**
     * @dev Initialize vesting contract.
     * @param _vToken vesting funds token address
     * @param _vStart vesting start time
     * @param _vEnd vesting end time
     * @param _vPeriod staircase durarion
     */
    function initalizeVesting(
        address _vToken,
        uint _vStart,
        uint _vEnd,
        uint _vPeriod
    ) external onlyAdmin {
        // Ensure vesting is not in progress
        require(vActive == false, "VestingCentral: vesting in progress!");
        // Verify timestamps are logical
        require(
            (_vStart > block.timestamp) &&
            (_vEnd > _vStart) &&
            (_vPeriod > 0),
            "VestingCentral: invalid timestamps!"
        );
        // Initialize vesting configs
        vToken = _vToken;
        vStart = _vStart;
        vEnd = _vEnd;
        vPeriod = _vPeriod;
        vInstallments = (vEnd - vStart) / vPeriod;
        vReleased = 0;
        vDissolvable = true;
        vActive = true;

        emit Initialized(vStart, vEnd, vPeriod);
    }

    /**
     * @dev Adds a new member.
     * @param _account new member address
     * @param _shares new member shares
     */
    function addMember(address payable _account, uint _shares) external onlyAdmin {
        // Ensure account is valid
        require(_account != address(0), "VestingCentral: invalid address!");
        // Add member
        mConfigs.push(mConfig(_account, _shares));
        vMembers = mConfigs.length;
        // Update total shares
        vSharesTotal = totalShares();
        emit MemberAdded(_account,_shares);
    }

    /**
     * @dev Get indexed member.
     * @param _index member index
     */
    function getMember(uint8 _index) external view returns (address account, uint shares) {
        // Return indexed member configs
        return (mConfigs[_index].account, mConfigs[_index].shares);
    }

    /**
     * @dev Checks if caller is a member.
     */
    function isMember() internal view returns (bool) {
        for(uint i = 0; i < mConfigs.length; i++) {
            if(_msgSender() == mConfigs[i].account) {
                return true;
            }
        }
        // Caller is not a member
        return false;
    }

    /**
     * @dev Removes a member, clears vested funds to member prior to removal.
     * @param _index member to be removed
     */
    function removeMember(uint8 _index) external onlyAdmin {
        // Ensure index is valid
        require(mConfigs.length > _index, "VestingCentral: invalid index!");
        // Ensure there is no vested amount due
        require(checkVested() == 0, "VestingCentral: clear payments due!");
        address member = mConfigs[_index].account; 
        // Reorder memberConfigs array
        if(mConfigs.length >= 1) {
            for(uint8 i = _index; i < mConfigs.length - 1; i++) {
                mConfigs[i] = mConfigs[i + 1];
            }
        }
        // Remove member
        mConfigs.pop();
        vMembers = mConfigs.length;
        // Update total shares
        vSharesTotal = totalShares();
        emit MemberRemoved(member);
    }

    /**
     * @dev Returns total shares.  
     */
    function totalShares() internal view returns (uint256) {
        uint sharesTotal = 0;
        for(uint8 i = 0; i < mConfigs.length; i++) {
            sharesTotal += mConfigs[i].shares;
        }
        return sharesTotal;
    }

    /**
     * @dev Returns vested amount 
     */
    function checkVested() public view returns (uint) {
        // Ensure vesting is in progress
        if(vActive) {
            // Pull unvesting token balance
            uint balance = IERC20(vToken).balanceOf(address(this));
            if(block.timestamp < vStart) { // Vesting not started.
                return 0;
            } else if(block.timestamp > vEnd) { // Vesting ended.
                return balance;
            } else { // Vesting in progress
                uint accrued = ((block.timestamp - vStart) / vPeriod) - vReleased;
                uint unreleased = vInstallments - vReleased;
                return ((balance * accrued) / unreleased);
            }
        }
        return 0;
    }

    /**
     * @notice Transfers vested tokens to all members.
     */
    function releaseVested() external {
        // Only members can release vested funds
        require(isMember(), "VestingCentral: restricted to members only!");
        // Determine vested amount
        uint vestedAmount = checkVested();
        uint amount;
        // Ensure there is vested amount due
        require(vestedAmount > 0, "VestingCentral: no payments due!");
        for(uint i = 0; i < mConfigs.length; i++) {
            amount = vestedAmount * mConfigs[i].shares / vSharesTotal;
            IERC20(vToken).transfer(mConfigs[i].account, amount);
        }
        vReleased = ((block.timestamp - vStart) / vPeriod);
        vActive = (vInstallments > vReleased) ? true : false; 
        
        emit Released(vestedAmount, mConfigs.length);
    }

    /**
     * @notice Locks active vesting, this can not be undone. 
     */
    function lockVesting() external onlyAdmin {
        // Ensure locking is possible
        require(vActive && vDissolvable, "VestingCentral: blocked!");
        vDissolvable = false;    
    
        emit Locked(block.timestamp, vEnd);
    }
    
    /**
     * @notice Dissolve vesting if no outstanding payments, return unvested funds 
     */
    function dissolveVesting() external onlyAdmin {
        // Ensure there is no vested amount due
        require(checkVested() == 0, "VestingCentral: clear payments due!");
        // Ensure dissolve call is logical
        require(vActive && vDissolvable, "VestingCentral: blocked!");
        // Pull vested token balance
        uint balance = IERC20(vToken).balanceOf(address(this));
        if(balance > 0) {
            IERC20(vToken).transfer(owner(), balance);
        }
        vToken = address(0);
        vStart = 0;
        vEnd = 0;
        vPeriod = 0;
        vInstallments = 0;
        vReleased = 0;
        vActive = false;

        emit Dissolved(owner(), balance);
    }

    /**
     * @dev Recovers funds sent accidentally, controllers can recover.
     * @param _anyERC20 address of token to recover
     * @param _recipient address of recipient
     * @param _amount amount to be recovered
     */
    function recoverERC20(address _anyERC20, address payable _recipient, uint256 _amount) external onlyControllers {
        // Funds other than vesting token can be recovered
        require(_anyERC20 != vToken,"VestingCentral: Can not recover from vesting funds!");
        // Recover locked funds for recipient
        IERC20(_anyERC20).transfer(_recipient, _amount);
    }
}