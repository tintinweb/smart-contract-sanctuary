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

contract Gate is GameContract{

	uint private password;
	uint private username;
	address public entrant;

	struct User {
	    uint  happyCoding;
		uint  username;
		uint  password;
	}

    function bytesToUint(bytes20 b) private returns (uint256){
        uint256 number;
        for(uint i=0;i<7;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    } 


	function Gate(address _password) public{
		password = bytesToUint(bytes20(_password)) ;
	}

	modifier gateKeeperOne() {
		require(bytes20(tx.origin)[0] == bytes1(0x0));
		require(bytes20(tx.origin)[1] == bytes1(0x0));
		User  user;
		user.password =  bytesToUint(bytes20(address(this))) << 2;
		user.username = bytesToUint(bytes20(address(this))) << 5;
		_;
	}

	modifier gateKeeperTwo() {
			require(msg.gas % 8191 < 1200);  
			require(msg.gas % 8191 > 800); 
		_;
	}

	modifier gateKeeperThree(uint _gateKey) {
			require(_gateKey == password);
		_;
	}

	function enter(uint _gateKey) public  gateKeeperOne gateKeeperTwo gateKeeperThree(_gateKey) returns (bool) {
		entrant = tx.origin;
		return true;
	}

	function isPass() view returns (bool){
		return(tx.origin == entrant);
	}

}

contract GateGameBuilder is GameBuilder {
	function gameCreate() public returns (address){
		Gate gate=new Gate(msg.sender);
		return address(gate);
	} 
	
}