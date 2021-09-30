/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract ChainfiBaseBank {

    address public token1;
    address public token2;
    address public chainfiToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
        chainfiToken = 0x4293c4c9a75D5554Da71a5746Dd8560453FD3ca7;
    }


    // allow user to stake tokens in contract
    function stakeTokens(uint _amount) public {

        // Trasnfer tokens to contract for staking
        IERC20(token1).transferFrom(msg.sender, address(this), _amount);
        IERC20(token2).transferFrom(msg.sender, address(this), _amount);

        // Update the staking balance in map
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status to track
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // allow user to unstake total balance and withdraw USDC from the contract
    function unstakeTokens() public {

    	// get the users staking balance in usdc
    	uint balance = stakingBalance[msg.sender];
    
        // reqire the amount staked needs to be greater then 0
        require(balance > 0, "staking balance can not be 0");
    
        // transfer usdc tokens out of this contract to the msg.sender
        IERC20(token1).transfer(msg.sender, balance);
        IERC20(token2).transfer(msg.sender, balance);
    
        // reset staking balance map to 0
        stakingBalance[msg.sender] = 0;
    
        // update the staking status
        isStaking[msg.sender] = false;

    } 


    // Issue bank tokens as a reward for staking
    function issueInterestToken() public {
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];

            if(balance > 0) {
                // Percentage here?
                IERC20(chainfiToken).transfer(recipient, balance);
            }
        }
    }
}

contract ChainfiBusdBank is ChainfiBaseBank (0x4293c4c9a75D5554Da71a5746Dd8560453FD3ca7, 0x0000000000000000000000000000000000000000) {
    
    string public name = "ChainFi & BUSD Bank";
    

    constructor() {}
}

contract ChainfiBnbBank is ChainfiBaseBank (0x4293c4c9a75D5554Da71a5746Dd8560453FD3ca7, 0x0000000000000000000000000000000000000000) {

    
    string public name = "ChainFi & BNB Bank";
    

    constructor() {}
}

contract BusdBnbBank is ChainfiBaseBank (0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000) {
       
    string public name = "BUSD & BNB Bank";

    constructor() {}
}