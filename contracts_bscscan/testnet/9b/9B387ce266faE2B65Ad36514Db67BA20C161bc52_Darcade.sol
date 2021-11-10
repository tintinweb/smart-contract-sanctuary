// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './Machine.sol';

/**
 * @title Darcade
 * @dev Handles arcade logic
 */
contract Darcade is ReentrancyGuard, Ownable, Machine {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev {_wallet} The wallet receiving the fees
    */
    address payable private _wallet;

    /**
     * @dev {_processingFeeWallet} The wallet receiving the processing fees
     */
    address payable private _processingFeeWallet;

    /**
     * @dev {_creditFee} The insert coin fee in wei
    */
    uint256 internal _creditFee = 10000000000000000;

    /**
     * @dev {_processingFee} The withdrawal processing fee in wei
     */
    uint256 internal _processingFee = 5000000000000000;

    /**
     * @dev {_authorizedUserFee} The authorized user fee in wei
     */
    uint256 internal _authorizedUserFee = 5000000000000000;

    /**
     * @dev {_userGameSession} The games currently in session
     */
    mapping (string => mapping(string =>address)) private userGameSession;

    /**
     * @dev {canCashOut} Can this session cash out?
     */
    mapping (string => bool) private canCashOut;


    /**
     * @dev {GameSession} Fires when coin is inserted
     */
    event GameSession(address wallet, uint256 amount, string gameId, string userId);

    /**
     * @dev {CashOutInitiated} Fires when cash out is initiated
     */
    event CashOutInitiated(string session, address wallet);

    /**
     * @dev {CashOutComplete} Fires when cash out is complete
     */
    event CashOutComplete(string machineId, string gameId, string sessionId, uint256 amountInWei, address receiver);

    /**
     * @dev {AuthorizedUserRequested} Fires off when a request to add an authroized user to a machine is triggered
     */
    event AuthorizedUserRequested(string machineId, address authorizedWallet);

    /**
     * @dev {AuthorizedUserRemovalRequested} Fires off when a request to remove an authroized user from a machine is triggered
     */
    event AuthorizedUserRemovalRequested(string machineId, address authorizedWallet);

    /**
     * @param receivingFeesWallet Address where collected funds will be forwarded to
     */
    constructor (address payable receivingFeesWallet, address payable processingFeeWallet) {
        require(receivingFeesWallet != address(0), "Darcade: wallet is the zero address");
        _wallet = receivingFeesWallet;
        _processingFeeWallet = processingFeeWallet;
    }

    /**
    * @return the address where funds are collected.
    */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @dev Set the Wallet that is Receiving Fees
     */
    function setWallet(address payable newWallet) public onlyOwner {
        require(newWallet != address(0), "Darcade: wallet is the zero address");
        _wallet = newWallet;
    }

    /**
     * @dev Set the Wallet that is Receiving Processing Fees
     */
    function setProcessingFeeWallet(address payable newWallet) public onlyOwner {
        require(newWallet != address(0), "Darcade: wallet is the zero address");
        _processingFeeWallet = newWallet;
    }

    /**
     * @dev Handles coin insertion
     */
    function insertCoin(string memory gameId, string memory userId) public nonReentrant payable {
        address beneficiary = _msgSender();
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        updateUserGameSession(gameId, userId);
        _forwardFunds();

        emit GameSession(beneficiary, weiAmount, gameId, userId);
    }

    /**
     * @dev Handles withdrawing rewards from a specific session.
     */
    function withdraw(string memory sessionId) public nonReentrant payable {
        _preValidateWithdrawal(_msgSender(), msg.value);
        _processingFeeWallet.transfer(msg.value);
        canCashOut[sessionId] = true;
        emit CashOutInitiated(sessionId, _msgSender());
    }

    modifier onlyProcessor() {
        require(msg.sender == _processingFeeWallet, "Only the Processor can do this!");
        _;
    }

    /**
     * @dev Handles the reward collection ( only processor can execute this )
     */
    function collectReward(string memory machineId, string memory gameId, string memory sessionId, string memory userId, uint256 amountInWei, address payable receiver) public onlyProcessor {
        require(canCashOut[sessionId] == true, "This session is not eligible to cash out");
        super._collectReward(machineId, gameId, amountInWei, receiver);
        canCashOut[sessionId] = false;
        userGameSession[userId][gameId] = address(0x0);
        emit CashOutComplete(machineId, gameId, sessionId, amountInWei, receiver);
    }

    /**
     * @dev Distributes the Prizes in 1 call
     */
    function distributePrizes(string memory machineId, string memory gameId, address payable[] memory addrs, uint[] memory amntsInWei) public onlyProcessor {
        super._distributePrizes(machineId, gameId, addrs, amntsInWei);
    }

    /**
     * @dev Request to Add an authroized user to a machine
     */
    function requestAddAuthorizedUserToMachine(string memory machineId, address authorizedWallet) public nonReentrant payable {
        _processingFeeWallet.transfer(msg.value);
        emit AuthorizedUserRequested(machineId, authorizedWallet);
    }

    /**
     * @dev Requests removal of an authorized user from a machine
     */
    function requestRemoveAuthorizedUserFromMachine(string memory machineId, address authorizedWallet) public nonReentrant payable {
        _processingFeeWallet.transfer(msg.value);
        emit AuthorizedUserRemovalRequested(machineId, authorizedWallet);
    }

    /**
     * @dev Adds Authorized User To a machine
     */
    function addAuthorizedUserToMachine(string memory machineId, address authorizedWallet) public  onlyProcessor {
        super._addAuthorizedUserToMachine(machineId, authorizedWallet);
    }

    /**
     * @dev Removes Authorized User From A Machine
     */
    function removeAuthorizedUserToMachine(string memory machineId, address authorizedWallet) public onlyProcessor {
        super._removeAuthorizedUserFromMachine(machineId, authorizedWallet);
    }

    /**
     * @dev Pre-validates the withdrawal
    */
    function _preValidateWithdrawal(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Darcade: beneficiary is the zero address");
        require(weiAmount != 0, "Darcade: weiAmount is 0");
        require(weiAmount == _processingFee, "Darcade: the withdrawal fee is invalid");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Adds a game in session value
     */
    function updateUserGameSession(string memory gameId, string memory userId) internal {
        userGameSession[userId][gameId] = _msgSender();
    }

    /**
     * @dev Pre-validates the insert coin purchase
    */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Darcade: beneficiary is the zero address");
        require(weiAmount != 0, "Darcade: weiAmount is 0");
        require(weiAmount == _creditFee, "Darcade: the credit fee is invalid");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Sets the insert coin fee
     */
    function setCreditFee(uint256 creditFeeInWei) public onlyOwner {
        _creditFee = creditFeeInWei;
    }

    /**
     * @dev Sets the authorized user fee
     */
    function setAuthorizedUserFee(uint256 authorizedUserFeeInWei) public onlyOwner {
        _authorizedUserFee = authorizedUserFeeInWei;
    }

    /**
     * @dev Sets the processing fee
     */
    function setProcessingFee(uint256 processingFeeInWei) public onlyOwner {
        _processingFee = processingFeeInWei;
    }

    /**
     * @dev Gets the processing fee
     */
    function getProcessingFee() public view returns (uint256) {
        return _processingFee;
    }

    /**
     * @dev Gets the insert coin fee
     */
    function getCreditFee() public view returns (uint256) {
        return _creditFee;
    }

    /**
     * @dev Gets the authorized user fee
     */
    function getAuthorizedUserFee() public view returns (uint256) {
        return _authorizedUserFee;
    }

    /**
     * @dev Checks if user session is active in a specific game
     */
    function getUserGameSession(string memory gameId, string memory userId) public view returns (address) {
        return userGameSession[userId][gameId];
    }


    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Machine {

    using SafeMath for uint256;

    mapping(string => mapping(string => Liquidity)) private machines;

    mapping(string => mapping(address => bool)) private canAddLiquidity;

    struct Liquidity {
        IERC20 token;
        uint256 amountInWei;
        uint256 reserveInWei;
    }

    event MachineGameLiquidityReceived(string machineId, string gameId, address from, uint256 amountInWei, uint256 reserveInWei);
    event MachineGameLiquidityRemoved(string machineId, string gameId, address by, uint256 amountInWei, IERC20 tokenRemoved);
    event MachineGameRewardSent(string machineId, string gameId, address to, uint256 amount);
    event MachineReserveUsed(string machineId, string gameId, address usedBy, uint256 amountTakenFromReserve);
    event PrizeDistributionComplete(string machineId, string gameId);

    /**
     * @dev Adds liquidity to a machine game.
     */
    function addLiquidityToMachineGame(string memory machineId, string memory gameId, IERC20 _token, uint256 amountInWei, uint256 reserveInWei) public {
        uint256 amountPlusReserveInWei = amountInWei.add(reserveInWei);
        require(canAddLiquidity[machineId][msg.sender] == true, "You are not authorized to add liquidity to this machine.");
        require(amountInWei > 0, "You must send an amount larger than zero");
        require(reserveInWei > 0, "You must send a reserve amount larger than zero");
        require(_token.allowance(msg.sender, address(this)) >= amountPlusReserveInWei, "You must execute approve on the token for the desired amount plus the reserve amount before adding liquidity!");
        _token.transferFrom(msg.sender, address(this), amountPlusReserveInWei);
        machines[machineId][gameId] = Liquidity(_token, machines[machineId][gameId].amountInWei += amountInWei, machines[machineId][gameId].reserveInWei += reserveInWei);
        emit MachineGameLiquidityReceived(machineId, gameId, msg.sender, amountInWei, reserveInWei);
    }

    /**
     * @dev Removes Liquidity from a machine game
     */
    function removeLiquidityFromMachineGame(string memory machineId, string memory gameId) public {
        require(canAddLiquidity[machineId][msg.sender] == true, "You are not authorized to remove liquidity from this machine.");
        IERC20 _liquidToken = machines[machineId][gameId].token;
        uint256 amountPlusReserveInWei = machines[machineId][gameId].amountInWei.add(machines[machineId][gameId].reserveInWei);
        _liquidToken.transfer(msg.sender, amountPlusReserveInWei);
        delete machines[machineId][gameId];
        emit MachineGameLiquidityRemoved(machineId, gameId, msg.sender, amountPlusReserveInWei, _liquidToken);
    }

    /**
     * @dev Grants an authorized user permission to add liquidity to machine.
     */
    function _addAuthorizedUserToMachine(string memory machineId, address authorizedWallet) internal {
        canAddLiquidity[machineId][authorizedWallet] = true;
    }

    /**
     * @dev Revokes an authorized user permission to add liquidity to machine.
     */
    function _removeAuthorizedUserFromMachine(string memory machineId, address authorizedWallet) internal {
        canAddLiquidity[machineId][authorizedWallet] = false;
    }


    /**
     * @dev Sends Game Reward to winner
     */
    function _collectReward(string memory machineId, string memory gameId, uint256 amountInWei, address payable receiver) internal {
        IERC20 _rewardToken = machines[machineId][gameId].token;
        uint256 machineLiquid = machines[machineId][gameId].amountInWei;
        uint256 machineReserveLiquid = machines[machineId][gameId].reserveInWei;
        uint256 combinedLiquid = machineLiquid.add(machineReserveLiquid);
        if(machineLiquid >= amountInWei){
            _rewardToken.transfer(receiver, amountInWei);
            machines[machineId][gameId].amountInWei -= amountInWei;
            emit MachineGameRewardSent(machineId, gameId, receiver, amountInWei);
        } else if (machineLiquid < amountInWei) {
            // check the reserve tank...
            if (combinedLiquid >= amountInWei) {
                _rewardToken.transfer(receiver, amountInWei);
                uint256 takeFromReserve = amountInWei.sub(machines[machineId][gameId].amountInWei);
                uint256 takeFromMachine = amountInWei.sub(takeFromReserve);
                machines[machineId][gameId].amountInWei -= takeFromMachine;
                machines[machineId][gameId].reserveInWei -= takeFromReserve;
                emit MachineReserveUsed(machineId, gameId, receiver, takeFromReserve);
                emit MachineGameRewardSent(machineId, gameId, receiver, amountInWei);
            } else {
                require(combinedLiquid >= amountInWei, "This machine does not have enough liquidity in the tank");
            }
        }
    }

    /**
     * @dev Distributes the Prizes in 1 call
     */
    function _distributePrizes(string memory machineId, string memory gameId, address payable[] memory addrs, uint[] memory amntsInWei) internal {

        require(addrs.length == amntsInWei.length, "The length of two array should be the same");

        uint256 machineLiquid = machines[machineId][gameId].amountInWei;
        uint256 machineReserveLiquid = machines[machineId][gameId].reserveInWei;
        uint256 combinedLiquid = machineLiquid.add(machineReserveLiquid);
        IERC20 _rewardToken = machines[machineId][gameId].token;

        for (uint i=0; i < addrs.length; i++) {

            machineLiquid = machines[machineId][gameId].amountInWei;
            machineReserveLiquid = machines[machineId][gameId].reserveInWei;
            combinedLiquid = machineLiquid.add(machineReserveLiquid);
            address payable receiver = addrs[i];
            uint256 amountInWei = amntsInWei[i];

            if(machineLiquid >= amountInWei){
                _rewardToken.transfer(receiver, amountInWei);
                machines[machineId][gameId].amountInWei -= amountInWei;

            } else if (machineLiquid < amountInWei) {
                // check the reserve tank...
                if (combinedLiquid >= amountInWei) {
                    _rewardToken.transfer(receiver, amountInWei);
                    uint256 takeFromReserve = amountInWei.sub(machines[machineId][gameId].amountInWei);
                    uint256 takeFromMachine = amountInWei.sub(takeFromReserve);
                    machines[machineId][gameId].amountInWei -= takeFromMachine;
                    machines[machineId][gameId].reserveInWei -= takeFromReserve;
                    emit MachineReserveUsed(machineId, gameId, receiver, takeFromReserve);
                } else {
                    require(combinedLiquid >= amountInWei, "This machine does not have enough liquidity in the tank");
                }
            }

        }

        emit PrizeDistributionComplete(machineId, gameId);
    }


    /**
     * @dev Gets the Liquidity Remaining for specific game and machine
     */
    function getMachineGameRemainingLiquidity(string memory machineId, string memory gameId) public view returns (uint256) {
        return machines[machineId][gameId].amountInWei;
    }

    /**
     * @dev Gets the Liquidity Remaining for specific game and machine in the reserve tank
     */
    function getMachineGameReserveTank(string memory machineId, string memory gameId) public view returns (uint256) {
        return machines[machineId][gameId].reserveInWei;
    }

    /**
     * @dev Gets the active token being used for the specific machine and game
     */
    function getMachineGameActiveToken(string memory machineId, string memory gameId) public view returns (IERC20) {
        return machines[machineId][gameId].token;
    }

    /**
     * @dev Checks if a user is authorized to add liquidity to a machine
     */
    function isUserAuthorizedToAddLiquidity(string memory machineId, address authorizedWallet) public view returns (bool) {
        return canAddLiquidity[machineId][authorizedWallet];
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