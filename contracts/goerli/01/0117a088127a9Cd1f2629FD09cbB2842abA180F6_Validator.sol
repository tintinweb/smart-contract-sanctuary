// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IStakeManager.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/INodeOperatorRegistry.sol";

/// @title ValidatorImplementation
/// @author 2021 ShardLabs.
/// @notice The validator contract is a simple implementation of the stakeManager API, the
/// ValidatorProxies use this contract to interact with the stakeManager.
/// When a ValidatorProxy calls this implementation the state is copied
/// (owner, implementation, operator), then they are used to check if the msg-sender is the
/// node operator contract, and if the validatorProxy implementation match with the current
/// validator contract.
contract Validator is IERC721Receiver, IValidator {
    using SafeERC20 for IERC20;

    address private implementation;
    address private operator;
    address private validatorFactory;

    /// @notice Check if the operator contract is the msg.sender.
    modifier isOperator() {
        require(
            msg.sender == operator,
            "Caller should be the operator contract"
        );
        _;
    }

    /// @notice Allows to stake on the Polygon stakeManager contract by
    /// calling stakeFor function and set the user as the equal to this validator proxy
    /// address.
    /// @param _sender the address of the operator-owner that approved Matics.
    /// @param _amount the amount to stake with.
    /// @param _heimdallFee the heimdall fees.
    /// @param _acceptDelegation accept delegation.
    /// @param _signerPubkey signer public key used on the heimdall node.
    /// @param _commissionRate validator commision rate
    /// @return Returns the validatorId and the validatorShare contract address.
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _heimdallFee,
        bool _acceptDelegation,
        bytes memory _signerPubkey,
        uint256 _commissionRate,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (uint256, address) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        IERC20 polygonERC20 = IERC20(_polygonERC20);

        uint256 totalAmount = _amount + _heimdallFee;
        polygonERC20.safeTransferFrom(_sender, address(this), totalAmount);
        polygonERC20.safeApprove(address(stakeManager), totalAmount);
        stakeManager.stakeFor(
            address(this),
            _amount,
            _heimdallFee,
            _acceptDelegation,
            _signerPubkey
        );

        uint256 validatorId = stakeManager.getValidatorId(address(this));
        address validatorShare = stakeManager.getValidatorContract(validatorId);
        if (_commissionRate > 0) {
            stakeManager.updateCommissionRate(validatorId, _commissionRate);
        }

        return (validatorId, validatorShare);
    }

    /// @notice Restake validator rewards or new Matics validator on stake manager.
    /// @param _sender operator's owner that approved tokens to the validator contract.
    /// @param _validatorId validator id.
    /// @param _amount amount to stake.
    /// @param _stakeRewards restake rewards.
    /// @param _amountStaked total amount staked by the operator in stake manager.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    /// @return return a bool and the new total amount staked in stake manager.
    function restake(
        address _sender,
        uint256 _validatorId,
        uint256 _amount,
        bool _stakeRewards,
        uint256 _amountStaked,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (bool, uint256) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);

        if (_amount > 0) {
            IERC20 polygonERC20 = IERC20(_polygonERC20);
            polygonERC20.safeTransferFrom(_sender, address(this), _amount);
            polygonERC20.safeApprove(address(stakeManager), _amount);
        }
        if (stakeManager.validatorStake(_validatorId) != _amountStaked) {
            return (false, 0);
        }

        stakeManager.restake(_validatorId, _amount, _stakeRewards);

        return (true, stakeManager.validatorStake(_validatorId));
    }

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @param _validatorId validatorId.
    /// @param _stakeManager address of the stake manager
    function unstake(uint256 _validatorId, address _stakeManager)
        external
        override
        isOperator
    {
        // stakeManager
        IStakeManager(_stakeManager).unstake(_validatorId);
    }

    /// @notice Allows a validator to top-up the heimdall fees.
    /// @param _sender address that approved the _heimdallFee amount.
    /// @param _heimdallFee amount.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function topUpForFee(
        address _sender,
        uint256 _heimdallFee,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        IERC20 polygonERC20 = IERC20(_polygonERC20);

        polygonERC20.safeTransferFrom(_sender, address(this), _heimdallFee);
        polygonERC20.safeApprove(address(stakeManager), _heimdallFee);
        stakeManager.topUpForFee(address(this), _heimdallFee);
    }

    /// @notice Allows to withdraw rewards from the validator using the _validatorId. Only the
    /// owner can request withdraw. The rewards are transfered to the _rewardAddress.
    /// @param _validatorId validator id.
    /// @param _rewardAddress reward address.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function withdrawRewards(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (uint256) {
        IStakeManager(_stakeManager).withdrawRewards(_validatorId);

        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);

        return balance;
    }

    /// @notice Allows to unstake the staked tokens (+rewards) and transfer them
    /// to the owner rewardAddress.
    /// @param _validatorId validator id.
    /// @param _rewardAddress rewardAddress address.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function unstakeClaim(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (uint256) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        stakeManager.unstakeClaim(_validatorId);
        // polygonERC20
        // stakeManager
        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);

        return balance;
    }

    /// @notice Allows to update signer publickey.
    /// @param _validatorId validator id.
    /// @param _signerPubkey new publickey.
    /// @param _stakeManager stake manager address
    function updateSigner(
        uint256 _validatorId,
        bytes memory _signerPubkey,
        address _stakeManager
    ) external override isOperator {
        IStakeManager(_stakeManager).updateSigner(_validatorId, _signerPubkey);
    }

    /// @notice Allows withdraw heimdall fees.
    /// @param _accumFeeAmount accumulated heimdall fees.
    /// @param _index index.
    /// @param _proof proof.
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        stakeManager.claimFee(_accumFeeAmount, _index, _proof);

        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);
    }

    /// @notice Allows to update commission rate of a validator.
    /// @param _validatorId validator id.
    /// @param _newCommissionRate new commission rate.
    /// @param _stakeManager stake manager address
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate,
        address _stakeManager
    ) public override isOperator {
        IStakeManager(_stakeManager).updateCommissionRate(
            _validatorId,
            _newCommissionRate
        );
    }

    /// @notice Allows to unjail a validator.
    /// @param _validatorId validator id
    function unjail(uint256 _validatorId, address _stakeManager)
        external
        override
        isOperator
    {
        IStakeManager(_stakeManager).unjail(_validatorId);
    }

    /// @notice Allows to transfer the validator nft token to the reward address a validator.
    /// @param _validatorId operator id.
    /// @param _stakeManagerNFT stake manager nft contract.
    /// @param _rewardAddress reward address.
    function migrate(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress
    ) external override isOperator {
        IERC721 erc721 = IERC721(_stakeManagerNFT);
        erc721.approve(_rewardAddress, _validatorId);
        erc721.safeTransferFrom(address(this), _rewardAddress, _validatorId);
    }

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    /// @param _validatorId validator id
    /// @param _stakeManagerNFT address of the staking NFT
    /// @param _rewardAddress address that will receive the rewards from staking
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager address of the stake manager
    function join(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external override isOperator {
        IERC721 erc721 = IERC721(_stakeManagerNFT);
        erc721.safeTransferFrom(_rewardAddress, address(this), _validatorId);
        updateCommissionRate(_validatorId, _newCommissionRate, _stakeManager);
    }

    /// @notice Allows to get the version of the validator implementation.
    /// @return Returns the version.
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice Implement @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol interface.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title polygon stake manager interface.
/// @author 2021 ShardLabs
/// @notice User to interact with the polygon stake manager.
interface IStakeManager {
    /// @notice Stake a validator on polygon stake manager.
    /// @param user user that own the validator in our case the validator contract.
    /// @param amount amount to stake.
    /// @param heimdallFee heimdall fees.
    /// @param acceptDelegation accept delegation.
    /// @param signerPubkey signer publickey used in heimdall node.
    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) external;

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param validatorId validator id.
    /// @param amount amount to stake.
    /// @param stakeRewards restake rewards.
    function restake(
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards
    ) external;

    /// @notice Request unstake a validator.
    /// @param validatorId validator id.
    function unstake(uint256 validatorId) external;

    /// @notice Increase the heimdall fees.
    /// @param user user that own the validator in our case the validator contract.
    /// @param heimdallFee heimdall fees.
    function topUpForFee(address user, uint256 heimdallFee) external;

    /// @notice Get the validator id using the user address.
    /// @param user user that own the validator in our case the validator contract.
    /// @return return the validator id
    function getValidatorId(address user) external view returns (uint256);

    /// @notice get the validator contract used for delegation.
    /// @param validatorId validator id.
    /// @return return the address of the validator contract.
    function getValidatorContract(uint256 validatorId)
        external
        view
        returns (address);

    /// @notice Withdraw accumulated rewards
    /// @param validatorId validator id.
    function withdrawRewards(uint256 validatorId) external returns (uint256);

    /// @notice Get validator total staked.
    /// @param validatorId validator id.
    function validatorStake(uint256 validatorId)
        external
        view
        returns (uint256);

    /// @notice Allows to unstake the staked tokens on the stakeManager.
    /// @param validatorId validator id.
    function unstakeClaim(uint256 validatorId) external;

    /// @notice Allows to update the signer pubkey
    /// @param _validatorId validator id
    /// @param _signerPubkey update signer public key
    function updateSigner(uint256 _validatorId, bytes memory _signerPubkey)
        external;

    /// @notice Allows to claim the heimdall fees.
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external;

    /// @notice Allows to update the commision rate of a validator
    /// @param _validatorId operator id
    /// @param _newCommissionRate commission rate
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate
    ) external;

    /// @notice Allows to unjail a validator.
    /// @param _validatorId id of the validator that is to be unjailed
    function unjail(uint256 _validatorId) external;

    /// @notice Returns a withdrawal delay.
    function withdrawalDelay() external view returns (uint256);

    /// @notice Transfers amount from delegator
    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function epoch() external view returns (uint256);

    enum Status {
        Inactive,
        Active,
        Locked,
        Unstaked
    }

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
        uint256 commissionRate;
        uint256 lastCommissionUpdate;
        uint256 delegatorsReward;
        uint256 delegatedAmount;
        uint256 initialRewardPerStake;
    }

    function validators(uint256 _index)
        external
        view
        returns (Validator memory);

    /// @notice Returns the address of the nft contract
    function NFTContract() external view returns (address);

    /// @notice Returns the validator accumulated rewards on stake manager.
    function validatorReward(uint256 validatorId)
        external
        view
        returns (uint256);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../Validator.sol";

/// @title IValidator.
/// @author 2021 ShardLabs
/// @notice Validator interface.
interface IValidator {
    /// @notice Allows to stake a validator on the Polygon stakeManager contract.
    /// @dev Stake a validator on the Polygon stakeManager contract.
    /// @param _sender msg.sender.
    /// @param _amount amount to stake.
    /// @param _heimdallFee herimdall fees.
    /// @param _acceptDelegation accept delegation.
    /// @param _signerPubkey signer public key used on the heimdall.
    /// @param _commisionRate commision rate of a validator
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _heimdallFee,
        bool _acceptDelegation,
        bytes memory _signerPubkey,
        uint256 _commisionRate,
        address stakeManager,
        address polygonERC20
    ) external returns (uint256, address);

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param _sender operator owner which approved tokens to the validato contract.
    /// @param validatorId validator id.
    /// @param amount amount to stake.
    /// @param stakeRewards restake rewards.
    /// @param amountStaked total amount staked by the operator in stake manager.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function restake(
        address _sender,
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards,
        uint256 amountStaked,
        address _stakeManager,
        address _polygonERC20
    ) external returns (bool, uint256);

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @dev Unstake a validator from the Polygon stakeManager contract by passing the validatorId
    /// @param _validatorId validatorId.
    /// @param _stakeManager address of the stake manager
    function unstake(uint256 _validatorId, address _stakeManager) external;

    /// @notice Allows to top up heimdall fees.
    /// @param _heimdallFee amount
    /// @param _sender msg.sender
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function topUpForFee(
        address _sender,
        uint256 _heimdallFee,
        address _stakeManager,
        address _polygonERC20
    ) external;

    /// @notice Allows to withdraw rewards from the validator.
    /// @dev Allows to withdraw rewards from the validator using the _validatorId. Only the
    /// owner can request withdraw in this the owner is this contract.
    /// @param _validatorId validator id.
    /// @param _rewardAddress user address used to transfer the staked tokens.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    /// @return Returns the amount transfered to the user.
    function withdrawRewards(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external returns (uint256);

    /// @notice Allows to claim staked tokens on the stake Manager after the end of the
    /// withdraw delay
    /// @param _validatorId validator id.
    /// @param _rewardAddress user address used to transfer the staked tokens.
    /// @return Returns the amount transfered to the user.
    function unstakeClaim(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external returns (uint256);

    /// @notice Allows to update the signer pubkey
    /// @param _validatorId validator id
    /// @param _signerPubkey update signer public key
    /// @param _stakeManager stake manager address
    function updateSigner(
        uint256 _validatorId,
        bytes memory _signerPubkey,
        address _stakeManager
    ) external;

    /// @notice Allows to claim the heimdall fees.
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    /// @param _ownerRecipient owner recipient
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof,
        address _ownerRecipient,
        address _stakeManager,
        address _polygonERC20
    ) external;

    /// @notice Allows to update the commision rate of a validator
    /// @param _validatorId operator id
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager stake manager address
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external;

    /// @notice Allows to unjail a validator.
    /// @param _validatorId operator id
    function unjail(uint256 _validatorId, address _stakeManager) external;

    /// @notice Allows to migrate the ownership to an other user.
    /// @param _validatorId operator id.
    /// @param _stakeManagerNFT stake manager nft contract.
    /// @param _rewardAddress reward address.
    function migrate(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress
    ) external;

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    /// @param _validatorId validator id
    /// @param _stakeManagerNFT address of the staking NFT
    /// @param _rewardAddress address that will receive the rewards from staking
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager address of the stake manager
    function join(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../lib/Operator.sol";

/// @title INodeOperatorRegistry
/// @author 2021 ShardLabs
/// @notice Node operator registry interface
interface INodeOperatorRegistry {
    /// @notice Allows to add a new node operator to the system.
    /// @param _name the node operator name.
    /// @param _rewardAddress public address used for ACL and receive rewards.
    /// @param _signerPubkey public key used on heimdall len 64 bytes.
    function addOperator(
        string memory _name,
        address _rewardAddress,
        bytes memory _signerPubkey
    ) external;

    /// @notice Allows to stop a node operator.
    /// @param _operatorId node operator id.
    function stopOperator(uint256 _operatorId) external;

    /// @notice Allows to remove a node operator from the system.
    /// @param _operatorId node operator id.
    function removeOperator(uint256 _operatorId) external;

    /// @notice Allows a staked validator to join the system.
    function joinOperator() external;

    /// @notice Allows to stake an operator on the Polygon stakeManager.
    /// This function calls Polygon transferFrom so the totalAmount(_amount + _heimdallFee)
    /// has to be approved first.
    /// @param _amount amount to stake.
    /// @param _heimdallFee heimdallFee to stake.
    function stake(uint256 _amount, uint256 _heimdallFee) external;

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param _amount amount to stake.
    /// @param _restakeRewards restake rewards.
    function restake(uint256 _amount, bool _restakeRewards) external;

    /// @notice Allows the operator's owner to migrate the NFT. This can be done only
    /// if the DAO stopped the operator.
    function migrate() external;

    /// @notice Allows to unstake an operator from the stakeManager. After the withdraw_delay
    /// the operator owner can call claimStake func to withdraw the staked tokens.
    function unstake() external;

    /// @notice Allows to topup heimdall fees on polygon stakeManager.
    /// @param _heimdallFee amount to topup.
    function topUpForFee(uint256 _heimdallFee) external;

    /// @notice Allows to claim staked tokens on the stake Manager after the end of the
    /// withdraw delay
    function unstakeClaim() external;

    /// @notice Allows to get the total staked by a validator.
    /// @param _rewardAddress reward address.
    /// @return Returns the total staked.
    function getValidatorStake(address _rewardAddress)
        external
        view
        returns (uint256);

    /// @notice Allows an owner to withdraw rewards from the stakeManager.
    function withdrawRewards() external;

    /// @notice Allows to update the signer pubkey
    /// @param _signerPubkey update signer public key
    function updateSigner(bytes memory _signerPubkey) external;

    /// @notice Allows to claim the heimdall fees staked by the owner of the operator
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external;

    /// @notice Allows to unjail a validator and switch from UNSTAKE status to STAKED
    function unjail() external;

    /// @notice Allows an operator's owner to set the operator name.
    function setOperatorName(string memory _name) external;

    /// @notice Allows an operator's owner to set the operator rewardAddress.
    function setOperatorRewardAddress(address _rewardAddress) external;

    /// @notice Allows the DAO to set _defaultMaxDelegateLimit.
    function setDefaultMaxDelegateLimit(uint256 _defaultMaxDelegateLimit)
        external;

    /// @notice Allows the DAO to set _maxDelegateLimit for an operator.
    function setMaxDelegateLimit(uint256 _operatorId, uint256 _maxDelegateLimit)
        external;

    /// @notice Allows the DAO to set _slashingDelay.
    function setSlashingDelay(uint256 _slashingDelay) external;

    /// @notice Allows the DAO to set _commissionRate.
    function setCommissionRate(uint256 _commissionRate) external;

    /// @notice Allows the DAO to set _commissionRate for an operator.
    /// @param _operatorId id of the operator
    /// @param _newCommissionRate new commission rate
    function updateOperatorCommissionRate(
        uint256 _operatorId,
        uint256 _newCommissionRate
    ) external;

    /// @notice Allows the DAO to set _minAmountStake and _minHeimdallFees.
    function setStakeAmountAndFees(
        uint256 _minAmountStake,
        uint256 _minHeimdallFees
    ) external;

    /// @notice Allows to pause/unpause the node operator contract.
    function togglePause() external;

    /// @notice Allows the DAO to enable/disable restake.
    function setRestake(bool _restake) external;

    /// @notice Allows the DAO to enable/disable unjail.
    function setUnjail(bool _unjail) external;

    /// @notice Allows the DAO to set stMATIC contract.
    function setStMATIC(address _stMATIC) external;

    /// @notice Allows the DAO to set validator factory contract.
    function setValidatorFactory(address _validatorFactory) external;

    /// @notice Allows the DAO to set stake manager contract.
    function setStakeManager(address _stakeManager) external;

    /// @notice Allows to set contract version.
    function setVersion(string memory _version) external;

    /// @notice Get the stMATIC contract addresses
    function getContracts()
        external
        view
        returns (
            address _validatorFactory,
            address _stakeManager,
            address _polygonERC20,
            address _stMATIC
        );

    /// @notice Allows to get stats.
    function getState()
        external
        view
        returns (
            uint256 _totalNodeOperator,
            uint256 _totalInactiveNodeOperator,
            uint256 _totalActiveNodeOperator,
            uint256 _totalStoppedNodeOperator,
            uint256 _totalUnstakedNodeOperator,
            uint256 _totalClaimedNodeOperator,
            uint256 _totalWaitNodeOperator,
            uint256 _totalExitNodeOperator
        );

    /// @notice Allows to get all the active operators info.
    function getOperatorInfos(bool _rewardData)
        external
        view
        returns (Operator.OperatorInfo[] memory);

    /// @notice Allows slashing all the operators if the local stakedAmount is not equal
    /// to the stakedAmount on stake manager.
    function slashOperators(bool[] memory _slashedOperatorIds) external;

    /// @notice Allows listing all the operator's status by checking if the local stakedAmount
    /// is not equal to the stakedAmount on stake manager.
    function getIfOperatorsWereSlashed() external view returns (bool[] memory);

    /// @notice Allows update an operator status from WAIT to EXIT
    function exitOperator(address _validatorShare) external;

    /// @notice Allows to get all the operator ids.
    function getOperatorIds() external view returns (uint256[] memory);

    /// @notice Allows to get an node operator validatorShare contracts.
    function getNodeOperatorState() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

library Operator {
    struct OperatorInfo {
        uint256 operatorId;
        address validatorShare;
        uint256 maxDelegateLimit;
        uint8 rewardPercentage;
        address rewardAddress;
    }
}