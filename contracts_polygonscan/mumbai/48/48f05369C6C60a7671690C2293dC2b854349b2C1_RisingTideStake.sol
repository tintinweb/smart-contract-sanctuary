pragma solidity 0.6.12;
// SPDX-License-Identifier: Unlicensed

import "./interfaces.sol";
//import "hardhat/console.sol";

contract RisingTideStake is IERC20, Ownable  {
    using SafeMath for uint256;

    string public constant name = "RisingTideStake";
    string public constant symbol = "RTS";
    uint8 public constant decimals = 0;
    uint256 totalSupply_ = 0;
    uint256 buyFee = 96;
    uint256 sellFee = 96;
    uint256 transferFee = 98;
    uint256 currentPrice;
    uint256 public prevContractBalance = 0;
    address payable devWallet = 0xc2eFda556F63855d80c0f9A4ad66E48e3435FD38;
    address tokenAddress = 0xc8c6D155CE2C4514Df95F38B96ac8D2536C0f433;
    address payable public adminAddr;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) private isExcludedFromTaxes;
    mapping(uint256 => uint256) public priceHistory;
    
    //serivce variables
    uint256 decimalHandler = 10**18;
    bool private emergencyModeEnabled = false;
    address payable emergencyWallet = 0xc2eFda556F63855d80c0f9A4ad66E48e3435FD38;
    
    constructor() public {}
     /////////////
    //IERC20 MRTSODS
    /////////////

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        return _transferFrom(msg.sender, receiver, numTokens);
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        return _transferFrom(owner, buyer, numTokens);
    }

    function increaseAllowanceForStake(address owner, address spender, uint256 addedValue) public override returns(bool) {
        require (owner != address(0));
        require (spender != address(0));
        require (addedValue != 0);
        return true;
    }

    function decreaseAllowanceForStake(address owner, address spender, uint256 addedValue) public override returns(bool) {
        require (owner != address(0));
        require (spender != address(0));
        require (addedValue != 0);
        return true;
    }
    
    
    /////////////
    //CUSTOM MRTSODS
    /////////////
    
    function _transferFrom(address fromAddr, address toAddr, uint256 tokens) private returns(bool) {
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        require(fromAddr != address(0), "Sender must be valorized");
        require(tokens>0, "Amount of tokens sended must be grater than 0");
        //implement better logic on taxes 
        balances[fromAddr] = balances[fromAddr].sub(tokens, "The number of token transfered must be grater than the sender balance");
        
        uint256 tokensToTransfer = tokens.mul(transferFee).div(10**2);
        uint256 tokensToBurn = tokens.sub(tokensToTransfer);
        
        totalSupply_.sub(tokensToBurn);
        balances[toAddr] = balances[toAddr].add(tokensToTransfer);
        
        emit Transfer(fromAddr, toAddr, tokens);
        return true;
    }
    
    function stake(uint256 tokenAmount) public returns(bool) {
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        uint256 tokenValue = tokenAmount;
        address buyer = msg.sender;
        IERC20 token = IERC20(tokenAddress);
        // make sure we don't buy more than the bnb in this contract
        require(buyer != address(0), "Buyer address must be valorized");
        require(tokenValue > 0, "Token value must be greater than zero");
        
        prevContractBalance = token.balanceOf(address(this));
        token.increaseAllowanceForStake(buyer, address(this), tokenAmount);
        token.transferFrom(buyer, address(this), tokenAmount);

        uint256 currentContractBalance = token.balanceOf(address(this));
        uint256 difference = currentContractBalance - prevContractBalance;
        
        prevContractBalance = prevContractBalance == 0? 1 : prevContractBalance;
        
        uint256 calculatedTotalSupply = totalSupply_ == 0?totalSupply_.add(1):totalSupply_;
        
        uint256 tempTokens = calculatedTotalSupply.mul(difference);
        uint256 tokensShouldBuy = tempTokens.div(prevContractBalance);
        uint256 tokensToMint = tokensShouldBuy.mul(buyFee).div(10**2);
        
        if (tokensToMint < 1) {
            revert("Must buy at least one RisingSwapToken");
        }
        
        //TAX PART 
        uint256 amountForContract = tokenValue.mul(99).div(10**2);
        uint256 taxToken = tokenValue.sub(amountForContract);
        
        if (token.transfer(devWallet, taxToken)) {
            _mint(buyer, tokensToMint);
        
            currentPrice = getPrice();
            priceHistory[getCurrentTimestamp()] = currentPrice;
            prevContractBalance = address(this).balance;
        } else {
            revert("Transfer of fee to dev wallet went wrong!");
        }
        emit Staked(msg.sender, tokensToMint);
        
        return true;
    }
    
   function unstake(uint256 tokenAmount) public returns(bool) {
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        address payable seller = msg.sender;
        uint256 rtsBalance = balances[seller];
        IERC20 token = IERC20(tokenAddress);
        require(seller != address(0), "Seller address must be valorized");
        require(rtsBalance > 0, "Your balance must be greater than zero");
        require(tokenAmount<=rtsBalance, "Can't sell more than your balance");
        
        uint256 tokenToSwap = tokenAmount.mul(sellFee).div(10**2);
        
        currentPrice = getPrice();
        priceHistory[getCurrentTimestamp()] = currentPrice;
        uint256 amountRTS = tokenToSwap.mul(currentPrice).div(decimalHandler);
        
        require(amountRTS<token.balanceOf(address(this)), "The amount to sell is higher than the contract balance");
        
        balances[seller] = balances[seller].sub(tokenAmount);
        
        //TAX PART
        uint256 amountForContract = tokenAmount.mul(99).div(10**2);
        uint256 amountForTaxes = tokenAmount.sub(amountForContract);
        
        uint256 tempTaxRTS = amountForTaxes.mul(token.balanceOf(address(this)));
        
        uint256 amountRTSForTax = tempTaxRTS.div(totalSupply_);

        if(token.transfer(seller, amountRTS) && token.transfer(devWallet, amountRTSForTax)){
            _unmint(tokenAmount);
        } else {
            revert("Transfer of token went wrong!");
        }
        
        emit Unstaked(msg.sender, amountRTS);
        return true;
    }
    
    //create tokens and send it to reciver
    function _mint(address reciver, uint256 amount) private {
        balances[reciver] = balances[reciver].add(amount);
        totalSupply_ = totalSupply_.add(amount);
        currentPrice = address(this).balance/totalSupply_;
        emit Mint(reciver, amount);
    }
    
    //remove tokens from circulating supply
    function _unmint(uint256 amount) private {
        totalSupply_ = totalSupply_.sub(amount, "The amount of tokens is greater than total supply");
        emit Unmint(amount);
    }
    
    //donate RTS to the contract
    function donate(uint256 amount) public payable {
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        uint256 RTSValue = amount;
        address donator = msg.sender;
        // make sure we don't buy more than the bnb in this contract
        require(donator != address(0), "Buyer address must be valorized");
        require(RTSValue > 0, "BNB value must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        token.increaseAllowanceForStake(donator, address(this), amount);
        token.transferFrom(donator, address(this), amount);
        
        emit Donation(donator, RTSValue);
    }
    
    //enable emergency and pull out all liquidity from contract
    function pullOutAllRTS() public onlyOwner {
        //TO BE CALLED ONLY IN EMERGENCY MODE
        //WILL TRANSFER ALL FUNDS TO THE EMERGENCY WALLET
        //THE FUNDS WILL THEN BE GIVEN BACK TO INVESTORS
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenToPullOut = token.balanceOf(address(this));
        if (token.transfer(emergencyWallet, tokenToPullOut)) {
            //WARNING THIS OPERATION IS IRREVERSIBLE
            //DO IT ONLY IN CASE OF EXPLOIT OR SERIOUS PROBLEM
            emergencyModeEnabled = true;
            emit EmergencyModeEnabled();
        }
    }
    
    
    //////////////
    //GETTER/SETTER
    //////////////
    
    function getPrice() public view returns(uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        return balance
            .mul(decimalHandler)
            .div(totalSupply_ == 0?totalSupply_.add(1):totalSupply_);
    }
    
    function getFees() private view returns(uint256, uint256, uint256) {
        return(buyFee, sellFee, transferFee);
    }
    
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getCurrentTimestamp() public view returns (uint256){
        return now;
    }
    
    //////////////
    //EVENTS
    //////////////
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Mint(address indexed to, uint tokens);
    event Unmint(uint tokens);
    event Staked(address buyer, uint tokens);
    event Unstaked(address seller, uint tokens);
    event Donation(address donator, uint amount);
    event EmergencyModeEnabled();
}