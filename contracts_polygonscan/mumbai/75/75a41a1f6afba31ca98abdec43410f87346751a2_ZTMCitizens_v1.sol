/**
 *Submitted for verification at polygonscan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT
// File: contracts/ZTMHelpers.sol


pragma solidity ^0.8.0;

/**
 * @title ZTMHelpers Contract
 * @dev Contains commain helper methods for other contracts
 */
contract ZTMHelpers {
    /**
     * @dev converts uint256 to string
     * @param v integer value
     */
    function uint2str(uint256 v)
        internal
        pure
        returns (string memory uintAsString)
    {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s); // memory isn't implicitly convertible to storage
        return str;
    }

    /**
     * @dev Concats two values. i.e one string and another integer
     * @param identifier Identifier as a first value to concat
     * @param index second value to concat
     */
    function concatValues(
        string memory identifier,
        string memory version,
        uint256 index
    ) internal pure returns (string memory value) {
        return
            string(
                abi.encodePacked(
                    identifier,
                    ":v",
                    version,
                    ":",
                    uint2str(index)
                )
            );
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recoverSigner(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * @dev Compare two string variables
     * @param firstValue First string variable
     * @param secondValue Second string variable
     * @return true if matches else false
     */
    function matchStrings(string memory firstValue, string memory secondValue)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((firstValue))) ==
            keccak256(abi.encodePacked((secondValue))));
    }
}

// File: contracts/non-upgradeables/ZTMCitizens_v1.sol


pragma solidity ^0.8.0;


/**
 * @dev External interface of versioned ZTMCitizens which is actually a prior version of this contract.
 */
interface PriorZTMCitizens {
    function checkCitizenVersionAndPermission(
        address citizenAddress,
        string memory citizenID
    ) external view returns (uint256 citizenVersion, bool isOwner);

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

    function getCitizenVersion(string memory citizenID)
        external
        view
        returns (uint256 citizenVersion);
}

/**
 * @title ZTMCitizens_v1 Contract
 *
 * This is a non-upgradeable contract which always has a reference to its prior version non-upgradeable contract only if current version is greater than "1".
 * Citizens are registered as non verified citizen on their own. Citiznes are always indexed with unique ID as `ZTMCitizen:v1:1` which is simply a combination of
 * {_CITIZEN_IDENTIFIER}:v{_UNVERIFIED_CITIZEN_CONTRACT_VERSION}:{_lastCitizenIndex}
 */
//solhint-disable-next-line contract-name-camelcase
contract ZTMCitizens_v1 is ZTMHelpers {
    string public constant _UNVERIFIED_CITIZEN_CONTRACT_VERSION = "1";
    string public constant _CITIZEN_IDENTIFIER = "ZTMCitizen";

    //Interface defination
    PriorZTMCitizens private _priorVersionedSC;

    /**
     * @dev Instantiate prior versioned contract of its own.
     * @param _priorVersionedAddress address of prior versioned address. If current version is "2" then it holds the address of "1.x.x".
     */
    constructor(address _priorVersionedAddress) {
        // Initialize prior contract only when current contract is not(greater than) version "1"
        if (!initalVersionedContract()) {
            _priorVersionedSC = PriorZTMCitizens(_priorVersionedAddress);
        }
    }

    /**
     * @dev Unverified Citizen structs.
     *  citizenAddress - public address of a citizen used to regsiter a record.ex:"0xEdAf02F9917716a09ae6a03DF6a5912489239A59"
     *  citizenID - Unique zitizen identifier ex:"ZTMCitizen:v1.1:1"
     *  firstName - first name of a citizen. ex: "John"
     *  middleName - middle name of a citizen. ex: "Disilva"
     *  lastName -last name of a citizen. ex: "Mayor"
     *  country - country of a citizen. ex: "United States of America" or "USA"
     *  citizenship - citizenship of a citizen. ex: "C-1234567"
     *  currentState - current state of a citizen. ex: "California"
     *  currentCity - current city of a citizen. ex:"Frenso"
     *  currentZip - current zip of a citizen. ex:"90011"
     *  linkedin - valid linkedin url of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     *  version - version of a citizen details. ex:1,2,3
     *  citizenCreatedDate - timestamp when citizen data recorded.
     */
    struct Citizen {
        address citizenAddress;
        string citizenID;
        string firstName;
        string middleName;
        string lastName;
        string country;
        string citizenship;
        string currentState;
        string currentCity;
        string currentZip;
        string linkedin;
        uint256 version;
        uint256 citizenCreatedDate;
    }

    /**
     * @dev Every created citizen is mapped with unique string Key and
     */
    mapping(string => mapping(uint256 => Citizen)) private _citizensUnverified;
    mapping(string => uint256) private _citizenLatestVersion;
    mapping(address => uint256) private _citizenAddressToIndex;

    //citizen last index and array of citizen indexes
    uint256 private _lastCitizenIndex;
    uint256[] private _citizenIndices;

    /**
     * @dev This methods is called by the citizen who is trying to register himself as a unverified citizen. User's public address trying to perform the registeration is linked
     * with the citizen.
     * @param firstName - First name of a citizen. ex: "John"
     * @param middleName - Middle name of a citizen. ex: "Disilva"
     * @param lastName - Last name of a citizen. ex: "Mayor"
     * @param country - Country of a citizen. ex: "United States of America" or "USA"
     * @param citizenship - A valid citizenship of a citizen. ex: "C-1234567"
     * @param currentState - Ccurrent state of a citizen. ex: "California"
     * @param currentCity - Current city of a citizen. ex:"Frenso"
     * @param currentZip - Current zip of a citizen. ex:"90011"
     * @param linkedin - Linkedin of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     * @param citizenAddress - External address trying to create a citizen. ex:"0xEdAf02F9917716a09ae6a03DF6a5912489239A59"
     * @param signature - Externally signed message for signer address verification
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
        address citizenAddress,
        bytes memory signature
    ) external onlyNewCitizenAddress(citizenAddress) {
        // this recreates the message that was signed on the client
        bytes32 messageHash = toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    firstName,
                    lastName,
                    country,
                    citizenship,
                    currentState,
                    currentCity,
                    currentZip,
                    linkedin,
                    citizenAddress
                )
            )
        );
        require(
            recoverSigner(messageHash, signature) == citizenAddress,
            "Signature error. Methods tampered with."
        );
        _internalRegisterUnverifiedCitizen(
            firstName,
            middleName,
            lastName,
            country,
            citizenship,
            currentState,
            currentCity,
            currentZip,
            linkedin,
            citizenAddress
        );
    }

    /**
     * @dev This is the private method that holds the logic and performs the operation of creating a new Citizen struct. It is invoked internally from the contract from `registerUnverifiedCitizen`.
     * @param firstName - First name of a citizen. ex: "John"
     * @param middleName - Middle name of a citizen. ex: "Disilva"
     * @param lastName - Last name of a citizen. ex: "Mayor"
     * @param country - Country of a citizen. ex: "United States of America" or "USA"
     * @param citizenship - A valid citizenship of a citizen. ex: "C-1234567"
     * @param currentState - Ccurrent state of a citizen. ex: "California"
     * @param currentCity - Current city of a citizen. ex:"Frenso"
     * @param currentZip - Current zip of a citizen. ex:"90011"
     * @param linkedin - Linkedin of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     * @param citizenAddress - External address trying to create a citizen. ex:"0xEdAf02F9917716a09ae6a03DF6a5912489239A59"
     */
    function _internalRegisterUnverifiedCitizen(
        string memory firstName,
        string memory middleName,
        string memory lastName,
        string memory country,
        string memory citizenship,
        string memory currentState,
        string memory currentCity,
        string memory currentZip,
        string memory linkedin,
        address citizenAddress
    ) private {
        string memory citizenID = concatValues(
            _CITIZEN_IDENTIFIER,
            _UNVERIFIED_CITIZEN_CONTRACT_VERSION,
            ++_lastCitizenIndex
        );
        Citizen storage citizen = _citizensUnverified[citizenID][
            ++_citizenLatestVersion[citizenID]
        ];
        citizen.citizenAddress = citizenAddress;
        citizen.citizenID = citizenID;
        citizen.firstName = firstName;
        citizen.middleName = middleName;
        citizen.lastName = lastName;
        citizen.country = country;
        citizen.citizenship = citizenship;
        citizen.currentState = currentState;
        citizen.currentCity = currentCity;
        citizen.currentZip = currentZip;
        citizen.linkedin = linkedin;
        citizen.version = _citizenLatestVersion[citizenID]; // solhint-disable-next-line not-rely-on-time
        citizen.citizenCreatedDate = block.timestamp;
        // Only push address in list if its new citizen record
        if (_citizenLatestVersion[citizenID] == 1)
            _citizenIndices.push(_lastCitizenIndex);

        _citizenAddressToIndex[citizenAddress] = _lastCitizenIndex;
    }

    /**
     * @dev Only a respective citizen can update his details. Updating means simply creating a newer version of the citizen detail.
     * Citizen's version are auto increment property in struct.
     * @param firstName - First name of a citizen. ex: "John"
     * @param middleName - Middle name of a citizen. ex: "Disilva"
     * @param lastName - Last name of a citizen. ex: "Mayor"
     * @param country - Country of a citizen. ex: "United States of America" or "USA"
     * @param citizenship - A valid citizenship of a citizen. ex: "C-1234567"
     * @param currentState - Ccurrent state of a citizen. ex: "California"
     * @param currentCity - Current city of a citizen. ex:"Frenso"
     * @param currentZip - Current zip of a citizen. ex:"90011"
     * @param linkedin - Linkedin of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     * @param citizenID - ID of a citizen. ex"ZTMCitizen:v1:1"
     * @param signature - Externally signed message for signer address verification
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
        address citizenAddress,
        bytes memory signature
    ) external {
        //First find the last version of citizen and check if citizen record belongs to citizen address can update it or not
        (
            uint256 lastVersionOfCitizen,
            bool isOwner
        ) = checkCitizenVersionAndPermission(citizenAddress, citizenID);
        require(isOwner, "Permission denied. Cannot update citizen.");
        require(lastVersionOfCitizen > 0, "Citizen doesn't exist.");

        // this recreates the message that was signed on the client
        bytes32 messageHash = toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    firstName,
                    lastName,
                    country,
                    citizenship,
                    currentState,
                    currentCity,
                    currentZip,
                    linkedin,
                    citizenAddress
                )
            )
        );
        require(
            recoverSigner(messageHash, signature) == citizenAddress,
            "Signature error. Methods tampered with."
        );
        _internalUpdateUnverifiedCitizen(
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
            citizenAddress,
            lastVersionOfCitizen
        );
    }

    /**
     * @dev This is the private method that holds the logic and performs the operation of creating a new Citizen struct with new version which is also a update mechanism.
      It is invoked internally from the contract from `updateUnverifiedCitizen`.
     * @param firstName - First name of a citizen. ex: "John"
     * @param middleName - Middle name of a citizen. ex: "Disilva"
     * @param lastName - Last name of a citizen. ex: "Mayor"
     * @param country - Country of a citizen. ex: "United States of America" or "USA"
     * @param citizenship - A valid citizenship of a citizen. ex: "C-1234567"
     * @param currentState - Ccurrent state of a citizen. ex: "California"
     * @param currentCity - Current city of a citizen. ex:"Frenso"
     * @param currentZip - Current zip of a citizen. ex:"90011"
     * @param linkedin - Linkedin of a citizen. ex:"https://www.linkedin.com/in/race-track-39a699200/"
     * @param citizenID - ID of a citizen. ex"ZTMCitizen:v1:1"
     * @param lastVersionOfCitizen last version of a citizen
     */
    function _internalUpdateUnverifiedCitizen(
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
        uint256 lastVersionOfCitizen
    ) private {
        _citizenLatestVersion[citizenID] = lastVersionOfCitizen + 1;
        Citizen storage citizen = _citizensUnverified[citizenID][
            _citizenLatestVersion[citizenID]
        ];
        citizen.citizenAddress = citizenAddress;
        citizen.citizenID = citizenID;
        citizen.firstName = firstName;
        citizen.middleName = middleName;
        citizen.lastName = lastName;
        citizen.country = country;
        citizen.citizenship = citizenship;
        citizen.currentState = currentState;
        citizen.currentCity = currentCity;
        citizen.currentZip = currentZip;
        citizen.linkedin = linkedin;
        citizen.version = _citizenLatestVersion[citizenID]; // solhint-disable-next-line not-rely-on-time
        citizen.citizenCreatedDate = block.timestamp;
    }

    /**
     * @dev Get the properties of Citizen struct based on citizenID. Every citizen are mapped with unique ID as `ZTMCitizen:v1:1`.
     * @notice If record is found in current contract simply return else look for the prior version if current version is "1" otherwise revert
     * @param citizenID - ID of a citizen
     * @return citizenAddress - Address of a citizen
     * @return firstName - First name of a citizen
     * @return middleName - Middle name of a citizen
     * @return lastName - Last name of a citizen
     * @return citizenship - Citizenship of a citizen
     * @return linkedin -Linkedin URL of a citizen
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
        //if citizen data exists && its "1" contract then return
        if (_citizenLatestVersion[citizenID] > 0 || initalVersionedContract()) {
            require(
                _citizenLatestVersion[citizenID] > 0,
                "Citizen doesn't exist."
            );
            Citizen memory citizen = _citizensUnverified[citizenID][
                _citizenLatestVersion[citizenID]
            ];
            return (
                citizen.citizenAddress,
                citizen.firstName,
                citizen.middleName,
                citizen.lastName,
                citizen.citizenship,
                citizen.linkedin
            );
        }
        //look for prior version if not found in "1"
        return _priorVersionedSC.getUnverifiedCitizen(citizenID);
    }

    /**
     * @dev Gets the remaining properties of Citizen's struct
     * Since all the properties can not be returned with same method this is another method that just returns the remaining properties of citizen struct.
     * @param citizenID - ID of a citizen whose properties is retured.
     * @return country - Country of a citizen.
     * @return currentState - Current state of a citizen.
     * @return currentCity - Current city of a citizen.
     * @return currentZip - Current zip of a citizen.
     * @return version - Latest version of citizen data.
     * @return createdAt - Timestamp when citizen record created.
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
        //if citizen data exists && it is "1" contract then find and return from "1"
        if (_citizenLatestVersion[citizenID] > 0 || initalVersionedContract()) {
            require(
                _citizenLatestVersion[citizenID] > 0,
                "Citizen doesn't exist."
            );
            Citizen memory citizen = _citizensUnverified[citizenID][
                _citizenLatestVersion[citizenID]
            ];

            return (
                citizen.country,
                citizen.currentState,
                citizen.currentCity,
                citizen.currentZip,
                citizen.version,
                citizen.citizenCreatedDate
            );
        }
        // Look for prior versioned contract if not found in current contract
        return _priorVersionedSC.getUnverifiedCitizenExtraData(citizenID);
    }

    /**
     * @dev Get the latest version of citizen record based on the citizenID
     * It will search an entire versions of ZTMCitizens so far.
     * @param citizenID - Address of a citizen.
     * @return citizenVersion - Lates version of a citizen record.
     */
    function getCitizenVersion(string memory citizenID)
        external
        view
        returns (uint256 citizenVersion)
    {
        uint256 version = _citizenLatestVersion[citizenID];
        //if "1" or citizen version found then simply return else look for prior version
        if (version > 0 || initalVersionedContract()) {
            return version;
        }
        return _priorVersionedSC.getCitizenVersion(citizenID);
    }

    /**
     * @dev Returns the citizen's indices. Returing a big size array takes time so cursor is implemented to return indices in a chunk.
     * Every citizen count is stored in array of integer. Over time array size could be big which will create a problem while returning and may take longer period of time to succeed.
     * Therefore, citizen indexes are retured in a chunk. Lets say if 1000 indices then this method can return 100 indices for the first time and next 100 for second time and so on.
     * @param cursor - Starting index of an array from where to return the value.
     * @param length - Length of an array from cursor upto which the values get returned.
     * @return Array of indices based on cursor and length
     */
    function getUnverifiedCitizenIndicesByCursor(uint256 cursor, uint256 length)
        external
        view
        returns (uint256[] memory)
    {
        if (length > _citizenIndices.length - cursor) {
            length = _citizenIndices.length - cursor;
        }
        uint256[] memory allIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            allIds[i] = _citizenIndices[cursor + i];
        }
        return allIds;
    }

    /**
     * @dev Based on citizen address which is the address used while registering a citizen; this method helps to find out the ID of the citizen record.
     * On the other hand, it will also return the version of a ZTMCitizens contract where  that record exists.
     * @param citizenAddress -Address of a citizen.
     * @return citizenID - ID of citizen.
     * @return citizenIndex - Index of a citizen record.
     * @return contractVersion - Version of ZTMCitizens contract where the citizen record exists.
     */
    function getUnverifiedCitizenAddressIndex(address citizenAddress)
        public
        view
        returns (
            string memory citizenID,
            uint256 citizenIndex,
            string memory contractVersion
        )
    {
        // return from current version if record found or if its "1"
        uint256 cindex = _citizenAddressToIndex[citizenAddress];
        if (cindex > 0 || initalVersionedContract()) {
            return (
                concatValues(
                    _CITIZEN_IDENTIFIER,
                    _UNVERIFIED_CITIZEN_CONTRACT_VERSION,
                    cindex
                ),
                cindex,
                _UNVERIFIED_CITIZEN_CONTRACT_VERSION
            );
        }
        // look for versioned contracts if current contract's version is the the inital version
        return
            _priorVersionedSC.getUnverifiedCitizenAddressIndex(citizenAddress);
    }

    /**
     * @dev Check if current version is initial version contract ie v1
     * @return true if version is "1" else false.
     */
    function initalVersionedContract() internal pure returns (bool) {
        return matchStrings(_UNVERIFIED_CITIZEN_CONTRACT_VERSION, "1");
    }

    /**
     * @dev Checks and returns the last version of citizen record and ownership of citizen address.
     * @param citizenAddress - Address of a citizen whose ownership is to be checked.
     * @param citizenID - ID of a citizen.
     * @return citizenVersion - Last version of a citizen.
     * @return isOwner true if citizen record belongs to citizenAddress.
     */
    function checkCitizenVersionAndPermission(
        address citizenAddress,
        string memory citizenID
    ) public view returns (uint256 citizenVersion, bool isOwner) {
        // if citizen found in this current version or if "1"
        if (_citizenLatestVersion[citizenID] > 0 || initalVersionedContract()) {
            return (
                _citizenLatestVersion[citizenID],
                hasPermission(citizenAddress, citizenID)
            );
        }
        return
            _priorVersionedSC.checkCitizenVersionAndPermission(
                citizenAddress,
                citizenID
            );
    }

    /**
     * @dev Check if citizen record belongs to citizen address. This is needed while updating the citizen record because nobody except the owner can update the detail.
     * @param citizenAddress - Address of a citizen.
     * @param citizenID - ID of a citizen.
     * @return  true if citizen record belongs to citizenAddress.
     */
    function hasPermission(address citizenAddress, string memory citizenID)
        internal
        view
        returns (bool)
    {
        return (_citizensUnverified[citizenID][_citizenLatestVersion[citizenID]]
            .citizenAddress == citizenAddress);
    }

    /**
     * @dev Check if citizen address already used in registration.
     * @param citizenAddress Address of a citizen.
     */
    modifier onlyNewCitizenAddress(address citizenAddress) {
        (, uint256 cindex, ) = getUnverifiedCitizenAddressIndex(citizenAddress);
        require(cindex == 0, "Citizen address already exists.");

        _;
    }
}