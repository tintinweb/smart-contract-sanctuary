pragma solidity ^0.8.0;
//SPDX-License-Identifier:MIT

import "./IToken.sol";
import "./IERC20.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BridgeEth {

  address public admin;
  IToken public token;
  IERC20 public token_;
  bool private initialized;
  mapping(address => mapping(uint => bool)) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature,
    Step indexed step
  );

  event OwnershipTransferred(address indexed _from, address indexed _to);

  // constructor(address _token) {
  //   admin = msg.sender;
  //   token = IToken(_token);
  // }

  function initialize(address _token) public{
    require(!initialized, "Initializable: contract is already initialized");
    admin = msg.sender;
    token = IToken(_token);
    token_ = IERC20(_token);
  }

   // transfer Ownership to other address
  function transferOwnership(address _newOwner) public {
      require(_newOwner != address(0x0));
      require(msg.sender == admin);
      emit OwnershipTransferred(admin,_newOwner);
      admin = _newOwner;
  }
    
  // transfer Ownership to other address
  function transferTokenOwnership(address _newOwner) public {
      require(_newOwner != address(0x0));
      require(msg.sender == admin);
      token.changeOwnership(_newOwner);
  }

  address public contractAddress;

  function burn(address to, uint amount, uint nonce, bytes calldata signature) external {
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    processedNonces[msg.sender][nonce] = true;
   
    token_.transferFrom(address(msg.sender), address(this), amount);
   
    token.burn(amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Burn
    );
  }

  function mint(
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      from, 
      to, 
      amount,
      nonce
    )));
    require(recoverSigner(message, signature) == from , 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    token.mint(to, amount);
    emit Transfer(
      from,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Mint
    );
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
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

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier:MIT

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier:MIT

interface IToken {
  function mint(address to, uint amount) external;
  function burn(uint amount) external;
  function changeOwnership(address  _newOwner) external;
}

