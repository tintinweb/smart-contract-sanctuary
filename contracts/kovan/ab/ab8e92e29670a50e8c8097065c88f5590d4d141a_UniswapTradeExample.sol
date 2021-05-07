/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

//example contract address: https://etherscan.io/address/0x1d6cbd79054b89ade7d840d1640a949ea82b7639#code

pragma solidity ^0.6.12;
abstract contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() public  virtual view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() public  virtual view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) public  virtual payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) public  virtual returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) public  virtual view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) public  virtual view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold)  public virtual view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought)  public virtual view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) virtual payable public  returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) virtual payable public  returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) virtual payable public  returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) virtual payable public  returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) virtual payable public  returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) virtual payable public  returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) virtual payable public  returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) virtual payable public  returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) virtual payable public  returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) virtual  payable public  returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) virtual payable public  returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) virtual payable  public returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) virtual payable public  returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) virtual payable public  returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) virtual payable  public returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) virtual payable public returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) virtual  public payable returns (bool);
    function transferFrom(address _from, address _to, uint256 value) virtual public   payable returns (bool);
    function approve(address _spender, uint256 _value) virtual public   payable returns (bool);
    function allowance(address _owner, address _spender) virtual public  view returns (uint256);
    function balanceOf(address _owner) virtual public  view returns (uint256);
    function totalSupply() virtual public  view returns (uint256);
    // Never use
    function setup(address token_addr) public virtual;
}

interface ERC20 {
    function totalSupply() external  view returns (uint supply);
    function balanceOf(address _owner) external   view returns (uint balance);
    function transfer(address _to, uint _value) external   returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external   returns (bool success);
    function approve(address _spender, uint _value) external   returns (bool success);
    function allowance(address _owner, address _spender) external   view returns (uint remaining);
    function decimals() external   view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface OrFeedInterface {
  function getExchangeRate ( string calldata fromSymbol, string calldata toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string calldata symbol ) external view returns ( address );
  function getSynthBytes32 ( string calldata symbol ) external view returns ( bytes32 );
  function getForexAddress ( string calldata symbol ) external view returns ( address );
}



contract UniswapTradeExample{

    function buyDai() public  payable returns(uint256){

        //token we are buying contract address... this this case DAI
        address daiAddress = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
        //Define Uniswap
        UniswapExchangeInterface usi = UniswapExchangeInterface(daiAddress);

        //amoutn of ether sent to this contract
        uint256 amountEth = msg.value;

        uint256 amountBack = usi.ethToTokenSwapInput{value:amountEth}(1, block.timestamp);

        ERC20 daiToken = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        daiToken.transfer(msg.sender, amountBack);
        return amountBack;


    }

    function getDAIPrice() public  view returns(uint256){
        OrFeedInterface orfeed= OrFeedInterface(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);
        uint256 ethPrice = orfeed.getExchangeRate("ETH", "USD", "", 100000000);
        return ethPrice;
    }



}