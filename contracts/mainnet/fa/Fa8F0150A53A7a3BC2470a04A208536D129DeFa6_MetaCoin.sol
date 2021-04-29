/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// This is just a experimental contract called RoundByRound (♻)
// =============================================================
// * There are 16 tokens that are being sold in circulations
// * all tokens has the same price (begin with 300 wei)
// * A token can be bought, but not sold or transferred
// * Every time 16 tokens have been sold, a new round begins
// * At the beginning of each round, the price of all tokens increases
//
// What happens with Token 0 at Round 1 ? Token 0 has already a holder?!
// * The current owner of Token 0 will receive 2/3 of the current price and the token will be transferred to the new holder
// * Example: Token 0 was bought at Round 0 for 300wei. The next Round (1) will increase the price to 900wei
// *          Once Token 0 got sold the current owner receive 600wei. (+100%)
//
// So u telling me by just put my ETH into this experiment i will get 100% of my invest back when my token is sold?
// * YES, well... no :D You can only invest the value which was given by the current price function... but yes :)
// * Round 0 starts with  300 wei which are 0,0000000000000003 ETH
// * Round 1 starts with  900 wei which are 0,0000000000000009 ETH
// * Round 2 starts with 2700 wei which are 0,0000000000000027 ETH ...
//
// Are there events out ?
// * Yes, there are 3 events fired, "Transfer", "NewRound", "Reward"
//
// Sound strange, where is the source code ?
// * Checkout Etherscan, contract tab. The whole contract is published!
//
// Ookay u got me, how can i play these stupid game ?
// * there is no interface available, you need a little bit of knowledge.
// * Contract: 0xFa8F0150A53A7a3BC2470a04A208536D129DeFa6
// * Open the Read Contract tab: https://etherscan.io/address/0xFa8F0150A53A7a3BC2470a04A208536D129DeFa6#readContract
// * Get the current Price
// * Open the Write Contract tab: https://etherscan.io/address/0xFa8F0150A53A7a3BC2470a04A208536D129DeFa6#writeContract
// * Call buyIndex with the correct price value.
// * thats it, now just wait until your token is sold again :)


pragma solidity >=0.4.25 <0.7.0;

contract MetaCoin {
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	uint256 public price = 300;  // Round 0 start at 300 wei
	uint256 public round = 0;
	uint256 public currentIndex = 0;

	address payable private owner;

	mapping (uint => address payable) index2Address;
	mapping (address => uint) address2Index;

	event Transfer(address indexed _from, address indexed _to, uint256 _pixelId);
	event NewRound( uint256 _price, uint256 _roundNumber);
	event Reward(address indexed _to, uint256 _value);

	constructor() public {
		owner = msg.sender;
		name = "RoundByRound";
		symbol = "♻";
		decimals = 0;
		totalSupply = 15;
	}

	function buyIndex() public payable {
		require(msg.value >= price, "price invalid");

		address payable _holder = index2Address[currentIndex];

		if (_holder != address(0x0)){
			uint _reward = (price / 3) * 2;
			_holder.transfer(_reward);	//send the current owner 2/3 of the value
			emit Reward(_holder, _reward);
		}

		emit Transfer(_holder, msg.sender, 1);

		address2Index[msg.sender] = currentIndex;
		index2Address[currentIndex] = msg.sender;

		//next round starts!
		if(currentIndex == totalSupply){
			currentIndex = 0;
			round++;
			price = price * 3;					//new round, new price

			emit NewRound(price, round);
		}else{
			currentIndex++;						//increase index
		}
	}

	function ownerOf(uint id) public view returns( address ) { return index2Address[id]; }

	function withdraw(uint256 _amount) public {
		require(msg.sender == owner);
		msg.sender.transfer(_amount);
	}
}