/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CrossChain {
    address  private _owner;
    uint256  private _ethfee;
    
    event DoCrossEvent(address indexed coinContract, string indexed tochain, string indexed toaddr, uint256 amount);
    
	constructor() {
	    _owner = msg.sender;
	    _ethfee = 0;
    }
	
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
	modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }
    
    function resetOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
    
    function resetEthfee(uint256 ethfee) public onlyOwner {
        _ethfee = ethfee;
    }
    
	function withdrawErc20(address contractAddr, uint256 amount) onlyOwner public {
        IERC20(contractAddr).transfer(_owner, amount);
	}
	
	function withdrawETH(uint256 amount) onlyOwner public {
		payable(_owner).transfer(amount);
	}
    
    function getConf() public view returns (uint256, address) {
        return (_ethfee, _owner);
    }
    
    function doCross(address coinContract, string memory tochain, string memory toaddr, uint256 amount) public payable
            returns (address, address, string memory, string memory, uint256) {
        require(amount > 0);
        require(msg.value >= _ethfee);
        
        IERC20(coinContract).transferFrom(_msgSender(), address(this), amount);
        
        emit DoCrossEvent(coinContract, tochain, toaddr, amount);
        
        return (_msgSender(), coinContract, tochain, toaddr, amount);
    }
}