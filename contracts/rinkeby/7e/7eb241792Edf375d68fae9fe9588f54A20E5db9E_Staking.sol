/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IERC20 {

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Staking {

    constructor(uint rewardrate, address tokenadd, address tokenOwner) {
        _rewardrate = rewardrate;
        Token = IERC20(tokenadd);
        TokenOwner = tokenOwner;
    }

    IERC20 Token;

    uint256 public _rewardrate;


    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    address private Tokenadd;
    address private TokenOwner;

    struct info{
        uint amountEth;
        uint blocknumber;
    }

    mapping(address => info) User;

    function stake() external payable{
        require(msg.value > 0, "Cannot stake 0");
        User[msg.sender].amountEth += msg.value;
        User[msg.sender].blocknumber = block.number;
    }

    function _calculateReward(uint amount, uint blocknumber) internal  view returns (uint){
        uint blockdiff = block.number - blocknumber;
        return (blockdiff*amount*_rewardrate)/100;
    } 

    function withdrawal() external{
        uint tokens = _calculateReward(User[msg.sender].amountEth, User[msg.sender].blocknumber);
        payable(msg.sender).transfer(User[msg.sender].amountEth);
        Token.transferFrom(TokenOwner, msg.sender, tokens);
        delete User[msg.sender];
    }
}