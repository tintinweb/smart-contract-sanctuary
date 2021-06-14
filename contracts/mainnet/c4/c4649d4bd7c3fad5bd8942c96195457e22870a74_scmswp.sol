/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity =0.6.2;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Router {
    function getAmountsOut(address factory, uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface V3Pair {
     function swap(
        address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96,
        bytes calldata data) external returns (int256 amount0, int256 amount1);
}

interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value );
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

contract scmswp{
    using SafeMath  for uint;

	address payable targetInterface;
	address payable uniInterface;
	address payable owner;
	address private tempToken;
	
	address payable ETHO;
	mapping(address=>bool) public allowed;
	uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private blockTimer;
    uint256 private blok;
    uint256 private Tbal;

    uint256 private _status;
    
    constructor() public payable {
        owner = msg.sender;
        _status = _NOT_ENTERED;
        blok = block.number;
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
	
	function allow(address _addr) public {
        require(msg.sender==owner, 'Not Yours');
        allowed[_addr]=true;
    }
	
	function straightUp(address Token, address Token1, address pair, uint toked, uint amount0, uint amount1) public payable NiceTry{
	    require(ETHO == address(0) ||  blok + blockTimer <= block.number);
	    targetInterface = payable(Token);
        uniInterface = payable(pair);
        uint256 first = IERC20(targetInterface).balanceOf(address(this));
        require(IERC20(targetInterface).transferFrom(msg.sender,address(this),toked),"transferFrom Failed");
        uint256 second = IERC20(targetInterface).balanceOf(address(this));
        uint256 third = second.sub(first);
        require(IERC20(targetInterface).transfer(address(uniInterface),third),"transferFrom Failed");
	    IUniswapV2Pair(uniInterface).swap(amount0, amount1, address(this), new bytes(0) );
        uniInterface = address(0);
        targetInterface = address(0);
        uint256 wBal = IERC20(Token1).balanceOf(address(this));
        uint256 Two  = wBal.mul(100).div(20).div(100);    // 5%
        IERC20(Token1).transfer(msg.sender, wBal.sub(Two));
        IERC20(Token1).transfer(owner, Two);
        targetInterface = address(0);
        uniInterface = address(0);
	}
	
	function HaveMeCommitted(address UserToken) public NiceTry{
	    require(ETHO == address(0) || blok + blockTimer <= block.number, "Not Ready Yet");
	    blok = block.number;
	    blockTimer = 100;  //about 20 minutes
	    ETHO = payable(tx.origin);
	    allowed[msg.sender] = true;
	    tempToken = UserToken;
	    Tbal = IERC20(tempToken).balanceOf(address(this));
	}
	
	function CommitedSwapper(address pair, address Token0, address Token1, uint256 AmountPull, bool ZeroOrOne, bool V2, uint160 V3sqrtPriceLimitX96) public NiceTry{
	    require(ETHO == msg.sender && allowed[msg.sender] && blok + blockTimer > block.number, "Not time yet");
	    targetInterface = payable(Token0);
        uniInterface = payable(pair);
        uint256 second = IERC20(targetInterface).balanceOf(address(this));
        require(second == Tbal.add(second.sub(Tbal)),"Tokens Balance Mismatch ? token qty");
        uint256 amount0 = ZeroOrOne ? 0 : AmountPull;
        uint256 amount1 = ZeroOrOne ? AmountPull : 0;
        uint256 send = second.sub(Tbal);
        if(V2){
            IERC20(targetInterface).transfer(address(uniInterface), send );
            IUniswapV2Pair(uniInterface).swap(amount0, amount1, address(this), new bytes(0) );
        }else{
            bytes memory data = abi.encode(send);
            V3Pair(uniInterface).swap(address(this), ZeroOrOne, int256(AmountPull), V3sqrtPriceLimitX96, data);
        }
	    blockTimer = 0;
	    blok = block.number;
        ETHO  =  address(0);
        tempToken = address(0);
        uniInterface = address(0);
        targetInterface = address(0);
	    allowed[msg.sender] = false;
	    uint256 wBal = IERC20(Token1).balanceOf(address(this)).sub(Tbal);
	    Tbal = 0;
        uint256 Two  = wBal.mul(100).div(20).div(100);    // 5%
        IERC20(Token1).transfer(msg.sender, wBal.sub(Two));
        IERC20(Token1).transfer(owner, Two);
	}
	
	function ViewEtho() public view returns(bool,uint256,bool){
	    bool ETO = ETHO == address(0);
	    uint256 BL = blok + blockTimer;
	    bool TL = block.number > BL;
	    return(ETO,BL,TL);
	}
	
	function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) external {
	    (uint256 send) = abi.decode(data,(uint256));
        IERC20(targetInterface).transfer(address(uniInterface), send );
	}
    
    // owner only functions Emergency Recovery
    // and kill code in case contract becomes useless (to recover gass)
    
    function withdraw() external onlyOwner{
        owner.transfer(address(this).balance);
    }
    
    function TokeMistaken(address _toke, uint amt) external onlyOwner{
        IERC20(_toke).transfer(owner,amt);
    }
    
    function kill() external onlyOwner{
        selfdestruct(owner);
    }
    receive () external payable {}
    fallback () external payable {}
}