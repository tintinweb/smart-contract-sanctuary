// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVesting.sol";

// Structs are used here as they do not incur any overhead, and
// make the function specifications below less tedious

struct Claim {
  uint256 amount;
  uint8 tranche;
  uint32 expiry;
  // This is simply here for reference. Solidity does not have optional params
  // and after the London fork, zero bytes are charged more in calldata, so we
  // simply leave it out of the struct and add it as an argument where it's
  // needed
  /* address optionalTarget; */
}

// ECDSA signature as struct
struct Signature {
  uint8 v; // Must be 27 or 28
  bytes32 r;
  bytes32 s; // Must be small order
}

function hash_claim (
  uint chainid,
  Claim calldata c,
  address target
) pure returns (bytes32) {
  bytes memory _msg = abi.encodePacked(chainid, c.amount, c.tranche, c.expiry);
  if (target != address(0)) {
    _msg = abi.encodePacked(_msg, target);
  }

  return keccak256(_msg);
}

contract Claim_Codes {
  // Only address able to perform management operations
  address public controller;

  // Vega vesting contract, which must have this contract registered as an
  // issuer for `issue_into_tranche` to work. Marked immutable to assist the
  // solidity compiler in inlining
  IVesting immutable trusted_vesting_contract;

  // Track committed and spent signatures (codes). The next constants are used
  // as special placeholders. Note that uninitialised slots in a map always will
  // have the default value (eg address 0x0 in this case)
  mapping (bytes32 => address) public commitments;
  address constant UNCLAIMED_CODE = address(0);
  address constant SPENT_CODE = address(1);

  // Map issuers to their max allowed spending. We may consider here whether we
  // actually care about limiting each issuer (signer) spending or not
  mapping (address => uint256) public issuers;

  // Allow list of countries that can use claim codes. Mapping uppercase ascii
  // ISO 2-letter country codes.
  mapping (bytes2 => bool) public allowed_countries;

  constructor (address vesting_address) {
    trusted_vesting_contract = IVesting(vesting_address);
    controller = msg.sender;
  }

  // To prevent front running on untargeted codes, the user can precommit to the
  // S part of the signature (ie. the one-time key)
  function commit_untargeted (bytes32 s) external {
    require(commitments[s] == UNCLAIMED_CODE);
    commitments[s] = msg.sender;
  }

  // Since solidity/web3 do not support optional arguments, we must have a
  // separate function with and without the target argument
  function claim_targeted (
    Signature calldata sig,
    Claim calldata clm,
    bytes2 country,
    address target
  ) external {
    _claim(sig, clm, target, country);
  }

  function claim_untargeted (
    Signature calldata sig,
    Claim calldata clm,
    bytes2 country
  ) external {
    _claim(sig, clm, address(0), country);
  }

  function _claim (
    Signature calldata sig,
    Claim calldata clm,
    address target,
    bytes2 country
  ) internal {
    require(clm.expiry > block.timestamp, "Claim code has expired");
    require(allowed_countries[country], "Claim code is not available in your country");

    // Verify the claim was signed by an issuer
    bytes32 hash = hash_claim(block.chainid, clm, target);
    address issuer = verify(hash, sig);
    require(issuer != address(0), "Invalid claim code");

    // Burn the claim
    target = burn_claim(sig, target);

    require(issuer != target, "Cannot claim to yourself");
    uint256 issuer_amount = issuers[issuer];
    require(clm.amount <= issuer_amount, "Out of funds");
    issuers[issuer] = issuer_amount - clm.amount;

    trusted_vesting_contract.issue_into_tranche(target, clm.tranche, clm.amount);
  }

  function allow_countries (
    bytes2[] calldata countries
  ) only_controller external {
    for (uint i = 0; i < countries.length; i++) {
      allowed_countries[countries[i]] = true;
    }
  }

  function block_countries (
    bytes2[] calldata countries
  ) only_controller external {
    for (uint i = 0; i < countries.length; i++) {
      allowed_countries[countries[i]] = false;
    }
  }

  function permit_issuer (address issuer, uint256 amount) only_controller external {
    issuers[issuer] = amount;
  }

  function revoke_issuer (address issuer) only_controller external {
    delete(issuers[issuer]);
  }

  function swap_controller(address _controller) only_controller external {
    require(_controller != address(0));
    controller = _controller;
  }

  function destroy () only_controller external {
    selfdestruct(payable(msg.sender));
  }

  // Strict ECDSA recovery;
  // - Only allow small-order s
  // - Only allow correct v encoding (27 or 28)
  function verify (
    bytes32 hash,
    Signature calldata _sig
  ) internal pure returns (address) {
    if (_sig.s > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
    return ecrecover(hash, _sig.v, bytes32(_sig.r), bytes32(_sig.s));
  }

  function burn_claim (
    Signature calldata sig,
    address target
  ) internal returns (address) {
    address _tmp = commitments[sig.s];

    // If targeted code, just check that it's unspent
    if (target != address(0)) {
      require(_tmp != SPENT_CODE, "Claim code already spent");
    }
    // If untargeted, check that it was committed or unspent
    else {
      require(_tmp == msg.sender || _tmp == UNCLAIMED_CODE, "Claim code already spent");
      target = msg.sender;
    }

    commitments[sig.s] = SPENT_CODE;
    return target;
  }

  modifier only_controller () {
    require(msg.sender == controller);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVesting {
  function issue_into_tranche (
    address user,
    uint8 tranche,
    uint256 amount
  ) external;
}

