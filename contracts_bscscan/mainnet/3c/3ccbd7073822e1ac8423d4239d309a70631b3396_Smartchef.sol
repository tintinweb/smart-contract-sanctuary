/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: GPL-v3.0

pragma solidity >=0.4.0;

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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
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
}


pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.6.12;

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
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
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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


pragma solidity ^0.6.0;

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

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}


pragma solidity >=0.4.0;

contract Context {

    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.4.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.6.12;

contract Smartchef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 depositTime;    // The last deposit time
        uint256 lastRewardBlock;// The last reward time
    }

    IBEP20 public token;
    uint256 public totalStakedAmount;

    address public feeAddress1 = 0x88501d955B56a4513F41E4E2A0cc6072645543f4;
    address public feeAddress2 = 0xD0aB7364D0b6e760948dE1856A65953eC8b77A37;

    uint256 public depositFee = 100;
    uint256 public withdrawFee = 200;
    uint256 public compoundPercentage = 100;
    uint256 public rewardPercentage = 50;
    uint256 public lockTime = 1800; // seconds

    uint256 public constant BLOCKS_PER_YEAR = 10512000;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(address _tokenAddress) public {
        token = IBEP20(_tokenAddress);
        token.approve(address(this), MAX_UINT256);
        totalStakedAmount = 0;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return getRewardAmount(user);
    }

    function getRewardAmount(UserInfo storage user) private view returns (uint256) {
        if (block.number > user.lastRewardBlock) {
            uint256 multiplier = getMultiplier(user.lastRewardBlock, block.number);
            return user.amount.mul(rewardPercentage).div(10000).mul(multiplier).div(BLOCKS_PER_YEAR);
        }
        return 0;
    }

    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            // give reward
            uint256 pendingRewardToken = getRewardAmount(user);
            if(pendingRewardToken > 0 && token.balanceOf(address(this)) > pendingRewardToken) {
                // compound
                pendingRewardToken = compound(pendingRewardToken);
                token.safeTransferFrom(address(this), address(msg.sender), pendingRewardToken);
            }
        }

        if(_amount > 0) {
            _amount = takeDepositFee(_amount);
            token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            totalStakedAmount = totalStakedAmount.add(_amount);
            user.depositTime = now;
        }

        user.lastRewardBlock = block.number;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.depositTime + lockTime < now, "withdraw: Can not withdraw in the Lock Period");

        // reward
        uint256 pendingRewardToken = getRewardAmount(user);
        if(pendingRewardToken > 0 && token.balanceOf(address(this)) > pendingRewardToken) {
            // compound
            pendingRewardToken = compound(pendingRewardToken);
            token.safeTransferFrom(address(this), address(msg.sender), pendingRewardToken);
            user.lastRewardBlock = block.number;
        }

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalStakedAmount = totalStakedAmount.sub(_amount);
            _amount = takeWithDrawFee(_amount);
            token.safeTransferFrom(address(this), address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, _amount);
    }

    function getTotalStakedAmount() public view returns (uint256){
        return totalStakedAmount;
    }

    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.depositTime + lockTime < now, "withdraw: Can not withdraw in the Lock Period");

        uint256 amount = takeWithDrawFee(user.amount);
        token.safeTransferFrom(address(this), address(msg.sender), amount);
        totalStakedAmount = totalStakedAmount.sub(user.amount);
        user.amount = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)), 'not enough token');
        token.safeTransferFrom(address(this), address(msg.sender), _amount);
    }

    function compound(uint256 _amount) private returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];

        uint256 compoundAmount = _amount.mul(compoundPercentage).div(10000);
        user.amount = user.amount.add(compoundAmount);
        totalStakedAmount = totalStakedAmount.add(compoundAmount);
        return _amount.sub(compoundAmount);
    }

    function takeDepositFee(uint256 _amount) internal returns (uint256) {
        uint256 feeAmount = _amount.mul(depositFee).div(10000);
        token.safeTransferFrom(address(msg.sender), feeAddress1, feeAmount.div(2));
        token.safeTransferFrom(address(msg.sender), feeAddress2, feeAmount.div(2));

        return _amount.sub(feeAmount);
    }

    function takeWithDrawFee(uint256 _amount) internal returns (uint256) {
        uint256 feeAmount = _amount.mul(withdrawFee).div(10000);
        token.safeTransferFrom(address(msg.sender), feeAddress1, feeAmount.div(2));
        token.safeTransferFrom(address(msg.sender), feeAddress2, feeAmount.div(2));

        return _amount.sub(feeAmount);
    }

    function setRewardPercentage(uint256 _rewardPercent) public onlyOwner {
        rewardPercentage = _rewardPercent;
    }

    function setLockTime(uint256 _lockTimeSeconds) public onlyOwner {
        lockTime = _lockTimeSeconds;
    }

    function setFeeAddress(address _feeAddress1, address _feeAddress2) public onlyOwner {
        feeAddress1 = _feeAddress1;
        feeAddress2 = _feeAddress2;
    }

    function setFees(uint256 _depositFee, uint256 _withdrawFee) public onlyOwner {
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
    }

    function setCompoundPercent(uint256 _compoundPercent) public onlyOwner {
        compoundPercentage = _compoundPercent;
    }
}