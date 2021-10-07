/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



interface IERC20 {
function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Vault {

    IERC20 renBTC = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);

    uint dappFee = 10;
    uint totalVolume = 0;

    mapping(address => bool) users;
    mapping(address => uint) pendingWithdrawal;
    mapping(address => uint) usersPayments;



    function _calculateAfterPercentage(
        uint _amount, 
        uint _basisPoint
    ) public pure returns(uint result) {
        result = _amount - ( (_amount * _basisPoint) / 10000 ); //5 -> 0.05%;
    }

    function _calculateFeeAllocationPercentage(
        uint _amount, 
        address _user
    ) public returns(uint userAllocation) {
        usersPayments[_user] += _amount;
        totalVolume += _amount;
        userAllocation = ( (usersPayments[_user] * 10000) / totalVolume ) * 1 ether;
    }

    function _bytesToAddress(bytes memory bys) public pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }

    function _preSending(address _user) private {
        pendingWithdrawal[_user] = address(this).balance;
    }

    function _sendEtherToUser(address _user) public {
        _preSending(_user);
        uint amount = pendingWithdrawal[_user];
        pendingWithdrawal[_user] = 0;
        payable(_user).transfer(amount);
    }

    function _sendsFeeToVault(uint _amount, address _payme) public returns(uint, bool) {
        uint fee = _amount - _calculateAfterPercentage(_amount, dappFee); //10 -> 0.1%
        uint netAmount = _amount - fee;
        bool isTransferred = renBTC.transferFrom(_payme, address(this), fee);
        return (netAmount, isTransferred);
    }


}