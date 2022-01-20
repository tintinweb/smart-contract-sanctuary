//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;
// Imported OZ helper contracts
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// Inherited allowing for ownership of contract
import "@openzeppelin/contracts/access/Ownable.sol";
// Allows for intergration with ChainLink VRF
import "./IRandomNumberGenerator.sol";
// Interface for Lottery NFT to mint tokens
import "./INFTP.sol";
// Allows for time manipulation. Set to 0x address on test/mainnet deploy
import "./Testable.sol";
// Safe math
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeMath16.sol";
import "./SafeMath8.sol";
// import "hardhat/console.sol";
contract Lottery is Ownable, Initializable, Testable {
    // Libraries
    // Safe math
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;
    // Safe ERC20
    using SafeERC20 for IERC20;
    // Address functionality
    using Address for address;

    // State variables
    // Instance of NFTP token (collateral currency for lotto)
    INFTP internal nftp_;
    // Storing of the randomness generator
    IRandomNumberGenerator internal randomGenerator_;
    // Request ID for random number
    bytes32 internal requestId_;
    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    // Lottery size
    uint8 public sizeOfLottery_;
    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The lottery has been closed and the numbers drawn
    }

    enum LotteryType {
        Public, // Weighted Distribution
        Community //Equally Distributed Probability
    }
    address[] whitelist;
    // All the needed info around a lottery
    struct Coefficient {
        string name; //prizeClass
        uint256 gteq_amount; //greater than or equal to amount
        uint256 factor; //RNG distribution factor
    }

    struct LottoInfo {
        uint256 lotteryId; // ID for lotto
        Status lotteryStatus; // Status for lotto
        LotteryType lotteryType;
        Coefficient[] coefficients; //
        uint256 winningSize;
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        address[] stakeholders;
        mapping(address => uint256) weightedAddresses;
        address[] primaryWinnings;
        mapping(address => bool) primaryWinningFlags;
        address[] secondaryWinnings;
        mapping(address => bool) secondaryWinningFlags;
    }
    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event LotteryOpen(uint256 lotteryId);

    event LotteryClose(uint256 lotteryId);
    event Whitelisted(address _address);
    event Unwhitelisted(address _address);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "Only random generator"
        );
        _;
    }
    modifier onlyCompletedLotto(uint256 _lotteryId) {
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Completed,
            "Lottery State incorrect for get results"
        );
        _;
    }

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(address _nftp, address _timer) public Testable(_timer) {
        require(_nftp != address(0), "NFTP Contracts cannot be 0 address");
        nftp_ = INFTP(_nftp);
    }

    function initialize(address _IRandomNumberGenerator)
        external
        initializer
        onlyOwner
    {
        require(
            _IRandomNumberGenerator != address(0),
            "Contracts cannot be 0 address"
        );
        randomGenerator_ = IRandomNumberGenerator(_IRandomNumberGenerator);
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------
    function getLottoStatus(uint256 _lotteryId) external view returns (Status) {
        return (allLotteries_[_lotteryId].lotteryStatus);
    }

    function getLottoStakeholders(uint256 _lotteryId)
        external
        view
        returns (address[] memory)
    {
        return (allLotteries_[_lotteryId].stakeholders);
    }

    function getLottoStakeholderWeight(uint256 _lotteryId, address stakeholder)
        external
        view
        returns (uint256)
    {
        return (allLotteries_[_lotteryId].weightedAddresses[stakeholder]);
    }

    function getLottoPrimaryWinnings(uint256 _lotteryId)
        external
        view
        onlyCompletedLotto(_lotteryId)
        returns (address[] memory)
    {
        return (allLotteries_[_lotteryId].primaryWinnings);
    }

    function getLottoSecondaryWinnings(uint256 _lotteryId)
        external
        view
        onlyCompletedLotto(_lotteryId)
        returns (address[] memory)
    {
        return (allLotteries_[_lotteryId].secondaryWinnings);
    }

    function isLottoPrimaryWinning(uint256 _lotteryId, address _address)
        external
        view
        onlyCompletedLotto(_lotteryId)
        returns (bool)
    {
        return (allLotteries_[_lotteryId].primaryWinningFlags[_address]);
    }

    function isLottoSecondaryWinning(uint256 _lotteryId, address _address)
        external
        view
        onlyCompletedLotto(_lotteryId)
        returns (bool)
    {
        return (allLotteries_[_lotteryId].secondaryWinningFlags[_address]);
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOwner)

    function drawWinningNumbers(uint256 _lotteryId) external onlyOwner {
        // Checks that the lottery is past the closing block
        require(
            allLotteries_[_lotteryId].closingTimestamp <= getCurrentTime(),
            "Cannot set winning numbers during lottery"
        );
        // Checks lottery numbers have not already been drawn
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Open,
            "Lottery State incorrect for draw"
        );
        // Sets lottery status to closed
        allLotteries_[_lotteryId].lotteryStatus = Status.Closed;

        //copy stakeholder state
        if (allLotteries_[_lotteryId].lotteryType == LotteryType.Public) {
            allLotteries_[_lotteryId].stakeholders = nftp_.getStakeholders();
            for (
                uint256 s = 0;
                s < allLotteries_[_lotteryId].stakeholders.length;
                s += 1
            ) {
                address staked_address;
                staked_address = allLotteries_[_lotteryId].stakeholders[s];
                allLotteries_[_lotteryId].weightedAddresses[staked_address] = 1;
                for (
                    uint256 i = 0;
                    i < allLotteries_[_lotteryId].coefficients.length;
                    i += 1
                ) {
                    if (
                        (allLotteries_[_lotteryId]
                            .coefficients[i]
                            .gteq_amount <= nftp_.stakeOf(staked_address)) &&
                        (allLotteries_[_lotteryId].coefficients[i].factor >
                            allLotteries_[_lotteryId].weightedAddresses[
                                staked_address
                            ])
                    ) {
                        allLotteries_[_lotteryId].weightedAddresses[
                                staked_address
                            ] = allLotteries_[_lotteryId]
                            .coefficients[i]
                            .factor;
                    }
                }
            }
        } else {
            //Case 2: community sale - whitelisted with equal distribution
            allLotteries_[_lotteryId].stakeholders = whitelist;
            for (
                uint256 s = 0;
                s < allLotteries_[_lotteryId].stakeholders.length;
                s += 1
            ) {
                address staked_address;
                staked_address = allLotteries_[_lotteryId].stakeholders[s];
                allLotteries_[_lotteryId].weightedAddresses[staked_address] = 1;
            }
        }

        // Requests a random number from the generator
        requestId_ = randomGenerator_.getRandomNumber(_lotteryId);
        // Emits that random number has been requested
        emit RequestNumbers(_lotteryId, requestId_);
    }

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external onlyRandomGenerator {
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Closed,
            "Draw numbers first"
        );
        if (requestId_ == _requestId) {
            allLotteries_[_lotteryId].lotteryStatus = Status.Completed;
            allLotteries_[_lotteryId].primaryWinnings = _split(
                _randomNumber,
                _lotteryId,
                0
            );
            allLotteries_[_lotteryId].secondaryWinnings = _split(
                _randomNumber,
                _lotteryId,
                allLotteries_[_lotteryId].winningSize
            );
        }

        emit LotteryClose(_lotteryId);
    }

    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
    function createNewLotto(
        uint256 _startingTimestamp,
        uint256 _closingTimestamp,
        LotteryType _lotteryType,
        uint256 _winningSize,
        Coefficient[] calldata _coefficients
    ) external onlyOwner returns (uint256 lotteryId) {
        require(
            _startingTimestamp != 0 && _startingTimestamp < _closingTimestamp,
            "Timestamps for lottery invalid"
        );
        // Incrementing lottery ID
        lotteryIdCounter_ = lotteryIdCounter_.add(1);
        lotteryId = lotteryIdCounter_;

        Status lotteryStatus;
        if (_startingTimestamp >= getCurrentTime()) {
            lotteryStatus = Status.Open;
        } else {
            lotteryStatus = Status.NotStarted;
        }
        // Saving data in struct
        LottoInfo storage newLottery = allLotteries_[lotteryId];
        newLottery.lotteryId = lotteryId;
        newLottery.lotteryStatus = lotteryStatus;
        newLottery.lotteryType = _lotteryType;
        for (uint256 i = 0; i < _coefficients.length; i += 1) {
            newLottery.coefficients.push(_coefficients[i]);
        }
        newLottery.winningSize = _winningSize;
        newLottery.startingTimestamp = _startingTimestamp;
        newLottery.closingTimestamp = _closingTimestamp;

        // Emitting important information around new lottery.
        emit LotteryOpen(lotteryId);
    }

    function openLottery(uint256 _lotteryId) external onlyOwner {
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.NotStarted &&
                allLotteries_[_lotteryId].startingTimestamp >= getCurrentTime(),
            "Lottery not in state for open"
        );
        allLotteries_[_lotteryId].lotteryStatus = Status.Open;
        // Emitting event with all information
        emit LotteryOpen(_lotteryId);
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    struct WeightedRandom {
        uint256 cummulatedSum;
        uint256[] Prob;
        uint256[] Alias;
        uint256[] p;
        uint256[] Small;
        uint256[] Large;
    }

    function _split(
        uint256 _randomNumber,
        uint256 _lotteryId,
        uint256 paddedSize
    ) internal returns (address[] memory) {
        // Temporary storage for winning numbers
        LottoInfo storage lotterySetting = allLotteries_[_lotteryId];
        uint256 sizeOfLottery = lotterySetting.winningSize;
        address[] memory winningAddresses = new address[](sizeOfLottery);
        // build address list
        // Loops the size of the number of tickets in the lottery
        for (uint256 i = 0; i < sizeOfLottery; i++) {
            if (lotterySetting.stakeholders.length <= i + paddedSize) {
                break;
            }
            uint256 populationSize = lotterySetting.stakeholders.length -
                i -
                paddedSize;
            WeightedRandom memory result = _calcProb(
                lotterySetting,
                populationSize
            );
            // 2. Generation:
            // Encodes the random number with its position in loop
            bytes32 hashOfRandom = keccak256(
                abi.encodePacked(_randomNumber, i)
            );
            // Casts random number hash into uint256
            uint256 numberRepresentation = uint256(hashOfRandom);
            // Sets the winning number position to a uint16 of random hash number

            // Generate a fair die roll from an n-sided die; call the side i.
            // Generate a uniformly-random value x in the range [0,1).
            // Return ⌊xn⌋.
            uint256 position = numberRepresentation.mod(populationSize);

            // Flip a biased coin that comes up heads with probability Prob[i].
            // Generate a uniformly-random value x in the range [0,1).
            // If x<pheads, return "heads."
            // If x≥pheads, return "tails."
            // If the coin comes up "heads," return i.
            // Otherwise, return Alias[i].
            uint256 biased = numberRepresentation.mod(result.cummulatedSum);
            uint256 winningPosition;

            if (biased < result.Prob[position]) {
                winningPosition = position;
            } else {
                winningPosition = result.Alias[position];
            }
            winningAddresses[i] = lotterySetting.stakeholders[winningPosition];
            // Swap winningPosition with last item
            lotterySetting.stakeholders[winningPosition] = lotterySetting
                .stakeholders[populationSize.sub(1)];
            lotterySetting.stakeholders[
                populationSize.sub(1)
            ] = winningAddresses[i];
            if (paddedSize == 0) {
                lotterySetting.primaryWinningFlags[winningAddresses[i]] = true;
            } else {
                lotterySetting.secondaryWinningFlags[
                    winningAddresses[i]
                ] = true;
            }
        }
        return winningAddresses;
    }

    function _calcProb(LottoInfo storage lotterySetting, uint256 populationSize)
        internal
        view
        returns (WeightedRandom memory)
    {
        // 1. initialization
        WeightedRandom memory result = WeightedRandom({
            cummulatedSum: 0,
            Alias: new uint256[](populationSize),
            Prob: new uint256[](populationSize),
            p: new uint256[](populationSize),
            Small: new uint256[](populationSize),
            Large: new uint256[](populationSize)
        });
        // cumullative total
        uint256 k;
        for (k = 0; k < populationSize; k++) {
            result.cummulatedSum = result.cummulatedSum.add(
                lotterySetting.weightedAddresses[lotterySetting.stakeholders[k]]
            );
        }
        //Create arrays Alias and Prob, each of size n.
        //Create two worklists, Small and Large. (Small from 0->sm, Large from 0->la, with reversed index inside common array)
        uint256 sm = 0;
        uint256 la = 0;

        //Multiply each probability by n.
        for (k = 0; k < populationSize; k++) {
            address stake_k = lotterySetting.stakeholders[k];
            result.p[k] = lotterySetting.weightedAddresses[stake_k].mul(
                populationSize
            );

            // For each scaled probability pi:
            // If pi<1, add i to Small.
            // Otherwise (pi≥1), add i to Large.
            if (result.p[k] < result.cummulatedSum) {
                sm++;
                result.Small[sm - 1] = k;
            } else {
                la++;
                result.Large[la - 1] = k;
            }
        }
        // (Large might be emptied first)
        while (sm != 0 && la != 0) {
            uint256 l = result.Small[sm - 1];
            sm--;
            uint256 g = result.Large[la - 1];
            la--;
            result.Prob[l] = result.p[l];
            result.Alias[l] = g;

            // Set pg:=(pg+pl)−1. (This is a more numerically stable option.)
            result.p[g] = result.p[g].add(result.p[l]).sub(
                result.cummulatedSum
            );

            if (result.p[g] < result.cummulatedSum) {
                sm++;
                result.Small[sm - 1] = g;
            } else {
                la++;
                result.Large[la - 1] = g;
            }
        }
        while (la != 0) {
            uint256 g = result.Large[la - 1];
            la--;
            result.Prob[g] = result.cummulatedSum;
        }
        while (sm != 0) {
            uint256 l = result.Small[sm - 1];
            sm--;
            result.Prob[l] = result.cummulatedSum;
        }
        return result;
    }

    // ---------- WHITELIST ----------

    /**
     * @notice A method to check if an address is in whitelist.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is in whitelist,
     * and if so its position in the whitelist array.
     */
    function isWhitelisted(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < whitelist.length; s += 1) {
            if (_address == whitelist[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add to whitelist.
     * @param _address The address to add.
     */
    function addWhitelisted(address _address) external onlyOwner {
        (bool _isWhitelisted, ) = isWhitelisted(_address);
        if (!_isWhitelisted) {
            whitelist.push(_address);
            emit Whitelisted(_address);
        }
    }

    /**
     * @notice A method to remove from whitelist.
     * @param _address The address to remove.
     */
    function removeWhitelisted(address _address) external onlyOwner {
        (bool _isWhitelisted, uint256 s) = isWhitelisted(_address);
        if (_isWhitelisted) {
            whitelist[s] = whitelist[whitelist.length - 1];
            whitelist.pop();
            emit Unwhitelisted(_address);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IRandomNumberGenerator {

    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(
        uint256 lotteryId
    ) 
        external 
        returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
// Imported OZ helper contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTP is IERC20 {
    function getStakeholders()
    external
    view
    returns(address[] memory);
    
    function stakeOf(address _stakeholder)
    external
    view
    returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
pragma solidity >= 0.6.0;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 32 bit integers.
 */
library SafeMath16 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
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
  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint16 c = a - b;

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
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint16 c = a * b;
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
  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint16 c = a / b;
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
  function mod(uint16 a, uint16 b) internal pure returns (uint16) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 32 bit integers.
 */
library SafeMath8 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
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
  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint8 c = a - b;

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
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint8 c = a * b;
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
  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint8 c = a / b;
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
  function mod(uint8 a, uint8 b) internal pure returns (uint8) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
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
pragma solidity >= 0.6.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = block.timestamp; 
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}