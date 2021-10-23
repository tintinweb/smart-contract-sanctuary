/**
 *Submitted for verification at polygonscan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File: contracts/interfaces/ZTMCitizens_interfaces.sol


pragma solidity ^0.8.0;

interface IZTMCitizensVersioned {
    function registerUnverifiedCitizen(
        string memory firstName,
        string memory middleName,
        string memory lastName,
        string memory country,
        string memory citizenship,
        string memory currentState,
        string memory currentCity,
        string memory currentZip,
        string memory linkedin,
        address citizenAddress,
        bytes memory signature
    ) external;

    function updateUnverifiedCitizen(
        string memory firstName,
        string memory middleName,
        string memory lastName,
        string memory country,
        string memory citizenship,
        string memory currentState,
        string memory currentCity,
        string memory currentZip,
        string memory linkedin,
        string memory citizenID,
        address citizenAddress,
        bytes memory signature
    ) external;

    function getUnverifiedCitizen(string memory citizenID)
        external
        view
        returns (
            address citizenAddress,
            string memory firstName,
            string memory middleName,
            string memory lastName,
            string memory citizenship,
            string memory linkedin
        );

    function getUnverifiedCitizenExtraData(string memory citizenID)
        external
        view
        returns (
            string memory country,
            string memory currentState,
            string memory currentCity,
            string memory currentZip,
            uint256 version,
            uint256 createdAt
        );

    function getUnverifiedCitizenAddressIndex(address citizenAddress)
        external
        view
        returns (
            string memory citizenID,
            uint256 citizenIndex,
            string memory contractVersion
        );

    function getUnverifiedCitizenIndicesByCursor(uint256 cursor, uint256 length)
        external
        view
        returns (uint256[] memory);

    function getCitizenVersion(string memory citizenID)
        external
        view
        returns (uint256 citizenVersion);

    function _UNVERIFIED_CITIZEN_CONTRACT_VERSION()
        external
        view
        returns (string memory);
}

// File: contracts/ZTMCitizens.sol


pragma solidity ^0.8.0;



/**
 * @title ZTMCitizens Contract
 * @dev Responsible for creating citizens and assigning roles.
 * It also provides all the information of citizen including roles. Citizen's information can be updated and roles can be assigned or revoked too.
 */
contract ZTMCitizens is Initializable {
    IZTMCitizensVersioned private _currentVersionedSC;

    //addresses of all  non upgradeable Unverified citizen's contract deployed so far
    address[] private _allNonUpgrdeables;

    address private _contractOwner;

    /**
     * @dev It is similar as constructor method which is called only once during the time of deployment
     */
    function contractConstructor() external initializer {
        _contractOwner = msg.sender;
    }

    /**
     * @dev Instantiate ZTMCitizens versioned smartcontract. Only owner has permission to execute this method
     * @param versionedCitizenSCAddress address of a deployed versioned ZTMCitizens contract
     */
    function citizenInit(address versionedCitizenSCAddress) external {
        require(
            msg.sender == _contractOwner,
            "Permission denied. Not a contract owner"
        );
        _currentVersionedSC = IZTMCitizensVersioned(versionedCitizenSCAddress);
        //keep the deployment addresses of versioned contract in state variable
        _allNonUpgrdeables.push(versionedCitizenSCAddress);
    }

    /**
     * @dev Accepts the citizen information and saves it in the blockchain.
     * @param firstName first name of a citizen. ex: "John"
     * @param middleName middle name of a citizen. ex: "Disilva"
     * @param lastName last name of a citizen. ex: "Mayor"
     * @param country country of a citizen. ex: "United States of America"
     * @param citizenship citizenship of a citizen. ex: "C-1234567"
     * @param currentState current state of a citizen. ex: "California"
     * @param currentCity current city of a citizen. ex:"Frenso"
     * @param currentZip current zip of a citizen. ex:"90011"
     * @param linkedin linkedin of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     * @param signature externally signed message for signer address verification
     */
    function registerUnverifiedCitizen(
        string memory firstName,
        string memory middleName,
        string memory lastName,
        string memory country,
        string memory citizenship,
        string memory currentState,
        string memory currentCity,
        string memory currentZip,
        string memory linkedin,
        bytes memory signature
    ) external {
        _currentVersionedSC.registerUnverifiedCitizen(
            firstName,
            middleName,
            lastName,
            country,
            citizenship,
            currentState,
            currentCity,
            currentZip,
            linkedin,
            msg.sender,
            signature
        );
    }

    /**
     * @dev Accepts the citizen information and updates it in the blockchain.
     * @param firstName first name of a citizen. ex: "John"
     * @param middleName middle name of a citizen. ex: "Disilva"
     * @param lastName last name of a citizen. ex: "Mayor"
     * @param country country of a citizen. ex: "United States of America"
     * @param citizenship citizenship of a citizen. ex: "C-1234567"
     * @param currentState current state of a citizen. ex: "California"
     * @param currentCity current city of a citizen. ex:"Frenso"
     * @param currentZip current zip of a citizen. ex:"90011"
     * @param linkedin linkedin of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     * @param citizenID ID of a citizen. ex"ZTMCitizen:v1:1"
     * @param signature externally signed message for signer address verification
     */
    function updateUnverifiedCitizen(
        string memory firstName,
        string memory middleName,
        string memory lastName,
        string memory country,
        string memory citizenship,
        string memory currentState,
        string memory currentCity,
        string memory currentZip,
        string memory linkedin,
        string memory citizenID,
        bytes memory signature
    ) external {
        _currentVersionedSC.updateUnverifiedCitizen(
            firstName,
            middleName,
            lastName,
            country,
            citizenship,
            currentState,
            currentCity,
            currentZip,
            linkedin,
            citizenID,
            msg.sender,
            signature
        );
    }

    /**
     * @dev Get the citizen version based on citizenID
     * @param citizenID address of a citizen
     * @return citizenVersion version of a citizen record
     */
    function getCitizenVersion(string memory citizenID)
        external
        view
        returns (uint256 citizenVersion)
    {
        return _currentVersionedSC.getCitizenVersion(citizenID);
    }

    /**
     * @dev Returns the citizen's information
     * @param citizenID ID of a citizen
     * @return citizenAddress address of a citizen
     * @return firstName first name of a citizen
     * @return middleName middle name of a citizen
     * @return lastName last name of a citizen
     * @return citizenship citizenship of a citizen
     * @return linkedin linkedin of a citizen
     */
    function getUnverifiedCitizen(string memory citizenID)
        external
        view
        returns (
            address citizenAddress,
            string memory firstName,
            string memory middleName,
            string memory lastName,
            string memory citizenship,
            string memory linkedin
        )
    {
        return _currentVersionedSC.getUnverifiedCitizen(citizenID);
    }

    /**
     * @dev Returns the citizen's information remaining data
     * @param citizenID ID of a citizen
     * @return country country of a citizen
     * @return currentState current state of a citizen
     * @return currentCity current city of a citizen
     * @return currentZip current zip of a citizen
     * @return version latest version of citizen data
     * @return createdAt timestamp when citizen record created
     */
    function getUnverifiedCitizenExtraData(string memory citizenID)
        external
        view
        returns (
            string memory country,
            string memory currentState,
            string memory currentCity,
            string memory currentZip,
            uint256 version,
            uint256 createdAt
        )
    {
        return _currentVersionedSC.getUnverifiedCitizenExtraData(citizenID);
    }

    /**
     * @dev Get the citizen index wrt to citizen address
     * @param citizenAddress address of a citizen
     * @return citizenID string ID of a citizen
     * @return citizenIndex index of a citizen record
     * @return contractVersion version of a contract
     */
    function getUnverifiedCitizenAddressIndex(address citizenAddress)
        external
        view
        returns (
            string memory citizenID,
            uint256 citizenIndex,
            string memory contractVersion
        )
    {
        return
            _currentVersionedSC.getUnverifiedCitizenAddressIndex(
                citizenAddress
            );
    }

    /**
     * @dev Get the latest version of a contract
     * @return version latest version of a contract running
     */
    function getContractVersion()
        external
        view
        returns (string memory version)
    {
        return _currentVersionedSC._UNVERIFIED_CITIZEN_CONTRACT_VERSION();
    }

    /**
     * @dev Returns the citizen's addresses. Returing a big size array takes time so cursor is implemented to return addresses in a chunk.
     * @param cursor array index from which to return
     * @param length length of an array to return when request is made
     * @param searchContractVersion version of contract to be searched for citizen
     * @return indices array of addresses based on cursor and length
     */
    function getUnverifiedCitizenIndicesByCursor(
        uint256 cursor,
        uint256 length,
        uint256 searchContractVersion
    ) external view returns (uint256[] memory indices) {
        return
            IZTMCitizensVersioned(_allNonUpgrdeables[searchContractVersion - 1])
                .getUnverifiedCitizenIndicesByCursor(cursor, length);
    }
}