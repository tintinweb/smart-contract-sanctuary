/**
 *Submitted for verification at Etherscan.io on 2021-03-18
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
    mapping(uint => Transaction) internal _transactions;
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

    function addManager(address manager) public onlyOwner {
        _managers[manager] = 1;
    }

    function removeManager(address manager) public onlyOwner {
        _managers[manager] = 0;
    }

    function getPendingTransactions() public view returns (uint[] memory){
        return _pendingTransactions;
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

        return (
        _transactions[transactionId].creator,
        _transactions[transactionId].teamId,
        _transactions[transactionId].teamAccount,
        _transactions[transactionId].newTeamAccount,
        _transactions[transactionId].agent,
        _transactions[transactionId].newAgent,
        _transactions[transactionId].signatureCount);
    }

    function deleteTransaction(uint transactionId) public isManager {
        require(_transactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        require(_transactions[transactionId].creator == msg.sender, 'YouSwap:CALLER_MUST_BE_THE_CREATER');
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

        delete _transactions[transactionId];
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

    address private _youToken;
    uint256 blocksOfMonth = 10;//3600/15*24*30;
    uint256 startHeight = 0;
    uint256 public constant totalSupplyForTeam = 3 * 10 ** 13;//15% of the total supply of YOU
    uint256 public suppliedForTeam = 0;
    uint private _decimals = 10;
    mapping(uint8 => Team) private _teams;

    event Claimed(address indexed recipient, uint8 teamId, uint256 amountOfYou);

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
        
        _teams[1].approved = true;
        _teams[1].account = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _teams[1].agent = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _teams[1].reserved = 150 * 10 ** _decimals;
        _teams[1].lastClaimedHeight = startHeight;
        
        _teams[2].approved = true;
        _teams[2].account = 0xfCa8243ADc135E043D73a6F68DEc771F086277F2;
        _teams[2].agent = 0xfCa8243ADc135E043D73a6F68DEc771F086277F2;
        _teams[2].reserved = 30 * 10 ** _decimals;
        _teams[2].lastClaimedHeight = startHeight;
        
        _teams[3].approved = true;
        _teams[3].account = 0x2a5e20e25B8fEbFbB00f4278f976a7e97cBaFebd;
        _teams[3].agent = 0x2a5e20e25B8fEbFbB00f4278f976a7e97cBaFebd;
        _teams[3].reserved = 100 * 10 ** _decimals;
        _teams[3].lastClaimedHeight = startHeight;

        _teams[4].approved = true;
        _teams[4].account = 0x80b10F9b9D67FD8CCA73624c1da1e3F8BD14970f;
        _teams[4].agent = 0x80b10F9b9D67FD8CCA73624c1da1e3F8BD14970f;
        _teams[4].reserved = 100 * 10 ** _decimals;
        _teams[4].lastClaimedHeight = startHeight;

        _teams[5].approved = true;
        _teams[5].account = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _teams[5].agent = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _teams[5].reserved = 30 * 10 ** _decimals;
        _teams[5].lastClaimedHeight = startHeight;

        _teams[6].approved = true;
        _teams[6].account = 0x9Eb6040Ba1656e5fD5763B8f4E6CD9Af538B6bE6;
        _teams[6].agent = 0x9Eb6040Ba1656e5fD5763B8f4E6CD9Af538B6bE6;
        _teams[6].reserved = 590 * 10 ** _decimals;
        _teams[6].lastClaimedHeight = startHeight;

        _teams[7].approved = true;
        _teams[7].account = 0x80b56548ba2FeCA57713E41513acfD70bb55f8a3;
        _teams[7].agent = 0xfCa8243ADc135E043D73a6F68DEc771F086277F2;
        _teams[7].reserved = 500 * 10 ** _decimals;
        _teams[7].lastClaimedHeight = startHeight;

        _teams[8].approved = true;
        _teams[8].account = 0x3973ddD9b4660211194a01303f0D03D5b93806D7;
        _teams[8].agent = 0xfCa8243ADc135E043D73a6F68DEc771F086277F2;
        _teams[8].reserved = 600 * 10 ** _decimals;
        _teams[8].lastClaimedHeight = startHeight;

        _teams[9].approved = true;
        _teams[9].account = 0xAB82C265F010943758ab44df317AB95Aee2bC09a;
        _teams[9].agent = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _teams[9].reserved = 900 * 10 ** _decimals;
        _teams[9].lastClaimedHeight = startHeight;
    }
    
    function nextClaimHeightOf(uint8 teamId) external view returns (uint256) {
        return _teams[teamId].lastClaimedHeight + blocksOfMonth;
    }

    function claimedOf(uint8 teamId) external view returns (uint256) {
        return _teams[teamId].claimed;
    }

    function balanceOf(uint8 teamId) external view returns (uint256) {
        return _teams[teamId].reserved - _teams[teamId].claimed;
    }

    function updateTeam(uint8 teamId, address newAccount, address newAgent) isManager external lock returns (uint256) {
        require(_teams[teamId].approved, 'YouSwap: NOT_EXIST');
        uint transactionId = ++_nonce;
        Transaction storage transaction =  _transactions[transactionId];
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

        _pendingTransactions.push(transactionId);

        emit TransactionCreated(msg.sender, teamId, _teams[teamId].account, newAccount, _teams[teamId].agent, newAgent, transactionId);

        return transactionId;
    }

    function teamOf(uint8 teamId)  external view returns
    (
        address account,
        address agent,
        uint256 reserved,
        uint256 claimed,
        uint8 claimedTimes,
        uint256 lastClaimedHeight
    ) {
        return
        (
        _teams[teamId].account,
        _teams[teamId].agent,
        _teams[teamId].reserved,
        _teams[teamId].claimed,
        _teams[teamId].claimedTimes,
        _teams[teamId].lastClaimedHeight
        );
    }

    function claim(uint8 teamId) external lock {
        require(_teams[teamId].approved, 'YouSwap: TEAM_NOT_EXIST');
        require(_teams[teamId].agent == msg.sender, 'YouSwap: NOT_ALLOWED');
        require(_teams[teamId].claimed < _teams[teamId].reserved, 'YouSwap: EXCEEDS_THE_RESERVED_AMOUNT');
        uint deltaBlocks = block.number - _teams[teamId].lastClaimedHeight;
        require(deltaBlocks >= blocksOfMonth, 'YouSwap: CLAIMED_THIS_MONTH');

        uint times = deltaBlocks.div(blocksOfMonth);
        uint256 canClaimThisTime = _teams[teamId].reserved.div(60).mul(times);

        if (_teams[teamId].claimed.add(canClaimThisTime) > _teams[teamId].reserved) {
            canClaimThisTime = _teams[teamId].reserved.sub(_teams[teamId].claimed);
        }
        _mintYou(_teams[teamId].account, canClaimThisTime);
        _teams[teamId].claimed = _teams[teamId].claimed.add(canClaimThisTime);

        _teams[teamId].lastClaimedHeight = _teams[teamId].lastClaimedHeight.add(blocksOfMonth * times);

        suppliedForTeam += canClaimThisTime;
        require(suppliedForTeam <= totalSupplyForTeam, 'YouSwap: EXCEEDS_THE_UPPER_LIMIT');
        emit Claimed(_teams[teamId].account, teamId, canClaimThisTime);
    }

    function _mintYou(address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = _youToken.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function signTransaction(uint transactionId) public lock isManager {
        require(_transactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        Transaction storage transaction = _transactions[transactionId];
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