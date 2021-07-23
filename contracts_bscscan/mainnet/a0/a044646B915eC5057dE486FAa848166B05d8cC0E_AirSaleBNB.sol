/**
 *Submitted for verification at BscScan.com on 2021-07-23
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



contract AirSaleBNB {

        IERC20 public token;
        address public tokenOwner;
        uint256 public _decimals;
        uint256 public _ammount;
        uint256 public _price;
        uint256 public _cap;
        uint256 public _totalSale; 
        uint256 public _reffPercent; 
        uint256 public _reffAmmount;
        uint256 public _BNBreffPercent;
        address public _reff;
        uint256 public _tokenBalance;
        uint256 public _totalSoldAmmount;
        uint256 public _thisSaleClaimedAmmount;
        IERC20 public _BEPTokenAddress;
        
        //event trial(
        //    address rRecipient,
        //   uint ethInWei,
        //    uint ethMsgVal,
        //    uint reffpct
        //    );   
        receive() external payable {}

        constructor (address _tokenAddr ) {
            token = IERC20(_tokenAddr);
            tokenOwner = msg.sender ;
            
            
        }
        
        
        function setPresale(uint256 price, uint256 cap, uint256 decimals , uint256 reffPercent , uint256 BNBreffPct) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            _decimals = decimals;
            _price = price;//x token per BNB
            _cap = cap*10**_decimals;
            _reffPercent = reffPercent;
            _ammount = _price * 10**_decimals;
            _reffAmmount =  (_ammount * _reffPercent / 100 );
            _thisSaleClaimedAmmount = 0;
            _BNBreffPercent = BNBreffPct;
        }
        
        
        function checkContract() public view returns( address contractAddress, uint256 tokenBalance , uint256 price ,  uint256 totalSale){
            return(  address(this), token.balanceOf(address(this))/(10**_decimals) , _price,  _totalSale );
            
        }
        
        function checkContract2() public view returns( uint256 ammountPerBNB , uint256 reffAmmountPerBNB , uint256 price , uint256 cap ){
            return(  _ammount/(10**_decimals), _reffAmmount/(10**_decimals), _price, _cap/(10**_decimals) );
            
        }
        function returnPresaleToOwner() public {
            require(msg.sender == tokenOwner,'Token Owner only');
            token.transfer(msg.sender, token.balanceOf(address(this)));
            //tokenOwner.transfer(msg.sender , address(this).balance);
            
            
        }
        
        function tokenSale(address payable reff) public payable  {
            require(token.balanceOf(reff) != 0 && _cap > _ammount && reff != 0x0000000000000000000000000000000000000000 && msg.sender != reff);
                uint256 _eth18 = msg.value;
                uint256 _tkns = (_eth18 * _ammount)/(10**18);
                uint256 _refftkns = (_eth18 * _reffAmmount)/(10**18);
                require(_eth18 >= ((10/10000)*10**18),'Minimum 0,001 BNB');
                uint256 _ethinWei = ( _eth18 *_BNBreffPercent/100 );
                
                
                token.transfer(reff ,_refftkns);
                _cap = _cap - _refftkns;
                _thisSaleClaimedAmmount = _thisSaleClaimedAmmount + _refftkns;
                _totalSoldAmmount = _totalSoldAmmount + _refftkns;
                token.transfer(msg.sender, _tkns);
                reff.transfer(_ethinWei);
                _cap = _cap - _tkns;
                _thisSaleClaimedAmmount = _thisSaleClaimedAmmount + _tkns;
                _totalSoldAmmount = _totalSoldAmmount + _tkns;
                
                _totalSale ++;
            
            
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