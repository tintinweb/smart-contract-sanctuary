// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/IProphet.sol";
import "../interfaces/IDailyPrize.sol";
import "../interfaces/IExchange.sol";

interface IMPOT {
    function mint(address _to, uint256 _amount) external;
}

contract CryptoPropheciesGame is ReentrancyGuard, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    struct Battle {
        address player1;
        address player2;
        address winner;
        uint256 TCPAmount;
        uint256 bTCPAmount;
        uint256 startTimestamp;
        uint256 player1ProphetId;
        uint256 player2ProphetId;
    }

    mapping(uint256 => Battle) public battles;
    mapping(address => bool) public GCs;
    mapping(uint16 => uint16[2]) public multipliers;

    // Magic token
    IMPOT public MPOT;

    // bTCP swap contract address
    IExchange public ctExchange;

    // Prophet contract address
    address public prophetAddr;

    //TCP token contract address
    address public TCP;

    //bTCP token contract address
    address public bTCP;

    //KFBurn address
    address public kfBurnAddr;

    //KFDailyPrize address
    address public kfDailyPrizeAddr;

    //KFCustody address
    address public kfCustodyAddr;

    //DailyPrize contract address;
    address public ctDailyPrize;

    //battle index
    uint256 public battleId;

    uint256 public MAX_BATTLE_DURATION = 1 days;

    event BattleEnded(uint256 indexed battleId, address indexed winner);

    event KFBurnAddressUpdated(address account);

    event KFDailyPrizeAddressUpdated(address account);

    event KFCustodyAddressUpdated(address account);

    event CTDailyPrizeUpdated(address account);

    event KingdomFeeDeducted(uint256 amount);

    event WinBattleFunds(address indexed account, uint256 amount);

    event BattleCreated(
        uint256 battleId,
        address indexed player1,
        address indexed player2,
        uint256 wagerAmount,
        uint256 timestamp,
        uint256 player1ProphetId,
        uint256 player2ProphetId,
        uint256 player1ProphetTier,
        uint256 player2ProphetTier
    );

    event DailyPrizeTicketAdded(address indexed account, uint256 amount, uint256 timestamp);

    constructor(
        address _MPOT,
        address _TCP,
        address _bTCP,
        address _kfBurnAddr,
        address _kfDailyPrizeAddr,
        address _kfCustodyAddr,
        address _ctDailyPrize,
        address _ctExchange
    ) {
        require(_kfBurnAddr != address(0), "kfBurnAddr not set");
        require(_kfCustodyAddr != address(0), "kfCustodyAddr not set");
        require(_kfDailyPrizeAddr != address(0), "kfDailyPrizeAddress not set");
        require(_ctDailyPrize != address(0), "ctDailyPrize not set");

        MPOT = IMPOT(_MPOT);
        TCP = _TCP;
        bTCP = _bTCP;
        kfBurnAddr = _kfBurnAddr;
        kfCustodyAddr = _kfCustodyAddr;
        kfDailyPrizeAddr = _kfDailyPrizeAddr;
        ctDailyPrize = _ctDailyPrize;
        ctExchange = IExchange(_ctExchange);

        IERC20(bTCP).approve(_ctExchange, 2**256 - 1);
    }

    modifier onlyGC() {
        require(GCs[msg.sender], "Not have GC permission");
        _;
    }

    function createBattle(
        address _player1,
        uint256 _player1ProphetId,
        address _player2,
        uint256 _player2ProphetId,
        uint256 _wagerAmount
    ) external nonReentrant onlyGC {
        require(_player1 != address(0), "Invalid player1 address");
        require(_player2 != address(0), "Invalid player2 address");
        require(_player1 != _player2, "Players addresses are the same");
        require(
            INFT(prophetAddr).ownerOf(_player1ProphetId) == _player1,
            "Player1 not owning nft item"
        );
        require(
            INFT(prophetAddr).ownerOf(_player2ProphetId) == _player2,
            "Player2 not owning nft item"
        );

        (uint256 player1TCP, uint256 player1bTCP) = _sendWager(_player1, _wagerAmount);
        (uint256 player2TCP, uint256 player2bTCP) = _sendWager(_player2, _wagerAmount);

        battles[battleId] = Battle(
            _player1,
            _player2,
            address(1),
            player1TCP + player2TCP,
            player1bTCP + player2bTCP,
            block.timestamp,
            _player1ProphetId,
            _player2ProphetId
        );

        (, uint16 player1Rarity, , , , ) = IProphet(prophetAddr).prophets(_player1ProphetId);
        (, uint16 player2Rarity, , , , ) = IProphet(prophetAddr).prophets(_player2ProphetId);

        emit BattleCreated(
            battleId,
            _player1,
            _player2,
            _wagerAmount,
            block.timestamp,
            _player1ProphetId,
            _player2ProphetId,
            player1Rarity,
            player2Rarity
        );
        battleId++;
    }

    function endBattle(uint256 _battleId, address _winner) external nonReentrant onlyGC {
        Battle storage battle = battles[_battleId];

        require(battle.winner == address(1), "Battle already ended");
        require(battle.player1 != address(0), "Battle not found");
        require(
            battle.player1 == _winner || battle.player2 == _winner || _winner == address(0),
            "Invalid winner address"
        );
        battle.winner = _winner;
        emit BattleEnded(_battleId, _winner);

        _transferFundsToWinner(_battleId);
    }

    function setGC(address _account, bool _value) external onlyOwner {
        require(_account != address(0), "Invalid address");
        GCs[_account] = _value;
    }

    function updateKFBurnAddress(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        kfBurnAddr = _account;
        emit KFBurnAddressUpdated(_account);
    }

    function updateKFDailyPrizeAddress(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        kfDailyPrizeAddr = _account;
        emit KFDailyPrizeAddressUpdated(_account);
    }

    function updateKFCustodyAddress(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        kfCustodyAddr = _account;
        emit KFCustodyAddressUpdated(_account);
    }

    function updateCTDailyPrize(address _contract) external onlyOwner {
        require(_contract.isContract(), "Invalid contract");
        ctDailyPrize = _contract;
        emit CTDailyPrizeUpdated(_contract);
    }

    function updateProphetContractAddress(address _contract) external onlyOwner {
        require(_contract != address(0), "Invalid address");
        prophetAddr = _contract;
    }

    function updateExchangeContractAddress(address _contract) external onlyOwner {
        require(_contract != address(0), "Invalid address");
        ctExchange = IExchange(_contract);
    }

    function updateMultipliers(
        uint16[] memory _tiers,
        uint16[] memory _winMultipliers,
        uint16[] memory _loseMultipliers
    ) external onlyOwner {
        require(_tiers.length == _winMultipliers.length && _tiers.length != 0, "Invalid length");
        require(_winMultipliers.length == _loseMultipliers.length, "Invalid length");

        for (uint16 i = 0; i < _tiers.length; i++) {
            multipliers[_tiers[i]][0] = _winMultipliers[i];
            multipliers[_tiers[i]][1] = _loseMultipliers[i];
        }
    }

    function updateMPOT(address _MPOT) external onlyOwner {
        require(_MPOT != address(0), "Invalid address");
        MPOT = IMPOT(_MPOT);
    }

    function _sendWager(address _sender, uint256 _amount) internal returns (uint256, uint256) {
        uint256 TCPBal = IERC20(TCP).balanceOf(_sender);
        uint256 bTCPBal = IERC20(bTCP).balanceOf(_sender);
        require(TCPBal + bTCPBal >= _amount, "Not enough token amount in user wallet");

        if (bTCPBal >= _amount) {
            IERC20(bTCP).safeTransferFrom(_sender, address(this), _amount);

            return (0, _amount);
        } else if (bTCPBal < _amount && bTCPBal != 0) {
            IERC20(bTCP).safeTransferFrom(_sender, address(this), bTCPBal);
            IERC20(TCP).safeTransferFrom(_sender, address(this), _amount - bTCPBal);

            return (_amount - bTCPBal, bTCPBal);
        }

        IERC20(TCP).safeTransferFrom(_sender, address(this), _amount);
        return (_amount, 0);
    }

    function _transferFundsToWinner(uint256 _battleId) internal {
        Battle memory battle = battles[_battleId];

        if (battle.bTCPAmount != 0) {
            // Burn bTCP token and get TCP token from Exchange contract
            ctExchange.swap(battle.bTCPAmount);
        }

        // transfer kingdom fee
        uint256 totalTokenAmount = battle.TCPAmount + battle.bTCPAmount;
        uint256 kingdomFee = (totalTokenAmount * 3) / 100;

        // 50% kingdom fee to burn address
        IERC20(TCP).safeTransfer(kfBurnAddr, kingdomFee / 2);
        // 40% kingdom fee to daily prize address
        IERC20(TCP).safeTransfer(kfDailyPrizeAddr, (kingdomFee / 10) * 4);
        // 10% kingdom fee to team custody
        IERC20(TCP).safeTransfer(
            kfCustodyAddr,
            kingdomFee - kingdomFee / 2 - (kingdomFee / 10) * 4
        );
        // call dailyPrize contract method
        IDailyPrize(ctDailyPrize).addPrize((kingdomFee / 10) * 4);

        emit KingdomFeeDeducted(kingdomFee);

        // transfer remaining to winner
        if (battle.winner == address(0)) {
            IERC20(TCP).safeTransfer(battle.player1, (totalTokenAmount - kingdomFee) / 2);
            IERC20(TCP).safeTransfer(battle.player2, (totalTokenAmount - kingdomFee) / 2);
        } else {
            IERC20(TCP).safeTransfer(battle.winner, totalTokenAmount - kingdomFee);
        }

        // emit events for daily prize tickets
        (, uint16 player1Rarity, , , , ) = IProphet(prophetAddr).prophets(battle.player1ProphetId);
        (, uint16 player2Rarity, , , , ) = IProphet(prophetAddr).prophets(battle.player2ProphetId);

        uint256 ticketAmount = totalTokenAmount / 2 / 1e18;

        if (battle.winner == battle.player1) {
            if (ticketAmount * multipliers[player1Rarity][0] != 0) {
                IDailyPrize(ctDailyPrize).addTickets(
                    battle.player1,
                    ticketAmount * multipliers[player1Rarity][0]
                );
                emit DailyPrizeTicketAdded(
                    battle.player1,
                    ticketAmount * multipliers[player1Rarity][0],
                    block.timestamp
                );
            }

            if (ticketAmount * multipliers[player2Rarity][1] != 0) {
                IDailyPrize(ctDailyPrize).addTickets(
                    battle.player2,
                    ticketAmount * multipliers[player2Rarity][1]
                );
                emit DailyPrizeTicketAdded(
                    battle.player2,
                    ticketAmount * multipliers[player2Rarity][1],
                    block.timestamp
                );
            }
        }

        if (battle.winner == battle.player2) {
            if (ticketAmount * multipliers[player2Rarity][0] != 0) {
                IDailyPrize(ctDailyPrize).addTickets(
                    battle.player2,
                    ticketAmount * multipliers[player2Rarity][0]
                );
                emit DailyPrizeTicketAdded(
                    battle.player2,
                    ticketAmount * multipliers[player2Rarity][0],
                    block.timestamp
                );
            }

            if (ticketAmount * multipliers[player1Rarity][1] != 0) {
                IDailyPrize(ctDailyPrize).addTickets(
                    battle.player1,
                    ticketAmount * multipliers[player1Rarity][1]
                );
                emit DailyPrizeTicketAdded(
                    battle.player1,
                    ticketAmount * multipliers[player1Rarity][1],
                    block.timestamp
                );
            }
        }

        if (battle.winner == address(0)) {
            IDailyPrize(ctDailyPrize).addTickets(
                battle.player1,
                ticketAmount * multipliers[player1Rarity][0]
            );
            IDailyPrize(ctDailyPrize).addTickets(
                battle.player2,
                ticketAmount * multipliers[player2Rarity][0]
            );
            emit DailyPrizeTicketAdded(
                battle.player1,
                ticketAmount * multipliers[player1Rarity][0],
                block.timestamp
            );
            emit DailyPrizeTicketAdded(
                battle.player2,
                ticketAmount * multipliers[player2Rarity][0],
                block.timestamp
            );
        }

        emit WinBattleFunds(battle.winner, totalTokenAmount - kingdomFee);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFT {
    function burn(uint256) external;

    function ownerOf(uint256) external view returns (address);
}

interface IProphet is INFT {
    function mint(
        address,
        uint16,
        uint16,
        uint16,
        uint16
    ) external returns (uint256);

    function prophets(uint256)
        external
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint16,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IDailyPrize {
    function addTickets(address _player, uint256 _tickets) external;

    function addPrize(uint256 _prize) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchange {
    // swap function from bTCP to TCP
    function swap(uint256 _bTCPAmount) external;
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