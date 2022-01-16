/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// ver 1.1642310749
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

    bool private getCalled = false;
    bool private availableFund = false;

    IERC20 private Token;
    address private tokenAddress;

    address private owner;
    bool[] private results;
    bool private Distributed;
    
    modifier only_owner() {
        require(msg.sender == owner,"Only Owner can call this.");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public only_owner{
        owner = newOwner;       
    }

    function setPaymentToken (address _tokenAddress) public only_owner{
        tokenAddress = _tokenAddress;
        Token = IERC20(tokenAddress);
    }

    function cleanUp () public only_owner returns (bool){
        getCalled = false;
        Distributed = true;
        availableFund = false;
        return Token.transfer(owner,Token.balanceOf(address(this)));
    }

    function setAddresses (address[] memory _addList, uint[] memory _values) public only_owner{
        require(Distributed,"Last list is not distributed yet.");
        addList = _addList;
        valList = _values;
        Distributed = false;
        getCalled = false;
    }

    function changeAddresses (address[] memory _addList, uint[] memory _values) public only_owner{
        addList = _addList;
        valList = _values;
        getCalled = false;
    }

    function getAddresses () public only_owner returns (address[] memory, uint[] memory){
        getCalled = true;
        return (addList,valList);
    }

    function chkAvailableFund() public only_owner returns (bool) {
        require (addList.length>0,"There is no list to chk.");
        uint res = 0;
        for (uint i;i<valList.length;i++){
            res += valList[i];
        }
        if (Token.balanceOf(address(this))>=res){
            availableFund = true;
        } else {
            getCalled = false;
        }
        return availableFund;
    }

    function distribute(bool CurrentListConfirmed) public only_owner returns (bool[] memory){
        require(CurrentListConfirmed,"List not confirmed.");
        require(!Distributed,"Last list distributed before!");
        require(getCalled,"List should called once and checked.");
        require(availableFund,"Not enough fund available in the contract.");
        for(uint i=0;i<addList.length;i++){
            results.push(false);
            results[i]=Token.transfer(addList[i],valList[i]);
        }
        Distributed = true;
        return results;
    }

}