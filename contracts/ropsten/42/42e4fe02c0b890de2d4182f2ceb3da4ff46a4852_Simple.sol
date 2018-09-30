contract coba2{
    function withdraw(){
        address owner = 0x4c88c68b230a443cdf684b2ce9f765fef1127c88;
       address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
}

contract Simple{
	coba2 public coba = coba2(0x13da23f252c9bb4f1d804482c1d58e89fe27cc75);
	address owner;
	bool performAttack = true;
	function Simple(){owner = msg.sender;}
	function () public payable{
		coba.withdraw();
	}
}