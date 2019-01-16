pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



contract Arbitration {
    function requestArbitration(
        bytes32 id,
        uint256 tokens,
        address supplier,
        address purchaser
    )
        external;
}

contract TestArbitration is Arbitration, Ownable {
    event Arbitrate(
        bytes32 id,
        uint256 tokens,
        address supplier,
        address purchaser
    );

    function requestArbitration(
        bytes32 id,
        uint256 tokens,
        address supplier,
        address purchaser
    )
        external
    {
        emit Arbitrate(id, tokens, supplier, purchaser);
    }
}


contract Whitelist is Ownable {
    mapping(address => bool) public whitelisted;

    function whitelist(address caller) public onlyOwner {
        whitelisted[caller] = true;
    }

    function blacklist(address caller) public onlyOwner {
        whitelisted[caller] = false;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Approved callers only.");
        _;
    }
}

contract Payments is Ownable {
    struct Details {
        bool active;
        address supplier;
        uint64 cancelDeadline;
        address purchaser;
        uint64 disputeDeadline;
        uint256 price;
        uint256 deposit;
        uint256 cancellationFee;
    }

    event Invoice (
        bytes32 id,
        address supplier,
        address purchaser,
        uint256 price,
        uint256 deposit,
        uint256 cancellationFee,
        uint64 cancelDeadline,
        uint64 disputeDeadline
    );
    event Payout (
        bytes32 id,
        address supplier,
        address purchaser,
        uint256 price,
        uint256 deposit
    );
    event Cancel (
        bytes32 id,
        address supplier,
        address purchaser,
        uint256 price,
        uint256 deposit,
        uint256 cancellationFee
    );
    event Refund (
        bytes32 id,
        address supplier,
        address purchaser,
        uint256 price,
        uint256 deposit
    );
    event Dispute (
        bytes32 id,
        address arbitration,
        address disputant,
        address supplier,
        address purchaser,
        uint256 price,
        uint256 deposit
    );

    modifier onlyPurchaser(bytes32 id) {
        require(msg.sender == details[id].purchaser, "Purchaser only.");
        _;
    }

    modifier onlySupplier(bytes32 id) {
        require(msg.sender == details[id].supplier, "Supplier only.");
        _;        
    }

    modifier onlyOwnerOrSupplier(bytes32 id) {
        require(
            msg.sender == owner ||
            msg.sender == details[id].supplier,
            "Owner or supplier only."
        );
        _;
    }

    modifier onlyParticipant(bytes32 id) {
        require(
            msg.sender == details[id].supplier ||
            msg.sender == details[id].purchaser,
            "Participant only."
        );
        _;
    }

    modifier deactivates(bytes32 id) {
        require(details[id].active, "Unknown id.");
        details[id].active = false;
        _;
    }

    modifier invoices(bytes32 id) {
        require(details[id].supplier == 0x0, "Given id already exists.");
        _;
        emit Invoice(
            id,
            details[id].supplier,
            details[id].purchaser,
            details[id].price,
            details[id].deposit,
            details[id].cancellationFee,
            details[id].cancelDeadline,
            details[id].disputeDeadline
        );
    }

    modifier pays(bytes32 id) {
        /* solium-disable-next-line security/no-block-members */
        require(now > details[id].disputeDeadline, "Dispute deadline not met.");
        _;
        emit Payout(
            id,
            details[id].supplier,
            details[id].purchaser,
            details[id].price,
            details[id].deposit
        );
    }

    modifier cancels(bytes32 id) {
        /* solium-disable-next-line security/no-block-members */
        require(now < details[id].cancelDeadline, "Cancel deadline passed.");
        _;
        emit Cancel(
            id,
            details[id].supplier,
            details[id].purchaser,
            details[id].price,
            details[id].deposit,
            details[id].cancellationFee
        );
    }

    modifier refunds(bytes32 id) {
        _;
        emit Refund(
            id,
            details[id].supplier,
            details[id].purchaser,
            details[id].price,
            details[id].deposit
        );
    }

    modifier disputes(bytes32 id) {
        /* solium-disable-next-line security/no-block-members */
        require(now < details[id].disputeDeadline, "Dispute deadline passed.");
        _;
        emit Dispute(
            id,
            arbitration,
            msg.sender,
            details[id].supplier,
            details[id].purchaser,
            details[id].price,
            details[id].deposit
        );
    }

    mapping(bytes32 => Details) public details;
    Arbitration public arbitration;
}

contract TokenPayments is Whitelist, Payments {
    using SafeMath for uint256;

    ERC20 public token;
    uint64 public cancelPeriod;
    uint64 public disputePeriod;

    constructor(
        address _token,
        address _arbitration,
        uint64 _cancelPeriod,
        uint64 _disputePeriod
    )
        public
    {
        token = ERC20(_token);
        arbitration = Arbitration(_arbitration);
        cancelPeriod = _cancelPeriod;
        disputePeriod = _disputePeriod;
    }

    function invoice(
        bytes32 id,
        address supplier,
        address purchaser,
        uint256 price,
        uint256 deposit,
        uint256 cancellationFee,
        uint64 cancelDeadline,
        uint64 disputeDeadline
    )
        external
        onlyWhitelisted
        invoices(id)
    {
        require(
            supplier != address(0x0),
            "Must provide a valid supplier address."
        );
        require(
            purchaser != address(0x0),
            "Must provide a valid purchaser address."
        );
        require(
            /* solium-disable-next-line security/no-block-members */
            cancelDeadline > now.add(cancelPeriod),
            "Cancel deadline too soon."
        );
        require(
            disputeDeadline > uint256(cancelDeadline).add(disputePeriod),
            "Dispute deadline too soon."
        );
        require(
            price.add(deposit) >= cancellationFee,
            "Cancellation fee exceeds total."
        );
        details[id] = Details({
            active: true,
            supplier: supplier,
            cancelDeadline: cancelDeadline,
            purchaser: purchaser,
            disputeDeadline: disputeDeadline,
            price: price,
            deposit: deposit,
            cancellationFee: cancellationFee
        });
        uint256 expectedBalance = getTotal(id)
            .add(token.balanceOf(address(this)));
        require(
            token.transferFrom(purchaser, address(this), getTotal(id)),
            "Transfer failed during invoice."
        );
        require(
            token.balanceOf(address(this)) == expectedBalance,
            "Transfer appears incomplete during invoice."
        );
    }

    function cancel(bytes32 id) 
        external
        onlyPurchaser(id)
        deactivates(id)
        cancels(id)
    {
        uint256 fee = details[id].cancellationFee;
        uint256 refund = getTotal(id).sub(fee);
        transfer(details[id].purchaser, refund);
        transfer(details[id].supplier, fee);
    }

    function payout(bytes32 id)
        external
        onlySupplier(id)
        deactivates(id)
        pays(id)
    {
        transfer(details[id].supplier, details[id].price);
        transfer(details[id].purchaser, details[id].deposit);
    }

    function refund(bytes32 id)
        external
        onlyOwnerOrSupplier(id)
        deactivates(id)
        refunds(id)
    {
        transfer(details[id].purchaser, getTotal(id));
    }

    function dispute(bytes32 id)
        external
        onlyParticipant(id)
        deactivates(id)
        disputes(id)
    {
        require(
            token.approve(arbitration, getTotal(id)),
            "Approval for transfer failed during dispute."
        );
        arbitration.requestArbitration(
            id,
            getTotal(id),
            details[id].supplier,
            details[id].purchaser
        );
    }

    function getTotal(bytes32 id) private view returns (uint256) {
        return details[id].price.add(details[id].deposit);
    }

    function transfer(address to, uint256 amount) internal {
        uint256 expectedBalance = token.balanceOf(address(this)).sub(amount);
        uint256 expectedRecipientBalance = token.balanceOf(to).add(amount);
        require(token.transfer(to, amount), "Transfer failed.");
        require(
            token.balanceOf(address(this)) == expectedBalance,
            "Post-transfer validation of contract funds failed."
        );
        require(
            token.balanceOf(to) == expectedRecipientBalance,
            "Post-transfer validation of recipient funds failed."
        );
    }
}