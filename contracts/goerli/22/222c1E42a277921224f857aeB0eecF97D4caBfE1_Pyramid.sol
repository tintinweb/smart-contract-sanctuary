//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./Usecase.sol";

// import "hardhat/console.sol";

contract Pyramid is Usecase, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    //library
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;

    // contract environment
    enum Environment {
        Maintaince,
        Production
    }

    Environment private env;

    //enum for event
    enum TableEventState {
        Create,
        PlayerJoin,
        FinishGame
    }

    enum PlayerEventState {
        Create,
        JoinTable,
        ChaingTable,
        LeaveTable,
        QuitGame
    }

    enum GainReasonType {
        Introducer,
        Replay,
        Winner
    }

    enum WithdrawType {
        Reward,
        Profit
    }

    //player reward amount
    mapping(address => uint256) public pendingWithdrawals;

    //minimum need amount for contract
    uint256 internal minimumAmount;

    //---------- event -------------------------
    /// @notice received ether event
    /// @param addr sender address
    /// @param amount amount
    event LogReceived(address indexed addr, uint256 amount);

    /// @notice emitted on game finished then split table
    /// @param tableNo  new table number
    /// @param oldNo old table number
    /// @param price table price
    event LogSplitTable(uint16 indexed tableNo, uint16 indexed oldNo, TablePrice indexed price);

    /// @notice emitted on table change
    /// @param tableNo table number
    /// @param state TableEventState enum
    /// @param player join player
    event LogTable(uint16 indexed tableNo, TableEventState indexed state, address indexed player);

    /// @notice emitted on player data change
    /// @param player player address
    /// @param upline upline address
    /// @param state event state
    /// @param tableNo playing table
    event LogPlayer(
        address indexed player,
        address indexed upline,
        PlayerEventState indexed state,
        uint16 tableNo
    );

    /// @notice emitted on create new player or player change name
    /// @param player player's address
    /// @param name player name
    event LogPlayerName(address indexed player, bytes32 name);

    /// @notice player gain star event
    /// @param taker recipient player address
    /// @param giver giver star address
    /// @param reason gain reason
    event LogGainStar(address indexed taker, address indexed giver, GainReasonType indexed reason);

    /// @notice new introduce reward event
    /// @param player taker address
    /// @param reason downline address
    /// @param amount reward amount
    /// @param table  winner table no
    /// @param downline introduce downline address
    /// @param price  ref price
    event LogGainReward(
        address indexed player,
        GainReasonType indexed reason,
        uint256 indexed amount,
        uint16 table,
        address downline,
        TablePrice price
    );

    /// @notice withdraw reward event
    /// @param player player address
    /// @param withdrawType type enum
    /// @param amount amount
    event LogWithdraw(address indexed player, WithdrawType indexed withdrawType, uint256 amount);

    /// @notice finish game event
    /// @param tableNo table number
    /// @param winner winner address
    /// @param second second address
    /// @param third third address
    event LogFinishGame(
        uint16 indexed tableNo,
        address indexed winner,
        address second,
        address third
    );
    //---------- error --------------------------------

    /// @notice error
    /// @param code error code
    /// @dev
    ///    --- 1xx Account error ----
    ///    110 Unfound account
    ///    111 Account already exist
    ///    121 Unfound introducer
    ///    113 Account playing
    ///    114 Account not playing
    ///    --- 3xx Game error --------
    ///    301 Table closed
    ///    --- 4xx Withdraw error ----
    ///    401 Profit profit not enough
    ///    402 Reward not enough
    ///    --- 5xx Maybe tried to attack -----
    ///    500 Unmatch price.
    ///    501 Unknown environment
    ///    502 Only account can call this
    ///    503 Only can call when system maintenance
    ///    504 System maintenance
    /// @param message error message
    error RequestError(uint256 code, bytes32 message);

    //----------replace modifier -----------------------------
    /// @notice check payd amount
    /// @dev price should 1 ether or 0.5 ether
    function __matchPrice(uint256 _amount) internal pure {
        if (_amount != 1 ether && _amount != 1 ether / 2)
            revert RequestError(500, "Unmatch price.");
    }

    /// @notice check caller address is an account
    /// @dev use "@openzeppelin/contracts/utils/Address.sol"
    function __onlyAccount(address _addr) internal view {
        if (_addr.isContract()) revert RequestError(502, "Only account can call this");
    }

    /// @notice check environment not maintaince
    function __onlyMaintaince() internal view {
        if (env != Environment.Maintaince)
            revert RequestError(503, "Only can call when maintenance");
    }

    /// @notice check environment not maintaince
    function __blockingMaintaince() internal view {
        if (env == Environment.Maintaince) revert RequestError(504, "System maintenance");
    }

    //---------- function -----------------------------

    /// @dev replace constructor
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    function initialize() public virtual override initializer {
        Usecase.initialize();
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    /// @dev generate first player then open to the public
    function startGame() external onlyOwner returns (bool) {
        __onlyMaintaince();

        address owner = owner();
        Player memory p = getPlayer(owner);
        if (p.register == true) {
            return false;
        }

        newPlayer(msg.sender, "Superman", msg.sender);
        uint256 no;
        no = newTable(TablePrice.H, TableType.Original);
        joinTable(no, msg.sender, TablePrice.H);

        no = newTable(TablePrice.M, TableType.Original);
        joinTable(no, msg.sender, TablePrice.M);

        env = Environment.Production;

        return true;
    }

    /// receive ether
    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    /// fallback
    fallback() external {}

    /// @notice withdraw profit use for owner
    function withdrawProfit() external onlyOwner nonReentrant {
        uint256 profit = address(this).balance - minimumAmount;
        payable(owner()).transfer(profit);
        emit LogWithdraw(owner(), WithdrawType.Profit, profit);
    }

    /// @notice withdraw reward use for players
    /// @dev Remember to zero the pending refund before sending to prevent re-entrancy attacks
    function withdrawReward() external nonReentrant {
        __blockingMaintaince();
        __onlyAccount(msg.sender);

        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount <= 0) revert RequestError(402, "Reward not enough");
        pendingWithdrawals[msg.sender] = 0;
        minimumAmount -= amount;

        payable(msg.sender).transfer(amount);
        emit LogWithdraw(msg.sender, WithdrawType.Reward, amount);
    }

    /// @notice apply play game
    /// @dev new player join to play handler
    /// @param _introducer introducer address
    /// @param _playerName introducer address
    function play(address _introducer, bytes32 _playerName) external payable nonReentrant {
        __blockingMaintaince();
        __onlyAccount(msg.sender);
        __matchPrice(msg.value);

        if (getPlayerRegisetr(msg.sender)) revert RequestError(111, "Account already exist");
        if (!getPlayerRegisetr(_introducer)) revert RequestError(121, "Unfound introducer");

        TablePrice price = _transfromPriceType(msg.value);

        //create new player and bind upline
        newPlayer(msg.sender, _playerName, _introducer);
        assignTable(msg.sender, _introducer, price);
        giveIntRewerd(msg.sender, _introducer, price);
        giverIntStar(msg.sender, price);
        emit LogReceived(msg.sender, msg.value);
    }

    /// @notice replay game
    /// @dev similar Play() but not introduce code param
    function replay() public payable nonReentrant {
        __blockingMaintaince();
        __onlyAccount(msg.sender);
        __matchPrice(msg.value);

        Player memory p = getPlayer(msg.sender);
        if (!p.register) revert RequestError(110, "Unfound account");

        uint256 pno = msg.value == 1 ether ? p.playingH : p.playingM;
        if (pno > 0) revert RequestError(113, "Account playing");

        //just buy insurance
        if (p.upline == address(0)) {
            p.upline = owner();
        }
        TablePrice price = _transfromPriceType(msg.value);

        assignTable(msg.sender, p.upline, price);
        giveIntRewerd(msg.sender, p.upline, price);
        giveReplayStar(msg.sender, price);
        emit LogReceived(msg.sender, msg.value);
    }

    /// @notice player name setter
    /// @param _newName new name
    function changeName(bytes32 _newName) external nonReentrant {
        __blockingMaintaince();

        if (!getPlayerRegisetr(msg.sender)) revert RequestError(110, "Unfound account"); //should registered
        emit LogPlayerName(msg.sender, _newName);
    }

    // //======== getter & setter ============

    /// @notice minimumAmount setter
    /// @dev just use for uint test
    /// @param _amount amount
    function setMinimumAmount(uint256 _amount) external onlyOwner {
        __onlyMaintaince();
        minimumAmount = _amount;
    }

    /// @notice minimumAmount getter
    /// @return amount
    function getMinimumAmount() external view onlyOwner returns (uint256) {
        return minimumAmount;
    }

    /// @notice get profit amount
    /// @dev only owner can call it
    function getProfit() external view onlyOwner returns (uint256) {
        return address(this).balance - minimumAmount;
    }

    /// @notice env setter
    /// @dev only owner can call it
    /// @param _env env number 0 => dev 1 => prod
    function setEnv(uint256 _env) external onlyOwner {
        if (_env < 0 || _env > 1) revert RequestError(501, "Unknown environment");
        env = Environment(_env);
    }

    /// @notice env getter
    /// @dev only owner can call it
    /// @return env number 0 => dev 1 => prod
    function getEnv() external view onlyOwner returns (Environment) {
        return env;
    }

    /// @notice get player information
    /// @param _addr player address
    /// @return PlayerInfo struct
    function fetchPlayer(address _addr) external view returns (PlayerInfo memory) {
        return _getPlayerInfo(_addr);
    }

    /// @notice get table information
    /// @param _no table no
    /// @return tableInfo struct
    function fetchTable(uint256 _no) external view returns (TableInfo memory) {
        return _getTableInfo(_no);
    }

    // //=========== intrnal & private ==============

    // ///@notice create new table
    // ///@param _price TablePrice join price
    // ///@param _type TableType table type
    function newTable(TablePrice _price, TableType _type) private returns (uint256 tableNo) {
        tableNo = _createTable(_price, _type);
        emit LogTable(tableNo.toUint16(), TableEventState.Create, address(0));

        return tableNo;
    }

    /// @notice player join table
    /// @param _tableNo table number
    /// @param _player player address
    /// @param _price table price
    function joinTable(
        uint256 _tableNo,
        address _player,
        TablePrice _price
    ) private {
        _joinTable(_tableNo, _player, _price);
        EmitLogPlayer(_player, PlayerEventState.JoinTable, _tableNo);
        emit LogTable(_tableNo.toUint16(), TableEventState.PlayerJoin, _player);
    }

    /// @notice assign player on upline table
    /// @param _player player address
    /// @param _upline upline address
    /// @param _price player paids amount
    function assignTable(
        address _player,
        address _upline,
        TablePrice _price
    ) private returns (uint256 tableNo) {
        tableNo = _getUplineGameTable(_upline, owner(), _price);

        if (tableNo != 0 && getTableSeats(tableNo).length < 7) {
            joinTable(tableNo, _player, _price);

            //check table is can be close
            finishGame(tableNo, _price);
            return tableNo;
        }

        //can't find in rule table..
        tableNo = newTable(_price, TableType.Split);
        joinTable(tableNo, _player, _price);
        return tableNo;
    }

    /// @notice check seats if sit full. close table
    /// @dev setting table state to close..then kick winner and split table
    /// @param _tableNo table number
    /// @param _price table price
    /// @return bool
    function finishGame(uint256 _tableNo, TablePrice _price) private returns (bool) {
        Table memory t = getTable(_tableNo);
        address[] storage seats = getTableSeats(_tableNo);
        if (seats.length < 7) {
            //seats not full
            return false;
        }

        //order by star amount
        address[] memory rank = _calcRanking(seats, _price);

        emit LogFinishGame(_tableNo.toUint16(), rank[0], rank[1], rank[2]);

        _closeTable(_tableNo, t.price);
        emit LogTable(_tableNo.toUint16(), TableEventState.FinishGame, address(0));

        //1st add giver reward and clean star
        winnerHandler(rank[0], _tableNo, t.price);

        //2nd. 3rd split new table with other player
        splitTable(rank, _tableNo, t.price);

        return true;
    }

    /// @notice winner handler when finish game
    /// @param _winner winner aaddress
    /// @param _tableNo finish table no
    /// @param _price table price enum
    function winnerHandler(
        address _winner,
        uint256 _tableNo,
        TablePrice _price
    ) private {
        _setWinnerPlayer(_winner, _price);
        EmitLogPlayer(_winner, PlayerEventState.LeaveTable, _tableNo);
        giveWinnerRewerd(_winner, _tableNo, _price);
    }

    /// @notice split table when finish game
    /// @param _players players address
    /// @param _tableNo finish table no
    /// @param _price table price enum
    function splitTable(
        address[] memory _players,
        uint256 _tableNo,
        TablePrice _price
    ) private {
        address[3] memory atb = [_players[1], _players[3], _players[4]];
        address[3] memory btb = [_players[2], _players[5], _players[6]];
        uint256 ano = _changeTable(atb, _price);
        uint256 bno = _changeTable(btb, _price);

        //split log
        emit LogSplitTable(ano.toUint16(), _tableNo.toUint16(), _price);
        emit LogSplitTable(bno.toUint16(), _tableNo.toUint16(), _price);

        //log new table
        emit LogTable(ano.toUint16(), TableEventState.Create, address(0));
        emit LogTable(bno.toUint16(), TableEventState.Create, address(0));

        //log player change table
        EmitLogPlayer(_players[1], PlayerEventState.ChaingTable, ano);
        EmitLogPlayer(_players[3], PlayerEventState.ChaingTable, ano);
        EmitLogPlayer(_players[4], PlayerEventState.ChaingTable, ano);
        emit LogTable(ano.toUint16(), TableEventState.Create, _players[1]);
        emit LogTable(ano.toUint16(), TableEventState.Create, _players[3]);
        emit LogTable(ano.toUint16(), TableEventState.Create, _players[4]);

        EmitLogPlayer(_players[2], PlayerEventState.ChaingTable, bno);
        EmitLogPlayer(_players[5], PlayerEventState.ChaingTable, bno);
        EmitLogPlayer(_players[6], PlayerEventState.ChaingTable, bno);
        emit LogTable(bno.toUint16(), TableEventState.Create, _players[2]);
        emit LogTable(bno.toUint16(), TableEventState.Create, _players[5]);
        emit LogTable(bno.toUint16(), TableEventState.Create, _players[6]);
    }

    /// @notice create new player
    /// @param _player player address
    /// @param _upline introduce code
    function newPlayer(
        address _player,
        bytes32 _playerName,
        address _upline
    ) private {
        _createPlayer(_player, _upline);
        emit LogPlayerName(_player, _playerName);
        EmitLogPlayer(_player, PlayerEventState.Create, 0);
    }

    /// @notice log introduce reward info
    /// @dev table price 50%
    /// @param _downline downline's address
    /// @param _upline recipient player
    /// @param _price player paid amount
    /// @return bool
    function giveIntRewerd(
        address _downline,
        address _upline,
        TablePrice _price
    ) private returns (bool) {
        uint256 amt = _transfromPriceAmount(_price) / 2;
        pendingWithdrawals[_upline] += amt;
        minimumAmount += amt;

        emit LogGainReward(_upline, GainReasonType.Introducer, amt, 0, _downline, _price);

        return true;
    }

    /// @notice record winner reward info
    /// @dev table's price 200% - 10% handling fee = 190%
    /// @param _winner winner address
    /// @param _tableNo table number
    /// @param _price player paid amount
    /// @return bool
    function giveWinnerRewerd(
        address _winner,
        uint256 _tableNo,
        TablePrice _price
    ) private returns (bool) {
        uint256 priceWei = _transfromPriceAmount(_price);
        uint256 amt = priceWei * 2 - (priceWei / 10);
        pendingWithdrawals[_winner] += amt;
        minimumAmount += amt;

        emit LogGainReward(
            _winner,
            GainReasonType.Winner,
            amt,
            _tableNo.toUint16(),
            address(0),
            _price
        );

        return true;
    }

    /// @notice assign star for introducer
    /// @param _player player address
    /// @return bool
    function giverIntStar(address _player, TablePrice _price) private returns (bool) {
        (address taker, address giver) = _assignIntroducerStar(_player, _price);

        //no one recive
        if (taker == address(0) || giver == address(0)) {
            return false;
        }

        emit LogGainStar(taker, giver, GainReasonType.Introducer);

        return true;
    }

    /// @notice assign star for replay
    /// @param _player downline's address
    /// @return bool
    function giveReplayStar(address _player, TablePrice _price) private returns (bool) {
        (address taker, address giver) = _assignReplayStar(_player, _price);

        //no one recive
        if (taker == address(0) || giver == address(0)) {
            return false;
        }

        emit LogGainStar(taker, giver, GainReasonType.Replay);

        return true;
    }

    //@notice emit player record event
    function EmitLogPlayer(
        address _player,
        PlayerEventState _state,
        uint256 _tableNo
    ) private {
        address uplien = getPlayerUpline(_player);

        emit LogPlayer(_player, uplien, _state, _tableNo.toUint16());
    }

    //================ v2 add ==========================

    /// @notice player quit game
    /// @param _tableNo quit table no
    function quit(uint256 _tableNo) external {
        uint256 returnPrice = _quitTable(_tableNo, msg.sender);
        pendingWithdrawals[msg.sender] += returnPrice;
        minimumAmount += returnPrice;

        EmitLogPlayer(msg.sender, PlayerEventState.QuitGame, _tableNo);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
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

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./Repository.sol";

contract Usecase is Repository {
    using SafeCastUpgradeable for uint256;

    function initialize() public virtual override {
        Repository.initialize();
    }

    /// @notice create new player
    /// @dev write player struct and binding upline and downline relaction
    /// @param _player player address
    /// @param _upline introduce address
    function _createPlayer(address _player, address _upline) internal {
        Player memory p;
        p.upline = _upline; //bind upline
        p.register = true; //set register
        setPlayer(_player, p);
        incrementPlayer();

        //upline bind downliner
        pushDownlines(_upline, _player);
    }

    ///@notice create new table
    ///@dev write table struct data
    ///@param _price table price
    ///@param _type table type
    function _createTable(TablePrice _price, TableType _type) internal returns (uint256 tableNo) {
        tableNo = incrementTable();

        uint256 inx = pushOpening(_price, tableNo);

        Table memory t;
        t.tableType = _type;
        t.price = _price;
        t.isOpen = true;
        t.index = inx;

        setTable(tableNo, t);

        return tableNo;
    }

    /// @notice player join table
    /// @dev set table number to playingTable field
    /// @param _tableNo table number
    /// @param _player player address
    /// @param _price table price enum
    function _joinTable(
        uint256 _tableNo,
        address _player,
        TablePrice _price
    ) internal virtual {
        assert(seats[_tableNo].length < 7);
        Player memory p = getPlayer(_player);

        uint256 pno = _price == TablePrice.H ? p.playingH : p.playingM;
        assert(pno == 0);

        if (_price == TablePrice.H) {
            p.playingH = _tableNo;
        } else {
            p.playingM = _tableNo;
        }
        setPlayer(_player, p);
        pushTableSeats(_tableNo, _player);
    }

    /// @notice get player info by address
    /// @param _player player address
    /// @return PlayerInfo player info
    function _getPlayerInfo(address _player) internal view returns (PlayerInfo memory) {
        Player memory p = getPlayer(_player);

        bool playing = _checkIsPlaying(_player);
        PlayingTable[] memory ptb = _getPlayingTable(_player);
        address[] memory downlines = getDownlines(_player);

        return
            PlayerInfo({
                account: _player,
                register: p.register,
                playing: playing,
                upline: p.upline,
                downlines: downlines,
                playingTable: ptb
            });
    }

    /// @notice check player is playing
    /// @param _player player address
    /// @return tables and bool: playing tables number array and bool
    function _checkIsPlaying(address _player) internal view returns (bool) {
        Player memory p = getPlayer(_player);
        return p.playingH != 0 || p.playingM != 0;
    }

    function _getPlayingTable(address _player)
        internal
        view
        returns (PlayingTable[] memory tables)
    {
        Player memory p = getPlayer(_player);
        tables = new PlayingTable[](2);

        tables[0].price = TablePrice.H;
        tables[0].no = p.playingH.toUint16();
        tables[0].star = p.starH.toUint8();
        tables[1].price = TablePrice.M;
        tables[1].no = p.playingM.toUint16();
        tables[1].star = p.starM.toUint8();
    }

    /// @notice get table informetion
    /// @param _tableNo table number
    /// @return info TableInfo struct
    function _getTableInfo(uint256 _tableNo) internal view returns (TableInfo memory info) {
        Table memory t = getTable(_tableNo);
        address[] memory st = getTableSeats(_tableNo);

        info = TableInfo({
            isOpen: t.isOpen,
            tableType: t.tableType,
            price: _transfromPriceAmount(t.price),
            seats: st,
            tableNo: _tableNo.toUint16(),
            priceType: t.price
        });
    }

    /// @notice close table by tableNo and price
    /// @param _tableNo table number
    /// @param _price table price
    function _closeTable(uint256 _tableNo, TablePrice _price) internal {
        Table memory t = getTable(_tableNo);
        t.isOpen = false;
        deleteOpening(_price, t.index, _tableNo);
        t.index = 0;
        setTable(_tableNo, t);
    }

    /// @notice player change table
    /// @param _players player address
    /// @param _price table price
    function _changeTable(address[3] memory _players, TablePrice _price)
        internal
        returns (uint256 tableNo)
    {
        uint256 no = _createTable(_price, TableType.Split);
        seats[no] = _players;

        for (uint256 i = 0; i < 3; i++) {
            setPlayingTable(_players[i], _price, no);
        }

        return no;
    }

    /// @notice get upline playing table no
    /// @dev if upline not playing same price game, just get the one more level upline
    /// @param _firstAddr player address
    /// @param _finalAddr his owner and final upline..
    /// @param _price player paids amount
    function _getUplineGameTable(
        address _firstAddr,
        address _finalAddr,
        TablePrice _price
    ) internal view returns (uint256 tableNo) {
        address nextUplineAddr = _firstAddr;
        tableNo = 0;
        uint256 pno;

        //should fixed number of iterations...because block gas limit rule
        for (uint256 i = 0; i < 5; i++) {
            pno = getPlayingTable(nextUplineAddr, _price);
            if (pno == 0) {
                if (nextUplineAddr == _finalAddr) {
                    //is final upline
                    return 0;
                }
                nextUplineAddr = getPlayerUpline(nextUplineAddr);
                continue;
            }

            if (!getTableIsOpen(pno)) {
                continue;
            }

            tableNo = pno;
            break;
        }
        //can't find upline table
        if (tableNo == 0) {
            tableNo = _getOpeningTable(_price);
        }
    }

    ///@notice get first opening table
    ///@param _price table price
    ///@return uint256
    function _getOpeningTable(TablePrice _price) private view returns (uint256) {
        address[] storage seats;
        //assign first has seat table
        uint256[] storage open = opening[uint256(_price)];
        for (uint256 i = 0; i < open.length; i++) {
            if (i == 10) {
                //limit max iteration
                break;
            }

            seats = getTableSeats(open[i]);
            if (seats.length < 7) {
                return open[i];
            }
        }

        return 0;
    }

    /// @notice calculate ranking
    /// @dev two star are winner.
    ///      if two or more player have two star. the top is winner.
    ///      next the left.. last right
    /// @param _seats players
    /// @param _price table price
    /// @return sorted address
    function _calcRanking(address[] memory _seats, TablePrice _price)
        internal
        view
        returns (address[] memory sorted)
    {
        uint256[] memory inx = new uint256[](7);
        sorted = new address[](_seats.length);
        uint256 cnt = 0;

        //first find have two star player
        for (uint256 i = 0; i < _seats.length; i++) {
            if (getPlayerStar(_seats[i], _price) == 2) {
                inx[cnt] = i;
                cnt++;
            }
        }

        //second find have one star player
        for (uint256 i = 0; i < _seats.length; i++) {
            if (getPlayerStar(_seats[i], _price) == 1) {
                inx[cnt] = i;
                cnt++;
            }
        }

        //finally add zero player star
        for (uint256 i = 0; i < _seats.length; i++) {
            if (getPlayerStar(_seats[i], _price) == 0) {
                inx[cnt] = i;
                cnt++;
            }
        }

        for (uint256 i = 0; i < inx.length; i++) {
            sorted[i] = _seats[inx[i]];
        }

        return sorted;
    }

    /// @notice assing star for introducer
    /// @dev first give introducer(upline).. if upline has two star..transfer to downline
    /// @param _player player address
    /// @param _price table price
    /// @return taker and giver
    function _assignIntroducerStar(address _player, TablePrice _price)
        internal
        returns (address taker, address giver)
    {
        address upline = getPlayerUpline(_player);
        if (_isCanGainStar(upline, _price)) {
            _giveStar(upline, _price);
            return (upline, _player);
        }

        //upline has two star or not playing
        //transfer to his downline
        address[] storage downlines = getDownlines(upline);
        for (uint256 i = 0; i < downlines.length; i++) {
            if (i > 19) {
                //downline max iteration twenty
                break;
            }

            if (_isCanGainStar(downlines[i], _price)) {
                _giveStar(downlines[i], _price);
                return (downlines[i], upline);
            }
        }

        //no one gain star
        return (address(0), address(0));
    }

    /// @notice assign replay star for introducer
    /// @dev first give introducer(upline), if upline has two star, transfer to one more level upline
    /// @param _player player address
    /// @return taker and giver
    function _assignReplayStar(address _player, TablePrice _price)
        internal
        returns (address taker, address giver)
    {
        taker = getPlayerUpline(_player);
        giver = _player;

        // max iteration twice
        for (uint256 i = 0; i < 2; i++) {
            if (_isCanGainStar(taker, _price)) {
                _giveStar(taker, _price);
                return (taker, giver);
            }

            giver = taker;
            taker = getPlayerUpline(giver);
        }

        //no one receive star
        return (address(0), address(0));
    }

    /// @notice table price -> enum transformer
    /// @param _amount price amount
    /// @return price enum
    function _transfromPriceType(uint256 _amount) internal pure returns (TablePrice price) {
        assert(_amount == 1 ether || _amount == 1 ether / 2);

        return _amount == 1 ether ? TablePrice.H : TablePrice.M;
    }

    /// @notice table enum -> price transformer
    /// @param _price TablePrice enum
    /// @return amount price amount
    function _transfromPriceAmount(TablePrice _price) internal pure returns (uint256 amount) {
        return _price == TablePrice.H ? 1 ether : 1 ether / 2;
    }

    /// @notice set winner player struct field
    /// @param _player player address
    /// @param _price TablePrice enum
    function _setWinnerPlayer(address _player, TablePrice _price) internal {
        Player memory p = getPlayer(_player);
        if (_price == TablePrice.H) {
            p.playingH = 0;
            p.starH = 0;
        } else {
            p.playingM = 0;
            p.starM = 0;
        }

        setPlayer(_player, p);
    }

    /// @notice check this addresss player can be gain star
    /// @dev should playing and the star less then 2
    /// @param _player player address
    /// @return bool
    function _isCanGainStar(address _player, TablePrice _price) private view returns (bool) {
        Player memory p = getPlayer(_player);
        if (_price == TablePrice.H) {
            return p.playingH > 0 && p.starH < 2;
        } else {
            return p.playingM > 0 && p.starM < 2;
        }
    }

    /// @notice check this addresss player can be gain star
    /// @dev should playing and the star less then 2
    /// @param _player player address
    function _giveStar(address _player, TablePrice _price) private {
        uint256 star = getPlayerStar(_player, _price);
        assert(star < 2);
        star += 1;
        setPlayerStar(_player, star, _price);
    }

    //================ v2 add =========================

    /// @notice player quit table
    /// @dev subtract introducer reward and 10% handling fee
    /// @param _tableNo table no
    /// @param _player player address
    /// @return returnPrice return price
    function _quitTable(uint256 _tableNo, address _player) internal returns (uint256 returnPrice) {
        Table memory t = getTable(_tableNo);
        assert(t.isOpen == true);

        //remove playing table and star
        Player memory p = getPlayer(_player);
        if (t.price == TablePrice.H) {
            assert(p.playingH > 0);
            p.playingH = 0;
            p.starH = 0;
        } else {
            assert(p.playingM > 0);
            p.playingM = 0;
            p.starM = 0;
        }

        deleteTableSeats(_tableNo, _player);
        setPlayer(_player, p);

        uint256 price = _transfromPriceAmount(t.price);
        returnPrice = price - ((price / 2) + (price / 10));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "hardhat/console.sol";

contract Repository is Initializable {
    using SafeCastUpgradeable for uint256;

    /// player struct for internal pass on
    struct Player {
        bool register;
        uint256 playingH;
        uint256 playingM;
        address upline;
        uint256 starH;
        uint256 starM;
    }

    // playing table data struct
    struct PlayingTable {
        TablePrice price;
        uint16 no;
        uint8 star;
    }

    // player information for getter
    struct PlayerInfo {
        bool register;
        bool playing;
        address account;
        address upline;
        address[] downlines;
        PlayingTable[] playingTable;
    }

    //original => system create
    //split => split from original
    enum TableType {
        Original,
        Split
    }

    //H => 1 ether
    //M => 0.5 ether
    enum TablePrice {
        H,
        M
    }

    /// table struct for internal pass on
    /// @dev also the order of the bytes
    struct Table {
        bool isOpen;
        TableType tableType;
        TablePrice price;
        uint256 index; //index at opening
    }

    // player information for getter
    struct TableInfo {
        bool isOpen;
        TableType tableType;
        uint256 price;
        address[] seats;
        uint16 tableNo;
        TablePrice priceType;
    }

    uint256 internal playerCount; //total player count
    uint256 internal tableCount; //total table count
    mapping(address => bytes32) internal players; //map[player address]Player struct encode
    mapping(uint256 => bytes32) internal tables; //map[table no]Table struct encode

    //binding player and his downlines
    mapping(address => address[]) downlines; //map[player address]downlines address

    //relation price and opening table..
    mapping(uint256 => uint256[]) internal opening; //map[TablePrice]tables no

    // seats arranged:
    //      0
    //     1 2
    //   3 4 5 6
    mapping(uint256 => address[]) seats; //map[table no]player adderss

    //------------- functions ----------------------

    /// @dev replace constructor
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    function initialize() public virtual initializer {
        tableCount = 1;
    }

    /// @notice Serialization Player struct
    /// @param _player Player struct
    /// @return bytecode struct field data encode
    function PlayerSerializing(Player memory _player) internal pure returns (bytes32 bytecode) {
        uint8 register = _player.register == true ? 1 : 0;
        uint8 starH = _player.starH.toUint8();
        uint8 starM = _player.starM.toUint8();
        uint16 playingH = _player.playingH.toUint16();
        uint16 playingM = _player.playingM.toUint16();
        address upline = _player.upline;

        assembly {
            mstore(0x20, register)
            mstore(0x1f, starH)
            mstore(0x1e, starM)
            mstore(0x1d, playingH)
            mstore(0x1b, playingM)
            mstore(0x19, upline)

            bytecode := mload(0x20)
        }
    }

    /// @notice Deserialization Player struct
    /// @param _bytecode struct field data encode
    /// @return player Player struct
    function PlayerDeserializing(bytes32 _bytecode) internal pure returns (Player memory player) {
        uint8 register;
        uint8 starH;
        uint8 starM;
        uint16 playingH;
        uint16 playingM;
        address upline;

        assembly {
            register := _bytecode
            mstore(0x20, _bytecode)
            starH := or(mload(0x1f), 0)
            starM := or(mload(0x1e), 0)
            playingH := or(mload(0x1d), 0)
            playingM := or(mload(0x1b), 0)
            upline := or(mload(0x19), 0)
        }

        player = Player({
            register: register == 1,
            starH: uint256(starH),
            starM: uint256(starM),
            playingH: uint256(playingH),
            playingM: uint256(playingM),
            upline: upline
        });
    }

    /// @notice player getter
    /// @param _addr player address
    /// @return player Player struct
    function getPlayer(address _addr) internal view returns (Player memory player) {
        bytes32 p = players[_addr];
        player = PlayerDeserializing(p);
    }

    /// @notice player setter
    /// @param _addr player address
    /// @param _player ByteCode struct
    function setPlayer(address _addr, Player memory _player) internal {
        bytes32 p = PlayerSerializing(_player);
        players[_addr] = p;
    }

    /// @notice increment player count
    /// @return count before addition count
    function incrementPlayer() internal returns (uint256 count) {
        count = playerCount;
        playerCount++;
    }

    /// @notice get player register field
    /// @param _addr player address
    /// @return register bool
    function getPlayerRegisetr(address _addr) internal view returns (bool register) {
        Player memory p = getPlayer(_addr);
        return p.register;
    }

    /// @notice player star field getter
    /// @param _addr player address
    /// @return star star amount
    function getPlayerStar(address _addr, TablePrice _price) internal view returns (uint256) {
        Player memory p = getPlayer(_addr);
        return _price == TablePrice.H ? p.starH : p.starM;
    }

    /// @notice player star field setter
    /// @param _addr player address
    /// @param _addr player address
    function setPlayerStar(
        address _addr,
        uint256 _amount,
        TablePrice _price
    ) internal {
        assert(_amount <= 2); //maximum 2
        Player memory p = getPlayer(_addr);
        _price == TablePrice.H ? p.starH = _amount : p.starM = _amount;
        setPlayer(_addr, p);
    }

    /// @notice get player address field
    /// @param _addr player address
    /// @return upline upline address
    function getPlayerUpline(address _addr) internal view returns (address upline) {
        Player memory p = getPlayer(_addr);
        return p.upline;
    }

    /// @notice get playing table by player address and TablePrice enum
    /// @param _addr player address
    /// @param _price TablePrice enum
    /// @return no table no
    function getPlayingTable(address _addr, TablePrice _price) internal view returns (uint256 no) {
        Player memory p = getPlayer(_addr);
        return _price == TablePrice.H ? p.playingH : p.playingM;
    }

    /// @notice playingTable setter
    /// @param _no table no
    /// @param _price table price
    /// @param _addr player address
    function setPlayingTable(
        address _addr,
        TablePrice _price,
        uint256 _no
    ) internal {
        Player memory p = getPlayer(_addr);
        if (_price == TablePrice.H) {
            p.playingH = _no;
        }
        if (_price == TablePrice.M) {
            p.playingM = _no;
        }
        setPlayer(_addr, p);
    }

    //-------------- downlines -------------------

    /// @notice get downlines by player adderss
    /// @param _addr player address
    /// @return downlines array of downlines
    function getDownlines(address _addr) internal view returns (address[] storage) {
        return downlines[_addr];
    }

    /// @notice push downline to downlines field
    /// @param _addr player address
    /// @param _downline downline address
    function pushDownlines(address _addr, address _downline) internal {
        downlines[_addr].push(_downline);
    }

    //---------- tables -------------------

    /// @notice Serialization Table struct
    /// @param _table Table struct
    /// @return bytecode struct field data encode
    function TableSerializing(Table memory _table) internal pure returns (bytes32 bytecode) {
        uint8 isOpen = _table.isOpen == true ? 1 : 0;
        uint8 tableType = uint8(_table.tableType);
        uint8 price = uint8(_table.price);
        uint16 index = _table.index.toUint16();

        assembly {
            mstore(0x20, isOpen)
            mstore(0x1f, tableType)
            mstore(0x1e, price)
            mstore(0x1d, index)

            bytecode := mload(0x20)
        }
    }

    /// @notice Deserialization Table struct
    /// @param _bytecode struct field data encode
    /// @return table Player struct
    function TableDeserializing(bytes32 _bytecode) internal pure returns (Table memory table) {
        uint8 isOpen;
        uint8 tableType;
        uint8 price;
        uint16 index;

        assembly {
            isOpen := _bytecode
            mstore(0x20, _bytecode)
            tableType := or(mload(0x1f), 0)
            price := or(mload(0x1e), 0)
            index := or(mload(0x1d), 0)
        }

        table = Table({
            isOpen: isOpen == 1,
            tableType: TableType(tableType),
            price: TablePrice(price),
            index: uint256(index)
        });
    }

    /// @notice get opening data
    function getOpening(TablePrice _price, uint256 _index) internal view returns (uint256 no) {
        uint256 price = uint256(_price);
        no = opening[price][_index];
        return no;
    }

    /// @notice push table no to opening mapping
    function pushOpening(TablePrice _price, uint256 _no) internal returns (uint256 index) {
        uint256 price = uint256(_price);
        opening[price].push(_no);
        index = index > 0 ? index - 1 : 0;
        return index;
    }

    /// @notice delete opening data by price and index
    /// @param _price table price
    /// @param _index array index
    /// @param _no table no for require
    function deleteOpening(
        TablePrice _price,
        uint256 _index,
        uint256 _no
    ) internal returns (bool) {
        uint256 price = uint256(_price);
        uint256 no = opening[price][_index];
        if (no == _no) {
            delete (opening[price][_index]);
            return true;
        }

        //shit..index dirty..
        uint256[] storage open = opening[price];
        for (uint256 i = 0; i < open.length; i++) {
            if (open[i] == _no) {
                delete (open[i]);
                return true;
            }
            if (i == 20) {
                //limit number of iterations...because block gas limit rule
                break;
            }
        }
        return false;
    }

    /// @notice table getter
    /// @param _no table no
    /// @return table Table struct
    function getTable(uint256 _no) internal view returns (Table memory table) {
        bytes32 t = tables[_no];
        table = TableDeserializing(t);
        return table;
    }

    /// @notice table setter
    /// @param _no table no
    /// @param _table ByteCode struct
    function setTable(uint256 _no, Table memory _table) internal {
        bytes32 t = TableSerializing(_table);
        tables[_no] = t;
    }

    /// @notice increment table count
    /// @return count before addition count
    function incrementTable() internal returns (uint256 count) {
        count = tableCount;
        tableCount++;
    }

    /// @notice get table isOpen field
    /// @param _no table no
    /// @return isOpen bool
    function getTableIsOpen(uint256 _no) internal view returns (bool isOpen) {
        Table memory t = getTable(_no);
        return t.isOpen;
    }

    /// @notice set table isOpen field
    /// @param _no table no
    /// @param _isOpen isOpen
    function setTableIsOpen(uint256 _no, bool _isOpen) internal {
        Table memory t = getTable(_no);
        t.isOpen = _isOpen;
        setTable(_no, t);
    }

    /// @notice get tableType field
    /// @param _no table no
    /// @return tableType TableType enum
    function getTableType(uint256 _no) internal view returns (TableType tableType) {
        Table memory t = getTable(_no);
        return t.tableType;
    }

    /// @notice get table price field
    /// @param _no table no
    /// @return price TablePrice enum
    function getTablePrice(uint256 _no) internal view returns (TablePrice price) {
        Table memory t = getTable(_no);
        return t.price;
    }

    /// @notice table index field getter
    /// @param _no table no
    /// @return index uint16
    function getTableIndex(uint256 _no) internal view returns (uint256 index) {
        Table memory t = getTable(_no);
        return t.index;
    }

    /// @notice table index field setter
    /// @param _no table no
    /// @param _index opening index
    function setTableIndex(uint256 _no, uint256 _index) internal {
        Table memory t = getTable(_no);
        t.index = _index;
        setTable(_no, t);
    }

    /// @notice table seats field getter
    /// @param _no table no
    /// @return seats address[]
    function getTableSeats(uint256 _no) internal view returns (address[] storage) {
        return seats[_no];
    }

    /// @notice push player to table seats field
    /// @param _no table no
    /// @param _addr player address
    function pushTableSeats(uint256 _no, address _addr) internal {
        assert(seats[_no].length < 7);
        seats[_no].push(_addr);
    }

    //================ v2 add =========================

    /// @notice delete player from table seats field
    /// @dev v2 add; re sort sequence
    /// @param _no table no
    /// @param _addr player address
    function deleteTableSeats(uint256 _no, address _addr) internal {
        address[] storage tbSeats = seats[_no];
        bool exist = false;
        uint256 inx = 0;

        //check the _addr exist
        for (uint256 i = 0; i < tbSeats.length; i++) {
            if (i > 7) {
                break;
            }
            if (tbSeats[i] != _addr) {
                tbSeats[inx] = tbSeats[i];
                inx++;
            } else {
                exist = true;
            }
        }

        if (exist) {
            tbSeats.pop();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

