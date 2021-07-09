// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "./utils/lib_storage/UserProxyStorage.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxy {
    // Below are the variables which consume storage slots.
    address public operator;
    string public version;  // Current version of the contract

    // Operator events
    event TransferOwnership(address newOperator);
    event SetAMMStatus(bool enable);
    event UpgradeAMMWrapper(address newAMMWrapper);
    event SetPMMStatus(bool enable);
    event UpgradePMM(address newPMM);
    event SetRFQStatus(bool enable);
    event UpgradeRFQ(address newRFQ);

    receive() external payable {}


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "UserProxy: not the operator");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "UserProxy: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize(address _rfqAddr, address _newAMMWrapperAddr) external {
        require(_rfqAddr != address(0), "UserProxy: _rfqAddr should not be 0");
        require(_newAMMWrapperAddr != address(0), "UserProxy: _newAMMWrapperAddr should not be 0");
        require(
            keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("5.1.1")),
            "UserProxy: not upgrading from version 5.1.1"
        );

        // Set RFQ
        RFQStorage.getStorage().rfqAddr = _rfqAddr;
        RFQStorage.getStorage().isEnabled = true;

        // Set new AMMWrapper
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
        AMMWrapperStorage.getStorage().isEnabled = true;

        // Upgrade version
        version = "5.2.0";
    }

    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function ammWrapperAddr() public view returns (address) {
        return AMMWrapperStorage.getStorage().ammWrapperAddr;
    }

    function isAMMEnabled() public view returns (bool) {
        return AMMWrapperStorage.getStorage().isEnabled;
    }

    function pmmAddr() public view returns (address) {
        return PMMStorage.getStorage().pmmAddr;
    }

    function isPMMEnabled() public view returns (bool) {
        return PMMStorage.getStorage().isEnabled;
    }

    function rfqAddr() public view returns (address) {
        return RFQStorage.getStorage().rfqAddr;
    }

    function isRFQEnabled() public view returns (bool) {
        return RFQStorage.getStorage().isEnabled;
    }

    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    function setAMMStatus(bool _enable) public onlyOperator {
        AMMWrapperStorage.getStorage().isEnabled = _enable;

        emit SetAMMStatus(_enable);
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeAMMWrapper(address _newAMMWrapperAddr, bool _enable) external onlyOperator {
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
        AMMWrapperStorage.getStorage().isEnabled = _enable;

        emit UpgradeAMMWrapper(_newAMMWrapperAddr);
        emit SetAMMStatus(_enable);
    }

    function setPMMStatus(bool _enable) public onlyOperator {
        PMMStorage.getStorage().isEnabled = _enable;

        emit SetPMMStatus(_enable);
    }

    /**
     * @dev Update PMM contract address. Used only when ABI of PMM remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradePMM(address _newPMMAddr, bool _enable) external onlyOperator {
        PMMStorage.getStorage().pmmAddr = _newPMMAddr;
        PMMStorage.getStorage().isEnabled = _enable;

        emit UpgradePMM(_newPMMAddr);
        emit SetPMMStatus(_enable);
    }

    function setRFQStatus(bool _enable) public onlyOperator {
        RFQStorage.getStorage().isEnabled = _enable;

        emit SetRFQStatus(_enable);
    }

    /**
     * @dev Update RFQ contract address. Used only when ABI of RFQ remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeRFQ(address _newRFQAddr, bool _enable) external onlyOperator {
        RFQStorage.getStorage().rfqAddr = _newRFQAddr;
        RFQStorage.getStorage().isEnabled = _enable;

        emit UpgradeRFQ(_newRFQAddr);
        emit SetRFQStatus(_enable);
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    /**
     * @dev proxy the call to AMM
     */
    function toAMM(bytes calldata _payload) external payable {
        require(isAMMEnabled(), "UserProxy: AMM is disabled");

        (bool callSucceed,) = ammWrapperAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /**
     * @dev proxy the call to PMM
     */
    function toPMM(bytes calldata _payload) external payable {
        require(isPMMEnabled(), "UserProxy: PMM is disabled");
        require(msg.sender == tx.origin, "UserProxy: only EOA");

        (bool callSucceed,) = pmmAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /**
     * @dev proxy the call to RFQ
     */
    function toRFQ(bytes calldata _payload) external payable {
        require(isRFQEnabled(), "UserProxy: RFQ is disabled");
        require(msg.sender == tx.origin, "UserProxy: only EOA");

        (bool callSucceed,) = rfqAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

library AMMWrapperStorage {
    bytes32 private constant STORAGE_SLOT = 0xbf49677e3150252dfa801a673d2d5ec21eaa360a4674864e55e79041e3f65a6b;


    /// @dev Storage bucket for proxy contract.
    struct Storage {
        // The address of the AMMWrapper contract.
        address ammWrapperAddr;
        // Is AMM enabled
        bool isEnabled;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("userproxy.ammwrapper.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

library PMMStorage {
    bytes32 private constant STORAGE_SLOT = 0x8f135983375ba6442123d61647e7325c1753eabc2e038e44d3b888a970def89a;


    /// @dev Storage bucket for proxy contract.
    struct Storage {
        // The address of the PMM contract.
        address pmmAddr;
        // Is PMM enabled
        bool isEnabled;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("userproxy.pmm.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

library RFQStorage {
    bytes32 private constant STORAGE_SLOT = 0x857df08bd185dc66e3cc5e11acb4e1dd65290f3fee6426f52f84e8faccf229cf;


    /// @dev Storage bucket for proxy contract.
    struct Storage {
        // The address of the RFQ contract.
        address rfqAddr;
        // Is RFQ enabled
        bool isEnabled;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("userproxy.rfq.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}