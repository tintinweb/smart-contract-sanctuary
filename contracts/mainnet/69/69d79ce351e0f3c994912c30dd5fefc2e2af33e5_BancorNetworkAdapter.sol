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

contract BancorConverterInterface {
    string public converterType;
    ERC20Extended[] public quickBuyPath;
    /**
        @dev returns the length of the quick buy path array
        @return quick buy path length
    */
    function getQuickBuyPathLength() public view returns (uint256);
    /**
        @dev returns the expected return for converting a specific amount of _fromToken to _toToken

        @param _fromToken  ERC20 token to convert from
        @param _toToken    ERC20 token to convert to
        @param _amount     amount to convert, in fromToken

        @return expected conversion return amount
    */
    function getReturn(ERC20Extended _fromToken, ERC20Extended _toToken, uint256 _amount) public view returns (uint256);
    /**
        @dev converts the token to any other token in the bancor network by following a predefined conversion path
        note that when converting from an ERC20 token (as opposed to a smart token), allowance must be set beforehand

        @param _path        conversion path, see conversion path format in the BancorNetwork contract
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function quickConvert(ERC20Extended[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        returns (uint256);

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

contract BancorNetworkAdapter is OlympusExchangeAdapterInterface {
    using SafeMath for uint256;

    address public exchangeAdapterManager;
    bytes32 public exchangeId;
    bytes32 public name;
    ERC20Extended public constant ETH_TOKEN_ADDRESS = ERC20Extended(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ERC20Extended public constant bancorToken = ERC20Extended(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    ERC20Extended public constant bancorETHToken = ERC20Extended(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    mapping(address => BancorConverterInterface) public tokenToConverter;
    mapping(address => address) public tokenToRelay;

    bool public adapterEnabled;

    modifier checkArrayLengths(address[] tokenAddresses, BancorConverterInterface[] converterAddresses, address[] relayAddresses) {
        require(tokenAddresses.length == converterAddresses.length && relayAddresses.length == converterAddresses.length);
        _;
    }

    modifier checkTokenSupported(address _token) {
        BancorConverterInterface bancorConverter = tokenToConverter[_token];
        require(address(bancorConverter) != 0x0, "Token not supported");
        _;
    }

    constructor (address _exchangeAdapterManager, address[] _tokenAddresses,
    BancorConverterInterface[] _converterAddresses, address[] _relayAddresses)
    checkArrayLengths(_tokenAddresses, _converterAddresses, _relayAddresses) public {
        updateSupportedTokenList(_tokenAddresses, _converterAddresses, _relayAddresses);
        exchangeAdapterManager = _exchangeAdapterManager;
        adapterEnabled = true;
    }

    modifier onlyExchangeAdapterManager() {
        require(msg.sender == address(exchangeAdapterManager));
        _;
    }

    function updateSupportedTokenList(address[] _tokenAddresses, BancorConverterInterface[] _converterAddresses, address[] _relayAddresses)
    checkArrayLengths(_tokenAddresses, _converterAddresses, _relayAddresses)
    public onlyOwner returns (bool success) {
        for(uint i = 0; i < _tokenAddresses.length; i++){
            tokenToConverter[_tokenAddresses[i]] = _converterAddresses[i];
            tokenToRelay[_tokenAddresses[i]] = _relayAddresses[i];
        }
        return true;
    }

    function supportsTradingPair(address _srcAddress, address _destAddress) external view returns(bool supported){
        address _tokenAddress = ETH_TOKEN_ADDRESS == _srcAddress ? _destAddress : _srcAddress;
        BancorConverterInterface bancorConverter = tokenToConverter[_tokenAddress];
        return address(bancorConverter) != 0x0;
    }

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount)
    external view returns(uint expectedRate, uint slippageRate) {
        require(_amount > 0);
        bool isBuying = _sourceAddress == ETH_TOKEN_ADDRESS;
        ERC20Extended targetToken = isBuying ? _destAddress : _sourceAddress;
        BancorConverterInterface BNTConverter = tokenToConverter[address(bancorToken)];

        uint rate;
        BancorConverterInterface targetTokenConverter = tokenToConverter[address(targetToken)];

        uint ETHToBNTRate = BNTConverter.getReturn(bancorETHToken, bancorToken, _amount);


        // Bancor is a special case, it&#39;s their token
        if (targetToken == bancorToken){
            if(isBuying) {
                rate = ((ETHToBNTRate * 10**18) / _amount);
            } else {
                rate = BNTConverter.getReturn(bancorToken, bancorETHToken, _amount);
                rate = ((rate * 10**_sourceAddress.decimals()) / _amount);
            }
        } else {
            if(isBuying){
                // Get amount of tokens for the amount of BNT for amount ETH
                rate = targetTokenConverter.getReturn(bancorToken, targetToken, ETHToBNTRate);
                // Convert rate to 1ETH to token or token to 1 ETH
                rate = ((rate * 10**18) / _amount);
            } else {
                uint targetTokenToBNTRate = targetTokenConverter.getReturn(targetToken, bancorToken, 10**targetToken.decimals());
                rate = BNTConverter.getReturn(bancorToken, bancorETHToken, targetTokenToBNTRate);
                // Convert rate to 1ETH to token or token to 1 ETH
                rate = ((rate * 10**_sourceAddress.decimals()) / _amount);
            }
        }

        // TODO slippage?
        return (rate,0);
    }

    // https://support.bancor.network/hc/en-us/articles/360000878832-How-to-use-the-quickConvert-function
    function getPath(ERC20Extended _token, bool isBuying) public view returns(ERC20Extended[] tokenPath, uint resultPathLength) {
        BancorConverterInterface bancorConverter = tokenToConverter[_token];
        uint pathLength;
        ERC20Extended[] memory path;

        // When buying, we can get the path from Bancor easily, by getting the quickBuyPath from the converter address
        if(isBuying){
            pathLength = bancorConverter.getQuickBuyPathLength();
            require(pathLength > 0, "Error with pathLength");
            path = new ERC20Extended[](pathLength);

            for (uint i = 0; i < pathLength; i++) {
                path[i] = bancorConverter.quickBuyPath(i);
            }
            return (path, pathLength);
        }

        // When selling, we need to make the path ourselves

        address relayAddress = tokenToRelay[_token];

        if(relayAddress == 0x0){
            // Bancor is a special case, it&#39;s their token
            if(_token == bancorToken){
                path = new ERC20Extended[](3);
                path[0] = _token;
                path[1] = _token;
                path[2] = bancorETHToken;
                return (path, 3);
            }
            // It&#39;s a Bancor smart token, handle it accordingly
            path = new ERC20Extended[](5);
            path[0] = _token;
            path[1] = _token;
            path[2] = bancorToken;
            path[3] = bancorToken;
            path[4] = bancorETHToken;
            return (path, 5);
        }

        // It&#39;s a relay token, handle it accordingly
        path = new ERC20Extended[](5);
        path[0] = _token;                              // ERC20 Token to sell
        path[1] = ERC20Extended(relayAddress);         // Relay address (automatically converted to converter address)
        path[2] = bancorToken;                         // BNT Smart token address, as converter
        path[3] = bancorToken;                         // BNT Smart token address, as "to" and "from" token
        path[4] = bancorETHToken;                      // The Bancor ETH token, this will signal we want our return in ETH

        return (path, 5);
    }

    // In contrast to Kyber, Bancor uses a minimum return for the complete trade, instead of a minimum rate for 1 ETH (for buying) or token (when selling)
    function convertMinimumRateToMinimumReturn(ERC20Extended _token, uint _minimumRate, uint _amount, bool isBuying)
    private view returns(uint minimumReturn) {
        if(_minimumRate == 0){
            return 1;
        }

        if(isBuying){
            return (_amount * 10**18) / _minimumRate;
        }

        return (_amount * 10**_token.decimals()) / _minimumRate;
    }

    function sellToken
    (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
    ) checkTokenSupported(_token) external returns(bool success) {
        require(_token.balanceOf(address(this)) >= _amount, "Balance of token is not sufficient in adapter");
        ERC20Extended[] memory internalPath;
        ERC20Extended[] memory path;
        uint pathLength;
        (internalPath,pathLength) = getPath(_token, false);

        path = new ERC20Extended[](pathLength);
        for(uint i = 0; i < pathLength; i++) {
            path[i] = internalPath[i];
        }

        BancorConverterInterface bancorConverter = tokenToConverter[_token];

        ERC20NoReturn(_token).approve(address(bancorConverter), 0);
        ERC20NoReturn(_token).approve(address(bancorConverter), _amount);
        uint minimumReturn = convertMinimumRateToMinimumReturn(_token,_amount,_minimumRate, false);
        uint returnedAmountOfETH = bancorConverter.quickConvert(path,_amount,minimumReturn);
        require(returnedAmountOfETH > 0, "BancorConverter did not return any ETH");
        _depositAddress.transfer(returnedAmountOfETH);
        return true;
    }

    function buyToken (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
    ) checkTokenSupported(_token) external payable returns(bool success){
        require(msg.value == _amount, "Amount of Ether sent is not the same as the amount parameter");
        ERC20Extended[] memory internalPath;
        ERC20Extended[] memory path;
        uint pathLength;
        (internalPath,pathLength) = getPath(_token, true);
        path = new ERC20Extended[](pathLength);
        for(uint i = 0; i < pathLength; i++) {
            path[i] = internalPath[i];
        }

        uint minimumReturn = convertMinimumRateToMinimumReturn(_token,_amount,_minimumRate, true);
        uint returnedAmountOfTokens = tokenToConverter[address(bancorToken)].quickConvert.value(_amount)(path,_amount,minimumReturn);
        require(returnedAmountOfTokens > 0, "BancorConverter did not return any tokens");
        ERC20NoReturn(_token).transfer(_depositAddress, returnedAmountOfTokens);
        return true;
    }

    function enable() external onlyOwner returns(bool){
        adapterEnabled = true;
        return true;
    }

    function disable() external onlyOwner returns(bool){
        adapterEnabled = false;
        return true;
    }

    function isEnabled() external view returns (bool success) {
        return adapterEnabled;
    }

    function setExchangeAdapterManager(address _exchangeAdapterManager) external onlyOwner {
        exchangeAdapterManager = _exchangeAdapterManager;
    }

    function setExchangeDetails(bytes32 _id, bytes32 _name)
    external onlyExchangeAdapterManager returns(bool)
    {
        exchangeId = _id;
        name = _name;
        return true;
    }

    function getExchangeDetails()
    external view returns(bytes32 _name, bool _enabled)
    {
        return (name, adapterEnabled);
    }
}