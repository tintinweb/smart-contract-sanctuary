// SPDX-License-Identifier: Unlicensed

/*
    Moon Lottery is a community driven gambling token. ML is a descentralized token, that means the developers team will not 
hold any tokens and the ownership will be renonced after launching. The liquidity pool tokens will be locked fir 4 years.

Website: https://moonlottery.online
Telegram: https://t.me/lottery_moon
Twitter: https://twitter.com/lottery_moon

More information you cand find on the website.
*/

pragma solidity ^0.8.6;
import "ERC20.sol";


interface RNG{ // random number generator interface
    function rng() external returns(uint256);
}

contract MoonLottery is ERC20 {
// constants
    uint256 private constant MAX = ~uint256(0) / 10;
    address private constant BurnAddress = address(0x000000000000000000000000000000000000dEaD);
// arrays, mapings and address
    address[] private listOfHolders; //list of all token holders with any ballance (inc 0)
    mapping(address => bool) private isAddressExistInList; //to not add duplicated address
    mapping(address => bool) private isAddressExcludedFromList; //for excluded address ex. uniswappair, router, this contract, owner
    mapping(address => bool) private isExcludedFromFee; //for contract, owner, presale contract and router
    RNG private randomNumberGenerator; //Random number generator contract
    address payable private bnbAdress;
    address private presaleContractAddress;
// pair and router address
    address private uniswapV2Pair;
    IUniswapV2Router02 private uniswapV2Router;
// traking variables    
    uint256 private amountOfTotalRandomWins;
    uint256 private amountOfTotalJackpot;
    uint256 private amountBurn;
    uint256 private amountToProtocol;
    uint256 private jackpotPool;
// max values
    uint8 private maxWalletSizeProcent;
    uint256 private maxWalletSize;
// swap bools
    bool private inSwapAndTransfer;
    bool private swapAndTransferEnabled=true;
    bool private presaleMode = true; //used only before lunching to presale reasons;
// events
    event WinRandomLottery(address winner, uint256 amount);
    event SwapAndTransfer(uint256 tokenAmount, uint256 ethAmount);
    event BurnedTokens(uint256 amount);
    event WinJackpot(address winner, uint256 amount);
    event Received(address sender, uint amount);
    event SoldOnPresale(address buyer, uint amount);
    event AddedToRandomLotteryList(address holder);
    
    constructor (address payable _bnbAddress, address _router, address _rng) 
        ERC20( //ERC20 Base Constructor
            21000000, //Total Supply
            18, //Decimals
            "Moon Lottery", //Name
            "ML", //Symbol
            1//Max Tx Procent
            ){
// set addresses from constructor
        maxWalletSizeProcent = 4;
        randomNumberGenerator = RNG(_rng); //Random Number Generator contract Address
        bnbAdress = _bnbAddress; //Protocol Address
        address router =  _router; //Router Address                
// set min amounts
        jackpotPool = 94500 ether; //Initial Jackpot Pool
// set max amounts
        maxWalletSize = tSupply * maxWalletSizeProcent / 100; //Max wallet size
//router and pair
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router=_uniswapV2Router;
//exclude address from fee:
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[bnbAdress] = true;
        isExcludedFromFee[uniswapV2Pair] = true;
        isExcludedFromFee[BurnAddress] = true;
//exclude from random lolottery
        isAddressExcludedFromList[owner()] = true;
        isAddressExcludedFromList[address(this)] = true;
        isAddressExcludedFromList[bnbAdress] = true;
        isAddressExcludedFromList[uniswapV2Pair] = true;
        isAddressExcludedFromList[address(uniswapV2Router)] = true;
        isAddressExcludedFromList[BurnAddress] = true;
    }
       
//START - Core functions for this specific contract - randomness, jackpot, lottery, fees   
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function generateRandomNumber(uint256 _max) private returns(uint256){
            return randomNumberGenerator.rng() % (_max + 1);
    }
    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        require(balance[account] >= amount, "ERC20: burn amount exceeds balance");
        _tokenTransfer(account,BurnAddress,amount);
        amountBurn += amount;
        emit BurnedTokens(amount);
    }
    function takeFees(address sender, uint256 amount) private returns(uint256){
         uint256 initialAmount = amount;
            uint256 totalTax = amount * 15 / 100; // 15% total fees
            amount = amount - totalTax; // final amount
            uint256 amountToRandom = totalTax * 10 / 15; // 10% to a random holder if meets the requirments
            jackpotPool += totalTax * 3 / 15; // 3% to the jackpotPool
            amountToProtocol += totalTax * 2 / 15; // 2% to the protocol
            balance[address(this)] = balance[address(this)] + totalTax; 
            balance[sender] = balance[sender] - (initialAmount - amount);
            emit Transfer(sender, address(this), (initialAmount - amount));
            sendToRandomHolder(amountToRandom); // check for random holder
        return amount;
    }
    function sendToRandomHolder(uint256 amount) private{
        uint256 _rn = generateRandomNumber(listOfHolders.length - 1);
        if(balance[listOfHolders[_rn]] >= 1000 ether) { // the random holder must have at least 1,000 tokens to participate in the lottery
            balance[listOfHolders[_rn]] = balance[listOfHolders[_rn]] + amount;
            balance[address(this)] = balance[address(this)] - amount;
            emit WinRandomLottery(listOfHolders[_rn], amount);
            emit Transfer(address(this), listOfHolders[_rn], amount);
            amountOfTotalRandomWins = amountOfTotalRandomWins + amount;
        } else{ // if the holder doesn't have at least 1,000 tokens, the 10% fee is split
            _burn(address(this),amount * 2 / 10); // 2% is burn
            amountToProtocol += amount * 3 / 10; // 3% is going to the protocol
            jackpotPool += amount * 5 / 10; // 5% is goint to the jackpot pool
        }
    }
    function checkAndAddToHoldersList(address buyer) private{ // add new buyers to the list of holders
        if(!isAddressExistInList[buyer]) {
            listOfHolders.push(buyer);
            isAddressExistInList[buyer] = true;
            emit AddedToRandomLotteryList(buyer);
        }
    }
    function verifyWin(uint256 amount, uint _jackpot, uint256 _rn) internal pure returns(uint256){
        if(amount >= 30000 ether){ // if transaction ar over 30,000 tokens
            if(_rn % 100000 == 87639) // 1 in 100,000 chances to win 65% of the JackPot
                return _jackpot * 65 / 100;
            else if(_rn % 2000 == 1478) // 1 in 2,000 chances to win 20% of the JackPot    
                return _jackpot * 20 / 100;    
            else if(_rn % 1000 == 286) // 1 in 1,000 chances to win 10% of the JackPot    
                return _jackpot * 10 / 100;   
            else if(_rn % 100 == 27) // 1 in 100 chances to win 1% of the JackPot
                return _jackpot / 100; 
        } else if(amount >= 3000 ether){ // if transaction ar over 3,000 tokens and less then 30,000 tokens
            if(_rn % 1000 == 286) // 1 in 1,000 chances to win 10% of the JackPot    
               return _jackpot * 10 / 100;   
            else if(_rn % 100 == 27) // 1 in 100 chances to win 1% of the JackPot
                return _jackpot / 100;
        }
        return 0;
    }
    function tryForJackpot(address buyer, uint256 amount) private {
        uint256 amountWin = verifyWin(amount,jackpotPool,generateRandomNumber(MAX)); // returns the amount winned from the jackpot (if win)
            balance[address(this)] -= amountWin;
            balance[buyer] += amountWin;
            amountOfTotalJackpot += amountWin;
            jackpotPool -= amountWin;
            emit WinJackpot(buyer,amountWin);
            emit Transfer(address(this), buyer,amountWin); 
    }
    
    function verifyWinTest(uint256 amount, uint _jackpot, uint256 _rn) internal pure returns(uint256){
        if(amount >= 30000 ether){ // if transaction ar over 30,000 tokens
            if(_rn % 100 == 87) // 1 in 100,000 chances to win 65% of the JackPot
                return _jackpot * 65 / 100;
            else if(_rn % 30 == 28) // 1 in 2,000 chances to win 20% of the JackPot    
                return _jackpot * 20 / 100;    
            else if(_rn % 20 == 18) // 1 in 1,000 chances to win 10% of the JackPot    
                return _jackpot * 10 / 100;   
            else if(_rn % 10 == 2) // 1 in 100 chances to win 1% of the JackPot
                return _jackpot / 100; 
        } else if(amount >= 3000 ether){ // if transaction ar over 3,000 tokens and less then 30,000 tokens
            if(_rn % 20 == 18) // 1 in 1,000 chances to win 10% of the JackPot    
               return _jackpot * 10 / 100;   
            else if(_rn % 10 == 2) // 1 in 100 chances to win 1% of the JackPot
                return _jackpot / 100;
        }
        return 0;
    }
    function tryForJackpotTest(address buyer, uint256 amount) internal {
        uint256 amountWin = verifyWinTest(amount,jackpotPool,generateRandomNumber(MAX));
            balance[address(this)] -= amountWin;
            balance[buyer] += amountWin;
            amountOfTotalJackpot += amountWin;
            jackpotPool -= amountWin;
            emit WinJackpot(buyer,amountWin);
            emit Transfer(address(this), buyer,amountWin);        
    }
//END - Core functions for this specific contract - randomness, lottery, jackpot, fees    

//START - Swap functions, transfer for protocol
    modifier lockTheSwap { //for add lp and swap for eth
        inSwapAndTransfer = true;
        _;
        inSwapAndTransfer = false;
    }
    function swapAndProtocol() private lockTheSwap{
       if(amountToProtocol >= 2000 ether){ // swap only if the amount colected from fees is greater  then 2,000 tokens to avoid spamming
            uint256 initialTokenBallance = amountToProtocol;
            if(initialTokenBallance > maxTxAmount) // check to not exceeds the max transaction amount
                initialTokenBallance = maxTxAmount;
            swapExactTokenForETH(initialTokenBallance);
            amountToProtocol -= initialTokenBallance;
            uint256 ethAmountToTransfer = address(this).balance;
            bnbAdress.transfer(ethAmountToTransfer);
            emit SwapAndTransfer(initialTokenBallance, ethAmountToTransfer);
        }
    }
    function swapExactTokenForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
//END - Swap functions, transfer for protocol  
    
//START - Transfer function and related functions    
    function _Transfer(address sender, address recipient, uint256 amount) internal override { //overrides the original ERC20 virtual function
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balance[sender]>=amount, "Insufficient balance");
        
        
        if(sender != owner() && recipient != owner())  //only owner can make a transaction greater then maxTxAmount (needed for add lp and for presale)
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount."); 
        
        if(!presaleMode){ // when is not in presale mode - normal mode
            uint256 finalTransferAmount = amount; //local variable for amount calculation after fee
            
            if(isBuyTransction(sender,recipient)) {  //only if is a buy transaction will add the holder in the list and try to win the jackpot
                require((balance[recipient] + amount) <= maxWalletSize, "The amount buy exceeds the maximum wallet size allowed"); // if the amount exceeds the max wallet size allowed, the buy can't take place, sells cand be done (in limit of the max transaction amount) and wins from the lottery can occur
                checkAndAddToHoldersList(recipient); // check if is a new buyer
                tryForJackpotTest(recipient,amount); // try for jackpot if requirements are meet
            }
            
            if (!inSwapAndTransfer){ // if it's mot in a swap and transfer procces (normal operation)
                if (!isExcludedFromFee[sender] || !isExcludedFromFee[recipient]){
                    finalTransferAmount = takeFees(sender, amount); // takes fees
                }
            }
            
            if (!inSwapAndTransfer && sender != uniswapV2Pair && swapAndTransferEnabled) { //swap for protocol fee, only on sells and make sure is not in a loop
                swapAndProtocol(); 
            }
        
             _tokenTransfer(sender,recipient,finalTransferAmount); //the transfer after fees
        }
        else{ // when is in presale mode, only presale contract and owner can transfer tokens to avoid any bad intentions
            if(sender == presaleContractAddress){ // when presale contract send tokens to presale buyers
               checkAndAddToHoldersList(recipient); 
               _tokenTransfer(sender,recipient,amount);
               emit SoldOnPresale(recipient,amount);
            } else if(sender == owner()){ // owner can do transfers (eg send to presale contract, add lp)
                _tokenTransfer(sender,recipient,amount);
            } else { 
                revert("Only Owners and Presale contract cand do transfers for the moment");
            }
        }
    }
    
    function isBuyTransction(address sender, address recipient) private view returns(bool){
        if(sender == uniswapV2Pair && !isAddressExcludedFromList[recipient])
        return true;
        return false;
    }
//END - Transfer function and related functions    
    
//START - Setter and getter functions public or onlyowner
//onlyowner - setter
    function addAddresInList(address _adr) public onlyOwner{
        checkAndAddToHoldersList(_adr);
    }
    function getAddressFromList(uint256 ind) public view onlyOwner returns(address) {
        return listOfHolders[ind];
    }
    function startPresaleMode() public onlyOwner {
        presaleMode = true;
    }
    function endPresaleMode() public onlyOwner {
        presaleMode = false;
    }
    function setPresaleContractAdress(address _pca) public onlyOwner{
        presaleContractAddress = _pca;
    }
    function setRNGAdress(address _rng) public onlyOwner{
        randomNumberGenerator = RNG(_rng);
    }
//public view 
    function isAdressExcludedFromFee(address account) public view returns(bool) {
        return isExcludedFromFee[account];
    }
    function isAdressExcludedFromAddressList(address account) public view returns(bool) {
        return isAddressExcludedFromList[account];
    }
    function isAdressInRandomWinnersList(address account) public view returns(bool) {
        return isAddressExistInList[account];
    }
    function getAmountOfTotalRandomWins() public view returns (uint256) {
        return amountOfTotalRandomWins / 1 ether;
    }
    function getAmountOfTotalJackpotWins() public view returns (uint256) {
        return amountOfTotalJackpot / 1 ether;
    }
    function getAmountOfTotalBurn() public view returns (uint256) {
        return amountBurn / 1 ether;
    }
    function getJackpotPool() public view returns (uint256) {
        return jackpotPool / 1 ether;
    }
    function getMaxWalletSize() public view returns (uint256) {
        return maxWalletSize / 1 ether;
    }
    function getPresaleContractAddress() public view returns (address) {
        return presaleContractAddress;
    }
    function manualSwapAndTransfer() public {
        swapAndProtocol();
    }
//END - Setter and getter functions public or onlyowner    
    
 
    
}