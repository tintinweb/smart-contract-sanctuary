/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: contracts\utils\Ownable.sol

pragma solidity 0.5.17;


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

// File: contracts\utils\IERC20.sol



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts\utils\SafeERC20.sol



// import "./ERC20Basic.sol";


// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(
        ERC20 _token,
        address _to,
        uint256 _value
    ) internal {
        require(_token.transfer(_to, _value));
    }

    function safeTransferFrom(
        ERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_token.transferFrom(_from, _to, _value));
    }

    function safeApprove(
        ERC20 _token,
        address _spender,
        uint256 _value
    ) internal {
        require(_token.approve(_spender, _value));
    }
}

// File: contracts\utils\CanReclaimToken.sol





// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20;

    /**
     * @dev Reclaim all ERC20Basic compatible tokens
     * @param _token ERC20Basic The address of the token contract
     */
    function reclaimToken(ERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(owner, balance);
    }
}

// File: contracts\utils\Claimable.sol




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

// File: contracts\utils\OwnableContract.sol




// empty block is used as this contract just inherits others.
contract OwnableContract is CanReclaimToken, Claimable { } /* solhint-disable-line no-empty-blocks */

// File: contracts\controller\IController.sol




// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


interface ControllerInterface {
    function mint(address to, uint amount) external returns (bool);
    function burn(uint value) external returns (bool);
    function isCustodian(address addr) external view returns (bool);
    function isMerchant(address addr) external view returns (bool);
    function getToken() external view returns (ERC20);
}

// File: contracts\factory\Factory.sol





contract Factory is OwnableContract {
    enum RequestStatus {PENDING, CANCELED, APPROVED, REJECTED}

    struct Request {
        address requester; // sender of the request.
        uint256 amount; // amount of token to mint/burn.
        string depositAddress; // custodian's asset address in mint, merchant's asset address in burn.
        string txid; // asset txid for sending/redeeming asset in the mint/burn process.
        uint256 nonce; // serial number allocated for each request.
        uint256 timestamp; // time of the request creation.
        RequestStatus status; // status of the request.
    }

    ControllerInterface public controller;

    // mapping between merchant to the corresponding custodian deposit address, used in the minting process.
    // by using a different deposit address per merchant the custodian can identify which merchant deposited.
    mapping(address => string) public custodianDepositAddress;

    // mapping between merchant to the its deposit address where the asset should be moved to, used in the burning process.
    mapping(address => string) public merchantDepositAddress;

    // mapping between a mint request hash and the corresponding request nonce.
    mapping(bytes32 => uint256) public mintRequestNonce;

    // mapping between a burn request hash and the corresponding request nonce.
    mapping(bytes32 => uint256) public burnRequestNonce;

    Request[] public mintRequests;
    Request[] public burnRequests;

    constructor(address _controller) public {
        require(_controller != address(0), "invalid _controller address");
        controller = ControllerInterface(_controller);
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

    event CustodianDepositAddressSet(
        address indexed merchant,
        address indexed sender,
        string depositAddress
    );

    function setCustodianDepositAddress(
        address merchant,
        string memory depositAddress
    ) public onlyCustodian returns (bool) {
        require(merchant != address(0), "invalid merchant address");
        require(
            controller.isMerchant(merchant),
            "merchant address is not a real merchant."
        );
        require(
            !isEmptyString(depositAddress),
            "invalid asset deposit address"
        );

        custodianDepositAddress[merchant] = depositAddress;
        emit CustodianDepositAddressSet(merchant, msg.sender, depositAddress);
        return true;
    }

    event MerchantDepositAddressSet(
        address indexed merchant,
        string depositAddress
    );

    function setMerchantDepositAddress(string memory depositAddress)
        public
        onlyMerchant
        returns (bool)
    {
        require(
            !isEmptyString(depositAddress),
            "invalid asset deposit address"
        );

        merchantDepositAddress[msg.sender] = depositAddress;
        emit MerchantDepositAddressSet(msg.sender, depositAddress);
        return true;
    }

    event MintRequestAdd(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    function addMintRequest(
        uint256 amount,
        string memory txid,
        string memory depositAddress
    ) public onlyMerchant returns (bool) {
        require(
            !isEmptyString(depositAddress),
            "invalid asset deposit address"
        );
        require(
            compareStrings(depositAddress, custodianDepositAddress[msg.sender]),
            "wrong asset deposit address"
        );

        uint256 nonce = mintRequests.length;
        uint256 timestamp = getTimestamp();

        Request memory request =
            Request({
                requester: msg.sender,
                amount: amount,
                depositAddress: depositAddress,
                txid: txid,
                nonce: nonce,
                timestamp: timestamp,
                status: RequestStatus.PENDING
            });

        bytes32 requestHash = calcRequestHash(request);
        mintRequestNonce[requestHash] = nonce;
        mintRequests.push(request);

        emit MintRequestAdd(
            nonce,
            msg.sender,
            amount,
            depositAddress,
            txid,
            timestamp,
            requestHash
        );
        return true;
    }

    event MintRequestCancel(
        uint256 indexed nonce,
        address indexed requester,
        bytes32 requestHash
    );

    function cancelMintRequest(bytes32 requestHash)
        external
        onlyMerchant
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        require(
            msg.sender == request.requester,
            "cancel sender is different than pending request initiator"
        );
        mintRequests[nonce].status = RequestStatus.CANCELED;

        emit MintRequestCancel(nonce, msg.sender, requestHash);
        return true;
    }

    event MintConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    function confirmMintRequest(bytes32 requestHash)
        external
        onlyCustodian
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.APPROVED;
        require(
            controller.mint(request.requester, request.amount),
            "mint failed"
        );

        emit MintConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    event MintRejected(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    function rejectMintRequest(bytes32 requestHash)
        external
        onlyCustodian
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.REJECTED;

        emit MintRejected(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    event Burned(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        uint256 timestamp,
        bytes32 requestHash
    );

    function burn(uint256 amount) external onlyMerchant returns (bool) {
        string memory depositAddress = merchantDepositAddress[msg.sender];
        require(
            !isEmptyString(depositAddress),
            "merchant asset deposit address was not set"
        );

        uint256 nonce = burnRequests.length;
        uint256 timestamp = getTimestamp();

        // set txid as empty since it is not known yet.
        string memory txid = "";

        Request memory request =
            Request({
                requester: msg.sender,
                amount: amount,
                depositAddress: depositAddress,
                txid: txid,
                nonce: nonce,
                timestamp: timestamp,
                status: RequestStatus.PENDING
            });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestNonce[requestHash] = nonce;
        burnRequests.push(request);

        require(
            controller.getToken().transferFrom(
                msg.sender,
                address(controller),
                amount
            ),
            "transfer tokens to burn failed"
        );
        require(controller.burn(amount), "burn failed");

        emit Burned(
            nonce,
            msg.sender,
            amount,
            depositAddress,
            timestamp,
            requestHash
        );
        return true;
    }

    event BurnConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 inputRequestHash
    );

    function confirmBurnRequest(bytes32 requestHash, string memory txid)
        public
        onlyCustodian
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingBurnRequest(requestHash);

        burnRequests[nonce].txid = txid;
        burnRequests[nonce].status = RequestStatus.APPROVED;
        burnRequestNonce[calcRequestHash(burnRequests[nonce])] = nonce;

        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    function getMintRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        Request memory request = mintRequests[nonce];
        string memory statusString = getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getMintRequestsLength() external view returns (uint256 length) {
        return mintRequests.length;
    }

    function getBurnRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        Request storage request = burnRequests[nonce];
        string memory statusString = getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getBurnRequestsLength() external view returns (uint256 length) {
        return burnRequests.length;
    }

    function getTimestamp() internal view returns (uint256) {
        // timestamp is only used for data maintaining purpose, it is not relied on for critical logic.
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function getPendingMintRequest(bytes32 requestHash)
        internal
        view
        returns (uint256 nonce, Request memory request)
    {
        require(requestHash != 0, "request hash is 0");
        nonce = mintRequestNonce[requestHash];
        request = mintRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getPendingBurnRequest(bytes32 requestHash)
        internal
        view
        returns (uint256 nonce, Request memory request)
    {
        require(requestHash != 0, "request hash is 0");
        nonce = burnRequestNonce[requestHash];
        request = burnRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function validatePendingRequest(Request memory request, bytes32 requestHash)
        internal
        pure
    {
        require(
            request.status == RequestStatus.PENDING,
            "request is not pending"
        );
        require(
            requestHash == calcRequestHash(request),
            "given request hash does not match a pending request"
        );
    }

    function calcRequestHash(Request memory request)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    request.requester,
                    request.amount,
                    request.depositAddress,
                    request.txid,
                    request.nonce,
                    request.timestamp
                )
            );
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(b)));
    }

    function isEmptyString(string memory a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function getStatusString(RequestStatus status)
        internal
        pure
        returns (string memory)
    {
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