// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.5.16;

import "./DaiToken.sol";
import "./FarmToken.sol";

contract TokenFarm {
    string public name = "Token Farm";
    address public owner;
    FarmToken public farmToken;
    DaiToken public daiToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping (address => bool) public hasStaked;
    mapping (address => bool) public isStaking;

    
    constructor(FarmToken _farmToken, DaiToken _daiToken) public{
       farmToken = _farmToken;
       daiToken = _daiToken;
       owner = msg.sender; 
    }


     /**
     * @notice Stakes/Deposit Dai Token.
     * @dev Stakes Dai Token
     * @param _amount Number of tokens to be deposited.
     */
    function stakeTokens(uint _amount) public {

        require(_amount > 0, "Send an amount > 0");

        //Transfer Dai tokens to this contract for staking
        daiToken.transferFrom(msg.sender, address(this), _amount);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array
        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }

        isStaking[msg.sender] = true;
    }

    /**
     * @notice Untakes/Withdraw Dai Token.
     * @dev Untakes/Withdraw Dai Token.
     */

    function unstakeTokens() public {

        uint balance = stakingBalance[msg.sender];

        require(balance > 0, "Insufficient Balance");

        stakingBalance[msg.sender] = 0;

        daiToken.transfer(msg.sender, balance);

        isStaking[msg.sender] = false;
    }

    /**
     * @notice Issuing Tokens.
     * @dev Issuing Tokens.
     * @param _cursor Starting value of the index that is to be fetched from stakers array.
     * @param _count Number of stakers that is to be fetched from the array. In order to fetch entire array, set count to zero or a number higher than the last index of the array. 
A     */

    function issueTokens(uint _cursor, uint _count) public {
        require(msg.sender == owner, "Caller must be the owner");
        
        for (uint i = _cursor; i < stakers.length && (i < _cursor + _count || _count == 0 ); i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0){
                farmToken.transfer(recipient, balance);
            }
        }
    }

}