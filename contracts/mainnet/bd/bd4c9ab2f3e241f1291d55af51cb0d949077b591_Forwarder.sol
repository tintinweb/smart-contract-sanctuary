pragma solidity ^0.4.24;

contract Forwarder {
    string public name = &quot;Forwarder&quot;;
    address private currentCorpBank_;
    bool needsBank_ = true;
    
    constructor() 
        public
    {
        //constructor does nothing.
    }
    
    function()
        public
        payable
    {
        // done so that if any one tries to dump eth into this contract, we can
        // just forward it to corp bank.
        if (currentCorpBank_ != address(0))
            currentCorpBank_.transfer(msg.value);
    }
    
    function deposit()
        public 
        payable
        returns(bool)
    {
        require(msg.value > 0, &quot;Forwarder Deposit failed - zero deposits not allowed&quot;);
        require(needsBank_ == false, &quot;Forwarder Deposit failed - no registered bank&quot;);
        currentCorpBank_.transfer(msg.value);
        return(true);
    }

    function withdraw()
        public
        payable
    {
        require(msg.sender == currentCorpBank_);
        currentCorpBank_.transfer(address(this).balance);
    }

    function setup(address _firstCorpBank)
        external
    {
        require(needsBank_ == true, &quot;Forwarder setup failed - corp bank already registered&quot;);
        currentCorpBank_ = _firstCorpBank;
        needsBank_ = false;
    }
}