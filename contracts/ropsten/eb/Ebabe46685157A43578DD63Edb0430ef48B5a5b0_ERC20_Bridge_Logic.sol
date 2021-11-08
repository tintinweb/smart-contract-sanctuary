//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC20_Bridge_Logic.sol";
import "./IMultisigControl.sol";
import "./ERC20_Asset_Pool.sol";

/// @title ERC20 Bridge Logic
/// @author Vega Protocol
/// @notice This contract is used by Vega network users to deposit and withdraw ERC20 tokens to/from Vega.
// @notice All funds deposited/withdrawn are to/from the assigned ERC20_Asset_Pool
contract ERC20_Bridge_Logic is IERC20_Bridge_Logic {

    //stops overflow
    using SafeMath for uint256;

    address multisig_control_address;
    address erc20_asset_pool_address;
    // asset address => is listed
    mapping(address => bool) listed_tokens;
    // asset address => minimum deposit amt
    mapping(address => uint256) minimum_deposits;
    // asset address => maximum deposit amt
    mapping(address => uint256) maximum_deposits;
    // Vega asset ID => asset_source
    mapping(bytes32 => address) vega_asset_ids_to_source;
    // asset_source => Vega asset ID
    mapping(address => bytes32) asset_source_to_vega_asset_id;

    /// @param erc20_asset_pool Initial Asset Pool contract address
    /// @param multisig_control Initial MultisigControl contract address
    constructor(address erc20_asset_pool, address multisig_control) {
        erc20_asset_pool_address = erc20_asset_pool;
        multisig_control_address = multisig_control;
    }

    /***************************FUNCTIONS*************************/
    /// @notice This function lists the given ERC20 token contract as valid for deposit to this bridge
    /// @param asset_source Contract address for given ERC20 token
    /// @param vega_asset_id Vega-generated asset ID for internal use in Vega Core
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Listed if successful
    function list_asset(address asset_source, bytes32 vega_asset_id, uint256 nonce, bytes memory signatures) public override {
        require(!listed_tokens[asset_source], "asset already listed");
        bytes memory message = abi.encode(asset_source, vega_asset_id, nonce, 'list_asset');
        require(IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce), "bad signatures");
        listed_tokens[asset_source] = true;
        vega_asset_ids_to_source[vega_asset_id] = asset_source;
        asset_source_to_vega_asset_id[asset_source] = vega_asset_id;
        emit Asset_Listed(asset_source, vega_asset_id, nonce);
    }

    /// @notice This function removes from listing the given ERC20 token contract. This marks the token as invalid for deposit to this bridge
    /// @param asset_source Contract address for given ERC20 token
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Removed if successful
    function remove_asset(address asset_source, uint256 nonce, bytes memory signatures) public override {
        require(listed_tokens[asset_source], "asset not listed");
        bytes memory message = abi.encode(asset_source, nonce, 'remove_asset');
        require(IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce), "bad signatures");
        listed_tokens[asset_source] = false;
        emit Asset_Removed(asset_source, nonce);
    }

    /// @notice This function sets the minimum allowable deposit for the given ERC20 token
    /// @param asset_source Contract address for given ERC20 token
    /// @param minimum_amount Minimum deposit amount
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Deposit_Minimum_Set if successful
    function set_deposit_minimum(address asset_source, uint256 minimum_amount, uint256 nonce, bytes memory signatures) public override{
        require(listed_tokens[asset_source], "asset not listed");
        bytes memory message = abi.encode(asset_source, minimum_amount, nonce, 'set_deposit_minimum');
        require(IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce), "bad signatures");
        minimum_deposits[asset_source] = minimum_amount;
        emit Asset_Deposit_Minimum_Set(asset_source, minimum_amount, nonce);
    }

    /// @notice This function sets the maximum allowable deposit for the given ERC20 token
    /// @param asset_source Contract address for given ERC20 token
    /// @param maximum_amount Maximum deposit amount
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Deposit_Maximum_Set if successful
    function set_deposit_maximum(address asset_source, uint256 maximum_amount, uint256 nonce, bytes memory signatures) public override {
        require(listed_tokens[asset_source], "asset not listed");
        bytes memory message = abi.encode(asset_source, maximum_amount, nonce, 'set_deposit_maximum');
        require(IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce), "bad signatures");
        maximum_deposits[asset_source] = maximum_amount;
        emit Asset_Deposit_Maximum_Set(asset_source, maximum_amount, nonce);
    }

    /// @notice This function withdrawals assets to the target Ethereum address
    /// @param asset_source Contract address for given ERC20 token
    /// @param amount Amount of ERC20 tokens to withdraw
    /// @param expiry Vega-assigned timestamp of withdrawal order expiration
    /// @param target Target Ethereum address to receive withdrawn ERC20 tokens
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Withdrawn if successful
    function withdraw_asset(address asset_source, uint256 amount, uint256 expiry, address target, uint256 nonce, bytes memory signatures) public  override{
        require(expiry > block.timestamp, "withdrawal has expired");
        bytes memory message = abi.encode(asset_source, amount, expiry, target,  nonce, 'withdraw_asset');
        require(IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce), "bad signatures");
        require(ERC20_Asset_Pool(erc20_asset_pool_address).withdraw(asset_source, target, amount), "token didn't transfer, rejected by asset pool.");
        emit Asset_Withdrawn(target, asset_source, amount, nonce);
    }

    /// @notice This function allows a user to deposit given ERC20 tokens into Vega
    /// @param asset_source Contract address for given ERC20 token
    /// @param amount Amount of tokens to be deposited into Vega
    /// @param vega_public_key Target Vega public key to be credited with this deposit
    /// @dev MUST emit Asset_Deposited if successful
    /// @dev ERC20 approve function should be run before running this
    /// @notice ERC20 approve function should be run before running this
    function deposit_asset(address asset_source, uint256 amount, bytes32 vega_public_key) public override {
        require(listed_tokens[asset_source], "asset not listed");
        //User must run approve before deposit
        require(maximum_deposits[asset_source] == 0 || amount <= maximum_deposits[asset_source], "deposit above maximum");
        require(amount >= minimum_deposits[asset_source], "deposit below minimum");
        require(IERC20(asset_source).transferFrom(msg.sender, erc20_asset_pool_address, amount), "transfer failed in deposit");
        emit Asset_Deposited(msg.sender, asset_source, amount, vega_public_key);
    }

    /***************************VIEWS*****************************/
    /// @notice This view returns true if the given ERC20 token contract has been listed valid for deposit
    /// @param asset_source Contract address for given ERC20 token
    /// @return True if asset is listed
    function is_asset_listed(address asset_source) public override view returns(bool){
        return listed_tokens[asset_source];
    }

    /// @notice This view returns minimum valid deposit
    /// @param asset_source Contract address for given ERC20 token
    /// @return Minimum valid deposit of given ERC20 token
    function get_deposit_minimum(address asset_source) public override view returns(uint256){
        return minimum_deposits[asset_source];
    }

    /// @notice This view returns maximum valid deposit
    /// @param asset_source Contract address for given ERC20 token
    /// @return Maximum valid deposit of given ERC20 token
    function get_deposit_maximum(address asset_source) public override view returns(uint256){
        return maximum_deposits[asset_source];
    }

    /// @return current multisig_control_address
    function get_multisig_control_address() public override view returns(address) {
        return multisig_control_address;
    }

    /// @param asset_source Contract address for given ERC20 token
    /// @return The assigned Vega Asset Id for given ERC20 token
    function get_vega_asset_id(address asset_source) public override view returns(bytes32){
        return asset_source_to_vega_asset_id[asset_source];
    }

    /// @param vega_asset_id Vega-assigned asset ID for which you want the ERC20 token address
    /// @return The ERC20 token contract address for a given Vega Asset Id
    function get_asset_source(bytes32 vega_asset_id) public override view returns(address){
        return vega_asset_ids_to_source[vega_asset_id];
    }
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/