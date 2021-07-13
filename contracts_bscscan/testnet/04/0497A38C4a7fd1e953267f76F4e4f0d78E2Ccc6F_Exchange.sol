/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed
pragma abicoder v2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

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

contract SignatureChecker is Ownable{
    // keccak256("submit(uint256 owner, uint256 amount, uint256 week, uint256 nonce, uint deadline, bytes memory signature)");
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("submit(uint256 user, uint256 amount,uint256 nonce, uint deadline, bytes memory signature)");
    uint public chainId;
    
    constructor()  {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
    }
    
    mapping(address => mapping(uint256 => bool)) public seenNonces;
    
    function hashCreation() internal pure returns (bytes32  messageHash){
        bytes32 hash = keccak256(abi.encodePacked());
        messageHash = toSignedMessageHash(hash);
    }
    
    function submit(uint256 nonce, uint deadline,uint8 v,bytes32 r,bytes32 s) internal {
        // This recreates the message hash that was signed on the client.
        require(block.timestamp <= deadline, "sign error");
        bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, nonce, chainId, deadline));
        bytes32 messageHash = toSignedMessageHash(hash);
        
        // Verify that the message's signer is the owner of the order
        address signer = recover(messageHash,v,r,s);
        require(signer == owner(), "Invalid address");
        
        require(!seenNonces[signer][nonce] , "Nonce mismatch");
        seenNonces[signer][nonce] = true;
    }
    
    function recover(bytes32 hash,uint8 v,bytes32 r,bytes32 s) internal pure returns (address) {
        return ecrecover(hash, v, r, s);
    }
      
    function toSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


contract Exchange is Ownable, SignatureChecker {

    using SafeMath for uint256;

    // receving wow token address
    IERC20 public wow;
    // new wow token address
    IERC20 public newWow;
    // minimum token limit. ratio = limit:1
    uint256 public limit = 100e9; 
    uint256 public minimumTokenToExchange = 1e9;
    // contract status. 
    bool public pause;
    
    struct claimParams{
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
        uint deadline;
    }
    
    mapping(address => bool)public isClaim;
    
    event ExchangeWOW(address receiver, uint256 wowAmount, uint256 newWowAmount);
    event SafeWithdrawToken(address token,address receiver, uint256 amount);
    event SetLimit(address caller, uint256 newLimit);
    event SetStatus(address caller, bool newstatus);

    modifier isPause() {
       require(!pause, "contract paused");
       _;
    }
    
    constructor (IERC20 _oldWOW, IERC20 _newWOW) {
        wow = _oldWOW;
        newWow = _newWOW;
    }
    
    function setLimit(uint256 _newLimit) external onlyOwner {
        limit = _newLimit;
        emit SetLimit(msg.sender, _newLimit);
    }
    
    function setStatus(bool _newstatus) external onlyOwner {
        pause = _newstatus;
        emit SetStatus(msg.sender, _newstatus);
    }
    
    function setMinimumTokenToExchange( uint _minimumTokenToExchange) external onlyOwner {
        minimumTokenToExchange = _minimumTokenToExchange;
    }
    
    function claimWow(claimParams memory _VRS) external isPause {
        require(!isClaim[msg.sender],"Already claimed");
        require(wow.balanceOf(msg.sender) >= minimumTokenToExchange, "_amount to exchange must be atleast one");
        submit(_VRS.nonce,_VRS.deadline,_VRS.v,_VRS.r,_VRS.s);
        uint256 _amount = wow.balanceOf(msg.sender);
        uint256 value = _amount.mul(1e12).mul(1e9).div(limit); //amountIn *1e12 *decimals /limit 
        
        value = value.div(1e12); // value /1e12
        
        require(newWow.transfer(msg.sender, value), "new transer Failed");
        
        isClaim[msg.sender] = true;
        
        emit ExchangeWOW(msg.sender, _amount, value);
        
    }
    
    // function safeWithdrawToken(address[] memory _tokenAddress ) external onlyOwner {
       
    //   for (uint256 i = 0; i < _tokenAddress.length; i++ ) { 
    //         if(_tokenAddress[i] == address(0x00)) {
    //             uint256 amount = address(this).balance;
    //             if(amount > 0) {
    //                 msg.sender.transfer(amount);
    //                 emit SafeWithdrawToken(_tokenAddress[i], msg.sender, amount);
    //             }
    //         } else {
    //             uint256 amount =  IERC20(_tokenAddress[i]).balanceOf(address(this));
    //             if(amount > 0) {
    //                 IERC20(_tokenAddress[i]).transfer(msg.sender,amount);
    //                 emit SafeWithdrawToken(_tokenAddress[i], msg.sender, amount);
    //             }
    //         } 
    //     }
    // }
    
}