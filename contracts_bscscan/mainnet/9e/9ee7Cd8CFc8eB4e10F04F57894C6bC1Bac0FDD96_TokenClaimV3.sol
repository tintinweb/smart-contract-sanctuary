/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.9;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

pragma solidity 0.8.9;

contract TokenClaimV3 is Ownable {
    using SafeERC20 for IERC20;

    string public name;
    IERC20 public ERC20Interface;

    mapping(address => mapping(uint256 => uint256)) public unlockTime;
    mapping(address => mapping(uint256 => mapping(address => uint256))) userTokenClaimPerPhase;

    event RewardAdded(address indexed token, uint256 phase, uint256 amount);
    event Claimed(address indexed user, address indexed token, uint256 amount);

    modifier _hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        require(token != address(0), "Zero token address");
        ERC20Interface = IERC20(token);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    function updateUserTokens(
        address tokenAddress,
        uint256 totalReward,
        uint256 phaseNo,
        uint256 release,
        address[] memory users,
        uint256[] memory tokenValues
    )
        external
        _hasAllowance(msg.sender, totalReward, tokenAddress)
        onlyOwner
        returns (bool)
    {
        require(totalReward > 0 && users.length > 0, "Invalid data");
        require(users.length == tokenValues.length, "Invalid user data");
        require(release > block.timestamp, "Invalid release time");
        if (unlockTime[tokenAddress][phaseNo] > 0) {
            require(
                block.timestamp < unlockTime[tokenAddress][phaseNo],
                "Phase already started"
            );
        }
        unlockTime[tokenAddress][phaseNo] = release;
        uint256 rewardCheck = totalReward;
        for (uint256 i = 0; i < users.length; i++) {
            userTokenClaimPerPhase[tokenAddress][phaseNo][users[i]] =
                userTokenClaimPerPhase[tokenAddress][phaseNo][users[i]] +
                tokenValues[i];
            unchecked {
                rewardCheck = rewardCheck - tokenValues[i];
            }
        }
        require(rewardCheck == 0, "Incorrect reward values");
        ERC20Interface = IERC20(tokenAddress);
        ERC20Interface.safeTransferFrom(msg.sender, address(this), totalReward);
        emit RewardAdded(tokenAddress, phaseNo, totalReward);
        return true;
    }

    function getUserPhaseTokenClaim(
        address tokenAddress,
        uint256 phaseNo,
        address user
    ) external view returns (uint256) {
        return userTokenClaimPerPhase[tokenAddress][phaseNo][user];
    }

    function claim(address tokenAddress, uint256 phaseNo)
        external
        returns (bool)
    {
        require(
            unlockTime[tokenAddress][phaseNo] < block.timestamp,
            "Wait for unlock time"
        );
        uint256 amount = userTokenClaimPerPhase[tokenAddress][phaseNo][
            msg.sender
        ];
        require(
            amount > 0,
            "No claimable tokens available for user in this phase"
        );
        delete userTokenClaimPerPhase[tokenAddress][phaseNo][msg.sender];
        ERC20Interface = IERC20(tokenAddress);
        require(
            ERC20Interface.balanceOf(address(this)) > amount,
            "No tokens available in the contract"
        );
        ERC20Interface.safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, tokenAddress, amount);
        return true;
    }
}