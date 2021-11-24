/**
 *Submitted for verification at FtmScan.com on 2021-11-24
*/

// File: erc20/OneTimeDistributor.sol


pragma solidity ^0.8.7;


interface IMonsterERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract OneTimeDistributor {
    address public immutable token;
    address public immutable receiver;
    uint public immutable amount;
    bool isClaimed = false;

    event Claimed(address receiver, uint256 amount);

    constructor(address token_, address receiver_, uint amount_) {
        token = token_;
        receiver = receiver_;
        amount = amount_;
    }

    function claim() external {
        require(!isClaimed, 'Already claimed');

        isClaimed = true;
        require(IMonsterERC20(token).mint(receiver, amount), 'Mint failed');

        emit Claimed(receiver, amount);
    }
}