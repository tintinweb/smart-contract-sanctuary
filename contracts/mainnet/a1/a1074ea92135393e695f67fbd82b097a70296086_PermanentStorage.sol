// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "./IPermanentStorage.sol";
import "./PSStorage.sol";

contract PermanentStorage is IPermanentStorage {

    // Constants do not have storage slot.
    bytes32 public constant curveTokenIndexStorageId = 0xf4c750cdce673f6c35898d215e519b86e3846b1f0532fb48b84fe9d80f6de2fc; // keccak256("curveTokenIndex")
    bytes32 public constant transactionSeenStorageId = 0x695d523b8578c6379a2121164fd8de334b9c5b6b36dff5408bd4051a6b1704d0;  // keccak256("transactionSeen")
    bytes32 public constant relayerValidStorageId = 0x2c97779b4deaf24e9d46e02ec2699240a957d92782b51165b93878b09dd66f61;  // keccak256("relayerValid")

    // Below are the variables which consume storage slots.
    address public operator;
    string public version;  // Current version of the contract
    mapping(bytes32 => mapping(address => bool)) private permission;


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "PermanentStorage: not the operator");
        _;
    }

    modifier validRole(bool _enabled, address _role) {
        if (_enabled) {
            require(
                (_role == operator) || (_role == ammWrapperAddr()) || (_role == pmmAddr()),
                "PermanentStorage: not a valid role"
            );
        }
        _;
    }

    modifier isPermitted(bytes32 _storageId, address _role) {
        require(permission[_storageId][_role], "PermanentStorage: has no permission");
        _;
    }


    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "PermanentStorage: operator can not be zero address");
        operator = _newOperator;
    }

    /// @dev Set permission for entity to write certain storage.
    function setPermission(bytes32 _storageId, address _role, bool _enabled) external onlyOperator validRole(_enabled, _role) {
        permission[_storageId][_role] = _enabled;
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize(address _operator) external {
        require(
            keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("")),
            "PermanentStorage: not upgrading from default version"
        );

        version = "5.0.0";
        operator = _operator;
    }


    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function hasPermission(bytes32 _storageId, address _role) external view returns (bool) {
        return permission[_storageId][_role];
    }

    function ammWrapperAddr() public view returns (address) {
        return PSStorage.getStorage().ammWrapperAddr;
    }

    function pmmAddr() public view returns (address) {
        return PSStorage.getStorage().pmmAddr;
    }

    function wethAddr() override external view returns (address) {
        return PSStorage.getStorage().wethAddr;
    }

    function getCurveTokenIndex(address _makerAddr, address _assetAddr) override external view returns (int128) {
        return AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_assetAddr];
    }

    function isTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRelayerValid(address _relayer) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().relayerValid[_relayer];
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /// @dev Update AMMWrapper contract address.
    function upgradeAMMWrapper(address _newAMMWrapper) external onlyOperator {
        PSStorage.getStorage().ammWrapperAddr = _newAMMWrapper;
    }

    /// @dev Update PMM contract address.
    function upgradePMM(address _newPMM) external onlyOperator {
        PSStorage.getStorage().pmmAddr = _newPMM;
    }

    /// @dev Update WETH contract address.
    function upgradeWETH(address _newWETH) external onlyOperator {
        PSStorage.getStorage().wethAddr = _newWETH;
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function setCurveTokenIndex(address _makerAddr, address[] calldata _assetAddrs) override external isPermitted(curveTokenIndexStorageId, msg.sender) {
        int128 tokenLength = int128(_assetAddrs.length);
        for (int128 i = 0 ; i < tokenLength; i++) {
            address assetAddr = _assetAddrs[uint256(i)];
            AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][assetAddr] = i;
        }
    }

    function setTransactionSeen(bytes32 _transactionHash) override external isPermitted(transactionSeenStorageId, msg.sender) {
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRelayersValid(address[] calldata _relayers, bool[] calldata _isValids) override external isPermitted(relayerValidStorageId, msg.sender) {
        require(_relayers.length == _isValids.length, "PermanentStorage: inputs length mismatch");
        for (uint256 i = 0; i < _relayers.length; i++) {
            AMMWrapperStorage.getStorage().relayerValid[_relayers[i]] = _isValids[i];
        }
    }
}
