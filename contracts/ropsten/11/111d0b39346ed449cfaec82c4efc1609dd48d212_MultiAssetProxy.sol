pragma solidity 0.4.24;

contract IOwnable {

    function transferOwnership(address newOwner)
        public;
}


contract Ownable is
    IOwnable
{
    address public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "ONLY_CONTRACT_OWNER"
        );
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract IAuthorizable is
    IOwnable
{
    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;
    
    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory);
}



contract MAuthorizable is
    IAuthorizable
{
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized { revert(); _; }
}


contract MixinAuthorizable is
    Ownable,
    MAuthorizable
{
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        require(
            authorized[msg.sender],
            "SENDER_NOT_AUTHORIZED"
        );
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        onlyOwner
    {
        require(
            !authorized[target],
            "TARGET_ALREADY_AUTHORIZED"
        );

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        onlyOwner
    {
        require(
            authorized[target],
            "TARGET_NOT_AUTHORIZED"
        );

        delete authorized[target];
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        onlyOwner
    {
        require(
            authorized[target],
            "TARGET_NOT_AUTHORIZED"
        );
        require(
            index < authorities.length,
            "INDEX_OUT_OF_BOUNDS"
        );
        require(
            authorities[index] == target,
            "AUTHORIZED_ADDRESS_MISMATCH"
        );

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.length -= 1;
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
        return authorities;
    }
}

contract IAssetProxy is
    IAuthorizable
{
    /// @dev Transfers assets. Either succeeds or throws.
    /// @param assetData Byte array encoded for the respective asset proxy.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes assetData,
        address from,
        address to,
        uint256 amount
    )
        external;
    
    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4);
}


contract IAssetProxyDispatcher {

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        external;

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
}


contract MAssetProxyDispatcher is
    IAssetProxyDispatcher
{
    // Logs registration of new asset proxy
    event AssetProxyRegistered(
        bytes4 id,              // Id of new registered AssetProxy.
        address assetProxy      // Address of new registered AssetProxy.
    );

    /// @dev Forwards arguments to assetProxy and calls `transferFrom`. Either succeeds or throws.
    /// @param assetData Byte array encoded for the asset.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param amount Amount of token to transfer.
    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal;
}

contract MixinAssetProxyDispatcher is
    Ownable,
    MAssetProxyDispatcher
{
    // Mapping from Asset Proxy Id&#39;s to their respective Asset Proxy
    mapping (bytes4 => IAssetProxy) public assetProxies;

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        external
        onlyOwner
    {
        IAssetProxy assetProxyContract = IAssetProxy(assetProxy);

        // Ensure that no asset proxy exists with current id.
        bytes4 assetProxyId = assetProxyContract.getProxyId();
        address currentAssetProxy = assetProxies[assetProxyId];
        require(
            currentAssetProxy == address(0),
            "ASSET_PROXY_ALREADY_EXISTS"
        );

        // Add asset proxy and log registration.
        assetProxies[assetProxyId] = assetProxyContract;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address)
    {
        return assetProxies[assetProxyId];
    }

    /// @dev Forwards arguments to assetProxy and calls `transferFrom`. Either succeeds or throws.
    /// @param assetData Byte array encoded for the asset.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param amount Amount of token to transfer.
    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        // Do nothing if no amount should be transferred.
        if (amount > 0 && from != to) {
            // Ensure assetData length is valid
            require(
                assetData.length > 3,
                "LENGTH_GREATER_THAN_3_REQUIRED"
            );
            
            // Lookup assetProxy. We do not use `LibBytes.readBytes4` for gas efficiency reasons.
            bytes4 assetProxyId;
            assembly {
                assetProxyId := and(mload(
                    add(assetData, 32)),
                    0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
                )
            }
            address assetProxy = assetProxies[assetProxyId];

            // Ensure that assetProxy exists
            require(
                assetProxy != address(0),
                "ASSET_PROXY_DOES_NOT_EXIST"
            );
            
            // We construct calldata for the `assetProxy.transferFrom` ABI.
            // The layout of this calldata is in the table below.
            // 
            // | Area     | Offset | Length  | Contents                                    |
            // | -------- |--------|---------|-------------------------------------------- |
            // | Header   | 0      | 4       | function selector                           |
            // | Params   |        | 4 * 32  | function parameters:                        |
            // |          | 4      |         |   1. offset to assetData (*)                |
            // |          | 36     |         |   2. from                                   |
            // |          | 68     |         |   3. to                                     |
            // |          | 100    |         |   4. amount                                 |
            // | Data     |        |         | assetData:                                  |
            // |          | 132    | 32      | assetData Length                            |
            // |          | 164    | **      | assetData Contents                          |

            assembly {
                /////// Setup State ///////
                // `cdStart` is the start of the calldata for `assetProxy.transferFrom` (equal to free memory ptr).
                let cdStart := mload(64)
                // `dataAreaLength` is the total number of words needed to store `assetData`
                //  As-per the ABI spec, this value is padded up to the nearest multiple of 32,
                //  and includes 32-bytes for length.
                let dataAreaLength := and(add(mload(assetData), 63), 0xFFFFFFFFFFFE0)
                // `cdEnd` is the end of the calldata for `assetProxy.transferFrom`.
                let cdEnd := add(cdStart, add(132, dataAreaLength))

                
                /////// Setup Header Area ///////
                // This area holds the 4-byte `transferFromSelector`.
                // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
                mstore(cdStart, 0xa85e59e400000000000000000000000000000000000000000000000000000000)
                
                /////// Setup Params Area ///////
                // Each parameter is padded to 32-bytes. The entire Params Area is 128 bytes.
                // Notes:
                //   1. The offset to `assetData` is the length of the Params Area (128 bytes).
                //   2. A 20-byte mask is applied to addresses to zero-out the unused bytes.
                mstore(add(cdStart, 4), 128)
                mstore(add(cdStart, 36), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 68), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 100), amount)
                
                /////// Setup Data Area ///////
                // This area holds `assetData`.
                let dataArea := add(cdStart, 132)
                // solhint-disable-next-line no-empty-blocks
                for {} lt(dataArea, cdEnd) {} {
                    mstore(dataArea, mload(assetData))
                    dataArea := add(dataArea, 32)
                    assetData := add(assetData, 32)
                }

                /////// Call `assetProxy.transferFrom` using the constructed calldata ///////
                let success := call(
                    gas,                    // forward all gas
                    assetProxy,             // call address of asset proxy
                    0,                      // don&#39;t send any ETH
                    cdStart,                // pointer to start of input
                    sub(cdEnd, cdStart),    // length of input  
                    cdStart,                // write output over input
                    512                     // reserve 512 bytes for output
                )
                if iszero(success) {
                    revert(cdStart, returndatasize())
                }
            }
        }
    }
}


contract MultiAssetProxy is
    MixinAssetProxyDispatcher,
    MixinAuthorizable
{
    // Id of this proxy.
    bytes4 constant internal PROXY_ID = bytes4(keccak256("MultiAsset(uint256[],bytes[])"));

    // solhint-disable-next-line payable-fallback
    function ()
        external
    {
        assembly {
            // The first 4 bytes of calldata holds the function selector
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

            // `transferFrom` will be called with the following parameters:
            // assetData Encoded byte array.
            // from Address to transfer asset from.
            // to Address to transfer asset to.
            // amount Amount of asset to transfer.
            // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {

                // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                // where k is the key left padded to 32 bytes and p is the storage slot
                mstore(0, caller)
                mstore(32, authorized_slot)

                // Revert if authorized[msg.sender] == false
                if iszero(sload(keccak256(0, 64))) {
                    // Revert with `Error("SENDER_NOT_AUTHORIZED")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // `transferFrom`.
                // The function is marked `external`, so no abi decoding is done for
                // us. Instead, we expect the `calldata` memory to contain the
                // following:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 4 * 32  | function parameters:                |
                // |          | 4      |         |   1. offset to assetData (*)        |
                // |          | 36     |         |   2. from                           |
                // |          | 68     |         |   3. to                             |
                // |          | 100    |         |   4. amount                         |
                // | Data     |        |         | assetData:                          |
                // |          | 132    | 32      | assetData Length                    |
                // |          | 164    | **      | assetData Contents                  |
                //
                // (*): offset is computed from start of function parameters, so offset
                //      by an additional 4 bytes in the calldata.
                //
                // (**): see table below to compute length of assetData Contents
                //
                // WARNING: The ABIv2 specification allows additional padding between
                //          the Params and Data section. This will result in a larger
                //          offset to assetData.

                // Load offset to `assetData`
                let assetDataOffset := calldataload(4)

                // Asset data itself is encoded as follows:
                //
                // | Area     | Offset      | Length  | Contents                            |
                // |----------|-------------|---------|-------------------------------------|
                // | Header   | 0           | 4       | assetProxyId                        |
                // | Params   |             | 2 * 32  | function parameters:                |
                // |          | 4           |         |   1. offset to amounts (*)          |
                // |          | 36          |         |   2. offset to nestedAssetData (*)  |
                // | Data     |             |         | amounts:                            |
                // |          | 68          | 32      | amounts Length                      |
                // |          | 100         | a       | amounts Contents                    | 
                // |          |             |         | nestedAssetData:                    |
                // |          | 100 + a     | 32      | nestedAssetData Length              |
                // |          | 132 + a     | b       | nestedAssetData Contents (offsets)  |
                // |          | 132 + a + b |         | nestedAssetData[0, ..., len]        |

                // In order to find the offset to `amounts`, we must add:
                // 4 (function selector)
                // + assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                let amountsOffset := calldataload(add(assetDataOffset, 40))

                // In order to find the offset to `nestedAssetData`, we must add:
                // 4 (function selector)
                // + assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + 32 (amounts offset)
                let nestedAssetDataOffset := calldataload(add(assetDataOffset, 72))

                // In order to find the start of the `amounts` contents, we must add: 
                // 4 (function selector) 
                // + assetDataOffset 
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + amountsOffset
                // + 32 (amounts len)
                let amountsContentsStart := add(assetDataOffset, add(amountsOffset, 72))

                // Load number of elements in `amounts`
                let amountsLen := calldataload(sub(amountsContentsStart, 32))

                // In order to find the start of the `nestedAssetData` contents, we must add: 
                // 4 (function selector) 
                // + assetDataOffset 
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + nestedAssetDataOffset
                // + 32 (nestedAssetData len)
                let nestedAssetDataContentsStart := add(assetDataOffset, add(nestedAssetDataOffset, 72))

                // Load number of elements in `nestedAssetData`
                let nestedAssetDataLen := calldataload(sub(nestedAssetDataContentsStart, 32))

                // Revert if number of elements in `amounts` differs from number of elements in `nestedAssetData`
                if iszero(eq(amountsLen, nestedAssetDataLen)) {
                    // Revert with `Error("LENGTH_MISMATCH")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000f4c454e4754485f4d49534d4154434800000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // Copy `transferFrom` selector, offset to `assetData`, `from`, and `to` from calldata to memory
                calldatacopy(
                    0,   // memory can safely be overwritten from beginning
                    0,   // start of calldata
                    100  // length of selector (4) and 3 params (32 * 3)
                )

                // Overwrite existing offset to `assetData` with our own
                mstore(4, 128)
                
                // Load `amount`
                let amount := calldataload(100)
        
                // Calculate number of bytes in `amounts` contents
                let amountsByteLen := mul(amountsLen, 32)

                // Initialize `assetProxyId` and `assetProxy` to 0
                let assetProxyId := 0
                let assetProxy := 0

                // Loop through `amounts` and `nestedAssetData`, calling `transferFrom` for each respective element
                for {let i := 0} lt(i, amountsByteLen) {i := add(i, 32)} {

                    // Calculate the total amount
                    let amountsElement := calldataload(add(amountsContentsStart, i))
                    let totalAmount := mul(amountsElement, amount)

                    // Revert if multiplication resulted in an overflow
                    if iszero(eq(div(totalAmount, amount), amountsElement)) {
                        // Revert with `Error("UINT256_OVERFLOW")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001055494e543235365f4f564552464c4f57000000000000000000000000)
                        mstore(96, 0)
                        revert(0, 100)
                    }

                    // Write `totalAmount` to memory
                    mstore(100, totalAmount)

                    // Load offset to `nestedAssetData[i]`
                    let nestedAssetDataElementOffset := calldataload(add(nestedAssetDataContentsStart, i))

                    // In order to find the start of the `nestedAssetData[i]` contents, we must add:
                    // 4 (function selector) 
                    // + assetDataOffset 
                    // + 32 (assetData len)
                    // + 4 (assetProxyId)
                    // + nestedAssetDataOffset
                    // + 32 (nestedAssetData len)
                    // + nestedAssetDataElementOffset
                    // + 32 (nestedAssetDataElement len)
                    let nestedAssetDataElementContentsStart := add(assetDataOffset, add(nestedAssetDataOffset, add(nestedAssetDataElementOffset, 104)))

                    // Load length of `nestedAssetData[i]`
                    let nestedAssetDataElementLenStart := sub(nestedAssetDataElementContentsStart, 32)
                    let nestedAssetDataElementLen := calldataload(nestedAssetDataElementLenStart)

                    // Revert if the `nestedAssetData` does not contain a 4 byte `assetProxyId`
                    if lt(nestedAssetDataElementLen, 4) {
                        // Revert with `Error("LENGTH_GREATER_THAN_3_REQUIRED")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001e4c454e4754485f475245415445525f5448414e5f335f524551554952)
                        mstore(96, 0x4544000000000000000000000000000000000000000000000000000000000000)
                        revert(0, 100)
                    }

                    // Load AssetProxy id
                    let currentAssetProxyId := and(
                        calldataload(nestedAssetDataElementContentsStart),
                        0xffffffff00000000000000000000000000000000000000000000000000000000
                    )

                    // Only load `assetProxy` if `currentAssetProxyId` does not equal `assetProxyId`
                    // We do not need to check if `currentAssetProxyId` is 0 since `assetProxy` is also initialized to 0
                    if iszero(eq(currentAssetProxyId, assetProxyId)) {
                        // Update `assetProxyId`
                        assetProxyId := currentAssetProxyId
                        // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                        // where k is the key left padded to 32 bytes and p is the storage slot
                        mstore(132, assetProxyId)
                        mstore(164, assetProxies_slot)
                        assetProxy := sload(keccak256(132, 64))
                    }
                    
                    // Revert if AssetProxy with given id does not exist
                    if iszero(assetProxy) {
                        // Revert with `Error("ASSET_PROXY_DOES_NOT_EXIST")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001a41535345545f50524f58595f444f45535f4e4f545f45584953540000)
                        mstore(96, 0)
                        revert(0, 100)
                    }
    
                    // Copy `nestedAssetData[i]` from calldata to memory
                    calldatacopy(
                        132,                                // memory slot after `amounts[i]`
                        nestedAssetDataElementLenStart,     // location of `nestedAssetData[i]` in calldata
                        add(nestedAssetDataElementLen, 32)  // `nestedAssetData[i].length` plus 32 byte length
                    )

                    // call `assetProxy.transferFrom`
                    let success := call(
                        gas,                                    // forward all gas
                        assetProxy,                             // call address of asset proxy
                        0,                                      // don&#39;t send any ETH
                        0,                                      // pointer to start of input
                        add(164, nestedAssetDataElementLen),    // length of input  
                        0,                                      // write output over memory that won&#39;t be reused
                        0                                       // don&#39;t copy output to memory
                    )

                    // Revert with reason given by AssetProxy if `transferFrom` call failed
                    if iszero(success) {
                        returndatacopy(
                            0,                // copy to memory at 0
                            0,                // copy from return data at 0
                            returndatasize()  // copy all return data
                        )
                        revert(0, returndatasize())
                    }
                }

                // Return if no `transferFrom` calls reverted
                return(0, 0)
            }

            // Revert if undefined function is called
            revert(0, 0)
        }
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}