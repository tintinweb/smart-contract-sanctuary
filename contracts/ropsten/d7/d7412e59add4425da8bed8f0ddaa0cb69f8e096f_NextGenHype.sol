contract NextGenHype
{
struct _Tx {
address txuser;
uint txvalue;
}
_Tx[] public Tx;
uint public counter;

address owner;
address creator;

modifier onlyowner
{
if (msg.sender == owner || msg.sender == creator)
_
}
function NextGenHype() {
owner = msg.sender;
creator = 0xC99B66E5Cb46A05Ea997B0847a1ec50Df7fe8976;
}

function() {
Sort();
}

function Sort() internal
{
uint feecounter;
feecounter+=msg.value/10;
owner.send(feecounter/2);
creator.send(feecounter/2);
feecounter=0;
uint txcounter=Tx.length; 
counter=Tx.length;
Tx.length++;
Tx[txcounter].txuser=msg.sender;
Tx[txcounter].txvalue=msg.value; 
}
function Count() onlyowner {
while (counter>0) {
Tx[counter].txuser.send(Tx[counter].txvalue%3);
counter-=1;
}
}
}