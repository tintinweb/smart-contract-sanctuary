/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract Brige is Ownable{
    uint public pounge;
    IERC20 public token;
    string public name;
    event Cross(address indexed addr_,uint indexed amount_);
    event SendToken(address indexed addr_, uint indexed amount_);
    
    function setPounge(uint com_) public onlyOwner{
        pounge = com_;
    }
    
    function setToken(address addr_) public onlyOwner {
        token = IERC20(addr_);
    }
    
    function cross(uint amount_) public payable {
        require(msg.value >= pounge,'too low');
        token.transferFrom(msg.sender,address(this),amount_);
        emit Cross(msg.sender,amount_);
    }
    
    function claimMain(address addr_) public onlyOwner {
        payable(addr_).transfer(address(this).balance);
    }
    function claimToken(address addr_) public onlyOwner {
        token.transfer(addr_,token.balanceOf(address(this)));
    }
    function sendToken(address addr_, uint amount_) public onlyOwner {
        token.transfer(addr_,amount_);
        emit SendToken(addr_,amount_);
    }
    function setName(string memory com_) public onlyOwner{
        name = com_;
    }
    
}