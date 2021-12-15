pragma solidity ^0.5.16;
import "./SafeBEP20.sol";
import "./IBEP20.sol";
import "./VAIVaultProxy.sol";
import "./VAIVaultStorage.sol";
import "./VAIVaultErrorReporter.sol";

contract VAIVault is VAIVaultStorage {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice Event emitted when VAI deposit
    event Deposit(address indexed user, uint256 amount);

    /// @notice Event emitted when VAI withrawal
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Event emitted when admin changed
    event AdminTransfered(address indexed oldAdmin, address indexed newAdmin);

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @notice Deposit VAI to VAIVault for XVS allocation
     * @param _amount The amount to deposit to vault
     */
    function deposit(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        updateVault();

        // Transfer pending tokens to user
        updateAndPayOutPending(msg.sender);

        // Transfer in the amounts from user
        if(_amount > 0) {
            vai.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(accXVSPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Withdraw VAI from VAIVault
     * @param _amount The amount to withdraw from vault
     */
    function withdraw(uint256 _amount) public nonReentrant {
        _withdraw(msg.sender, _amount);
    }

    /**
     * @notice Claim XVS from VAIVault
     */
    function claim() public nonReentrant {
        _withdraw(msg.sender, 0);
    }

    /**
     * @notice Low level withdraw function
     * @param account The account to withdraw from vault
     * @param _amount The amount to withdraw from vault
     */
    function _withdraw(address account, uint256 _amount) internal {
        UserInfo storage user = userInfo[account];
        require(user.amount >= _amount, "withdraw: not good");

        updateVault();
        updateAndPayOutPending(account); // Update balances of account this is not withdrawal but claiming XVS farmed

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            vai.safeTransfer(address(account), _amount);
        }
        user.rewardDebt = user.amount.mul(accXVSPerShare).div(1e18);

        emit Withdraw(account, _amount);
    }

    /**
     * @notice View function to see pending XVS on frontend
     * @param _user The user to see pending XVS
     */
    function pendingXVS(address _user) public view returns (uint256)
    {
        UserInfo storage user = userInfo[_user];

        return user.amount.mul(accXVSPerShare).div(1e18).sub(user.rewardDebt);
    }

    /**
     * @notice Update and pay out pending XVS to user
     * @param account The user to pay out
     */
    function updateAndPayOutPending(address account) internal {
        uint256 pending = pendingXVS(account);

        if(pending > 0) {
            safeXVSTransfer(account, pending);
        }
    }

    /**
     * @notice Safe XVS transfer function, just in case if rounding error causes pool to not have enough XVS
     * @param _to The address that XVS to be transfered
     * @param _amount The amount that XVS to be transfered
     */
    function safeXVSTransfer(address _to, uint256 _amount) internal {
        uint256 xvsBal = xvs.balanceOf(address(this));

        if (_amount > xvsBal) {
            xvs.transfer(_to, xvsBal);
            xvsBalance = xvs.balanceOf(address(this));
        } else {
            xvs.transfer(_to, _amount);
            xvsBalance = xvs.balanceOf(address(this));
        }
    }

    /**
     * @notice Function that updates pending rewards
     */
    function updatePendingRewards() public {
        uint256 newRewards = xvs.balanceOf(address(this)).sub(xvsBalance);

        if(newRewards > 0) {
            xvsBalance = xvs.balanceOf(address(this)); // If there is no change the balance didn't change
            pendingRewards = pendingRewards.add(newRewards);
        }
    }

    /**
     * @notice Update reward variables to be up-to-date
     */
    function updateVault() internal {
        uint256 vaiBalance = vai.balanceOf(address(this));
        if (vaiBalance == 0) { // avoids division by 0 errors
            return;
        }

        accXVSPerShare = accXVSPerShare.add(pendingRewards.mul(1e18).div(vaiBalance));
        pendingRewards = 0;
    }

    /**
     * @dev Returns the address of the current admin
     */
    function getAdmin() public view returns (address) {
        return admin;
    }

    /**
     * @dev Burn the current admin
     */
    function burnAdmin() public onlyAdmin {
        emit AdminTransfered(admin, address(0));
        admin = address(0);
    }

    /**
     * @dev Set the current admin to new address
     */
    function setNewAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new owner is the zero address");
        emit AdminTransfered(admin, newAdmin);
        admin = newAdmin;
    }

    /*** Admin Functions ***/

    function _become(VAIVaultProxy vaiVaultProxy) public {
        require(msg.sender == vaiVaultProxy.admin(), "only proxy admin can change brains");
        require(vaiVaultProxy._acceptImplementation() == 0, "change not authorized");
    }

    function setVenusInfo(address _xvs, address _vai) public onlyAdmin {
        xvs = IBEP20(_xvs);
        vai = IBEP20(_vai);

        _notEntered = true;
    }
}