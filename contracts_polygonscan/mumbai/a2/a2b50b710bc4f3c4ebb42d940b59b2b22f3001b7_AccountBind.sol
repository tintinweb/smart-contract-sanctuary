/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

contract AccountBind is Ownable{

    struct Account {
        uint mid;
        bool bound;
    }

    mapping(address => Account) accounts;
    mapping(uint => address) mids;

     // 合约支持捐赠
     // 捐助用户燃料费发放
    function donate() payable public returns(address addr, uint amount, bool success){
        return (msg.sender, msg.value, payable(address(this)).send(msg.value));
    }

    // 判断地址是否已经绑定
    function isAddressBound(address addr) view internal returns(bool) {
        return accounts[addr].bound;
    }

    // 判断 MID 是否已经绑定
    function isMidBound(uint mid) view internal returns(bool) {
        return mids[mid] != address(0);
    }

    // 获取地址绑定的 MID
    // Token Mint 合约需要调用
    function getMid(address addr) view external returns(uint) {
        require(
            isAddressBound(addr) == true,
            "Address not bound."
        );
        return accounts[addr].mid;
    }

    // 合约中还剩多少钱 ^_^
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 完成绑定，发钱发钱
    // 只允许管理员调用
    function bind(address payable addr, uint mid) public payable onlyOwner {
        require(
            isAddressBound(addr) != true,
            "Address already bound."
        );
        require(
            isMidBound(mid) != true,
            "Mid already bound."
        );
        accounts[addr] = Account({mid: mid, bound: true});
        mids[mid] = addr;
        addr.transfer(10000000000000000);
    }

    // 不玩了，不玩了，尼玛退钱
    // 只允许管理员调用
    function withdraw() public payable onlyOwner {
        payable(Ownable.owner()).transfer(getBalance());
    }

}