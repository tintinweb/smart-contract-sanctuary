/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity ^0.5.0;
//https://etherscan.io/token/0x0d8775f648430679a709e98d2b0cb6250d2887ef

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address tokenOwner) external view returns (uint256 balance);
  function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
  function transfer(address to, uint256 tokens) external returns (bool success);
  function approve(address spender, uint256 tokens) external returns (bool success);
  function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
  function burnTokens(uint256 _amount) external;
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

//WRITE CONTRACT
contract Froze {
    // public values
    uint256 public totalFroze;
    uint256[] lockedblocks;
    uint256[] lockedfunds;
	IERC20 public TokenContract;
	address public TokenReceiver;
    
	function nextBlockOn() public view returns (uint256 blockNumber) {
        return lockedblocks[0];
    }
	
	function nextAmountOn() public view returns (uint256 amountFroze) {
		return lockedfunds[ lockedblocks[0] ];
    }
	
	function AmountOnBlockNum(uint256 block_num) public view returns (uint256 amountFroze) {
		return lockedfunds[ block_num ];
    }
	
	function AddLock(uint256 block_num, uint256 value) public isOwner {
	  require(value > 0, "Amount is too low");
	  require(block.number < block_num, "Block is too low");
	  require(lockedfunds[block_num] <= 0, "Block lock exist");
      lockedblocks[lockedfunds.length + 1] = block_num;
	  lockedfunds[block_num] = value;
	  totalFroze += value;
    }
	
	function SetLock(IERC20 _TokenContract, address _TokenReceiver) public isOwner {
      TokenContract = _TokenContract;
      TokenReceiver = _TokenReceiver;
    }
	
	function UnLock() public {
	  require(lockedblocks.length > 0, "Dont exist locked blocks");
	  uint256 block_num_lock = lockedblocks[0];
	  require(block.number < block_num_lock, "Block is too low");
	  uint256 amount = lockedfunds[block_num_lock];
	  require((totalFroze -= amount) > 0, "Frozen amount is too low");
	  totalFroze -= amount;
	  TokenContract.transfer(address(TokenReceiver), amount);
	}
	
	//OWNER
	address private owner;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }
    
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}