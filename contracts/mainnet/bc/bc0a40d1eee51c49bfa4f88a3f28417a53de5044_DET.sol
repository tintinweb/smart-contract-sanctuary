/**
 *Submitted for verification at Etherscan.io on 2020-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract DET {
    using SafeMath for uint256;
    
    /*==============================
    =            DET EVENTS            =
    ==============================*/
    
    
    event Approved(
        address indexed spender,
        address indexed recipient,
        uint256 tokens
    );

     event Buy(
         address indexed buyer,
         uint256 tokensTransfered,
         uint256 tokenToTransfer,
         uint256 referralBal
     );
     
      event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
     event Sells(
         address indexed seller,
         uint256 calculatedEtherTransfer,
         uint256 tokens
     );
     
     event stake(
         address indexed staker,
         uint256 amount,
         uint256 timing
     );
     
     
     /*=====================================
    =            DET CONFIGURABLES            =
    =====================================*/
    
     string public token_name;
     string public token_symbol;
     uint8 public decimal;
    
     uint256 public token_price = 190000000000000;
     uint256 public basePrice0 = 90000000000000;
     uint256 public basePrice1 = 190000000000000;
     uint256 public basePrice2 = 290000000000000;
     uint256 public basePrice3 = 350000000000000;
     uint256 public basePrice4 = 390000000000000;
     uint256 public basePrice5 = 480000000000000;
    
     uint256 public basePrice6 = 580000000000000;
    
     uint256 public basePrice7 = 1400000000000000;
     uint256 public basePrice8 = 2300000000000000;
     uint256 public basePrice9 = 4800000000000000;
     uint256 public basePrice10 = 9700000000000000;
     uint256 public basePrice11= 19000000000000000;
     uint256 public basePrice12 = 58000000000000000;
     uint256 public basePrice13 = 140000000000000000;
     uint256 public basePrice14 = 580000000000000000;
     uint256 public basePrice15 = 1550000000000000000;
     uint256 public basePrice16 = 3670000000000000000;
    
     uint256 public initialPriceIncrement = 0;
    
     uint256 public currentPrice;
    
     uint256 public totalSupply_;
     uint256 public tokenSold = 200000;
     address payable owner;
     address stakeHolder;
    
     mapping(address => uint256) public tokenLedger;
     mapping(address => mapping(address => uint256)) public allowed;

    
     modifier onlyOwner {
         require(msg.sender == owner, "Caller is not the owner");
        _;
     }
    
     constructor(string memory _tokenName, string memory _tokenSymbol, uint256 initialSupply) public  {
        owner = msg.sender;
        stakeHolder = owner;
        token_name = _tokenName;
        token_symbol = _tokenSymbol;
        decimal = 0;
        currentPrice = token_price + initialPriceIncrement;
        totalSupply_ = initialSupply;
        totalSupply_ = totalSupply_.sub(tokenSold);
        tokenLedger[owner] = tokenSold;
    }
    
    function contractAddress() public view returns(address) {
        return address(this);
    }

    function updateCurrentPrice(uint256 _newPrice) external onlyOwner returns (bool) {
          currentPrice = _newPrice;
          return true;
    }
    
    function etherToToken(uint256 incomingEtherWei) public view returns(uint256)  {
        uint256 tokenToTransfer = incomingEtherWei.div(currentPrice);
        return tokenToTransfer;
    }

    
    function tokenToEther(uint256 tokenToSell) public view returns(uint256)  {
        uint256 convertedEther = tokenToSell * currentPrice;
        return convertedEther;
    }

     
     function taxedTokenTransfer(uint256 incomingEther) internal view returns(uint256) {
            uint256 deduction = incomingEther * 20000/100000;
            uint256 taxedEther = incomingEther - deduction;
            uint256 tokenToTransfer = taxedEther.div(currentPrice);
            return tokenToTransfer;
     }

 
    
    function balanceOf(address _customerAddress) external
        view
        returns(uint256)
    {
        return tokenLedger[_customerAddress];
    }
    
    function getCurrentPrice() public view returns(uint) {
         return currentPrice;
     }
     
    function stake_funds()  public view returns(uint256) {
        return tokenLedger[stakeHolder];
    }
    
     
    function buy_token(address _referredBy ) external payable returns (bool) {
         require(_referredBy != msg.sender, "Self reference not allowed");
         address buyer = msg.sender;
         uint256 etherValue = msg.value;
         uint256 taxedTokenAmount = taxedTokenTransfer(etherValue);
         uint256 tokenToTransfer = etherValue.div(currentPrice);

         require(tokenToTransfer >= 5, "Minimum DET purchase limit is 5");
         require(buyer != address(0), "Can't send to Zero address");
         
         uint256 referralTokenBal = tokenLedger[_referredBy];
         
         emit Transfer(address(this), buyer, taxedTokenAmount);
         tokenLedger[buyer] = tokenLedger[buyer].add(taxedTokenAmount);
         tokenSold = tokenSold.add(tokenToTransfer);
         priceAlgoBuy(tokenToTransfer);
         emit Buy(buyer,taxedTokenAmount, tokenToTransfer, referralTokenBal);
         return true;
     }
    
     
    function sell(uint256 tokenToSell) external returns(bool){
          require(tokenSold >= tokenToSell, "Token sold should be greater than zero");
          require(tokenToSell >= 5, "Minimum token sell amount is 5 DET");
          require(msg.sender != address(0), "address zero");
          require(tokenToSell <= tokenLedger[msg.sender], "insufficient balance");
           
           uint256 convertedWei = etherValueTransfer(tokenToSell);
           tokenLedger[msg.sender] = tokenLedger[msg.sender].sub(tokenToSell);
           tokenSold = tokenSold.sub(tokenToSell);
           priceAlgoSell(tokenToSell);
           msg.sender.transfer(convertedWei);
           emit Transfer(msg.sender, address(this), tokenToSell);
           emit Sells(msg.sender,convertedWei, tokenToSell);
           return true;
     }
    
     
    function etherValueTransfer(uint256 tokenToSell) public view returns(uint256) {
        uint256 convertedEther = tokenToSell * currentPrice;
        return convertedEther;
     }
      
     
     function totalEthereumBalance() external onlyOwner view returns (uint256) {
        return address(this).balance;
    }
     
    
    function mintToken(uint256 _mintedAmount) onlyOwner public {
        totalSupply_ = totalSupply_.add(_mintedAmount);
    }
    
     function destruct() onlyOwner() public{
        selfdestruct(owner);
    }
    
    
    function withdrawReward(uint256 numberOfTokens, address _customerAddress)
        onlyOwner
        public
    {
        tokenLedger[_customerAddress] = tokenLedger[_customerAddress].add(numberOfTokens);
    }
    
    
    function holdStake(uint256 _amount, uint256 _timing)
        public
    {
           address _customerAddress = msg.sender;
           require(_amount <= tokenLedger[_customerAddress], "insufficient balance");
           require(_amount >= 20, "Minimum stake is 20 DET");
           tokenLedger[_customerAddress] = tokenLedger[_customerAddress].sub(_amount);
           tokenLedger[stakeHolder] = tokenLedger[stakeHolder].add(_amount);
           emit stake(_customerAddress, _amount, _timing);
     }
       
    function unstake(uint256 _amount, address _customerAddress)
        onlyOwner
        public
    {
        tokenLedger[_customerAddress] = tokenLedger[_customerAddress].add(_amount);
        tokenLedger[stakeHolder] = tokenLedger[stakeHolder].sub(_amount);
    }
    
    
    

     function transfer(address _toAddress, uint256 _amountOfTokens) onlyOwner
        public
        returns(bool)
      {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenLedger[_customerAddress]);
        
        tokenLedger[_customerAddress] = tokenLedger[_customerAddress].sub(_amountOfTokens);
        tokenLedger[_toAddress] = tokenLedger[_toAddress].add(_amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 tokens) public returns(bool success)  {
        require(tokens <= tokenLedger[_from]);
        require(tokens > 0);
        require(tokens <= allowed[_from][msg.sender]);
        
        tokenLedger[_from] = tokenLedger[_from].sub(tokens);
        tokenLedger[_to] = tokenLedger[_to].add(tokens);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(tokens);
        emit Transfer(_from, _to, tokens);
        return true;
    }
    
    
  function priceAlgoBuy( uint256 tokenQty) internal{

   if( tokenSold >= 0 && tokenSold <= 200000 ){
          currentPrice = basePrice0;
          basePrice0 = currentPrice;
      }
      
      
      if( tokenSold >= 200000 && tokenSold <= 250000 ){
          currentPrice = basePrice1;
          basePrice1 = currentPrice;
      }

      if( tokenSold > 250000 && tokenSold <= 300000 ){
         initialPriceIncrement = tokenQty*300000000;
         currentPrice = basePrice2 + initialPriceIncrement;
         basePrice2 = currentPrice;
      }

     if(tokenSold > 300000 && tokenSold <= 350000){
          initialPriceIncrement = tokenQty*450000000;
          currentPrice = basePrice3 + initialPriceIncrement;
          basePrice3 = currentPrice;
      }
      if(tokenSold > 350000 && tokenSold <= 400000){
           initialPriceIncrement = tokenQty*770000000;
           currentPrice = basePrice4 + initialPriceIncrement;
           basePrice4 = currentPrice;
       }
      if( tokenSold > 400000 && tokenSold <= 450000 ){
           initialPriceIncrement = tokenQty*870000000;
           currentPrice = basePrice5 + initialPriceIncrement;
           basePrice5 = currentPrice;
      }
      if( tokenSold > 450000 && tokenSold <= 500000 ){
           initialPriceIncrement = tokenQty*5725000000;
           currentPrice = basePrice6 + initialPriceIncrement;
           basePrice6 = currentPrice;
       }

     if( tokenSold > 500000 && tokenSold <= 550000 ){
          initialPriceIncrement = tokenQty*9725000000;
          currentPrice = basePrice7 + initialPriceIncrement;
          basePrice7 = currentPrice;
      }

      if(tokenSold > 550000 && tokenSold <= 600000){
          initialPriceIncrement = tokenQty*13900000000;
          currentPrice = basePrice8 + initialPriceIncrement;
          basePrice8 = currentPrice;
      }

       if( tokenSold > 600000 && tokenSold <= 650000 ){
               initialPriceIncrement = tokenQty*34200000000;
               currentPrice = basePrice9 + initialPriceIncrement;
               basePrice9 = currentPrice;
       }

      if( tokenSold > 650000 && tokenSold <= 700000 ){
          initialPriceIncrement = tokenQty*103325000000;
          currentPrice = basePrice10 + initialPriceIncrement;
          basePrice10 = currentPrice;
       }

     if(tokenSold > 700000 && tokenSold <= 750000){
           initialPriceIncrement = tokenQty*394050000000;
           currentPrice = basePrice11 + initialPriceIncrement;
           basePrice11 = currentPrice;

       }

      if(tokenSold > 750000 && tokenSold <= 800000){
           initialPriceIncrement = tokenQty*694050000000;//
           currentPrice = basePrice12 + initialPriceIncrement;
           basePrice12 = currentPrice;

       }

     if(tokenSold > 800000 && tokenSold <= 850000){
           initialPriceIncrement = tokenQty*6500000000000;
           currentPrice = basePrice13 + initialPriceIncrement;
           basePrice13 = currentPrice;

       }

     if(tokenSold > 850000 && tokenSold <= 900000){
          initialPriceIncrement = tokenQty*8400000000000;
          currentPrice = basePrice14 + initialPriceIncrement;
          basePrice14 = currentPrice;

     }

      if(tokenSold > 900000 && tokenSold <= 950000){
         initialPriceIncrement = tokenQty*8400000000000;
         currentPrice = basePrice15 + initialPriceIncrement;
         basePrice15 = currentPrice;
     }

     if(tokenSold > 950000 ){
         initialPriceIncrement = tokenQty*18400000000000;
         currentPrice = basePrice16 + initialPriceIncrement;
         basePrice16 = currentPrice;
      }
    }

     
    function priceAlgoSell( uint256 tokenQty) internal{

    if( tokenSold >= 0 && tokenSold <= 200000 ){
          currentPrice = basePrice0;
          basePrice0 = currentPrice;
      }
      
      if( tokenSold >= 200000 && tokenSold <= 250000 ){
          currentPrice = basePrice1;
          basePrice1 = currentPrice;
      }

      if( tokenSold > 250000 && tokenSold <= 300000 ){
         initialPriceIncrement = tokenQty*300000000;
         currentPrice = basePrice2 - initialPriceIncrement;
         basePrice2 = currentPrice;
      }

     if(tokenSold > 300000 && tokenSold <= 350000){
          initialPriceIncrement = tokenQty*450000000;
          currentPrice = basePrice3 - initialPriceIncrement;
          basePrice3 = currentPrice;
      }
      if(tokenSold > 350000 && tokenSold <= 400000){
           initialPriceIncrement = tokenQty*770000000;
           currentPrice = basePrice4 - initialPriceIncrement;
           basePrice4 = currentPrice;
       }
      if( tokenSold > 400000 && tokenSold <= 450000 ){
           initialPriceIncrement = tokenQty*870000000;
           currentPrice = basePrice5 - initialPriceIncrement;
           basePrice5 = currentPrice;
      }
      if( tokenSold > 450000 && tokenSold <= 500000 ){
           initialPriceIncrement = tokenQty*5725000000;
           currentPrice = basePrice6 - initialPriceIncrement;
           basePrice6 = currentPrice;
       }

     if( tokenSold > 500000 && tokenSold <= 550000 ){
          initialPriceIncrement = tokenQty*9725000000;
          currentPrice = basePrice7 - initialPriceIncrement;
          basePrice7 = currentPrice;
      }

      if(tokenSold > 550000 && tokenSold <= 600000){
          initialPriceIncrement = tokenQty*13900000000;
          currentPrice = basePrice8 - initialPriceIncrement;
          basePrice8 = currentPrice;
      }

       if( tokenSold > 600000 && tokenSold <= 650000 ){
           initialPriceIncrement = tokenQty*34200000000;
           currentPrice = basePrice9 - initialPriceIncrement;
           basePrice9 = currentPrice;
       }

      if( tokenSold > 650000 && tokenSold <= 700000 ){
          initialPriceIncrement = tokenQty*103325000000;
          currentPrice = basePrice10 - initialPriceIncrement;
          basePrice10 = currentPrice;
       }

     if(tokenSold > 700000 && tokenSold <= 750000){
           initialPriceIncrement = tokenQty*394050000000;
           currentPrice = basePrice11 - initialPriceIncrement;
           basePrice11 = currentPrice;

       }

      if(tokenSold > 750000 && tokenSold <= 800000){
           initialPriceIncrement = tokenQty*694050000000;
           currentPrice = basePrice12 - initialPriceIncrement;
           basePrice12 = currentPrice;

       }

     if(tokenSold > 800000 && tokenSold <= 850000){
           initialPriceIncrement = tokenQty*6500000000000;
           currentPrice = basePrice13 - initialPriceIncrement;
           basePrice13 = currentPrice;

       }

     if(tokenSold > 850000 && tokenSold <= 900000){
          initialPriceIncrement = tokenQty*8400000000000;
          currentPrice = basePrice14 - initialPriceIncrement;
          basePrice14 = currentPrice;

     }

      if(tokenSold > 900000 && tokenSold <= 950000){
         initialPriceIncrement = tokenQty*8400000000000;
         currentPrice = basePrice15 - initialPriceIncrement;
         basePrice15 = currentPrice;
     }

     if(tokenSold > 950000 ){
         initialPriceIncrement = tokenQty*18400000000000;
         currentPrice = basePrice16 - initialPriceIncrement;
         basePrice16 = currentPrice;
     }

  }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}