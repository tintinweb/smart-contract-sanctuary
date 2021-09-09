/**
 *Submitted for verification at BscScan.com on 2021-09-09
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



contract MAirSaleBNB {
        
        struct Token {
            IERC20  token;
            uint256  _decimals;
            uint256  _ammount;
            uint256  _price;
            uint256  _cap;
            uint256 _totalGet; 
            uint256 _reffPercent; 
            uint256 _reffAmmount;
            uint256 _tokenBalance;
            uint256 _totalGetAmmount;
            uint256 _thisGetClaimedAmmount;
        }
        mapping (IERC20 => Token) Tokens;
        uint _BNBreffPercentSTD;
        address public tokenOwner;
        address public _reff;
        bool public _BNBbonus = true;
        IERC20 public _BEPTokenAddress;
        IERC20[] public _addresses;
        
        //event trial(
        //    address rRecipient,
        //   uint ethInWei,
        //    uint ethMsgVal,
        //    uint reffpct
        //    );   
        receive() external payable {}

        constructor () {
        
            tokenOwner = msg.sender ;
            
            
        }
        
        function preSetReffPerc(uint BNBreffPct,bool BNBbonus) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            _BNBreffPercentSTD = BNBreffPct;
            _BNBbonus = BNBbonus;
        }
        
        
        function preSet(IERC20 _tokenAddr,uint256 price, uint256 cap, uint256 decimals , uint256 reffPercent , uint256 BNBreffPct) public {
            require(msg.sender == tokenOwner,'Token Owner only');
            Tokens[_tokenAddr].token = _tokenAddr;
            Tokens[_tokenAddr]._decimals = decimals;
            Tokens[_tokenAddr]._price = price;//x token per BNB
            Tokens[_tokenAddr]._cap = cap*10**Tokens[_tokenAddr]._decimals;
            Tokens[_tokenAddr]._reffPercent = reffPercent;
            Tokens[_tokenAddr]._ammount = Tokens[_tokenAddr]._price * 10**Tokens[_tokenAddr]._decimals;
            Tokens[_tokenAddr]._reffAmmount =  (Tokens[_tokenAddr]._ammount * Tokens[_tokenAddr]._reffPercent / 100 );
            Tokens[_tokenAddr]._thisGetClaimedAmmount = 0;
            _BNBreffPercentSTD = BNBreffPct;
        }
        
        
        function checkContract(IERC20 _tokenAddr) public view returns(  IERC20 tokenAdr,uint256 tokenBalance , uint256 price ,  uint256 totalGet, uint256 ammountPerBNB, uint256 reffAmmountPerBNB ){
            return(  Tokens[_tokenAddr].token, Tokens[_tokenAddr].token.balanceOf(address(this))/(10**Tokens[_tokenAddr]._decimals) , Tokens[_tokenAddr]._price,  Tokens[_tokenAddr]._totalGet, Tokens[_tokenAddr]._ammount/(10**Tokens[_tokenAddr]._decimals),Tokens[_tokenAddr]._reffAmmount/(10**Tokens[_tokenAddr]._decimals));
            
        }
        
        
        
        
        
        function manyAirdrop(IERC20[] memory _tokenAddreses,uint maxSlot, address payable reff) public payable  {
            _addresses = _tokenAddreses;
            uint256 _eth18 = msg.value;
            require(_eth18 >= ((10/10000)*10**18),'Minimum 0,001 ');
            for (uint i=0 ; i < maxSlot; i++){
            require(Tokens[_addresses[i]].token.balanceOf(reff) != 0 && Tokens[_addresses[i]]._cap > Tokens[_addresses[i]]._ammount && reff != 0x0000000000000000000000000000000000000000 && msg.sender != reff);
                //uint256 _eth18 = msg.value;
                uint256 _tkns = (_eth18 * Tokens[_addresses[i]]._ammount)/(10**18)/maxSlot;
                uint256 _refftkns = (_eth18 * Tokens[_addresses[i]]._reffAmmount)/(10**18)/maxSlot;
                
                //uint256 _ethinWei = ( _eth18 * Tokens[_addresses[i]]._BNBreffPercent/100 );
                
                
                Tokens[_addresses[i]].token.transfer(reff ,_refftkns);
                Tokens[_addresses[i]]._cap = Tokens[_addresses[i]]._cap - _refftkns;
                Tokens[_addresses[i]]._thisGetClaimedAmmount = Tokens[_addresses[i]]._thisGetClaimedAmmount + _refftkns;
                Tokens[_addresses[i]]._totalGetAmmount = Tokens[_addresses[i]]._totalGetAmmount + _refftkns;
                Tokens[_addresses[i]].token.transfer(msg.sender, _tkns);
                
                Tokens[_addresses[i]]._cap = Tokens[_addresses[i]]._cap - _tkns;
                Tokens[_addresses[i]]._thisGetClaimedAmmount = Tokens[_addresses[i]]._thisGetClaimedAmmount + _tkns;
                Tokens[_addresses[i]]._totalGetAmmount = Tokens[_addresses[i]]._totalGetAmmount + _tkns;
                
                Tokens[_addresses[i]]._totalGet ++;
            
            }
            uint256 _ethinWei = ( _eth18 * _BNBreffPercentSTD/100 );
            if (_BNBbonus == true){
            reff.transfer(_ethinWei);}
                
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