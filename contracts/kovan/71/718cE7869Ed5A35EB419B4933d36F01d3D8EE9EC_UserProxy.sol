// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "./interface/IPermanentStorage.sol";
import "./utils/lib_storage/UserProxyStorage.sol";
import "./utils/GasTokenAdapter.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxy is GasTokenAdapter {
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
    // function initialize(address _permStorage) external {
    function initialize(address _permStorage, address _operator) external {
        operator = _operator;
        // No version check if deploying new PermanentStorage
        // require(
        //     keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("5.0.0")),
        //     "UserProxy: not upgrading from version 5.0.0"
        // );
        UserProxyStorage.getStorage().permStorageAddr = _permStorage;

        // Upgrade version
        version = "5.2.0";
    }


    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function permStorageAddr() public view returns (address) {
        return UserProxyStorage.getStorage().permStorageAddr;
    }
    
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
    function _isValidRelayer() internal view returns (bool) {
        return IPermanentStorage(permStorageAddr()).isRelayerValid(tx.origin);
    }

    /**
     * @dev proxy the call to AMM
     */
    function toAMM(bytes calldata _payload, uint256 gasTokenAmount) external payable freesGST(gasTokenAmount, _isValidRelayer()) {
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
    function toPMM(bytes calldata _payload, uint256 gasTokenAmount) external payable freesGST(gasTokenAmount, _isValidRelayer()) {
        require(isPMMEnabled(), "UserProxy: PMM is disabled");

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
    function toRFQ(bytes calldata _payload, uint256 gasTokenAmount) external payable freesGST(gasTokenAmount, _isValidRelayer()) {
        require(isRFQEnabled(), "UserProxy: RFQ is disabled");

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

pragma solidity ^0.6.0;

interface IPermanentStorage {
    function wethAddr() external view returns (address);
    function getCurvePoolInfo(address _makerAddr, address _takerAssetAddr, address _makerAssetAddr) external view returns (int128 takerAssetIndex, int128 makerAssetIndex, uint16 swapMethod, bool supportGetDx);
    function setCurvePoolInfo(address _makerAddr, address[] calldata _underlyingCoins, address[] calldata _coins, bool _supportGetDx) external;
    function isTransactionSeen(bytes32 _transactionHash) external view returns (bool);  // Kept for backward compatability. Should be removed from AMM 5.2.1 upward
    function isAMMTransactionSeen(bytes32 _transactionHash) external view returns (bool);
    function isRFQTransactionSeen(bytes32 _transactionHash) external view returns (bool);
    function isRelayerValid(address _relayer) external view returns (bool);
    function setTransactionSeen(bytes32 _transactionHash) external;  // Kept for backward compatability. Should be removed from AMM 5.2.1 upward
    function setAMMTransactionSeen(bytes32 _transactionHash) external;
    function setRFQTransactionSeen(bytes32 _transactionHash) external;
    function setRelayersValid(address[] memory _relayers, bool[] memory _isValids) external;
}

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

library UserProxyStorage {
    bytes32 private constant STORAGE_SLOT = 0xa6de0532a2ea71cb7fbb5c265698d3ac5a073eb3d03664207e7073b99fd020a7;

    struct Storage {
        address permStorageAddr;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("userproxy.userproxy.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

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

pragma solidity ^0.6.0;

import "../interface/IGasToken.sol";

contract GasTokenAdapter {
    // solhint-disable-next-line const-name-snakecase
    IGasToken public constant GST = IGasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);  // GST2 contract
    address public constant GSTHolder = 0xDB73875FB771b95d6FECf967c00E00862c133F32;

    // @dev Frees gas tokens based on who sent the transaction. If transaction
    // is sent by relayer, our `GSTHolder` pays for gas token, `msg.sender` otherwise.
    modifier freesGST(uint256 _amount, bool _sentByRelayer) {
        uint256 gasBefore = gasleft();

        _;

        if ((_amount > 0 ) && (address(GST) != address(0))) {
            uint256 amount;
            uint256 amountFreed;

            if (_sentByRelayer) {
                amount = _amount;
                amountFreed = GST.freeFromUpTo(GSTHolder, amount);
            } else {
                // (gasUsed + FREE_BASE) / (2 * REIMBURSE - FREE_TOKEN)
                //            14154             24000        6870
                amount = (gasBefore - gasleft() + 14154) / 41130;
                amountFreed = GST.freeFromUpTo(msg.sender, amount);
            }
        }
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IGasToken is IERC20 {
    function free(uint256 value) public virtual returns (bool success);
    function freeUpTo(uint256 value) public virtual returns (uint256 freed);
    function freeFrom(address from, uint256 value) public virtual returns (bool success);
    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}