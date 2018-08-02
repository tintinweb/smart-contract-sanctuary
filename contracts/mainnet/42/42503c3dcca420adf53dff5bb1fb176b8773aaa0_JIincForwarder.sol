pragma solidity ^0.4.24;
/*
 * @title -Jekyll Island- CORP BANK FORWARDER v0.4.6
 * ┌┬┐┌─┐┌─┐┌┬┐   ╦╦ ╦╔═╗╔╦╗  ┌─┐┬─┐┌─┐┌─┐┌─┐┌┐┌┌┬┐┌─┐
 *  │ ├┤ ├─┤│││   ║║ ║╚═╗ ║   ├─┘├┬┘├┤ └─┐├┤ │││ │ └─┐
 *  ┴ └─┘┴ ┴┴ ┴  ╚╝╚═╝╚═╝ ╩   ┴  ┴└─└─┘└─┘└─┘┘└┘ ┴ └─┘
 *                                  _____                      _____
 *                                 (, /     /)       /) /)    (, /      /)          /)
 *          ┌─┐                      /   _ (/_      // //       /  _   // _   __  _(/
 *          ├─┤                  ___/___(/_/(__(_/_(/_(/_   ___/__/_)_(/_(_(_/ (_(_(_
 *          ┴ ┴                /   /          .-/ _____   (__ /                               
 *                            (__ /          (_/ (, /                                      /)™ 
 *                                                 /  __  __ __ __  _   __ __  _  _/_ _  _(/
 * ┌─┐┬─┐┌─┐┌┬┐┬ ┬┌─┐┌┬┐                          /__/ (_(__(_)/ (_/_)_(_)/ (_(_(_(__(/_(_(_
 * ├─┘├┬┘│ │ │││ ││   │                      (__ /              .-/  &#169; Jekyll Island Inc. 2018
 * ┴  ┴└─└─┘─┴┘└─┘└─┘ ┴                                        (_/
 *====/$$$$$===========/$$=================/$$ /$$====/$$$$$$===========/$$===========================/$$=*
 *   |__  $$          | $$                | $$| $$   |_  $$_/          | $$                          | $$
 *      | $$  /$$$$$$ | $$   /$$ /$$   /$$| $$| $$     | $$    /$$$$$$$| $$  /$$$$$$  /$$$$$$$   /$$$$$$$
 *      | $$ /$$__  $$| $$  /$$/| $$  | $$| $$| $$     | $$   /$$_____/| $$ |____  $$| $$__  $$ /$$__  $$
 * /$$  | $$| $$$$$$$$| $$$$$$/ | $$  | $$| $$| $$     | $$  |  $$$$$$ | $$  /$$$$$$$| $$  \ $$| $$  | $$
 *| $$  | $$| $$_____/| $$_  $$ | $$  | $$| $$| $$     | $$   \____  $$| $$ /$$__  $$| $$  | $$| $$  | $$
 *|  $$$$$$/|  $$$$$$$| $$ \  $$|  $$$$$$$| $$| $$    /$$$$$$ /$$$$$$$/| $$|  $$$$$$$| $$  | $$|  $$$$$$$
 * \______/  \_______/|__/  \__/ \____  $$|__/|__/   |______/|_______/ |__/ \_______/|__/  |__/ \_______/
 *===============================/$$  | $$ Inc.  ╔═╗╔═╗╦═╗╔═╗  ╔╗ ╔═╗╔╗╔╦╔═  ┌─┐┌─┐┬─┐┬ ┬┌─┐┬─┐┌┬┐┌─┐┬─┐                                 
 *                              |  $$$$$$/=======║  ║ ║╠╦╝╠═╝  ╠╩╗╠═╣║║║╠╩╗  ├┤ │ │├┬┘│││├─┤├┬┘ ││├┤ ├┬┘  
 *                               \______/        ╚═╝╚═╝╩╚═╩    ╚═╝╩ ╩╝╚╝╩ ╩  └  └─┘┴└─└┴┘┴ ┴┴└──┴┘└─┘┴└─==*
 * ╔═╗┌─┐┌┐┌┌┬┐┬─┐┌─┐┌─┐┌┬┐  ╔═╗┌─┐┌┬┐┌─┐ ┌──────────┐                       
 * ║  │ ││││ │ ├┬┘├─┤│   │   ║  │ │ ││├┤  │ Inventor │                      
 * ╚═╝└─┘┘└┘ ┴ ┴└─┴ ┴└─┘ ┴   ╚═╝└─┘─┴┘└─┘ └──────────┘                      
 *===========================================================================================*
 *                                ┌────────────────────┐
 *                                │ Setup Instructions │
 *                                └────────────────────┘
 * (Step 1) import the Jekyll Island Inc Forwarder Interface into your contract
 * 
 *    import &quot;./JIincForwarderInterface.sol&quot;;
 *
 * (Step 2) set it to point to the forwarder
 * 
 *    JIincForwarderInterface private Jekyll_Island_Inc = JIincForwarderInterface(0xdd4950F977EE28D2C132f1353D1595035Db444EE);
 *                                ┌────────────────────┐
 *                                │ Usage Instructions │
 *                                └────────────────────┘
 * whenever your contract needs to send eth to the corp bank, simply use the 
 * the following command:
 *
 *    Jekyll_Island_Inc.deposit.value(amount)()
 * 
 * OPTIONAL:
 * if you need to be checking wither the transaction was successful, the deposit function returns 
 * a bool indicating wither or not it was successful.  so another way to call this function 
 * would be:
 * 
 *    require(Jekyll_Island_Inc.deposit.value(amount)() == true, &quot;Jekyll Island deposit failed&quot;);
 * 
 */

interface JIincInterfaceForForwarder {
    function deposit(address _addr) external payable returns (bool);
    function migrationReceiver_setup() external returns (bool);
}

contract JIincForwarder {
    string public name = &quot;JIincForwarder&quot;;
    JIincInterfaceForForwarder private currentCorpBank_;
    address private newCorpBank_;
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
        currentCorpBank_.deposit.value(address(this).balance)(address(currentCorpBank_));
    }
    
    function deposit()
        public 
        payable
        returns(bool)
    {
        require(msg.value > 0, &quot;Forwarder Deposit failed - zero deposits not allowed&quot;);
        require(needsBank_ == false, &quot;Forwarder Deposit failed - no registered bank&quot;);
        if (currentCorpBank_.deposit.value(msg.value)(msg.sender) == true)
            return(true);
        else
            return(false);
    }
//==============================================================================
//     _ _ . _  _ _ _|_. _  _   .
//    | | ||(_|| (_| | |(_)| |  .
//===========_|=================================================================    
    function status()
        public
        view
        returns(address, address, bool)
    {
        return(address(currentCorpBank_), address(newCorpBank_), needsBank_);
    }

    function startMigration(address _newCorpBank)
        external
        returns(bool)
    {
        // make sure this is coming from current corp bank
        require(msg.sender == address(currentCorpBank_), &quot;Forwarder startMigration failed - msg.sender must be current corp bank&quot;);
        
        // communicate with the new corp bank and make sure it has the forwarder 
        // registered 
        if(JIincInterfaceForForwarder(_newCorpBank).migrationReceiver_setup() == true)
        {
            // save our new corp bank address
            newCorpBank_ = _newCorpBank;
            return (true);
        } else 
            return (false);
    }
    
    function cancelMigration()
        external
        returns(bool)
    {
        // make sure this is coming from the current corp bank (also lets us know 
        // that current corp bank has not been killed)
        require(msg.sender == address(currentCorpBank_), &quot;Forwarder cancelMigration failed - msg.sender must be current corp bank&quot;);
        
        // erase stored new corp bank address;
        newCorpBank_ = address(0x0);
        
        return (true);
    }
    
    function finishMigration()
        external
        returns(bool)
    {
        // make sure its coming from new corp bank
        require(msg.sender == newCorpBank_, &quot;Forwarder finishMigration failed - msg.sender must be new corp bank&quot;);

        // update corp bank address        
        currentCorpBank_ = (JIincInterfaceForForwarder(newCorpBank_));
        
        // erase new corp bank address
        newCorpBank_ = address(0x0);
        
        return (true);
    }
//==============================================================================
//    . _ ._|_. _ |   _ _ _|_    _   .
//    || || | |(_||  _\(/_ | |_||_)  .  (this only runs once ever)
//==============================|===============================================
    function setup(address _firstCorpBank)
        external
    {
        require(needsBank_ == true, &quot;Forwarder setup failed - corp bank already registered&quot;);
        currentCorpBank_ = JIincInterfaceForForwarder(_firstCorpBank);
        needsBank_ = false;
    }
}