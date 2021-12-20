/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
// BEP20 Token for theGreenAir.com
// Rio Brandi - España 
pragma solidity ^0.8.4;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external  returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external  view  returns(string memory);
    function symbol() external view   returns (string memory);
    function decimals() external view  returns (uint8);
    
    function burn(address _from, uint256 _amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _name;
    string private _symbol;

    address payable public owner;
    
    uint256 public tokenPrice;

    bool public pivateSaleIsOpen = false;
    mapping (address => bool) public allowedWallet;

    mapping (address => uint256) public privateLimitWallet;

    bool public tradeIsOpen = false;
    mapping (address => bool) public contractAdmin; 
    
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
   
    constructor ( string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        tokenPrice = 0.000002 ether;
        owner = payable(msg.sender);
        contractAdmin[msg.sender] = true;
        allowedWallet[msg.sender] = true;
    }
    /* The function can be called only from the owner to let permissions to an admin address */
    function addContractSaler(address _adminUser, bool isAllowed) public returns (bool )  {
        require(contractAdmin[msg.sender], "Only Admin can act with this");
        contractAdmin[_adminUser] = isAllowed;
        return true;
    }

    /* The function allow PreSale Address to transfer token after presale closing and before Trade opening */
    function addAllowedWallet(address _wallet, bool isAllowed) public returns (bool )  {
        require(contractAdmin[msg.sender], "Only Admin can act with this");
        allowedWallet[_wallet] = isAllowed;
        return isAllowed;
    }

    function setPrivateSaleStatus( bool isOpen) public returns (bool )  {
        require(contractAdmin[msg.sender], "Only Admin can act with this");
        pivateSaleIsOpen = isOpen;
        return isOpen;
    }

   function setTokenPrice(uint256 priceWeiTokens) public  returns (bool ) {
        require(msg.sender == owner,"Only Admin can set the price");
        tokenPrice = priceWeiTokens;
        return true;
    }
    /* After Presale: buyers can sell tokens only in Public Sale in pancakeswap*/
    function openTrade() public  returns (bool ) {
        require(msg.sender == owner,"Only Admin can open Trade");
        tradeIsOpen = true;
        return true;
    }
    /* Private sale function */
    function buyToken( uint tokens) payable public  returns (bool ) {//
        uint amount = msg.value;
        require(pivateSaleIsOpen, "Private sale is closed");
        require(amount >= tokenPrice * (tokens / (10 ** uint256(_decimals))), "Wrong Token price!");
        require(privateLimitWallet[msg.sender].add(amount) <= 5 ether, "Private sale limit 5 BNB reached");
        privateLimitWallet[msg.sender] = privateLimitWallet[msg.sender].add(amount);
        _balances[owner] =  _balances[owner].sub(tokens);
        _balances[_msgSender()] = _balances[_msgSender()].add(tokens);
        emit Transfer(owner, _msgSender(), tokens);
        owner.transfer(amount);
        return true;
    }
            
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
              
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(((currentAllowance >= amount)), "GREEN: transfer amount exceeds allowance ");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance.sub(amount));
             }
        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        /* use openTrade to permit transfership */
        if(!tradeIsOpen){
        require(allowedWallet[sender] , "Trasfership is locked before presale is closed");
        }
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance.sub(amount);
        }
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply =_totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance.sub(amount);
        }
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address Owner, address spender, uint256 amount) internal virtual {
        require(Owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
   
	function burn(address _from, uint256 _amount) override external {
		require(contractAdmin[msg.sender],"Only approved address can burn");
		_burn(_from, _amount);
	}
 
}
contract GREEN_Token is ERC20 {
    
    constructor() ERC20("GreenAir", "GREEN",12)  {
        uint256 totalSupply = 1_000_000_000 * (10 ** uint256(12));
        _mint(owner,totalSupply );
    }
}