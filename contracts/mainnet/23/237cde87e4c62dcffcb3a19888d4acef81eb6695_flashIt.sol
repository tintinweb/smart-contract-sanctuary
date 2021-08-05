/**
 *Submitted for verification at Etherscan.io on 2020-05-04
*/

pragma solidity >=0.4.26;

pragma experimental ABIEncoderV2;

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata  hint) external payable returns(uint);
    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns (uint);
}

abstract contract IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() virtual external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() virtual external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) virtual external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) virtual external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) virtual external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) virtual external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) virtual external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) virtual external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) virtual external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) virtual external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) virtual external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) virtual external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) virtual external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) virtual external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) virtual external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) virtual external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) virtual external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) virtual external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) virtual external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) virtual external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) virtual external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) virtual external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) virtual external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) virtual external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) virtual external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) virtual external returns (bool);
    function approve(address _spender, uint256 _value) virtual external returns (bool);
    function allowance(address _owner, address _spender) virtual external view returns (uint256);
    function balanceOf(address _owner) virtual external view returns (uint256);
    function totalSupply() virtual external view returns (uint256);
    // Never use
    function setup(address token_addr) virtual external;
}
interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function totalSupply() external view returns (uint);
  function approve(address guy, uint wad) external returns (bool);
  function transfer(address dst, uint wad) external returns (bool);
  function transferFrom(address src, address dst, uint wad) external returns (bool);
  //function() external payable;
}

interface IUniswapFactory {
    function createExchange(address token) external returns (address exchange);
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    function initializeFactory(address template) external;
}






interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

abstract contract IERC20Token {
    function name() public view returns (string memory) {this;}
    function symbol() public view returns (string memory) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
}

/*interface OrFeedInterface {
  function getExchangeRate ( string fromSymbol, string toSymbol, string  venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string  symbol ) external view returns ( address );
  function getSynthBytes32 ( string  symbol ) external view returns ( bytes32 );
  function getForexAddress ( string  symbol ) external view returns ( address );
  function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string[] tokens,  uint256 amount, string[] exchanges) external payable returns (bool);
}*/

interface OrFeedInterface {
  function getExchangeRate ( string calldata fromSymbol, string calldata toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string calldata symbol ) external view returns ( address );
  function getSynthBytes32 ( string calldata symbol ) external view returns ( bytes32 );
  function getForexAddress ( string calldata symbol ) external view returns ( address );
  function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string[]calldata tokens,  uint256 amount, string[] calldata exchanges) external payable returns (bool);
  //function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string calldata, tokens,  uint256 amount, string[] exchanges) external payable returns (bool);
//function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string calldata tokens,  uint256 amount, string calldata exchanges) external payable returns (bool);
}
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

interface IBancorNetwork {
    function getReturnByPath(address[] calldata  _path, uint256 _amount) external view returns (uint256, uint256);
    function convert2(address[] calldata _path, uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);

    function claimAndConvert2(
        address[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external returns (uint256);
}
interface IBancorNetworkPathFinder {
    function generatePath(address _sourceToken, address _targetToken) external view returns (address[] memory);
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal view returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal view returns(uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal view returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal view returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract flashIt{
    
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata  _params) external {


    ERC20 theToken = ERC20(_reserve);

        //place the arb you would like to perform below

        OrFeedInterface orfeed= OrFeedInterface(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);

        //approve the token you are starting  (tokenOrder element 0 below)with (so that the orfeed contract perform its operations below )
        theToken.approve(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336, 10000000000000000000000000000);
        
         //string[] memory tokenOrder = new string[](3);
         //string[] memory exchangeOrder = new string[](3);
         
         string[] memory tokenOrder = new string[](2);
         string[] memory exchangeOrder = new string[](2);
         
         tokenOrder[0]= "DAI";
         //tokenOrder[1]= "WETH";
         //tokenOrder[2]= "SAI";
         
         tokenOrder[1]= "ETH";
         
         
         //exchangeOrder[0]= "KYBER";
         //exchangeOrder[1]= "KYBER";
         //exchangeOrder[2]= "KYBER";
         
         exchangeOrder[0]= "KYBER";
         exchangeOrder[1]= "BANCOR";
         
         
         
        orfeed.arb((address(this)), (address(this)), tokenOrder, _amount, exchangeOrder);
      
        //transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
        theToken.transfer(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3, (_amount+ _fee));
    
    }
}