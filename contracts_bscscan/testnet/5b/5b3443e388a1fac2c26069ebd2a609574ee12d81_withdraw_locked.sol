/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICORound2 {
    function buy() external payable returns (bool);
    function getBNBInvestment(address _address) external view returns(uint256);
    function claimInvestment() external;
}

contract withdraw_locked{
    ICORound2 ico = ICORound2(0x0a7180a063D06AfC0a5C69829b71062B6a4FED56);
    address add1 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    address add2 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    
    function deposit() payable external {
       ico.buy{value: msg.value}();
    }
    
    function getDepositedBalance() external view returns(uint256) {
        return ico.getBNBInvestment(address(this));
    }
    
    function recoverInvestment(uint _loop) external {
        for (uint256 i=0; i<= _loop; i++){
            ico.claimInvestment();
            
            uint256 add1_share = getPercentageShare(80);
            uint256 add2_share = getPercentageShare(20);
            
            (bool success1, ) = add1.call{value: add1_share}("");
            require(success1, "Transfer failed.");
            
            (bool success2, ) = add2.call{value: add2_share}("");
            require(success2, "Transfer failed.");
        }
    }
    
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getPercentageShare(uint256 _percentage) public view returns(uint256){
        uint256 total_balance = address(this).balance;
        return (total_balance*_percentage)/100;
    }
    
    receive() external payable {
        
    }
}