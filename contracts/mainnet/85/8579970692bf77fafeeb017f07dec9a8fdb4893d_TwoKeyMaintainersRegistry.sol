/**
 *Submitted for verification at Etherscan.io on 2021-02-01
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

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
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

contract TwoKeyMaintainersRegistryAbstract is Upgradeable {
    /**
     * All keys used for the storage contract.
     * Saved as a constants to avoid any potential typos
     */
    string constant _isMaintainer = "isMaintainer";
    string constant _isCoreDev = "isCoreDev";
    string constant _idToMaintainer = "idToMaintainer";
    string constant _idToCoreDev = "idToCoreDev";
    string constant _numberOfMaintainers = "numberOfMaintainers";
    string constant _numberOfCoreDevs = "numberOfCoreDevs";
    string constant _numberOfActiveMaintainers = "numberOfActiveMaintainers";
    string constant _numberOfActiveCoreDevs = "numberOfActiveCoreDevs";

    //For all math operations we use safemath
    using SafeMath for *;

    // Flag which will make function setInitialParams callable only once
    bool initialized;

    address public TWO_KEY_SINGLETON_REGISTRY;

    IStructuredStorage public PROXY_STORAGE_CONTRACT;


    /**
     * @notice Function which can be called only once, and is used as replacement for a constructor
     * @param _twoKeySingletonRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy of storage contract
     * @param _maintainers is the array of initial maintainers we'll kick off contract with
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage,
        address [] _maintainers,
        address [] _coreDevs
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        PROXY_STORAGE_CONTRACT = IStructuredStorage(_proxyStorage);

        //Deployer is also maintainer
        addMaintainer(msg.sender);

        //Set initial maintainers
        for(uint i=0; i<_maintainers.length; i++) {
            addMaintainer(_maintainers[i]);
        }

        //Set initial core devs
        for(uint j=0; j<_coreDevs.length; j++) {
            addCoreDev(_coreDevs[j]);
        }

        //Once this executes, this function will not be possible to call again.
        initialized = true;
    }


    /**
     * @notice Function which will determine if address is maintainer
     */
    function checkIsAddressMaintainer(address _sender) public view returns (bool) {
        return isMaintainer(_sender);
    }

    /**
     * @notice Function which will determine if address is core dev
     */
    function checkIsAddressCoreDev(address _sender) public view returns (bool) {
        return isCoreDev(_sender);
    }

    /**
     * @notice Function to get all maintainers set DURING CAMPAIGN CREATION
     */
    function getAllMaintainers()
    public
    view
    returns (address[])
    {
        uint numberOfMaintainersTotal = getNumberOfMaintainers();
        uint numberOfActiveMaintainers = getNumberOfActiveMaintainers();
        address [] memory activeMaintainers = new address[](numberOfActiveMaintainers);

        uint counter = 0;
        for(uint i=0; i<numberOfMaintainersTotal; i++) {
            address maintainer = getMaintainerPerId(i);
            if(isMaintainer(maintainer)) {
                activeMaintainers[counter] = maintainer;
                counter = counter.add(1);
            }
        }
        return activeMaintainers;
    }


    /**
     * @notice Function to get all maintainers set DURING CAMPAIGN CREATION
     */
    function getAllCoreDevs()
    public
    view
    returns (address[])
    {
        uint numberOfCoreDevsTotal = getNumberOfCoreDevs();
        uint numberOfActiveCoreDevs = getNumberOfActiveCoreDevs();
        address [] memory activeCoreDevs = new address[](numberOfActiveCoreDevs);

        uint counter = 0;
        for(uint i=0; i<numberOfActiveCoreDevs; i++) {
            address coreDev= getCoreDevPerId(i);
            if(isCoreDev(coreDev)) {
                activeCoreDevs[counter] = coreDev;
                counter = counter.add(1);
            }
        }
        return activeCoreDevs;
    }

    /**
     * @notice Function to check if address is maintainer
     * @param _address is the address we're checking if it's maintainer or not
     */
    function isMaintainer(
        address _address
    )
    internal
    view
    returns (bool)
    {
        bytes32 keyHash = keccak256(_isMaintainer, _address);
        return PROXY_STORAGE_CONTRACT.getBool(keyHash);
    }

    /**
     * @notice Function to check if address is coreDev
     * @param _address is the address we're checking if it's coreDev or not
     */
    function isCoreDev(
        address _address
    )
    internal
    view
    returns (bool)
    {
        bytes32 keyHash = keccak256(_isCoreDev, _address);
        return PROXY_STORAGE_CONTRACT.getBool(keyHash);
    }

    /**
     * @notice Function which will add maintainer
     * @param _maintainer is the address of new maintainer we're adding
     */
    function addMaintainer(
        address _maintainer
    )
    internal
    {

        bytes32 keyHashIsMaintainer = keccak256(_isMaintainer, _maintainer);

        // Fetch the id for the new maintainer
        uint id = getNumberOfMaintainers();

        // Generate keyHash for this maintainer
        bytes32 keyHashIdToMaintainer = keccak256(_idToMaintainer, id);

        // Representing number of different maintainers
        incrementNumberOfMaintainers();
        // Representing number of currently active maintainers
        incrementNumberOfActiveMaintainers();

        PROXY_STORAGE_CONTRACT.setAddress(keyHashIdToMaintainer, _maintainer);
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsMaintainer, true);
    }


    /**
     * @notice Function which will add maintainer
     * @param _coreDev is the address of new maintainer we're adding
     */
    function addCoreDev(
        address _coreDev
    )
    internal
    {

        bytes32 keyHashIsCoreDev = keccak256(_isCoreDev, _coreDev);

        // Fetch the id for the new core dev
        uint id = getNumberOfCoreDevs();

        // Generate keyHash for this core dev
        bytes32 keyHashIdToCoreDev= keccak256(_idToCoreDev, id);

        // Representing number of different core devs
        incrementNumberOfCoreDevs();
        // Representing number of currently active core devs
        incrementNumberOfActiveCoreDevs();

        PROXY_STORAGE_CONTRACT.setAddress(keyHashIdToCoreDev, _coreDev);
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsCoreDev, true);
    }

    /**
     * @notice Function which will remove maintainer
     * @param _maintainer is the address of the maintainer we're removing
     */
    function removeMaintainer(
        address _maintainer
    )
    internal
    {
        bytes32 keyHashIsMaintainer = keccak256(_isMaintainer, _maintainer);
        decrementNumberOfActiveMaintainers();
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsMaintainer, false);
    }

    /**
     * @notice Function which will remove maintainer
     * @param _coreDev is the address of the maintainer we're removing
     */
    function removeCoreDev(
        address _coreDev
    )
    internal
    {
        bytes32 keyHashIsCoreDev = keccak256(_isCoreDev , _coreDev);
        decrementNumberOfActiveCoreDevs();
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsCoreDev, false);
    }

    function getNumberOfMaintainers()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfMaintainers));
    }

    function getNumberOfCoreDevs()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfCoreDevs));
    }

    function getNumberOfActiveMaintainers()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfActiveMaintainers));
    }

    function getNumberOfActiveCoreDevs()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfActiveCoreDevs));
    }


    function incrementNumberOfMaintainers()
    internal
    {
        bytes32 keyHashNumberOfMaintainers = keccak256(_numberOfMaintainers);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfMaintainers,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfMaintainers).add(1)
        );
    }


    function incrementNumberOfCoreDevs()
    internal
    {
        bytes32 keyHashNumberOfCoreDevs = keccak256(_numberOfCoreDevs);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfCoreDevs,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfCoreDevs).add(1)
        );
    }


    function incrementNumberOfActiveMaintainers()
    internal
    {
        bytes32 keyHashNumberOfActiveMaintainers = keccak256(_numberOfActiveMaintainers);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfActiveMaintainers,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfActiveMaintainers).add(1)
        );
    }

    function incrementNumberOfActiveCoreDevs()
    internal
    {
        bytes32 keyHashNumberToActiveCoreDevs= keccak256(_numberOfActiveCoreDevs);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberToActiveCoreDevs,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberToActiveCoreDevs).add(1)
        );
    }

    function decrementNumberOfActiveMaintainers()
    internal
    {
        bytes32 keyHashNumberOfActiveMaintainers = keccak256(_numberOfActiveMaintainers);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfActiveMaintainers,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfActiveMaintainers).sub(1)
        );
    }

    function decrementNumberOfActiveCoreDevs()
    internal
    {
        bytes32 keyHashNumberToActiveCoreDevs = keccak256(_numberOfActiveCoreDevs);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberToActiveCoreDevs,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberToActiveCoreDevs).sub(1)
        );
    }

    function getMaintainerPerId(
        uint _id
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_idToMaintainer,_id));
    }


    function getCoreDevPerId(
        uint _id
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_idToCoreDev,_id));
    }


    // Internal function to fetch address from TwoKeyRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

}

contract TwoKeyMaintainersRegistry is TwoKeyMaintainersRegistryAbstract {
    /**
     * @notice Modifier to restrict calling the method to anyone but twoKeyAdmin
     */
    modifier onlyTwoKeyAdmin() {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(msg.sender == address(twoKeyAdmin));
        _;
    }

    /**
     * @notice Function which can add new maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function addMaintainers(
        address [] _maintainers
    )
    public
    onlyTwoKeyAdmin
    {
        uint numberOfMaintainersToAdd = _maintainers.length;
        for(uint i=0; i<numberOfMaintainersToAdd; i++) {
            addMaintainer(_maintainers[i]);
        }
    }

    /**
     * @notice Function which can add new core devs, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of core devs
     * @param _coreDevs is the array of core developer addresses
     */
    function addCoreDevs(
        address [] _coreDevs
    )
    public
    onlyTwoKeyAdmin
    {
        uint numberOfCoreDevsToAdd = _coreDevs.length;
        for(uint i=0; i<numberOfCoreDevsToAdd; i++) {
            addCoreDev(_coreDevs[i]);
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function removeMaintainers(
        address [] _maintainers
    )
    public
    onlyTwoKeyAdmin
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;

        for(uint i=0; i<numberOfMaintainers; i++) {
            removeMaintainer(_maintainers[i]);
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _coreDevs is the array of maintainer addresses
     */
    function removeCoreDevs(
        address [] _coreDevs
    )
    public
    onlyTwoKeyAdmin
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfCoreDevs = _coreDevs.length;

        for(uint i=0; i<numberOfCoreDevs; i++) {
            removeCoreDev(_coreDevs[i]);
        }
    }


}