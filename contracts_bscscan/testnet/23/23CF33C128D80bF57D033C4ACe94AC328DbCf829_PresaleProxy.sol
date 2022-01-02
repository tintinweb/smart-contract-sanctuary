/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;
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

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


interface IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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

interface IPresaleProxy{
   function getDeploymentFee() external returns (uint256);
   function getTokenFee() external returns (uint256);
   function getfundReciever() external returns (address);
}

contract BSCPresale is Owned  {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    address public tokenAddress;
    uint256 public tokenDecimals = 18;

    string public tokenName;
    string public tokenSymbol;
    
    uint256 public tokenRatePerEth = 60000000000;
    uint256 public tokenRatePerEthPancake = 100;
    uint256 public rateDecimals = 0;
    
    uint256 public minEthLimit = 1e17; // 0.1 BNB
    uint256 public maxEthLimit = 10e18; // 10 BNB

    address public PROXY;
    
   
    string[] public social;
    string public description;
    string public logo;
    
    uint256 public soldTokens=0;
    
    uint256 public intervalDays;
    
    uint256 public startTime;
    
    uint256 public endTime = 2 days;
    
    bool public isClaimable = false;
    
    bool public isWhitelisted = false;

   bool public isSuccess = false;

    uint256 public hardCap = 0;
    
    uint256 public softCap = 0;
    
    uint256 public earnedCap =0;
    
    uint256 public totalSold = 0;

    uint256 public vestingInterval = 0;
    uint256 public vestingPercent = 0;

    uint256 public depolymentFee;
    uint256 public fee;
    
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool public isautoAdd;
    bool public isVested;
    bool public isWithoutToken;
    
    uint256 public unlockOn;
    
    uint256 public liquidityPercent;

    uint256 public participants;
    
    address payable public ownerAddress;
    
    mapping(address => uint256) public usersInvestments;
    
    struct User{
        uint256 actualBalance;
        uint256 balanceOf;
        uint256 lastClaimed;
    }

    mapping (address => User) public userInfo;
    
    constructor(address[] memory _addresses,uint256[] memory _values,bool[] memory _isSet,string[] memory _details) public {

        // _token 0
        //_router 1

        //_min 0 
        //_max 1
        //_rate 2
        // _soft  3
        // _hard 4
        //_pancakeRate  5
        //_unlockon  6
        // _percent 7
        // _start 8
        //_end 9
        //_vestPercent 10
        //_vestInterval 11

        // isAuto 0
        //_isvested 1

        // description 0 
        // website,twitter,telegram 1,2,3
        //logo 4
        //name 5
        //symbol 6
        PROXY = msg.sender;
        if(!isWithoutToken){
        tokenAddress = _addresses[0];
        tokenDecimals = IBEP20(tokenAddress).decimals();
        }else{
            tokenAddress = address(this);
            tokenName = _details[5];
            tokenSymbol = _details[6];
        }
        minEthLimit = _values[0];
        maxEthLimit = _values[1];
        tokenRatePerEth = _values[2];
        hardCap = _values[4];
        softCap = _values[3];
        owner = msg.sender;
        vestingPercent = _values[10];
        vestingInterval = _values[11];
        isVested = _isSet[1];
        // Pancake testnet Router : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
          IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_addresses[1]);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        tokenRatePerEthPancake = _values[5];
        unlockOn = _values[6].mul(1 days);
        
        if(_values[8] == 0){
        startTime = block.timestamp;
        intervalDays = _values[9].mul(1 days);
        endTime = block.timestamp.add(intervalDays);
        isPresaleOpen = true;
        }else{
        startTime = block.timestamp.add(_values[8].mul(1 days));
        endTime = startTime.add(_values[9].add(1 days));
        }
        isautoAdd = _isSet[0];
        liquidityPercent = _values[7];
        depolymentFee = IPresaleProxy(msg.sender).getDeploymentFee();
        fee = IPresaleProxy(msg.sender).getTokenFee();
        ownerAddress = payable(IPresaleProxy(msg.sender).getfundReciever());
        description = _details[0];
        social.push(_details[1]);
        social.push(_details[2]);
        social.push(_details[3]);
        logo = _details[4];
    }
    
    function startPresale(uint256 numberOfdays) external onlyOwner{
        require(!isPresaleOpen, "Presale is open");
        intervalDays = numberOfdays.mul(1 days);
        endTime = block.timestamp.add(intervalDays);
        isPresaleOpen = true;
        isClaimable = false;
    }
    
    function closePresale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet or ended.");
        totalSold = totalSold.add(soldTokens);
        soldTokens = 0;
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        tokenAddress = token;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    function getUserInvestments(address user) public view returns (uint256){
        return usersInvestments[user];
    }

    function getSaleInfo() public view returns (string[] memory _data,uint256 rate,uint256 cap,uint256 start,uint256 _end,uint256 _earnedCap,uint256 _participants,bool isVest,bool _isWhitelisted,string[] memory _socials) {
       if(!isWithoutToken){
        _data[0] = (IBEP20(tokenAddress).name());
        _data[1] = (IBEP20(tokenAddress).symbol());
       }else{
        _data[0] = tokenName;
        _data[1] = tokenSymbol;
       }
        _data[2] = logo;
        _data[3] = description;
        rate = tokenRatePerEth;
        cap = hardCap;
        start = startTime;
        _end = endTime;
        _earnedCap = earnedCap;
        _participants = participants;
        isVest = isVested;
        _socials = social;

        return (_data,rate,cap,start,_end,_earnedCap,_participants,isVest,_isWhitelisted,_socials);
    }
    
    function getUserClaimbale(address user) public view returns (uint256){
        return userInfo[user].balanceOf;
    }
    
    receive() external payable{
        uint256 amount = msg.value;
        if(block.timestamp > endTime || earnedCap.add(amount) > hardCap)
        isPresaleOpen = false;
            
        if(block.timestamp >= startTime && block.timestamp <= endTime)
        isPresaleOpen = true;
        
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(amount) <= maxEthLimit
                && usersInvestments[msg.sender].add(amount) >= minEthLimit,
                "Installment Invalid."
            );
        if(usersInvestments[msg.sender] == 0)
        participants++;
         require(earnedCap.add(amount) <= hardCap,"Hard Cap Exceeds");
       
        if(isWithoutToken){
        require((hardCap).sub(soldTokens) > 0 ,"No Presale Funds left");
        uint256 tokenAmount = getTokensPerEth(amount);
        require( (hardCap).sub(soldTokens) >= tokenAmount ,"No Presale Funds left");
        userInfo[msg.sender].balanceOf = userInfo[msg.sender].balanceOf.add(tokenAmount);
        userInfo[msg.sender].actualBalance = userInfo[msg.sender].balanceOf;
        soldTokens = soldTokens.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(amount);
        earnedCap = earnedCap.add(amount);
        }else{
        require( (IBEP20(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
        uint256 tokenAmount = getTokensPerEth(amount);
        require( (IBEP20(tokenAddress).balanceOf(address(this))).sub(soldTokens) >= tokenAmount ,"No Presale Funds left");
        userInfo[msg.sender].balanceOf = userInfo[msg.sender].balanceOf.add(tokenAmount);
        userInfo[msg.sender].actualBalance = userInfo[msg.sender].balanceOf;
        soldTokens = soldTokens.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(amount);
        earnedCap = earnedCap.add(amount);
        }
       
    }
    
    
  function claimTokens() public{
        address user = msg.sender;
        require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
        require(isClaimable, "You cannot claim tokens until the finalizeSale.");
        require(userInfo[user].balanceOf > 0 , "No Tokens left !");
        if(isSuccess){
        VestedClaim(user);
        }else{
        payable(msg.sender).transfer(usersInvestments[msg.sender]);
        }
       
    }

    function VestedClaim(address user) internal {
        if(isVested){
        require(block.timestamp > userInfo[user].lastClaimed.add(vestingInterval),"Vesting Interval is not reached !");
        uint256 toTransfer =  userInfo[user].actualBalance.mul(vestingPercent).div(10000);
        if(toTransfer > userInfo[user].balanceOf)
            toTransfer = userInfo[user].balanceOf;
        require(IBEP20(tokenAddress).transfer(user, toTransfer), "Insufficient balance of presale contract!");
        userInfo[user].balanceOf = userInfo[user].balanceOf.sub(toTransfer);
        userInfo[user].lastClaimed = block.timestamp;
       }else{
        require(IBEP20(tokenAddress).transfer(user, userInfo[user].balanceOf), "Insufficient balance of presale contract!");
        userInfo[user].balanceOf = 0;
        }
    }

    function getVestedclaim(address user) public view returns (uint256) {
        uint256 toTransfer = userInfo[user].actualBalance.mul(vestingPercent).div(10000);
        uint256 vestedClaim = userInfo[user].balanceOf < toTransfer ? toTransfer : userInfo[user].balanceOf;
        return (userInfo[user].balanceOf == 0) ? 0 : vestedClaim ;
    }

    function isEligibletoVestedClaim(address _user) public view returns (bool) {
        return (block.timestamp > userInfo[_user].lastClaimed.add(vestingInterval));
    }
    
    function finalizeSale() public onlyOwner{
        require(!isPresaleOpen, "You cannot finalizeSale until the presale is closed.");
        if(!isWithoutToken){
            if(earnedCap >= softCap)
                isSuccess = true;
        
            if(isSuccess && isautoAdd && address(this).balance > 0){
                _addLiquidityToken();
                ownerAddress.transfer(earnedCap.mul(fee).div(100));
                require(IBEP20(tokenAddress).transfer(address(ownerAddress),totalSold.mul(fee).div(100)), "Insufficient balance of presale contract!");
            }
        }
        isClaimable = !(isClaimable);
    }
    
    function _addLiquidityToken() internal{
     uint256 amountInEth = earnedCap.mul(liquidityPercent).div(100);
     uint256 tokenAmount = amountInEth.mul(tokenRatePerEthPancake);
     tokenAmount = getEqualTokensDecimals(tokenAmount);
     addLiquidity(tokenAmount,amountInEth);
     unlockOn = block.timestamp.add(unlockOn);
    }
    
    function checkTokentoAddLiquidty() public view returns(uint256) {
    uint256 contractBalance = IBEP20(tokenAddress).balanceOf(address(this)).sub(soldTokens.add(totalSold));
    uint256 amountInEth = earnedCap.mul(liquidityPercent).div(100);
    uint256 tokenAmount = amountInEth.mul(tokenRatePerEthPancake);
     tokenAmount =  tokenAmount.mul(uint256(1)).div(10**(uint256(18).sub(tokenDecimals).add(rateDecimals)));
         contractBalance = contractBalance.div(10 ** tokenDecimals);
            return (tokenAmount).sub(contractBalance);
    }
    
    function getTokensPerEth(uint256 amount) public view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function getEqualTokensDecimals(uint256 amount) internal view returns (uint256){
        return amount.mul(uint256(1)).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
         IBEP20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);
        // add the liquidity
          uniswapV2Router.addLiquidityETH{value: ethAmount}(
           tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    
    function withdrawBNB() public onlyOwner{
        require(address(this).balance > 0 , "No Funds Left");
         owner.transfer(address(this).balance);
    }
    
    function getUnsoldTokensBalance() public view returns(uint256) {
        return isWithoutToken? hardCap.sub(soldTokens) : IBEP20(tokenAddress).balanceOf(address(this));
    }

    
    function getLPtokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        require (block.timestamp > unlockOn,"Unlock Period is still on");
        IBEP20(uniswapV2Pair).transfer(owner, (IBEP20(uniswapV2Pair).balanceOf(address(this))));
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        IBEP20(tokenAddress).transfer(owner, (IBEP20(tokenAddress).balanceOf(address(this))));
    }
}




contract PresaleProxy is Owned {
    using SafeMath for uint256;

    struct Sale{
        address _sale;
        uint256 _start;
        uint256 _end;
    }

    uint256 public depolymentFee = 0.25 ether;
    uint256 public fee = 2;

    address public fundReciever = 0xaF91832294A334BC7Cc4C7787d0e8b66b7D0BAC5;
   

    mapping(address => address) public _preSale;
    Sale[] public _sales;

    constructor() public{

    }

    function getSale(address _token) public view returns (address) {
        return _preSale[_token];
    }

    function setDeploymentFee(uint256 _fee) external onlyOwner {
        depolymentFee = _fee;
    }

    function setTokenFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function getDeploymentFee() public view returns(uint256){
        return depolymentFee;
    }

    function getfundReciever() public view returns (address){
        return fundReciever;
    }

    function setfundReciever(address _reciever) external onlyOwner {
        fundReciever = _reciever;
    }

    function getTokenFee() public view returns(uint256){
        return fee;
    }

    function getTotalSales() public view returns (Sale[] memory){
        return _sales;
    }

    function getSales() public view returns (Sale[] memory _active,Sale[] memory _inactive) {
        uint256 j =0;
        uint256 k =0;
        for(uint8 i=0; i< _sales.length; i++){
             if(block.timestamp >= _sales[i]._start && block.timestamp <= _sales[i]._end){
                _active[j]=(_sales[i]); j++;
             }else{
                _inactive[k]=(_sales[i]); k++;
             }
        }
        return (_active,_inactive);
    }

    function getSalesLimit(uint256 _start,uint256 _end) public view returns (Sale[] memory _active) {
        uint256 j =0;
         for(uint256 i=_start-1; i< _end; i++){
              _active[j]=(_sales[i]); j++;
         }
         return _active;
    }

    function createPresale(address[] calldata _addresses,uint256[] calldata _values,bool[] memory _isSet,string[] memory _details) public payable onlyOwner{
        // _token 0
        //_router 1

        //_min 0 
        //_max 1
        //_rate 2
        // _soft  3
        // _hard 4
        //_pancakeRate  5
        //_unlockon  6
        // _percent 7
        // _start 8
        //_end 9
        //_vestPercent 10
        //_vestInterval 11

        // isAuto 0
        //_isvested 1
        // isWithoutToken 2
       
        // description 0 
        // website,twitter,telegram 1,2,3
        //logo 4
        //name 5
        //symbol 6
         // require(depolymentFee == msg.value,"Insufficient fee");
         // payable(fundReciever).transfer(msg.value);
           _preSale[_addresses[0]] = address(new BSCPresale(_addresses,_values,_isSet,_details));
            _sales.push(
                Sale({
                    _sale: _preSale[_addresses[0]],
                    _start: _values[8],
                    _end: _values[9]
                })
            );
        
    }


}