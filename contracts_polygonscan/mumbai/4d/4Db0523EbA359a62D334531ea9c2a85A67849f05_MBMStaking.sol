// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

import "./MBMStakingStorage.sol";
import "./FixedSupplyToken.sol";

contract MBMStaking is MBMStakingStorage, Owned {
    using SafeMath for uint;

    event StakingMbm (address indexed staker, uint stakingAmount, uint period, uint indexed stakingIndex);
    event AppliedForReward(address indexed staker, uint stakedAmount, uint pendingReward, uint indexed stakingIndex);
    event CollectingReward(address indexed staker, uint stakedAmount, uint totalCollected, uint indexed stakingIndex);

    modifier allowedStaking {
        require(allowStaking == true);
        _;
    }

    constructor(address _mbmToken){
        mbmToken = _mbmToken;
        lockupPeriod1 = 30 days;
        lockupPeriod2 = 90 days;
        lockupPeriod3 = 360 days;
        withdrawalPeriod1 = 7 days;
        withdrawalPeriod2 = 4 days;
        withdrawalPeriod3 = 2 days;
        warmupPeriod = 1 days;
        startOfStaking = now;
        allowStaking = true;
    }

    function stakeMbm(uint amount, uint periodInDays) external allowedStaking returns (bool){
        require(amount > 0, "ERR_EMPTY");
        require(periodInDays.mul(86400) == lockupPeriod1 || periodInDays.mul(86400) == lockupPeriod2 || periodInDays.mul(86400) == lockupPeriod3, "ERR_BAD_PERIOD");
        uint endDate = now.add(periodInDays.mul(86400));
        StakingMargin margin;
        if (amount < uint(1000000).mul(10 ** 18)) {
            margin = StakingMargin.LOW;
        } else if (uint(1000000).mul(10 ** 18) >= amount && amount < uint(5000000).mul(10 ** 18)) {
            margin = StakingMargin.MID;
        } else {
            margin = StakingMargin.HIGH;
        }
        stakedBalances.push(StakedBalance(msg.sender, amount, now, endDate, margin, false, 0, 0, false));
        stakedIndexesPerAddress[msg.sender].push(stakedBalances.length - 1);
        stakedPool += amount;
        emit StakingMbm(msg.sender, amount, periodInDays, stakedBalances.length - 1);
        return FixedSupplyToken(mbmToken).transferFrom(msg.sender, address(this), amount);
    }

    function applyToWithdrawStakedMbm(uint index) external {
        uint256 i = stakedIndexesPerAddress[msg.sender][index];
        require(index < stakedBalances.length, "ERR_NOT_FOUND");

        StakedBalance storage balance = stakedBalances[i];
        require(balance.owner == msg.sender, "ERR_NO_PERMISSION");
        require(balance.endDate < now, "ERR_LOCKED");
        require(balance.pendingForWithdrawal == false, "ERR_APPLIED");
        (balance.pendingReward,) = _calculateStakingReward(balance.amount, balance.addedDate, balance.endDate, balance.margin);
        if (balance.margin == StakingMargin.LOW) {
            balance.withdrawalDate = now.add(withdrawalPeriod1);
        } else if (balance.margin == StakingMargin.MID) {
            balance.withdrawalDate = now.add(withdrawalPeriod2);
        } else {
            balance.withdrawalDate = now.add(withdrawalPeriod3);
        }
        balance.pendingForWithdrawal = true;
        emit AppliedForReward(msg.sender, balance.amount, balance.pendingReward, i);
    }

    function withdrawStakedMbm(uint index) external returns (bool){
        uint256 i = stakedIndexesPerAddress[msg.sender][index];
        require(index < stakedBalances.length, "ERR_NOT_FOUND");

        StakedBalance storage balance = stakedBalances[i];

        require(balance.owner == msg.sender, "ERR_NO_PERMISSION");
        require(balance.deleted == false, "ERR_COLLECTED");
        require(balance.withdrawalDate < now && balance.pendingForWithdrawal == true, "ERR_LOCKED");
        require(balance.pendingReward <= rewardPool && balance.amount <= stakedPool, "ERR_NO_FUNDS");

        stakedPool -= balance.amount;
        rewardPool -= balance.pendingReward;
        balance.deleted = true;
        uint tokensToCollect = balance.amount.add(balance.pendingReward);
        emit CollectingReward(msg.sender, balance.amount, tokensToCollect, i);
        return FixedSupplyToken(mbmToken).transfer(msg.sender, tokensToCollect);
    }

    function calculateStakingReward(uint amountStaked, uint startDate, uint endDate, StakingMargin margin) external view returns (uint reward, uint apy){
        return _calculateStakingReward(amountStaked, startDate, endDate, margin);
    }

    function _calculateStakingReward(uint amountStaked, uint startDate, uint endDate, StakingMargin margin) internal view returns (uint _reward, uint _apy){
        uint apy;
        if (margin == StakingMargin.LOW) {
            if (endDate.sub(startDate) == lockupPeriod1) {
                apy = _calculateApy(LOW_STAKE_PERIOD1_CEILING_APY, LOW_STAKE_PERIOD1_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000).div(12), apy);
            } else if (endDate.sub(startDate) == lockupPeriod2) {
                apy = _calculateApy(LOW_STAKE_PERIOD2_CEILING_APY, LOW_STAKE_PERIOD2_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000).div(4), apy);
            } else {
                apy = _calculateApy(LOW_STAKE_PERIOD3_CEILING_APY, LOW_STAKE_PERIOD3_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000), apy);
            }
        } else if (margin == StakingMargin.MID) {
            if (endDate.sub(startDate) == lockupPeriod1) {
                apy = _calculateApy(MID_STAKE_PERIOD1_CEILING_APY, MID_STAKE_PERIOD1_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000).div(12), apy);
            } else if (endDate.sub(startDate) == lockupPeriod2) {
                apy = _calculateApy(MID_STAKE_PERIOD2_CEILING_APY, MID_STAKE_PERIOD2_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000).div(4), apy);
            } else {
                apy = _calculateApy(MID_STAKE_PERIOD3_CEILING_APY, MID_STAKE_PERIOD3_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000), apy);
            }
        } else {
            if (endDate.sub(startDate) == lockupPeriod1) {
                apy = _calculateApy(HIGH_STAKE_PERIOD1_CEILING_APY, HIGH_STAKE_PERIOD1_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000).div(12), apy);
            } else if (endDate.sub(startDate) == lockupPeriod2) {
                apy = _calculateApy(HIGH_STAKE_PERIOD2_CEILING_APY, HIGH_STAKE_PERIOD2_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000).div(4), apy);
            } else {
                apy = _calculateApy(HIGH_STAKE_PERIOD3_CEILING_APY, HIGH_STAKE_PERIOD3_FLOOR_APY, startDate);
                return (amountStaked.mul(apy).div(10000), apy);
            }
        }
    }

    function calculateApy(uint ceilingApy, uint floorApy, uint startDate) external view returns (uint){
        return _calculateApy(ceilingApy, floorApy, startDate);
    }

    //apy * 100
    function _calculateApy(uint ceilingApy, uint floorApy, uint startDate) internal view returns (uint){
        int calculateIfInWarmup = int(startDate.sub(startOfStaking)) - int(warmupPeriod);
        if (calculateIfInWarmup > 1) {
            uint weekStaked = startDate.sub(startOfStaking).sub(86400).div(86400).div(7);
            if (weekStaked < 4) {
                if (weekStaked == 0) {
                    return ceilingApy;
                } else {
                    return ceilingApy.sub(weekStaked.mul(5));
                }
            } else if (weekStaked <8) {
                return ceilingApy.sub((uint(3).mul(5)).add(weekStaked.sub(3).mul(7)));
            } else if (weekStaked < 12) {
                return ceilingApy.sub((uint(3).mul(5).add(uint(4).mul(7))).add(weekStaked.sub(7).mul(10)));
            } else if (weekStaked < 16) {
                return ceilingApy.sub(((uint(3).mul(5)).add(uint(4).mul(7)).add(uint(4).mul(10))).add(weekStaked.sub(15).mul(15)));
            } else if (weekStaked == 28) {
                return floorApy.add(10);
            } else {
                return floorApy;
            }
        } else {
            return 0;
        }
    }

    function topUpRewardPool(uint amount) external onlyOwner returns (bool){
        rewardPool += amount;
        return FixedSupplyToken(mbmToken).transferFrom(msg.sender, address(this), amount);
    }

    function collectRewardPool(uint amount) external onlyOwner returns (bool){
        require(amount <= rewardPool, "ERR no funds");
        rewardPool -= amount;
        return FixedSupplyToken(mbmToken).transfer(msg.sender, amount);
    }

    function setLockupPeriod1(uint _days) external onlyOwner {
        lockupPeriod1 = _days.mul(86400);
    }

    function setLockupPeriod2(uint _days) external onlyOwner {
        lockupPeriod2 = _days.mul(86400);
    }

    function setLockupPeriod3(uint _days) external onlyOwner {
        lockupPeriod3 = _days.mul(86400);
    }

    function setAllowStaking(bool allowed) external onlyOwner {
        allowStaking = allowed;
    }

    function getStakedIndexesPerAddressCount(address addr) external view returns (uint){
        return stakedIndexesPerAddress[addr].length;
    }
}

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// 'FIXED' 'Example Fixed Supply Token' token contract
//
// Symbol      : FIXED
// Name        : Example Fixed Supply Token
// Total supply: 1,000,000.000000000000000000
// Decimals    : 18
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;


/**
* @notice Contract is a inheritable smart contract that will add a
* New modifier called onlyOwner available in the smart contract inheriting it
*
* onlyOwner makes a function only callable from the Token owner
*
*/
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract MBMStakingStorage {

    enum StakingMargin {LOW, MID, HIGH}

    uint16 public constant LOW_STAKE_PERIOD1_CEILING_APY = 950; // 9,5% *100
    uint16 public constant LOW_STAKE_PERIOD1_FLOOR_APY = 600; // 6% *100
    uint16 public constant LOW_STAKE_PERIOD2_CEILING_APY = 1450; // 14,5% *100
    uint16 public constant LOW_STAKE_PERIOD2_FLOOR_APY = 1100; // 11% *100
    uint16 public constant LOW_STAKE_PERIOD3_CEILING_APY = 2150; // 21,5% *100
    uint16 public constant LOW_STAKE_PERIOD3_FLOOR_APY = 1800; // 18% *100

    uint16 public constant MID_STAKE_PERIOD1_CEILING_APY = 1050; // 10,5% *100
    uint16 public constant MID_STAKE_PERIOD1_FLOOR_APY = 700; // 7% *100
    uint16 public constant MID_STAKE_PERIOD2_CEILING_APY = 1550; // 15,5% *100
    uint16 public constant MID_STAKE_PERIOD2_FLOOR_APY = 1200; // 12% *100
    uint16 public constant MID_STAKE_PERIOD3_CEILING_APY = 2250; // 22,5% *100
    uint16 public constant MID_STAKE_PERIOD3_FLOOR_APY = 1900; // 19% *100

    uint16 public constant HIGH_STAKE_PERIOD1_CEILING_APY = 1250; // 12,5% *100
    uint16 public constant HIGH_STAKE_PERIOD1_FLOOR_APY = 900; // 9% *100
    uint16 public constant HIGH_STAKE_PERIOD2_CEILING_APY = 1750; // 17,5% *100
    uint16 public constant HIGH_STAKE_PERIOD2_FLOOR_APY = 1400; // 14% *100
    uint16 public constant HIGH_STAKE_PERIOD3_CEILING_APY = 2450; // 24,5% *100
    uint16 public constant HIGH_STAKE_PERIOD3_FLOOR_APY = 2100; // 21% *100

    uint public rewardPool;
    uint public stakedPool;

    uint public lockupPeriod1;
    uint public lockupPeriod2;
    uint public lockupPeriod3;

    uint public withdrawalPeriod1;
    uint public withdrawalPeriod2;
    uint public withdrawalPeriod3;

    bool public allowStaking;
    uint public startOfStaking;
    uint public warmupPeriod;

    address public mbmToken;

    StakedBalance[] public stakedBalances;
    mapping(address => uint[]) public stakedIndexesPerAddress;

    struct StakedBalance {
        address owner;
        uint amount;
        uint addedDate;
        uint endDate;
        StakingMargin margin;
        bool pendingForWithdrawal;
        uint pendingReward;
        uint withdrawalDate;
        bool deleted;

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Owned.sol";
import "./ERC20Interface.sol";

// ----------------------------------------------------------------------------
// 'FIXED' 'Example Fixed Supply Token' token contract
//
// Symbol      : FIXED
// Name        : Example Fixed Supply Token
// Total supply: 1,000,000.000000000000000000
// Decimals    : 18
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "MBM";
        name = "Mobilum Token";
        decimals = 18;
        _totalSupply = 640000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}