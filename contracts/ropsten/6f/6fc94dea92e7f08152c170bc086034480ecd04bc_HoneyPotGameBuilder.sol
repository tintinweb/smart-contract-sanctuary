/**
****
****      ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
****     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
****     ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ 
****     ▐░▌          ▐░▌          ▐░▌          ▐░▌       ▐░▌    ▐░▌          ▐░▌     
****     ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌    ▐░▌          ▐░▌     
****     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░▌     ▐░▌          ▐░▌     
****      ▀▀▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░▌          ▐░█▀▀▀▀▀▀▀█░▌    ▐░▌          ▐░▌     
****               ▐░▌▐░▌          ▐░▌          ▐░▌       ▐░▌    ▐░▌          ▐░▌     
****      ▄▄▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▄▄▄▄█░█▄▄▄▄      ▐░▌     
****     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     
****      ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀      
****                                                                                  
**** Created by SECBIT.  https://secbit.io
****
**** Github:  https://github.com/sec-bit      
**** Twitter: @SECBIT_IO
****
*/
pragma solidity ^0.4.18;

contract GameContract{
	GameBuilder private mainContract;
	constructor() public payable{
		mainContract=GameBuilder(msg.sender); 
	}

	function submit() public returns (bool){
		require(isPass());
		return mainContract.submit();
	}

	function isPass() view returns (bool);
}

contract GameBuilder{
	// player => game contract
	mapping(address => address) public playContract ;
	// player => is winner?
	mapping(address => bool) public isWinned;
	// winners
	address[] public winnerList;
	// winner count
	uint public winnerNums=0;

	constructor() public payable{
	}

	function() payable{
	
	}

	function submit() public returns (bool){
		require(playContract[tx.origin] != address(0));
		return isPass(tx.origin);
	}

	function isPass(address _submiter) private returns (bool){
		if (isWinned[_submiter]) {
			return true;
		}
		require(GameContract(playContract[_submiter]).isPass());
		winnerList.push(tx.origin);
		isWinned[tx.origin] = true;
		winnerNums++;
		return true;
	}

	function play() public returns (address){
		if (playContract[tx.origin] == address(0)){
			address a = gameCreate();
			playContract[tx.origin] = a;
		}
		return playContract[tx.origin];
	}
	function gameCreate() public returns (address);
}

contract HoneyPot is GameContract {

    constructor (bytes b) public payable {
        assembly { return(add(0x20, b), mload(b)) }
    }
    
    function withdraw() public payable {
        require(msg.value > 0.01 ether);
        msg.sender.transfer(address(this).balance);
    }

	function isPass() public view returns (bool) {
		return address(this).balance == 0;
	}

}


contract HoneyPotGameBuilder is GameBuilder{

 	bytes internal constant ID = hex"600436106100385763ffffffff60e060020a6000350416632d1d744a811461003d5780635bcb2fc61461006657806362a2cf0c1461007b575b600080fd5b34801561004957600080fd5b506100526100a7565b604080519115158252519081900360200190f35b34801561007257600080fd5b506100526100ad565b6100a57bffffffffffffffffffffffffffffffffffffffffffffffffffffffff196004351661015f565b005b30311590565b60006100b76100a7565b15156100c257600080fd5b6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16635bcb2fc66040518163ffffffff1660e060020a028152600401602060405180830381600087803b15801561012e57600080fd5b505af1158015610142573d6000803e3d6000fd5b505050506040513d602081101561015857600080fd5b5051905090565b671bc16d674ec80000341015610174576101d8565b3360e060020a027bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19908116908216146101a9576101d8565b6040513390303180156108fc02916000818181858888f193505050501580156101d6573d6000803e3d6000fd5b505b505600a165627a7a72305820ffe3bcce5406d5607e228c03c6425ba6d5a75947653ee13fe611abcd6e262fd50029";

	constructor() public payable{
	}

	function gameCreate() public returns (address){
		HoneyPot c= (new HoneyPot).value(0.0001 ether)(ID);
		return address(c);
	} 
}