/**
 *Submitted for verification at BscScan.com on 2021-11-12
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
    mapping(uint256 => address) public investors;
    mapping(address => uint256) private _investorIndex;
    mapping(address => bool) public isInvestor;
    uint256 public index;
    
    function setToken(IERC20 tokenAdd) external onlyOwner{
        token = tokenAdd;
    }
    
    function addInvestor(address account) external onlyOwner{
        require(!isInvestor[account], "Account is already an investor");
        isInvestor[account] = true;
        investors[index] = account;
        _investorIndex[account] = index;
        index++;
    }
    
    function addInvestorsBulk(address[] memory accounts) external onlyOwner{
        for(uint256 i; i < accounts.length; i++){
            require(!isInvestor[accounts[i]], "Account is already an investor");
            isInvestor[accounts[i]] = true;
            investors[index] = accounts[i];
            _investorIndex[accounts[i]] = index;
            index++;
        }
    }
    
    function removeInvestor(address account) external onlyOwner{
        require(isInvestor[account], "Account is not an investor");
        isInvestor[account] = false;
        uint256 i = _investorIndex[account];
        investors[i] = investors[index-1];
        investors[index-1] = investors[index];
        index--;
    }
    
    function distributeTokens() external{
        uint256 amount = token.balanceOf(address(this));
        for(uint256 i = 0; i< index; i++){
            token.transfer(investors[i], amount / index);
        }
    }
    
    function rescueBEP20(IERC20 tokenAdd) external onlyOwner{
        tokenAdd.transfer(owner(), tokenAdd.balanceOf(address(this)));
    }
    
}