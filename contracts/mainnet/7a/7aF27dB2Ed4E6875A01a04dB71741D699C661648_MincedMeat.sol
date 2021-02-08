/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

contract MincedMeat{

    using SafeMath for uint256;
    mapping(address => bool) public owners;        // 管理员
    mapping(address => bool) public allowCallers;  // 允许调用transactionChannel的合约地址
    mapping(address => uint256) public serviceCharges;  // 手续费设置
    string public prefix = "\x19Ethereum Signed Message:\n32";
    ERC20 erc20;

    constructor() public{
        owners[msg.sender] = true;
    }

    // 交易管道
    function transactionChannel(address[] memory _from,address[] memory _to,uint256[] memory _value,bytes32[] memory _r,bytes32[] memory _s,uint8[] memory _v,address _contractAddress) public onlyAllowCallers{
        erc20 = ERC20(_contractAddress);
        uint256 serviceCharge = serviceCharges[_contractAddress];
        if(serviceCharges[_contractAddress] == 0){
            for(uint256 i=0; i<_from.length; i++){
                _sendTransaction(_from[i],_to[i],_value[i],_r[i],_s[i],_v[i],_contractAddress);
            }
        }else{
            for(uint256 i=0; i<_from.length; i++){
                if(erc20.balanceOf(_from[i]) >= _value[i] && getVerifySignatureResult(_from[i],_to[i],_value[i],_r[i],_s[i],_v[i],_contractAddress) == _from[i]){
                    erc20.transferFrom(_from[i],tx.origin,serviceCharge);
                    erc20.transferFrom(_from[i],_to[i],_value[i].sub(serviceCharge));
                }
            }
        }
    }

    // 验证并发送转账交易
    function _sendTransaction(address _from,address _to,uint256 _value,bytes32 _r,bytes32 _s,uint8 _v,address _contractAddress) private{
        if(getVerifySignatureResult(_from,_to,_value, _r, _s, _v,_contractAddress) == _from){
            erc20.transferFrom(_from,_to,_value);
        }
    }

    // 查看交易签名对应的地址
    function getVerifySignatureResult(address _from,address _to,uint256 _value,bytes32 _r,bytes32 _s,uint8 _v,address _contractAddress) public view returns(address){
        return ecrecover(getSha3Result(_from,_to,_value,_contractAddress), _v, _r, _s);
    }

    // 查看随机数签名对应的地址
    function getVerifySignatureByRandom(bytes memory _random,bytes32 _r,bytes32 _s,uint8 _v) public view returns(address){
        return ecrecover(keccak256(abi.encodePacked(prefix,keccak256(abi.encodePacked(_random)))),_v,_r,_s);
    }

    // 获取sha3加密结果
    function getSha3Result(address _from,address _to,uint256 _value,address _contractAddress) public view returns(bytes32){
        return keccak256(abi.encodePacked(prefix,keccak256(abi.encodePacked(_from,_to,_value,_contractAddress))));
    }

    // 更新合约手续费
    function addServiceCharge(address _contractAddress,uint256 _serviceCharge) public onlyOwner{
        serviceCharges[_contractAddress] = _serviceCharge;
    }

    // 增加允许调用管道的合约地址
    function addCaller(address _caller) public onlyOwner{
        allowCallers[_caller] = true;
    }

    // 删除允许调用管道的合约地址
    function removeCaller(address _caller) public onlyOwner{
        allowCallers[_caller] = false;
    }

    // 增加管理员
    function addOwner(address _owner) public onlyOwner{
        owners[_owner] = true;
    }

    // 删除管理员
    function removeOwner(address _owner) public onlyOwner{
        owners[_owner] = false;
    }

    //  仅限管理员操作
    modifier onlyOwner(){
        require(owners[msg.sender], 'No authority');
        _;
    }

    //  仅允许指定地址调用
    modifier onlyAllowCallers(){
        require(allowCallers[msg.sender],'No call permission');
        _;
    }
}

interface ERC20{
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address) external returns(uint256);
}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"When sub, a must be greater than b");
        uint256 c = a - b;
        return c;
    }
}