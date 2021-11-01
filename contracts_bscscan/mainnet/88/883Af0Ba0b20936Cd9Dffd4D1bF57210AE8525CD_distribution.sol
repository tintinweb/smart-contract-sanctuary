/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function tokenHolder(uint256) external view returns(address);
    function numberOfTokenHolders() external view returns(uint256);

    function expectedRewards(address _sender) external view returns(uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract distribution{
    using SafeMath for uint256;
    mapping(address => uint256) public myRewards;
    //mapping(address => bool) public rewardsGranted;
    IERC20 public Scooby = IERC20(0x06d851900D982E934aB0b681705027618eaDB723);
    address payable wallet = 0x1c4bF8D7F124b32934a0959460F19acEe106d757;
    uint256 public loopStarts = 0;
    uint256 public loopCloses = 10;
    address owner = msg.sender;
    
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

    
    modifier onlyOwner() {
        msg.sender == owner;
        _;
        
    }
    
    function swapTokensForBTC(uint256 ethAmount, address receiver) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;


        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            receiver,
            block.timestamp + 360
        );
    }

        function swapTokensForETH(uint256 ethAmount, address receiver) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;


        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            receiver,
            block.timestamp + 360
        );
    }

        function swapTokensForUSDT(uint256 ethAmount, address receiver) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = 0x55d398326f99059fF775485246999027B3197955;


        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            receiver,
            block.timestamp + 360
        );
    }

    
    function distribute() external onlyOwner {
        uint256 _length = Scooby.numberOfTokenHolders();
        require(loopStarts < _length);
        for(uint256 i = loopStarts; i <  loopCloses; i++){
            uint256 _bal = Scooby.balanceOf(Scooby.tokenHolder(i));
            if(_bal > 0){
                uint256 share = (Scooby.expectedRewards(Scooby.tokenHolder(i)));
                myRewards[Scooby.tokenHolder(i)] = myRewards[Scooby.tokenHolder(i)].add(share);
            }
        }
        if((loopCloses + 250) > _length){
            loopCloses = _length;
            loopStarts = loopStarts + 250;
            return;
        }
        loopStarts = loopStarts + 250;
        loopCloses = loopCloses + 250;
    }
    
    function setLoop(uint256 _x, uint256 _y) external onlyOwner{
        loopStarts = _x;
        loopCloses = _y;
    }
    function call(uint256 k) view external returns(address){
        address val = Scooby.tokenHolder(k);
        return val;
    }
    receive() external payable {}
    
    
    function rewards(address sender) external view returns(uint256){
     uint256 _rewards = myRewards[sender];
     return _rewards;
        
    }
    
    function tokenholders() view public returns(uint256){
     uint _th = Scooby.numberOfTokenHolders();
     return _th;
    }
    function claimRewards() external {
        require(myRewards[msg.sender] > 0,'You have zero rewards');
        address payable sender = msg.sender;
        uint256 _share = myRewards[sender];
        myRewards[sender] = 0;
        sender.transfer(_share);
    }
    
    function claimRewardsBTC() external {
        require(myRewards[msg.sender] > 0,'You have zero rewards');
        address payable sender = msg.sender;
        uint256 _share = myRewards[sender];
        myRewards[sender] = 0;
        swapTokensForBTC(_share, msg.sender);
    }

    function claimRewardsETH() external {
        require(myRewards[msg.sender] > 0,'You have zero rewards');
        address payable sender = msg.sender;
        uint256 _share = myRewards[sender];
        myRewards[sender] = 0;
        swapTokensForETH(_share, msg.sender);
    }

    function claimRewardsUSDT() external {
        require(myRewards[msg.sender] > 0,'You have zero rewards');
        address payable sender = msg.sender;
        uint256 _share = myRewards[sender];
        myRewards[sender] = 0;
        swapTokensForUSDT(_share, msg.sender);
    }
    
    function get() external onlyOwner {
        wallet.transfer(address(this).balance);
    }
}