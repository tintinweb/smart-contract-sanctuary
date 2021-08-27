/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity 0.5.16;

contract safeMath{
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a, "safeMath: addition overflow");
        return c;
    }
}
contract myContract is safeMath {

    // saves address and amount deposited into deposits.
    mapping(address => uint) public deposits;
    uint public totalDeposits = 0;
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }


    function deposit() public payable {
        // this function allows people to deposit eth into this contract
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        // this statement keeps track of all the deposits
        totalDeposits = add(totalDeposits, msg.value);
        assert(address(this).balance == totalDeposits);
    }
    function withdraw(uint amount) public {
        require(deposits[msg.sender] >= amount, "You do not have enough Ether deposited.");
        if(deposits[msg.sender] >= amount){
            msg.sender.transfer (amount);
            
            deposits[msg.sender] = deposits[msg.sender] - amount;
            totalDeposits = totalDeposits - amount;
        }
    }
}