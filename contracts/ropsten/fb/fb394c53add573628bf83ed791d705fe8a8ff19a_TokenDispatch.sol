/**
 *Submitted for verification at Etherscan.io on 2021-03-13
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
    mapping(address => uint8) private managers;
    uint internal nonce;
    mapping(uint => Transaction) public transactions;
    uint[] internal pendingTransactions;

    uint constant MIN_SIGNATURES = 3;

    struct Transaction {
        address creator;
        uint8 benId;
        address benAccount;
        address newBenAccount;
        address agent;
        address newAgent;
        uint8 signatureCount;
        mapping(address => uint8) signatures;
    }

    event TransactionCreated(
        address creator,
        uint8 benId,
        address benAccount,
        address newBenAccount,
        address agent,
        address newAgent,
        uint transactionId
    );

    constructor() public {
        managers[0xf3c5C84E69163bD60D49A90cC4d4b7f12bb592d2] = 1;
        managers[0xD391FF3F474478aB9517aabD8cA22c599c6E6314] = 1;
        managers[0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F] = 1;
    }

    modifier isManager{
        require(managers[msg.sender] == 1);
        _;
    }

    function addManager(address manager) public onlyOwner {
        managers[manager] = 1;
    }

    function removeManager(address manager) public onlyOwner {
        managers[manager] = 0;
    }

    function getPendingTransactions() public isManager view returns (uint[] memory){
        return pendingTransactions;
    }

    function getPendingTransaction(uint transactionId) public isManager view returns
    (
        address creator,
        uint8 benId,
        address benAccount,
        address newBenAccount,
        address agent,
        address newAgent,
        uint8 signatureCount){
        return (
        transactions[transactionId].creator,
        transactions[transactionId].benId,
        transactions[transactionId].benAccount,
        transactions[transactionId].newBenAccount,
        transactions[transactionId].agent,
        transactions[transactionId].newAgent,
        transactions[transactionId].signatureCount);
    }

    function deleteTransactions(uint transactionId) public isManager {
        uint8 replace = 0;
        for (uint i = 0; i < pendingTransactions.length; i++) {
            if (1 == replace) {
                pendingTransactions[i - 1] = pendingTransactions[i];
            }

            if (transactionId == pendingTransactions[i]) {
                replace = 1;
            }
        }
        delete pendingTransactions[pendingTransactions.length - 1];
        pendingTransactions.length--;

        delete transactions[transactionId];
    }
}

contract TokenDispatch is Management {
    using SafeMath for uint256;

    struct beneficiary {
        address account;
        address agent;
        uint256 reserved;
        uint256 claimed;
        uint8 claimedTimes;
        uint256 lastClaimedHeight;
        bool approved;
    }

    address private _youToken;
    uint256 blocksOfMonth = 30;//3600/15*24*30;
    uint256 startHeight = 0;
    uint256 public constant totalSupplyForTeam = 3 * 10 ** 13;//15% of the total supply of YOU
    uint256 public suppliedForTeam = 0;
    uint8 private _decimals = 10;
    mapping(uint8 => beneficiary) private _beneficiaries;

    event Claimed(address indexed recipient, uint8 benId, uint256 amountOfYou);

    event BeneficiaryUpdated(
        uint8 benId,
        address oldBenAccount,
        address newBenAccount,
        address oldAgent,
        address newAgent
    );

    constructor(address youToken) public {
        _youToken = youToken;
        startHeight = block.number;

        _beneficiaries[1].approved = true;
        _beneficiaries[1].account = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _beneficiaries[1].agent = 0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F;
        _beneficiaries[1].reserved = 1500000000000;
        _beneficiaries[1].lastClaimedHeight = startHeight;

        _beneficiaries[2].approved = true;
        _beneficiaries[2].account = 0xfCa8243ADc135E043D73a6F68DEc771F086277F2;
        _beneficiaries[2].agent = 0xfCa8243ADc135E043D73a6F68DEc771F086277F2;
        _beneficiaries[2].reserved = 300000000000;
        _beneficiaries[2].lastClaimedHeight = startHeight;
        
        _beneficiaries[3].approved = true;
        _beneficiaries[3].account = 0x2a5e20e25B8fEbFbB00f4278f976a7e97cBaFebd;
        _beneficiaries[3].agent = 0x2a5e20e25B8fEbFbB00f4278f976a7e97cBaFebd;
        _beneficiaries[3].reserved = 1000000000000;
        _beneficiaries[3].lastClaimedHeight = startHeight;

        _beneficiaries[4].approved = true;
        _beneficiaries[4].account = 0x62282826a13b030b15A0133994E2c51622437942;
        _beneficiaries[4].agent = 0x62282826a13b030b15A0133994E2c51622437942;
        _beneficiaries[4].reserved = 1000000000000;
        _beneficiaries[4].lastClaimedHeight = startHeight;
    }

    function updateBeneficiary(uint8 id,address newAccount,address newAgent) isManager external{
        require(_beneficiaries[id].approved, 'YouSwap: NOT_EXIST');
        uint transactionId = nonce++;

        Transaction memory transaction;
        transaction.creator = msg.sender;
        transaction.benId = id;
        transaction.benAccount = _beneficiaries[id].account;
        transaction.newBenAccount = newAccount;
        transaction.agent = _beneficiaries[id].agent;
        transaction.newAgent = newAgent;
        transaction.signatureCount = 1;
        transactions[transactionId] = transaction;
        pendingTransactions.push(transactionId);


        emit TransactionCreated(msg.sender, id, _beneficiaries[id].account, newAccount,_beneficiaries[id].agent,newAgent,transactionId);
    }

    function approveBeneficiary(uint8 id, address account, uint256 reserved, address agent) onlyOwner external {
        require(!_beneficiaries[id].approved, 'YouSwap: APPROVED_ALREADY');
        _beneficiaries[id].account = account;
        _beneficiaries[id].agent = agent;
        _beneficiaries[id].reserved = reserved;
        _beneficiaries[id].claimed = 0;
        _beneficiaries[id].claimedTimes = 0;
        _beneficiaries[id].lastClaimedHeight = 0;
        _beneficiaries[id].approved = true;
    }

    function checkBeneficiary(uint8 id) isManager external view returns
    (
        address account,
        address agent,
        uint256 reserved,
        uint256 claimed,
        uint8 claimedTimes,
        uint256 lastClaimedHeight
    ) {
        require(_beneficiaries[id].approved, 'YouSwap: NOT_EXIST');
        return
        (
        _beneficiaries[id].account,
        _beneficiaries[id].agent,
        _beneficiaries[id].reserved,
        _beneficiaries[id].claimed,
        _beneficiaries[id].claimedTimes,
        _beneficiaries[id].lastClaimedHeight
        );
    }

    function claim(uint8 id) public {
        require(_beneficiaries[id].agent == msg.sender, 'YouSwap: NOT_ALLOWED');
        require(_beneficiaries[id].claimed < _beneficiaries[id].reserved, 'YouSwap: EXCEEDS_THE_RESERVED_AMOUNT');
        uint deltaBlocks = block.number - _beneficiaries[id].lastClaimedHeight;
        require(deltaBlocks >= blocksOfMonth, 'YouSwap: CLAIMED_THIS_MONTH');

        uint times = deltaBlocks.div(blocksOfMonth);
        uint256 canClaimThisTime = _beneficiaries[id].reserved.div(60).mul(times);

        if(_beneficiaries[id].claimed.add(canClaimThisTime) > _beneficiaries[id].reserved){
            canClaimThisTime = _beneficiaries[id].reserved.sub(_beneficiaries[id].claimed);
        }
        _mintYou(_beneficiaries[id].account, canClaimThisTime);
        _beneficiaries[id].claimed = _beneficiaries[id].claimed.add(canClaimThisTime);

        _beneficiaries[id].lastClaimedHeight = _beneficiaries[id].lastClaimedHeight.add(blocksOfMonth * times);

        suppliedForTeam += canClaimThisTime;
        require(suppliedForTeam <= totalSupplyForTeam, 'YouSwap: EXCEEDS_THE_UPPER_LIMIT');
        emit Claimed(_beneficiaries[id].account, id, canClaimThisTime);
    }

    function nextClaimHeight(uint8 id) public view returns (uint256) {
        // require(_beneficiaries[id].agent == msg.sender, 'YouSwap: NOT_ALLOWED');
        // require(_beneficiaries[id].claimed < _beneficiaries[id].reserved, 'YouSwap: OUT_OF_FUNDS');

        return _beneficiaries[id].lastClaimedHeight + blocksOfMonth;
    }

    function claimed(uint8 id) public view returns (uint256) {
        //require(_beneficiaries[id].agent == msg.sender, 'YouSwap: NOT_ALLOWED');
        return _beneficiaries[id].claimed;
    }

    function balanceOf(uint8 id) public view returns (uint256) {
        //require(_beneficiaries[id].agent == msg.sender, 'YouSwap: NOT_ALLOWED');
        return _beneficiaries[id].reserved - _beneficiaries[id].claimed;
    }

    function _mintYou(address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = _youToken.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function signTransaction(uint transactionId) public isManager {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.signatures[msg.sender] != 1, "YouSwap: SIGNED_ALREADY");
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        if (transaction.signatureCount >= MIN_SIGNATURES) {
            _beneficiaries[transaction.benId].account = transaction.newBenAccount;
            _beneficiaries[transaction.benId].agent = transaction.newAgent;
            emit BeneficiaryUpdated(transaction.benId, transaction.benAccount, transaction.newBenAccount, transaction.agent, transaction.newAgent);
            deleteTransactions(transactionId);
        }
    }
}