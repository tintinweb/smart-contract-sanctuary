/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.13;

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyEventSourceEvents {
    // This 2 functions will be always in the interface since we need them very often
    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);

    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external;

    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external;

    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external;

    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external;

    function priceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    )
    external;

    function userRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    )
    external;

    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external;


    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public;


}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

contract ITwoKeyRegistryStorage is IStructuredStorage {

}

library Call {
    function params0(address c, bytes _method) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x04, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params1(address c, bytes _method, uint _val) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)
        // append argument after function sig
            mstore(add(ptr,0x04), _val)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x24, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params2(address c, bytes _method, uint _val1, uint _val2) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), _val1)
            mstore(add(ptr,0x24), _val2)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x44, // Inputs are 4 bytes for signature and 2 uint256
            ptr,  //Store output over input
            0x20) //Outputs are 1 uint long

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x20)) // Set storage pointer to new space
        }
    }

    function loadAddress(bytes sig, uint idx) public pure returns (address) {
        address influencer;
        idx += 20;
        assembly
        {
            influencer := mload(add(sig, idx))
        }
        return influencer;
    }

    function loadUint8(bytes sig, uint idx) public pure returns (uint8) {
        uint8 weight;
        idx += 1;
        assembly
        {
            weight := mload(add(sig, idx))
        }
        return weight;
    }


    function recoverHash(bytes32 hash, bytes sig, uint idx) public pure returns (address) {
        // same as recoverHash in utils/sign.js
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        require (sig.length >= 65+idx, 'bad signature length');
        idx += 32;
        bytes32 r;
        assembly
        {
            r := mload(add(sig, idx))
        }

        idx += 32;
        bytes32 s;
        assembly
        {
            s := mload(add(sig, idx))
        }

        idx += 1;
        uint8 v;
        assembly
        {
            v := mload(add(sig, idx))
        }
        if (v >= 32) { // handle case when signature was made with ethereum web3.eth.sign or getSign which is for signing ethereum transactions
            v -= 32;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; // 32 is the number of bytes in the following hash
            hash = keccak256(abi.encodePacked(prefix, hash));
        }
        if (v <= 1) v += 27;
        require(v==27 || v==28,'bad sig v');
        //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L57
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, 'bad sig s');
        return ecrecover(hash, v, r, s);

    }

    function recoverSigMemory(bytes sig) private pure returns (address[], address[], uint8[], uint[], uint) {
        uint8 version = loadUint8(sig, 0);
        uint msg_len = (version == 1) ? 1+65+20 : 1+20+20;
        uint n_influencers = (sig.length-21) / (65+msg_len);
        uint8[] memory weights = new uint8[](n_influencers);
        address[] memory keys = new address[](n_influencers);
        if ((sig.length-21) % (65+msg_len) > 0) {
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        uint[] memory offsets = new uint[](n_influencers);

        return (influencers, keys, weights, offsets, msg_len);
    }

    function recoverSigParts(bytes sig, address last_address) private pure returns (address[], address[], uint8[], uint[]) {
        // sig structure:
        // 1 byte version 0 or 1
        // 20 bytes are the address of the contractor or the influencer who created sig.
        //  this is the "anchor" of the link
        //  It must have a public key aleady stored for it in public_link_key
        // Begining of a loop on steps in the link:
        // * 65 bytes are step-signature using the secret from previous step
        // * message of the step that is going to be hashed and used to compute the above step-signature.
        //   message length depend on version 41 (version 0) or 86 (version 1):
        //   * 1 byte cut (percentage) each influencer takes from the bounty. the cut is stored in influencer2cut or weight for voting
        //   * 20 bytes address of influencer (version 0) or 65 bytes of signature of cut using the influencer address to sign
        //   * 20 bytes public key of the last secret
        // In the last step the message can be optional. If it is missing the message used is the address of the sender
        uint idx = 0;
        uint msg_len;
        uint8[] memory weights;
        address[] memory keys;
        address[] memory influencers;
        uint[] memory offsets;
        (influencers, keys, weights, offsets, msg_len) = recoverSigMemory(sig);
        idx += 1;  // skip version

        idx += 20; // skip old_address which should be read by the caller in order to get old_key
        uint count_influencers = 0;

        while (idx + 65 <= sig.length) {
            offsets[count_influencers] = idx;
            idx += 65;  // idx was increased by 65 for the signature at the begining which we will process later

            if (idx + msg_len <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
                weights[count_influencers] = loadUint8(sig, idx);
                require(weights[count_influencers] > 0,'weight not defined (1..255)');  // 255 are used to indicate default (equal part) behaviour
                idx++;


                if (msg_len == 41)  // 1+20+20 version 0
                {
                    influencers[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                    keys[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                } else if (msg_len == 86)  // 1+65+20 version 1
                {
                    keys[count_influencers] = loadAddress(sig, idx+65);
                    influencers[count_influencers] = recoverHash(
                        keccak256(
                            abi.encodePacked(
                                keccak256(abi.encodePacked("bytes binding to weight","bytes binding to public")),
                                keccak256(abi.encodePacked(weights[count_influencers],keys[count_influencers]))
                            )
                        ),sig,idx);
                    idx += 65;
                    idx += 20;
                }

            } else {
                // handle short signatures generated with free_take
                influencers[count_influencers] = last_address;
            }
            count_influencers++;
        }
        require(idx == sig.length,'illegal message size');

        return (influencers, keys, weights, offsets);
    }

    function recoverSig(bytes sig, address old_key, address last_address) public pure returns (address[], address[], uint8[]) {
        // validate sig AND
        // recover the information from the signature: influencers, public_link_keys, weights/cuts
        // influencers may have one more address than the keys and weights arrays
        //
        require(old_key != address(0),'no public link key');

        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        uint[] memory offsets;
        (influencers, keys, weights, offsets) = recoverSigParts(sig, last_address);

        // check if we received a valid signature
        for(uint i = 0; i < influencers.length; i++) {
            if (i < weights.length) {
                require (recoverHash(keccak256(abi.encodePacked(weights[i], keys[i], influencers[i])),sig,offsets[i]) == old_key, 'illegal signature');
                old_key = keys[i];
            } else {
                // signed message for the last step is the address of the converter
                require (recoverHash(keccak256(abi.encodePacked(influencers[i])),sig,offsets[i]) == old_key, 'illegal last signature');
            }
        }

        return (influencers, keys, weights);
    }
}

contract Utils {

    /**
     * @notice Function to transform string to bytes32
     * @dev string should be less than 32 chars
     */
    function stringToBytes32(
        string memory source
    )
    internal
    pure
    returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @notice Function to concat at most 3 strings
     * @dev If you want to handle concatenation of less than 3, then pass first their values and for the left pass empty strings
     * @return string concatenated
     */
    function strConcat(
        string _a,
        string _b,
        string _c
    )
    internal
    pure
    returns (string)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        return string(babcde);
    }


}

contract ITwoKeySingletonUtils {

    address public TWO_KEY_SINGLETON_REGISTRY;

    // Modifier to restrict method calls only to maintainers
    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    /**
     * @notice Function to get any singleton contract proxy address from TwoKeySingletonRegistry contract
     * @param contractName is the name of the contract we're looking for
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }

    function getNonUpgradableContractAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getNonUpgradableContractAddress(contractName);
    }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

contract TwoKeyRegistry is Upgradeable, Utils, ITwoKeySingletonUtils {

    using Call for *;

    bool initialized;

    string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";

    ITwoKeyRegistryStorage public PROXY_STORAGE_CONTRACT;




    /**
     * @notice          Function which can be called only once
     *                  used as a constructor
     *
     * @param           _twoKeySingletonesRegistry is the address of TwoKeySingletonsRegistry contract
     * @param           _proxyStorage is the address of the proxy contract used as a storage
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyRegistryStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice          Function which is called either during the registration or when user
     *                  decides to change his username
     *
     * @param           _username is the new username user want's to set. Must be unique.
     * @param           _userAddress is the address of the user who is this action being
     *                  performed for.
     *
     */
    function addOrChangeUsernameInternal(
        string _username,
        address _userAddress
    )
    internal
    {
        // Generate the name in the bytes
        bytes32 usernameBytes32 = stringToBytes32(_username);

        // Create key hashes for mappings for username2currentAddress and address2username
        bytes32 keyHashUserNameToAddress = keccak256("username2currentAddress", usernameBytes32);
        bytes32 keyHashAddressToUserName = keccak256("address2username", _userAddress);

        // Assert that username is not taken
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashUserNameToAddress) == address(0));

        // Set mapping address => username
        PROXY_STORAGE_CONTRACT.setString(keyHashAddressToUserName, _username);

        // Set mapping username => address
        PROXY_STORAGE_CONTRACT.setAddress(keyHashUserNameToAddress, _userAddress);
    }


    /**
     * @notice          Function where maintainer can register user
     *
     * @param           _username is the username of the user
     * @param           _userEthereumAddress is the address of the user
     */
    function addName(
        string _username,
        address _userEthereumAddress
    )
    internal
    {
        // Throw if user address already has some username assigned
        bytes memory currentUsernameAssignedToAddress = bytes(address2username(_userEthereumAddress));
        require(currentUsernameAssignedToAddress.length == 0);

        // Here also the validation for uniqueness for this username will be done
        addOrChangeUsernameInternal(_username, _userEthereumAddress);
    }


    /**
     * @notice          Function to map plasma and ethereum addresses for the user
     *                  The signature is generated by 2key-protocol function registry/index.ts
     *                  -> signEthereumToPlasma function
     * @param           signature is the message user signed with his ethereum address
     * @param           plasmaAddress is the plasma address of user which is signed by eth address
     * @param           ethereumAddress is the ethereum address of the user who signed the message
     *
     */
    function addPlasma2Ethereum(
        bytes signature,
        address plasmaAddress,
        address ethereumAddress
    )
    internal
    {
        // Generate the hash
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(plasmaAddress))));

        // Recover ethereumAddress from the hash by signature
        address recoveredEthereumAddress = Call.recoverHash(hash,signature,0);

        // Require that ethereum addresses are matching
        require(ethereumAddress == recoveredEthereumAddress);

        // Generate the keys for the storage for 2 mappings we want to check and update
        bytes32 keyHashPlasmaToEthereum = keccak256("plasma2ethereum", plasmaAddress);
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", ethereumAddress);

        // Assert that both of this address currently don't exist in our system
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashPlasmaToEthereum) == address(0));
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma) == address(0));

        // Store the addresses
        PROXY_STORAGE_CONTRACT.setAddress(keyHashPlasmaToEthereum, ethereumAddress);
        PROXY_STORAGE_CONTRACT.setAddress(keyHashEthereumToPlasma, plasmaAddress);
    }



    /**
     * @notice          Function to register user and set his username by maintainer
     */
    function registerUserByMaintainer(
        bytes signature,
        string username,
        address ethereumAddress,
        address plasmaAddress
    )
    public
    onlyMaintainer
    {
        addName(username, ethereumAddress);
        addPlasma2Ethereum(signature,plasmaAddress,ethereumAddress);
    }



    /**
     * @notice          Function where username can be changed
     *
     * @param           newUsername is the new username user wants to add
     * @param           userPublicAddress is the ethereum address of the user
     */
    function changeUsername(
        string newUsername,
        address userPublicAddress
    )
    public
    onlyMaintainer
    {
        // Get current username which is allocated to this address
        string memory currentUsername = address2username(userPublicAddress);

        // Delete current username=>address mapping
        PROXY_STORAGE_CONTRACT.setAddress(keccak256("username2currentAddress", stringToBytes32(currentUsername)), address(0));

        addOrChangeUsernameInternal(newUsername, userPublicAddress);

        // Emit event on TwoKeyEventSource that the username is changed
        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"))
            .emitHandleChangedEvent(
                getEthereumToPlasma(userPublicAddress),
                newUsername
            );
    }


    /**
     * @notice          Function to read from mapping username => address
     *
     * @param           _username is the username of the user
     */
    function getUserName2UserAddress(
        string _username
    )
    public
    view
    returns (address)
    {
        bytes32 usernameBytes = stringToBytes32(_username);
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256("username2currentAddress", usernameBytes));
    }

    /**
     * @notice          Function to read from the mapping plasma=>ethereum
     *
     * @param           plasmaAddress is the plasma address we're searching eth address for
     */
    function getPlasmaToEthereum(
        address plasmaAddress
    )
    public
    view
    returns (address)
    {
        bytes32 keyHashPlasmaToEthereum = keccak256("plasma2ethereum", plasmaAddress);
        address ethereumAddress = PROXY_STORAGE_CONTRACT.getAddress(keyHashPlasmaToEthereum);

        return ethereumAddress != address(0) ? ethereumAddress : plasmaAddress;
    }

    /**
     * @notice          Function to read from the mapping ethereum => plasma
     *
     * @param           ethereumAddress is the ethereum address we're searching plasma address for
     *
     * @return          plasma address if exist otherwise 0x0 (address(0))
     */
    function getEthereumToPlasma(
        address ethereumAddress
    )
    public
    view
    returns (address)
    {
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", ethereumAddress);
        address plasmaAddress = PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma);

        return plasmaAddress != address(0) ? plasmaAddress : ethereumAddress;
    }


    /**
     * @notice          Function to check if the user exists
     *
     * @param           _userAddress is the address of the user
     *
     * @return          true if exists otherwise false
     */
    function checkIfUserExists(
        address _userAddress
    )
    public
    view
    returns (bool)
    {
        string memory username = PROXY_STORAGE_CONTRACT.getString(keccak256("address2username", _userAddress));
        bytes memory usernameInBytes = bytes(username);
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", _userAddress);
        address plasma = PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma);
        if(usernameInBytes.length == 0 || plasma == address(0)) {
            return false;
        }
        return true;
    }


    /**
     * @notice          Function to get user data
     *
     * @param           _userAddress is the ethereum address of the user
     */
    function getUserData(
        address _userAddress
    )
    public
    view
    returns (bytes)
    {
        string memory username = address2username(_userAddress);
        return (abi.encodePacked(stringToBytes32(username), bytes32(0), bytes32(0)));
    }


    /**
     * @notice          Function to read from the mapping userAddress => username
     *
     * @param           keyAddress is the address we use as the key
     */
    function address2username(
        address keyAddress
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256("address2username", keyAddress));
    }


    /**
     * @notice          Function to read from the mapping username => currentAddress
     *
     * @param           _username is the hex username we want to get address for
     */
    function username2currentAddress(
        bytes32 _username
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256("username2currentAddress", _username));
    }

}