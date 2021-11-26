// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b,"mul");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"div");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"sub");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"add");

        return c;
    }

}
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);

}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"onlyOwner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"incorrect address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MyTradeOrderBook APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MyTradeOrderBook TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MyTradeOrderBook TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: MyTradeOrderBook ETH_TRANSFER_FAILED');
    }
}

interface IMyTradeOrderBookExt{
    function liquidityPrice(
        address _fromTokenAddr,
        address _toTokenAddr,
        address _pairAddr,
        uint _reserve0,
        uint _reserve1
    )external;
    function cancelOrderWithNum(//按数量取消订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    )external;

    function addOrder(
        address _maker,
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
        uint256 _orderIndex
    )external;
    function updateOrderInfo(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex,
        uint256 _outNum,
        uint256 _inNum
    )external;
    function getOrderIndexsForMaker(
        address _fromTokenAddr,
        address _toTokenAddr,
        address _maker
    )external view returns(uint256[] memory cindexs);
    function getOrderInfo(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
   )external view returns(uint256 _orderTime,uint256 _toTokenSum);
}
interface IMyTradeOrderMining{
    function updateOrderMiningNumByOuter() external returns (bool);
}
interface ISwapMining {
    function swap(address account, address input, address output, uint256 amount) external returns (bool);
}
library OrderBookHelper{
    using SafeMath for uint;
   
   // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
     // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function getInAmount(
        uint256 fromNum,
        uint256 toNum,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns(uint256 z){
        uint256 p=reserveA.mul(reserveB).mul(fromNum).mul(1000)/997/toNum;
        uint256 q=reserveA.mul(reserveA).mul(8973)/3964107892;
        uint256 x=sqrt(p.add(q));

        uint256 y=reserveA.mul(1997)/1994;
        if(x>y){
            z=x.sub(y).add(1);
        }else{
            z=0;
        }
    }
    function joinNumber(
        uint256 _number,
        uint256[] memory narray
    )internal pure returns(uint256[] memory){
        if(_number==0){
            return narray;
        }
        uint256 nl=narray.length;
        uint256[] memory narray1=new uint256[](nl+1);
        for(uint256 i=0;i<nl;i++){
            narray1[i]=narray[i];
        }
        narray1[nl]=_number;
        return narray1;
    }
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
contract MyTradeOrderBook is Ownable,ReentrancyGuard{
    using SafeMath for uint;
    IUniswapV2Factory immutable public uniswapV2Factory;
    address immutable public WETH;
    address public feeAddr;
    uint256 constant UINT256_MAX = ~uint256(0);
    IMyTradeOrderBookExt myTradeOrderBookExt;
    address public myTradeOrderMining;
    address public swapMining;
    function setMyTradeOrderMining(address _myTradeOrderMining) public onlyOwner {
        myTradeOrderMining = _myTradeOrderMining;
    }
    address public forPreDiposit;
     function setForPreDiposit(address _forPreDiposit) public onlyOwner {
        forPreDiposit = _forPreDiposit;
    }
    function setSwapMining(address _swapMininng) public onlyOwner {
        swapMining = _swapMininng;
    }
    //最小数量限额：0.1,可外部设置
    mapping (address  => uint) minLimitMap;
    /**
     *设置最小允许的数
     */
    function setMinLimit(
        address _tokenAddr,
        uint _minLimit
    ) onlyOwner public returns(bool) {
        minLimitMap[_tokenAddr] = _minLimit;
        return true;
    }
    
    struct Order{
        address maker;
        address fromTokenAddr;
        address toTokenAddr;
        uint256 remainNumber;
        uint256 fromTokenNumber;// 代币挂单金额
        uint256 toTokenNumber;// 意向代币目标金额
    }
    struct TokenPair{
        uint256 orderMaxIndex;
        mapping(address=> uint256) lastIndex;
        mapping(uint256=> Order) orderMap;// orderIndex=》Order
        mapping(uint256=> uint256) orderNextSequence;// 价格低的orderIndex=》价格高的orderIndex
        mapping(uint256=> uint256) orderPreSequence;// 价格高的orderIndex=》价格低的orderIndex
    }
    mapping (address=> mapping (uint  => uint8)) isForEth;
    TokenPair[] tokenPairArray;// tokenPair数组
    mapping (address  => uint256) tokenPairIndexMap;// tokenPairAddr=>tokenPair数组下标
    address immutable public flashLoan;
    constructor(
        address _WETH,
        address _uniswapV2Factory
    ) payable  {
        WETH=_WETH;
        feeAddr=msg.sender;
        tokenPairArray.push();
        uniswapV2Factory=IUniswapV2Factory(_uniswapV2Factory);
        flashLoan=address(new FlashLoan(msg.sender));
    }
    function safeApproveFlashLoan(
        address tokenA
    )public{
    	TransferHelper.safeApprove(
            tokenA,
            flashLoan,
            UINT256_MAX
        );
    }
    function setMyTradeOrderBookExtAddr(
        address _myTradeOrderBookExtAddr
    ) onlyOwner public returns(bool) {
        myTradeOrderBookExt=IMyTradeOrderBookExt(_myTradeOrderBookExtAddr);
        return true;
    }
    receive() external payable { 
        if(msg.value>0&&msg.sender!=WETH){
            IWETH(WETH).deposit{value : msg.value}();
        }
    }
    fallback(bytes calldata _input) external payable returns (bytes memory _output){
    }
    function setFeeAddr(address _feeAddr)public onlyOwner {
        feeAddr=_feeAddr;
    }
    mapping (address  => uint256) public allUserDiposit;//所有用户存款代币数量
    mapping (address  => mapping (address  => uint256)) public userDiposit;
    function deposit(address _token,uint _num) public {
        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            _num
        );
        userDiposit[msg.sender][_token] = userDiposit[msg.sender][_token].add(_num);
        allUserDiposit[_token]=allUserDiposit[_token].add(_num);
    }
    function withdraw(address _token,uint _num) public {
        require(userDiposit[msg.sender][_token]>=_num,"Insufficient Number");
        TransferHelper.safeTransfer(
                _token,
                msg.sender,
                _num
            );
        userDiposit[msg.sender][_token] = userDiposit[msg.sender][_token].sub(_num);
        allUserDiposit[_token]=allUserDiposit[_token].sub(_num);
    }
  
    function addOrderWithPreDiposit(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )public nonReentrant returns(uint256 reserveNum,uint256 orderIndex) {
        require(msg.sender==forPreDiposit);
        require(userDiposit[msg.sender][_fromTokenAddr]>=_fromTokenNumber,"Insufficient Balance");
        require(_fromTokenNumber>=minLimitMap[_fromTokenAddr],"min limit");
        userDiposit[msg.sender][_fromTokenAddr] = userDiposit[msg.sender][_fromTokenAddr].sub(_fromTokenNumber);
        (reserveNum,orderIndex)=_addOrder(
            msg.sender,
            _fromTokenAddr,
            _toTokenAddr,
            _targetOrderIndex,
            _fromTokenNumber,
            _toTokenNumber
        );
    }
    function cancelOrderForNumWithPreDiposit(//按数量取消订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    )public nonReentrant returns(bool) {
        _cancelOrderForNum(_fromTokenAddr,_toTokenAddr,_orderIndex,_num);
        userDiposit[msg.sender][_fromTokenAddr] = userDiposit[msg.sender][_fromTokenAddr].add(_num);
        return true;
    }
    function cancelOrderForNum(//按数量取消订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    )public nonReentrant returns(bool) {
        _cancelOrderForNum(_fromTokenAddr,_toTokenAddr,_orderIndex,_num);
        allUserDiposit[_fromTokenAddr]=allUserDiposit[_fromTokenAddr].sub(_num);
        if(_fromTokenAddr==WETH){
           IWETH(WETH).withdraw(_num);
           TransferHelper.safeTransferETH(
              msg.sender,
              _num
           );
        }else{
           TransferHelper.safeTransfer(
                _fromTokenAddr,
                msg.sender,
                _num
            );
        }
        if(myTradeOrderMining!=address(0)){
            IMyTradeOrderMining(myTradeOrderMining).updateOrderMiningNumByOuter();
        }
        return true;
    }
    function _cancelOrderForNum(//按数量取消订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    )internal{
        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr,_toTokenAddr);
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        require(tokenPairIndex!=0,"tokenPair not exist");
        TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
        require(_tokenPair.orderMap[_orderIndex].maker==msg.sender,"invalid maker");
        require(_orderIndex!=0,"order not exist");
        uint256 remainNumber=_tokenPair.orderMap[_orderIndex].remainNumber;
        require(remainNumber>=_num,"Insufficient RemainNumber");
        if(remainNumber==_num){
            if(_tokenPair.lastIndex[_fromTokenAddr]==_orderIndex){
                _tokenPair.lastIndex[_fromTokenAddr]=_tokenPair.orderNextSequence[_orderIndex];
                _tokenPair.orderPreSequence[_tokenPair.lastIndex[_fromTokenAddr]]=0;
                _tokenPair.orderNextSequence[_orderIndex]=0;
            }else{
                uint256 orderPreIndex=_tokenPair.orderPreSequence[_orderIndex];
                require(orderPreIndex!=0,"no preIndex");
                require(_tokenPair.orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr,"invalid fromTokenAddr");
                uint256 orderNextIndex=_tokenPair.orderNextSequence[_orderIndex];
                _tokenPair.orderNextSequence[orderPreIndex]=orderNextIndex;
                if(orderNextIndex!=0){
                    _tokenPair.orderPreSequence[orderNextIndex]=orderPreIndex;
                }
                _tokenPair.orderPreSequence[_orderIndex]=0;
                _tokenPair.orderNextSequence[_orderIndex]=0;
            }
        }else{
            _tokenPair.orderMap[_orderIndex].remainNumber=remainNumber.sub(_num);
        }
        
        (uint256 reserveA,uint256 reserveB)=getReserves(_fromTokenAddr, _toTokenAddr);
        myTradeOrderBookExt.liquidityPrice(_fromTokenAddr,_toTokenAddr,pairAddr,reserveA,reserveB);
        myTradeOrderBookExt.cancelOrderWithNum(_fromTokenAddr,_toTokenAddr,_orderIndex,_num);
    }
    function _orderIndexSequence(
        uint256 _targetOrderIndex,
        uint256 _orderIndex,
        TokenPair storage _tokenPair,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )internal{
        if(_fromTokenNumber.mul(_tokenPair.orderMap[_targetOrderIndex].toTokenNumber)<=
            _tokenPair.orderMap[_targetOrderIndex].fromTokenNumber.mul(_toTokenNumber)){
            uint256 orderNextSequence=_tokenPair.orderNextSequence[_targetOrderIndex];
            if(orderNextSequence==0){
                _tokenPair.orderNextSequence[_targetOrderIndex]=_orderIndex;
                _tokenPair.orderPreSequence[_orderIndex]=_targetOrderIndex;
            }else{
                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderNextSequence].toTokenNumber)<=
                    _tokenPair.orderMap[orderNextSequence].fromTokenNumber.mul(_toTokenNumber)){
                    _orderIndexSequence(orderNextSequence,
                        _orderIndex,_tokenPair,_fromTokenNumber,_toTokenNumber);
                }else{
                    _tokenPair.orderPreSequence[_orderIndex]=_targetOrderIndex;
                    _tokenPair.orderNextSequence[_targetOrderIndex]=_orderIndex;
                    _tokenPair.orderPreSequence[orderNextSequence]=_orderIndex;
                    _tokenPair.orderNextSequence[_orderIndex]=orderNextSequence;
                }
            }
        }else{
            uint256 orderPreIndex=_tokenPair.orderPreSequence[_targetOrderIndex];
            if(orderPreIndex==0){
                _tokenPair.orderPreSequence[_targetOrderIndex]=_orderIndex;
                _tokenPair.orderNextSequence[_orderIndex]=_targetOrderIndex;
            }else{
                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderPreIndex].toTokenNumber)>=
                    _tokenPair.orderMap[orderPreIndex].fromTokenNumber.mul(_toTokenNumber)){
                    _orderIndexSequence(orderPreIndex,
                        _orderIndex,_tokenPair,_fromTokenNumber,_toTokenNumber);
                }else{
                    _tokenPair.orderNextSequence[_orderIndex]=_targetOrderIndex;
                    _tokenPair.orderPreSequence[_targetOrderIndex]=_orderIndex;
                    _tokenPair.orderNextSequence[orderPreIndex]=_orderIndex;
                    _tokenPair.orderPreSequence[_orderIndex]=orderPreIndex;
                }
            }
        }
    }
 
    function addOrderWithETH(
        address _maker,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _toTokenNumber
    )public payable nonReentrant returns(uint256 reserveNum,uint256 orderIndex) {
        require(msg.value>minLimitMap[WETH],"min limit");
        IWETH(WETH).deposit{value : msg.value}();
        (reserveNum,orderIndex)=_addOrder(_maker,WETH,_toTokenAddr,_targetOrderIndex,msg.value,_toTokenNumber);
    }
    function addOrderForETH(
        address _maker,
        address _fromTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )public returns(uint256 reserveNum,uint256 orderIndex) {
        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr,WETH);
        require(pairAddr!=address(0),"pairAddr not exist");
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        if(tokenPairIndex== 0){//如果交易对不存在就新增一个
            tokenPairIndex=tokenPairArray.length;
            tokenPairArray.push();
            tokenPairIndexMap[pairAddr]=tokenPairIndex;
        }  
        isForEth[_fromTokenAddr][tokenPairArray[tokenPairIndex].orderMaxIndex.add(1)]=2;
        (reserveNum,orderIndex)=addOrder(
            _maker,
            _fromTokenAddr,
            WETH,
            _targetOrderIndex,
            _fromTokenNumber,
            _toTokenNumber
        );
    }
    function addOrder(
        address _maker,
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )public nonReentrant returns(uint256 reserveNum,uint256 orderIndex) {
        require(_fromTokenNumber>minLimitMap[_fromTokenAddr],"min limit");
        TransferHelper.safeTransferFrom(
            _fromTokenAddr,
            msg.sender,
            address(this),
            _fromTokenNumber
        );
        (reserveNum,orderIndex)=_addOrder(_maker,_fromTokenAddr,
            _toTokenAddr,_targetOrderIndex,_fromTokenNumber,_toTokenNumber
        );
    }
    function _addOrder(
        address _maker,
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )internal returns(
        uint256 reserveNum,
        uint256 orderIndex
    ) {
        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr,_toTokenAddr);
        require(pairAddr!=address(0),"pairAddr not exist");
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        if(tokenPairIndex== 0){//如果交易对不存在就新增一个
            tokenPairIndex=tokenPairArray.length;
            tokenPairArray.push();
            tokenPairIndexMap[pairAddr]=tokenPairIndex;
        }
        TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
        orderIndex=_tokenPair.orderMaxIndex.add(1);
        _tokenPair.orderMaxIndex=orderIndex;

        uint256 lastIndex=_tokenPair.lastIndex[_fromTokenAddr];
        if(lastIndex!=0){
            if(_targetOrderIndex==0){
                _targetOrderIndex=lastIndex;
            }else if(
                _tokenPair.orderNextSequence[_targetOrderIndex]==0&&
                _tokenPair.orderPreSequence[_targetOrderIndex]==0
            ){
                _targetOrderIndex=lastIndex;
            }else if(_tokenPair.orderMap[_targetOrderIndex].fromTokenAddr!=_fromTokenAddr){
                _targetOrderIndex=lastIndex;
            }
            _orderIndexSequence(_targetOrderIndex,orderIndex,_tokenPair,
                _fromTokenNumber,_toTokenNumber
            );
        }
        myTradeOrderBookExt.addOrder(
            _maker,
            _fromTokenAddr,
            _toTokenAddr,
            _fromTokenNumber,
            _toTokenNumber,
            orderIndex);
        Order memory order=Order(_maker,_fromTokenAddr,_toTokenAddr,
           _fromTokenNumber,_fromTokenNumber,_toTokenNumber);
        _tokenPair.orderMap[orderIndex]=order;
        (uint256 reserveA,uint256 reserveB)=getReserves(_fromTokenAddr, _toTokenAddr);
        if(_tokenPair.orderPreSequence[orderIndex]==0){
            _tokenPair.lastIndex[order.fromTokenAddr]=orderIndex;
            checkTrade(_tokenPair,orderIndex,order,reserveA,reserveB);
	        reserveNum=_tokenPair.orderMap[orderIndex].remainNumber;
	        if(reserveNum==0){
	            uint _nextIndex=_tokenPair.orderNextSequence[orderIndex];
	            _tokenPair.lastIndex[order.fromTokenAddr]=_nextIndex;
	            if(_nextIndex!=0){
		            _tokenPair.orderNextSequence[orderIndex]=0;
		            _tokenPair.orderPreSequence[_nextIndex]=0;
	            }
	        }else{
	            allUserDiposit[order.fromTokenAddr]=allUserDiposit[order.fromTokenAddr].add(reserveNum);
	        }
	        uint remainBal=IERC20(_fromTokenAddr).balanceOf(address(this));
	        if(remainBal>allUserDiposit[order.fromTokenAddr]){//剩余的是手续费
	            TransferHelper.safeTransfer(
	                order.fromTokenAddr,
	                feeAddr,
	                remainBal.sub(allUserDiposit[order.fromTokenAddr])
	            );
	        }
        }else{
            reserveNum=_fromTokenNumber;
            allUserDiposit[order.fromTokenAddr]=allUserDiposit[order.fromTokenAddr].add(reserveNum);
        }
        myTradeOrderBookExt.liquidityPrice(order.fromTokenAddr,order.toTokenAddr,pairAddr,reserveA,reserveB);
        if(myTradeOrderMining!=address(0)){
            IMyTradeOrderMining(myTradeOrderMining).updateOrderMiningNumByOuter();
        }
    }
    function checkTrade(
        TokenPair storage _tokenPair,
        uint256 orderIndex,
        Order memory o,
        uint256 reserveA,
        uint256 reserveB
    ) internal {
        if(o.fromTokenNumber.mul(reserveB)>o.toTokenNumber.mul(reserveA)){//如果流动池价格低于当前价格
            uint256 cInAmount=OrderBookHelper.getInAmount(
                o.fromTokenNumber,o.toTokenNumber,reserveA,reserveB
            );//计算达到当前订单价格需要付出的币数量
            if(cInAmount>o.fromTokenNumber){
                cInAmount=o.fromTokenNumber;
            }
            uint[3] memory numArray=[0,0,_tokenPair.lastIndex[o.toTokenAddr]];
            if(numArray[2]!=0){//如果存在挂单
                Order storage bom=_tokenPair.orderMap[numArray[2]];
                Order memory bo=bom;
                if(o.fromTokenNumber.mul(bo.fromTokenNumber)>=o.toTokenNumber.mul(bo.toTokenNumber)){//当前订单价格超过挂单的价格
                    uint256 newInAmount;
                    if(o.fromTokenNumber.mul(bo.fromTokenNumber)==o.toTokenNumber.mul(bo.toTokenNumber)){
                        newInAmount=cInAmount;
                    }else{
                        newInAmount=OrderBookHelper.getInAmount(//计算对手订单价格需要付出的币数量
                    	bo.toTokenNumber,bo.fromTokenNumber,reserveA,reserveB);
                    }
                    if(cInAmount>=newInAmount){//全部成交超过对手订单价格
                        uint256 tokenANum=o.fromTokenNumber.sub(newInAmount);
                        while(numArray[2]>0&&tokenANum>0){
                            uint tonum=getToNum(bo);
                            uint tonumsFee=tonum.mul(997).div(1000);
                            if(tokenANum>=tonum){//如果全部成交也不够
                                if(bo.toTokenAddr==WETH&&isForEth[bo.fromTokenAddr][numArray[2]]==2){
                                    IWETH(WETH).withdraw(tonumsFee);
                                    TransferHelper.safeTransferETH(
                                      bo.maker,
                                      tonumsFee
                                    );
                                }else{
                                    TransferHelper.safeTransfer(
                                        bo.toTokenAddr,
                                        bo.maker,
                                        tonumsFee
                                    );
                                }
                                numArray[0]=numArray[0].add(tonum);//付出的
                                numArray[1]=numArray[1].add(bo.remainNumber);//得到的 
                                bom.remainNumber=0;
                                myTradeOrderBookExt.updateOrderInfo(
                                    bo.fromTokenAddr,
                                    bo.toTokenAddr,
                                    numArray[2],
                                    tonumsFee,//成交数量
                                    bo.remainNumber
                                );
                                uint newBIndex=_tokenPair.orderNextSequence[numArray[2]];//继续向上一单推进
	                            _tokenPair.orderNextSequence[numArray[2]]=0;
                                numArray[2]=newBIndex;
    	                        _tokenPair.lastIndex[o.toTokenAddr]=numArray[2];
                                if(numArray[2]!=0){
	                                _tokenPair.orderPreSequence[numArray[2]]=0;
                                    bom=_tokenPair.orderMap[numArray[2]];
                                    bo=bom;
                                    if(o.fromTokenNumber.mul(bo.fromTokenNumber)>=o.toTokenNumber.mul(bo.toTokenNumber)){
                                        newInAmount=OrderBookHelper.getInAmount(
                                        bo.toTokenNumber,bo.fromTokenNumber,reserveA,reserveB);//计算对手订单价格需要付出的币数量
	                                    uint atemp=newInAmount.add(numArray[0]);
	                                    if(cInAmount>=newInAmount&&o.fromTokenNumber>atemp){//继续向上一条订单价格推进
	                                        tokenANum=o.fromTokenNumber.sub(atemp);
	                                    }else{
	                                        tokenANum=0;//停止向上遍列
	                                    }
                                    }else{
                                        tokenANum=0;//停止向上遍列
                                    }
                                }
                            }else{
                                //如果最后一条订单簿能成交够,部分成交订单簿
                                uint256 atoNum=tokenANum.mul(997).div(1000);
                                if(bo.toTokenAddr==WETH&&isForEth[bo.fromTokenAddr][numArray[2]]==2){
                                    IWETH(WETH).withdraw(atoNum);
                                    TransferHelper.safeTransferETH(
                                        bo.maker,
                                        atoNum
                                    );
                                }else{
                                    TransferHelper.safeTransfer(
                                        bo.toTokenAddr,
                                        bo.maker,
                                        atoNum
                                    );
                                }
                                numArray[0]=numArray[0].add(tokenANum);
                                uint256 tokenBNum=atoNum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                                numArray[1]=numArray[1].add(tokenBNum);
                                bom.remainNumber=bo.remainNumber.sub(tokenBNum);
                                myTradeOrderBookExt.updateOrderInfo(
                                    bo.fromTokenAddr,
                                    bo.toTokenAddr,
                                    numArray[2],
                                    atoNum,//成交数量
                                    tokenBNum
                                );
                                tokenANum=0;//停止向上遍列
                            }
                        }
                    }
                }
            }
            uint256 inAmountToliq=o.fromTokenNumber.sub(numArray[0]);
            if(cInAmount<inAmountToliq){
                inAmountToliq=cInAmount;
            }
            if(inAmountToliq>0){
                numArray[0]=numArray[0].add(inAmountToliq);
                {
                    address _fromTokenAddr=o.fromTokenAddr;
                    address _toTokenAddr=o.toTokenAddr;
                    uint _reserveA=reserveA;
                    uint _reserveB=reserveB;
                    uint256 numerator = _reserveA.mul(1000);
                    uint256 denominator =_reserveB.sub(1).mul(997);
                    uint256 amountIn = (numerator / denominator).add(2);
                    if(inAmountToliq>=amountIn){
                        uint256 amountOut=OrderBookHelper.getAmountOut(inAmountToliq,_reserveA,_reserveB);
                        numArray[1]=numArray[1].add(amountOut);
                        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
                        TransferHelper.safeTransfer(
                            _fromTokenAddr,
                            pairAddr, 
                            inAmountToliq
                        );
                        (address token0,) =OrderBookHelper.sortTokens(_fromTokenAddr, _toTokenAddr);
                        if(_fromTokenAddr == token0){
                            IUniswapV2Pair(pairAddr).swap(
                                0, amountOut, address(this), new bytes(0)
                            );
                        }else{
                            IUniswapV2Pair(pairAddr).swap(
                                amountOut, 0, address(this), new bytes(0)
                            );
                        }
                        allUserDiposit[_toTokenAddr]=allUserDiposit[_toTokenAddr].add(amountOut);
                    }
                }
            }
            if(numArray[0]>0){
                if(numArray[1]>0){
                    if(o.toTokenAddr==WETH&&isForEth[o.fromTokenAddr][orderIndex]==2){
                        IWETH(WETH).withdraw(numArray[1]);
                        TransferHelper.safeTransferETH(
                            o.maker,
                            numArray[1]
                        );
                    }else{
                        TransferHelper.safeTransfer(
                            o.toTokenAddr,
                            o.maker,
                            numArray[1]
                        );
                    }
                    if (swapMining != address(0)) {
                        ISwapMining(swapMining).swap(o.maker, o.fromTokenAddr, o.toTokenAddr, numArray[1]);
                    }
                    allUserDiposit[o.toTokenAddr]=allUserDiposit[o.toTokenAddr].sub(numArray[1]);
                }
                myTradeOrderBookExt.updateOrderInfo(
                    _tokenPair.orderMap[orderIndex].fromTokenAddr,
                    _tokenPair.orderMap[orderIndex].toTokenAddr,
                    orderIndex,
                    numArray[1],//成交数量
                    numArray[0]
                );
                _tokenPair.orderMap[orderIndex].remainNumber=
                    o.fromTokenNumber.sub(numArray[0]);
                
            }
        }else {
            uint[3] memory numArray=[0,0,_tokenPair.lastIndex[o.toTokenAddr]];
            uint256 tokenANum=o.fromTokenNumber;
            while(numArray[2]!=0&&tokenANum!=0){
                Order storage bo=_tokenPair.orderMap[numArray[2]];
                if(o.fromTokenNumber.mul(bo.fromTokenNumber)==o.toTokenNumber.mul(bo.toTokenNumber)){
                    tokenANum=o.fromTokenNumber.sub(numArray[0]);
                    uint256 toNum=getToNum(bo);
                    if(tokenANum>=toNum){
                        uint256 atoNum=toNum.mul(997).div(1000);
                        if(bo.toTokenAddr==WETH&&isForEth[bo.fromTokenAddr][numArray[2]]==2){
                            IWETH(WETH).withdraw(atoNum);
                            TransferHelper.safeTransferETH(
                                bo.maker,
                                atoNum
                            );
                        }else{
                            TransferHelper.safeTransfer(
                                bo.toTokenAddr,
                                bo.maker,
                                atoNum
                            );
                        }
                        numArray[0]=numArray[0].add(toNum);
                        numArray[1]=numArray[1].add(bo.remainNumber);
                        myTradeOrderBookExt.updateOrderInfo(
                            _tokenPair.orderMap[numArray[2]].fromTokenAddr,
                            _tokenPair.orderMap[numArray[2]].toTokenAddr,
                            numArray[2],
                            atoNum,//成交数量
                            bo.remainNumber
                        );
                        uint newBIndex=_tokenPair.orderNextSequence[numArray[2]];
                        _tokenPair.lastIndex[o.toTokenAddr]=newBIndex;
                        if(newBIndex!=0){
                        	_tokenPair.orderNextSequence[numArray[2]]=0;
                        	_tokenPair.orderPreSequence[newBIndex]=0;
                        }
                        _tokenPair.orderMap[numArray[2]].remainNumber=0;
                        numArray[2]=newBIndex;
                    }else{
                        uint256 atoNum=tokenANum.mul(997).div(1000);
                        if(bo.toTokenAddr==WETH&&isForEth[bo.fromTokenAddr][numArray[2]]==2){
                            IWETH(WETH).withdraw(atoNum);
                            TransferHelper.safeTransferETH(
                                bo.maker,
                                atoNum
                            );
                        }else{
                            TransferHelper.safeTransfer(
                                bo.toTokenAddr,
                                bo.maker,
                                atoNum
                            );
                        }
                        
                        numArray[0]=o.fromTokenNumber;
                        uint256 tokenBNum=atoNum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                        numArray[1]=numArray[1].add(tokenBNum);
                        _tokenPair.orderMap[numArray[2]].remainNumber=
                            bo.remainNumber.sub(tokenBNum);
                        myTradeOrderBookExt.updateOrderInfo(
                            _tokenPair.orderMap[numArray[2]].fromTokenAddr,
                            _tokenPair.orderMap[numArray[2]].toTokenAddr,
                            numArray[2],
                            atoNum,//成交数量
                            tokenBNum
                        );
                        break;
                    }
                }else{
                    break;
                }
            }
            if(numArray[0]>0){
                if(o.toTokenAddr==WETH&&isForEth[o.fromTokenAddr][orderIndex]==2){
                    IWETH(WETH).withdraw(numArray[1]);
                    TransferHelper.safeTransferETH(
                        o.maker,
                        numArray[1]
                    );
                }else{
                    TransferHelper.safeTransfer(
                        o.toTokenAddr,
                        o.maker,
                        numArray[1]
                    );
                }
                
                if (swapMining != address(0)) {
                    ISwapMining(swapMining).swap(o.maker, o.fromTokenAddr, o.toTokenAddr, numArray[1]);
                }
                allUserDiposit[o.toTokenAddr]=allUserDiposit[o.toTokenAddr].sub(numArray[1]);
                myTradeOrderBookExt.updateOrderInfo(
                    _tokenPair.orderMap[orderIndex].fromTokenAddr,
                    _tokenPair.orderMap[orderIndex].toTokenAddr,
                   orderIndex,
                    numArray[1],//成交数量
                    numArray[0]
                );    
                    
                _tokenPair.orderMap[orderIndex].remainNumber=
                    o.fromTokenNumber.sub(numArray[0]);
            }
         }
            
    }

    function getOrderByIndexBatch(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256[] memory _orderIndexs//必须是已存在的orderIndex，否则会得不到正确结果
    )public view returns(
        address[] memory makers,//挂单者
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory fromTokenNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory remainNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    ){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage tokenPair=tokenPairArray[tokenPairIndex];
                uint256 l=_orderIndexs.length;
                makers=new  address[](l);
                fromTokenAddrs=new address[](l);
                fromTokenNumbers=new uint256[](l);
                remainNumbers=new uint256[](l);
                toTokenNumbers=new uint256[](l);
                timestamps=new uint256[](l);
                toTokenSums=new uint256[](l);
                for(uint256 i=0;i<l;i++){
                    {
                        uint256 _orderIndex=_orderIndexs[i];
                        Order memory o=tokenPair.orderMap[_orderIndex];
                        makers[i]=o.maker;
                        fromTokenAddrs[i]=o.fromTokenAddr;
                        toTokenNumbers[i]=o.toTokenNumber;
                        fromTokenNumbers[i]=o.fromTokenNumber;
                        remainNumbers[i]=o.remainNumber;
                        (timestamps[i],toTokenSums[i])=myTradeOrderBookExt.getOrderInfo(o.fromTokenAddr,o.toTokenAddr,_orderIndex);
                    }
                }
            }
        }
    }

    function getPageOrders(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderStartIndex,// 订单序号点
        uint256 _records// 每次获取的个数
    )public view returns(uint256[] memory orderIndexs){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage tokenPair=tokenPairArray[tokenPairIndex];
                if(tokenPair.orderNextSequence[_orderStartIndex]==0){
                    uint256 ordersLastIndex=tokenPair.lastIndex[_fromTokenAddr];
                    if(tokenPair.orderPreSequence[_orderStartIndex]!=0||
                    _orderStartIndex==ordersLastIndex){
                        orderIndexs=new uint256[](1);
                        orderIndexs[0]=_orderStartIndex;
                    }
                }else{
                    orderIndexs=new uint256[](1);
                    orderIndexs[0]=_orderStartIndex;
                    if(_records!=1){
                        uint256[] memory newOrderIndexs=OrderBookHelper.joinNumber(
                            tokenPair.orderNextSequence[orderIndexs[0]],orderIndexs);
                        uint256 ll=newOrderIndexs.length;//新数组长度
                        uint256 orderNextSequence=tokenPair.orderNextSequence[newOrderIndexs[ll-1]];
                        while(orderNextSequence>0&&ll<_records){
                            newOrderIndexs=OrderBookHelper.joinNumber(orderNextSequence,newOrderIndexs);
                            if(ll==newOrderIndexs.length){//新数组长度没变停止
                                break;
                            }
                            ll=newOrderIndexs.length;//更新新数组长度
                            orderNextSequence=tokenPair.orderNextSequence[newOrderIndexs[ll-1]];
                        }
                        orderIndexs=newOrderIndexs;
                    }
                }
            }
        }
    }

    function getClosestOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
        uint256 _depth
    )public view returns (uint256 closestOrderIndex,uint8 isEnd){
        if(_depth==0){
            return (_targetOrderIndex,0);
        }
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
                if(_tokenPair.orderNextSequence[_targetOrderIndex]==0
                	&&_tokenPair.orderPreSequence[_targetOrderIndex]==0){
                    _targetOrderIndex=_tokenPair.lastIndex[_fromTokenAddr];
                }
                if(_targetOrderIndex!=0){
                    Order memory o=_tokenPair.orderMap[_targetOrderIndex];
                    if(o.fromTokenAddr!=_fromTokenAddr){
                        _targetOrderIndex=_tokenPair.lastIndex[_fromTokenAddr];
                    }
                    if(_targetOrderIndex!=0){
				        if(_fromTokenNumber.mul(_tokenPair.orderMap[_targetOrderIndex].toTokenNumber)<=
				            _tokenPair.orderMap[_targetOrderIndex].fromTokenNumber.mul(_toTokenNumber)){
				            uint256 orderNextSequence=_tokenPair.orderNextSequence[_targetOrderIndex];
				            if(orderNextSequence==0){
				               return (_targetOrderIndex,1);
				            }else{
				                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderNextSequence].toTokenNumber)<=
				                    _tokenPair.orderMap[orderNextSequence].fromTokenNumber.mul(_toTokenNumber)){
				                    return getClosestOrderIndex(
				                        _fromTokenAddr,
				                        _toTokenAddr,
				                        orderNextSequence,
				                        _fromTokenNumber,
				                        _toTokenNumber,
				                        _depth.sub(1)
				                    );
				                }else{
				                    return (_targetOrderIndex,1);
				                }
				            }
				        }else{
				            uint256 orderPreIndex=_tokenPair.orderPreSequence[_targetOrderIndex];
				            if(orderPreIndex==0){
				                return (_targetOrderIndex,1);
				            }else{
				                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderPreIndex].toTokenNumber)>=
				                    _tokenPair.orderMap[orderPreIndex].fromTokenNumber.mul(_toTokenNumber)){
				                     return getClosestOrderIndex(
				                        _fromTokenAddr,
				                        _toTokenAddr,
				                        orderPreIndex,
				                        _fromTokenNumber,
				                        _toTokenNumber,
				                        _depth.sub(1)
				                    );
				                }else{
				                  return (_targetOrderIndex,1);
				                }
				            }
				        }
                    }
                }
            }
        }
    }
    function getLastOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr
    )public view returns (uint256 lastOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                lastOrderIndex=tokenPairArray[tokenPairIndex].lastIndex[_fromTokenAddr];
            }
        }
    }
    function getNextOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )public view returns  (uint256 nextOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                if(tokenPairArray[tokenPairIndex].orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr){
                    nextOrderIndex=tokenPairArray[tokenPairIndex].orderNextSequence[_orderIndex];
                }
            }
        }
    }
    function getPreOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )public view returns (uint256 preOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        if(tokenPairIndex!=0){
            if(tokenPairArray[tokenPairIndex].orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr){
                preOrderIndex=tokenPairArray[tokenPairIndex].orderPreSequence[_orderIndex];
            }
        }
    }
    function getToNum(Order memory bo) internal pure returns (uint256 _to){
        _to=bo.toTokenNumber.mul(
            bo.remainNumber
        ).div(bo.fromTokenNumber).mul(1000).div(997);
    }
   
    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = OrderBookHelper.sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(uniswapV2Factory.getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
}
interface IFlashLoanService {
     function check(address from, uint256 value) external returns (bool);
}

contract FlashLoan is ReentrancyGuard,Ownable{
    address public loanServiceAddr;
    constructor(
        address _owner
    ){
       _transferOwnership(_owner);
    }
    function setLoanServiceAddr(address _loanServiceAddr)public onlyOwner {
        loanServiceAddr=_loanServiceAddr;
    }
    function loan(
        address from,
        address token,
        uint value,
        address contractAddr,
        bytes memory msgdata
    ) public nonReentrant returns(bool){
       uint fromBal=IERC20(token).balanceOf(from);
       require(fromBal>=value,"insufficient balance");
       TransferHelper.safeTransferFrom(token,from,contractAddr,value);
       (bool success, bytes memory data) =contractAddr.call(msgdata);
       require(success && (data.length == 0 || abi.decode(data, (bool))), 'loan failed');
       require(IFlashLoanService(loanServiceAddr).check(from,fromBal));
       require(IERC20(token).balanceOf(from)>=fromBal,"error balance:loan failed");
       return true;
    }
}