pragma solidity ^0.4.18;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) pure internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public; // Some ERC20 doesn&#39;t have return
    function transferFrom(address _from, address _to, uint _value) public; // Some ERC20 doesn&#39;t have return
    function approve(address _spender, uint _value) public; // Some ERC20 doesn&#39;t have return
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract KyberNetworkContract {

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @return amount of actual dest tokens
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
    
    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev best conversion rate for a pair of tokens, if number of reserves have small differences. randomize
    /// @param src Src token
    /// @param dest Destination token
    /* solhint-disable code-complexity */
    function findBestRate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint, uint);
}

interface KULAPTradingProxy {
    // Trade event
    event Trade( ERC20 src, uint srcAmount, ERC20 dest, uint destAmount);

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @return amount of actual dest tokens
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest
    )
        public
        payable
        returns(uint);
    
    function rate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint, uint);
}

contract Dex is Ownable {
    event Trade( ERC20 src, uint srcAmount, ERC20 dest, uint destAmount);

    using SafeMath for uint256;
    ERC20 public etherERC20 = ERC20(0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    address public dexWallet = 0x7ff0F1919424F0D2B6A109E3139ae0f1d836D468; // To receive fee of the DEX network

    // list of trading proxies
    KULAPTradingProxy[] public tradingProxies;

    function _tradeEtherToToken(uint256 tradingProxyIndex, uint256 srcAmount, ERC20 dest) private returns(uint256)  {
        // Load trading proxy
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

        // Trade to proxy
        uint256 destAmount = tradingProxy.trade.value(srcAmount)(
            etherERC20,
            srcAmount, 
            dest
        );

        return destAmount;
    }

    // Receive ETH in case of trade Token -> ETH, will get ETH back from trading proxy
    function () payable {

    }

    function _tradeTokenToEther(uint256 tradingProxyIndex, ERC20 src, uint256 amount) private returns(uint256)  {
        // Load trading proxy
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

        // Approve to TradingProxy
        src.approve(tradingProxy, amount);

        // Trande with kyber
        uint256 destAmount = tradingProxy.trade(
            src, 
            amount, 
            etherERC20);
        
        return destAmount;
    }

    // Ex1: trade 0.5 ETH -> EOS
    // 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    //
    // Ex2: trade 30 EOS -> ETH
    // 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    function _trade(uint256 tradingProxyIndex, ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount) private returns(uint256)  {
        uint256 destAmount;

        // Trade ETH -> Any
        if (etherERC20 == src) {
            destAmount = _tradeEtherToToken(tradingProxyIndex, srcAmount, dest);
        
        // Trade Any -> ETH
        } else if (etherERC20 == dest) {
            destAmount = _tradeTokenToEther(tradingProxyIndex, src, srcAmount);

        // Trade Any -> Any
        } else {

        }

        // Throw exception if destination amount doesn&#39;t meet user requirement.
        assert(destAmount >= minDestAmount);

        return destAmount;
    }

    // Ex1: trade 0.5 ETH -> EOS
    // 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    //
    // Ex2: trade 30 EOS -> ETH
    // 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    function trade(uint256 tradingProxyIndex, ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount) payable public returns(uint256)  {
        uint256 destAmount;

        // Trade ETH -> Any
        if (etherERC20 == src) {
            destAmount = _trade(tradingProxyIndex, src, srcAmount, dest, 1);

            // Throw exception if destination amount doesn&#39;t meet user requirement.
            assert(destAmount >= minDestAmount);

            // Send back token to sender
            // Some ERC20 Smart contract not return Bool, so we can&#39;t check here
            // require(dest.transfer(msg.sender, destAmount));
            dest.transfer(msg.sender, destAmount);
        
        // Trade Any -> ETH
        } else if (etherERC20 == dest) {
            // Transfer token to This address
            src.transferFrom(msg.sender, address(this), srcAmount);

            destAmount = _trade(tradingProxyIndex, src, srcAmount, dest, 1);

            // Throw exception if destination amount doesn&#39;t meet user requirement.
            assert(destAmount >= minDestAmount);

            // Send back ether to sender
            // TODO: Check if amount send correctly, because solidty will not raise error when not enough amount
            msg.sender.send(destAmount);

        // Trade Any -> Any
        } else {

        }

        Trade( src, srcAmount, dest, destAmount);

        return destAmount;
    }

    // Ex1: trade 50 OMG -> ETH -> EOS
    // Step1: trade 50 OMG -> ETH
    // Step2: trade xx ETH -> EOS

    // Ex1: trade 0.5 ETH -> EOS
    // 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    //
    // Ex2: trade 30 EOS -> ETH
    // 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    function tradeRoutes(ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount, address[] _tradingPaths) payable public returns(uint256)  {
        uint256 destAmount;

        if (etherERC20 != src) {
            // Transfer token to This address
            src.transferFrom(msg.sender, address(this), srcAmount);
        }

        uint256 pathSrcAmount = srcAmount;
        for (uint i=0; i < _tradingPaths.length; i+=3) {
            uint256 tradingProxyIndex =         uint256(_tradingPaths[i]);
            ERC20 pathSrc =                     ERC20(_tradingPaths[i+1]);
            ERC20 pathDest =                    ERC20(_tradingPaths[i+2]);

            destAmount = _trade(tradingProxyIndex, pathSrc, pathSrcAmount, pathDest, 1);
            pathSrcAmount = destAmount;
        }

        // Throw exception if destination amount doesn&#39;t meet user requirement.
        assert(destAmount >= minDestAmount);

        // Trade Any -> ETH
        if (etherERC20 == dest) {
            // Send back ether to sender
            // TODO: Check if amount send correctly, because solidty will not raise error when not enough amount
            msg.sender.send(destAmount);
        
        // Trade Any -> Token
        } else {
            // Send back token to sender
            // Some ERC20 Smart contract not return Bool, so we can&#39;t check here
            // require(dest.transfer(msg.sender, destAmount));
            dest.transfer(msg.sender, destAmount);
        }

        Trade( src, srcAmount, dest, destAmount);

        return destAmount;
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev best conversion rate for a pair of tokens, if number of reserves have small differences. randomize
    /// @param tradingProxyIndex index of trading proxy
    /// @param src Src token
    /// @param dest Destination token
    /// @param srcAmount Srouce amount
    /* solhint-disable code-complexity */
    function rate(uint256 tradingProxyIndex, ERC20 src, ERC20 dest, uint srcAmount) public view returns(uint, uint) {
        // Load trading proxy
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

        return tradingProxy.rate(src, dest, srcAmount);
    }

    /**
    * @dev Function for adding new trading proxy
    * @param _proxyAddress The address of trading proxy.
    * @return index of this proxy.
    */
    function addTradingProxy(
        KULAPTradingProxy _proxyAddress
    ) public onlyOwner returns (uint256) {

        tradingProxies.push( _proxyAddress );

        return tradingProxies.length;
    }
}