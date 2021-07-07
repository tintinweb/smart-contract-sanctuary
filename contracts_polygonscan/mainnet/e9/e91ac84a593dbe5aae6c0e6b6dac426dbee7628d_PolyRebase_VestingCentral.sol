/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

    using SafeERC20 for IERC20;

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
            IERC20(vToken).safeTransfer(mConfigs[i].account, amount);
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
            IERC20(vToken).safeTransfer(owner(), balance);
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
        require(
            ((_anyERC20 != vToken) || (vActive == false)),
            "VestingCentral: vToken recovery not possible during active vesting!"
        );
        // Recover locked funds for recipient
        IERC20(_anyERC20).safeTransfer(_recipient, _amount);
    }
}