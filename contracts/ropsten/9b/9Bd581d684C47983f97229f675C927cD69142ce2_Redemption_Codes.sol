/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.1;



interface IERC20_Vesting {
  function issue_into_tranche(address user, uint8 tranche_id, uint256 amount) external;
}

/// @title Redemption_Codes
/// @author Vega Protocol
/// @notice This contract manages the vesting of the Vega V2 ERC20 token
contract Redemption_Codes {

  event Issuer_Permitted(address indexed issuer, uint256 amount);
  event Issuer_Revoked(address indexed issuer);
  event Controller_Set(address indexed new_controller);

  /// @dev run ERC20_Vesting.permit_issuer(this contract, amount) prior to redemptions
  address public controller;
  address vesting_address;
  // nonce => has been used
  mapping(uint256 => bool) public nonces;

  /// @notice none of these parameters cannot be changed once deployed
  constructor(address _vesting_address, address _controller, bytes32 _country_list_hash){
    controller = _controller;
    vesting_address = _vesting_address;
    country_list_hash = _country_list_hash;
  }

  bytes32 country_list_hash;
  mapping(uint8 => bool) blocked_countries;
  event Country_Blocked(uint256 country_code);
  function block_country(uint8 country_code) public only_controller {
    blocked_countries[country_code] = true;
    emit Country_Blocked(country_code);
  }

  event Redeemed(bytes32 indexed message_hash);

  function redeem_targeted(bytes calldata redemption_code, uint256 denomination, uint8 tranche, uint256 expiry, uint256 nonce, uint8 country_code) public {
    require(expiry == 0 || block.timestamp <= expiry, "this code has expired");
    require(!nonces[nonce], "already redeemed");
    require(!blocked_countries[country_code], "restricted country");

    bytes32 message_hash = keccak256(abi.encode(denomination, tranche, expiry, nonce, msg.sender));
    //recover address from that msg
    bytes32 r;
    bytes32 s;
    uint8 v;

      assembly {
        // first 32 bytes, after the length prefix
       r := calldataload(redemption_code.offset)
   // second 32 bytes
       s := calldataload(add(redemption_code.offset, 32))
   // final byte (first byte of the next 32 bytes)
       v := byte(0,calldataload(add(redemption_code.offset, 64)))
      }
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Mallable signature error");

    if (v < 27) v += 27;

    address recovered_address = ecrecover(message_hash, v, r, s);
    require(recovered_address != address(0), "bad redemption code");
    require(recovered_address != msg.sender, "cannot issue to self");
    if(permitted_issuance[recovered_address] > 0){
      /// @dev if code gets here, they are an issuer if not they must be the controller
      require(permitted_issuance[recovered_address] >= denomination, "not enough permitted balance");
      permitted_issuance[recovered_address] -= denomination;
    } else {
      require(recovered_address == controller, "unauthorized issuer");
    }

    nonces[nonce] = true;
    IERC20_Vesting(vesting_address).issue_into_tranche(msg.sender, tranche, denomination);
    emit Redeemed(message_hash);
  }

  function get_code_hash(bytes memory redemption_code) public view returns (bytes32){
    return keccak256(abi.encode(redemption_code, msg.sender));
  }

  mapping(bytes32 => bool) public commits;
  function commit_untargeted_code(bytes32 hash) public {
    commits[hash] = true;
  }

  function redeem_untargeted_code(bytes calldata redemption_code, uint256 denomination, uint8 tranche, uint256 expiry, uint256 nonce, uint8 country_code) public {
    /// @dev, must run commit_untargeted_code first
    require(expiry == 0 || block.timestamp <= expiry, "this code has expired");
    require(!nonces[nonce], "already redeemed");
    require(!blocked_countries[country_code], "restricted country");

    bytes32 message_hash = keccak256(abi.encode(denomination, tranche, expiry, nonce));
    bytes32 commit_msg = keccak256(abi.encode(redemption_code, msg.sender));
    require(commits[commit_msg], "code has not been commited");

    //recover address from that msg
    bytes32 r;
    bytes32 s;
    uint8 v;

      assembly {
        // first 32 bytes, after the length prefix
       r := calldataload(redemption_code.offset)
   // second 32 bytes
       s := calldataload(add(redemption_code.offset, 32))
   // final byte (first byte of the next 32 bytes)
       v := byte(0,calldataload(add(redemption_code.offset, 64)))
      }
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Mallable signature error");

    if (v < 27) v += 27;

    address recovered_address = ecrecover(message_hash, v, r, s);
    require(recovered_address != address(0), "bad redemption code");
    require(recovered_address != msg.sender, "cannot issue to self");
    if(permitted_issuance[recovered_address] > 0){
      /// @dev if code gets here, they are an issuer if not they must be the controller
      require(permitted_issuance[recovered_address] >= denomination, "not enough permitted balance");
      permitted_issuance[recovered_address] -= denomination;
    } else {
      require(recovered_address == controller, "unauthorized issuer");
    }
    delete(commits[commit_msg]);
    nonces[nonce] = true;
    IERC20_Vesting(vesting_address).issue_into_tranche(msg.sender, tranche, denomination);
    emit Redeemed(message_hash);
  }

  /// @notice issuer address => permitted issuance allowance
  mapping(address => uint256) public permitted_issuance;

  /// @notice This function allows the controller to permit the given address to issue the given Amount
  /// @notice Target users MUST have a zero (0) permitted issuance balance (try revoke_issuer)
  /// @dev emits Issuer_Permitted event
  /// @param issuer Target address to be allowed to issue given amount
  /// @param amount Number of tokens issuer is permitted to issue
  function permit_issuer(address issuer, uint256 amount) public only_controller {
    /// @notice revoke is required first to stop a simple double allowance attack
    require(amount > 0, "amount must be > 0");
    require(permitted_issuance[issuer] == 0, "issuer already permitted, revoke first");
    require(controller != issuer, "controller cannot be permitted issuer");
    permitted_issuance[issuer] = amount;
    emit Issuer_Permitted(issuer, amount);
  }

  /// @notice This function allows the controller to revoke issuance permission from given target
  /// @notice permitted_issuance must be greater than zero (0)
  /// @dev emits Issuer_Revoked event
  /// @param issuer Target address of issuer to be revoked
  function revoke_issuer(address issuer) public only_controller {
    require(permitted_issuance[issuer] != 0, "issuer already revoked");
    permitted_issuance[issuer] = 0;
    emit Issuer_Revoked(issuer);
  }
  modifier only_controller {
         require( msg.sender == controller, "not controller" );
         _;
  }

  /// @notice This function allows the controller to assign a new controller
  /// @dev Emits Controller_Set event
  /// @param new_controller Address of the new controller
  function set_controller(address new_controller) public only_controller {
    controller = new_controller;
    permitted_issuance[new_controller] = 0;
    emit Controller_Set(new_controller);
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