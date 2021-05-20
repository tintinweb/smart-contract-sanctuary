pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";
import "LivePriceETH.sol";

contract LGE is Ownable, LivePrice {
    using SafeMath for uint256;

    address[] internal investor;
    mapping(address => uint256) public amount;
    mapping(address => uint256) internal score;

    uint256 public totalRaised;
    uint256 public endTime;

    mapping(address => uint256) allowed;

    PreLGEInterface preLGE;
    UniSwapRouter UniSwap;
    UniSwapFactory Factory;
    SWNInterface SWN;
    STBLInterface STBL;
    LiquidityLock LiquidityContract;
    uint256 oracleValueDivisor;
    uint256 maxMintableSWN;
    uint256 decimals;
    address DAI;
    TokenInterface _DAI;

    constructor() {
      endTime = block.timestamp.add(1210000); // Open for Two Weeks
      preLGE = PreLGEInterface(0xB23d4420ca5ffBB3C5C32Ef44e404e7B8C113314);
      UniSwap = UniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      Factory = UniSwapFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
      oracleValueDivisor = 10**8;
      decimals = 10**18;
      DAI = address(0x4AB968f8662007Ad5ebB8558569321A25aEEb335); // 0x6B175474E89094C44Da98b954EedeAC495271d0F
      maxMintableSWN = decimals.mul(5000000);
      _DAI = TokenInterface(DAI);

    }

    function invest(address _investor) public payable {
        require(block.timestamp < endTime, "Liquidity Generation Event is closed!");
        require(msg.value > 0, "No ETH sent!");
        uint256 currentPrice = uint(getLatestPrice());
        (bool _isInvestor, ) = isInvestor(_investor);
        if (!_isInvestor) {
          investor.push(_investor);
        }
        amount[_investor] = amount[_investor].add(msg.value);
        totalRaised = totalRaised.add(msg.value);

        uint256 currentScore = currentPrice.mul(msg.value).div(oracleValueDivisor);
        score[_investor] = score[_investor].add(currentScore);
      }

    function isInvestor(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < investor.length; s += 1){
            if (_address == investor[s]) return (true, s);
        }
        return (false, 0);
    }
    function getInvestors()
        public

        view
        returns(address[] memory)
    {
        return investor;
    }

    function getScores() public view returns (uint256[] memory) {
      uint256[] memory scores = new uint256[](investor.length);
      for (uint256 s = 0; s < investor.length; s += 1){
        scores[s] = score[investor[s]];
      }
      return scores;
    }

    function getTotalScore() public view returns (uint256 totalScore) {
      for (uint256 s = 0; s < investor.length; s += 1){
        totalScore = totalScore.add(score[investor[s]]);
      }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function endLGE(uint256 _swapSlippage) public onlyOwner {
      endTime = block.timestamp;

      uint256 totalLGEScore = getTotalScore().add(preLGE.getTotalScore());
      uint256 amountToSend = totalRaised.div(2);
      (address[] memory LGEInvestors, uint256[] memory LGEScores) = concatenateInvestorArrays();
      uint256 amountOut = _DAI.balanceOf(address(this)); //swapETHtoDAI(amountToSend, _swapSlippage);
      uint256 amountSTBL = STBL.createSTBL(DAI, amountOut, 5);
      uint256 amountSWN = amountOut.mul(5);
      if(amountSWN > maxMintableSWN) amountSWN = maxMintableSWN;
      SWN.mint(address(this), amountSWN);
      (, , uint256 amountLP) = UniSwap.addLiquidity(address(SWN), address(STBL), amountSWN, amountSTBL, amountSWN.mul(80).div(100), amountSTBL.mul(80).div(100), address(this), block.timestamp.add(180));
      address liquidityToken = Factory.getPair(address(SWN), address(STBL));
      LiquidityContract.pushPermanentLockFromLGE(liquidityToken, amountLP, LGEInvestors, individualLiquidityTokenAmount(amountLP, totalLGEScore, LGEScores));
    }

    function concatenateInvestorArrays() internal returns(address[] memory, uint256[] memory){
      address[] memory LGEInvestors = preLGE.getInvestors();
      uint256[] memory LGEScores = preLGE.getScores();
      uint256 length1 = LGEInvestors.length;
      uint256 length2 = investor.length;
      address[] memory investorArray = new address[](length1.add(length2));
      uint256[] memory scoreArray = new uint256[](length1.add(length2));
      for (uint256 s = 0; s < length1; s += 1){
        investorArray[s] = LGEInvestors[s];
        scoreArray[s] = LGEScores[s];
      }
      for (uint256 s = 0; s < length2; s += 1){
        investorArray[length1 + s] = investor[s];
        scoreArray[length1 + s] = score[investor[s]];
      }
      return(investorArray, scoreArray);
    }
    function swapETHtoDAI(uint amountToSend, uint swapSlippage) internal returns (uint256 amountOut) {
      require(0 < swapSlippage && swapSlippage <= 100, "Slippage out of bounds!");
        address[] memory path = new address[](2);
      path[0] = UniSwap.WETH();
      path[1] = DAI; // DAI
      uint priceFeed = uint(getLatestPrice());
      uint amountOutMin = amountToSend.mul(priceFeed).div(oracleValueDivisor).mul(100-swapSlippage).div(100); // Accounting for slippage
      uint[] memory tradeAmounts = UniSwap.swapExactETHForTokens{value: amountToSend}(amountOutMin, path, address(this), block.timestamp.add(180));
      amountOut = tradeAmounts[tradeAmounts.length - 1];
    }

    function individualLiquidityTokenAmount(uint256 _totalLiquidityTokensCreated, uint256 totalScore, uint256[] memory scores)
    internal
    pure
    returns(uint256[] memory)
    {
      uint256[] memory liquidityTokens = new uint256[](scores.length);
      for (uint256 s = 0; s < scores.length; s += 1){
          liquidityTokens[s] =  _totalLiquidityTokensCreated.div(totalScore.div(scores[s]));
      }
      return liquidityTokens;
    }

    function pushInterfaceAddresses(address _SWN, address _STBL, address _liquidity) public onlyOwner {
      SWN = SWNInterface(_SWN);
      STBL = STBLInterface(_STBL);
      LiquidityContract = LiquidityLock(_liquidity);
    }

    function approveFor(address _address, uint256 _amount) public onlyOwner{
      allowed[_address] = allowed[_address].add(_amount);
    }

    function withdraw(address payable _to, uint256 _amount)
    public
    {
      require(_amount <= getBalance(), "Amount larger than contract holds!");
      require(allowed[_to] >= _amount, "Allowance exceeded!");
      allowed[_to] = allowed[_to].sub(_amount);
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}

interface PreLGEInterface {
  function getInvestors() external returns(address[] memory);
  function getScores() external returns (uint256[] memory);
  function getTotalScore() external returns (uint256);
}

interface UniSwapRouter {
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
  function WETH() external returns(address);
}
interface UniSwapFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface STBLInterface {
  function createSTBL(address _tokenIn, uint256 _amountIn, uint256 _slippagePercentage) external returns(uint256);
}
interface SWNInterface {
  function mint(address to, uint256 amount) external;
}
interface LiquidityLock {
  function pushPermanentLockFromLGE(address _liquidityToken, uint256 _totalLiquidityTokenAmount, address[] memory investors, uint256[] memory tokenAmount) external;
}
interface TokenInterface {
  function balanceOf(address _address) external returns(uint256);
}