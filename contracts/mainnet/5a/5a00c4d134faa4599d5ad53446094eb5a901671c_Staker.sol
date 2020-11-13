//    /\  _  \/\  _`\ /\__  _\/\  _`\ /\  _`\     
//    \ \ \L\ \ \,\L\_\/_/\ \/\ \ \L\_\ \ \L\ \   
//     \ \  __ \/_\__ \  \ \ \ \ \  _\L\ \ ,  /   
//      \ \ \/\ \/\ \L\ \ \ \ \ \ \ \L\ \ \ \\ \  
//       \ \_\ \_\ `\____\ \ \_\ \ \____/\ \_\ \_\
//        \/_/\/_/\/_____/  \/_/  \/___/  \/_/\/ /
// ASTER PROJECT - ASTER-1H 
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Uniswap{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
}

interface Pool{
    function primary() external view returns (address);
}

contract Poolable{
    
    address payable internal constant _POOLADDRESS = 0x6fe6403080A3f80Da00387224E7846E1239DEC26;
 
    function primary() private view returns (address) {
        return Pool(_POOLADDRESS).primary();
    }
    
    modifier onlyPrimary() {
        require(msg.sender == primary(), "Caller is not primary");
        _;
    }
}

contract Staker is Poolable{
    
    using SafeMath for uint256;
    
    uint constant internal DECIMAL = 10**18;
    uint constant public INF = 33136721748;

    uint private _rewardValue = 10**18;
    
    mapping (address => uint256) public  timePooled;
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;
    mapping (address => uint256) private referralEarned;

    address public Ast1Address;
    
    address constant public UNIROUTER         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public FACTORY           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(UNIROUTER).WETH();
    
    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    
    receive() external payable {
        
       if(msg.sender != UNIROUTER){
           stake(msg.sender, address(0));
       }
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{ value: amount }(""); 
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    //If true, no changes can be made
    function unchangeable() public view returns (bool){
        return _unchangeable;
    }
    
    function rewardValue() public view returns (uint){
        return _rewardValue;
    }
    
    
    //THE ONLY ADMIN FUNCTIONS vvvv
    //After this is called, no changes can be made
    function makeUnchangeable() public{
        _unchangeable = true;
    }
    
    //Can only be called once to set token address
    function setTokenAddress(address input) public{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        Ast1Address = input;
    }
    
    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateRewardValue(uint input) public {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }
    //THE ONLY ADMIN FUNCTIONS ^^^^
    
  
    function stake(address staker, address payable ref) public payable{
        
		staker = msg.sender;
		
        if(ref != address(0)){
            
            referralEarned[ref] = referralEarned[ref] + ((address(this).balance/10)*DECIMAL)/price();
        }
    
        sendValue(_POOLADDRESS, address(this).balance/2);
        
        address poolAddress = Uniswap(FACTORY).getPair(Ast1Address, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(Ast1Address).balanceOf(poolAddress); //token in uniswap
        
        uint toMint = (address(this).balance.mul(tokenAmount)).div(ethAmount);
        IERC20(Ast1Address).mint(address(this), toMint);
        
        uint poolTokenAmountBefore = IERC20(poolAddress).balanceOf(address(this));
        
        uint amountTokenDesired = IERC20(Ast1Address).balanceOf(address(this));
        IERC20(Ast1Address).approve(UNIROUTER, amountTokenDesired ); //allow pool to get tokens
        Uniswap(UNIROUTER).addLiquidityETH{ value: address(this).balance }(Ast1Address, amountTokenDesired, 1, 1, address(this), INF);
        
        uint poolTokenAmountAfter = IERC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);
        
        rewards[staker] = rewards[staker].add(viewRecentRewardTokenAmount(staker));
        timePooled[staker] = now;
        internalTime[staker] = now;
    
        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }

    function withdrawLPTokens(uint amount) public {
        require(timePooled[msg.sender] + 1 hours <= now, "It has not been 1 hours since you staked yet");
        
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].sub(amount);
        
        address poolAddress = Uniswap(FACTORY).getPair(Ast1Address, WETHAddress);
        IERC20(poolAddress).transfer(msg.sender, amount);
        
        internalTime[msg.sender] = now;
    }
    
    function withdrawRewardTokens(uint amount) public {
        require(timePooled[msg.sender] + 1 hours <= now, "It has not been 1 hours since you staked yet");
        
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        internalTime[msg.sender] = now;
        
        uint removeAmount = ethtimeCalc(amount)/2;
        rewards[msg.sender] = rewards[msg.sender].sub(removeAmount);
       
        IERC20(Ast1Address).mint(msg.sender, amount);
    }
    
    function withdrawReferralEarned(uint amount) public{
        require(timePooled[msg.sender] != 0, "You have to stake at least a little bit to withdraw referral rewards");
        require(timePooled[msg.sender] + 1 hours <= now, "It has not been 1 hours since you staked yet");
        
        referralEarned[msg.sender] = referralEarned[msg.sender].sub(amount);
        IERC20(Ast1Address).mint(msg.sender, amount);
    }
    
    function viewRecentRewardTokenAmount(address who) internal view returns (uint){
        return (viewPooledEthAmount(who).mul( now.sub(internalTime[who]) ));
    }
    
    function viewRewardTokenAmount(address who) public view returns (uint){
        return earnCalc( rewards[who].add(viewRecentRewardTokenAmount(who))*2 );
    }
    
    function viewLPTokenAmount(address who) public view returns (uint){
        return LPTokenBalance[who];
    }
    
    function viewPooledEthAmount(address who) public view returns (uint){
      
        address poolAddress = Uniswap(FACTORY).getPair(Ast1Address, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        
        return (ethAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function viewPooledTokenAmount(address who) public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(Ast1Address, WETHAddress);
        uint tokenAmount = IERC20(Ast1Address).balanceOf(poolAddress); //token in uniswap
        
        return (tokenAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function viewReferralEarned(address who) public view returns (uint){
        return referralEarned[who];
    }
    
    function price() public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(Ast1Address, WETHAddress);
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(Ast1Address).balanceOf(poolAddress); //token in uniswap
        
        return (DECIMAL.mul(ethAmount)).div(tokenAmount);
    }

    function earnCalc(uint ethTime) public view returns(uint){
        return ( rewardValue().mul(ethTime)  ) / ( 31557600 * DECIMAL );
    }
    
    function ethtimeCalc(uint Ast1) internal view returns(uint){
        return ( Ast1.mul(31557600 * DECIMAL) ).div( rewardValue() );
    }
}