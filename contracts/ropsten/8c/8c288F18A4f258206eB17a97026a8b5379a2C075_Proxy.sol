pragma solidity 0.4.24;

contract LibOwnable {
    address private _owner;

    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
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
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LibWhitelist is LibOwnable {
    mapping (address => bool) public whitelist;
    address[] public allAddresses;

    event AddressAdded(
        address indexed adr
    );

    event AddressRemoved(
        address indexed adr
    );

    /** @dev Only address in whitelist can invoke functions with this modifier. */
    modifier onlyAddressInWhitelist {
        require(whitelist[msg.sender], "SENDER_NOT_IN_WHITELIST");
        _;
    }

    /** @dev add Address into whitelist
      * @param adr Address to add
      */
    function addAddress(address adr) external onlyOwner {
        emit AddressAdded(adr);
        whitelist[adr] = true;
        allAddresses.push(adr);
    }

    /** @dev remove Address from whitelist
      * @param adr Address to remove
      */
    function removeAddress(address adr) external onlyOwner {
        emit AddressRemoved(adr);
        delete whitelist[adr];
        for(uint i = 0; i < allAddresses.length; i++){
            if(allAddresses[i] == adr) {
                allAddresses[i] = allAddresses[allAddresses.length - 1];
                allAddresses.length -= 1;
                break;
            }
        }
    }

    /** @dev Get all addresses in whitelist  */
    function getAllAddresses() external view returns (address[] memory) {
        return allAddresses;
    }
}

contract Proxy is LibWhitelist {

    /** @dev Calls into ERC20 Token contract, invoking transferFrom.
      * @param token Address of token to transfer.
      * @param from Address to transfer token from.
      * @param to Address to transfer token to.
      * @param value Amount of token to transfer.
      */
    function transferFrom(address token, address from, address to, uint256 value)
        external
        onlyAddressInWhitelist
    {
        assembly {

            /* Identifier of transferFrom function
             * keccak256(&#39;transferFrom(address,address,uint256)&#39;) & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
             */
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

            /* calldatacopy(t, f, s) copy s bytes from calldata at position f to mem at position t
             * copy from, to, value from calldata to memory
             */
            calldatacopy(4, 36, 96)

            /* call ERC20 Token contract transferFrom function */
            let result := call(gas, token, 0, 0, 100, 0, 32)

            /* Some ERC20 Token contract doesn&#39;t return any value when calling the transferFrom function successfully.
             * So we consider the transferFrom call is successful in either case below.
             *   1. call successfully and nothing return.
             *   2. call successfully, return value is 32 bytes long and the value isn&#39;t equal to zero.
             */
            if eq(result, 1) {
                if or(eq(returndatasize, 0), and(eq(returndatasize, 32), gt(mload(0), 0))) {
                    return(0, 0)
                }
            }
        }

        revert("TRANSFER_FROM_FAILED");
    }
}