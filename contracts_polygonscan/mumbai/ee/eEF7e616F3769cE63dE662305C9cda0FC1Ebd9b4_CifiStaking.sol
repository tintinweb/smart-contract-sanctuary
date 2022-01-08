// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
import './libraries/Math.sol';
import "./libraries/SafeMath.sol";
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';

contract CifiStaking {
    using SafeMath  for uint;

    struct UserInfo {
        uint256 amount;
        uint256 rewarded;
        uint256 rewardDebt;
        uint256 lastCalculatedTimeStamp;
        uint256 lastDepositTimeStamp;
    }

    // pool info
    uint256 totalAmount;
    uint256 lastRewardTimeStamp;
    address public cifiToken;
    address public adminAddress;
    // CIFI tokens created per Sec.
    uint256 public rewardPerSec = 810185100000000; // 70 CIFI per day
    
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    address[] public userList;
    uint256 public lockedTime = 7 * 24 * 3600; // 7days
    uint private unlocked = 1;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Reward(address indexed user, uint256 amount);

    modifier lock() {
        require(unlocked == 1, 'CifiStaking: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _cifiToken) public {
        adminAddress = msg.sender;
        cifiToken = _cifiToken;
        totalAmount = 0;
    }

    function setAdmin(address _adminAddress) public {
        require(adminAddress == msg.sender, "not Admin");
        adminAddress = _adminAddress;
    }

    function updatePool() internal {
        for (uint i = 0; i < userList.length; i++) {
            UserInfo storage user = userInfo[userList[i]];
            uint256 lastTimeStamp = block.timestamp;
            uint256 accDebt = lastTimeStamp.sub(user.lastCalculatedTimeStamp).mul(rewardPerSec).mul(user.amount) / totalAmount;
            user.rewardDebt = user.rewardDebt.add(accDebt);
            user.lastCalculatedTimeStamp = lastTimeStamp;
        }
    }
    function deposit(uint256 amount) public lock {
        require(amount > 0, "invaild amount");
        TransferHelper.safeTransferFrom(cifiToken, msg.sender, address(this), amount);
        UserInfo storage user = userInfo[msg.sender];
        bool isFirst = true;
        for (uint i = 0; i < userList.length; i++) {
            if (userList[i] == msg.sender) {
                isFirst = false;
            }
        }
        updatePool();
        if (isFirst) {
            userList.push(msg.sender);
            user.amount = amount;
            user.rewarded = 0;
            user.rewardDebt = 0;
            user.lastDepositTimeStamp = block.timestamp;            
        } else {
            user.amount = user.amount + amount;
            user.lastDepositTimeStamp = block.timestamp;
        }
        totalAmount = totalAmount + amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw() public lock {
        UserInfo storage user = userInfo[msg.sender];
        require(user.lastDepositTimeStamp > 0, "invalid user");
        require(user.amount > 0, "not staked");
        require(user.lastDepositTimeStamp + lockedTime < block.timestamp, "you are in lockedTime.");
        updatePool();
        uint256 withdrawAmount = user.amount;
        user.amount = 0;
        totalAmount = totalAmount - withdrawAmount;
        uint256 rewardAmount = user.rewardDebt;
        user.rewardDebt = 0;
        if (user.lastDepositTimeStamp + lockedTime < block.timestamp) {
            rewardAmount = rewardAmount * 9 / 10;
        }
        user.rewarded = user.rewarded + rewardAmount;
        TransferHelper.safeTransfer(cifiToken, msg.sender, withdrawAmount + rewardAmount);
        emit Withdraw(msg.sender, withdrawAmount);
        emit Reward(msg.sender, rewardAmount);
    }

    function reward() public lock {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 rewardAmount = user.rewardDebt;
        require(rewardAmount > 0, "not enough reward amount");
        if (user.lastDepositTimeStamp + lockedTime < block.timestamp) {
            rewardAmount = rewardAmount * 9 / 10;
        }
        
        user.rewarded = user.rewarded + rewardAmount;
        user.rewardDebt = 0;
        TransferHelper.safeTransfer(cifiToken, msg.sender, rewardAmount);
        emit Reward(msg.sender, rewardAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}