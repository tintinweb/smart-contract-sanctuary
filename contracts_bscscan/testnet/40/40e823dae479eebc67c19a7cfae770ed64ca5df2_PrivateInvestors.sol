/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns(uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PrivateInvestors is Ownable{
    
    IERC20 public token;
    address[] public investors;
    mapping(address => bool) public isInvestor;
    mapping(address => int256) index;
    
    function setToken(IERC20 tokenAdd) external onlyOwner{
        token = tokenAdd;
    }
    
    function addInvestor(address account) external onlyOwner{
        require(!isInvestor[account], "Account is already an investor");
        isInvestor[account] = true;
        index[account] = int(investors.length + 1);
        investors.push(account);
    }
    
    function addInvestorsBulk(address[] memory accounts) external onlyOwner{
        for(uint256 i; i < accounts.length; i++){
            require(!isInvestor[accounts[i]], "Account is already an investor");
            isInvestor[accounts[i]] = true;
            index[accounts[i]] = int(investors.length + 1);
            investors.push(accounts[i]);
        }
    }
    
    function removeInvestor(address account) external onlyOwner{
        require(isInvestor[account], "Account is not an investor");
        isInvestor[account] = false;
        
        if (uint(index[account]) >= investors.length) return;

        for (uint i = uint(index[account]); i <investors.length-1; i++){
            investors[i] = investors[i+1];
        }
        delete investors[investors.length-1];
        investors.pop();
        index[account] = -1;
    }
    
    function distributeTokens(uint256 amount) external{
        for(uint256 i = 0; i< investors.length; i++){
            token.transferFrom(msg.sender, investors[i], amount / investors.length);
        }
    }
    
    function manualDistribute(uint256 amount) external {
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
         for(uint256 i = 0; i< investors.length; i++){
            token.transfer(investors[i], amount / investors.length);
        }
    }
    
    
    function rescueBEP20(IERC20 tokenAdd) external onlyOwner{
        tokenAdd.transfer(owner(), tokenAdd.balanceOf(address(this)));
    }
    
}