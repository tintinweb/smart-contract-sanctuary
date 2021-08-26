/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: CC BY 3.0 US

/**
 * TESTNET RE-DEPLOYMENT TO CONFORM WITH COINSCOPE.CO'S AUDIT RECOMMENDATIONS, 25/08/21
 *
 * Creative Commons Attribution License 4. 0 for ADMIRE Content Coin, https://admire.dev/
 * Attribution license because this "highly secure" token can be easily modified to
 * do exceptionally evil things, such as capture and divert individual address' balances.
 *
 * If you see a deployed contract with the same amount of MultiSig options, it's likely
 * a copy and you need to review the modifiers in the final token contract. Make sure they're
 * only reverting. If not, it's an "evil contract", beware!
 *
 * Only complile with solc >=0.8.0, mathmatics now rely on the compiler's built in overflow checks.
 * Coinscope.co audit flagged arthimetic for wrapping with SafeMath, but it's not needed anymore, 
 * overflows now revert automatically: https://docs.soliditylang.org/en/v0.8.6/080-breaking-changes.html
 * Reference Explanation: Lines 1349-1355. If using these as invidividual files, use a static solc 
 * (ie not ^0.8.0), newer the better.
 *
 * ADMIRE's core team is welcoming, positive and inclusive: If you clone our token or
 * code, do drop in on social media and say "hello"! Regardless, best of luck!
 *
 * BEWARE: This is CREATE2 deployed and self-destructable contract! "selfdestruct" is 
 * wrapped by the community multisig address and not available to the dev team without permission.
 * The deployed block height should be slightly before the code verification's height. 
 * We found this the best solution to community safety Vs. an upgradable (post-audit) token.
 * This is a very dangerous attribute, the deployed token's "control page" will track and record
 * deployment, any redeployments and file diffs. The salt is included with encrypted dev key backups.
 * 
 * BYTECODE SIZE AND GAS ISSUES: Strings are <=32 bytes. TODO: Try and better explain 
 * require/reverts in comments. Coinscope.co caught a dozen extraneous lines, cheers
 * to them!
 *
 * For testing, optimize as you will, for deployment, at least 1337 or more runs to
 * lower actual gas usage at the (possible) cost of higher deployment.
 *
 * Do not add gas to the listing modifiers. These are straight storage lookups, not arrays.
 * Further, the lookup variables were chosen to be very small, that is, there
 * should be very few blacklisted users (so checks for bool->false) and not many whitelisted
 * contracts (so checks for bool->true). There is no theoretical limit to storage lookups, 
 * and those modifiers should never require more gas. This is a feature, not a flaw.
 *
 * Solidity is odd: multiple smaller functions costs more gas and requires more bytecode. Conversely, 
 * looping arrays costs gas, so straight lookups remain. This is also a readability, usability
 * and simplicity trade-off: seem far more important to KISS (Keep It Simple, Stupid).
 *
 * uint256 uses less gas than uint8. Odd. So be it.
 * 
 * Inlining internal functions takes bytecode but is supposed to save gas over public,
 * which are read into memory and passed to the function. MultiSig functions need to be
 * public, not much can be done as we're up against the bytecode size constraint.
 */

pragma solidity 0.8.7;
// pragma experimental ABIEncoderV2; // placeholder: enabled by default ^0.8.0

// AND PDX-License-Identifier: MIT
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

// AND PDX-License-Identifier: MIT

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * Modified from: https://soliditydeveloper.com/extcodehash
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // Coinscope.co audit suggested moving this to a declaration to save bytecode, which
        // isn't possible as this library is pulled into all our contracts (and flattened here 
        // for audit readability). It'd have to be a struct and re-declared in the library.
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

}

// AND PDX-License-Identifier: MIT

contract OwnableMultiSig is Context {
    using Address for address;
    address public _owner;
    address public _multisig;
    address public _operator;

    // @dev Inherited logic:
    // @dev Initializes the contract with MultiSig _mint_wrappers_stopped state control off.
    // @dev Initializes the contract with MultiSig _change_operator_stopped state control off.
    // @dev Initializes the contract with MultiSig _rate_change_stopped state control off.
    // @dev Initializes the contract with MultiSig _blacklist_stopped state control off.
    // @dev Initializes the contract with MultiSig _antiwhale_stopped state control off.
    // @dev Initializes the contract with MultiSig _owner_privileges_stopped state control off.
    // @dev Initializes the contract with MultiSig _approve__addresses_stopped state control off.
    // @dev Initializes the contract with MultiSig _nocontracts_stopped state control off.
    // @dev Initializes the contract with MultiSig _multisig_stopped state.

    constructor() {
        // Explicitly and safely declare our own msgSender variable. Upgrading to solc 0.8.6 
        // caused odd issues with _msgSender(), not sure why, don't care, just declare:
        address msgSender = _msgSender();
        _owner = msgSender;
        _multisig = msgSender;
        _operator = msgSender;
        // emit notices on deployment for clarity's sake reading the TX
        emit OwnershipTransferred(address(0), msgSender);
        emit MultiSigTransferred(address(0), msgSender);
        emit OperatorTransferred(address(0), msgSender);
        _mint_wrappers_stopped = false;
        _change_operator_stopped = false;
        _rate_change_stopped = false;
        _blacklist_stopped = false;
        _antiwhale_stopped = false;
        _owner_privileges_stopped = false;
        _approve_spendable_address_stopped = false;
        _nocontracts_stopped = false;
        _multisig_stopped = false;
    }

    // @dev **************** Ownership Events   ***********************
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event MultiSigTransferred(
        address indexed previousMultiSig,
        address indexed newMultiSig
    );
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    // @dev ____________________Functions__________________________
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function multisig() public view virtual returns (address) {
        return _multisig;
    }

    // @dev ____________________Modifiers__________________________
    /**
     * @dev Throws if called by any account other than the owner.
     * Gas: mind the byte count on require messages.
     */
    modifier onlyOwner() {
        require(
            owner() == _msgSender(), 
            "Ownable::not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOperator() {
        require(
            operator() == _msgSender(),
            "Ownable::caller is not operator"
        );
        _;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMultiSig() {
        require(
            multisig() == _msgSender(),
            "Ownable::caller is not multisig"
        );
        _;
    }

    // @dev ____________________Renunciations__________________________
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership()
        public
        virtual
        onlyOwner
        whenOwnerPrivilegesOn
    {
        _setOwner(address(0));
    }

    // @dev __________________Transfer Functions________________________
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Gas: mind the byte count on require messages.
     * NOTE: owner, operator and multisig all start as deployer, so all functions are
     * available and must be explicitly transfered away to secure this token.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        onlyOwner
        whenOwnerPrivilegesOn
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is 0 address"
        );
        _setOwner(newOwner);
    }

    function transferOperator(address newOperator)
        public
        virtual
        onlyOperator
        whenChangeByOperatorOn
    {
        require(
            newOperator != address(0),
            "Ownable:new operator is 0 address"
        );
        _setOperator(newOperator);
    }

    function transferMultiSig(address newMultiSig)
        public
        virtual
        onlyOperator
        whenMultiSigOn
    {
        require(
            newMultiSig != address(0),
            "Ownable:new multisig is 0 address"
        );
        _setMultiSig(newMultiSig);
    }

    // @dev __________________Transfer Address Functions________________________
    // fixes coinscope.co reduntant code
    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

    }

    function _setOperator(address newOperator) private {
        emit OwnershipTransferred(_operator, newOperator);
        _operator = newOperator;

    }

    function _setMultiSig(address newMultiSig) private {
        emit MultiSigTransferred(_multisig, newMultiSig);
        _multisig = newMultiSig;

    }

    // @dev **************** Lock the Mint_Wrappers   ***********************
    // @dev Emitted when Minting is paused by Operator.
    event Mint_Wrappers_Stopped(address account);

    // @dev Emitted when the Minting is allowed by Operator.
    event Started_Mint_Wrappers(address account);

    bool internal _mint_wrappers_stopped;

    // @dev Returns true if the contract is _mint_wrappers_stopped, and false otherwise.
    function mint_wrappers_stopped() public view returns (bool) {
        return _mint_wrappers_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _mint_wrappers_stopped.
    modifier whenMintWrappersOn() {
        require(!_mint_wrappers_stopped, "MultiSig::Mint Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _mint_wrappers_stopped.
    modifier whenMintWrappersOff() {
        require(
            _mint_wrappers_stopped,
            "Multisig::Declined _mint_wrappers"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function mint:
    // function mint(address _to, uint256 _amount) public onlyOwner whenMintWrappersOn {
    function _stop_mint_wrappers() internal virtual whenMintWrappersOn {
        _mint_wrappers_stopped = true;
        emit Mint_Wrappers_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_mint_wrappers() internal virtual whenMintWrappersOff {
        _mint_wrappers_stopped = false;
        emit Started_Mint_Wrappers(_msgSender());
    }

    // @dev **************** Lock the Operator   ***********************
    // @dev Emitted when Changing The Operator is paused by Operator.
    event Change_Operator_Stopped(address account);

    // @dev Emitted when the Changing The Operator is allowed by Operator.
    event Started_Change_Operator(address account);

    bool private _change_operator_stopped;

    // @dev Returns true if the contract is _change_operator_stopped, and false otherwise.
    function change_operator_stopped() public view returns (bool) {
        return _change_operator_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _change_operator_stopped.
    modifier whenChangeByOperatorOn() {
        require(
            !_change_operator_stopped,
            "MultiSig::Changes by Operator On"
        );
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _change_operator_stopped.
    modifier whenChangeByOperatorOff() {
        require(
            _change_operator_stopped,
            "Multisig::Changes by Operator Off"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function D3_transferOperator:
    // function D3_transferOperator(address newOperator) public onlyOwner whenChangeByOperatorOn {
    function _stop_change_operator() internal virtual whenChangeByOperatorOn {
        _change_operator_stopped = true;
        emit Change_Operator_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_change_operator() internal virtual whenChangeByOperatorOff {
        _change_operator_stopped = false;
        emit Started_Change_Operator(_msgSender());
    }

    // @dev **************** Lock the Rates   ***********************
    // @dev Emitted when RateChanging is paused by Operator.
    event Rate_Change_Stopped(address account);

    // @dev Emitted when the RateChanging is allowed by Operator.
    event Started_Rate_Change(address account);

    bool private _rate_change_stopped;

    // @dev Returns true if the contract is _rate_change_stopped, and false otherwise.
    function rate_change_stopped() public view returns (bool) {
        return _rate_change_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _rate_change_stopped.
    modifier whenRateChangeOn() {
        require(!_rate_change_stopped, "MultiSig::RateChanges On");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _rate_change_stopped.
    modifier whenRateChangeOff() {
        require(
            _rate_change_stopped,
            "Multisig::RateChange Perm Off"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function updateRate:
    //function updateRate(uint16 _charityRate) public onlypOwner whenRateChangeOn {
    function _stop_rate_change() internal virtual whenRateChangeOn {
        _rate_change_stopped = true;
        emit Rate_Change_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_rate_change() internal virtual whenRateChangeOff {
        _rate_change_stopped = false;
        emit Started_Rate_Change(_msgSender());
    }

    // @dev **************** Lock the Blacklist   ***********************
    // @dev Emitted when Minting is paused by Operator.
    event Blacklist_Stopped(address account);

    // @dev Emitted when the Minting is allowed by Operator.
    event Started_Blacklist(address account);

    bool private _blacklist_stopped;

    // @dev Returns true if the contract is _blacklist_stopped, and false otherwise.
    function blacklist_stopped() public view returns (bool) {
        return _blacklist_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _blacklist_stopped.
    modifier whenBlacklistOn() {
        require(!_blacklist_stopped, "MultiSig::Mint To Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _blacklist_stopped.
    modifier whenBlacklistOff() {
        require(
            _blacklist_stopped,
            "Multisig::Mint To Denied"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function blacklistUpdate:
    // function blacklistUpdate(address user, bool value) public virtual onlyOwner whenBlacklistOn {
    function _stop_blacklist() internal virtual whenBlacklistOn {
        _blacklist_stopped = true;
        emit Blacklist_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_blacklist() internal virtual whenBlacklistOff {
        _blacklist_stopped = false;
        emit Started_Blacklist(_msgSender());
    }

    // @dev **************** Lock the AntiWhale   ***********************
    // @dev Emitted when Minting is paused by Operator.
    event AntiWhale_Stopped(address account);

    // @dev Emitted when the Minting is allowed by Operator.
    event Started_AntiWhale(address account);

    bool private _antiwhale_stopped;

    // @dev Returns true if the contract is _antiwhale_stopped, and false otherwise.
    function antiwhale_stopped() public view returns (bool) {
        return _antiwhale_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _antiwhale_stopped.
    modifier whenAntiWhaleOn() {
        require(!_antiwhale_stopped, "MultiSig::AntiWhale On");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _antiwhale_stopped.
    modifier whenAntiWhaleOff() {
        require(
            _antiwhale_stopped,
            "Multisig::AntiWhale Off"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function antiwhaleUpdate:
    // function G5_setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOwner whenAntiWhaleOn {
    function _stop_antiwhale() internal virtual whenAntiWhaleOn {
        _antiwhale_stopped = true;
        emit AntiWhale_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_antiwhale() internal virtual whenAntiWhaleOff {
        _antiwhale_stopped = false;
        emit Started_AntiWhale(_msgSender());
    }

    /* @dev **************** Lock the OwnerPrivileges_To   ***********************
     * This breaks almost everything, only for serious emergencies!
     */
    // @dev Emitted when OwnerPrivileges is paused by Operator.
    event OwnerPrivileges_Stopped(address account);

    // @dev Emitted when the OwnerPrivileges is allowed by Operator.
    event Started_OwnerPrivileges(address account);

    bool private _owner_privileges_stopped;

    // @dev Returns true if the contract is _owner_privileges_stopped, and false otherwise.
    function owner_privileges_stopped() public view returns (bool) {
        return _owner_privileges_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _owner_privileges_stopped.
    modifier whenOwnerPrivilegesOn() {
        require(
            !_owner_privileges_stopped,
            "MultiSig::OwnerPrivileges Allowed"
        );
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _owner_privileges_stopped.
    modifier whenOwnerPrivilegesOff() {
        require(
            _owner_privileges_stopped,
            "MultiSig::OwnerPrivileges Revoked"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function mintUpdate:
    // function mint(uint256 amount) public onlyOwner  whenOwnerPrivilegesOff returns (bool) {
    function _stop_owner_privileges() internal virtual whenOwnerPrivilegesOn {
        _owner_privileges_stopped = true;
        emit OwnerPrivileges_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_owner_privileges() internal virtual whenOwnerPrivilegesOff {
        _owner_privileges_stopped = false;
        emit Started_OwnerPrivileges(_msgSender());
    }

    // @dev **************** Locking Approving Access by address can BREAKS THINGS   ***********************
    // @dev Emitted when ApproveSpendableAddress is paused by Operator.
    event Approve_Spendable_Address_Stopped(address account);

    // @dev Emitted when the ApproveSpendableAddress is allowed by Operator.
    event Started_Approve_Spendable_Address(address account);

    bool private _approve_spendable_address_stopped;

    // @dev Returns true if the contract is _approve_spendable_address_stopped, and false otherwise.
    function approve_spendable_address_stopped() public view returns (bool) {
        return _approve_spendable_address_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _approve_spendable_address_stopped.
    modifier whenApproveSpendableAddressOn() {
        require(
            !_approve_spendable_address_stopped,
            "ApproveSpendableAddress Allowed"
        );
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _approve_spendable_address_stopped.
    modifier whenApproveSpendableAddressOff() {
        require(
            _approve_spendable_address_stopped,
            "ApproveSpendableAddress Denied"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function whenApproveSpendableAddressOn
    function _stop_approve_spendable_address()
        internal
        virtual
        whenApproveSpendableAddressOn
    {
        _approve_spendable_address_stopped = true;
        emit Approve_Spendable_Address_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_approve_spendable_address()
        internal
        virtual
        whenApproveSpendableAddressOff
    {
        _approve_spendable_address_stopped = false;
        emit Started_Approve_Spendable_Address(_msgSender());
    }

    /* @dev ************ Locking Out Access by Contracts BREAKS THINGS   ********************
     * First whitelist all contracts that interact with GROGU, turn this on.
     */

    // @dev Emitted when Changing Contract Interaction is paused by Operator.
    event NoContracts_Stopped(address account);

    // @dev Emitted when the Changing Contract Interaction is allowed by Operator.
    event Started_NoContracts(address account);

    bool internal _nocontracts_stopped;

    // @dev Returns true if the contract is _nocontracts_stopped, and false otherwise.
    function nocontracts_stopped() public view returns (bool) {
        return _nocontracts_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _nocontracts_stopped.
    modifier whenNoContractsOn() {
        require(!_nocontracts_stopped, "MultiSig::NoContracts Allow");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _nocontracts_stopped.
    modifier whenNoContractsOff() {
        require(
            _nocontracts_stopped,
            "Multisig::NoContracts Revoked"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function E5_updateCharityRate:
    function _stop_nocontracts() internal virtual whenNoContractsOn {
        _nocontracts_stopped = true;
        emit NoContracts_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_nocontracts() internal virtual whenNoContractsOff {
        _nocontracts_stopped = false;
         emit Started_NoContracts(_msgSender());
    }

    // @dev ************** Operator Hands Off MultiSig Controls  *********************

    // @dev Emitted when MultiSiging is paused by Operator.
    event MultiSig_Stopped(address account);

    // @dev Emitted when the MultiSiging is allowed by Operator.
    event Started_MultiSig(address account);

    bool private _multisig_stopped;

    // @dev Returns true if the contract is _multisig_stopped, and false otherwise.
    function multisig_stopped() public view returns (bool) {
        return _multisig_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _multisig_stopped.
    modifier whenMultiSigOn() {
        require(!_multisig_stopped, "MultiSig::MultiSig Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _multisig_stopped.
    modifier whenMultiSigOff() {
        require(
            _multisig_stopped,
            "MultiSig::Permission Revoked"
        );
        _;
    }

    // @dev Triggers stopped state. Call in function mintUpdate:
    function _stop_multisig() internal virtual whenMultiSigOn {
        _multisig_stopped = true;
        emit MultiSig_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_multisig() internal virtual whenMultiSigOff {
        _multisig_stopped = false;
        emit Started_MultiSig(_msgSender());
    }
    
    // @dev A1 and A2 are in Pausable.sol, which is still separate

    // @dev Here begins the Public MultiSig Controls
    function B1_MintWrappers_EnableProtection()
        public
        onlyOperator
        whenMintWrappersOn
    {
        _stop_mint_wrappers();
    }

    function B2_MintWrappers_DisableProtection()
        public
        onlyOperator
        whenMintWrappersOff
    {
        _start_mint_wrappers();
    }

    function C1_OwnerPrivileges_Revoke()
        public
        onlyOperator
        whenOwnerPrivilegesOn
    {
        _stop_owner_privileges();
    }

    function C2_OwnerPrivileges_Allow()
        public
        onlyMultiSig
        whenOwnerPrivilegesOff
    {
        _start_owner_privileges();
    }

    function D1_Revoke_Changes_By_The_Operator()
        public
        onlyMultiSig
        whenChangeByOperatorOn
    {
        _stop_change_operator();
    }

    function D2_Allow_Changes_By_The_Operator()
        public
        onlyMultiSig
        whenChangeByOperatorOff
    {
        _start_change_operator();
    }

    function E1_Revoke_Changing_Rates() 
        public 
        onlyMultiSig 
        whenRateChangeOn 
    {
        _stop_rate_change();
    }

    function E2_Allow_Changing_Rates() 
        public 
        onlyMultiSig 
        whenRateChangeOff 
    {
        _start_rate_change();
    }

    /* @dev E5_updateCharityRate, E6_updateMaxTransferAmountRate, 
     * E7_updateTransferTaxRate, E7_updateMinAmountToLiquify
     * remain in main contract
     */

    function F1_BlacklistingAddresses_TurnOff()
        public
        onlyMultiSig
        whenBlacklistOn
    {
        _stop_blacklist();
    }

    function F2_BlacklistingAdresses_TurnOn()
        public
        onlyMultiSig
        whenBlacklistOff
    {
        _start_blacklist();
    }

    // @dev F3_blacklistUpdate, F4_isBlacklisted in main contract

    function G1_Revoke_AntiWhale() public onlyMultiSig whenAntiWhaleOn {
        _stop_antiwhale();
    }

    function G2_Allow_AntiWhale() public onlyMultiSig whenAntiWhaleOff {
        _start_antiwhale();
    }

    // @dev G3_setExcludedFromAntiWhale, G4_isExcludedFromAntiWhale in main contract
    // @dev WARNING! This will absolutely break things! Whitelist every known contract first!
    function H1_ContractWrapperProtection_TurnOn()
        public
        onlyOperator
        whenNoContractsOn
    {
        _stop_nocontracts();
    }

    function H2_ContractWrapperProtection_TurnOff()
        public
        onlyOperator
        whenNoContractsOff
    {
        _start_nocontracts();
    }

    // @dev WARNING! Things will break! The devs need to be able to increase allowances.
    function I1_OperatorCanAddSpendableAddresses_TurnOff()
        public
        onlyMultiSig
        whenApproveSpendableAddressOn
    {
        _stop_approve_spendable_address();
    }

    function I2_OperatorCanAddSpendableAddresses_TurnOn()
        public
        onlyMultiSig
        whenApproveSpendableAddressOff
    {
        _start_approve_spendable_address();
    }

    // @dev I3_contractwhitelistUpdate, I4_minterRoleUpdate

    function J1_MultiSig_Enable() public onlyMultiSig whenMultiSigOn {
        _stop_multisig();
    }

    function J2_MultiSig_TurnOff() public onlyMultiSig whenMultiSigOff {
        _start_multisig();
    }

    // @dev K1_withdrawTokensSentHere in main contract
}

// AND PDX-License-Identifier: MIT

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// AND PDX-License-Identifier: MIT

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// @dev This is munged together from:
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// AND PDX-License-Identifier: MIT

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */

contract Pausable is Context, OwnableMultiSig {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    // @dev begins MultiSig enforcement
    function A1_PauseTheChain_Pause() public onlyOperator whenNotPaused {
        _pause();
    }

    function A2_PauseTheChain_Unpause() public onlyOperator whenPaused {
        _unpause();
    }
}

// AND PDX-License-Identifier: MIT
contract BEP20 is Context, IBEP20, OwnableMultiSig, Pausable {
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        whenNotPaused
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        whenNotPaused
        whenApproveSpendableAddressOn
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) 
        public 
        virtual 
        override 
        whenNotPaused
        returns (bool) {
        _transfer(sender, recipient, amount);
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        whenApproveSpendableAddressOn
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        whenNotPaused
        whenApproveSpendableAddressOn
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "decreased below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     * JUST GET RID OF THIS, REDUNDANT WITH _mint AND TOO MUCH FUD/DRAMA
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    // function mint(uint256 amount)
    //     public
    //     onlyOwner
    //     whenOwnerPrivilegesOn
    //     returns (bool)
    // {
    //     _mint(_msgSender(), amount);
    //     return true;
    // }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * This is virtual and overriden with multisig checks in main contract
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "transfer from the 0 address");
        require(recipient != address(0), "transfer to the 0 address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds bal");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     *
     * WARNING! Grogu MUST USE solc ^0.8.0 and the built-in overflow protection, otherwise
     * SafeMath.sol must be re-introduced. https://soliditydeveloper.com/solidity-0.8
     * That documentation isn't clear on this, but calling unchecked reverts to the old way
     * requiring SafeMath wrapping: https://blog.soliditylang.org/2020/10/28/solidity-0.8.x-preview/
     * notes: "The main change for 0.8.x is the switch to checked arithmetic operations by default. 
     * This means that x + y will throw an exception on overflow. In other words: You will not need 
     * SafeMath anymore!"
     * 
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "approve from the 0 address");
        require(spender != address(0), "approve to the 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}

// AND PDX-License-Identifier: MIT

// @dev For consistency, decimals are hard-coded to 18 in BEP20PausablemultiSig.sol
contract GRGU_v37 is BEP20("GRGUV37", "GRGUV37") {
    using Address for address;

    // Transfer tax rate in basis points. (default 5% which would be 500)
    uint16 public transferTaxRate = 0;
    // Charity rate % of transfer tax. (default 20% which is 20 below x 5% = 1% of total amount).
    uint16 public charityRate = 0;
    // Max transfer tax rate: 10% which is 1000 below
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Charity address
    // uncomment and leave constant if you don't want to be able to change the charity address
    // Also, if you want it fixed, comment out the address changing funtions and event below
    //address public constant CHARITY_ADDRESS = 0x5d484FbAa477D3bB73D94D89F17E6F5858B85dc0;
    address public CHARITY_ADDRESS = 0x5d484FbAa477D3bB73D94D89F17E6F5858B85dc0;
    // uncomment and leave constant if you don't want to be able to change the tax address
    // Also, if you want it fixed, comment out the address changing funtions and event below
    //address public constant TAX_ADDRESS = 0x73cb224189F6b33aB841B946EcE553c07EBdF1A0;
    address public TAX_ADDRESS = 0x73cb224189F6b33aB841B946EcE553c07EBdF1A0;
    // address public TREASURY_ADDRESS = 0xB32a4f632BCA850bCe8609b8894857D6f1BAd578;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply, which is 50 below)
    uint16 public maxTransferAmountRate = 50;
    // Addresses that excluded from antiWhale
    mapping(address => bool) public _excludedFromAntiWhale;
    // Address that are blacklisted
    mapping(address => bool) public _blacklist;
    // Contract address that are whitelisted
    mapping(address => bool) public _contractwhitelist;
    // Address that have the Minter Role
    mapping(address => bool) public _minter_role_address;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Min amount to liquify. (default 500 GROGUs)
    uint256 public minAmountToLiquify = 500 ether;
    // The swap router, modifiable. Will be changed to Grogu's router when our own AMM release
    IUniswapV2Router02 public groguSwapRouter;
    // The trading pair
    address public groguSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    // Events
    event ContractAddressTransferred(
        address indexed previosContractAddress,
        address indexed newContractAddress
    );
    event CharityAddressTransferred(
        address indexed previosCharityAddress,
        address indexed newCharityAddress
    );
    event TaxAddressTransferred(
        address indexed previosTaxAddress,
        address indexed newTaxAddress
    );
    event TransferTaxRateUpdated(
        address indexed _operator, 
        uint256 previousRate, 
        uint256 newRate
    );
    event CharityRateUpdated(
        address indexed _operator, 
        uint256 previousRate, 
        uint256 newRate
    );
    event MaxTransferAmountRateUpdated(
        address indexed _operator, 
        uint256 previousRate, 
        uint256 newRate
    );
    event SwapAndLiquifyEnabledUpdated(
        address indexed _operator, 
        bool enabled
    );
    event MinAmountToLiquifyUpdated(
        address indexed _operator, 
        uint256 previousAmount, 
        uint256 newAmount
    );
    event GroguRouterUpdated(
        address indexed _operator, 
        address indexed router, 
        address indexed pair
    );
    event SwapAndLiquify(
        uint256 tokensSwapped, 
        uint256 ethReceived, 
        uint256 tokensIntoLiqudity
    );
    event BlacklistUpdated(
        address indexed _operator, 
        bool value
    );
    event ContractWhitelistUpdated(
        address indexed _operator, 
        bool value
    );
    event MinterRoleUpdated(
        address indexed _operator, 
        bool value
    );
    event ExcludedFromAntiWhale(
        address indexed _operator, 
        bool value
    );
    event WithdrawTokensSentHere(
        address token, 
        address _operator, 
        uint256 amount
    );

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false &&
                _excludedFromAntiWhale[recipient] == false
            ) {
                require(
                    amount <= maxTransferAmount(),
                    "antiWhale::exceeds maxTXAmount"
                );
            }
        }
        _;
    }

    modifier blacklisted(address sender, address recipient) {
        if (_blacklist[sender] == true || _blacklist[recipient] == true) {
            // @dev WARNING! If this is doing anything other than revert, it's an evil contract
            // @dev should be similar to: revert("GROGU::blacklisted: Transfer declined");
            revert("GROGU::blacklisted addr");
        }
        _;
    }

    modifier NoContractsOn(address sender, address recipient) {
        if (_nocontracts_stopped == true) {
            if (
                (sender.isContract() && _contractwhitelist[sender] == false) 
                  ||
                (recipient.isContract() && _contractwhitelist[recipient] == false)
            ) {
                revert(
                    "MultiSig::non-whitelist contract"
                );
            }
        }
        _;
    }

    modifier MintWrappersOn(address recipient) {
        if (_mint_wrappers_stopped == true) {
            if (
                (_minter_role_address[recipient] == false || _minter_role_address[msg.sender] == false) 
                  ||
                (recipient.isContract() && _contractwhitelist[recipient] == false)
            ) {
                revert(
                    "MultiSig::Minting declined"
                );
            }
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    constructor() {
        emit CharityAddressTransferred(address(0), CHARITY_ADDRESS);
        emit TaxAddressTransferred(address(0), TAX_ADDRESS);
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[CHARITY_ADDRESS] = true;
        _excludedFromAntiWhale[TAX_ADDRESS] = true;
        // _excludedFromAntiWhale[TREASURY_ADDRESS] = true;
        _contractwhitelist[address(this)] = true;
        _minter_role_address[msg.sender] = true;
        _minter_role_address[address(this)] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address recipient, uint256 _amount)
        public
        whenNotPaused
        onlyOperator
        MintWrappersOn(recipient)
    {
        // require(_minter_role_address[user] == false, "Blacklisted");
        _mint(recipient, _amount);
        _moveDelegates(address(0), _delegates[recipient], _amount);
    }

    // @dev begins MultiSig enforcement
    // The A functions are in PausableMultiSig.sol, only here as a placeholder 
    // A1_PauseTheChain_Pause() public onlyOperator whenNotPaused {
    // A2_PauseTheChain_Unpause() public onlyOperator whenPaused {

    // function B1_MintWrappers_EnableProtection() public onlyOperator whenMintWrappersOn
    // function B2_MintWrappers_DisableProtection() public onlyOperator whenMintWrappersOff

    // @dev Disables the owner from interacting with enabled functions
    // function C1_OwnerPrivileges_Revoke() public onlyOperator whenOwnerPrivilegesOn
    // function C2_OwnerPrivileges_Allow() public  onlyMultiSig  whenOwnerPrivilegesOff

    // function D1_Revoke_Changes_By_The_Operator() public onlyMultiSig whenChangeByOperatorOn
    // function D2_Allow_Changes_By_The_Operator() public onlyMultiSig whenChangeByOperatorOff

    // function E1_Revoke_Changing_Rates() public onlyMultiSig whenRateChangeOn {
    // function E2_Allow_Changing_Rates() public onlyMultiSig whenRateChangeOff {
    //     _start_rate_change();
    // }

    /**
     * @dev Change the charity address, two levels of control:
     * 1) Only the operator can change the address and only when:
     * 2) The multisig authorizer has set whenRateChangeOn to true.
     * Comment out this function if you want CHARITY_ADDRESS to be static
     */
    function E3_transferCharitytAddress(address newCharityAddress)
        public
        virtual
        onlyOperator
        whenRateChangeOn
    {
        require(
            newCharityAddress != address(0),
            "transferCharityAddr:not to 0 addr"
        );
        emit CharityAddressTransferred(CHARITY_ADDRESS, newCharityAddress);
        CHARITY_ADDRESS = newCharityAddress;
    }

    /**
     * @dev Change the charity address, only allowed when multisig auth to change tax rate is true
     * Comment out this function if you want CHARITY_ADDRESS to be static
     */
    function E4_transferTaxAddress(address newTaxAddress)
        public
        virtual
        onlyOperator
        whenRateChangeOn
    {
        require(
            newTaxAddress != address(0),
            "transferTaxAddr:not to 0 address"
        );
        emit TaxAddressTransferred(TAX_ADDRESS, newTaxAddress);
        TAX_ADDRESS = newTaxAddress;
    }

    /**
     * @dev Update the charity rate.
     * Can only be called by the current operator.
     */
    function E5_updateCharityRate(uint16 _charityRate)
        public
        onlyOperator
        whenRateChangeOn
    {
        require(
            _charityRate <= 10000,
            "CharityRate: must > max rate."
        );
        emit CharityRateUpdated(msg.sender, charityRate, _charityRate);
        charityRate = _charityRate;
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function E6_updateMaxTransferAmountRate(uint16 _maxTransferAmountRate)
        public
        onlyOperator
        whenRateChangeOn
    {
        require(
            _maxTransferAmountRate <= 10000,
            "MaxTransferRate: Max < max rate."
        );
        emit MaxTransferAmountRateUpdated(
            msg.sender,
            maxTransferAmountRate,
            _maxTransferAmountRate
        );
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function E7_updateTransferTaxRate(uint16 _transferTaxRate)
        public
        onlyOperator
        whenRateChangeOn
    {
        require(
            _transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE,
            "TransferTaxRate: !< max rate."
        );
        emit TransferTaxRateUpdated(
            msg.sender,
            transferTaxRate,
            _transferTaxRate
        );
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @dev Update the min amount to liquify.
     * Can only be called by the current operator.
     */
    function E7_updateMinAmountToLiquify(uint256 _minAmount)
        public
        onlyOperator
    {
        emit MinAmountToLiquifyUpdated(
            msg.sender,
            minAmountToLiquify,
            _minAmount
        );
        minAmountToLiquify = _minAmount;
    }

    // @dev function F1_BlacklistingAddresses_TurnOff()
    // @dev function F2_BlacklistingAdresses_TurnOn()


    function F3_blacklistUpdate(address user, bool value)
        public
        virtual
        onlyOperator
        whenBlacklistOn
    {
        // require(user == _msgSender(), "Only owner is allowed to modify blacklist.");
        _blacklist[user] = value;
        emit BlacklistUpdated(user, value);
    }

   function F4_isBlacklisted(address _account) public view returns (bool) {
        return _blacklist[_account];
    }
    // function G1_Revoke_AntiWhale() public onlyMultiSig whenAntiWhaleOn {
    // function G2_Allow_AntiWhale() public onlyMultiSig whenAntiWhaleOff {


    function G3_setExcludedFromAntiWhale(address _account, bool _excluded)
        public
        onlyOperator
        whenAntiWhaleOn
    {
        _excludedFromAntiWhale[_account] = _excluded;
        emit ExcludedFromAntiWhale(_account, _excluded);
    }

    function G4_isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev G1_Revoke_AntiWhale, G2_Allow_AntiWhale, H1_ContractWrapperProtection_TurnOn,
     * H2_ContractWrapperProtection_TurnOff, I1_OperatorCanAddSpendableAddresses_TurnOff
     * I2_OperatorCanAddSpendableAddresses_TurnOn In OwnableMultiSig.sol
     */

    function I3_contractwhitelistUpdate(address _account, bool _excluded)
        public
        onlyOperator
        whenApproveSpendableAddressOn
    {
        _contractwhitelist[_account] = _excluded;
        emit ContractWhitelistUpdated(_account, _excluded);
    }

    function I4_minterRoleUpdate(address _account, bool _excluded)
        public
        onlyOperator
        whenApproveSpendableAddressOn
    {
        _minter_role_address[_account] = _excluded;
        emit MinterRoleUpdated(_account, _excluded);
    }

    // @ dev J1_MultiSig_Enable, J2_MultiSig_TurnOff in OwnableMultiSig.sol

    // @dev owner can drain tokens that are sent here by mistake
    function K1_withdrawTokensSentHere(BEP20 token, uint256 amount)
        public
        onlyOperator
    {
        emit WithdrawTokensSentHere(address(token), operator(), amount);
        token.transfer(owner(), amount);
    }

    // @dev overrides transfer function to meet tokenomics of GROGU
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
        override
        whenNotPaused
        blacklisted(sender, recipient)
        antiWhale(sender, recipient, amount)
        NoContractsOn(sender, recipient)
    {
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true &&
            _inSwapAndLiquify == false &&
            address(groguSwapRouter) != address(0) &&
            groguSwapPair != address(0) &&
            sender != groguSwapPair &&
            sender != owner()
        ) {
            swapAndLiquify();
        }
        //} else if (recipient == CHARITY_ADDRESS || transferTaxRate == 0) {
        if (charityRate > 0 && transferTaxRate == 0) {
            uint256 charityAmount = amount*(charityRate)/(10000);
            uint256 sendAmount = amount-(charityAmount);
            super._transfer(sender, CHARITY_ADDRESS, charityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        } else if (charityRate == 0 || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 0% of every transfer
            uint256 taxAmount = amount*(transferTaxRate)/(10000);
            uint256 charityAmount = taxAmount*(charityRate)/(10000);
            uint256 liquidityAmount = taxAmount-(charityAmount);
            require(
                taxAmount == charityAmount + liquidityAmount,
                "transfer: Charity val invalid"
            );

            // default 95% of transfer sent to recipient
            uint256 sendAmount = amount-(taxAmount);
            require(
                amount == sendAmount + taxAmount,
                "transfer: Tax val invalid"
            );

            super._transfer(sender, CHARITY_ADDRESS, charityAmount);
            //super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, TAX_ADDRESS, liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 _maxTransferAmount = maxTransferAmount();
        contractTokenBalance = contractTokenBalance > _maxTransferAmount
            ? _maxTransferAmount
            : contractTokenBalance;

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount/(2);
            uint256 otherHalf = liquifyAmount-(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance-(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the groguSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = groguSwapRouter.WETH();

        _approve(address(this), address(groguSwapRouter), tokenAmount);

        // make the swap
        groguSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(groguSwapRouter), tokenAmount);

        // add the liquidity
        groguSwapRouter.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

    /// destroy the contract and reclaim the leftover funds. REMOVE FOR PRODUCTION USE
    address payable admin;

    function close() public onlyOperator whenOwnerPrivilegesOn {
        // require(msg.sender == admin,"only admin can selfdestruct");
        selfdestruct(admin);
    }


    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply()*(maxTransferAmountRate)/(10000);
    }

    // To receive BNB from groguSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled)
        public
        onlyOperator
        whenRateChangeOn
    {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateGroguRouter(address _router)
        public
        onlyOperator
        whenRateChangeOn
    {
        groguSwapRouter = IUniswapV2Router02(_router);
        groguSwapPair = IUniswapV2Factory(groguSwapRouter.factory()).getPair(
            address(this),
            groguSwapRouter.WETH()
        );
        require(
            groguSwapPair != address(0),
            "Router: Invalid pair address."
        );
        emit GroguRouterUpdated(
            msg.sender,
            address(groguSwapRouter),
            groguSwapPair
        );
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "getPriorVotes:not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying GROGUs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld-(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld+(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "_writeCheckpoint: num > 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}