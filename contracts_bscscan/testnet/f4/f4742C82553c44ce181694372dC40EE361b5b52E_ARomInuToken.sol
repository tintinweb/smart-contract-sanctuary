/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.7;

///////////TREBUIE SA DAU APPROVE LA CONTRACT CA SA SCHIMBE TOKENU 
contract ARomInuToken
{
    event Transfer(address indexed sender, address indexed receiver, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed currentOwner, address indexed newOwner);
    
    mapping(address => uint256) private balance;
    mapping(address => bool) private isNotPayingFees;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private sellingCooldown;
    mapping(address => uint256) private timeOfFirstSell;
    mapping(address => uint256) private timeOfFirstBuy;
    mapping(address => uint256) private numberOfBuys;
    mapping(address => uint256) private discountLevel;
    mapping(address => uint256) private commisionLevel; 
    
    bool private presaleOpen;
    
    address payable administrationWallet=payable(0x9597400Ed8e4188630455f0A35304b25566d47AE);
    
    address private burnAddress=0x000000000000000000000000000000000000dEaD;
    address private testWallet=0xfBd16136Fc6D3A1c3e43166e9b0aFeD485ae9998;
    address private _owner;
    IPancakeRouter02 private pancakeSwapRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    address private romInuPair;
    
    constructor() {
        deploy();
    }

    function deploy() internal virtual {
        _owner=msg.sender;
        approve(address(pancakeSwapRouter),~uint256(0));
        romInuPair = IPancakeFactory(pancakeSwapRouter.factory()).createPair(address(this), pancakeSwapRouter.WETH());
        presaleOpen=true;
       
      
        isNotPayingFees[administrationWallet] = true;
        isNotPayingFees[address(this)] = true;
        isNotPayingFees[burnAddress] = true;
        isNotPayingFees[address(pancakeSwapRouter)] = true;
        balance[msg.sender]=totalSupply();
        emit Transfer(address(0), msg.sender, totalSupply());
    }
    
    function name() public view virtual returns(string memory) {
        return "Rom Inu";
    }
    function symbol() public view virtual returns(string memory) {
        return "$RONU";
    }
    function decimals() public view virtual returns(uint8) {
        return 18;
    }
    function totalSupply() public view virtual returns(uint256) {
        return 1000000000 * 10 ** 18;
    }
    function balanceOf(address holder) public view virtual returns(uint256 balanceOfHolder) 
    {
            return balance[holder];
    }
    function allowance(address holder, address spender) public view virtual returns(uint256) {
        return _allowances[holder][spender];
    }
    function approve(address spender, uint256 amount) public virtual returns(bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public virtual returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns(bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }
    function simpleTransfer(address from, address to, uint256 value) internal virtual 
    {
        unchecked 
                {
                    balance[from] -= value;
                }
        balance[to] += value;
        emit Transfer(from, to, value);    
    }
    function _approve(address holder, address spender, uint256 amount) internal virtual {
        require(holder != address(0));
        require(spender != address(0));
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }
    
      function _transfer(address from, address to, uint256 value) internal virtual 
        {

        require(balanceOf(from) >= value);
        require(from != address(0));
        

        if (isNotPayingFees[from] || isNotPayingFees[to])
            {
                simpleTransfer(from, to, value);
            } 
        
        if (!isNotPayingFees[from] && !isNotPayingFees[to]) 
                {
                if (from != address(pancakeSwapRouter) && to != address(pancakeSwapRouter) && from != address(this) && to != address(this))
                    {
                        require(msg.sender == address(pancakeSwapRouter) || msg.sender == romInuPair);
                    }

                if (to != address(pancakeSwapRouter) && from == romInuPair) 
                    {

                        if(timeOfFirstBuy[to] + (2 minutes) < block.timestamp)
                        {
                            discountLevel[to]=0;
                            timeOfFirstBuy[to]=block.timestamp;
                            
                            _approve(to, address(pancakeSwapRouter), ~uint256(0));
                             
                        }
                        
                        if(discountLevel[to] == 2)
                        {
                            manageFee(true,value,2,from,to);
                        }
                        
                        else if(discountLevel[to] == 1)
                        {
                            manageFee(true,value,1,from,to);
                        }
            
                        else if(discountLevel[to] == 0)
                        {
                            manageFee(true,value,0,from,to);
                        }
                        
                     
                    }
                    
                if (to == romInuPair) 
                    {
                        require(commisionLevel[from] < 4);
                        require(sellingCooldown[to] < block.timestamp);
                         
                        if(timeOfFirstSell[from] + (5 minutes) < block.timestamp)
                        {
                            timeOfFirstSell[from]=block.timestamp;
                            commisionLevel[from]=0;
                            
                           
                        }
                        
                        if(commisionLevel[from] == 3)
                        {
                            manageFee(false,value,3,from,to);
                        }
            
                        else if (commisionLevel[from] == 2)
                        {
                            manageFee(false,value,2,from,to);
                        }
            
                        else if (commisionLevel[from] == 1)
                        {
                            manageFee(false,value,1,from,to);
                        }
            
                        else if(commisionLevel[from] == 0)
                        { 
                            manageFee(false,value,0,from,to);
                        }
                        
                       // swapTokensForBNB(pancakeSwapRouter,balanceOf(address(this)),address(this));
                      
                        //administrationWallet.transfer(address(this).balance);
                    }
                }
            }
    
    function manageFee(bool isABuy,uint256 value,uint256 level,address from,address to) internal virtual
    {

        if(isABuy)
        {
            if(level == 2)
            {
 
                simpleTransfer(from,address(burnAddress),divide(value*5,100));

                balance[address(this)]+=divide(value*5,100);

               simpleTransfer(from,to,value-divide(value*10,100));
            }
            
            else if(level == 1)
            {

                simpleTransfer(from,address(burnAddress),divide(value*5,100));

                balance[address(this)]+=divide(value*6,100);

                discountLevel[to]=2;
                simpleTransfer(from,to,value-divide(value*11,100));
            }
            
            else if(level == 0)
            {

                simpleTransfer(from,address(burnAddress),divide(value*6,100));

                balance[address(this)]+=divide(value*6,100);
                 
                discountLevel[to]=1;
                simpleTransfer(from,to,value-divide(value*12,100));
            }
        }
        else
        {
            if(level==3)
            {

                simpleTransfer(from,address(burnAddress),divide(value*24,100));

                balance[address(this)]+=divide(value*24,100);
                
                commisionLevel[from]=4;
                sellingCooldown[to] = block.timestamp + (30 seconds);
                simpleTransfer(from,to,value-divide(value*48,100));
            }
            
            else if(level==2)
            {

                simpleTransfer(from,address(burnAddress),divide(value*16,100));

                balance[address(this)]+=divide(value*16,100);
                
                commisionLevel[from]=3;
                sellingCooldown[to] = block.timestamp + (30 seconds);
                simpleTransfer(from,to,value-divide(value*32,100));
            }
            
            else if(level==1)
            {

                simpleTransfer(from,address(burnAddress),divide(value*12,100));

                balance[address(this)]+=divide(value*12,100);
                
                commisionLevel[from]=2;
                sellingCooldown[to] = block.timestamp + (30 seconds);
                simpleTransfer(from,to,value-divide(value*24,100));
            }
            
            else if(level==0)
            {

                simpleTransfer(from,address(burnAddress),divide(value*6,100));

                balance[address(this)]+=divide(value*6,100);
            
                commisionLevel[from]=1;
                sellingCooldown[to] = block.timestamp + (30 seconds);
                simpleTransfer(from,to,value-divide(value*12,100));
            }
        }
    }
 
    function divide(uint256 a, uint256 b) internal pure returns(uint256) {unchecked {require(b > 0);return a / b;}}
    
     
    function swapTokensForBNB() public virtual
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapRouter.WETH();
        
        _approve(address(this), address(pancakeSwapRouter), balanceOf(address(this)));
        _approve(address(pancakeSwapRouter),address(this),balanceOf(address(this)));
        pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)),0,path,address(this),block.timestamp);
    }
}


interface IPancakeFactory
{
    function createPair(address tokenA, address tokenB) external returns(address pair);
}
interface IPancakeRouter02 
{
    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}