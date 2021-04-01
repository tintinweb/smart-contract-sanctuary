/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity =0.8.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface IReferralProgram {
    function userSponsorByAddress(address user) external view returns (uint);
    function userSponsor(uint user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userIdByAddress(address user) external view returns (uint);
    function userSponsorAddressByAddress(address user) external view returns (address);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract UnicornReferralProgramLogic is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    address public immutable additionalToken;
    uint[] public levels;
    uint public referralReward;
    IReferralProgram public immutable unicornUsers;
    mapping(address => bool) allowedFeeDistributors;
    
    IRouter public swapRouter;
    bool public isSetPrice;
    uint public discountRate; 
    uint public additionalToRewardTokenRate;

    event DistributeFees(address user, uint amount);
    event SkipFeeDistribution(address user, uint amount);
    event UpdateLevels(uint[] newLevels);
    event UpdateAllowedFeeDistributor(address distributor, bool isAllowed);

    constructor(address mainTokenAddress, address additionalTokenAddress, address unicornUsersReferral, uint inititalRewardToAdditionalTokenRate)  {
        referralReward = 100; //10.0%
        levels = [50, 30, 20];
        rewardToken = IERC20(mainTokenAddress);
        additionalToken = additionalTokenAddress;
        unicornUsers = IReferralProgram(unicornUsersReferral);
        isSetPrice = true;
        additionalToRewardTokenRate = inititalRewardToAdditionalTokenRate;
    }

    receive() payable external {
        revert();
    }

    function processStake(address user, uint amountIn, bool isRewardToken) external {
        if (!isRewardToken) amountIn = getRewardTokenEquivalentAmount(amountIn);
        uint amount = amountIn.mul(referralReward) / 1000;
        if (rewardToken.balanceOf(address(this)) < amount) {
            emit SkipFeeDistribution(user, amount);
            return;
        }
        address sponsor = unicornUsers.userSponsorAddressByAddress(user);
        uint unspent = amount;
        for (uint i; i < levels.length; i++) {
            if (i != 0) sponsor = unicornUsers.userSponsorAddressByAddress(sponsor);
            if (sponsor == address(0)) {
                rewardToken.transfer(unicornUsers.userAddressById(2), unspent);
                break;
            } else {
                uint transferAmount = amount.mul(levels[i]) / 100;
                rewardToken.transfer(sponsor, transferAmount);
                unspent = unspent.sub(transferAmount);
            }
        }
        emit DistributeFees(user, amount);
    } 

    function getRewardTokenEquivalentAmount(uint additionalTokenAmount) public view returns (uint) { 
        if (isSetPrice) {
            return additionalTokenAmount.mul(1e18) / additionalToRewardTokenRate;
        } else {
            return getTokenEquivalentAmountFromRouter(additionalTokenAmount);
        }
    }

    function getTokenEquivalentAmountFromRouter(uint amount) public view returns (uint) {
        address[] memory path = new address[](2);

        path[0] = address(additionalToken);
        path[1] = address(rewardToken);        
        return swapRouter.getAmountsOut(amount, path)[1].mul(1000).div(1000 + discountRate);
    }


    function togglePricePolicy() external onlyOwner {
        isSetPrice = !isSetPrice;
    }

    function updateStakeTokenToBurnTokenRate(uint newRate) external onlyOwner {
        require(newRate > 0, "HardStakingNFTAuction: New rate is must be greater than 0");
        additionalToRewardTokenRate = newRate;
    }    
    
    function updateDiscountRate(uint newDiscountRate) external onlyOwner {
        require(newDiscountRate < 1000, "HardStakingNFTAuction: New discount rate must be less than 1000");
        discountRate = newDiscountRate;
    }

    function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "HardStakingNFTAuction: Address is zero");
        swapRouter = IRouter(newSwapRouter);
    }

    function updateLevels(uint[] memory newLevels) external onlyOwner {
        uint checkSum;
        for (uint i; i < newLevels.length; i++) {
            checkSum += newLevels[i];
        }
        require(checkSum == 100, "Unicorn Referral: Wrong levels amounts");
        levels = newLevels;
        emit UpdateLevels(newLevels);
    }

    function updateAllowedFeeDistributor(address distributor, bool isAllowed) external onlyOwner {
        allowedFeeDistributors[distributor] = isAllowed;
        emit UpdateAllowedFeeDistributor(distributor, isAllowed);
    }

    function updateReferralReward(uint reward) external onlyOwner {
        referralReward = reward;
    }  

    function rescue(address to, address tokenAddress, uint amount) external onlyOwner {
        require(to != address(0), "Unicorn Referral: Cannot rescue to the zero address");
        require(amount > 0, "Unicorn Referral: Cannot rescue 0");

        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    function rescue(address payable to, uint amount) external onlyOwner {
        require(to != address(0), "Unicorn Referral: Cannot rescue to the zero address");
        require(amount > 0, "Unicorn Referral: Cannot rescue 0");

        to.transfer(amount);
    }  
}