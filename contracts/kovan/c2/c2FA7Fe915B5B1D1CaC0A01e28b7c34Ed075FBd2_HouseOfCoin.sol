// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
* @title The house Of coin minting contract.
* @author daigaro.eth
* @notice  Allows users with acceptable reserves to mint backedAsset.
* @notice  Allows user to burn their minted asset to release their reserve.
* @dev  Contracts are split into state and functionality.
*/

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IERC20Extension.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IAssetsAccountant.sol";
import "./interfaces/IAssetsAccountantState.sol";
import "./interfaces/IHouseOfReserveState.sol";

contract HouseOfCoinState {

    // HouseOfCoinMinting Events
    /**
    * @dev Log when a user is mints coin.
    * @param user Address of user that minted coin.
    * @param backedtokenID Token Id number of asset in {AssetsAccountant}.
    * @param amount minted.
    */
    event CoinMinted(address indexed user, uint indexed backedtokenID, uint amount);

    /**
    * @dev Log when a user paybacks minted coin.
    * @param user Address of user that minted coin.
    * @param backedtokenID Token Id number of asset in {AssetsAccountant}.
    * @param amount payback.
    */
    event CoinPayback(address indexed user, uint indexed backedtokenID, uint amount);

    bytes32 public constant HOUSE_TYPE = keccak256("COIN_HOUSE");

    address public backedAsset;

    address public assetsAccountant;

    IOracle public oracle;
}

contract HouseOfCoin is Initializable, HouseOfCoinState {
    
    /**
    * @dev Initializes this contract by setting:
    * @param _backedAsset ERC20 address of the asset type of coin to be minted in this contract.
    * @param _assetsAccountant Address of the {AssetsAccountant} contract.
    * @param _oracle Address of the oracle that will return price in _backedAsset units per reserve asset units.
    */
    function initialize(
        address _backedAsset,
        address _assetsAccountant,
        address _oracle
    ) public initializer() 
    {
        backedAsset = _backedAsset;
        assetsAccountant = _assetsAccountant;
        oracle = IOracle(_oracle);
    }

    /**
    * @notice  Function to mint ERC20 'backedAsset' of this HouseOfCoin.
    * @dev  Requires user to have reserves for this backed asset at HouseOfReserves.
    * @param reserveAsset ERC20 address of asset to be used to back the minted coins.
    * @param houseOfReserve Address of the {HouseOfReserves} contract that manages the 'reserveAsset'.
    * @param amount To mint. 
    * Emits a {CoinMinted} event.
    */
    function mintCoin(address reserveAsset, address houseOfReserve, uint amount) public {

        IHouseOfReserveState hOfReserve = IHouseOfReserveState(houseOfReserve);
        IERC20Extension bAsset = IERC20Extension(backedAsset);

        uint reserveTokenID = hOfReserve.reserveTokenID();
        uint backedTokenID = getBackedTokenID(reserveAsset);

        // Validate reserveAsset is active with {AssetsAccountant} and check houseOfReserve inputs.
        require(
            IAssetsAccountantState(assetsAccountant).houseOfReserves(reserveTokenID) != address(0) &&
            hOfReserve.reserveAsset() == reserveAsset,
            "Not valid reserveAsset!"
        );

        // Validate this HouseOfCoin is active with {AssetsAccountant} and can mint backedAsset.
        require(bAsset.hasRole(keccak256("MINTER_ROLE"), address(this)), "houseOfCoin not authorized to mint backedAsset!" );

        // Get inputs for checking minting power, collateralization factor and oracle price
        IHouseOfReserveState.Factor memory collatRatio = hOfReserve.collateralRatio();
        uint price = oracle.getLastPrice();

        // Checks minting power of msg.sender.
        uint mintingPower = _checkMintingPower(
            msg.sender,
            reserveTokenID,
            backedTokenID,
            collatRatio,
            price
        );
        require(
            mintingPower > 0 &&
            mintingPower >= amount,
             "Not enough reserves to mint amount!"
        );

        // Update state in AssetAccountant
        IAssetsAccountant(assetsAccountant).mint(
            msg.sender,
            backedTokenID,
            amount,
            ""
        );

        // Mint backedAsset Coins
        bAsset.mint(msg.sender, amount);

        // Emit Event
        emit CoinMinted(msg.sender, backedTokenID, amount);
    }

    /**
    * @notice  Function to payback ERC20 'backedAsset' of this HouseOfCoin.
    * @dev Requires knowledge of the reserve asset used to back the minted coins.
    * @param _backedTokenID Token Id in {AssetsAccountant}, releases the reserve asset used in 'getTokenID'.
    * @param amount To payback. 
    * Emits a {CoinPayback} event.
    */
    function paybackCoin(uint _backedTokenID, uint amount) public {

        IAssetsAccountant accountant = IAssetsAccountant(assetsAccountant);
        IERC20Extension bAsset = IERC20Extension(backedAsset);

        uint userTokenIDBal = accountant.balanceOf(msg.sender, _backedTokenID);

        // Check in {AssetsAccountant} that msg.sender backedAsset was created with assets '_backedTokenID'
        require(userTokenIDBal >= 0, "No _backedTokenID balance!");

        // Check that amount is less than '_backedTokenID' in {Assetsaccountant}
        require(userTokenIDBal >= amount, "amount >  _backedTokenID balance!");

        // Check that msg.sender has the intended backed ERC20 asset.
        require(bAsset.balanceOf(msg.sender) >= amount, "No ERC20 allowance!");

        // Burn amount of ERC20 tokens paybacked.
        bAsset.burn(msg.sender, amount);

        // Burn amount of _backedTokenID in {AssetsAccountant}
        accountant.burn(msg.sender, _backedTokenID, amount);

        emit CoinPayback(msg.sender, _backedTokenID, amount);
    }

    /**
    *
    * @dev  Get backedTokenID to be used in {AssetsAccountant}
    * @param _reserveAsset ERC20 address of the reserve asset used to back coin.
    */
    function getBackedTokenID(address _reserveAsset) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(_reserveAsset, backedAsset, "backedAsset")));
    }
    
    /**
    * @dev  Internal function to query balances in {AssetsAccountant}
    */
    function _checkBalances(
        address user,
        uint _reservesTokenID,
        uint _bAssetRTokenID
    ) internal view returns (uint reserveBal, uint mintedCoinBal) {
        reserveBal = IERC1155(assetsAccountant).balanceOf(user, _reservesTokenID);
        mintedCoinBal = IERC1155(assetsAccountant).balanceOf(user, _bAssetRTokenID);
    }

    /**
    * @notice  External function that returns the amount of backed asset coins user can mint with unused reserve asset.
    * @param user to check minting power.
    * @param reserveAsset Address of reserve asset.
    */
    function checkMintingPower(address user, address reserveAsset) external view returns(uint) {

        // Get all required inputs
        IAssetsAccountantState accountant = IAssetsAccountantState(assetsAccountant);

        uint reserveTokenID = accountant.reservesIds(reserveAsset, backedAsset);

        uint backedTokenID = getBackedTokenID(reserveAsset);

        address hOfReserveAddr = accountant.houseOfReserves(reserveTokenID);

        IHouseOfReserveState hOfReserve = IHouseOfReserveState(hOfReserveAddr);

        IHouseOfReserveState.Factor memory collatRatio = hOfReserve.collateralRatio();

        uint price = oracle.getLastPrice();

        return _checkMintingPower(
            user,
            reserveTokenID,
            backedTokenID,
            collatRatio,
            price
        );
    }

    /**
    * @dev  Internal function to check if user is liquidatable
    */
    function _checkMintingPower(
        address user,
        uint reserveTokenID,
        uint backedTokenID,
        IHouseOfReserveState.Factor memory collatRatio,
        uint price
    ) public view returns(uint) {

        // Need balances for tokenIDs of both reserves and backed asset in {AssetsAccountant}
        (uint reserveBal, uint mintedCoinBal) =  _checkBalances(
            user,
            reserveTokenID,
            backedTokenID
        );

        // Check if msg.sender has reserves
        if (reserveBal == 0) {
            // If msg.sender has NO reserves, minting power = 0.
            return 0;
        } else {
            // Check that user is not Liquidatable
            (bool liquidatable, uint mintingPower) = _checkIfLiquidatable(
                reserveBal,
                mintedCoinBal,
                collatRatio,
                price
            );
            if(liquidatable) {
                // If msg.sender is liquidatable, minting power = 0.
                return 0;
            } else {
                return mintingPower;
            }
        }
    }

    /**
    * @dev  Internal function to check if user is liquidatable
    */
    function _checkIfLiquidatable(
        uint reserveBal,
        uint mintedCoinBal,
        IHouseOfReserveState.Factor memory collatRatio,
        uint price
    ) internal view returns (bool liquidatable, uint mintingPower) {

        uint reserveBalreducedByFactor =
            ( reserveBal * collatRatio.denominator) / collatRatio.numerator;
            
        uint maxMintableAmount =
            (reserveBalreducedByFactor * price) / 10**(oracle.oraclePriceDecimals());

        liquidatable = mintedCoinBal > maxMintableAmount? true : false;

        mintingPower = !liquidatable ? (maxMintableAmount - mintedCoinBal) : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IOracle {
    
    function getLastPrice() external view returns(uint);

    function oraclePriceDecimals() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IHouseOfReserveState {

    struct Factor{
        uint numerator;
        uint denominator;
    }

    /**
     * @dev Returns the reserveAsset of this HouseOfReserve.
     */
    function reserveAsset() external view returns(address);

    /**
     * @dev Returns the backedAsset of this HouseOfReserve.
     */
    function backedAsset() external view returns(address);

    /**
     * @dev Returns the reserveTokenID (used in {AssetsAccountant}) in HouseOfReserve.
     */
    function reserveTokenID() external view returns(uint);

    /**
    * @dev Returns the type of House Contract.
    */
    function HOUSE_TYPE() external returns(bytes32);

    /**
     * @dev Returns the collateralizationRatio of a HouseOfReserve.
     */
    function collateralRatio() external view returns(Factor memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IERC20Extension is IERC20, IAccessControl {

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IAssetsAccountantState {

    /**
    * @dev Returns the address of the HouseOfReserve corresponding to reserveAsset.
    */
    function houseOfReserves(uint reserveAssetTokenID) external view returns(address);

    /**
    * @dev Returns the reserve Token Id that corresponds to reserveAsset and backedAsset
    */
    function reservesIds(address reserveAsset, address backedAsset) external view returns(uint);

    /**
    * @dev Returns the address of the HouseOfCoin corresponding to backedAsset.
    */
    function houseOfCoins(address backedAsset) external view returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAssetsAccountant is IERC1155 {
    
    /**
     * @dev Registers a HouseOfReserve or HouseOfCoinMinting contract address in AssetsAccountant.
     * grants MINTER_ROLE and BURNER_ROLE to House
     * Requirements:
     * - the caller must have ADMIN_ROLE.
     */
    function registerHouse(address houseAddress, address asset) external;
    
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     * See {ERC1155-_mint}.
     * Requirements:
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    /**
     * @dev Burns `amount` of tokens from `to`, of token type `id`.
     * See {ERC1155-_burn}.
     * Requirements:
     * - the caller must have the `BURNER_ROLE`.
     */
    function burn(address account, uint256 id, uint256 value) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {burn}.
     */
    function burnBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;



}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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