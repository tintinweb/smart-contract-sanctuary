// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMathInt, SafeMathUint} from "./libraries/SafeMath.sol";

contract Staking is Ownable {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant MAGNITUDE = 10**40;

    // Token token;
    uint256 internal magnifiedRewardPerShare;
    mapping(address => int256) internal magnifiedRewardCorrections;
    uint256 internal _totalSupply;
    mapping(address => uint256) public claimedRewards;

    event RewardsReceived(address indexed from, uint256 amount);
    event Deposit(address indexed user, uint256 underlyingToken);
    event Withdraw(address indexed user, uint256 underlyingToken);
    event RewardClaimed(address indexed user, address indexed to, uint256 amount);

    /// @notice when the smart contract receives ETH, register payment
    /// @dev can only receive ETH when tokens are staked
    receive() external payable {
        require(totalSupply() > 0, "NO_TOKENS_STAKED");
        if (msg.value > 0) {
            magnifiedRewardPerShare += (msg.value * MAGNITUDE) / totalSupply();
            emit RewardsReceived(msg.sender, msg.value);
        }
    }

    /// @notice allows to deposit the underlying token into the staking contract
    /// @dev mints an amount of overlying tokens according to the stake in the pool
    /// @param _amount amount of underlying token to deposit
    function deposit(address sender, uint256 _amount) external onlyOwner {
        _totalSupply += _amount;
        magnifiedRewardCorrections[sender] -= (magnifiedRewardPerShare * _amount).toInt256Safe();
        emit Deposit(sender, _amount);
    }

    /// @notice allows to withdraw the underlying token from the staking contract
    /// @param _amount of overlying tokens to withdraw
    /// @param _claim whether or not to claim ETH rewards
    /// @return amount of underlying tokens withdrawn
    function withdraw(address sender, uint256 _amount, bool _claim) external onlyOwner returns (uint256) {
        if (_claim) {
            uint256 claimableRewards = claimableRewardsOf(sender, _amount);
            if (claimableRewards > 0) {
                claimedRewards[sender] += claimableRewards;
                (bool success, ) = sender.call{value: claimableRewards}("");
                require(success, "ETH_TRANSFER_FAILED");
                emit RewardClaimed(sender, sender, claimableRewards);
            }
        }
        _totalSupply -= _amount;
        magnifiedRewardCorrections[sender] += (magnifiedRewardPerShare * _amount).toInt256Safe();
        emit Withdraw(sender, _amount);
        return _amount;
    }

    /// @notice allows to claim accumulated ETH rewards
    /// @param _to address to send rewards to
    function claimRewards(address sender, address _to, uint256 userAmount) external onlyOwner {
        uint256 claimableRewards = claimableRewardsOf(sender, userAmount);
        if (claimableRewards > 0) {
            claimedRewards[sender] += claimableRewards;
            (bool success, ) = _to.call{value: claimableRewards}("");
            require(success, "ETH_TRANSFER_FAILED");
            emit RewardClaimed(sender, _to, claimableRewards);
        }
    }

    /// @return total amount of ETH rewards earned by user
    function totalRewardsEarned(address _user, uint256 userAmount) public view returns (uint256) {
        int256 magnifiedRewards = (magnifiedRewardPerShare * userAmount).toInt256Safe();
        uint256 correctedRewards = (magnifiedRewards + magnifiedRewardCorrections[_user]).toUint256Safe();
        return correctedRewards / MAGNITUDE;
    }

    /// @return amount of ETH rewards that can be claimed by user
    function claimableRewardsOf(address _user, uint256 userAmount) public view returns (uint256) {
        return totalRewardsEarned(_user, userAmount) - claimedRewards[_user];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}