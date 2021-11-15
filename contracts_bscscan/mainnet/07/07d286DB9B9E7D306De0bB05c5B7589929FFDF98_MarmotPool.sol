// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/SafeERC20.sol";
import "../lib/SafeMath.sol";
import "../interface/IOracle.sol";
import '../interface/IBTokenSwapper.sol';
import "../interface/alpaca/IAlpacaVault.sol";
import "../interface/alpaca/IAlpacaFairLaunch.sol";
import "../interface/IWETH.sol";
import "../token/MarmotToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MarmotPool is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant ONE = 10**18;
    uint256 constant FUND_RATIO = 176470588235294144;


    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of staking token contract.
        string symbol;
        uint256 decimal;
        uint256 discount;
        address oracleAddress; //staking price contract address
        uint256 accMarmotPerShare;
        uint256 totalShare;    // Total amount of current pool deposit.
        address alpacaVault;
        uint256 alpacaPid;
    }

    MarmotToken public marmot;
    // all pool share main pool
    uint256 public lastRewardBlock;
    // marmot token reward per block.
    uint256 public marmotPerBlock0; // for stable coins
    uint256 public marmotPerBlock1; // for crypto natives (BTC ETH BNB)
    // Info of each pool.
    PoolInfo[] public poolInfos;
    // Info of each user that stakes staking tokens. pid => userAddress => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfos;
    // Control mining
    bool public paused;
    // The block number when marmot mining starts.
    uint256 private _startBlock;
    // 15% of token mint to vault address
    address private _vaultAddr;
    // Alpaca setting
    address public alpacaFairLaunch;
    // WBNB address
    address public wrappedNativeAddr;
    // Approved Swappers
    mapping(address => bool) approvedSwapper;

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, 'reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier notPause() {
        require(paused == false, "MP: farming suspended");
        _;
    }

    event AddSwapper(address indexed swapperAddress);
    event RemoveSwapper(address indexed swapperAddress);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);


    function initialize(
        MarmotToken _marmot,
        uint256 _marmotPerBlock0,
        uint256 _marmotPerBlock1,
        uint256 _startBlock_
      ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        marmot = _marmot;
        marmotPerBlock0 = _marmotPerBlock0;
        marmotPerBlock1 = _marmotPerBlock1;
        paused = false;
        _startBlock = _startBlock_;
        _vaultAddr = msg.sender;
      }

    function blockNumber() public view returns (uint256) {
        return block.number;
    }

    function timeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    // ============ OWNER FUNCTIONS ========================================
    function addMinter(address _addMinter) external onlyOwner returns (bool) {
		bool result = marmot.addMinter(_addMinter);
		return result;
	}

	function delMinter(address _delMinter) external onlyOwner returns (bool) {
		bool result = marmot.delMinter(_delMinter);
		return result;
	}

    function setMarmotPerBlock(uint256 _marmotPerBlock0, uint256 _marmotPerBlock1) external onlyOwner {
        updatePool();
        marmotPerBlock0 = _marmotPerBlock0;
        marmotPerBlock1 = _marmotPerBlock1;
    }

    function setAlpacaFairLaunch(address _alpacaFairLaunch) external onlyOwner {
        require(_alpacaFairLaunch != address(0), "MarmotPool: can not set zero address");
        alpacaFairLaunch = _alpacaFairLaunch;
    }

    function setWrappedNativeAddr(address _wrappedNativeAddr) external onlyOwner {
        require(_wrappedNativeAddr != address(0), "wrappedNativeAddr is the zero address");
        wrappedNativeAddr = _wrappedNativeAddr;
    }

    function setVaultAddress(address vaultAddress) external onlyOwner {
        require(vaultAddress != address(0), "devAddress is the zero address");
        _vaultAddr = vaultAddress;
    }


    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function addSwapper(address swapperAddress) external onlyOwner {
        approvedSwapper[swapperAddress] = true;
        emit AddSwapper(swapperAddress);
    }

    function removeSwapper(address swapperAddress) external onlyOwner {
        approvedSwapper[swapperAddress] = false;
        emit RemoveSwapper(swapperAddress);
    }

   // ============ POOL STATUS ========================================
    function getPoolLength() public view returns (uint256) {
        return poolInfos.length;
    }

    function getPoolInfo(uint256 pid) external view returns (PoolInfo memory poolInfo) {
        poolInfo = poolInfos[pid];
    }

    function getUserInfo(uint pid, address user) external view returns (UserInfo memory userInfo) {
        userInfo = userInfos[pid][user];
    }

    function getPrice(uint256 pid) public view returns (uint256) {
        address oracleAddress = poolInfos[pid].oracleAddress;
        uint256 oraclePrice = IOracle(oracleAddress).getPrice();
        return oraclePrice;
    }

    function vaultAddr() external view returns (address) {
        return _vaultAddr;
    }

    function startBlock() external view returns (uint256) {
        return _startBlock;
    }

    function getPoolValue0() public view returns (uint256 value) {
        PoolInfo memory poolInfo = poolInfos[0];
        value = poolInfo.totalShare * poolInfo.discount / ONE;
    }


    function getAllPoolValue1() public view returns (uint256 allValue) {
        for (uint256 i = 1; i < poolInfos.length; i++) {
            allValue += getPoolValue1(i);
        }
    }

    function getPoolValue1(uint256 pid) public view returns (uint256 value) {
        PoolInfo memory poolInfo = poolInfos[pid];
        value =  poolInfo.totalShare * poolInfo.discount / ONE * getPrice(pid) / ONE;
    }

    // ============ POOL SETTINGS ========================================
    function addPool(address tokenAddress, string memory symbol, uint256 discount, address oracleAddress, address alpacaVault, uint256 alpacaPid) public onlyOwner {
        require(tokenAddress != address(0), "tokenAddress is the zero address");
        updatePool();

        for (uint256 i = 0; i < poolInfos.length; i++) {
            PoolInfo memory poolInfo = poolInfos[i];
            require(address(poolInfo.token) != tokenAddress, "duplicate tokenAddress");
        }
        lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        PoolInfo memory newPoolInfo;
        newPoolInfo.token = IERC20(tokenAddress);
        newPoolInfo.symbol = symbol;
        newPoolInfo.decimal = IERC20(tokenAddress).decimals();
        newPoolInfo.discount = discount;
        newPoolInfo.oracleAddress = oracleAddress;
        newPoolInfo.alpacaVault = alpacaVault;
        newPoolInfo.alpacaPid = alpacaPid;
        poolInfos.push(newPoolInfo);
    }

    function setPool(uint256 pid, address tokenAddress, uint256 discount, address oracleAddress, address alpacaVault, uint256 alpacaPid) public onlyOwner {
        PoolInfo storage poolInfo = poolInfos[pid];
        poolInfo.token = IERC20(tokenAddress);
        poolInfo.discount = discount;
        poolInfo.oracleAddress = oracleAddress;
        poolInfo.alpacaVault = alpacaVault;
        poolInfo.alpacaPid = alpacaPid;
    }

    function updatePool() internal {
        uint256 preBlockNumber = lastRewardBlock;
        uint256 curBlockNumber = block.number;
        if (curBlockNumber > preBlockNumber) {
            uint256 delta = curBlockNumber - preBlockNumber;

            if (poolInfos.length > 0) {
                PoolInfo storage poolInfo = poolInfos[0];
                if (poolInfo.totalShare > 0) poolInfo.accMarmotPerShare += marmotPerBlock0 * delta * ONE / poolInfo.totalShare;
            }

            if (poolInfos.length > 1) {
                uint256 totalValue1 = getAllPoolValue1();
                if (totalValue1 > 0) {
                    for (uint256 i = 1; i < poolInfos.length; i++) {
                        PoolInfo storage poolInfo1 = poolInfos[i];
                        uint256 value1 = getPoolValue1(i);
                        if (value1 > 0) poolInfo1.accMarmotPerShare += value1 * marmotPerBlock1 * delta * ONE / (totalValue1 * poolInfo1.totalShare);
                    }
                }
            }
            lastRewardBlock = curBlockNumber;
        }
    }


    function getPoolBalance(uint256 _pid) public view returns (uint256){
        PoolInfo memory poolInfo = poolInfos[_pid];
        return poolInfo.totalShare;
    }



    // ============ ALPACA FUNCTIONS ========================================
    function alpacaDeposit(uint256 pid, uint256 amount) internal {
        address alpacaVault = poolInfos[pid].alpacaVault;
        uint256 alpacaPid = poolInfos[pid].alpacaPid;
        if (address(poolInfos[pid].token) == wrappedNativeAddr) {
            (bool success, ) = alpacaVault.call{value: amount}(abi.encodeWithSignature("deposit(uint256)", amount));
            require(success, "MP: BNB deposit fail");
        }
        else {
            poolInfos[pid].token.safeApprove(alpacaVault, type(uint256).max);
            IAlpacaVault(alpacaVault).deposit(amount);
            poolInfos[pid].token.safeApprove(alpacaVault, 0);
        }
        uint256 ibAmount = IAlpacaVault(alpacaVault).balanceOf(address(this));
        IAlpacaVault(alpacaVault).approve(alpacaFairLaunch, type(uint256).max);
        IAlpacaFairLaunch(alpacaFairLaunch).deposit(address(this), alpacaPid, ibAmount);
        IAlpacaVault(alpacaVault).approve(alpacaFairLaunch, 0);

    }

    function alpacaWithdraw(uint256 pid, uint256 amount) internal {
        address alpacaVault = poolInfos[pid].alpacaVault;
        uint256 alpacaPid = poolInfos[pid].alpacaPid;
        uint256 share = amount * IAlpacaVault(alpacaVault).totalSupply() / IAlpacaVault(alpacaVault).totalToken();
        IAlpacaFairLaunch(alpacaFairLaunch).withdraw(address(this), alpacaPid, share);
        IAlpacaVault(alpacaVault).withdraw(share);
    }

    function alpacaHarvestAll() external {
        for (uint256 i = 0; i < poolInfos.length; i++) {
            alpacaHarvest(i);
        }
    }

    function alpacaHarvest(uint256 pid) public {
        PoolInfo storage poolInfo = poolInfos[pid];
        if (poolInfo.totalShare > 0) {
            IAlpacaFairLaunch(alpacaFairLaunch).harvest(poolInfo.alpacaPid);
        }
    }

    function buyBackAndBurn(address BX, address swapperAddress, uint256 referencePrice) external {
        require(approvedSwapper[swapperAddress], "MP: invalid swapperAddress");
        if (BX == wrappedNativeAddr) {
            IWETH(wrappedNativeAddr).deposit{value: address(this).balance}();
        }

        uint256 amount = IERC20(BX).balanceOf(address(this));
        IERC20(BX).safeApprove(swapperAddress, type(uint256).max);
        (uint256 resultB0, ) = IBTokenSwapper(swapperAddress).swapExactBXForB0(amount, referencePrice);
        IERC20(BX).safeApprove(swapperAddress, 0);

        marmot.burn(resultB0);
    }

    // ============ USER INTERACTION ========================================
    // Deposit staking tokens
    function deposit(uint256 pid, uint256 amount) public payable _lock_ notPause {
        updatePool();
        address user = msg.sender;
        PoolInfo storage poolInfo = poolInfos[pid];
        UserInfo storage userInfo = userInfos[pid][user];

        if (userInfo.amount > 0) {
            uint256 pendingAmount = poolInfo.accMarmotPerShare * userInfo.amount / ONE - userInfo.rewardDebt;
            if (pendingAmount > 0) {
                marmot.mint(_vaultAddr, pendingAmount * FUND_RATIO / ONE);
                marmot.mint(user, pendingAmount);
            }
        }
        if (amount > 0) {
            if (msg.value != 0) {
                require(address(poolInfo.token) == wrappedNativeAddr, "MP: baseToken is not wNative");
                require(amount == msg.value, "MP: amount != msg.value");
                userInfo.amount += amount;
                poolInfo.totalShare += amount;
                alpacaDeposit(pid, amount);
            }
            else {
                require(address(poolInfo.token) != wrappedNativeAddr, "MP: baseToken is wNative");
                uint256 nativeAmount;
                (nativeAmount, amount) = _deflationCompatibleSafeTransferFrom(poolInfo.token, user, address(this), amount);
                userInfo.amount += amount;
                poolInfo.totalShare += amount;
                alpacaDeposit(pid, nativeAmount);
            }
        }
        userInfo.rewardDebt = poolInfo.accMarmotPerShare * userInfo.amount / ONE;
        emit Deposit(user, pid, amount);
    }

    // Withdraw staking tokens
    function withdraw(uint256 pid, uint256 amount) public _lock_ notPause {
        updatePool();
        address user = msg.sender;
        PoolInfo storage poolInfo = poolInfos[pid];
        UserInfo storage userInfo = userInfos[pid][user];
        require(userInfo.amount >= amount, "withdraw: exceeds balance");

        if (userInfo.amount > 0) {
            uint256 pendingAmount = poolInfo.accMarmotPerShare * userInfo.amount / ONE - userInfo.rewardDebt;
            if (pendingAmount > 0) {
                marmot.mint(_vaultAddr, pendingAmount * FUND_RATIO / ONE);
                marmot.mint(user, pendingAmount);
            }
        }
        if (amount > 0) {
            userInfo.amount -= amount;
            poolInfo.totalShare -= amount;
            uint256 decimals = poolInfo.token.decimals();
            alpacaWithdraw(pid, amount.rescale(18, decimals));
            if (address(poolInfo.token) == wrappedNativeAddr) {
                payable(user).transfer(amount);
            } else {
                poolInfo.token.safeTransfer(user, amount.rescale(18, decimals));
            }
        }
        userInfo.rewardDebt = poolInfo.accMarmotPerShare * userInfo.amount / ONE;
        emit Withdraw(user, pid, amount);
    }

    function claimAll() external _lock_ notPause {
        updatePool();
        address user = msg.sender;
        uint256 pendingAmount;
        for (uint256 i = 0; i < poolInfos.length; i++) {
                PoolInfo storage poolInfo = poolInfos[i];
                UserInfo storage userInfo = userInfos[i][user];
                if (userInfo.amount > 0) {
                    pendingAmount += poolInfo.accMarmotPerShare * userInfo.amount / ONE - userInfo.rewardDebt;
                    userInfo.rewardDebt = poolInfo.accMarmotPerShare * userInfo.amount / ONE;
                }
        }
        if (pendingAmount > 0) {
            marmot.mint(_vaultAddr, pendingAmount * FUND_RATIO / ONE);
            marmot.mint(user, pendingAmount);
            emit Claim(user, pendingAmount);
        }
    }

    function pendingAll() view external returns (uint256) {
        address user = msg.sender;
        uint256 pendingAmount;
        uint256 preBlockNumber = lastRewardBlock;
        uint256 curBlockNumber = block.number;
        if (curBlockNumber > preBlockNumber) {
            for (uint256 i = 0; i < poolInfos.length; i++) {
                    PoolInfo memory poolInfo = poolInfos[i];
                    UserInfo memory userInfo = userInfos[i][user];
                    if (userInfo.amount > 0) {
                        pendingAmount += poolInfo.accMarmotPerShare * userInfo.amount / ONE - userInfo.rewardDebt;
                    }
            }

            uint256 delta = curBlockNumber - preBlockNumber;
            uint256 addMarmotPerShare;
            uint256 totalValue1;
            if (poolInfos.length >= 1) totalValue1 = getAllPoolValue1();

            for (uint256 i = 0; i < poolInfos.length; i++) {
                PoolInfo memory poolInfo = poolInfos[i];
                UserInfo memory userInfo = userInfos[i][user];
                if (i == 0) {
                    if (poolInfo.totalShare > 0) {
                        addMarmotPerShare = marmotPerBlock0 * delta * ONE / poolInfo.totalShare;
                        pendingAmount += addMarmotPerShare * userInfo.amount / ONE;
                    }
                }
                else {
                    uint256 value1 = getPoolValue1(i);
                    if (value1 > 0 && totalValue1 >0) {
                        addMarmotPerShare = value1 * marmotPerBlock1 * delta * ONE / (totalValue1 * poolInfo.totalShare);
                        pendingAmount += addMarmotPerShare * userInfo.amount / ONE;
                    }
                }
            }
        }
        return pendingAmount;
    }

    function pending(uint256 pid, address user) view public returns (uint256) {
        uint256 preBlockNumber = lastRewardBlock;
        uint256 curBlockNumber = block.number;
        uint256 pendingAmount;
        if (curBlockNumber > preBlockNumber) {
            PoolInfo memory poolInfo = poolInfos[pid];
            UserInfo memory userInfo = userInfos[pid][user];
            if (userInfo.amount > 0) {
                pendingAmount = poolInfo.accMarmotPerShare * userInfo.amount / ONE - userInfo.rewardDebt;
            }

            uint256 delta = curBlockNumber - preBlockNumber;
            if (pid == 0) {
                if (poolInfo.totalShare > 0) {
                    uint256 addMarmotPerShare = marmotPerBlock0 * delta * ONE / poolInfo.totalShare;
                    pendingAmount += addMarmotPerShare * userInfo.amount / ONE;
                }
            } else {
                uint256 totalValue1 = getAllPoolValue1();
                uint256 value1 = getPoolValue1(pid);
                if (value1 > 0) {
                    uint256 addMarmotPerShare = value1 * marmotPerBlock1 * delta * ONE / (totalValue1 * poolInfo.totalShare);
                    pendingAmount += addMarmotPerShare * userInfo.amount / ONE;
                }
            }
        }
        return pendingAmount;
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 pid) public _lock_ {
        _emergencyWithdraw(pid, msg.sender);
    }

    function _emergencyWithdraw(uint256 pid, address user) internal {
        PoolInfo storage poolInfo = poolInfos[pid];
        UserInfo storage userInfo = userInfos[pid][user];
        uint256 amount = userInfo.amount;
        userInfo.amount = 0;
        userInfo.rewardDebt = 0;
        uint256 decimals = poolInfo.token.decimals();
        alpacaWithdraw(pid, amount.rescale(18, decimals));
        if (address(poolInfo.token) == wrappedNativeAddr) {
                payable(user).transfer(amount);
            } else {
                poolInfo.token.safeTransfer(user, amount.rescale(18, decimals));
        }
        poolInfo.totalShare -= amount;
        emit EmergencyWithdraw(user, pid, amount);
    }


    function _deflationCompatibleSafeTransferFrom(IERC20 token, address from, address to, uint256 amount)
        internal returns (uint256, uint256) {
        uint256 decimals = token.decimals();
        uint256 balance1 = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount.rescale(18, decimals));
        uint256 balance2 = token.balanceOf(to);
        return (balance2 - balance1, (balance2 - balance1).rescale(decimals, 18));
    }


    fallback() external payable {
//        require(msg.sender == address(marmot), "WE_SAVED_YOUR_ETH_:)");
    }

    receive() external payable {
//        require(msg.sender == address(marmot), "WE_SAVED_YOUR_ETH_:)");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../interface/IERC20.sol";
import "../lib/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2**255 - 1;
    int256  constant IMIN = -2**255;

    /// convert uint256 to int256
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'UIO');
        return int256(a);
    }

    /// convert int256 to uint256
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'IUO');
        return uint256(a);
    }

    /// take abs of int256
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'AO');
        return a >= 0 ? a : -a;
    }


    /// rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * (10 ** decimals2) / (10 ** decimals1);
    }

    /// rescale a int256 from base 10**decimals1 to 10**decimals2
    function rescale(int256 a, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        return decimals1 == decimals2 ? a : a * utoi(10 ** decimals2) / utoi(10 ** decimals1);
    }

    /// reformat a uint256 to be a valid 10**decimals base value
    /// the reformatted value is still in 10**18 base
    function reformat(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return decimals == 18 ? a : rescale(rescale(a, 18, decimals), decimals, 18);
    }

    /// reformat a int256 to be a valid 10**decimals base value
    /// the reformatted value is still in 10**18 base
    function reformat(int256 a, uint256 decimals) internal pure returns (int256) {
        return decimals == 18 ? a : rescale(rescale(a, 18, decimals), decimals, 18);
    }

    /// ceiling value away from zero, return a valid 10**decimals base value, but still in 10**18 based
    function ceil(int256 a, uint256 decimals) internal pure returns (int256) {
        if (reformat(a, decimals) == a) {
            return a;
        } else {
            int256 b = rescale(a, 18, decimals);
            b += a > 0 ? int256(1) : int256(-1);
            return rescale(b, decimals, 18);
        }
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracle {

    function getPrice() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IBTokenSwapper {

    function swapExactB0ForBX(uint256 amountB0, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(uint256 amountBX, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(uint256 amountB0, uint256 amountBX, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(uint256 amountB0, uint256 amountBX, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function getLimitBX() external view returns (uint256);

    function sync() external;

}

pragma solidity >=0.8.0 <0.9.0;

interface IAlpacaVault {

  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;

  /// @dev Request funds from user through Vault
  function requestFunds(address targetedToken, uint amount) external;

  function totalSupply() external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function token() external view returns (address);

}

pragma solidity >=0.8.0 <0.9.0;

interface IAlpacaFairLaunch {
  function poolLength() external view returns (uint256);

  function addPool(
    uint256 _allocPoint,
    address _stakeToken,
    bool _withUpdate
  ) external;

  function setPool(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external;

  function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);

  function updatePool(uint256 _pid) external;

  function deposit(address _for, uint256 _pid, uint256 _amount) external;

  function withdraw(address _for, uint256 _pid, uint256 _amount) external;

  function withdrawAll(address _for, uint256 _pid) external;

  function harvest(uint256 _pid) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../utils/ERC20.sol";
import "../utils/Ownable.sol";
import "../lib/EnumerableSet.sol";

// MarmotToken with Governance.
contract MarmotToken is ERC20("MarmotToken", "MARMOT", 299792458e18), Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet private _minters;

  // modifier for mint function
  modifier onlyMinter() {
    require(isMinter(msg.sender), "caller is not minter");
        _;
  }

  function mint(address _to, uint256 _amount) public onlyMinter {
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }


  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
  }

  function addMinter(address _addMinter) public onlyOwner returns (bool) {
      require(_addMinter != address(0), "MarmotToken: _addMinter is the zero address");
      return EnumerableSet.add(_minters, _addMinter);
  }

  function delMinter(address _delMinter) public onlyOwner returns (bool) {
      require(_delMinter != address(0), "MarmotToken: _delMinter is the zero address");
      return EnumerableSet.remove(_minters, _delMinter);
  }

  function getMinterLength() public view returns (uint256) {
      return EnumerableSet.length(_minters);
  }

  function isMinter(address account) public view returns (bool) {
      return EnumerableSet.contains(_minters, account);
  }

  function getMinter(uint256 _index) public view returns (address){
      require(_index <= getMinterLength() - 1, "MarmotToken: index out of bounds");
      return EnumerableSet.at(_minters, _index);
  }



  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  /// @notice A record of each accounts delegate
  mapping(address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
  );

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
  );

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegator The address to get delegatee for
    */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
    );

    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "MarmotToken::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "MarmotToken::delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "MarmotToken::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
    require(blockNumber < block.number, "MarmotToken::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying MARMOTs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld - amount;
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld + amount;
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, "MarmotToken::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IERC20.sol';

contract ERC20 is IERC20 {
    uint256 constant ONE = 10**18;

    string _name;

    string _symbol;

    uint8 constant _decimals = 18;

    uint256 _totalSupply;

    uint256 _cap;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    constructor (string memory name_, string memory symbol_, uint256 cap_) {
        _name = name_;
        _symbol = symbol_;
        _cap = cap_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), 'ERC20.approve: to 0 address');
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), 'ERC20.transfer: to 0 address');
        require(_balances[msg.sender] >= amount, 'ERC20.transfer: amount exceeds balance');
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), 'ERC20.transferFrom: to 0 address');
        require(_balances[from] >= amount, 'ERC20.transferFrom: amount exceeds balance');

        if (msg.sender != from && _allowances[from][msg.sender] != type(uint256).max) {
            require(_allowances[from][msg.sender] >= amount, 'ERC20.transferFrom: amount exceeds allowance');
            uint256 newAllowance = _allowances[from][msg.sender] - amount;
            _approve(from, msg.sender, newAllowance);
        }

        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount <= _cap, "ERC20: cap exceeded");

        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[from];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[from] = accountBalance - amount;
        }
        _totalSupply -= amount;
        _cap -= amount;

        emit Transfer(from, address(0), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

