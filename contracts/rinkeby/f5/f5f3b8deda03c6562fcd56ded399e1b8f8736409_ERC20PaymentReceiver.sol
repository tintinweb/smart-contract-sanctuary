/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

//SPDX-License-Identifier: UNLICENSED
 
 

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
    return msg.sender;
}

    function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
}
}


contract ERC20PaymentReceiver is Context, IERC20 {
    mapping(address => uint256) private _balances;

     address public owner;
     IERC20 public tokenAddress;
   
    constructor(IERC20 _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender ;
    }
    modifier onlyOwner{
        require (owner == msg.sender);
        _;
        
    }
    
    
    
function balanceOf(address account) external override view virtual  returns (uint256) {
        return _balances[account];
    }
    
    
    

function withdraw(address to, address _tokenAddress , uint256 _amount) public onlyOwner returns(bool) {
    IERC20(_tokenAddress).transfer(to , _amount);
    return true;
}


function getBalanceOfToken(address _tokenAddress) public  view returns (uint256) {
  return IERC20(_tokenAddress).balanceOf(address(this));
}
    function transfer(address recipient, uint256 amount) public onlyOwner override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
}
 
 
   
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

         
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }   
    
 
}