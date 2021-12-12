/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MTKico {
    address _owner;
    uint private _startdate;
	/*30 Days presale*/
    uint private _enddate = 30*24*60*60;
	/* Tokens per wei ( 1 wei = 10000 Token wei) */
	uint private _price = 100000;
	string private _name;
	
	address private _devFund;
	
	IERC20 public token = IERC20(0xEC83Dff37A0A430E6909342af426Bf0766f2728A);
	
	constructor(){
		_name = "MTK1 ICO";
		_owner = msg.sender;
		_startdate = block.timestamp;
		
		_devFund = 0xEa19d7F16f85e963721816383484b8DFd9c4F834;
	}
	
	modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        // This _; is not a TYPO, It is important for the compiler;
        _;
    }
	
	function name() external view returns (string memory){
		return _name;
	}
	
    receive () external payable {
		uint256 now1 = block.timestamp;
        require((now1 > _startdate && now1 < _startdate + _enddate), "Presale ICO Ended!");
		
		uint256 amt = msg.value;
		amt = amt * _price;
		require( token.balanceOf( address(this) ) >= amt, "Dex Doesnot have enough balance");
		
        payable(_owner).transfer(msg.value);
        token.transfer(msg.sender, amt);
    }
	
	function price() external view returns (uint256){
		return _price;
	}
	
	function start() external view returns (uint256){
		return _startdate;
	}
	
	/* Useful in case wrong tokens are recieved */
	function retrieveTokens(address _token, address recipient, uint256 amount) public onlyOwner{
		_retrieveTokens(_token, recipient, amount);
	}
	
	function _retrieveTokens(address _token, address recipient, uint256 amount) internal{
		require(amount > 0, "amount should be greater than zero");
		IERC20 erctoken = IERC20(_token);
		erctoken.transfer(recipient, amount);
	}
	
	function changetokenAddress(address newTA) public onlyOwner{
		token = IERC20(newTA);
	}
	
	function changeDevFundAddress(address newDF) public onlyOwner{
		_devFund = newDF;
	}
}