// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./base/token/BEP20/IBEP20.sol";
import "./base/token/BEP20/EmergencyWithdrawable.sol";

contract Starpot is EmergencyWithdrawable {
    IBEP20 public xld;
    uint256 public ticketPrice = 20000 * 10**9;
    uint256 public ticketsAvailable;
    uint256 public nextOrderId;
    address public operator;
    mapping(address => mapping(uint256 => uint256)) public claimedIds;

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event TicketsBought(address indexed from, uint256 indexed orderId, uint256 quantity);
    event TicketsGranted(address indexed to, uint256 indexed orderId, uint256 quantity, uint256 reasonId);
    event Claimed(address indexed from, uint256 indexed id, uint256 amount);

    constructor(IBEP20 _xld) {
        setXld(_xld);
        setOperator(owner());
    }

    function grantTickets(address to, uint256 quantity, uint256 reasonId) external onlyAdmins {
        require(quantity > 0, "Starpot: Invalid quantity");
        require(to != address(0), "Starpot: Invalid address");

        emit TicketsGranted(to, ++nextOrderId, quantity, reasonId);
    }

    function buyTickets(uint256 quantity) external {
        require(quantity > 0, "Starpot: Invalid quantity");
        ticketsAvailable -= quantity;

        xld.transferFrom(msg.sender, address(this), quantity * ticketPrice);

        emit TicketsBought(msg.sender, ++nextOrderId, quantity);
    }

    function claim(uint256 id, uint256 amount, bytes memory signature) external {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        doClaim(id, amount, v, r, s);
    }

    function claimBulk(uint256[] calldata id, uint256[] calldata amount, bytes[] memory signatures) external {
        for(uint i = 0; i < id.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = splitSignature(signatures[i]);
            doClaim(id[i], amount[i], v, r, s);
        }
    }

    function isClaimed(address user, uint256 id) external view returns(bool) {
        return claimedIds[user][id] > 0;
    }

    function doClaim(uint256 id, uint256 amount, uint8 v, bytes32 r, bytes32 s) internal {
        require(claimedIds[msg.sender][id] == 0, "Starpot: Already claimed");
        require(amount > 0, "Starpot: Nothing to claim");

        bytes32 msgHash = prefixed(keccak256(abi.encodePacked(msg.sender, id, amount)));
        require(operator == ecrecover(msgHash, v, r, s), "Invalid signature");


        claimedIds[msg.sender][id] = amount;
        xld.transfer(msg.sender, amount);

        emit Claimed(msg.sender, id, amount);
    }

    function splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65);

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    function hashData(address sender, uint256 id, uint256 amount) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(sender, id, amount));
    }

    function hashDataPrefixed(address sender, uint256 id, uint256 amount) external pure returns(bytes32) {
        return prefixed(keccak256(abi.encodePacked(sender, id, amount)));
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function disburseTickets(uint256 quantity) external onlyAdmins {
        ticketsAvailable += quantity;
    }

    function setTicketPrice(uint256 price) external onlyOwner {
        ticketPrice = price;
    }

    function setTicketsAvailable(uint256 quantity) external onlyAdmins {
        ticketsAvailable = quantity;
    }

    function burn(uint256 amount) external onlyAdmins {
        xld.transfer(BURN_ADDRESS, amount);
    }

    function setXld(IBEP20 _xld) public onlyOwner {
        require(address(_xld) != address(0), "Starpot: Invalid address");
        xld = _xld;
    }

    function setOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "Starpot: Invalid address");
        operator = _operator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./IBEP20.sol";

abstract contract EmergencyWithdrawable is AccessControlled {
    /**
     * @notice Withdraw unexpected tokens sent to the contract
     */
    function withdrawStuckTokens(address token) external onlyOwner {
        uint256 amount = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(msg.sender, amount);
    }
    
    /**
     * @notice Withdraws funds of the contract - only for emergencies
     */
    function emergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent calls to a function.
 */
abstract contract AccessControlled {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address private _owner;
    bool private _isPaused;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _authorizedContracts;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _status = _NOT_ENTERED;
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        setAdmin(_owner, true);
        setAdmin(address(this), true);
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "AccessControlled: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
        require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        _;
    }

    modifier notUnauthorizedContract() {
        if (!_authorizedContracts[msg.sender]) {
            require(!_isContract(msg.sender), "AccessControlled: unauthorized contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: unauthorized proxy contract not allowed");
        }
        _;
    }

    modifier isNotUnauthorizedContract(address addr) {
        if (!_authorizedContracts[addr]) {
            require(!_isContract(addr), "AccessControlled: contract not allowed");
        }
        
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "AccessControlled: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by a non-admin account
     */
    modifier onlyAdmins() {
        require(_admins[msg.sender], "AccessControlled: caller does not have permission");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "AccessControlled: paused");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function setAdmin(address addr, bool _isAdmin) public onlyOwner {
        _admins[addr] = _isAdmin;
    }

    function isAdmin(address addr) public view returns(bool) {
        return _admins[addr];
    }

    function setAuthorizedContract(address addr, bool isAuthorized) public onlyOwner {
        _authorizedContracts[addr] = isAuthorized;
    }

    function pause() public onlyOwner {
        _isPaused = true;
    }

    function unpause() public onlyOwner {
        _isPaused = false;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

