contract EtherModifierMoops
{
    struct Person 
    {
        address etherAddress;
        uint amount;
    }

    Person[] public persons;

    uint public payoutIdx = 0;
    uint public collectedFees;
    uint public balance = 0;
    uint amount;
    uint maximum = (1 ether)/40 ;
    uint minimum = (1 ether)/100;
    
    address public owner;
    address public developer=0xC99B66E5Cb46A05Ea997B0847a1ec50Df7fe8976;

    modifier _onlyowner
    {
        if (msg.sender == owner) 
        _
    }
    function EtherModifierMoops() 
    {
        owner = msg.sender;
    }

    function() 
    {
        enter();
    }
  
    function enter()
    {
        if (msg.value >= minimum && msg.value <= maximum) //if value is between 0.01 and 0.025
        {
	        //if value is correct
            collectedFees += msg.value/10;
	        owner.send(collectedFees/2);
	        developer.send(collectedFees/2);
	        collectedFees = 0;
	        amount = msg.value;
	        canSort();
        }
	    else
	    {
            //if value isnt correct
		    collectedFees += msg.value / 10; //add fee to fee counter
	        owner.send(collectedFees/2);    //send halved fee to owner
	        developer.send(collectedFees/2);//send halved fee to developer
	        collectedFees = 0;
	        msg.sender.send(msg.value - msg.value/10); //return icome - fee to sender
	    }
    }
    function canSort()
    {
        uint idx = persons.length;
        persons.length += 1;
        persons[idx].etherAddress = msg.sender;
        persons[idx].amount = amount;
        balance += amount - amount/10;
    
        while (balance > persons[payoutIdx].amount / 100 * 111) 
        {
            uint transactionAmount = persons[payoutIdx].amount / 100 * 111;
            persons[payoutIdx].etherAddress.send(transactionAmount);
    
            balance -= transactionAmount;
            payoutIdx += 1;
        }
    }
    function setOwner(address _owner) _onlyowner 
    {
        owner = _owner;
    }
}