/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.10;

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

  
    contract Refinancle {
        
        // call it DefiBank
        string public name = "Refinancle";

        // Owner of the bank
        address public owner;


        // create 2 state variables
        IERC20  USDToken;


        address[] public stakers;
        mapping(address => uint) public stakingBalance;
        mapping(address => bool) public hasStaked;
        mapping(address => bool) public isStaking;
        uint256 public totalStaked = 0;
        



        event AddInterest( address indexed to, uint256 value);



        // in constructor pass in the address for USDToken token and your custom bank token
        // that will be used to pay interest
        constructor(address usdToken) {
            USDToken = IERC20(usdToken);
            owner = msg.sender;
        }



        modifier onlyOwner() {
            require(msg.sender == owner , "unauthorized: not owner");
            _;
        }


        function changeOwner(address newOwner) public onlyOwner {
            // reqire the permission of the current owner
            owner = newOwner;
        }


        // allow user to stake USDToken tokens in contract
        
        function stakeTokens(uint256 _amount) public {

            require(USDToken.balanceOf(msg.sender) >= _amount, "You don't have enought of USD");
            // Allow Dapp to get the amount of USD
            IERC20(USDToken).approve(address(this), _amount);
            // Trasnfer HTGToken tokens to contract for staking
            USDToken.transferFrom(msg.sender, address(this), _amount);

            uint256 interest = _amount * 50 / 10000;
            uint256 restAmount = _amount -  interest;

            uint256 interestOwner = interest/5;
            interest -= interestOwner;

            USDToken.transfer(owner, interestOwner);
            // Update the staking balance in map
            stakingBalance[msg.sender] = stakingBalance[msg.sender] + restAmount;
            
            totalStaked += restAmount;

            //Distribute the interest
            issueInterest(interest, 1);

            // Add user to stakers array if they haven't staked already
            if(!hasStaked[msg.sender]) {
                stakers.push(msg.sender);
            }

            // Update staking status to track
            isStaking[msg.sender] = true;
            hasStaked[msg.sender] = true;
        }

            // allow user to unstake total balance and withdraw USDToken from the contract
        
        function unstakeTokens() public {

            // get the users staking balance in USDToken
            uint balance = stakingBalance[msg.sender];
        
            // reqire the amount staked needs to be greater then 0
            require(balance > 0, "staking balance can not be 0");
        

            uint256 interest = balance * 50 / 10000;
            uint256 restBalance = balance -  interest;

            uint256 interestOwner = interest / 5;
            interest -= interestOwner;

            USDToken.transfer(owner, interestOwner);
            // transfer USDToken tokens out of this contract to the msg.sender
            USDToken.transfer(msg.sender, restBalance);
        
            // reset staking balance map to 0
            stakingBalance[msg.sender] = 0;
        
            totalStaked -= restBalance;

            issueInterest(interest, 0);
            // update the staking status
            isStaking[msg.sender] = false;

    } 


    // Issue bank tokens as a reward for staking
    
    function issueInterest(uint256 _amount, uint operation)  internal {

            for (uint i=0; i<stakers.length; i++) {
                
                    address recipient = stakers[i];
                    if(recipient!=msg.sender){
                        uint balance = stakingBalance[recipient];

                        uint256 interest = _amount * getInterest(balance) / 10**8;

                        stakingBalance[recipient] += interest;
                        emit AddInterest(recipient, interest);

                        if(operation==1)
                            totalStaked += interest;
                        else
                            totalStaked -= interest;

                    }
                    
                    
            }
   
    }

    function getInterest (uint256 balance) internal view returns(uint256) {
             return (balance * 100 * 10**6) / totalStaked;
    }
}