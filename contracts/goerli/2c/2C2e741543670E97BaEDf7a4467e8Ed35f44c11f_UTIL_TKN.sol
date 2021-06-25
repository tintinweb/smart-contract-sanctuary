/*--------------------------------------------------------PRuF0.7.1
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\../\\ ___/\\\\\\\\\\\\\\\
 _\/\\\/////////\\\ _/\\\///////\\\ ____\//..\//____\/\\\///////////__
  _\/\\\.......\/\\\.\/\\\.....\/\\\ ________________\/\\\ ____________
   _\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\.\/\\\\\\\\\\\ ____
    _\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\.\/\\\///////______
     _\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\.\/\\\ ____________
      _\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\.\/\\\ ____________
       _\/\\\ ____________\/\\\ _____\//\\\.\//\\\\\\\\\ _\/\\\ ____________
        _\/// _____________\/// _______\/// __\///////// __\/// _____________
         *-------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 *  TO DO
 * sharesShare is 0.25 share of root costs- when we transition networks this should be rewritten to become a variable share.
 *-----------------------------------------------------------------
 * PRUF UTILITY TOKEN CONTRACT
 *---------------------------------------------------------------*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.7;

import "./PRUF_INTERFACES.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./ERC20Snapshot.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a MINTER_ROLE that allows for token minting (creation)
 *  - a PAUSER_ROLE that allows to stop all token transfers
 *  - a SNAPSHOT_ROLE that allows to take snapshots
 *  - a PAYABLE_ROLE role that allows authorized addresses to invoke the token splitting payment function (all paybale contracts)
 *  - a TRUSTED_AGENT_ROLE role that allows authorized addresses to transfer and burn tokens (AC_MGR)




 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract UTIL_TKN is
    Context,
    AccessControl,
    ERC20Burnable,
    Pausable,
    ERC20Snapshot
{
    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAYABLE_ROLE = keccak256("PAYABLE_ROLE");
    bytes32 public constant TRUSTED_AGENT_ROLE = keccak256(
        "TRUSTED_AGENT_ROLE"
    );

    using SafeMath for uint256;

    uint256 private _cap = 4000000000000000000000000000; //4billion max supply

    address private sharesAddress = address(0);

    struct Invoice {
        //invoice struct to facilitate payment messaging in-contract
        address rootAddress;
        uint256 rootPrice;
        address ACTHaddress;
        uint256 ACTHprice;
    }

    uint256 trustedAgentEnabled = 1;

    mapping(address => uint256) private coldWallet;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `CONTRACT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor() public ERC20("PRüF Network", "PRUF") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONTRACT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    //------------------------------------------------------------------------MODIFIERS

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Admin
     */
    modifier isAdmin() {
        require(
            hasRole(CONTRACT_ADMIN_ROLE, _msgSender()),
            "PRuF:MOD: must have CONTRACT_ADMIN_ROLE"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Pauser
     */
    modifier isPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "PRuF:MOD: must have PAUSER_ROLE"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Minter
     */
    modifier isMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "PRuF:MOD: must have MINTER_ROLE"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Payable in PRuF
     */
    modifier isPayable() {
        require(
            hasRole(PAYABLE_ROLE, _msgSender()),
            "PRuF:MOD: must have PAYABLE_ROLE"
        );
        require(
            trustedAgentEnabled == 1,
            "PRuF:MOD: Trusted Payable Function permanently disabled - use allowance / transferFrom pattern"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Trusted Agent
     */
    modifier isTrustedAgent() {
        require(
            hasRole(TRUSTED_AGENT_ROLE, _msgSender()),
            "PRuF:MOD: must have TRUSTED_AGENT_ROLE"
        );
        require(
            trustedAgentEnabled == 1,
            "PRuF:MOD: Trusted Agent function permanently disabled - use allowance / transferFrom pattern"
        );
        _;
    }

    /*
     * @dev ----------------------------------------PERMANANTLY !!!  Kills trusted agent and payable functions
     * this will break the functionality of current payment mechanisms.
     *
     * The workaround for this is to create an allowance for pruf contracts for a single or multiple payments,
     * either ahead of time "loading up your PRUF account" or on demand with an operation. On demand will use quite a bit more gas.
     * "preloading" should be pretty gas efficient, but will add an extra step to the workflow, requiring users to have sufficient
     * PRuF "banked" in an allowance for use in the system.
     *
     */
    function adminKillTrustedAgent(uint256 _key) external isAdmin {
        if (_key == 170) {
            trustedAgentEnabled = 0; //-------------------THIS IS A PERMANENT ACTION AND CANNOT BE UNDONE
        }
    }

    /*
     * @dev Set calling wallet to a "cold Wallet" that cannot be manipulated by TRUSTED_AGENT or PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function setColdWallet() external {
        coldWallet[_msgSender()] = 170;
    }

    /*
     * @dev un-set calling wallet to a "cold Wallet", enabling manipulation by TRUSTED_AGENT and PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function unSetColdWallet() external {
        coldWallet[_msgSender()] = 0;
    }

    /*
     * @dev return an adresses "cold wallet" status
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS
     */
    function isColdWallet(address _addr) external view returns (uint256) {
        return coldWallet[_addr];
    }

    /*
     * @dev Set address of SHARES payment contract. by default contract will use root address instead if set to zero.
     */
    function AdminSetSharesAddress(address _paymentAddress) external isAdmin {
        require(
            _paymentAddress != address(0),
            "PRuF:SSA: payment address cannot be zero"
        );

        //^^^^^^^checks^^^^^^^^^

        sharesAddress = _paymentAddress;
        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev Deducts token payment from transaction
     */
    function payForService(
        address _senderAddress,
        address _rootAddress,
        uint256 _rootPrice,
        address _ACTHaddress,
        uint256 _ACTHprice
    ) external isPayable {
        require(
            coldWallet[_senderAddress] == 0,
            "PRuF:PFS: Cold Wallet - Trusted payable functions prohibited"
        );
        require( //redundant? throws on transfer?
            balanceOf(_senderAddress) >= _rootPrice.add(_ACTHprice),
            "PRuF:PFS: insufficient balance"
        );
        //^^^^^^^checks^^^^^^^^^

        if (sharesAddress == address(0)) {
            //IF SHARES ADDRESS IS NOT SET
            _transfer(_senderAddress, _rootAddress, _rootPrice);
            _transfer(_senderAddress, _ACTHaddress, _ACTHprice);
        } else {
            //IF SHARES ADDRESS IS SET
            uint256 sharesShare = _rootPrice.div(uint256(4)); // sharesShare is 0.25 share of root costs when we transition networks this should be a variable share.
            uint256 rootShare = _rootPrice.sub(sharesShare); // adjust root price to be root price - 0.25 share

            _transfer(_senderAddress, _rootAddress, rootShare);
            _transfer(_senderAddress, sharesAddress, sharesShare);
            _transfer(_senderAddress, _ACTHaddress, _ACTHprice);
        }
        //^^^^^^^effects / interactions^^^^^^^^^
    }

    /*
     * @dev arbitrary burn (requires TRUSTED_AGENT_ROLE)   ****USE WITH CAUTION
     */
    function trustedAgentBurn(address _addr, uint256 _amount)
        external
        isTrustedAgent
    {
        require(
            coldWallet[_addr] == 0,
            "PRuF:BRN: Cold Wallet - Trusted functions prohibited"
        );
        //^^^^^^^checks^^^^^^^^^
        _burn(_addr, _amount);
        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev arbitrary transfer (requires TRUSTED_AGENT_ROLE)   ****USE WITH CAUTION
     */
    function trustedAgentTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external isTrustedAgent {
        require(
            coldWallet[_from] == 0,
            "PRuF:TAT: Cold Wallet - Trusted functions prohibited"
        );
        //^^^^^^^checks^^^^^^^^^
        _transfer(_from, _to, _amount);
        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev Take a balance snapshot, returns snapshot ID
     */
    function takeSnapshot() external returns (uint256) {
        require(
            hasRole(SNAPSHOT_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have snapshot role to take a snapshot"
        );
        return _snapshot();
    }

    /**
     * @dev Creates `_amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 _amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "PRuF:MOD: must have MINTER_ROLE"
        );
        //^^^^^^^checks^^^^^^^^^

        _mint(to, _amount);
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual isPauser {
        //^^^^^^^checks^^^^^^^^^
        _pause();
        //^^^^^^^effects^^^^^^^^
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual isPauser {
        //^^^^^^^checks^^^^^^^^^
        _unpause();
        //^^^^^^^effects^^^^^^^^
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev all paused functions are blocked here, unless caller has "pauser" role
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);

        require(
            (!paused()) || hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20Pausable: function unavailble while contract is paused"
        );
        if (from == address(0)) {
            // When minting tokens
            require(
                totalSupply().add(amount) <= _cap,
                "ERC20Capped: cap exceeded"
            );
        }
    }
}