pragma solidity >=0.5.0 <0.6.0;

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

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
	
    function swapExactHTForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactHT(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForHT(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapHTForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
		
	function takerWithdraw() external;
	
    function dexmint(address mintTo, uint256 amount) external returns (bool);
	
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external view returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
	
	function factory() external view returns (address);
}

contract cFlashSwap is Manager{
    using Address for address;
    using Sort for uint[];
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelistSwap;
    EnumerableSet.AddressSet private _whitelist;
    EnumerableSet.AddressSet private _swapNamelist;
    EnumerableSet.AddressSet private _tokenNamelist;
	
	uint airdropRate = 10000; // = 1X of swap value.
    address _ETHAddr;
    address _FDTAddr;
	function() external payable{}
	
	function ETHAddr() public view returns(address){
        require(_ETHAddr != address(0), "It's a null address");
        return _ETHAddr;
    }
	
	function setETHAddr(address addr) public onlyManager{
        _ETHAddr = addr;
    }
	
	function FDTAddr() public view returns(address){
        require(_FDTAddr != address(0), "It's a null address");
        return _FDTAddr;
    }
	
	function setFDTAddr(address addr) public onlyManager{
        _FDTAddr = addr;
    }
	
    function setairdropRate(uint amount) public onlyManager{
        airdropRate = amount;
    }

    //----------------Whitelist Token----------------------------
	
    function addWhitelist(address _addToken) public onlyManager returns (bool) {
        require(_addToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) public onlyManager returns (bool) {
        require(_delToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.remove(_whitelist, _delToken);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address _token) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, _token);
    }

    function getWhitelist(uint256 _index) public view returns (address){
        require(_index <= getWhitelistLength() - 1, "index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    function addWhitelistAll(address[] memory _addToken) public onlyManager returns (bool) {
        uint amountToken = _addToken.length;
        for (uint i = 0; i < amountToken; i++){
			EnumerableSet.add(_whitelist, _addToken[i]);
        }
        return true;
    }
	//----------------Whitelist DEX Swap----------------------------
	
    function addWhitelistSwap(address _addSwap) public onlyManager returns (bool) {
        require(_addSwap != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_whitelistSwap, _addSwap);
    }

    function delWhitelistSwap(address _delSwap) public onlyManager returns (bool) {
        require(_delSwap != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.remove(_whitelistSwap, _delSwap);
    }

    function getWhitelistLengthSwap() public view returns (uint256) {
        return EnumerableSet.length(_whitelistSwap);
    }

    function isWhitelistSwap(address _SwapAddr) public view returns (bool) {
        return EnumerableSet.contains(_whitelistSwap, _SwapAddr);
    }

    function getWhitelistSwap(uint256 _index) public view returns (address){
        require(_index <= getWhitelistLengthSwap() - 1, "index out of bounds");
        return EnumerableSet.at(_whitelistSwap, _index);
    }

    function addWhitelistSwapAll(address[] memory _addSwap) public onlyManager returns (bool) {
        uint amountSwap = _addSwap.length;
        for (uint i = 0; i < amountSwap; i++){
			EnumerableSet.add(_whitelistSwap, _addSwap[i]);
        }
        return true;
    }
}

contract FlashDogeFinance is cFlashSwap, math{
    using Address for address;
    using Sort for uint[];
    function() external payable{}

    event swapTTT(uint _dexNO, uint _tokenIn, uint _tokenOut, uint _amountsIn, uint _amountsOut, uint _feeAmount, uint _airDropAmount);
    
    event swapTT(uint _dexNO, uint _amountsIn, uint _amountsOut, uint _airDropAmount);
	//----------------Swap Trade----------------------------

	//--Swap Exact ETH to token--//
    function swapETHAnyway(uint _tradeTokenNO, uint8 dexNO, uint slippageRate) external payable{
		require(slippageRate >= 500 && slippageRate <= 1000, "Slippage Rate error");
		uint _tradeAmount = msg.value;
		address tokenAddr = getWhitelist(_tradeTokenNO);

		uint _tokenAmountsOut = inqETHToTokenAmountsOut(_tradeTokenNO, dexNO, _tradeAmount);
		address[] memory pathtokenIn = new address[](2);
		pathtokenIn[0] = ETHAddr();
		pathtokenIn[1] = tokenAddr;
		uint amountOutMin = _tokenAmountsOut.mul(slippageRate).div(1000);
		uint TraderResult = 0;

		if(dexNO == 0){
            uint[] memory TradeOut = ISwap(getWhitelistSwap(dexNO)).swapExactHTForTokens.value( _tradeAmount)(
                amountOutMin,
                pathtokenIn,
                address(this),
                now.add(1800)
            );
			TraderResult = TradeOut[TradeOut.length - 1];
		}else{
            uint[] memory TradeOut = ISwap(getWhitelistSwap(dexNO)).swapExactETHForTokens.value( _tradeAmount)(
                amountOutMin,
                pathtokenIn,
                address(this),
                now.add(1800)
            );
			TraderResult = TradeOut[TradeOut.length - 1];
		}
		uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
		uint TraderToken = TraderResult.mul(998).div(1000);
		uint ManagerToken = TraderResult.mul(2).div(1000);

		uint FDTmintAmounts = _tradeAmount.mul(airdropRate).div(10000);
		require(ISwap(FDTAddr()).dexmint(msg.sender, FDTmintAmounts), "Value error.");
		require(IERC20(tokenAddr).transfer(msg.sender, TraderToken));
 		require(IERC20(tokenAddr).transfer(manager, ManagerToken));
		emit swapTTT(dexNO, 99, _tradeTokenNO, _tradeAmount, TraderToken, ManagerToken, FDTmintAmounts);
    }
	
	//--Swap Exact token to token--//
    function swapTokentoToken(uint _TokenNOin, uint _TokenNOout, uint8 dexNO, uint _tradeAmount, uint slippageRate) external {
		require(slippageRate >= 500 && slippageRate <= 1000, "Slippage Rate error");	

		address tokenInAddr = getWhitelist(_TokenNOin);
		address tokenOutAddr = getWhitelist(_TokenNOout);
		uint playerTokenBalance = IERC20(tokenInAddr).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(tokenInAddr).transferFrom(msg.sender, address(this), _tradeAmount), "Token value error.");
		
		uint _amountsOutToken = inqETokenToTokenAmountsOut(_TokenNOin, _TokenNOout, dexNO, _tradeAmount);
		uint amountsOutMinToken = _amountsOutToken.mul(slippageRate).div(1000);

		address[] memory pathtokenOut = new address[](2);
		pathtokenOut[0] = tokenInAddr;
		pathtokenOut[1] = tokenOutAddr;

		uint[] memory TradeOut = ISwap(getWhitelistSwap(dexNO)).swapExactTokensForTokens(
            _tradeAmount,
            amountsOutMinToken,
            pathtokenOut,
            address(this),
            now.add(1800)
		);
		
		uint TraderResult = TradeOut[TradeOut.length - 1];
		uint ResultValue = inqTokenToETHAmountsOut(_TokenNOout, dexNO, TraderResult);
		
		uint TraderToken = TraderResult.mul(998).div(1000);
		uint ManagerToken = TraderResult.mul(2).div(1000);
		
		uint FDTmintAmounts = ResultValue.mul(airdropRate).div(10000);
		require(ISwap(FDTAddr()).dexmint(msg.sender, FDTmintAmounts), "Value error.");
		
		require(IERC20(tokenOutAddr).transfer(msg.sender, TraderToken));
 		require(IERC20(tokenOutAddr).transfer(manager, ManagerToken));
		emit swapTT(dexNO, _tradeAmount, TraderToken, FDTmintAmounts);
    }

	//--Swap Exact token to ETH--//
    function swapTokenAnyway(uint _tradeTokenNO, uint8 dexNO, uint _tradeAmount, uint slippageRate) external {
		require(slippageRate >= 500 && slippageRate <= 1000, "Slippage Rate error");	

		address tokenAddr = getWhitelist(_tradeTokenNO);
		uint playerTokenBalance = IERC20(tokenAddr).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(tokenAddr).transferFrom(msg.sender, address(this), _tradeAmount), "Player value error.");
		
		uint _amountsOut2ETH = inqTokenToETHAmountsOut(_tradeTokenNO, dexNO, _tradeAmount);
		uint amountOutMinETH = _amountsOut2ETH.mul(slippageRate).div(1000);

		address[] memory pathtokenOut = new address[](2);
		pathtokenOut[0] = tokenAddr;
		pathtokenOut[1] = ETHAddr();
		uint TraderResult = 0;
		if(dexNO == 0){
            uint[] memory TradeOut = ISwap(getWhitelistSwap(dexNO)).swapExactTokensForHT(
                _tradeAmount,
                amountOutMinETH,
                pathtokenOut,
                address(this),
                now.add(1800)
            );
			TraderResult = TradeOut[TradeOut.length - 1];
		}else{
            uint[] memory TradeOut = ISwap(getWhitelistSwap(dexNO)).swapExactTokensForETH(
                _tradeAmount,
                amountOutMinETH,
                pathtokenOut,
                address(this),
                now.add(1800)
            );
			TraderResult = TradeOut[TradeOut.length - 1];
		}
		
		uint TraderETH = TraderResult.mul(998).div(1000);
		uint ManagerETH = TraderResult.mul(2).div(1000);
		uint FDTmintAmounts = _amountsOut2ETH.mul(airdropRate).div(10000);
		require(ISwap(FDTAddr()).dexmint(msg.sender, FDTmintAmounts), "Value error.");
		(msg.sender).transfer(TraderETH);
		swapFeeToFDT(ManagerETH);
		emit swapTTT(dexNO, _tradeTokenNO, 99, _tradeAmount, TraderETH, ManagerETH, FDTmintAmounts);
    }

	//--Manager only--//
    function swapTokenAnywayAll(uint _tradeTokenNO, uint8 dexNO, uint slippageRate) public onlyManager {
		require(slippageRate >= 500 && slippageRate <= 1000, "Slippage Rate error");	
		uint _thisTokenBalance = IERC20(getWhitelist(_tradeTokenNO)).balanceOf(address(this));
		uint _amountsOut2ETH = inqTokenToETHAmountsOut(_tradeTokenNO, dexNO, _thisTokenBalance);
		uint amountOutMinETH = _amountsOut2ETH.mul(slippageRate).div(1000);

		address[] memory pathtokenOut = new address[](2);
		pathtokenOut[0] = getWhitelist(_tradeTokenNO);
		pathtokenOut[1] = ETHAddr();

		if(dexNO == 0){
            ISwap(getWhitelistSwap(dexNO)).swapExactTokensForHT(
                _thisTokenBalance,
                amountOutMinETH,
                pathtokenOut,
                address(this),
                now.add(1800)
            );
		}else{
            ISwap(getWhitelistSwap(dexNO)).swapExactTokensForETH(
                _thisTokenBalance,
                amountOutMinETH,
                pathtokenOut,
                address(this),
                now.add(1800)
            );
		}
		manager.toPayable().transfer(address(this).balance);
    }

	//--Swap fee to FDT--//
    function swapFeeToFDT(uint _ethToExact) private {
        address[] memory getETHpath = new address[](2);
        getETHpath[0] = ETHAddr();
        getETHpath[1] = FDTAddr();
		
        ISwap(getWhitelistSwap(1)).swapExactETHForTokens.value( _ethToExact)(
            1,
            getETHpath,
            manager,
            now.add(1800)
        );
    }

	//--Manager only--//--Approve a whiteList token to all dex--//
    function approveForWhiteListSwapAll(uint tokenNO) external onlyManager{
        address tokenAddr = getWhitelist(tokenNO);
		uint amountSwap = getWhitelistLengthSwap();
		
        for (uint8 i = 0; i < amountSwap; i++) {
            address dexAddr = getWhitelistSwap(i);
			IERC20(tokenAddr).approve(dexAddr, 1000000000000000000*10**18);
        }
    }

	//--Manager only--//--Approve all whiteList token to all dex--//
    function _approveForWhiteListSwapAllToken() private{
		uint amountToken = getWhitelistLength();
		uint amountSwap = getWhitelistLengthSwap();

        for (uint8 i = 0; i < amountSwap; i++) {
		    for (uint8 j = 0; j < amountToken; j++) {
		        address dexAddr = getWhitelistSwap(i);
		        address tokenAddr = getWhitelist(j);
		    	IERC20(tokenAddr).approve(dexAddr, 1000000000000000000*10**18);
		    }
        }
    }

	//--Manager only--//--Approve all whiteList token to all dex--//
    function approveForWhiteListSwapAllToken() external onlyManager{
		uint amountToken = getWhitelistLength();
		uint amountSwap = getWhitelistLengthSwap();

        for (uint8 i = 0; i < amountSwap; i++) {
		    for (uint8 j = 0; j < amountToken; j++) {
		        address dexAddr = getWhitelistSwap(i);
		        address tokenAddr = getWhitelist(j);
		    	IERC20(tokenAddr).approve(dexAddr, 1000000000000000000*10**18);
		    }
        }
    }
	
	//--Manager only--//--Approve a whiteList token to a dex--//
    function approveForWhiteListSwap(uint tokenNO, uint256 dexNO) external onlyManager{
        address tokenAddr = getWhitelist(tokenNO);
		address dexAddr = getWhitelistSwap(dexNO);
        IERC20(tokenAddr).approve(dexAddr, 1000000000000000000*10**18);
    }
	
	//--Manager only--//
    function SetupAll(address ETHaddr, address FDTaddr, address[] calldata _addToken, address[] calldata _addSwap) external onlyManager{
        setETHAddr(ETHaddr);
        setFDTAddr(FDTaddr);
        addWhitelistAll(_addToken);
        addWhitelistSwapAll(_addSwap);
		_approveForWhiteListSwapAllToken();
    }
	
	//--Manager only--//
    function AirDropBatch(address _airdropTokenaddr, uint _airdropAmounts, address[] memory _deliveryAddrs) public onlyManager returns (bool) {
        uint _addressAmount = _deliveryAddrs.length;
		uint _totalTokenAmount = _airdropAmounts.mul(_addressAmount);
        uint _thisTokenBalance = IERC20(_airdropTokenaddr).balanceOf(msg.sender);
		require((_thisTokenBalance >= _totalTokenAmount), "Not enough tokens.");
		require(IERC20(_airdropTokenaddr).transferFrom(msg.sender, address(this), _totalTokenAmount), "Value error.");

        for (uint i = 0; i < _addressAmount; i++){
            require(IERC20(_airdropTokenaddr).transfer(_deliveryAddrs[i], _airdropAmounts));
        }
        return true;
    }

	//----------------Swap Check----------------------------
	
	//--Check input address assets of whitelist tokens--//
    function checkAddressAssets(address inputAddr) public view returns(uint[] memory){
        uint amountToken = getWhitelistLength();
		uint[] memory balanceToken = new uint[](amountToken);

        for (uint i = 0; i < amountToken; i++){
			balanceToken[i] = IERC20(getWhitelist(i)).balanceOf(inputAddr);
        }
        return balanceToken;
    }

	//--Calculate ETH Exact amounts in to all DEX token amounts out--//
    function calculateETHINnOut(uint indexToken, uint amountsInETH) public view returns(uint[] memory){
        uint amountSwap = getWhitelistLengthSwap();
        uint[] memory _amountsTokenOut = new uint[](amountSwap);

        for (uint8 i = 0; i < amountSwap; i++) {
            _amountsTokenOut[i] = inqETHToTokenAmountsOut(indexToken, i, amountsInETH);
        }
        return _amountsTokenOut;
    }
	
	//--Calculate token Exact amounts in to all DEX ETH amounts out--//
    function calculateTokenToETH(uint indexToken, uint amountsIn) public view returns(uint[] memory){
        uint amountSwap = getWhitelistLengthSwap();
        uint[] memory _amountsOutETH = new uint[](amountSwap);

        for (uint8 i = 0; i < amountSwap; i++) {
            _amountsOutETH[i] = inqTokenToETHAmountsOut(indexToken, i, amountsIn);
        }
        return _amountsOutETH;
    }

	//--Calculate token1 Exact amounts in to a DEX token2 amounts out, than swap token2 amounts in to all DEX token3 amounts out--//
    function calculateTokenINnOut(uint indexToken1, uint indexToken2, uint indexToken3, uint8 dexNOin, uint amountsIn) public view returns(uint[] memory){  //Calculate IN n Out Result
        uint amountSwap = getWhitelistLengthSwap();
		uint _tokenAmountsOut = inqETokenToTokenAmountsOut(indexToken1, indexToken2, dexNOin, amountsIn);
        uint[] memory _amountsOut2 = new uint[](amountSwap);

        for (uint8 i = 0; i < amountSwap; i++) {
            _amountsOut2[i] = inqETokenToTokenAmountsOut(indexToken2, indexToken3, i, _tokenAmountsOut);
        }
        return _amountsOut2;
    }

	//--Calculate token1 Exact amounts in to all DEX token2 amounts out--//
    function calculateTokenOut(uint indexToken1, uint indexToken2, uint amountsIn) public view returns(uint[] memory){
        uint amountSwap = getWhitelistLengthSwap();
        uint[] memory _amountsOut = new uint[](amountSwap);

        for (uint8 i = 0; i < amountSwap; i++) {
            _amountsOut[i] = inqETokenToTokenAmountsOut(indexToken1, indexToken2, i, amountsIn);
        }
        return _amountsOut;
    }

	//--Calculate token1 amounts in to all DEX token2 Exact amounts out--//
    function calculateTokenIN(uint indexToken1, uint indexToken2, uint amountsOut) public view returns(uint[] memory){
        uint amountSwap = getWhitelistLengthSwap();
        uint[] memory _amountsIN = new uint[](amountSwap);

        for (uint8 i = 0; i < amountSwap; i++) {
            _amountsIN[i] = inqTokenToETokenAmountsIN(indexToken1, indexToken2, i, amountsOut);
        }
        return _amountsIN;
    }

	//--Calculate token1 Exact amounts in to a DEX token2 amounts out--//
    function inqETokenToTokenAmountsOut(uint token1, uint token2, uint dexNO, uint amountsIn) public view returns(
        uint amountsOutToken){
		
        address[] memory path = new address[](2);
		path[0] = getWhitelist(token1);
		path[1] = getWhitelist(token2);
		uint[] memory _amountsOutToken = new uint[](2);
		address _toPair = TogetPairbyAddr(getWhitelist(token1), getWhitelist(token2), dexNO);
		
		if (_toPair == address(0)){
            _amountsOutToken[0] = amountsIn;
            _amountsOutToken[1] = 0;
        }else{
            _amountsOutToken = ISwap(getWhitelistSwap(dexNO)).getAmountsOut(amountsIn, path);
		}

        return _amountsOutToken[1];
    }

	//--Calculate token1 amounts in to a DEX token2 Exact amounts out--//
    function inqTokenToETokenAmountsIN(uint token1, uint token2, uint dexNO, uint amountsOut) public view returns(
        uint amountsOutToken){
		
        address[] memory path = new address[](2);
		path[0] = getWhitelist(token1);
		path[1] = getWhitelist(token2);
		uint[] memory _amountsOutToken = new uint[](2);
		address _toPair = TogetPairbyAddr(getWhitelist(token1), getWhitelist(token2), dexNO);
		
		if (_toPair == address(0)){
            _amountsOutToken[0] = 0;
            _amountsOutToken[1] = amountsOut;
        }else{
            _amountsOutToken = ISwap(getWhitelistSwap(dexNO)).getAmountsIn(amountsOut, path);
		}

        return _amountsOutToken[0];
    }

	//--Calculate all tokens buy price in a DEX by token2 value--//
    function inqTokenBuyPriceINDEX(uint tokenNO, uint dexNO) public view returns(
        uint[] memory){
		uint amountTokens = getWhitelistLength();
		uint[] memory _allDEXBuyPrice = new uint[](amountTokens);
		uint amountsOut = 1*10**18;
		address _dexNOAddr = getWhitelistSwap(dexNO);
		address _tokensAddr = getWhitelist(tokenNO);
		for (uint8 i = 0; i < amountTokens; i++) {
            address[] memory path = new address[](2);
            path[0] = _tokensAddr;
            path[1] = getWhitelist(i);
            uint[] memory _amountsINToken = new uint[](2);
            address _toPair = TogetPairbyAddr(_tokensAddr, getWhitelist(i), dexNO);
		
            if (_toPair == address(0)){
                _amountsINToken[0] = 0;
                _amountsINToken[1] = amountsOut;
                }else{
                _amountsINToken = ISwap(_dexNOAddr).getAmountsIn(amountsOut, path);
            }
			_allDEXBuyPrice[i] = _amountsINToken[0];
        }
        return _allDEXBuyPrice;
    }

	//--Calculate all tokens sell price in a DEX by token2 value--//
    function inqTokenSellPriceINDEX(uint tokenNO, uint dexNO) public view returns(
        uint[] memory){
		uint amountTokens = getWhitelistLength();
		uint[] memory _allDEXSellPrice = new uint[](amountTokens);
		uint amountsIN = 1*10**18;
		address _dexNOAddr = getWhitelistSwap(dexNO);
		address _tokensAddr = getWhitelist(tokenNO);
		for (uint8 i = 0; i < amountTokens; i++) {
            address[] memory path = new address[](2);
            path[0] = getWhitelist(i);
            path[1] = _tokensAddr;
            uint[] memory _amountsOutToken = new uint[](2);
            address _toPair = TogetPairbyAddr(getWhitelist(i), _tokensAddr, dexNO);
		
            if (_toPair == address(0)){
                _amountsOutToken[0] = amountsIN;
                _amountsOutToken[1] = 0;
                }else{
                _amountsOutToken = ISwap(_dexNOAddr).getAmountsOut(amountsIN, path);
            }
			_allDEXSellPrice[i] = _amountsOutToken[1];
        }
        return _allDEXSellPrice;
    }

	//--Calculate Exact ETH amounts in a DEX token amounts out--//
    function inqETHToTokenAmountsOut(uint256 tokenSort, uint256 dexNO, uint amountsInETH) public view returns(
        uint amountsOutToken){
		
        address[] memory path = new address[](2);
		path[0] = ETHAddr();
		path[1] = getWhitelist(tokenSort);
		uint[] memory _amountsOutToken = new uint[](2);
		address _toPair = TogetPairbyAddr(ETHAddr(), getWhitelist(tokenSort), dexNO);
		
		if (_toPair == address(0)){
            _amountsOutToken[0] = amountsInETH;
            _amountsOutToken[1] = 0;
        }else{
            _amountsOutToken = ISwap(getWhitelistSwap(dexNO)).getAmountsOut(amountsInETH, path);
		}

        return _amountsOutToken[1];
    }

	//--Calculate Exact token amounts in a DEX ETH amounts out--//
    function inqTokenToETHAmountsOut(uint256 tokenSort, uint256 dexNO, uint amountsInToken) public view returns(
        uint amountsOutETH){
		
        address[] memory path = new address[](2);
		path[0] = getWhitelist(tokenSort);
		path[1] = ETHAddr();
		uint[] memory _amountsOutETH = new uint[](2);
		address _toPair = TogetPairbyAddr(getWhitelist(tokenSort), ETHAddr(), dexNO);
		
		if (_toPair == address(0)){
            _amountsOutETH[0] = amountsInToken;
            _amountsOutETH[1] = 0;
        }else{
            _amountsOutETH = ISwap(getWhitelistSwap(dexNO)).getAmountsOut(amountsInToken, path);
		}

        return _amountsOutETH[1];
    }
	
	//--Calculate Exact ETH amounts in DEX1 to a token amounts out, thsan swap this token amounts to DEX2 to ETH amounts out--//
    function inqETHInandOut(uint8 tokenSort, uint amountsInETH, uint8 dexNOin, uint8 dexNOOut) public view returns(
        uint amountsOutETH){
		uint _tokenAmountsOut = inqETHToTokenAmountsOut(tokenSort, dexNOin, amountsInETH);
		uint _amountsOutETH = inqTokenToETHAmountsOut(tokenSort, dexNOOut, _tokenAmountsOut);

        return _amountsOutETH;
    }

	//--Toget 2 tokens pair address in a DEX factory address by token address--//
	function TogetPairbyAddr(address _tokenA, address _tokenB, uint dexNO) private view returns(address pair){
        address _dexFactory = ISwap(getWhitelistSwap(dexNO)).factory();
        address _toPair = ISwap(_dexFactory).getPair(_tokenA, _tokenB);
        return _toPair;
    }
	
	//--Toget 2 tokens pair address in a DEX factory address by token NO--//
	function TogetPair(uint tokenANO, uint tokenBNO, uint dexNO) public view returns(address pair){
        address _tokenA = getWhitelist(tokenANO);
        address _tokenB = getWhitelist(tokenBNO);
        address _dexFactory = ISwap(getWhitelistSwap(dexNO)).factory();
        address _toPair = ISwap(_dexFactory).getPair(_tokenA, _tokenB);
        return _toPair;
    }

	//--Manager only--//
    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }

	//--Manager only--//
    function gettakerWithdraw(address miningPool, address tokenAddr) public onlyManager{
        ISwap(miningPool).takerWithdraw();
		uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
		require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }
}