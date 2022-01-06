// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/ICompetitionFactory.sol";
import "./interface/IRegularCompetitionContract.sol";
import "./interface/IChainLinkOracleSportData.sol";
import "./interface/IP2PCompetitionContract.sol";
import "./interface/ICompetitionContract.sol";

contract CompetitionPool is Ownable {
    using SafeERC20 for IERC20;

    struct BetSLip {
        ICompetitionContract competionContract;
        uint256 numberOfVotesPlayer1;
        uint256 numberOfVotesPlayer2;
    }

    struct Competition {
        string sportType;
        string matchName;
        string streamLink;
        string player1Name;
        string player2Name;
        address player2;
        bool isPublic;
        uint256 entryFee;
    }

    struct Pool {
        Type competitonType;
        bool existed;
    }

    enum Type {
        Regular,
        P2P
    }

    address public tokenAddress;
    address public linkTokenForOracle;
    address oracle;
    ICompetitionFactory public competitionFactory; /////////////////////////////////

    address[] public pools;
    mapping(address => address) public creator;
    mapping(address => Pool) public existed;

    uint256[] bracketsAmountToken;
    uint256 public decimalOfRate;
    mapping(uint256 => uint256[]) public rewardRate; // uint =>[creator, owner, winner]

    event CreatedNewRegularCompetition(
        address indexed _creator,
        address _contracts
    );
    event CreatedNewP2PCompetition(
        address indexed _creator,
        address _contracts
    );
    event RewardRate(
        uint256[] _bracketsAmountToken,
        uint256[] _rewardRateOfcreator,
        uint256[] _rewardRateOfOwner,
        uint256[] _rewardRateOfWinner,
        uint256 _decimalOfRate
    );
    event ReceivedETH(address sender, uint256 value);
    event Factory(address _factory);

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    constructor(
        address _chainlinkOracleSportData,
        address _competitionFactory,
        address _tokenAddress
    ) {
        oracle = _chainlinkOracleSportData;
        competitionFactory = ICompetitionFactory(_competitionFactory);
        tokenAddress = _tokenAddress;
    }

    modifier onlyExistedPool(address _pool) {
        require(existed[_pool].existed, "CompetitionPool: Pool not found");
        _;
    }

    modifier onlyBettingOwner(address _pool) {
        require(creator[_pool] == msg.sender, "CompetitionPool: Only Creator");
        _;
    }

    function setFactory(address _factory) public onlyOwner {
        competitionFactory = ICompetitionFactory(_factory);
        emit Factory(_factory);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setLinkTokenAddress(address _linkTokenAddress) public onlyOwner {
        linkTokenForOracle = _linkTokenAddress;
    }

    function setRewardRates(
        uint256[] memory _bracketsAmountToken,
        uint256[] memory _rewardRateOfcreator,
        uint256[] memory _rewardRateOfOwner,
        uint256 _decimalOfRate
    ) public onlyOwner {
        require(
            _bracketsAmountToken.length == _rewardRateOfcreator.length &&
                _bracketsAmountToken.length == _rewardRateOfOwner.length,
            "CompetitionPool: Arrays must be of equal length"
        );
        require(
            _bracketsAmountToken[0] == 0,
            "CompetitionPool: _bracketsAmountToken[0] must be Zero"
        );
        for (uint256 i = 0; i < _bracketsAmountToken.length - 1; i++) {
            require(
                _bracketsAmountToken[i] < _bracketsAmountToken[i + 1],
                "CompetitionPool: _bracketsAmountToken must be sorted ascending"
            );
            require(
                _rewardRateOfcreator[i] + _rewardRateOfOwner[i] <=
                    10**(decimalOfRate + 2),
                "CompetitionPool: rewardRateOfcreator + rewardRateOfOwner must be <=100%"
            );
        }
        bracketsAmountToken = _bracketsAmountToken;
        decimalOfRate = _decimalOfRate;
        uint256[] memory _rewardRateOfWinner = new uint256[](
            bracketsAmountToken.length
        );
        for (uint256 i = 0; i < bracketsAmountToken.length; i++) {
            _rewardRateOfWinner[i] =
                10**(decimalOfRate + 2) -
                _rewardRateOfcreator[i] -
                _rewardRateOfOwner[i];

            setRewardRate(
                i,
                _rewardRateOfcreator[i],
                _rewardRateOfOwner[i],
                10**(decimalOfRate + 2) -
                    _rewardRateOfcreator[i] -
                    _rewardRateOfOwner[i]
            );
        }
        emit RewardRate(
            _bracketsAmountToken,
            _rewardRateOfcreator,
            _rewardRateOfOwner,
            _rewardRateOfWinner,
            _decimalOfRate
        );
    }

    function getBracketsAmountToken() public view returns (uint256[] memory) {
        return bracketsAmountToken;
    }

    function setRewardRate(
        uint256 _index,
        uint256 _rewardRateOfcreator,
        uint256 _rewardRateOfowner,
        uint256 _rewardRateOfWinner
    ) internal onlyOwner {
        require(
            _index >= 0 && _index < bracketsAmountToken.length,
            "CompetitionPool: Index is incorrect"
        );
        rewardRate[_index] = [
            _rewardRateOfcreator,
            _rewardRateOfowner,
            _rewardRateOfWinner
        ];
    }

    function getRewardRate(uint256 _index)
        public
        view
        returns (uint256[] memory, uint256)
    {
        return (rewardRate[_index], decimalOfRate);
    }

    function getTotalLinkToken() public view returns (uint256) {
        return IERC20(linkTokenForOracle).balanceOf(address(this));
    }

    function betSlip(BetSLip[] memory _betSlipList) public payable {
        uint256 totalFee;
        for (uint256 i = 0; i < _betSlipList.length; i++) {
            totalFee +=
                ICompetitionContract(_betSlipList[i].competionContract)
                    .getEntryFee() *
                (_betSlipList[i].numberOfVotesPlayer1 +
                    _betSlipList[i].numberOfVotesPlayer2);
        }
        require(
            msg.value == totalFee,
            "CompetitionPool: Please send enough ETH"
        );

        for (uint256 i = 0; i < _betSlipList.length; i++) {
            ICompetitionContract competitionContract = ICompetitionContract(
                _betSlipList[i].competionContract
            );

            require(
                existed[address(competitionContract)].existed,
                "CompetitionPool: Pool not found"
            );
            competitionContract.placeBet{
                value: competitionContract.getEntryFee() *
                    (_betSlipList[i].numberOfVotesPlayer1 +
                        _betSlipList[i].numberOfVotesPlayer2)
            }(
                msg.sender,
                _betSlipList[i].numberOfVotesPlayer1,
                _betSlipList[i].numberOfVotesPlayer2
            );
        }
    }

    function createNewRegularCompetition(
        uint256 _competitionId,
        bool _isPublic,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee,
        uint256 _player1,
        uint256 _player2
    ) public payable returns (address) {
        address competitionContract = competitionFactory
            .createRegularCompetitionContract(address(this), msg.sender);
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.Regular, true);
        creator[competitionContract] = msg.sender;
        emit CreatedNewRegularCompetition(msg.sender, competitionContract);

        IRegularCompetitionContract(competitionContract).setBasic(
            _isPublic,
            _startTimestamp,
            _endTimestamp,
            _entryFee
        );

        IRegularCompetitionContract(competitionContract).setCompetition(
            _competitionId,
            _player1,
            _player2
        );
        IRegularCompetitionContract(competitionContract).setOracle(oracle);

        _setRateforCreator(competitionContract);

        if (msg.value > 0) {
            IRegularCompetitionContract(competitionContract).depositEth{
                value: msg.value
            }();
        }

        IRegularCompetitionContract(competitionContract).start();

        return address(competitionContract);
    }

    function createNewP2PCompetition(
        Competition memory _competition,
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _startP2PTime,
        uint256 _endP2PTime,
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime
    ) public payable returns (address) {
        require(
            block.timestamp <= _startBetTime,
            "CompetitionPool: Time is illegal"
        );
        address competitionContract = competitionFactory
            .createP2PCompetitionContract(address(this), msg.sender);
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.P2P, true);
        creator[competitionContract] = msg.sender;
        emit CreatedNewP2PCompetition(msg.sender, competitionContract);

        IP2PCompetitionContract(competitionContract).setStartAndEndTimestamp(
            _startBetTime,
            _endBetTime,
            _startP2PTime,
            _endP2PTime
        );

        IP2PCompetitionContract(competitionContract).setBasic(
            _competition.sportType,
            _competition.matchName,
            _competition.streamLink,
            _competition.player1Name,
            _competition.player2Name,
            _competition.player2,
            msg.sender
        );

        IP2PCompetitionContract(competitionContract).setEntryFee(
            _competition.entryFee
        );
        IP2PCompetitionContract(competitionContract).setDistanceTime(
            _distanceConfirmTime,
            _distanceVoteTime
        );
        IP2PCompetitionContract(competitionContract).setIsPublic(
            _competition.isPublic
        );

        _setRateforCreator(competitionContract);

        if (msg.value > 0) {
            IP2PCompetitionContract(competitionContract).depositEth{
                value: msg.value
            }();
        }

        return address(competitionContract);
    }

    function placeBet(
        address _competitionContract,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) public payable onlyExistedPool(_competitionContract) {
        ICompetitionContract competitionContract = ICompetitionContract(
            _competitionContract
        );
        uint256 fee = competitionContract.getEntryFee() *
            (_numberOfVotesPlayer1 + _numberOfVotesPlayer2);
        require(msg.value == fee, "CompetitionPool: Please send enough ETH");
        competitionContract.placeBet{value: fee}(
            msg.sender,
            _numberOfVotesPlayer1,
            _numberOfVotesPlayer2
        );
    }

    function depositeForCompetitonContract(address _competiton)
        public
        payable
        onlyExistedPool(_competiton)
        onlyBettingOwner(_competiton)
    {
        require(msg.value > 0, "CompetitionPool: Please send value >0");
        ICompetitionContract(_competiton).depositEth{value: msg.value}();
    }

    function depositeLinkTokenForOracle(uint256 _amount) public {
        require(_amount <= IERC20(linkTokenForOracle).balanceOf(address(this)));
        IERC20(linkTokenForOracle).safeTransfer(address(oracle), _amount);
    }

    function depositeLinkTokenForOracle(address _owner, uint256 _amount)
        public
    {
        IERC20(linkTokenForOracle).safeTransferFrom(
            _owner,
            address(oracle),
            _amount
        );
    }

    function close(address _pool) public onlyExistedPool(_pool) {
        ICompetitionContract(_pool).close();
    }

    function _setRateforCreator(address _pool) private {
        address _creator = creator[_pool];
        (
            uint256 _ownerRate,
            uint256 _creatorRate,
            uint256 _winnerRate
        ) = getRate(_creator);
        uint256[] memory rewardRateCopy = new uint256[](3);
        rewardRateCopy[0] = _ownerRate;
        rewardRateCopy[1] = _creatorRate;
        rewardRateCopy[2] = _winnerRate;
        ICompetitionContract(_pool).setRewardRate(
            rewardRateCopy,
            decimalOfRate
        );
    }

    function getRate(address _creator)
        public
        view
        returns (
            uint256 _ownerRate,
            uint256 _creatorRate,
            uint256 _winnerRate
        )
    {
        uint256 _index;
        uint256 balance = IERC20(tokenAddress).balanceOf(_creator);
        for (uint256 i = bracketsAmountToken.length - 1; i > 0; i--) {
            if (balance >= bracketsAmountToken[i]) {
                _index = i;
                break;
            }
        }
        return (
            rewardRate[_index][0],
            rewardRate[_index][1],
            rewardRate[_index][2]
        );
    }

    function withdrawETH(address payable _receiver, uint256 _value)
        public
        onlyOwner
    {
        Address.sendValue(_receiver, _value);
    }

    function withdrawAllETH(address payable _receiver) public onlyOwner {
        Address.sendValue(_receiver, address(this).balance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRegularCompetitionContract {
    struct Competition {
        uint256 competitionId;
        uint256 player1;
        uint256 player2;
        Player playerWon;
        uint256 winnerReward;
    }
    struct Voting {
        uint256 player1;
        uint256 player2;
    }

    enum Privacy {
        Private,
        Public
    }
    enum Status {
        Lock,
        Open,
        End
    }
    enum Player {
        NoPlayer,
        Player1,
        Player2
    }

    event PlaceBet(
        address indexed buyer,
        uint256 numberOfVotesPlayer1,
        uint256 numberOfVotesPlayer2,
        uint256 amount
    );
    event Ready(
        uint256 timestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    event Close(uint256 timestamp, Player playerWon, uint256 winnerReward);
    event RewardRate(
        uint256 _rewardRateOfcreator,
        uint256 _rewardRateOfowner,
        uint256 _rewardRateOfWinner
    );
    event Destroy(uint256 timestamp);
    event WithdrawReward(address user, uint256 amount);

    function setBasic(
        bool _isPublic,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee
    ) external returns (bool);

    function depositEth() external payable;

    function start() external;

    function placeBet(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function placeBet(
        address _user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function close() external;

    function getEntryFee() external view returns (uint256);

    function getTotalBalance() external view returns (uint256);

    function getTotalEthBet(address _user)
        external
        view
        returns (
            uint256 totalBetForPlayer1,
            uint256 totalBetForPlayer2,
            uint256 totalBet
        );

    function setRewardRate(
        uint256[] calldata _rewardRate,
        uint256 _decimalOfRate
    ) external;

    function setOracle(address _oracle) external;

    function setCompetition(
        uint256 _competitionId,
        uint256 _player1,
        uint256 _player2
    ) external;

    function withdrawReward() external;

    function destroyContract() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IP2PCompetitionContract {
    struct Competition {
        string sportType;
        string matchName;
        string streamLink;
        Player player1;
        Player player2;
        PlayerWon playerWon;
        uint256 winerReward;
        bool isAccept;
        bool resulted;
    }

    struct Voting {
        uint256 player1;
        uint256 player2;
    }

    struct Confirm {
        bool isConfirm;
        PlayerWon playerWon;
    }

    struct Player {
        address playerAddr;
        string playerName;
    }

    enum Privacy {
        Private,
        Public
    }
    enum Status {
        Lock,
        Open,
        End
    }
    enum PlayerWon {
        NoPlayer,
        Player1,
        Player2
    }

    event NewP2PCompetition(address indexed player1, address indexed player2);
    event PlaceBet(
        address indexed buyer,
        uint256 numberOfVotesPlayer1,
        uint256 numberOfVotesPlayer2,
        uint256 amount
    );
    event Ready(
        uint256 timestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    event Close(uint256 timestamp, PlayerWon playerWon, uint256 winerReward);
    event RewardRate(
        uint256 _rewardRateOfcreator,
        uint256 _rewardRateOfowner,
        uint256 _rewardRateOfWinner
    );
    event Destroy(uint256 timestamp);
    event WithdrawReward(address user, uint256 amount);
    event Accepted(address _player2, uint256 _timestamp);
    event ConfirmResult(address _player, bool _isWinner, uint256 _timestamp);
    event SetResult(bool _success);

    function getEntryFee() external view returns (uint256);

    function setRewardRate(uint256[] memory _rewardRate, uint256 _decimalOfRate)
        external;

    function setBasic(
        string memory _sportType,
        string memory _matchName,
        string memory _streamLink,
        string memory _player1Name,
        string memory _player2Name,
        address _player2,
        address _player1
    ) external payable returns (bool);

    function setEntryFee(uint256 _entryFee) external;

    function setStartAndEndTimestamp(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _startP2PTime,
        uint256 _endP2PTime
    ) external;

    function setDistanceTime(
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime
    ) external;

    function setIsPublic(bool _isPublic) external;

    function depositEth() external payable;

    function acceptBetting() external;

    function placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function confirmResult(bool _isWinner) external;

    function vote(bool _player1Win, bool _player2Win) external;

    function close() external;

    function claimable(address user)
        external
        view
        returns (bool canClaim, uint256 amount);

    function withdrawReward() external;

    function getTotalEthBet(address _user)
        external
        view
        returns (
            uint256 totalBetForPlayer1,
            uint256 totalBetForPlayer2,
            uint256 totalBet
        );

    function getTotalBalance() external view returns (uint256);

    function getPrivacy() external view returns (Privacy);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface ICompetitionFactory{
    function createRegularCompetitionContract(address  _owner, address  _creator)
        external
        returns (address);
        
    function createP2PCompetitionContract(address _owner, address _creator)
        external
        returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICompetitionContract {
    function getEntryFee() external view returns (uint256);

    function placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function depositEth() external payable;

    function close() external;

    function setRewardRate(uint256[] memory _rewardRate, uint256 _decimalOfRate)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IChainLinkOracleSportData {
    function getPayment() external returns (uint256);

    function requestData(uint256 _matchId) external returns (bytes32);

    function getData(bytes32 _id) external view returns (uint256[] memory);
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