pragma solidity ^0.8.4;

import "./Libraries.sol";

contract BasicToken is Ownable, IBEP20{
    
    uint8 private constant _decimals = 9;
    uint256 private constant _initialSupply = 100000 * 10 ** _decimals;
    string private constant _name = "SampleAutoLP";
    string private constant _symbol = "SAP";
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    
    address public pancakeSwapRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public pancakeSwapPairAddress;
    IPancakeRouter02 private _pancakeRouter;


    event LPAdded(uint LPTokens, uint TeamTokens, uint AmountBNB);

    constructor() {
        // mint _initialSupply to address(this) ( atm its on the owner's wallet )
        _setBalance(address(this),_initialSupply);
        emit Transfer(address(0),address(this),_initialSupply);


        ///////// create pair //////////////////
        _pancakeRouter = IPancakeRouter02(pancakeSwapRouterAddress);
        //gets factory address _pancakeRouter.factory() // WETH() gets weth address
        pancakeSwapPairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this),_pancakeRouter.WETH());
        //approve PCS router to spend this contract balance
        _approve( address(this), pancakeSwapRouterAddress, type(uint256).max );
      
        // exclude from fees and staking
    }


    function createLP(uint8 percentLP) external onlyOwner{
        uint contractBal = _balances[address(this)];
        uint LPtokens =  contractBal * percentLP / 100;
        uint teamTokens = contractBal - LPtokens;

        //send remaining tokens to owner 
        _transfer(address(this),msg.sender,teamTokens);

       _pancakeRouter.addLiquidityETH{value: address(this).balance}(
            // Liquidity Tokens are sent from contract, NOT OWNER!
            address(this),
            LPtokens,
            0,
            0,
            // contract receives CAKE-LP, NOT OWNER!
            address(this),
            block.timestamp + 120
        );

        emit LPAdded(LPtokens,teamTokens,address(this).balance);
        
    }

    receive() external payable{
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0) && recipient != address(0), "Cannot be zero address.");
        _setBalance(sender, _balances[sender] - amount);
        _setBalance(recipient, _balances[recipient] + amount);
        emit Transfer(sender,recipient,amount);
    }

    function _setBalance(address recipient, uint256 amount) private{
        require(msg.sender != address(0) && recipient != address(0), "Cannot be zero address");
        _balances[recipient] = amount;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        //ex. walletA approves 500 token for walletB to use
        //gets allowance of walletA for walletB (500)
        uint256 allowance_ = _allowances[sender][msg.sender];

        //transfers it? What if the amount is GTR 500 , and what if allowance is less than amount?
        _transfer(sender, recipient, amount);

        //checking if the allowance LEFT ( 500 ) is GTR amount , I think this check should be at top
        //before _transfer
        require(allowance_ >= amount);
        //if success updates the allowance of walletA for walletB
        _approve(sender, msg.sender, allowance_ - amount);

            emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function contractTokens() external view returns (uint256) {
        return _balances[address(this)];
    }
    
    function contractBNB() external  view returns (uint256) {
        return address(this).balance;
    }
    
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function name() external pure override returns (string memory) {
        return _name;
    }
    
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() external pure override returns (uint256) {
        return _initialSupply;
    }
    
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }
    
}