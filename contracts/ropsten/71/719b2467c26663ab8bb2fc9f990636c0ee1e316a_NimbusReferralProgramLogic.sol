/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface INimbusReferralProgram {
    function userSponsor(uint user) external view returns (uint);
    function userSponsorByAddress(address user) external view returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userSponsorAddressByAddress(address user) external view returns (address);
}

interface INimbusStakingPool {
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns (IBEP20);
}

interface INimbusRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external  view returns (uint[] memory amounts);
}

contract NimbusReferralProgramLogic is Ownable { 
    INimbusReferralProgram public immutable users;
    IBEP20 public immutable NBU;
    INimbusRouter public swapRouter;
    INimbusStakingPool[] public stakingPools; 

    uint[] public levels;
    uint public maxLevel;
    uint public maxLevelDepth;
    uint public minTokenAmountForCheck;

    mapping(address => mapping(uint => uint)) private _undistributedFees;
    mapping(address => uint) private _recordedBalances;


    address public specialReserveFund;
    address public swapToken;
    uint public swapTokenAmountForFeeDistributionThreshold;

    event DistributeFees(address indexed token, uint indexed userId, uint amount);
    event DistributeFeesForUser(address indexed token, uint indexed recipientId, uint amount);
    event ClaimEarnedFunds(address indexed token, uint indexed userId, uint unclaimedAmount);
    event TransferToNimbusSpecialReserveFund(address indexed token, uint indexed fromUserId, uint undistributedAmount);
    event UpdateLevels(uint[] newLevels);
    event UpdateSpecialReserveFund(address newSpecialReserveFund);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Nimbus Referral: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address referralUsers, address nbu)  {
        require(referralUsers != address(0) && nbu != address(0), "Nimbus Referral: Address is zero");
        levels = [40, 20, 13, 10, 10, 7];
        maxLevel = 6;
        NBU = IBEP20(nbu);
        users = INimbusReferralProgram(referralUsers);

        minTokenAmountForCheck = 10 * 1e18;
        maxLevelDepth = 25;
    }

    function undistributedFees(address token, uint userId) external view returns (uint) {
        return _undistributedFees[token][userId];
}

    function recordFee(address token, address recipient, uint amount) external lock { 
        uint actualBalance = IBEP20(token).balanceOf(address(this));
        require(actualBalance - amount >= _recordedBalances[token], "Nimbus Referral: Balance check failed");
        uint uiserId = users.userIdByAddress(recipient);
        if (users.userSponsor(uiserId) == 0) uiserId = 0;
        _undistributedFees[token][uiserId] += amount;
        _recordedBalances[token] = actualBalance;
    }

    function distributeEarnedFees(address token, uint userId) external {
        distributeFees(token, userId);
        uint callerId = users.userIdByAddress(msg.sender);
        if (_undistributedFees[token][callerId] > 0) distributeFees(token, callerId);
    }

    function distributeEarnedFees(address token, uint[] memory userIds) external {
        for (uint i; i < userIds.length; i++) {
            distributeFees(token, userIds[i]);
        }
        
        uint callerId = users.userIdByAddress(msg.sender);
        if (_undistributedFees[token][callerId] > 0) distributeFees(token, callerId);
    }

    function distributeEarnedFees(address[] memory tokens, uint userId) external {
        uint callerId = users.userIdByAddress(msg.sender);
        for (uint i; i < tokens.length; i++) {
            distributeFees(tokens[i], userId);
            if (_undistributedFees[tokens[i]][callerId] > 0) distributeFees(tokens[i], callerId);
        }
    }
    
    function distributeFees(address token, uint userId) private {
        require(_undistributedFees[token][userId] > 0, "Nimbus Referral: Undistributed fee is 0");
        uint amount = _undistributedFees[token][userId];
        uint level = transferToSponsor(token, userId, amount, 0, 0); 

        if (level < maxLevel) {
            uint undistributedPercentage;
            for (uint ii = level; ii < maxLevel; ii++) {
                undistributedPercentage += levels[ii];
            }
            uint undistributedAmount = amount * undistributedPercentage / 100;
            _undistributedFees[token][0] += undistributedAmount;
            emit TransferToNimbusSpecialReserveFund(token, userId, undistributedAmount);
        }

        emit DistributeFees(token, userId, amount);
        _undistributedFees[token][userId] = 0;
    }

    function transferToSponsor(address token, uint userId, uint amount, uint level, uint levelGuard) private returns (uint) {
        if (level >= maxLevel) return maxLevel;
        if (levelGuard > maxLevelDepth) return level;
        uint sponsorId = users.userSponsor(userId);
        if (sponsorId < 1000000001) return level;
        address sponsorAddress = users.userAddressById(sponsorId);
        if (isUserBalanceEnough(sponsorAddress)) {
            uint bonusAmount = amount * levels[level] / 100;
            TransferHelper.safeTransfer(token, sponsorAddress, bonusAmount);
            _recordedBalances[token] = _recordedBalances[token] - bonusAmount;
            emit DistributeFeesForUser(token, sponsorId, bonusAmount);
            return transferToSponsor(token, sponsorId, amount, ++level, ++levelGuard);
        } else {
            return transferToSponsor(token, sponsorId, amount, level, ++levelGuard);
        }            
    }

    function isUserBalanceEnough(address user) public view returns (bool) {
        if (user == address(0)) return false;
        uint amount = NBU.balanceOf(user);
        for (uint i; i < stakingPools.length; i++) {
            amount += stakingPools[i].balanceOf(user);
        }
        if (amount < minTokenAmountForCheck) return false;
        address[] memory path = new address[](2);
        path[0] = address(NBU);
        path[1] = swapToken;
        uint tokenAmount = swapRouter.getAmountsOut(amount, path)[1];
        return tokenAmount >= swapTokenAmountForFeeDistributionThreshold;
    }

    function claimSpecialReserveFundBatch(address[] memory tokens) external {
        for (uint i; i < tokens.length; i++) {
            claimSpecialReserveFund(tokens[i]);
        }
    }

    function claimSpecialReserveFund(address token) public {
        uint amount = _undistributedFees[token][0]; 
        require(amount > 0, "Nimbus Referral: No unclaimed funds for selected token");
        TransferHelper.safeTransfer(token, specialReserveFund, amount);
        _recordedBalances[token] -= amount;
        _undistributedFees[token][0] = 0;
    }


        function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "Nimbus Referral: Address is zero");
        swapRouter = INimbusRouter(newSwapRouter);
    }

    function updateSwapToken(address newSwapToken) external onlyOwner {
        require(newSwapToken != address(0), "Nimbus Referral: Address is zero");
        swapToken = newSwapToken;
    }

    function updateSwapTokenAmountForFeeDistributionThreshold(uint threshold) external onlyOwner {
        swapTokenAmountForFeeDistributionThreshold = threshold;
    }

    function updateMaxLevelDepth(uint newMaxLevelDepth) external onlyOwner {
        maxLevelDepth = newMaxLevelDepth;
    }

    function updateMinTokenAmountForCheck(uint newMinTokenAmountForCheck) external onlyOwner {
        minTokenAmountForCheck = newMinTokenAmountForCheck;
    }

    

    function updateStakingPoolAdd(address newStakingPool) external onlyOwner {
        INimbusStakingPool pool = INimbusStakingPool(newStakingPool);
        require (pool.stakingToken() == NBU, "Nimbus Referral: Wrong pool staking tokens");

        for (uint i; i < stakingPools.length; i++) {
            require (address(stakingPools[i]) != newStakingPool, "Nimbus Referral: Pool exists");
        }
        stakingPools.push(INimbusStakingPool(pool));
    }

    function updateStakingPoolRemove(uint poolIndex) external onlyOwner {
        stakingPools[poolIndex] = stakingPools[stakingPools.length - 1];
        stakingPools.pop();
    }
    
    function updateSpecialReserveFund(address newSpecialReserveFund) external onlyOwner {
        require(newSpecialReserveFund != address(0), "Nimbus Referral: Address is zero");
        specialReserveFund = newSpecialReserveFund;
        emit UpdateSpecialReserveFund(newSpecialReserveFund);
    }

    function updateLevels(uint[] memory newLevels) external onlyOwner {
        uint checkSum;
        for (uint i; i < newLevels.length; i++) {
            checkSum += newLevels[i];
        }
        require(checkSum == 100, "Nimbus Referral: Wrong levels amounts");
        levels = newLevels;
        maxLevel = newLevels.length;
        emit UpdateLevels(newLevels);
    }
}

//helper methods for interacting with BEP20 tokens and sending BNB that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        //bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        //bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        //bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}