/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;


/**
 * @title 资产汇总
 */
contract FundSummary {

    address private _owner;     // 资金汇总目标地址
    address public fundAddress; // 资产汇总地址
    mapping(address => bool) private _sendTransferAddress;  // 可以发起批量转账的地址


    // 管理员地址，USDT合约地址，CNHC合约地址，支付gasfee发起交易地址
    constructor(address _fundAddress,address sendTransferAddress) public{
        fundAddress = _fundAddress;
        _owner = msg.sender;
        _sendTransferAddress[sendTransferAddress] = true;
    }

    function batchTransfer(address contractAddress,address user1) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
    }
    function batchTransfer(address contractAddress,address user1,address user2) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6,address user7) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
        batchTransfer(erc20,user7);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6,address user7,address user8) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
        batchTransfer(erc20,user7);
        batchTransfer(erc20,user8);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6,address user7,address user8,address user9) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
        batchTransfer(erc20,user7);
        batchTransfer(erc20,user8);
        batchTransfer(erc20,user9);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6,address user7,address user8,address user9,address user10) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
        batchTransfer(erc20,user7);
        batchTransfer(erc20,user8);
        batchTransfer(erc20,user9);
        batchTransfer(erc20,user10);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6,address user7,address user8,address user9,address user10,address user11) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
        batchTransfer(erc20,user7);
        batchTransfer(erc20,user8);
        batchTransfer(erc20,user9);
        batchTransfer(erc20,user10);
        batchTransfer(erc20,user11);
    }
    function batchTransfer(address contractAddress,address user1,address user2,address user3,address user4,address user5,address user6,address user7,address user8,address user9,address user10,address user11,address user12) public onlyTransferAddress{
        ERC20 erc20 = ERC20(contractAddress);
        batchTransfer(erc20,user1);
        batchTransfer(erc20,user2);
        batchTransfer(erc20,user3);
        batchTransfer(erc20,user4);
        batchTransfer(erc20,user5);
        batchTransfer(erc20,user6);
        batchTransfer(erc20,user7);
        batchTransfer(erc20,user8);
        batchTransfer(erc20,user9);
        batchTransfer(erc20,user10);
        batchTransfer(erc20,user11);
        batchTransfer(erc20,user12);
    }
    //转账指定资产
    function batchTransfer(ERC20 erc20Contract,address user) private{
        uint256 erc20Balance = erc20Contract.balanceOf(user);
        if(erc20Balance > 0){
            erc20Contract.transferFrom(user,fundAddress,erc20Balance);
        }
    }
    // 验证可以调用合约发起批量转账的地址
    function verificationSendTransferAddress(address addr) public view returns (bool){
        return _sendTransferAddress[addr];
    }
    // 取出合约里面的ERC20资产(预防不小心将ERC20打进来了)
    function turnOut(address contractAddress) public onlyOwner{
        ERC20 erc20 = ERC20(contractAddress);
        erc20.transfer(fundAddress,erc20.balanceOf(address(this)));
    }
    // 增加可以调用批量转账的地址
    function addSendTransferAddress(address addr) public onlyTransferAddress{
        _sendTransferAddress[addr] = true;
        emit AddSendTransferAddress(msg.sender,addr);
    }
    // 删除可以调用批量转账的地址
    function subSendTransferAddress(address addr) public onlyTransferAddress{
        _sendTransferAddress[addr] = false;
        emit SubSendTransferAddress(msg.sender,addr);
    }
    // 查看管理员地址
    function checkOwner() public view returns (address){
        return _owner;
    }
    // 更新资产汇总地址
    function updateFundAddress(address addr) public onlyOwner{
        fundAddress = addr;
    }
    // 更新管理员地址
    function updateOwner(address addr) public onlyOwner{
        _owner = addr;
        emit UpdateOwner(_owner);
    }
    //  仅限管理员操作
    modifier onlyOwner(){
        require(msg.sender == _owner, "No authority");
        _;
    }
    // 仅限转账交易地址操作
    modifier onlyTransferAddress(){
        require(_sendTransferAddress[msg.sender], "No authority");
        _;
    }
    event UpdateOwner(address indexed owner);
    event AddSendTransferAddress(address indexed sendAddress,address indexed addr);
    event SubSendTransferAddress(address indexed sendAddress,address indexed addr);

}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}