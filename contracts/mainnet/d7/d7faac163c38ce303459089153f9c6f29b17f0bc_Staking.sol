// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";

import "./ERC20Snapshot.sol";
import "./AccessControlEnumerable.sol";

import {SafeMathInt, SafeMathUint} from "./SafeMath.sol";

interface Token is IERC20Permit, IERC20 {}

/// @title Staking contract for ERC20 tokens
/// @author Daniel Gretzke
/// @notice Allows users to stake an underlying ERC20 token and receive a new ERC20 token in return which tracks their stake in the pool
/// @notice Rewards in form of the underlying ERC20 token are distributed proportionally across all staking participants
/// @notice Rewards in ETH are distributed proportionally across all staking participants
contract Staking is ERC20Snapshot, AccessControlEnumerable {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 private constant MAX_UINT256 = type(uint256).max;
    // allows to distribute small amounts of ETH correctly
    uint256 internal constant MAGNITUDE = 10**40;
    bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTTER");

    Token token;
    uint256 internal magnifiedRewardPerShare;
    mapping(address => int256) internal magnifiedRewardCorrections;
    mapping(address => uint256) public claimedRewards;

    event RewardsReceived(address indexed from, uint256 amount);
    event Deposit(address indexed user, uint256 underlyingToken, uint256 overlyingToken);
    event Withdraw(address indexed user, uint256 underlyingToken, uint256 overlyingToken);
    event RewardClaimed(address indexed user, address indexed to, uint256 amount);
    event SnapshotterUpdated(address snapshotter, bool isSnapshotter);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) ERC20(_name, _symbol) {
        token = Token(_token);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice when the smart contract receives ETH, register payment
    /// @dev can only receive ETH when tokens are staked
    receive() external payable {
        require(totalSupply() > 0, "NO_TOKENS_STAKED");
        if (msg.value > 0) {
            magnifiedRewardPerShare += (msg.value * MAGNITUDE) / totalSupply();
            emit RewardsReceived(_msgSender(), msg.value);
        }
    }

    /// @notice creates a snapshot of the current balances, used to calculate random NFT rewards
    /// @dev only parties with snapshotter role can call this function
    /// @return id of the taken snapshot
    function takeSnapshot() external onlyRole(SNAPSHOTTER_ROLE) returns (uint256) {
        return _snapshot();
    }

    /// @notice allows to deposit tokens without an approve transaction by using the EIP2612 permit standard
    /// @param _amount amount of underlying token to deposit
    /// @param _deadline until the signature is valid
    /// @param _signature permit signature
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bytes memory _signature
    ) external {
        require(_signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        token.permit(_msgSender(), address(this), type(uint256).max, _deadline, v, r, s);
        deposit(_amount);
    }

    /// @notice allows to deposit the underlying token into the staking contract
    /// @dev mints an amount of overlying tokens according to the stake in the pool
    /// @param _amount amount of underlying token to deposit
    function deposit(uint256 _amount) public {
        uint256 share = 0;
        if (totalSupply() > 0) {
            share = (totalSupply() * _amount) / token.balanceOf(address(this));
        } else {
            share = _amount;
        }
        token.transferFrom(_msgSender(), address(this), _amount);
        _mint(_msgSender(), share);
        emit Deposit(_msgSender(), _amount, share);
    }

    /// @notice allows to withdraw the underlying token from the staking contract
    /// @param _amount of overlying tokens to withdraw
    /// @param _claim whether or not to claim ETH rewards
    /// @return amount of underlying tokens withdrawn
    function withdraw(uint256 _amount, bool _claim) external returns (uint256) {
        if (_claim) {
            claimRewards(_msgSender());
        }
        uint256 withdrawnTokens = (_amount * token.balanceOf(address(this))) / totalSupply();
        _burn(_msgSender(), _amount);
        token.transfer(_msgSender(), withdrawnTokens);
        emit Withdraw(_msgSender(), withdrawnTokens, _amount);
        return withdrawnTokens;
    }

    /// @notice allows to claim accumulated ETH rewards
    /// @param _to address to send rewards to
    function claimRewards(address _to) public {
        uint256 claimableRewards = claimableRewardsOf(_msgSender());
        if (claimableRewards > 0) {
            claimedRewards[_msgSender()] += claimableRewards;
            (bool success, ) = _to.call{value: claimableRewards}("");
            require(success, "ETH_TRANSFER_FAILED");
            emit RewardClaimed(_msgSender(), _to, claimableRewards);
        }
    }

    /// @dev on mint, burn and transfer adjust corrections so that ETH rewards don't change on these events
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            magnifiedRewardCorrections[to] -= (magnifiedRewardPerShare * amount).toInt256Safe();
        } else if (to == address(0)) {
            // burn
            magnifiedRewardCorrections[from] += (magnifiedRewardPerShare * amount).toInt256Safe();
        } else {
            // transfer
            int256 magnifiedCorrection = (magnifiedRewardPerShare * amount).toInt256Safe();
            magnifiedRewardCorrections[from] += (magnifiedCorrection);
            magnifiedRewardCorrections[to] -= (magnifiedCorrection);
        }
    }

    /// @return accumulated underlying token balance that can be withdrawn by the user
    function tokenBalance(address _user) public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return (balanceOf(_user) * token.balanceOf(address(this))) / totalSupply();
    }

    /// @return total amount of ETH rewards earned by user
    function totalRewardsEarned(address _user) public view returns (uint256) {
        int256 magnifiedRewards = (magnifiedRewardPerShare * balanceOf(_user)).toInt256Safe();
        uint256 correctedRewards = (magnifiedRewards + magnifiedRewardCorrections[_user]).toUint256Safe();
        return correctedRewards / MAGNITUDE;
    }

    /// @return amount of ETH rewards that can be claimed by user
    function claimableRewardsOf(address _user) public view returns (uint256) {
        return totalRewardsEarned(_user) - claimedRewards[_user];
    }
}