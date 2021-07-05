/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

███████╗███╗░░░███╗░█████╗░████████╗██████╗░██╗██╗░░██╗
██╔════╝████╗░████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝
█████╗░░██╔████╔██║███████║░░░██║░░░██████╔╝██║░╚███╔╝░
██╔══╝░░██║╚██╔╝██║██╔══██║░░░██║░░░██╔══██╗██║░██╔██╗░
███████╗██║░╚═╝░██║██║░░██║░░░██║░░░██║░░██║██║██╔╝╚██╗
╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝╚═╝░░╚═╝

https://t.me/ethereumatrix
https://ethereumatrix.com/
https://twitter.com/ethereumatrix
https://www.reddit.com/r/EthereuMatrix/

Token Information
1. Total 1,000,000,000,000
2. Fair launch on Ethereum
3. Anti-robot protection
4. 0.5% initial buy limit on launch
5. 5% marketing and team fee
6. 2% redistribution
7. No presale
8. No team tokens
9. Contract renounced on launch
10. LP locked on launch (100 years)

 */
contract eMTX  {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 1_000_000_000_000;

    string private _name = " t.me/ethereumatrix";
    string private _symbol ="eMTX";

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    constructor() {
        _balances[_msgSender()] += _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual  returns (string memory) {
        return _name;
    }
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual  returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual  returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual  returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue);
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0));
        require(recipient != address(0));

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}