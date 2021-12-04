// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import { Base64 } from "base64-sol/base64.sol";
import { RxStructs } from "./libraries/RxStructs.sol";
import { TokenURIDescriptor } from "./libraries/TokenURIDescriptor.sol";

/// @title A NFT Prescription creator
/// @author Matias Parij (@7i7o)
/// @notice You can use this contract only as a MVP for minting Prescriptions
/// @dev Features such as workplaces for doctors or pharmacists are for future iterations
contract Rx is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {

    /// @notice Using OpenZeppelin's Counters for TokenId enumeration
    using Counters for Counters.Counter;

    /// @notice Role definition for Minter
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// @notice Role definition for Minter
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Role definition for Burner
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Using OpenZeppelin's Counters for TokenId enumeration
    /// @dev We increment the counter in the constructor to start Ids in 1, keeping Id 0 (default for
    ///      uints in solidity) to signal that someone doesn't have any NFTs
    Counters.Counter private _tokenIdCounter;

    /** Begin of State Variables & Modifiers for final project */

    bool private pausableRolePaused = false;

    uint256 constant MAX_KEY_LENGTH = 20;
    uint256 constant MAX_VALUE_LENGTH = 62;
    uint256 constant RX_LINES = 12; // Has to be same value as in RxStructs !!!

    /// @notice this mapping holds all the subjects registered in the contract
    mapping ( address => RxStructs.Subject ) private subjects;

    /// @notice this mapping holds all the doctors registered in the contract
    mapping ( address => RxStructs.Doctor ) private doctors;

    /// @notice this mapping holds all the pharmacists registered in the contract
    mapping ( address => RxStructs.Pharmacist ) private pharmacists;

    /// @notice this mapping holds all the prescriptions minted in the contract
    mapping (uint256 => RxStructs.RxData) private rxs;

    /// @dev Modifier that checks that an account is actually a registered subject
    modifier isSubject(address _subjectId) {
        require( (_subjectId != address(0) && subjects[_subjectId].subjectId == _subjectId) ,
                    'not a subject'
                );
        _;
    }

    /// @dev Modifier that checks that an account is a registered doctor
    modifier isDoctor(address _subjectId) {
        require( (_subjectId != address(0) && doctors[_subjectId].subjectId == _subjectId) ,
                    'not a doc'
                );
        _;
    }

    /// @dev Modifier that checks that an account is NOT a registered doctor
    modifier isNotDoctor(address _subjectId) {
        require( (doctors[_subjectId].subjectId == address(0)) ,
                    'is a Doctor'
                );
        _;
    }

    /// @dev Modifier that checks that an account is a registered pharmacist
    modifier isPharmacist(address _subjectId) {
        require( (_subjectId != address(0) && pharmacists[_subjectId].subjectId == _subjectId) ,
                    'not a pharm'
                );
        _;
    }

    /// @dev Modifier that checks that an account is NOT a registered pharmacist
    modifier isNotPharmacist(address _subjectId) {
        require( (pharmacists[_subjectId].subjectId == address(0)) ,
                    'is a pharm'
                );
        _;
    }

    /// @dev Function to allow accounts not registered as patient to have a pausable role
    function onlyPausableRole(bytes32 role) private view {
        if (!pausableRolePaused) {
            _checkRole(role, _msgSender());
        } else {
            // Not registered accounts act as pausable role
            require( subjects[_msgSender()].subjectId == address(0) || hasRole(role, _msgSender()), 'is a patient');
        }
        // _;
    }

    /// @notice Event to signal when a new Rx has been minted
    /// @param sender address of the Doctor that minted the Rx
    /// @param receiver address of the Subject that received the Rx minted
    /// @param tokenId Id of the Token (Rx) that has been minted
    event minted(address indexed sender, address indexed receiver, uint256 indexed tokenId);

    /// @notice Event to signal when adding/replacing a Subject allowed to receive/hold NFT Prescriptions
    /// @param sender is the address of the admin that set the Subject's data
    /// @param _subjectId is the registered address of the subject (approved for holding NFT Prescriptions)
    /// @param _birthDate is the subjects' date of birth, in seconds, from UNIX Epoch (1970-01-01)
    /// @param _name is the subject's full name
    /// @param _homeAddress is the subject's legal home address
    event subjectDataSet(address indexed sender, address indexed _subjectId, uint256 _birthDate, string _name, string _homeAddress);

    /// @notice Event to signal when adding/replacing a Doctor allowed to mint NFT Prescriptions
    /// @param sender is the address of the admin that set the Doctor's data
    /// @param _subjectId is the ethereum address for the doctor (same Id as the subject that holds this doctor's personal details)
    /// @param _degree contains a string with the degree of the doctor
    /// @param _license contains a string with the legal license of the doctor
    event doctorDataSet(address indexed sender, address indexed _subjectId, string _degree, string _license);
    
    /// @notice Event to signal when adding/replacing a Pharmacist allowed to burn NFT Prescriptions
    /// @param sender is the address of the admin that set the Pharmacist's data
    /// @param _subjectId is the ethereum address for the pahrmacist (same Id as the subject that holds this pharmacist's personal details)
    /// @param _degree contains a string with the degree of the pharmacist
    /// @param _license contains a string with the legal license of the pharmacist
    event pharmacistDataSet(address indexed sender, address indexed _subjectId, string _degree, string _license);

    /// @notice Event to signal a removed Subject
    /// @param sender is the address of the admin that removed the Subject
    /// @param _subjectId is the registered address of the subject removed
    event subjectRemoved(address indexed sender, address indexed _subjectId);

    /// @notice Event to signal a removed Doctor
    /// @param sender is the address of the admin that removed the Doctor
    /// @param _subjectId is the registered address of the doctor removed
    event doctorRemoved(address indexed sender, address indexed _subjectId);

    /// @notice Event to signal a removed Pharmacist
    /// @param sender is the address of the admin that removed the Pharmacist
    /// @param _subjectId is the registered address of the pharmacist removed
    event pharmacistRemoved(address indexed sender, address indexed _subjectId);

    /** End of State Variables & Modifiers for final project */

    /// @notice constructor for NFT Prescriptions contract
    /// @dev Using ERC721 default constructor with "Prescription" and "Rx" as Name and Symbol for the tokens
    /// @dev We set up the contract creator (msg.sender) with the ADMIN_ROLE to manage all the other Roles
    /// @dev We increment the counter in the constructor to start Ids in 1, keeping Id 0 (default for uints
    ///      in solidity) to signal that someone doesn't have any NFTs
    constructor() ERC721("Rx", "Rx") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);  // ADMIN role to manage all 3 roles
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);

        grantRole(ADMIN_ROLE, msg.sender);

        // _setupRole(MINTER_ROLE, msg.sender); // MINTER_ROLE reserved for Doctors only
        // _setupRole(BURNER_ROLE, msg.sender); // BURNER_ROLE reserved for Pharmacists only

        _tokenIdCounter.increment();
    }

    /// @dev function override required by solidity
    /// @notice function override to store burner data in the rx before burning
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyRole(BURNER_ROLE) {
        // delete rxs[tokenId]; // Keep Rx Data to be able to view past Rxs
        require(
            getApproved(tokenId) == msg.sender ||
            isApprovedForAll(ownerOf(tokenId), msg.sender),
            "pharm not approved");
        // We save the burner (pharmacist) data to the Rx
        rxs[tokenId].pharmacistSubject = getSubject(msg.sender);
        rxs[tokenId].pharmacist = getPharmacist(msg.sender);
        super._burn(tokenId);
        //TODO: Change prescription life cycle in 'Status' to keep prescription data without burning
    }

    /// @dev TokenURI generated on the fly from stored data (function override required by solidity)  
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return TokenURIDescriptor.constructTokenURI(tokenId, name(), symbol(), rxs[tokenId]);
    }

    /// @dev function override required by solidity
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /** Begin of implementation of functions for final project */

    /// @notice Function to verify string length and validate data input
    /// @param maxLength Maximum string length
    function _validateStrings(uint256 maxLength, string[RX_LINES] calldata stringArray) internal pure returns (bool) {
        for (uint256 i = 0; i < RX_LINES; i++) {
            if ( bytes(stringArray[i]).length >= maxLength) {
                return false;
            }
        }
        return true;
    }

    /// @notice Funtion to mint a Prescription. Should be called only by a Doctor (has MINTER_ROLE)
    /// @param to The id of the subject (patient) recipient of the prescription
    /// @param _keys Text lines with the 'title' of each content of the prescription (max 19 characters each)
    /// @param _values Text lines with the 'content' of the prescription (max 61 characters each)
    /// @dev Does NOT store a tokenURI. It stores Prescription data on contract (tokenURI is generated upon request)
    function mint(address to, string[RX_LINES] calldata _keys, string[RX_LINES] calldata _values)
        public
        onlyRole(MINTER_ROLE)
        isSubject(to) 
        {
            require( (msg.sender != to) , 'mint to yourself');
            require( _validateStrings( MAX_KEY_LENGTH, _keys ) , 'key 2 long' );
            require( _validateStrings( MAX_VALUE_LENGTH, _values ) , 'value 2 long' );

            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            super._safeMint(to, tokenId);

            // Store prescription data in contract, leaving tokenURI empty, for it is generated on request (Uniswap V3 style!)
            rxs[tokenId] = RxStructs.RxData(
                                block.timestamp,
                                getSubject(to),
                                getSubject(msg.sender),
                                RxStructs.Subject(address(0), 0, '', ''),
                                getDoctor(msg.sender),
                                RxStructs.Pharmacist(address(0), '', ''),
                                _keys,
                                _values);

            emit minted(msg.sender, to, tokenId);
    }

    /// @notice Function to get data for a specific tokenId. Only for Doctor, Patient or Pharmacist of the tokenId.
    /// @param tokenId uint256 representing an existing tokenId
    /// @return a RxData struct containing all the Rx Data
    function getRx(uint256 tokenId) public view returns (RxStructs.RxData memory) {
        return rxs[tokenId];
    }

    /// @notice Function to set pausableRolePaused (only deployer of contract is allowed)
    /// @param _paused bool to set state variable
    function setPausableRolePaused(bool _paused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        pausableRolePaused = _paused;
    }

    /// @notice Function to set pausableRolePaused (only deployer of contract is allowed)
    /// @return bool with state variable
    function getPausableRolePaused() public view returns (bool) {
        return pausableRolePaused;
    }

    /// @notice function override to prohibit token transfers
    function _transfer(address from, address to, uint256 tokenId ) internal view override(ERC721) {
        require(msg.sender == address(0), "rxs are untransferable");
    }

    /// @notice Function to add an admin account
    /// @param to Address of the account to grant admin role
    function addAdmin(address to) public   {
        // onlyPausableRole(ADMIN_ROLE);
        if (!pausableRolePaused) {
            grantRole(ADMIN_ROLE, to);
        } else {
            // if ( subjects[_msgSender()].subjectId == address(0) || hasRole(role, _msgSender())) {
            // We skip role manager checks for the final project presentation
            _grantRole(ADMIN_ROLE, to);
            // }
        }
    }

    /// @notice Function to remove an admin account
    /// @param to Address of the account to remove admin role
    function removeAdmin(address to) public onlyRole(ADMIN_ROLE) {
        // onlyPausableRole(ADMIN_ROLE);
        revokeRole(ADMIN_ROLE, to);
    }

    /// @notice Function to check if someone has admin role
    /// @param to address to check for admin role privilege
    /// @return true if @param to is an admin or false otherwise
    function isAdmin(address to) public view returns (bool) {
        return hasRole(ADMIN_ROLE, to); // || (pausableRolePaused && subjects[_msgSender()].subjectId == address(0));
    }

    /// @notice Function to retrieve a Subject
    /// @param _subjectId the registered address of the subject to retrieve
    /// @return an object with the Subject
    function getSubject(address _subjectId)
        public
        view
        returns (RxStructs.Subject memory) {
            return subjects[_subjectId];
    }

    /// @notice Function to retrieve a Doctor
    /// @param _subjectId the registered address of the doctor to retrieve
    /// @return an object with the Doctor
    function getDoctor(address _subjectId)
        public
        view
        returns (RxStructs.Doctor memory) {
            return doctors[_subjectId];
    }

    /// @notice Function to retrieve a Pharmacist
    /// @param _subjectId the registered address of the pharmacist to retrieve
    /// @return an object with the Pharmacist
    function getPharmacist(address _subjectId)
        public
        view
        returns (RxStructs.Pharmacist memory) {
            return pharmacists[_subjectId];
    }

    /// @notice Function to add/replace a Subject allowed to receive/hold NFT Prescriptions
    /// @param _subjectId is the registered address of the subject (approved for holding NFT Prescriptions)
    /// @param _birthDate is the subjects' date of birth, in seconds, from UNIX Epoch (1970-01-01)
    /// @param _name is the subject's full name
    /// @param _homeAddress is the subject's legal home address
    /// @return the ethereum address of the subject that was registered in the contract
    /// @dev Only ADMIN_ROLE users are allowed to modify subjects
    function setSubjectData(address _subjectId, uint256 _birthDate, string calldata _name, string calldata _homeAddress)
        public
        onlyRole(ADMIN_ROLE)
        returns (address) {
            // onlyPausableRole(ADMIN_ROLE);
            require (_subjectId != address(0), "0 address");
            // Subject memory newSubject = Subject(_subjectId, _name, _birthDate, _homeAddress);
            // subjects[_subjectId] = newSubject;
            subjects[_subjectId] = RxStructs.Subject(_subjectId, _birthDate, _name, _homeAddress);
            emit subjectDataSet(msg.sender, _subjectId, _birthDate, _name, _homeAddress);
            return subjects[_subjectId].subjectId;
    }

    /// @notice Function to add/replace a Doctor allowed to mint NFT Prescriptions
    /// @param _subjectId should be a valid ethereum address (same Id as the subject that holds this doctor's personal details)
    /// @param _degree should contain string with the degree of the doctor
    /// @param _license should contain string with the legal license of the doctor
    /// @dev @param _workplaces is a feature for future implementations
    /// @return the ethereum address of the doctor that was registered in the contract
    function setDoctorData(address _subjectId, string calldata _degree, string calldata _license) //, address[] calldata _workplaces)
        public
        onlyRole(ADMIN_ROLE)
        isSubject(_subjectId)
        returns (address) {
            // onlyPausableRole(ADMIN_ROLE);
            // require (_subjectId != address(0), "Wallet Address cannot be 0x0"); // Should be covered by isSubject()
            // Doctor memory newDoctor = Doctor(_subjectId, _degree, _license);
            // doctors[_subjectId] = newDoctor;
            // if (doctors[_subjectId].subjectId == address(0)) { // Doctor didn't exist, should be granted the MINTER_ROLE
            grantRole(MINTER_ROLE, _subjectId);
            // }
            doctors[_subjectId] = RxStructs.Doctor(_subjectId, _degree, _license);
            emit doctorDataSet(msg.sender, _subjectId, _degree, _license);
            return doctors[_subjectId].subjectId;
    }

    /// @notice Function to add/replace a Pharmacist allowed to burn NFT Prescriptions
    /// @param _subjectId should be a valid ethereum address (same Id as the subject that holds this pharmacist's personal details)
    /// @param _degree should contain string with the degree of the pharmacist
    /// @param _license should contain string with the legal license of the pharmacist
    /// @dev @param _workplaces is a feature for future implementations
    /// @return the ethereum address of the pharmacist that was registered in the contract
    function setPharmacistData(address _subjectId, string calldata _degree, string calldata _license) //, address[] calldata _workplaces)
        public
        onlyRole(ADMIN_ROLE)
        isSubject(_subjectId)
        returns (address) {
            // onlyPausableRole(ADMIN_ROLE);
            // require (_subjectId != address(0), "Wallet Address cannot be 0x0"); // Should be covered by isSubject()
            // Pharmacist memory newPharmacist = Pharmacist(_subjectId, _degree, _license);
            // pharmacists[_subjectId] = newPharmacist;
            // if (pharmacists[_subjectId].subjectId == address(0)) { // Pharmacist didn't exist, should be granted BURNER_ROLE
            grantRole(BURNER_ROLE, _subjectId);
            // }
            pharmacists[_subjectId] = RxStructs.Pharmacist(_subjectId, _degree, _license);
            emit pharmacistDataSet(msg.sender, _subjectId, _degree, _license);
            return pharmacists[_subjectId].subjectId;
    }

    /// @notice Function to remove a registered Subject 
    /// @param _subjectId is the registered address of the subject to remove
    /// @dev Only ADMIN_ROLE users are allowed to remove subjects
    function removeSubject(address _subjectId)
        public
        onlyRole(ADMIN_ROLE)
        isSubject(_subjectId)
        isNotDoctor(_subjectId)
        isNotPharmacist(_subjectId) {
            // onlyPausableRole(ADMIN_ROLE);// require (_subjectId != address(0), "Wallet Address cannot be 0x0"); // Should be covered by isSubject()
            delete subjects[_subjectId];
            emit subjectRemoved(msg.sender, _subjectId);
    }

    /// @notice Function to remove a registered Doctor
    /// @param _subjectId is the registered address of the doctor to remove
    /// @dev Only ADMIN_ROLE users are allowed to remove doctors
    function removeDoctor(address _subjectId)
        public
        onlyRole(ADMIN_ROLE)
        isDoctor(_subjectId) {
            // onlyPausableRole(ADMIN_ROLE);
            // require (_subjectId != address(0), "Wallet Address cannot be 0x0"); // Should be covered by isDoctor()
            revokeRole(MINTER_ROLE, _subjectId);
            delete doctors[_subjectId];
            emit doctorRemoved(msg.sender, _subjectId);
    }

    /// @notice Function to remove a registered Pharmacist
    /// @param _subjectId is the registered address of the pharmacist to remove
    /// @dev Only ADMIN_ROLE users are allowed to remove pharmacists
    function removePharmacist(address _subjectId)
        public
        onlyRole(ADMIN_ROLE)
        isPharmacist(_subjectId) {
            
            // require (_subjectId != address(0), "Wallet Address cannot be 0x0"); // Should be covered by isPharmacist()
            revokeRole(BURNER_ROLE, _subjectId);
            delete pharmacists[_subjectId];
            emit pharmacistRemoved(msg.sender, _subjectId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/utils/Strings.sol';
import { Base64 } from "base64-sol/base64.sol";
import { DateTime } from "./DateTime.sol";
import { RxStructs } from "./RxStructs.sol";
import { NFTSVG } from "./NFTSVG.sol";

library TokenURIDescriptor {

    /// @notice Function to generate a Base64 encoded JSON, that includes a SVG to be used as the token URI
    /// @param tokenId The tokenId of the NFT
    /// @param name The name() of the ERC721
    /// @param rx A Prescription Object containing all that we need to create the SVG
    /// @return A string with the Base64 encoded JSON containing the tokenURI
    function constructTokenURI(uint256 tokenId, string memory name, string memory symbol, RxStructs.RxData memory rx)
    internal
    pure
    returns (string memory) {

            string memory stringDate = DateTime.timestampToString(rx.date);
            string memory stringBirthdate = DateTime.timestampToString(rx.patient.birthDate);

            // json strings with a Base64 encoded image (SVG) inside
            string[24] memory jsonParts;
            jsonParts[0]  = '{"name":"';
            jsonParts[1]  =     name;
            jsonParts[2]  =     ' #';
            jsonParts[3]  =     Strings.toString(tokenId);
            jsonParts[4]  = '","symbol":"';
            jsonParts[5]  =     symbol;
            jsonParts[6]  = '","description":"On-Chain NFT Prescriptions"';
            jsonParts[7]  = ',"attributes":['
                                '{"trait_type":"PatientName","value":"';
            jsonParts[8]  =          rx.patient.name;
            jsonParts[9]  =     '"},{"trait_type":"Patient Birthdate","value":"';
            jsonParts[10] =         stringBirthdate;
            jsonParts[11] =     '"},{"trait_type":"Doctor Name","value":"';
            jsonParts[12] =         rx.doctorSubject.name;
            jsonParts[13] =     '"},{"trait_type":"Doctor Degree","value":"';
            jsonParts[14] =         rx.doctor.degree;
            jsonParts[16] =     '"},{"trait_type":"Doctor License","value":"';
            jsonParts[17] =         rx.doctor.license;
            jsonParts[18] =     '"},{"trait_type":"RX Date","value":"';
            jsonParts[19] =         stringDate;
            jsonParts[20] =     '"}]';
            jsonParts[21] = ',"image": "data:image/svg+xml;base64,';
            jsonParts[22] =     Base64.encode(bytes(
                                    NFTSVG.generateSVG(tokenId, name, rx)
                                ));
            jsonParts[23] = '"}';

            string memory output = string(abi.encodePacked(jsonParts[0], jsonParts[1], jsonParts[2], jsonParts[3], jsonParts[4], jsonParts[5], jsonParts[6], jsonParts[7], jsonParts[8]));
            output = string(abi.encodePacked(output, jsonParts[9], jsonParts[10], jsonParts[11], jsonParts[12], jsonParts[13], jsonParts[14], jsonParts[15], jsonParts[16]));
            output = string(abi.encodePacked(output, jsonParts[17], jsonParts[18], jsonParts[19], jsonParts[20], jsonParts[21], jsonParts[22], jsonParts[23]));

            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(output))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library RxStructs {

    uint256 constant MAX_KEY_LENGTH = 20;
    uint256 constant MAX_VALUE_LENGTH = 62;
    uint256 constant RX_LINES = 12;
    uint256 constant LINE_PADDING = 30;
    
    /// @notice enum to reflect diferent states of the Prescription
    /// @param Draft reflects a Prescription that is not minted yet
    /// @param Minted reflects a freshly minted Prescription, not yet ready to be used by a patient in a Pharmacy
    /// @param Prescribed reflects a Prescription in the posession of the patient, not yet exhanged/used in a Pharmacy
    /// @param Used reflects a Prescription in the posession of a Pharmacist, already used by a patient (it could still need to be inspected/payed by a health insurance)
    /// @param Burned reflects a Prescription that has been Burned by the Pharmacist, because it has already been payed/accounted for
    //TODO: enum Status { Draft, Minted, Prescribed, Used, Burned }

    /// @notice struct to store a suject (person/patient) details
    /// @param ethAddress should be a valid ethereum address (used as an Id for the subject)
    /// @param name should contain string with the full name of the subject
    /// @param birthDate should contain string with the date of birth of the subject
    /// @param homeAddress should contain string with the home address of the subject
    struct Subject {
        address subjectId;
        uint256 birthDate;
        string name;
        string homeAddress;
    }

    /// @notice struct to store a doctor (minter) details
    /// @param subject should be a valid ethereum address (same Id as the subject that holds this doctor's personal details)
    /// @param degree should contain string with the degree of the doctor
    /// @param license should contain string with the legal license of the doctor
    /// @dev @param workplaces is a feature for future implementations
    struct Doctor {
        address subjectId;
        string degree;
        string license;
        // TODO: address[] workplaces;
    }

    /// @notice struct to store a pharmacist (burner) details
    /// @param subject should be a valid ethereum address (same Id as the subject that holds this pharmacist's personal details)
    /// @param degree should contain string with the degree of the pharmacist
    /// @param license should contain string with the legal license of the pharmacist
    /// @dev @param workplaces is a feature for future implementations
    struct Pharmacist {
        address subjectId;
        string degree;
        string license;
        // TODO: address[] workplaces;
    }

    /// @notice struct representing the prescription
    /// @dev @param status Represents the status of the prescription (Minted, Prescribed, Used, Burned)
    /// @param date Date of the prescription (rounded to a timestamp of a block)
    /// @param patient Subject with the data of the patient
    /// @param doctorSubject Subject with the data of the doctor
    /// @param pharmacistSubject Subject with the data of the pharmacist
    /// @param doctor Doctor with the data of the doctor
    /// @param pharmacist Pharmacist with the data of the pharmacist
    /// @param keys String array with the title of each written line of the prescription
    /// @param values String array with values of each written line of the prescription
    struct RxData {
        //TODO: Status status;
        uint256 date;
        Subject patient;
        Subject doctorSubject;
        Subject pharmacistSubject;
        Doctor doctor;
        Pharmacist pharmacist;
        string[RX_LINES] keys;
        string[RX_LINES] values;
        // address pharmacistSubjectId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/utils/Strings.sol';
import { DateTime } from "./DateTime.sol";
import { RxStructs } from "./RxStructs.sol";

/// @title Library to generate SVG for the NFT
/// @author Matias Parij (@7i7o)
/// @notice Used by main Rx contract to generate tokenURI image
library NFTSVG {

    /// @notice Function that generates a SVG to be included in the tokenURI
    /// @param tokenId The tokenId of the NFT
    /// @param name The name() of the ERC721
    /// @param rx A Prescription Object containing all that we need to create the SVG
    function generateSVG(uint256 tokenId, string memory name, RxStructs.RxData memory rx)
        internal
        pure
        returns (string memory svg) {

            string memory stringDate = DateTime.timestampToString(rx.date);
            string memory stringBirthdate = DateTime.timestampToString(rx.patient.birthDate);
            
            string[30] memory parts;  // Should have 30: 1 header + 12 keys + 1 font separator + 1 Patient values + 1 date value + 1 Doctor values + 12 values + 1 Footer

            // SVG Header
            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" font-family="sans-serif" font-size="12px" ' 
                            'preserveAspectRatio="xMinYMin meet" viewBox="0 0 600 800" style="background:white">'
                            '<g fill="none" stroke="#000" stroke-width="1px">'
                                '<rect x="2" y="2" width="596" height="796"/>' // Frame
                                '<path d="m15 135h570"/>' // Top line
                                '<path d="m15 630h570"/>' // Bottom line
                            '</g>'
                            '<g font-size="88px"><text x="10" y="215">P</text><text x="35" y="250">X</text></g>' // RX
                            '<g text-anchor="end">' // Titles group (keys)
                                '<text x="118" y="30">Name</text>'
                                '<text x="118" y="60">Date of Birth</text>'
                                '<text x="118" y="90">Address</text>'
                                '<text x="118" y="120">Patient Wallet</text>'
                                '<text x="118" y="660">Date</text>'
                                '<text x="118" y="690">Doctor Name</text>'
                                '<text x="118" y="720">MD</text>'
                                '<text x="118" y="750">License</text>'
                                '<text x="118" y="780">Doctor Wallet</text>';

            // uint256 l = 0; // text length
            uint256 y = 280; // Y Position
            string memory text = ''; // text

            // Generate all the 'keys' text lines in the SVG
            for (uint256 i = 0; i < RxStructs.RX_LINES; i++) {
                text = rx.keys[i];
                if ( bytes(text).length > 0 ){
                    parts[i+1] = string(abi.encodePacked('<text x="118" y="',Strings.toString(y),'">',text,'</text>'));
                }
                y += RxStructs.LINE_PADDING;
            }

            // SVG 'change font' separator
            parts[13] = '</g><g font-family="Courier" font-weight="bold">';

            // Generate all the patient SVG lines
            parts[14] = string(abi.encodePacked(
                '<text x="128" y="30">',rx.patient.name,'</text>',
                '<text x="128" y="60">',stringBirthdate,'</text>',
                '<text x="128" y="90">',rx.patient.homeAddress,'</text>',
                '<text x="128" y="120">',Strings.toHexString(uint256(uint160(rx.patient.subjectId)), 20),'</text>'
            ));

            // Generate the date and Rx# SVG line
            parts[15] = string(abi.encodePacked(
                '<text x="128" y="660">',
                    stringDate,
                '</text>'
                '<text x="585" y="660" text-anchor="end" font-style="italic">'
                    ,name,'# ',Strings.toString(tokenId),
                '</text>'
            ));

            // Generate all the doctor SVG lines
            parts[16] = string(abi.encodePacked(
                '<text x="128" y="690">',rx.doctorSubject.name,'</text>',
                '<text x="128" y="720">',rx.doctor.degree,'</text>',
                '<text x="128" y="750">',rx.doctor.license,'</text>',
                '<text x="128" y="780">',Strings.toHexString(uint256(uint160(rx.doctor.subjectId)), 20),'</text>'
            ));

            y = 280;
            // Generate all the 'values' text lines in the SVG
            for (uint256 i = 0; i < RxStructs.RX_LINES; i++) {
                text = rx.values[i];
                if ( bytes(text).length > 0 ){
                    parts[i+17] = string(abi.encodePacked('<text x="128" y="',Strings.toString(y),'">',text,'</text>'));
                }
                y += RxStructs.LINE_PADDING;
            }
    
            parts[29] = '</g>'
                        // Small logo at the bottom that can be commented out
                        '<g opacity="0.6"><circle fill="darkblue" cx="566" cy="754.4" r="7.5"/><path fill="red" d="m580.4 761h4l-15,24h-4z"/><path fill="darkred" d="m565.4 761h4l15,24h-4z"/><path fill="blue" d="m558 749v24h15z"/></g>'
                        '</svg>';

            string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
            output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15]));
            output = string(abi.encodePacked(output, parts[16], parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23]));
            output = string(abi.encodePacked(output, parts[24], parts[25], parts[26], parts[27], parts[28], parts[29]));

            return output;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9; // Modified for and updated pragma solidity declaration
// pragma solidity ^0.4.16;

import '@openzeppelin/contracts/utils/Strings.sol';


/// @notice Date and Time utilities for ethereum contracts
/// @author Piper Merriam https://github.com/pipermerriam
library DateTime {

        struct DateTimeStruct {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        string constant DATE_SEPARATOR = '-';

        /// @notice Function that returns a string (YYYY-MM-DD) from a timestamp
        /// @param dt uint256 timestamp (commonly block.timestamp)
        function timestampToString(uint256 dt) public pure returns (string memory) {
                return timestampToString(dt, DATE_SEPARATOR);
        }


        /// @notice Function that returns a string (YYYY-MM-DD) from a timestamp
        /// @param dt uint256 timestamp (commonly block.timestamp)
        /// @param separator string with the separator
        function timestampToString(uint256 dt, string memory separator) public pure returns (string memory) {
                DateTimeStruct memory date = parseTimestamp(dt);
                return string(abi.encodePacked(
                Strings.toString(date.year),
                separator,
                Strings.toString(date.month),
                separator,
                Strings.toString(date.day)
                ));
        }

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        // function parseTimestamp(uint timestamp) internal pure returns (DateTimeStruct dt) {
        function parseTimestamp(uint timestamp) public pure returns (DateTimeStruct memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}