// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {

  /* storage */

  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(address => uint256) public nonces;

  string public name;
  string public symbol;

  /* immutables */

  uint8 public immutable decimals;
  uint256 internal immutable INITIAL_CHAIN_ID;
  bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
  address internal immutable OWNER;

  /* constants */

  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  /* events */

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /* constructor */

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    OWNER = msg.sender;
  }

  /* functions */

  function approve(address spender, uint256 amount) external returns (bool) {
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    balanceOf[msg.sender] -= amount;
    unchecked { balanceOf[to] += amount; }
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {

    uint256 allowed = allowance[from][msg.sender];

    if (allowed != type(uint256).max || msg.sender == OWNER) {
      allowance[from][msg.sender] = allowed - amount;
    }

    balanceOf[from] -= amount;
    unchecked { balanceOf[to] += amount; }
    emit Transfer(from, to, amount);

    return true;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {

    require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

    unchecked {
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );
      address recoveredAddress = ecrecover(digest, v, r, s);
      require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");
      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view returns (bytes32) {
    return keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  function issue(address to, uint256 amount) public {
    require(msg.sender == OWNER);
    totalSupply += amount;
    unchecked { balanceOf[to] += amount; }
    emit Transfer(address(0), to, amount);
  }
}