pragma solidity ^0.4.24;


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
 * @title HtczExchange
 * @dev Eth <-> HTCZ Exchange supporting contract
 */
contract HtczExchange is Ownable {

    using SafeMath for uint256;

    // ** Events **

    // Deposit received -> sent to exchange to HTCZ token
    event Deposit(address indexed sender, uint eth_amount, uint htcz_amount);

    // HTCZ token was sent in exchange for Ether
    event Exchanged(address indexed receiver, uint indexed htcz_tx, uint htcz_amount, uint eth_amount);

    // HTCZ Reserve amount changed
    event ReserveChanged(uint old_htcz_amount, uint new_htcz_amount);

    // Operator changed
    event OperatorChanged(address indexed new_operator);


    // ** Contract state **

    // HTCZ token (address is in ETZ network)
    address public htcz_token;

    // Source of wallet for reserve (address is in ETZ network)
    address public htcz_cold_wallet;

    // HTCZ wallet used to exchange (address is in ETZ network)
    address public htcz_exchange_wallet;

    // Operator account of the exchange
    address public operator;

    // HTCZ amount used for exchange, should not exceed htcz_reserve
    uint public htcz_exchanged_amount;

    // HTCZ reserve for exchange
    uint public htcz_reserve;

    // ETH -> HTCZ exchange rate
    uint public exchange_rate;

    // gas spending on transfer function
    uint constant GAS_FOR_TRANSFER = 47627;

    // ** Modifiers **

    // Throws if called by any account other than the operator.
    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    constructor(    address _htcz_token,
                    address _htcz_cold_wallet,
                    address _htcz_exchange_wallet,
                    address _operator,
                    uint _exchange_rate ) public {

	    require(_htcz_token != address(0));
	    require(_htcz_cold_wallet != address(0));
	    require(_htcz_exchange_wallet != address(0));
	    require(_operator != address(0));
	    require(_exchange_rate>0);

	    htcz_token = _htcz_token;
	    htcz_cold_wallet = _htcz_cold_wallet;
	    htcz_exchange_wallet = _htcz_exchange_wallet;
	    exchange_rate = _exchange_rate;
	    operator = _operator;

    }

    /**
    * @dev Accepts Ether.
    * Throws is token balance is not available to issue HTCZ tokens
    */
    function() external payable {

        require( msg.value > 0 );

        uint eth_amount = msg.value;
        uint htcz_amount = eth_amount.mul(exchange_rate);

        htcz_exchanged_amount = htcz_exchanged_amount.add(htcz_amount);

        require( htcz_reserve >= htcz_exchanged_amount );

        emit Deposit(msg.sender, eth_amount, htcz_amount);
    }

    /**
    * @dev Transfers ether by operator command in exchange to HTCZ tokens
    * Calculates gas amount, gasprice and substracts that from the transfered amount.
    * Note, that smart contracts are not allowed as the receiver.
    */
    function change(address _receiver, uint _htcz_tx, uint _htcz_amount) external onlyOperator {

        require(_receiver != address(0));

        uint gas_value = GAS_FOR_TRANSFER.mul(tx.gasprice);
        uint eth_amount = _htcz_amount / exchange_rate;

        require(eth_amount > gas_value);

        eth_amount = eth_amount.sub(gas_value);

        require(htcz_exchanged_amount >= _htcz_amount );

        htcz_exchanged_amount = htcz_exchanged_amount.sub(_htcz_amount);

        msg.sender.transfer(gas_value);
        _receiver.transfer(eth_amount);

        emit Exchanged(_receiver, _htcz_tx, _htcz_amount, eth_amount);

    }

    /**
    * @dev Increase HTCZ reserve
    */
    function increaseReserve(uint _amount) external onlyOperator {

        uint old_htcz_reserve = htcz_reserve;
        uint new_htcz_reserve = old_htcz_reserve.add(_amount);

        require( new_htcz_reserve > old_htcz_reserve);

        htcz_reserve = new_htcz_reserve;

        emit ReserveChanged(old_htcz_reserve, new_htcz_reserve);

    }

    /**
    * @dev Decrease HTCZ reserve
    */
    function decreaseReserve(uint _amount) external onlyOperator {

        uint old_htcz_reserve = htcz_reserve;
        uint new_htcz_reserve = old_htcz_reserve.sub(_amount);

        require( new_htcz_reserve < old_htcz_reserve);
        require( new_htcz_reserve >= htcz_exchanged_amount );

        htcz_reserve = new_htcz_reserve;

        emit ReserveChanged(old_htcz_reserve, new_htcz_reserve);

    }


    /**
    * @dev Set other operator ( 0 allowed )
    */
    function changeOperator(address _operator) external onlyOwner {
        require(_operator != operator);
        operator = _operator;
        emit OperatorChanged(_operator);
    }


}