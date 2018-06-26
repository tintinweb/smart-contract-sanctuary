pragma solidity ^0.4.18;

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ContractToken {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract StreamityEscrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECRecovery for bytes32;

    uint8 constant public STATUS_NO_DEAL = 0x0;
    uint8 constant public STATUS_DEAL_WAIT_CONFIRMATION = 0x01;
    uint8 constant public STATUS_DEAL_APPROVE = 0x02;
    uint8 constant public STATUS_DEAL_RELEASE = 0x03;

    ERC20Interface public streamityContractAddress;
    
    uint256 public availableForWithdrawal;

    uint32 public requestCancellationTime;

    mapping(bytes32 => Deal) public streamityTransfers;

    function StreamityEscrow() public {
        owner = msg.sender; 
        requestCancellationTime = 2 hours;
    }

    struct Deal {
        uint256 value;
        uint256 cancelTime;
        address seller;
        address buyer;
        uint8 status;
        uint256 commission;
        bool isAltCoin;
    }

    event StartDealEvent(bytes32 _hashDeal, address _seller, address _buyer);
    event ApproveDealEvent(bytes32 _hashDeal, address _seller, address _buyer);
    event ReleasedEvent(bytes32 _hashDeal, address _seller, address _buyer);
    event SellerCancellEvent(bytes32 _hashDeal, address _seller, address _buyer);
    
    function pay(bytes32 _tradeID, address _seller, address _buyer, uint256 _value, uint256 _commission, bytes _sign) 
    external 
    payable 
    {
        require(msg.value > 0);
        require(msg.value == _value);
        require(msg.value > _commission);
        bytes32 _hashDeal = keccak256(_tradeID, _seller, _buyer, msg.value, _commission);
        verifyDeal(_hashDeal, _sign);
        startDealForUser(_hashDeal, _seller, _buyer, _commission, msg.value, false);
    }

    function () public payable {
        availableForWithdrawal = availableForWithdrawal.add(msg.value);
    }

    function payAltCoin(bytes32 _tradeID, address _seller, address _buyer, uint256 _value, uint256 _commission, bytes _sign) 
    external 
    {
        bytes32 _hashDeal = keccak256(_tradeID, _seller, _buyer, _value, _commission);
        verifyDeal(_hashDeal, _sign);
        bool result = streamityContractAddress.transferFrom(msg.sender, address(this), _value);
        require(result == true);
        startDealForUser(_hashDeal, _seller, _buyer, _commission, _value, true);
    }

    function verifyDeal(bytes32 _hashDeal, bytes _sign) private view {
        require(_hashDeal.recover(_sign) == owner);
        require(streamityTransfers[_hashDeal].status == STATUS_NO_DEAL); 
    }

    function startDealForUser(bytes32 _hashDeal, address _seller, address _buyer, uint256 _commission, uint256 _value, bool isAltCoin) 
    private returns(bytes32) 
    {
        Deal storage userDeals = streamityTransfers[_hashDeal];
        userDeals.seller = _seller;
        userDeals.buyer = _buyer;
        userDeals.value = _value; 
        userDeals.commission = _commission; 
        userDeals.cancelTime = block.timestamp.add(requestCancellationTime); 
        userDeals.status = STATUS_DEAL_WAIT_CONFIRMATION;
        userDeals.isAltCoin = isAltCoin;
        emit StartDealEvent(_hashDeal, _seller, _buyer);
        
        return _hashDeal;
    }

    function withdrawCommisionToAddress(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= availableForWithdrawal); 
        availableForWithdrawal = availableForWithdrawal.sub(_amount);
        _to.transfer(_amount);
    }

    function withdrawCommisionToAddressAltCoin(address _to, uint256 _amount) external onlyOwner {
        
    }

    function getStatusDeal(bytes32 _hashDeal) external view returns (uint8) {
        return streamityTransfers[_hashDeal].status;
    }
    
    // _additionalComission is wei
    uint256 constant GAS_releaseTokens = 22300;
    function releaseTokens(bytes32 _hashDeal, uint256 _additionalGas) 
    external 
    nonReentrant
    returns(bool) 
    {
        Deal storage deal = streamityTransfers[_hashDeal];

        if (deal.status == STATUS_DEAL_APPROVE) {
            deal.status = STATUS_DEAL_RELEASE; 
            bool result = false;

            if (deal.isAltCoin == false)
                result = transferMinusComission(deal.buyer, deal.value, deal.commission.add((msg.sender == owner ? (GAS_releaseTokens.add(_additionalGas)).mul(tx.gasprice) : 0)));
            else 
                result = transferMinusComissionAltCoin(streamityContractAddress, deal.buyer, deal.value, deal.commission);

            if (result == false) {
                deal.status = STATUS_DEAL_APPROVE; 
                return false;   
            }

            emit ReleasedEvent(_hashDeal, deal.seller, deal.buyer);
            delete streamityTransfers[_hashDeal];
            return true;
        }
        
        return false;
    }

    function releaseTokensForce(bytes32 _hashDeal) 
    external onlyOwner
    nonReentrant
    returns(bool) 
    {
        Deal storage deal = streamityTransfers[_hashDeal];
        uint8 prevStatus = deal.status; 
        if (deal.status != STATUS_NO_DEAL) {
            deal.status = STATUS_DEAL_RELEASE; 
            bool result = false;

            if (deal.isAltCoin == false)
                result = transferMinusComission(deal.buyer, deal.value, deal.commission);
            else 
                result = transferMinusComissionAltCoin(streamityContractAddress, deal.buyer, deal.value, deal.commission);

            if (result == false) {
                deal.status = prevStatus; 
                return false;   
            }

            emit ReleasedEvent(_hashDeal, deal.seller, deal.buyer);
            delete streamityTransfers[_hashDeal];
            return true;
        }
        
        return false;
    }

    uint256 constant GAS_cancelSeller= 23000;
    function cancelSeller(bytes32 _hashDeal, uint256 _additionalGas) 
    external onlyOwner
    nonReentrant	
    returns(bool)   
    {
        Deal storage deal = streamityTransfers[_hashDeal];
        require(deal.status == STATUS_DEAL_WAIT_CONFIRMATION);
        
        deal.status = STATUS_DEAL_RELEASE; 

        bool result = false;
        if (deal.isAltCoin == false)
            result = transferMinusComission(deal.buyer, deal.value, deal.commission.add(GAS_cancelSeller.add(_additionalGas)).mul(tx.gasprice));
        else 
            result = transferMinusComissionAltCoin(streamityContractAddress, deal.buyer, deal.value, deal.commission);

        require(result);
        
        emit SellerCancellEvent(_hashDeal, deal.seller, deal.buyer);
        delete streamityTransfers[_hashDeal];
        return true;
        
    }

    function approveDeal(bytes32 _hashDeal) 
    external 
    onlyOwner 
    nonReentrant	
    returns(bool) 
    {
        Deal storage deal = streamityTransfers[_hashDeal];
        
        if (deal.status == STATUS_DEAL_WAIT_CONFIRMATION) {
            deal.status = STATUS_DEAL_APPROVE;
            emit ApproveDealEvent(_hashDeal, deal.seller, deal.buyer);
            return true;
        }
        
        return false;
    }

    function transferMinusComission(address _to, uint256 _value, uint256 _commission) 
    private returns(bool) 
    {
        uint256 _totalComission = _commission; 
        
        require(availableForWithdrawal.add(_totalComission) >= availableForWithdrawal); // Check for overflows

        availableForWithdrawal = availableForWithdrawal.add(_totalComission); 

        _to.transfer(_value.sub(_totalComission));
        return true;
    }

    function transferMinusComissionAltCoin(ERC20Interface _contract, address _to, uint256 _value, uint256 _commission) 
    private returns(bool) 
    {
        uint256 _totalComission = _commission; 
        _contract.transfer(_to, _value.sub(_totalComission));
        return true;
    }

    function setStreamityContractAddress(address newAddress) 
    external onlyOwner 
    {
        streamityContractAddress = ERC20Interface(newAddress);
    }

    // For other Tokens
    function transferToken(ContractToken _tokenContract, address _transferTo, uint256 _value) onlyOwner external {
         _tokenContract.transfer(_transferTo, _value);
    }
    function transferTokenFrom(ContractToken _tokenContract, address _transferTo, address _transferFrom, uint256 _value) onlyOwner external {
         _tokenContract.transferFrom(_transferTo, _transferFrom, _value);
    }
    function approveToken(ContractToken _tokenContract, address _spender, uint256 _value) onlyOwner external {
         _tokenContract.approve(_spender, _value);
    }
}