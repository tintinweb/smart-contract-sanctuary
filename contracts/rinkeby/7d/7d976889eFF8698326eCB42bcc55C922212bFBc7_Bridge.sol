// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @dev This contract allows cross chain token transfers.
 *
 * There are two processes that take place in the contract -
 * - Initiate a cross chain transfer to a target blockchain (locks tokens from the caller account on Ethereum)
 * - Report a cross chain transfer initiated on a source blockchain (releases tokens to an account on Ethereum)
 *
 * Reporting cross chain transfers works similar to standard multisig contracts, meaning that multiple
 * callers are required to report a transfer before tokens are released to the target account.
 */
contract Bridge is Ownable {

    // represents a transaction on another blockchain where tokens were destroyed/locked
    struct Transaction {
        uint256 amount;
        bytes32 fromBlockchain;
        address to;
        uint8 numOfReports;
        bool completed;
    }

    struct SendRewardsConfig {
        bytes32 toBlockchain;
        bytes32 toAccount;
        uint256 maxLockLimit;
    }

    bytes32 public sendRewardsToBlockchain; // the target blockchain when send rewards
    bytes32 public sendRewardsToAccount; // the target account when send rewards
    uint256 public sendRewardsMaxLockLimit; // the lock limit when send rewards
    uint256 public maxLockLimit; // the maximum amount of tokens that can be locked in one transaction
    uint256 public maxReleaseLimit; // the maximum amount of tokens that can be released in one transaction
    uint256 public minLimit; // the minimum amount of tokens that can be transferred in one transaction
    uint256 public prevLockLimit; // the lock limit *after* the last transaction
    uint256 public prevReleaseLimit; // the release limit *after* the last transaction
    uint256 public limitIncPerBlock; // how much the limit increases per block
    uint256 public prevLockBlockNumber; // the block number of the last lock transaction
    uint256 public prevReleaseBlockNumber; // the block number of the last release transaction
    uint256 public commissionAmount; // the commission amount reduced from the release amount
    uint256 public totalCommissions; // current total commissions accumulated on report tx
    uint8 public minRequiredReports; // minimum number of required reports to release tokens

    IERC20 public token; // erc20 token

    bool public xTransfersEnabled = true; // true if x transfers are enabled, false if not
    bool public reportingEnabled = true; // true if reporting is enabled, false if not

    // txId -> Transaction
    mapping(uint256 => Transaction) public transactions;

    // xTransferId -> txId
    mapping(uint256 => uint256) public transactionIds;

    // txId -> reporter -> true if reporter already reported txId
    mapping(uint256 => mapping(address => bool)) public reportedTxs;

    // address -> true if address is reporter
    mapping(address => bool) public reporters;

    /**
     * @dev triggered when tokens are locked in smart contract
     *
     * @param _from    wallet address that the tokens are locked from
     * @param _amount  amount locked
     */
    event TokensLock(address indexed _from, uint256 _amount);

    /**
     * @dev triggered when tokens are released by the smart contract
     *
     * @param _to      wallet address that the tokens are released to
     * @param _amount  amount released
     */
    event TokensRelease(address indexed _to, uint256 _amount);

    /**
     * @dev triggered when commissions are withdrawn by the smart contract
     *
     * @param _to      wallet address that the tokens are withdrawn to
     * @param _amount  amount withdrawn
     */
    event CommissionsWithdraw(address indexed _to, uint256 _amount);

    /**
     * @dev triggered when xTransfer is successfully called
     *
     * @param _from            wallet address that initiated the xtransfer
     * @param _toBlockchain    target blockchain
     * @param _to              target wallet
     * @param _amount          transfer amount
     * @param _id              xtransfer id
     */
    event XTransfer(address indexed _from, bytes32 _toBlockchain, bytes32 indexed _to, uint256 _amount, uint256 _id);

    /**
     * @dev triggered when report is successfully submitted
     *
     * @param _reporter         reporter wallet
     * @param _fromBlockchain   source blockchain
     * @param _txId             tx id on the source blockchain
     * @param _to               target wallet
     * @param _amount           transfer amount
     * @param _xTransferId      xtransfer id
     * @param _commissionAmount commission amount
     */
    event TxReport(
        address indexed _reporter,
        bytes32 _fromBlockchain,
        uint256 _txId,
        address _to,
        uint256 _amount,
        uint256 _xTransferId,
        uint256 _commissionAmount
    );

    /**
     * @dev triggered when final report is successfully submitted
     *
     * @param _to  target wallet
     * @param _id  xtransfer id
     */
    event XTransferComplete(address _to, uint256 _id);

    /**
     * @dev triggered when rewards were sent
     *
     * @param _from rewards sender
     * @param _amount  amount of tokens
     */
    event RewardsSent(address _from, uint256 _amount);

    /**
     * @dev initializes a new Bridge instance
     *
     * @param _maxLockLimit          maximum amount of tokens that can be locked in one transaction
     * @param _maxReleaseLimit       maximum amount of tokens that can be released in one transaction
     * @param _minLimit              minimum amount of tokens that can be transferred in one transaction
     * @param _limitIncPerBlock      how much the limit increases per block
     * @param _minRequiredReports    minimum number of reporters to report transaction before tokens can be released
     * @param _sendRewards           send rewards config
     * @param _token                 erc20 token
     */
    constructor(
        uint256 _maxLockLimit,
        uint256 _maxReleaseLimit,
        uint256 _minLimit,
        uint256 _limitIncPerBlock,
        uint8 _minRequiredReports,
        uint256 _commissionAmount,
        bytes memory _sendRewards,
        IERC20 _token
    )
        greaterThanZero(_maxLockLimit)
        greaterThanZero(_maxReleaseLimit)
        greaterThanZero(_minLimit)
        greaterThanZero(_limitIncPerBlock)
        greaterThanZero(_minRequiredReports)
        validExternalAddress(address(_token))
    {
        // validate input
        require(_minLimit <= _maxLockLimit && _minLimit <= _maxReleaseLimit, "ERR_INVALID_MIN_LIMIT");

        // the maximum limits, minimum limit, and limit increase per block
        maxLockLimit = _maxLockLimit;
        maxReleaseLimit = _maxReleaseLimit;
        minLimit = _minLimit;
        limitIncPerBlock = _limitIncPerBlock;
        minRequiredReports = _minRequiredReports;

        // send rewards
        SendRewardsConfig memory sendRewardsConfig = abi.decode(_sendRewards, (SendRewardsConfig));
        sendRewardsToBlockchain = sendRewardsConfig.toBlockchain;
        sendRewardsToAccount = sendRewardsConfig.toAccount;
        sendRewardsMaxLockLimit = sendRewardsConfig.maxLockLimit;

        // previous limit is _maxLimit, and previous block number is current block number
        prevLockLimit = _maxLockLimit;
        prevReleaseLimit = _maxReleaseLimit;
        prevLockBlockNumber = block.number;
        prevReleaseBlockNumber = block.number;

        // no need to validate number as it allowed to be 0
        commissionAmount = _commissionAmount;

        token = _token;
    }

    // validates that the caller is a reporter
    modifier reporterOnly {
        _reporterOnly();
        _;
    }

    // error message binary size optimization
    function _reporterOnly() internal view {
        require(reporters[msg.sender], "ERR_ACCESS_DENIED");
    }

    // allows execution only when x transfers are enabled
    modifier xTransfersAllowed {
        _xTransfersAllowed();
        _;
    }

    // error message binary size optimization
    function _xTransfersAllowed() internal view {
        require(xTransfersEnabled, "ERR_DISABLED");
    }

    // allows execution only when reporting is enabled
    modifier reportingAllowed {
        _reportingAllowed();
        _;
    }

    // error message binary size optimization
    function _reportingAllowed() internal view {
        require(reportingEnabled, "ERR_DISABLED");
    }
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // verifies that a value is greater than some amount
    modifier greaterEqualThanAmount(uint256 _value, uint256 _amount) {
        _greaterEqualThanAmount(_value, _amount);
        _;
    }

    // error message binary size optimization
    function _greaterEqualThanAmount(uint256 _value, uint256 _amount) internal pure {
        require(_value >= _amount, "ERR_VALUE_TOO_LOW");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    /**
     * @dev setter
     *
     * @param _maxLockLimit    new maxLockLimit
     */
    function setMaxLockLimit(uint256 _maxLockLimit) public onlyOwner greaterThanZero(_maxLockLimit) {
        maxLockLimit = _maxLockLimit;
    }

    /**
     * @dev setter
     *
     * @param _maxReleaseLimit    new maxReleaseLimit
     */
    function setMaxReleaseLimit(uint256 _maxReleaseLimit) public onlyOwner greaterThanZero(_maxReleaseLimit) {
        maxReleaseLimit = _maxReleaseLimit;
    }

    /**
     * @dev setter
     *
     * @param _minLimit    new minLimit
     */
    function setMinLimit(uint256 _minLimit) public onlyOwner greaterThanZero(_minLimit) {
        // validate input
        require(_minLimit <= maxLockLimit && _minLimit <= maxReleaseLimit, "ERR_INVALID_MIN_LIMIT");

        minLimit = _minLimit;
    }

    /**
     * @dev setter
     *
     * @param _limitIncPerBlock    new limitIncPerBlock
     */
    function setLimitIncPerBlock(uint256 _limitIncPerBlock) public onlyOwner greaterThanZero(_limitIncPerBlock) {
        limitIncPerBlock = _limitIncPerBlock;
    }

    /**
     * @dev setter
     *
     * @param _minRequiredReports    new minRequiredReports
     */
    function setMinRequiredReports(uint8 _minRequiredReports) public onlyOwner greaterThanZero(_minRequiredReports) {
        minRequiredReports = _minRequiredReports;
    }

    /**
     * @dev setter
     *
     * @param _commissionAmount    new commission amount
     */
    function setCommissionAmount(uint256 _commissionAmount) public onlyOwner {
        commissionAmount = _commissionAmount;
    }

    /**
     * @dev setter
     *
     * @param _blockchain    target blockchain where the rewards will be sent to
     */
    function setRewardsToBlockchain(bytes32 _blockchain) public onlyOwner {
        sendRewardsToBlockchain = _blockchain;
    }

    /**
     * @dev setter
     *
     * @param _toAccount    target account which the rewards will be sent to
     */
    function setRewardsToAccount(bytes32 _toAccount) public onlyOwner {
        sendRewardsToAccount = _toAccount;
    }

    /**
     * @dev setter
     *
     * @param _maxLockLimit    rewards max limit amount
     */
    function setRewardsMaxLockLimit(uint256 _maxLockLimit) public onlyOwner greaterThanZero(_maxLockLimit) {
        sendRewardsMaxLockLimit = _maxLockLimit;
    }

    /**
     * @dev allows the owner to set/remove reporters
     *
     * @param _reporters   array of reporters which their status is to be set
     * @param _active      array of booleans. true if the reporter is approved, false otherwise
     */
    function setReporters(address[] calldata _reporters, bool[] calldata _active) public onlyOwner {
        require(_reporters.length == _active.length, "missing active status to set for all reporters");
        for (uint16 reporterIndex = 0; reporterIndex < _reporters.length; reporterIndex++)
            reporters[_reporters[reporterIndex]] = _active[reporterIndex];
    }

    /**
     * @dev allows the owner enable/disable the xTransfer method
     *
     * @param _enable     true to enable, false to disable
     */
    function enableXTransfers(bool _enable) public onlyOwner {
        xTransfersEnabled = _enable;
    }

    /**
     * @dev allows the owner enable/disable the reportTransaction method
     *
     * @param _enable     true to enable, false to disable
     */
    function enableReporting(bool _enable) public onlyOwner {
        reportingEnabled = _enable;
    }

    /**
     * @dev claims tokens from a signer (calculated from provided signature) to be converted to tokens on another blockchain
     *
     * @param _toBlockchain    blockchain on which tokens will be issued
     * @param _to              address to send the tokens to
     * @param _amount          the amount of tokens to transfer
     * @param _deadline        permit deadline
     * @param _signer          address to claim tokens from
     * @param _v               ECDSA signature recovery identifier
     * @param _r               ECDSA signature number
     * @param _s               ECDSA signature number
     */
    function xTransfer(
        bytes32 _toBlockchain,
        bytes32 _to,
        uint256 _amount,
        uint256 _deadline,
        address _signer,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public xTransfersAllowed {
        // get the current lock limit
        uint256 currentLockLimit = getCurrentLockLimit();

        // require that; minLimit <= _amount <= currentLockLimit
        require(_amount >= minLimit && _amount <= currentLockLimit, "ERR_AMOUNT_NOT_IN_RANGE");

        // Permit function enables to give allowance to a spender, without a payment of the signer, due to the fact
        // that any account can call permit, provided that it has the signature (_v, _r, _s parameters).
        // Example: https://deweb-io.github.io/token/permit_demo.html
        ERC20Permit(address(token)).permit(_signer, address(this), _amount, _deadline, _v, _r, _s);

        lockTokens(_signer, _amount);

        // set the previous lock limit and block number
        prevLockLimit = currentLockLimit - _amount;
        prevLockBlockNumber = block.number;

        // emit XTransfer event
        emit XTransfer(_signer, _toBlockchain, _to, _amount, 0);
    }

   /**
     * @dev claims tokens from a signer to be converted to tokens on another blockchain (for a specific account)
     * @param _amount          the amount of tokens to transfer
    */
    function sendRewards(uint256 _amount) public xTransfersAllowed {
        require(_amount >= minLimit && _amount <= sendRewardsMaxLockLimit, "ERR_AMOUNT_NOT_IN_RANGE");

        lockTokens(msg.sender, _amount);

        // emit XTransfer event
        emit XTransfer(msg.sender, sendRewardsToBlockchain, sendRewardsToAccount, _amount, 0);

        // emit rewards sent event
        emit RewardsSent(msg.sender, _amount);
    }

    /**
     * @dev allows reporter to report transaction which occured on another blockchain
     *
     * @param _fromBlockchain  blockchain in which tokens were destroyed
     * @param _txId            transactionId of transaction thats being reported
     * @param _to              address to receive tokens
     * @param _amount          amount of tokens destroyed on another blockchain
     * @param _xTransferId     unique (if non zero) pre-determined id (unlike _txId which is determined after the transactions been mined)
     */
    function reportTx(
        bytes32 _fromBlockchain,
        uint256 _txId,
        address _to,
        uint256 _amount,
        uint256 _xTransferId
    ) public reporterOnly reportingAllowed validAddress(_to) greaterEqualThanAmount(_amount, commissionAmount) {
        // require that the transaction has not been reported yet by the reporter
        require(!reportedTxs[_txId][msg.sender], "ERR_ALREADY_REPORTED");

        // set reported as true
        reportedTxs[_txId][msg.sender] = true;

        Transaction storage txn = transactions[_txId];

        // If the caller is the first reporter, set the transaction details
        if (txn.numOfReports == 0) {
            txn.to = _to;
            txn.amount = _amount;
            txn.fromBlockchain = _fromBlockchain;

            if (_xTransferId != 0) {
                // verify uniqueness of xTransfer id to prevent overwriting
                require(transactionIds[_xTransferId] == 0, "ERR_TX_ALREADY_EXISTS");
                transactionIds[_xTransferId] = _txId;
            }
        } else {
            // otherwise, verify transaction details
            require(txn.to == _to && txn.amount == _amount && txn.fromBlockchain == _fromBlockchain, "ERR_TX_MISMATCH");

            if (_xTransferId != 0) {
                require(transactionIds[_xTransferId] == _txId, "ERR_TX_ALREADY_EXISTS");
            }
        }

        // increment the number of reports
        txn.numOfReports++;

        emit TxReport(msg.sender, _fromBlockchain, _txId, _to, _amount, _xTransferId, commissionAmount);

        // if theres enough reports, try to release tokens
        if (txn.numOfReports >= minRequiredReports) {
            require(!transactions[_txId].completed, "ERR_TX_ALREADY_COMPLETED");

            // set the transaction as completed
            transactions[_txId].completed = true;

            emit XTransferComplete(_to, _xTransferId);

            // update the current total commissions
            totalCommissions += commissionAmount;

            releaseTokens(_to, _amount - commissionAmount); // release amount minus commission amount
        }
    }

    /**
     * @dev gets x transfer amount by xTransferId (not txId)
     *
     * @param _xTransferId    unique (if non zero) pre-determined id (unlike _txId which is determined after the transactions been broadcasted)
     * @param _for            address corresponding to xTransferId
     *
     * @return amount that was sent in xTransfer corresponding to _xTransferId
     */
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256) {
        // xTransferId -> txId -> Transaction
        Transaction memory transaction = transactions[transactionIds[_xTransferId]];

        // verify that the xTransferId is for _for
        require(transaction.to == _for, "ERR_TX_MISMATCH");

        return transaction.amount;
    }

    /**
     * @dev method for calculating current lock limit
     *
     * @return the current maximum limit of tokens that can be locked
     */
    function getCurrentLockLimit() public view returns (uint256) {
        uint256 currentLockLimit = prevLockLimit + ((block.number - prevLockBlockNumber) * limitIncPerBlock);
        if (currentLockLimit > maxLockLimit) {
            return maxLockLimit;
        }

        return currentLockLimit;
    }

    /**
     * @dev method for calculating current release limit
     *
     * @return the current maximum limit of tokens that can be released
     */
    function getCurrentReleaseLimit() public view returns (uint256) {
        uint256 currentReleaseLimit = prevReleaseLimit + ((block.number - prevReleaseBlockNumber) * limitIncPerBlock);
        if (currentReleaseLimit > maxReleaseLimit) {
            return maxReleaseLimit;
        }

        return currentReleaseLimit;
    }

    /**
     * @dev claims and locks tokens from signer to be converted to tokens on another blockchain
     *
     * @param _sender  the address to lock tokens from
     * @param _amount  the amount of tokens to lock
     */
    function lockTokens(address _sender, uint256 _amount) private {
        // Do not allow amounts that can not be represented in EOS.
        require(_amount % 10**14 == 0, "ERR_AMOUNT_TOO_MANY_DECIMALS");
        token.transferFrom(_sender, address(this), _amount);

        emit TokensLock(_sender, _amount);
    }

    /**
     * @dev private method to release tokens held by the contract
     *
     * @param _to      the address to release tokens to
     * @param _amount  the amount of tokens to release
     */
    function releaseTokens(address _to, uint256 _amount) private {
        // get the current release limit
        uint256 currentReleaseLimit = getCurrentReleaseLimit();

        require(_amount >= minLimit, "ERR_AMOUNT_TOO_LOW");
        require(_amount <= currentReleaseLimit, "ERR_AMOUNT_TOO_HIGH");

        // update the previous release limit and block number
        prevReleaseLimit = currentReleaseLimit - _amount;
        prevReleaseBlockNumber = block.number;

        // no need to require, reverts on failure
        token.transfer(_to, _amount);

        emit TokensRelease(_to, _amount);
    }

    /**
     * @dev allows the owner to withdraw all commissions accumulated
     *
     * @param _to      the address to withdraw commissions to
     */
    function withdrawCommissions(address _to) public onlyOwner validAddress(_to) {
        // reset total commissions
        totalCommissions = 0;

        // no need to require, reverts on failure
        token.transfer(_to, totalCommissions);

        emit CommissionsWithdraw(_to, totalCommissions);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}