pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/passThrough/PassThroughStorage.sol

contract PassThroughStorage {
    bytes4 public constant ERC721_Received = 0x150b7a02;
    uint256 public constant MAX_EXPIRATION_TIME = (365 * 2 days);
    mapping(bytes4 => uint256) public disableMethods;

    address public estateRegistry;
    address public operator;
    address public target;

    event MethodAllowed(
      address indexed _caller,
      bytes4 indexed _signatureBytes4,
      string _signature
    );

    event MethodDisabled(
      address indexed _caller,
      bytes4 indexed _signatureBytes4,
      string _signature
    );

    event TargetChanged(
      address indexed _caller,
      address indexed _oldTarget,
      address indexed _newTarget
    );
}

// File: contracts/passThrough/PassThrough.sol

contract PassThrough is Ownable, PassThroughStorage {
    /**
    * @dev Constructor of the contract.
    */
    constructor(address _estateRegistry, address _operator) Ownable() public {
        estateRegistry = _estateRegistry;
        operator = _operator;

        // Set target
        setTarget(estateRegistry);

        // ERC721 methods
        disableMethod("approve(address,uint256)", MAX_EXPIRATION_TIME);
        disableMethod("setApprovalForAll(address,bool)", MAX_EXPIRATION_TIME);
        disableMethod("transferFrom(address,address,uint256)", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferFrom(address,address,uint256)", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferFrom(address,address,uint256,bytes)", MAX_EXPIRATION_TIME);

        // EstateRegistry methods
        disableMethod("transferLand(uint256,uint256,address)", MAX_EXPIRATION_TIME);
        disableMethod("transferManyLands(uint256,uint256[],address)", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferManyFrom(address,address,uint256[])", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferManyFrom(address,address,uint256[],bytes)", MAX_EXPIRATION_TIME);

    }

    /**
    * @dev Fallback function could be called by the operator, if the method is allowed, or
    * by the owner. If the call was unsuccessful will revert.
    */
    function() external {
        require(
            isOperator() && isMethodAllowed(msg.sig) || isOwner(),
            "Permission denied"
        );

        bytes memory _calldata = msg.data;
        uint256 _calldataSize = msg.data.length;
        address _dst = target;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := call(sub(gas, 10000), _dst, 0, add(_calldata, 0x20), _calldataSize, 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            if iszero(result) { revert(ptr, size) }
            return(ptr, size)
        }
    }

    /**
    * @dev Check if sender is the operator
    * @return bool whether is sender is the caller or not
    */
    function isOperator() internal view returns (bool) {
        return msg.sender == operator;
    }

    /**
    * @dev Check if a method is allowed
    * @param _signature string - method signature
    * @return bool - whether method is allowed or not
    */
    function isMethodAllowed(bytes4 _signature) internal view returns (bool) {
        return disableMethods[_signature] < block.timestamp;
    }

    function setTarget(address _target) public {
        require(
            isOperator() || isOwner(),
            "Permission denied"
        );

        emit TargetChanged(msg.sender, target, _target);
        target = _target;
    }

    /**
    * @dev Disable a method for two years
    * Note that the input expected is the method signature as &#39;transfer(address,uint256)&#39;
    * @param _signature string - method signature
    */
    function disableMethod(string memory _signature, uint256 _time) public onlyOwner {
        require(_time > 0, "Time should be greater than 0");
        require(_time <= MAX_EXPIRATION_TIME, "Time should be lower than 2 years");

        bytes4 signatureBytes4 = convertToBytes4(abi.encodeWithSignature(_signature));
        disableMethods[signatureBytes4] = block.timestamp + _time;

        emit MethodDisabled(msg.sender, signatureBytes4, _signature);
    }

    /**
    * @dev Allow a method previously disabled
    * Note that the input expected is the method signature as &#39;transfer(address,uint256)&#39;
    * @param _signature string - method signature
    */
    function allowMethod(string memory _signature) public onlyOwner {
        bytes4 signatureBytes4 = convertToBytes4(abi.encodeWithSignature(_signature));
        require(!isMethodAllowed(signatureBytes4), "Method is already allowed");

        disableMethods[signatureBytes4] = 0;

        emit MethodAllowed(msg.sender, signatureBytes4, _signature);
    }

    /**
    * @dev Convert bytes to bytes4
    * @param _signature bytes - method signature
    * @return bytes4 - method signature in bytes4
    */
    function convertToBytes4(bytes memory _signature) internal pure returns (bytes4) {
        require(_signature.length == 4, "Invalid method signature");
        bytes4 signatureBytes4;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            signatureBytes4 := mload(add(_signature, 32))
        }
        return signatureBytes4;
    }

    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    * after a `safetransfer`. This function MAY throw to revert and reject the
    * transfer. Return of other than the magic value MUST result in the
    * transaction being reverted.
    * Note: the contract address is always the message sender.
    * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(
        address /*_from*/,
        address /*_to*/,
        uint256 /*_tokenId*/,
        bytes memory /*_data*/
    )
        public
        view
        returns (bytes4)
    {
        require(msg.sender == estateRegistry, "Token not accepted");
        return ERC721_Received;
    }
}