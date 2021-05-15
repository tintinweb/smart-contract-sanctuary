/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity ^0.6.7;

contract Vester {
    address public immutable token;
    address public recipient;

    uint public immutable vestingAmount;
    uint public immutable vestingBegin;
    uint public immutable vestingCliff;
    uint public immutable vestingEnd;

    uint public lastUpdate;

    constructor(
        address token_,
        address recipient_,    
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_
    ) public {
        require(vestingBegin_ >= block.timestamp, 'Vester::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'Vester::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'Vester::constructor: end is too early');

        token = token_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin_;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'Vester::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'Vester::claim: not time yet');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(token).balanceOf(address(this));
        } else {
            amount = mul(vestingAmount, (block.timestamp - lastUpdate)) / (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IERC20(token).transfer(recipient, amount);
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        require(b == 0 || (c = a * b) / b == a, 'Vester::mul: multiplication overflow');
    }    
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}