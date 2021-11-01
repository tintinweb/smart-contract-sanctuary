/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface IERC20{
    function totalSuplly() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);

    function transfer(address _to, uint _token) external returns(bool);
    function approve(address spender, uint256 _token) external returns(bool);
    function tranferFrom(address _from, address _to, uint _token) external returns(bool);

    event Transfer(address indexed _from,address indexed _to, uint256 _token);
    event Approval(address indexed owner, address indexed spender, uint _token);
    }
abstract contract Context{
    function _msgSender() internal view virtual returns(address){
        return msg.sender;
    }
    function _msgData() internal view virtual returns(bytes calldata){
        return msg.data;
    }    
}
interface IERC20METADATA{
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
    function decimal() external view returns(uint8);
}
contract ERC20 is Context,IERC20,IERC20METADATA{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address=>uint256)) private _allowance;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    constructor(){
        _name="DanishERC20";
        _symbol= "DET";
        _totalSupply= 10000000000000000000000000;
    }

    function symbol() public view virtual override returns(string memory){
        return _symbol;
    }

    function name() public view virtual override returns(string memory){
        return _name;
    }

    function decimal() public view virtual override returns(uint8){
        return 18;
    }

    function totalSuplly() public view virtual override returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override  returns(uint256){
        return _balances[account];
    }

    function allowance(address owner, address spender)public view virtual override returns(uint256){
        return _allowance[owner][spender];
    }

    function transfer(address _to, uint _token) public virtual override returns(bool){
        _transfer(_msgSender(),_to, _token);
        return true;
    }

    function approve(address spender, uint256 _token) public virtual override returns(bool){
        _approve(_msgSender(),spender,_token);
        return true;    
    }

    function tranferFrom(address _from, address _to, uint _token)  public virtual override  returns(bool){
        _transfer(_from,_to, _token);
        uint256 currentAllowance = _allowance[_from][_msgSender()];
        require(currentAllowance >= _token, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_from,_msgSender(),currentAllowance - _token);
        }
        return true;
    }
    function _transfer(address _from,address _to, uint _amount)internal virtual{
        require(_from != address(0), "ERC20: transfer from address 0");
        require(_to != address(0), "ERC20: transfer to address 0");
        _beforeTokenTransfer(_from,_to, _amount);
        uint256 senderBalance = _balances[_from];
        require(senderBalance >=_amount,"ERC20: transfer token exceeding the limits");
        unchecked {
            _balances[_from] = senderBalance - _amount;
        }
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount); 
        _afterTokenTransfer(_from,_to, _amount);
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowance[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner,address spender, uint256 _token)internal virtual{
        require(owner != address(0), "ERC20: transfer from address 0");
        require(owner != address(0), "ERC20: transfer to address 0");
        _allowance[owner][spender]=_token;
        emit Approval(owner, spender, _token);
    }

    function _mint(address _account, uint256 _amount)internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), _account, _amount);
        _totalSupply+=_amount;
        _balances[_account]+=_amount;
         emit Transfer(address(0), _account, _amount);
    }
    function _burn(address _account, uint256 _amount)internal virtual{
        require(_account != address(0), "ERC20: burn from the zero address");
         _beforeTokenTransfer(address(0), _account, _amount);
         uint256 accountBalance = _balances[_account];
         require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");
         unchecked {
            _balances[_account]= accountBalance - _amount;
           
         }
        _totalSupply -= _amount;
        emit Transfer(_account, address(0), _amount);
        _afterTokenTransfer(_account, address(0), _amount);
    }
    function _beforeTokenTransfer(address _from,address _to, uint _token)internal virtual{}

    function _afterTokenTransfer(address _from,address _to, uint _token)internal virtual{}
}