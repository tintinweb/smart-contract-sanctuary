// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Privilege.sol";

contract BridgeGateway is Privilege {
    mapping(string => SendStruct) public sendMap;

    struct SendStruct {
        address fromAddr;
        address toAddr;
        address token20Addr;
        uint256 fromAmount;
    }

    event ReceiveEvent(address indexed fromAddr, uint256 amount);
    event ExtractEvent(address indexed ownerAddr, address indexed token20Addr, uint256 amount);
    event SendEvent(string indexed txId,address indexed fromAddr,
                    address indexed toAddr,address token20Addr,uint256 fromAmount);

    receive() external payable {
        emit ReceiveEvent(msg.sender, msg.value);
    }

    function extractToken(uint256 amount) external onlyOwner() returns (bool){
        require(
            address(this).balance >= amount,
            "Insufficient BridgeGateway Balance"
        );
        payable(super.owner()).transfer(amount);
        emit ExtractEvent(owner(), address(0), amount);
        return true;
    }

    function extractToken20(address token20Addr, uint256 amount)
        external
        onlyOwner() returns (bool)
    {
        require(token20Addr != address(0), "token20Addr cannot be empty");
        require(
            IERC20(token20Addr).balanceOf(address(this)) >= amount,
            "Insufficient BridgeGateway Balance"
        );
        require(
            IERC20(token20Addr).transfer(owner(), amount),
            "extract failed"
        );
        emit ExtractEvent(owner(), token20Addr, amount);
        return true;
    }

    function sendToken(
        string memory txId,
        address fromAddr,
        address payable toAddr,
        uint256 fromAmount
    ) external onlyPrivilegeAccount() returns (bool){
        require(
            sendMap[txId].fromAddr == address(0),
            "The transaction has been transferred"
        );
        require(toAddr != address(0), "The toAddr cannot be empty");
        require(
            address(this).balance >= fromAmount,
            "Insufficient BridgeGateway Balance"
        );

        limitMoneyPrivilegeAccount(fromAmount);

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount
        });

        toAddr.transfer(fromAmount);
        emit SendEvent(
            txId,
            fromAddr,
            toAddr,
            address(0),
            fromAmount
        );
        return true;
    }

    function sendToken20(
        string memory txId,
        address fromAddr,
        address toAddr,
        address token20Addr,
        uint256 fromAmount
    ) external onlyPrivilegeAccount() returns (bool){
        require(sendMap[txId].fromAddr == address(0), "txId is exis");
        require(toAddr != address(0), "The toAddr cannot be empty");
        require(token20Addr != address(0), "The token20Addr cannot be empty");

        require(
            IERC20(token20Addr).balanceOf(address(this)) >= fromAmount,
            "Insufficient BridgeGateway Balance"
        );

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount
        });

        limitMoneyPrivilegeAccount(fromAmount);

        require(
            IERC20(token20Addr).transfer(toAddr, fromAmount),
            "Token20 transfer failed"
        );

        emit SendEvent(
            txId,
            fromAddr,
            toAddr,
            token20Addr,
            fromAmount
        );
        return true;
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Privilege is Ownable {
    uint256 public currentDay = 0;

    mapping(address => PrivilegeAccountStruct) public privilegeAccountMap;

    struct PrivilegeAccountStruct {
        bool isState;
        uint256 dayMoney;
        uint256 dayMoneyLimit;
        uint256 totalMoney;
    }

    constructor() {
        privilegeAccountMap[owner()] = PrivilegeAccountStruct({
            isState: true,
            dayMoney: 1000000000000000000000,
            dayMoneyLimit: 1000000000000000000000,
            totalMoney: 10000000000000000000000
        });
    }

    modifier onlyPrivilegeAccount() {
        require(
            privilegeAccountMap[msg.sender].isState == true,
            "You have no privilege"
        );
        _;
    }
    function limitMoneyPrivilegeAccount(uint256 tradeMoney) internal{
        PrivilegeAccountStruct memory privilegeAccountStruct = privilegeAccountMap[msg.sender];
        if(block.timestamp/86400 > currentDay){
            currentDay = block.timestamp/86400;
            privilegeAccountStruct.dayMoney = privilegeAccountStruct.dayMoneyLimit;
        }
        require(
            privilegeAccountStruct.dayMoney >= tradeMoney,
            "The quota is exceeded on the day"
        );
        require(
            privilegeAccountStruct.totalMoney >= tradeMoney,
            "The total quota exceeds the limit"
        );
        privilegeAccountStruct.dayMoney -= tradeMoney;
        privilegeAccountStruct.totalMoney -= tradeMoney;
        privilegeAccountMap[msg.sender] = privilegeAccountStruct;
    }

    function setPrivilegeAccount(address addr,uint256 dayMoneyLimit,uint256 totalMoney) external onlyOwner() returns (bool){
        require(addr != address(0), "The addr cannot be empty");
        privilegeAccountMap[addr].isState = true;
        privilegeAccountMap[addr].dayMoney = dayMoneyLimit;
        privilegeAccountMap[addr].dayMoneyLimit = dayMoneyLimit;
        privilegeAccountMap[addr].totalMoney = totalMoney;
        return true;
    }

    function removePrivilegeAccount(address addr) external onlyOwner() returns (bool){
        require(addr != address(0), "The addr cannot be empty");
        privilegeAccountMap[addr].isState = false;
        return true;
    }
}