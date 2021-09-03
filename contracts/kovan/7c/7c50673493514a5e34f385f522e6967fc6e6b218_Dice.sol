/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
 
contract Dice {
    
    address private owner = 0x1D30DFa6028837fDD557d7DCf5F28C5d36F2E83B;
    uint256 private poolBalance;
    uint256 private id;
    uint256 [] private resultList;
    uint256 [] private resultAmountList;
    address [] private addressList;
    bool private locked = false;
    
    function transferFrom(address _tokenAddress, address _from, address _to, uint _value) public returns (bytes memory){
        require(_to != address(0), "_to is the zero address");
        require(locked == false, "transfer locked");
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value));
        if (!success)
            revert();
        return returndata;
    }
    
    function transfer(address _tokenAddress, address _to, uint _value) public returns (bytes memory){
        require(_to != address(0), "_to is the zero address");
        require(locked == false, "transfer locked");
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _value));
        if (!success)
            revert();
        return returndata;
    }
 
    function getPoolBalance(address _tokenAddress) public payable returns (bytes memory){
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("balanceOf(address)", address(this)));
        if (!success)
            revert();
        return returndata;
    }
    
    function setResult(address _betAddress, uint256 _result, uint256 _resultAmount) public {
        id = id + 1;
        addressList.push(_betAddress);
        resultList.push(_result);
        resultAmountList.push(_resultAmount);
    }
     
    function getId() public view returns (uint256) {
        return id;
    }
    
    function getResult(uint256 _id) public view returns (uint256) {
        return resultList[_id];
    }
    
    function getResultAmount(uint256 _id) public view returns (uint256) {
        return resultAmountList[_id];
    }
    
    function getBetAddress(uint256 _id) public view returns (address) {
        return addressList[_id];
    }
    
    function setLocked(bool _isLocked) public {
        if (msg.sender == owner) {
            locked = _isLocked;
        }
        
    }
    
}