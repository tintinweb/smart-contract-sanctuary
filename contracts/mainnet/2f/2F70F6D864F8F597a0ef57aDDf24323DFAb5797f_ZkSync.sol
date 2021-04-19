pragma solidity ^0.5.0;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeMathUInt128.sol";
import "./SafeCast.sol";
import "./Utils.sol";

import "./Storage.sol";
import "./Config.sol";
import "./Events.sol";

import "./Bytes.sol";
import "./Operations.sol";

import "./UpgradeableMaster.sol";
import "./uniswap/UniswapV2Factory.sol";

import "./PairTokenManager.sol";

/// @title zkSync main contract
/// @author Matter Labs
contract ZkSync is PairTokenManager, UpgradeableMaster, Storage, Config, Events, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;

    bytes32 public constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    //create pair
    function createPair(address _tokenA, address _tokenB) external {
        requireActive();
        governance.requireGovernor(msg.sender);
        //check _tokenA is registered or not
        uint16 tokenAID = governance.validateTokenAddress(_tokenA);

        //check _tokenB is registered or not
        uint16 tokenBID = governance.validateTokenAddress(_tokenB);

        //create pair
        address pair = pairmanager.createPair(_tokenA, _tokenB);
        require(pair != address(0), "pair is invalid");

	addPairToken(pair);

        registerCreatePair(
        tokenAID, tokenBID,
		validatePairTokenAddress(pair),
        pair);
    }

    //create pair including ETH
    function createETHPair(address _tokenERC20) external {
        requireActive();
        governance.requireGovernor(msg.sender);
        //check _tokenERC20 is registered or not
        uint16 erc20ID = governance.validateTokenAddress(_tokenERC20);

        //create pair
        address pair = pairmanager.createPair(address(0), _tokenERC20);
        require(pair != address(0), "pair is invalid");

	addPairToken(pair);

        registerCreatePair(
            0,
            erc20ID,
            validatePairTokenAddress(pair),
            pair);
    }

    function registerCreatePair(uint16 _tokenA, uint16 _tokenB, uint16 _tokenPair, address _pair) internal {
        // Priority Queue request
        Operations.CreatePair memory op = Operations.CreatePair({
            accountId: 0,  //unknown at this point
            tokenA: _tokenA,
            tokenB: _tokenB,
            tokenPair: _tokenPair,
            pair: _pair
            });
        bytes memory pubData = Operations.writeCreatePairPubdata(op);
        addPriorityRequest(Operations.OpType.CreatePair, pubData);

        emit OnchainCreatePair(_tokenA, _tokenB, _tokenPair, _pair);
    }

    // Upgrade functional

    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external returns (uint) {
        return UPGRADE_NOTICE_PERIOD;
    }

    /// @notice Notification that upgrade notice period started
    function upgradeNoticePeriodStarted() external {

    }

    /// @notice Notification that upgrade preparation status is activated
    function upgradePreparationStarted() external {
        upgradePreparationActive = true;
        upgradePreparationActivationTime = now;
    }

    /// @notice Notification that upgrade canceled
    function upgradeCanceled() external {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
    }

    /// @notice Notification that upgrade finishes
    function upgradeFinishes() external {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
    }

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external returns (bool) {
        return !exodusMode;
    }

    /// @notice Franklin contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    /// _governanceAddress The address of Governance contract
    /// _verifierAddress The address of Verifier contract
    /// _ // FIXME: remove _genesisAccAddress
    /// _genesisRoot Genesis blocks (first block) root
    function initialize(bytes calldata initializationParameters) external {
        initializeReentrancyGuard();

        (
        address _governanceAddress,
        address _verifierAddress,
        address _verifierExitAddress,
	    address _pairManagerAddress
        ) = abi.decode(initializationParameters, (address, address, address, address));

        verifier = Verifier(_verifierAddress);
        verifierExit = VerifierExit(_verifierExitAddress);
        governance = Governance(_governanceAddress);
        pairmanager = UniswapV2Factory(_pairManagerAddress);
    }

    function setGenesisRootAndAddresses(bytes32 _genesisRoot, address _zkSyncCommitBlockAddress, address _zkSyncExitAddress) external {
        // This function cannot be called twice as long as
        // _zkSyncCommitBlockAddress and _zkSyncExitAddress have been set to
        // non-zero.
        require(zkSyncCommitBlockAddress == address(0), "sraa1");
        require(zkSyncExitAddress == address(0), "sraa2");
        blocks[0].stateRoot = _genesisRoot;
        zkSyncCommitBlockAddress = _zkSyncCommitBlockAddress;
        zkSyncExitAddress = _zkSyncExitAddress;
    }

    /// @notice zkSync contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Sends tokens
    /// @dev NOTE: will revert if transfer call fails or rollup balance difference (before and after transfer) is bigger than _maxAmount
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @param _maxAmount Maximum possible amount of tokens to transfer to this account
    function withdrawERC20Guarded(IERC20 _token, address _to, uint128 _amount, uint128 _maxAmount) external returns (uint128 withdrawnAmount) {
        require(msg.sender == address(this), "wtg10"); // wtg10 - can be called only from this contract as one "external" call (to revert all this function state changes if it is needed)

        uint16 lpTokenId = tokenIds[address(_token)];
        uint256 balance_before = _token.balanceOf(address(this));
        if (lpTokenId > 0) {
            validatePairTokenAddress(address(_token));
            pairmanager.mint(address(_token), _to, _amount);
        } else {
            require(Utils.sendERC20(_token, _to, _amount), "wtg11"); // wtg11 - ERC20 transfer fails
        }
        uint256 balance_after = _token.balanceOf(address(this));
        uint256 balance_diff = balance_before.sub(balance_after);
        require(balance_diff <= _maxAmount, "wtg12"); // wtg12 - rollup balance difference (before and after transfer) is bigger than _maxAmount

        return SafeCast.toUint128(balance_diff);
    }

    /// @notice executes pending withdrawals
    /// @param _n The number of withdrawals to complete starting from oldest
    function completeWithdrawals(uint32 _n) external nonReentrant {
        // TODO: when switched to multi validators model we need to add incentive mechanism to call complete.
        uint32 toProcess = Utils.minU32(_n, numberOfPendingWithdrawals);
        uint32 startIndex = firstPendingWithdrawalIndex;
        numberOfPendingWithdrawals -= toProcess;
        firstPendingWithdrawalIndex += toProcess;

        for (uint32 i = startIndex; i < startIndex + toProcess; ++i) {
            uint16 tokenId = pendingWithdrawals[i].tokenId;
            address to = pendingWithdrawals[i].to;
            // send fails are ignored hence there is always a direct way to withdraw.
            delete pendingWithdrawals[i];

            bytes22 packedBalanceKey = packAddressAndTokenId(to, tokenId);
            uint128 amount = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
            // amount is zero means funds has been withdrawn with withdrawETH or withdrawERC20
            if (amount != 0) {
                balancesToWithdraw[packedBalanceKey].balanceToWithdraw -= amount;
                bool sent = false;
                if (tokenId == 0) {
                    address payable toPayable = address(uint160(to));
                    sent = Utils.sendETHNoRevert(toPayable, amount);
                } else {
                    address tokenAddr = address(0);
                    if (tokenId < PAIR_TOKEN_START_ID) {
                        // It is normal ERC20
                        tokenAddr = governance.tokenAddresses(tokenId);
                    } else {
                        // It is pair token
                        tokenAddr = tokenAddresses[tokenId];
                    }
                    // tokenAddr cannot be 0
                    require(tokenAddr != address(0), "cwt0");
                    // we can just check that call not reverts because it wants to withdraw all amount
                    (sent, ) = address(this).call.gas(ERC20_WITHDRAWAL_GAS_LIMIT)(
                        abi.encodeWithSignature("withdrawERC20Guarded(address,address,uint128,uint128)", tokenAddr, to, amount, amount)
                    );
                }
                if (!sent) {
                    balancesToWithdraw[packedBalanceKey].balanceToWithdraw += amount;
                }
            }
        }
        if (toProcess > 0) {
            emit PendingWithdrawalsComplete(startIndex, startIndex + toProcess);
        }
    }

    /// @notice Accrues users balances from deposit priority requests in Exodus mode
    /// @dev WARNING: Only for Exodus mode
    /// @dev Canceling may take several separate transactions to be completed
    /// @param _n number of requests to process
    function cancelOutstandingDepositsForExodusMode(uint64 _n) external nonReentrant {
        require(exodusMode, "coe01"); // exodus mode not active
        uint64 toProcess = Utils.minU64(totalOpenPriorityRequests, _n);
        require(toProcess > 0, "coe02"); // no deposits to process
        for (uint64 id = firstPriorityRequestId; id < firstPriorityRequestId + toProcess; id++) {
            if (priorityRequests[id].opType == Operations.OpType.Deposit) {
                Operations.Deposit memory op = Operations.readDepositPubdata(priorityRequests[id].pubData);
                bytes22 packedBalanceKey = packAddressAndTokenId(op.owner, op.tokenId);
                balancesToWithdraw[packedBalanceKey].balanceToWithdraw += op.amount;
            }
            delete priorityRequests[id];
        }
        firstPriorityRequestId += toProcess;
        totalOpenPriorityRequests -= toProcess;
    }

    /// @notice Deposit ETH to Layer 2 - transfer ether from user into contract, validate it, register deposit
    /// @param _franklinAddr The receiver Layer 2 address
    function depositETH(address _franklinAddr) external payable nonReentrant {
        requireActive();
        registerDeposit(0, SafeCast.toUint128(msg.value), _franklinAddr);
    }

    /// @notice Withdraw ETH to Layer 1 - register withdrawal and transfer ether to sender
    /// @param _amount Ether amount to withdraw
    function withdrawETH(uint128 _amount) external nonReentrant {
        registerWithdrawal(0, _amount, msg.sender);
        (bool success, ) = msg.sender.call.value(_amount)("");
        require(success, "fwe11"); // ETH withdraw failed
    }

    /// @notice Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _franklinAddr Receiver Layer 2 address
    function depositERC20(IERC20 _token, uint104 _amount, address _franklinAddr) external nonReentrant {
        requireActive();

        // Get token id by its address
        uint16 lpTokenId = tokenIds[address(_token)];
        uint16 tokenId = 0;
        if (lpTokenId == 0) {
            // This means it is not a pair address
            tokenId = governance.validateTokenAddress(address(_token));
        } else {
            lpTokenId = validatePairTokenAddress(address(_token));
        }

        uint256 balance_before = 0;
        uint256 balance_after = 0;
        uint128 deposit_amount = 0;
        if (lpTokenId > 0) {
            // Note: For lp token, main contract always has no money
            balance_before = _token.balanceOf(msg.sender);
            pairmanager.burn(address(_token), msg.sender, SafeCast.toUint128(_amount)); //
            balance_after = _token.balanceOf(msg.sender);
            deposit_amount = SafeCast.toUint128(balance_before.sub(balance_after));
            registerDeposit(lpTokenId, deposit_amount, _franklinAddr);
        } else {
            balance_before = _token.balanceOf(address(this));
            require(Utils.transferFromERC20(_token, msg.sender, address(this), SafeCast.toUint128(_amount)), "fd012"); // token transfer failed deposit
            balance_after = _token.balanceOf(address(this));
            deposit_amount = SafeCast.toUint128(balance_after.sub(balance_before));
            registerDeposit(tokenId, deposit_amount, _franklinAddr);
        }
    }

    /// @notice Withdraw ERC20 token to Layer 1 - register withdrawal and transfer ERC20 to sender
    /// @param _token Token address
    /// @param _amount amount to withdraw
    function withdrawERC20(IERC20 _token, uint128 _amount) external nonReentrant {
        uint16 lpTokenId = tokenIds[address(_token)];
        uint16 tokenId = 0;
        if (lpTokenId == 0) {
            // This means it is not a pair address
            tokenId = governance.validateTokenAddress(address(_token));
        } else {
            tokenId = validatePairTokenAddress(address(_token));
        }
        bytes22 packedBalanceKey = packAddressAndTokenId(msg.sender, tokenId);
        uint128 balance = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
        uint128 withdrawnAmount = this.withdrawERC20Guarded(_token, msg.sender, _amount, balance);
        registerWithdrawal(tokenId, withdrawnAmount, msg.sender);
    }

    /// @notice Register full exit request - pack pubdata, add priority request
    /// @param _accountId Numerical id of the account
    /// @param _token Token address, 0 address for ether
    function fullExit (uint32 _accountId, address _token) external nonReentrant {
        requireActive();
        require(_accountId <= MAX_ACCOUNT_ID, "fee11");

        uint16 tokenId;
        if (_token == address(0)) {
            tokenId = 0;
        } else {
            tokenId = governance.validateTokenAddress(_token);
            require(tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, "fee12");
        }

        // Priority Queue request
        Operations.FullExit memory op = Operations.FullExit({
            accountId:  _accountId,
            owner:      msg.sender,
            tokenId:    tokenId,
            amount:     0 // unknown at this point
        });
        bytes memory pubData = Operations.writeFullExitPubdata(op);
        addPriorityRequest(Operations.OpType.FullExit, pubData);

        // User must fill storage slot of balancesToWithdraw(msg.sender, tokenId) with nonzero value
        // In this case operator should just overwrite this slot during confirming withdrawal
        bytes22 packedBalanceKey = packAddressAndTokenId(msg.sender, tokenId);
        balancesToWithdraw[packedBalanceKey].gasReserveValue = 0xff;
    }

     /// @notice Register deposit request - pack pubdata, add priority request and emit OnchainDeposit event
    /// @param _tokenId Token by id
    /// @param _amount Token amount
    /// @param _owner Receiver
    function registerDeposit(
        uint16 _tokenId,
        uint128 _amount,
        address _owner
    ) internal {
        // Priority Queue request
        Operations.Deposit memory op = Operations.Deposit({
            accountId:  0, // unknown at this point
            owner:      _owner,
            tokenId:    _tokenId,
            amount:     _amount
            });
        bytes memory pubData = Operations.writeDepositPubdata(op);
        addPriorityRequest(Operations.OpType.Deposit, pubData);

        emit OnchainDeposit(
            msg.sender,
            _tokenId,
            _amount,
            _owner
        );
    }

    /// @notice Register withdrawal - update user balance and emit OnchainWithdrawal event
    /// @param _token - token by id
    /// @param _amount - token amount
    /// @param _to - address to withdraw to
    function registerWithdrawal(uint16 _token, uint128 _amount, address payable _to) internal {
        bytes22 packedBalanceKey = packAddressAndTokenId(_to, _token);
        uint128 balance = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
        balancesToWithdraw[packedBalanceKey].balanceToWithdraw = balance.sub(_amount);
        emit OnchainWithdrawal(
            _to,
            _token,
            _amount
        );
    }
    /// @notice Checks that current state not is exodus mode
    function requireActive() internal view {
        require(!exodusMode, "fre11"); // exodus mode activated
    }

    // Priority queue

    /// @notice Saves priority request in storage
    /// @dev Calculates expiration block for request, store this request and emit NewPriorityRequest event
    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    function addPriorityRequest(
        Operations.OpType _opType,
        bytes memory _pubData
    ) internal {
        // Expiration block is: current block number + priority expiration delta
        uint256 expirationBlock = block.number + PRIORITY_EXPIRATION;

        uint64 nextPriorityRequestId = firstPriorityRequestId + totalOpenPriorityRequests;

        priorityRequests[nextPriorityRequestId] = PriorityOperation({
            opType: _opType,
            pubData: _pubData,
            expirationBlock: expirationBlock
        });

        emit NewPriorityRequest(
            msg.sender,
            nextPriorityRequestId,
            _opType,
            _pubData,
            expirationBlock
        );

        totalOpenPriorityRequests++;
    }

    // The contract is too large. Break some functions to zkSyncCommitBlockAddress
    function() external payable {
        address nextAddress = zkSyncCommitBlockAddress;
        require(nextAddress != address(0), "zkSyncCommitBlockAddress should be set");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), nextAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// Address of lock flag variable.
    /// Flag is placed at random memory location to not interfere with Storage contract.
    uint constant private LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    function initializeReentrancyGuard () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        assembly { sstore(LOCK_FLAG_ADDRESS, 1) }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bool notEntered;
        assembly { notEntered := sload(LOCK_FLAG_ADDRESS) }

        // On the first call to nonReentrant, _notEntered will be true
        require(notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly { sstore(LOCK_FLAG_ADDRESS, 0) }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly { sstore(LOCK_FLAG_ADDRESS, 1) }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUInt128 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint128 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Sends tokens
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transfer` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function sendERC20(IERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) = address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _amount)
        );
        // `transfer` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Transfers token from one address to another
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transferFrom` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _from Address of sender
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function transferFromERC20(IERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) = address(_token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount)
        );
        // `transferFrom` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Sends ETH
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function sendETHNoRevert(address payable _to, uint256 _amount) internal returns (bool) {
        // TODO: Use constant from Config
        uint256 ETH_WITHDRAWAL_GAS_LIMIT = 10000;

        (bool callSuccess, ) = _to.call.gas(ETH_WITHDRAWAL_GAS_LIMIT).value(_amount)("");
        return callSuccess;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _message signed message.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes memory _message) internal pure returns (address) {
        require(_signature.length == 65, "ves10"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint offset = 0;

        (offset, signR) = Bytes.readBytes32(_signature, offset);
        (offset, signS) = Bytes.readBytes32(_signature, offset);
        uint8 signV = uint8(_signature[offset]);

        return ecrecover(keccak256(_message), signV, signR, signS);
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

import "./Governance.sol";
import "./Verifier.sol";
import "./VerifierExit.sol";
import "./Operations.sol";

import "./uniswap/UniswapV2Factory.sol";

/// @title zkSync storage contract
/// @author Matter Labs
contract Storage {

    /// @notice Flag indicates that upgrade preparation status is active
    /// @dev Will store false in case of not active upgrade mode
    bool public upgradePreparationActive;

    /// @notice Upgrade preparation activation timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint public upgradePreparationActivationTime;

    /// @notice Verifier contract. Used to verify block proof and exit proof
    Verifier internal verifier;
    VerifierExit internal verifierExit;

    /// @notice Governance contract. Contains the governor (the owner) of whole system, validators list, possible tokens list
    Governance internal governance;
    
    UniswapV2Factory internal pairmanager;

    struct BalanceToWithdraw {
        uint128 balanceToWithdraw;
        uint8 gasReserveValue; // gives user opportunity to fill storage slot with nonzero value
    }

    /// @notice Root-chain balances (per owner and token id, see packAddressAndTokenId) to withdraw
    mapping(bytes22 => BalanceToWithdraw) public balancesToWithdraw;

    /// @notice verified withdrawal pending to be executed.
    struct PendingWithdrawal {
        address to;
        uint16 tokenId;
    }
    
    /// @notice Verified but not executed withdrawals for addresses stored in here (key is pendingWithdrawal's index in pending withdrawals queue)
    mapping(uint32 => PendingWithdrawal) public pendingWithdrawals;
    uint32 public firstPendingWithdrawalIndex;
    uint32 public numberOfPendingWithdrawals;

    /// @notice Total number of verified blocks i.e. blocks[totalBlocksVerified] points at the latest verified block (block 0 is genesis)
    uint32 public totalBlocksVerified;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @notice Rollup block data (once per block)
    /// @member validator Block producer
    /// @member committedAtBlock ETH block number at which this block was committed
    /// @member cumulativeOnchainOperations Total number of operations in this and all previous blocks
    /// @member priorityOperations Total number of priority operations for this block
    /// @member commitment Hash of the block circuit commitment
    /// @member stateRoot New tree root hash
    ///
    /// Consider memory alignment when changing field order: https://solidity.readthedocs.io/en/v0.4.21/miscellaneous.html
    struct Block {
        uint32 committedAtBlock;
        uint64 priorityOperations;
        uint32 chunks;
        bytes32 withdrawalsDataHash; /// can be restricted to 16 bytes to reduce number of required storage slots
        bytes32 commitment;
        bytes32 stateRoot;
    }

    /// @notice Blocks by Franklin block id
    mapping(uint32 => Block) public blocks;

    /// @notice Onchain operations - operations processed inside rollup blocks
    /// @member opType Onchain operation type
    /// @member amount Amount used in the operation
    /// @member pubData Operation pubdata
    struct OnchainOperation {
        Operations.OpType opType;
        bytes pubData;
    }

    /// @notice Flag indicates that a user has exited certain token balance (per account id and tokenId)
    mapping(uint32 => mapping(uint16 => bool)) public exited;
    mapping(uint32 => mapping(uint32 => bool)) public swap_exited;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @notice Priority Operation container
    /// @member opType Priority operation type
    /// @member pubData Priority operation public data
    /// @member expirationBlock Expiration block number (ETH block) for this request (must be satisfied before)
    struct PriorityOperation {
        Operations.OpType opType;
        bytes pubData;
        uint256 expirationBlock;
    }

    /// @notice Priority Requests mapping (request id - operation)
    /// @dev Contains op type, pubdata and expiration block of unsatisfied requests.
    /// @dev Numbers are in order of requests receiving
    mapping(uint64 => PriorityOperation) public priorityRequests;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

    /// @notice Packs address and token id into single word to use as a key in balances mapping
    function packAddressAndTokenId(address _address, uint16 _tokenId) internal pure returns (bytes22) {
        return bytes22((uint176(_address) | (uint176(_tokenId) << 160)));
    }

    /// @notice Gets value from balancesToWithdraw
    function getBalanceToWithdraw(address _address, uint16 _tokenId) public view returns (uint128) {
        return balancesToWithdraw[packAddressAndTokenId(_address, _tokenId)].balanceToWithdraw;
    }

    address public zkSyncCommitBlockAddress;
    address public zkSyncExitAddress;
}

pragma solidity ^0.5.0;


/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {

    /// @notice ERC20 token withdrawal gas limit, used only for complete withdrawals
    uint256 constant ERC20_WITHDRAWAL_GAS_LIMIT = 250000;

    /// @notice ETH token withdrawal gas limit, used only for complete withdrawals
    uint256 constant ETH_WITHDRAWAL_GAS_LIMIT = 10000;

    /// @notice Bytes in one chunk
    uint8 constant CHUNK_BYTES = 9;

    /// @notice zkSync address length
    uint8 constant ADDRESS_BYTES = 20;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    /// @notice Public key bytes length
    uint8 constant PUBKEY_BYTES = 32;

    /// @notice Ethereum signature r/s bytes length
    uint8 constant ETH_SIGN_RS_BYTES = 32;

    /// @notice Success flag bytes length
    uint8 constant SUCCESS_FLAG_BYTES = 1;

    /// @notice Max amount of tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 128 - 1;

    /// @notice Max account id that could be registered in the network
    uint32 constant MAX_ACCOUNT_ID = (2 ** 24) - 1;

    /// @notice Expected average period of block creation
    uint256 constant BLOCK_PERIOD = 15 seconds;

    /// @notice ETH blocks verification expectation
    /// Blocks can be reverted if they are not verified for at least EXPECT_VERIFICATION_IN.
    /// If set to 0 validator can revert blocks at any time.
    uint256 constant EXPECT_VERIFICATION_IN = 0 hours / BLOCK_PERIOD;

    uint256 constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 constant CREATE_PAIR_BYTES = 4 * CHUNK_BYTES;
    uint256 constant DEPOSIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_TO_NEW_BYTES = 6 * CHUNK_BYTES;
    uint256 constant PARTIAL_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_BYTES = 2 * CHUNK_BYTES;
    uint256 constant UNISWAP_ADD_RM_LIQ_BYTES = 6 * CHUNK_BYTES;
    uint256 constant UNISWAP_SWAP_BYTES = 4 * CHUNK_BYTES;

    /// @notice Full exit operation length
    uint256 constant FULL_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @notice OnchainWithdrawal data length
    uint256 constant ONCHAIN_WITHDRAWAL_BYTES = 1 + 20 + 2 + 16; // (uint8 addToPendingWithdrawalsQueue, address _to, uint16 _tokenId, uint128 _amount)

    /// @notice ChangePubKey operation length
    uint256 constant CHANGE_PUBKEY_BYTES = 6 * CHUNK_BYTES;

    /// @notice Expiration delta for priority request to be satisfied (in seconds)
    /// NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD), otherwise incorrect block with priority op could not be reverted.
    uint256 constant PRIORITY_EXPIRATION_PERIOD = 3 days;

    /// @notice Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 constant PRIORITY_EXPIRATION = PRIORITY_EXPIRATION_PERIOD / BLOCK_PERIOD;

    /// @notice Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

    /// @notice Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint constant MASS_FULL_EXIT_PERIOD = 3 days;

    /// @notice Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @notice Notice period before activation preparation status of upgrade mode (in seconds)
    // NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint constant UPGRADE_NOTICE_PERIOD = MASS_FULL_EXIT_PERIOD + PRIORITY_EXPIRATION_PERIOD + TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT;

}

pragma solidity ^0.5.0;

import "./Upgradeable.sol";
import "./Operations.sol";


/// @title zkSync events
/// @author Matter Labs
interface Events {

    /// @notice Event emitted when a block is committed
    event BlockCommit(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is verified
    event BlockVerification(uint32 indexed blockNumber);

    /// @notice Event emitted when a sequence of blocks is verified
    event MultiblockVerification(uint32 indexed blockNumberFrom, uint32 indexed blockNumberTo);

    /// @notice Event emitted when user send a transaction to withdraw her funds from onchain balance
    event OnchainWithdrawal(
        address indexed owner,
        uint16 indexed tokenId,
        uint128 amount
    );

    /// @notice Event emitted when user send a transaction to deposit her funds
    event OnchainDeposit(
        address indexed sender,
        uint16 indexed tokenId,
        uint128 amount,
        address indexed owner
    );

    event OnchainCreatePair(
        uint16 indexed tokenAId,
        uint16 indexed tokenBId,
        uint16 indexed pairId,
        address pair
    );

    /// @notice Event emitted when user sends a authentication fact (e.g. pub-key hash)
    event FactAuth(
        address indexed sender,
        uint32 nonce,
        bytes fact
    );

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(
        uint32 indexed totalBlocksVerified,
        uint32 indexed totalBlocksCommitted
    );

    /// @notice Exodus mode entered event
    event ExodusMode();

    /// @notice New priority request event. Emitted when a request is placed into mapping
    event NewPriorityRequest(
        address sender,
        uint64 serialId,
        Operations.OpType opType,
        bytes pubData,
        uint256 expirationBlock
    );

    /// @notice Deposit committed event.
    event DepositCommit(
        uint32 indexed zkSyncBlockId,
        uint32 indexed accountId,
        address owner,
        uint16 indexed tokenId,
        uint128 amount
    );

    /// @notice Full exit committed event.
    event FullExitCommit(
        uint32 indexed zkSyncBlockId,
        uint32 indexed accountId,
        address owner,
        uint16 indexed tokenId,
        uint128 amount
    );

    /// @notice Pending withdrawals index range that were added in the verifyBlock operation.
    /// NOTE: processed indexes in the queue map are [queueStartIndex, queueEndIndex)
    event PendingWithdrawalsAdd(
        uint32 queueStartIndex,
        uint32 queueEndIndex
    );

    /// @notice Pending withdrawals index range that were executed in the completeWithdrawals operation.
    /// NOTE: processed indexes in the queue map are [queueStartIndex, queueEndIndex)
    event PendingWithdrawalsComplete(
        uint32 queueStartIndex,
        uint32 queueEndIndex
    );

    event CreatePairCommit(
        uint32 indexed zkSyncBlockId,
        uint32 indexed accountId,
        uint16 tokenAId,
        uint16 tokenBId,
        uint16 indexed tokenPairId,
        address pair
    );
}

/// @title Upgrade events
/// @author Matter Labs
interface UpgradeEvents {

    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(
        uint indexed versionId,
        address indexed upgradeable
    );

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        uint indexed versionId,
        address[] newTargets,
        uint noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(
        uint indexed versionId
    );

    /// @notice Upgrade mode preparation status event
    event PreparationStart(
        uint indexed versionId
    );

    /// @notice Upgrade mode complete event
    event UpgradeComplete(
        uint indexed versionId,
        address[] newTargets
    );

}

pragma solidity ^0.5.0;

// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {

    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "bt211");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/32), data)
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint(self), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "bta11");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "btb20");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "btu02");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "btu03");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "btu04");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "btu16");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "btu20");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory  _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "btb32");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length), "bse11"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            // TODO: Review this thoroughly.
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return new_offset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(bytes memory _data, uint _offset, uint _length) internal pure returns (uint new_offset, bytes memory data) {
        data = slice(_data, _offset, _length);
        new_offset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint _offset) internal pure returns (uint new_offset, bool r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint8 r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint32 r) {
        new_offset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint128 r) {
        new_offset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint _offset) internal pure returns (uint new_offset, address r) {
        new_offset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint _offset) internal pure returns (uint new_offset, bytes20 r) {
        new_offset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint _offset) internal pure returns (uint new_offset, bytes32 r) {
        new_offset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    // Helper function for hex conversion.
    function halfByteToHex(byte _byte) internal pure returns (byte _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11");  // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory  _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
                // here outStringByte from each half of input byte calculates by the next:
                //
                // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
                // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(out_curr,            shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130)))
                mstore(add(out_curr, 0x01), shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130)))
            }
        }
        return outStringBytes;
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint _new_length) internal pure returns (uint r) {
        require(_new_length <= 0x20, "trm10");  // new_length is longer than word
        require(_data.length >= _new_length, "trm11");  // data is to short

        uint a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _new_length) * 8);
    }
}

pragma solidity ^0.5.0;

import "./Bytes.sol";


/// @title zkSync operations tools
library Operations {

    // Circuit ops and their pubdata (chunks * bytes)

    /// @notice zkSync circuit operation type
    enum OpType {
        Noop,
        Deposit,
        TransferToNew,
        PartialExit,
        _CloseAccount, // used for correct op id offset
        Transfer,
        FullExit,
        ChangePubKey,
        CreatePair,
        AddLiquidity,
        RemoveLiquidity,
        Swap
    }

    // Byte lengths

    uint8 constant TOKEN_BYTES = 2;

    uint8 constant PUBKEY_BYTES = 32;

    uint8 constant NONCE_BYTES = 4;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    uint8 constant ADDRESS_BYTES = 20;

    /// @notice Packed fee bytes lengths
    uint8 constant FEE_BYTES = 2;

    /// @notice zkSync account id bytes lengths
    uint8 constant ACCOUNT_ID_BYTES = 4;

    uint8 constant AMOUNT_BYTES = 16;

    /// @notice Signature (for example full exit signature) bytes length
    uint8 constant SIGNATURE_BYTES = 64;

    // Deposit pubdata
    struct Deposit {
        uint32 accountId;
        uint16 tokenId;
        uint128 amount;
        address owner;
    }

    uint public constant PACKED_DEPOSIT_PUBDATA_BYTES = 
        ACCOUNT_ID_BYTES + TOKEN_BYTES + AMOUNT_BYTES + ADDRESS_BYTES;

    /// Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure
        returns (Deposit memory parsed)
    {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);   // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);   // amount
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);    // owner

        require(offset == PACKED_DEPOSIT_PUBDATA_BYTES, "rdp10"); // reading invalid deposit pubdata size
    }

    /// Serialize deposit pubdata
    function writeDepositPubdata(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),   // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenId,  // tokenId
            op.amount,   // amount
            op.owner     // owner
        );
    }

    /// @notice Check that deposit pubdata from request and block matches
    function depositPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // We must ignore `accountId` because it is present in block pubdata but not in priority queue
        bytes memory lhs_trimmed = Bytes.slice(_lhs, ACCOUNT_ID_BYTES, PACKED_DEPOSIT_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        bytes memory rhs_trimmed = Bytes.slice(_rhs, ACCOUNT_ID_BYTES, PACKED_DEPOSIT_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        return keccak256(lhs_trimmed) == keccak256(rhs_trimmed);
    }

    // FullExit pubdata

    struct FullExit {
        uint32 accountId;
        address owner;
        uint16 tokenId;
        uint128 amount;
    }

    uint public constant PACKED_FULL_EXIT_PUBDATA_BYTES = 
        ACCOUNT_ID_BYTES + ADDRESS_BYTES + TOKEN_BYTES + AMOUNT_BYTES;

    function readFullExitPubdata(bytes memory _data) internal pure
        returns (FullExit memory parsed)
    {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);      // accountId
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);         // owner
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);        // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);        // amount

        require(offset == PACKED_FULL_EXIT_PUBDATA_BYTES, "rfp10"); // reading invalid full exit pubdata size
    }

    function writeFullExitPubdata(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            op.accountId,  // accountId
            op.owner,      // owner
            op.tokenId,    // tokenId
            op.amount      // amount
        );
    }

    /// @notice Check that full exit pubdata from request and block matches
    function fullExitPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // `amount` is ignored because it is present in block pubdata but not in priority queue
        uint lhs = Bytes.trim(_lhs, PACKED_FULL_EXIT_PUBDATA_BYTES - AMOUNT_BYTES);
        uint rhs = Bytes.trim(_rhs, PACKED_FULL_EXIT_PUBDATA_BYTES - AMOUNT_BYTES);
        return lhs == rhs;
    }

    // PartialExit pubdata
    
    struct PartialExit {
        //uint32 accountId; -- present in pubdata, ignored at serialization
        uint16 tokenId;
        uint128 amount;
        //uint16 fee; -- present in pubdata, ignored at serialization
        address owner;
    }

    function readPartialExitPubdata(bytes memory _data, uint _offset) internal pure
        returns (PartialExit memory parsed)
    {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint offset = _offset + ACCOUNT_ID_BYTES;                   // accountId (ignored)
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset); // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset); // amount
        offset += FEE_BYTES;                                        // fee (ignored)
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);  // owner
    }

    function writePartialExitPubdata(PartialExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),  // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenId, // tokenId
            op.amount,  // amount
            bytes2(0),  // fee (ignored)  (update when FEE_BYTES is changed)
            op.owner    // owner
        );
    }

    // ChangePubKey

    struct ChangePubKey {
        uint32 accountId;
        bytes20 pubKeyHash;
        address owner;
        uint32 nonce;
    }

    function readChangePubKeyPubdata(bytes memory _data, uint _offset) internal pure
        returns (ChangePubKey memory parsed)
    {
        uint offset = _offset;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);                // accountId
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset);              // pubKeyHash
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);                   // owner
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);                    // nonce
    }

    // Withdrawal data process

    function readWithdrawalData(bytes memory _data, uint _offset) internal pure
        returns (bool _addToPendingWithdrawalsQueue, address _to, uint16 _tokenId, uint128 _amount)
    {
        uint offset = _offset;
        (offset, _addToPendingWithdrawalsQueue) = Bytes.readBool(_data, offset);
        (offset, _to) = Bytes.readAddress(_data, offset);
        (offset, _tokenId) = Bytes.readUInt16(_data, offset);
        (offset, _amount) = Bytes.readUInt128(_data, offset);
    }

    // CreatePair pubdata
    
    struct CreatePair {
        uint32 accountId;
        uint16 tokenA;
        uint16 tokenB;
        uint16 tokenPair;
        address pair;
    }

    uint public constant PACKED_CREATE_PAIR_PUBDATA_BYTES =
        ACCOUNT_ID_BYTES + TOKEN_BYTES + TOKEN_BYTES + TOKEN_BYTES + ADDRESS_BYTES;

    function readCreatePairPubdata(bytes memory _data) internal pure
        returns (CreatePair memory parsed)
    {
        uint offset = 0;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.tokenA) = Bytes.readUInt16(_data, offset); // tokenAId
        (offset, parsed.tokenB) = Bytes.readUInt16(_data, offset); // tokenBId
        (offset, parsed.tokenPair) = Bytes.readUInt16(_data, offset); // pairId
        (offset, parsed.pair) = Bytes.readAddress(_data, offset); // pairId
        require(offset == PACKED_CREATE_PAIR_PUBDATA_BYTES, "rcp10"); // reading invalid create pair pubdata size
    }

    function writeCreatePairPubdata(CreatePair memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            bytes4(0),      // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenA,      // tokenAId
            op.tokenB,      // tokenBId
            op.tokenPair,   // pairId
            op.pair         // pair account
        );
    }

    /// @notice Check that create pair pubdata from request and block matches
    function createPairPubdataMatch(bytes memory _lhs, bytes memory _rhs) internal pure returns (bool) {
        // We must ignore `accountId` because it is present in block pubdata but not in priority queue
        bytes memory lhs_trimmed = Bytes.slice(_lhs, ACCOUNT_ID_BYTES, PACKED_CREATE_PAIR_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        bytes memory rhs_trimmed = Bytes.slice(_rhs, ACCOUNT_ID_BYTES, PACKED_CREATE_PAIR_PUBDATA_BYTES - ACCOUNT_ID_BYTES);
        return keccak256(lhs_trimmed) == keccak256(rhs_trimmed);
    }


}

pragma solidity ^0.5.0;


/// @title Interface of the upgradeable master contract (defines notice period duration and allows finish upgrade during preparation of it)
/// @author Matter Labs
interface UpgradeableMaster {

    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external returns (uint);

    /// @notice Notifies contract that notice period started
    function upgradeNoticePeriodStarted() external;

    /// @notice Notifies contract that upgrade preparation status is activated
    function upgradePreparationStarted() external;

    /// @notice Notifies contract that upgrade canceled
    function upgradeCanceled() external;

    /// @notice Notifies contract that upgrade finishes
    function upgradeFinishes() external;

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external returns (bool);

}

pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    address public zkSyncAddress;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() public {
    }

    function initialize(bytes calldata data) external {

    }

    function setZkSyncAddress(address _zksyncAddress) external {
        require(zkSyncAddress == address(0), "szsa1");
        zkSyncAddress = _zksyncAddress;
    }

    /// @notice PairManager contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(msg.sender == zkSyncAddress, 'fcp1');
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        require(zkSyncAddress != address(0), 'wzk');
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function mint(address pair, address to, uint amount) external {
        require(msg.sender == zkSyncAddress, 'fmt1');
        IUniswapV2Pair(pair).mint(to, amount);
    }

    function burn(address pair, address to, uint amount) external {
        require(msg.sender == zkSyncAddress, 'fbr1');
        IUniswapV2Pair(pair).burn(to, amount);
    }
}

pragma solidity ^0.5.0;

contract PairTokenManager {
    /// @notice Max amount of pair tokens registered in the network.
    /// This is computed by: 2048 - 128 = 1920
    uint16 constant MAX_AMOUNT_OF_PAIR_TOKENS = 1920;

    uint16 constant PAIR_TOKEN_START_ID = 128;

    /// @notice Total number of pair tokens registered in the network
    uint16 public totalPairTokens;

    /// @notice List of registered tokens by tokenId
    mapping(uint16 => address) public tokenAddresses;

    /// @notice List of registered tokens by address
    mapping(address => uint16) public tokenIds;
    
    /// @notice Token added to Franklin net
    event NewToken(
        address indexed token,
        uint16 indexed tokenId
    );

    function addPairToken(address _token) internal {
        require(tokenIds[_token] == 0, "pan1"); // token exists
        require(totalPairTokens < MAX_AMOUNT_OF_PAIR_TOKENS, "pan2"); // no free identifiers for tokens

        uint16 newPairTokenId = PAIR_TOKEN_START_ID + totalPairTokens;
        totalPairTokens++;

        tokenAddresses[newPairTokenId] = _token;
        tokenIds[_token] = newPairTokenId;
        emit NewToken(_token, newPairTokenId);
    }

    /// @notice Validate pair token address
    /// @param _tokenAddr Token address
    /// @return tokens id
    function validatePairTokenAddress(address _tokenAddr) public view returns (uint16) {
        uint16 tokenId = tokenIds[_tokenAddr];
        require(tokenId != 0, "pms3");
        require(tokenId < (PAIR_TOKEN_START_ID + MAX_AMOUNT_OF_PAIR_TOKENS), "pms4");
        return tokenId;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.5.0;

import "./Config.sol";


/// @title Governance Contract
/// @author Matter Labs
contract Governance is Config {

    /// @notice Token added to Franklin net
    event NewToken(
        address indexed token,
        uint16 indexed tokenId
    );

    /// @notice Governor changed
    event NewGovernor(
        address newGovernor
    );

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(
        address indexed validatorAddress,
        bool isActive
    );

    /// @notice Address which will exercise governance over the network i.e. add tokens, change validator set, conduct upgrades
    address public networkGovernor;

    /// @notice Total number of ERC20 tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 public totalTokens;

    /// @notice List of registered tokens by tokenId
    mapping(uint16 => address) public tokenAddresses;

    /// @notice List of registered tokens by address
    mapping(address => uint16) public tokenIds;

    /// @notice List of permitted validators
    mapping(address => bool) public validators;

    constructor() public {}

    /// @notice Governance contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    ///     _networkGovernor The address of network governor
    function initialize(bytes calldata initializationParameters) external {
        address _networkGovernor = abi.decode(initializationParameters, (address));

        networkGovernor = _networkGovernor;
    }

    /// @notice Governance contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external {
        requireGovernor(msg.sender);
        require(_newGovernor != address(0), "zero address is passed as _newGovernor");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Add token to the list of networks tokens
    /// @param _token Token address
    function addToken(address _token) external {
        requireGovernor(msg.sender);
        require(tokenIds[_token] == 0, "gan11"); // token exists
        require(totalTokens < MAX_AMOUNT_OF_REGISTERED_TOKENS, "gan12"); // no free identifiers for tokens
        require(
            _token != address(0), "address cannot be zero"
        );

        totalTokens++;
        uint16 newTokenId = totalTokens; // it is not `totalTokens - 1` because tokenId = 0 is reserved for eth

        tokenAddresses[newTokenId] = _token;
        tokenIds[_token] = newTokenId;
        emit NewToken(_token, newTokenId);
    }

    /// @notice Change validator status (active or not active)
    /// @param _validator Validator address
    /// @param _active Active flag
    function setValidator(address _validator, bool _active) external {
        requireGovernor(msg.sender);
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    /// @notice Check if specified address is is governor
    /// @param _address Address to check
    function requireGovernor(address _address) public view {
        require(_address == networkGovernor, "grr11"); // only by governor
    }

    /// @notice Checks if validator is active
    /// @param _address Validator address
    function requireActiveValidator(address _address) external view {
        require(validators[_address], "grr21"); // validator is not active
    }

    /// @notice Validate token id (must be less than or equal to total tokens amount)
    /// @param _tokenId Token id
    /// @return bool flag that indicates if token id is less than or equal to total tokens amount
    function isValidTokenId(uint16 _tokenId) external view returns (bool) {
        return _tokenId <= totalTokens;
    }

    /// @notice Validate token address
    /// @param _tokenAddr Token address
    /// @return tokens id
    function validateTokenAddress(address _tokenAddr) external view returns (uint16) {
        uint16 tokenId = tokenIds[_tokenAddr];
        require(tokenId != 0, "gvs11"); // 0 is not a valid token
	    require(tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, "gvs12");
        return tokenId;
    }

    function getTokenAddress(uint16 _tokenId) external view returns (address) {
        address tokenAddr = tokenAddresses[_tokenId];
        return tokenAddr;
    }
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./KeysWithPlonkAggVerifier.sol";

// Hardcoded constants to avoid accessing store
contract Verifier is KeysWithPlonkAggVerifier {

    bool constant DUMMY_VERIFIER = false;

    function initialize(bytes calldata) external {
    }

    /// @notice Verifier contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    function isBlockSizeSupported(uint32 _size) public pure returns (bool) {
        if (DUMMY_VERIFIER) {
            return true;
        } else {
            return isBlockSizeSupportedInternal(_size);
        }
    }

    function verifyMultiblockProof(
        uint256[] calldata _recursiveInput,
        uint256[] calldata _proof,
        uint32[] calldata _block_sizes,
        uint256[] calldata _individual_vks_inputs,
        uint256[] calldata _subproofs_limbs
    ) external view returns (bool) {
        if (DUMMY_VERIFIER) {
            uint oldGasValue = gasleft();
            uint tmp;
            while (gasleft() + 500000 > oldGasValue) {
                tmp += 1;
            }
            return true;
        }
        uint8[] memory vkIndexes = new uint8[](_block_sizes.length);
        for (uint32 i = 0; i < _block_sizes.length; i++) {
            vkIndexes[i] = blockSizeToVkIndex(_block_sizes[i]);
        }
        VerificationKey memory vk = getVkAggregated(uint32(_block_sizes.length));
        return  verify_serialized_proof_with_recursion(_recursiveInput, _proof, VK_TREE_ROOT, VK_MAX_INDEX, vkIndexes, _individual_vks_inputs, _subproofs_limbs, vk);
    }
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./KeysWithPlonkSingleVerifier.sol";

// Hardcoded constants to avoid accessing store
contract VerifierExit is KeysWithPlonkSingleVerifier {

    function initialize(bytes calldata) external {
    }

    /// @notice VerifierExit contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    function verifyExitProof(
        bytes32 _rootHash,
        uint32 _accountId,
        address _owner,
        uint16 _tokenId,
        uint128 _amount,
        uint256[] calldata _proof
    ) external view returns (bool) {
        return true;
        bytes32 commitment = sha256(abi.encodePacked(_rootHash, _accountId, _owner, _tokenId, _amount));

        uint256[] memory inputs = new uint256[](1);
        uint256 mask = (~uint256(0)) >> 3;
        inputs[0] = uint256(commitment) & mask;
        Proof memory proof = deserialize_proof(inputs, _proof);
        VerificationKey memory vk = getVkExit();
        require(vk.num_inputs == inputs.length);
        return verify(proof, vk);
    }

    function concatBytes(bytes memory param1, bytes memory param2) public pure returns (bytes memory) {
        bytes memory merged = new bytes(param1.length + param2.length);

        uint k = 0;
        for (uint i = 0; i < param1.length; i++) {
            merged[k] = param1[i];
            k++;
        }

        for (uint i = 0; i < param2.length; i++) {
            merged[k] = param2[i];
            k++;
        }
        return merged;
    }

    function verifyLpExitProof(
        bytes calldata _account_data,
        bytes calldata _pair_data0,
        bytes calldata _pair_data1,
        uint256[] calldata _proof
    ) external view returns (bool) {
        return true;
//        bytes memory _data1 = concatBytes(_account_data, _pair_data0);
//        bytes memory _data2 = concatBytes(_data1, _pair_data1);
//        bytes32 commitment = sha256(_data2);
//
//        uint256[] memory inputs = new uint256[](1);
//        uint256 mask = (~uint256(0)) >> 3;
//        inputs[0] = uint256(commitment) & mask;
//        Proof memory proof = deserialize_proof(inputs, _proof);
//        VerificationKey memory vk = getVkLpExit();
//        require(vk.num_inputs == inputs.length);
//        return verify(proof, vk);
    }
}

pragma solidity ^0.5.0;


/// @title Interface of the upgradeable contract
/// @author Matter Labs
interface Upgradeable {

    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    /// @param newTargetInitializationParameters New target initialization parameters
    function upgradeTarget(address newTarget, bytes calldata newTargetInitializationParameters) external;

}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity =0.5.16;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IUNISWAPERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using UniswapSafeMath  for uint;
    using UQ112x112 for uint224;

    address public factory;
    address public token0;
    address public token1;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function mint(address to, uint amount) external lock {
        require(msg.sender == factory, 'mt1');
        _mint(to, amount);
    }

    function burn(address to, uint amount) external lock {
        require(msg.sender == factory, 'br1');
        _burn(to, amount);
    }
}

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./PlonkAggCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkAggVerifier is AggVerifierWithDeserialize {

uint256 constant VK_TREE_ROOT = 0x21ed3488cdd5c5abfcf823d9c1253116692f9fc54e8a43d895154e037ee953aa;
uint8 constant VK_MAX_INDEX = 5;

function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
if (_size == uint32(6)) { return true; }
else if (_size == uint32(24)) { return true; }
else if (_size == uint32(48)) { return true; }
else if (_size == uint32(108)) { return true; }
else if (_size == uint32(240)) { return true; }
else if (_size == uint32(480)) { return true; }
else { return false; }
}

function blockSizeToVkIndex(uint32 _chunks) internal pure returns (uint8) {
if (_chunks == uint32(6)) { return 0; }
else if (_chunks == uint32(24)) { return 1; }
else if (_chunks == uint32(48)) { return 2; }
else if (_chunks == uint32(108)) { return 3; }
else if (_chunks == uint32(240)) { return 4; }
else if (_chunks == uint32(480)) { return 5; }
}


function getVkAggregated(uint32 _blocks) internal pure returns (VerificationKey memory vk) {
if (_blocks == uint32(1)) { return getVkAggregated1(); }
else if (_blocks == uint32(5)) { return getVkAggregated5(); }
else if (_blocks == uint32(10)) { return getVkAggregated10(); }
else if (_blocks == uint32(20)) { return getVkAggregated20(); }
}


function getVkAggregated1() internal pure returns(VerificationKey memory vk) {
vk.domain_size = 4194304;
vk.num_inputs = 1;
vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
0x19fbd6706b4cbde524865701eae0ae6a270608a09c3afdab7760b685c1c6c41b,
0x25082a191f0690c175cc9af1106c6c323b5b5de4e24dc23be1e965e1851bca48
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x16c02d9ca95023d1812a58d16407d1ea065073f02c916290e39242303a8a1d8e,
0x230338b422ce8533e27cd50086c28cb160cf05a7ae34ecd5899dbdf449dc7ce0
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x1db0d133243750e1ea692050bbf6068a49dc9f6bae1f11960b6ce9e10adae0f5,
0x12a453ed0121ae05de60848b4374d54ae4b7127cb307372e14e8daf5097c5123
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x1062ed5e86781fd34f78938e5950c2481a79f132085d2bc7566351ddff9fa3b7,
0x2fd7aac30f645293cc99883ab57d8c99a518d5b4ab40913808045e8653497346
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x062755048bb95739f845e8659795813127283bf799443d62fea600ae23e7f263,
0x2af86098beaa241281c78a454c5d1aa6e9eedc818c96cd1e6518e1ac2d26aa39
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x0994e25148bbd25be655034f81062d1ebf0a1c2b41e0971434beab1ae8101474,
0x27cc8cfb1fafd13068aeee0e08a272577d89f8aa0fb8507aabbc62f37587b98f
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x044edf69ce10cfb6206795f92c3be2b0d26ab9afd3977b789840ee58c7dbe927,
0x2a8aa20c106f8dc7e849bc9698064dcfa9ed0a4050d794a1db0f13b0ee3def37
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x136967f1a2696db05583a58dbf8971c5d9d1dc5f5c97e88f3b4822aa52fefa1c,
0x127b41299ea5c840c3b12dbe7b172380f432b7b63ce3b004750d6abb9e7b3b7a
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x02fd5638bf3cc2901395ad1124b951e474271770a337147a2167e9797ab9d951,
0x0fcb2e56b077c8461c36911c9252008286d782e96030769bf279024fc81d412a
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x1865c60ecad86f81c6c952445707203c9c7fdace3740232ceb704aefd5bd45b3,
0x2f35e29b39ec8bb054e2cff33c0299dd13f8c78ea24a07622128a7444aba3f26
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x2a86ec9c6c1f903650b5abbf0337be556b03f79aecc4d917e90c7db94518dde6,
0x15b1b6be641336eebd58e7991be2991debbbd780e70c32b49225aa98d10b7016
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x213e42fcec5297b8e01a602684fcd412208d15bdac6b6331a8819d478ba46899,
0x03223485f4e808a3b2496ae1a3c0dfbcbf4391cffc57ee01e8fca114636ead18
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x2e9b02f8cf605ad1a36e99e990a07d435de06716448ad53053c7a7a5341f71e1,
0x2d6fdf0bc8bd89112387b1894d6f24b45dcb122c09c84344b6fc77a619dd1d59
);

vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000005
);
vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000007
);
vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
0x000000000000000000000000000000000000000000000000000000000000000a
);

vk.g2_x = PairingsBn254.new_g2(
[0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
[0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
);
}

function getVkAggregated5() internal pure returns(VerificationKey memory vk) {
vk.domain_size = 16777216;
vk.num_inputs = 1;
vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
0x023cfc69ef1b002da66120fce352ede75893edd8cd8196403a54e1eceb82cd43,
0x2baf3bd673e46be9df0d43ca30f834671543c22db422f450b2efd8c931e9b34e
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x23783fe0e5c3f83c02c864e25fe766afb727134c9a77ae6b9694efb7b46f31ab,
0x1903d01005e447d061c16323a1d604d8fbd4b5cc9b64945a71f1234d280c4d3a
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x2897df6c6fa993661b2b0b0cf52460278e33533de71b3c0f7ed7c1f20af238c6,
0x042344afee0aed5505e59bce4ebbe942a91268a8af6b77ea95f603b5b726e8cb
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x0fceed33e78426afc38d8a68c0d93413d2bbaa492b087125271d33d52bdb07b8,
0x0057e4f63be36edb56e91da931f3d0ba72d1862d4b7751c59b92b6ae9f1fcc11
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x14230a35f172cd77a2147cecc20b2a13148363cbab78709489a29d08001e26fb,
0x04f1040477d77896475080b5abb8091cda2cce4917ee0ba5dd62d0ab1be379b4
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x20d1a079ad80a8abb7fd8ba669dddbbe23231360a5f0ba679b6536b6bf980649,
0x120c5a845903bd6de4105eb8cef90e6dff2c3888ada16c90e1efb393778d6a4d
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x1af6b9e362e458a96b8bbbf8f8ce2bdbd650fb68478360c408a2acf1633c1ce1,
0x27033728b767b44c659e7896a6fcc956af97566a5a1135f87a2e510976a62d41
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x0dbfb3c5f5131eb6f01e12b1a6333b0ad22cc8292b666e46e9bd4d80802cccdf,
0x2d058711c42fd2fd2eef33fb327d111a27fe2063b46e1bb54b32d02e9676e546
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x0c8c7352a84dd3f32412b1a96acd94548a292411fd7479d8609ca9bd872f1e36,
0x0874203fd8012d6976698cc2df47bca14bc04879368ade6412a2109c1e71e5e8
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x1b17bb7c319b1cf15461f4f0b69d98e15222320cb2d22f4e3a5f5e0e9e51f4bd,
0x0cf5bc338235ded905926006027aa2aab277bc32a098cd5b5353f5545cbd2825
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x0794d3cfbc2fdd756b162571a40e40b8f31e705c77063f30a4e9155dbc00e0ef,
0x1f821232ab8826ea5bf53fe9866c74e88a218c8d163afcaa395eda4db57b7a23
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x224d93783aa6856621a9bbec495f4830c94994e266b240db9d652dbb394a283b,
0x161bcec99f3bc449d655c0ca59874dafe1194138eec91af34392b09a83338ca1
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x1fa27e2916b2c11d39c74c0e61063190da31c102d2b7da5c0a61ec8c5e82f132,
0x0a815ee76cd8aa600e6f66463b25a0ee57814bfdf06c65a91ddc70cede41caae
);

vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000005
);
vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000007
);
vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
0x000000000000000000000000000000000000000000000000000000000000000a
);

vk.g2_x = PairingsBn254.new_g2(
[0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
[0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
);
}

function getVkAggregated10() internal pure returns(VerificationKey memory vk) {
vk.domain_size = 33554432;
vk.num_inputs = 1;
vk.omega = PairingsBn254.new_fr(0x0d94d63997367c97a8ed16c17adaae39262b9af83acb9e003f94c217303dd160);
vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
0x118a33d75bd2b49bc91e7e9b60592a9e93128780f0ee45909d5c1583fc312e2b,
0x029bfeb33d7ea821336d26518d0ea369963ed9a697feab042ed9c1196ce60fcd
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x237c2be6d5ab05dac2f085e603d16a40474d8507e9e3ffb26ca054b71bec84e8,
0x0a041723d3c5882a11f0380cab33ba8c0ec5d333b7618b477073970b93e4161b
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x06e8bb6c2c9ef293a5273b2a501c8484c81cf8907eb20b3b3e8745670d3edf9c,
0x144efe2e483905c439661fdce23df9ebbadd45dd8002ff5658356e4448c12cdf
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x186679a0b8edcf535be61dd0c4b3d9f1f1d570f53ace4100c154bc8d857467a3,
0x0b294653f6bba0293f8d9a91dff2bf2156d7a7169e22ae80f31dc10a500d1275
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x1b097f651e551cfca089d6483aa78c9fca8022f11cc0f5210062df4ea09675dc,
0x08cd7b2c48da8faefa0d79d5ca5e6106d9375e17a65d8ff184eed450e4d90de4
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x2f558b39270c076e92f12a09863a5b70ba3f471e75bc4a76c5bf0709bc39410a,
0x25f36985d8ede876604c7f5d08dd2fb6f4b069d6e8d587dbb50f7418b3ff87d3
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x194e7f1cf485a42a4d4313a28ba289a9a2d80a09482cc85acbc2b39713bae24a,
0x2f9491a38a23267390e77c706ad178a4884cf960708c601e2841cc173c580427
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x11aea225adaaced8cadf40634b8ec791133a571f1ef60e9857305d1b6c4af319,
0x1c71a79c4433117ec0ef80d773cf03dc2555d10cfa8726301f4fda6a273f9790
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x12f7e96a400593a494e9d5541b641c804edabdb56f9a3004187e82fc97f45e41,
0x14205d243f5a63f318b0826e2b69aaa61dd8e19cb1b353545619b063dc2a4c52
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x1faf8943996cbaa6882e78b34bce97e5c2e623e7ba4c1f46cbfba88da7ffd132,
0x1fbb80b092682f790975ae9323c957b49d51f9e5562152fc73bc00c291a71664
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x0871ff65b88a40eec8c8a9573625b76eb7c5cd07e1374fb29b984c8e9bdac46b,
0x2788d12e2329037f8184ee892a22a92d056616921d3df424a208ebd06b7870e7
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x1b54676a721bbeb1304eb2721a0ce8d8f147e792481880a3e9164de4ed8958c7,
0x0af99225ab387d31f9654e8b26de1b67a175e47d59adaf6340fbc1dcc7ce2196
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x1313fcb16f52505aee519aff9adc46c81d7fc702d41ce04a89516c7da5a5cc4a,
0x060a56882fc5eeb6f267876174fb0490c0c6ccde2ed4f56b021370d47051caac
);

vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000005
);
vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000007
);
vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
0x000000000000000000000000000000000000000000000000000000000000000a
);

vk.g2_x = PairingsBn254.new_g2(
[0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
[0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
);
}

function getVkAggregated20() internal pure returns(VerificationKey memory vk) {
vk.domain_size = 67108864;
vk.num_inputs = 1;
vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
0x2657afa69e15a3998bde27116082a0e8cfe5e7fe9be3ffb37d318b5368e92a2f,
0x15b2c5e18b45bdc797c1102ad693259df3f3cdf7432b21337a93dd428878d4dc
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x120d7974239dd8111afeb34cca058db63227e5eea30495479c2f86ef2704239d,
0x185de0bdd64bb1f78e9de92bd71d112ce1b5290bd4f15f58e54ef783730bdb2e
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x20c77a6ac5ec6a5cf728a6496bad151a7fa84583a4e44cafab5335ece5b68e92,
0x28955c55fa76091bb1beb3bc81f3f0abea9c1772b213e9cc24fb32ce017fdc19
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x072a5373c38c252bbd9dbd16ea4ff418e3e6c3d13073c17347805af6afc016a0,
0x150ff2f3ae9c31a8c94c31605f5f70804bdf3bc601269bca4b6b4137eaf2db53
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x2d8fc65e12e3262a891d252a81f13f75e03e5e3be04ca03a0c376a1aafa833c5,
0x14b32a4898df4aa936fe124a5dc886263e12b0f173b8e96eb011eea6b43a6c2b
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x2a10059adb643c8fd510fa78b1d3ca75acfabf6dd02e777421510f59b7fe35db,
0x0de555189d42fbe10d0f1f325b431499562fc0bdfa631e24babc3b08f2b40239
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x15aebf231748de2a113e3b78d4778ee429485ee725192adcd83d90195ae46a62,
0x1643482806d5c12ed94b8843ed3ab29b443be1c4303757b4494965e2725aca21
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x22e8fa104dc1110e140f69f66defd24c501459661ab45680be88107773596583,
0x0dea216f16fedc871f884b081d934b7be1637c1705e33cee7e33d301e9dd0a31
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x24830cfaa291d8dcd99a8f7fcfe313645286e26c427a75ec64bb385d03d18a62,
0x0cf6a160da9f331955256a0fba54561e82b6ee0ce2f4fa434addf1e07304f4ea
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x05a5a5b8bd64cb5c0ec27397ece0f4c00e1f0889f1516b4ba8b821f832b24bb6,
0x22d6f8ac4a745aaaa9b48b388f7ca383f13d1684e04b24f627fbfa65d10404c0
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x0b44251fce15393e219d9bec3e17261f9b041b2b837ed6897735544e0d7d195d,
0x15c907d4d776e0878ab9491847edc0a857ef4c7ca77acd365d95f00dddc327aa
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x132f2aafa0add2184b557aa5e5a75cbef16661fd28209728a658dbda6fdccfbb,
0x223da3cd1f9ad3cf6a0cd37ceb1010286bcd88a92a16eef81447bbd0b365042c
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x3006215b71c3d3ce7dd057f3a139fbb293e44a6ed529494b4e32e4517f51b6f4,
0x061a53d503897b89fd301316a738bf7b0e483232dc9e38677a18a8d3742cb370
);

vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000005
);
vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
0x0000000000000000000000000000000000000000000000000000000000000007
);
vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
0x000000000000000000000000000000000000000000000000000000000000000a
);

vk.g2_x = PairingsBn254.new_g2(
[0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
[0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
);
}


}

pragma solidity >=0.5.0 <0.7.0;

import "./PlonkSingleCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkSingleVerifier is SingleVerifierWithDeserialize {

    function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
        if (_size == uint32(6)) { return true; }
        else if (_size == uint32(24)) { return true; }
        else if (_size == uint32(48)) { return true; }
        else if (_size == uint32(108)) { return true; }
        else if (_size == uint32(240)) { return true; }
        else if (_size == uint32(480)) { return true; }
        else { return false; }
    }

    
    function getVkExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x1360d4580199c4997d4ba4c95ed0577cf4672d086b2818f6e6ad604e7185e7da,
            0x07bd14656eda23c59d7f02c19094f242b50ecb69fb169d1d63877594e797bf81
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x24a435a22b07533a9f71c89407c0390ac2a0548619d8f52712b5bed9268f864b,
            0x05939b3d7e4a7320085e48cb625b9c32749673e6671790181d57f95022ffa003
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x2e823ec36c8b0a8b453581b51058242ce9aa592f1862b55f3b66e6426dee7bbf,
            0x0354110ce3383bfd9af7ef2a92d52d93b90a60e76b1e0cb67eaf18cae022a84d
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x251fffa91e442330d7645b9a22cbacbc5a1a13e4c61429b1efd5ba03d2839eaa,
            0x2b508ba6b6fa40660bfd9bb2ed248a4fcc72f0d78798a4b16c7fd5c93ac57b62
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2210ea90c32db8a24dcd71dceabf9c8440074ad16056fd3bb99ce5720fd600a1,
            0x2d4e27890cd3fe700af39b50df098c81d8f9dac7ea7f39a078180d44b7f8c215
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x10115c8ad63661c31136f26cd4841fa9603fb0a8d15068a84a945ba027fdddd0,
            0x0421ad5cb895a2a5a0698452eb59f199fd72c1f8c8fb150649fcc887b2a0da21
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x2ef4e2f810e41d13109c14819c24eadbc582ff0c62607292888b198ebf499c98,
            0x0e85b5c05a3789024172ededc3eada603afd17313acb056acdd9ee87083577c3
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x24cc5f0fd58545753ba5874e8f6f2243eb8eb1deb0d980735d8a6cf4c368dfa6,
            0x2fb47cbb3008a4201760340adbf1c2acfb298928c78906d45961557738114d19
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x0d5afddeffe093e9a4b4293058b751a8c4db5ad97bae1b94ca5e2a0cd95455e7,
            0x1903e888f61c545870fc780d3d89ce6a21b601c1003d07b197baca50b2bca80c
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x229183766cf243e99fb9fcc7bb76f425cc9a97768a121dd729aba031cd7a0179,
            0x0b5d2879a5ea9e85b389f276c587d4a1ecf096de60229bc4134d00a5a7194f33
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x1a20d88ed8a07c9df93dd37cdbdda6d37ecc3fbecd92bb90574410d4bcba17db,
            0x0d867c3762edd7bbe0c5ca5c6c1335aacebb1f5f6cebd9cc17687c40a22daaa5
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
             0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
             0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkLpExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 524288;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0cf1526aaafac6bacbb67d11a4077806b123f767e4b0883d14cc0193568fc082);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x0056414a9808c35434b70f00837b0df6096695a4f7bfd8fec55268b46a3c45ac,
            0x12d27e314d3fd2a5bda673353e961f5a2154f385b6829e15b5d3e547b1ce7678
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x1e44e773a20daabce7705a17551ee209c634e4fefe8c871da73ec160e13dff17,
            0x1fed1bedd62db6f55171a540e5d839f7ddb0c3f9839f9b88d9a4a72c2da3b1f5
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x1c7b37eabf1febe3958e41dca63a8c7aedcae08ac0ced628aa98ec30a9093e71,
            0x09f5cd26c7097b259dc0b68e3ff073dcd72cab556e7e84a07a376f23c2a3efbc
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0f8aaf75061245f1afd39f6c2ddbdd002560d8ade05a3c72fa411498ecd0850f,
            0x0399f219a1d3499a427b07bf64ee9d6a0cdcbf238d999cb205ea28ed40bb53c6
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2d9e24829410b34c2f478732e5e65d4f671ff50165332c6a65e8eba9cbd8d9c9,
            0x03ab6bb2cb6ead217753c5f5722361f775d5d085b87d4bcf0d542e70e43ffb2f
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x2f88402fef4ee91a3e7621a4648543b0d8ac5a860756c2b9d940f579721bef3d,
            0x27d29dce8ec872ebdfcaebbe993fbf96aec68cb34260cb7f982535ac3a933582
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x2e6fcd05f9201bcecf8ba4eca4e5b36ba4b36ec71cee3b24b23eb4229b850475,
            0x1f9b76f495670289eb2968cba709a832aa320787ad9f4336ad48fdecfff20ace
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1d2036466b3dccfcd9cbf5044ae3979bc461931dd2cf40046db9a53e48f6d753,
            0x0a3656b72d0cead4d2b1f71559c16ca1d7a0f2866123916d8b11989832fb3b1a
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1b78245056c25753e12fc07514eee928edc8159d8ea070b3630c1f5c9ee88603,
            0x2acdfa5a12d60d1e71fa1ef1425d37c0dd33dbb899fc2af1cb589fc8ec7ee230
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x148813470615cf6d90bda720078cfb6795e74e9dad829303e96808edec498de4,
            0x0db3ae162ea9ef8f242b3468565952e68b4ea84391034b9115898d01a2c786e3
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x235b7a06df623b1499d06fd1ce673b0f8c55f64df2b23ddcfb9e5cd8698e989e,
            0x0dc9c1ac3479d4d8431f93cd8c140755867a23c9a2167d7fd0a35c7c8359afb1
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
             0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
             0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function initialize(address, address) external;

    function mint(address to, uint amount) external;
    function burn(address to, uint amount) external;
}

pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/UniswapSafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using UniswapSafeMath for uint;

    string public constant name = 'ZKSWAP V1';
    string public constant symbol = 'ZKS-V1';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

pragma solidity =0.5.16;

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

pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

pragma solidity >=0.5.0;

interface IUNISWAPERC20 {
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

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./PlonkCoreLib.sol";

contract Plonk4AggVerifierWithAccessToDNext {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;


    uint256 constant ZERO = 0;
    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant THREE = 3;
    uint256 constant FOUR = 4;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant NUM_DIFFERENT_GATES = 2;
    uint256 constant NUM_SETUP_POLYS_FOR_MAIN_GATE = 7;
    uint256 constant NUM_SETUP_POLYS_RANGE_CHECK_GATE = 0;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;
    uint256 constant NUM_GATE_SELECTORS_OPENED_EXPLICITLY = 1;

    uint256 constant RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant LIMB_WIDTH = 68;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[NUM_SETUP_POLYS_FOR_MAIN_GATE + NUM_SETUP_POLYS_RANGE_CHECK_GATE] gate_setup_commitments;
        PairingsBn254.G1Point[NUM_DIFFERENT_GATES] gate_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] copy_permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH-1] copy_permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point copy_permutation_grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr[NUM_GATE_SELECTORS_OPENED_EXPLICITLY] gate_selector_values_at_z;
        PairingsBn254.Fr copy_grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH-1] permutation_polynomials_at_z;

        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i-1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(
        uint256 domain_size,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory inputs_term = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            inputs_term.add_assign(tmp);
        }

        inputs_term.mul_assign(proof.gate_selector_values_at_z[0]);
        rhs.add_assign(inputs_term);

        // now we need 5th power
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.copy_grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function add_contribution_from_range_constraint_gates(
        PartialVerifierState memory state,
        Proof memory proof,
        PairingsBn254.Fr memory current_alpha
    ) internal pure returns (PairingsBn254.Fr memory res) {
        // now add contribution from range constraint gate
        // we multiply selector commitment by all the factors (alpha*(c - 4d)(c - 4d - 1)(..-2)(..-3) + alpha^2 * (4b - c)()()() + {} + {})

        PairingsBn254.Fr memory one_fr = PairingsBn254.new_fr(ONE);
        PairingsBn254.Fr memory two_fr = PairingsBn254.new_fr(TWO);
        PairingsBn254.Fr memory three_fr = PairingsBn254.new_fr(THREE);
        PairingsBn254.Fr memory four_fr = PairingsBn254.new_fr(FOUR);

        res = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t0 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t2 = PairingsBn254.new_fr(0);

        for (uint256 i = 0; i < 3; i++) {
            current_alpha.mul_assign(state.alpha);

            // high - 4*low

            // this is 4*low
            t0 = PairingsBn254.copy(proof.wire_values_at_z[3 - i]);
            t0.mul_assign(four_fr);

            // high
            t1 = PairingsBn254.copy(proof.wire_values_at_z[2 - i]);
            t1.sub_assign(t0);

            // t0 is now t1 - {0,1,2,3}

            // first unroll manually for -0;
            t2 = PairingsBn254.copy(t1);

            // -1
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(one_fr);
            t2.mul_assign(t0);

            // -2
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(two_fr);
            t2.mul_assign(t0);

            // -3
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(three_fr);
            t2.mul_assign(t0);

            t2.mul_assign(current_alpha);

            res.add_assign(t2);
        }

        // now also d_next - 4a

        current_alpha.mul_assign(state.alpha);

        // high - 4*low

        // this is 4*low
        t0 = PairingsBn254.copy(proof.wire_values_at_z[0]);
        t0.mul_assign(four_fr);

        // high
        t1 = PairingsBn254.copy(proof.wire_values_at_z_omega[0]);
        t1.sub_assign(t0);

        // t0 is now t1 - {0,1,2,3}

        // first unroll manually for -0;
        t2 = PairingsBn254.copy(t1);

        // -1
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(one_fr);
        t2.mul_assign(t0);

        // -2
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(two_fr);
        t2.mul_assign(t0);

        // -3
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(three_fr);
        t2.mul_assign(t0);

        t2.mul_assign(current_alpha);

        res.add_assign(t2);

        return res;
    }

    function reconstruct_linearization_commitment(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^{6} * (selector(x) - selector(z))
        // + v^{7..9} * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^10 (z(x) - z(z*omega)) <- we need this power
        // + v^11 * (d(x) - d(z*omega))
        // ]
        //

        // we reconstruct linearization polynomial virtual selector
        // for that purpose we first linearize over main gate (over all it's selectors)
        // and multiply them by value(!) of the corresponding main gate selector
        res = PairingsBn254.copy_g1(vk.gate_setup_commitments[STATE_WIDTH + 1]); // index of q_const(x)

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.gate_setup_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH+2].point_mul(proof.wire_values_at_z_omega[0]); // index of q_d_next(x)
        res.point_add_assign(tmp_g1);

        // multiply by main gate selector(z)
        res.point_mul_assign(proof.gate_selector_values_at_z[0]); // these is only one explicitly opened selector

        PairingsBn254.Fr memory current_alpha = PairingsBn254.new_fr(ONE);

        // calculate scalar contribution from the range check gate
        tmp_fr = add_contribution_from_range_constraint_gates(state, proof, current_alpha);
        tmp_g1 = vk.gate_selector_commitments[1].point_mul(tmp_fr); // selector commitment for range constraint gate * scalar
        res.point_add_assign(tmp_g1);

        // proceed as normal to copy permutation
        current_alpha.mul_assign(state.alpha); // alpha^5

        PairingsBn254.Fr memory alpha_for_grand_product = PairingsBn254.copy(current_alpha);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.copy_permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.copy_permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i+1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(alpha_for_grand_product);

        // alpha^n & L_{0}(z), and we bump current_alpha
        current_alpha.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(current_alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        // prefactor for grand_product(x) is complete

        // add to the linearization a part from the term
        // - (a(z) + beta*perm_a + gamma)*()*()*z(z*omega) * beta * perm_d(X)
        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.copy_grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(alpha_for_grand_product); // we multiply by the power of alpha from the argument

        // actually multiply prefactors by z(x) and perm_d(x) and combine them
        tmp_g1 = proof.copy_permutation_grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.copy_permutation_commitments[STATE_WIDTH - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        // multiply them by v immedately as linearization has a factor of v^1
        res.point_mul_assign(state.v);
        // res now contains contribution from the gates linearization and
        // copy permutation part

        // now we need to add a part that is the rest
        // for z(x*omega):
        // - (a(z) + beta*perm_a + gamma)*()*()*(d(z) + gamma) * z(x*omega)
    }

    function aggregate_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point[2] memory res) {
        PairingsBn254.G1Point memory d = reconstruct_linearization_commitment(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint i = 0; i < NUM_GATE_SELECTORS_OPENED_EXPLICITLY; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.gate_selector_commitments[0].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint i = 0; i < vk.copy_permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.copy_permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        // now do prefactor for grand_product(x*omega)
        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        commitment_aggregation.point_add_assign(proof.copy_permutation_grand_product_commitment.point_mul(tmp_fr));

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_fr.assign(proof.gate_selector_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.copy_grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        res[0] = pair_with_generator;
        res[1] = pair_with_x;

        return res;
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.copy_permutation_grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega, state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        transcript.update_with_fr(proof.gate_selector_values_at_z[0]);

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.copy_grand_product_at_z_omega);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function aggregate_for_verification(Proof memory proof, VerificationKey memory vk) internal view returns (bool valid, PairingsBn254.G1Point[2] memory part) {
        PartialVerifierState memory state;

        valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return (valid, part);
        }

        part = aggregate_commitments(state, proof, vk);

        (valid, part);
    }

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        valid = PairingsBn254.pairingProd2(recursive_proof_part[0], PairingsBn254.P2(), recursive_proof_part[1], vk.g2_x);

        return valid;
    }

    function verify_recursive(
        Proof memory proof,
        VerificationKey memory vk,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[] memory subproofs_limbs
    ) internal view returns (bool) {
        (uint256 recursive_input, PairingsBn254.G1Point[2] memory aggregated_g1s) = reconstruct_recursive_public_input(
            recursive_vks_root, max_valid_index, recursive_vks_indexes,
            individual_vks_inputs, subproofs_limbs
        );

        assert(recursive_input == proof.input_values[0]);

        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        recursive_proof_part[0].point_add_assign(aggregated_g1s[0]);
        recursive_proof_part[1].point_add_assign(aggregated_g1s[1]);

        valid = PairingsBn254.pairingProd2(recursive_proof_part[0], PairingsBn254.P2(), recursive_proof_part[1], vk.g2_x);

        return valid;
    }

    function reconstruct_recursive_public_input(
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[] memory subproofs_aggregated
    ) internal pure returns (uint256 recursive_input, PairingsBn254.G1Point[2] memory reconstructed_g1s) {
        assert(recursive_vks_indexes.length == individual_vks_inputs.length);
        bytes memory concatenated = abi.encodePacked(recursive_vks_root);
        uint8 index;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            index = recursive_vks_indexes[i];
            assert(index <= max_valid_index);
            concatenated = abi.encodePacked(concatenated, index);
        }
        uint256 input;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            input = individual_vks_inputs[i];
            //            assert(input < PairingsBn254.r_mod);
            concatenated = abi.encodePacked(concatenated, input);
        }

        concatenated = abi.encodePacked(concatenated, subproofs_aggregated);

        bytes32 commitment = sha256(concatenated);
        recursive_input = uint256(commitment) & RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK;

        reconstructed_g1s[0] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[0] + (subproofs_aggregated[1] << LIMB_WIDTH) + (subproofs_aggregated[2] << 2*LIMB_WIDTH) + (subproofs_aggregated[3] << 3*LIMB_WIDTH),
            subproofs_aggregated[4] + (subproofs_aggregated[5] << LIMB_WIDTH) + (subproofs_aggregated[6] << 2*LIMB_WIDTH) + (subproofs_aggregated[7] << 3*LIMB_WIDTH)
        );

        reconstructed_g1s[1] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[8] + (subproofs_aggregated[9] << LIMB_WIDTH) + (subproofs_aggregated[10] << 2*LIMB_WIDTH) + (subproofs_aggregated[11] << 3*LIMB_WIDTH),
            subproofs_aggregated[12] + (subproofs_aggregated[13] << LIMB_WIDTH) + (subproofs_aggregated[14] << 2*LIMB_WIDTH) + (subproofs_aggregated[15] << 3*LIMB_WIDTH)
        );

        return (recursive_input, reconstructed_g1s);
    }
}

contract AggVerifierWithDeserialize is Plonk4AggVerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 34;

    function deserialize_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof
    ) internal pure returns(Proof memory proof) {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j+1]
            );

            j += 2;
        }

        proof.copy_permutation_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j+1]
        );
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j+1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            proof.gate_selector_values_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }


        proof.copy_grand_product_at_z_omega = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j+1]
        );
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j+1]
        );
    }

    function verify_serialized_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify(proof, vk);

        return valid;
    }

    function verify_serialized_proof_with_recursion(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[] memory subproofs_limbs,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify_recursive(proof, vk, recursive_vks_root, max_valid_index, recursive_vks_indexes, individual_vks_inputs, subproofs_limbs);

        return valid;
    }
}

pragma solidity >=0.5.0 <0.7.0;

import "./PlonkCoreLib.sol";

contract Plonk4SingleVerifierWithAccessToDNext {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[STATE_WIDTH+2] selector_commitments; // STATE_WIDTH for witness + multiplication + constant
        PairingsBn254.G1Point[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] next_step_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH-1] permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH-1] permutation_polynomials_at_z;

        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i-1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(
        uint256 domain_size,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            rhs.add_assign(tmp);
        }

        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function reconstruct_d(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^(6..8) * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^9 (z(x) - z(z*omega)) <- we need this power
        // + v^10 * (d(x) - d(z*omega))
        // ]
        //
        // we pay a little for a few arithmetic operations to not introduce another constant
        uint256 power_for_z_omega_opening = 1 + 1 + STATE_WIDTH + STATE_WIDTH - 1;
        res = PairingsBn254.copy_g1(vk.selector_commitments[STATE_WIDTH + 1]);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.selector_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.selector_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.next_step_selector_commitments[0].point_mul(proof.wire_values_at_z_omega[0]);
        res.point_add_assign(tmp_g1);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i+1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(state.alpha);
        tmp_fr.mul_assign(state.alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        PairingsBn254.Fr memory grand_product_part_at_z_omega = state.v.pow(power_for_z_omega_opening);
        grand_product_part_at_z_omega.mul_assign(state.u);

        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(state.alpha);

        // add to the linearization
        tmp_g1 = proof.grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.permutation_commitments[STATE_WIDTH - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        res.point_mul_assign(state.v);

        res.point_add_assign(proof.grand_product_commitment.point_mul(grand_product_part_at_z_omega));
    }

    function verify_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.G1Point memory d = reconstruct_d(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint i = 0; i < vk.permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        return PairingsBn254.pairingProd2(pair_with_generator, PairingsBn254.P2(), pair_with_x, vk.g2_x);
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega, state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        PartialVerifierState memory state;

        bool valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return false;
        }

        valid = verify_commitments(state, proof, vk);

        return valid;
    }
}

contract SingleVerifierWithDeserialize is Plonk4SingleVerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 33;

    function deserialize_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof
    ) internal pure returns(Proof memory proof) {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j+1]
            );

            j += 2;
        }

        proof.grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j+1]
        );
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j+1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        proof.grand_product_at_z_omega = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j+1]
        );
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j+1]
        );
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library UniswapSafeMath {
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

pragma solidity >=0.5.0 <0.7.0;

library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod-2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod);
        require(y < q_mod);
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs);

        return G1Point(x, y);
    }

    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return G2Point(
            [0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
            0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed],
            [0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
            0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa]
        );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2)
    internal view returns (G1Point memory r)
    {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(G1Point memory p1, G1Point memory p2)
    internal view
    {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(G1Point memory p1, G1Point memory p2, G1Point memory dest)
    internal view
    {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_sub_assign(G1Point memory p1, G1Point memory p2)
    internal view
    {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(G1Point memory p1, G1Point memory p2, G1Point memory dest)
    internal view
    {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s)
    internal view returns (G1Point memory r)
    {
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s)
    internal view
    {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(G1Point memory p, Fr memory s, G1Point memory dest)
    internal view
    {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2)
    internal view returns (bool)
    {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2)
    internal view returns (bool)
    {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

library TranscriptLibrary {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(abi.encodePacked(DST_0, old_state_0, self.state_1, value));
        self.state_1 = keccak256(abi.encodePacked(DST_1, old_state_0, self.state_1, value));
    }

    function update_with_fr(Transcript memory self, PairingsBn254.Fr memory value) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(Transcript memory self, PairingsBn254.G1Point memory p) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self) internal pure returns(PairingsBn254.Fr memory challenge) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state_0, self.state_1, self.challenge_counter));
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

{
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  }
}