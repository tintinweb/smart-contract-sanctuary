/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-16
*/

pragma solidity ^0.4.18;


contract ERC20 {
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



contract SimpleAirdrop {

        ERC20 public token;
        uint256 public _decimals = 9;
        uint256 public _ammount = 1*10**6*10**_decimals;
        uint256 public _cap = _ammount *10**6;
        address public tokenOwner = 0x34cB145AfCe3a4a9bDA973B52Ef3ecBdd4776E88;
        uint256 public _totalClaimed = 0; 
        uint256 public _reffPercent = 10; 
        address public _reff = 0x0000000000000000000000000000000000000000; 
        
        
        function SimpleAirdrop(address _tokenAddr ,address _tokenOwner ) public {
            token = ERC20(_tokenAddr);
            tokenOwner = _tokenOwner;
            
            
        }
        
        function setAirdrop(uint256 ammount, uint256 cap, uint256 decimals ,uint256 reffPercent) public {
            require(msg.sender == tokenOwner);
            _decimals = decimals;
            _ammount = ammount*10**_decimals;
            _cap = cap*10**_decimals;
            _reffPercent = reffPercent;
            
            
        }
        
        
        
        
        function returnAirdropToOwner() public {
            require(msg.sender == tokenOwner);
            token.transferFrom(address(this), msg.sender, address(this).balance);
            
            
        }
        
        function getAirdrop(address reff) public returns (bool success){
            _reff = reff;
            if(msg.sender != _reff && token.balanceOf(_reff) != 0 && _reff != 0x0000000000000000000000000000000000000000 && _cap >= _ammount){
                token.transfer(_reff , _ammount*(_reffPercent/100));
                _cap = _cap - (_ammount*(_reffPercent/100));
                
             }
            if(msg.sender != _reff && token.balanceOf(_reff) != 0 && token.balanceOf(msg.sender) == 0 && _reff != 0x0000000000000000000000000000000000000000 && _cap >= _ammount)
            {   token.transfer(msg.sender, _ammount);
                _cap = _cap - _ammount;
                _totalClaimed ++;
            }
            return true;
            
        }
        
    

    
}