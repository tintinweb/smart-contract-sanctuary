/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface ERC20Interface {
    function getTotalSupply() external view returns(uint256);
    function getBalance(address accountNo) external view returns(uint256);
    function getAllowance(address owner, address spender) external view returns (uint256);
     
    function transferAmount(address recipient, uint256 amount) external returns(bool);
    function approveTransaction(address spender, uint256 amount) external returns(bool);
    function transferFromSender(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed fromAddress, address indexed toAddress, uint256 value);
    event Approval(address indexed ownerAddress, address indexed spenderAddress, uint256 value);
}
 
 contract bkToken is ERC20Interface{
     string public tokenSymbol;
     string public tokenName;
     uint8 public decimals;
     uint public _totalSupplyOfToken;
     address public tokenOwner;

     mapping(address=>uint) private _tokenBalance;
     mapping(address => mapping(address => uint256)) private _allowances;
     constructor() public {
     tokenOwner=msg.sender;
     tokenSymbol = "PRR";
     tokenName= "PREE1.0 Fixed Supply Token";
     decimals=18;
     _totalSupplyOfToken=1000000 * 10**(decimals);
     _tokenBalance[tokenOwner]= _totalSupplyOfToken;
     emit Transfer(address(0),tokenOwner,_totalSupplyOfToken);
     }

     function getTotalSupply() public view override returns (uint256) {
            return _totalSupplyOfToken;
     }
       function getBalance(address accountno) public view override returns (uint256) {
        return _tokenBalance[accountno];
    } 
    function getAllowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function transferAmount(address recipient, uint256 amount) public virtual override returns (bool){
        address sender=msg.sender;
        _tokenBalance[sender]=_tokenBalance[sender] - amount;
        _tokenBalance[recipient]=_tokenBalance[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;

        }

    function approveTransaction(address spender, uint256 amount) public virtual override returns (bool) {
        address approver = msg.sender;
        
        _allowances[approver][spender] = amount;
        emit Approval(approver, spender, amount);
        return true;
    }

     function transferFromSender(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _tokenBalance[sender] = _tokenBalance[sender] - amount;
        _tokenBalance[recipient] = _tokenBalance[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        
        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
        return true;
    }

 }