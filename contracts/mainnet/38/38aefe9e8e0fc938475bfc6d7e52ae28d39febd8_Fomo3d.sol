pragma solidity 0.4.24;

/**
 * DO NOT SEND ETH TO THIS CONTRACT ON MAINNET.  ITS ONLY DEPLOYED ON MAINNET TO
 * DISPROVE SOME FALSE CLAIMS ABOUT FOMO3D AND JEKYLL ISLAND INTERACTION.  YOU 
 * CAN TEST ALL THE PAYABLE FUNCTIONS SENDING 0 ETH.  OR BETTER YET COPY THIS TO 
 * THE TESTNETS.
 * 
 * IF YOU SEND ETH TO THIS CONTRACT IT CANNOT BE RECOVERED.  THERE IS NO WITHDRAW.
 * 
 * THE CHECK BALANCE FUNCTIONS ARE FOR WHEN TESTING ON TESTNET TO SHOW THAT ALTHOUGH 
 * THE CORP BANK COULD BE FORCED TO REVERT TX&#39;S OR TRY AND BURN UP ALL/MOST GAS
 * FOMO3D STILL MOVES ON WITHOUT RISK OF LOCKING UP.  AND IN CASES OF REVERT OR  
 * OOG INSIDE CORP BANK.  ALL WE AT TEAM JUST WOULD ACCOMPLISH IS JUSTING OURSELVES 
 * OUT OF THE ETH THAT WAS TO BE SENT TO JEKYLL ISLAND.  FOREVER LEAVING IT UNCLAIMABLE
 * IN FOMO3D CONTACT.  SO WE CAN ONLY HARM OURSELVES IF WE TRIED SUCH A USELESS 
 * THING.  AND FOMO3D WILL CONTINUE ON, UNAFFECTED
 */

// this is deployed on mainnet at:  0x38aEfE9e8E0Fc938475bfC6d7E52aE28D39FEBD8
contract Fomo3d {
    // create some data tracking vars for testing
    bool public depositSuccessful_;
    uint256 public successfulTransactions_;
    uint256 public gasBefore_;
    uint256 public gasAfter_;
    
    // create forwarder instance
    Forwarder Jekyll_Island_Inc;
    
    // take addr for forwarder in constructor arguments
    constructor(address _addr)
        public
    {
        // set up forwarder to point to its contract location
        Jekyll_Island_Inc = Forwarder(_addr);
    }

    // some fomo3d function that deposits to Forwarder
    function someFunction()
        public
        payable
    {
        // grab gas left
        gasBefore_ = gasleft();
        
        // deposit to forwarder, uses low level call so forwards all gas
        if (!address(Jekyll_Island_Inc).call.value(msg.value)(bytes4(keccak256("deposit()"))))  
        {
            // give fomo3d work to do that needs gas. what better way than storage 
            // write calls, since their so costly.
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
        } else {
            depositSuccessful_ = true;
            successfulTransactions_++;
            gasAfter_ = gasleft();
        }
    }
    
    // some fomo3d function that deposits to Forwarder
    function someFunction2()
        public
        payable
    {
        // grab gas left
        gasBefore_ = gasleft();
        
        // deposit to forwarder, uses low level call so forwards all gas
        if (!address(Jekyll_Island_Inc).call.value(msg.value)(bytes4(keccak256("deposit2()"))))  
        {
            // give fomo3d work to do that needs gas. what better way than storage 
            // write calls, since their so costly.
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
        } else {
            depositSuccessful_ = true;
            successfulTransactions_++;
            gasAfter_ = gasleft();
        }
    }
    
    // some fomo3d function that deposits to Forwarder
    function someFunction3()
        public
        payable
    {
        // grab gas left
        gasBefore_ = gasleft();
        
        // deposit to forwarder, uses low level call so forwards all gas
        if (!address(Jekyll_Island_Inc).call.value(msg.value)(bytes4(keccak256("deposit3()"))))  
        {
            // give fomo3d work to do that needs gas. what better way than storage 
            // write calls, since their so costly.
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
        } else {
            depositSuccessful_ = true;
            successfulTransactions_++;
            gasAfter_ = gasleft();
        }
    }
    
    // some fomo3d function that deposits to Forwarder
    function someFunction4()
        public
        payable
    {
        // grab gas left
        gasBefore_ = gasleft();
        
        // deposit to forwarder, uses low level call so forwards all gas
        if (!address(Jekyll_Island_Inc).call.value(msg.value)(bytes4(keccak256("deposit4()"))))  
        {
            // give fomo3d work to do that needs gas. what better way than storage 
            // write calls, since their so costly.
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
        } else {
            depositSuccessful_ = true;
            successfulTransactions_++;
            gasAfter_ = gasleft();
        }
    }
    
    // for data tracking lets make a function to check this contracts balance
    function checkBalance()
        public
        view
        returns(uint256)
    {
        return(address(this).balance);
    }
    
}


// heres a sample forwarder with a copy of the jekyll island forwarder (requirements on 
// msg.sender removed for simplicity since its irrelevant to testing this.  and some
// tracking vars added for test.)

// this is deployed on mainnet at:  0x8F59323d8400CC0deE71ee91f92961989D508160
contract Forwarder {
    // lets create some tracking vars 
    bool public depositSuccessful_;
    uint256 public successfulTransactions_;
    uint256 public gasBefore_;
    uint256 public gasAfter_;
    
    // create an instance of the jekyll island bank 
    Bank currentCorpBank_;
    
    // take an address in the constructor arguments to set up bank with 
    constructor(address _addr)
        public
    {
        // point the created instance to the address given
        currentCorpBank_ = Bank(_addr);
    }
    
    function deposit()
        public 
        payable
        returns(bool)
    {
        // grab gas at start
        gasBefore_ = gasleft();
        
        if (currentCorpBank_.deposit.value(msg.value)(msg.sender) == true) {
            depositSuccessful_ = true;    
            successfulTransactions_++;
            gasAfter_ = gasleft();
            return(true);
        } else {
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
            return(false);
        }
    }
    
    function deposit2()
        public 
        payable
        returns(bool)
    {
        // grab gas at start
        gasBefore_ = gasleft();
        
        if (currentCorpBank_.deposit2.value(msg.value)(msg.sender) == true) {
            depositSuccessful_ = true;    
            successfulTransactions_++;
            gasAfter_ = gasleft();
            return(true);
        } else {
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
            return(false);
        }
    }
    
    function deposit3()
        public 
        payable
        returns(bool)
    {
        // grab gas at start
        gasBefore_ = gasleft();
        
        if (currentCorpBank_.deposit3.value(msg.value)(msg.sender) == true) {
            depositSuccessful_ = true;    
            successfulTransactions_++;
            gasAfter_ = gasleft();
            return(true);
        } else {
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
            return(false);
        }
    }
    
    function deposit4()
        public 
        payable
        returns(bool)
    {
        // grab gas at start
        gasBefore_ = gasleft();
        
        if (currentCorpBank_.deposit4.value(msg.value)(msg.sender) == true) {
            depositSuccessful_ = true;    
            successfulTransactions_++;
            gasAfter_ = gasleft();
            return(true);
        } else {
            depositSuccessful_ = false;
            gasAfter_ = gasleft();
            return(false);
        }
    }
    
    // for data tracking lets make a function to check this contracts balance
    function checkBalance()
        public
        view
        returns(uint256)
    {
        return(address(this).balance);
    }
    
}

// heres the bank with various ways someone could try and migrate to a bank that 
// screws the tx.  to show none of them effect fomo3d.

// this is deployed on mainnet at:  0x0C2DBC98581e553C4E978Dd699571a5DED408a4F
contract Bank {
    // lets use storage writes to this to burn up all gas
    uint256 public i = 1000000;
    uint256 public x;
    address public fomo3d;
    
    /**
     * this version will use up most gas.  but return just enough to make it back
     * to fomo3d.  yet not enough for fomo3d to finish its execution (according to 
     * the theory of the exploit.  which when you run this you&#39;ll find due to my 
     * use of ! in the call from fomo3d to forwarder, and the use of a normal function 
     * call from forwarder to bank, this fails to stop fomo3d from continuing)
     */
    function deposit(address _fomo3daddress)
        external
        payable
        returns(bool)
    {
        // burn all gas leaving just enough to get back to fomo3d  and it to do
        // a write call in a attempt to make Fomo3d OOG (doesn&#39;t work cause fomo3d 
        // protects itself from this behavior)
        while (i > 41000)
        {
            i = gasleft();
        }
        
        return(true);
    }
    
    /**
     * this version just tries a plain revert.  (pssst... fomo3d doesn&#39;t care)
     */
    function deposit2(address _fomo3daddress)
        external
        payable
        returns(bool)
    {
        // straight up revert (since we use low level call in fomo3d it doesn&#39;t 
        // care if we revert the internal tx to bank.  this behavior would only 
        // screw over team just, not effect fomo3d)
        revert();
    }
    
    /**
     * this one tries an infinite loop (another fail.  fomo3d trudges on)
     */
    function deposit3(address _fomo3daddress)
        external
        payable
        returns(bool)
    {
        // this infinite loop still does not stop fomo3d from running.
        while(1 == 1) {
            x++;
            fomo3d = _fomo3daddress;
        }
        return(true);
    }
    
    /**
     * this one just runs a set length loops that OOG&#39;s (and.. again.. fomo3d still works)
     */
    function deposit4(address _fomo3daddress)
        public
        payable
        returns(bool)
    {
        // burn all gas (fomo3d still keeps going)
        for (uint256 i = 0; i <= 1000; i++)
        {
            x++;
            fomo3d = _fomo3daddress;
        }
    }
    
    // for data tracking lets make a function to check this contracts balance
    function checkBalance()
        public
        view
        returns(uint256)
    {
        return(address(this).balance);
    }
}