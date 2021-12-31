/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity ^0.6.12;
    
    // SPDX-License-Identifier: MIT
    
    library SafeMath {
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        uint256 c = a / b;
        return c;
      }
    
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
    
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    
      function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
      }
    }
    
    contract Owned {
        address payable public owner;
    
        event OwnershipTransferred(address indexed _from, address indexed _to);
    
        constructor() public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        
        function getOwner() public view returns(address){
        return owner;
        }
    
        function transferOwnership(address payable _newOwner) public onlyOwner {
            owner = _newOwner;
            emit OwnershipTransferred(msg.sender, _newOwner);
        }
    }
    
    
interface IBEP20 {
    function decimals() external view returns (uint256 balance);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

    interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    
        
contract LegitSale is Owned {
        using SafeMath for uint256;
        
        bool public isPresaleOpen;
        
        address public tokenAddress = 0x1489A7244Adc47E664D17dAE1969FAdB7d438C83;
        uint256 public tokenDecimals = 9;
        
        bool public isSaleEnabled = true;
        uint256 public rateDecimals = 0;
        
        uint256 public soldTokens=0;
        
        uint256 public totalsold = 0;
        
        address public LP = 0x3e5b309A103706f9828163f964CD59b3735Bfd8D;
        address public WBNB;
        
        struct UserStruct {
        bool isExist;
        address referrer;
        uint256 directCount;
        address[] referral;
        uint256 amount;
        uint256 earned;
        uint256 signedTime;
        }
        
    
      mapping (address => UserStruct) public users;
      mapping (address => address) public _parent;
    
      event Rewards(address indexed _from, address indexed _referrer, uint256 amount);
      event Claim(address indexed _from,address indexed _to,uint256 amount);
    
      uint256 public userCount = 0;
      uint256 public totalEarned = 0;
      
      uint256 public totalFee = 900;
   
    
      uint256[] public rewardLevel;

      uint256 public MAX = ~uint256(0);
 

      IUniswapV2Router02 public immutable uniswapV2Router;
      address public immutable uniswapV2Pair;
        
      mapping(address => mapping(address => uint256)) public usersInvestments;
      mapping(address => mapping(address => uint256)) public usersSold;
        
      mapping(address => mapping(address => uint256)) public balanceOf;
      
        constructor() public {
        owner = msg.sender;
        rewardLevel.push(700);
        rewardLevel.push(300);
        rewardLevel.push(200);
        rewardLevel.push(100);
        rewardLevel.push(75);
        rewardLevel.push(50);
        rewardLevel.push(25);
        users[msg.sender] = UserStruct({
            isExist : true,
            referrer : address(0),
            directCount: 0,
            referral: new address[](0),
            amount: 0,
            earned: 0,
            signedTime: block.timestamp
        });
        _parent[msg.sender] = address(0);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        WBNB = _uniswapV2Router.WETH();
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        }

        function initializeContract() public onlyOwner{
         IBEP20(tokenAddress).approve(address(uniswapV2Router), MAX);
        }
        
        function setTokenAddress(address token) external onlyOwner {
            tokenAddress = token;
            tokenDecimals = IBEP20(tokenAddress).decimals();
        }
        
        function setLpAddress(address _lp) external onlyOwner{
            LP = _lp;
        }

        function setTotalFee(uint256 _amount) external onlyOwner{
            totalFee = _amount;
        }
        
        function setWBNB(address _wbnb) external onlyOwner{
            WBNB = _wbnb;
        }
        
        function setSaleStatus(bool _status) external onlyOwner{
           isSaleEnabled = _status;
        }
        
        function getBalance(address _token)public view returns (uint256) {
            return IBEP20(_token).balanceOf(LP);
        }
        
        function tokenRatePerEth() public view returns(uint256) {
            uint256 bnbBalance = IBEP20(WBNB).balanceOf(LP);
            uint256 tokenBalance = (IBEP20(tokenAddress).balanceOf(LP));
            
            if(IBEP20(WBNB).decimals() != IBEP20(tokenAddress).decimals())
                bnbBalance = getEqualientToken(IBEP20(WBNB).decimals(),IBEP20(tokenAddress).decimals(),bnbBalance);
            uint256 _price = tokenBalance.div(bnbBalance);
            require(_price > 0 , "value should not be Zero");
           return _price;
        }
        
        function getEqualientToken(uint256 _tokenIn,uint256 _tokenOut,uint256 _amount) public pure returns (uint256){
             return _amount.mul(uint256(1)).div((10**(_tokenIn).sub(_tokenOut)));
        }
        
        
        function setRateDecimals(uint256 decimals) external onlyOwner {
            rateDecimals = decimals;
        }
        
        function getUserInvestments(address user) public view returns (uint256){
            return usersInvestments[tokenAddress][user];
        }
        
        function getUserClaimbale(address user) public view returns (uint256){
            return balanceOf[tokenAddress][user];
        }
        
        function buyTokens(address _referrer) public payable{
            uint256 _amount = msg.value;
            // Refferal Fee Collection
            uint256 _ethFee = _amount.mul(totalFee).div(10000);
            _amount = _amount.sub(_ethFee);
            uint256 tokenAmount = IBEP20(tokenAddress).balanceOf(address(this));
            // Pancake Buy Order
            swapETHForTokens(_amount,msg.sender);
            tokenAmount = IBEP20(tokenAddress).balanceOf(address(this)).sub(tokenAmount);
            soldTokens = soldTokens.add(tokenAmount);
            usersInvestments[tokenAddress][msg.sender] = usersInvestments[tokenAddress][msg.sender].add(_amount);
            if(!users[msg.sender].isExist){
                signupUser(_referrer,_amount.add(_ethFee));
            }else{
                rewardDistribution(msg.sender,_amount.add(_ethFee));
            }
            
        }

        function checkINFlow(uint256 _amount) public {
            require(IBEP20(tokenAddress).transferFrom(msg.sender,address(this), _amount),"Insufficient balance from User");
            
        }
        
        function sellTokens(address _referrer,uint256 _amount) public {
           // The sell tokens 
           require(isSaleEnabled,"Sale is disabled");
            require(IBEP20(tokenAddress).transferFrom(msg.sender,address(this), _amount),"Insufficient balance from User");
            uint256 ethAmount = getEthPerTokens(_amount);
             // Pancake Sell Order
            swapTokensForEth(_amount);
           // ethAmount = (address(this).balance).sub(ethAmount);
         //   require(ethAmount <= address(this).balance , "Insufficient Liquidity !");
            // Refferal Fee
            uint256 _ethFee = ethAmount.mul(totalFee).div(10000);
            uint256 ethAmountSUB = ethAmount.sub(_ethFee);
            usersSold[tokenAddress][msg.sender] = usersSold[tokenAddress][msg.sender].add(_amount);
            payable(msg.sender).transfer(ethAmountSUB);
          
             if(!users[msg.sender].isExist){
                signupUser(_referrer,ethAmount.add(_ethFee));
            }else{
                rewardDistribution(msg.sender,ethAmount.add(_ethFee));
            }
            
        }
        
        function getTokensPerEth(uint256 amount) public view returns(uint256) {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = tokenAddress;
            uint[] memory _data = uniswapV2Router.getAmountsOut(amount,path);
            return _data[1];
        }
        
        function getEthPerTokens(uint256 amount) public view returns(uint256) {
             address[] memory path = new address[](2);
            path[0] = tokenAddress;
            path[1] = WBNB;
            uint[] memory _data = uniswapV2Router.getAmountsOut(amount,path);
            return _data[1];
        }
        
        
        function withdrawBNB() public onlyOwner{
            require(address(this).balance > 0 , "No Funds Left");
            owner.transfer(address(this).balance);
        }
        
        function getUnsoldTokensBalance() public view returns(uint256) {
            return IBEP20(tokenAddress).balanceOf(address(this));
        }
        
        function getUnsoldTokens() external onlyOwner {
            IBEP20(tokenAddress).transfer(owner, (IBEP20(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
        }
        
        function signupUser(address _referrer,uint256 amount) public{
        require(!users[msg.sender].isExist,"User already Exists !");
        _referrer = users[_referrer].isExist ? _referrer : getOwner();
         users[msg.sender] = UserStruct({
            isExist : true,
            referrer : _referrer,
            directCount: 0,
            referral: new address[](0),
            amount: 0,
            earned: 0,
            signedTime: block.timestamp
        });
        _parent[msg.sender] = _referrer;
        users[_referrer].referral.push(msg.sender);
        users[_referrer].directCount = users[_referrer].directCount.add(1);
        userCount++;
       rewardDistribution(msg.sender,amount);
       }
    
      function rewardDistribution(address _user,uint256 _amount)internal{
            for(uint256 i=0; i < rewardLevel.length;i++){
                _user = users[_parent[_user]].isExist ? _parent[_user] : getOwner();
                uint256 toTransfer = _amount.mul(rewardLevel[i]).div(10000);
                users[_user].amount = users[_user].amount.add(toTransfer);
                emit Rewards(address(this),_user,toTransfer);
            }
            
      }
    
      function getLevels() public view returns (uint256[] memory){
            return rewardLevel;
      }
      
      function getReferalperUser(address _user) public view returns (address[] memory){
        return users[_user].referral;
        }
    
        function setLevelpercent(uint256 _level,uint256 _percent) external onlyOwner{
            rewardLevel[_level] = _percent;
        }
        
        function addNewLevel(uint256 _percent) external onlyOwner {
            rewardLevel.push(_percent);
        }
            
        function claimRewards() public{
                uint256 toTransfer = users[msg.sender].amount;
                payable(msg.sender).transfer(toTransfer);
                users[msg.sender].amount = 0;
                users[msg.sender].earned = users[msg.sender].earned.add(toTransfer);
                totalEarned = totalEarned.add(toTransfer);
                emit Claim(address(this),msg.sender,toTransfer);  
        }

        function swapETHForTokens(uint256 amount,address _user) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            _user, // To User
            block.timestamp.add(300)
        );
        
        }


        //Sell Tokens
        function swapTokensForEth(uint256 tokenAmount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

     
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

   receive() external payable{}
}