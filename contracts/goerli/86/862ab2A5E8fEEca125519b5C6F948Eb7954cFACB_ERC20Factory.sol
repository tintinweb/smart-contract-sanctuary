// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Lib.sol";


/// @title MinimalProxy Factory
/// @author coinstructor.io
/// @dev Refer to https://eips.ethereum.org/EIPS/eip-1167 for details
/// @notice The Factory contract creates Minimal Proxies using EIP1167,
/// @notice which point to ERC20 contracts implementation, this saving on gas
contract ERC20Factory {
  // Service fee for each MinimalProxy creation
  uint256 constant serviceFee = 50000000000000000; // 0.05 ETH

  // The owner of the contract, who receives the funds
  address payable immutable public owner;

  address immutable public signer;
  bool public requireSigned;

  /// @notice Event will be emitted every time a new ERC20 MinimalProxy is created
  /// @param newERC20Address is an address of the newly created ERC20 token MinimalProxy
  event ERC20Created(address newERC20Address);

  // EIP712 niceties
  bytes32 public DOMAIN_SEPARATOR;

  string public constant version = "1";

  constructor(address payable _owner, address _signer) {
    owner = _owner;
    signer = _signer;
    uint256 chainId = 0;
    assembly {
        chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("ERC20Factory")),
        keccak256(bytes(version)),
        1, //chainId,
        address(this)
    ));
  }

  /// @notice Creates a MinimalProxy contract via EIP1167 assembly code
  /// @dev Using this implementation: https://github.com/optionality/clone-factory
  /// @param target is an address of implementation, to which the MinimalProxy will point to
  /// @return result is an address of a newly created MinimalProxy
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  /// @notice Tests if MinimalProxy instance really points to the correct implementation
  /// @param target is an address of implementation, to which the MinimalProxy should point to
  /// @param query is an address of MinimalProxy that needs to be tested
  /// @return result is true if MinimalProxy really points to the implementation address
  function isClone(address target, address query) external view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }

  /// @notice Pays out all Factory ETH balance to owners address
  function payout() external {
    require(owner.send(address(this).balance));
  }

  /// @notice Pays out all Factory ERC20 token balance to owners address
  /// @param _tokenAddress is an address of the ERC20 token to payout
  function payoutToken(address _tokenAddress) external {
    IERC20Lib token = IERC20Lib(_tokenAddress);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "Nothing to payout");
    token.transfer(owner, amount);
  }

  /// @notice Creates and initializes the ERC20 MinimalProxy contract
  /// @param libraryAddress_ is an address of implementation, to which the MinimalProxy should point to
  /// @param name_ is the ERC20 token name
  /// @param symbol_ is the ERC20 token symbol
  /// @param totalSupply_ is the ERC20 token totalSupply that will be minted to msg.sender
  function createERC20(address libraryAddress_, string memory name_, string memory symbol_, uint256 totalSupply_) payable external {
    // The service fee should be paid when calling this function
    require(msg.value >= serviceFee, "Service Fee of 0.05ETH wasn't paid");
    address clone = createClone(libraryAddress_);
    IERC20Lib(clone).init(msg.sender, name_, symbol_, totalSupply_);
    emit ERC20Created(clone);
  }

  /// @notice Creates and initializes the ERC20 MinimalProxy contract
  /// @param libraryAddress_ is an address of implementation, to which the MinimalProxy should point to
  /// @param name_ is the ERC20 token name
  /// @param symbol_ is the ERC20 token symbol
  /// @param totalSupply_ is the ERC20 token totalSupply that will be minted to msg.sender
  /// @param referral_ is the referral, who will receive 0.01 ETH from the deployment
  function createERC20WithReferral(address libraryAddress_, string memory name_, string memory symbol_, uint256 totalSupply_, address payable referral_) payable external {
    // The service fee should be paid when calling this function
    require(msg.value >= serviceFee, "Service Fee of 0.05ETH wasn't paid");
    require(requireSigned == false, "Only Signed referrals are allowed");
    address clone = createClone(libraryAddress_);
    IERC20Lib(clone).init(msg.sender, name_, symbol_, totalSupply_);
    emit ERC20Created(clone);

    // Referral must accept money, otherwise he will not be paid (saves gas and eliminates security risks)
    referral_.send(0.01 ether);
  }

  /// @notice Restricts referral creation to be signed by the service
  /// @param requireSigned_ true if signature is required
  function setRequireSigned(bool requireSigned_) external {
    require(msg.sender == signer);
    requireSigned = requireSigned_;
  }

  bytes32 public constant PERMIT_TYPEHASH = keccak256("createERC20WithReferralSigned(address libraryAddress,string name,string symbol,uint256 totalSupply,address referral)");

  /// @notice Creates and initializes the ERC20 MinimalProxy contract using a referral link and signatures
  /// @param libraryAddress_ is an address of implementation, to which the MinimalProxy should point to
  /// @param name_ is the ERC20 token name
  /// @param symbol_ is the ERC20 token symbol
  /// @param totalSupply_ is the ERC20 token totalSupply that will be minted to msg.sender
  /// @param referral_ is the referral, who will receive 0.01 ETH from the deployment
  /// @param v_ A final byte of signature (ECDSA component)
  /// @param r_ The first 32 bytes of signature (ECDSA component)
  /// @param s_ The second 32 bytes of signature (ECDSA component)
  function createERC20WithReferralSigned(address libraryAddress_,
                                   string memory name_,
                                   string memory symbol_,
                                   uint256 totalSupply_,
                                   address payable referral_,
                                   uint8 v_,
                                   bytes32 r_,
                                   bytes32 s_) payable external {
    // The service fee should be paid when calling this function
    require(msg.value >= serviceFee, "Service Fee of 0.05ETH wasn't paid");

    bytes32 digest = keccak256(abi.encodePacked(
                                "\x19\x01",
                                DOMAIN_SEPARATOR,
                                keccak256(abi.encode(
                                  PERMIT_TYPEHASH,
                                  libraryAddress_,
                                  keccak256(bytes(name_)),
                                  keccak256(bytes(symbol_)),
                                  totalSupply_,
                                  referral_
                                ))
                              ));
    
    require(signer == ecrecover(digest, v_, r_, s_), "invalid signature or parameters");

    address clone = createClone(libraryAddress_);
    IERC20Lib(clone).init(msg.sender, name_, symbol_, totalSupply_);

    emit ERC20Created(clone);

    // Referral must accept money, otherwise he will not be paid (saves gas and eliminates security risks)
    referral_.send(0.01 ether);
  }
}