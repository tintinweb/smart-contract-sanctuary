pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

contract LucidContract_0_1 is Destructible {

    string private account_;
    
    string[3] internal currencies_ = ["USD", "EUR", "BTC"];
    
    event Created(bytes32 _tradeHash);
    event Released(bytes32 _tradeHash);
    event RefundRequest(bytes32 _tradeHash, string side);
    event Refunded(bytes32 _tradeHash);

    struct Escrow {
        // Set so we know the trade has already been created.
        bool exists;
        // The timestamp after which the sender can cancel the transaction unilaterally. 
        // 1 = unlimited cancel time
        uint32 deadline;
        bool[2] refund;
        address sender;
        string title;
        string description; 
        int amount;
        string currency;
        address recipient;
    }
    // Mapping of active transactions. Key is a hash of the transaction data.
    mapping (bytes32 => Escrow) public escrows;

    function create(
        string title, 
        string description, 
        uint32 deadline, 
        int amount, 
        string currency, 
        address recipient
    ) external returns(bytes32) {
        bytes32 _tradeHash = keccak256(abi.encodePacked(title, description, deadline, amount, currency, msg.sender, recipient));
        require(!escrows[_tradeHash].exists, "Transaction already exists");
        require(bytes(title).length > 0, "No title provided");
        require(bytes(description).length > 0, "No description provided");
        require(amount > 1, "Too small amount");
        require(_includes(currencies_, currency), "Not supported currency");
        require(deadline > block.timestamp, "Deadline should be not earlier than now"); 
        // For infinite deadline – "deadline == 0 ? 1 : " and " || deadline == 0"
        escrows[_tradeHash] = Escrow(true, deadline, [false, false], msg.sender, title, description, amount, currency, recipient);
        emit Created(_tradeHash);
        return _tradeHash;
    }
    function confirm(bytes32 tradeHash) external returns(bool) {
        if (!escrows[tradeHash].exists) return false;
        require(msg.sender == escrows[tradeHash].sender, "Only payer can confirm");
        delete escrows[tradeHash];
        emit Released(tradeHash);
        return true;
    }
    function unilateralRefund(bytes32 tradeHash) external returns(bool) {
        if (!escrows[tradeHash].exists) return false;
        require(block.timestamp >= escrows[tradeHash].deadline, "Refund available only after deadline");
        require(msg.sender == escrows[tradeHash].sender, "Only payer can request unilateral refund");
        delete escrows[tradeHash];
        emit Refunded(tradeHash);
        return true;
    }
    function refund(bytes32 tradeHash) external returns(bool) {
        if (!escrows[tradeHash].exists) return false;
        require(
            msg.sender == escrows[tradeHash].sender || 
            msg.sender == escrows[tradeHash].recipient, 
            "Refund only available for payer and recipient"
        );
        if (msg.sender == escrows[tradeHash].sender) {
            escrows[tradeHash].refund[0] = true;
            emit RefundRequest(tradeHash, "sender");
            if (escrows[tradeHash].refund[0] == true && escrows[tradeHash].refund[1] == true) {
                delete escrows[tradeHash];
                emit Refunded(tradeHash);
            }
        }
        if (msg.sender == escrows[tradeHash].recipient) {
            escrows[tradeHash].refund[1] = true;
            emit RefundRequest(tradeHash, "recipient");
            if (escrows[tradeHash].refund[0] == true && escrows[tradeHash].refund[1] == true) {
                delete escrows[tradeHash];
                emit Refunded(tradeHash);
            }
        }
        return true;
    }
    function _includes(string[3] arr, string str) internal pure returns(bool) {
        if (keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked(arr[0]))) {
            return true;
        } else {
            if (keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked(arr[1]))) {
                return true;
            } else {
                if (keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked(arr[2]))) {
                    return true;
                }
            }
        }
        return false;
    }
}