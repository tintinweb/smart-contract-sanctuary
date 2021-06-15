// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
import "./BTInterface.sol";

/**
 * @title BullToken
 * @dev Allowing transaction paying a burning fee, allowing third part transaction
 */
contract BullToken is BTInterface {
    
    // mapping between address and its balance
    mapping (address => uint256) private _balances;
    
    // mapping between address and its suspended token
    mapping (address => uint256) private _blocked_token;
    
    // mapping between owner address and allowance addresses
    mapping ( address => mapping (address =>uint256 )) private _allowances;
    
    // variabili di istanza
    address private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _burning;

    // costruiamo una sola volta, al deploy, un contratto con variabile nome, variabile simbolo, 18 decimali di default e 5^10 totalSupply
    constructor(/*string memory name, string memory symbol*/){
        _name = "Bull Token";
        _symbol = "BLL";
        _decimals = 18;
        _totalSupply = 50000000000000000000000000000;
        _owner = _msgSender();
        _balances[_owner] = _totalSupply;
    }

    function _msgSender() internal view returns (address){
        return msg.sender;
    }

    // It returns token name
    function getName() public view returns (string memory){
        return _name;
    }

    // It returns token symbol
    function getSymbol() public view returns (string memory){
        return _symbol;
    }

    // It returns token decimals
    function decimals() public view override returns(uint8){
        return _decimals;
    }
    // It returns totalSupply
    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }

    // It returns balance of the account
    function myBalance() public view override returns(uint256){
        return _balances[_msgSender()];
    }

    // It returns available balance of the account
    function myAvailableBalance() public view override returns(uint256){
        return _balances[_msgSender()] - _blocked_token[_msgSender()];
    }

    // It returns suspended token of the account
    function myBlockedToken() public view override returns(uint256){
        return _blocked_token[_msgSender()];
    }

    // trasferisce dal sender al recipient un dato amount: vedi _transfer
    function transfer (address recipient, uint256 amount) public override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // restituisce la quantità dei token che spender può spendere per conto dell'owner
    function checkGivenAllowance(address spender) public view override returns (uint256){
        return _allowances[_msgSender()][spender];
    }

    // restituisce la quantità dei token che spender può spendere per conto dell'owner
    function checkReceivedAllowance(address owner) public view override returns (uint256){
        return _allowances[owner][_msgSender()];
    }
    
    // l'owner approva un trasferimento di spender per un certo amount (spender può spendere fino a tot token)
    function allowThirdPartTransaction(address spender, uint256 amount) public override returns (bool){
        require(_balances[_msgSender()] >= amount, "You are not allowed to authorize more than your balance");
        require(_msgSender() != spender, "You're already allowed to use your token");
        
        _approve(_msgSender(), spender, amount);

        return true;
    }

    // lo spender che è stato abilitato a spendere i token può trasferire i miei token dal mio conto ad un altro conto
    function thirdPartTransaction(address sender, address recipient, uint256 amount) public override returns (bool){
        require(amount <= _allowances[sender][_msgSender()], "Amount exeeds allowance");
        
        _transferThirdPart(sender, recipient, amount);
        _approveThirdPart(sender, _msgSender(), _allowances[sender][_msgSender()]);
        _allowances[sender][_msgSender()]-= amount;
        return true;
    }

    // It increase allowance of "addedValue"
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        require(_balances[_msgSender()] >= addedValue, "It's not allowed to authorize more than your balance");
        require(_allowances[_msgSender()][spender] + addedValue <= _balances[_msgSender()], "It's not allowed to authorize more than own balance");
        _allowances[_msgSender()][spender] += addedValue;
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]);
        return true;
    }

    // It decrease allowance of "subtractedValue"
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        require(_allowances[_msgSender()][spender] - subtractedValue >= 0, "Decreased allowance below zero");
        require(_allowances[_msgSender()][spender] != 0, "You can't decrease allowance on a not allowed spender");
        _allowances[_msgSender()][spender] -= subtractedValue;
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]);
        return true;
    }

    // trasferimento dal conto del sender al recipient con burn del 0,0001% arrotondato per difetto
    function _transfer(address sender, address recipient, uint256 amount) internal{
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");
        require(_balances[sender] - _blocked_token[sender] >= amount, "You are trying to use suspended token, check your allowances");

        _burning = (mulDiv(amount,1,10000));
        require(_balances[sender] >= (amount + _burning), "Transfer amount exceeds balance plus fee");
        require(_balances[sender] - _blocked_token[sender] >= amount + _burning, "Transfer amount exceeds balance plus fee");

        _burn(sender, _burning); // fai controlli, leva i token da bruciare dal wallet del sender e li manda a adress(0)
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
        // trasferimento dal conto del sender al recipient con burn del 0,0001% arrotondato per difetto
    function _transferThirdPart(address sender, address recipient, uint256 amount) internal{
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");
        require(_blocked_token[sender] >= amount, "You are trying to use suspended token, check your allowances");

        _burning = (mulDiv(amount,1,10000));
        require(_balances[sender] >= (amount + _burning), "Transfer amount exceeds balance plus fee");
        require(_blocked_token[sender] >= amount + _burning, "Transfer amount exceeds balance plus fee");

        _burn(sender, _burning); // fai controlli, leva i token da bruciare dal wallet del sender e li manda a adress(0)
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _blocked_token[sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
    }

    // Private hidden function, to approve transfers and blocked token
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve from the zero address");
        _blocked_token[_msgSender()] = amount;

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        
    }

    // Private hidden function, to approve transfers
    function _approveThirdPart(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve from the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        
    }
    
    // It burns token decreasing totalSupply
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    // It returns percentual rounded down to previous Integer
    function mulDiv (uint x, uint y, uint z) internal pure returns (uint) {
        return (x*y/z);
}

    //when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    // will be to transferred to `to`.
    // when `from` is zero, `amount` tokens will be minted for `to`.
    // when `to` is zero, `amount` of ``from``'s tokens will be burned.
    // `from` and `to` are never both zero.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }

}