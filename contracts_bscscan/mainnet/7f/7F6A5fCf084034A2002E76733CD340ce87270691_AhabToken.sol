pragma solidity 0.6.0;

import "./deps.sol";
//import "hardhat/console.sol";

contract AhabToken is IERC20, Ownable  {
    using SafeMath for uint256;

    string public constant name = "Ahab Token";
    string public constant symbol = "AHAB";
    uint8 public constant decimals = 0;
    uint256 totalSupply_;
    uint256 buyFee;
    uint256 sellFee;
    uint256 transferFee;
    uint256 devFee;
    uint256 currentPrice;
    uint256 public prevContractBalance = 0;
    address payable devWallet = 0x507c04756720f3D610f7D22449B823533aFCc3a1;
    address payable public adminAddr;

    //mapping variables
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    
    //price history logic
    mapping(uint256 => uint256) public priceHistory;
    uint256[] public priceHistoryIndexes;
    
    //serivce variables
    uint256 decimalHandler = 10**18;
    bool private emergencyModeEnabled = false;
    address payable emergencyWallet = 0xEf0b84715620471909FE0290A4cAFCc83dcaE544;
    mapping(address => uint256) public invested; //to trace investment in case of refund
    bool private isOperationEnabled = false;
    
    //constructor
    constructor(uint256 bFee, uint256 sFee, uint256 tFee, uint dFee) public {
        adminAddr = msg.sender;
        buyFee = bFee;
        sellFee = sFee;
        transferFee = tFee;
        devFee = dFee;
        _mint(adminAddr, 10000000000000);
    }
     /////////////
    //IERC20 METHODS
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

    function transferFrom(address sender, address reciver, uint256 numTokens) public override returns (bool) {
        return _transferFrom(sender, reciver, numTokens);
    }
    
    
    /////////////
    //CUSTOM METHODS
    /////////////
    
    function _transferFrom(address fromAddr, address toAddr, uint256 tokens) private returns(bool) {
        require(isOperationEnabled, "Operations are not enabled yet, try again when the contract operations are enabled. Visit ahabtoken.net for more info");
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        require(fromAddr != address(0), "Sender must be valorized");
        require(tokens>0, "Amount of tokens sended must be grater than 0");
        //implement better logic on taxes 
        balances[fromAddr] = balances[fromAddr].sub(tokens, "The number of token transfered must be grater than the sender balance");
        
        uint256 tokensToTransfer = tokens.mul(transferFee).div(10**2);
        uint256 tokensToBurn = tokens.sub(tokensToTransfer);
        
        _unmint(tokensToBurn);
        balances[toAddr] = balances[toAddr].add(tokensToTransfer);
        
        emit Transfer(fromAddr, toAddr, tokens);
        return true;
    }
    
    //method for ICO only, will be disabled after ICO
    function buyForICO() private returns(bool) {
        require(!isOperationEnabled, "ICO has ended, please buy via common way");
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        uint256 ETHValue = msg.value;
        address buyer = msg.sender;
        // make sure we don't buy more than the bnb in this contract
        require(buyer != address(0), "Buyer address must be valorized");
        require(ETHValue > 0, "BNB value must be greater than zero");
        
        uint256 tokensShouldBuy = ETHValue.mul(10);
        uint256 tokensToMint = tokensShouldBuy.mul(buyFee).div(10**2);
        
        if (tokensToMint < 1) {
            revert("Must buy at least one Ahab Token");
        }
        
        //TAX PART 
        uint256 amountForContract = ETHValue.mul(devFee).div(10**2);
        uint256 taxETH = ETHValue.sub(amountForContract);
        
        if (devWallet.send(taxETH)) {
            _mint(buyer, tokensToMint);
        
            currentPrice = getPrice();
            prevContractBalance = address(this).balance;
            invested[buyer] = invested[buyer].add(ETHValue);
        } else {
            revert("Transfer of fee to dev wallet went wrong!");
        }
        
        emit Bought(msg.sender, tokensToMint);
        
        return true;
    }
    
    function buy() private returns(bool) {
        require(isOperationEnabled, "Operations are not enabled yet, try again when the contract operations are enabled. Visit ahabtoken.net for more info");
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        uint256 ETHValue = msg.value;
        address buyer = msg.sender;
        // make sure we don't buy more than the bnb in this contract
        require(buyer != address(0), "Buyer address must be valorized");
        require(ETHValue > 0, "BNB value must be greater than zero");
        
        uint256 currentContractBalance = address(this).balance;
        prevContractBalance = currentContractBalance.sub(ETHValue);
        uint256 difference = currentContractBalance - prevContractBalance;
        
        prevContractBalance = prevContractBalance == 0 ? 1 : prevContractBalance;
        
        uint256 calculatedTotalSupply = totalSupply_ == 0?totalSupply_.add(1):totalSupply_;
        
        uint256 tempTokens = calculatedTotalSupply.mul(difference);
        uint256 tokensShouldBuy = tempTokens.div(prevContractBalance);
        uint256 tokensToMint = tokensShouldBuy.mul(buyFee).div(10**2);
        
        if (tokensToMint < 1) {
            revert("Must buy at least one Ahab Token");
        }
        
        //TAX PART 
        uint256 amountForContract = ETHValue.mul(devFee).div(10**2);
        uint256 taxETH = ETHValue.sub(amountForContract);
        
        if (devWallet.send(taxETH)) {
            _mint(buyer, tokensToMint);
        
            currentPrice = getPrice();
            prevContractBalance = address(this).balance;
            invested[buyer] = invested[buyer].add(ETHValue);
        } else {
            revert("Transfer of fee to dev wallet went wrong!");
        }
        
        //update price
        currentPrice = getPrice();
        //add current price to priceHistory
        priceHistory[now] = currentPrice;
        priceHistoryIndexes.push(now);
        
        emit Bought(msg.sender, tokensToMint);
        
        return true;
    }
    
    function sell(uint256 tokenAmount) public  returns(bool) {
        require(isOperationEnabled, "Operations are not enabled yet, try again when the contract operations are enabled. Visit ahabtoken.net for more info");
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        address payable seller = msg.sender;
        uint256 ahabBalance = balances[seller];
        require(seller != address(0), "Seller address must be valorized");
        require(ahabBalance > 0, "Your balance must be greater than zero");
        require(tokenAmount<=ahabBalance, "Can't sell more than your balance");
        
        uint256 tokenToSwap = tokenAmount.mul(sellFee).div(10**2);
        
        //update price
        currentPrice = getPrice();
        //add current price to priceHistory
        priceHistory[now] = currentPrice;
        priceHistoryIndexes.push(now);
        
        uint256 amountETH = tokenToSwap.mul(currentPrice).div(decimalHandler);
        
        require(amountETH<address(this).balance, "The amount to sell is higher than the contract balance");
        
        balances[seller] = balances[seller].sub(tokenAmount);
        
        //TAX PART
        uint256 amountForContract = tokenAmount.mul(devFee).div(10**2);
        uint256 amountForTaxes = tokenAmount.sub(amountForContract);
        
        uint256 tempTaxETH = amountForTaxes.mul(address(this).balance);
        
        uint256 amountETHForTax = tempTaxETH.div(totalSupply_);
        
        if(seller.send(amountETH) && devWallet.send(amountETHForTax)){
            _unmint(tokenAmount);
            invested[seller] = invested[seller].sub(amountETH);
        } else {
            revert("Transfer of BNB went wrong!");
        }
        
        emit Sold(msg.sender, amountETH);
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
    
    //donate ETH to the contract
    function donate() public payable {
        require(!emergencyModeEnabled, "Emergency mode is enabled, all operations are disabled");
        uint256 ETHValue = msg.value;
        address donator = msg.sender;
        require(donator != address(0), "Buyer address must be valorized");
        require(ETHValue > 0, "BNB value must be greater than zero");
        
        emit Donation(donator, ETHValue);
    }
    
    //burn tokens sended
    function burnAhab(uint256 tokenAmount) public {
        address burner = msg.sender;
        require(burner != address(0), "Burner address must be valorized");
        require(tokenAmount<=balances[burner], "Amount to burn must be less than your balance");
        require(tokenAmount<=totalSupply_, "Amount to burn must be less than total supply");
        
        balances[burner] = balances[burner].sub(tokenAmount);
        _unmint(tokenAmount);
    }
    
    //handle ETH recived from contract
    receive() external payable {
        if (isOperationEnabled)
        buy();
        else buyForICO();
    }
    
    //enable emergency and pull out all liquidity from contract
    function enablePanicMode() public onlyOwner {
        //TO BE CALLED ONLY IN EMERGENCY MODE
        //WILL TRANSFER ALL FUNDS TO THE EMERGENCY WALLET
        //THE FUNDS WILL THEN BE GIVEN BACK TO INVESTORS THROUGH AHABTOKEN.NET
        if (emergencyWallet.send(address(this).balance)) {
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
        return address(this).balance
            .mul(decimalHandler) //give more precision on the price decimals 
            .div(totalSupply_ == 0?totalSupply_.add(1):totalSupply_);
    }
    
    function getFees() private view returns(uint256, uint256, uint256) {
        return(buyFee, sellFee, transferFee);
    }
    
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function setOperationEnabled(bool state) public onlyOwner {
        isOperationEnabled=state;
    }
    
    //////////////
    //EVENTS
    //////////////
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Mint(address indexed to, uint tokens);
    event Unmint(uint tokens);
    event Bought(address buyer, uint tokens);
    event Sold(address seller, uint tokens);
    event Donation(address donator, uint amount);
    event EmergencyModeEnabled();
}