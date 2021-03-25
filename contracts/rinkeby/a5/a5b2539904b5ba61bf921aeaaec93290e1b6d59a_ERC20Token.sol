pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

contract ERC20Token is Context, IERC20, IERC20Metadata
{
    string private _name = "TicketCoin"; //or biff coin? like biff tanen from back to the future
    string private _symbol = "TKT";
    uint256 private _totalSupply;
    uint256 private _taxRate;
    uint256 private _ticketTransfer;
    mapping (uint256 => Ticket) private _events;
     mapping (address => mapping (address => uint256)) private _allowances;
    
    struct Ticket
    {
        uint eventID;
        uint ticketID;
    }
    struct TicketedEvent{
        uint eventID;
        string eventName;
        string eventUnixTime;
        uint totalTicketSupply;
        uint openDate;
        uint closeDate;
    }

    mapping (address => uint256) private _balances;

    constructor (string memory name_, string memory symbol_)
    {
        _name = name_;
        _symbol = symbol_;
    }
    function createTicketedEvent(string memory eventName, uint totalTicketSupply, uint openDate, uint closeDate) public view virtual returns (bool)
    {
      //  TicketedEvent tEvent = new TicketedEvent(eventName,)
    }
    function buyTicket(address buyer) public view virtual  returns(bool)
    {

    }
    function transferTicket(address from, address to) public view virtual  returns (bool)
    {
        return true;
    }
    function useTicket(uint ticketID) public view virtual  returns (bool)
    {
       
    }
    function name() public view virtual override returns (string memory)
    {
        return _name;
    }
    function symbol() public view virtual override returns (string memory)
    {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8)
    {
        return 18;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        _transfer(sender, recipient, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual
    {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    function balanceOf(address account) public view virtual override returns (uint256)
    {
        return _balances[account];
    }

    function totalSupply() public view virtual override returns(uint256)
    {
        return _totalSupply;
    }
    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[owner][spender];
    }
}