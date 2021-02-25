/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

/**

  Source code of Opium Protocol
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// File: contracts/Errors/RegistryErrors.sol

pragma solidity 0.5.16;

contract RegistryErrors {
    string constant internal ERROR_REGISTRY_ONLY_INITIALIZER = "REGISTRY:ONLY_INITIALIZER";
    string constant internal ERROR_REGISTRY_ONLY_OPIUM_ADDRESS_ALLOWED = "REGISTRY:ONLY_OPIUM_ADDRESS_ALLOWED";
    
    string constant internal ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS = "REGISTRY:CANT_BE_ZERO_ADDRESS";

    string constant internal ERROR_REGISTRY_ALREADY_SET = "REGISTRY:ALREADY_SET";
}

// File: contracts/Registry.sol

pragma solidity 0.5.16;


/// @title Opium.Registry contract keeps addresses of deployed Opium contracts set to allow them route and communicate to each other
contract Registry is RegistryErrors {

    // Address of Opium.TokenMinter contract
    address private minter;

    // Address of Opium.Core contract
    address private core;

    // Address of Opium.OracleAggregator contract
    address private oracleAggregator;

    // Address of Opium.SyntheticAggregator contract
    address private syntheticAggregator;

    // Address of Opium.TokenSpender contract
    address private tokenSpender;

    // Address of Opium commission receiver
    address private opiumAddress;

    // Address of Opium contract set deployer
    address public initializer;

    /// @notice This modifier restricts access to functions, which could be called only by initializer
    modifier onlyInitializer() {
        require(msg.sender == initializer, ERROR_REGISTRY_ONLY_INITIALIZER);
        _;
    }

    /// @notice Sets initializer
    constructor() public {
        initializer = msg.sender;
    }

    // SETTERS

    /// @notice Sets Opium.TokenMinter, Opium.Core, Opium.OracleAggregator, Opium.SyntheticAggregator, Opium.TokenSpender, Opium commission receiver addresses and allows to do it only once
    /// @param _minter address Address of Opium.TokenMinter
    /// @param _core address Address of Opium.Core
    /// @param _oracleAggregator address Address of Opium.OracleAggregator
    /// @param _syntheticAggregator address Address of Opium.SyntheticAggregator
    /// @param _tokenSpender address Address of Opium.TokenSpender
    /// @param _opiumAddress address Address of Opium commission receiver
    function init(
        address _minter,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender,
        address _opiumAddress
    ) external onlyInitializer {
        require(
            minter == address(0) &&
            core == address(0) &&
            oracleAggregator == address(0) &&
            syntheticAggregator == address(0) &&
            tokenSpender == address(0) &&
            opiumAddress == address(0),
            ERROR_REGISTRY_ALREADY_SET
        );

        require(
            _minter != address(0) &&
            _core != address(0) &&
            _oracleAggregator != address(0) &&
            _syntheticAggregator != address(0) &&
            _tokenSpender != address(0) &&
            _opiumAddress != address(0),
            ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS
        );

        minter = _minter;
        core = _core;
        oracleAggregator = _oracleAggregator;
        syntheticAggregator = _syntheticAggregator;
        tokenSpender = _tokenSpender;
        opiumAddress = _opiumAddress;
    }

    /// @notice Allows opium commission receiver address to change itself
    /// @param _opiumAddress address New opium commission receiver address
    function changeOpiumAddress(address _opiumAddress) external {
        require(opiumAddress == msg.sender, ERROR_REGISTRY_ONLY_OPIUM_ADDRESS_ALLOWED);
        require(_opiumAddress != address(0), ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS);
        opiumAddress = _opiumAddress;
    }

    // GETTERS

    /// @notice Returns address of Opium.TokenMinter
    /// @param result address Address of Opium.TokenMinter
    function getMinter() external view returns (address result) {
        return minter;
    }

    /// @notice Returns address of Opium.Core
    /// @param result address Address of Opium.Core
    function getCore() external view returns (address result) {
        return core;
    }

    /// @notice Returns address of Opium.OracleAggregator
    /// @param result address Address of Opium.OracleAggregator
    function getOracleAggregator() external view returns (address result) {
        return oracleAggregator;
    }

    /// @notice Returns address of Opium.SyntheticAggregator
    /// @param result address Address of Opium.SyntheticAggregator
    function getSyntheticAggregator() external view returns (address result) {
        return syntheticAggregator;
    }

    /// @notice Returns address of Opium.TokenSpender
    /// @param result address Address of Opium.TokenSpender
    function getTokenSpender() external view returns (address result) {
        return tokenSpender;
    }

    /// @notice Returns address of Opium commission receiver
    /// @param result address Address of Opium commission receiver
    function getOpiumAddress() external view returns (address result) {
        return opiumAddress;
    }
}