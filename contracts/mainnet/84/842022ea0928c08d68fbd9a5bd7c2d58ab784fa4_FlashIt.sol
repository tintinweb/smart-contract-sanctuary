/**
 *Submitted for verification at Etherscan.io on 2020-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.7.0;

interface KyberNetworkProxyInterface {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);

    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);

    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns (uint);


}

abstract contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view virtual returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view virtual returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable virtual returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external virtual returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view virtual returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view virtual returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view virtual returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view virtual returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable virtual returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable virtual returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable virtual returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable virtual returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external virtual returns (uint256  eth_bought);
    function tokenToEthTransferInput
    (uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external virtual returns (uint256  eth_bought);
    function tokenToEthSwapOutput
    (uint256 eth_bought, uint256 max_tokens, uint256 deadline) external virtual returns (uint256  tokens_sold);
    function tokenToEthTransferOutput
    (uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external virtual returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput
    (uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external virtual returns (uint256  tokens_bought);
    function tokenToTokenTransferInput
    (uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external virtual returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput
    (uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external virtual returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput
    (uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external virtual returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput
    (uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external virtual returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput
    (uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external virtual returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput
    (uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external virtual returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput
    (uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external virtual returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external virtual returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external virtual returns (bool);
    function approve(address _spender, uint256 _value) external virtual returns (bool);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function totalSupply() external view virtual returns (uint256);
    // Never use
    function setup(address token_addr) virtual external;
}

interface OrFeedInterface {
  function getExchangeRate 
  ( string calldata fromSymbol, string calldata toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string calldata symbol ) external view returns ( address );
  function getSynthBytes32 ( string calldata symbol ) external view returns ( bytes32 );
  function getForexAddress ( string calldata symbol ) external view returns ( address );
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract FlashIt {

    using SafeMath for uint256;

    address public owner;
    address public uniswapToken;
    KyberNetworkProxyInterface public kyberProxy;
    OrFeedInterface internal orfeed = OrFeedInterface(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Is not the owner");
        }
        _;
    }

    event ArbComplete(bool _success, uint256 _initialAmount, uint256 _finalAmount);

    constructor(address _kyberProxyAddress, address _uniswapProxyAddress) public {
        owner = msg.sender;
        changeKyberUniswapAddresses(_kyberProxyAddress, _uniswapProxyAddress);
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external {

        /*---Trades---*/

        kyber2UniswapArb(_reserve, _amount);

        /*---EndTrades---*/

        ERC20 _token = ERC20(_reserve);
        _token.transfer(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3, _amount.add(_fee));
        
    }

    function kyber2UniswapArb(address _tokenAddress, uint256 _amount) public onlyOwner returns (bool){

        ERC20 _token = ERC20(_tokenAddress);
        uint256 ethBack = swapToken2Ether(_token, _amount);
        uint256 tokenAmount = swapEther2Token(ethBack);

        emit ArbComplete(true, _amount, tokenAmount);
        return true;
    }

    function swapToken2Ether(ERC20 token, uint256 tokenQty) internal returns (uint256) {

        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "Balance of token equal to 0");

        if (balance < tokenQty) {
            tokenQty = balance;
        }

       token.approve(address(kyberProxy), 0);

       token.approve(address(kyberProxy), tokenQty);

        uint destAmount = kyberProxy.tradeWithHint(
           token,
           tokenQty,
           ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
           address(this),
           8000000000000000000000000000000000000000000000000000000000000000,
           0,
           0x0000000000000000000000000000000000000004,
           "PERM"
        );

        return destAmount;
    }

    function swapEther2Token(uint256 _amount) internal returns (uint256) {
        UniswapExchangeInterface usi = UniswapExchangeInterface(uniswapToken);
        usi.ethToTokenSwapInput{value: _amount}(1, block.timestamp);
    }

    function withdrawETHAndTokens(address _tokenAddress) public onlyOwner{
        msg.sender.call{value: (address(this).balance)};
        ERC20 token = ERC20(_tokenAddress);
        uint256 currentTokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, currentTokenBalance);
    }

    function changeKyberUniswapAddresses(address _kyberProxy, address _uniswapProxy) public onlyOwner {
        kyberProxy = KyberNetworkProxyInterface(_kyberProxy);
        uniswapToken = _uniswapProxy;
    }

    function getKyberSellPrice(string memory _token) public view returns (uint256){
       uint256 currentPrice =  orfeed.getExchangeRate("ETH", _token, "SELL-KYBER-EXCHANGE", 1000000000000000000);
        return currentPrice;
    }

    function getUniswapBuyPrice(string memory _token) public view returns (uint256){
       uint256 currentPrice =  orfeed.getExchangeRate("ETH", _token, "BUY-UNISWAP-EXCHANGE", 1000000000000000000);
        return currentPrice;
    }
}