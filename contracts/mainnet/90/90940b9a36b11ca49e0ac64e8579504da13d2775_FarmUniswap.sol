/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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

interface IFarmFactory {
    function userEnteredFarm(address _user) external;

    function userLeftFarm(address _user) external;

    function registerFarm(address _farmAddress) external;
}

contract FarmUniswap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice information stuct on each user than stakes LP tokens.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    /// @notice all the settings for this farm in one struct
    struct FarmInfo {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 blockReward;
        uint256 bonusEndBlock;
        uint256 bonus;
        uint256 endBlock;
        uint256 lastRewardBlock; // Last block number that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e12
        uint256 farmableSupply; // set in init, total amount of tokens farmable
        uint256 numFarmers;
    }

    /// @notice farm type id. Useful for back-end systems to know how to read the contract (ABI) as we plan to launch multiple farm types
    uint256 public farmType = 1;

    IFarmFactory public factory;
    address public farmGenerator;

    FarmInfo public farmInfo;

    /// @notice information on each user than stakes LP tokens
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(address _factory, address _farmGenerator) public {
        factory = IFarmFactory(_factory);
        farmGenerator = _farmGenerator;
    }

    /**
     * @notice initialize the farming contract. This is called only once upon farm creation and the FarmGenerator ensures the farm has the correct paramaters
     */
    function init(
        IERC20 _rewardToken,
        uint256 _amount,
        IERC20 _lpToken,
        uint256 _blockReward,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus
    ) public {
        address msgSender = _msgSender();
        require(msgSender == address(farmGenerator), "FORBIDDEN");

        TransferHelper.safeTransferFrom(
            address(_rewardToken),
            msgSender,
            address(this),
            _amount
        );
        farmInfo.rewardToken = _rewardToken;

        farmInfo.startBlock = _startBlock;
        farmInfo.blockReward = _blockReward;
        farmInfo.bonusEndBlock = _bonusEndBlock;
        farmInfo.bonus = _bonus;

        uint256 lastRewardBlock =
            block.number > _startBlock ? block.number : _startBlock;
        farmInfo.lpToken = _lpToken;
        farmInfo.lastRewardBlock = lastRewardBlock;
        farmInfo.accRewardPerShare = 0;

        farmInfo.endBlock = _endBlock;
        farmInfo.farmableSupply = _amount;
    }

    /**
     * @notice Gets the reward multiplier over the given _from_block until _to block
     * @param _from_block the start of the period to measure rewards for
     * @param _to the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _from_block, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 _from =
            _from_block >= farmInfo.startBlock
                ? _from_block
                : farmInfo.startBlock;
        uint256 to = farmInfo.endBlock > _to ? _to : farmInfo.endBlock;
        //
        if (to <= farmInfo.bonusEndBlock) {
            return to.sub(_from).mul(farmInfo.bonus);
        } else if (_from >= farmInfo.bonusEndBlock) {
            return to.sub(_from);
        } else {
            return
                farmInfo.bonusEndBlock.sub(_from).mul(farmInfo.bonus).add(
                    to.sub(farmInfo.bonusEndBlock)
                );
        }
    }

    /**
     * @notice function to see accumulated balance of reward token for specified user
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = farmInfo.accRewardPerShare;
        uint256 lpSupply = farmInfo.lpToken.balanceOf(address(this));
        if (block.number > farmInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(farmInfo.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(farmInfo.blockReward);
            accRewardPerShare = accRewardPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @notice updates pool information to be up to date to the current block
     */
    function updatePool() public {
        if (block.number <= farmInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = farmInfo.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            farmInfo.lastRewardBlock = block.number < farmInfo.endBlock
                ? block.number
                : farmInfo.endBlock;
            return;
        }
        uint256 multiplier =
            getMultiplier(farmInfo.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(farmInfo.blockReward);
        farmInfo.accRewardPerShare = farmInfo.accRewardPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        farmInfo.lastRewardBlock = block.number < farmInfo.endBlock
            ? block.number
            : farmInfo.endBlock;
    }

    /**
     * @notice deposit LP token function for msgSender
     * @param _amount the total deposit amount
     */
    function deposit(uint256 _amount) public {
        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(farmInfo.accRewardPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeRewardTransfer(msgSender, pending);
        }
        if (user.amount == 0 && _amount > 0) {
            factory.userEnteredFarm(msgSender);
            farmInfo.numFarmers = farmInfo.numFarmers.add(1);
        }
        farmInfo.lpToken.safeTransferFrom(
            address(msgSender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(farmInfo.accRewardPerShare).div(1e12);
        emit Deposit(msgSender, _amount);
    }

    /**
     * @notice withdraw LP token function for msgSender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) public {
        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];
        require(user.amount >= _amount, "INSUFFICIENT");
        updatePool();
        if (user.amount == _amount && _amount > 0) {
            factory.userLeftFarm(msgSender);
            farmInfo.numFarmers = farmInfo.numFarmers.sub(1);
        }
        uint256 pending =
            user.amount.mul(farmInfo.accRewardPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeRewardTransfer(msgSender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(farmInfo.accRewardPerShare).div(1e12);
        farmInfo.lpToken.safeTransfer(address(msgSender), _amount);
        emit Withdraw(msgSender, _amount);
    }

    /**
     * @notice emergency functoin to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() public {
        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];
        farmInfo.lpToken.safeTransfer(address(msgSender), user.amount);
        emit EmergencyWithdraw(msgSender, user.amount);
        if (user.amount > 0) {
            factory.userLeftFarm(msgSender);
            farmInfo.numFarmers = farmInfo.numFarmers.sub(1);
        }
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @notice Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _to the user address to transfer tokens to
     * @param _amount the total amount of tokens to transfer
     */
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = farmInfo.rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            farmInfo.rewardToken.transfer(_to, rewardBal);
        } else {
            farmInfo.rewardToken.transfer(_to, _amount);
        }
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}