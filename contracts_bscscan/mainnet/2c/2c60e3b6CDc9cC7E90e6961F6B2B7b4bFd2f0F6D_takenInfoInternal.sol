pragma solidity >= 0.5.0 < 0.6.0;

import "./TokenInfoLib.sol";
import "./SafeMath.sol";

contract takenInfoInternal {
    
    using TokenInfoLib for TokenInfoLib.TokenInfo;

    struct Account {
		mapping(address => TokenInfoLib.TokenInfo) tokenInfos;
		bool active;
	}
	
	mapping(address => Account) accounts;
	address public controller;
	address public gov;
	address[] public activeAccounts;
	
	event TransferController(address newController);
	
	constructor() public {
        controller = msg.sender;
        gov = msg.sender;
    }
    
    
    function transferController(address newController) public {
        require(msg.sender == controller || msg.sender == gov , "!Owner");
        require(newController != address(0), "Ownable: new owner is the zero address");
       controller = newController;
       
       emit TransferController( newController);
    }
    
	
	modifier onlyOwner () {
        require(msg.sender == controller || msg.sender == gov, "!controller");
        _;
    }
    
    function getActive(address accountAddr) public view returns(bool) {
        return accounts[accountAddr].active;
    }
    
    function setActive(address accountAddr, bool act) public onlyOwner {
        accounts[accountAddr].active = act;
    }
    
    
    function getTotalAmount(address accountAddr, address tokenAddress) public view returns(int256) {
        return accounts[accountAddr].tokenInfos[tokenAddress].totalAmount(block.timestamp);
    }
    
    function getTokenNumbers(address tokenAddress,address account)public view returns (int256 amount) {
		return accounts[account].tokenInfos[tokenAddress].totalnumber();
	}
	
	function addAmount(address account,address tokenAddress,  uint256 amount, uint256 rate, uint256 currentTimestamp)public onlyOwner returns(int256){
		return accounts[account].tokenInfos[tokenAddress].addAmount(amount, rate, currentTimestamp);
	}
	
	function minusAmount(address account,address tokenAddress,  uint256 amount, uint256 rate, uint256 currentTimestamp)public onlyOwner{
		accounts[account].tokenInfos[tokenAddress].minusAmount(amount, rate, currentTimestamp);
	}
	
	//
	function getCurrentTotalAmount(address accountAddr, address tokenAddress) public view returns(int256) {
        return accounts[accountAddr].tokenInfos[tokenAddress].getCurrentTotalAmount();
    }
    
    function getCurrentRate(address accountAddr, address tokenAddress) public view returns(uint256) {
        return accounts[accountAddr].tokenInfos[tokenAddress].currentrate();
    }
    
    function setActiveAccountse(address accountAddr) public onlyOwner {
        activeAccounts.push(accountAddr);
    }
    
    function getActiveAccountse() public view returns(address[] memory) {
        return activeAccounts;
    }
    
}