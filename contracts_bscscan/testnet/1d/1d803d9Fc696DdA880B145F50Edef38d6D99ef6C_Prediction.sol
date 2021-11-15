pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Prediction is Pausable {
    using SafeERC20 for IERC20;

    enum Position {UP, DOWN}
    enum Result {WAITING, UP, DOWN, DRAW}

    struct TokenVolume {
        uint256 totalAmount;
        uint256 upAmount;
        uint256 downAmount;
        uint256 wonAmount;
        uint256 lostAmount;
    }

    struct Round {
        uint256 epoch;
        uint256 startBlock;
        uint256 endBlock;
        uint256 openPrice;
        uint256 closePrice;
        mapping(address => TokenVolume) volumes;
        address[] listToken;
        Result result;
        bool binanceCalled;
    }

    struct PredictionInfo {
        Position position;
        mapping(address => uint256) volumes;
        bool claimed;
    }

    mapping(uint256 => Round) public rounds; // epoch -> round
    mapping(uint256 => mapping(address => PredictionInfo)) public predictionHistory; // epoch -> address -> PredictionInfo
    mapping(address => uint256[]) public userHistory; // address -> list epoch
    mapping(address => bool) public admins;
    mapping(address => bool) public operators;
    mapping(address => address) public parents;
    mapping(address => uint256) public feeRates; // rate/1000. Ex 15/1000 = 1.5%
    uint256[] public refRates; // rate/1000
    uint256 public defaultFeeRate = 60; // 60/1000 = 6%
    uint256 totalRef = 15; // Total 15/1000 = 1.5%
    uint256 addedEpoch = 0;

    address public fundWallet;
    address public dividendWallet;

    uint256 public startBlock;
    uint256 public roundDuration;
    uint256 public minPredictionAmount;

    event StartRound(uint256 indexed epoch, uint256 blockNumber,uint256 price);
    event EndRound(uint256 indexed epoch, uint256 price, string metadata);
    event Predict(address indexed sender, uint256 indexed epoch, uint256 amount, uint256 side);
    event Claim(address indexed sender, uint256 epoch, address token, uint256 amount);
    event Withdraw(address wallet, uint256 amount, address token);
    event MinPredictionAmountUpdated(uint256 indexed epoch, uint256 minPredictionAmount);
    event RewardsCalculated(uint256 indexed epoch, Result indexed result);

    constructor(
        address _fundWallet,
        address _dividendWallet,
        uint256 _roundDuration,
        uint256 _minPredictionAmount,
        uint256 _startBlock
    ) {
        admins[msg.sender] = true;
        operators[msg.sender] = true;

        fundWallet = _fundWallet;
        dividendWallet = _dividendWallet;
        roundDuration = _roundDuration;
        minPredictionAmount = _minPredictionAmount;
        if (minPredictionAmount == 0) {
            minPredictionAmount = 1e15;
        }

        totalRef = 15; // Total 1.5%
        refRates.push(5); // F1: 0.5%
        refRates.push(4); // F2: 0.4%
        refRates.push(3); // F3: 0.3%
        refRates.push(2); // F4: 0.2%
        refRates.push(1); // F5: 0.5%

        feeRates[address(0)] = 60; // 0.6% - Native token
        genesisStartRound(0, _startBlock);

        // default for testing purpose
        // fundWallet: 0xfe72617caDBBa6b0246c4d352603EfE56EF8905e
        // zero address: 0x0000000000000000000000000000000000000000
        feeRates[address(0xDd9814AB334D1d407d46B6E9D5761484B64F2419)] = 40;
        admins[address(0x8d6190EAd66aF422E78DA07D4382aC7A9E2e8B11)] = true;
        admins[address(0x8C454f4dEd84888Deb69a1f0649f148C3A05890B)] = true;
        operators[address(0x8C454f4dEd84888Deb69a1f0649f148C3A05890B)] = true;
        operators[address(0x8d6190EAd66aF422E78DA07D4382aC7A9E2e8B11)] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "admin: invalid permission");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "operator: invalid permission");
        _;
    }

    /**
     * @dev add admin address
     * callable by owner
     */
    function addAdmin(address _admin) public onlyAdmin {
        require(_admin != address(0), "Cannot be zero address");
        admins[_admin] = true;
        operators[_admin] = true;
    }

    /**
     * @dev add operator address
     * callable by admin
     */
    function addOperator(address _operator) public onlyAdmin {
        require(_operator != address(0), "Cannot be zero address");
        operators[_operator] = true;
    }

    /**
     * @dev set fund wallet address
     * callable by admin
     */
    function setFundWallet(address _fundWallet) public onlyAdmin {
        require(_fundWallet != address(0), "Cannot be zero address");
        fundWallet = _fundWallet;
    }

    /**
     * @dev set fund wallet address
     * callable by admin
     */
    function setDividendWallet(address _dividendWallet) public onlyAdmin {
        require(_dividendWallet != address(0), "Cannot be zero address");
        dividendWallet = _dividendWallet;
    }

    /**
     * @dev set fund wallet address
     * callable by admin
     */
    function setRefRates(uint256[] memory _refRates) public onlyAdmin {
        require(refRates.length == _refRates.length, "Ref rates must be same length");

        uint256 total = 0;
        for (uint256 index; index < _refRates.length; index++) {
            refRates[index] = _refRates[index];
            total += refRates[index];
        }

        totalRef = total;
    }

    /**
     * @dev set operation fee
     * callable by admin
     */
    function setOperationFee(uint256 rate, address token) public onlyAdmin {
        if (rate == 0) {
            rate = defaultFeeRate;
        }

        feeRates[token] = rate;
    }

    /**
     * @dev set round Duration
     * callable by admin
     */
    function setRoundDuration(uint256 _roundDuration) public onlyAdmin {
        uint256 currentEpoch = getCurrentEpoch();
        addedEpoch = currentEpoch;
        roundDuration = _roundDuration;
        startBlock = block.number;

        rounds[currentEpoch].endBlock = rounds[currentEpoch].startBlock + roundDuration;
    }

    /**
     * @dev set minPredictionAmount
     * callable by admin
     */
    function setMinPredictionAmount(uint256 _minPredictionAmount) public onlyAdmin {
        minPredictionAmount = _minPredictionAmount;

        emit MinPredictionAmountUpdated(getCurrentEpoch(), minPredictionAmount);
    }

    /**
     * @dev Start genesis round (always round 0)
     */
    function genesisStartRound(uint256 price, uint256 _startBlock) public onlyAdmin {
//        require(_startBlock >= block.number, "Cannot set start block");
        startBlock = _startBlock;
        rounds[0].startBlock = startBlock;
        rounds[0].endBlock = rounds[0].startBlock + roundDuration;
        rounds[0].openPrice = price;
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function endRound(uint256 epoch, uint256 currentPrice, string memory metadata) public onlyOperator {
        require(rounds[epoch].binanceCalled == false, "Round has ended");
        require(rounds[epoch].endBlock < block.number, "Round has not ended");

        // end current round
        rounds[epoch].closePrice = currentPrice;
        rounds[epoch].binanceCalled = true;

        // next round
        epoch = epoch + 1;
        rounds[epoch].startBlock = rounds[epoch - 1].endBlock + 1;
        rounds[epoch].endBlock = rounds[epoch].startBlock + roundDuration;
        rounds[epoch].openPrice = currentPrice;

        // calculate reward for current round (Now is previous round)
        _calculateRewards(epoch - 1);

        emit EndRound(epoch, currentPrice, metadata);
    }

    function predict(uint256 epoch, uint256 side, uint256 amount, address token, address parent) public payable whenNotPaused {
        if (token == address(0)) {
            amount = msg.value;
        }

        require(side == 0 || side == 1, "Invalid side"); // 0 is UP, 1 is DOWN
        require(amount >= minPredictionAmount, "Prediction amount must be greater than minPredictionAmount");
        require(epoch == getCurrentEpoch() + 1, "Round not matched");
        require(predictionHistory[epoch][msg.sender].volumes[token] == 0, "Can only bet once per round");
        require(feeRates[token] > 0, "Token is not accepted");

        // update parent
        if (parents[msg.sender] == address(0)) {
            if (parent == address(0)) {
                parent = fundWallet; // parent is zero
            } else {
                parents[msg.sender] = parent; // update new parent
            }
        } else {
            parent = parents[msg.sender]; // cannot update parent
        }

        if (parent == address(0)) {
            parent = fundWallet;
        }

        uint256 operationFee = feeRates[token];
        uint256 predictionAmount = amount - totalRef * amount / 1000 - amount * operationFee / 1000;

        _forwardRefs(amount, token); // forward refs
        _forwardFund(amount * operationFee / 2 / 1000, dividendWallet, token); // forward dividend with 1/2 fee rate
        _forwardFund(amount * operationFee / 2 / 1000, fundWallet, token); // forward dev with 1/2 fee rate
        _forwardFund(predictionAmount, address(this), token); // forward fund to contract

        // update round data
        Round storage round = rounds[epoch];
        Position position = Position.UP;
        if (round.volumes[token].totalAmount == 0) {
            round.listToken.push(token);
        }

        round.volumes[token].totalAmount += predictionAmount;
        if (side == 0) { // UP
            round.volumes[token].upAmount += predictionAmount;
        } else {
            round.volumes[token].downAmount += predictionAmount;
            position = Position.DOWN;
        }

        // update user data
        PredictionInfo storage info = predictionHistory[epoch][msg.sender];
        info.position = position;
        info.volumes[token] = predictionAmount;
        userHistory[msg.sender].push(epoch);

        emit Predict(msg.sender, epoch, amount, side);
    }

    /**
     * @dev Claim reward
     */
    function claim(uint256 epoch) public {
        require(epoch > 0, "Cannot claim first round");
        require(rounds[epoch].startBlock != 0, "Round has not started");
        require(block.number > rounds[epoch].endBlock, "Round has not ended");
        require(!predictionHistory[epoch][msg.sender].claimed, "Rewards claimed");

        Round storage round = rounds[epoch];
        PredictionInfo storage info = predictionHistory[epoch][msg.sender];

        for (uint256 index = 0; index < round.listToken.length; index++) {
            address token = round.listToken[index];
            uint256 reward = 0;
            uint256 amount = info.volumes[token];

            Position position = info.position;
            uint256 lost = round.volumes[token].lostAmount;
            uint256 won = round.volumes[token].wonAmount;

            if (round.result == Result.DRAW) {
                // refund
                info.claimed = true;
                _claimFund(amount, msg.sender, token);
                emit Claim(msg.sender, epoch, token, amount);
                continue;
            }

            if (round.result == Result.UP && position == Position.UP ||
            round.result == Result.DOWN && position == Position.DOWN) {
                if (lost == 0) {
                    // refund
                    info.claimed = true;
                    _claimFund(amount, msg.sender, token);
                    emit Claim(msg.sender, epoch, token, amount);
                    continue;
                }

                // it ensure to divide by Zero
                if (won == 0) {
                    continue;
                }

                // pay reward: 94% of lost
                reward = amount * lost * (1000 - defaultFeeRate) / 1000 / won  + amount;
                info.claimed = true;
                _claimFund(reward, msg.sender, token);
                emit Claim(msg.sender, epoch, token, reward);
                continue;
            }

            // cannot set price -> refund
            if (round.result == Result.WAITING &&
            round.endBlock + 100 * roundDuration <= block.number) {
                info.claimed = true;
                _claimFund(amount, msg.sender, token);
                emit Claim(msg.sender, epoch, token, amount);
                continue;
            }
        }
    }

    /**
     * @dev Withdraw all rewards
     * callable by admin
     */
    function withdraw(uint256 amount, address token) public onlyAdmin {
        _claimFund(amount, fundWallet, token);
        emit Withdraw(fundWallet, amount, token);
    }

    /**
     * @dev Return round epochs that a user has participated
     */
    function getUserHistory(
        address user,
        uint256 cursor,
        uint256 size
    ) public view returns (uint256[] memory, uint256, uint256) {
        uint256 length = size;
        if (length > userHistory[user].length - cursor) {
            length = userHistory[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userHistory[user][cursor + i];
        }

        return (values, cursor + length, userHistory[user].length);
    }

    /**
     * @dev Return round total epochs
     */
    function getTotalRound(address user) public view returns (uint256) {
        return userHistory[user].length;
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(uint256 epoch) internal {
        require(rounds[epoch].result == Result.WAITING, "Rewards calculated");
        Round storage round = rounds[epoch];

        // UP wins
        if (round.closePrice > round.openPrice) {
            round.result = Result.UP;
        }
        // DOWN wins
        else if (round.closePrice < round.openPrice) {
            round.result = Result.DOWN;
        }
        // DRAW
        else {
            round.result = Result.DRAW;
        }

        for (uint256 index = 0; index < round.listToken.length; index++) {
            address token = round.listToken[index];
            uint256 fee = feeRates[token];

            if (round.result == Result.DRAW) {
                round.volumes[token].wonAmount = 0;
                round.volumes[token].lostAmount = 0;
                continue;
            }

            if (round.result == Result.UP) {
                round.volumes[token].wonAmount = round.volumes[token].upAmount;
                round.volumes[token].lostAmount = round.volumes[token].downAmount - round.volumes[token].downAmount * fee / 1000;
                continue;
            }

            if (round.result == Result.DOWN) {
                round.volumes[token].wonAmount = round.volumes[token].downAmount;
                round.volumes[token].lostAmount = round.volumes[token].upAmount - round.volumes[token].upAmount * fee / 1000;
                continue;
            }
        }

        emit RewardsCalculated(epoch, round.result);
    }

    function _forwardRefs(uint256 amount, address token) internal {
        uint256 levels = refRates.length;
        uint256 devAmount = 0;

        for (uint256 level = 0; level < levels; level++) {
            address parent = parents[msg.sender];
            uint256 fee = refRates[level] * amount / 1000;

            if (parent != address(0)) {
                _forwardFund(fee, parent, token);
                continue;
            }

            devAmount += fee;
        }

        if (devAmount > 0) {
            _forwardFund(devAmount, fundWallet, token);
        }
    }

    // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
    function _forwardFund(uint256 amount, address to, address token) internal {
        if (token == address(0)) { // native token (BNB)
            (bool success, ) = to.call{gas: 23000, value: amount}("");
            require(success, "TransferHelper: NATIVE_TOKEN_TRANSFER_FAILED");

            return;
        }

        IERC20(token).safeTransferFrom(msg.sender, to, amount);
    }

    function _claimFund(uint256 amount, address to, address token) internal {
        if (token == address(0)) { // native token (BNB)
            payable(to).transfer(amount);
            return;
        }

        IERC20(token).safeTransfer(to, amount);
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (roundDuration == 0 || startBlock == 0 || block.number <= startBlock) {
            return 0;
        }

        return (block.number - startBlock) / roundDuration + addedEpoch;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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

