/**
 *Submitted for verification at FtmScan.com on 2022-01-23
*/

// File: ..\Contracts\Rewarder.sol

    // SPDX-License-Identifier: MIT

    // Special Thanks to @BoringCrypto for his ideas and patience

    pragma solidity 0.6.12;
    pragma experimental ABIEncoderV2;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedSafeMath.sol
    library SignedSafeMath {
        int256 constant private _INT256_MIN = -2**255;

        /**
        * @dev Returns the multiplication of two signed integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `*` operator.
        *
        * Requirements:
        *
        * - Multiplication cannot overflow.
        */
        function mul(int256 a, int256 b) internal pure returns (int256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
                return 0;
            }

            require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

            int256 c = a * b;
            require(c / a == b, "SignedSafeMath: multiplication overflow");

            return c;
        }

        /**
        * @dev Returns the integer division of two signed integers. Reverts on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function div(int256 a, int256 b) internal pure returns (int256) {
            require(b != 0, "SignedSafeMath: division by zero");
            require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

            int256 c = a / b;

            return c;
        }

        /**
        * @dev Returns the subtraction of two signed integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
        function sub(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a - b;
            require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

            return c;
        }

        /**
        * @dev Returns the addition of two signed integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `+` operator.
        *
        * Requirements:
        *
        * - Addition cannot overflow.
        */
        function add(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a + b;
            require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

            return c;
        }

        function toUInt256(int256 a) internal pure returns (uint256) {
            require(a >= 0, "Integer < 0");
            return uint256(a);
        }
    }

    /// @notice A library for performing overflow-/underflow-safe math,
    /// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
    library BoringMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
            require((c = a + b) >= b, "BoringMath: Add Overflow");
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
            require((c = a - b) <= a, "BoringMath: Underflow");
        }

        function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
            require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
        }

        function to128(uint256 a) internal pure returns (uint128 c) {
            require(a <= uint128(-1), "BoringMath: uint128 Overflow");
            c = uint128(a);
        }

        function to64(uint256 a) internal pure returns (uint64 c) {
            require(a <= uint64(-1), "BoringMath: uint64 Overflow");
            c = uint64(a);
        }

        function to32(uint256 a) internal pure returns (uint32 c) {
            require(a <= uint32(-1), "BoringMath: uint32 Overflow");
            c = uint32(a);
        }
    }

    /// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
    library BoringMath128 {
        function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
            require((c = a + b) >= b, "BoringMath: Add Overflow");
        }

        function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
            require((c = a - b) <= a, "BoringMath: Underflow");
        }
    }


    contract BoringOwnableData {
        address public owner;
        address public pendingOwner;
    }

    contract BoringOwnable is BoringOwnableData {
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        /// @notice `owner` defaults to msg.sender on construction.
        constructor() public {
            owner = msg.sender;
            emit OwnershipTransferred(address(0), msg.sender);
        }

        /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
        /// Can only be invoked by the current `owner`.
        /// @param newOwner Address of the new owner.
        /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
        /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
        function transferOwnership(
            address newOwner,
            bool direct,
            bool renounce
        ) public onlyOwner {
            if (direct) {
                // Checks
                require(newOwner != address(0) || renounce, "Ownable: zero address");

                // Effects
                emit OwnershipTransferred(owner, newOwner);
                owner = newOwner;
                pendingOwner = address(0);
            } else {
                // Effects
                pendingOwner = newOwner;
            }
        }

        /// @notice Needs to be called by `pendingOwner` to claim ownership.
        function claimOwnership() public {
            address _pendingOwner = pendingOwner;

            // Checks
            require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

            // Effects
            emit OwnershipTransferred(owner, _pendingOwner);
            owner = _pendingOwner;
            pendingOwner = address(0);
        }

        /// @notice Only allows the `owner` to execute the function.
        modifier onlyOwner() {
            require(msg.sender == owner, "Ownable: caller is not the owner");
            _;
        }
    }

    interface IERC20 {
        function totalSupply() external view returns (uint256);

        function balanceOf(address account) external view returns (uint256);

        function allowance(address owner, address spender) external view returns (uint256);

        function approve(address spender, uint256 amount) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);

        /// @notice EIP 2612
        function permit(
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external;
    }


    library BoringERC20 {
        bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
        bytes4 private constant SIG_NAME = 0x06fdde03; // name()
        bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
        bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
        bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

        function returnDataToString(bytes memory data) internal pure returns (string memory) {
            if (data.length >= 64) {
                return abi.decode(data, (string));
            } else if (data.length == 32) {
                uint8 i = 0;
                while(i < 32 && data[i] != 0) {
                    i++;
                }
                bytes memory bytesArray = new bytes(i);
                for (i = 0; i < 32 && data[i] != 0; i++) {
                    bytesArray[i] = data[i];
                }
                return string(bytesArray);
            } else {
                return "???";
            }
        }

        /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
        /// @param token The address of the ERC-20 token contract.
        /// @return (string) Token symbol.
        function safeSymbol(IERC20 token) internal view returns (string memory) {
            (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
            return success ? returnDataToString(data) : "???";
        }

        /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
        /// @param token The address of the ERC-20 token contract.
        /// @return (string) Token name.
        function safeName(IERC20 token) internal view returns (string memory) {
            (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
            return success ? returnDataToString(data) : "???";
        }

        /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
        /// @param token The address of the ERC-20 token contract.
        /// @return (uint8) Token decimals.
        function safeDecimals(IERC20 token) internal view returns (uint8) {
            (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
            return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
        }

        /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
        /// Reverts on a failed transfer.
        /// @param token The address of the ERC-20 token.
        /// @param to Transfer tokens to.
        /// @param amount The token amount.
        function safeTransfer(
            IERC20 token,
            address to,
            uint256 amount
        ) internal {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
        }

        /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
        /// Reverts on a failed transfer.
        /// @param token The address of the ERC-20 token.
        /// @param from Transfer tokens from.
        /// @param to Transfer tokens to.
        /// @param amount The token amount.
        function safeTransferFrom(
            IERC20 token,
            address from,
            address to,
            uint256 amount
        ) internal {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
        }
    }

    contract BaseBoringBatchable {
        /// @dev Helper function to extract a useful revert message from a failed call.
        /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
        function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
            // If the _res length is less than 68, then the transaction failed silently (without a revert message)
            if (_returnData.length < 68) return "Transaction reverted silently";

            assembly {
                // Slice the sighash.
                _returnData := add(_returnData, 0x04)
            }
            return abi.decode(_returnData, (string)); // All that remains is the revert string
        }

        /// @notice Allows batched call to self (this contract).
        /// @param calls An array of inputs for each call.
        /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
        /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
        /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
        // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
        // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
        // C3: The length of the loop is fully under user control, so can't be exploited
        // C7: Delegatecall is only used on the same contract, so it's safe
        function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results) {
            successes = new bool[](calls.length);
            results = new bytes[](calls.length);
            for (uint256 i = 0; i < calls.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
                require(success || !revertOnFail, _getRevertMsg(result));
                successes[i] = success;
                results[i] = result;
            }
        }
    }

    contract BoringBatchable is BaseBoringBatchable {
        /// @notice Call wrapper that performs `ERC20.permit` on `token`.
        /// Lookup `IERC20.permit`.
        // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
        //     if part of a batch this could be used to grief once as the second call would not need the permit
        function permitToken(
            IERC20 token,
            address from,
            address to,
            uint256 amount,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) public {
            token.permit(from, to, amount, deadline, v, r, s);
        }
    }

    interface IRewarder {
        function onReward(uint256 pid, address user, uint256 averageBlockDeposit, uint256 newLpAmount) external;
        function pendingTokens(uint256 pid, address user, uint256 TokenAmount) external view returns (IERC20[] memory, uint256[] memory);
        function claim(uint256 _pid, address _user, uint256 _averageDeposit, address to) external returns(uint256);
    }


    interface IMigratorChef {
        // Take the current LP token address and return the new LP token address.
        // Migrator should have full access to the caller's LP token.
        function migrate(IERC20 token) external returns (IERC20);
    }

    interface IMasterMind {
        using BoringERC20 for IERC20;
        struct UserInfo {
            uint256 shares;
            uint256 averageBlockDeposit;
        }
        struct PoolInfo {
            address target;
            address adapter;
            uint256 targetPoolId;
            uint256 drainModifier;
            uint256 totalShares;
            uint256 totalDeposits;
            uint256 entranceFee;
        }
        function poolInfo(uint256 pid) external view returns (IMasterMind.PoolInfo memory);
        function userInfo(uint256 pid, address user) external view returns (IMasterMind.UserInfo memory);
        function totalAllocPoint() external view returns (uint256);
        function deposit(uint256 _pid, uint256 _amount) external;
        function withdraw(uint256 _pid, uint256 _amount) external;
        function userShares(uint256 _pid, address user) external view returns (uint256);
    }


    contract Rewarder is IRewarder,  BoringOwnable{
        using BoringMath for uint256;
        using BoringMath128 for uint128;
        using BoringERC20 for IERC20;

        IERC20 public immutable rewardToken;

        /// @notice Info of each MM user.
        /// `amount` LP token amount the user has provided.
        /// `rewardDebt` The amount of Token entitled to the user.
        struct UserInfo {
            uint256 amount;
            uint256 rewardDebt;
        }

        /// @notice Info of each MM pool.
        /// `allocPoint` The amount of allocation points assigned to the pool.
        /// Also known as the amount of Token to distribute per block.
        struct PoolInfo {
            uint128 accTokenPerBillonShares;
            uint64 lastRewardBlock;
            uint64 allocPoint;
        }

        /// @notice Info of each pool.
        mapping (uint256 => PoolInfo) public poolInfo;
        mapping (uint256 => mapping (address => uint256)) public rewardAcc;
        uint256[] public poolIds; 
        /// @notice Info of each user that stakes LP tokens.
        mapping (uint256 => mapping (address => UserInfo)) public userInfo;
        /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
        uint256 totalAllocPoint;

        uint256 public tokenPerBlock;
        uint256 private constant ACC_TOKEN_PRECISION = 1e9;
        uint256 public TIME_CONSTANT = 3;
        uint256 weekC = 75;
        uint256 monthC = 150;
        uint256 yearC = 250;
        uint256 boostC = 1000;
        address public MasterMind;
        bool public stable;
        address public dev;
        address public dao;
        uint256 devF = 100;
        uint256 daoF = 100;
        uint256 public constant BLOCKS_IN_YEAR = 32850000;
        uint256 public constant BLOCKS_IN_DAY = 90000;
        event LogOnReward(address indexed user, uint256 indexed pid, uint256 amount);
        event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
        event LogSetPool(uint256 indexed pid, uint256 allocPoint);
        event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accTokenPerBillonShares);
        event LogInit();
        event RewardRateUpdated(uint256 oldRate, uint256 newRate);
        event LogClaim(uint256 _pid, address _user, uint256 _averageDeposit, address to);

        constructor (IERC20 _rewardToken, uint256 _tokenPerBlock, address _MasterMind, address _dao) public {
            rewardToken = _rewardToken;
            tokenPerBlock = _tokenPerBlock;
            MasterMind = _MasterMind;
            dev = msg.sender;
            dao = _dao;
        }


        function onReward (uint256 pid, address _user, uint256 averageBlockDeposit, uint256 shares) onlyMM override external {
            PoolInfo memory pool = updatePool(pid);
            UserInfo storage user = userInfo[pid][_user];
            uint256 pending;
            if (user.amount > 0) {
                pending =
                    (user.amount.mul(pool.accTokenPerBillonShares) / ACC_TOKEN_PRECISION / 1e9).sub(
                        user.rewardDebt
                    );
                rewardAcc[pid][_user]=rewardAcc[pid][_user].add(pending.mul((boostC.add(this.Boost(averageBlockDeposit))))/boostC);
            }
            user.amount = shares;
            user.rewardDebt = shares.mul(pool.accTokenPerBillonShares) / ACC_TOKEN_PRECISION / 1e9;
            updateRewardPerBlock();
            emit LogOnReward(_user, pid, pending);
        }

        function claim(uint256 _pid, address _user, uint256 _averageDeposit, address to) onlyMM override external returns (uint256) {
            uint256 amount = rewardAcc[_pid][_user];
            UserInfo storage user = userInfo[_pid][_user];
            rewardAcc[_pid][_user] = 0;
            if (amount>0){
                rewardToken.safeTransfer(to, amount);
                rewardToken.safeTransfer(dev, amount.mul(devF)/1000);
                rewardToken.safeTransfer(dao, amount.mul(daoF)/1000);
            }
            emit LogClaim(_pid, _user, _averageDeposit, to);
            return amount;
        }

        function updateRewardPerBlock() internal {
            if (!stable){
                uint256 amount = IERC20(rewardToken).balanceOf(address(this));
                tokenPerBlock = amount.mul(TIME_CONSTANT)/(BLOCKS_IN_YEAR);
            }
        }

        function updateContants(uint256 _TIME_CONSTANT, uint256 _weekC, uint256 _monthC, uint256 _yearC) external onlyOwner{
            TIME_CONSTANT = _TIME_CONSTANT;
            weekC = _weekC;
            monthC = _monthC;
            yearC = _yearC;
        }

        function newDevDao(address _dev) external onlyOwner {
            dev = _dev;
        }

        function newDao( address _dao) external onlyOwner {
            dao = _dao;
        }

        function updateStable(bool _stable, uint256 _RewardPerBlock) external onlyOwner{
            stable = _stable;
            tokenPerBlock = _RewardPerBlock;
        }

        function pendingTokens(uint256 pid, address user, uint256) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
            IERC20[] memory _rewardTokens = new IERC20[](1);
            _rewardTokens[0] = (rewardToken);
            uint256[] memory _rewardAmounts = new uint256[](1);
            _rewardAmounts[0] = pendingToken(pid, user);
            return (_rewardTokens, _rewardAmounts);
        }

        modifier onlyMM {
            require(
                msg.sender == MasterMind,
                "Only MM can call this function."
            );
            _;
        }

        /// @notice Returns the number of MM pools.
        function poolLength() public view returns (uint256 pools) {
            pools = poolIds.length;
        }

        function addBulk(uint256[] memory allocPoints, uint256[] memory  _pids) external onlyOwner{
            uint256 lastRewardBlock = block.number;
            for (uint i = 0; i < allocPoints.length; i++) {
                uint256 allocPoint = allocPoints[i];
                uint256 _pid = _pids[i];
                require(poolInfo[_pid].lastRewardBlock == 0, "Pool already exists");
                totalAllocPoint = totalAllocPoint.add(allocPoint);
                poolInfo[_pid] = PoolInfo({
                    allocPoint: allocPoint.to64(),
                    lastRewardBlock: lastRewardBlock.to64(),
                    accTokenPerBillonShares: 0
                });
                poolIds.push(_pid);
                emit LogPoolAddition(_pid, allocPoint);
            }
        }

        /// @notice Update the given pool's Token allocation point and `IRewarder` contract. Can only be called by the owner.
        /// @param _pid The index of the pool. See `poolInfo`.
        /// @param _allocPoint New AP of the pool.
        function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
            totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
            poolInfo[_pid].allocPoint = _allocPoint.to64();
            emit LogSetPool(_pid, _allocPoint);
        }

        /// @notice View function to see pending Token
        /// @param _pid The index of the pool. See `poolInfo`.
        /// @param _user Address of user.
        /// @return pending Token reward for a given user.
        function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
            PoolInfo memory pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][_user];
            uint256 accTokenPerBillonShares = pool.accTokenPerBillonShares;
            uint256 totalShares = IMasterMind(MasterMind).poolInfo(_pid).totalShares;
            uint256 averageBlockDeposit = IMasterMind(MasterMind).userInfo(_pid, _user).averageBlockDeposit;
            if (block.number > pool.lastRewardBlock && totalShares != 0) {
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 Reward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
                accTokenPerBillonShares = accTokenPerBillonShares.add(Reward.mul(ACC_TOKEN_PRECISION).mul(1e9) / totalShares);
            }
            pending = rewardAcc[_pid][_user].add(((user.amount.mul(accTokenPerBillonShares) / ACC_TOKEN_PRECISION / 1e9).sub(user.rewardDebt)).mul((boostC.add(this.Boost(averageBlockDeposit)))/boostC));
        }


        function Boost(uint256 averageBlock) external view returns (uint256) {
            uint256 elapsed = block.number.sub(averageBlock);
            if (elapsed >= 30*BLOCKS_IN_DAY)
                return  monthC.add((yearC.sub(monthC)).mul(elapsed.sub(30*BLOCKS_IN_DAY))/(335*BLOCKS_IN_DAY));
            if (elapsed >= 7*BLOCKS_IN_DAY)
                return weekC.add((monthC.sub(weekC)).mul(elapsed.sub(7*BLOCKS_IN_DAY))/(23*BLOCKS_IN_DAY));
            return weekC.mul(elapsed)/(7*BLOCKS_IN_DAY); 
        }
        /// @notice Update reward variables for all pools. Be careful of gas spending!
        /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
        function massUpdatePools(uint256[] calldata pids) public {
            uint256 len = pids.length;
            for (uint256 i = 0; i < len; ++i) {
                updatePool(pids[i]);
            }
        }
        /// @notice Update reward variables of the given pool.
        /// @param pid The index of the pool. See `poolInfo`.
        /// @return pool Returns the pool that was updated.
        function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
            pool = poolInfo[pid];
            require(pool.lastRewardBlock != 0, "Pool does not exist");
            if (block.number > pool.lastRewardBlock) {
                uint256 totalShares = IMasterMind(MasterMind).poolInfo(pid).totalShares;
                if (totalShares > 0) {
                    uint256 blocks = block.number.sub(pool.lastRewardBlock);
                    uint256 Reward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
                    pool.accTokenPerBillonShares = pool.accTokenPerBillonShares.add((Reward.mul(ACC_TOKEN_PRECISION).mul(1e9) / totalShares).to128());
                }
                pool.lastRewardBlock = block.number.to64();
                poolInfo[pid] = pool;
                emit LogUpdatePool(pid, pool.lastRewardBlock, totalShares, pool.accTokenPerBillonShares);
            }
            updateRewardPerBlock();
        }

        /// @dev Sets the distribution reward rate. This will also update all of the pools.
        /// @param _tokenPerBlock The number of tokens to distribute per block
        function setRewardRate(uint256 _tokenPerBlock, uint256[] calldata _pids) external onlyOwner {
            massUpdatePools(_pids);

            uint256 oldRate = tokenPerBlock;
            tokenPerBlock = _tokenPerBlock;

            emit RewardRateUpdated(oldRate, _tokenPerBlock);
        }
    }