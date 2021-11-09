/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

pragma solidity ^0.6.12;

library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * 
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract Context {
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
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract DataLayout is LibraryLock {
    string public startChain;
    uint public chainId;
    uint256 public nonce;
    uint public threshold;
    mapping(address => bool) isValidSigner;
    address[] public signersArr;

    bytes32 DOMAIN_SEPARATOR;
    
    //transactions being sent to contracts on external chains
    uint256 public outboundIndex;
    struct outboundTransactions {
        address sender;
        uint256 amount;
        uint256 feeAmount;
        address recipient;
        address destination;
        string chain;
        string preferredNode;
        address startContract;
    }
    mapping(uint256 => outboundTransactions) public outboundHistory;
    
    //transactions being sent to contracts on local chain
    uint256 public inboundIndex;
    struct inboundTransactions {
        uint256 amount;
        address sender;
        address recipient;
        string chain;
    }
    mapping(uint256 => inboundTransactions) public inboundHistory;
    
    mapping(address => bool) public allowedContracts;
    
    address public bridgeAddress;
}

contract PortContract is Ownable, Proxiable, DataLayout {
    using SafeMath for uint256;
    using SafeMath for uint32;
    
    constructor () public {
 
    }

    function proxyConstructor(string memory _startChain, uint _threshold, uint _chainId) public {
        require(!initialized, "Contract is already initialized");
        startChain = _startChain;
        threshold = _threshold;
        chainId = _chainId;
        initialize();
    }

    function updateCode(address newCode) public onlyOwner delegatedOnly  {
        updateCodeAddress(newCode);
    }

    receive() external payable {

  	}
    
    event BridgeSwapOut(
        address sender,
        address recipient,
        address destination,
        uint256 amount,
        string startChain,
        string endChain,
        string preferredNode,
        uint256 feeAmount,
        address startContract
        
    );

    event BridgeSwapIn(
        string startChain,
        address sender,
        address recipient,
        uint256 amount
    );

    modifier onlyBridge {
        require(msg.sender == bridgeAddress);
        _;
    }
    
    modifier onlyAllowed {
        require(allowedContracts[msg.sender]);
        _;
    }
    
    function setContractStatus(address _contract, bool status) public onlyOwner {
        allowedContracts[_contract] = status;
    }
        
    function addSigner(address[] memory _signers) public onlyOwner {
        for (uint i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "0 Address cannot be a signer");
            require(isValidSigner[_signers[i]], "New signer cannot be an existing signer");
            isValidSigner[_signers[i]] = true;
        }
    }
    
    function outboundSwap(
        address sender, 
        address recipient,
        address destination,
        uint256 amount,
        string memory preferredNode,
        string memory endChain) public payable onlyAllowed {
        require(msg.value > 0, "Fee amount must be greater than 0");
        outboundIndex = outboundIndex.add(1);
        outboundHistory[outboundIndex].sender = sender;
        outboundHistory[outboundIndex].amount = amount;
        outboundHistory[outboundIndex].feeAmount = msg.value;
        outboundHistory[outboundIndex].startContract = msg.sender;
        outboundHistory[outboundIndex].destination = destination;
        outboundHistory[outboundIndex].recipient = recipient;
        outboundHistory[outboundIndex].chain = endChain;
        outboundHistory[outboundIndex].preferredNode = preferredNode;
        
        payable(bridgeAddress).transfer(msg.value);
        
        emit BridgeSwapOut(sender, recipient, destination, amount, startChain, endChain, preferredNode, msg.value, msg.sender);
    }
    
    function inboundSwap(
        string memory _startChain,
        address sender,
        address recipient,
        address destination,
        uint256 amount) public onlyBridge {
        
        inboundIndex = inboundIndex.add(1);
        inboundHistory[inboundIndex].amount = amount;
        inboundHistory[inboundIndex].sender = sender;
        inboundHistory[inboundIndex].recipient = recipient;
        inboundHistory[inboundIndex].chain = _startChain;
        
        HokkContract(destination).portMessage(recipient, amount);
        emit BridgeSwapIn(startChain, sender, recipient, amount);
    }

    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    function execute(
        string memory _startChain,
        address sender,
        address recipient,
        address destination,
        uint256 amount,
        uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS) public {
        require(sigR.length == threshold);
        require(sigR.length == sigS.length && sigR.length == sigV.length);
        require(isValidSigner[msg.sender]);

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("HOKK Bridge Port")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("inboundSwap(string _startChain,address sender,address recipient,address destination,uint256 amount,uint256 nonce)"),
                _startChain,
                sender,
                recipient,
                destination,
                amount,
                nonce
            )
        );
        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 hash = keccak256(abi.encode("\x19\x01", eip712DomainHash, hashStruct));

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(hash, sigV[i], sigR[i], sigS[i]);
            require(recovered > lastAdd && isValidSigner[recovered]);
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for.
        // The address.call() syntax is no longer recommended, see:
        // https://github.com/ethereum/solidity/issues/2884
        bool success = true;
        nonce = nonce + 1;
        require(success);
        inboundSwap(_startChain, sender, recipient, destination, amount);
        // assembly { success := call(gasLimit, destination, value, add(data, 0x20), mload(data), 0, 0) }
        // require(success);
    }
    
}

interface HokkContract {
    function portMessage(address recipient, uint256 amount) external;
}