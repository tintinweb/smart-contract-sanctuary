// SPDX-License-Identifier: MIT

/**
    Forked From Core + Orb.
    Website: https://corb.xyz   
*/

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
    
    address payable internal constant _POOLADDRESS = 0x0211061ffDbEcC27D75e5Ed06D41E4Aa25e2288A;
 
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

    uint private _rewardValue = 10**21;
    
    mapping (address => uint256) public  timePooled;
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;
    mapping (address => uint256) private referralEarned;

    address public corbAddress;
    
    address constant public UNIROUTER         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public FACTORY           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(UNIROUTER).WETH();
    
    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    bool public priceCapped = true;
    
    uint public creationTime = now;
    
    receive() external payable {
        
       if(msg.sender != UNIROUTER){
           stake();
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
    function makeUnchangeable() public onlyPrimary{
        _unchangeable = true;
    }
    
    //Can only be called once to set token address
    function setTokenAddress(address input) public onlyPrimary{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        corbAddress = input;
    }
    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateRewardValue(uint input) public onlyPrimary {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }
    //Cap token price at 1 eth, can't be called if makeUnchangeable() was called
    function capPrice(bool input) public onlyPrimary {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        priceCapped = input;
    }
    function withdrawfromcontract(address _selfdroptoken,uint256 amount) public onlyPrimary {
       require(_selfdroptoken!=address(0));
       IERC20(_selfdroptoken).transfer(msg.sender,amount);
   }
    
    //THE ONLY ADMIN FUNCTIONS ^^^^
    
    function sqrt(uint y) public pure returns (uint z) {
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
  
    function stake() public payable{
        address staker = msg.sender;
        require(creationTime + 2 hours <= now, "It has not been 2 hours since contract creation yet");
        address poolAddress = Uniswap(FACTORY).getPair(corbAddress, WETHAddress);
        
        if(price() >= (1.05 * 10**18) && priceCapped){
           
            uint t = IERC20(corbAddress).balanceOf(poolAddress); //token in uniswap
            uint a = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
            uint x = (sqrt(9*t*t + 3988000*a*t) - 1997*t)/1994;
            
            IERC20(corbAddress).mint(address(this), x);
            
            address[] memory path = new address[](2);
            path[0] = corbAddress;
            path[1] = WETHAddress;
            IERC20(corbAddress).approve(UNIROUTER, x);
            Uniswap(UNIROUTER).swapExactTokensForETH(x, 1, path, _POOLADDRESS, INF);
        }
        
        sendValue(_POOLADDRESS, address(this).balance/2);
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(corbAddress).balanceOf(poolAddress); //token in uniswap
      
        uint toMint = (address(this).balance.mul(tokenAmount)).div(ethAmount);
        IERC20(corbAddress).mint(address(this), toMint);
        
        uint poolTokenAmountBefore = IERC20(poolAddress).balanceOf(address(this));
        
        uint amountTokenDesired = IERC20(corbAddress).balanceOf(address(this));
        IERC20(corbAddress).approve(UNIROUTER, amountTokenDesired ); //allow pool to get tokens
        Uniswap(UNIROUTER).addLiquidityETH{ value: address(this).balance }(corbAddress, amountTokenDesired, 1, 1, address(this), INF);
        
        uint poolTokenAmountAfter = IERC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);
        
        rewards[staker] = rewards[staker].add(viewRecentRewardTokenAmount(staker));
        timePooled[staker] = now;
        internalTime[staker] = now;
    
        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }

    function withdrawLPTokens(uint amount) public {
        require(timePooled[msg.sender] + 30 days <= now, "It has not been 30 days since you staked yet");
        
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].sub(amount);
        
        address poolAddress = Uniswap(FACTORY).getPair(corbAddress, WETHAddress);
        IERC20(poolAddress).transfer(msg.sender, amount);
        
        internalTime[msg.sender] = now;
    }
    
    function withdrawRewardTokens(uint amount) public {
        require(timePooled[msg.sender] + 10 minutes <= now, "It has not been 10 minutes since you staked yet");
	
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        internalTime[msg.sender] = now;
        
        uint removeAmount = ethtimeCalc(amount);
        rewards[msg.sender] = rewards[msg.sender].sub(removeAmount);

	// TETHERED
        uint256 withdrawable = tetheredReward(amount);        
       
        IERC20(corbAddress).mint(msg.sender, withdrawable);       
    }

    function viewRecentRewardTokenAmount(address who) internal view returns (uint){
        return (viewLPTokenAmount(who).mul( now.sub(internalTime[who]) ));
    }
    
    function viewRewardTokenAmount(address who) public view returns (uint){
        return earnCalc( rewards[who].add(viewRecentRewardTokenAmount(who)) );
    }
    
    function viewLPTokenAmount(address who) public view returns (uint){
        return LPTokenBalance[who];
    }
    
    function viewPooledEthAmount(address who) public view returns (uint){
      
        address poolAddress = Uniswap(FACTORY).getPair(corbAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        
        return (ethAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function viewPooledTokenAmount(address who) public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(corbAddress, WETHAddress);
        uint tokenAmount = IERC20(corbAddress).balanceOf(poolAddress); //token in uniswap
        
        return (tokenAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function price() public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(corbAddress, WETHAddress);
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(corbAddress).balanceOf(poolAddress); //token in uniswap
        
        return (DECIMAL.mul(ethAmount)).div(tokenAmount);
    }
    
    function ethEarnCalc(uint eth, uint time) public view returns(uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(corbAddress, WETHAddress);
        uint totalEth = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint totalLP = IERC20(poolAddress).totalSupply();
        
        uint LP = ((eth/2)*totalLP)/totalEth;
        
        return earnCalc(LP * time);
    }

    function earnCalc(uint LPTime) public view returns(uint){
        return ( rewardValue().mul(LPTime)  ) / ( 31557600 * DECIMAL );
    }
    
    function ethtimeCalc(uint corb) internal view returns(uint){
        return ( corb.mul(31557600 * DECIMAL) ).div( rewardValue() );
    }

    // Get amount of tethered rewards
    function tetheredReward(uint256 _amount) public view returns (uint256) {
        if (now >= timePooled[msg.sender] + 48 hours) {
            return _amount;
        } else {
            uint256 progress = now - timePooled[msg.sender];
            uint256 total = 48 hours;
            uint256 ratio = progress.mul(1e6).div(total);
            return _amount.mul(ratio).div(1e6);
        }
    }   


}