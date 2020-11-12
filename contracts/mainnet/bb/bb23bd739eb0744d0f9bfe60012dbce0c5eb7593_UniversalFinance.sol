/**
 *Submitted for verification at Etherscan.io on 2020-11-06
*/

pragma solidity ^0.6.0;

contract UniversalFinance {
   
   /**
   * using safemath for uint256
    */
     using SafeMath for uint256;

   

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
   
    /**
    events for transfer
     */

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    /**
    * Approved Events
     */

    event Approved(
        address indexed spender,
        address indexed recipient,
        uint256 tokens
    );

    /**
    * buy Event
     */

     event Buy(
         address buyer,
         uint256 tokensTransfered
     );
   
   /**
    * sell Event
     */

     event Sell(
         address seller,
         uint256 calculatedEtherTransfer
     );
     
     event Reward(
       address indexed to,
       uint256 rewardAmount,
       uint256 level
    );

   /** configurable variables
   *  name it should be decided on constructor
    */
    string public tokenName;

    /** configurable variables
   *  symbol it should be decided on constructor
    */

    string public tokenSymbol;
   
    /** configurable variables
   *  decimal it should be decided on constructor
    */

    uint8 internal decimal;

    /** configurable variables
 
   
    /**
    * owner address
     */

     address public owner;

     /**
     current price
      */
    uint256 internal ethDecimal = 1000000000000000000;
    uint256 public currentPrice;
    uint256 public initialPrice = 10000000000000;
    uint256 public initialPriceIncrement = 0;
    uint256 public basePrice = 400;
    /**
    totalSupply
     */

    uint256 public _totalSupply;
   
    uint256 public _circulatedSupply = 0;
    uint256 public basePrice1 = 10000000000000;
    uint256 public basePrice2 = 250000000000000;
    uint256 public basePrice3 = 450000000000000;
    uint256 public basePrice4 = 800000000000000;
    uint256 public basePrice5 = 1375000000000000;
    uint256 public basePrice6 = 2750000000000000;
    uint256 public basePrice7 = 4500000000000000;
    uint256 public basePrice8 = 8250000000000000;
    uint256 public basePrice9 = 13250000000000000;
    uint256 public basePrice10 = 20500000000000000;
    uint256 public basePrice11 = 32750000000000000;
    uint256 public basePrice12 = 56250000000000000;
    uint256 public basePrice13 = 103750000000000000;
    uint256 public basePrice14 = 179750000000000000;
    uint256 public basePrice15 = 298350000000000000;
    uint256 public basePrice16 = 533350000000000000;
    uint256 public basePrice17 = 996250000000000000;
    uint256 public basePrice18 = 1780750000000000000;
    uint256 public basePrice19 = 2983350000000000000;
    uint256 public basePrice20 = 5108000000000000000;
    uint256 public basePrice21 = 8930500000000000000;
    uint256 public basePrice22 = 15136500000000000000;
   
   
       
         

   mapping(address => uint256) private tokenBalances;
   mapping(address => uint256) private allTimeTokenBal;

//   mapping (address => mapping (address => uint256 )) private _allowances;
   mapping(address => address) public genTree;
//   mapping(address => uint256) internal rewardBalanceLedger_;
//   mapping (address => mapping (uint256 => uint256 )) private levelCommission;

    /**
    modifier for checking onlyOwner
     */

     modifier onlyOwner() {
         require(msg.sender == owner,"Caller is not the owner");
         _;
     }

    constructor(string memory _tokenName, string  memory _tokenSymbol, uint256 totalSupply) public
    {
        //sonk = msg.sender;
       
        /**
        * set owner value msg.sender
         */
        owner = msg.sender;

        /**
        * set name for contract
         */

         tokenName = _tokenName;

         /**
        * set symbol for contract
         */

        /**
        * set decimals
         */

         decimal = 0;

         /**
         set tokenSymbol
          */

        tokenSymbol =  _tokenSymbol;

         /**
         set Current Price
          */

          currentPrice = initialPrice + initialPriceIncrement;

         
          _totalSupply = totalSupply;
          //_mint(owner,_totalSupply);

       
    }
   
    function geAllTimeTokenBalane(address _hodl) external view returns(uint256) {
            return allTimeTokenBal[_hodl];
     }
   
    /*function getRewardBalane(address _hodl) external view returns(uint256) {
            return rewardBalanceLedger_[_hodl];
     }*/
   
   function taxDeduction(uint256 incomingEther) public pure returns(uint256)  {
         
        uint256 deduction = incomingEther * 22500/100000;
        return deduction;
         
    }
   
    function getTaxedEther(uint256 incomingEther) public pure returns(uint256)  {
         
        uint256 deduction = incomingEther * 22500/100000;
        uint256 taxedEther = incomingEther - deduction;
        return taxedEther;
         
    }
   
   function etherToToken(uint256 incomingEther) public view returns(uint256)  {
         
        uint256 deduction = incomingEther * 22500/100000;
        uint256 taxedEther = incomingEther - deduction;
        uint256 tokenToTransfer = taxedEther.div(currentPrice);
        return tokenToTransfer;
         
    }
   
   
    function tokenToEther(uint256 tokenToSell) public view returns(uint256)  {
         
        uint256 convertedEther = tokenToSell * (currentPrice - (currentPrice/100));
        return convertedEther;
         
    }
   
   
    function transferEther(address payable receiver,uint256 _value) external onlyOwner returns (bool) {
        require(msg.sender == owner, 'You are not owner');
        receiver.transfer(_value);
        return true;
     }
     
     
    /**
    get TokenName
     */
    function name() public view returns(string memory) {
        return tokenName;
    }

    /**
    get symbol
     */

     function symbol() public view returns(string memory) {
         return tokenSymbol;
     }

     /**
     get decimals
      */

      function decimals() public view returns(uint8){
            return decimal;
      }
     
      /**
      getTotalsupply of contract
       */

    function totalSupply() external view returns(uint256) {
            return _totalSupply;
    }

    /**
    * balance of of token hodl.
     */

     function balanceOf(address _hodl) external view returns(uint256) {
            return tokenBalances[_hodl];
     }

    /**
    get current price
     */

     function getCurrentPrice() external view returns(uint256) {
         return currentPrice;
     }

     /**
     * update current price
     * notice this is only done by owner  
      */

      function updateCurrentPrice(uint256 _newPrice) external onlyOwner returns (bool) {
          currentPrice = _newPrice;
          return true;
      }
      
     
     
     /*function contractAddress() public view returns(address) {
         return address(this);
     }*/

     /* function levelWiseBalance(address _hodl, uint256 level) external view returns (uint256) {
        return levelCommission[_hodl][level];
      }*/
      /**
      buy Tokens from Ethereum.
       */

     function buy(address _referredBy) external payable returns (bool) {
         require(_referredBy != msg.sender, "Self reference not allowed");
        /* if(_referredBy == msg.sender){
             return false;
         }else{
         if(tokenBalances[msg.sender] > 5000){
             return false;
         }
         else{*/
         address buyer = msg.sender;
         uint256 etherValue = msg.value;
         uint256 circulation = etherValue.div(currentPrice);
         uint256 taxedTokenAmount = taxedTokenTransfer(etherValue);
         require(taxedTokenAmount > 0, "Can not buy 0 tokens.");
         require(taxedTokenAmount <= 5000, "Maximum Buying Reached.");
         require(taxedTokenAmount.add(allTimeTokenBal[msg.sender]) <= 5000, "Maximum Buying Reached.");
         genTree[msg.sender] = _referredBy;
         _mint(buyer,taxedTokenAmount,circulation);
         emit Buy(buyer,taxedTokenAmount);
         return true;
         /*}
         }*/
     }
     
     receive() external payable {
         require((allTimeTokenBal[msg.sender] + msg.value) <= 5000, "Maximum Buying Reached.");
         genTree[msg.sender] = address(0);
         address buyer = msg.sender;
         uint256 etherValue = msg.value;
         uint256 actualTokenQty = etherValue.div(currentPrice);
         uint256 calculatedTokens = taxedTokenTransfer(etherValue);
         require(calculatedTokens <= 5000, "Maximum Buying Reached.");
         _mint(buyer,calculatedTokens,actualTokenQty);
         emit Buy(buyer,calculatedTokens);
         
     }
     
     function priceAlgoBuy(uint256 tokenQty) internal{
         if(_circulatedSupply >= 0 && _circulatedSupply <= 600000){
             currentPrice = basePrice1;
             basePrice1 = currentPrice;
         }
         if(_circulatedSupply > 600000 && _circulatedSupply <= 1100000){
             initialPriceIncrement = tokenQty*300000000;
             currentPrice = basePrice2 + initialPriceIncrement;
             basePrice2 = currentPrice;
         }
         if(_circulatedSupply > 1100000 && _circulatedSupply <= 1550000){
             initialPriceIncrement = tokenQty*450000000;
             currentPrice = basePrice3 + initialPriceIncrement;
             basePrice3 = currentPrice;
         }
         if(_circulatedSupply > 1550000 && _circulatedSupply <= 1960000){
             initialPriceIncrement = tokenQty*675000000;
             currentPrice = basePrice4 + initialPriceIncrement;
             basePrice4 = currentPrice;
         }if(_circulatedSupply > 1960000 && _circulatedSupply <= 2310000){
             initialPriceIncrement = tokenQty*2350000000;
             currentPrice = basePrice5 + initialPriceIncrement;
             basePrice5 = currentPrice;
         }
         if(_circulatedSupply > 2310000 && _circulatedSupply <= 2640000){
             initialPriceIncrement = tokenQty*3025000000;
             currentPrice = basePrice6 + initialPriceIncrement;
             basePrice6 = currentPrice;
         }
         if(_circulatedSupply > 2640000 && _circulatedSupply <= 2950000){
             initialPriceIncrement = tokenQty*5725000000;
             currentPrice = basePrice7 + initialPriceIncrement;
             basePrice7 = currentPrice;
         }
         if(_circulatedSupply > 2950000 && _circulatedSupply <= 3240000){
             initialPriceIncrement = tokenQty*8525000000;
             currentPrice = basePrice8 + initialPriceIncrement;
             basePrice8 = currentPrice;
         }
         
         if(_circulatedSupply > 3240000 && _circulatedSupply <= 3510000){
             initialPriceIncrement = tokenQty*13900000000;
             currentPrice = basePrice9 + initialPriceIncrement;
             basePrice9 = currentPrice;
             
         }if(_circulatedSupply > 3510000 && _circulatedSupply <= 3770000){
             initialPriceIncrement = tokenQty*20200000000;
             currentPrice = basePrice10 + initialPriceIncrement;
             basePrice10 = currentPrice;
             
         }if(_circulatedSupply > 3770000 && _circulatedSupply <= 4020000){
             initialPriceIncrement = tokenQty*50000000000;
             currentPrice = basePrice11 + initialPriceIncrement;
             basePrice11 = currentPrice;
             
         }if(_circulatedSupply > 4020000 && _circulatedSupply <= 4260000){
             initialPriceIncrement = tokenQty*133325000000;
             currentPrice = basePrice12 + initialPriceIncrement;
             basePrice12 = currentPrice;
             
         }if(_circulatedSupply > 4260000 && _circulatedSupply <= 4490000){
             initialPriceIncrement = tokenQty*239125000000;
             currentPrice = basePrice13 + initialPriceIncrement;
             basePrice13 = currentPrice;
             
         }
         if(_circulatedSupply > 4490000 && _circulatedSupply <= 4700000){
             initialPriceIncrement = tokenQty*394050000000;
             currentPrice = basePrice14 + initialPriceIncrement;
             basePrice14 = currentPrice;
             
         }
         if(_circulatedSupply > 4700000 && _circulatedSupply <= 4900000){
             initialPriceIncrement = tokenQty*689500000000;
             currentPrice = basePrice15 + initialPriceIncrement;
             basePrice15 = currentPrice;
             
         }
         if(_circulatedSupply > 4900000 && _circulatedSupply <= 5080000){
             initialPriceIncrement = tokenQty*1465275000000;
             currentPrice = basePrice16 + initialPriceIncrement;
             basePrice16 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5080000 && _circulatedSupply <= 5220000){
             initialPriceIncrement = tokenQty*3158925000000;
             currentPrice = basePrice17 + initialPriceIncrement;
             basePrice17 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5220000 && _circulatedSupply <= 5350000){
             initialPriceIncrement = tokenQty*5726925000000;
             currentPrice = basePrice18 + initialPriceIncrement;
             basePrice18 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5350000 && _circulatedSupply <= 5460000){
             initialPriceIncrement = tokenQty*13108175000000;
             currentPrice = basePrice19 + initialPriceIncrement;
             basePrice19 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5460000 && _circulatedSupply <= 5540000){
             initialPriceIncrement = tokenQty*34687500000000;
             currentPrice = basePrice20 + initialPriceIncrement;
             basePrice20 = currentPrice;
             
         }
         if(_circulatedSupply > 5540000 && _circulatedSupply <= 5580000){
             initialPriceIncrement = tokenQty*120043750000000;
             currentPrice = basePrice21 + initialPriceIncrement;
             basePrice21 = currentPrice;
             
         }
         if(_circulatedSupply > 5580000 && _circulatedSupply <= 5600000){
             initialPriceIncrement = tokenQty*404100000000000;
             currentPrice = basePrice22 + initialPriceIncrement;
             basePrice22 = currentPrice;
         }
     }
     
     
      function priceAlgoSell(uint256 tokenQty) internal{
         if(_circulatedSupply >= 0 && _circulatedSupply < 600000){
             initialPriceIncrement = tokenQty*300000;
             currentPrice = basePrice1 - initialPriceIncrement;
             basePrice1 = currentPrice;
         }
         if(_circulatedSupply >= 600000 && _circulatedSupply <= 1100000){
             initialPriceIncrement = tokenQty*300000000;
             currentPrice = basePrice2 - initialPriceIncrement;
             basePrice2 = currentPrice;
         }
         if(_circulatedSupply > 1100000 && _circulatedSupply <= 1550000){
             initialPriceIncrement = tokenQty*450000000;
             currentPrice = basePrice3 - initialPriceIncrement;
             basePrice3 = currentPrice;
         }
         if(_circulatedSupply > 1550000 && _circulatedSupply <= 1960000){
             initialPriceIncrement = tokenQty*675000000;
             currentPrice = basePrice4 - initialPriceIncrement;
             basePrice4 = currentPrice;
         }if(_circulatedSupply > 1960000 && _circulatedSupply <= 2310000){
             initialPriceIncrement = tokenQty*2350000000;
             currentPrice = basePrice5 - initialPriceIncrement;
             basePrice5 = currentPrice;
         }
         if(_circulatedSupply > 2310000 && _circulatedSupply <= 2640000){
             initialPriceIncrement = tokenQty*3025000000;
             currentPrice = basePrice6 - initialPriceIncrement;
             basePrice6 = currentPrice;
         }
         if(_circulatedSupply > 2640000 && _circulatedSupply <= 2950000){
             initialPriceIncrement = tokenQty*5725000000;
             currentPrice = basePrice7 - initialPriceIncrement;
             basePrice7 = currentPrice;
         }
         if(_circulatedSupply > 2950000 && _circulatedSupply <= 3240000){
             initialPriceIncrement = tokenQty*8525000000;
             currentPrice = basePrice8 - initialPriceIncrement;
             basePrice8 = currentPrice;
         }
         
         if(_circulatedSupply > 3240000 && _circulatedSupply <= 3510000){
             initialPriceIncrement = tokenQty*13900000000;
             currentPrice = basePrice9 - initialPriceIncrement;
             basePrice9 = currentPrice;
             
         }if(_circulatedSupply > 3510000 && _circulatedSupply <= 3770000){
             initialPriceIncrement = tokenQty*20200000000;
             currentPrice = basePrice10 - initialPriceIncrement;
             basePrice10 = currentPrice;
             
         }if(_circulatedSupply > 3770000 && _circulatedSupply <= 4020000){
             initialPriceIncrement = tokenQty*50000000000;
             currentPrice = basePrice11 - initialPriceIncrement;
             basePrice11 = currentPrice;
             
         }if(_circulatedSupply > 4020000 && _circulatedSupply <= 4260000){
             initialPriceIncrement = tokenQty*133325000000;
             currentPrice = basePrice12 - initialPriceIncrement;
             basePrice12 = currentPrice;
             
         }if(_circulatedSupply > 4260000 && _circulatedSupply <= 4490000){
             initialPriceIncrement = tokenQty*239125000000;
             currentPrice = basePrice13 - initialPriceIncrement;
             basePrice13 = currentPrice;
             
         }
         if(_circulatedSupply > 4490000 && _circulatedSupply <= 4700000){
             initialPriceIncrement = tokenQty*394050000000;
             currentPrice = basePrice14 - initialPriceIncrement;
             basePrice14 = currentPrice;
             
         }
         if(_circulatedSupply > 4700000 && _circulatedSupply <= 4900000){
             initialPriceIncrement = tokenQty*689500000000;
             currentPrice = basePrice15 - initialPriceIncrement;
             basePrice15 = currentPrice;
             
         }
         if(_circulatedSupply > 4900000 && _circulatedSupply <= 5080000){
             initialPriceIncrement = tokenQty*1465275000000;
             currentPrice = basePrice16 - initialPriceIncrement;
             basePrice16 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5080000 && _circulatedSupply <= 5220000){
             initialPriceIncrement = tokenQty*3158925000000;
             currentPrice = basePrice17 - initialPriceIncrement;
             basePrice17 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5220000 && _circulatedSupply <= 5350000){
             initialPriceIncrement = tokenQty*5726925000000;
             currentPrice = basePrice18 - initialPriceIncrement;
             basePrice18 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5350000 && _circulatedSupply <= 5460000){
             initialPriceIncrement = tokenQty*13108175000000;
             currentPrice = basePrice19 - initialPriceIncrement;
             basePrice19 = currentPrice;
             
         }
         
          if(_circulatedSupply > 5460000 && _circulatedSupply <= 5540000){
             initialPriceIncrement = tokenQty*34687500000000;
             currentPrice = basePrice20 - initialPriceIncrement;
             basePrice20 = currentPrice;
             
         }
         if(_circulatedSupply > 5540000 && _circulatedSupply <= 5580000){
             initialPriceIncrement = tokenQty*120043750000000;
             currentPrice = basePrice21 - initialPriceIncrement;
             basePrice21 = currentPrice;
             
         }
         if(_circulatedSupply > 5580000 && _circulatedSupply <= 5600000){
             initialPriceIncrement = tokenQty*404100000000000;
             currentPrice = basePrice22 - initialPriceIncrement;
             basePrice22 = currentPrice;
         }
     }
     
     
   /* function distributeRewards(uint256 _amountToDistribute, address _idToDistribute)
    internal
    {
       
        for(uint256 i=0; i<15; i++)
        {
            address referrer = genTree[_idToDistribute];
            uint256 holdingAmount = ((currentPrice/ethDecimal) * basePrice) *tokenBalances[referrer];
            if(referrer != address(0))
            {
                if(i == 0 && holdingAmount>=100){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[0]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[0]/10000);
                }else if((i == 1) && holdingAmount>=200){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[1]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[1]/10000);
                }else if((i == 2) && holdingAmount>=200){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[2]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[2]/10000);
                }else if((i == 3) && holdingAmount>=300){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[3]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[3]/10000);
                }else if((i >= 4 && i<= 9) && holdingAmount>=300){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[4]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[4]/10000);
                }else if((i >= 10 && i<= 12) && holdingAmount>=400){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[5]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[5]/10000);
                }else if((i >= 13 && i<15) && holdingAmount>=500){
                    rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[6]/10000);
                    levelCommission[referrer][i+1].add(_amountToDistribute*percent_[6]/10000);
                }else{
                   
                }
               
                _idToDistribute = referrer;
                //emit Reward(referrer,(_amountToDistribute*_amountToDistribute[i]*100)/10,i);
            }else{
               
            }
        }
       
    }*/

    /**
    calculation logic for buy function
     */

     function taxedTokenTransfer(uint256 incomingEther) internal view returns(uint256) {
            uint256 deduction = incomingEther * 22500/100000;
            uint256 taxedEther = incomingEther - deduction;
            uint256 tokenToTransfer = taxedEther.div(currentPrice);
            return tokenToTransfer;
     }

     /**
     * sell method for ether.
      */

     function sell(uint256 tokenToSell) external returns(bool){
          require(_circulatedSupply > 0, "no circulated tokens");
          require(tokenToSell > 0, "can not sell 0 token");
          require(tokenToSell <= tokenBalances[msg.sender], "not enough tokens to transact");
          require(tokenToSell.add(_circulatedSupply) <= _totalSupply, "exceeded total supply");
          uint256 convertedEthers = etherValueTransfer(tokenToSell);
          msg.sender.transfer(convertedEthers);
          _burn(msg.sender,tokenToSell);
          emit Sell(msg.sender,convertedEthers);
          return true;
     }
     
     
     

     function etherValueTransfer(uint256 tokenToSell) internal view returns(uint256) {
         uint256 convertedEther = tokenToSell * (currentPrice - currentPrice/100);
        return convertedEther;
     }


    function accumulatedEther() external onlyOwner view returns (uint256) {
        return address(this).balance;
    }
   
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        emit Transfer(sender, recipient, amount);
        tokenBalances[sender] = tokenBalances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        tokenBalances[recipient] = tokenBalances[recipient].add(amount);
    }

   
     /*function _approve(address spender, address recipient, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[spender][recipient] = amount;
        emit Approved(spender, recipient, amount);
    }*/


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */

    function _mint(address account, uint256 amount, uint256 circulation) internal  {
        require(account != address(0), "ERC20: mint to the zero address");
       /* if(account == owner){
            emit Transfer(address(0), account, amount);
            tokenBalances[owner] = tokenBalances[owner].add(amount);
        }else{*/
            emit Transfer(address(this), account, amount);
            tokenBalances[account] = tokenBalances[account].add(amount);
            allTimeTokenBal[account] = allTimeTokenBal[account].add(amount);
            _circulatedSupply = _circulatedSupply.add(circulation);
            priceAlgoBuy(circulation);
        /*}*/
       
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        emit Transfer(account, address(this), amount);
        tokenBalances[account] = tokenBalances[account].sub(amount);
        //tokenBalances[owner] = tokenBalances[owner].add(amount);
        _circulatedSupply = _circulatedSupply.sub(amount);
        allTimeTokenBal[account] = allTimeTokenBal[account].sub(amount);
        priceAlgoSell(amount);
    }

    function _msgSender() internal view returns (address ){
        return msg.sender;
    }
 
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}