pragma solidity ^0.8.0;
import "./interfaces/IPointList.sol";
import "../IINFPermissionManager.sol";
contract PointListAdapter is IPointList {
    IINFPermissionManager public immutable permissionManager;

    constructor(IINFPermissionManager _permissionManager) {
        permissionManager = _permissionManager;
    }

    /**
     * @notice Initializes point list with admin address.
     * @param _admin Admins address.
     */
    function initPointList(address _admin) public override {
        return;
    }

    /**
     * @notice Checks if account address is in the list (has any points).
     * @param _account Account address.
     * @return exempt True or False.
     */
    function isInList(address _account) public view override returns (bool exempt) {
        (exempt, , , ) = permissionManager.getStatusAndFee(msg.sender, _account);
    }

    /**
     * @notice Checks if account has more or equal points as the number given.
     * @param _account Account address.
     * @param _amount Desired amount of points.
     * @return exempt True or False.
     */
    function hasPoints(address _account, uint256 _amount) public view override returns (bool exempt) {
        (exempt, , , ) = permissionManager.getStatusAndFee(msg.sender, _account);
    }

    /**
     * @notice Sets points to accounts in one batch.
     * @param _accounts An array of accounts.
     * @param _amounts An array of corresponding amounts.
     */
    function setPoints(address[] memory _accounts, uint256[] memory _amounts) external override {
        return;
    }
}

pragma solidity >= 0.6.12;

// ----------------------------------------------------------------------------
// White List interface
// ----------------------------------------------------------------------------

interface IPointList {
    function isInList(address account) external view returns (bool);
    function hasPoints(address account, uint256 amount) external view  returns (bool);
    function setPoints(
        address[] memory accounts,
        uint256[] memory amounts
    ) external; 
    function initPointList(address accessControl) external ;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IINFPermissionManager {
    event LogWhiteListInvestor(address indexed investor, bool approved);
    event LogSetFeeAndFeeRecipient(uint256 fee, address indexed feeRecipient);
    event LogSetTokenFee(uint256 fee, address indexed tokenId);
    event LogFeeExempt(address indexed user, uint256 status);

    function getStatusAndFee(
        address sender,
        address receiver
    ) external view returns (bool exempt, uint256 fee, uint256 feePrecision, address feeRecipient);

    function setFeeExempt(address user, bool senderExempt, bool recipientExempt) external;

    function whitelistInvestor(address investor, bool approved) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 350
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