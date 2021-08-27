/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract preSale {

    address public owner;

    address public tokenAddress;
    //uint public rate;
    uint public cap;
    uint public minBNBContribution;
    uint public maxBNBContribution;

    //uint public tokensAvaliable;
    uint public weiRaised;
    bool public capReached = false;

    uint total_contributors = 0;
    mapping (address => uint) private contributions;
    mapping (uint => address) public contributor_indices;
    //mapping (address => uint) public t_balances;

    constructor (uint _cap, uint _minBNB, uint _maxBNB) {
        cap = _cap;
        minBNBContribution = _minBNB;
        maxBNBContribution = _maxBNB;
        owner = msg.sender;
    }

    // function approveTokens(uint tokens) public {
    //     // approve the tokens from the sender to this contract
    //     IERC20(tokenAddress).approve(address(this), tokens);
    // }

    // function seeAllowance(address _owner) public view returns (uint) {
    //     // approve the tokens from the sender to this contract
    //     return IERC20(tokenAddress).allowance(_owner, address(this));
    // }

    // function seeBalance( address _addr) public view returns (uint) {
    //     return IERC20(tokenAddress).balanceOf(_addr);
    // }

    // function depositTokens(uint tokens) public {

    //     // add the deposited tokens into existing balance 
    //     t_balances[msg.sender]+= tokens;

    //     // transfer the tokens from the sender to this contract
    //     IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokens);
    // }

    // function returnTokens() public {
    //     uint256 amount = t_balances[msg.sender];
    //     t_balances[msg.sender] = 0;
    //     IERC20(tokenAddress).transfer(msg.sender, amount);
    // }


    function SeeAddressContribution(address _addr) public view returns (uint) {
        return contributions[_addr];
    }

    function setTokenAddress(address _addr) public {
        // Update the value at this address
        tokenAddress = _addr;
    }

    function deposit() public payable {
        require(msg.value >= minBNBContribution, "Deposit Value is Too Small");
        require(msg.value <= maxBNBContribution, "Deposit Value is Too Big");
        require(!capReached, "Cap is already reached");

        weiRaised += msg.value;
        require(weiRaised <= cap, "Reverted: BNB deposit would go over cap");
        
        // 1% offset (Add later)
        if (weiRaised >= cap){
            capReached = true;
        }

        bool found = false;

        for(uint i = 0; i < total_contributors; i++)
        {
            if(contributor_indices[i] == msg.sender)
            {
                found = true;
            }
        }

        require(found == false, "You have already contributed to the presale");
        contributor_indices[total_contributors] = msg.sender;
        contributions[msg.sender] = msg.value;
        total_contributors++;
    }

    function send_BNB_back() external onlyOwner {
        for (uint i = 0 ; i < total_contributors; i++) {
            // use inner mapping to get address, get bnb amount with address, send back that bnb value
            payable(contributor_indices[i]).call{value:contributions[contributor_indices[i]]};
        }
    }

    function withdraw() public onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Failed to send Ether");
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

}