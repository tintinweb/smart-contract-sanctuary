// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "./mixins/NonTransferrableErc20.sol";
import "./mixins/Vesting.sol";
import "./mixins/Claiming.sol";
import "./mixins/MerkleDistributor.sol";
import "./vendored/mixins/StorageAccessible.sol";

/// @dev The token that manages how the CoW Protocol governance token is
/// distributed to all different types of investors.
/// @title CoW Protocol Virtual Token
/// @author CoW Protocol Developers
contract CowProtocolVirtualToken is
    NonTransferrableErc20,
    Vesting,
    Claiming,
    MerkleDistributor,
    StorageAccessible
{
    string private constant ERC20_SYMBOL = "TESTvCOW";
    string private constant ERC20_NAME = "*TEST* CoW Protocol Virtual Token";

    constructor(
        bytes32 merkleRoot,
        address cowToken,
        address payable communityFundsTarget,
        address investorFundsTarget,
        address usdcToken,
        uint256 usdcPrice,
        address gnoToken,
        uint256 gnoPrice,
        address wrappedNativeToken,
        uint256 nativeTokenPrice,
        address teamController
    )
        NonTransferrableErc20(ERC20_NAME, ERC20_SYMBOL)
        Claiming(
            cowToken,
            communityFundsTarget,
            investorFundsTarget,
            usdcToken,
            usdcPrice,
            gnoToken,
            gnoPrice,
            wrappedNativeToken,
            nativeTokenPrice,
            teamController
        )
        MerkleDistributor(merkleRoot)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /// @dev Returns the sum of tokens that are either held as
    /// instantlySwappableBalance or will be vested in the future
    /// @param user The user for whom the balance is calculated
    /// @return Balance of the user
    function balanceOf(address user) public view returns (uint256) {
        return
            instantlySwappableBalance[user] +
            fullAllocation[user] -
            vestedAllocation[user];
    }

    /// @dev Returns the balance of a user assuming all vested tokens would
    /// have been converted into virtual tokens
    /// @param user The user for whom the balance is calculated
    /// @return Balance the user would have after calling `swapAll`
    function swappableBalanceOf(address user) public view returns (uint256) {
        return instantlySwappableBalance[user] + newlyVestedBalance(user);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";

/// @dev A contract of an ERC20 token that cannot be transferred.
/// @title Non-Transferrable ERC20
/// @author CoW Protocol Developers
abstract contract NonTransferrableErc20 is IERC20 {
    /// @dev The ERC20 name of the token
    string public name;
    /// @dev The ERC20 symbol of the token
    string public symbol;
    /// @dev The ERC20 number of decimals of the token
    uint8 public constant decimals = 18; // solhint-disable const-name-snakecase

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// @dev This error is fired when trying to perform an action that is not
    /// supported by the contract, like transfers and approvals. These actions
    /// will never be supported.
    error NotSupported();

    /// @dev All types of transfers are permanently disabled.
    function transferFrom(
        address,
        address,
        uint256
    ) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of transfers are permanently disabled.
    function transfer(address, uint256) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of approvals are permanently disabled to reduce code
    /// size.
    function approve(address, uint256) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev Approvals cannot be set, so allowances are always zero.
    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/libraries/Math.sol";

import "../interfaces/VestingInterface.sol";

/// @dev The vesting logic for distributing the COW token
/// @title Vesting Logic
/// @author CoW Protocol Developers
contract Vesting is VestingInterface {
    /// @dev The timestamp of the official vesting start. This value is shared
    /// between all participants.
    uint256 public immutable vestingStart;
    /// @dev How long it will take for all vesting to be completed. It is set to
    /// four years.
    uint256 public constant VESTING_PERIOD_IN_SECONDS = 4 * 365 days + 1 days;

    /// @dev Stores the amount of vesting that the user has already vested.
    mapping(address => uint256) public vestedAllocation;
    /// @dev Stores the maximum amount of vesting available to each user. This
    /// is exactly the total amount of vesting that can be converted after the
    /// vesting period is completed.
    mapping(address => uint256) public fullAllocation;

    /// @dev Stores a bit indicating whether a vesting is cancelable
    /// Important: This implementaiton implies that there can not be a
    /// cancelable and non-cancelable vesting in parallel
    mapping(address => bool) public isCancelable;

    /// @dev Event emitted when a new vesting position is added. The amount is
    /// the additional amount that can be vested at the end of the
    /// claiming period.
    event VestingAdded(address indexed user, uint256 amount, bool isCancelable);
    /// @dev Event emitted when a vesting position is canceled. The amount is
    /// the number of remaining vesting that will be given to the beneficiary.
    event VestingStopped(
        address indexed user,
        address freedVestingBeneficiary,
        uint256 amount
    );
    /// @dev Event emitted when the users claims (also partially) a vesting
    /// position.
    event Vested(address indexed user, uint256 amount);

    /// @dev Error returned when trying to stop a claim that is not cancelable.
    error VestingNotCancelable();

    constructor() {
        vestingStart = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /// @inheritdoc VestingInterface
    function addVesting(
        address user,
        uint256 vestingAmount,
        bool isCancelableFlag
    ) internal override {
        if (isCancelableFlag) {
            // if one cancelable vesting is made, it converts all vestings into cancelable ones
            isCancelable[user] = isCancelableFlag;
        }
        fullAllocation[user] += vestingAmount;
        emit VestingAdded(user, vestingAmount, isCancelableFlag);
    }

    /// @inheritdoc VestingInterface
    function shiftVesting(address user, address freedVestingBeneficiary)
        internal
        override
        returns (uint256 accruedVesting)
    {
        if (!isCancelable[user]) {
            revert VestingNotCancelable();
        }
        accruedVesting = vest(user);
        uint256 userFullAllocation = fullAllocation[user];
        uint256 userVestedAllocation = vestedAllocation[user];
        fullAllocation[user] = 0;
        vestedAllocation[user] = 0;
        fullAllocation[freedVestingBeneficiary] += userFullAllocation;
        vestedAllocation[freedVestingBeneficiary] += userVestedAllocation;
        emit VestingStopped(
            user,
            freedVestingBeneficiary,
            userFullAllocation - userVestedAllocation
        );
    }

    /// @inheritdoc VestingInterface
    function vest(address user)
        internal
        override
        returns (uint256 newlyVested)
    {
        newlyVested = newlyVestedBalance(user);
        vestedAllocation[user] += newlyVested;
        emit Vested(user, newlyVested);
    }

    /// @dev Assuming no conversions has been done by the user, calculates how
    /// much vesting can be converted at this point in time.
    /// @param user The user for whom the result is being calculated.
    /// @return How much vesting can be converted if no conversions had been
    /// done before.
    function cumulativeVestedBalance(address user)
        public
        view
        returns (uint256)
    {
        return
            (Math.min(
                block.timestamp - vestingStart, // solhint-disable-line not-rely-on-time
                VESTING_PERIOD_IN_SECONDS
            ) * fullAllocation[user]) / (VESTING_PERIOD_IN_SECONDS);
    }

    /// @dev Calculates how much vesting can be converted at this point in time.
    /// Unlike `cumulativeVestedBalance`, this function keeps track of previous
    /// conversions.
    /// @param user The user for whom the result is being calculated.
    /// @return How much vesting can be converted.
    function newlyVestedBalance(address user) public view returns (uint256) {
        return cumulativeVestedBalance(user) - vestedAllocation[user];
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";
import "../vendored/libraries/SafeERC20.sol";

import "../interfaces/ClaimingInterface.sol";
import "../interfaces/VestingInterface.sol";

/// @dev The logic behind the claiming of virtual tokens and the swapping to
/// real tokens.
/// @title COW Virtual Token Claiming Logic
/// @author CoW Protocol Developers
abstract contract Claiming is ClaimingInterface, VestingInterface, IERC20 {
    using SafeERC20 for IERC20;

    /// @dev Prices are represented as fractions. For readability, the
    /// denominator is one unit of the virtual token (assuming it has 18
    /// decimals), in this way the numerator of a price is the number of atoms
    /// that have the same value as a unit of virtual token.
    uint256 internal constant PRICE_DENOMINATOR = 10**18;
    /// @dev Price numerator for the COW/USDC price. This is the number of USDC
    /// atoms required to obtain a full unit of virtual token from an option.
    uint256 public immutable usdcPrice;
    /// @dev Price numerator for the COW/GNO price. This is the number of GNO
    /// atoms required to obtain a full unit of virtual token from an option.
    uint256 public immutable gnoPrice;
    /// @dev Price numerator for the COW/native-token price. This is the number
    /// of native token wei required to obtain a full unit of virtual token from
    /// an option.
    uint256 public immutable nativeTokenPrice;

    /// @dev The proceeds from selling options to the community will be sent to,
    /// this address.
    address payable public immutable communityFundsTarget;
    /// @dev All proceeds from known investors will be sent to this address.
    address public immutable investorFundsTarget;

    /// @dev Address of the real COW token. Tokens claimed by this contract can
    /// be converted to this token if this contract stores some balance of it.
    IERC20 public immutable cowToken;
    /// @dev Address of the USDC token. It is a form of payment for investors.
    IERC20 public immutable usdcToken;
    /// @dev Address of the GNO token. It is a form of payment for users who
    /// claim the options derived from holding GNO.
    IERC20 public immutable gnoToken;
    /// @dev Address of the wrapped native token. It is a form of payment for
    /// users who claim the options derived from being users of the CoW
    /// Protocol.
    IERC20 public immutable wrappedNativeToken;

    /// @dev Address representing the CoW Protocol/CowSwap team. It is the only
    /// address that is allowed to stop the vesting of a claim, and exclusively
    /// for team claims.
    address public immutable teamController;

    /// @dev Time at which this contract was deployed.
    uint256 public immutable deploymentTimestamp;

    /// @dev Returns the amount of virtual tokens in existence, including those
    /// that have yet to be vested.
    uint256 public totalSupply;

    /// @dev How many tokens can be immediately swapped in exchange for real
    /// tokens for each user.
    mapping(address => uint256) public instantlySwappableBalance;

    /// @dev Error presented to a user trying to claim virtual tokens after the
    /// claiming period has ended.
    error ClaimingExpired();
    /// @dev Error presented to anyone but the team controller to stop a
    /// cancelable vesting position (i.e., only team vesting).
    error OnlyTeamController();
    /// @dev Error resulting from sending an incorrect amount of native to the
    /// contract.
    error InvalidNativeTokenAmount();
    /// @dev Error caused by an unsuccessful attempt to transfer native tokens.
    error FailedNativeTokenTransfer();
    /// @dev Error resulting from sending native tokens for a claim that cannot
    /// be redeemed with native tokens.
    error CannotSendNativeToken();

    constructor(
        address _cowToken,
        address payable _communityFundsTarget,
        address _investorFundsTarget,
        address _usdcToken,
        uint256 _usdcPrice,
        address _gnoToken,
        uint256 _gnoPrice,
        address _wrappedNativeToken,
        uint256 _nativeTokenPrice,
        address _teamController
    ) {
        cowToken = IERC20(_cowToken);
        communityFundsTarget = _communityFundsTarget;
        investorFundsTarget = _investorFundsTarget;
        usdcToken = IERC20(_usdcToken);
        usdcPrice = _usdcPrice;
        gnoToken = IERC20(_gnoToken);
        gnoPrice = _gnoPrice;
        wrappedNativeToken = IERC20(_wrappedNativeToken);
        nativeTokenPrice = _nativeTokenPrice;
        teamController = _teamController;

        // solhint-disable-next-line not-rely-on-time
        deploymentTimestamp = block.timestamp;
    }

    /// @dev Allows the decorated function only to be executed before the
    /// contract deployment date plus the input amount of seconds.
    /// @param durationSinceDeployment Number of seconds after contract
    /// deployment before which the function can be executed anymore. The
    /// function reverts afterwards.
    modifier before(uint256 durationSinceDeployment) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > deploymentTimestamp + durationSinceDeployment) {
            revert ClaimingExpired();
        }
        _;
    }

    /// @dev The decorated function can only be executed by the team controller.
    modifier onlyTeamController() {
        if (msg.sender != teamController) {
            revert OnlyTeamController();
        }
        _;
    }

    /// @inheritdoc ClaimingInterface
    function performClaim(
        ClaimType claimType,
        address payer,
        address claimant,
        uint256 amount,
        uint256 sentNativeTokens
    ) internal override {
        if (claimType == ClaimType.Airdrop) {
            claimAirdrop(claimant, amount, sentNativeTokens);
        } else if (claimType == ClaimType.GnoOption) {
            claimGnoOption(claimant, amount, payer, sentNativeTokens);
        } else if (claimType == ClaimType.UserOption) {
            claimUserOption(claimant, amount, payer, sentNativeTokens);
        } else if (claimType == ClaimType.Investor) {
            claimInvestor(claimant, amount, payer, sentNativeTokens);
        } else if (claimType == ClaimType.Team) {
            claimTeam(claimant, amount, sentNativeTokens);
        } else {
            // claimType == ClaimType.Advisor
            claimAdvisor(claimant, amount, sentNativeTokens);
        }

        // Each claiming operation results in the creation of `amount` virtual
        // tokens.
        totalSupply += amount;
        emit Transfer(address(0), claimant, amount);
    }

    /// @dev Stops all vesting claims of a user. This is only applicable for
    /// claims that are cancellable, i.e., team claims.
    /// @param user The user whose vesting claims should be canceled.
    function stopClaim(address user) external onlyTeamController {
        uint256 accruedVesting = shiftVesting(user, teamController);
        instantlySwappableBalance[user] += accruedVesting;
    }

    /// @dev Transfers all ETH stored in the contract to the community funds
    // target.
    function withdrawEth() external {
        // We transfer ETH using .call instead of .transfer as not to restrict
        // the amount of gas sent to the target address during the transfer.
        // This is particularly relevant for sending ETH to smart contracts:
        // since EIP 2929, if a contract sends eth using `.transfer` then the
        // transaction proposed to the node needs to specify an _access list_,
        // which is currently not well supported by some wallet implementations.
        // There is no reentrancy risk as this call does not touch any storage
        // slot and the contract balance is not used in other logic.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = communityFundsTarget.call{
            value: address(this).balance
        }("");
        if (!success) {
            revert FailedNativeTokenTransfer();
        }
    }

    /// @dev Performs an airdrop-type claim for the user.
    /// @param account The user for which the claim is performed.
    /// @param amount The full amount claimed by the user.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function claimAirdrop(
        address account,
        uint256 amount,
        uint256 sentNativeTokens
    ) private before(6 weeks) {
        if (sentNativeTokens != 0) {
            revert CannotSendNativeToken();
        }
        instantlySwappableBalance[account] += amount;
    }

    /// @dev Claims a Gno option for the user.
    /// @param account The user for which the claim is performed.
    /// @param amount The full amount claimed by the user after vesting.
    /// @param payer The address that pays the amount required by the claim.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function claimGnoOption(
        address account,
        uint256 amount,
        address payer,
        uint256 sentNativeTokens
    ) private before(2 weeks) {
        if (sentNativeTokens != 0) {
            revert CannotSendNativeToken();
        }
        collectPayment(gnoToken, gnoPrice, payer, communityFundsTarget, amount);
        addVesting(account, amount, false);
    }

    /// @dev Claims a native-token-based option for the user.
    /// @param account The user for which the claim is performed.
    /// @param amount The full amount claimed by the user after vesting.
    /// @param payer The address that pays the amount required by the claim.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function claimUserOption(
        address account,
        uint256 amount,
        address payer,
        uint256 sentNativeTokens
    ) private before(2 weeks) {
        if (sentNativeTokens != 0) {
            collectNativeTokenPayment(amount, sentNativeTokens);
        } else {
            collectPayment(
                wrappedNativeToken,
                nativeTokenPrice,
                payer,
                communityFundsTarget,
                amount
            );
        }
        addVesting(account, amount, false);
    }

    /// @dev Claims an investor option.
    /// @param account The user for which the claim is performed.
    /// @param amount The full amount claimed by the user after vesting.
    /// @param payer The address that pays the amount required by the claim.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function claimInvestor(
        address account,
        uint256 amount,
        address payer,
        uint256 sentNativeTokens
    ) private before(2 weeks) {
        if (sentNativeTokens != 0) {
            revert CannotSendNativeToken();
        }
        collectPayment(
            usdcToken,
            usdcPrice,
            payer,
            investorFundsTarget,
            amount
        );
        addVesting(account, amount, false);
    }

    /// @dev Claims a team option. Team options are granted without any payment
    /// but can be canceled.
    /// @param account The user for which the claim is performed.
    /// @param amount The full amount claimed by the user after vesting.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function claimTeam(
        address account,
        uint256 amount,
        uint256 sentNativeTokens
    ) private before(6 weeks) {
        if (sentNativeTokens != 0) {
            revert CannotSendNativeToken();
        }
        addVesting(account, amount, true);
    }

    /// @dev Claims an adviser option. Team options are granted without any
    /// payment and cannot be canceled.
    /// @param account The user for which the claim is performed.
    /// @param amount The full amount claimed by the user after vesting.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function claimAdvisor(
        address account,
        uint256 amount,
        uint256 sentNativeTokens
    ) private before(6 weeks) {
        if (sentNativeTokens != 0) {
            revert CannotSendNativeToken();
        }
        addVesting(account, amount, false);
    }

    /// @dev Executes a transfer from the user to the target. The transfered
    /// amount is based on the input COW price and amount of COW bought.
    /// @param token The token used for the payment.
    /// @param price The number of atoms of the input token that are equivalent
    /// to one atom of COW multiplied by PRICE_DENOMINATOR.
    /// @param from The address from which to take the funds.
    /// @param to The address to which to send the funds.
    /// @param amount The amount of COW atoms that will be paid for.
    function collectPayment(
        IERC20 token,
        uint256 price,
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 tokenEquivalent = convertCowAmountAtPrice(amount, price);
        token.safeTransferFrom(from, to, tokenEquivalent);
    }

    /// @dev Transfers native tokens from this contract to the target, assuming
    /// that the amount of native tokens sent coincides with the expected amount
    /// of native tokens. This amount is based on the price of the native token
    /// and amount of COW bought.
    /// @param amount The amount of COW atoms that will be paid for.
    /// @param sentNativeTokens Amount of ETH sent along to the transaction.
    function collectNativeTokenPayment(uint256 amount, uint256 sentNativeTokens)
        private
        view
    {
        uint256 nativeTokenEquivalent = convertCowAmountAtPrice(
            amount,
            nativeTokenPrice
        );
        if (sentNativeTokens != nativeTokenEquivalent) {
            revert InvalidNativeTokenAmount();
        }
    }

    /// @dev Converts input amount in COW token atoms to an amount in token
    /// atoms at the specified price.
    /// @param amount Amount of tokens to convert.
    /// @param price The number of atoms of the input token that are equivalent
    /// to one atom of COW *multiplied by PRICE_DENOMINATOR*.
    function convertCowAmountAtPrice(uint256 amount, uint256 price)
        private
        pure
        returns (uint256)
    {
        return (amount * price) / PRICE_DENOMINATOR;
    }

    /// @dev Converts an amount of (virtual) tokens from this contract to real
    /// tokens based on the claims previously performed by the caller.
    /// @param amount How many virtual tokens to convert into real tokens.
    function swap(uint256 amount) external {
        makeVestingSwappable();
        _swap(amount);
    }

    /// @dev Converts all available (virtual) tokens from this contract to real
    /// tokens based on the claims previously performed by the caller.
    /// @return swappedBalance The full amount that was swapped (i.e., virtual
    /// tokens burnt as well as real tokens received).
    function swapAll() external returns (uint256 swappedBalance) {
        swappedBalance = makeVestingSwappable();
        _swap(swappedBalance);
    }

    /// @dev Transfers real tokens to the message sender and reduces the balance
    /// of virtual tokens available. Note that this function assumes that the
    /// current contract stores enough real tokens to fulfill this swap request.
    /// @param amount How many virtual tokens to convert into real tokens.
    function _swap(uint256 amount) private {
        instantlySwappableBalance[msg.sender] -= amount;
        totalSupply -= amount;
        cowToken.safeTransfer(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /// @dev Adds the currently vested amount to the immediately swappable
    /// balance.
    /// @return swappableBalance The maximum balance that can be swapped at
    /// this point in time by the caller.
    function makeVestingSwappable() private returns (uint256 swappableBalance) {
        swappableBalance =
            instantlySwappableBalance[msg.sender] +
            vest(msg.sender);
        instantlySwappableBalance[msg.sender] = swappableBalance;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

// This contract is based on Uniswap's MekleDistributor, which can be found at:
// https://github.com/Uniswap/merkle-distributor/blob/0d478d722da2e5d95b7292fd8cbdb363d98e9a93/contracts/MerkleDistributor.sol
//
// The changes between the original contract and this are:
//  - the claim function doesn't trigger a transfer on a successful proof, but
//    it executes a dedicated (virtual) function.
//  - added a claimMany function for bundling multiple claims in a transaction
//  - supported sending an amount of native tokens along with the claim
//  - added the option of claiming less than the maximum amount
//  - gas optimizations in the packing and unpacking of the claimed bit
//  - bumped Solidity version
//  - code formatting

pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";
import "../vendored/libraries/MerkleProof.sol";

import "../interfaces/ClaimingInterface.sol";

abstract contract MerkleDistributor is ClaimingInterface {
    bytes32 public immutable merkleRoot;

    /// @dev Event fired if a claim was successfully performed.
    event Claimed(
        uint256 index,
        ClaimType claimType,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount
    );

    /// @dev Error caused by a user trying to call the claim function for a
    /// claim that has already been used before.
    error AlreadyClaimed();
    /// @dev Error caused by a user trying to claim a larger amount than the
    /// maximum allowed in the claim.
    error ClaimingMoreThanMaximum();
    /// @dev Error caused by the caller trying to perform a partial claim while
    /// not being the owner of the claim.
    error OnlyOwnerCanClaimPartially();
    /// @dev Error caused by calling the claim function with an invalid proof.
    error InvalidProof();
    /// @dev Error caused by calling claimMany with a transaction value that is
    /// different from the required one.
    error InvalidNativeTokenValue();

    /// @dev Packed array of booleans that stores if a claim is available.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
    }

    /// @dev Checks if the claim at the provided index has already been claimed.
    /// @param index The index to check.
    /// @return Whether the claim at the given index has already been claimed.
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask != 0;
    }

    /// @dev Mark the provided index as having been claimed.
    /// @param index The index that was claimed.
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @dev This function verifies the provided input proof based on the
    /// provided input. If the proof is valid, the function [`performClaim`] is
    /// called for the claimed amount.
    /// @param index The index that identifies the input claim.
    /// @param claimType See [`performClaim`].
    /// @param claimant See [`performClaim`].
    /// @param claimableAmount The maximum amount that the claimant can claim
    /// for this claim. Should not be smaller than claimedAmount.
    /// @param claimedAmount See [`performClaim`].
    /// @param merkleProof A proof that the input claim belongs to the unique
    /// Merkle root associated to this contract.
    function claim(
        uint256 index,
        ClaimType claimType,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount,
        bytes32[] calldata merkleProof
    ) external payable {
        _claim(
            index,
            claimType,
            claimant,
            claimableAmount,
            claimedAmount,
            merkleProof,
            msg.value
        );
    }

    /// @dev This function verifies and executes multiple claims in the same
    /// transaction.
    /// @param indices A vector of indices. See [`claim`] for details.
    /// @param claimTypes A vector of claim types. See [`performClaim`] for
    /// details.
    /// @param claimants A vector of claimants. See [`performClaim`] for
    /// details.
    /// @param claimableAmounts A vector of claimable amounts. See [`claim`] for
    /// details.
    /// @param claimedAmounts A vector of claimed amounts. See [`performClaim`]
    /// for details.
    /// @param merkleProofs A vector of merkle proofs. See [`claim`] for
    /// details.
    /// @param sentNativeTokens A vector of native token amounts. See
    /// [`performClaim`] for details.
    function claimMany(
        uint256[] memory indices,
        ClaimType[] memory claimTypes,
        address[] calldata claimants,
        uint256[] calldata claimableAmounts,
        uint256[] calldata claimedAmounts,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata sentNativeTokens
    ) external payable {
        uint256 sumSentNativeTokens;
        for (uint256 i = 0; i < indices.length; i++) {
            sumSentNativeTokens += sentNativeTokens[i];
            _claim(
                indices[i],
                claimTypes[i],
                claimants[i],
                claimableAmounts[i],
                claimedAmounts[i],
                merkleProofs[i],
                sentNativeTokens[i]
            );
        }
        if (sumSentNativeTokens != msg.value) {
            revert InvalidNativeTokenValue();
        }
    }

    /// @dev This function verifies the provided input proof based on the
    /// provided input. If the proof is valid, the function [`performClaim`] is
    /// called for the claimed amount.
    /// @param index See [`claim`].
    /// @param claimType See [`performClaim`].
    /// @param claimant See [`performClaim`].
    /// @param claimableAmount See [`claim`].
    /// @param claimedAmount See [`performClaim`].
    /// @param merkleProof See [`claim`].
    /// @param sentNativeTokens See [`performClaim`].
    function _claim(
        uint256 index,
        ClaimType claimType,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount,
        bytes32[] calldata merkleProof,
        uint256 sentNativeTokens
    ) private {
        if (isClaimed(index)) {
            revert AlreadyClaimed();
        }
        if (claimedAmount > claimableAmount) {
            revert ClaimingMoreThanMaximum();
        }
        if ((claimedAmount < claimableAmount) && (msg.sender != claimant)) {
            revert OnlyOwnerCanClaimPartially();
        }

        // Note: all types used inside `encodePacked` should have fixed length,
        // otherwise the same proof could be used in different claims.
        bytes32 node = keccak256(
            abi.encodePacked(index, claimType, claimant, claimableAmount)
        );
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        _setClaimed(index);

        performClaim(
            claimType,
            msg.sender,
            claimant,
            claimedAmount,
            sentNativeTokens
        );

        emit Claimed(
            index,
            claimType,
            claimant,
            claimableAmount,
            claimedAmount
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

// Vendored from Gnosis utility contracts, see:
// <https://raw.githubusercontent.com/gnosis/gp-v2-contracts/40c349d52d14f8f3c9f787fe2fca5a496bb10ea9/src/contracts/mixins/StorageAccessible.sol>
// The following changes were made:
// - Modified Solidity version
// - Formatted code

pragma solidity ^0.8.10;

/// @title ViewStorageAccessible - Interface on top of StorageAccessible base class to allow simulations from view functions
interface ViewStorageAccessible {
    /**
     * @dev Same as `simulateDelegatecall` on StorageAccessible. Marked as view so that it can be called from external contracts
     * that want to run simulations from within view functions. Will revert if the invoked simulation attempts to change state.
     */
    function simulateDelegatecall(
        address targetContract,
        bytes memory calldataPayload
    ) external view returns (bytes memory);

    /**
     * @dev Same as `getStorageAt` on StorageAccessible. This method allows reading aribtrary ranges of storage.
     */
    function getStorageAt(uint256 offset, uint256 length)
        external
        view
        returns (bytes memory);
}

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length)
        external
        view
        returns (bytes memory)
    {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Catches revert and returns encoded result as bytes.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateDelegatecall(
        address targetContract,
        bytes memory calldataPayload
    ) public returns (bytes memory response) {
        bytes memory innerCall = abi.encodeWithSelector(
            this.simulateDelegatecallInternal.selector,
            targetContract,
            calldataPayload
        );
        // solhint-disable-next-line avoid-low-level-calls
        (, response) = address(this).call(innerCall);
        bool innerSuccess = response[response.length - 1] == 0x01;
        setLength(response, response.length - 1);
        if (innerSuccess) {
            return response;
        } else {
            revertWith(response);
        }
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Returns encoded result as revert message
     * concatenated with the success flag of the inner call as a last byte.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateDelegatecallInternal(
        address targetContract,
        bytes memory calldataPayload
    ) external returns (bytes memory response) {
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, response) = targetContract.delegatecall(calldataPayload);
        revertWith(abi.encodePacked(response, success));
    }

    function revertWith(bytes memory response) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            revert(add(response, 0x20), mload(response))
        }
    }

    function setLength(bytes memory buffer, uint256 length) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(buffer, length)
        }
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/token/ERC20/IERC20.sol>

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/utils/math/Math.sol>

// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

/// @dev The contract functions that are shared between the `Vesting` and
/// `Claiming` contracts. The two components are handled and tested
/// separately and are linked to each other by the functions in this contract.
/// This contracs is for all intents and purposes an interface, however actual
/// interfaces cannot declare internal functions.
/// @title COW token vesting interface.
/// @author CoW Protocol Developers
abstract contract VestingInterface {
    /// @dev Adds an amount that will be vested over time.
    /// Should be called from the parent contract on redeeming a vested claim.
    /// @param user The user for whom the vesting is performed.
    /// @param vestingAmount The (added) amount to be vested in time.
    /// @param isCancelableFlag Flag whether the vesting is cancelable
    function addVesting(
        address user,
        uint256 vestingAmount,
        bool isCancelableFlag
    ) internal virtual;

    /// @dev Computes the current vesting from the total vested amount and marks
    /// that amount as converted. This is called by the parent contract every
    /// time virtual tokens from a vested claim are swapped into real tokens.
    /// @param user The user for which the amount is vested.
    /// @return Amount converted.
    function vest(address user) internal virtual returns (uint256);

    /// @dev Transfers a cancelable vesting of a user to another address.
    /// Returns the amount of token that is not yet converted.
    /// @param user The user for whom the vesting is removed.
    /// @param freedVestingBeneficiary The address to which to assign the amount
    /// that remains to be vested.
    /// @return accruedVesting The total number of tokens that remain to be
    /// converted
    function shiftVesting(address user, address freedVestingBeneficiary)
        internal
        virtual
        returns (uint256 accruedVesting);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

// Vendored from GPv2 contracts v1.1.2, see:
// <https://raw.githubusercontent.com/gnosis/gp-v2-contracts/7fb88982021e9a274d631ffb598694e6d9b30089/src/contracts/libraries/GPv2SafeERC20.sol>
// The following changes were made:
// - Bumped up Solidity version and checked that the assembly is still valid.
// - Use own vendored IERC20 instead of custom implementation.
// - Removed "GPv2" from contract name.
// - Modified revert messages, including length.

pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "SafeERC20: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "SafeERC20: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token)
        private
        view
        returns (bool success)
    {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.8.10/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.8.10/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(25, "SafeERC20: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(30, "SafeERC20: bad transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

/// @dev The contract functions that are shared between the `Claiming` and
/// `MerkleDistributor` contracts. The two components are handled and tested
/// separately and are linked to each other by the functions in this contract.
/// This contracs is for all intents and purposes an interface, however actual
/// interfaces cannot declare internal functions.
/// @title COW token claiming interface.
/// @author CoW Protocol Developers
abstract contract ClaimingInterface {
    /// @dev Exhaustive list of the different branches of the claiming logic.
    enum ClaimType {
        Airdrop,
        GnoOption,
        UserOption,
        Investor,
        Team,
        Advisor
    }

    /// @dev This function is executed when a valid proof of the claim is
    /// provided and executes all steps required for each claim type.
    /// @param claimType Which claim will be performed. See [`ClaimType`] for
    /// an exausting list.
    /// @param payer The address that will pay if the claim to be performed
    /// requires a payment.
    /// @param claimant The account to which the claim is assigned and which
    /// will receive the corresponding virtual tokens.
    /// @param claimedAmount The amount that the user decided to claim (after
    /// vesting if it applies).
    /// @param sentNativeTokens The amount of native tokens that the user sent
    /// along with the transaction.
    function performClaim(
        ClaimType claimType,
        address payer,
        address claimant,
        uint256 claimedAmount,
        uint256 sentNativeTokens
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/utils/cryptography/MerkleProof.sol>

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }
}