/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: UNLICENSED
   
    pragma solidity ^0.6.6;
   
   
    /**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
    library SafeMath {
   
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
   
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
   
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
       
        return c;
    }
   
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
   
    /**
    * @dev Mod two numbers.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
        }
    }
   
   
    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */
    interface IERC20 {
   
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
   
    function approve(address spender, uint256 amount) external returns (bool);
   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
   
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }
   
   
    /**
    * @title SafeERC20
    * @dev Wrappers around ERC20 operations that throw on failure.
    * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
    * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
    */
    library SafeERC20 {
    using SafeMath for uint256;
   
        function safeTransfer(IERC20 token, address to, uint256 value) internal {
            require(token.transfer(to, value));
        }
   
        function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
            require(token.transferFrom(from, to, value));
        }
    }
    
     /**
    * @title Presale
    * @dev Presale distribution of tokens
    */
    contract Presale {
        using SafeERC20 for IERC20;
       
        using SafeMath for uint256;
        
        IERC20 private token;
       
        address private _owner;
       
        
        /**
       * @dev constructor
       * @param contractAddress Main token contractAddress
       * @param _minContribution Minimum contribution in Presale
       * @param _minCap Minimum cap to make presale successfull
       * @param _maxCap Maximum cap of presale
       * @param _endDate Presale ened date
       */
        constructor(address contractAddress,address payable _targetWallet,uint256 _minContribution,uint256 _minCap,uint256 _maxCap,uint256 _endDate) public {
            require(_targetWallet != address(0) ,"Address zero");
            require(_minCap >0 && _maxCap>_minCap,"Value must be greater");
            token=IERC20(contractAddress);
            _owner=msg.sender;
            wallet=_targetWallet;
            presaleEndDate = block.timestamp+(60*60*24*_endDate);
            //presaleStartDate = block.timestamp+(60*60*24*_startDate);
            presaleStartDate = block.timestamp;
            minContribution = _minContribution;
            minCap = _minCap;
            maxCap = _maxCap;
        }
        /**
       * @dev Throws if called by any account other than the owner.
       */
        modifier onlyOwner(){
            require(_owner==msg.sender,"Only owner");
             _;
        }
       
        // Amount raised in presale
        // ==================
        uint256 public amountRaisedPresale;
       
        address payable private wallet;
       
        mapping (address => uint256) private presaleInvestors;
        uint256 public presaleStartDate;
        uint256 public presaleEndDate;
        uint256 public minContribution;
        uint256 public minCap;
        uint256 public maxCap;
        uint public rate=20000000000000;
   
        //Tokens for presale
        uint256 public presaleToken=50000000000000;
       
        //Tokens distributed in presale
        uint256 public tokenSoldInPresale;
       
        // Events
        // =================
        event TokenPurchase(address _beneficiary,uint256 amount,uint256 tokens);
        event Refund(address target, uint256 amount);
       
        modifier onlyBeforeEnd() {
            require(block.timestamp>=presaleStartDate && block.timestamp <= presaleEndDate,"Closed");
            _;
        }
   
        modifier onlyMoreThanMinContribution() {
            require(msg.value >= minContribution,"Amount less than the minimum contribution");
            _;
        }
   
        modifier onlyMaxCapNotReached() {
            require(amountRaisedPresale <= maxCap,"Max cap reached");
            _;
        }
   
        modifier onlyFailedPreSale() {
            require((block.timestamp>=presaleStartDate && block.timestamp >= presaleEndDate) && amountRaisedPresale < minCap ,"Closed and Presale goal not reached");
            _;
        }
   
        modifier onlyPreSaleSuccess() {
            require(block.timestamp >= presaleEndDate && amountRaisedPresale >= minCap ,"Closed and Presale goal not reached");
             _;
        }
       
        /**
       * @dev Receive function to receive funds
       */
        receive() external payable {
             buyTokens(msg.sender);
        }
   
        /**
       * @dev Buy tokens .
       * @param _beneficiary Address that will fund the smart contract and trafer the tokens
       */
        function buyTokens(address payable _beneficiary) public onlyBeforeEnd onlyMoreThanMinContribution onlyMaxCapNotReached payable {
            require(_beneficiary != address(0));
            uint256 amount=msg.value;
            (uint256 tokens,uint256 change) = _getTokenAmount(amount);
           
            uint256 acceptedFunds = amount.sub(change);
           
            if(change!=0) {
              _beneficiary.transfer(change);
            }
           
            amountRaisedPresale=amountRaisedPresale.add(acceptedFunds);
            tokens=tokens.mul(2)*1000000;
            token.transfer(_beneficiary,tokens);
            tokenSoldInPresale=tokenSoldInPresale.add(tokens);
            uint256 amountDeposited= presaleInvestors[_beneficiary];
            presaleInvestors[_beneficiary]=amountDeposited.add(acceptedFunds);
            wallet.transfer(amount);
            emit TokenPurchase(_beneficiary,acceptedFunds,tokens);
        }
       
        // Check Presale Closed
        // ==================
        function closePresale() public onlyOwner{
            presaleEndDate=block.timestamp;
        }
       
        // Token Amount
        // ==================
        function _getTokenAmount(uint256 _amount) internal view returns (uint256 count,uint256 change)
        {
            uint256 capacityLeft = presaleToken-tokenSoldInPresale;
       
            if (_amount < rate) {
              return (0, _amount);
            }
           
            count = _amount.div(rate);
            change = _amount.mod(rate);
           
            if (count >= capacityLeft) {
              change += rate * (count - capacityLeft);
              count = capacityLeft;
            }

            return (count, change);
        }
       
        // Check Presale is Closed
        // ==========================
        function checkPresaleClosed() public view returns(bool) {
            return (block.timestamp>=presaleEndDate);
        }
   
        function checkPresaleFailed() public view returns(bool) {
            return block.timestamp >= presaleEndDate && amountRaisedPresale < minCap;
        }
       
        // ReFund PreSale
        // ===========================
       
        function refundPresale() public onlyFailedPreSale {
            msg.sender.transfer(presaleInvestors[msg.sender]);
            emit Refund(msg.sender,presaleInvestors[msg.sender]);
        }
       
        // Claim amount generated from presale
        // ===========================
        function claimAmountGeneratedFromPresale() public onlyOwner onlyPreSaleSuccess{
            wallet.transfer(amountRaisedPresale);
        }
   
  
    }