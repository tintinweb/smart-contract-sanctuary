pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IMinterToken.sol";

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
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 openPrice;
        uint256 closePrice;
        mapping(address => TokenVolume) volumes;
        address[] listToken;
        address[] listUserUp;
        address[] listUserDown;
        uint256 rand;
        address luckyUser;
        Result result;
        bool binanceCalled;
    }

    struct PredictionInfo {
        mapping(address => uint256) up;
        mapping(address => uint256) down;
        bool participated;
        bool claimed;
        bool luck;
    }

    struct RefInfo {
        uint256 total;
        mapping(address => uint256) totalRefEarned;
        mapping(address => uint256) totalRefClaimed;
        address[] listToken;
    }

    struct DividendInfo {
        mapping(address => uint256) total;
        mapping(address => uint256) totalWithdrawal;
        address[] listToken;
    }

    mapping(uint256 => Round) public rounds; // epoch -> round
    mapping(uint256 => mapping(address => PredictionInfo)) public predictionHistory; // epoch -> address -> PredictionInfo
    mapping(address => uint256[]) public userHistory; // address -> list epoch
    mapping(address => bool) public admins;
    mapping(address => address) public parents;
    mapping(address => RefInfo) public refs;
    mapping(address => uint256) public feeRates; // rate/1000. Ex 15/1000 = 1.5%
    mapping(address => uint256) public minPredictionAmount;
    mapping(address => uint256) public minterVol;
    uint256[] public refRates; // rate/1000
    uint256 public defaultFeeRate = 60; // 60/1000 = 6%
    uint256 totalRef = 15; // Total 15/1000 = 1.5%
    uint256 addedEpoch = 0;
    uint256 mintTokenAmount = 8 * 10 ** 18; // 8 token

    IMinterToken public mintedToken;
    DividendInfo private dividendInfo;
    uint256 public startTimestamp;
    uint256 public roundDuration;

    event StartRound(uint256 indexed epoch, uint256 blockNumber,uint256 price);
    event EndRound(uint256 indexed epoch, uint256 price, string metadata);
    event Predict(address indexed sender, uint256 indexed epoch, uint256 amount, uint256 side, address token);
    event Claim(address indexed sender, uint256 epoch, address token, uint256 amount);
    event ClaimRef(address indexed user, address token, uint256 amount);
    event ClaimDividend(address wallet, uint256 amount, address token);
    event Withdraw(address wallet, uint256 amount, address token);
    event MinPredictionAmountUpdated(uint256 indexed epoch, uint256 minPredictionAmount, address token);
    event MinterVolUpdated(uint256 indexed epoch, uint256 minPredictionAmount, address token);
    event RewardsCalculated(uint256 indexed epoch, Result indexed result, uint256 openPrice, uint256 closePrice, address[] tokens, uint256[] up, uint256[] down);

    constructor(
        address _mintedToken,
        uint256 _roundDuration,
        uint256 _startTimestamp
    ) {
        admins[msg.sender] = true;
        mintedToken = IMinterToken(_mintedToken);
        roundDuration = _roundDuration;

        totalRef = 15; // Total 1.5%
        refRates.push(5); // F1: 0.5%
        refRates.push(4); // F2: 0.4%
        refRates.push(3); // F3: 0.3%
        refRates.push(2); // F4: 0.2%
        refRates.push(1); // F5: 0.1%

        genesisStartRound(0, _startTimestamp);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "admin: invalid permission");
        _;
    }

    /**
     * @dev add admin address
     * callable by owner
     */
    function addAdmin(address _admin) public onlyAdmin {
        require(_admin != address(0), "Cannot be zero address");
        admins[_admin] = true;
    }

    /**
     * @dev set mint token address
     * callable by admin
     */
    function setMintedToken(address _token) public onlyAdmin {
        require(_token != address(0), "Cannot be zero address");
        mintedToken = IMinterToken(_token);
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

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev set round Duration
     * callable by admin
     */
    function setRoundDuration(uint256 _roundDuration) public onlyAdmin {
        uint256 currentEpoch = getCurrentEpoch();
        addedEpoch = currentEpoch;
        roundDuration = _roundDuration;
        startTimestamp = block.timestamp;

        rounds[currentEpoch].endTimestamp = rounds[currentEpoch].startTimestamp + roundDuration;
    }

    /**
     * @dev set minPredictionAmount
     * callable by admin
     */
    function setMinPredictionAmount(uint256 _minPredictionAmount, address _token) public onlyAdmin {
        minPredictionAmount[_token] = _minPredictionAmount;

        emit MinPredictionAmountUpdated(getCurrentEpoch(), _minPredictionAmount, _token);
    }

    /**
     * @dev set minterVol
     * callable by admin
     */
    function setMinterVol(uint256 amount, address token) public onlyAdmin {
        minterVol[token] = amount;

        emit MinterVolUpdated(getCurrentEpoch(), amount, token);
    }

    /**
     * @dev Withdraw all rewards
     * callable by admin
     */
    function withdraw(address to, uint256 amount, address token) public onlyAdmin {
        require(to != address(0), "Cannot be zero address");

        _claimFund(amount, to, token);
        emit Withdraw(to, amount, token);
    }

    /**
     * @dev Withdraw all rewards with per mile
     * callable by admin
     */
    function withdrawToDividend(address dividendWallet) public onlyAdmin {
        require(dividendWallet != address(0), "Cannot be zero address");

        for (uint256 index = 0; index < dividendInfo.listToken.length; index++) {
            address token = dividendInfo.listToken[index];
            uint256 amount = dividendInfo.total[token] - dividendInfo.totalWithdrawal[token];

            if (amount > 0) {
                _claimFund(amount, dividendWallet, token);
                dividendInfo.totalWithdrawal[token] += amount;
                emit ClaimDividend(dividendWallet, amount, token);
            }
        }
    }

    /**
     * @dev Start genesis round (always round 0)
     */
    function genesisStartRound(uint256 price, uint256 _startTimestamp) public onlyAdmin {
        startTimestamp = _startTimestamp;
        rounds[0].startTimestamp = startTimestamp;
        rounds[0].endTimestamp = rounds[0].startTimestamp + roundDuration; // not inclusive
        rounds[0].openPrice = price;
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function endRound(uint256 epoch, uint256 currentPrice, string memory metadata) public onlyAdmin {
        require(rounds[epoch].binanceCalled == false, "Round has ended");
        require(epoch < getCurrentEpoch(), "Round has not ended");

        // end current round
        rounds[epoch].closePrice = currentPrice;
        rounds[epoch].binanceCalled = true;

        // next round
        epoch = epoch + 1;
        rounds[epoch].startTimestamp = rounds[epoch - 1].endTimestamp; // inclusive
        if (rounds[epoch].startTimestamp == 0 && addedEpoch == 0) { // backup timestamp
            rounds[epoch].startTimestamp = epoch * roundDuration + startTimestamp;
        }
        rounds[epoch].endTimestamp = rounds[epoch].startTimestamp + roundDuration;
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
        require(amount >= minPredictionAmount[token], "Prediction amount must be greater than minPredictionAmount");
        require(epoch == getCurrentEpoch() + 1, "Round not matched");
//        require(predictionHistory[epoch][msg.sender].participated == false, "Can only bet once per round");
        require(feeRates[token] > 0, "Token is not accepted");

        uint256 predictionAmount = amount - totalRef * amount / 1000;
        _forwardRefs(amount, token, parent); // forward refs
        _forwardFund(amount, address(this), token); // forward all fund to contract

        // update round data
        Round storage round = rounds[epoch];
        if (round.volumes[token].totalAmount == 0) {
            round.listToken.push(token);
        }

        // update user data
        PredictionInfo storage info = predictionHistory[epoch][msg.sender];

        round.volumes[token].totalAmount += predictionAmount;
        if (side == 0) { // UP
            round.volumes[token].upAmount += predictionAmount;
            if (info.up[token] == 0) {
                round.listUserUp.push(msg.sender);
            }
            info.up[token] += predictionAmount;
        } else {
            round.volumes[token].downAmount += predictionAmount;
            if (info.down[token] == 0) {
                round.listUserDown.push(msg.sender);
            }
            info.down[token] += predictionAmount;
        }

        if (!info.participated) {
            userHistory[msg.sender].push(epoch);
            info.participated = true;
        }

        emit Predict(msg.sender, epoch, amount, side, token);
    }

    /**
     * @dev Claim reward
     */
    function claim(uint256 epoch) public {
        require(epoch < getCurrentEpoch(), "Round has not ended");

        Round storage round = rounds[epoch];
        PredictionInfo storage info = predictionHistory[epoch][msg.sender];

        require(!info.claimed, "Rewards claimed");
        require(info.participated, "User has not participated this round");

        for (uint256 index = 0; index < round.listToken.length; index++) {
            address token = round.listToken[index];
            uint256 reward = 0;
            uint256 amountUp = info.up[token];
            uint256 amountDown = info.down[token];
            if (amountUp + amountDown == 0) { // user not predict with this token
                continue;
            }

            uint256 lost = round.volumes[token].lostAmount;
            uint256 won = round.volumes[token].wonAmount;

            if (round.result == Result.DRAW) {
                // refund
                info.claimed = true;
                _claimFund(amountUp + amountDown, msg.sender, token);
                emit Claim(msg.sender, epoch, token, amountUp + amountDown);

                if (info.luck) {
                    mintedToken.mint(msg.sender, mintTokenAmount);
                }
                return;
            }

            // won up
            if (round.result == Result.UP && amountUp > 0) {
                if (lost == 0) {
                    // refund
                    info.claimed = true;
                    _claimFund(amountUp, msg.sender, token);
                    emit Claim(msg.sender, epoch, token, amountUp);

                    if (info.luck) {
                        mintedToken.mint(msg.sender, mintTokenAmount);
                    }
                    return;
                }

                if (won == 0) {
                    continue;
                }

                // pay reward
                reward = amountUp * lost / won  + amountUp;
                info.claimed = true;
                _claimFund(reward, msg.sender, token);
                emit Claim(msg.sender, epoch, token, reward);

                if (info.luck) {
                    mintedToken.mint(msg.sender, mintTokenAmount);
                }
                return;
            }

            // won down
            if (round.result == Result.DOWN && amountDown > 0) {
                if (lost == 0) {
                    // refund
                    info.claimed = true;
                    _claimFund(amountDown, msg.sender, token);
                    emit Claim(msg.sender, epoch, token, amountDown);

                    if (info.luck) {
                        mintedToken.mint(msg.sender, mintTokenAmount);
                    }
                    return;
                }

                if (won == 0) {
                    continue;
                }

                // pay reward
                reward = amountDown * lost / won  + amountDown;
                info.claimed = true;
                _claimFund(reward, msg.sender, token);
                emit Claim(msg.sender, epoch, token, reward);

                if (info.luck) {
                    mintedToken.mint(msg.sender, mintTokenAmount);
                }
                return;
            }

            // lost
            if ((round.result == Result.UP && amountDown > 0) ||
                (round.result == Result.DOWN && amountUp > 0)) {

                info.claimed = true;
                emit Claim(msg.sender, epoch, token, 0);
                return;
            }

            // cannot set price -> refund
            if (round.result == Result.WAITING &&
            epoch * roundDuration + startTimestamp + 1 days <= block.timestamp) {
                info.claimed = true;
                _claimFund(amountUp + amountDown, msg.sender, token);
                emit Claim(msg.sender, epoch, token, amountUp + amountDown);
                return;
            }

            // the remaining case is waiting for backend set price
        }
    }

    /**
     * @dev Claim refs reward
     */
    function claimRef() public {
        RefInfo storage ref = refs[msg.sender];
        uint256 length = ref.listToken.length;

        for (uint256 index = 0; index < length; index++) {
            address token = ref.listToken[index];
            uint256 amount = ref.totalRefEarned[token] - ref.totalRefClaimed[token];

            if (amount > 0) {
                _claimFund(amount, msg.sender, token);
                ref.totalRefClaimed[token] += amount;
                emit ClaimRef(msg.sender, token, amount);
            }
        }
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

        uint256 winnerLength = 0;
        uint256[] memory upAmount = new uint256[](round.listToken.length);
        uint256[] memory downAmount = new uint256[](round.listToken.length);

        for (uint256 index = 0; index < round.listToken.length; index++) {
            address token = round.listToken[index];
            uint256 operationFee = feeRates[token];
            uint256 fee = 0;
            upAmount[index] = round.volumes[token].upAmount;
            downAmount[index] = round.volumes[token].downAmount;

            if (round.result == Result.UP) {
                fee = round.volumes[token].downAmount * operationFee / 1000;
                round.volumes[token].wonAmount = round.volumes[token].upAmount;
                round.volumes[token].lostAmount = round.volumes[token].downAmount - fee;
                if (round.volumes[token].totalAmount >= minterVol[token]) {
                    winnerLength = round.listUserUp.length;
                }
            }

            if (round.result == Result.DOWN) {
                fee = round.volumes[token].upAmount * operationFee / 1000;

                round.volumes[token].wonAmount = round.volumes[token].downAmount;
                round.volumes[token].lostAmount = round.volumes[token].upAmount - fee;
                if (round.volumes[token].totalAmount >= minterVol[token]) {
                    winnerLength = round.listUserDown.length;
                }
            }

            if (round.result == Result.DRAW) {
                if (round.volumes[token].totalAmount >= minterVol[token]) {
                    winnerLength = round.listUserUp.length + round.listUserDown.length;
                }
            }

            if (fee > 0) {
                if (dividendInfo.total[token] == 0) {
                    dividendInfo.listToken.push(token);
                }

                dividendInfo.total[token] += fee/2; // calculate dividend with 1/2 fee rate
            }
        }

        uint256 rand = 0;
        if (winnerLength > 0) {
            rand = uint256(keccak256(abi.encodePacked(round.openPrice, round.closePrice, block.timestamp))) % winnerLength;
            round.rand = rand;
            // case result == DRAW
            // winnerLength = listUserUp --> listUserDown

            if (round.result == Result.UP ||
                (round.result == Result.DRAW && rand < round.listUserUp.length)) {
                round.luckyUser = round.listUserUp[rand];
            }

            if (round.result == Result.DOWN) {
                round.luckyUser = round.listUserDown[rand];
            }

            if (round.result == Result.DRAW && rand >= round.listUserUp.length) {
                round.luckyUser = round.listUserDown[rand - round.listUserUp.length];
            }

            predictionHistory[epoch][round.luckyUser].luck = true;
        } else {
            mintedToken.mint(address(this), mintTokenAmount); // mint to contract address
        }

        emit RewardsCalculated(epoch, round.result, round.openPrice, round.closePrice, round.listToken, upAmount, downAmount);
    }

    function _forwardRefs(uint256 amount, address token, address parent) internal {
        bool isNewParent = false;
        address currentParent = msg.sender;
        uint256 newTotalChild = refs[msg.sender].total;

        if (parent == msg.sender) { // do not allow
            parent = address(0);
        }

        // update new parent
        if (parents[msg.sender] == address(0) && parent != address(0)) {
            parents[msg.sender] = parent;
            isNewParent = true;
        }

        for (uint256 level = 0; level < refRates.length; level++) {
            currentParent = parents[currentParent];
            uint256 fee = refRates[level] * amount / 1000;

            if (currentParent != address(0)) {
                if (refs[currentParent].totalRefEarned[token] == 0) {
                    refs[currentParent].listToken.push(token);
                }

                refs[currentParent].totalRefEarned[token] += fee;
                if (isNewParent) { // merge branch that include all descendants
                    refs[currentParent].total += newTotalChild + 1;
                }

                continue;
            }
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

    // Public view

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

    function getLuckyUser(uint256 epoch) public view returns (address) {
        return rounds[epoch].luckyUser;
    }

    function getTotalRound(address user) public view returns (uint256) {
        return userHistory[user].length;
    }

    function getDividendInfo() public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 length = dividendInfo.listToken.length;
        uint256[] memory amounts = new uint256[](length);
        uint256[] memory claimed = new uint256[](length);

        for (uint256 index = 0; index < length; index++) {
            address token = dividendInfo.listToken[index];
            amounts[index] = dividendInfo.total[token];
            claimed[index] = dividendInfo.totalWithdrawal[token];
        }

        return (dividendInfo.listToken, amounts, claimed);
    }

    function getRefInfo(address user) public view returns (uint256, address[] memory, uint256[] memory, uint256[] memory) {
        RefInfo storage info = refs[user];
        uint256 length = info.listToken.length;
        uint256[] memory refAmounts = new uint256[](length);
        uint256[] memory refClaimed = new uint256[](length);

        for (uint256 index = 0; index < length; index++) {
            address token = info.listToken[index];

            refAmounts[index] = info.totalRefEarned[token];
            refClaimed[index] = info.totalRefClaimed[token];
        }

        return (info.total, info.listToken, refAmounts, refClaimed);
    }

    function getVolByAddress(uint256 epoch, address token) public view returns (uint256, uint256) {
        return (rounds[epoch].volumes[token].upAmount, rounds[epoch].volumes[token].downAmount);
    }

    function getPredictionHistory(uint256 epoch, address user) public view returns
    (bool, uint256, uint256, address[] memory, uint256[] memory, uint256[] memory, bool) {
        Round storage round = rounds[epoch];
        PredictionInfo storage info = predictionHistory[epoch][user];
        uint256 length = round.listToken.length;
        uint256[] memory upAmount = new uint256[](length);
        uint256[] memory downAmount = new uint256[](length);
        uint256 predictAmountUp = 0;
        uint256 predictAmountDown = 0;
        bool isWin = false;

        if (!info.participated) {
            return (false, 0, 0, round.listToken, upAmount, downAmount, false);
        }

        for (uint256 index = 0; index < round.listToken.length; index++) {
            address token = round.listToken[index];
            uint256 amount = info.up[token] + info.down[token];
            if (amount > 0) { // user predict with this token
                predictAmountUp = info.up[token];
                predictAmountDown = info.down[token];
                if ((info.up[token] > 0 && round.result == Result.UP) ||
                    (info.down[token] > 0 && round.result == Result.DOWN)) {
                    isWin = true;
                }
            }

            upAmount[index] = round.volumes[token].upAmount;
            downAmount[index] = round.volumes[token].downAmount;
        }

        return (info.claimed, predictAmountUp, predictAmountDown, round.listToken, upAmount, downAmount, isWin);
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (roundDuration == 0 || startTimestamp == 0 || block.timestamp < startTimestamp) {
            return 0;
        }

        return (block.timestamp - startTimestamp) / roundDuration + addedEpoch;
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

pragma solidity ^0.8.0;

interface IMinterToken {
    function safeMint(address to, uint256 amount) external;
    function mint(address to, uint256 amount) external returns (bool, string memory);
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

