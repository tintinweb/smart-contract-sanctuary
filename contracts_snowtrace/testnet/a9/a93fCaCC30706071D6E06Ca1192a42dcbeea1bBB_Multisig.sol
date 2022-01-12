// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;
pragma abicoder v2; 

//import "hardhat/console.sol";
import './IJoeRouter02.sol';

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

  IJoeRouter02 private joeRouter;

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
    address joeAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    joeRouter = IJoeRouter02(joeAddress);
  }

  // function updateSwapRouterAddress(address swapRouterAddress) public onlyOwner {
  //     joeRouter = IJoeRouter02("0x60ae616a2155ee3d9a68541ba4544862310933d4");
  // }

  function testSwap() public virtual {
      address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
      address DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
      address[] memory path = new address[](2);
     // path.push(WAVAX);
      //path.push(DAI);
      path[0]=WAVAX;
      path[0]=DAI;
      joeRouter.swapExactAVAXForTokens{value: address(this).balance}
          (0, // FIXME
            path,
            address(this),
            block.timestamp);
  }

  function addFunds(address[] memory fundingMembers, uint256 amount) public payable virtual {
    // function to add funds to the wallet
    // consider a block on non members, or at least a requirement to accept
  }

  // Consider checking what proposals are active when adding signer to determine if they can vote
  function addNewSigner(address newSigner) public virtual {
   if (!signer[msg.sender]) revert NotSigner();
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
    //////////////// if (!signer[msg.sender]) revert NotSigner();
    if (targets.length != values.length || values.length != payloads.length) revert NoArrayParity();

    // console.logString("proposal________");
    // console.logAddress(targets[0]);
    // console.logUint(values[0]);
    // console.logBytes(payloads[0]);
    // console.logString("________");

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

    //////// RE ADD THIS
    // if (prop.sigs < sigsRequired) revert InsufficientSigs();

    // cannot realistically overflow on human timescales
    unchecked {
      for (uint256 i; i < prop.targets.length; i++) {
        
        // console.logString("execute proposal________");
        // console.logAddress(prop.targets[i]);
        // console.logUint(prop.values[i]);
        // console.logBytes(prop.payloads[i]);
        // console.logString("________");


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