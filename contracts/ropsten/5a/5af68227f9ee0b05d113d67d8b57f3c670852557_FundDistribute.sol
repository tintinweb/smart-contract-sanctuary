/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// ver 1.1642519787
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//      /////////////////////////// Definitions ///////////////////
contract FundDistribute {

    address[] private addList;
    uint[] private valList;

    // bool private getCalled = false;
    bool private availableFund = false;

    IERC20 private Token;
    address private tokenAddress;

    address private owner;
    bool[] private results;
    bool private Distributed;
    uint private totalAmount;
    
    modifier only_owner() {
        require(msg.sender == owner,"Only Owner can call this.");
        _;
    }

    constructor(){
        owner = msg.sender;
        Distributed = true;
    }

    function changeOwner(address newOwner) public only_owner{
        owner = newOwner;       
    }

    function setPaymentToken (address _tokenAddress) public only_owner{
        tokenAddress = _tokenAddress;
        Token = IERC20(tokenAddress);
    }

    function cleanUp () public only_owner{
        // getCalled = false;
        Distributed = true;
        availableFund = false;
        totalAmount = 0;
        delete results;
        delete addList;
        delete valList;
        bool res = false;
        if (Token.transfer(owner,Token.balanceOf(address(this)))){
            res = true;
        }
        // if (payable(address(this)))
        emit CleanUp_Done(res);
    }

    function setAddresses (address[] memory _addList, uint[] memory _values) public only_owner{
        require(Distributed,"Last list is not distributed yet.");
        addList = _addList;
        valList = _values;
        Distributed = false;
        // getCalled = false;
        emit AddressesArranged (addList,valList);
    }

    function changeAddresses (address[] memory _addList, uint[] memory _values) public only_owner{
        addList = _addList;
        valList = _values;
        emit AddressesChanged (addList,valList);
        // getCalled = false;
    }

    function getAddressesView () public view returns (address[] memory, uint[] memory, address){
        require(tokenAddress != address(0),"Token should set at first place.");
        return (addList,valList,tokenAddress);
    }

    function getAddresses () public only_owner{
        require(tokenAddress != address(0),"Token should set at first place.");
        Distributed = false;
        emit AddressesReturned (addList,valList,tokenAddress);
    }

    function chkAvailableFund() public only_owner{
        require (addList.length>0,"There is no list to chk.");
        totalAmount = 0;
        for (uint i;i<valList.length;i++){
            totalAmount += valList[i];
        }
        if (Token.balanceOf(address(this))>=totalAmount){
            availableFund = true;
        }else {
            availableFund = false;
        }
    }

    function distribute(bool CurrentListConfirmed, uint _totalAmount) public only_owner{
        require(CurrentListConfirmed,"List not confirmed.");
        require(!Distributed,"Last list distributed before!");
        // require(getCalled,"List should called once and checked.");
        require(availableFund,"Not enough fund available in the contract.");
        require(totalAmount==_totalAmount,"Wrong Total Amount.");
        for(uint i=0;i<addList.length;i++){
            results.push(false);
            results[i]=Token.transfer(addList[i],valList[i]);
        }
        Distributed = true;
        emit FundDistributed(results);
    }


    function get_Result()public view returns (bool[] memory){
        require(Distributed,"Fund is not distributed yet.");
        return results;
    }

    event AddressesArranged (address[] addresses, uint[] values);
    event AddressesChanged (address[] addresses, uint[] values);
    event CleanUp_Done (bool cleanupResult);
    event FundDistributed (bool[] distributionResults);
    event AddressesReturned (address[] addresses,uint[] values,address tokenAddress);

}