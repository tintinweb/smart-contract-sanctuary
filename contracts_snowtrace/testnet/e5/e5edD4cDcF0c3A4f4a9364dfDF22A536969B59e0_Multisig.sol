/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

// _TODO
// - consider change of word "signer" to "member" for clarity
// - make add member proposal instead of instant add 
// - await confirmation from added member
// - deposit funds 
// - handle proposals send before new member joins
// - exit group 

/// @notice Simple gas-optimized multi-signature contract.
contract Multisig {
  event Propose(address indexed proposer, uint256 indexed proposal);
  event Sign(address indexed signer, uint256 indexed proposal);
  event Execute(uint256 indexed proposal);
  event AddNewSigner(address signer);

  error NoArrayParity();
  error NotSigner();
  error Signed();
  error InsufficientSigs();
  error ExecuteFailed();

  //address[] fundingMembers;

  uint8 sigsRequired;
  uint256 proposalCounter;
  //uint256 amount;

  mapping(address => bool) public signer;
  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => mapping(address => bool)) public signed;

  struct Proposal {
    address[] targets;
    uint256[] values;
    bytes[] payloads;
    uint8 sigs;
  }

  constructor(address[] memory signers_, uint8 sigsRequired_) {
    // cannot realistically overflow on human timescales
    unchecked {
      for (uint256 i; i < signers_.length; i++) {
        signer[signers_[i]] = true;
      }
    }   
    sigsRequired = sigsRequired_;
  }

  function addFunds(address[] memory fundingMembers, uint256 amount) public payable virtual {
    // function to add funds to the wallet
    // consider a block on non members, or at least a requirement to accept
  }

  // Consider checking what proposals are active when adding signer to determine if they can vote
  function addNewSigner(address newSigner) public virtual {
   signer[newSigner]=true;
   emit AddNewSigner(newSigner);
  }

  function getProposal(uint256 proposal) public view virtual returns 
    (  address[] memory targets, 
      uint256[] memory values, 
      bytes[] memory payloads, 
      uint8 sigs
    ) 
  {
    Proposal storage prop = proposals[proposal];

    (targets, values, payloads, sigs) = (prop.targets, prop.values, prop.payloads, prop.sigs);
  }

  function propose(
    address[] calldata targets, 
    uint256[] calldata values, 
    bytes[] calldata payloads
  ) public virtual {
    if (!signer[msg.sender]) revert NotSigner();
    if (targets.length != values.length || values.length != payloads.length) revert NoArrayParity();

    // cannot realistically overflow on human timescales
    unchecked {
      uint256 proposal = proposalCounter++;

      proposals[proposal] = Proposal({
        targets: targets,
        values: values,
        payloads: payloads,
        sigs: 0
      });

      emit Propose(msg.sender, proposal);
    }
  }

  // may be possible to take signing off chain and only submit the result
  function sign(uint256 proposal) public virtual {
    if (!signer[msg.sender]) revert NotSigner();
    if (signed[proposal][msg.sender]) revert Signed();
    
    // cannot realistically overflow on human timescales
    unchecked {
      proposals[proposal].sigs++;
    }

    signed[proposal][msg.sender] = true;

    emit Sign(msg.sender, proposal);
  }

  function execute(uint256 proposal) public virtual {
    Proposal storage prop = proposals[proposal];

    if (prop.sigs < sigsRequired) revert InsufficientSigs();

    // cannot realistically overflow on human timescales
    unchecked {
      for (uint256 i; i < prop.targets.length; i++) {
        (bool success, ) = prop.targets[i].call{value: prop.values[i]}(prop.payloads[i]);

        if (!success) revert ExecuteFailed();
      }
    }

    delete proposals[proposal];

    emit Execute(proposal);
  }

  function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
    results = new bytes[](data.length);
    
    // cannot realistically overflow on human timescales
    unchecked {
      for (uint256 i = 0; i < data.length; i++) {
        (bool success, bytes memory result) = address(this).delegatecall(data[i]);

        if (!success) {
          if (result.length < 68) revert();
          
          assembly {
            result := add(result, 0x04)
          }
          
          revert(abi.decode(result, (string)));
        }
        results[i] = result;
      }
    }
  }

  receive() external payable virtual {}
}