/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

// File: contracts/utils/OwnableContract.sol

// empty block is used as this contract just inherits others.
contract OwnableContract is CanReclaimToken, Claimable { } /* solhint-disable-line no-empty-blocks */

// File: contracts/controller/ControllerInterface.sol

interface ControllerInterface {
    function mint(address to, uint amount) external returns (bool);
    function burn(uint value) external returns (bool);
    function isCustodian(address addr) external view returns (bool);
    function isMerchant(address addr) external view returns (bool);
    function getWBitclout() external view returns (ERC20);
}

// File: contracts/factory/Factory.sol

contract Factory is OwnableContract {

    enum RequestStatus {PENDING, CANCELED, APPROVED, REJECTED}

    struct Request {
        address requester; // sender of the request.
        uint amount; // amount of wbitclout to mint/burn.
        string bitcloutDepositAddress; // custodian's bitclout address in mint, merchant's bitclout address in burn.
        string bitcloutTxid; // bitcoin txid for sending/redeeming bitclout in the mint/burn process.
        uint nonce; // serial number allocated for each request.
        uint timestamp; // time of the request creation.
        RequestStatus status; // status of the request.
    }

    ControllerInterface public controller;

    // mapping between merchant to the corresponding custodian deposit address, used in the minting process.
    // by using a different deposit address per merchant the custodian can identify which merchant deposited.
    mapping(address=>string) public custodianBitcloutDepositAddress;

    // mapping between merchant to the its deposit address where bitclout should be moved to, used in the burning process.
    mapping(address=>string) public merchantBitcloutDepositAddress;

    // mapping between a mint request hash and the corresponding request nonce. 
    mapping(bytes32=>uint) public mintRequestNonce;

    // mapping between a burn request hash and the corresponding request nonce.
    mapping(bytes32=>uint) public burnRequestNonce;

    Request[] public mintRequests;
    Request[] public burnRequests;

    constructor(ControllerInterface _controller) public {
        require(_controller != address(0), "invalid _controller address");
        controller = _controller;
        owner = _controller;
    }

    modifier onlyMerchant() {
        require(controller.isMerchant(msg.sender), "sender not a merchant.");
        _;
    }

    modifier onlyCustodian() {
        require(controller.isCustodian(msg.sender), "sender not a custodian.");
        _;
    }

    event CustodianBitcloutDepositAddressSet(address indexed merchant, address indexed sender, string bitcloutDepositAddress);

    function setCustodianBitcloutDepositAddress(
        address merchant,
        string bitcloutDepositAddress
    )
        external
        onlyCustodian
        returns (bool) 
    {
        require(merchant != 0, "invalid merchant address");
        require(controller.isMerchant(merchant), "merchant address is not a real merchant.");
        require(!isEmptyString(bitcloutDepositAddress), "invalid bitclout deposit address");

        custodianBitcloutDepositAddress[merchant] = bitcloutDepositAddress;
        emit CustodianBitcloutDepositAddressSet(merchant, msg.sender, bitcloutDepositAddress);
        return true;
    }

    event MerchantBitcloutDepositAddressSet(address indexed merchant, string bitcloutDepositAddress);

    function setMerchantBitcloutDepositAddress(string bitcloutDepositAddress) external onlyMerchant returns (bool) {
        require(!isEmptyString(bitcloutDepositAddress), "invalid bitclout deposit address");

        merchantBitcloutDepositAddress[msg.sender] = bitcloutDepositAddress;
        emit MerchantBitcloutDepositAddressSet(msg.sender, bitcloutDepositAddress);
        return true; 
    }

    event MintRequestAdd(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string bitcloutDepositAddress,
        string bitcloutTxid,
        uint timestamp,
        bytes32 requestHash
    );

    function addMintRequest(
        uint amount,
        string bitcloutTxid,
        string bitcloutDepositAddress
    )
        external
        onlyMerchant
        returns (bool)
    {
        require(!isEmptyString(bitcloutDepositAddress), "invalid bitclout deposit address"); 
        require(compareStrings(bitcloutDepositAddress, custodianBitcloutDepositAddress[msg.sender]), "wrong bitclout deposit address");

        uint nonce = mintRequests.length;
        uint timestamp = getTimestamp();

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            bitcloutDepositAddress: bitcloutDepositAddress,
            bitcloutTxid: bitcloutTxid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        mintRequestNonce[requestHash] = nonce; 
        mintRequests.push(request);

        emit MintRequestAdd(nonce, msg.sender, amount, bitcloutDepositAddress, bitcloutTxid, timestamp, requestHash);
        return true;
    }

    event MintRequestCancel(uint indexed nonce, address indexed requester, bytes32 requestHash);

    function cancelMintRequest(bytes32 requestHash) external onlyMerchant returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        require(msg.sender == request.requester, "cancel sender is different than pending request initiator");
        mintRequests[nonce].status = RequestStatus.CANCELED;

        emit MintRequestCancel(nonce, msg.sender, requestHash);
        return true;
    }

    event MintConfirmed(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string bitcloutDepositAddress,
        string bitcloutTxid,
        uint timestamp,
        bytes32 requestHash
    );

    function confirmMintRequest(bytes32 requestHash) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.APPROVED;
        require(controller.mint(request.requester, request.amount), "mint failed");

        emit MintConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.bitcloutDepositAddress,
            request.bitcloutTxid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    event MintRejected(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string bitcloutDepositAddress,
        string bitcloutTxid,
        uint timestamp,
        bytes32 requestHash
    );

    function rejectMintRequest(bytes32 requestHash) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.REJECTED;

        emit MintRejected(
            request.nonce,
            request.requester,
            request.amount,
            request.bitcloutDepositAddress,
            request.bitcloutTxid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    event Burned(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string bitcloutDepositAddress,
        uint timestamp,
        bytes32 requestHash
    );

    function burn(uint amount) external onlyMerchant returns (bool) {
        string memory bitcloutDepositAddress = merchantBitcloutDepositAddress[msg.sender];
        require(!isEmptyString(bitcloutDepositAddress), "merchant bitclout deposit address was not set"); 

        uint nonce = burnRequests.length;
        uint timestamp = getTimestamp();

        // set txid as empty since it is not known yet.
        string memory bitcloutTxid = "";

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            bitcloutDepositAddress: bitcloutDepositAddress,
            bitcloutTxid: bitcloutTxid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestNonce[requestHash] = nonce; 
        burnRequests.push(request);

        require(controller.getWBitclout().transferFrom(msg.sender, controller, amount), "trasnfer tokens to burn failed");
        require(controller.burn(amount), "burn failed");

        emit Burned(nonce, msg.sender, amount, bitcloutDepositAddress, timestamp, requestHash);
        return true;
    }

    event BurnConfirmed(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string bitcloutDepositAddress,
        string bitcloutTxid,
        uint timestamp,
        bytes32 inputRequestHash
    );

    function confirmBurnRequest(bytes32 requestHash, string bitcloutTxid) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingBurnRequest(requestHash);

        burnRequests[nonce].bitcloutTxid = bitcloutTxid;
        burnRequests[nonce].status = RequestStatus.APPROVED;
        burnRequestNonce[calcRequestHash(burnRequests[nonce])] = nonce;

        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.bitcloutDepositAddress,
            bitcloutTxid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    function getMintRequest(uint nonce)
        external
        view
        returns (
            uint requestNonce,
            address requester,
            uint amount,
            string bitcloutDepositAddress,
            string bitcloutTxid,
            uint timestamp,
            string status,
            bytes32 requestHash
        )
    {
        Request memory request = mintRequests[nonce];
        string memory statusString = getStatusString(request.status); 

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        bitcloutDepositAddress = request.bitcloutDepositAddress;
        bitcloutTxid = request.bitcloutTxid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getMintRequestsLength() external view returns (uint length) {
        return mintRequests.length;
    }

    function getBurnRequest(uint nonce)
        external
        view
        returns (
            uint requestNonce,
            address requester,
            uint amount,
            string bitcloutDepositAddress,
            string bitcloutTxid,
            uint timestamp,
            string status,
            bytes32 requestHash
        )
    {
        Request storage request = burnRequests[nonce];
        string memory statusString = getStatusString(request.status); 

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        bitcloutDepositAddress = request.bitcloutDepositAddress;
        bitcloutTxid = request.bitcloutTxid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getBurnRequestsLength() external view returns (uint length) {
        return burnRequests.length;
    }

    function getTimestamp() internal view returns (uint) {
        // timestamp is only used for data maintaining purpose, it is not relied on for critical logic.
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function getPendingMintRequest(bytes32 requestHash) internal view returns (uint nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = mintRequestNonce[requestHash];
        request = mintRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getPendingBurnRequest(bytes32 requestHash) internal view returns (uint nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = burnRequestNonce[requestHash];
        request = burnRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function validatePendingRequest(Request memory request, bytes32 requestHash) internal pure {
        require(request.status == RequestStatus.PENDING, "request is not pending");
        require(requestHash == calcRequestHash(request), "given request hash does not match a pending request");
    }

    function calcRequestHash(Request request) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            request.requester,
            request.amount,
            request.bitcloutDepositAddress,
            request.bitcloutTxid,
            request.nonce,
            request.timestamp
        ));
    }

    function compareStrings (string a, string b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function isEmptyString (string a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function getStatusString(RequestStatus status) internal pure returns (string) {
        if (status == RequestStatus.PENDING) {
            return "pending";
        } else if (status == RequestStatus.CANCELED) {
            return "canceled";
        } else if (status == RequestStatus.APPROVED) {
            return "approved";
        } else if (status == RequestStatus.REJECTED) {
            return "rejected";
        } else {
            // this fallback can never be reached.
            return "unknown";
        }
    }
}