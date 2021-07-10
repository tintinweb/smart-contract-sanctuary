/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity =0.6.2;

interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function burn(address to) external returns (uint amount0, uint amount1);
    function skim(address to) external;
    function sync() external;
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

contract SLQ{
    using SafeMath  for uint;
    
	address payable public owner;
	address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	
	address send;
	
	uint256 AmountA;
	uint256 AmountB;
	uint256 blocked;
	uint256 timed = 0;
	uint256 timer = 50;
	
	constructor() public payable{
	    owner = msg.sender;
	}
	
	modifier onlyOwner(){
	    require(tx.origin==owner);
	    _;
	}    
	

	
	function getLQ(address pair, uint256 LP) public payable {
	    require(msg.value >= 0.005 ether);
	    pair.call(abi.encodeWithSignature("sync()"));
	    pair.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, pair, LP));
	    (bool success,) = pair.call(abi.encodeWithSignature("burn(address)",msg.sender));
	    require(success, "burn failed");
	}
	
	
	function getLQtwo(address pair, uint256 LP) public {
	    require(block.number > timed);
	    pair.call(abi.encodeWithSignature("sync()"));
	    pair.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, pair, LP));
	    (bool success, bytes memory data) = pair.call(abi.encodeWithSignature("burn(address)",address(this)));
	    require(success, "burn failed");
	    (uint256 A, uint256 B) = abi.decode(data,(uint256,uint256));
	    send = msg.sender;
	    AmountA = A;
	    AmountB = B;
	    blocked = block.number;
	    timed = blocked + timer;
	}
	
	function retrieve(address token0, address token1) public {
	    require(msg.sender == send && block.number <= timed);
	    if(token0 == weth){
	        uint256 fee = AmountA.mul(50).div(1000);
	        uint256 WthOut = AmountA.sub(fee);
	        token0.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender,WthOut));
	        uint256 BAL = IERC20(token1).balanceOf(address(this));
	        token1.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender,BAL));
	        
	        uint256 WBAL = IERC20(token0).balanceOf(address(this));
	        token0.call(abi.encodeWithSignature("transfer(address,uint256)",owner,WBAL));
	    }else{
	        uint256 fee = AmountB.mul(50).div(1000);
	        uint256 WthOut = AmountB.sub(fee);
	        token1.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender,WthOut));
	        uint256 BAL = IERC20(token0).balanceOf(address(this));
	        token0.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender,BAL));
	        
	        uint256 WBAL = IERC20(token1).balanceOf(address(this));
	        token1.call(abi.encodeWithSignature("transfer(address,uint256)",owner,WBAL));
	    }
	    send = address(0);
	    AmountA = 0;
	    AmountB = 0;
	    blocked = 0;
	    timed = 0;
	}
	
	
	function ViewEtho() public view returns(bool,uint256,bool){
	    bool ETO = send == address(0);
	    uint256 BL = blocked + timer;
	    bool TL = block.number > BL;
	    return(ETO,BL,TL);
	}
	
	
	function withdraw() public payable onlyOwner{
        owner.transfer( address( this ).balance );
    }

    function toke(address _toke, uint amt) public payable onlyOwner{
        if(_toke == weth){
            uint256 Wbal = IERC20(weth).balanceOf(address(this));
            weth.call(abi.encodeWithSignature("withdraw(uint256)",Wbal));
            owner.transfer(address(this).balance);
        }else{
            IERC20(_toke).transfer(owner,amt);
        }
    }
    
    function kill() external payable onlyOwner{
        selfdestruct(owner);
    }
    receive () external payable {}
    fallback () external payable {}
}