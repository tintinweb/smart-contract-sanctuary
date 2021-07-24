/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity 0.6.0;
// SPDX-License-Identifier: UNLICENSED

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20 {
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool); 
}


contract Wortheum {
    uint256 public totalMember = 10000;
    uint256 public totalInvestmentCount = 50000;
    mapping(uint256 => Member) private member;
    mapping(uint256 => Investments) private investments;
    address private ownerAddress;
    
    address public _token = 0x7b0CB0481E20448B030DeB3F292b61605EcEf050; // LTM Token by Broken Pie Pvt Ltd.
    ERC20 public token = ERC20(_token);


    constructor() public {
        ownerAddress = msg.sender;
    }

    struct Member {
        uint256 id;
        string name;
        string sponsor;
        string leg;
        string placement;
        address wallet_address;
    }

    struct Investments {
        uint256 id;
        uint256 member_id;
        uint256 amount;
        address wallet;
        uint192 step;
    }

    function Register(string memory name, string memory sponsor, string memory leg, string memory placement) public returns (uint256){
        totalMember++;
        member[totalMember] = Member(totalMember, name, sponsor, leg, placement, msg.sender);
        return totalMember;
    }


    function Invest(uint256 id, address contractAddress, address Hexaddress, uint amount, uint192 packageId, address one, address two, address three, address four) public {
        totalInvestmentCount++;
        token.approve(msg.sender,amount);
        token.transferFrom(msg.sender,address(this),amount);
        token.approve(contractAddress,amount);
        uint256 oneAmount = amount*5/100;
        uint256 twoAmount = amount*2/100;
        uint256 threeAmount = amount*1/100;
        
        // Send Referral Commission
        
        uint256 ownerAmount = amount*91/100;
        if(one == address(one)){
        token.transferFrom(address(this),one,oneAmount);
        }
        if(two == address(two)){
        token.transferFrom(address(this),two,twoAmount);
        }
        if(three == address(three)){
        token.transferFrom(address(this),three,threeAmount);
        }
        
        token.transferFrom(address(this),Hexaddress,ownerAmount);
        Investments(totalInvestmentCount, id, amount, msg.sender, packageId);
    }
    
    function referral_commission(uint256 id, uint256 amount) public payable{
         for (uint index = 50000; index < totalMember; index++) {
            if (member[index].id == id) {
        address payable receiver = payable(member[index].wallet_address);
        receiver.transfer(amount);
            }
        }
    }

    function checkBalance(address wallet) public view returns (uint256){
        return wallet.balance;
    }

    function checkInvestment(address wallet) public view returns (uint256){
        for (uint index = 50000; index < totalInvestmentCount; index++) {
            if (investments[index].wallet == wallet) {
                return investments[index].amount;
            }else{
            return investments[50001].amount;
            }
        }
        return 0;
    }
}