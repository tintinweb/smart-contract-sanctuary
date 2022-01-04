pragma solidity 0.8.11;
import "./Wallet.sol";

contract ExampleVerifier {
  event Deployed(address addr, uint256 salt);

  // This wouldn't actually happen on chain - this would instead use sourcify
  // to get the creationCode and constructor ABI of a verified contract.
  function javascript_getBytecode(address verified_contract)
    private
    pure
    returns (bytes memory)
  {
    // lookup verified_contract. Lets pretend its Wallet
    return type(Wallet).creationCode;
  }

  // Again, this wouldn't actually happen on chain -
  // from the found constructor ABI, show appropriate UI (two address fields in this example),
  // encode the args
  function javascript_getInitCodeFromConstructorArgs(
    address owner,
    address admin
  ) private pure returns (bytes memory) {
    bytes memory bytecode = javascript_getBytecode(address(0));
    return abi.encodePacked(bytecode, abi.encode(owner), abi.encode(admin));
  }

  function javascript_getCounterFactualAddress(
    /* address sender, */
    // doesn't need to be this, could be the users own address
    uint256 _salt,
    address owner,
    address admin
  ) public view returns (address) {
    bytes memory bytecode = javascript_getInitCodeFromConstructorArgs(
      owner,
      admin
    );
    return getAddress(bytecode, _salt);
  }

  function getAddress(bytes memory bytecode, uint256 _salt)
    private
    view
    returns (address)
  {
    address sender = address(this); // could instead come from args
    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), sender, _salt, keccak256(bytecode))
    );

    return address(uint160(uint256(hash)));
  }

  function deploy(bytes memory bytecode, uint256 _salt) public payable {
    address addr;

    assembly {
      addr := create2(
        callvalue(), // wei sent with current call
        // Actual code starts after skipping the first 32 bytes
        add(bytecode, 0x20),
        mload(bytecode), // Load the size of code contained in the first 32 bytes
        _salt // Salt from function arguments
      )

      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    emit Deployed(addr, _salt);
  }

  function deployWalletExample(
    uint256 _salt,
    address owner,
    address admin
  ) public payable {
    bytes memory bytecode = javascript_getInitCodeFromConstructorArgs(
      owner,
      admin
    );
    deploy(bytecode, _salt);
  }
}

pragma solidity 0.8.11;

contract Wallet {
  address payable public owner;
  address public admin;

  constructor(address payable _owner, address _admin) {
    owner = _owner;
    admin = _admin;
  }

  function withdraw() public {
    require(msg.sender == owner || msg.sender == admin, "Not permitted");
    owner.transfer(address(this).balance);
  }
}