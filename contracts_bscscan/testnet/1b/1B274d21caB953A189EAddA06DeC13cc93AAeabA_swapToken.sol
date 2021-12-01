/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: UNLICENSED

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDXB {
    function burn(uint256 _value) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Validator {
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("validateSig(address _owner, uint _amount, uint _deadline, bytes memory signature)");
    uint public chainId;
    
    using ECDSA for bytes32;
    
    constructor() {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        
        chainId = _chainId;
    }
    
    function validateSig(address _owner, uint _amount, uint _deadline, bytes memory signature) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, _owner, _amount, chainId, _deadline));
      bytes32 messageHash = hash.toSignedMessageHash();
    
      // Verify that the message's signer is the owner of the order
      return messageHash.recover(signature);
    }
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
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
  function toSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

contract swapToken is Ownable, Validator {
    event Swap( address indexed _user, uint _amount, uint _time);
    
    IBEP20 public DXB;
    address public oldDXB;
    address public swapManager;
    uint public endSale;
    
    constructor( IBEP20 _DXB, address _oldDXB, address _swapManager, uint _endSale) {
        DXB = _DXB;
        oldDXB = _oldDXB;
        swapManager = _swapManager;
        endSale = _endSale;
    }
    
    mapping(address => bool) blackList;
    mapping(bytes => bool) signature;

    function setEndSale( uint _endSale) external onlyOwner {
      endSale = _endSale;
    }

    function setSwapManager( address _newManager) external onlyOwner {
        require(_newManager != address(0));
        swapManager = _newManager;
    }
    
    function setBlackList( address _acc, bool _stat) external onlyOwner {
        require(blackList[_acc] != _stat, "setBlackList : current stat is same as _stat");
        blackList[_acc] = _stat;
    }
    
    function swap( uint _amount, uint _deadline, bytes memory _signature) external {
        require(block.timestamp < endSale, "swap : sale ended or sale end time isnt started");
        require(!blackList[_msgSender()], "swap : is on the black list");
        require(IBEP20(oldDXB).balanceOf(_msgSender()) >= _amount, "swap : insufficient user balance");
        require(IBEP20(oldDXB).allowance(_msgSender(), address(this)) >= _amount, "swap : insufficient allowance");
        require(DXB.balanceOf(address(this)) >= _amount, "swap : insufficient balance of new DXB on the swap contract");
        require(!signature[_signature], "swap : signature already used");
        require(validateSig( _msgSender(), _amount, _deadline, _signature) == swapManager, "swap : signature failed");
        
        signature[_signature] = true;
        
        require(IBEP20(oldDXB).transferFrom(_msgSender(), address(this), _amount), "swap : transferFrom failed");
        IDXB(oldDXB).burn( _amount); // burn old DXB
        
        DXB.transfer(_msgSender(), _amount);
        emit Swap( _msgSender(), _amount, block.timestamp);
    }
    
    function emergency( address token, address _to, uint _amount) external onlyOwner { // in case of failure.
        address _contractAdd = address(this);
        
        if(token == address(0)){
            require(_contractAdd.balance >= _amount,"insufficient BNB");
            payable(_to).transfer(_amount);
        }
        else{
            require( IBEP20(token).balanceOf(_contractAdd) >= _amount,"insufficient Token balance");
            IBEP20(token).transfer(_to, _amount);
        }
    }
}