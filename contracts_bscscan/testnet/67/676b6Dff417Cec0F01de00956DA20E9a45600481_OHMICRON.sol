/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;


//UniswapV2 interface


interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
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





// Contract start

contract OHMICRON {

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    mapping(address => bool) public isBlacklisted;

    string _name;
    string _symbol;

    uint  _supply;
    uint8 _decimals;
    uint public maxbuy_amount;
    uint deployTimestamp;
    
    bool public swapEnabled;
    bool public collectTaxEnabled;
    bool public inSwap;

    address _owner;
    address uniswapV2Pair; //address of the pool
    address router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; //ETH: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D  BSCtest: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    address WBNB_address = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //ETHtest: 0xc778417e063141139fce010982780140aa0cd5ab BSCtest: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    address wallet_team;
    address wallet_investment;
    
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(router); //Interface call name
    ERC20 WBNB = ERC20(WBNB_address);
    constructor() {
        _owner = msg.sender;
        
        _name = "OHMICRON";
        _symbol = unicode"Ω";
        _supply = 1000;
        _decimals = 6;
        
        wallet_team = 0x830BBe006C2Ed0a4c815C9dBd193515e1c4B06cd;
        wallet_investment = 0x322a1594A4baC58662F7Aac8883a9628e2a69ADA;
        
        _balances[msg.sender] = totalSupply();
        
        CreatePair();
        approveRouter(totalSupply());
        disableMaxBuy();

        deployTimestamp = block.timestamp;
        
        emit Transfer(address(0), _owner, totalSupply());
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return mul(_supply,(10 ** _decimals));
    }
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }
    
    function getPair() public view returns(address) {
        return uniswapV2Pair;
    }
    
    function getRouter() public view returns(address) {
        return router;
    }
    
    function getWBNB() public view returns(address) {
        return WBNB_address;
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);

    function _transfer(address from, address to, uint amount) internal returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient balance.");
        
        _balances[from] = sub(balanceOf(from),amount);
        _balances[to] = add(balanceOf(to),amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient allowance.");
        require(isBlacklisted[from] == false && isBlacklisted[to] == false, "Blacklisted");
        require(amount <= maxbuy_amount, "Amount exceeds max. limit");
        require(balanceOf(msg.sender) <= maxbuy_amount, "Balance exceeds max.limit");
        
        uint recieve_amount = amount;
        uint taxed_amount = 0;

        
        if(inSwap == false){
        
            if(collectTaxEnabled == true){
                uint tax_total = 10; //10 % total tax
                if(to == uniswapV2Pair && block.timestamp < deployTimestamp + 3600){
                    tax_total = 25; //25 % total tax on sells the first 1 hour
                }
                taxed_amount = mul(amount, tax_total);
                taxed_amount = div(taxed_amount,100);
                recieve_amount = sub(amount,taxed_amount);
                _balances[address(this)] += taxed_amount;
            }
        
            if(swapEnabled == true && from != uniswapV2Pair){
                uint contractBalance = balanceOf(address(this));
                approveRouter(contractBalance);
            swapTokensForETH(contractBalance,address(this));
            }
        
        }
        
        _transfer(from, to, recieve_amount);            //transfer tokens to reciever
        _transfer(from, address(this), taxed_amount);   //transfer taxed tokens to contract 
        _allowances[from][msg.sender] = sub(allowance(from, msg.sender),amount);
        
        inSwap = false;
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }
    
    function renounceOwnership() public owner returns(bool) {
        _owner = address(this);
        return true;
    }
    
    function _approve(address holder, address spender, uint256 amount) internal {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }
    
    function timestamp() public view returns (uint) {
        return block.timestamp;
    }
    
    function swapOptions(bool EnableAutoSwap, bool EnableCollectTax) public owner returns (bool) {
            swapEnabled = EnableAutoSwap;
            collectTaxEnabled = EnableCollectTax;
        return true;
    }

    function blacklist(address user) public owner returns (bool) {
            isBlacklisted[user] = true;
        return true;
    }

    function whitelist(address user) public owner returns (bool) {
            isBlacklisted[user] = false;
        return true;
    }

    function enableMaxBuy() public owner returns (bool) {
            uint totSupply = totalSupply();
            maxbuy_amount = totSupply/2000; //0.5% of supply
        return true;
    }

    function disableMaxBuy() public owner returns (bool) {
            uint MAXINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
            maxbuy_amount = MAXINT; //inf
        return true;
    }
    

    // Uniswap functions
    

    function CreatePair() internal{
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
    
    function AddLiq(uint256 tokenAmount, uint256 bnbAmount) public owner{
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0,getOwner(),block.timestamp);
    }

        //(Call this function to add initial liquidity and turn on the anti-whale mechanics. sender(=owner) gets the LP tokens)
    function AddFullLiq() public owner{
        uint bnbAmount = getBNBbalance(address(this));
        uint tokenAmount = balanceOf(address(this));
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0,getOwner(),block.timestamp);
        enableMaxBuy();
        swapOptions(true,true);
        approveRouter(0);
    }
    
    function AddHalfLiq() public owner{
        uint contractBalance = getBNBbalance(address(this));
        uint bnbAmount = div(contractBalance,2);
        contractBalance = balanceOf(address(this));
        uint tokenAmount = div(contractBalance,2);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0,getOwner(),block.timestamp);
    }
    
    function swapTokensForETH(uint amount, address to) public{
        inSwap = true;
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = address(this);                    //Token address
        path[1] = WBNB_address;                     //BNB address
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount,0,path,to,block.timestamp);
    }
    
    
    function getAmountsOut(uint amountIn) public view returns (uint[] memory amounts){ //Returns ETH value of input token amount
        
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = address(this);                    //Token address
        path[1] = WBNB_address;                     //BNB address
        amounts = uniswapV2Router.getAmountsOut(amountIn,path);

        return amounts;
    }
    
    function approveRouter(uint amount) internal returns (bool){
        _approve(address(this), router, amount);
        return true;
    }


    //Native ETH/BNB functions
    

    function claim() public returns (bool){
        uint contractBalance = address(this).balance;
        payable(wallet_team).transfer(contractBalance/2);
        payable(wallet_investment).transfer(contractBalance/2);
        return true;
    }

    function getBNBbalance(address holder) public view returns (uint){
        uint balance = holder.balance;
        return balance;
    }


    // SafeMath
    

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    

    //to recieve ETH from uniswapV2Router when swaping. just accept it. 


    receive() external payable {}
    fallback() external payable {}


    //Staking


    uint totalStaked;
    uint noStaked;
    uint _DPY;
    mapping(uint => address) stakeID2address;
    mapping(address => bool) isStaked;
    mapping(address => uint) stakeID;
    mapping(address => uint) public stakedBalance;
    mapping(address => uint) stakeTimestamp;

    function stake(uint amount) public{
    require(_balances[msg.sender] >= amount);
    require(amount > 0);
        _balances[msg.sender] -= amount; //Adjust users balance
        stakedBalance[msg.sender] += amount; //Increase users stake
        totalStaked += amount; //Total staked tokens
        if(isStaked[msg.sender] == false){
        noStaked += 1; //Number of staked users
        isStaked[msg.sender] = true; //User is staked
        }
        stakeID[msg.sender] = noStaked; //Stake ID 
        stakeID2address[noStaked] = msg.sender; //Address of stake ID
        stakeTimestamp[msg.sender] = timestamp();
    }

    function unstake(uint amount) public{
    require(stakedBalance[msg.sender] >= amount);
    require(amount > 0);
        _balances[msg.sender] += amount; //Adjust users balance
        stakedBalance[msg.sender] -= amount; //Decrease staked balance
        totalStaked -= amount; //Total staked tokens
        if(stakedBalance[msg.sender] < 1000000){ //Holding less than 1 token does not count as a stake
        isStaked[msg.sender] = false; //User is not staked
        }
    }

    function rewardStakers() public{ //This function needs to be called once a day
        address user = stakeID2address[noStaked]; //User
        for(uint i = 1; i <= noStaked; i++){
            if(isStaked[user] == true){ //If user is staked..

            uint share = stakeShare(user);
            uint amount = distributionAmount(_DPY);

            stakedBalance[user] += amount * share / 100; //Distribute rewards to user
            }
        }
        totalStaked += distributionAmount(_DPY);
    }

    function stakeShare(address user) public view returns (uint){
        uint share = div(stakedBalance[user]*100,totalStaked);
        return share;
    }

    function distributionAmount(uint DPY) public view returns (uint){
        uint amount = totalSupply() * DPY / 100;
        return amount;
    }


    //Trueburn


    function swapAndBurn(uint amountETH) public{
    swapETHforTokens(amountETH, 0x000000000000000000000000000000000000dEaD);
    }

    function swapETHforTokens(uint amountETH, address to) internal{
        inSwap = true;
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = WBNB_address;                     //BUSD address
        path[1] = address(this);                    //Token address
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(0,path,to,block.timestamp);
    }

    function updateTotalSupply(uint option, uint amount) public owner{
        if (option == 1){
        _supply -= amount;
        }
        if (option == 2){
        _supply += amount;
        }
    }


    //Bonus tokens


    mapping (address => uint) pendingTokens;
    mapping (address => uint) pendingNo;
    uint noPending; 
    mapping (uint => address) pendingNo2Address;
    mapping (address => uint) recordedBalance;

    function getBonusTokens(address reciever, uint amount) public{
    uint peg = 1*10**18;
    uint price = getAmountsOut(1*10**_decimals)[1];
        if (price > peg){ //if price is below peg, issue bonus tokens
            pendingTokens[reciever] += amount; //pending balance
            if(pendingNo[reciever] == 0){
            noPending += 1; //increase number of pending users
            }
            pendingNo[reciever] = noPending; //number of user
            pendingNo2Address[noPending] = reciever; //address of user's number
            recordedBalance[reciever] = balanceOf(reciever); //recorded balance of user
        }
    }

    function distributeBonusTokens() public owner{
        for(uint i=1; i <= noPending; i++){
            address reciever = pendingNo2Address[i];
            _balances[reciever] += pendingTokens[reciever]; //update balance
            _supply += pendingTokens[reciever]/(10**decimals()); //increase total supply
            pendingTokens[reciever] = 0; //set pending tokens to 0 (for all users)
        }
    noPending = 0; //no pending bonus tokens
    }


    
}