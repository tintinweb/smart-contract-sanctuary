/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity =0.6.2;


interface V3Pair {
     function swap(
        address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96,
        bytes calldata data) external returns (int256 amount0, int256 amount1);
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'MY ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'MY ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'MY ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MY SafeMath: division by zero");
        return a / b;
    }
}

contract LpSwap{
    using SafeMath  for uint;

	address payable token0;
	
	address payable uniInterface;
	address payable owner;
	
	mapping(address=>uint256) public time;
	
	uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    
    constructor() public payable {
        owner = msg.sender;
        _status = _NOT_ENTERED;
        time[owner] = now+4784119860;
    }
    
	modifier onlyOwner {
	    require(tx.origin==owner,'not owner');
	    _;
	}
	
	modifier NiceTry {
        require(_status != _ENTERED, "Only Once May You Pass");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
	
    
    function giveTime(uint256 timed, address user) public onlyOwner{
	    time[user] = now+timed;
    }
    
    function getUserTime(address user) public view returns(uint256 timeLeft){
        timeLeft = time[user];
    }
    
    function BuyTime(uint256 timed) public payable {
        if(timed <= 3600){
            require(msg.value >= 0.001 ether, "wrong payment");
        }
        if(timed > 3600 && timed <= 7200){
            require(msg.value >= 0.002 ether, "wrong payment");
        }
        if(timed > 7200 && timed <= 10800){
            require(msg.value >= 0.003 ether, "wrong payment");
        }
        if(timed > 10800 && timed <= 21600){
            require(msg.value >= 0.005 ether, "wrong payment");
        }
        if(timed > 21600 && timed <= 43200){
            require(msg.value >= 0.008 ether, "wrong payment");
        }
        if(timed > 43200 && timed <= 86400){
            require(msg.value >= 0.01 ether, "wrong payment");
        }
        if(timed > 86400){
            require(msg.value >= 0.02 ether, "wrong payment");
        }
	    time[msg.sender] = now+timed;
    }

	
	function DirectSwap(address pair, address SellToken, int256 AmountPull, uint256 send, bool ZeroOrOne,uint160 V3sqrtPriceLimitX96) public NiceTry{
	    require(time[msg.sender] > now, "Not paid, or times up");
	    token0 = payable(SellToken);
        uniInterface = payable(pair);
        bytes memory data = abi.encode(send,msg.sender);
        V3Pair(uniInterface).swap(msg.sender, ZeroOrOne, int256(AmountPull), V3sqrtPriceLimitX96, data);
        token0 = address(0);
        uniInterface = address(0);
	}
	
	
	function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) external {
	    (uint256 send, address user) = abi.decode(data,(uint256,address));
        safeTransferFrom(token0, user, address(uniInterface), send );
	}
    
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    // owner only functions Emergency Recovery
    // and kill code in case contract becomes useless (to recover gass)
    
    function withdraw() external onlyOwner{
        owner.transfer(address(this).balance);
    }
    
    function TokeMistaken(address _toke, address where, uint amt) external onlyOwner{
        safeTransfer(_toke,where,amt);
    }
    
    function kill() external onlyOwner{
        selfdestruct(owner);
    }
    receive () external payable {}
    fallback () external payable {}
}