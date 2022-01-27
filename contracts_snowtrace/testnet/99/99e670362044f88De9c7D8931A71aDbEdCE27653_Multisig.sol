// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;
pragma abicoder v2; 

//import "hardhat/console.sol";
import './IJoeRouter02.sol';
import './IERC20.sol';

// _TODO
// - make add member proposal instead of instant add 
// - await confirmation from added member
// - deposit funds + tracking ownership
// - handle proposals sent before new member joins
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

  IJoeRouter02 public joeRouter;
  address traderJoeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
  //C1 public c1;

  uint8 sigsRequired;
  uint8 totalSigners;
  uint256 proposalCounter;

  mapping(address => bool) public signer;
  // mapping(address => mapping(address => uint256)) public signerFundingInput;
  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => mapping(address => bool)) public signed;

  struct Proposal {
    address target;
    string proposalType;
    bytes payload;
    uint8 sigs;
  }

  constructor(address[] memory signers_, uint8 sigsRequired_, uint8 totalSigners_) payable {

    unchecked {
      for (uint256 i; i < signers_.length; i++) {
        signer[signers_[i]] = true;
      }
    }   
    sigsRequired = sigsRequired_;
    totalSigners = totalSigners_;
    joeRouter = IJoeRouter02(traderJoeRouter);
  }  

  // consider a block on non members, or at least a requirement to accept inputs
  function addFunds(uint256 amountIn, address tokenAddress) public payable virtual {
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountIn);
  }

  function getContractDetails() public view virtual returns(
    uint8 m, 
    uint8 n
  ){
    (m, n) = (sigsRequired, totalSigners);
  }

  function getProposal(uint256 proposal) public view virtual returns(
    address target, 
    string memory proposalType, 
    bytes memory payload, 
    uint8 sigs
  ){
    Proposal storage prop = proposals[proposal];
    (target, proposalType, payload, sigs) = (prop.target, prop.proposalType, prop.payload, prop.sigs);
  }

  function propose(
    address target, 
    //uint256[] calldata values, 
    string calldata proposalType,
    bytes calldata payload
  ) public virtual {
    //////////////// if (!signer[msg.sender]) revert NotSigner();
    //if (targets.length != values.length || values.length != payloads.length) revert NoArrayParity();
    unchecked{
    uint256 proposal = proposalCounter++; 
    proposals[proposal] = Proposal({
      target: target,
      proposalType: proposalType,
      payload: payload,
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

    if (proposals[proposal].sigs == sigsRequired){
      execute(proposal);
    }
  }

  function execute(uint proposal) public virtual {
    Proposal storage prop = proposals[proposal];
    if (prop.sigs < sigsRequired) revert InsufficientSigs();

  // Consider checking what proposals are active when adding signer to determine if they can vote
    if (keccak256(bytes(prop.proposalType)) == keccak256(bytes("member"))){
      address newMember = address(uint160(bytes20(keccak256(abi.encodePacked(prop.payload)))));
      signer[newMember]=true;
      sigsRequired++;
      totalSigners++;
      emit AddNewSigner(newMember);
    } 

    if (keccak256(bytes(prop.proposalType)) == keccak256(bytes("token"))) {
      (uint256 amountIn, uint256 amountOutMin, address[] memory path, uint256 deadline) = abi
        .decode(prop.payload, (uint256, uint256, address[], uint256));
      IERC20(path[0]).approve(traderJoeRouter, amountIn);
      joeRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    
      // TODO check result 
      //if (!success) revert ExecuteFailed();
      //flag proposal as complete
    }


    emit Execute(1);
  }

  receive() external payable virtual {}
}