/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity = 0.5.16;

library SafeMath {
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
        uint256 c = a + b;
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "YouSwap: CALLER_IS_NOT_THE_OWNER");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "YouSwap: NEW_OWNER_IS_THE_ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Management is Ownable {
    mapping(address => uint8) private _managers;
    uint internal _nonce;
    mapping(uint => Transaction) internal _pendingTransactions;
    uint[] internal _pendingTxIDs;

    uint internal constant MIN_SIGNATURES = 3;
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'YouSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    struct Transaction {
        uint8 state;
        address creator;
        uint8 teamId;
        address teamAccount;
        address newTeamAccount;
        address agent;
        address newAgent;
        uint8 signatureCount;
        mapping(address => uint8) signatures;
    }

    event TransactionCreated(
        address creator,
        uint8 teamId,
        address teamAccount,
        address newTeamAccount,
        address teamAgent,
        address newTeamAgent,
        uint transactionId
    );

    constructor() internal {
        _managers[0xf3c5C84E69163bD60D49A90cC4d4b7f12bb592d2] = 1;
        _managers[0xD391FF3F474478aB9517aabD8cA22c599c6E6314] = 1;
        _managers[0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F] = 1;
    }

    modifier isManager{
        require(_managers[msg.sender] == 1, "CALLER_IS_NOT_A_MANAGER");
        _;
    }

    function addManager(address manager) external onlyOwner {
        _managers[manager] = 1;
    }

    function removeManager(address manager) external onlyOwner {
        _managers[manager] = 0;
    }

    function getPendingTxIDs() external view returns (uint[] memory){
        return _pendingTxIDs;
    }

    function getPendingTransaction(uint transactionId) external view returns
    (
        address creator,
        uint8 teamId,
        address teamAccount,
        address newTeamAccount,
        address teamAgent,
        address newTeamAgent,
        uint8 signatureCount){

        require(_pendingTransactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');

        return (
        _pendingTransactions[transactionId].creator,
        _pendingTransactions[transactionId].teamId,
        _pendingTransactions[transactionId].teamAccount,
        _pendingTransactions[transactionId].newTeamAccount,
        _pendingTransactions[transactionId].agent,
        _pendingTransactions[transactionId].newAgent,
        _pendingTransactions[transactionId].signatureCount);
    }

    function deleteTransaction(uint transactionId) public isManager {
        require(_pendingTransactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        uint8 replace = 0;
        for (uint i = 0; i < _pendingTxIDs.length; i++) {
            if (1 == replace) {
                _pendingTxIDs[i - 1] = _pendingTxIDs[i];
            }

            if (transactionId == _pendingTxIDs[i]) {
                replace = 1;
            }
        }
        delete _pendingTxIDs[_pendingTxIDs.length - 1];
        _pendingTxIDs.length--;

        delete _pendingTransactions[transactionId];
    }
}

contract YouDispatch is Management {
    using SafeMath for uint256;

    struct Team {
        address account;
        address agent;
        uint256 reserved;
        uint256 claimed;
        uint8 claims;
        uint256 lastClaimTime;
        uint256 packageI;
        uint256 packageII;
        uint256 packageIII;
        uint256 packageIV;
        bool approved;
    }

    //2021-03-26 00:00:00 UTC epoch
    uint256 public startTime = 1616716800;
    uint256 private constant oneDay = 1 minutes;//1 days;
    uint256 public constant oneMonth = oneDay * 3;//oneDay * 30;
    uint256 public constant totalSupply = 4 * 10 ** 13;//30 million for startup team, 10 million for investment organizations
    uint256 public totalClaimed = 0;
    uint256 public approved = 0;
    uint8 private _teamId = 0;
    mapping(uint8 => Team) private _teams;
    address public constant youToken = 0x941BF24605b3cb640717eEb19Df707954CE85ebe;

    event Claimed(
        address indexed recipient,
        uint8 teamId,
        uint256 amountOfYou
    );

    event ApproveTeam(
        uint8 teamId,
        address indexed account,
        address indexed agent,
        uint256 reserve
    );

    event TeamUpdated(
        uint8 teamId,
        address indexed oldAccount,
        address newAccount,
        address indexed oldAgent,
        address newAgent
    );
    
    constructor() public {
        //Core teams
        approve(0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F,0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F,1500000000000,1);
        approve(0x423FbD16E47aB73A9d0Aeb32Cd1ee5512B5c581f,0x423FbD16E47aB73A9d0Aeb32Cd1ee5512B5c581f,400000000000,2);
        approve(0x62282826a13b030b15A0133994E2c51622437942,0x62282826a13b030b15A0133994E2c51622437942,1000000000000,3);
        approve(0xC1D1280cBe4432f4Ba29d1531952B968Ce266FcC,0xC1D1280cBe4432f4Ba29d1531952B968Ce266FcC,1000000000000,4);
        approve(0x570De9F71cbf7d7ED0fCE4907701a2b94F79DFBE,0x570De9F71cbf7d7ED0fCE4907701a2b94F79DFBE,300000000000,5);
        approve(0x2a553eE93cAc2945526fE7F25FBe98609db0bAB8,0xfCa8243ADc135E043D73a6F68DEc771F086277F2,5800000000000,6);
        approve(0x54705E4cf673A601962867156B9f190cd26193dA,0xfCa8243ADc135E043D73a6F68DEc771F086277F2,5000000000000,7);
        approve(0x1ad4FB7ce96F9a743ac977121b5Bce15c3765618,0xfCa8243ADc135E043D73a6F68DEc771F086277F2,6000000000000,8);
        approve(0x3c79a5582Dc2f59e311374FD2a00379d59534BB9,0xfCa8243ADc135E043D73a6F68DEc771F086277F2,9000000000000,9);
        //Investment organizations
        approve(0xd76ea05E548D9D72B5c3b644367aDC8e31a2d8a1,0x51FF7A7Eb5Ca5936A4084cCF7F545dE3550b93b5,2500000000000,10);
        approve(0xA1495825865790E5CaB1C00AF620fc73A26D5F0c,0x51FF7A7Eb5Ca5936A4084cCF7F545dE3550b93b5,2500000000000,11);
        approve(0x591d4298a8952eCb5a7d8614cF7f02a6dD78C619,0x51FF7A7Eb5Ca5936A4084cCF7F545dE3550b93b5,2500000000000,12);
        approve(0xba468580B83f6a93e3a70796D4a861F34F8340a8,0x51FF7A7Eb5Ca5936A4084cCF7F545dE3550b93b5,2500000000000,13);
    }
    
    function approve(address account, address agent, uint256 reserve, uint8 teamId) internal onlyOwner {
        //require(approved.add(reserve) <= totalSupply, 'YouSwap: EXCEEDS_THE_TOTAL_SUPPLY_FOR_TEAM');

        _teams[teamId].approved = true;
        // _teams[teamId].account = account;
        // _teams[teamId].agent = agent;
        // _teams[teamId].reserved = reserve;

        // _teams[teamId].packageI = reserve.mul(12).div(100);
        // _teams[teamId].packageII = reserve.mul(27).div(100);
        // _teams[teamId].packageIII = reserve.mul(24).div(100);
        // _teams[teamId].packageIV = reserve.mul(37).div(100);

        // _teams[teamId].lastClaimTime = startTime;
        approved = approved.add(reserve);

        emit ApproveTeam(teamId, account, agent, reserve);
    }

    function teamOf(uint8 teamId) external view returns
    (
        address account,
        address agent,
        uint256 reserved,
        uint256 claimed,
        uint8 claims,
        uint256 lastClaimTime
    ) {
        require(_teams[teamId].approved, 'YouSwap: NOT_EXIST');
        return
        (
        _teams[teamId].account,
        _teams[teamId].agent,
        _teams[teamId].reserved,
        _teams[teamId].claimed,
        _teams[teamId].claims,
        _teams[teamId].lastClaimTime
        );
    }

    function nextClaimTimeOf(uint8 teamId) external view returns (uint256) {
        require(_teams[teamId].approved, 'YouSwap: NOT_EXIST');
        require(_teams[teamId].claimed < _teams[teamId].reserved, 'YouSwap: COMPLETED_ALREADY');
        return _teams[teamId].lastClaimTime.add(oneMonth);
    }

    function claimedOf(uint8 teamId) external view returns (uint256) {
        require(_teams[teamId].approved, 'YouSwap: NOT_EXIST');
        return _teams[teamId].claimed;
    }

    function balanceOf(uint8 teamId) external view returns (uint256) {
        require(_teams[teamId].approved, 'YouSwap: NOT_EXIST');
        return _teams[teamId].reserved.sub(_teams[teamId].claimed);
    }

    function updateTeam(uint8 teamId, address newAccount, address newAgent) isManager external returns (uint256) {
        require(_teams[teamId].approved, 'YouSwap: NOT_EXIST');
        uint transactionId = ++_nonce;
        Transaction storage transaction = _pendingTransactions[transactionId];
        require(transaction.state == 0, 'YouSwap: TRANSACTION_EXISTS');
        transaction.state = 1;
        transaction.creator = msg.sender;
        transaction.teamId = teamId;
        transaction.teamAccount = _teams[teamId].account;
        transaction.newTeamAccount = newAccount;
        transaction.agent = _teams[teamId].agent;
        transaction.newAgent = newAgent;
        transaction.signatureCount = 1;
        transaction.signatures[msg.sender] = 1;

        _pendingTxIDs.push(transactionId);

        emit TransactionCreated(msg.sender, teamId, _teams[teamId].account, newAccount, _teams[teamId].agent, newAgent, transactionId);

        return transactionId;
    }

    function claim(uint8 teamId) external lock {
        require(_teams[teamId].approved, 'YouSwap: TEAM_NOT_EXIST');
        require(_teams[teamId].agent == msg.sender || _teams[teamId].account == msg.sender, 'YouSwap: CALLER_IS_NOT_THE_OWNER_OR_AGENT');
        require(now >= _teams[teamId].lastClaimTime.add(oneMonth), 'YouSwap: TIME_IS_NOT_UP');
        require(_teams[teamId].claimed < _teams[teamId].reserved, 'YouSwap: EXCEEDS_THE_RESERVED_AMOUNT');

        uint256 times = 0;
        uint256 canClaimThisTime = 0;
        if (now <= startTime.add(oneMonth.mul(3))) {//The first stage of 3 months, normal claim-state
            times = now.sub(_teams[teamId].lastClaimTime).div(oneMonth);
            canClaimThisTime = _teams[teamId].packageI.div(3).mul(times);
            _teams[teamId].lastClaimTime = _teams[teamId].lastClaimTime.add(oneMonth.mul(times));
        }
        else if (now <= startTime.add(oneMonth.mul(12))) {//The second stage of 9 months(4~12month)
            if (_teams[teamId].lastClaimTime < startTime.add(oneMonth.mul(3))) {//Claim-progress still in the first stage,then just finish this stage
                canClaimThisTime = _teams[teamId].packageI.sub(_teams[teamId].claimed);
                _teams[teamId].lastClaimTime = startTime.add(oneMonth.mul(3));
            }
            else {//Claim-progress in the second stage(4~12month),normal claim-state
                times = now.sub(_teams[teamId].lastClaimTime).div(oneMonth);
                canClaimThisTime = _teams[teamId].packageII.div(9).mul(times);
                _teams[teamId].lastClaimTime = _teams[teamId].lastClaimTime.add(oneMonth.mul(times));
            }
        }
        else if (now <= startTime.add(oneMonth.mul(24))) {//The third stage of 12 months(13~24)
            if (_teams[teamId].lastClaimTime < startTime.add(oneMonth.mul(3))) {//Claim-progress still in the first stage,then just finish this stage
                canClaimThisTime = _teams[teamId].packageI.sub(_teams[teamId].claimed);
                _teams[teamId].lastClaimTime = startTime.add(oneMonth.mul(3));
            }
            else if (_teams[teamId].lastClaimTime < startTime.add(oneMonth.mul(12))) {//Only finish the second stage
                canClaimThisTime = _teams[teamId].packageII.add(_teams[teamId].packageI).sub(_teams[teamId].claimed);
                _teams[teamId].lastClaimTime = startTime.add(oneMonth.mul(12));
            }
            else {
                times = now.sub(_teams[teamId].lastClaimTime).div(oneMonth);
                canClaimThisTime = _teams[teamId].packageIII.div(12).mul(times);
                _teams[teamId].lastClaimTime = _teams[teamId].lastClaimTime.add(oneMonth.mul(times));
            }
        }
        else {//The fourth stage of 37 months
            if (_teams[teamId].lastClaimTime < startTime.add(oneMonth.mul(3))) {
                canClaimThisTime = _teams[teamId].packageI.sub(_teams[teamId].claimed);
                _teams[teamId].lastClaimTime = startTime.add(oneMonth.mul(3));
            }
            else if (_teams[teamId].lastClaimTime < startTime.add(oneMonth.mul(12))) {
                canClaimThisTime = _teams[teamId].packageII.add(_teams[teamId].packageI).sub(_teams[teamId].claimed);
                _teams[teamId].lastClaimTime = startTime.add(oneMonth.mul(12));
            }
            else if (_teams[teamId].lastClaimTime < startTime.add(oneMonth.mul(24))) {
                canClaimThisTime = _teams[teamId].packageIII.add(_teams[teamId].packageII).add(_teams[teamId].packageI).sub(_teams[teamId].claimed);
                _teams[teamId].lastClaimTime = startTime.add(oneMonth.mul(24));
            }
            else {
                times = now.sub(_teams[teamId].lastClaimTime).div(oneMonth);
                canClaimThisTime = _teams[teamId].packageIV.div(37).mul(times);
                if (_teams[teamId].claimed.add(canClaimThisTime).add(10000) > _teams[teamId].reserved) {//The last month
                    canClaimThisTime = _teams[teamId].reserved.sub(_teams[teamId].claimed);
                }
                _teams[teamId].lastClaimTime = _teams[teamId].lastClaimTime.add(oneMonth.mul(times));
            }
        }

        _mintYou(_teams[teamId].account, canClaimThisTime);
        _teams[teamId].claimed = _teams[teamId].claimed.add(canClaimThisTime);

        totalClaimed = totalClaimed.add(canClaimThisTime);
        require(totalClaimed <= totalSupply, 'YouSwap: EXCEEDS_THE_UPPER_LIMIT');
        emit Claimed(_teams[teamId].account, teamId, canClaimThisTime);
    }

    function _mintYou(address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = youToken.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: MINT_FAILED');
    }

    function signTransaction(uint transactionId) external lock isManager {
        require(_pendingTransactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        Transaction storage transaction = _pendingTransactions[transactionId];
        require(transaction.signatures[msg.sender] != 1, "YouSwap: SIGNED_ALREADY");
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        if (transaction.signatureCount >= MIN_SIGNATURES) {
            _teams[transaction.teamId].account = transaction.newTeamAccount;
            _teams[transaction.teamId].agent = transaction.newAgent;
            emit TeamUpdated(transaction.teamId, transaction.teamAccount, transaction.newTeamAccount, transaction.agent, transaction.newAgent);

            deleteTransaction(transactionId);
        }
    }
}