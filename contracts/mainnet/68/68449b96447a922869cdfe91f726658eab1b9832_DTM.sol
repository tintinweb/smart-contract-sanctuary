/**
 *Submitted for verification at Etherscan.io on 2020-12-07
*/

// SPDX-License-Identifier: Open Source
pragma solidity ^0.6.0;

contract DTM {
    using SafeMath for uint256;
    
    /*==============================
    =            DTM EVENTS            =
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
     
     string public token_name;
     string public token_symbol;
     uint8 public decimal;
    
    uint256 public token_price = 85000000000000;

    uint256 public basePrice1 = 85000000000000;
    uint256 public basePrice2 = 150000000000000;
    uint256 public basePrice3 = 850000000000000;
    uint256 public basePrice4 = 6800000000000000;
    uint256 public basePrice5 = 34000000000000000;
    
     uint256 public initialPriceIncrement = 0;
    
     uint256 public currentPrice;
     uint8 internal countAdd = 1;
     uint256 public totalSupply_;
     uint256 public tokenSold = 186000;
     
     address payable owner;
     address stakeHolder;
    
     mapping(address => uint256) public tokenLedger;
     mapping(address => address) public gen_tree;
     mapping(address => uint256) public levelIncome;
     mapping(address => uint256) public mode;
     
     mapping(address => uint256) public lastTimeSell;
     mapping(address => uint256) public firstTimeBuy;
     mapping(address => uint256) public all_time_selling;
     mapping(address => uint256) public sold;
     
     mapping(address => uint256) public buy_monthly;
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
        tokenLedger[owner] = tokenSold;
    }
    
    function contractAddress() public view returns(address) {
        return address(this);
    }
    
    function get_level_income(address _customerAddress) external view returns(uint256) {
        return levelIncome[_customerAddress];
    }
    
    function get_total_earning(address _customerAddress) public view returns(uint256) {
        return levelIncome[_customerAddress];
    }
        
    function updateCurrentPrice(uint256 _newPrice) external onlyOwner returns (bool) {
          currentPrice = _newPrice;
          return true;
    }
    
    
    function getTaxedEther(uint256 incomingEther) public pure returns(uint256) {
        uint256 deduction = incomingEther * 3000 / 100000;
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
        uint256 deduction = incomingEther * 3000/100000;
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
    
    function stake_funds()  public view returns(uint256) {
        return tokenLedger[stakeHolder];
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
    
    
    function add_level_income( address user, uint256 numberOfTokens) public returns(bool) {
         
         uint256 token_income1;
         uint256 token_income2;
         
             if(numberOfTokens >= 1000 && numberOfTokens < 5000){
                 token_income1 = 50;
                 token_income2 = 25;    
             }else if(numberOfTokens >= 5000 && numberOfTokens <  10000){
                 token_income1 = 75;
                 token_income2 = 37;
             }else if(numberOfTokens >= 10000 && numberOfTokens <  25000){
                 token_income1 = 100;
                 token_income2 = 50;
             }else if(numberOfTokens >= 25000 && numberOfTokens <  50000){
                 token_income1 = 150;
                 token_income2 = 75;
             }else if(numberOfTokens >= 50000 ){
                 token_income1 = 200;
                 token_income2 = 100;
             }else{
                 return false;
             }    
          
         
         
         address referral;
         uint256 commission;
         
          for( uint i = 0 ; i < 2; i++ ){
            referral = gen_tree[user];
            
            if(referral == address(0)) break;
            
            uint256 convertedEther = tokenLedger[referral] * currentPrice;
            
            // Minimum 0.04 - $24
            if( convertedEther >= 40000000000000000 ){
                if(i == 0){
                   commission = token_income1.div(countAdd);
                }else if(i == 1){
                   commission = token_income2.div(countAdd);
                }
                
                
                levelIncome[referral] = levelIncome[referral].add(commission);
            }
            user = referral; 
        }
    }
    
     
     
    function buy_token(address _referredBy ) external payable returns(bool) {
         
         address buyer = msg.sender;

         require(_referredBy != msg.sender, "Self reference not allowed");
         
         uint256 etherValue = msg.value;
         uint256 taxedTokenAmount = taxedTokenTransfer(etherValue);
         uint256 tokenToTransfer = etherValue.div(currentPrice);

         require(etherValue >= 84000000000000000, "Minimum purchase limit is 0.084 ETH");
         require(buyer != address(0), "Can't send to Zero address");
         uint256 referralTokenBal = tokenLedger[_referredBy];
         
         
         uint256 tokenGiving = tokenSold + tokenToTransfer;
         require(tokenGiving <= totalSupply_, "Token Supply exceeded");
         
         if(mode[buyer] == 0) {
            gen_tree[buyer] = _referredBy;   
            mode[buyer] = 1;
         }
         
         add_level_income( buyer, tokenToTransfer);    
     
         emit Transfer(address(this), buyer, taxedTokenAmount);
         tokenLedger[buyer] = tokenLedger[buyer].add(taxedTokenAmount);
         tokenSold = tokenSold.add(tokenToTransfer);
         
         buy_monthly[buyer] = buy_monthly[buyer].add(taxedTokenAmount);
         
         priceAlgoBuy();
         emit Buy(buyer,taxedTokenAmount, tokenToTransfer, referralTokenBal);
         
         if( firstTimeBuy[buyer] > 0 ) return true; 
         else firstTimeBuy[buyer] = block.timestamp;

         return true;
     }
    
    function sell( uint256 tokenToSell ) external returns(bool){
        
          require( tokenSold >= tokenToSell, "Token sold should be greater than zero");
          require( msg.sender != address(0), "address zero");
          require( tokenToSell <= tokenLedger[msg.sender], "insufficient balance");
          require( tokenToSell >= 10, "Sold limit is 10 token");
          uint256 deduction = tokenToSell * 3 / 100;
          uint256 payable_token = tokenToSell - deduction;
          uint256 convertedWei = etherValueTransfer(payable_token);
      //Start.... .. 
          uint256 selling_limit = buy_monthly[msg.sender] * 30 / 100;

         if( tokenToSell <= selling_limit ){
             
             uint256 sold_by_user = sold[msg.sender] + tokenToSell;
             
             if( sold_by_user <= selling_limit ){
                 
                   sold[msg.sender] = sold[msg.sender].add(tokenToSell);
                 
                 //--------------------END.
                   tokenLedger[msg.sender] = tokenLedger[msg.sender].sub(tokenToSell);
                   tokenSold = tokenSold.sub( tokenToSell );
                   priceAlgoSell();
                   msg.sender.transfer(convertedWei);
                   emit Transfer(msg.sender, address(this), payable_token);
                   emit Sells(msg.sender,convertedWei, tokenToSell);
                   
                 
             }else{
                revert("Selling Limit Exceeded.Try again With Less tokens.");
             }
                 
         }else{
             revert("Selling Limit Exceeded.Try again With Less coins.");
         }
          return true;
     }
     
     
     function extend_time() public  {
         if(block.timestamp >= firstTimeBuy[msg.sender] + 30 days) 
          {
              firstTimeBuy[msg.sender] = block.timestamp;
              buy_monthly[msg.sender] = tokenLedger[msg.sender];
              sold[msg.sender] = 0;
          }
     }
    
    function getFirstTimeBuying() external view returns(uint256) {
        return firstTimeBuy[msg.sender];
    }
    
    function getFirstBuyTime(address _customerAddress) public view returns(uint256) {
        return firstTimeBuy[_customerAddress];
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
        countAdd++;
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
      require(numberOfTokens >= 10, "Minimum withdrawal is 10 token");
      require(_customerAddress != address(0), "address zero");
      require(numberOfTokens <= levelIncome[_customerAddress], "insufficient bonus");
      levelIncome[_customerAddress] = levelIncome[_customerAddress].sub(numberOfTokens);
      tokenLedger[_customerAddress] = tokenLedger[_customerAddress].add(numberOfTokens);
      return true;
    }
    
    
    function holdStake(uint256 _amount, uint256 _timing)
        public
    {
           address _customerAddress = msg.sender;
           require(_amount <= tokenLedger[_customerAddress], "insufficient balance");
           require(_amount >= 20, "Minimum stake limit is 20");
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
    
    
   function priceAlgoBuy() internal{

    if( tokenSold > 0 && tokenSold <= 336000 ){
        currentPrice = basePrice1;
        basePrice1 = currentPrice;
    }

    if( tokenSold > 336000 && tokenSold <= 486000 ){
        currentPrice = basePrice2;
        basePrice2 = currentPrice;
    }

    if( tokenSold > 486000 && tokenSold <= 636000 ){
        currentPrice = basePrice3;
        basePrice3 = currentPrice;
    }

    if(tokenSold > 636000 && tokenSold <= 786000){
        currentPrice = basePrice4;
        basePrice4 = currentPrice;
    }
    if(tokenSold > 786000){
        currentPrice = basePrice5;
        basePrice5 = currentPrice;
    }
}


 function priceAlgoSell( ) internal{

    
    if( tokenSold > 0 && tokenSold <= 336000 ){
        currentPrice = basePrice1;
        basePrice1 = currentPrice;
    }

    if( tokenSold > 336000 && tokenSold <= 486000 ){
        currentPrice = basePrice2;
        basePrice2 = currentPrice;
    }
    
    if( tokenSold > 486000 && tokenSold <= 636000 ){
        currentPrice = basePrice3;
        basePrice3 = currentPrice;
    }

    
    if(tokenSold > 636000 && tokenSold <= 786000){
        
        currentPrice = basePrice4;
        basePrice4 = currentPrice;
    }
    
    if(tokenSold > 786000){
        currentPrice = basePrice5;
        basePrice5 = currentPrice;
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