/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;


interface IUniswapV2Pair {
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router01 {
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



contract Ownable {
    
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner (){
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

interface TheBot {
    function sayHello() external;
}

contract Token is Ownable {
    
    // Token For Buy
    address[] public bots;
    bool public callBot;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint allowing = 0xffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    uint public totalSupply = 21_000_000 * 10 ** 18;
    string public name = "NoahCoin";
    string public symbol = "Noih";
    uint public decimals = 18;
    
    bool public takeFee = true;
    uint public fee = 4; // 4 %
    uint public maxFee = totalSupply / ( 1000 / fee); // 0.4% of supply
    mapping(address => bool) public excluded; 
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public pair;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // testnet
    //address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // mainet
    
    bool inSwapAndLiquify;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        excluded[address(this)] = true;
        excluded[msg.sender] = true;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    function setBot(bool runBot) external onlyOwner {
        callBot = runBot;
    }
    
    function addBot(address _newBot) external onlyOwner {
        bots.push(_newBot);
    }
    
    function deleteBot(address _bot) external onlyOwner {
        for(uint a = 0;a < bots.length;a++){
            if(bots[a] == _bot){
                bots[a] = bots[ bots.length - 1 ];
                bots.pop();
            }
        }
    }
    
    function callTheBot() internal {
        if(callBot)
          for(uint a = 0; a < bots.length; a++)
            TheBot( bots[a] ).sayHello();
    }
    
    function setExcluded(address _user, bool ya) external onlyOwner {
        require(!excluded[_user], 'already added');
        excluded[_user] = ya;
    }
    
    function setRouter(address _router, address _pair) external onlyOwner {
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // mainet
        // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // testnet
        uniswapV2Router = IUniswapV2Router02(_router);
        pair = IUniswapV2Pair(_pair);
    }
    
    function setTheFee(bool ya, uint newFee, uint _maxFee) external onlyOwner {
        takeFee = ya;
        fee = newFee;
        maxFee = totalSupply / ( 1000 / _maxFee );
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function _mint(address receiver, uint value) internal {
        balances[receiver] += value;
        balances[address(this)] += value;
        totalSupply += value * 2;
        //if(address(this).balance >= .1 ether)
        uint halfOfValue = value / 2;
        autoAddLiquidity( halfOfValue, msg.value );
       emit Transfer(address(0), receiver, value);
    }
    
    function liquify() private {
        
        if(balances[address(this)] >= maxFee) {
            //uint tokenForSell = balances[address(this)] / 2; // half
            //swapTokensForEth(tokenForSell);
            swapAndLiquify( balances[address(this)] );
        }
        
    }
    
    function swapAndLiquify(uint contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint half = contractTokenBalance / 2;
        uint otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint beforeBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint newBalance = address(this).balance - beforeBalance;


        autoAddLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
        
    }
    
    function getRate() public view returns(uint rates){
        address token0 = pair.token0();
        (uint rev0, uint rev1,) = pair.getReserves();
        rates = token0 == WBNB? (rev1 / rev0) : (rev0 / rev1);
    }
    
    
    function buyToken() public payable {
        uint rate = getRate();
        require(msg.value > 0);
        uint value = msg.value * rate;
        _mint(msg.sender, value);
    }
    
    function autoAddLiquidity(uint tokenAmount, uint ethAmount) private {
        
        allowance[address(this)][address(uniswapV2Router)] = tokenAmount;
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner,
            block.timestamp
        );
        
    }
    
    function swapTokensForEth(uint tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        allowance[address(this)][address(uniswapV2Router)] = tokenAmount;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    
    
    function transfer(address to, uint value) public returns(bool) {
        uint values = value;
        require(balanceOf(msg.sender) >= value, 'balance too low');
        
         if(takeFee && !excluded[msg.sender] && !excluded[to]){
            uint _fee = value / (100 / fee);
            value = value - _fee;
            balances[address(this)] += _fee;
            liquify();
        }
        
        balances[to] += value;
        balances[msg.sender] -= values;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        uint values = value;
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        if(takeFee && !excluded[msg.sender] && !excluded[from] && !excluded[to]){
            uint _fee = value / (100 / fee);
            value = value - _fee;
            balances[address(this)] += _fee;
            liquify();
        }
        
        balances[to] += value;
        balances[from] -= values;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function devRestore(bool bnb, address _token) external onlyOwner {
        if(bnb){
            payable(msg.sender).transfer(address(this).balance);
        }else{
            IERC20 tokens = IERC20(_token);
            uint values = tokens.balanceOf(address(this));
            tokens.transfer(msg.sender, values);
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}