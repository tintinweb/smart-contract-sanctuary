// SPDX-License-Identifier: MIT
// from: https://github.com/dappuniversity/defi_tutorial/tree/starter-code
pragma solidity ^0.5.0;

import "./DappToken.sol";
import "./DaiToken.sol";

contract TokenFarm {
    string public name = "Dapp Token Farm";
    DappToken public dappToken;
    DaiToken public daiToken;
    address public owner;
    uint8 public stakingPercent;

    event IssueTokens(
        address indexed _investor,
        uint8 _stakingPercent,
        string _token,
        uint256 _value
    );

    event StakeTokens(
        address indexed _investor,
        string _token,
        uint256 _value
    );

    event UnstakeTokens(
        address indexed _investor,
        string _token,
        uint256 _value
    );

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller must be the owner");
        _;
    }

    constructor (DappToken _dappToken, DaiToken _daiToken, uint8 _stakingPercent) public {
        dappToken = _dappToken;
        daiToken = _daiToken;
        stakingPercent = _stakingPercent;
        owner = msg.sender;
    }

    // Stakes tokens (deposit DAI)
    function stakeTokens(uint _amount) public {
        require(_amount > 0, "amount cannot be 0");
        daiToken.transferFrom(msg.sender, address(this), _amount);

        // TODO: record times of each staked amount for better token issuing logic
        stakingBalance[msg.sender] += _amount;

        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true; // for future use
        emit StakeTokens(msg.sender, daiToken.symbol(), _amount);
    }

    // Issuing Tokens to all stakers based on current stakingPercent
    function issueTokens() public onlyOwner {
        for(uint i=0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient] * (stakingPercent/100);
            if (balance > 0) {
                dappToken.transfer(recipient, balance);
                emit IssueTokens(recipient, stakingPercent, daiToken.symbol(), balance);
            }
        }
    }

    // Unstaking tokens (withdraw DAI)
    function unstakeTokens() public {
        uint balance = stakingBalance[msg.sender];
        require(balance > 0, "amount cannot be 0");
        require(isStaking[msg.sender] == true, "must be staking to unstake");
        
        stakingBalance[msg.sender] = 0;
        isStaking[msg.sender] = false;

        daiToken.transfer(msg.sender, balance);
        emit UnstakeTokens(msg.sender, daiToken.symbol(), balance);
    }

}