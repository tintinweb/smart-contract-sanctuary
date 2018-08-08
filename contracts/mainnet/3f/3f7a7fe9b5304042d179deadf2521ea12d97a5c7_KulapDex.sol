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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title ERC20
 * @dev The ERC20 interface has an standard functions and event
 * for erc20 compatible token on Ethereum blockchain.
 */
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external; // Some ERC20 doesn&#39;t have return
    function transferFrom(address _from, address _to, uint _value) external; // Some ERC20 doesn&#39;t have return
    function approve(address _spender, uint _value) external; // Some ERC20 doesn&#39;t have return
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title KULAP Trading Proxy
 * @dev The KULAP trading proxy interface has an standard functions and event
 * for other smart contract to implement to join KULAP Dex as Market Maker. 
 */
interface KULAPTradingProxy {
    // Trade event
    /// @dev when new trade occure (and success), this event will be boardcast. 
    /// @param src Source token
    /// @param srcAmount amount of source tokens
    /// @param dest   Destination token
    /// @return amount of actual destination tokens
    event Trade( ERC20 src, uint srcAmount, ERC20 dest, uint destAmount);

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Source token
    /// @param dest   Destination token
    /// @param srcAmount amount of source tokens
    /// @return amount of actual destination tokens
    function trade(
        ERC20 src,
        ERC20 dest,
        uint srcAmount
    )
        external
        payable
        returns(uint);
    
    /// @dev provite current rate between source and destination token 
    ///      for given source amount
    /// @param src Source token
    /// @param dest   Destination token
    /// @param srcAmount amount of source tokens
    /// @return current reserve and rate
    function rate(
        ERC20 src, 
        ERC20 dest, 
        uint srcAmount
    ) 
        external 
        view 
        returns(uint, uint);
}

contract KulapDex is Ownable {
    event Trade(
        // Source
        address indexed _srcAsset,
        uint256         _srcAmount,

        // Destination
        address indexed _destAsset,
        uint256         _destAmount,

        // User
        address indexed _trader, 

        // System
        uint256          fee
    );

    using SafeMath for uint256;
    ERC20 public etherERC20 = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // address public dexWallet = 0x7ff0F1919424F0D2B6A109E3139ae0f1d836D468; // To receive fee of the KULAP Dex network

    // list of trading proxies
    KULAPTradingProxy[] public tradingProxies;

    function _tradeEtherToToken(
        uint256 tradingProxyIndex, 
        uint256 srcAmount, 
        ERC20 dest
        ) 
        private 
        returns(uint256)  {
        // Load trading proxy
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

        // Trade to proxy
        uint256 destAmount = tradingProxy.trade.value(srcAmount)(
            etherERC20,
            dest,
            srcAmount
        );

        return destAmount;
    }

    // Receive ETH in case of trade Token -> ETH, will get ETH back from trading proxy
    function () public payable {

    }

    function _tradeTokenToEther(
        uint256 tradingProxyIndex, 
        ERC20 src, 
        uint256 srcAmount
        ) 
        private 
        returns(uint256)  {
        // Load trading proxy
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

        // Approve to TradingProxy
        src.approve(tradingProxy, srcAmount);

        // Trande to proxy
        uint256 destAmount = tradingProxy.trade(
            src, 
            etherERC20,
            srcAmount
        );
        
        return destAmount;
    }

    // Ex1: trade 0.5 ETH -> EOS
    // 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    //
    // Ex2: trade 30 EOS -> ETH
    // 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    function _trade(
        uint256             _tradingProxyIndex, 
        ERC20               _src, 
        uint256             _srcAmount, 
        ERC20               _dest, 
        uint256             _minDestAmount
    ) private returns(uint256)  {
        // Destination amount
        uint256 destAmount;

        // Record src/dest asset for later consistency check.
        uint256 srcAmountBefore;
        uint256 destAmountBefore;
        // Source
        if (etherERC20 == _src) {
            srcAmountBefore = address(this).balance;
        } else {
            srcAmountBefore = _src.balanceOf(this);
        }
        // Dest
        if (etherERC20 == _dest) {
            destAmountBefore = address(this).balance;
        } else {
            destAmountBefore = _dest.balanceOf(this);
        }

        // Trade ETH -> Token
        if (etherERC20 == _src) {
            destAmount = _tradeEtherToToken(_tradingProxyIndex, _srcAmount, _dest);
        
        // Trade Token -> ETH
        } else if (etherERC20 == _dest) {
            destAmount = _tradeTokenToEther(_tradingProxyIndex, _src, _srcAmount);

        // Trade Token -> Token
        // For token -> token use tradeRoutes instead
        } else {
            revert();
        }

        // Recheck if src/dest amount correct
        // Source
        if (etherERC20 == _src) {
            assert(address(this).balance == srcAmountBefore.sub(_srcAmount));
        } else {
            assert(_src.balanceOf(this) == srcAmountBefore.sub(_srcAmount));
        }
        // Dest
        if (etherERC20 == _dest) {
            assert(address(this).balance == destAmountBefore.add(destAmount));
        } else {
            assert(_dest.balanceOf(this) == destAmountBefore.add(destAmount));
        }

        // Throw exception if destination amount doesn&#39;t meet user requirement.
        assert(destAmount >= _minDestAmount);

        return destAmount;
    }

    // Ex1: trade 0.5 ETH -> EOS
    // 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    //
    // Ex2: trade 30 EOS -> ETH
    // 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    function trade(uint256 tradingProxyIndex, ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount) payable public returns(uint256)  {
        uint256 destAmount;

        // Trade ETH -> Token
        if (etherERC20 == src) {
            destAmount = _trade(tradingProxyIndex, src, srcAmount, dest, 1);

            // Throw exception if destination amount doesn&#39;t meet user requirement.
            assert(destAmount >= minDestAmount);

            // Send back token to sender
            // Some ERC20 Smart contract not return Bool, so we can&#39;t check here
            // require(dest.transfer(msg.sender, destAmount));
            dest.transfer(msg.sender, destAmount);
        
        // Trade Token -> ETH
        } else if (etherERC20 == dest) {
            // Transfer token to This address
            src.transferFrom(msg.sender, address(this), srcAmount);

            destAmount = _trade(tradingProxyIndex, src, srcAmount, dest, 1);

            // Throw exception if destination amount doesn&#39;t meet user requirement.
            assert(destAmount >= minDestAmount);

            // Send back ether to sender
            // Throws on failure
            msg.sender.transfer(destAmount);

        // Trade Token -> Token
        // For token -> token use tradeRoutes instead
        } else {
            revert();
        }

        emit Trade( src, srcAmount, dest, destAmount, msg.sender, 0);
        

        return destAmount;
    }

    // Ex1: trade 50 OMG -> ETH -> EOS
    // Step1: trade 50 OMG -> ETH
    // Step2: trade xx ETH -> EOS
    // "0x5b9a857e0C3F2acc5b94f6693536d3Adf5D6e6Be", "30000000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "1", ["0x0000000000000000000000000000000000000000", "0x5b9a857e0C3F2acc5b94f6693536d3Adf5D6e6Be", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "0x0000000000000000000000000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817"]
    //
    // Ex2: trade 50 OMG -> ETH -> DAI
    // Step1: trade 50 OMG -> ETH
    // Step2: trade xx ETH -> DAI
    // "0x5b9a857e0C3F2acc5b94f6693536d3Adf5D6e6Be", "30000000000000000000", "0x45ad02b30930cad22ff7921c111d22943c6c822f", "1", ["0x0000000000000000000000000000000000000000", "0x5b9a857e0C3F2acc5b94f6693536d3Adf5D6e6Be", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "0x0000000000000000000000000000000000000001", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "0x45ad02b30930cad22ff7921c111d22943c6c822f"]
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
            // Throws on failure
            msg.sender.transfer(destAmount);
        
        // Trade Any -> Token
        } else {
            // Send back token to sender
            // Some ERC20 Smart contract not return Bool, so we can&#39;t check here
            // require(dest.transfer(msg.sender, destAmount));
            dest.transfer(msg.sender, destAmount);
        }

        emit Trade( src, srcAmount, dest, destAmount, msg.sender, 0);

        return destAmount;
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev best conversion rate for a pair of tokens, if number of reserves have small differences. randomize
    /// @param tradingProxyIndex index of trading proxy
    /// @param src Source token
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