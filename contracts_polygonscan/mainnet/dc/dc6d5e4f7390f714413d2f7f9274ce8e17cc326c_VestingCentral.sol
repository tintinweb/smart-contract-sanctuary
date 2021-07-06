/**
 *Submitted for verification at polygonscan.com on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Controllers
 * @dev owner/admin only access restriction.
 * Merged and extended functionality from OpenZeppelin Context & Ownable contracts.
 * For details see https://docs.openzeppelin.com/
 */
contract Controllers {

    // Contract controllers
    address private _owner;
    address private _admin;

    event NewOwner(address oldOwner, address newOwner);
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        _owner = _msgSender();
        _admin = _owner;
        emit NewOwner(address(0), owner());
        emit NewAdmin(address(0), admin());
    }

    /**
     * @dev modifier for owner only functions.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "owner only!");
        _;
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

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }

    /**
     * @dev Assigns new admin.
     * @param _newAdmin address of new admin
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        // Check for non 0 address
        require(_newAdmin != address(0), "admin can not be zero address");
        emit NewAdmin(admin(), _newAdmin);
        _admin = _newAdmin;
    }

    /**
     * @dev Assigns new owner.
     * @param _newOwner address of new owner
     */
    function setOwner(address _newOwner) external onlyOwner {
        // Check for non 0 address
        require(_newOwner != address(0), "owner can not be zero address");
        emit NewOwner(owner(), _newOwner);
        _owner = _newOwner;
    }
}

/**
 * @title VestingCentral
 * @dev Simple vesting scheme with staircase release schedule & multiple member participation.
 */
contract VestingCentral is Controllers {

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
        address account;
        uint shares;
    }

    // member configs of all participating members
    mConfig[] private mConfigs;

    // Vesting Events.
    event Initialized(uint start, uint end, uint period);
    event MemberAdded(address account, uint shares);
    event MemberRemoved(address account);
    event Released(uint amount, uint members);
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
        uint _vPeriod,
        bool _vDissolvable
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
        vDissolvable = _vDissolvable;
        vActive = true;

        emit Initialized(vStart, vEnd, vPeriod);
    }

    /**
     * @dev Adds a new member.
     * @param _account new member address
     * @param _shares new member shares
     */
    function addMember(address _account, uint _shares) external onlyAdmin {
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
    function recoverERC20(address _anyERC20, address _recipient, uint256 _amount) external onlyControllers {
        // Funds other than vesting token can be recovered
        require(_anyERC20 != vToken,"VestingCentral: Can not recover from vesting funds!");
        // Recover locked funds for recipient
        IERC20(_anyERC20).transfer(_recipient, _amount);
    }
}