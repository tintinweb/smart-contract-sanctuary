/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity =0.8.0;

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

interface INimbusReferralProgram {
    function userSponsorByAddress(address user) external view returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userSponsorAddressByAddress(address user) external view returns (address);
}

interface INimbusStakingPool {
    function balanceOf(address account) external view returns (uint256);
}

interface INimbusRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external  view returns (uint[] memory amounts);
}

contract NimbusReferralProgram is INimbusReferralProgram, Ownable {
    using SafeMath for uint;

    uint public lastUserId;
    mapping(address => uint) public override userIdByAddress;
    mapping(uint => address) public userAddressById;

    uint[] public levels;
    uint public maxLevel;
    uint public maxLevelDepth;
    uint public minTokenAmountForCheck;

    mapping(uint => uint) private _userSponsor;
    mapping(address => mapping(uint => uint)) private _undistributedFees;
    mapping(uint => uint[]) private _userReferrals;
    mapping(uint => bool) private _networkBonus;
    mapping(address => uint) private _recordedBalances;
    mapping(uint => mapping(uint => uint)) private _legacyBalances;
    mapping(uint => mapping(uint => bool)) private _legacyBalanceStatus;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("UpdateUserAddressBySig(uint256 id,address user,uint256 nonce,uint256 deadline)");
    bytes32 public constant UPDATE_ADDRESS_TYPEHASH = 0x965f73b57f3777233e641e140ef6fc17fb3dd7594d04c94df9e3bc6f8531614b;
    // keccak256("UpdateUserDataBySig(uint256 id,address user,bytes32 refHash,uint256 nonce,uint256 deadline)");
    bytes32 public constant UPDATE_DATA_TYPEHASG = 0x48b1ff889c9b587c3e7ddba4a9f57008181c3ed75eabbc6f2fefb3a62e987e95;
    mapping(address => uint) public nonces;

    IERC20 public immutable NBU;
    INimbusRouter public swapRouter;                
    INimbusStakingPool[] public stakingPools; 
    address public migrator;
    address public specialReserveFund;
    address public swapToken;                       
    uint public swapTokenAmountForFeeDistributionThreshold;

    event DistributeFees(address token, uint userId, uint amount);
    event DistributeFeesForUser(address token, uint recipientId, uint amount);
    event ClaimEarnedFunds(address token, uint userId, uint unclaimedAmount);
    event TransferToNimbusSpecialReserveFund(address token, uint fromUserId, uint undistributedAmount);
    event UpdateLevels(uint[] newLevels);
    event UpdateSpecialReserveFund(address newSpecialReserveFund);
    event MigrateUserBySign(address signatory, uint userId, address userAddress, uint nonce);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Nimbus: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address migratorAddress, address nbu)  {
        migrator = migratorAddress;
        levels = [40, 20, 13, 10, 10, 7];
        maxLevel = 6;
        NBU = IERC20(nbu);

        minTokenAmountForCheck = 10 * 10 ** 18;
        maxLevelDepth = 25;

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("NimbusReferralProgram")),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    receive() payable external {
        revert();
    }

    modifier onlyMigrator() {
        require(msg.sender == migrator, "Nimbus Referral: caller is not the migrator");
        _;
    }

    function userSponsorByAddress(address user) external override view returns (uint) {
        return _userSponsor[userIdByAddress[user]];
    }

    function userSponsor(uint user) external view returns (uint) {
        return _userSponsor[user];
    }

    function userSponsorAddressByAddress(address user) external override view returns (address) {
        uint sponsorId = _userSponsor[userIdByAddress[user]];
        if (sponsorId < 1000000001) return address(0);
        else return userAddressById[sponsorId];
    }

    function getUserReferrals(uint userId) external view returns (uint[] memory) {
        return _userReferrals[userId];
    }

    function getUserReferrals(address user) external view returns (uint[] memory) {
        return _userReferrals[userIdByAddress[user]];
    }

    function getLegacyBalance(uint id) external view returns (uint NBU_USDT, uint GNBU_USDT) {
        NBU_USDT = _legacyBalances[id][0];
        GNBU_USDT = _legacyBalances[id][1];
    }

    function getLegacyBalanceProcessStatus(uint id) external view returns (bool NBU_USDT, bool GNBU_USDT) {
        NBU_USDT = _legacyBalanceStatus[id][0];
        GNBU_USDT = _legacyBalanceStatus[id][1];
    }

    function undistributedFees(address token, uint userId) external view returns (uint) {
        return _undistributedFees[token][userId];
    }




    function registerBySponsorAddress(address sponsorAddress) external returns (uint) { 
        return registerBySponsorId(userIdByAddress[sponsorAddress]);
    }

    function register() public returns (uint) {
        return registerBySponsorId(1000000001);
    }

    function registerBySponsorId(uint sponsorId) public returns (uint) {
        require(userIdByAddress[msg.sender] == 0, "Nimbus Referral: Already registered");
        require(_userSponsor[sponsorId] != 0, "Nimbus Referral: No such sponsor");
        
        uint id = ++lastUserId; //gas saving
        userIdByAddress[msg.sender] = id;
        userAddressById[id] = msg.sender;
        _userSponsor[id] = sponsorId;
        _userReferrals[sponsorId].push(id);
        return id;
    }

    function recordFee(address token, address recipient, uint amount) external lock { 
        uint actualBalance = IERC20(token).balanceOf(address(this));
        require(actualBalance - amount >= _recordedBalances[token], "Nimbus Referral: Balance check failed");
        uint uiserId = userIdByAddress[recipient];
        if (_userSponsor[uiserId] == 0) uiserId = 0;
        _undistributedFees[token][uiserId] = _undistributedFees[token][uiserId].add(amount);
        _recordedBalances[token] = actualBalance;
    }

    function distributeEarnedFees(address token, uint userId) external {
        distributeFees(token, userId);
        uint callerId = userIdByAddress[msg.sender];
        if (_undistributedFees[token][callerId] > 0) distributeFees(token, callerId);
    }

    function distributeEarnedFees(address token, uint[] memory userIds) external {
        for (uint i; i < userIds.length; i++) {
            distributeFees(token, userIds[i]);
        }
        
        uint callerId = userIdByAddress[msg.sender];
        if (_undistributedFees[token][callerId] > 0) distributeFees(token, callerId);
    }

    function distributeEarnedFees(address[] memory tokens, uint userId) external {
        uint callerId = userIdByAddress[msg.sender];
        for (uint i; i < tokens.length; i++) {
            distributeFees(tokens[i], userId);
            if (_undistributedFees[tokens[i]][callerId] > 0) distributeFees(tokens[i], callerId);
        }
    }
    
    function distributeFees(address token, uint userId) private {
        require(_undistributedFees[token][userId] > 0, "Undistributed fee is 0");
        uint amount = _undistributedFees[token][userId];
        uint level = transferToSponsor(token, userId, amount, 0, 0); 

        if (level < maxLevel) {
            uint undistributedPercentage;
            for (uint ii = level; ii < maxLevel; ii++) {
                undistributedPercentage += levels[ii];
            }
            uint undistributedAmount = amount * undistributedPercentage / 100;
            _undistributedFees[token][0] = _undistributedFees[token][0].add(undistributedAmount);
            emit TransferToNimbusSpecialReserveFund(token, userId, undistributedAmount);
        }

        emit DistributeFees(token, userId, amount);
        _undistributedFees[token][userId] = 0;
    }

    function transferToSponsor(address token, uint userId, uint amount, uint level, uint levelGuard) private returns (uint) {
        if (level >= maxLevel) return maxLevel;
        if (levelGuard > maxLevelDepth) return level;
        uint sponsorId = _userSponsor[userId];
        if (sponsorId < 1000000001) return level;
        address sponsorAddress = userAddressById[sponsorId];
        if (isUserBalanceEnough(sponsorAddress)) {
            uint bonusAmount = amount.mul(levels[level]) / 100;
            TransferHelper.safeTransfer(token, sponsorAddress, bonusAmount);
            _recordedBalances[token] = _recordedBalances[token].sub(bonusAmount);
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
            amount = amount.add(stakingPools[i].balanceOf(user));
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
        _recordedBalances[token] = _recordedBalances[token].sub(amount);
        _undistributedFees[token][0] = 0;
    }




    function migrateUsers(uint[] memory ids, uint[] memory sponsorId, address[] memory userAddress, uint[] memory nbuUsdt) external onlyMigrator {
        require(lastUserId == 0, "Nimbus Referral: Basic migration is finished"); 
        require(ids.length == sponsorId.length, "Nimbus Referral: Different array lengths");     
        for (uint i; i < ids.length; i++) {
            uint id = ids[i];
            _userSponsor[id] = sponsorId[i];
            if (userAddress[i] != address(0)) {
                userIdByAddress[userAddress[i]] = id;
                userAddressById[id] = userAddress[i];
            }
            if (nbuUsdt[i] > 0) _legacyBalances[id][0] = nbuUsdt[i];
        }
    } 

    function updateUserLegacyBalances(uint currencyId, uint[] memory ids, uint[] memory balances) external onlyMigrator {
        require(ids.length == balances.length, "Nimbus Referral: Different array lengths");     
        for (uint i; i < ids.length; i++) {
            _legacyBalances[ids[i]][currencyId] = balances[i];
        }
    }

    function updateUserLegacyBalanceStatuses(uint currencyId, uint[] memory ids, bool[] memory status) external onlyMigrator {
        require(ids.length == status.length, "Nimbus Referral: Different array lengths");     
        for (uint i; i < ids.length; i++) {
            _legacyBalanceStatus[ids[i]][currencyId] = status[i];
        }
    }

    function updateUserAddress(uint id, address userAddress) external onlyMigrator {
        require(userAddress != address(0), "Nimbus Referral: Address is zero");
        require(_userSponsor[id] < 1000000001, "Nimbus Referral: No such user");
        require(userIdByAddress[userAddress] == 0, "Nimbus Referral: Address is already in the system");
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
    }

    function updateUserAddressBySig(uint id, address userAddress, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: signature expired");
        require(userIdByAddress[userAddress] == 0, "Nimbus Referral: Address is already in the system");
        uint nonce = nonces[userAddress]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_ADDRESS_TYPEHASH, id, userAddress, nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus: INVALID_SIGNATURE');
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
        emit MigrateUserBySign(recoveredAddress, id, userAddress, nonce);
    }

    function updateUserDataBySig(uint id, address userAddress, uint[] memory referrals, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: signature expired");
        uint nonce = nonces[userAddress]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_DATA_TYPEHASG, id, userAddress, keccak256(abi.encodePacked(referrals)), nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus: INVALID_SIGNATURE');
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
        _userReferrals[id] = referrals;
        emit MigrateUserBySign(recoveredAddress, id, userAddress, nonce);
    }

    function updateUserReferralsBySig(uint id, address userAddress, uint[] memory referrals, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: signature expired");
        uint nonce = nonces[userAddress]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_DATA_TYPEHASG, id, userAddress, keccak256(abi.encodePacked(referrals)), nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus: INVALID_SIGNATURE');
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
        for (uint i; i < referrals.length; i++) {
            _userReferrals[id].push(referrals[i]);
        }
        emit MigrateUserBySign(recoveredAddress, id, userAddress, nonce);
    }

    function updateUserReferrals(uint id, uint[] memory referrals) external onlyMigrator {
        _userReferrals[id] = referrals;
        for (uint i; i < referrals.length; i++) {
            _userReferrals[id].push(referrals[i]);
        }
    }

    function updateMigrator(address newMigrator) external onlyMigrator {
        require(newMigrator != address(0), "Nimbus Referral: Address is zero");
        migrator = newMigrator;
    }

    function finishBasicMigration(uint userId) external onlyMigrator {
        lastUserId = userId;
    }




    function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "Address is zero");
        swapRouter = INimbusRouter(newSwapRouter);
    }

    function updateSwapToken(address newSwapToken) external onlyOwner {
        require(newSwapToken != address(0), "Address is zero");
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
        for (uint i; i < stakingPools.length; i++) {
            require (address(stakingPools[i]) != newStakingPool, "Pool exists");
        }
        stakingPools.push(INimbusStakingPool(newStakingPool));
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

//helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}