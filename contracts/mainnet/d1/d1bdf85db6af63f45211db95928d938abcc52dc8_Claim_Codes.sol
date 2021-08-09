/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20_Vesting {
  /// @notice this function allows the conroller or permitted issuer to issue tokens from this contract itself (no tranches) into the specified tranche
  function issue_into_tranche(address user, uint8 tranche_id, uint256 amount) external;
}

/// @title Claim_Codes
/// @author Vega Protocol
/// @notice This contract manages claim code redeption and issue limits
/// @dev run ERC20_Vesting.permit_issuer(this contract, amount) prior to claims
contract Claim_Codes {

  event Issuer_Permitted(address indexed issuer, uint256 amount);
  event Issuer_Revoked(address indexed issuer);
  event Controller_Set(address indexed new_controller);
  event Claimed(bytes32 indexed message_hash);

  /// @notice this is the address of the 'owner' of this contract. Only the controller can permit_issuer
  address public controller;
  /// @notice this is the address of the ERC20_Vesting smart contract whos issue_into_tranche command this contract calls
  address public vesting_address;
  /// @notice nonce => has been used
  mapping(uint256 => bool) public nonces;
  /// @notice 2 char ISO country codes ASCII to hex string (like 0x12Af) => is allowed country
  mapping(bytes2 => bool) public allowed_countries;
  /// @notice this is a mapping of all of the commited, but unclaimed untargeted claim codes
  /// @notice the bytes32 hash is: keccak256(abi.encode(claim_code, claimer))
  mapping(bytes32 => bool) public commits;
  /// @notice issuer address => permitted issuance allowance
  mapping(address => uint256) public permitted_issuance;

  /// @param _vesting_address The target ERC20_Vesting contract
  /// @param _controller address of the 'admin' of this contract
  /// @notice _vesting_address cannot be changed once deployed
  constructor(address _vesting_address, address _controller){
    controller = _controller;
    vesting_address = _vesting_address;
    emit Controller_Set(_controller);
  }

  /// @notice this function removes the provided country codes from list of allowed countries
  /// @param country_codes Array of 2 char ISO country codes ASCII to hex string (like 0x12Af) that will be blocked
  function block_countries(bytes2[] calldata country_codes) public only_controller {
    for (uint256 i = 0; i < country_codes.length; i++) {
      allowed_countries[country_codes[i]] = false;
    }
  }

  /// @notice this function adds the provided country codes to list of allowed countries
  /// @param country_codes Array of 2 char ISO country codes ASCII to hex string (like 0x12Af) that will be allowed
  function allow_countries(bytes2[] calldata country_codes) public only_controller {
    for (uint256 i = 0; i < country_codes.length; i++) {
      allowed_countries[country_codes[i]] = true;
    }
  }

  function verify_signature(bytes calldata claim_code, bytes32 message_hash) internal pure returns(address) {
    //recover address from that msg
    bytes32 r;
    bytes32 s;
    uint8 v;

      assembly {
        // first 32 bytes, after the length prefix
       r := calldataload(claim_code.offset)
       // second 32 bytes
       s := calldataload(add(claim_code.offset, 32))
       // final byte (first byte of the next 32 bytes)
       v := byte(0,calldataload(add(claim_code.offset, 64)))
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

    return ecrecover(message_hash, v, r, s);
  }

  /// @notice this function redeems claim codes that have been issued to a specific Ethereum address
  /// @notice this function verifies that the claim code and provided params are correct, then issues 'denomination' amount of tokens into provided tranche
  /// @notice this function calls ERC20_Vesting.issue_into_tranche
  /// @notice code issuer must have permitted_issuance balance >= denomination
  /// @notice only the targeted address encoded into the claim_code can run this function
  /// @param claim_code this is the signed hash: keccak256(abi.encode(denomination, tranche, expiry, nonce, target))
  /// @param denomination amount of tokens to be claimed
  /// @param tranche the tranche_id of tranche into which the tokens will be issued
  /// @param expiry expiration unix timestap (in seconds) of the code being claimed
  /// @param nonce the unique randomly generated number of the code being claimed
  /// @param country_code the 2 char ISO country code ASCII to hex string (like 0x12Af) of the claimer
  /// @notice Crimea is excluded from both Russia and Ukraine for the purpose of processing claim codes, the substitute ISO code for Crimera region is "RC"
  function redeem_targeted(bytes calldata claim_code, uint256 denomination, uint8 tranche, uint256 expiry, uint256 nonce, bytes2 country_code) public {
    require(expiry == 0 || block.timestamp <= expiry, "this code has expired");
    require(!nonces[nonce], "already redeemed");
    require(allowed_countries[country_code], "restricted country");

    bytes32 message_hash = keccak256(abi.encode(denomination, tranche, expiry, nonce, msg.sender));

    address recovered_address = verify_signature(claim_code, message_hash);
    require(recovered_address != address(0), "bad claim code");
    require(recovered_address != msg.sender, "cannot issue to self");
    if(permitted_issuance[recovered_address] > 0){
      /// @dev if code gets here, they are an issuer if not they must be the controller to continue
      require(permitted_issuance[recovered_address] >= denomination, "not enough permitted balance");
      permitted_issuance[recovered_address] -= denomination;
    } else {
      require(recovered_address == controller, "unauthorized issuer");
    }

    nonces[nonce] = true;
    IERC20_Vesting(vesting_address).issue_into_tranche(msg.sender, tranche, denomination);
    emit Claimed(message_hash);
  }

  /// @notice this function returns the hash of the claim_code + the address of the wallet that runs this.
  /// @notice the hash generated by this fucntion is the expected hash for commit_untargeted_code
  /// @param claim_code the untargeted claim code which is the signed hash: keccak256(abi.encode(denomination, tranche, expiry, nonce))
  function get_code_hash(bytes memory claim_code) public view returns (bytes32){
    return keccak256(abi.encode(claim_code, msg.sender));
  }

  /// @notice this function is the commit step of the commit/reveal procedure to prevent frontrunning of untargeted claim codes
  /// @param hash this is the hash of the claim_code mixed with the claimer's address: keccak256(abi.encode(claim_code, claimer_address))
  /// @notice this step MUST be completed before redeem_untargeted_code will work, otherwise the claimer will recieve the error: "code has not been commited"
  function commit_untargeted_code(bytes32 hash) public {
    commits[hash] = true;
  }

  /// @notice this function redeems untargeted claim codes to the address that runs it
  /// @notice this function verifies that the claim code and provided params are correct, then issues 'denomination' amount of tokens into provided tranche
  /// @notice this function calls ERC20_Vesting.issue_into_tranche
  /// @notice code issuer must have permitted_issuance balance >= denomination
  /// @notice claimer MUST run commit_untargeted_code first
  /// @param claim_code this is the signed hash: keccak256(abi.encode(denomination, tranche, expiry, nonce, target))
  /// @param denomination amount of tokens to be claimed
  /// @param tranche the tranche_id of tranche into which the tokens will be issued
  /// @param expiry expiration unix timestap (in seconds) of the code being claimed
  /// @param nonce the unique randomly generated number of the code being claimed
  /// @param country_code the 2 char ISO country code ASCII to hex string (like 0x12Af) of the claimer
  /// @notice Crimea is excluded from both Russia and Ukraine for the purpose of processing claim codes, the substitute ISO code for Crimera region is "RC"
  function redeem_untargeted_code(bytes calldata claim_code, uint256 denomination, uint8 tranche, uint256 expiry, uint256 nonce, bytes2 country_code) public {
    require(expiry == 0 || block.timestamp <= expiry, "this code has expired");
    require(!nonces[nonce], "already redeemed");
    require(allowed_countries[country_code], "restricted country");

    bytes32 message_hash = keccak256(abi.encode(denomination, tranche, expiry, nonce));
    bytes32 commit_msg = keccak256(abi.encode(claim_code, msg.sender));
    require(commits[commit_msg], "code has not been commited");

    address recovered_address = verify_signature(claim_code, message_hash);
    require(recovered_address != address(0), "bad claim code");
    require(recovered_address != msg.sender, "cannot issue to self");
    if(permitted_issuance[recovered_address] > 0){
      /// @dev if code gets here, they are an issuer if not they must be the controller to continue
      require(permitted_issuance[recovered_address] >= denomination, "not enough permitted balance");
      permitted_issuance[recovered_address] -= denomination;
    } else {
      require(recovered_address == controller, "unauthorized issuer");
    }
    delete(commits[commit_msg]);
    nonces[nonce] = true;
    IERC20_Vesting(vesting_address).issue_into_tranche(msg.sender, tranche, denomination);
    emit Claimed(message_hash);
  }

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

  /// @notice This function allows the controller to assign a new controller
  /// @dev Emits Controller_Set event
  /// @param new_controller Address of the new controller
  function set_controller(address new_controller) public only_controller {
    controller = new_controller;
    permitted_issuance[new_controller] = 0;
    emit Controller_Set(new_controller);
  }

  modifier only_controller {
         require( msg.sender == controller, "not controller" );
         _;
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