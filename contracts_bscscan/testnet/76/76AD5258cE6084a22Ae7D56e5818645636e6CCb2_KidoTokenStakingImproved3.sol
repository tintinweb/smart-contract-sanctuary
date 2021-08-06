pragma solidity ^0.5.16;

import "./KidoToken.sol";

contract KidoTokenStakingImproved3{

    address public owner;
    KidoToken public kidoToken;

    uint timeOfStake = block.timestamp;

    address[] public stakers;
    mapping(address => uint256) public startTime;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address => uint) public rewardBalance;
    mapping(address => uint256) public balanceOf;


    constructor(KidoToken _kidoToken) public {
        kidoToken = _kidoToken;
        owner = msg.sender;
    }


        function calculateAverageStartTime(address _usr, uint _newStake) public view returns(uint){

        uint oldStakingTime = SafeMath.mul(startTime[_usr], stakingBalance[_usr]);
        uint newStakingTime = SafeMath.mul(block.timestamp, _newStake);

        uint totalStakingBalance = SafeMath.add(stakingBalance[_usr], _newStake);

        uint totalStakingTime = SafeMath.add(oldStakingTime, newStakingTime);

        uint averageStartTime = SafeMath.div(totalStakingTime, totalStakingBalance);

        return averageStartTime;


        }


      function stakeTokens(uint _amount) public {
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        kidoToken.transferFrom(msg.sender, address(this), _amount);

        if(isStaking[msg.sender]) {

            startTime[msg.sender] = calculateAverageStartTime(msg.sender, _amount);

        }else{
            stakers.push(msg.sender);
            isStaking[msg.sender] = true;
            startTime[msg.sender] = block.timestamp;

        }

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        hasStaked[msg.sender] = true;
    }


        function calculateYieldTime(address _usr) public view returns(uint){
        uint end = block.timestamp;
        uint totalTime = SafeMath.sub(end, startTime[_usr]);
        uint inMinutes = SafeMath.div(totalTime, 60);
        return inMinutes;

         }




        // Unstaking Tokens (Withdraw)

        function unstakeTokens(uint _amount) public {

        //require(stakingBalance[msg.sender] > 0, "staking balance cannot be 0");
        require(stakingBalance[msg.sender]  >= _amount, "Balance should be bigger than the amount");

        if(_amount <= stakingBalance[msg.sender]){

        uint timeStaked = calculateYieldTime(msg.sender);

        //uint yield = SafeMath.div(SafeMath.mul(stakingBalance[msg.sender], timeStaked, 5), 100000);
        uint temp = SafeMath.mul(_amount , timeStaked);
        uint yield = SafeMath.div(temp, 103680); // 500% Yearly. . .

        kidoToken.transfer(msg.sender, _amount + yield);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] - _amount;

        }

        // Update staking status
        if(stakingBalance[msg.sender] <= 0 ){
        isStaking[msg.sender] = false;
      }

   }



       function getRewardBalance(address account) public view returns (uint256) {
      //require(msg.sender == owner, "caller must be the owner");

        uint timeStaked = calculateYieldTime(account);

        uint temp = SafeMath.mul(stakingBalance[account], timeStaked);
        uint yield = SafeMath.div(temp, 103680);

        return yield;

    }



    function emergencyWithdraw(address _to, uint _amount) public {
        // We added this method to transfer funds in case we migrate to a different contract.
        require(msg.sender == owner, "caller must be the owner");

        kidoToken.transfer(_to,_amount);
    }

}