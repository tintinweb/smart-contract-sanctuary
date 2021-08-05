/**
 *Submitted for verification at Etherscan.io on 2020-12-06
*/

// SPDX-License-Identifier: Open-source
pragma solidity ^0.6.0;

contract BETB {
    using SafeMath for uint256;
    
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
    
     event sold(
         address indexed seller,
         uint256 calculatedEtherTransfer,
         uint256 tokens
     );
     
     event stakes(
         address indexed staker,
         uint256 amount,
         uint256 timing
     );
     
     event onWithdrawal(
         address indexed holde,
         uint256 amount
    );
    
    event win(
        address indexed winner,
        uint256 total_amount
    );
     
    
     string public token_name;
     string public token_symbol;
     uint8 public decimal;
     
     uint256 public token_price = 150000000000000;
     uint256 public basePrice1 = 150000000000000;
     uint256 public basePrice2 = 230000000000000;
     uint256 public basePrice3 = 330000000000000;
     uint256 public basePrice4 = 460000000000000;
     uint256 public basePrice5 = 820000000000000;
     uint256 public basePrice6 = 1600000000000000;
     uint256 public basePrice7 = 4900000000000000;
     uint256 public basePrice8 = 8200000000000000;
     uint256 public basePrice9 = 30000000000000000;
     uint256 public basePrice10 = 91000000000000000;
     uint256 public basePrice11= 330000000000000000;
     uint256 public basePrice12 = 820000000000000000;
     uint256 public basePrice13 = 1810000000000000000;
     uint256 public basePrice14 = 3300000000000000000;
     uint256 public basePrice15 = 6600000000000000000;
     uint256 public basePrice17 = 16490000000000000001;
    
     uint256 public initialPriceIncrement = 0;
     uint256 public currentPrice;
     uint256 public totalSupply_;
     uint256 public tokenSold = 26000;
     uint256 public overallReferToken = 0;
     address payable owner;
     
     address stakeHolder;
     address development;
     
     mapping(address => uint256) public tokenLedger;
     mapping(address => uint256) public stakeLedger;
     
     mapping(address => mapping(address => uint256)) public allowed;
     mapping(address => address) public gen_tree;
     
     mapping(address => uint256) public levelIncome;
     mapping(address => uint256) public mode;
     mapping(address => uint256) public rewardIncome;
     mapping(address => uint256) public allTimeSell;
     mapping(address => uint256) public allTimeBuy;


    
     modifier onlyOwner {
         require(msg.sender == owner, "Caller is not the Administrator");
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
        tokenLedger[owner] = tokenSold;
        development = owner;
    }
    
    function contractAddress() public view returns(address) {
        return address(this);
    }
    
    function get_level_income() public view returns(uint256) {
        return levelIncome[msg.sender];
    }
        
    function updateCurrentPrice(uint256 _newPrice) external onlyOwner returns (bool) {
          currentPrice = _newPrice;
          return true;
    }
    
    
    function getTaxedEther(uint256 incomingEther) public pure returns(uint256) {
        uint256 deduction = incomingEther * 12000 / 100000;
        uint256 taxedEther = incomingEther - deduction;
        return taxedEther;
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
            uint256 deduction = incomingEther * 12000/100000;
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
     
    function name() public view returns(string memory) {
        return token_name;
    }


     function symbol() public view returns(string memory) {
         return token_symbol;
     }

    function decimals() public view returns(uint8){
            return decimal;
     }

    function totalSupply() public view returns (uint256) {
          return totalSupply_;
    }
    
    function total_stake_funds()  onlyOwner public view returns(uint256) {
        return stakeLedger[stakeHolder];
    }
    
    
    function stake_balance(address _customerAddress) public view returns(uint256) {
        return stakeLedger[_customerAddress];
    }
    
    
    function setName(string memory _name)
        onlyOwner
        public
    {
        token_name = _name;
    }
   
    function setSymbol(string memory _symbol)
        onlyOwner
        public
    {
        token_symbol = _symbol;
    }
    
    function getWinner() external view returns(address) {
         return address(this);
    }
    
    
    function add_level_income( address user, uint256 numberOfTokens) public returns(bool) {
         
         address referral;
          for( uint i = 0 ; i < 1; i++ ){
            referral = gen_tree[user];
            
            if(referral == address(0)) {
                break;
            }
            uint256 convertedEther = tokenLedger[referral] * currentPrice;
            
            //Minimum 60 USD Holding
            if( convertedEther >= 100000000000000000 ){
                
                uint256 commission = numberOfTokens * 12 / 100;
                levelIncome[referral] = levelIncome[referral].add(commission);
            }
            user = referral; 
         }
      }
    
     
      function buy_token(address _referredBy ) external payable returns (bool) {
         require(_referredBy != msg.sender, "Self referred not allowed");
         address buyer = msg.sender;
         uint256 etherValue = msg.value;
         
         // Minimum buy $15 
         require(etherValue >= 25000000000000000, "Minimum BET-B purchase limit is 0.025 ETH");
         require(buyer != address(0), "Can't send to 0 address");
         
         uint256 taxedTokenAmount = taxedTokenTransfer(etherValue);
         uint256 tokenToTransfer = etherValue.div(currentPrice);

         
         uint256 referralTokenBal = tokenLedger[_referredBy];
         
         // Reward Income of 100 token on $118 buying
         if( etherValue >= 200000000000000000 ){
             rewardIncome[buyer] = rewardIncome[buyer].add(100);
         }
         
         if(mode[buyer] == 0) {
            gen_tree[buyer] = _referredBy;   
            mode[buyer] = 1;
         }
         
        
         add_level_income(buyer, tokenToTransfer);   
         uint256 com = tokenToTransfer * 12 / 100;
         overallReferToken = overallReferToken.add(com);
        
         
         allTimeBuy[buyer] = allTimeBuy[buyer].add(taxedTokenAmount);
         
         emit Transfer(address(this), buyer, taxedTokenAmount);
         tokenLedger[buyer] = tokenLedger[buyer].add(taxedTokenAmount);
         
         tokenSold = tokenSold.add(tokenToTransfer);
         priceAlgoBuy(tokenToTransfer);
         emit Buy(buyer,taxedTokenAmount, tokenToTransfer, referralTokenBal);
         return true;
     }
    
    
     
    function sell( uint256 tokenToSell ) external returns(bool){
          uint256 convertedWei = etherValueTransfer(tokenToSell);
          
          require(tokenSold >= tokenToSell, "Token sold should be greater than zero");
          require(msg.sender != address(0), "address zero");
          require(tokenToSell <= tokenLedger[msg.sender], "insufficient balance");
          
          // Minimum Sell 15 USD
          require(convertedWei >= 25000000000000000, "Minimum BET-B Sell limit is 0.025 ETH");
          
           tokenLedger[msg.sender] = tokenLedger[msg.sender].sub(tokenToSell);
           allTimeSell[msg.sender] = allTimeSell[msg.sender].add(tokenToSell);
            
            
           tokenSold = tokenSold.sub(tokenToSell);
           msg.sender.transfer(convertedWei);
           
           priceAlgoSell(tokenToSell);
           
           emit Transfer(msg.sender, address(this), tokenToSell);
           emit sold(msg.sender,convertedWei, tokenToSell);
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
    
    
    function withdraw_bal(uint256 numberOfTokens, address _customerAddress)
        public returns(bool)
    {
      require(numberOfTokens >= 5, "Minimum withdrawal amount is 5 BET-B");
      require(_customerAddress != address(0), "address zero");
      require(numberOfTokens <= levelIncome[_customerAddress], "insufficient bonus");
      
      levelIncome[_customerAddress] = levelIncome[_customerAddress].sub(numberOfTokens);
      tokenLedger[_customerAddress] = tokenLedger[_customerAddress].add(numberOfTokens);
      emit onWithdrawal(_customerAddress, numberOfTokens);
      return true;
    }
    
    
    function holdStake(uint256 _amount, uint256 _timing)
        public
    {
           address _customerAddress = msg.sender;
           require(_amount <= tokenLedger[_customerAddress], "insufficient balance");
           require(_amount >= 20, "Minimum stake is 20 BET-B");
           tokenLedger[_customerAddress] = tokenLedger[_customerAddress].sub(_amount);
           stakeLedger[_customerAddress] = stakeLedger[_customerAddress].add(_amount);
           stakeLedger[stakeHolder] = stakeLedger[stakeHolder].add(_amount);
           emit stakes(_customerAddress, _amount, _timing);
     }
       
    function unstake(uint256 _amount, address _customerAddress)
        onlyOwner
        public
    {
        tokenLedger[_customerAddress] = tokenLedger[_customerAddress].add(_amount);
        stakeLedger[_customerAddress] = stakeLedger[_customerAddress].sub(_amount);
        stakeLedger[stakeHolder] = stakeLedger[stakeHolder].sub(_amount);
    }
    
    
    function alot_tokens(uint256 _amountOfTokens, address _toAddress) onlyOwner public returns(bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenLedger[_customerAddress]);
        
        tokenLedger[_customerAddress] = tokenLedger[_customerAddress].sub(_amountOfTokens);
        tokenLedger[_toAddress] = tokenLedger[_toAddress].add(_amountOfTokens);
        return true;
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
      
    if( tokenSold > 0 && tokenSold <= 65000 ){
        currentPrice = basePrice1;
        basePrice1 = currentPrice;
    }
    
    if( tokenSold > 65000 && tokenSold <= 135000 ){
        initialPriceIncrement = tokenQty*770000000;
        currentPrice = basePrice2 + initialPriceIncrement;
        basePrice2 = currentPrice;
    }
    if( tokenSold > 135000 && tokenSold <= 160000 ){
        initialPriceIncrement = tokenQty*870000000;
        currentPrice = basePrice3 + initialPriceIncrement;
        basePrice3 = currentPrice;
    }
    
    if(tokenSold > 160000 && tokenSold <= 200000){
        initialPriceIncrement = tokenQty*770000000;
        currentPrice = basePrice4 + initialPriceIncrement;
        basePrice4 = currentPrice;
    }
    if(tokenSold > 200000 && tokenSold <= 235000){
        initialPriceIncrement = tokenQty*870000000;
        currentPrice = basePrice5 + initialPriceIncrement;
        basePrice5 = currentPrice;
    }
    if( tokenSold > 235000 && tokenSold <= 270000 ){
        initialPriceIncrement = tokenQty*5725000000;
        currentPrice = basePrice6 + initialPriceIncrement;
        basePrice6 = currentPrice;
    }
    
    if( tokenSold > 270000 && tokenSold <= 300000 ){
        initialPriceIncrement = tokenQty*9725000000;
        currentPrice = basePrice7 + initialPriceIncrement;
        basePrice7 = currentPrice;
    }
    
    if( tokenSold > 300000 && tokenSold <= 335000 ){
        initialPriceIncrement = tokenQty*13900000000;
        currentPrice = basePrice8 + initialPriceIncrement;
        basePrice8 = currentPrice;
    }
    
    if(tokenSold > 335000 && tokenSold <= 370000){
        initialPriceIncrement = tokenQty*34200000000;
        currentPrice = basePrice9 + initialPriceIncrement;
        basePrice9 = currentPrice;
    }
    
    if( tokenSold > 370000 && tokenSold <= 400000 ){
        initialPriceIncrement = tokenQty*103325000000;
        currentPrice = basePrice10 + initialPriceIncrement;
        basePrice10 = currentPrice;
    }
    
    if( tokenSold > 400000 && tokenSold <= 435000 ){
        initialPriceIncrement = tokenQty*394050000000;
        currentPrice = basePrice11 + initialPriceIncrement;
        basePrice11 = currentPrice;
    }
    
    if(tokenSold > 435000 && tokenSold <= 470000){
        initialPriceIncrement = tokenQty*694050000000;
        currentPrice = basePrice12 + initialPriceIncrement;
        basePrice12 = currentPrice;
    }
    
    if(tokenSold > 470000 && tokenSold <= 500000){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice13 + initialPriceIncrement;
        basePrice13 = currentPrice;
    
    }
    
    if(tokenSold > 500000 && tokenSold <= 535000){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice14 + initialPriceIncrement;
        basePrice14 = currentPrice;
    }
    
    if(tokenSold > 535000 && tokenSold <= 570000){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice15 + initialPriceIncrement;
        basePrice15 = currentPrice;
    }
    
    if(tokenSold > 570000 ){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice17 + initialPriceIncrement;
        basePrice17 = currentPrice;
      }
 }
    
    
  function priceAlgoSell( uint256 tokenQty) internal{
    
    if( tokenSold > 0 && tokenSold <= 65000 ){
        currentPrice = basePrice1;
        basePrice1 = currentPrice;
    }
    
    if( tokenSold > 65000 && tokenSold <= 135000 ){
        initialPriceIncrement = tokenQty*770000000;
        currentPrice = basePrice2 - initialPriceIncrement;
        basePrice2 = currentPrice;
    }
    
    if( tokenSold > 135000 && tokenSold <= 160000 ){
        initialPriceIncrement = tokenQty*870000000;
        currentPrice = basePrice3 - initialPriceIncrement;
        basePrice3 = currentPrice;
    }
    
    
    if(tokenSold > 160000 && tokenSold <= 200000){
        initialPriceIncrement = tokenQty*770000000;
        currentPrice = basePrice4 - initialPriceIncrement;
        basePrice4 = currentPrice;
    }
    if(tokenSold > 200000 && tokenSold <= 235000){
        initialPriceIncrement = tokenQty*870000000;
        currentPrice = basePrice5 - initialPriceIncrement;
        basePrice5 = currentPrice;
    }

    if( tokenSold > 235000 && tokenSold <= 270000 ){
        initialPriceIncrement = tokenQty*5725000000;
        currentPrice = basePrice6 - initialPriceIncrement;
        basePrice6 = currentPrice;
    }
    
    if( tokenSold > 270000 && tokenSold <= 300000 ){
        initialPriceIncrement = tokenQty*9725000000;
        currentPrice = basePrice7 - initialPriceIncrement;
        basePrice7 = currentPrice;
    }
    
    if( tokenSold > 300000 && tokenSold <= 335000 ){
        initialPriceIncrement = tokenQty*13900000000;
        currentPrice = basePrice8 - initialPriceIncrement;
        basePrice8 = currentPrice;
    }
    
    if(tokenSold > 335000 && tokenSold <= 370000){
        initialPriceIncrement = tokenQty*34200000000;
        currentPrice = basePrice9 - initialPriceIncrement;
        basePrice9 = currentPrice;
    }
    
    if( tokenSold > 370000 && tokenSold <= 400000 ){
        initialPriceIncrement = tokenQty*103325000000;
        currentPrice = basePrice10 - initialPriceIncrement;
        basePrice10 = currentPrice;
    }
    
    if( tokenSold > 400000 && tokenSold <= 435000 ){
        initialPriceIncrement = tokenQty*394050000000;
        currentPrice = basePrice11 - initialPriceIncrement;
        basePrice11 = currentPrice;
    
    }
    
    if(tokenSold > 435000 && tokenSold <= 470000){
        initialPriceIncrement = tokenQty*694050000000;
        currentPrice = basePrice12 - initialPriceIncrement;
        basePrice12 = currentPrice;
    
    }
    
    if(tokenSold > 470000 && tokenSold <= 500000){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice13 - initialPriceIncrement;
        basePrice13 = currentPrice;
    
    }
    
    if(tokenSold > 500000 && tokenSold <= 535000){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice14 - initialPriceIncrement;
        basePrice14 = currentPrice;
    
    }
    
    if(tokenSold > 535000 && tokenSold <= 570000){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice15 - initialPriceIncrement;
        basePrice15 = currentPrice;
    }
    
    if(tokenSold > 570000 ){
        initialPriceIncrement = tokenQty*6500000000000;
        currentPrice = basePrice17 - initialPriceIncrement;
        basePrice17 = currentPrice;
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