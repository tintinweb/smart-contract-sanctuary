/**
 *Submitted for verification at BscScan.com on 2021-10-21
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

contract OneBuy {
    address private _owner;
    address private usdtContract;
    address private receiveAddr;
    
    uint256 private usdtAmount1;
    uint256 private usdtAmount2;
    uint256 private usdtAmount3;
    
    uint256 private leftAmount1;
    uint256 private leftAmount2;
    uint256 private leftAmount3;
    
    mapping(address => mapping(uint256 => uint256)) private buynum;
    
	constructor() {
	    _owner = msg.sender;
	    
	    usdtContract = 0x55d398326f99059fF775485246999027B3197955;
	    receiveAddr = 0xb5138fFbF2E707A2Ca04a357c68C9706F0810bca;
	    usdtAmount1 = 12000 * 10 ** 18;
	    usdtAmount2 = 500 * 10 ** 18;
	    usdtAmount3 = 500 * 10 ** 18;
	    
	    leftAmount1 = 500;
	    leftAmount2 = 140;
	    leftAmount3 = 400;
    }
	
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
	modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
    
	function withdrawErc20(address contractAddr, uint256 amount) onlyOwner public {
        IERC20(contractAddr).transfer(_owner, amount);
	}
	
	function withdrawETH(uint256 amount) onlyOwner public {
		payable(_owner).transfer(amount);
	}

    function getConfig(address addr) public view returns (address[3] memory, uint256[11] memory) {
        address[3] memory addrs = [_owner, usdtContract, receiveAddr];
        
        uint256[11] memory numbs = [
            usdtAmount1, usdtAmount2, usdtAmount3,
            leftAmount1, leftAmount2, leftAmount3, 
            buynum[addr][1], buynum[addr][2], buynum[addr][3],
            IERC20(usdtContract).balanceOf(addr),
            IERC20(usdtContract).allowance(addr, address(this))];
            
        return (addrs, numbs);
    } 
    
    function setAddrs(address usdt, address recei) onlyOwner public {
        usdtContract = usdt;
        receiveAddr = recei;
    }
    
    function setNumbs(uint256[] memory nums) onlyOwner public {
        usdtAmount1 = nums[0];
        usdtAmount2 = nums[1];
        usdtAmount3 = nums[2];
        
        leftAmount1 = nums[3];
        leftAmount2 = nums[4];
        leftAmount3 = nums[5];
    }
    
    function buyByErc20(uint256 kind, string memory name, string memory mail, uint256[] memory infos) public {
        if (kind == 1) {
            IERC20(usdtContract).transferFrom(_msgSender(), receiveAddr, usdtAmount1);
            buynum[_msgSender()][kind] += usdtAmount1;
            leftAmount1 -= 1;
        } else if (kind == 2) {
            require(buynum[_msgSender()][kind] < 1);
            
            IERC20(usdtContract).transferFrom(_msgSender(), receiveAddr, usdtAmount2);
            buynum[_msgSender()][kind] += 1;
            leftAmount2 -= 1;
        } else if (kind == 3) {
            require(infos.length > 0 && infos[0] > 0);
            IERC20(usdtContract).transferFrom(_msgSender(), receiveAddr, infos[0] * usdtAmount3);
            buynum[_msgSender()][kind] += infos[0];
            leftAmount3 -= 1;
        } 
    }
    
}