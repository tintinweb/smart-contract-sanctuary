/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IPancakeRouter02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }



    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target addres contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}


interface ILendingPool {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _share) external;

    function totalToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IStakingPool {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 bonusDebt;
        address fundedBy;
    }

    function userInfo(uint256 poolId, address user) external view returns (UserInfo memory);

    function deposit(address _for, uint256 _pid, uint256 _amount) external;

    function withdraw(address _for, uint256 _pid, uint256 _amount) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);
}

interface IFarmBridge {
    function deposit(uint256 amount) external;

    function withdrawUnderLying(uint256 amount) external;

    function withdrawAll() external;
}

contract FarmBridgeBUSD  is IFarmBridge {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    ILendingPool public lendingPool;
    IStakingPool public stakingPool;
    uint256 public poolId;
    address public pancakeRouter;
    IBEP20 public busd;
    IBEP20 public rewardToken;
    address public governance;
    address public noLossPot;
    address[] public liquidationPath;

    struct RewardResponse {
        uint256 amountAlpaca;
        uint256 amountBUSD;
    }

    constructor(
        ILendingPool _lendingPool,
        IStakingPool _stakingPool,
        uint256 _poolId,
        address _pancakeRouter,
        IBEP20 _busd,
        IBEP20 _rewardToken,
        address _noLossPot
    ) public {
        lendingPool = _lendingPool;
        stakingPool = _stakingPool;
        poolId = _poolId;
        pancakeRouter = _pancakeRouter;
        busd = _busd;
        rewardToken = _rewardToken;
        governance = msg.sender;
        noLossPot = _noLossPot;
        liquidationPath.push(address(_rewardToken));
        liquidationPath.push(address(_busd));
        busd.safeApprove(address(_lendingPool), uint(- 1));
        IBEP20(address(_lendingPool)).safeApprove(address(_stakingPool), uint(- 1));
    }
    modifier restricted(){
        require(msg.sender == governance || msg.sender == noLossPot, "restricted");
        _;
    }
    function deposit(uint256 amount) external override {
        busd.safeTransferFrom(msg.sender, address(this), amount);
        uint256 totalStakingToken = busd.balanceOf(address(this));
        lendingPool.deposit(totalStakingToken);
        uint256 totalIStakingToken = IBEP20(address(lendingPool)).balanceOf(address(this));
        stakingPool.deposit(address(this), poolId, totalIStakingToken);
    }

    function withdrawUnderLying(uint256 amount) external restricted override {
        uint256 share = amount.mul(lendingPool.totalSupply()).div(lendingPool.totalToken());
        stakingPool.withdraw(address(this), poolId, share);
        lendingPool.withdraw(share);
        uint256 totalStakingToken = busd.balanceOf(address(this));
        if (amount > totalStakingToken) {
            amount = totalStakingToken;
        }
        busd.transfer(msg.sender, amount);

    }

    function withdrawAll() external restricted override {
        stakingPool.withdrawAll(address(this), poolId);
        uint256 totalIStakingToken = IBEP20(address(lendingPool)).balanceOf(address(this));
        lendingPool.withdraw(totalIStakingToken);
        liquidateBonus();
        uint256 totalStakingToken = busd.balanceOf(address(this));
        busd.transfer(msg.sender, totalStakingToken);
    }

    event TooLowBalance();
    event  Liquidated(uint256 amount);

    function liquidateBonus() internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance < 1e15) {
            emit TooLowBalance();
            return;
        }
        emit Liquidated(balance);

        // we can accept 1 as minimum as this will be called by trusted roles only
        uint256 amountOutMin = 0;
        rewardToken.safeApprove(pancakeRouter, 0);
        rewardToken.safeApprove(pancakeRouter, balance);

        IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(
            balance,
            amountOutMin,
            liquidationPath,
            address(this),
            block.timestamp
        );
    }

    function reward() public view returns (RewardResponse memory){
        uint256 amountAlpaca = stakingPool.pendingAlpaca(poolId, msg.sender);
        uint256 totalIBUSD = stakingPool.userInfo(poolId, address(this)).amount;
        uint256 amountBusd = totalIBUSD.mul(lendingPool.totalToken()).div(lendingPool.totalSupply());
        return RewardResponse(amountAlpaca, amountBusd);
    }

    function inCaseTokenStuck(IBEP20 token, uint256 amount, address to) public  restricted{
        token.transfer(to, amount);
    }
}