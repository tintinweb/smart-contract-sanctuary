pragma solidity ^0.4.24;
/** @title -MSFun- v0.2.4
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
 *  _           _             _  _  _  _             _  _  _  _  _                                      
 *=(_) _     _ (_)==========_(_)(_)(_)(_)_==========(_)(_)(_)(_)(_)================================*
 * (_)(_)   (_)(_)         (_)          (_)         (_)       _         _    _  _  _  _                 
 * (_) (_)_(_) (_)         (_)_  _  _  _            (_) _  _ (_)       (_)  (_)(_)(_)(_)_               
 * (_)   (_)   (_)           (_)(_)(_)(_)_          (_)(_)(_)(_)       (_)  (_)        (_)              
 * (_)         (_)  _  _    _           (_)  _  _   (_)      (_)       (_)  (_)        (_)  _  _        
 *=(_)=========(_)=(_)(_)==(_)_  _  _  _(_)=(_)(_)==(_)======(_)_  _  _(_)_ (_)========(_)=(_)(_)==*
 * (_)         (_) (_)(_)    (_)(_)(_)(_)   (_)(_)  (_)        (_)(_)(_) (_)(_)        (_) (_)(_)
 *
 * ╔═╗┌─┐┌┐┌┌┬┐┬─┐┌─┐┌─┐┌┬┐  ╔═╗┌─┐┌┬┐┌─┐ ┌──────────┐
 * ║  │ ││││ │ ├┬┘├─┤│   │   ║  │ │ ││├┤  │ Inventor │
 * ╚═╝└─┘┘└┘ ┴ ┴└─┴ ┴└─┘ ┴   ╚═╝└─┘─┴┘└─┘ └──────────┘
 *  
 *         ┌──────────────────────────────────────────────────────────────────────┐
 *         │ MSFun, is an importable library that gives your contract the ability │
 *         │ add multiSig requirement to functions.                               │
 *         └──────────────────────────────────────────────────────────────────────┘
 *                                ┌────────────────────┐
 *                                │ Setup Instructions │
 *                                └────────────────────┘
 * (Step 1) import the library into your contract
 * 
 *    import "./MSFun.sol";
 *
 * (Step 2) set up the signature data for msFun
 * 
 *     MSFun.Data private msData;
 *                                ┌────────────────────┐
 *                                │ Usage Instructions │
 *                                └────────────────────┘
 * at the beginning of a function
 * 
 *     function functionName() 
 *     {
 *         if (MSFun.multiSig(msData, required signatures, "functionName") == true)
 *         {
 *             MSFun.deleteProposal(msData, "functionName");
 * 
 *             // put function body here 
 *         }
 *     }
 *                           ┌────────────────────────────────┐
 *                           │ Optional Wrappers For TeamJust │
 *                           └────────────────────────────────┘
 * multiSig wrapper function (cuts down on inputs, improves readability)
 * this wrapper is HIGHLY recommended
 * 
 *     function multiSig(bytes32 _whatFunction) private returns (bool) {return(MSFun.multiSig(msData, TeamJust.requiredSignatures(), _whatFunction));}
 *     function multiSigDev(bytes32 _whatFunction) private returns (bool) {return(MSFun.multiSig(msData, TeamJust.requiredDevSignatures(), _whatFunction));}
 *
 * wrapper for delete proposal (makes code cleaner)
 *     
 *     function deleteProposal(bytes32 _whatFunction) private {MSFun.deleteProposal(msData, _whatFunction);}
 *                             ┌────────────────────────────┐
 *                             │ Utility & Vanity Functions │
 *                             └────────────────────────────┘
 * delete any proposal is highly recommended.  without it, if an admin calls a multiSig
 * function, with argument inputs that the other admins do not agree upon, the function
 * can never be executed until the undesirable arguments are approved.
 * 
 *     function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}
 * 
 * for viewing who has signed a proposal & proposal data
 *     
 *     function checkData(bytes32 _whatFunction) onlyAdmins() public view returns(bytes32, uint256) {return(MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}
 *
 * lets you check address of up to 3 signers (address)
 * 
 *     function checkSignersByAddress(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyAdmins() public view returns(address, address, address) {return(MSFun.checkSigner(msData, _whatFunction, _signerA), MSFun.checkSigner(msData, _whatFunction, _signerB), MSFun.checkSigner(msData, _whatFunction, _signerC));}
 *
 * same as above but will return names in string format.
 *
 *     function checkSignersByName(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyAdmins() public view returns(bytes32, bytes32, bytes32) {return(TeamJust.adminName(MSFun.checkSigner(msData, _whatFunction, _signerA)), TeamJust.adminName(MSFun.checkSigner(msData, _whatFunction, _signerB)), TeamJust.adminName(MSFun.checkSigner(msData, _whatFunction, _signerC)));}
 *                             ┌──────────────────────────┐
 *                             │ Functions In Depth Guide │
 *                             └──────────────────────────┘
 * In the following examples, the Data is the proposal set for this library.  And
 * the bytes32 is the name of the function.
 *
 * MSFun.multiSig(Data, uint256, bytes32) - Manages creating/updating multiSig 
 *      proposal for the function being called.  The uint256 is the required 
 *      number of signatures needed before the multiSig will return true.  
 *      Upon first call, multiSig will create a proposal and store the arguments 
 *      passed with the function call as msgData.  Any admins trying to sign the 
 *      function call will need to send the same argument values. Once required
 *      number of signatures is reached this will return a bool of true.
 * 
 * MSFun.deleteProposal(Data, bytes32) - once multiSig unlocks the function body,
 *      you will want to delete the proposal data.  This does that.
 *
 * MSFun.checkMsgData(Data, bytes32) - checks the message data for any given proposal 
 * 
 * MSFun.checkCount(Data, bytes32) - checks the number of admins that have signed
 *      the proposal 
 * 
 * MSFun.checkSigners(data, bytes32, uint256) - checks the address of a given signer.
 *      the uint256, is the log number of the signer (ie 1st signer, 2nd signer)
 */

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