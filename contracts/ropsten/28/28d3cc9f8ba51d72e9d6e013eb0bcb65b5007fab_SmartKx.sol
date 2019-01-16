pragma solidity ^0.4.24;

contract SmartKx {
  address public keyOwner;              // owner key
  address public keyManager;            // manager key
  string public eMap;                   // encrypted account map
  uint8 public numAccounts;             // number of accounts
  uint48[] public breaks;               // break points
  uint48[] public rates;                // rates as integer
  mapping(uint16 => mapping(uint8 => mapping(uint8 => uint48))) public accounts;


  // This is the constructor which registers the owner, manager, number of accounts, encrypted map
  constructor(
    address _keyManager,
    uint8 _numAccounts,
    string _eMap,
    uint48[] _breaks,
    uint48[] _rates
  )
    public
  {
    require(_breaks.length == _rates.length, "Number of breaks must equal number of rates");

    keyOwner = msg.sender;              // owner key is msg.sender
    keyManager = _keyManager;           // manager key
    numAccounts = _numAccounts;         // number of accounts
    eMap = _eMap;                       // encrypted map
    breaks = _breaks;                   // break points
    rates = _rates;                     // rates
  }

//***************** Modifiers *****************//

  // Ensures the year is correct
  modifier isValidYear(uint16 _Year) {
    require(_Year > 2017, &#39;Invalid year&#39;);
    require(_Year < 2048, &#39;Invalid year&#39;);
    _;
  }

  // Ensures the quarter is correct
  modifier isValidQuarter(uint8 _Quarter) {
    require(_Quarter > 0, &#39;Invalid quarter&#39;);
    require(_Quarter < 5, &#39;Invalid quarter&#39;);
    _;
  }

  // Ensures the account number is correct
  modifier isValidAccount(uint8 _Account) {
    require(_Account < numAccounts, &#39;Invalid account number&#39;);
    _;
  }



//*********** EVENTS **************************//

  event ReportAum(uint);
  event ReportSplits(uint48[]);
  event ReportFeeTotal(uint);

//*********** EXTERNAL FUNCTIONS **************//

  // Specify the year, quarter, account number and value
  function setAccountValue(
    uint16 _year,
    uint8 _quarter,
    uint8 _account,
    uint48 _value
  )
    isValidYear(_year)
    isValidQuarter(_quarter)
    isValidAccount(_account)
    public
    payable
    returns (uint48)
  {
    accounts[_year][_quarter][_account] = _value;
    return _value;
  }

  // getAccountValue
  function getAccountValue(
    uint16 _year,
    uint8 _quarter,
    uint8 _account
  )
    isValidYear(_year)
    isValidQuarter(_quarter)
    isValidAccount(_account)
    public
    view
    returns (uint48)
  {
    return accounts[_year][_quarter][_account];
  }

  // getAccountValues
  function getAccountValues(
    uint16 _year,
    uint8 _quarter
  )
    isValidYear(_year)
    isValidQuarter(_quarter)
    public
    view
    returns (uint48[])
  {
    uint48[] values;
    
    for (uint8 i = 0; i < numAccounts; i++) {
      values[i] = accounts[_year][_quarter][i];
    }

    return values;
  }

  // getFeeSchedule
  function getFeeSchedule()
    public
    view
    returns (uint48[], uint48[])
  {
    
  }


  function calculate(
    uint16 _year,
    uint8 _quarter
  )
    public
    view
    isValidYear(_year)
    isValidQuarter(_quarter)
    //returns(
    //     sha3 hash //contract number (so as to reference the hardcopy contract, etc.)
    //     household 
    //     account number
    //     fee structure // variable
    //     contract (when it was signed and cast)
    //     quarter it calculated fees for
    //     account value 
    //     resulting amount due
    //     (all the blockchain info to verify data)    
    // )
  {
    
    // Account Scope by year/quarter
    mapping(uint8 => uint48) target = accounts[_year][_quarter];

    uint8 i; // universal iterator // ignore for the most part

    uint48 aum = 0; // set total to zero // assets under management total across accounts

    uint48 feeTotal = 0;   // total fee from all accounts
    uint48[] splits;  // splits holds the grandTotal stratified by breaks // 1m, 2m, 1.43m on 4,430,000
    uint48[] feesBySplit; // fees spread across accounts // .10 * 1m, .08 * 2m, .6 * 1.43m on 4,430,000
    uint48[] spread;  //
    uint48[] feesByAccount; // fees spread across accounts



    // loop through accounts and return total aum
    for (i = 0; i < numAccounts; i++) {
      aum += target[i];
    }

    emit ReportAum(aum);
    
    // loop through breaks and chop up grandTotal
    // should yeild 1m, 2m, 1.43m on 4,430,000
    uint48 tempAum = aum;
    for (i = uint8(breaks.length); i >= 0; i--) {
      splits[i] = uint48(ceil(breaks[i], tempAum)); // use ceil for grabbing everything off the bottom of the total up to a max (breaks[i])
      tempAum = uint48(sub(tempAum, splits[i])); // even if splits or remainder are zero, this should work (0 - 0)
    }

    emit ReportSplits(splits);

    // loop through accounts and return total fee
    for (i = 0; i < splits.length; i++) {
      feeTotal += (splits[i] * 10) * rates[i];
    }

    emit ReportFeeTotal(feeTotal);

  }



//*********** HELPERS *************************//

  function ceil(uint a, uint m) internal pure returns (uint) {
    return ((a + m - 1) / m) * m;
  }

  function calculatePercentage(uint48 theNumber, uint48 bps) public view returns (uint128) {
    return uint128(int256(theNumber) * int256(bps) / int256(10000));
  }



//*********** SAFE MATH ***********************//

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }


}