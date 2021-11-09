/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract PlazaTokenCollect {
    using SafeMath for uint256;
    
    address tokenAddr = 0x7Fb96258Ea2EEf7b232a1E4801b473bf6C5A2833; // Plaza Token
    address sendAddr = 0x67537A7786Be4FfbDf48a8BA2fD906cfF9Cb697D;
    address owner; // Owner of contract
    uint8 _decimals = 9;
    uint256 maxAmount = 500000000000000 * 10 ** _decimals;
    uint256 startTime = 1634947200; // Timestamp in blocktime of the start of Swap.
    uint256 initialBonusRatio = 30;
    uint256 endingBonusRatio = 20;
    
    // Stores info on individual swaps
    struct swapInstance {
        address userAddrs;
        uint256 amount;
        uint256 bonusRate;
    }
    
    // Init array of swaps
    swapInstance[] swaps; 
    
    function getCurrentBonusRatio() public view returns (uint256) {
        if (startTime > block.timestamp) return 0;
        
        // Calc the hours passed from started time
        uint256 hoursPassed = (block.timestamp - startTime) / 3600;

        // Calc the bonus ratio
        uint256 bonusRatio;
        
        if (hoursPassed <= 24 * 2) {
            bonusRatio = initialBonusRatio;
        } else {
            bonusRatio = endingBonusRatio;
        }
        return bonusRatio;
    }
    
    modifier owneronly() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) public owneronly {
        owner = _owner;
    }

    function setSendAddress(address _sendAddr) external owneronly {
        sendAddr = _sendAddr;
    }

    function setTokenAddress(address _tokenAddr) external owneronly {
        tokenAddr = _tokenAddr;
    }
    
    function setStartTime(uint32 _startTime) external owneronly {
        startTime = _startTime;
    }

    function getBalanceOfToken(address userAddress)
        external
        view
        returns (uint256)
    {
        return IToken(tokenAddr).balanceOf(userAddress);
    }
       

    constructor() {
        owner = msg.sender;
    }
    
    function getSwaps() public owneronly view returns(swapInstance[] memory) {
        return swaps;
    }
    
    function getUserDeposits(address userAddress) external view returns (uint256) {
        uint256 totalDeposit = 0;
        for (uint i=0; i < swaps.length; i++)
            if (swaps[i].userAddrs == userAddress) {
                totalDeposit += swaps[i].amount;
            }
        return totalDeposit;
    }
    
    function transfer(uint256 amount) public {
        require(amount > 0, "You need to send at least some tokens");
        // Limit token amount
        require(amount <= maxAmount);

        IToken token = IToken(tokenAddr);
        
        // Create a new swapInstance struct to store swap details
        uint256 bonusRatio = getCurrentBonusRatio();
        swapInstance memory swapThis = swapInstance(msg.sender, amount.div(10**_decimals), bonusRatio);
        
        // Push swap details struct into array
        swaps.push(swapThis);

        // Transfer SHIKO tokens to withdraw address
        token.transferFrom(msg.sender, sendAddr, amount);
    }
}