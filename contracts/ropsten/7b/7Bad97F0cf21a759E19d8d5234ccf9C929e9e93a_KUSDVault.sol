pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.16;

import "./IERC20.sol";

/**
 * @title KUSDVault stores the Kine off-chain trading system's kUSD. When total vault of synthetic assets in Kine trading system changed, Kine reporter will mint/burn corresponding
 * kUSD in this vault to ensure kUSD total supply synced with synthetic assets' value.
 * @author Kine
 */
contract KUSDVault {
    // @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    // @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    // @notice Emitted when kUSD transferred
    event TransferKusd(address indexed counterParty, uint amount);

    // @notice Emitted when Erc20 transferred
    event TransferErc20(address indexed erc20, address indexed target, uint amount);

    // @notice Emitted when Ehter transferred
    event TransferEther(address indexed target, uint amount);

    // @notice Emitted when Ehter recieved
    event RecieveEther(uint amount);

    // @notice Emitted when operator changed
    event NewOperator(address oldOperator, address newOperator);

    // @notice Emitted when counter party changed
    event NewCounterParty(address oldCounterParty, address newCounterParty);

    // @notice Emitted when kUSD changed
    event NewKUSD(address oldKUSD, address newKUSD);

    address public admin;
    address public pendingAdmin;
    address public operator;
    address public counterParty;
    IERC20 public kUSD;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "only operator can call");
        _;
    }

    constructor(address admin_, address operator_, address counterParty_, address kUSD_) public {
        admin = admin_;
        operator = operator_;
        counterParty = counterParty_;
        kUSD = IERC20(kUSD_);
    }

    // @notice Operator can transfer kUSD to counterParty
    function transferKusd(uint amount) external onlyOperator {
        // check balance;
        uint balance = kUSD.balanceOf(address(this));
        require(balance >= amount, "not enough kUSD balance");
        // transferKusd
        bool success = kUSD.transfer(counterParty, amount);
        require(success, "transfer failed");

        emit TransferKusd(counterParty, amount);
    }

    // @notice Only admin can call
    function transferErc20(address erc20Addr, address target, uint amount) external onlyAdmin {
        // check balance;
        IERC20 erc20 = IERC20(erc20Addr);
        uint balance = erc20.balanceOf(address(this));
        require(balance >= amount, "not enough erc20 balance");
        // transfer token
        erc20.transfer(target, amount);

        emit TransferErc20(erc20Addr, target, amount);
    }

    // @notice Only admin can call
    function transferEther(address payable target, uint amount) external onlyAdmin {
        // check balance;
        require(address(this).balance >= amount, "not enough ether balance");
        // transfer ether
        require(target.send(amount), "transfer failed");
        emit TransferEther(target, amount);
    }

    // @notice Only admin can set operator
    function _setOperator(address newOperator) external onlyAdmin {
        address oldOperator = operator;
        operator = newOperator;
        emit NewOperator(oldOperator, newOperator);
    }

    // only admin can set counterParty
    function _setCounterParty(address newCounterParty) external onlyAdmin {
        address oldCounterParty = counterParty;
        counterParty = newCounterParty;
        emit NewCounterParty(oldCounterParty, newCounterParty);
    }

    // only admin can set kUSD
    function _setKUSD(address newKUSD) external onlyAdmin {
        address oldKUSD = address(kUSD);
        kUSD = IERC20(newKUSD);
        emit NewKUSD(oldKUSD, newKUSD);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) external onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      */
    function _acceptAdmin() external {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "unauthorized");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    // allow to recieve ether
    function() external payable {
        if(msg.value > 0) {
            emit RecieveEther(msg.value);
        }
    }
}