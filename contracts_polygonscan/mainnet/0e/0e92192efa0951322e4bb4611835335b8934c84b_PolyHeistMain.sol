/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

// File: IPolyHeistUserDatabase.sol


pragma solidity 0.8.6;

interface IPolyHeistUserDatabase {
    function getUserInfo(address _address) external view returns (uint128 id, uint128 referrerId, bytes16 name);

    function getDepositVars(address _address) external view returns (bytes16 _depositUsername, uint128 _referrerId, address _referrerAddress);

    function getAddressToId(address _address) external view returns (uint128);

    function getIdToAddress(uint128 _id) external view returns (address);

    function getAddressToUsername(address _address) external view returns (bytes16);

    function getUsersReferred(uint128 _referrerId) external view returns (uint128[] memory);

    function getUserReferrer(address _address) external view returns (uint128);

    function getUserTotal() external view returns (uint128);
    
    function isRegistered(address _address) external view returns(bool);
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

    constructor () {
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

// File: @openzeppelin/contracts/utils/Address.sol



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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/utils/Context.sol



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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: PolyHeistMain.sol

/* 
-SPDX-License-Identifier: UNLICENSED 
-This smart contract is unlicensed ie. non-open-source code and is protected by EULA.
-Any attempt to copy, modifiy, or use this code without written consent from PolyHeist is prohibited.
-Please see https://poly-heist.gitbook.io/info/license-agreement/license for more information.
-
*/
pragma solidity 0.8.6;





contract PolyHeistMain is Ownable, ReentrancyGuard {
    using Address for address;

    /*--- Smart contract developed by @rd_ev_ ---*/

    /*--- CONTRACT VARIABLES ---*/

    struct DepositInfo {
        uint id;
        uint balance;
        uint referralRewards;
        uint refCharged;
        uint refRewardsWithdrew;
        uint rewardsWithdrew;
    }

    struct RecentDeposit {
        bytes16 name;
        uint64 date;
        uint64 countdownTime;
        uint amount;
    }

    struct PotInfo {
        uint fee;
        uint winnerPot;
    }

    /*--- CONSTANT VARIABLES ---*/

    // Maximum distribution fee that can be set
    uint private immutable maxDistributionFee = 30;
    // Maximum random drop fee that can be set
    uint private immutable maxDropFee = 10;
    // Maximum referral fee that can be set
    uint private immutable maxReferralFee = 5;
    // Maximum dev fee that can be set
    uint private immutable maxDevFee = 10;
    // Maximum referral fees a single user is made to pay - 10 matic
    uint private immutable maxRefCharged = 10 ether;
    // Minimum deposit % that can be made in respect to current total - 0.05%
    uint private immutable minDepPercent = 2000;

    /*--- INITIAL VARIABLES ---*/

    // Interface to interact with userDatabase contract
    IPolyHeistUserDatabase internal userDatabase_;
    // RandDrop contract address
    address public randDropAddress;
    // RandDrop contract cannot be changed after setting address
    bool private hasSetRandDrop;
    // Distribution fee set to 15% for early users
    uint private distributionFee = 15;
    // Referral fee set to 5%
    uint private referralFee = 5;
    // Random drop fee set to 5%
    uint private dropFee = 5;
    // Dev fee set to 5% for early users
    uint private devFee = 5;
    // Total number of deposits
    uint public depositsTotal;
    // Total matic in the pot to be won by the last user deposit
    uint private winnerPotTotal;
    // Total rewards from distribution fees, distributed to all users weighted by their share of the pool
    uint private rewardPotTotal;
    // Total rewards waiting to be won in random drop
    uint public dropBalance;
    // Current winner of pot
    address private lastDeposit;
    // Time pot opened
    uint64 private startingTimestamp = uint64(block.timestamp);
    // Time until manual claim can be made
    uint64 private claimTimer = uint64(157762710427);
    // Check if claim has been made
    bool private hasMadeClaim;
    // Time left before last deposit can be made
    uint64 private countdownTimer = startingTimestamp + 20 hours;
    // Store admin address'
    mapping (address => bool) admins;
    // Address dev fee is sent to for funding devs
    address private devFeeAddress;
    // Dev fee balance
    uint private devBalance;
    // Map user to their deposit info
    mapping (address => DepositInfo) depositInfo;
    // Map deposit id to relevant pot info
    mapping (uint => PotInfo) potInfo;
    // Create array of all deposits for recent deposit info
    RecentDeposit[] recentDeposits;

    /*--- EVENTS ---*/

    event Deposit(uint indexed depositId, address indexed user, uint amount);
    event WithdrawRewards(address indexed user, uint amount);
    event NewAdmin(address indexed admin);
    event RemovedAdmin(address indexed admin);
    event UpdatedDistributionFee(uint distributionFee);
    event UpdatedReferralFee(uint referralFee);
    event UpdatedDropFee(uint dropFee);
    event UpdatedDevFee(uint devFee);
    event UpdatedDevFeeAddress(address indexed _adminAddress);
    event TransferedDropBalance(uint amount);
    event WinnerPaid(address indexed winner, uint amount);

    /*--- MODIFIERS ---*/

    modifier notContract() {
        require(
            !address(msg.sender).isContract(),
             "contract not allowed"
        );
        require(
            msg.sender == tx.origin,
             "proxy contract not allowed"
        );
        _;
    }

    modifier isUser() {
        require(
            userDatabase_.isRegistered(msg.sender),
            "you must register first"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner() ||
            admins[msg.sender] == true,
            "only admins"
        );
        _;
    }

    /*--- CONTRACT DEPLOYMENT CONSTRUCTOR ---*/

    constructor(
        address _devFeeAddress,
        address _userDatabaseAddress
        ) 
    {
        devFeeAddress = _devFeeAddress;
        userDatabase_ = IPolyHeistUserDatabase(_userDatabaseAddress);
    }

    function setRandDrop(address _randDrop) 
        external
        onlyOwner()
    {
        require(
            !hasSetRandDrop, 
            "contract can only be set once"
        );
        randDropAddress = _randDrop;
        hasSetRandDrop = true;
    }

    /*--- MAIN FUNCTIONS ---*/

    function deposit(uint _amount)
        external
        payable
        isUser()
        notContract()
    {
        require(
            countdownTime() > 0, 
            "unlucky time is up!"
        );
        require(
            msg.value == _amount &&
            _amount >= minDeposit(), 
            "not enough matic, you broke"
        );
        require(
            _amount % 1 ether == 0, 
            "whole numbers only smh"
        );

        // If user has rewards they must be withdrawn before they can re-deposit
        if (getRewards(msg.sender) > 0) {
            withdrawRewards();
        }

        // Get users name and info of their referrer
        (bytes16 depositUsername, uint128 referrerId, address referrerAddress) = userDatabase_.getDepositVars(msg.sender);
        uint amount;
        uint refBonus;
        // User has been referred if referrer id is not 0
        if (referrerId > 0) {
            (uint _newAmount, uint _refBonus) = handleReferrer(_amount, referrerAddress);
            amount = _newAmount;
            refBonus = _refBonus;
        } else {
            amount = _amount;
            refBonus = 0;
        }

        // Calculate bonuses to be taken from deposit
        uint usersBonus = (amount * distributionFee) / 100;
        uint dropBonus = (amount * dropFee) / 100;
        uint devBonus = (amount * devFee) / 100;
        uint bonuses = usersBonus + dropBonus + devBonus;
        uint userBalance = amount - bonuses;

        // Store reward bonus and pot total for this deposit
        // Top up winners pot after pot info is saved
        potInfo[depositsTotal] = PotInfo(
            usersBonus,
            winnerPotTotal
        );
        winnerPotTotal += userBalance;
        rewardPotTotal+=usersBonus;
        dropBalance += dropBonus;
        devBalance += devBonus;

        // If user has already deposited, update necessary parameters
        // Else create a new struct for users first deposit
        if (hasDeposited(msg.sender)) {
            depositInfo[msg.sender].id = depositsTotal;
            depositInfo[msg.sender].balance += userBalance;
            depositInfo[msg.sender].refCharged += refBonus;
        } else {
            depositInfo[msg.sender] = DepositInfo(
                depositsTotal,
                userBalance,
                0,
                refBonus,
                0,
                0
            );
        }

        // Stores deposit with extra info to be used on frontend
        recentDeposits.push(RecentDeposit(
            depositUsername,
            uint64(block.timestamp),
            countdownTime(),
            _amount
        ));
        emit Deposit(depositsTotal, msg.sender, _amount);
        depositsTotal++;

        // Reset the countdown
        resetCountdown(msg.sender); 
    }

    // Referrers must have a balance of 5 matic to earn referral rewards
    // Individual users can only be charged up to 10 Matic in referral fees
    function handleReferrer(uint _amount, address _referrerAddress)
        private
        returns (uint _newAmount, uint _refBonus)
    {
        uint charged = depositInfo[msg.sender].refCharged;
        if (charged >= 10 ether || getUserBalance(_referrerAddress) < 5 ether) {
            _refBonus = 0;
            _newAmount = _amount; 
        } else {
            _refBonus = (_amount * referralFee) / 100;
            if (charged + _refBonus > 10 ether) {
                _refBonus = 10 ether - charged;
            }
            _newAmount = _amount - _refBonus;
            depositInfo[_referrerAddress].referralRewards += _refBonus;
        }
        return (_newAmount, _refBonus);
    }

    // Pot rewards are withdrawn after being calculated
    function withdrawRewards() 
        public  
        nonReentrant() 
        isUser() 
    {
        require(
            hasDeposited(msg.sender),
            "deposit to earn rewards"
        );
        uint rewards = getRewards(msg.sender);
        require(
            rewards > 0,
            "reward balance zero"
        );
        depositInfo[msg.sender].id = depositsTotal - 1;
        depositInfo[msg.sender].rewardsWithdrew += rewards;
        Address.sendValue(payable(msg.sender), rewards);
        emit WithdrawRewards(msg.sender, rewards);
    }

    // Referral rewards are already calculated 
    function withdrawRefRewards() 
        external 
        nonReentrant() 
        isUser() 
    {
        require(
            hasDeposited(msg.sender),
            "no rewards if you haven't deposited"
        );
        uint refBonus = getRefRewards(msg.sender);
        require(
            refBonus >= 1e17, 
            "minimum withdrawl is 0.1 MATIC"
        );
        depositInfo[msg.sender].referralRewards = 0;
        depositInfo[msg.sender].refRewardsWithdrew += refBonus;
        Address.sendValue(payable(msg.sender), refBonus);
        emit WithdrawRewards(msg.sender, refBonus);
    }

    // Reset countdown back and store the the address of the deposit
    function resetCountdown(address _lastDeposit) 
        private 
    {
        countdownTimer = uint64(block.timestamp) + 20 hours;
        lastDeposit = _lastDeposit;
    }

    // Winner is deemed to have won fairly, pay winner 70% of pot, 
    // Pay 20% to random drop contract for final drop split between 5 users
    // Pay 10% to dev fee address 
    function validWinner() 
        external 
        nonReentrant() 
        onlyAdmin() 
    {
        require(
            countdownTime() == 0,
            "pot is still open"
        );
        uint winTotal = (winnerPotTotal * 70) / 100;
        uint lastFee = (winnerPotTotal * 10)/ 100;
        uint finalDropBalance = lastFee * 2;

        Address.sendValue(payable(lastDeposit), winTotal);
        Address.sendValue(payable(randDropAddress), finalDropBalance);
        Address.sendValue(payable(devFeeAddress), lastFee);
        emit TransferedDropBalance(finalDropBalance);
        emit WinnerPaid(lastDeposit, winTotal);
    }

    // If winner is deemed to have won maliciously, countdown will be reset and pot will continue as normal
    // Only way to stop unfair wins - LEGITIMATE winner WILL be paid out
    // The winning wallet is NOT inspected, only malicous attacks are considered, such as bloating the network to stop other transactions
    function invalidWinner() 
        external
        onlyAdmin() 
    {
        require(
            countdownTime() == 0,
            "pot is still open"
        );
        resetCountdown(lastDeposit);
        claimTimer = uint64(157762710427);
        hasMadeClaim = false;
    }

    /*--- MANUAL CLAIM FUNCTIONS ---*/

    // If after 1 week winner has not been deemed valid or invalid, the winner can manually claim
    // Example scenarios: 
    // All admins are dead and cannot call contract from the afterlife - RIP
    // All admins are in a comma or involved in accident that causes terminal brain dead
    // All admins have achieved lambo status and dipped off the scene

    function startManualClaimTimer()
       external
       isUser()
    {
        require(
            countdownTime() == 0,
            "pot is still open"
        );
        require(
            msg.sender == lastDeposit,
            "only winner can start the claim"
        );
        require(
            !hasMadeClaim,
            "claim has already started"
        );
        claimTimer = uint64(block.timestamp) + 1 weeks;
        hasMadeClaim = true;
    }

    function manualClaim()
        external
        isUser()
    {
        require(
            countdownTime() == 0,
            "pot is still open"
        );
        require(
            hasMadeClaim,
            "claim must be started"
        );
        require(
            uint64(block.timestamp) >= claimTimer,
            "claim time has not run out"
        );
        require(
            msg.sender == lastDeposit,
            "only winner can claim"
        );
        // To avoid all admins being assasinated :| winner reward is reduced to 50%
        // If all admins are dead then final drop split cannot be made so fee will be burned
        // Therefore potential drop winners are incentivised to protect admins at all cost ;)
        uint splitWin = winnerPotTotal / 2;
        Address.sendValue(payable(lastDeposit), splitWin);
        Address.sendValue(payable(address(0)), splitWin);
        emit WinnerPaid(lastDeposit, splitWin);
    }

    /*--- VIEW FUNCTIONS ---*/

    function hasDeposited(address _address) 
        private 
        view 
        returns (bool) 
    {
        return (getUserBalance(_address) > 0);
    }

    function minDeposit() 
        public
        view
        returns (uint) 
    {
        return (winnerPotTotal / minDepPercent);
    }

    function getRewards(address _address)
        public
        view
        returns (uint)
    {
        uint usrReward;
        uint initial = depositInfo[_address].id + 1;
        uint balance = depositInfo[_address].balance;
        for (uint i = initial; i < depositsTotal; i++) {
            usrReward +=
                (balance * potInfo[i].fee) /
                potInfo[i].winnerPot;
        }
        return (usrReward);
    }

    function getRefRewards(address _address)
        public
        view
        returns (uint)
    {
        return depositInfo[_address].referralRewards;
    }

    function getUserBalance(address _address) 
        private 
        view 
        returns (uint) 
    {
        return (depositInfo[_address].balance);
    }

    function isPotOpen()
        external
        view
        returns (bool)
    {
        return (countdownTime() > 0);
    }

    function countdownTime() 
        public
        view
        returns (uint64)
    {
        if (countdownTimer > uint64(block.timestamp)) {
            return (countdownTimer - uint64(block.timestamp));
        } else {
            return 0;
        }
    }

    /*--- FRONTEND HELPER FUNCTIONS ---*/

    function getPotInfo()
        external
        view
        returns (
            bytes16 currentWinner,
            uint64 timeLeft,
            uint winnerTotal,
            uint rewardTotal
        )
    {
        currentWinner = userDatabase_.getAddressToUsername(lastDeposit);
        return (currentWinner,countdownTime(), winnerPotTotal, rewardPotTotal);
    }

    function getUserData(address _address) 
        external 
        view 
        returns (
            uint128 userId, 
            bytes16 username, 
            uint balance, 
            uint pendingReward
        ) 
    {
        (uint128 id,, bytes16 name) = userDatabase_.getUserInfo(_address);
        return (
            id, 
            name, 
            depositInfo[_address].balance, 
            getRewards(_address) 
        );
    }

    function getRecentDeposits() 
        external
        view
        returns (RecentDeposit[] memory)
    {
        uint count = recentDeposits.length;
        uint inital = count - 5;
        RecentDeposit[] memory recent = new RecentDeposit[](5);

        for (uint i = inital; i < count; i++) {
            recent[(i - inital)] = recentDeposits[i];
        }
        return (recent);
    }

    function getRewardsWithdrew(address _address)
       external
       view
       returns (uint rewardsWithdrew) 
    {
        return depositInfo[_address].rewardsWithdrew;
    }

    function getRefRewardsWithdrew(address _address)
       external
       view
       returns (uint refRewardsWithdrew) 
    {
        return depositInfo[_address].refRewardsWithdrew;
    }

    function getCurrentFees()
       external
       view
       returns (uint distribution, uint referral, uint drop, uint dev) 
    {
        return (distributionFee, referralFee, dropFee, devFee);
    }

    /*--- UPDATE FUNCTIONS ---*/

    function updateDistributionFee(uint _distributionFee)
        external
        onlyAdmin()
    {
        require(
            _distributionFee != distributionFee,
            "fee is already set to this value"
        );
        require(
            _distributionFee <= maxDistributionFee,
            "fee cannot be higher than maximum"
        );
        distributionFee = _distributionFee;
        emit UpdatedDistributionFee(distributionFee);
    }

    function updateReferralFee(uint _referralFee) 
        external 
        onlyAdmin()
    {
        require(
            _referralFee != referralFee,
            "fee is already set to this value"
        );
        require(
            _referralFee <= maxReferralFee,
            "fee cannot be higher than maximum"
        );
        referralFee = _referralFee;
        emit UpdatedReferralFee(referralFee);
    }

    function updateDropFee(uint _dropFee) 
        external 
        onlyAdmin() 
    {
        require(
            _dropFee != dropFee, 
            "fee is already set to this value"
        );
        require(
            _dropFee <= maxDropFee,
            "fee cannot be higher than maximum"
        );
        dropFee = _dropFee;
        emit UpdatedDropFee(dropFee);
    }

    function updateDevFee(uint _devFee) 
        external 
        onlyAdmin() 
    {
        require(
            _devFee != devFee, 
            "fee is already set to this value"
        );
        require(
            _devFee <= maxDevFee,
            "fee cannot be higher than maximum"
        );
        devFee = _devFee;
        emit UpdatedDevFee(devFee);
    }

    function addAdmin(address _adminAddress)
        external
        onlyOwner()
    {
        require(
            admins[_adminAddress] == false, 
            "address is already an admin"
        );
        require(
            _adminAddress != address(0), 
            "invalid address"
        );
        admins[_adminAddress] = true;
        emit NewAdmin(_adminAddress);
    }
    
    function removeAdmin(address _adminAddress)
        external
        onlyOwner()
    {
        require(
            admins[_adminAddress] == true, 
            "address is not an admin"
        );
        require(
            _adminAddress != address(0), 
            "invalid address"
        );
        admins[_adminAddress] = false;
        emit RemovedAdmin(_adminAddress);
    }

    function updateDevFeeAddress(address _devFeeAddress) 
        external 
        onlyOwner() 
    {
        require(
            devFeeAddress != _devFeeAddress, 
            "address already set"
        );
        require(
            _devFeeAddress != address(0), 
            "invalid address"
        );
        devFeeAddress = _devFeeAddress;
        emit UpdatedDevFeeAddress(_devFeeAddress);
    }
    /*--- DEV FUNCTIONSS ---*/
    
    // Transfers drop balance to contract (not final drop)
    function transferDropBalance() 
        external 
        nonReentrant()
        onlyAdmin()
    {
        require(
            dropBalance > 0, 
            "random drop balance is zero"
        );
        Address.sendValue(payable(randDropAddress), dropBalance);
        emit TransferedDropBalance(dropBalance);
        dropBalance = 0;
    }

    function withdrawDevBalance() 
        external 
        nonReentrant()
        onlyAdmin() 
    {
        require(
            devBalance > 0, 
            "dev balance is zero"
        );
        Address.sendValue(payable(devFeeAddress), devBalance);
        devBalance = 0;
    }

    // First deposit of 50 Matic by PolyHeist to incentivise user deposits
    function initalDeposit()
        external
        payable
        onlyOwner()
    {
        require(
            msg.value == 50 ether,
            "not equal to 50 Matic"
        );
        require(
            depositsTotal == 0,
            "not equal to 50 Matic"
        );
        winnerPotTotal += 50 ether;
        depositInfo[msg.sender] = DepositInfo(depositsTotal, 50 ether, 0, 0, 0, 0);

        recentDeposits.push(RecentDeposit(
            0x706f6c792d6865697374000000000000,
            uint64(block.timestamp),
            countdownTime(),
            50 ether
        ));
        depositsTotal++;
        resetCountdown(msg.sender);
        emit Deposit(depositsTotal, msg.sender, 50 ether);
    }
}