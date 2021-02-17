/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity 0.6.7;

contract SAFESaviourRegistry {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "SAFESaviourRegistry/account-not-authorized");
        _;
    }

    // --- Other Modifiers ---
    modifier isSaviour {
        require(saviours[msg.sender] == 1, "SAFESaviourRegistry/not-a-saviour");
        _;
    }

    // --- Variables ---
    // Minimum amount of time that needs to elapse for a specific SAFE to be saved again
    uint256 public saveCooldown;

    // Timestamp for the last time when a specific SAFE has been saved
    mapping(bytes32 => mapping(address => uint256)) public lastSaveTime;

    // Whitelisted saviours
    mapping(address => uint256) public saviours;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event ToggleSaviour(address saviour, uint256 whitelistState);
    event MarkSave(bytes32 indexed collateralType, address indexed safeHandler);

    constructor(uint256 saveCooldown_) public {
        require(saveCooldown_ > 0, "SAFESaviourRegistry/null-save-cooldown");
        authorizedAccounts[msg.sender] = 1;
        saveCooldown = saveCooldown_;
        emit ModifyParameters("saveCooldown", saveCooldown_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "SAFESaviourRegistry/add-uint-uint-overflow");
    }

    // --- Administration ---
    /*
    * @notice Change the saveCooldown value
    * @param parameter Name of the parameter to change
    * @param val The new value for the param
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(val > 0, "SAFESaviourRegistry/null-val");
        if (parameter == "saveCooldown") {
          saveCooldown = val;
        } else revert("SAFESaviourRegistry/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notice Whitelist/blacklist a saviour contract
    * @param saviour The saviour contract to whitelist/blacklist
    */
    function toggleSaviour(address saviour) external isAuthorized {
        if (saviours[saviour] == 0) {
          saviours[saviour] = 1;
        } else {
          saviours[saviour] = 0;
        }
        emit ToggleSaviour(saviour, saviours[saviour]);
    }

    // --- Core Logic ---
    /*
    * @notice Mark a new SAFE as just having been saved
    * @param collateralType The collateral type backing the SAFE
    * @param safeHandler The SAFE's handler
    */
    function markSave(bytes32 collateralType, address safeHandler) external isSaviour {
        require(
          either(lastSaveTime[collateralType][safeHandler] == 0,
          addition(lastSaveTime[collateralType][safeHandler], saveCooldown) < now),
          "SAFESaviourRegistry/wait-more-to-save"
        );
        lastSaveTime[collateralType][safeHandler] = now;
        emit MarkSave(collateralType, safeHandler);
    }
}