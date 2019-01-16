pragma solidity 0.4.25;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ddb9bcabb89dbcb6b2b0bfbcf3beb2b0">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[20 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

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

contract DeconetPaymentsSplitting {
    using SafeMath for uint;

    // Logged on this distribution set up completion.
    event DistributionCreated (
        address[] destinations,
        uint[] sharesMantissa,
        uint sharesExponent
    );

    // Logged when funds landed to or been sent out from this contract balance.
    event FundsOperation (
        address indexed senderOrAddressee,
        uint amount,
        FundsOperationType indexed operationType
    );

    // Enumeration of possible funds operations.
    enum FundsOperationType { Incoming, Outgoing }

    // Describes Distribution destination and its share of all incoming funds.
    struct Distribution {
        // Destination address of the distribution.
        address destination;

        // Floating-point number mantissa of a share allotted for a destination address.
        uint mantissa;
    }

    // Stores exponent of a power term of a floating-point number.
    uint public sharesExponent;

    // Stores list of distributions.
    Distribution[] public distributions;

    /**
     * @dev Payable fallback that tries to send over incoming funds to the distribution destinations splitted
     * by pre-configured shares. In case when there is not enough gas sent for the transaction to complete
     * distribution, all funds will be kept in contract untill somebody calls `withdrawFullContractBalance` to
     * run postponed distribution and withdraw contract&#39;s balance funds.
     */
    function () public payable {
        emit FundsOperation(msg.sender, msg.value, FundsOperationType.Incoming);
        distributeFunds();
    }

    /**
     * @dev Set up distribution for the current clone, can be called only once.
     * @param _destinations Destination addresses of the current payments splitting contract clone.
     * @param _sharesMantissa Mantissa values for destinations shares ordered respectively with `_destinations`.
     * @param _sharesExponent Exponent of a power term that forms shares floating-point numbers, expected to
     * be the same for all values in `_sharesMantissa`.
     */
    function setUpDistribution(
        address[] _destinations,
        uint[] _sharesMantissa,
        uint _sharesExponent
    )
        external
    {
        require(distributions.length == 0, "Contract can only be initialized once"); // Make sure the clone isn&#39;t initialized yet.
        require(_destinations.length <= 8 && _destinations.length > 0, "There is a maximum of 8 destinations allowed");  // max of 8 destinations
        // prevent integer overflow when math with _sharesExponent happens
        // also ensures that low balances can be distributed because balance must always be >= 10**(sharesExponent + 2)
        require(_sharesExponent <= 4, "The maximum allowed sharesExponent is 4");
        // ensure that lengths of arrays match so array out of bounds can&#39;t happen
        require(_destinations.length == _sharesMantissa.length, "Length of destinations does not match length of sharesMantissa");

        uint sum = 0;
        for (uint i = 0; i < _destinations.length; i++) {
            // Forbid contract as destination so that transfer can never fail
            require(!isContract(_destinations[i]), "A contract may not be a destination address");
            sum = sum.add(_sharesMantissa[i]);
            distributions.push(Distribution(_destinations[i], _sharesMantissa[i]));
        }
         // taking into account 100% by adding 2 to the exponent.
        require(sum == 10**(_sharesExponent.add(2)), "The sum of all sharesMantissa should equal 10 ** ( _sharesExponent + 2 ) but it does not.");
        sharesExponent = _sharesExponent;
        emit DistributionCreated(_destinations, _sharesMantissa, _sharesExponent);
    }

    /**
     * @dev Process the available balance through the distribution and send money over to destination addresses.
     */
    function distributeFunds() public {
        uint balance = address(this).balance;
        require(balance >= 10**(sharesExponent.add(2)), "You can not split up less wei than sum of all shares");
        for (uint i = 0; i < distributions.length; i++) {
            Distribution memory distribution = distributions[i];
            uint amount = calculatePayout(balance, distribution.mantissa, sharesExponent);
            distribution.destination.transfer(amount);
            emit FundsOperation(distribution.destination, amount, FundsOperationType.Outgoing);
        }
    }

    /**
     * @dev Returns length of distributions array
     * @return Length of distributions array
    */
    function distributionsLength() public view returns (uint256) {
        return distributions.length;
    }


    /**
     * @dev Calculates a share of the full amount.
     * @param _fullAmount Full amount.
     * @param _shareMantissa Mantissa of the percentage floating-point number.
     * @param _shareExponent Exponent of the percentage floating-point number.
     * @return An uint of the payout.
     */
    function calculatePayout(uint _fullAmount, uint _shareMantissa, uint _shareExponent) private pure returns(uint) {
        return (_fullAmount.div(10 ** (_shareExponent.add(2)))).mul(_shareMantissa);
    }

    /**
     * @dev Checks whether or not a given address contains a contract
     * @param _addr The address to check
     * @return A boolean indicating whether or not the address is a contract
     */
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

contract DeconetPaymentsSplittingFactory is CloneFactory {

    // PaymentsSplitting master-contract address.
    address public libraryAddress;

    // Logged when a new PaymentsSplitting clone is deployed to the chain.
    event PaymentsSplittingCreated(address newCloneAddress);

    /**
     * @dev Constructor for the contract.
     * @param _libraryAddress PaymentsSplitting master-contract address.
     */
    constructor(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Create PaymentsSplitting clone.
     * @param _destinations Destination addresses of the new PaymentsSplitting contract clone.
     * @param _sharesMantissa Mantissa values for destinations shares ordered respectively with `_destinations`.
     * @param _sharesExponent Exponent of a power term that forms shares floating-point numbers, expected to
     * be the same for all values in `_sharesMantissa`.
     */
    function createPaymentsSplitting(
        address[] _destinations,
        uint[] _sharesMantissa,
        uint _sharesExponent
    )
        external
        returns(address)
    {
        address clone = createClone(libraryAddress);
        DeconetPaymentsSplitting(clone).setUpDistribution(_destinations, _sharesMantissa, _sharesExponent);
        emit PaymentsSplittingCreated(clone);
        return clone;
    }
}