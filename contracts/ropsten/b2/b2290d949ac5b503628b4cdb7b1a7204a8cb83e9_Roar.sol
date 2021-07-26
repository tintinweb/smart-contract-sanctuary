pragma solidity >= 0.5.17;

import "./math.sol";
import "./Manager.sol";
import "./IERC20.sol";

library useDecimal{
    using uintTool for uint;

    function m278(uint n) internal pure returns(uint){
        return n.mul(278)/1000;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}


interface ISwap{
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
	external
	returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
	external
	returns (uint[] memory amounts);
	
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
	external
	payable
	returns (uint amountToken, uint amountETH, uint liquidity);
		
	function takerWithdraw() external;
	
	function dexmint(address mintTo, uint256 amount) external returns (bool);
	
	function getPair(address tokenA, address tokenB) external view returns (address pair);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
	
	function factory() external view returns (address);
}

interface ILoadContract{
    function ContractLoader() external view returns(address);
    function FlashAddr() external view returns(address);
    function DEXAddr() external view returns(address);
    function ETHAddr() external view returns(address);
    function FDTAddr() external view returns(address);
    function FDTLPsAddr() external view returns(address);
    function RPoolAddr() external view returns(address);
    function addLiquidityP() external view returns(uint256);
    function buyFDTP() external view returns(uint256);
    function swapMaximum() external view returns(uint256);
    function PDtolerance() external view returns(uint256);
}

contract cRoar is Manager{
    using Address for address;
	
    address _LoadContractLink = 0xBa1132AeccF93ceE5e658A5De5267338C98269Db;
	uint swapLock;

	function() external payable{}
	
    function LoadContract() public view returns(address){
        return (ILoadContract(LoadContractLink())).ContractLoader();
    }
	
	function LoadContractLink() public view returns(address){
        return _LoadContractLink;
    }
	
	function FlashAddr() public view returns(address){
        return (ILoadContract(LoadContract())).FlashAddr();
    }
	
	function DEXAddr() public view returns(address){
        return (ILoadContract(LoadContract())).DEXAddr();
    }

	function ETHAddr() public view returns(address){
        return (ILoadContract(LoadContract())).ETHAddr();
    }

	function FDTAddr() public view returns(address){
        return (ILoadContract(LoadContract())).FDTAddr();
    }

	function FDTLPsAddr() public view returns(address){
        return (ILoadContract(LoadContract())).FDTLPsAddr();
    }

	function RPoolAddr() public view returns(address){
        return (ILoadContract(LoadContract())).RPoolAddr();
    }

	function getaddLiquidityP() public view returns (uint256) {
        return (ILoadContract(LoadContract())).addLiquidityP();
    }
	
	function getbuyFDTP() public view returns (uint256) {
        return (ILoadContract(LoadContract())).buyFDTP();
    }
	
	function getswapMaximum() public view returns (uint256) {
        return (ILoadContract(LoadContract())).swapMaximum();
    }
	
	function getPDtolerance() public view returns (uint256) {
        return (ILoadContract(LoadContract())).PDtolerance();
    }

}

contract Roar is cRoar, math{
    using Address for address;
    function() external payable{}
    uint swapPDAlert;
    uint[] priceHistory;
    event swapFDT(uint _amountsIn, uint _amountsOut, bool result);
	
	//----------------Swap Trade----------------------------
	//--Check FDT price from DEX--//
    function inqTokenAmountsOut(address TokenIn, address TokenOut, uint256 amountsInToken) public view returns(
        uint amountsOutETH){
		
        address[] memory path = new address[](2);
		path[0] = TokenIn;
		path[1] = TokenOut;
		uint[] memory _amountsOut = new uint[](2);
		 _amountsOut = ISwap(DEXAddr()).getAmountsOut(amountsInToken, path);

        return _amountsOut[1];
    }

	//--Swap Exact ETH to FDT from this contract--//
    function swapETHtoFDT() external payable{
		uint _tradeAmount = msg.value;
		require(_tradeAmount <= getswapMaximum(), "Roar : Swap amount is too large.");
		
		uint256 _tokenPrice = inqTokenAmountsOut(ETHAddr(), FDTAddr(), 1 * 10 ** uint256(15));
		uint256 _averagePrice = _tokenPrice;
		uint pHlength = priceHistory.length;
		if(pHlength > 5){
			uint _totalPrice = (priceHistory[pHlength - 1].add(priceHistory[pHlength - 2]).add(priceHistory[pHlength - 3]).add(priceHistory[pHlength - 4]).add(priceHistory[pHlength - 5])).div(5);
			_averagePrice = _totalPrice.mul(getPDtolerance()).div(100);
		}
		
		if(_tokenPrice > _averagePrice)
		{
			(msg.sender).transfer(_tradeAmount);
			swapPDAlert = now;
			emit swapFDT(_tradeAmount, 0, false);
		}else{
			uint256 _tokenPriceETH = _tokenPrice.div(1 * 10 ** uint256(15));
			uint256 _tokenAmountsOut = _tradeAmount.mul(_tokenPriceETH);
			uint256 _buyQLpsAmounts = _tradeAmount.mul(getbuyFDTP()).div(100);
			uint256 _addLpsAmounts = _tradeAmount.mul(getaddLiquidityP()).div(100);
			uint _thisTokenBalance = IERC20(FDTAddr()).balanceOf(address(this));
			uint256 _addLpsFDTneed = inqFDTLpsPrice().mul(_addLpsAmounts);
			
			if(_thisTokenBalance < _tokenAmountsOut.add(_addLpsFDTneed)){
				require(ISwap(FDTAddr()).dexmint(address(this), _addLpsFDTneed.sub(_thisTokenBalance)), "Value error.");
			}
			
			require(IERC20(FDTAddr()).transfer(msg.sender, _tokenAmountsOut));
			require(buyFDTFlash(_buyQLpsAmounts), "Buy FDT error.");
			require(addLiquidityFDT(_addLpsAmounts), "Add Liquidity error.");
			
			priceHistory.push(_tokenPrice);
			swapPDAlert = 0;
			emit swapFDT(_tradeAmount, _tokenAmountsOut, true);
		}
    }

	//--Add Liquidity to Lps contract--//
    function addLiquidityFDT(uint256 _addAmounts) private returns(bool){
		
		uint256 _addLpsFDTneed = inqFDTLpsPrice().mul(_addAmounts);
		require(_addLpsFDTneed <= IERC20(FDTAddr()).balanceOf(address(this)), "Roar : Not enough tokens.");
		
		uint256 _amountTokenMin = _addLpsFDTneed.mul(99).div(100);
		uint256 _amountETHMin = _addAmounts.mul(99).div(100);
		
		ISwap(DEXAddr()).addLiquidityETH.value( _addAmounts)(
			FDTAddr(),
			_addLpsFDTneed,
			_amountTokenMin,
			_amountETHMin,
			address(this),
			now.add(1800)
		);
		return true;
    }
	
	//--Buy FDT from DEX Lps this contract--//
    function buyFDTFlash(uint256 _addAmounts) private returns(bool){
		uint256 _amountTokenMin = _addAmounts.mul(90).div(100);
        address[] memory path = new address[](2);
		path[0] = ETHAddr();
		path[1] = FDTAddr();
		
		ISwap(DEXAddr().toPayable()).swapExactETHForTokens.value( _addAmounts)(
			_amountTokenMin,
			path,
			address(this),
			now.add(1800)
		);
		return true;
    }

	//--Check Lps token Price--//
    function inqFDTLpsPrice() public view returns(
        uint256 FDTAmounts){
		uint256 _balanceETH = IERC20(ETHAddr()).balanceOf(FDTLPsAddr());
		uint256 _balanceFDT = IERC20(FDTAddr()).balanceOf(FDTLPsAddr());
		uint256 _FDTAmounts1ETH = _balanceFDT.div(_balanceETH);
		
        return _FDTAmounts1ETH;
    }

	//--Check FDT price from DEX 0.001ETH--//
    function inqFDTPrice() public view returns(
        uint256 FDTPrice){
		uint256 _tokenPrice = inqTokenAmountsOut(ETHAddr(), FDTAddr(), 1 * 10 ** uint256(15));
		uint256 _tokenPriceETH = _tokenPrice.div(1 * 10 ** uint256(15));
		
        return _tokenPriceETH;
    }

	//--Check FDT price history--//
    function inqFDTPriceHistory() public view returns(
        uint[] memory){
		uint pHlength = priceHistory.length;

		uint[] memory returHistory = new uint[](5);
		returHistory[0] = priceHistory[pHlength - 1];
		returHistory[1] = priceHistory[pHlength - 2];
		returHistory[2] = priceHistory[pHlength - 3];
		returHistory[3] = priceHistory[pHlength - 4];
		returHistory[4] = priceHistory[pHlength - 5];
		
        return returHistory;
    }
	
	//--Check FDT average price--//
    function inqFDTaveragePrice() public view returns(
        uint256 FDTPrice){

		uint256 _tokenPrice = inqTokenAmountsOut(ETHAddr(), FDTAddr(), 1 * 10 ** uint256(15));
		uint256 _averagePrice = _tokenPrice;
		uint pHlength = priceHistory.length;
		if(pHlength > 5){
			_averagePrice  = (priceHistory[pHlength - 1].add(priceHistory[pHlength - 2]).add(priceHistory[pHlength - 3]).add(priceHistory[pHlength - 4]).add(priceHistory[pHlength - 5])).div(5);
		}

        return _averagePrice;
    }
	
	//--Check Total Info--//
    function inqTotalInfo() public view returns(
        uint[] memory){

		uint[] memory TotalInfo = new uint[](4);
		TotalInfo[0] = inqFDTLpsPrice();       //FDT price from Lps.
		TotalInfo[1] = inqFDTPrice();          //FDT price from 1 FDT.
		TotalInfo[2] = inqFDTaveragePrice();   //FDT average price from priceHistory.
		TotalInfo[3] = swapPDAlert;            //Price down Alert.
		
        return TotalInfo;
    }
	
	
	//--Manager only--//
    function approveForDEX() internal onlyManager{
        IERC20(ETHAddr()).approve(DEXAddr(), 100000000000000000000*10**18);
        IERC20(FDTAddr()).approve(DEXAddr(), 100000000000000000000*10**18);
        IERC20(FDTLPsAddr()).approve(DEXAddr(), 100000000000000000000*10**18);
    }

	//--Manager only--//
    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }
	
	//--Manager only--//
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}