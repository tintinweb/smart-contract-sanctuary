/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.0;

contract Test {
    using SafeMath for uint256;
    
    IERC20 public LP;
    IERC20 public rewardToken;
    address public LPaddress;
    uint256 rewardBalance;
    address public rewardAddress;
    
    constructor(address _LPaddress, address _rewardAddress) public {
        require(_LPaddress != address(0), "Zero LP address");
        LPaddress = _LPaddress;
        LP = IERC20(LPaddress);
        require(_rewardAddress != address(0), "Zero reward address");
        rewardAddress = _rewardAddress;
        rewardToken = IERC20(rewardAddress);
        
    }
    
    function getUserShares(address from) public view returns(uint256) {
        uint256 userBalance = LP.balanceOf(from);
        uint256 totalSupply = LP.totalSupply();
        uint256 userShare = userBalance.mul(10000).div(totalSupply);
        return(userShare);
    }
    
    function addRewards(uint256 rewardAmount) public returns(bool) {
        uint256 allowance = rewardToken.allowance(msg.sender, address(this));
        require(allowance >= rewardAmount, "Add allowance to the contract");
        rewardToken.transferFrom(msg.sender, address(this), rewardAmount);
        rewardBalance += rewardAmount;
    }
    
    function showUserReward(address from) public view returns(uint256) {
        // require(getUserShares(from) >0, "Not enough liquidity");
        return(getUserShares(from).mul(rewardBalance).div(10000));
    }
    
    function payUser(address from) public returns(bool) {
        require(getUserShares(from) > 0, "Not wnough liquidity");
        uint256 userReward = showUserReward(from);
        rewardToken.transfer(from, userReward);
        rewardBalance -= userReward;
    }
    
    function removeRewards() public returns(bool) {
        require(rewardBalance > 0, "No rewards in the contract");
        rewardToken.transfer(msg.sender, rewardBalance);
        rewardBalance = 0;
    }
}