pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

contract Escrow is Ownable {
    using SafeMath for uint256;
    struct EscrowElement {
    bool exists;
    address src;
    address dst;
    uint256 value;
    }

    address public token;
    ERC20 public tok;

    mapping (bytes20 => EscrowElement) public escrows;

    /* Numerator and denominator of common fraction.
        E.g. 1 & 25 mean one twenty fifths, i.e. 0.04 = 4% */
    uint256 public escrow_fee_numerator; /* 1 */
    uint256 public escrow_fee_denominator; /* 25 */



    event EscrowStarted(
    bytes20 indexed escrow_id,
    EscrowElement escrow_element
    );

    event EscrowReleased(
    bytes20 indexed escrow_id,
    EscrowElement escrow_element
    );

    event EscrowCancelled(
    bytes20 indexed escrow_id,
    EscrowElement escrow_element
    );


    event TokenSet(
    address indexed token
    );

    event Withdrawed(
    address indexed dst,
    uint256 value
    );

    function Escrow(address _token){
        token = _token;
        tok = ERC20(_token);
        escrow_fee_numerator = 1;
        escrow_fee_denominator = 25;
    }

    function startEscrow(bytes20 escrow_id, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(escrows[escrow_id].exists != true);
//        ERC20 tok = ERC20(token);
        tok.transferFrom(msg.sender, address(this), value);
        EscrowElement memory escrow_element = EscrowElement(true, msg.sender, to, value);
        escrows[escrow_id] = escrow_element;

        emit EscrowStarted(escrow_id, escrow_element);

        return true;
    }

    function releaseEscrow(bytes20 escrow_id, address fee_destination) onlyOwner returns (bool) {
        require(fee_destination != address(0));
        require(escrows[escrow_id].exists == true);

        EscrowElement storage escrow_element = escrows[escrow_id];

        uint256 fee = escrow_element.value.mul(escrow_fee_numerator).div(escrow_fee_denominator);
        uint256 value = escrow_element.value.sub(fee);

//        ERC20 tok = ERC20(token);

        tok.transfer(escrow_element.dst, value);
        tok.transfer(fee_destination, fee);


        EscrowElement memory _escrow_element = escrow_element;

        emit EscrowReleased(escrow_id, _escrow_element);

        delete escrows[escrow_id];

        return true;
    }

    function cancelEscrow(bytes20 escrow_id) onlyOwner returns (bool) {
        EscrowElement storage escrow_element = escrows[escrow_id];

//        ERC20 tok = ERC20(token);

        tok.transfer(escrow_element.src, escrow_element.value);
        /* Workaround because of lack of feature. See https://github.com/ethereum/solidity/issues/3577 */
        EscrowElement memory _escrow_element = escrow_element;


        emit EscrowCancelled(escrow_id, _escrow_element);

        delete escrows[escrow_id];

        return true;
    }

    function withdrawToken(address dst, uint256 value) onlyOwner returns (bool){
        require(dst != address(0));
        require(value > 0);
//        ERC20 tok = ERC20(token);
        tok.transfer(dst, value);

        emit Withdrawed(dst, value);

        return true;
    }

    function setToken(address _token) onlyOwner returns (bool){
        require(_token != address(0));
        token = _token;
        tok = ERC20(_token);
        emit TokenSet(_token);

        return true;
    }
    //


}