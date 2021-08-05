//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./safemath.sol";
import "./UniswapV2Router02.sol";
import "./UniswapV2Helper.sol";
import "./UniswapV2Factory.sol";
import "./IntMonaToken.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Context.sol"; 


contract MONA__Presale is Context {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    IERC20 token;
    IERC20 LISAv1;
    
    uint public tokensBought;
    bool public isRunning = true;
    bool public poolgenEnd = false;
    bool public EnableEmergencyRefund = false;
    bool public FirstPhaseEnd = false;
    address payable owner;
    
    uint256 public ethSent;
    uint256 tokensPerETH                = 800; // 80.0 ( 1 ETH = 80.0 LISAv2 )
    uint256 tokensPerETHAfterPresale    = 500; // 50.0 ( 1 ETH = 50.0 LISAv2 )
    uint256 tokensPerV1Tokens           =   6; //  0.6 ( 1 LISA = 0.6 LISAv2 )
    
    uint256 public lockedLiquidityAmount;
    

    mapping(address => uint) ethSpent; 
    
    mapping(address => mapping ( address => uint256)) _allowances;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    
    // UNISWAP DECLARATIONS - BEGIN
    address public uniswapPair;
    
    
    address public constant uniswapHelperAddress = 0x5CdF8D8CbCFf0AD458efed22A7451b69bAa0e8B6; 
    address public constant uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  
    

    UniswapV2Router02 private uniswapRouter;
    UniswapV2Factory private uniswapFactory;
    UniswapV2Helper private uniswapHelper; 
    
    // UNISWAP DECLARATIONS - END
    
    MonaToken private LISAv2;
    
    
    // address where liquidity pool tokens will be locked
    constructor(IERC20 _tokenV2, IERC20 _tokenV1 ) {
        token = _tokenV2;
        owner = msg.sender; 
        
        LISAv2 = MonaToken( address( _tokenV2 ) ); 
        LISAv1 = IERC20( _tokenV1 );
        
        uniswapFactory = UniswapV2Factory( uniswapFactoryAddress );
        uniswapRouter = UniswapV2Router02( uniswapRouterAddress );
        
        
        if( uniswapPair == address(0) ){
            uniswapPair = uniswapFactory.createPair(
                address( uniswapRouter.WETH() ),
                address( token )
            );
        } 
    }
    
    
    receive() external payable { 
        
        require(isRunning, "Actual presale is off!");
        
        require(msg.value >= 0.01 ether, "You sent less than 0.01 ETH");
        require(msg.value <= 2 ether,    "You sent more than 2.00 ETH");
        
        require(ethSent.add(msg.value) <= 150 ether, "Hard cap reached");
        
        require(ethSpent[msg.sender].add(msg.value) <= 2 ether, "You can't buy more");
        
        uint256 tokens = msg.value.mul(tokensPerETH).div( 10 );
        require(token.balanceOf(address(this)) >= tokens, "Not enough tokens in the contract");
        token.transfer(msg.sender, tokens);
        
        ethSpent[msg.sender] = ethSpent[msg.sender].add(msg.value);
        tokensBought = tokensBought.add(tokens);
        
        ethSent = ethSent.add(msg.value);
    }
    
    function releaseLISAv1() public onlyOwner {
        
        uint256 amount = LISAv1.balanceOf( address(this) );
        LISAv1.approve( owner, amount);
        LISAv1.safeTransferFrom( address(this), owner, amount);
        
    }
   
    function userEthSpenttInPresale(address user) external view returns(uint){
        return ethSpent[user];
    }
    
    function phaseEnd( ) external onlyOwner{
        FirstPhaseEnd = true;
    }
    function presaleEndAndCreateLiquidity( address _liquidityLockAddress ) external onlyOwner{
        // lock Preslae
        isRunning = false;
        
        // unlock emergencyRefund if something goes wrong
        EnableEmergencyRefund = true;
        
        // check if Create Liquidity has already been done
        require( poolgenEnd == false, "Liquidity generation already finished");
        
        // create liquidity - BEGIN
        
        // [ ETH to liquidity ] = [ ETH balance ]
        uint256 liquidityETH = address(this).balance;
        
        // [ tokens to liquidity ] = [ liquidity eth ] * [ tokens per ETH ]
        uint256 liquidityDesiredTokens = liquidityETH.mul( tokensPerETHAfterPresale ).div(10);
        
        // transaction must be completed within 5 minutes
        uint256 transactionDeadline = block.timestamp.add(5 minutes);
        
        LISAv2.approve(address(uniswapRouter), liquidityDesiredTokens);
        
        // send tokens and ETH to liquidity pool 
        try uniswapRouter.addLiquidityETH{ value: liquidityETH }(
                address( LISAv2 ),
                liquidityDesiredTokens,
                liquidityDesiredTokens,
                liquidityETH,
                address( _liquidityLockAddress ),
                transactionDeadline
            ) returns (uint amountToken, uint amountETH, uint liquidity)
        {
            // burn rest of tokens
            LISAv2.burn( token.balanceOf(address(this)));
            
        } catch {
            // error handling
        }
        
        // create liquidity - END
        
        // lock Create Liquidity
        poolgenEnd = true;
    }
    
    function swap(uint256 amount) external payable { 
        if(FirstPhaseEnd == true){
             revert( "First Phase already finished" );
        }
        require(isRunning, "Actual swap is off!");
        require(amount > 0, "Cannot swap 0");
        
        LISAv1.safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 tokens = amount.mul( tokensPerV1Tokens ).div( 10 );
        require( token.balanceOf(address(this)) >= tokens, "Not enough tokens in the contract");
        token.transfer(msg.sender, tokens);
        
    }
    
    
    
    // emergencyRefund in case of a bug in liquidity generation
    // transfer all funds to owner to refund people
    // Only available when liquidity pool not created ( if poolGenFailed == true )
    function emergencyRefund() public onlyOwner {
        // check if emergencyRefund is unlocked
        if(EnableEmergencyRefund == true){
            // send rest of tokens and eth to owner for refund or manualy create Liquidity
            owner.transfer(address(this).balance); 
            token.transfer(owner, token.balanceOf(address(this)));
        }
    }
}

    