/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/* 
 * @author Patrick McCorry & Chris Buckland (ITX)
 * @title Payment Deposit contract
 * @notice Handles customers deposits and only the owner/child contracts can issue withdraws. 
 */
contract PaymentDeposit is Ownable {

    // Every depositor has a unique identifier. Helps with off-chain tracking. 
    mapping(address => uint) public depositors;
    uint public uniqueDepositors; 

    event Deposit(address indexed sender, uint amount, uint indexed index);
    event Withdraw(address indexed depositor, address indexed recipient, uint amount);

    /**
     * @param _recipient Associate funds with this address. 
     * Supply a deposit for a specified recipient.
     * Caution: The recipient must be an externally owned account as all jobs sent to 
     * any.sender must be signed and associated with a positive balance in this contract. 
     */
    function depositFor(address _recipient) public payable { 
        require(msg.value > 0, "No value provided to depositFor.");
        uint index = getDepositorIndex(_recipient);
        emit Deposit(_recipient, msg.value, index);
    }

    /** 
     * @param _depositor Depositor address
     * Sets the depositors index if necessary.
     */
    function getDepositorIndex(address _depositor) internal returns(uint) {
        if(depositors[_depositor] == 0) {
            uniqueDepositors = uniqueDepositors + 1;
            depositors[_depositor] = uniqueDepositors;
        }

        return depositors[_depositor];
    }

    /*
     * It is only intended for external users who want to deposit via a wallet.
     */ 
    receive() external payable {
        require(msg.value > 0, "No value provided to fallback.");
        require(tx.origin == msg.sender, "Only EOA can deposit directly.");
        uint index = getDepositorIndex(msg.sender);
        emit Deposit(msg.sender, msg.value, index);
    }

    /**
     * Internal function for sending funds. 
     */
    function withdraw(address payable _depositor, address payable _recipient, uint _amount) internal {
        _recipient.transfer(_amount);
        emit Withdraw(_depositor, _recipient, _amount);
    }

    /**
     * @param _depositor Funds being withdrawn from (e.g. deducts their balance). 
     * @param _recipient Receiver of the funds
     * @param _amount Funds to send
     * Move funds out of the contract
     * Depositor is the OWNER of the funds being withdrawn. 
     * Recipient is the RECEIVER of the funds. 
     */
    function withdrawFor(address payable _depositor, address payable _recipient, uint _amount) public onlyOwner {
        withdraw(_depositor, _recipient, _amount);
    }

    /**
     * @param _recipient Address that receives funds in the new PaymentDeposit
     * @param _amount Funds to send
     * @param _otherDeposit New Payment Deposit contract
     * Use admin privileges to migrate a user's deposits to another deposit contract
     */
    function migrate(address payable _recipient, uint _amount, PaymentDeposit _otherDeposit) public onlyOwner {
        require(address(this).balance >= _amount, "Not enough balance to migrate.");
        require(address(_otherDeposit) != address(this), "Cannot migrate to same contract.");
        _otherDeposit.depositFor.value(_amount)(_recipient); // We assume an upgraded contract has this interface.
        emit Withdraw(address(this), _recipient, _amount);
    }
}

/**
 * @author Patrick McCorry & Chris Buckland (ITX)
 * @title Relayer Manager contract
 * @notice  Manage relayers and issue topups 
 */
contract RelayerManager is PaymentDeposit {

    mapping(address => bool) public relayers;

    event RelayerInstalled(address relayer);
    event RelayerUninstalled(address relayer);

    modifier onlyRelayer {
        require(relayers[msg.sender], "Only relayer can call this function.");
        _;
    }

    /** 
     * @param newOwner Owner of contract
     * @dev Owner cannot be a relayer or this contract.
     */
    function transferOwnership(address newOwner) public override onlyOwner { 
        require(!relayers[newOwner], "Relayer cannot be an owner.");
        require(newOwner != address(this), "Contract cannot own itself.");
        _transferOwnership(newOwner);
    }

    /**
     * @param _relayer New relayer address
     * @dev Only the owner can install a new relayer
     */
    function installRelayer(address _relayer) onlyOwner public {
        require(!relayers[_relayer], "Relayer is already installed.");
        require(_relayer != address(this), "The relay contract cannot be installed as a relayer.");
        require(_relayer != owner(), "Avoid mixing relayer and owner roles.");

        relayers[_relayer] = true;
        emit RelayerInstalled(_relayer);
    }

    /** 
     * @param _relayer New relayer address
     * @dev Only the owner can uninstall a new relayer
     */ 
    function uninstallRelayer(address _relayer) onlyOwner public {
        require(relayers[_relayer], "Relayer must be installed.");

        relayers[_relayer] = false;
        emit RelayerUninstalled(_relayer);
    }


    /** 
     * @param _recipient Receiver of the topup
     * @param _maxBalance Maximum topup to send 
     * Called by a relayer to perform a relative top up.
     * Only sends enough funds for relayer to reach max balance. 
     */  
    function relativeTopUp(address payable _recipient, uint256 _maxBalance) public onlyRelayer {
        require(relayers[_recipient], "Recipient must be a relayer to receive a top up.");
        uint256 relayerBalance = address(_recipient).balance;

        // The contract or relayer must be pre-collateralized with the
        // max balance in advance. So if maxBalance = 3 ETH, then a new relayer
        // should have a balance at or greater than 3 ETH.
        if (_maxBalance > relayerBalance) {
            uint256 toTopUp = _maxBalance - relayerBalance;
            withdraw(msg.sender, _recipient, toTopUp);
        }
    }

    /**
     * @param _recipient Receiver of the topup
     * @param _topUp Funds to send
     * Called by a relayer to perform an "absolute" top up.
     * It can exceed the expected max balance of a relayer.
     */ 
    function absoluteTopUp(address payable _recipient, uint256 _topUp) public onlyRelayer {
        require(relayers[_recipient], "Recipient must be a relayer to receive an emergency topup.");
        withdraw(msg.sender, _recipient, _topUp);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/** 
 * @author Patrick McCorry & Chris Buckland (ITX)
 * @title Relay contract
 * @notice Handles relaying transactions, managing the relayers & user deposits. 
 * @dev Two-stage deployment required. Deploy via CREATE2 and INIT() in the same transaction.
 */
contract InstantRefundRelay is RelayerManager {
    using SafeMath for uint256;

    event RelayExecuted(bytes32 indexed relayTxId, bool success, address indexed to, uint gasUsed, uint gasPrice);
    event OutOfCoins();

    // @dev The relay transaction
    struct RelayTx {
        bytes32 id; // Off-chain identifier to track transaction & payment.
        address to; // Address for external contract.
        bytes data; // Call data that we need to send. Includes function call name, etc.
        uint gasLimit; // How much gas is allocated to this function call?
    }
    
    /** 
     * @param _relayTx A relay tx containing the job to execute
     * @param _gasRefund Gas amount to refund
     * @dev Only authorised relayer can execute relay jobs and they are refunded gas at the end of the call.
     *     Critically, if the relay job fails, we can simply catch exception and continue with the refund. 
     */
    function execute(RelayTx calldata _relayTx, uint _gasRefund) external {
        uint gasStarted = gasleft();

        // The msg.sender check protects against two problems:
        // - Replay attacks across chains (chainid in transaction)
        // - Re-entrancy attacks back into .execute() (signer required)
        // - Stops external relayers spending the contract balance without any.sender authorisation
        require(relayers[msg.sender], "Relayer must call this function.");

        // In the worst case, the contract will only send 63/64 of the transaction's
        // remaining gas due to https://eips.ethereum.org/EIPS/eip-150
        // But this is problematic as outlined in https://eips.ethereum.org/EIPS/eip-1930
        // so to fix... we need to make sure we supply 64/63 * gasLimit.
        // Assumption: Underlying contract called did not have a minimum gas required check
        // We add 1000 to cover the cost of calculating new gas limit - this should be a lot more than
        // is required - measuring shows cost of 58
        require(gasleft() > _relayTx.gasLimit.div(63).add(_relayTx.gasLimit).add(1000), "Not enough gas supplied.");

        // execute the actual call
        (bool success,) = _relayTx.to.call.gas(_relayTx.gasLimit)(_relayTx.data);

        uint gasUsed = gasStarted.add(_gasRefund).sub(gasleft()); // Takes into account gas cost for refund. 

        if(_gasRefund > 0) {
            if(!msg.sender.send(gasUsed*tx.gasprice)) {
                // Notify admin we need to provide more refund to this contract
                emit OutOfCoins();
            }
        }

        emit RelayExecuted(_relayTx.id, success, _relayTx.to, gasUsed, tx.gasprice);
    }
}