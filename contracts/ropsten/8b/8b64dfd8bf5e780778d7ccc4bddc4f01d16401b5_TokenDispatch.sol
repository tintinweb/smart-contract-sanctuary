/**
 *Submitted for verification at Etherscan.io on 2021-03-20
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
    mapping(uint => Transaction) internal transactions;
    uint[] internal _pendingTransactions;

    uint constant MIN_SIGNATURES = 2;

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

    constructor() public {
        _managers[0xEe5438029959499acD5F7e0470FF56426d4f79D8] = 1;
        _managers[0xEbB0300B8c14BE71C732146802af6054C3C231C0] = 1;
        _managers[0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F] = 1;
    }

    modifier isManager{
        require(_managers[msg.sender] == 1,"CALLER_IS_NOT_A_MANAGER");
        _;
    }

    function addManager(address manager) external onlyOwner {
        _managers[manager] = 1;
    }

    function removeManager(address manager) external onlyOwner {
        _managers[manager] = 0;
    }

    function getPendingTransactions() external view returns (uint[] memory){
        return _pendingTransactions;
    }

    function deleteTransaction(uint transactionId) public isManager {
        require(transactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        uint8 replace = 0;
        for (uint i = 0; i < _pendingTransactions.length; i++) {
            if (1 == replace) {
                _pendingTransactions[i - 1] = _pendingTransactions[i];
            }

            if (transactionId == _pendingTransactions[i]) {
                replace = 1;
            }
        }
        delete _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.length--;

        delete transactions[transactionId];
    }
}

contract TokenDispatch is Management {
    using SafeMath for uint256;

    struct Team {
        address account;
        address agent;
        uint256 reserved;
        uint256 claimed;
        uint8 claimedTimes;
        uint256 lastClaimedHeight;
        bool approved;
    }

    uint256 public startHeight = 0;
    uint256 public constant totalSupplyForTeam = 3 * 10 ** 13;//30 million, 15% of the total supply of YOU
    uint256 public suppliedForTeam = 0;
    uint256 public approvedForTeam = 0;
    mapping(uint8 => Team) public teams;
    uint8 private _teamId = 0;
    address private _youToken;
    uint256 private constant _blocksOfMonth = 10;//3600/12*24*30;
    uint8 private constant _decimals = 10;

    event Claimed(
        address indexed recipient, 
        uint8 teamId, 
        uint256 amountOfYou
        );

    event ApproveTeam(
        uint8 teamId,
        address indexed account,
        address indexed agent,
        uint256 approved
        );
    
    event TeamUpdated(
        uint8 teamId,
        address oldAccount,
        address newAccount,
        address oldAgent,
        address newAgent
    );

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'YouSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        _youToken = 0xBC36D680638F0339F55CABbE7C3C5D636D5CB7B6;
        startHeight = block.number;
    }
    
    function approveTeam(address account,address agent, uint256 approved) external lock onlyOwner {
        require(approvedForTeam.add(approved) <= totalSupplyForTeam, 'YouSwap: EXCEEDS_THE_TOTAL_SUPPLY_FOR_TEAM');
        _teamId ++;
        teams[_teamId].approved = true;
        teams[_teamId].account = account;
        teams[_teamId].agent = agent;
        teams[_teamId].reserved = approved;
        teams[_teamId].lastClaimedHeight = startHeight;
        approvedForTeam = approvedForTeam.add(approved);
         
       emit ApproveTeam(_teamId, account, agent, approved);
    }

    function nextClaimHeightOf(uint8 teamId) external view returns (uint256) {
        return teams[teamId].lastClaimedHeight + _blocksOfMonth;
    }

    function claimedOf(uint8 teamId) external view returns (uint256) {
        return teams[teamId].claimed;
    }

    function balanceOf(uint8 teamId) external view returns (uint256) {
        return teams[teamId].reserved - teams[teamId].claimed;
    }
    
    function updateTeam(uint8 teamId, address newAccount, address newAgent) isManager external lock returns (uint256) {
        require(teams[teamId].approved, 'YouSwap: NOT_EXIST');
        uint transactionId = ++_nonce;
        Transaction storage transaction =  transactions[transactionId];
         require(transaction.state == 0, 'YouSwap: TRANSACTION_EXISTS');
        transaction.state = 1;
        transaction.creator = msg.sender;
        transaction.teamId = teamId;
        transaction.teamAccount = teams[teamId].account;
        transaction.newTeamAccount = newAccount;
        transaction.agent = teams[teamId].agent;
        transaction.newAgent = newAgent;
        transaction.signatureCount = 1;
        transaction.signatures[msg.sender] = 1;

        _pendingTransactions.push(transactionId);

        emit TransactionCreated(msg.sender, teamId, teams[teamId].account, newAccount, teams[teamId].agent, newAgent, transactionId);

        return transactionId;
    }

    function claim(uint8 teamId) external lock {
        require(teams[teamId].approved, 'YouSwap: TEAM_NOT_EXIST');
        require(teams[teamId].agent == msg.sender, 'YouSwap: NOT_ALLOWED');
        require(teams[teamId].claimed < teams[teamId].reserved, 'YouSwap: EXCEEDS_THE_RESERVED_AMOUNT');
        uint deltaBlocks = block.number - teams[teamId].lastClaimedHeight;
        require(deltaBlocks >= _blocksOfMonth, 'YouSwap: CLAIMED_THIS_MONTH');

        uint times = deltaBlocks.div(_blocksOfMonth);
        uint256 canClaimThisTime = teams[teamId].reserved.div(60).mul(times);

        if (teams[teamId].claimed.add(canClaimThisTime) > teams[teamId].reserved) {
            canClaimThisTime = teams[teamId].reserved.sub(teams[teamId].claimed);
        }
        _mintYou(teams[teamId].account, canClaimThisTime);
        teams[teamId].claimed = teams[teamId].claimed.add(canClaimThisTime);

        teams[teamId].lastClaimedHeight = teams[teamId].lastClaimedHeight.add(_blocksOfMonth * times);

        suppliedForTeam += canClaimThisTime;
        require(suppliedForTeam <= totalSupplyForTeam, 'YouSwap: EXCEEDS_THE_UPPER_LIMIT');
        emit Claimed(teams[teamId].account, teamId, canClaimThisTime);
    }

    function _mintYou(address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = _youToken.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function signTransaction(uint transactionId) external lock isManager {
        require(transactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        Transaction storage transaction = transactions[transactionId];
        require(transaction.signatures[msg.sender] != 1, "YouSwap: SIGNED_ALREADY");
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        if (transaction.signatureCount >= MIN_SIGNATURES) {
            teams[transaction.teamId].account = transaction.newTeamAccount;
            teams[transaction.teamId].agent = transaction.newAgent;
            emit TeamUpdated(transaction.teamId, transaction.teamAccount, transaction.newTeamAccount, transaction.agent, transaction.newAgent);
            
            deleteTransaction(transactionId);
        }
    }
}