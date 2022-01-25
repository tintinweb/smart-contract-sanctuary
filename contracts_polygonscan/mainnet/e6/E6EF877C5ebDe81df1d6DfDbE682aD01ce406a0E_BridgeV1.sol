// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IWBNB { // or wmatic
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
  function transferFrom(address src, address dst, uint wad) external returns (bool);
}


interface IERC20Burnable {
    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface IERC20Mintable {
    function mint(address account, uint256 amount) external returns (bool);
}

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}


library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }  
}


contract BridgeV1 is Ownable {
    using ECDSA for bytes32;

    uint256 public FEE;         // fee taken per trade
    uint256 public LIMIT;       // limit of tokens that can be transferred
    uint256 public BURN_PERCENTAGE;  // percentage of tokens that are burned on the first chain
    uint256 public MINT_PERCENTAGE;  // percentage of tokens that are minted on the second chain
    address public API;         // only API can call mint on this contract
    address private SIGNER;      // Signer public address
    address public TOKEN;       // token address

    address public WBNB; // wmatic or wbnb

    string public THIS_CHAIN;   // this chain string


    mapping(bytes32 => bool) done;              // prevent replay attacks
    mapping(string => address) chainToBridge;   // chainname and the bridge contract address
    mapping(address => uint256) burnNonce;
    mapping(address => bool) blackListed;

    enum State { PAUSED, ACTIVE }
    State public state;

    event CrossChainBurn(address from, address to, uint256 amountOut, string toChain, address toBridgeAddress, uint256 nonce);
    event CrossChainBurnReceipt(address from, address to, string chain, uint timeStamp, uint blockNumber, bytes32 onChainHash);
    // also let the user save the trnsaction hash

    event CrossChainMint(address from, address to, uint256 amountOut, string fromChain, address fromBridgeAddress);
    event CrossChainMintReceipt(address from, address to, string chain, uint timeStamp, uint blockNumber, bytes32 onChainHash);

    modifier onlyAPI() {
        require(API != address(0), "Bridge: API not set");
        require(msg.sender == API, "Bridge: Only API can call the function");
        _;
    }

    modifier active() {
      require(state == State.ACTIVE, "Bridge: Contract paused");
      _;
    }

    constructor(address _token, string memory _currentChain) Ownable() {
        THIS_CHAIN = _currentChain;
        TOKEN = _token;
        BURN_PERCENTAGE = 10_000; // Default for both of them is 100%
        MINT_PERCENTAGE = 9970; // 0.3 percent burnt forever
        state = State.PAUSED;
        WBNB = 0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F; // wbnb address
    }

    // ------------------------- SETTERS , GETTERS ------------------------------
    function updateToken(address _token) external virtual onlyOwner { TOKEN = _token; }

    function pauseContract() external virtual onlyOwner { state = State.PAUSED; }

    function unpauseContract() external virtual onlyOwner { state = State.ACTIVE; }

    function isDone(bytes32 txn) external view virtual returns(bool) { return done[txn]; }

    function getNonce(address addr) external view virtual returns(uint256) { return burnNonce[addr]; }

    function setFee(uint256 _fee) external virtual onlyOwner { FEE = _fee; }

    function setFeeTokenAddress(address _feeTokenAddress) external virtual onlyOwner {
      require(_feeTokenAddress != address(0), "Bridge: fee token address can't be null");
      WBNB = _feeTokenAddress;
    }

    function setBurnPercentage(uint256 _percentage) external virtual onlyOwner { BURN_PERCENTAGE = _percentage; }

    function setMintPercentage(uint256 _percentage) external virtual onlyOwner { MINT_PERCENTAGE = _percentage; }

    function setLimit(uint256 _limit) external virtual onlyOwner { LIMIT = _limit; }
    
    function setAPI(address _API) external virtual onlyOwner { API = _API; }

    function setSigner(address _signer) external virtual onlyOwner { SIGNER = _signer; }
    
    function getSigner() external view virtual onlyOwner returns(address) { return SIGNER; }
    
    function setBridgeAddressOnChain(string memory chain, address bridge) external virtual onlyOwner { chainToBridge[chain] = bridge; }

    function setBlackListed(address wallet, bool isBlackListed) external virtual onlyOwner { blackListed[wallet] = isBlackListed; }

    function getBlackListed(address wallet) external virtual returns(bool) { return blackListed[wallet]; }

    function amountIn(uint256 amount) public view virtual returns (uint256) {
        uint256 _amountIn = (amount * BURN_PERCENTAGE) / 10_000;
        return _amountIn;
    }

    function amountOut(uint256 amount) public view virtual returns (uint256) {
        uint256 _amountOut = (amount * MINT_PERCENTAGE) / 10_000;
        return _amountOut;
    }

    function transferBurn(address to, uint256 amount, string memory destChain) external virtual active {
        // to is the evm compatible address on other chain
        require(amount <= LIMIT, "Bridge: Amount should be less than limit");
        
        address from = _msgSender();
        require(!blackListed[from], "Bridge: Caller BlackListed!");
        require(IWBNB(WBNB).transferFrom(from, address(this), FEE), "BridgeL Could not deduct appropriate fee"); // transfer the WBNB token first
        require(IERC20Burnable(TOKEN).burnFrom(from, amount), "Bridge: Unable to burn token, check allowance and/or token address");
        uint256 _amountIn = amountIn(amount);

        bytes32 _hash = _buildHash(from, to, amount, THIS_CHAIN, destChain, address(this), chainToBridge[destChain], burnNonce[from]++);

        emit CrossChainBurn(from, to, _amountIn, destChain, chainToBridge[destChain], burnNonce[from] - 1);
        emit CrossChainBurnReceipt(from, to, THIS_CHAIN, block.timestamp, block.number, _hash);
        // let the user save the transaction hash and also the hash
    }


    function transferMint(address from, address to, uint256 amount, string memory srcChain, uint256 _nonce, uint8 v, bytes32 r, bytes32 s)
      external virtual onlyAPI active {

        bytes32 _hash = _buildHash(from, to, amount, srcChain, THIS_CHAIN, chainToBridge[srcChain], address(this), _nonce);
        require(!done[_hash], "Bridge: Txn Already Minted");
        done[_hash] = true;
        address _signer = ecrecover(_hash.toEthSignedMessageHash(),v,r,s);

        require(SIGNER == _signer, "Bridge: wrong signer!");
        uint256 _amountOut = amountOut(amount);
        require(IERC20Mintable(TOKEN).mint(to, _amountOut), "Bridge: Failed to mint tokens");

        emit CrossChainMint(from, to, amount, srcChain, chainToBridge[srcChain]);
        emit CrossChainMintReceipt(from, to, THIS_CHAIN, block.timestamp, block.number, _hash);
    }

    function _buildHash(
      address from, 
      address to, 
      uint256 amount, 
      string memory srcChain, 
      string memory destChain, 
      address srcBridge,
      address destBridge,
      uint256 nonce
    ) internal virtual view returns (bytes32) {
      uint256 _now = block.timestamp;
      bytes4 thisChainHash = bytes4(keccak256(abi.encode(THIS_CHAIN,_now)));
      bytes4 srcChainHash = bytes4(keccak256(abi.encode(srcChain,_now)));
      bytes4 destChainHash = bytes4(keccak256(abi.encode(destChain,_now)));
      require(srcChainHash == thisChainHash || chainToBridge[srcChain] != address(0), "Bridge: Unregistered src Chain");
      require(destChainHash == thisChainHash || chainToBridge[destChain] != address(0), "Bridge: Unregistered Destination Chain");

      bytes32 hash = keccak256(abi.encode(
        from, to, amount, srcChain, destChain, srcBridge, destBridge, nonce
      ));
      return hash;
    }

    function withdrawAnyToken(address _token, address _to, uint256 _amount) external onlyOwner {
      IERC20(_token).transfer(_to, _amount);
    }

}


/*

FLOW
----
set the following after deployment

function unpause
function setLimit(uint256 _limit) external onlyOwner
function setAPI(address _API) external onlyOwner
function setSigner(address _signer) external onlyOwner
function setBridgeAddressOnChain(string memory chain, address bridge)

Approve token so that it can be sent to the contract

*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}