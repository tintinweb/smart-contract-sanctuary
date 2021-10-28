/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity  = 0.8.8;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address public pendingOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "no permission");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    //转移owner权限函数
    function transferOwnership(address newOwner)  public onlyOwner {
        pendingOwner = newOwner;//设置pendingOwner为newOwner
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    //接受owner权限函数，仅pendingOwner可调用
    function acceptOwnership()  public onlyPendingOwner {
        emit OwnershipTransferred(_owner, pendingOwner);
        _owner = pendingOwner;//更新owner为pendingOwner
        pendingOwner = address(0);//pendingOwner置为零地址
    }

}

contract BlockedList is Ownable {
    mapping(address => bool) internal blockList;
    address public configurationController;
    event AddBlockList(address _account);
    event RemoveBlockList(address _account);
    event SetConfigAdmin(address _owner, address _account);
    function isblockAddr(address _account) public view  returns(bool) {
        return blockList[_account];
    }
    modifier onlyConfigurationController() {
        require(msg.sender== configurationController, "caller is not the admin");
        _;
    }
    //添加配置权限的管理员
    function setConfigurationController(address _configurationController) public onlyOwner{
        require(_configurationController != address(0), "the account is zero address");
        emit SetConfigAdmin(configurationController, _configurationController);
        configurationController = _configurationController;

    }

    function addBlockList(address[] memory _accountList) public onlyConfigurationController {
        uint256 length = _accountList.length;
        for (uint i = 0; i < length; i++) {
            blockList[_accountList[i]] = true;
            emit AddBlockList(_accountList[i]);
        }
    }

    function removeBlockList(address[] memory _accountList) public onlyConfigurationController{
        uint256 length = _accountList.length;
        for (uint i = 0; i < length; i++) {
            blockList[_accountList[i]] = true;
            emit RemoveBlockList(_accountList[i]);
        }
    }
}