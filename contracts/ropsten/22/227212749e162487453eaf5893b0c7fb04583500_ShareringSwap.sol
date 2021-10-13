/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * mul 
     * @dev Safe math multiply function
     */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  /**
   * add
   * @dev Safe math addition function
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external constant returns (uint256 balance);
}

/**
 * @title ShareringSwap
 * @dev ShareringSwap contract is Ownable
 **/
contract ShareringSwap is Ownable {
  using SafeMath for uint256;
  Token token;
  address public requester;
  address public approver;
  
  struct typeTxInfo {
    address to;
    uint256 value;
    bytes32 transactionId;
    uint status;
  }
  
  mapping(bytes32 => typeTxInfo) public Txs;
  
  /**
   * RequestSwap
   * @dev Log swap request
   */
  event RequestSwap(bytes32 transactionId, address indexed to, uint256 value);

  /**
   * ApprovalSwap
   * @dev Log swap approval
   */
  event ApprovalSwap(bytes32 transactionId, address indexed to, uint256 value);
  
  /**
   * onlyApprover
   * @dev Throws an error if called by any account other than the approver.
   **/
  modifier onlyApprover() {
    require(msg.sender == approver);
    _;
  }
  
    /**
   * onlyRequester
   * @dev Throws an error if called by any account other than the approver.
   **/
  modifier onlyRequester() {
    require(msg.sender == requester);
    _;
  }
  
  
  /**
   * ShareringSwap
   * @dev ShareringSwap constructor
   **/
  function ShareringSwap(address _tokenAddr, address _requester, address _approver) public {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
      requester = _requester;
      approver = _approver;
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  /**
   * withdraw
   **/
  function withdraw() onlyOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);
  }
  
  /**
   * set Approval Address
   **/
  function setApprover(address _approver) onlyOwner public {
    approver = _approver;
  }
  
   /**
   * set Requester Address
   **/
  function setRequester(address _requester) onlyOwner public {
    requester = _requester;
  }
  
  /**
   * tx info
   * @dev returns the tx info
   **/
  function txInfo(bytes32 _transactionId) public constant returns (address, uint256, uint) {
    return (Txs[_transactionId].to, Txs[_transactionId].value, Txs[_transactionId].status);
  }
  
   /**
   * Request swap
   **/
  function requestSwap(bytes32 _transactionId, address _to, uint256 _amount) onlyRequester public {
    Txs[_transactionId].transactionId = _transactionId;
    Txs[_transactionId].to = _to;
    Txs[_transactionId].value = _amount;
    Txs[_transactionId].status = 1;
    emit RequestSwap(_transactionId, _to, _amount);
  }
  
  
   /**
   * Approve swap
   **/
  function approveSwap(bytes32 _transactionId) onlyApprover public {
    uint256 balance = token.balanceOf(this);
    assert(balance > Txs[_transactionId].value);
    assert(Txs[_transactionId].status == 1);
    token.transfer(Txs[_transactionId].to, Txs[_transactionId].value);
    Txs[_transactionId].status == 2;
    emit ApprovalSwap(_transactionId, Txs[_transactionId].to, Txs[_transactionId].value);
  }
  
  
   /**
   * Approve multi swap
   **/
  function approveMultiSwap(bytes32[] _transactionIds) onlyApprover public {
    for (uint i = 0; i < _transactionIds.length; i++) {
       approveSwap(_transactionIds[i]); 
    }  
  }
}