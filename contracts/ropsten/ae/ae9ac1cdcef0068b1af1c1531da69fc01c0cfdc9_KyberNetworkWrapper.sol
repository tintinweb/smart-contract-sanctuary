pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev this version copied from zeppelin-solidity, constant changed to pure
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev Adds onlyOwner modifier. Subcontracts should implement checkOwner to check if caller is owner.
 */
contract Ownable {
    modifier onlyOwner() {
        checkOwner(msg.sender);
        _;
    }

    function checkOwner(address _address) public;
}

/**
 * @title Secured
 * @dev Adds only(role) modifier. Subcontracts should implement checkRole to check if caller is allowed to do action.
 */
contract Secured is Ownable {
    modifier only(string role) {
        require(msg.sender == getRole(role));
        _;
    }

    modifier ownerOr(string role) {
        bool roleMatches = msg.sender == getRole(role);
        if (!roleMatches) {
            checkOwner(msg.sender);
        }
        _;
    }

    modifier any(string role1, string role2) {
        require(msg.sender == getRole(role1) || msg.sender == getRole(role2));
        _;
    }

    function getRole(string role) constant public returns (address);
}

/**
 * @title Sale contract for Daonomic platform should implement this
 */
contract Sale {
    /**
     * @dev This event should be emitted when user buys something
     */
    event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus, bytes txId);
    /**
     * @dev Should be emitted if new payment method added
     */
    event RateAdd(address token);
    /**
     * @dev Should be emitted if payment method removed
     */
    event RateRemove(address token);

    /**
     * @dev Calculate rate for specified payment method
     */
    function getRate(address token) constant public returns (uint256);
    /**
     * @dev Calculate current bonus in tokens
     */
    function getBonus(uint256 sold) constant public returns (uint256);
    /**
     * @dev get xpub key for payment method (if applicable)
     */
    function getXPub(address token) constant public returns (string);
}

contract AbstractSale is Ownable, Sale, Secured {
    using SafeMath for uint256;

    event Withdraw(address to, uint256 value);

    function () payable public {
        onReceivePrivate(msg.sender, address(0), msg.value, "");
    }

    function buyTokens(address _buyer) payable public {
        onReceivePrivate(_buyer, address(0), msg.value, "");
    }

    function buyTokensSigned(address _buyer, bytes _txId, uint _value, uint8 _v, bytes32 _r, bytes32 _s) payable public {
        var hash = keccak256(_value, msg.sender);
        require(ecrecover(hash, _v, _r, _s) == getRole("signer"));
        onReceivePrivate(_buyer, address(0), _value, _txId);
    }

    function onReceive(address _buyer, address _token, uint256 _value, bytes _txId) only("operator") public {
        require(_token != address(0));
        onReceivePrivate(_buyer, _token, _value, _txId);
    }

    function onReceivePrivate(address _buyer, address _token, uint256 _value, bytes _txId) private {
        uint256 sold = getSold(_token, _value);
        require(sold > 0);
        uint256 bonus = getBonus(sold);
        checkPurchaseValid(_buyer, sold, bonus);
        doPurchase(_buyer, sold, bonus);
        emit Purchase(_buyer, _token, _value, sold, bonus, _txId);
        onPurchase(_buyer, _token, _value, sold, bonus);
    }

    function getSold(address _token, uint256 _value) constant public returns (uint256) {
        uint256 rate = getRate(_token);
        require(rate > 0);
        return _value.mul(rate).div(10**18);
    }

    function getBonus(uint256 sold) constant public returns (uint256);

    function getRate(address _token) constant public returns (uint256);

    function doPurchase(address buyer, uint256 sold, uint256 bonus) internal;

    function checkPurchaseValid(address /*buyer*/, uint256 /*sold*/, uint256 /*bonus*/) internal {

    }

    function onPurchase(address /*buyer*/, address /*token*/, uint256 /*value*/, uint256 /*sold*/, uint256 /*bonus*/) internal {

    }

    function canBuy(address _address) constant public returns (bool) {
        return true;
    }

    function withdrawEth(address _to, uint256 _value) onlyOwner public {
        _to.transfer(_value);
        emit Withdraw(_to, _value);
    }

    function getXPub(address token) constant public returns (string) {
        return "";
    }
}

contract BasicToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract Token is BasicToken {
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @title Kyber Network interface
contract KyberNetworkProxyInterface {
  function maxGasPrice() public view returns(uint);
  function getUserCapInWei(address user) public view returns(uint);
  function getUserCapInTokenWei(address user, Token token) public view returns(uint);
  function enabled() public view returns(bool);
  function info(bytes32 id) public view returns(uint);

  function getExpectedRate(Token src, Token dest, uint srcQty) public view
  returns (uint expectedRate, uint slippageRate);

  function tradeWithHint(Token src, uint srcAmount, Token dest, address destAddress, uint maxDestAmount,
    uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}

contract KyberNetworkWrapper {

  event ETHReceived(address indexed sender, uint amount);

  Token constant internal ETH_TOKEN_ADDRESS = Token(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  function() payable {
    emit ETHReceived(msg.sender, msg.value);
  }

  /// @dev Get the ETH price of the selling token (one full token, not cent)
  function getETHPrice(AbstractSale _sale) public view returns (uint ethPrice) {
    uint256 rate = _sale.getRate(address(0));
    ethPrice = 1 * 10 ** 36 / rate;
  }

  /// @dev Get the rate for user&#39;s token
  /// @param _kyberProxy KyberNetworkProxyInterface address
  /// @param token ERC20 token address
  /// @return expectedRate, slippageRate
  function getTokenRate(
    KyberNetworkProxyInterface _kyberProxy,
    AbstractSale _sale,
    Token token
  )
  public
  view
  returns (uint, uint)
  {
    uint256 ethPrice = getETHPrice(_sale);

    // Get the expected and slippage rates of the token to ETH
    (uint expectedRate, uint slippageRate) = _kyberProxy.getExpectedRate(token, ETH_TOKEN_ADDRESS, ethPrice);

    return (expectedRate, slippageRate);
  }

  /// @dev Acquires selling token using Kyber Network&#39;s supported token
  /// @param _kyberProxy KyberNetworkProxyInterface address
  /// @param _sale Sale address
  /// @param token ERC20 token address
  /// @param tokenQty Amount of tokens to be transferred by user
  /// @param maxDestQty Max amount of eth to contribute
  /// @param minRate The minimum rate or slippage rate.
  /// @param walletId Wallet ID where Kyber referral fees will be sent to
  function tradeAndBuy(
    KyberNetworkProxyInterface _kyberProxy,
    AbstractSale _sale,
    Token token,
    uint tokenQty,
    uint maxDestQty,
    uint minRate,
    address walletId
  )
  public
  {
    // Check if user is allowed to buy
    require(_sale.canBuy(msg.sender));

    // Check that the user has transferred the token to this contract
    require(token.transferFrom(msg.sender, this, tokenQty));

    // Get the starting token balance of the wrapper&#39;s wallet
    uint startTokenBalance = token.balanceOf(this);

    // Mitigate ERC20 Approve front-running attack, by initially setting
    // allowance to 0
    require(token.approve(_kyberProxy, 0));

    // Verify that the token balance has not decreased from front-running
    require(token.balanceOf(this) == startTokenBalance);

    // Once verified, set the token allowance to tokenQty
    require(token.approve(_kyberProxy, tokenQty));

    // Swap user&#39;s token to ETH to send to Sale contract
    uint userETH = _kyberProxy.tradeWithHint(token, tokenQty, ETH_TOKEN_ADDRESS, address(this), maxDestQty, minRate, walletId, "");

    _sale.buyTokens.value(userETH)(msg.sender);
  }

}