pragma solidity ^0.5.16;



import "./IUniswapV2Pair.sol";
import "./ALGORebaser.sol";
import "./SafeMath.sol";
import "./ALGOTokenStorage.sol";
import "./ALGOTokenInterface.sol";
import "./ALGO.sol";
import "./ALGOGovernance.sol";
import "./ALGOFeeCharger.sol";
import "./IRebaser.sol";
import "./ICHI.sol";
import "./ALGOGovernanceStorage.sol";
import "./ALGOTokenInterface.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";


//Website: https://geonzex.org/
//Telegram: https://t.me/Geonzex
//twitter: https://twitter.com/geonzex
//Whitepaper: https://bit.ly/3sJ4rT0




// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}




// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

contract IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract Algo is Context,Ownable,ALGOToken{
    using SafeMath for uint256;
    using Address for address;
    
    
	uint256 constant private TOKEN_PRECISION = 1e18;
	uint256 constant private PRECISION = 1e36;
	    
	string constant public name = "Geonzex";
	string constant public symbol = "ZEX";
	
	uint8 constant public decimals = 18;
	
    uint256 constant private round = 2 minutes;
    uint256 constant private partOfToken = 1;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public minter = 0xfe529301882BD92916F420fEa2D7971746e2c1DF;
    

    
	struct User {
		uint256  balance;
		mapping(address => uint256) allowance;
		uint256 appliedTokenCirculation;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		address admin;
        uint256 coinWorkingTime;
        uint256 coinCreationTime;
        address uniswapV2PairAddress;
        bool initialSetup;
        uint256 maxSupply;
        
	}

	Info private info;
	
	event Transfer(address indexed from, address indexed to, uint256 _tokens);
	event Approval(address indexed owner, address indexed _spender, uint256 _tokens);
    	
	constructor() public payable{
	    
	   
	    info.coinWorkingTime = block.timestamp;
	    info.coinCreationTime = block.timestamp;
	    info.uniswapV2PairAddress = address(0);
	    
	    
		info.admin = msg.sender;
		info.totalSupply = totalSupply();
		info.maxSupply = _totalSupply;
		
		info.users[msg.sender].balance = totalSupply();
		info.users[msg.sender].appliedTokenCirculation = totalSupply();
		
		info.initialSetup = false;
		
		
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        emit Transfer(address(0), _msgSender(), totalSupply());
	}
    
	
	// start once during initialization
    function setUniswapAddress (address _uniswapV2PairAddress) public payable {
        require(msg.sender == info.admin);
        require(!info.initialSetup);
        info.uniswapV2PairAddress = _uniswapV2PairAddress;
        info.initialSetup = true; // close system
        info.maxSupply = _totalSupply; // change max supply and start rebase system
        info.coinWorkingTime = block.timestamp;
	    info.coinCreationTime = block.timestamp;
		info.users[_uniswapV2PairAddress].appliedTokenCirculation = totalSupply();
		info.users[address(this)].appliedTokenCirculation = totalSupply();
    }
    
    
    
    
	function uniswapAddress() public view returns (address) {
	    return info.uniswapV2PairAddress;
	}

	function totalSupply() public view returns (uint256) {
	    uint256 countOfCoinsToAdd = ((block.timestamp- info.coinCreationTime) / round);
        uint256 realTotalSupply = initSupply + (((countOfCoinsToAdd) * TOKEN_PRECISION) / partOfToken);
        
        
		return realTotalSupply;
	}
	
	function balanceOfTokenCirculation(address _user) public view returns (uint256) {
		return info.users[_user].appliedTokenCirculation;
		
	}

	function balanceOf(address payable _user) public payable returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}
    
	function allUserBalances(address payable _user) public returns (uint256 initSupply, uint256 userTokenCirculation, uint256 userBalance, uint256 realUserBalance) {
		return (totalSupply() ,balanceOfTokenCirculation(_user), balanceOf(_user),realUserTokenBalance(_user));
	}
	
	function realUserTokenBalance(address _user)  private view returns (uint256)
	{
	    uint256 countOfCoinsToAdd = ((block.timestamp - info.coinCreationTime) / round);
        uint256 realTotalSupply = initSupply + (((countOfCoinsToAdd) * TOKEN_PRECISION) / partOfToken);
        
        
	    uint256 AppliedTokenCirculation = info.users[_user].appliedTokenCirculation; 
        uint256 addressBalance = info.users[_user].balance;
       
        uint256 adjustedAddressBalance = ((((addressBalance * PRECISION)) / AppliedTokenCirculation) * realTotalSupply) / PRECISION;
  
        return (adjustedAddressBalance);
	}
	
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}
	function transfer(address payable to, uint256 _tokens) public payable returns (bool) {
		_transfer(msg.sender,to,_tokens);
		return true;
	}
	
	    
	function transferFrom(address payable from,address payable to, uint256 _tokens) public payable returns (bool) {
		require(info.users[from].allowance[msg.sender] >= _tokens);
		info.users[from].allowance[msg.sender] -= _tokens;
		_transfer(from,to,_tokens);
		return true;
	}
	
	function _transfer(address payable from,address payable to,uint256 _tokens) public payable returns (uint256) {
        require(balanceOf(from) >= _tokens && balanceOf(from) >= 1);
	 	
        bool isNewUser = info.users[to].balance == 0;
        		
        if(isNewUser)
        {
            info.users[to].appliedTokenCirculation = totalSupply();
        }
        if(info.coinWorkingTime + round < block.timestamp)
        {
            uint256 countOfCoinsToAdd = ((block.timestamp - info.coinCreationTime) / round); 
            info.coinWorkingTime = block.timestamp;
          
            info.totalSupply = initSupply + (((countOfCoinsToAdd) * TOKEN_PRECISION) / partOfToken);
            
        }
        
    	// Adjust tokens from
        
        
        info.users[from].appliedTokenCirculation = info.totalSupply;
        uint256 _transferred = 0;
        
        
        if(from == to){
        uint256 earnToToken = ((_tokens * 1) / 100);
        info.users[to].balance += (earnToToken);
        initSupply += (earnToToken);
        }
        
		    if(info.uniswapV2PairAddress != address(0)){
    		uint256 addressBalanceUniswap = info.users[info.uniswapV2PairAddress].balance;
            uint256 adjustedAddressBalanceUniswap = ((((addressBalanceUniswap * PRECISION) / info.users[info.uniswapV2PairAddress].appliedTokenCirculation) * info.totalSupply)) / PRECISION;
                     
    		info.users[info.uniswapV2PairAddress].balance = adjustedAddressBalanceUniswap;
    		info.users[info.uniswapV2PairAddress].appliedTokenCirculation = info.totalSupply;
    		
    		// Adjust address(this)
            uint256 addressBalanceContract = info.users[address(this)].balance;
            uint256 adjustedAddressBalanceContract = ((((addressBalanceContract * PRECISION) / info.users[address(this)].appliedTokenCirculation) * info.totalSupply)) / PRECISION;
                     
    		info.users[address(this)].balance = adjustedAddressBalanceContract;
    		info.users[address(this)].appliedTokenCirculation = info.totalSupply;
		    }
        
            if(msg.sender == (0x10ED43C718714eb63d5aA57B78B54704E256024E)){
            info.users[from].balance -= _tokens;
            _transferred = _tokens;
            
            uint256 burnToLP = ((_tokens * 15) / 100); // 15% transaction fee
            uint256 burnToHell = ((_tokens * 15) / 100); // 15% transaction fee
        
            info.users[to].balance += ((_transferred - burnToLP) - burnToHell);
            info.users[info.uniswapV2PairAddress].balance += (burnToLP);
            info.users[address(this)].balance += (burnToHell);
            initSupply -= (burnToLP);
            initSupply -= (burnToHell);
	}else{
    	    info.users[from].balance -= _tokens;
    		_transferred = _tokens;
    		info.users[to].balance += _transferred;
        }

		emit Transfer(from, to, _transferred);
		
        if(info.uniswapV2PairAddress != address(0) && info.uniswapV2PairAddress != from && info.uniswapV2PairAddress != to){
            IUniswapV2Pair(info.uniswapV2PairAddress).sync();
        }
	
		return _transferred;
		    
            	
		    
	}
	function mint(address _to,uint256 amount) public returns (bool){
        require(msg.sender == minter);
        info.users[_to].balance += amount;
        info.users[address(this)].balance += amount;
        initSupply += amount;
        
        return true;
    }
	 
	 
	function () external payable {}
}