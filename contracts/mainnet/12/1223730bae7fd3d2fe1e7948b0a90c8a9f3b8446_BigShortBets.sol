/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.1;

// bigshortbets.com collection contract
contract BigShortBets {
    //minimum to collect
    uint256 constant public minETH = 1000 ether;
    //maximum pay-in w/o AML/KYC
    uint256 constant public noAmlMax = 9 ether;

    //list of balances
    mapping(address => uint256) private balances;

    //you-know-who
    address constant public owner = 0x23E7f318C383a5e9af702EE11e342632006A23Cc;

    //flags
    bool collectEnd = false;
    bool failed = false;

    // now + 6 months
    uint256 constant public failsafe = 1629155926;

    //pay in - just send ETH to contract address
    receive() external payable {
        require(!collectEnd, "Collect ended");
        uint256 amount = msg.value + balances[msg.sender];
        //if you want pay in more than 9 ETH - contact staff to KYC/AML
        //and pay directly to owner address
        //not KYC/AML-ed payments will be treated as a donation
        require(amount <= noAmlMax, "Need KYC/AML");
        balances[msg.sender] = amount;
        //fail in case that somethig* happend and collection not closed in 6 months
        if (block.timestamp > failsafe) {
            collectEnd = true;
            failed = true;
        }
        //*ie you-know-who dies
    }

    //check balance paid in - will be needed for token distribution
    function blanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    //total collected by this contract and KYC/AML-ed collect to owner address
    function totalCollected() public view returns (uint256) {
        return address(this).balance + address(owner).balance;
    }

    //withdraw ETH if collection failed
    function withdraw() external {
        require(failed, "Collect not failed");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        send(msg.sender, amount);
    }

    //end collecting - take ETH or fail and allow to withdraw
    function end() external {
        require(!collectEnd, "Collect ended");
        collectEnd = true;
        require(msg.sender == owner, "Only for owner");
        if (totalCollected() < minETH) {
            failed = true;
        } else {
            send(owner, address(this).balance);
        }
    }

    //internal "gas safe" ETH send function
    function send(address user, uint256 amount) private {
        bool success = false;
        (success, ) = address(user).call{value: amount}("");
        require(success, "Send failed");
    }
}

//rav3n_pl was here