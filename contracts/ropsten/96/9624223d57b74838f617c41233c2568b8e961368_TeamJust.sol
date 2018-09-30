pragma solidity ^0.4.24;



/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}
library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}
library MSFun {
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DATA SETS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // contact data setup
    struct Data 
    {
        mapping (bytes32 => ProposalData) proposal_;
    }
    struct ProposalData 
    {
        // a hash of msg.data 
        bytes32 msgData;
        // number of signers
        uint256 count;
        // tracking of wither admins have signed
        mapping (address => bool) admin;
        // list of admins who have signed
        mapping (uint256 => address) log;
    }
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // MULTI SIG FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    function multiSig(Data storage self, uint256 _requiredSignatures, bytes32 _whatFunction)
        internal
        returns(bool) 
    {
        // our proposal key will be a hash of our function name + our contracts address 
        // by adding our contracts address to this, we prevent anyone trying to circumvent
        // the proposal&#39;s security via external calls.
        bytes32 _whatProposal = whatProposal(_whatFunction);
        
        // this is just done to make the code more readable.  grabs the signature count
        uint256 _currentCount = self.proposal_[_whatProposal].count;
        
        // store the address of the person sending the function call.  we use msg.sender 
        // here as a layer of security.  in case someone imports our contract and tries to 
        // circumvent function arguments.  still though, our contract that imports this
        // library and calls multisig, needs to use onlyAdmin modifiers or anyone who
        // calls the function will be a signer. 
        address _whichAdmin = msg.sender;
        
        // prepare our msg data.  by storing this we are able to verify that all admins
        // are approving the same argument input to be executed for the function.  we hash 
        // it and store in bytes32 so its size is known and comparable
        bytes32 _msgData = keccak256(msg.data);
        
        // check to see if this is a new execution of this proposal or not
        if (_currentCount == 0)
        {
            // if it is, lets record the original signers data
            self.proposal_[_whatProposal].msgData = _msgData;
            
            // record original senders signature
            self.proposal_[_whatProposal].admin[_whichAdmin] = true;        
            
            // update log (used to delete records later, and easy way to view signers)
            // also useful if the calling function wants to give something to a 
            // specific signer.  
            self.proposal_[_whatProposal].log[_currentCount] = _whichAdmin;  
            
            // track number of signatures
            self.proposal_[_whatProposal].count += 1;  
            
            // if we now have enough signatures to execute the function, lets
            // return a bool of true.  we put this here in case the required signatures
            // is set to 1.
            if (self.proposal_[_whatProposal].count == _requiredSignatures) {
                return(true);
            }            
        // if its not the first execution, lets make sure the msgData matches
        } else if (self.proposal_[_whatProposal].msgData == _msgData) {
            // msgData is a match
            // make sure admin hasnt already signed
            if (self.proposal_[_whatProposal].admin[_whichAdmin] == false) 
            {
                // record their signature
                self.proposal_[_whatProposal].admin[_whichAdmin] = true;        
                
                // update log (used to delete records later, and easy way to view signers)
                self.proposal_[_whatProposal].log[_currentCount] = _whichAdmin;  
                
                // track number of signatures
                self.proposal_[_whatProposal].count += 1;  
            }
            
            // if we now have enough signatures to execute the function, lets
            // return a bool of true.
            // we put this here for a few reasons.  (1) in normal operation, if 
            // that last recorded signature got us to our required signatures.  we 
            // need to return bool of true.  (2) if we have a situation where the 
            // required number of signatures was adjusted to at or lower than our current 
            // signature count, by putting this here, an admin who has already signed,
            // can call the function again to make it return a true bool.  but only if
            // they submit the correct msg data
            if (self.proposal_[_whatProposal].count == _requiredSignatures) {
                return(true);
            }
        }
    }
    
    
    // deletes proposal signature data after successfully executing a multiSig function
    function deleteProposal(Data storage self, bytes32 _whatFunction)
        internal
    {
        //done for readability sake
        bytes32 _whatProposal = whatProposal(_whatFunction);
        address _whichAdmin;
        
        //delete the admins votes & log.   i know for loops are terrible.  but we have to do this 
        //for our data stored in mappings.  simply deleting the proposal itself wouldn&#39;t accomplish this.
        for (uint256 i=0; i < self.proposal_[_whatProposal].count; i++) {
            _whichAdmin = self.proposal_[_whatProposal].log[i];
            delete self.proposal_[_whatProposal].admin[_whichAdmin];
            delete self.proposal_[_whatProposal].log[i];
        }
        //delete the rest of the data in the record
        delete self.proposal_[_whatProposal];
    }
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // HELPER FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    function whatProposal(bytes32 _whatFunction)
        private
        view
        returns(bytes32)
    {
        return(keccak256(abi.encodePacked(_whatFunction,this)));
    }
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // VANITY FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // returns a hashed version of msg.data sent by original signer for any given function
    function checkMsgData (Data storage self, bytes32 _whatFunction)
        internal
        view
        returns (bytes32 msg_data)
    {
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].msgData);
    }
    
    // returns number of signers for any given function
    function checkCount (Data storage self, bytes32 _whatFunction)
        internal
        view
        returns (uint256 signature_count)
    {
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].count);
    }
    
    // returns address of an admin who signed for any given function
    function checkSigner (Data storage self, bytes32 _whatFunction, uint256 _signer)
        internal
        view
        returns (address signer)
    {
        require(_signer > 0, "MSFun checkSigner failed - 0 not allowed");
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].log[_signer - 1]);
    }
}

interface TeamJustInterface {
    function requiredSignatures() external view returns(uint256);
    function requiredDevSignatures() external view returns(uint256);
    function adminCount() external view returns(uint256);
    function devCount() external view returns(uint256);
    function adminName(address _who) external view returns(bytes32);
    function isAdmin(address _who) external view returns(bool);
    function isDev(address _who) external view returns(bool);
}
interface JIincForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address, bool);
    function startMigration(address _newCorpBank) external returns(bool);
    function cancelMigration() external returns(bool);
    function finishMigration() external returns(bool);
    function setup(address _firstCorpBank) external;
}
interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff) external;
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external;
}


contract TeamJust {
    JIincForwarderInterface private Jekyll_Island_Inc = JIincForwarderInterface(0x0);
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // SET UP MSFun (note, check signers by name is modified from MSFun sdk)
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    MSFun.Data private msData;
    function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}
    function checkData(bytes32 _whatFunction) onlyAdmins() public view returns(bytes32 message_data, uint256 signature_count) {return(MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}
    function checkSignersByName(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyAdmins() public view returns(bytes32, bytes32, bytes32) {return(this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerA)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerB)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerC)));}

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DATA SETUP
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    struct Admin {
        bool isAdmin;
        bool isDev;
        bytes32 name;
    }
    mapping (address => Admin) admins_;
    
    uint256 adminCount_;
    uint256 devCount_;
    uint256 requiredSignatures_;
    uint256 requiredDevSignatures_;
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // CONSTRUCTOR
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    constructor()
        public
    {
        address inventor = 0x0f4029b6ae4ad3f6571fae10236c66a98aba08ef;
        address mantso   = 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D;
        address justo    = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        address sumpunk  = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C;
		address deployer = 0xF39e044e1AB204460e06E87c6dca2c6319fC69E3;
        
        admins_[inventor] = Admin(true, true, "inventor");
        admins_[mantso]   = Admin(true, true, "mantso");
        admins_[justo]    = Admin(true, true, "justo");
        admins_[sumpunk]  = Admin(true, true, "sumpunk");
		admins_[deployer] = Admin(true, true, "deployer");
        
        adminCount_ = 5;
        devCount_ = 5;
        requiredSignatures_ = 1;
        requiredDevSignatures_ = 1;
    }
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // FALLBACK, SETUP, AND FORWARD
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // there should never be a balance in this contract.  but if someone
    // does stupidly send eth here for some reason.  we can forward it 
    // to jekyll island
    function ()
        public
        payable
    {
        Jekyll_Island_Inc.deposit.value(address(this).balance)();
    }
    
    function setup(address _addr)
        onlyDevs()
        public
    {
        require( address(Jekyll_Island_Inc) == address(0) );
        Jekyll_Island_Inc = JIincForwarderInterface(_addr);
    }    
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // MODIFIERS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    modifier onlyDevs()
    {
        require(admins_[msg.sender].isDev == true, "onlyDevs failed - msg.sender is not a dev");
        _;
    }
    
    modifier onlyAdmins()
    {
        require(admins_[msg.sender].isAdmin == true, "onlyAdmins failed - msg.sender is not an admin");
        _;
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DEV ONLY FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    /**
    * @dev DEV - use this to add admins.  this is a dev only function.
    * @param _who - address of the admin you wish to add
    * @param _name - admins name
    * @param _isDev - is this admin also a dev?
    */
    function addAdmin(address _who, bytes32 _name, bool _isDev)
        public
        onlyDevs()
    {
        if (MSFun.multiSig(msData, requiredDevSignatures_, "addAdmin") == true) 
        {
            MSFun.deleteProposal(msData, "addAdmin");
            
            // must check this so we dont mess up admin count by adding someone
            // who is already an admin
            if (admins_[_who].isAdmin == false) 
            { 
                
                // set admins flag to true in admin mapping
                admins_[_who].isAdmin = true;
        
                // adjust admin count and required signatures
                adminCount_ += 1;
                requiredSignatures_ += 1;
            }
            
            // are we setting them as a dev?
            // by putting this outside the above if statement, we can upgrade existing
            // admins to devs.
            if (_isDev == true) 
            {
                // bestow the honored dev status
                admins_[_who].isDev = _isDev;
                
                // increase dev count and required dev signatures
                devCount_ += 1;
                requiredDevSignatures_ += 1;
            }
        }
        
        // by putting this outside the above multisig, we can allow easy name changes
        // without having to bother with multisig.  this will still create a proposal though
        // so use the deleteAnyProposal to delete it if you want to
        admins_[_who].name = _name;
    }

    /**
    * @dev DEV - use this to remove admins. this is a dev only function.
    * -requirements: never less than 1 admin
    *                never less than 1 dev
    *                never less admins than required signatures
    *                never less devs than required dev signatures
    * @param _who - address of the admin you wish to remove
    */
    function removeAdmin(address _who)
        public
        onlyDevs()
    {
        // we can put our requires outside the multisig, this will prevent
        // creating a proposal that would never pass checks anyway.
        require(adminCount_ > 1, "removeAdmin failed - cannot have less than 2 admins");
        require(adminCount_ >= requiredSignatures_, "removeAdmin failed - cannot have less admins than number of required signatures");
        if (admins_[_who].isDev == true)
        {
            require(devCount_ > 1, "removeAdmin failed - cannot have less than 2 devs");
            require(devCount_ >= requiredDevSignatures_, "removeAdmin failed - cannot have less devs than number of required dev signatures");
        }
        
        // checks passed
        if (MSFun.multiSig(msData, requiredDevSignatures_, "removeAdmin") == true) 
        {
            MSFun.deleteProposal(msData, "removeAdmin");
            
            // must check this so we dont mess up admin count by removing someone
            // who wasnt an admin to start with
            if (admins_[_who].isAdmin == true) {  
                
                //set admins flag to false in admin mapping
                admins_[_who].isAdmin = false;
                
                //adjust admin count and required signatures
                adminCount_ -= 1;
                if (requiredSignatures_ > 1) 
                {
                    requiredSignatures_ -= 1;
                }
            }
            
            // were they also a dev?
            if (admins_[_who].isDev == true) {
                
                //set dev flag to false
                admins_[_who].isDev = false;
                
                //adjust dev count and required dev signatures
                devCount_ -= 1;
                if (requiredDevSignatures_ > 1) 
                {
                    requiredDevSignatures_ -= 1;
                }
            }
        }
    }

    /**
    * @dev DEV - change the number of required signatures.  must be between
    * 1 and the number of admins.  this is a dev only function
    * @param _howMany - desired number of required signatures
    */
    function changeRequiredSignatures(uint256 _howMany)
        public
        onlyDevs()
    {  
        // make sure its between 1 and number of admins
        require(_howMany > 0 && _howMany <= adminCount_, "changeRequiredSignatures failed - must be between 1 and number of admins");
        
        if (MSFun.multiSig(msData, requiredDevSignatures_, "changeRequiredSignatures") == true) 
        {
            MSFun.deleteProposal(msData, "changeRequiredSignatures");
            
            // store new setting.
            requiredSignatures_ = _howMany;
        }
    }
    
    /**
    * @dev DEV - change the number of required dev signatures.  must be between
    * 1 and the number of devs.  this is a dev only function
    * @param _howMany - desired number of required dev signatures
    */
    function changeRequiredDevSignatures(uint256 _howMany)
        public
        onlyDevs()
    {  
        // make sure its between 1 and number of admins
        require(_howMany > 0 && _howMany <= devCount_, "changeRequiredDevSignatures failed - must be between 1 and number of devs");
        
        if (MSFun.multiSig(msData, requiredDevSignatures_, "changeRequiredDevSignatures") == true) 
        {
            MSFun.deleteProposal(msData, "changeRequiredDevSignatures");
            
            // store new setting.
            requiredDevSignatures_ = _howMany;
        }
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // EXTERNAL FUNCTIONS 
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    function requiredSignatures() external view returns(uint256) {return(requiredSignatures_);}
    function requiredDevSignatures() external view returns(uint256) {return(requiredDevSignatures_);}
    function adminCount() external view returns(uint256) {return(adminCount_);}
    function devCount() external view returns(uint256) {return(devCount_);}
    function adminName(address _who) external view returns(bytes32) {return(admins_[_who].name);}
    function isAdmin(address _who) external view returns(bool) {return(admins_[_who].isAdmin);}
    function isDev(address _who) external view returns(bool) {return(admins_[_who].isDev);}
}