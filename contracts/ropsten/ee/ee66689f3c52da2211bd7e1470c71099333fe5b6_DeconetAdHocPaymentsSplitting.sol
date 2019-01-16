pragma solidity 0.4.25;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="553134233015343e3a3837347b363a38">[email&#160;protected]</a>
// released under Apache 2.0 licence
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

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}

/// @title simple interface for Kyber Network
interface SimpleNetworkInterface {
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint);
}
contract DeconetAdHocPaymentsSplitting {
    using SafeMath for uint;

    // Logged when funds go out
    event FundsOut (
        uint amount,
        address destination,
        ERC20 token,
        uint tokenAmount
    );

    // Logged when funds come in
    event FundsIn (
        uint amount,
        string memo
    );

    // 0x818E6FECD516Ecc3849DAf6845e3EC868087B755 for ropsten
    KyberNetworkProxyInterface internal kyberNetworkProxy;


    // copied from kyber contract
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    constructor(address _kyberNetworkProxyAddress) {
        kyberNetworkProxy = KyberNetworkProxyInterface(_kyberNetworkProxyAddress);
    }

    /**
     * @dev Disabled fallback payable function
     */
    function () public payable {
        revert(); // disable fallback function
    }

    /**
     * @dev Send funds to destinations
     * @param _destinations Destination addresses of the current payment.
     * @param _amounts Amounts for destinations ordered respectively with `_destinations`.
     * @param _outCurrencies Output currencies for every destination and ordered respectively with `_destinations`.
     * @param _memo A string memo.
     */
    function sendFunds(
        address[] _destinations,
        uint[] _amounts,
        ERC20[] _outCurrencies,
        string _memo
    )
        public
        payable
    {
        require(
            _destinations.length <= 8 && _destinations.length > 0,
            "There is a maximum of 8 destinations allowed"
        );  // max of 8 destinations
        // ensure that lengths of arrays match so array out of bounds can&#39;t happen
        require(
            _destinations.length == _amounts.length,
            "Length of destinations does not match length of amounts"
        );
        // ensure that lengths of arrays match so array out of bounds can&#39;t happen
        require(
            _destinations.length == _outCurrencies.length,
            "Length of destinations does not match length of outCurrencies"
        );

        uint balance = msg.value;
        emit FundsIn(balance, _memo);

        // ensure amounts sum correctly to `balance`.
        uint sum = 0;

        // loop over destinations and send out funds
        for (uint i = 0; i < _destinations.length; i++) {
            address destination = _destinations[i];
            ERC20 outCurrency = _outCurrencies[i];

            uint amount = _amounts[i];
            uint sent = amount;
            if (outCurrency == ETH_TOKEN_ADDRESS) {
                destination.transfer(amount);
            } else {
                sent = swapEtherToTokenAndTransfer(amount, outCurrency, destination);
            }

            emit FundsOut(amount, destination, outCurrency, sent);

            sum = sum.add(amount);
        }
        require(sum == balance, "The sum of all amounts should be equal balance but it does not");
    }

    //@dev assumed to be receiving ether wei
    //@param token destination token contract address
    //@param destAddress address to send swapped tokens to
    function swapEtherToTokenAndTransfer (uint256 amount, ERC20 token, address destAddress) internal returns (uint) {
        uint minRate;
        (, minRate) = kyberNetworkProxy.getExpectedRate(ETH_TOKEN_ADDRESS, token, amount);
        require(minRate != 0, "The conversion rate returned by Kyber is 0 which means the Kyber swap will not be processed");

        bytes memory hint;

        uint destAmount = kyberNetworkProxy.tradeWithHint.value(amount)(
            ETH_TOKEN_ADDRESS, // src token
            amount, // amount to convert
            token, // token to convert to
            destAddress, // where to send tokens to
            2**255, // max destintation amount.  should always be bigger than amount converted
            minRate, // min conversion rate
            address(0x0), // fee sharing wallet id.  should be 0x0
            hint // hint bytes.  should be empty
        );
        require(destAmount > 0, "Your ETH could not be converted via the Kyber Network");

        return destAmount;
    }
}