/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//"SPDX-License-Identifier:UNLICENSED"
pragma solidity ^0.8.0;

interface IERC20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ZeeTocken is IERC20{
 
    mapping (address => uint256) private _balances;
  
    mapping (address => mapping (address => uint256)) private _allowances;
  
    uint256 private _totalSupply;

    address public owner;
    
    string public name;
  
    string public symbol;
  
    uint public decimals;
 
    uint private tockenPrice = 10000000000000000;
 
    constructor ()  {
        name = "Zee Tocken";
        symbol = "Z";
        decimals = 16;  //1  - 1000 PKR 1 = 100 Paisa 2 decimal
        owner = msg.sender;
        
        //1 million tokens to be generated
        _totalSupply = 1000000 * 10**decimals; //exponenctial farmola
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
     }
   
    function changeTockenPrice(uint nPrice) public {
        require(msg.sender == owner, "only owner can change price");
        require(nPrice > 0,"price must be greater than zero");
        tockenPrice = nPrice;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "Not a valid sender address");
        require(recipient != address(0), "Not a valid recipient address");
        require(_balances[sender] > amount,"transfer amount exceeds balance");

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender] - amount;
        
        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender]; //return allowed amount
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), "BCC1: approve from the zero address");
        require(spender != address(0), "BCC1: approve to the zero address");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender]; //how much allowed
        require(_allowance > amount, "BCC1: transfer amount exceeds allowance");
        
        //deducting allowance
        _allowance = _allowance - amount;
        
        //--- start transfer execution -- 
        
        //owner decrease balance
        _balances[tokenOwner] =_balances[tokenOwner] - amount; 
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }
   
   function buyTocken(uint _tockens) public payable returns (bool) {
       
       require(_tockens > 0 && _tockens < _totalSupply, "number of tokens are not valid");
       require(msg.value >= (_tockens*tockenPrice), "amount of ether is not valid");
       
        _balances[owner] = _balances[owner] - _tockens;
        
        //increase the balance of token recipient account
        _balances[msg.sender] = _balances[msg.sender] + _tockens;

        emit Transfer(owner, msg.sender, _tockens);
        return true;

       
         }
   receive() external payable  {
   
  buyTocken(msg.value/tockenPrice);
   }
   
    fallback() external payable {
        buyTocken(msg.value/tockenPrice);
   }

}