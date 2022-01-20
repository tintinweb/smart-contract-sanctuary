/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity 0.5.13;

contract DoReclaim {
    uint public balanceReceived;

    event Reclaim(address indexed target, uint256 amount);
    event Deposit(address indexed depositor, uint256 amount);
    
    function deposit() public payable {
        balanceReceived += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function doReclaim(address payable target, uint256 amount) external {        
        address(target).transfer(amount);

        emit Reclaim(target, amount);
    }
}