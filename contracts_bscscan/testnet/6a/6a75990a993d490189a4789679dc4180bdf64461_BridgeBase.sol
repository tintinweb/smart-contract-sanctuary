/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// File: contracts/Itoken.sol

pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
  function transfer(address recipient, uint256 amount) external;
  function approve(address spender, uint256 amount) external;
  function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public{
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: contracts/BridgeBase.sol

pragma solidity ^0.8.0;



contract BridgeBase is Ownable {
  address public admin;
  uint256 public swapFee;
  IToken token;
  mapping(address => mapping(uint => bool)) public processedNonces;
  struct Token
    {
        bool isExist;
        string tokensymbol;
        address contractadd;
    }

  mapping(address => Token) public tokenStructs; // random access by question key

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    string to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature
  );

  constructor(uint256 _swapFee) {
    admin = msg.sender;
    swapFee = _swapFee;
  }

 

  function updateswapFee(uint256 _swapFee) public onlyOwner{
      swapFee = _swapFee;
  }

  function deposit(string calldata to, uint amount, uint nonce, bytes calldata signature,address contractadd) external {
    require(tokenStructs[contractadd].isExist==true , 'Token is not found');
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    uint feeAmount = amount * swapFee/100;
    uint transferAmount = amount - feeAmount;
    processedNonces[address(this)][nonce] = true;
    token = IToken(contractadd);
    token.transferFrom(msg.sender, address(this), amount);
    token.transfer(admin, feeAmount);
    emit Transfer(
      msg.sender,
      to,
      transferAmount,
      block.timestamp,
      nonce,
      signature
    );
  }


  function send(
    address from,
    string calldata to,
    uint amount,
    uint nonce,
    bytes calldata signature,
    address contractadd
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

    // address uniqueId = address(bytes20(sha256(abi.encodePacked(to,block.timestamp))));

    // address toadd  = convertFromTronInt(to);
    token = IToken(contractadd);
    token.transfer(toAddress(to),amount);
    emit Transfer(
      from,
      to,
      amount,
      block.timestamp,
      nonce,
      signature
    );
  }


   function addToken(string calldata tokensymbol,address contractadd) public onlyOwner () {
      tokenStructs[contractadd].isExist = true;
      tokenStructs[contractadd].tokensymbol = tokensymbol;
      tokenStructs[contractadd].contractadd = contractadd;
  }

  function safeWithdrawToken(uint256 amount,address contractadd) public onlyOwner () {
      token = IToken(contractadd);
      token.transfer(admin,amount);
  }

  function deactivateToken(string calldata tokensymbol,bool _isactive,address contractadd) public onlyOwner () {
      require(tokenStructs[contractadd].isExist==true , 'Token is not found');
      tokenStructs[contractadd].isExist = _isactive;
      tokenStructs[contractadd].tokensymbol = tokensymbol;
  }

   function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        return 0;
    }

    function hexStringToAddress(string calldata s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }

        return r;

    }

    function toAddress(string calldata s) public pure returns (address) {
        bytes memory _bytes = hexStringToAddress(s);
        require(_bytes.length >= 1 + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
        }

        return tempAddress;
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