pragma solidity 0.4.24;

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

contract ERC20NoReturn {
    uint256 public decimals;
    string public name;
    string public symbol;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public;
    function approve(address spender, uint tokens) public;
    function transferFrom(address from, address to, uint tokens) public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
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

contract ERC20Extended is ERC20 {
    uint256 public decimals;
    string public name;
    string public symbol;

}

contract OlympusExchangeAdapterManagerInterface is Ownable {
    function pickExchange(ERC20Extended _token, uint _amount, uint _rate, bool _isBuying) public view returns (bytes32 exchangeId);
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId) external view returns(bool supported);
    function getExchangeAdapter(bytes32 _exchangeId) external view returns(address);
    function isValidAdapter(address _adapter) external view returns(bool);
    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate);
}

library Utils {

    uint  constant PRECISION = (10**18);
    uint  constant MAX_DECIMALS = 18;

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        if( dstDecimals >= srcDecimals ) {
            require((dstDecimals-srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals-srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals-dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals-dstDecimals)));
        }
    }

    // function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
    //     if( srcDecimals >= dstDecimals ) {
    //         require((srcDecimals-dstDecimals) <= MAX_DECIMALS);
    //         return (PRECISION * dstQty * (10**(srcDecimals - dstDecimals))) / rate;
    //     } else {
    //         require((dstDecimals-srcDecimals) <= MAX_DECIMALS);
    //         return (PRECISION * dstQty) / (rate * (10**(dstDecimals - srcDecimals)));
    //     }
    // }
}

contract ComponentInterface {
    string public name;
    string public description;
    string public category;
    string public version;
}

contract ExchangeInterface is ComponentInterface {
    /*
     * @dev Checks if a trading pair is available
     * For ETH, use 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
     * @param address _sourceAddress The token to sell for the destAddress.
     * @param address _destAddress The token to buy with the source token.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @return boolean whether or not the trading pair is supported by this exchange provider
     */
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId)
        external view returns(bool supported);

    /*
     * @dev Buy a single token with ETH.
     * @param ERC20Extended _token The token to buy, should be an ERC20Extended address.
     * @param uint _amount Amount of ETH used to buy this token. Make sure the value sent to this function is the same as the _amount.
     * @param uint _minimumRate The minimum amount of tokens to receive for 1 ETH.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here.
     * @return boolean whether or not the trade succeeded.
     */
    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external payable returns(bool success);

    /*
     * @dev Sell a single token for ETH. Make sure the token is approved beforehand.
     * @param ERC20Extended _token The token to sell, should be an ERC20Extended address.
     * @param uint _amount Amount of tokens to sell.
     * @param uint _minimumRate The minimum amount of ETH to receive for 1 ERC20Extended token.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external returns(bool success);
}

contract KyberNetworkInterface {

    function getExpectedRate(ERC20Extended src, ERC20Extended dest, uint srcQty)
        external view returns (uint expectedRate, uint slippageRate);

    function trade(
        ERC20Extended source,
        uint srcAmount,
        ERC20Extended dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId)
        external payable returns(uint);
}

contract OlympusExchangeAdapterInterface is Ownable {

    function supportsTradingPair(address _srcAddress, address _destAddress)
        external view returns(bool supported);

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount)
        external view returns(uint expectedRate, uint slippageRate);

    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
        ) external returns(bool success);

    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
        ) external payable returns(bool success);

    function enable() external returns(bool);
    function disable() external returns(bool);
    function isEnabled() external view returns (bool success);

    function setExchangeDetails(bytes32 _id, bytes32 _name) external returns(bool success);
    function getExchangeDetails() external view returns(bytes32 _name, bool _enabled);

}

contract PriceProviderInterface is ComponentInterface {
    /*
     * @dev Returns the expected price for 1 of sourceAddress.
     * For ETH, use 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
     * @param address _sourceAddress The token to sell for the destAddress.
     * @param address _destAddress The token to buy with the source token.
     * @param uint _amount The amount of tokens which is wanted to buy.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @return returns the expected and slippage rate for the specified conversion
     */
    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate);
}

contract OlympusExchangeInterface is ExchangeInterface, PriceProviderInterface, Ownable {
    /*
     * @dev Buy multiple tokens at once with ETH.
     * @param ERC20Extended[] _tokens The tokens to buy, should be an array of ERC20Extended addresses.
     * @param uint[] _amounts Amount of ETH used to buy this token. Make sure the value sent to this function is the same as the sum of this array.
     * @param uint[] _minimumRates The minimum amount of tokens to receive for 1 ETH.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function buyTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external payable returns(bool success);

    /*
     * @dev Sell multiple tokens at once with ETH, make sure all of the tokens are approved to be transferred beforehand with the Olympus Exchange address.
     * @param ERC20Extended[] _tokens The tokens to sell, should be an array of ERC20Extended addresses.
     * @param uint[] _amounts Amount of tokens to sell this token. Make sure the value sent to this function is the same as the sum of this array.
     * @param uint[] _minimumRates The minimum amount of ETH to receive for 1 specified ERC20Extended token.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function sellTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external returns(bool success);
}

contract ComponentContainerInterface {
    mapping (string => address) components;

    event ComponentUpdated (string _name, address _componentAddress);

    function setComponent(string _name, address _providerAddress) internal returns (bool success);
    function getComponentByName(string name) public view returns (address);

}

contract DerivativeInterface is ERC20Extended, Ownable, ComponentContainerInterface {

    enum DerivativeStatus { New, Active, Paused, Closed }
    enum DerivativeType { Index, Fund }

    string public description;
    string public category;
    string public version;
    DerivativeType public fundType;

    address[] public tokens;
    DerivativeStatus public status;

    // invest, withdraw is done in transfer.
    function invest() public payable returns(bool success);
    function changeStatus(DerivativeStatus _status) public returns(bool);
    function getPrice() public view returns(uint);
}

contract FeeChargerInterface {
    // TODO: change this to mainnet MOT address before deployment.
    // solhint-disable-next-line
    ERC20Extended public MOT = ERC20Extended(0x263c618480DBe35C300D8d5EcDA19bbB986AcaeD);
    // kovan MOT: 0x41Dee9F481a1d2AA74a3f1d0958C1dB6107c686A
}

contract FeeCharger is Ownable, FeeChargerInterface {
    using SafeMath for uint256;

    FeeMode public feeMode = FeeMode.ByCalls;
    uint public feePercentage = 0;
    uint public feeAmount = 0;
    uint constant public FEE_CHARGER_DENOMINATOR = 10000;
    address private olympusWallet = 0x09227deaeE08a5Ba9D6Eb057F922aDfAd191c36c;
    bool private isPaying = false;

    enum FeeMode {
        ByTransactionAmount,
        ByCalls
    }

    modifier feePayable(uint _amount) {
      uint fee = calculateFee(_amount);
      DerivativeInterface derivative = DerivativeInterface(msg.sender);
      // take money directly from the derivative.
      require(MOT.balanceOf(address(derivative)) >= fee);
      require(MOT.allowance(address(derivative), address(this)) >= fee);
      _;
    }

    function calculateFee(uint _amount) public view returns (uint amount) {
        uint fee;
        if (feeMode == FeeMode.ByTransactionAmount) {
            fee = _amount * feePercentage / FEE_CHARGER_DENOMINATOR;
        } else if (feeMode == FeeMode.ByCalls) {
            fee = feeAmount;
        } else {
          revert("Unsupported fee mode.");
        }

        return fee;
    }    

    function adjustFeeMode(FeeMode _newMode) external onlyOwner returns (bool success) {
        feeMode = _newMode;
        return true;
    }

    function adjustFeeAmount(uint _newAmount) external onlyOwner returns (bool success) {
        feeAmount = _newAmount;
        return true;
    }    

    function adjustFeePercentage(uint _newPercentage) external onlyOwner returns (bool success) {
        require(_newPercentage <= FEE_CHARGER_DENOMINATOR);
        feePercentage = _newPercentage;
        return true;
    }    

    function setWalletId(address _newWallet) external onlyOwner returns (bool success) {
        require(_newWallet != 0x0);
        olympusWallet = _newWallet;
        return true;
    }

    function setMotAddress(address _motAddress) external onlyOwner returns (bool success) {
        require(_motAddress != 0x0);
        require(_motAddress != address(MOT));
        MOT = ERC20Extended(_motAddress);
        // this is only and will always be MOT.
        require(keccak256(abi.encodePacked(MOT.symbol())) == keccak256(abi.encodePacked("MOT")));

        return true;
    }


    /*
     * @dev Pay the fee for the call / transaction.
     * Depending on the component itself, the fee is paid differently.
     * @param uint _amountinMot The base amount in MOT, calculation should be one outside. 
     * this is only used when the fee mode is by transaction amount. leave it to zero if fee mode is
     * by calls.
     * @return boolean whether or not the fee is paid.
     */
    function payFee(uint _amountInMOT) internal feePayable(calculateFee(_amountInMOT)) returns (bool success) {
        uint _feeAmount = calculateFee(_amountInMOT);

        DerivativeInterface derivative = DerivativeInterface(msg.sender);

        uint balanceBefore = MOT.balanceOf(olympusWallet);
        require(!isPaying);
        isPaying = true;
        MOT.transferFrom(address(derivative), olympusWallet, _feeAmount);
        isPaying = false;
        uint balanceAfter = MOT.balanceOf(olympusWallet);

        require(balanceAfter == balanceBefore + _feeAmount);   
        return true;     
    }        
}

contract ExchangeProvider is FeeCharger, OlympusExchangeInterface {
    using SafeMath for uint256;
    string public name = "OlympusExchangeProvider";
    string public description =
    "Exchange provider of Olympus Labs, which additionally supports buy\and sellTokens for multiple tokens at the same time";
    string public category = "exchange";
    string public version = "v1.0";
    ERC20Extended private constant ETH  = ERC20Extended(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    OlympusExchangeAdapterManagerInterface private exchangeAdapterManager;

    constructor(address _exchangeManager) public {
        exchangeAdapterManager = OlympusExchangeAdapterManagerInterface(_exchangeManager);
        feeMode = FeeMode.ByTransactionAmount;
    }

    modifier checkAllowance(ERC20Extended _token, uint _amount) {
        require(_token.allowance(msg.sender, address(this)) >= _amount, "Not enough tokens approved");
        _;
    }

    function setExchangeAdapterManager(address _exchangeManager) external onlyOwner {
        exchangeAdapterManager = OlympusExchangeAdapterManagerInterface(_exchangeManager);
    }

    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address /* _partnerId */
        ) external payable returns(bool success) {

        require(msg.value == _amount);

        OlympusExchangeAdapterInterface adapter;
        // solhint-disable-next-line
        bytes32 exchangeId = _exchangeId == "" ? exchangeAdapterManager.pickExchange(_token, _amount, _minimumRate, true) : _exchangeId;
        if(exchangeId == 0){
            revert("No suitable exchange found");
        }

        require(payFee(msg.value * getMotPrice(exchangeId) / 10 ** 18));
        adapter = OlympusExchangeAdapterInterface(exchangeAdapterManager.getExchangeAdapter(exchangeId));
        require(
            adapter.buyToken.value(msg.value)(
                _token,
                _amount,
                _minimumRate,
                _depositAddress)
        );
        return true;
    }

    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address /* _partnerId */
        ) checkAllowance(_token, _amount) external returns(bool success) {

        OlympusExchangeAdapterInterface adapter;
        bytes32 exchangeId = _exchangeId == "" ? exchangeAdapterManager.pickExchange(_token, _amount, _minimumRate, false) : _exchangeId;
        if(exchangeId == 0){
            revert("No suitable exchange found");
        }

        uint tokenPrice;
        (tokenPrice,) = exchangeAdapterManager.getPrice(_token, ETH, _amount, exchangeId);
        require(payFee(tokenPrice  * _amount * getMotPrice(exchangeId) / 10 ** _token.decimals() / 10 ** 18));

        adapter = OlympusExchangeAdapterInterface(exchangeAdapterManager.getExchangeAdapter(exchangeId));

        ERC20NoReturn(_token).transferFrom(msg.sender, address(adapter), _amount);

        require(
            adapter.sellToken(
                _token,
                _amount,
                _minimumRate,
                _depositAddress)
            );
        return true;
    }

    function getMotPrice(bytes32 _exchangeId) private view returns (uint price) {
        (price,) = exchangeAdapterManager.getPrice(ETH, MOT, msg.value, _exchangeId);
    }

    function buyTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId, address /* _partnerId */
        ) external payable returns(bool success) {
        require(_tokens.length == _amounts.length && _amounts.length == _minimumRates.length, "Arrays are not the same lengths");
        require(payFee(msg.value * getMotPrice(_exchangeId) / 10 ** 18));
        uint totalValue;
        uint i;
        for(i = 0; i < _amounts.length; i++ ) {
            totalValue += _amounts[i];
        }
        require(totalValue == msg.value, "msg.value is not the same as total value");

        for (i = 0; i < _tokens.length; i++ ) {
            bytes32 exchangeId = _exchangeId == "" ?
            exchangeAdapterManager.pickExchange(_tokens[i], _amounts[i], _minimumRates[i], true) : _exchangeId;
            if (exchangeId == 0) {
                revert("No suitable exchange found");
            }
            require(
                OlympusExchangeAdapterInterface(exchangeAdapterManager.getExchangeAdapter(exchangeId)).buyToken.value(_amounts[i])(
                    _tokens[i],
                    _amounts[i],
                    _minimumRates[i],
                    _depositAddress)
            );
        }
        return true;
    }

    function sellTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId, address /* _partnerId */
        ) external returns(bool success) {
        require(_tokens.length == _amounts.length && _amounts.length == _minimumRates.length, "Arrays are not the same lengths");
        OlympusExchangeAdapterInterface adapter;

        uint[] memory prices = new uint[](3); // 0 tokenPrice, 1 MOT price, 3 totalValueInMOT
        for (uint i = 0; i < _tokens.length; i++ ) {
            bytes32 exchangeId = _exchangeId == bytes32("") ?
            exchangeAdapterManager.pickExchange(_tokens[i], _amounts[i], _minimumRates[i], false) : _exchangeId;
            if(exchangeId == 0){
                revert("No suitable exchange found");
            }

            (prices[0],) = exchangeAdapterManager.getPrice(_tokens[i], ETH, _amounts[i], exchangeId);
            (prices[1],) = exchangeAdapterManager.getPrice(ETH, MOT, prices[0] * _amounts[i], exchangeId);
            prices[2] += prices[0] * _amounts[i] * prices[1] / 10 ** _tokens[i].decimals() / 10 ** 18;

            adapter = OlympusExchangeAdapterInterface(exchangeAdapterManager.getExchangeAdapter(exchangeId));
            require(_tokens[i].allowance(msg.sender, address(this)) >= _amounts[i], "Not enough tokens approved");
            ERC20NoReturn(_tokens[i]).transferFrom(msg.sender, address(adapter), _amounts[i]);
            require(
                adapter.sellToken(
                    _tokens[i],
                    _amounts[i],
                    _minimumRates[i],
                    _depositAddress)
            );
        }

        require(payFee(prices[2]));

        return true;
    }

    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId) external view returns (bool){
        return exchangeAdapterManager.supportsTradingPair(_srcAddress, _destAddress, _exchangeId);
    }

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate) {
        return exchangeAdapterManager.getPrice(_sourceAddress, _destAddress, _amount, _exchangeId);
    }
}