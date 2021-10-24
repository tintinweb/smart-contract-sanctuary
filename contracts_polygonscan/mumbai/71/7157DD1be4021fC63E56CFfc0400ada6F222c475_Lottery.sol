/**
 *Submitted for verification at polygonscan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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
        _setOwner(_msgSender());
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

/**
 * @title RandomNumberGenerator Interface
 */
interface IRandomNumberGenerator {
    /**
     * @dev External function to request randomness and returns request Id. This function can be called by only apporved games.
     */
    function getRandomNumber() external returns (bytes32);
}

contract Lottery is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    ///@notice Event emitted when new lottery is started
    event newLotteryStarted(uint _endTime);

    /// @notice Event emitted when lottery status are modified
    event changeLotteryStatus(bool _lotteryStatus);

    /// @notice Event emitted when Tickets are bought
    event buyTicketSuccessed(
        address _buyer,
        lotteryTicket[] _lotterylist,
        uint _totalcostTickets
    );

    /// @notice Event emitted when cost per ticket are modified
    event changeCostPerTicket(uint _amount);

    /// @notice Event emitted when lotter is ended
    event results(
        uint _jackpotWinnersNum,
        uint _runnerUpWinnersNum,
        uint _jacpotPrice,
        uint _runnerUpPrice
    );

    /// @notice Event emitted when fee wallet is modified
    event changeDevWallet(address _devWallet);

    /// @notice Event emitted when the NLIFE token is modified
    event tokenChanged(address newTokenAddr);

    /// @notice Event emitted when the RNG is modified
    event RNGChanged(address _RNGAddr);

    /// @notice Event emitted when the erc20 token is withdrawn.
    event ERC20TokenWithdrew(address token, uint256 amount);

    modifier onlyRNG() {
        require(
            msg.sender == address(RNG),
            "Lottery: Caller is not the RandomNumberGenerator"
        );
        _;
    }

    struct lotteryTicket {
        uint firNum;
        uint secNum;
        uint thdNum;
    }
    lotteryTicket public winnerConditionNum;
    
    address[] public jackpotWinners;
    address[] public runnerUpWinners;
    address[] public players;

    address devWallet;
    IERC20 NLIFE;
    uint public costPerTicket;
    uint public endTime;
    bool public lotteryStatus = false;
    IRandomNumberGenerator RNG;

    mapping(address => lotteryTicket[]) public lotteryMap;
    mapping(address => bool) public isUser;
    
    /**
     * @dev Constructor function
     * @param _NLIFE Interface of NLIFE
     * @param _costPerTicket Ticket price
     * @param _devWallet Fee Wallet Address
     */
    constructor(IERC20 _NLIFE, address _devWallet, uint _costPerTicket, IRandomNumberGenerator _RNG)
    {
        NLIFE = _NLIFE;
        devWallet = _devWallet;
        costPerTicket = _costPerTicket;
        RNG = _RNG;
    }
    
    /**
     * @dev public function to start new lottery
     */
    function startNewLottery() private {
        require(lotteryStatus == true, "Lottery: Lottery is not opened");
        endTime = block.timestamp + 1 days;

        emit newLotteryStarted(endTime);
    }

    /**
     * @dev external function to change lotterystatue
     */
    function toggleLottery() external onlyOwner  {
        lotteryStatus = !lotteryStatus;
        if(lotteryStatus == true) {
            startNewLottery();
        }
        emit changeLotteryStatus(lotteryStatus);
    }

    /**
     * @dev external function to but tickets
     * @param _tickets List of tickets the player wants to buy
     */
    function buyTickets(lotteryTicket[] memory _tickets) external nonReentrant {
        require(lotteryStatus == true, "Lottery: Lottery is not opened");
        require(_tickets.length > 0, "Lottery: Ticket list is 0");

        uint totalcostTickets = costPerTicket * _tickets.length;
        uint256 fee = totalcostTickets * 76923 / 1000000;

        for(uint i = 0; i < _tickets.length; i++) {
            require(
                _tickets[i].firNum <= 25 &&
                _tickets[i].secNum <= 25 &&
                _tickets[i].thdNum <= 25,
                "Lottery: Lottery number must be less than 25"
            );
            lotteryMap[msg.sender].push(_tickets[i]);        
        }
        if(!isUser[msg.sender]) {
            players.push(msg.sender);
            isUser[msg.sender] == true;
        }

        NLIFE.safeTransferFrom(msg.sender, devWallet, fee);
        NLIFE.safeTransferFrom(msg.sender, address(this), totalcostTickets - fee);
        
        emit buyTicketSuccessed(msg.sender, _tickets, totalcostTickets);
    }

    /**
     * @dev private function to allow anyone draw lottery  from chainlink VRF if timestamp is correct
     */
    function drawLottery() external nonReentrant {
        require(
            block.timestamp >= endTime,
            "Lottery: Not ready to close to lottery yet"
        );
        RNG.getRandomNumber();
        RNG.getRandomNumber();
        RNG.getRandomNumber();
    }

    /**
     * @dev judgement function to be packpotwinner or runnerUpWinner
     * @param _result lottery number for winner
     * @param _player lottery number for player
     * @return 1 when packPotWinner, 2 when runnerUpWinner, 3 when nothing
     */
    function judgement(lotteryTicket memory _result, lotteryTicket memory _player) private pure returns(uint) {
        if (_result.firNum == _player.firNum && _result.secNum == _player.secNum && _result.thdNum == _player.thdNum) {
            return 1;
        } else if((_result.firNum == _player.firNum && _result.secNum == _player.secNum) || (_result.secNum == _player.secNum && _result.thdNum == _player.thdNum) || (_result.firNum == _player.firNum && _result.thdNum == _player.thdNum)) {
            return 2;
        } else {
            return 3;
        }
    }

    /**
     * @dev private function to send reward to winners
     */
    function playerReward() private {
        uint balance = NLIFE.balanceOf(address(this));
        uint jackPotPrice = 0;
        uint runnerUpPrice = 0;
        if(jackpotWinners.length != 0) {
            if(runnerUpWinners.length != 0) {
                //jackpotWinners earn 80%
                //runnerUpWinners earn 20%
                jackPotPrice = (balance * 8 / 10) / jackpotWinners.length;
                runnerUpPrice = (balance - jackPotPrice) / runnerUpWinners.length;
                for(uint index = 0; index < jackpotWinners.length; index++) {
                    NLIFE.safeTransfer(jackpotWinners[index], jackPotPrice);
                }
                for(uint index = 0; index < runnerUpWinners.length; index++) {
                    NLIFE.safeTransfer(runnerUpWinners[index], runnerUpPrice);
                }
            } else {
                //jackpotWinners earn 100%
                jackPotPrice = balance;
                for(uint index = 0; index < jackpotWinners.length; index++) {
                    NLIFE.safeTransfer(jackpotWinners[index], jackPotPrice);
                }
            }
        } else {
            if(runnerUpWinners.length != 0) {
                //runnerUpWinners earn 20%
                runnerUpPrice = (balance * 2 / 10) / runnerUpWinners.length;
                for(uint index = 0; index < runnerUpWinners.length; index++) {
                    NLIFE.safeTransfer(runnerUpWinners[index], runnerUpPrice);
                }
            }
        }
        emit results(
            jackpotWinners.length,
            runnerUpWinners.length,
            jackPotPrice,
            runnerUpPrice
        );

        jackpotWinners = new address[](0);
        runnerUpWinners =  new address[](0);
        players = new address[](0);
    }

    /**
     * @dev private function to declare winner in this lottery
     */
    function declareWinner(uint256[] memory _randomness) external onlyRNG {

        require(block.timestamp >= endTime);
        winnerConditionNum.firNum = _randomness[0] % 26;
        winnerConditionNum.secNum = _randomness[1] % 26;
        winnerConditionNum.thdNum = _randomness[2] % 26;

        for(uint i = 0; i < players.length; i++) {
            for(uint j = 0; j < lotteryMap[players[i]].length; j++) {
                uint result = judgement(winnerConditionNum, lotteryMap[players[i]][j]);
                if(result == 1) {
                    jackpotWinners.push(players[i]);
                } else if(result == 2) {
                    runnerUpWinners.push(players[i]);
                }
            }
        }
        playerReward();
        startNewLottery();
    }

    /**
     * @dev function to change cost per ticket
     * @param _amount Cost per ticket to change
     */
    function setcostPerTicket(uint _amount) external onlyOwner {
        costPerTicket = _amount;
        emit changeCostPerTicket(_amount);
    }

    /**
     * @dev external function to change fee wallet address
     */
    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
        emit changeDevWallet(devWallet);
    }

    /**
     * @dev external function to change Token
     */
    function changeToken(address _NLIFEAddr) external onlyOwner {
        NLIFE = IERC20(_NLIFEAddr);

        emit tokenChanged(_NLIFEAddr);
    }

    /**
     * @dev external function to change RNG
     */
    function changeRNG(address _RNGAddr) external onlyOwner {
        RNG = IRandomNumberGenerator(_RNGAddr);

        emit RNGChanged(_RNGAddr);
    }

    /**
     * @dev External function to withdraw any erc20 tokens. This function can be called by only owner.
     * @param _tokenAddr ERC20 token address
     */
    function withdrawERC20Token(address _tokenAddr) external onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));

        emit ERC20TokenWithdrew(_tokenAddr, token.balanceOf(address(this)));
    }

}