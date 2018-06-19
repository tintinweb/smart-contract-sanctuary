pragma solidity ^0.4.21;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 {

    function balanceOf(address _owner) external returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}


contract Offer {

	using SafeMath for uint256;                                        // Use safe math library

    ERC20 tokenContract;            // Object of token contract
    address owner; // address of contract creator
    address cpaOwner; // 0x583031d1113ad414f02576bd6afabfb302140987
    string public offer_id;
    uint256 public conversionsCount;
    uint256 public totalAmount;

    struct conversion{
        string id;
        uint256 timestamp;
        address affiliate;
        uint256 amount;
        uint256 toAffiliate;
    }

    event Conversion(
        string conversion_id
    );

    mapping (bytes32 => conversion) conversions;         // Conversions table

    function Offer(address tokenContractAddress, string _offer_id, address _cpaOwner) public {
        tokenContract = ERC20(tokenContractAddress);
        offer_id = _offer_id;
        owner = msg.sender;
        cpaOwner = _cpaOwner;
    }

    function getMyAddress() public view returns (address myAddress) {
        return msg.sender;
    }

    function getBalance(address _wallet) public view returns(uint256 _balance) {
        return tokenContract.balanceOf(_wallet);
    }

    function contractBalance() public view returns(uint256 _balance) {
        return tokenContract.balanceOf(address(this));
    }

    function writeConversion(string _conversion_id, address _affiliate, uint256 _amount, uint256 _toAffiliate)
        public returns (bool success) {
        require(msg.sender == owner);
        require(_toAffiliate <= _amount);
        require(_amount > 0);
        require(_toAffiliate > 0);
        if (getBalance(address(this)) >= _amount) {
            conversionsCount++;
            totalAmount = totalAmount.add(_amount);
            conversions[keccak256(_conversion_id)] = conversion(_conversion_id, now, _affiliate, _amount, _toAffiliate);
            tokenContract.transfer(_affiliate, _toAffiliate);
            tokenContract.transfer(cpaOwner, _amount.sub(_toAffiliate));
            emit Conversion(_conversion_id);
        } else {
            return false;
        }
        return true;
    }

    function getConversionInfo(string _conversion_id)
        public
        constant
        returns (string cid, uint256 ts, address aff, uint256 am, uint256 toAff) {
        conversion storage _c = conversions[keccak256(_conversion_id)];
        return (_c.id, _c.timestamp, _c.affiliate, _c.amount, _c.toAffiliate);
    }
}