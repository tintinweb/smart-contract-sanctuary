pragma solidity ^0.4.24;

/**
 * @title IERC20Token - erc20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract IERC20Token {
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	

	function balanceOf(address _owner) public constant returns (uint256 balance); //Get the account balance of another account with address _owner
	function transfer(address _to, uint256 _value) public returns (bool success); //Send _value amount of tokens to address _to
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success); //Send _value amount of tokens from address _from to address _to
	function approve(address _spender, uint256 _value) public returns (bool success); //Allow _spender to withdraw from your account, multiple times, up to the _value amount. If this function is called again it overwrites the current allowance with _value.
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining); //Returns the amount which _spender is still allowed to withdraw from _owner

	event Transfer(address indexed _from, address indexed _to, uint256 _value); // Triggered when tokens are transferred.
	event Approval(address indexed _owner, address indexed _spender, uint256 _value); //Triggered whenever approve(address _spender, uint256 _value) is called.
}

/* title Moscat
 * @dev 
 */
contract Moscat {
	struct Cat {
		uint256 catId;
		uint256 tail;
		uint256 body;
		uint256 head;
		uint256 leg;
		uint256 scale;
		uint256 birth;
	}
	
	struct Trade {
		uint256 price;
		uint256 startTime;
		address creator;
		address buyer;
		bool isFinished;
	}

	Cat[] public cats;
	Trade[] public trades;
    
    address tokenaddress = 0x1742c81075031b8f173d2327e3479d1fc3feaa76;

    IERC20Token public mossToken = IERC20Token(tokenaddress);

	mapping (uint => address) public catToOwner;
	mapping (uint => bool) public canTransfer;
	mapping (uint => Trade) public catToTrade;



	event RegisterCat(uint256 catId, uint256 tail, uint256 body, uint256 head, uint256 leg, uint256 scale, uint birth);

	modifier checkTransfer(uint256 catId){
		require(catId != 0);
		require(catToOwner[catId] == msg.sender);
		require(validateTransfer(catId));
		_;
	}

    function validateTransfer(uint256 catId) internal view returns (bool){
		if (canTransfer[catId] == true){
			return true;
		}
		return false;
	}	

	function registerCat(uint256 _catId, uint256 _tail, uint256 _body, uint256 _head, uint256 _leg, uint256 _scale) public {
		require(catToOwner[_catId] == address(0));
		
		cats.push(Cat(_catId, _tail, _body, _head, _leg, _scale,now));
		catToOwner[_catId] = msg.sender;
		canTransfer[_catId] = true;
		emit RegisterCat(_catId, _tail, _body, _head, _leg, _scale, now);
	}
	
	function createTrade(uint256 _catId, uint256 _price) public checkTransfer(_catId){
		require(msg.sender == catToOwner[_catId]);
		trades.push(catToTrade[_catId] = Trade(_price, now, msg.sender, address(0), false));
	}
	
	function buyCat(uint256 _catId) public {
		require(catToTrade[_catId].price <= mossToken.balanceOf(msg.sender));
		require(catToTrade[_catId].buyer == address(0));
		uint256 amountToken = mossToken.allowance(msg.sender, address(this));
		require(amountToken == catToTrade[_catId].price);
		mossToken.transferFrom(msg.sender ,address(this), amountToken);
		catToTrade[_catId].buyer = msg.sender;
		catToTrade[_catId].isFinished = true;
		catToOwner[_catId] = msg.sender;
	}
	
	function receiveToken(uint256 _catId) public {
	    require(catToTrade[_catId].creator == msg.sender);
	    if(mossToken.balanceOf(address(this)) > 0){
            mossToken.transfer(msg.sender, catToTrade[_catId].price);
	    }
	}
}