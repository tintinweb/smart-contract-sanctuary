/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract SwapEth2Ams {
    //AMS contract address
    IERC20 public amsContract;
    //one buyer max buy amount
    uint256 public constant MAX_BUY_AMOUNT = uint256(1000)*(uint256(10)**18);
    //swap price 1(ETH) = 10000(AMS)
    uint256 public constant ETH_PRICE = 10000;
    
    //sellers valid withdraw cash amount 
    mapping(address => uint256) private _sellers;
    //buyers vliad left buy amount
    mapping(address => uint256) private _buyers;
    
    //event logs
    event Swap(address seller, address buyer, uint256 valueEth, uint256 valueAms);
    event WithdrawEther(address indexed fromAddress, uint256 valueEth);
    
    constructor(IERC20 amsAddress) {
        amsContract = amsAddress;
    }
    
    function swap(address seller) public payable {
        uint256 amount = msg.value * ETH_PRICE;
        // require(_buyers[msg.sender] > amount, "Swap: left buy ams amount not enough");
        uint256 sellerAmount = amsContract.allowance(seller, address(this));
        require(sellerAmount >= amount, "Swap: seller ams amount not enough");
        bool transAmsState = amsContract.transferFrom(seller, msg.sender, amount);
        require(transAmsState == true, "Swap: seller unable to transfer ams");
        unchecked {
            _sellers[seller] += msg.value;
            _buyers[msg.sender] += amount;
        }
        emit Swap(seller, msg.sender, msg.value, amount);
    }

    function withdrawEther(address payable recipient) public {
        require(_sellers[recipient] > 0, "WithdrawEther: ETH sold is not enough to withdraw cash");
        uint amount = _sellers[recipient];
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        _sellers[recipient] = 0;
		emit WithdrawEther(recipient, amount);
    }
       
    function getBalanceEther() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getSllerEther(address seller) public view returns (uint256) {
        return _sellers[seller];
    }   
        
    function getLeftBuyAmount(address buyer) public view returns (uint256) {
        return _buyers[buyer];
    }    
    
    function getLeftSellAmount(address seller) public view returns (uint256) {
        return amsContract.allowance(seller, address(this));
    }
}