// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../util/Ownable.sol";
import "../USOFactory/IUSOFactory.sol";
import "./IUSO.sol";
import "../util/Approvable.sol";

/**
 * @title IFOV2
 * @notice It is an upgrade of the original USO model with 2 pools and
 * other PancakeProfile requirements.
 */
contract USO is IUSO, ReentrancyGuard, Ownable, Approvable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The offering token
    IERC20 public override offeringToken;

    // The factory
    IUSOFactory public override factory;

    // The block number when USO starts
    uint256 public override startsAt;

    // The block number when USO ends
    uint256 public override endsAt;

    // percent of fee which goes to the contract
    uint32 public override feePercent;

    // the metadata for the offering
    string public override metadata;

    // The specific pool information associated with this offering
    PoolInfo private _poolInfo;

    // total amount pool deposited
    uint256 public override totalAmountRaised;

    // how many rewards that have been claimed
    bool public override rewardsClaimed;

    // whether or not the contact has been marked as failed.
    bool public override reverted;

    // It maps the address to pool id to UserInfo
    mapping(address => UserInfo) public userInfo;

    bytes32 public constant override VERSION = bytes32('1.0.0');

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint32 public constant BASE_PERCENTAGE = 1e5;

    // Modifier to prevent contracts to participate
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        factory.checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev a check to ensure that the contract has not been reverted.
     */
    modifier notReverted() {
        require(!reverted, 'the offering has been reverted');
        _;
    }

    /**
     * @notice It initializes the contract (for proxy patterns)
     * @dev It can only be called once.
     * @param _factory: the factory this USO belongs to
     * @param _offeringToken: the token that is offered for the USO
     * @param _feePercent the percentage
     * @param _startsAt: the start block for the USO
     * @param _endsAt: the end block for the USO
     * @param _tokenOwnerAddress: the admin address for handling tokens
     */
    function initialize(
        address _factory,
        address _offeringToken,
        uint32 _feePercent,
        uint256 _startsAt,
        uint256 _endsAt,
        address _tokenOwnerAddress
    ) external override initializer {

        factory = IUSOFactory(_factory);
        offeringToken = IERC20(_offeringToken);

        require(offeringToken.totalSupply() >= 0);

        feePercent = _feePercent;
        startsAt = _startsAt;
        endsAt = _endsAt;

        Ownable__init(_tokenOwnerAddress);
    }

    /**
    * @dev returns whether or not this USO has begun
    * @return bool
    */
    function started() external view override returns (bool) {
        return block.timestamp >= startsAt;
    }

    /**
    * @dev returns whether or not this USO has begun
    * @return bool
    */
    function ended() external view override returns (bool) {
        return block.timestamp >= endsAt;
    }

    /**
    * @dev returns the pool information for this contract
    * @return PoolInfo
    */
    function poolInfo() external view override returns (PoolInfo memory) {
        return _poolInfo;
    }

    /**
     * @notice reverts a contract permanently. Preventing any further donations and allows everyone to safely
     * withdraw their investment
     * @dev is only callable with the correct permissions and can only be called once.
     */
    function revertOffering(string memory reason) external override onlyRole(factory.REVERT_ROLE()) notReverted {
        reverted = true;
        emit Reverted(reason, msg.sender);
    }

    /**
     * @notice It allows users to deposit the native token into the pool
     */
    function deposit() external payable override nonReentrant notContract onceApproved notReverted {
        uint256 _amount = msg.value;

        // Checks that pool was set
        require(
            _poolInfo.offeringAmount > 0 && _poolInfo.maxRaisingAmount > 0,
            "Pool not set"
        );

        // Checks whether the block number is not too early
        require(block.timestamp > startsAt, "Too early");

        // Checks whether the block number is not too late
        require(block.timestamp < endsAt, "Too late");

        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Amount must be greater than 0");

        // Update the user status
        userInfo[msg.sender].amountPool = userInfo[msg.sender].amountPool.add(_amount);

        // Check if the pool has a limit per user
        if (_poolInfo.maxEntryAmount > 0) {
            // Checks whether the limit has been reached
            require(
                userInfo[msg.sender].amountPool <= _poolInfo.maxEntryAmount,
                "New amount above user limit"
            );
        }

        // Check if the pool has a limit per user
        if (_poolInfo.minEntryAmount > 0) {
            // Checks whether the limit has been reached
            require(
                userInfo[msg.sender].amountPool >= _poolInfo.minEntryAmount,
                "New amount below user limit"
            );
        }

        // Updates the totalAmount for pool
        totalAmountRaised = totalAmountRaised.add(_amount);

        require(totalAmountRaised <= _poolInfo.maxRaisingAmount, 'Too many funds');

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice It allows users to harvest from pool. Will refund any bnb leftover, or send the user any rewards they received.
     */
    function harvest() external override nonReentrant notContract {
        // Checks whether it is too early to harvest
        require(block.timestamp > endsAt, "Too early to harvest");

        // Checks whether the user has participated
        require(userInfo[msg.sender].amountPool > 0, "Did not participate");

        // Checks whether the user has already harvested
        require(!userInfo[msg.sender].claimedPool, "Has harvested");

        // Updates the harvest status
        userInfo[msg.sender].claimedPool = true;

        uint256 offeringTokenAmount;
        uint256 refundingAmount;

        if (_minRequirementsMet()) {
            // Initialize the variables for offering, refunding user amounts, and tax amount
            offeringTokenAmount = _calculateOfferingAmount(msg.sender);

            // Transfer these tokens back to the user if quantity > 0
            if (offeringTokenAmount > 0) {
                offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
            }
        } else {
            refundingAmount = userInfo[msg.sender].amountPool;
            payable(msg.sender).transfer(refundingAmount);
        }

        emit Harvest(msg.sender, offeringTokenAmount, refundingAmount);
    }

    /**
    * @notice Updates the fee percent for the offering. This can only be done while the offering has not [email protected]
    */
    function setFeePercent(uint32 newFeePercent) external onlyRole(factory.FEE_ROLE()) notApproved {
        require(block.timestamp < startsAt, 'Promotion has already started.');
        require(newFeePercent <= BASE_PERCENTAGE, 'Invalid percentage');

        feePercent = newFeePercent;
    }

    function setMetadata(string memory _metadata) external override {
        require(owner() == msg.sender && !approved() || factory.hasRole(factory.MANAGE_OFFERING_ROLE(), msg.sender), 'You do not have permission to update this metadata');
        emit MetadataUpdated(metadata, _metadata, msg.sender);
        metadata = _metadata;
    }

    /**
     * @notice It sets parameters for pool
     * @param newPoolInfo: new pool information
     * @dev This function is only callable by admin.
     */
    function setPool(PoolInfo calldata newPoolInfo) external override onlyOwner notApproved {
        require(startsAt > block.timestamp, 'Promotion has already started.');

        PoolInfo memory prevPoolInfo = _poolInfo;
        _poolInfo = newPoolInfo;

        uint256 currentBalance = offeringToken.balanceOf(address(this));

        if (currentBalance < newPoolInfo.offeringAmount) {
            uint256 toDeposit = newPoolInfo.offeringAmount.sub(currentBalance);
            offeringToken.transferFrom(msg.sender, address(this), toDeposit);
        } else if (currentBalance > newPoolInfo.offeringAmount) {
            uint256 toWithdraw = currentBalance.sub(newPoolInfo.offeringAmount);
            offeringToken.transfer(msg.sender, toWithdraw);
        }

        _poolInfo.offeringAmount = offeringToken.balanceOf(address(this));

        emit PoolInfoUpdated(prevPoolInfo, newPoolInfo, msg.sender);
    }

    /**
    * @notice approves the offering, allowing people to participate and locks the offering from being updated
    */
    function approve() external override onlyRole(factory.MANAGE_OFFERING_ROLE()) notReverted{
        _approve();
    }

    /**
    * @notice unapproves an existing approved offering. Preventing anyone from participating and allowing changes to be made if not already started.
    */
    function unapprove() external override onlyRole(factory.MANAGE_OFFERING_ROLE()) notReverted {
        _unapprove();
    }

    /**
     * @notice It allows the admin to withdraw funds, or one of the
     * @dev This function is only callable by admin.
     */
    function claimRewards() external override {
        require(msg.sender == owner() || factory.hasRole(factory.CLAIM_ROLE(), msg.sender), 'You do not have the appropriate permissions.');
        require(block.timestamp > endsAt, 'Promotion has not ended yet.');
        require(!rewardsClaimed, "Rewards have already been claimed");

        rewardsClaimed = true;

        uint256 amount = address(this).balance;

        if (amount == 0) {
            return;
        }

        uint256 feeAmount = 0;
        uint256 rewardAmount = 0;
        uint256 refundAmount = 0;
        uint256 burnAmount = 0;

        if (_minRequirementsMet()) {
            uint256 diff = _poolInfo.maxRaisingAmount.sub(totalAmountRaised);
            burnAmount = diff.mul(_poolInfo.offeringAmount).div(_poolInfo.maxRaisingAmount);
            feeAmount = amount.mul(feePercent).div(BASE_PERCENTAGE);
            rewardAmount = amount.sub(feeAmount);
        } else {
            refundAmount = _poolInfo.offeringAmount;
        }

        if (refundAmount > 0) {
            offeringToken.transfer(owner(), refundAmount);
        }

        if (burnAmount > 0) {
            offeringToken.transfer(BURN_ADDRESS, burnAmount);
        }

        payable(owner()).transfer(rewardAmount);
        payable(factory.feeAddress()).transfer(feeAmount);

        emit RewardsClaimed(rewardAmount, feeAmount, refundAmount, burnAmount, owner(), factory.feeAddress(), msg.sender);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyRole(factory.MANAGE_OFFERING_ROLE()) {
        require(_tokenAddress != address(offeringToken), "Cannot be offering token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount, msg.sender);
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @return it returns the user's share of pool
     */
    function viewUserAllocation(address _user) public override view returns (uint256) {
        if (totalAmountRaised > 0) {
            return userInfo[_user].amountPool.mul(1e18).div(totalAmountRaised.mul(1e6));
        } else {
            return 0;
        }
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @param _startsAt: the new start block
     * @param _endsAt: the new end block
     * @dev This function is only callable by admin.
     */
    function updateStartAndEndTimes(uint256 _startsAt, uint256 _endsAt) external override onlyRole(factory.MANAGE_OFFERING_ROLE()) notApproved {
        require(block.timestamp < startsAt, "USO has started");
        require(_startsAt < _endsAt, "New startBlock must be lower than new endBlock");
        require(block.timestamp < _startsAt, "New startBlock must be higher than current block");

        uint256 prevStartsAt = startsAt;
        uint256 prevEndsAt = endsAt;

        startsAt = _startsAt;
        endsAt = _endsAt;

        emit NewStartAndEndBlocks(prevStartsAt, prevEndsAt, _startsAt, _endsAt, msg.sender);
    }

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param _user: user address
     */
    function viewUserOfferingAmount(address _user)
    external
    view
    override
    returns (uint256)
    {
        return _poolInfo.maxRaisingAmount > 0 ? _calculateOfferingAmount(_user) : 0;
    }

    /**
     * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
     * @param _user: user address
     * @return {uint256} It returns the offering amount, the refunding amount (in LP tokens),
     * and the tax (if any, else 0)
     */
    function _calculateOfferingAmount(address _user)
    internal
    view
    returns (uint256)
    {
        return userInfo[_user].amountPool.mul(_poolInfo.offeringAmount).div(_poolInfo.maxRaisingAmount);
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @dev helper method for checking whether the minimum requirements are met for completing an offering.
     * It will fail if it has been reverted, or th minimum raised, is not passed the min amount raising.
     */
    function _minRequirementsMet() internal view returns (bool) {
        return !reverted && totalAmountRaised >= _poolInfo.minRaisingAmount;
    }
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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface IOwnable {

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}


/**
* @dev This is a copy cat of the Ownable contract from openzeppelin,
* with the one difference being that it has an init function instead of a contructor.
*/
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
abstract contract Ownable is Context, Initializable, IOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function Ownable__init(address newOwner) internal initializer {
        _setOwner(newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override virtual returns (address) {
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

pragma solidity ^0.8.4;

import "../USO/IUSO.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IUSOFactory is IAccessControl {

    event USOCreated(address indexed usoAddress, address indexed sender);

    event USOTemplateUpdated(address prevTemplate, address newTemplate, bytes32 indexed prevVersion, bytes32 indexed newVersion, address indexed sender);

    event FeeAddressUpdated(address indexed prevFeeAddress, address indexed newFeeAddress, address indexed sender);

    function usoTemplate() external returns(IUSO);

    function feeAddress() external returns(address);

    function CLAIM_ROLE() external view returns (bytes32);

    function REVERT_ROLE() external view returns (bytes32);

    function MANAGE_OFFERING_ROLE() external view returns (bytes32);

    function FEE_ROLE() external view returns (bytes32);

    function CREATE_OFFERING_ROLE() external view returns (bytes32);

    function UPDATE_TEMPLATE_ROLE() external view returns (bytes32);

    function FEE_ADDRESS_ROLE() external view returns (bytes32);
    
    function setUSOTemplate(address _newTemplate) external;

    function setFeeAddress(address newFeeAddress) external;

    function checkRole(bytes32 role, address account) external view;

    function create(
        address token,
        uint32 feePercent,
        uint256 startsAt,
        uint256 endsAt,
        address tokenOwnerAddress
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../USOFactory/IUSOFactory.sol";
import "../util/Approvable.sol";
import "../util/Ownable.sol";

interface IUSO is IApprovable, IOwnable {

    struct PoolInfo {
        // amount of tokens offered for the pool (in offeringTokens)
        uint256 offeringAmount;
        // min amount of tokens raised for the pool
        uint256 minRaisingAmount;
        // max amount of tokens raised for the pool
        uint256 maxRaisingAmount;
        // limit of tokens per user (if 0, it is ignored)
        uint256 maxEntryAmount;
        // min requirement for entry
        uint256 minEntryAmount;
    }

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 amountPool; // How many tokens the user has provided for pool
        bool claimedPool; // Whether the user has claimed (default: false) for pool
    }

    // Admin withdraw events
    event RewardsClaimed(uint256 rewardAmount, uint256 feeAmount, uint256 refundAmount, uint256 burnAmount, address indexed rewardAddress, address indexed feeAddress, address indexed sender);

    // Pool Info is updated
    event PoolInfoUpdated(PoolInfo prevInfo, PoolInfo newInfo, address indexed sender);

    // Admin recovers token
    event AdminTokenRecovery(address indexed tokenAddress, uint256 amountTokens, address indexed sender);

    // Deposit event
    event Deposit(address indexed user, uint256 amount);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint256 refundingAmount);

    // Event for new start & end blocks
    event NewStartAndEndBlocks(uint256 prevStartsAt, uint256 prevEndsAt, uint256 newStartsAt, uint256 newEndsAt, address indexed sender);

    // Emits when a offering has been marked as reverted. Happens when it fails any safety checks
    event Reverted(string reason, address indexed sender);

    event MetadataUpdated(string prevMetadata, string newMetadata, address indexed sender);

    function VERSION() external returns (bytes32);

    function poolInfo() external view returns (PoolInfo memory);

    function started() external view returns (bool);

    function ended() external view returns (bool);

    function initialize(
        address _factory,
        address _offeringToken,
        uint32 _feePercent,
        uint256 _startAt,
        uint256 _endsAt,
        address _tokenOwnerAddress
    ) external;

    function rewardsClaimed() external view returns (bool);

    function reverted() external view returns (bool);

    function totalAmountRaised() external view returns (uint256);

    function feePercent() external view returns (uint32);

    function endsAt() external view returns (uint256);

    function startsAt() external view returns (uint256);

    function metadata() external view returns (string memory);

    function offeringToken() external view returns (IERC20);

    function factory() external view returns (IUSOFactory);

    function setMetadata(string memory newMetadata) external;

    /**
     * @notice It allows users to deposit LP tokens to pool
     */
    function deposit() external payable;

    /**
     * @notice It allows users to harvest from pool
     */
    function harvest() external;

    /**
     * @notice reverts a contract permanently. Preventing any further donations and allows everyone to safely
     * withdraw their investment
     * @dev is only callable with the correct permissions and can only be called once.
     */
    function revertOffering(string memory reason) external;

    /**
     * @notice It allows the admin to withdraw funds
     * @dev This function is only callable by admin.
     */
    function claimRewards() external;

    /**
     * @notice It sets parameters for pool
     * @param newPoolInfo: the new pool structure for this launch pad
     * @dev This function is only callable by admin.
     */
    function setPool(PoolInfo calldata newPoolInfo) external;

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     */
    function viewUserAllocation(address _user) external view returns (uint256);

    function updateStartAndEndTimes(uint256 _startsAt, uint256 _endsAt) external;

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param _user: user address
     */
    function viewUserOfferingAmount(address _user)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IApprovable {
    event Approved(address indexed sender);

    event Unapproved(address indexed sender);

    function approved() external view returns (bool);

    function approve() external;

    function unapprove() external;
}

abstract contract Approvable is IApprovable {

    bool internal _approved = false;

    /**
    * @dev require the contract to be approved
    */
    modifier onceApproved() {
        require(_approved, 'This contract has not been approved.');
        _;
    }

    /**
    * @dev requires the contract to not be approved
    */
    modifier notApproved() {
        require(!_approved, 'This is approved already.');
        _;
    }

    /**
    * @notice returns whether or not this contract has been approved
    */
    function approved() public override view returns (bool) {
        return _approved;
    }

    /**
    * @dev internal function for changing the status to approved
    */
    function _approve() internal {
        require(!_approved, 'Approvable: already approved');
        _approved = true;
        emit Approved(msg.sender);
    }

    /**
    * @dev internal function for changing the status to unapproved
    */
    function _unapprove() internal {
        require(_approved, 'Approvable: is not approved');
        _approved = false;
        emit Unapproved(msg.sender);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}