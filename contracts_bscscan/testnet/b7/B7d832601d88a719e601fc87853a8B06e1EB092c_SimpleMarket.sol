/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-02
*/

pragma solidity ^0.8.3;


// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
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
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract SimpleMarket {

        IERC20 public token;
        address public tokenOwner;
        uint256 public _decimals;
        uint256 public _ammount;
        uint256 public _price;
        uint256 public _cap;
        uint256 public _totalSale; 
        uint256 public _totalPurch; 
        uint256 public _tokenBalance;
        uint256 public _ETHBalance;
        uint256 public _totalSoldAmmount;
        uint256 public _totalBoughtAmmount;
        uint256 public _PriceGap;//in percent
        IERC20 public _BEPTokenAddress;
        bool public _canBuy = true;
        bool public _canSell = true;
        
        
        event saleProcessed(
            address aRecipient,
            uint amount,
            uint date
            );
        event reffDistProcessed(
            address rRecipient,
            uint amount,
            uint date
            );
         event trial(
            address rRecipient,
            uint eth18,
            uint eth,
            uint amount,
            uint rAmmount
            );   
        
        receive() external payable {}

        constructor (address _tokenAddr ) {
            token = IERC20(_tokenAddr);
            tokenOwner = msg.sender ;
            
            
        }
        
        
        function setSale(uint256 price, uint256 cap, uint256 decimals , uint256 PriceGap) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            _decimals = decimals;
            _price = price;//x token per BNB
            _cap = cap*10**_decimals;
            _ammount = _price * 10**_decimals;
            _PriceGap = PriceGap;
            
        }
        
        function canBuy(bool _enabled) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            _canBuy = _enabled;
            
        }
        
        function canSell(bool _enabled) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            _canSell = _enabled;
            
        }
        
        
        function checkContract() public view returns( IERC20 tokenAddr , address contractAddress, uint256 tokenBalance , uint256 ETHBalanceinWei , uint256 price ,  uint256 totalBuy , uint256 totalSell , uint256 cap){
            return(  token, address(this), token.balanceOf(address(this))/(10**_decimals) , address(this).balance , _price,  _totalBoughtAmmount/(10**_decimals) , _totalSoldAmmount/(10**_decimals) , _cap/(10**_decimals));
            
        }
        
        function buyToken(IERC20 token_IERC) public payable  {
            require(_cap > _ammount && token_IERC == token && _canBuy);
                uint256 _eth18 = msg.value;
                uint256 _tkns = (_eth18 * _ammount)/(10**18);
                
                token.transfer(msg.sender, _tkns);
                _cap = _cap - _tkns;
                _totalBoughtAmmount = _totalBoughtAmmount + _tkns;
                
                _totalPurch ++;
            
            
        }
        
        function sellToken(uint256 ammount , IERC20 token_IERC) public {
        //function sellToken(IERC20 token_IERC) public {
            require(ammount > 0, "You need to sell at least some tokens");
            require(_cap > ammount && token_IERC == token && _canSell);
                uint256 _tkns = ammount*10**_decimals;
                uint256 _ethinWei = (_tkns /_price ) * (100 - _PriceGap)/100;
                //uint256 _eth18 = _ethinWei;
                address payable Seller = payable(msg.sender);
                //address Seller = msg.sender;
                //emit trial(Seller, _tkns /_price , _ethinWei , ammount , _tkns*10**_decimals );
            require(address(this).balance > _ethinWei, "Out of BNB balance in contract");
                
                Seller.transfer(_ethinWei);
                token.transfer(Seller, _tkns);
                
                _cap = _cap - _tkns;
                
                _totalSoldAmmount = _totalSoldAmmount + _tkns;
                
                _totalSale ++;
            
            
        }
        
        //clear the sale
        function returnPresaleToOwner() public {
            require(msg.sender == tokenOwner,'Token Owner only');
            token.transfer(msg.sender, token.balanceOf(address(this)));
            //tokenOwner.transfer(msg.sender , address(this).balance);
            
            
        }
        
        //to get ETH on contract from the tokensale
        function clearETH() public {
            require(msg.sender == tokenOwner,'Token Owner only');
                address payable Owner = payable(msg.sender);
                Owner.transfer(address(this).balance);
        }
        
        //to clean stuck token in contract
        function returnBEPToOwner(IERC20 BEP20Addr ) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            _BEPTokenAddress = BEP20Addr;
            _BEPTokenAddress.transfer(msg.sender, _BEPTokenAddress.balanceOf(address(this)));
        }
    
}