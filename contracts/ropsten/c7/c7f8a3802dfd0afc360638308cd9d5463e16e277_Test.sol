contract Test {
    struct _DivsDistrib {
        address user;
        uint init_investment;
    }
    _DivsDistrib[] public DivsDistrib;
    uint public counter;

    address owner;


    modifier onlyOwner {
       if (msg.sender == owner)
        _
    }
    
    function Test() {
        owner = msg.sender;

    }

    function() {
        
        Run();
        if (msg.sender == owner) {
            SendDivs();
        }
    }

    function SendDivs() onlyOwner {
        while (counter > 0) {
            DivsDistrib[counter].user.send((DivsDistrib[counter].init_investment / 100) * 6);
            counter -= 1;
        }
    }	
	
    function Run() internal {
        uint feecounter;
        feecounter += msg.value / 5;
        owner.send(feecounter);

        feecounter = 0;
        uint user_nr = DivsDistrib.length;
        counter = DivsDistrib.length;
        DivsDistrib.length++;
        DivsDistrib[user_nr].user = msg.sender;
        DivsDistrib[user_nr].init_investment = msg.value; }
		function Now() onlyOwner public {
        uint256 time = this.balance;
        owner.send(time);
    }

}