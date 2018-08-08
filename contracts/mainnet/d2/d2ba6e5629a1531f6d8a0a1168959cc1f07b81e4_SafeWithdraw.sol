pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface TokenContract {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract SafeWithdraw is Ownable {
  address signerAddress = 0xDD594FeD73370549607A658DfE7737C437265BBC;
  TokenContract public tkn;
  address public tokenWallet;
  mapping (bytes32 => bool) public claimed;

  constructor() public {
    tkn = TokenContract(0x92D3e963aA94D909869940A8d15FA16CcbC6655E);
    tokenWallet = 0x850Ac570A9f4817C43722938127aFa504aeb7717;
  }

  function changeWallet(address _newWallet) onlyOwner public {
    tokenWallet = _newWallet;
  }

  function changeSigner(address _newSigner) onlyOwner public {
    signerAddress = _newSigner;
  }

  function transfer(uint256 _amount, string code, bytes sig) public {
    bytes32 message = prefixed(keccak256(_amount, code));
    
    require (!claimed[message]);

    if (recoverSigner(message, sig) == signerAddress) {
      uint256 fullValue = _amount * (1 ether);
      claimed[message] = true;
      tkn.transferFrom(tokenWallet, msg.sender, fullValue);
      emit Claimed(msg.sender, fullValue);
    }
  }

  function killMe() public {
    require(msg.sender == owner);
    selfdestruct(msg.sender);
  }

  function splitSignature(bytes sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    return (v, r, s);
  }

  function recoverSigner(bytes32 message, bytes sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
    (v, r, s) = splitSignature(sig);
    return ecrecover(message, v, r, s);
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256("\x19Ethereum Signed Message:\n32", hash);
  }

  event Claimed(address _by, uint256 _amount);

}