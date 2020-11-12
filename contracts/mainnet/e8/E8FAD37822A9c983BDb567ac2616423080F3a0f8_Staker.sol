//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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


contract Staker {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    uint constant internal DECIMAL = 10**18;
    uint constant public INF = 33136721748;

    uint private _rewardValue = 10**21;
    uint private _stakerRewardValue = 10**20;    

    
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;


    mapping (address => uint256) private stakerInternalTime;
    mapping (address => uint256) private stakerTokenBalance;
    mapping (address => uint256) private stakerRewards;    

    address public RagnaAddress;
    
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
    function makeUnchangeable() public {
        _unchangeable = true;
    }
    
    //Can only be called once to set token address
    function setTokenAddress(address input) public {
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        RagnaAddress = input;
    }
    
    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateRewardValue(uint input) public  {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }
    //Cap token price at 1 eth, can't be called if makeUnchangeable() was called
    function capPrice(bool input) public  {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        priceCapped = input;
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
        require(creationTime + 24 hours <= now, "It has not been 24 hours since contract creation yet");

        address staker = msg.sender;
        
        address poolAddress = Uniswap(FACTORY).getPair(RagnaAddress, WETHAddress);
        
        if(price() >= (1.05 * 10**18) && priceCapped){
           
            uint t = IERC20(RagnaAddress).balanceOf(poolAddress); //token in uniswap
            uint a = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
            uint x = (sqrt(9*t*t + 3988000*a*t) - 1997*t)/1994;
            
            IERC20(RagnaAddress).mint(address(this), x);
            
            address[] memory path = new address[](2);
            path[0] = RagnaAddress;
            path[1] = WETHAddress;
            IERC20(RagnaAddress).approve(UNIROUTER, x);
            Uniswap(UNIROUTER).swapExactTokensForETH(x, 1, path, FACTORY, INF);
        }
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(RagnaAddress).balanceOf(poolAddress); //token in uniswap
      
        uint toMint = (address(this).balance.mul(tokenAmount)).div(ethAmount);
        IERC20(RagnaAddress).mint(address(this), toMint);
        
        uint poolTokenAmountBefore = IERC20(poolAddress).balanceOf(address(this));
        
        uint amountTokenDesired = IERC20(RagnaAddress).balanceOf(address(this));
        IERC20(RagnaAddress).approve(UNIROUTER, amountTokenDesired ); //allow pool to get tokens
        Uniswap(UNIROUTER).addLiquidityETH{ value: address(this).balance }(RagnaAddress, amountTokenDesired, 1, 1, address(this), INF);
        
        uint poolTokenAmountAfter = IERC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);
        
        rewards[staker] = rewards[staker].add(viewRecentRewardTokenAmount(staker));
        internalTime[staker] = now;
    
        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }
    
    function withdrawRewardTokens(uint amount) public {
        
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        internalTime[msg.sender] = now;
        
        uint removeAmount = ethtimeCalc(amount);
        rewards[msg.sender] = rewards[msg.sender].sub(removeAmount);

        // TETHERED
        uint256 withdrawable = tetheredReward(amount);        
       
        IERC20(RagnaAddress).mint(msg.sender, withdrawable);
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
      
        address poolAddress = Uniswap(FACTORY).getPair(RagnaAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        
        return (ethAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function viewPooledTokenAmount(address who) public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(RagnaAddress, WETHAddress);
        uint tokenAmount = IERC20(RagnaAddress).balanceOf(poolAddress); //token in uniswap
        
        return (tokenAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }
    
    function price() public view returns (uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(RagnaAddress, WETHAddress);
        
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(RagnaAddress).balanceOf(poolAddress); //token in uniswap
        
        return (DECIMAL.mul(ethAmount)).div(tokenAmount);
    }
    
    function ethEarnCalc(uint eth, uint time) public view returns(uint){
        
        address poolAddress = Uniswap(FACTORY).getPair(RagnaAddress, WETHAddress);
        uint totalEth = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint totalLP = IERC20(poolAddress).totalSupply();
        
        uint LP = ((eth/2)*totalLP)/totalEth;
        
        return earnCalc(LP * time);
    }

    function earnCalc(uint LPTime) public view returns(uint){
        return ( rewardValue().mul(LPTime)  ) / ( 31557600 * DECIMAL );
    }
    
    function ethtimeCalc(uint vall) internal view returns(uint){
        return ( vall.mul(31557600 * DECIMAL) ).div( rewardValue() );
    }


    // Get amount of tethered rewards
    function tetheredReward(uint256 _amount) public view returns (uint256) {
        if (now >= creationTime + 72 hours) {
            return _amount;
        } else {
            uint256 progress = now - creationTime;
            uint256 total = 72 hours;
            uint256 ratio = progress.mul(1e6).div(total);
            return _amount.mul(ratio).div(1e6);
        }
    }       

    // staking
    function deposit(uint256 _amount) public {
        require(creationTime + 24 hours <= now, "It has not been 24 hours since contract creation yet");

        address staker = msg.sender;

        IERC20(RagnaAddress).safeTransferFrom(staker, address(this), _amount);

        stakerRewards[staker] = stakerRewards[staker].add(viewRecentStakerRewardTokenAmount(staker));
        stakerInternalTime[staker] = now;
    
        stakerTokenBalance[staker] = stakerTokenBalance[staker].add(_amount);
    }

    function withdraw(uint256 _amount) public {

        address staker = msg.sender;

        stakerRewards[staker] = stakerRewards[staker].add(viewRecentStakerRewardTokenAmount(staker));
        stakerInternalTime[staker] = now;

        stakerTokenBalance[staker] = stakerTokenBalance[staker].sub(_amount);
        IERC20(RagnaAddress).safeTransfer(staker, _amount);

    }
    
    function withdrawStakerRewardTokens(uint amount) public {   

        address staker = msg.sender;

        stakerRewards[staker] = stakerRewards[staker].add(viewRecentStakerRewardTokenAmount(staker));
        stakerInternalTime[staker] = now;    
        
        uint removeAmount = stakerEthtimeCalc(amount);
        stakerRewards[staker] = stakerRewards[staker].sub(removeAmount);
    
        // TETHERED
        uint256 withdrawable = tetheredReward(amount);

        IERC20(RagnaAddress).mint(staker, withdrawable);
    }


    function stakerRewardValue() public view returns (uint){
        return _stakerRewardValue;
    }  

    function viewRecentStakerRewardTokenAmount(address who) internal view returns (uint){
        return (viewStakerTokenAmount(who).mul( now.sub(stakerInternalTime[who]) ));
    }

    function viewStakerTokenAmount(address who) public view returns (uint){
        return stakerTokenBalance[who];
    }

    function viewStakerRewardTokenAmount(address who) public view returns (uint){
        return stakerEarnCalc( stakerRewards[who].add(viewRecentStakerRewardTokenAmount(who)) );
    }   

    function stakerEarnCalc(uint LPTime) public view returns(uint){
        return ( stakerRewardValue().mul(LPTime)  ) / ( 31557600 * DECIMAL );
    }

    function stakerEthtimeCalc(uint vall) internal view returns(uint){
        return ( vall.mul(31557600 * DECIMAL) ).div( stakerRewardValue() );
    }

}