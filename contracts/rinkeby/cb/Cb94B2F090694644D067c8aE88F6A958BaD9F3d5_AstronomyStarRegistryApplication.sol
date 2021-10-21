/*
MIT License

Copyright (c) 2021 Joshua Iván Mendieta Zurita

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

import "./Address.sol";
import "./Verifier.sol";

interface iAstronomyStarRegistryData {
      function registerUser(address userAddress) external;
      function isUserRegistered(address userAddress) external view returns (bool _state);
      
      function getTotalStarsDiscovered(address userAddress) external view returns (uint256 _total);
      function getRegisteredStarId(address userAddress, uint256 id) external view returns (uint256 _total);

      function registerStar(bytes32 hashPartA, bytes32 hashPartB, bytes32 name, bytes32 coordinates, address userAddress) external;
      function isStarNameRegistered(bytes32 name) external view returns (bool _state);
      function isStarCoordinatesRegistered(bytes32 coordinates) external view returns (bool _state);

      function modifyStarName(bytes32 hashPartA, bytes32 hashPartB, bytes32 name, bytes32 newName) external;
      function modifyStarCoordinates(bytes32 hashPartA, bytes32 hashPartB, bytes32 name, bytes32 coordinates) external;

      function getStarFromId(uint256 id) external view returns (bytes32 _partA, bytes32 _partB);
      function getStarFromName(bytes32 name) external view returns (bytes32 _partA, bytes32 _partB);
      function getStarFromCoordinates(bytes32 coordinates) external view returns (bytes32 _partA, bytes32 _partB);

      function getTotalRegisteredStars() external view returns (uint256 _total);
}

interface iIpfsHashHandler {
      function ipfsHashToBytes32(string memory source) external pure returns (bytes32 partA, bytes32 partB);
      function bytes32ToIpfsHash(bytes32 partA, bytes32 partB) external pure returns (string memory);
}

interface iDeclinationRegex {
      function matches(string memory input) external pure returns (bool);
}

interface iRightAscensionRegex {
      function matches(string memory input) external pure returns (bool);
}

/**
* @title An astronomy registry for stars
* @author Joshua Iván Mendieta Zurita
* @notice Only use this contract for storing the most basic information of stars
* @dev Not implemented verification of registered star coordinates within a degree of failure
* @custom:experimental This is an experimental contract
*/
contract AstronomyStarRegistryApplication is Verifier {
      using Address for address;
/****************************************
DATA CONTRACT OPERATIONAL CONTROL SECTION
****************************************/
      iAstronomyStarRegistryData AstronomyStarRegistryData;
      iIpfsHashHandler IpfsHashHandler;
      iDeclinationRegex DeclinationRegex;
      iRightAscensionRegex RightAscensionRegex;

      address private _deployer;
      address private _dataAddress;
      address private _ipfsHashHandlerAddress;
      address private _declinationRegexAddress;
      address private _rightAscensionRegexAddress;
      bool private _isOperational;

      /// @dev Stores the msg.sender address into the _deployer variable and set _isOperational variable as true
      constructor() {
            _deployer = msg.sender;
            _isOperational = true;
      }

      /// @dev Verifies that the caller is the _deployer
      modifier requireDeployer() {
            require(msg.sender == _deployer, "Only deployer can perform this action");
            _;
      }

      /// @dev Verifies that the passed address corresponds to a contract address
      modifier requireContract(address data) {
            require(Address.isContract(data) == true, "The given address must be from a contract");
            _;
      }

      /// @dev Verifies that the passed address doesn't corresponds to this contract address
      modifier requireNotCurrentContract(address data) {
            require(data != address(this), "The given contract address can not be the current contract");
            _;
      }

      /// @dev Emit an event with the data contract address
      event DATA_ADDRESS_SET(address data);

      /// @dev Stores the data address into the _dataAddress variable. The function is only callable by _deployer
      function setData(address data) external
      requireDeployer
      requireContract(data)
      requireNotCurrentContract(data) {
            _dataAddress = data;
            AstronomyStarRegistryData = iAstronomyStarRegistryData(data);
            emit DATA_ADDRESS_SET(data);
      }

      /// @dev Returns the _dataAddress variable value. The function is only callable by _deployer
      function getData() external view
      requireDeployer
      returns (address _data) {
            return _dataAddress;
      }

      /// @dev Stores the ipfsHashHandler address into the _ipfsHashHandlerAddress variable. The function is only callable by the _deployer
      function setIpfsHashHandler(address handler) external
      requireDeployer
      requireContract(handler)
      requireNotCurrentContract(handler) {
            _ipfsHashHandlerAddress = handler;
            IpfsHashHandler = iIpfsHashHandler(handler);
      }

      /// @dev Returns the _ipfsHashHandlerAddress variable value. The function is only callable by _deployer
      function getHandler() external view
      requireDeployer
      returns (address _handler) {
            return _ipfsHashHandlerAddress;
      }

      /// @dev Stores the declinationRegex address into the _declinationRegexAddress variable. The function is only callable by the _deployer
      function setDeclinationRegex(address declination) external
      requireDeployer
      requireContract(declination)
      requireNotCurrentContract(declination) {
            _declinationRegexAddress = declination;
            DeclinationRegex = iDeclinationRegex(declination);
      }

      /// @dev Returns the _declinationRegexAddress variable. The function is only callable by _deployer
      function getDeclination() external view
      requireDeployer
      returns (address _declination) {
            return _declinationRegexAddress;
      }

      /// @dev Stores the rightAscensionRegex address into the _rightAscensionRegexAddress variable. The function is only callable by the _deployer
      function setRightAscensionRegex(address rightAscension) external
      requireDeployer
      requireContract(rightAscension)
      requireNotCurrentContract(rightAscension) {
            _rightAscensionRegexAddress = rightAscension;
            RightAscensionRegex = iRightAscensionRegex(rightAscension);
      }

      /// @dev Returns the _rightAscensionRegexAddress variable. The function is only callable by _deployer
      function getRightAscension() external view
      requireDeployer
      returns (address _rightAscension) {
            return _rightAscensionRegexAddress;
      }

      /// @dev Emit an evnt with the _isOperational variable state
      event APPLICATION_OPERATIONAL_SET(bool status);

      /// @dev Sets the _isOperational variable's state with the value of the passed status
      function setOperational(bool status) external 
      requireDeployer {
            _isOperational = status;
            emit APPLICATION_OPERATIONAL_SET(status);
      }

      /// @dev Verifies that the contract variable _isOperational is true
      modifier requireOperational() {
            require(_isOperational == true, "Data contract is not operational");
            _;
      }

      /// @dev Returns the _isOperational variable's value. The function is only callable by _deployer
      function getOperational() external view
      requireDeployer
      returns (bool _status) {
            return _isOperational;
      }
/*****************************
INTERACTION WITH DATA CONTRACT
******************************/
      /// @dev Function that interacts with the data contract to register an user
      function registerUser() external
      requireOperational {
            AstronomyStarRegistryData.registerUser(msg.sender);
      }

      modifier requireRegisteredUser() {
            require(AstronomyStarRegistryData.isUserRegistered(msg.sender) == true, 'User is not registered');
            _;
      }

      /// @dev Function that interacts with the data contract to get the total stars discovered
      function getTotalStarsDiscovered() external view 
      requireOperational
      requireRegisteredUser
      returns (uint256 _total) {
            return AstronomyStarRegistryData.getTotalStarsDiscovered(msg.sender);
      }

      /// @dev Function that interacts with the data contract to get a star by passing a discovered id
      function getStarByDiscoveredId(uint256 id) external view
      requireOperational
      requireRegisteredUser
      returns (string memory star) {
            uint256 registeredId = AstronomyStarRegistryData.getRegisteredStarId(msg.sender, id);
            (bytes32 partA, bytes32 partB) = AstronomyStarRegistryData.getStarFromId(registeredId);
            return IpfsHashHandler.bytes32ToIpfsHash(partA, partB);
      }

      modifier requireRegexRules(string memory rightAscension, string memory declination) {
            require(RightAscensionRegex.matches(rightAscension) == true, 'Incorrect format for right ascension coordinate');
            require(DeclinationRegex.matches(declination) == true, 'Incorrect format for declination coordinate');
            _;
      }

      modifier requireFrontEnd( Proof memory proof, uint[1] memory input ) {
            require(verifyTx(proof, input) == true, "Require Front-End");
            _;
      }

      /// @dev Function that interacts with the data contract to register a star
      function registerStar(
            string memory starName, 
            string memory rightAscension, 
            string memory declination, 
            string memory ipfsHash,
            Proof memory proof,
            uint[1] memory input
      ) external
      requireOperational
      requireFrontEnd(proof, input)
      requireRegisteredUser
      requireRegexRules(rightAscension, declination) {
            (bytes32 partA, bytes32 partB) = IpfsHashHandler.ipfsHashToBytes32(ipfsHash);
            bytes32 name = keccak256(abi.encode(starName));
            bytes32 coordinates = keccak256(abi.encodePacked(rightAscension, declination));
            AstronomyStarRegistryData.registerStar(partA, partB, name, coordinates, msg.sender);
      }

      /// @dev Function that interacts with the data contract to modify a star name
      function modifyStarName(
            string memory name,
            string memory newName,
            string memory ipfsHash,
            Proof memory proof,
            uint[1] memory input
      ) external
      requireOperational
      requireFrontEnd(proof, input)
      requireRegisteredUser {
            bytes32 starName = keccak256(abi.encode(name));
            bytes32 newStarName = keccak256(abi.encode(newName));
            (bytes32 hashPartA, bytes32 hashPartB) = IpfsHashHandler.ipfsHashToBytes32(ipfsHash);
            AstronomyStarRegistryData.modifyStarName(hashPartA, hashPartB, starName, newStarName);
      }

      /// @dev Function that interacts with the data contract to modify a star coordinates
      function modifyStarCoordinates(
            string memory name, 
            string memory rightAscension, 
            string memory declination, 
            string memory ipfsHash,
            Proof memory proof,
            uint[1] memory input
      ) external
      requireOperational
      requireFrontEnd(proof, input)
      requireRegisteredUser
      requireRegexRules(rightAscension, declination) {
            bytes32 starName = keccak256(abi.encode(name));
            bytes32 coordinates = keccak256(abi.encodePacked(rightAscension, declination));
            (bytes32 hashPartA, bytes32 hashPartB) = IpfsHashHandler.ipfsHashToBytes32(ipfsHash);
            AstronomyStarRegistryData.modifyStarCoordinates(hashPartA, hashPartB, starName, coordinates);
      }

      /// @dev Function that interacts with the data contract to check if a star name is already registered
      function isStarNameRegistered(string memory starName) external view
      requireOperational
      requireRegisteredUser
      returns (bool _state) {
            bytes32 name = keccak256(abi.encode(starName));
            return AstronomyStarRegistryData.isStarNameRegistered(name);
      }

      /// @dev Function that interacts with the data contract to check if a star coordinate is already registered
      function isStarCoordinatesRegistered(string memory rightAscension, string memory declination) external view
      requireOperational
      requireRegisteredUser
      requireRegexRules(rightAscension, declination)
      returns (bool _state) {
            bytes32 coordinates = keccak256(abi.encodePacked(rightAscension, declination));
            return AstronomyStarRegistryData.isStarCoordinatesRegistered(coordinates);
      }

      /// @dev Function that interacts with the data contract to get a star by id
      function getStarFromId(uint256 id) external view
      requireOperational
      returns (string memory star) {
            (bytes32 partA, bytes32 partB) = AstronomyStarRegistryData.getStarFromId(id);
            return IpfsHashHandler.bytes32ToIpfsHash(partA, partB);
      }

      /// @dev Function that interacts with the data contract to get a star by name
      function getStarFromName(string memory starName) external view
      requireOperational
      returns (string memory star) {
            bytes32 name = keccak256(abi.encode(starName));
            (bytes32 partA, bytes32 partB) = AstronomyStarRegistryData.getStarFromName(name);
            return IpfsHashHandler.bytes32ToIpfsHash(partA, partB);
      }

      /// @dev Function that interacts with the data contract to get a star by coordinates
      function getStarFromCoordinates(string memory rightAscension, string memory declination) external view
      requireOperational
      requireRegexRules(rightAscension, declination)
      returns (string memory star) {
            bytes32 coordinates = keccak256(abi.encodePacked(rightAscension, declination));
            (bytes32 partA, bytes32 partB) = AstronomyStarRegistryData.getStarFromCoordinates(coordinates);
            return IpfsHashHandler.bytes32ToIpfsHash(partA, partB);
      }

      /// @dev Function that interacts with the data contract to get the total number of registered stars
      function getTotalRegisteredStars() external view 
      requireOperational
      returns (uint256 _total) {
            return AstronomyStarRegistryData.getTotalRegisteredStars();
      }
}