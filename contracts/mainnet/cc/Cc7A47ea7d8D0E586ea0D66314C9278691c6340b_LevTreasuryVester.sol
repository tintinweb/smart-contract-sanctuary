/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract LevTreasuryVester {
    using SafeMath for uint256;

    address public lev;
    mapping(address => TreasuryVester) public _Treasury;

    struct TreasuryVester {
        uint256 vestingAmount;
        uint256 vestingBegin;
        uint256 vestingFirst;
        uint256 vestingShare;
        uint256 nextTime;
        uint256 vestingCycle;
    }

    constructor(address _lev) public {
        lev = _lev;
    }

    function creatTreasury(
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingFirst_,
        uint256 vestingShare_,
        uint256 vestingBegin_,
        uint256 vestingCycle_
    ) external {
        require(
            vestingBegin_ >= block.timestamp,
            "TreasuryVester::creat: vesting begin too early"
        );
        require(
            vestingCycle_ >= 24 * 3600 * 30,
            "TreasuryVester::creat: vesting cycle too small"
        );
        TreasuryVester storage treasury = _Treasury[recipient_];
        require(
            treasury.vestingAmount == 0,
            "TreasuryVester::creat: recipient already exists"
        );
        treasury.vestingAmount = vestingAmount_;
        treasury.vestingBegin = vestingBegin_;
        treasury.vestingFirst = vestingFirst_;
        treasury.vestingShare = vestingShare_;
        treasury.nextTime = vestingBegin_;
        treasury.vestingCycle = vestingCycle_;

        ILev(lev).transferFrom(msg.sender, address(this), vestingAmount_);
    }

    function setRecipient(address recipient_) external {
        TreasuryVester storage treasury = _Treasury[msg.sender];
        TreasuryVester storage treasury2 = _Treasury[recipient_];
        require(
            treasury.vestingAmount > 0,
            "TreasuryVester::setRecipient: unauthorized"
        );
        require(
            treasury2.vestingAmount == 0,
            "TreasuryVester::setRecipient: recipient already exists"
        );
        treasury2 = treasury;
        treasury.vestingAmount = 0;
    }

    function claim() external {
        TreasuryVester storage treasury = _Treasury[msg.sender];
        require(
            treasury.vestingAmount > 0,
            "TreasuryVester::claim: not sufficient funds"
        );
        require(
            block.timestamp >= treasury.nextTime,
            "TreasuryVester::claim: not time yet"
        );
        uint256 amount;
        if (treasury.nextTime == treasury.vestingBegin) {
            amount = treasury.vestingFirst;
        } else {
            amount = treasury.vestingShare;
        }
        if (ILev(lev).balanceOf(address(this)) < amount) {
            amount = ILev(lev).balanceOf(address(this));
        }
        if (treasury.vestingAmount < amount) {
            amount = treasury.vestingAmount;
        }
        treasury.nextTime = treasury.nextTime.add(treasury.vestingCycle);
        treasury.vestingAmount = treasury.vestingAmount.sub(amount);
        ILev(lev).transfer(msg.sender, amount);
    }
}

interface ILev {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 rawAmount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}