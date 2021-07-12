/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-17
*/

pragma solidity ^0.5.0;

//Functions for retrieving min and Max in 51 length array (requestQ)
//Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol

library Utilities {
    /**
    * @dev Returns the minimum value in an array.
    */
    function getMax(uint256[51] memory data) internal pure returns (uint256 max, uint256 maxIndex) {
        max = data[1];
        maxIndex;
        for (uint256 i = 1; i < data.length; i++) {
            if (data[i] > max) {
                max = data[i];
                maxIndex = i;
            }
        }
    }

    /**
    * @dev Returns the minimum value in an array.
    */
    function getMin(uint256[51] memory data) internal pure returns (uint256 min, uint256 minIndex) {
        minIndex = data.length - 1;
        min = data[minIndex];
        for (uint256 i = data.length - 1; i > 0; i--) {
            if (data[i] < min) {
                min = data[i];
                minIndex = i;
            }
        }
    }

}


/**
* @title Tellor Getters Library
* @dev This is the getter library for all variables in the Tellor Tributes system. TellorGetters references this
* libary for the getters logic
*/

library TellorGettersLibrary {
    using SafeMath for uint256;
    /*Functions*/

    /*Tellor Getters*/
    /**
    * @dev This function gets the 5 miners currently selected for providing data
    * @return miners an array of the miner addresses
    */
    function getCurrentMiners(TellorStorage.TellorStorageStruct storage self) internal view returns(address[] memory miners){
        return self.selectedValidators;
    }

    /**
    * @dev This function tells you if a given challenge has been completed by a given miner
    * @param _challenge the challenge to search for
    * @param _miner address that you want to know if they solved the challenge
    * @return true if the _miner address provided solved the
    */
    function didMine(TellorStorage.TellorStorageStruct storage self, bytes32 _challenge, address _miner) 
        internal 
        view 
        returns (bool) 
    {
        return self.minersByChallenge[_challenge][_miner];
    }

    /**
    * @dev Checks if an address voted in a dispute
    * @param _disputeId to look up
    * @param _address of voting party to look up
    * @return bool of whether or not party voted
    */
    function didVote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, address _address) 
        internal 
        view 
        returns (bool) 
    {
        return self.disputesById[_disputeId].voted[_address];
    }

    /**
    * @dev allows Tellor to read data from the addressVars mapping
    * @param _data is the keccak256("variable_name") of the variable that is being accessed.
    * These are examples of how the variables are saved within other functions:
    * addressVars[keccak256("_owner")]
    * addressVars[keccak256("tellorContract")]
    */
    function getAddressVars(TellorStorage.TellorStorageStruct storage self, bytes32 _data) 
        internal 
        view 
        returns (address) 
    {
        return self.addressVars[_data];
    }

    /**
    * @dev Gets all dispute variables
    * @param _disputeId to look up
    * @return bytes32 hash of dispute
    * @return bool executed where true if it has been voted on
    * @return bool disputeVotePassed
    * @return address of reportedMiner
    * @return address of reportingParty
    * @return address of proposedForkAddress
    * @return uint of requestId
    * @return uint of timestamp
    * @return uint of value
    * @return uint of minExecutionDate
    * @return uint of numberOfVotes
    * @return uint of blocknumber
    * @return uint of minerSlot
    * @return uint of quorum
    * @return uint of fee
    * @return int count of the current tally
    */
    function getAllDisputeVars(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId)
        internal
        view
        returns (bytes32, bool, bool, address, address, uint256[9] memory, int256)
    {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.reportedMiner,
            disp.reportingParty,
            [
                disp.disputeUintVars[keccak256("requestId")],
                disp.disputeUintVars[keccak256("timestamp")],
                disp.disputeUintVars[keccak256("value")],
                disp.disputeUintVars[keccak256("minExecutionDate")],
                disp.disputeUintVars[keccak256("numberOfVotes")],
                disp.disputeUintVars[keccak256("blockNumber")],
                disp.disputeUintVars[keccak256("minerSlot")],
                disp.disputeUintVars[keccak256("quorum")],
                disp.disputeUintVars[keccak256("fee")]
            ],
            disp.tally
        );
    }

    /**
    * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
    * @return current challenge, currentRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request
    */
    function getCurrentVariables(TellorStorage.TellorStorageStruct storage self)
        internal
        view
        returns (bytes32, uint256, uint256)
    {
        return (
            self.currentChallenge,
            self.uintVars[keccak256("currentRequestId")],
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("totalTip")]
        );
    }

    /**
    * @dev Checks if a given hash of miner,requestId has been disputed
    * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
    * @return uint disputeId
    */
    function getDisputeIdsByDisputeHash(TellorStorage.TellorStorageStruct storage self, bytes32 _hash) 
        internal 
        view 
        returns (uint256[] memory) 
    {
        return self.disputeIdsByDisputeHash[_hash];
    }

    /**
    * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
    * @param _disputeId is the dispute id;
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
    * the variables/strings used to save the data in the mapping. The variables names are
    * commented out under the disputeUintVars under the Dispute struct
    * @return uint value for the bytes32 data submitted
    */
    function getDisputeUintVars(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.disputesById[_disputeId].disputeUintVars[_data];
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    * @return true if the is a timestamp for the lastNewValue
    */
    function getLastNewValue(TellorStorage.TellorStorageStruct storage self) 
        internal 
        view 
        returns (uint256, bool) 
    {
        return (
            retrieveData(
                self,
                self.requestIdByTimestamp[self.uintVars[keccak256("timeOfLastNewValue")]],
                self.uintVars[keccak256("timeOfLastNewValue")]
            ),
            true
        );
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @param _requestId being requested
    * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
    */
    function getLastNewValueById(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) 
        internal 
        view 
        returns (uint256, bool) {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        if (_request.requestTimestamps.length > 0) {
            return (retrieveData(self, _requestId, _request.requestTimestamps[_request.requestTimestamps.length - 1]), true);
        } else {
            return (0, false);
        }
    }

    /**
    * @dev Gets blocknumber for mined timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up blocknumber
    * @return uint of the blocknumber which the dispute was mined
    */
    function getMinedBlockNum(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].minedBlockNum[_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return the 5 miners' addresses
    */
    function getMinersByRequestIdAndTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (address[5] memory)
    {
        return self.requestDetails[_requestId].minersByValue[_timestamp];
    }

    /**
    * @dev Counts the number of values that have been submited for the request
    * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
    * request so far
    * @param _requestId the requestId to look up
    * @return uint count of the number of values received for the requestId
    */
    function getNewValueCountbyRequestId(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) 
        internal 
        view 
        returns (uint256) 
    {
        return self.requestDetails[_requestId].requestTimestamps.length;
    }

    /**
    * @dev Getter function for the specified requestQ index
    * @param _index to look up in the requestQ array
    * @return uint of reqeuestId
    */
    function getRequestIdByRequestQIndex(TellorStorage.TellorStorageStruct storage self, uint256 _index) 
        internal 
        view 
        returns (uint256) 
    {
        require(_index <= 50, "RequestQ index is above 50");
        return self.requestIdByRequestQIndex[_index];
    }

    /**
    * @dev Getter function for requestId based on timestamp
    * @param _timestamp to check requestId
    * @return uint of reqeuestId
    */
    function getRequestIdByTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _timestamp) 
        internal 
        view 
        returns (uint256) 
    {
        return self.requestIdByTimestamp[_timestamp];
    }

    /**
    * @dev Getter function for the requestQ array
    * @return the requestQ arrray
    */
    function getRequestQ(TellorStorage.TellorStorageStruct storage self) 
        internal 
        view 
        returns (uint256[51] memory) 
    {
        return self.requestQ;
    }

    /**
    * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
    * for the requestId specified
    * @param _requestId to look up
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
    * the variables/strings used to save the data in the mapping. The variables names are
    * commented out under the apiUintVars under the requestDetails struct
    * @return uint value of the apiUintVars specified in _data for the requestId specified
    */
    function getRequestUintVars(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].apiUintVars[_data];
    }

    /**
    * @dev Gets the API struct variables that are not mappings
    * @param _requestId to look up
    * @return uint of index in requestQ array
    * @return uint of current payout/tip for this requestId
    */
    function getRequestVars(TellorStorage.TellorStorageStruct storage self, uint256 _requestId)
        internal
        view
        returns (uint256, uint256)
    {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        return (
            _request.apiUintVars[keccak256("requestQPosition")],
            _request.apiUintVars[keccak256("totalTip")]
        );
    }

    /**
    * @dev This function allows users to retireve all information about a staker
    * @param _staker address of staker inquiring about
    * @return uint current state of staker
    * @return uint startDate of staking
    * @return uint stakePosition for the staker
    */
    function getStakerInfo(TellorStorage.TellorStorageStruct storage self, address _staker) 
        internal 
        view 
        returns (uint256, uint256,uint256) 
    {
        return (self.stakerDetails[_staker].currentStatus, self.stakerDetails[_staker].startDate, self.stakerDetails[_staker].stakePosition.length);
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestampt to look up miners for
    * @return address[5] array of 5 addresses ofminers that mined the requestId
    */
    function getSubmissionsByTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256[5] memory)
    {
        return self.requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }

    /**
    * @dev Gets the timestamp for the value based on their index
    * @param _requestID is the requestId to look up
    * @param _index is the value index to look up
    * @return uint timestamp
    */
    function getTimestampbyRequestIDandIndex(TellorStorage.TellorStorageStruct storage self, uint256 _requestID, uint256 _index)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestID].requestTimestamps[_index];
    }

    /**
    * @dev Getter for the variables saved under the TellorStorageStruct uintVars variable
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
    * the variables/strings used to save the data in the mapping. The variables names are
    * commented out under the uintVars under the TellorStorageStruct struct
    * This is an example of how data is saved into the mapping within other functions:
    * self.uintVars[keccak256("stakerCount")]
    * @return uint of specified variable
    */
    function getUintVar(TellorStorage.TellorStorageStruct storage self, bytes32 _data) 
        internal 
        view 
        returns (uint256) 
    {
        return self.uintVars[_data];
    }

    /**
    * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
    * @return onDeck/info on request with highest payout-- RequestId, Totaltips
    */
    function getVariablesOnDeck(TellorStorage.TellorStorageStruct storage self) 
        internal 
        view 
        returns (uint256, uint256) 
    {
        uint256 newRequestId = getTopRequestID(self);
        return (
            newRequestId,
            self.requestDetails[newRequestId].apiUintVars[keccak256("totalTip")]
        );
    }

    /**
    * @dev Getter function for the request with highest payout. This function is used within the getVariablesOnDeck function
    * @return uint _requestId of request with highest payout at the time the function is called
    */
    function getTopRequestID(TellorStorage.TellorStorageStruct storage self) 
        internal 
        view 
        returns (uint256 _requestId) 
    {
        uint256 _max;
        uint256 _index;
        (_max, _index) = Utilities.getMax(self.requestQ);
        _requestId = self.requestIdByRequestQIndex[_index];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return bool true if requestId/timestamp is under dispute
    */
    function isInDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp) 
        internal 
        view 
        returns (bool) 
    {
        return self.requestDetails[_requestId].inDispute[_timestamp];
    }

    /**
    * @dev Retreive value from oracle based on requestId/timestamp
    * @param _requestId being requested
    * @param _timestamp to retreive data/value from
    * @return uint value for requestId/timestamp submitted
    */
    function retrieveData(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].finalValues[_timestamp];
    }
}



/**
* @title Tellor Oracle System Library
* @dev Contains the functions' logic for the Tellor contract where miners can submit the proof of work
* along with the value and smart contracts can requestData and tip miners.
*/

library TellorLibrary {
    using SafeMath for uint256;
    //emits when a tip is added to a requestId
    event TipAdded(address indexed _sender, uint256 indexed _requestId, uint256 _tip, uint256 _totalTips);
    //emits when a new challenge is created (either on mined block or when a new request is pushed forward on waiting system)
    event NewChallenge(
        bytes32 indexed _currentChallenge,
        uint256 indexed _currentRequestId,
        uint256 _totalTips
    );
    //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request
    event NewRequestOnDeck(uint256 indexed _requestId, uint256 _onDeckTotalTips);
    //Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event NewValue(uint256 indexed _requestId, uint256 _time, uint256 _value, uint256 _totalTips, bytes32 _currentChallenge);
    //Emits upon each mine (5 total) and shows the miner, and value submitted
    event SolutionSubmitted(address indexed _miner,  uint256 indexed _requestId, uint256 _value, bytes32 _currentChallenge);
    //emits when a new validator is selected
    event NewValidatorsSelected(address _validator);

    
    /*Functions*/    
    /**
    * @dev Add tip to Request value from oracle
    * @param _requestId being requested to be mined
    * @param _tip amount the requester is willing to pay to be get on queue. Miners
    * mine the onDeckQueryHash, or the api with the highest payout pool
    */
    function addTip(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _tip) public {
        require(_requestId > 0, "RequestId is 0");
        TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
            
        require(tellorToken.allowance(msg.sender,address(this)) >= _tip,"Allowance must be set");
        //If the tip > 0 transfer the tip to this contract
        require (_tip >= 5, "Tip must be greater than 5");//must be greater than 5 loyas so each miner gets at least 1 loya
        tellorToken.transferFrom(msg.sender, address(this), _tip);
        //Update the information for the request that should be mined next based on the tip submitted
        updateOnDeck(self, _requestId, _tip);
        emit TipAdded(msg.sender, _requestId, _tip, self.requestDetails[_requestId].apiUintVars[keccak256("totalTip")]);
    }

    /**
    * @dev This function is called by submitMiningSolution and adjusts the difficulty, sorts and stores the first
    * 5 values received, pays the miners, the dev share and assigns a new challenge
    * @param _requestId for the current request being mined
    */
    function newBlock(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) internal {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
        uint256 _timeOfLastNewValue = now - (now % 1 minutes);
        self.uintVars[keccak256("timeOfLastNewValue")] = _timeOfLastNewValue;
        //The sorting algorithm that sorts the values of the first five values that come in
        TellorStorage.Details[5] memory a = self.currentMiners;
                uint256 i;
                for (i = 1; i < 5; i++) {
                    uint256 temp = a[i].value;
                    address temp2 = a[i].miner;
                    uint256 j = i;
                    while (j > 0 && temp < a[j - 1].value) {
                        a[j].value = a[j - 1].value;
                        a[j].miner = a[j - 1].miner;
                        j--;
                    }
                    if (j < i) {
                        a[j].value = temp;
                        a[j].miner = temp2;
                    }
                }
        //Pay the miners
        for (i = 0; i < 5; i++) {
            tellorToken.transfer(a[i].miner, self.uintVars[keccak256("currentTotalTips")] / 5);
        }
        emit NewValue(
            _requestId,
            _timeOfLastNewValue,
            a[2].value,
            self.uintVars[keccak256("currentTotalTips")] - (self.uintVars[keccak256("currentTotalTips")] % 5),
            self.currentChallenge
        );
        //Save the official(finalValue), timestamp of it, 5 miners and their submitted values for it, and its block number
        _request.finalValues[_timeOfLastNewValue] = a[2].value;
        _request.requestTimestamps.push(_timeOfLastNewValue);
        //these are miners by timestamp
        _request.minersByValue[_timeOfLastNewValue] = [a[0].miner, a[1].miner, a[2].miner, a[3].miner, a[4].miner];
        _request.valuesByTimestamp[_timeOfLastNewValue] = [a[0].value, a[1].value, a[2].value, a[3].value, a[4].value];
        _request.minedBlockNum[_timeOfLastNewValue] = block.number;
        //map the timeOfLastValue to the requestId that was just mined

        self.requestIdByTimestamp[_timeOfLastNewValue] = _requestId;
        //add timeOfLastValue to the newValueTimestamps array
        self.newValueTimestamps.push(_timeOfLastNewValue);
        //re-start the count for the slot progress to zero before the new request mining starts
        self.uintVars[keccak256("slotProgress")] = 0;
        uint256 _topId = TellorGettersLibrary.getTopRequestID(self);
        self.uintVars[keccak256("currentRequestId")] = _topId;
        //if the currentRequestId is not zero(currentRequestId exists/something is being mined) select the requestId with the hightest payout
        //else wait for a new tip to mine
        if (_topId > 0) {
            selectNewValidators(self,true);
            self.currentChallenge = keccak256(abi.encodePacked(randomnumber(self,_timeOfLastNewValue,a[2].value), self.currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
            //Update the current request to be mined to the requestID with the highest payout
            self.uintVars[keccak256("currentTotalTips")] = self.requestDetails[_topId].apiUintVars[keccak256("totalTip")];
            //Remove the currentRequestId/onDeckRequestId from the requestQ array containing the rest of the 50 requests
            self.requestQ[self.requestDetails[_topId].apiUintVars[keccak256("requestQPosition")]] = 0;

            //unmap the currentRequestId/onDeckRequestId from the requestIdByRequestQIndex
            self.requestIdByRequestQIndex[self.requestDetails[_topId].apiUintVars[keccak256("requestQPosition")]] = 0;

            //Remove the requestQposition for the currentRequestId/onDeckRequestId since it will be mined next
            self.requestDetails[_topId].apiUintVars[keccak256("requestQPosition")] = 0;

            //Reset the requestId TotalTip to 0 for the currentRequestId/onDeckRequestId since it will be mined next
            //and the tip is going to the current timestamp miners. The tip for the API needs to be reset to zero
            self.requestDetails[_topId].apiUintVars[keccak256("totalTip")] = 0;
            //gets the max tip in the in the requestQ[51] array and its index within the array??
            uint256 newRequestId = TellorGettersLibrary.getTopRequestID(self);
            //Issue the the next requestID 
           emit NewChallenge(
                self.currentChallenge,
                _topId,
                self.uintVars[keccak256("currentTotalTips")]
            );
            emit NewRequestOnDeck(
                newRequestId,
                self.requestDetails[newRequestId].apiUintVars[keccak256("totalTip")]
            );
        } else {
            self.uintVars[keccak256("currentTotalTips")] = 0;
            self.currentChallenge = "";
            self.selectedValidators.length = 0;
        }
    }

    /**
    * @dev Proof of work is called by the miner when they submit the solution (proof of work and value)
    * @param _requestId the apiId being mined
    * @param _value of api query
    */
    function submitMiningSolution(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _value)
        public
    {
        //requre miner is staked
        require(self.stakerDetails[msg.sender].currentStatus == 1, "Miner status is not staker");
        //Check the miner is submitting the pow for the current request Id
        require(_requestId == self.uintVars[keccak256("currentRequestId")], "RequestId is wrong");     
        //Check the validator submitting data is one of the selected validators
        require(self.validValidator[msg.sender] == true, "Not a selected validator");
        //Make sure the miner does not submit a value more than once
        require(self.minersByChallenge[self.currentChallenge][msg.sender] == false, "Miner already submitted the value");
        //Save the miner and value received
        self.currentMiners[self.uintVars[keccak256("slotProgress")]].value = _value;
        self.currentMiners[self.uintVars[keccak256("slotProgress")]].miner = msg.sender;
        //Add to the count how many values have been submitted, since only 5 are taken per request
        self.uintVars[keccak256("slotProgress")]++;
        //Update the miner status to true once they submit a value so they don't submit more than once
        self.minersByChallenge[self.currentChallenge][msg.sender] = true;
        emit SolutionSubmitted(msg.sender, _requestId, _value, self.currentChallenge);
        //If 5 values have been received, adjust the difficulty otherwise sort the values until 5 are received
        //Once a validator submits data set their status back to false
        self.validValidator[msg.sender] = false;
        if (self.uintVars[keccak256("slotProgress")] == 5) {
            newBlock(self, _requestId);
        }
    }

   /**
    * @dev This function updates APIonQ and the requestQ when requestData or addTip are ran
    * @param _requestId being requested
    * @param _tip is the tip to add
    */
    function updateOnDeck(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _tip) internal {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        uint256 onDeckRequestId = TellorGettersLibrary.getTopRequestID(self);
        _request.apiUintVars[keccak256("totalTip")] = _request.apiUintVars[keccak256("totalTip")].add(_tip);
        //Set _payout for the submitted request
        uint256 _payout = _request.apiUintVars[keccak256("totalTip")];
        //If there is no current request being mined
        //then set the currentRequestId to the requestid of the requestData or addtip requestId submitted,
        // the totalTips to the payout/tip submitted, and issue a new mining challenge
        if (self.uintVars[keccak256("currentRequestId")] == 0) {
            self.uintVars[keccak256("currentRequestId")] = _requestId;
            self.uintVars[keccak256("currentTotalTips")] = _payout;
            self.currentChallenge = keccak256(abi.encodePacked(_payout, self.currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
            selectNewValidators(self,true);
            emit NewChallenge(
                self.currentChallenge,
                self.uintVars[keccak256("currentRequestId")],
                self.uintVars[keccak256("currentTotalTips")]
            );
        } else if (_requestId == self.uintVars[keccak256("currentRequestId")]) {
                self.uintVars[keccak256("currentTotalTips")] = self.uintVars[keccak256("currentTotalTips")] + _payout;
        }else {
            //If there is no OnDeckRequestId
            //then replace/add the requestId to be the OnDeckRequestId, queryHash and OnDeckTotalTips(current highest payout, aside from what
            //is being currently mined)
            if (_payout > self.requestDetails[onDeckRequestId].apiUintVars[keccak256("totalTip")]) {
                //let everyone know the next on queue has been replaced
                emit NewRequestOnDeck(_requestId, _payout);
            }

            //if the request is not part of the requestQ[51] array
            //then add to the requestQ[51] only if the _payout/tip is greater than the minimum(tip) in the requestQ[51] array
            if (_request.apiUintVars[keccak256("requestQPosition")] == 0) {
                uint256 _min;
                uint256 _index;
                (_min, _index) = Utilities.getMin(self.requestQ);
                //we have to zero out the oldOne
                //if the _payout is greater than the current minimum payout in the requestQ[51] or if the minimum is zero
                //then add it to the requestQ array aand map its index information to the requestId and the apiUintvars
                if (_payout > _min) {
                    self.requestQ[_index] = _payout;
                    self.requestDetails[self.requestIdByRequestQIndex[_index]].apiUintVars[keccak256("requestQPosition")] = 0;
                    self.requestIdByRequestQIndex[_index] = _requestId;
                    _request.apiUintVars[keccak256("requestQPosition")] = _index;
                }
                // else if the requestid is part of the requestQ[51] then update the tip for it
            } else{
                self.requestQ[_request.apiUintVars[keccak256("requestQPosition")]] = _payout;
            }
        }
    }
    
    /**
    * @dev Reselects validators if any of the first five fail to submit data
    */
    function reselectNewValidators(TellorStorage.TellorStorageStruct storage self) public{
        require( self.uintVars[keccak256("lastSelection")] < now - 30, "has not been long enough reselect");
        selectNewValidators(self,false);// ??? Does false mean to select new validators?
    }

    /**
    * @dev Generates a random number to select validators
    */
    function randomnumber(TellorStorage.TellorStorageStruct storage self, uint _max, uint _nonce) internal view returns (uint){
        return  uint(keccak256(abi.encodePacked(_nonce,now,self.uintVars[keccak256("totalTip")],msg.sender,block.difficulty,self.stakers.length))) % _max;
    }

    /**
    * @dev Selects validators
    * @param _reset true to delete existing validators and re-selected
    */
    function selectNewValidators(TellorStorage.TellorStorageStruct storage self, bool _reset) public{
        if(_reset){
            self.selectedValidators.length = 0;
        }   
        uint j=0;
        uint i=0;
        uint r;
        address potentialValidator;
         while(j < 5 && self.stakers.length > self.selectedValidators.length){
            i++;
            r = randomnumber(self,self.stakers.length,i);
            potentialValidator = self.stakers[r];
            if(!self.validValidator[potentialValidator]){
                    self.selectedValidators.push(potentialValidator);
                    emit NewValidatorsSelected(potentialValidator);
                    self.validValidator[potentialValidator] = true;//used to check if they are a selectedvalidator (better than looping through array)
                    j++;
            }
       }
         self.uintVars[keccak256("lastSelected")] = now;
    }
}



//Slightly modified SafeMath library - includes a min and max function, removes useless div function
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a + b;
            assert(c >= a);
        } else {
            c = a + b;
            assert(c <= a);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (uint256) {
        return a > b ? uint256(a) : uint256(b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a - b;
            assert(c <= a);
        } else {
            c = a - b;
            assert(c >= a);
        }

    }
}


/**
 * @title Tellor Oracle Storage Library
 * @dev Contains all the variables/structs used by Tellor
 */

library TellorStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint256 value;
        address miner;
    }

    struct Dispute {
        bytes32 hash; //unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int256 tally; //current tally of votes for - against measure
        bool executed; //is the dispute settled
        bool disputeVotePassed; //did the vote pass?
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        mapping(bytes32 => uint256) disputeUintVars;
        //Each of the variables below is saved in the mapping disputeUintVars for each disputeID
        //e.g. TellorStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestId");//apiID of disputed value
        // uint keccak256("timestamp");//timestamp of distputed value
        // uint keccak256("value"); //the value being disputed
        // uint keccak256("minExecutionDate");//7 days from when dispute initialized
        // uint keccak256("numberOfVotes");//the number of parties who have voted on the measure
        // uint keccak256("blockNumber");// the blocknumber for which votes will be calculated from
        // uint keccak256("minerSlot"); //index in dispute array
        // uint keccak256("quorum"); //quorum for dispute vote NEW
        // uint keccak256("fee"); //fee paid corresponding to dispute
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }

    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute
        uint256 startDate; //stake start date
        uint256 withdrawDate;
        uint256 withdrawAmount;
        uint[] stakePosition;
        mapping(uint => uint) stakePositionArrayIndex;
    }


    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }

    struct Request {
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        //Each of the variables below is saved in the mapping apiUintVars for each api request
        //e.g. requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestQPosition"); //index in requestQ
        // uint keccak256("totalTip");//bonus portion of payout
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    struct TellorStorageStruct {
        address[] selectedValidators;
        address[]  stakers; 
        mapping(address => uint) missedCalls;//if your missed calls gets up to 3, you lose a TRB.  A successful retrieval resets its
        mapping(address => bool) validValidator; //ensures only selected validators can sumbmit data
        bytes32 currentChallenge; //current challenge to be solved
        uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
        uint256[] newValueTimestamps; //array of all timestamps requested
        Details[5] currentMiners; //This struct is for organizing the five mined values to find the median
        mapping(bytes32 => address) addressVars;
        //Address fields in the Tellor contract are saved the addressVars mapping
        //e.g. addressVars[keccak256("tellorContract")] = address
        //These are the variables saved in this mapping:
        // address keccak256("tellorContract");//Tellor address
        // address  keccak256("_deity");//Tellor Owner that can do things at will
        mapping(bytes32 => uint256) uintVars;
        //uint fields in the Tellor contract are saved the uintVars mapping
        //e.g. uintVars[keccak256("decimals")] = uint
        //These are the variables saved in this mapping:
        // keccak256("decimals");    //18 decimal standard ERC20
        // keccak256("disputeFee");//cost to dispute a mined value
        // keccak256("disputeCount");//totalHistoricalDisputes
        // keccak256("total_supply"); //total_supply of the token in circulation
        // keccak256("stakeAmount");//stakeAmount for miners (we can cut gas if we just hardcode it in...or should it be variable?)
        // keccak256("stakerCount"); //number of parties currently staked
        // keccak256("timeOfLastNewValue"); // time of last challenge solved
        // keccak256("difficulty"); // Difficulty of current block
        // keccak256("currentTotalTips"); //value of highest api/timestamp PayoutPool
        // keccak256("currentRequestId"); //API being mined--updates with the ApiOnQ Id
        // keccak256("requestCount"); // total number of requests through the system
        // keccak256("slotProgress");//Number of miners who have mined this value so far
        // keccak256("miningReward");//Mining Reward in PoWo tokens given to all miners per value
        // keccak256("timeTarget"); //The time between blocks (mined Oracle values)
        //keccak256("minimumPayment") //The minimum payment in TRB for a data request
        // keccak256("uniqueStakers")//Number of unique stakers
        // keccak256("lastSelected") //Time we last selected validators
        //This is a boolean that tells you if a given challenge has been completed by a given miner
        mapping(bytes32 => mapping(address => bool)) minersByChallenge;
        mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
        mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
        mapping(uint256 => Dispute) disputesById; //disputeId=> Dispute details
        mapping(address => Checkpoint[]) balances; //balances of a party given blocks
        mapping(address => mapping(address => uint256)) allowed; //allowance for a given party and approver
        mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
        mapping(uint256 => Request) requestDetails; //mapping of apiID to details
        mapping(bytes32 => uint256[]) disputeIdsByDisputeHash; //maps a hash to an ID for each dispute
    }
}


/**
* @title Tellor Transfer
* @dev Contais the methods related to transfers and ERC20. Tellor.sol and TellorGetters.sol
* reference this library for function's logic.
*/

library TellorTransfer {
    using SafeMath for uint256;

    /*Functions*/
    /**
    * @dev Gets balance of owner specified
    * @param _user is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _user
    */
    function balanceOf(TellorStorage.TellorStorageStruct storage self, address _user) public view returns (uint256) {
        return balanceOfAt(self, _user, block.number);
    }
    
    /**
    * @dev Completes POWO transfers by updating the balances on the current block number
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer
    */
    function doTransfer(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount) internal {
        require(_amount > 0, "Tried to send non-positive amount");
        uint256 previousBalance;
        if(_from != address(this)){
            require(balanceOf(self, _from).sub(_amount) >= 0, "Stake amount was not removed from balance");        
            previousBalance = balanceOfAt(self, _from, block.number);
            updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        }
        previousBalance = balanceOfAt(self, _to, block.number);
        require(previousBalance + _amount >= previousBalance, "Overflow happened"); // Check for overflow
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
    }

    /**
    * @dev Queries the balance of _user at a specific _blockNumber
    * @param _user The address from which the balance will be retrieved
    * @param _blockNumber The block number when the balance is queried
    * @return The balance at _blockNumber specified
    */
    function balanceOfAt(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _blockNumber) public view returns (uint256) {
        if ((self.balances[_user].length == 0) || (self.balances[_user][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getBalanceAt(self.balances[_user], _blockNumber);
        }
    }

    /**
    * @dev Getter for balance for owner on the specified _block number
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _block is the block number to search the balance on
    * @return the balance at the checkpoint
    */
    function getBalanceAt(TellorStorage.Checkpoint[] storage checkpoints, uint256 _block) public view returns (uint256) {
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock) return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /**
    * @dev Updates balance for from and to on the current block number via doTransfer
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _value is the new balance
    */
    function updateBalanceAtNow(TellorStorage.Checkpoint[] storage checkpoints, uint256 _value) public {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            TellorStorage.Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}




/**
* itle Tellor Stake
* @dev Contains the methods related to miners staking and unstaking. Tellor.sol
* references this library for function's logic.
*/

library TellorStake {
    event NewStake(address indexed _sender); //Emits upon new staker
    event StakeWithdrawn(address indexed _sender); //Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender); //Emits when a staker begins the 7 day withdraw period

    /*Functions*/

    /**
    * @dev This function allows stakers to request to withdraw their stake (no longer stake)
    * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
    * can withdraw the deposit
    */
    function requestStakingWithdraw(TellorStorage.TellorStorageStruct storage self, uint _amount) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        require(stakes.currentStatus == 1, "Miner is not staked");
        require(_amount % self.uintVars[keccak256("minimumStake")] == 0, "Must be divisible by minimumStake");
        require(_amount <= TellorTransfer.balanceOf(self,msg.sender));
        for(uint i=0; i < _amount / self.uintVars[keccak256("minimumStake")]; i++) {
            removeFromStakerArray(self, stakes.stakePosition[i],msg.sender);
        }
       //Change the miner staked to locked to be withdrawStake
        if (TellorTransfer.balanceOf(self,msg.sender) - _amount == 0){
            stakes.currentStatus = 2;
        }
        stakes.withdrawDate = now - (now % 86400);
        stakes.withdrawAmount = _amount;
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
    * @dev This function allows users to withdraw their stake after a 7 day waiting period from request
    */
    function withdrawStake(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have
        //passed by since they locked for withdraw
        require(now - (now % 86400) - stakes.withdrawDate >= 7 days, "7 days didn't pass");
        require(stakes.currentStatus !=3 , "Miner is under dispute");        
            TellorTransfer.doTransfer(self,msg.sender,address(0),stakes.withdrawAmount);
            if (TellorTransfer.balanceOf(self,msg.sender) == 0){
                stakes.currentStatus =0 ;
                self.uintVars[keccak256("stakerCount")] -= 1;
                self.uintVars[keccak256("uniqueStakers")] -= 1;
            }
            self.uintVars[keccak256("totalStaked")] -= stakes.withdrawAmount;
            TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
            tellorToken.transfer(msg.sender,stakes.withdrawAmount);
            emit StakeWithdrawn(msg.sender);
    }

    /**
    * @dev This function allows miners to deposit their stake
    * @param _amount is the amount to be staked
    */
    function depositStake(TellorStorage.TellorStorageStruct storage self, uint _amount) public {
       TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
        require(tellorToken.allowance(msg.sender,address(this)) >= _amount, "Proper amount must be allowed to this contract");
        tellorToken.transferFrom(msg.sender, address(this), _amount);
        //Ensure they can only stake if they are not currrently staked or if their stake time frame has ended
        //and they are currently locked for witdhraw
        require(self.stakerDetails[msg.sender].currentStatus == 0 ||  self.stakerDetails[msg.sender].currentStatus == 1, "Miner is in the wrong state");
        //if this is the first time this addres stakes count, then add them to the stake count
        if(TellorTransfer.balanceOf(self,msg.sender) == 0){
            self.uintVars[keccak256("uniqueStakers")] += 1;
        }
        require(_amount >= self.uintVars[keccak256("minimumStake")], "You must stake a certain amount");
        require(_amount % self.uintVars[keccak256("minimumStake")] == 0, "Must be divisible by minimumStake");
        for(uint i=0; i < _amount / self.uintVars[keccak256("minimumStake")]; i++){
            self.stakerDetails[msg.sender].stakePosition.push(self.stakers.length);
            //self.stakerDetails[msg.sender].stakePositionArrayIndex[self.stakerDetails[msg.sender].stakerPosition.length] = self.stakers.length;
            self.stakers.push(msg.sender);
            self.uintVars[keccak256("stakerCount")] += 1;
        }
        self.stakerDetails[msg.sender].currentStatus = 1;
        self.stakerDetails[msg.sender].startDate = now - (now % 86400);
        TellorTransfer.doTransfer(self,address(this),msg.sender,_amount);
        self.uintVars[keccak256("totalStaked")]  += _amount;
        emit NewStake(msg.sender);       
    }

    /**
    * @dev This function is used by requestStakingWithdraw to remove the staker from the stakers array
    * @param _pos is the staker's position in the array 
    * @param _staker is the staker's address
    */
    function removeFromStakerArray(TellorStorage.TellorStorageStruct storage self, uint _pos, address _staker) internal{
        address lastAdd;
        if(_pos == self.stakers.length-1){
            self.stakers.length--;
            self.stakerDetails[_staker].stakePosition.length--;
        }
        else{
            lastAdd = self.stakers[self.stakers.length-1];
            self.stakers[_pos] = lastAdd;
            self.stakers.length--;
            self.stakerDetails[_staker].stakePosition.length--;
        }
    }
}

interface TokenInterface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function balanceOfAt(address tokenOwner, uint256 blockNumber) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
* @title Tellor Dispute
* @dev Contains the methods related to disputes. Tellor.sol references this library for function's logic.
*/

library TellorDispute {
    using SafeMath for uint256;
    using SafeMath for int256;

    //emitted when a new dispute is initialized
    event NewDispute(uint256 indexed _disputeId, uint256 indexed _requestId, uint256 _timestamp, address _miner);
    //emitted when a new vote happens
    event Voted(uint256 indexed _disputeID, bool _position, address indexed _voter);
    //emitted upon dispute tally
    event DisputeVoteTallied(uint256 indexed _disputeID, int256 _result, address indexed _reportedMiner, address _reportingParty, bool _active);

    /*Functions*/

    /**
    * @dev Helps initialize a dispute by assigning it a disputeId
    * when a miner returns a false on the validate array(in Tellor.ProofOfWork) it sends the
    * invalidated value information to POS voting
    * @param _requestId being disputed
    * @param _timestamp being disputed
    * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
    * requires 5 miners to submit a value.
    */
    function beginDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        //require that no more than a day( (24 hours * 60 minutes)/10minutes=144 blocks) has gone by since the value was "mined"
        //require(now - _timestamp <= 1 days, "The value was mined more than a day ago");
        require(_request.minedBlockNum[_timestamp] > 0, "Mined block is 0");
        require(_minerIndex < 5, "Miner index is wrong");
        //_miner is the miner being disputed. For every mined value 5 miners are saved in an array and the _minerIndex
        //provided by the party initiating the dispute
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash = keccak256(abi.encodePacked(_miner, _requestId, _timestamp));
        if (self.disputeIdsByDisputeHash[_hash].length > 0){
                uint256 _finalId = self.disputeIdsByDisputeHash[_hash][self.disputeIdsByDisputeHash[_hash].length - 1];
                require(self.disputesById[_finalId].executed, "previous vote must be over with");
        } 

        //Increase the dispute count by 1
        self.uintVars[keccak256("disputeCount")] = self.uintVars[keccak256("disputeCount")] + 1;
        //Sets the new disputeCount as the disputeId
        uint256 disputeId = self.uintVars[keccak256("disputeCount")];
        //maps the dispute hash to the disputeId
        uint256 _fee = self.uintVars[keccak256("disputeFee")] * 2**self.disputeIdsByDisputeHash[_hash].length;
        self.disputeIdsByDisputeHash[_hash].push(disputeId);
        //Ensures that a dispute is not already open for the that miner, requestId and timestamp
        require(self.disputesById[self.disputeIdsByDisputeHash[_hash][0]].disputeUintVars[keccak256("minExecutionDate")] < now, "Dispute is already open");
        //Transfer dispute fee
        TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
        require(tellorToken.balanceOf(msg.sender) >= _fee, "Balance is too low to cover dispute fee");
        require(tellorToken.allowance(msg.sender,address(this)) >= _fee, "Proper amount must be allowed to this contract");
        tellorToken.transferFrom(msg.sender, address(this), _fee);  
        //maps the dispute to the Dispute struct
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            reportedMiner: _miner,
            reportingParty: msg.sender,
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });
        //Saves all the dispute variables for the disputeId
        self.disputesById[disputeId].disputeUintVars[keccak256("requestId")] = _requestId;
        self.disputesById[disputeId].disputeUintVars[keccak256("timestamp")] = _timestamp;
        self.disputesById[disputeId].disputeUintVars[keccak256("value")] = _request.valuesByTimestamp[_timestamp][_minerIndex];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 2 days * self.disputeIdsByDisputeHash[_hash].length;
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minerSlot")] = _minerIndex;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")] = _fee;
        //Values are sorted as they come in and the official value is the median of the first five
        //So the "official value" miner is always minerIndex==2. If the official value is being
        //disputed, it sets its status to inDispute(currentStatus = 3) so that users are made aware it is under dispute
        if (_minerIndex == 2) {
            _request.inDispute[_timestamp] = true;
            _request.finalValues[_timestamp] = 0;
        }
        self.stakerDetails[_miner].currentStatus = 3;
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }

    /**
    * @dev Allows token holders to vote
    * @param _disputeId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bool _supportsDispute) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        //Get the voteWeight or the balance of the user at the time/blockNumber the disupte began
        //if they are staked weigh vote based on their staked + unstaked balance of TRB on the side chain
        uint256 voteWeight;
        TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
        voteWeight = TellorTransfer.balanceOfAt(self, msg.sender, disp.disputeUintVars[keccak256("blockNumber")]) + tellorToken.balanceOfAt(msg.sender,disp.disputeUintVars[keccak256("blockNumber")]);
        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true, "Sender has already voted");
        //Requre that the user had a balance >0 at time/blockNumber the disupte began
        require(voteWeight > 0, "User balance is 0");
        //ensures miners that are under dispute cannot vote
        require(self.stakerDetails[msg.sender].currentStatus != 3, "Miner is under dispute");
        //Update user voting status to true
        disp.voted[msg.sender] = true;
        //Update the number of votes for the dispute
        disp.disputeUintVars[keccak256("numberOfVotes")] += 1;
        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        if (_supportsDispute) {
            disp.tally = disp.tally.add(int256(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int256(voteWeight));
        }
        //Let the network know the user has voted on the dispute and their casted vote
        emit Voted(_disputeId, _supportsDispute, msg.sender);
    }

    /**
    * @dev tallies the votes.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        //Ensure this has not already been executed/tallied
        require(disp.executed == false, "Dispute has been already executed");
        require(disp.reportingParty != address(0));
        //Ensure the time for voting has elapsed
        require(now > disp.disputeUintVars[keccak256("minExecutionDate")], "Time for voting haven't elapsed");
            TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];
            //If the vote for disputing a value is succesful(disp.tally >0) then unstake the reported
            // miner and transfer the stakeAmount and dispute fee to the reporting party
            if (disp.tally > 0) {
                //Set the dispute state to passed/true
                disp.disputeVotePassed = true;
            }
            if (stakes.currentStatus == 3){
                    stakes.currentStatus = 4;
            }
        //update the dispute status to executed
        disp.executed = true;
        disp.disputeUintVars[keccak256("tallyDate")] = now;
        emit DisputeVoteTallied(_disputeId, disp.tally, disp.reportedMiner, disp.reportingParty, disp.disputeVotePassed);
    }

    /**
    * @dev Unlocks the dispute fee
    * @param _disputeId is the dispute id
    */
    function unlockDisputeFee (TellorStorage.TellorStorageStruct storage self, uint _disputeId) public {
        bytes32 _hash = self.disputesById[_disputeId].hash;
        uint256 _finalId = self.disputeIdsByDisputeHash[_hash][self.disputeIdsByDisputeHash[_hash].length - 1];
        TellorStorage.Dispute storage disp = self.disputesById[_finalId];
        require(disp.disputeUintVars[keccak256("paid")] == 0,"already paid out");
        require(now - disp.disputeUintVars[keccak256("tallyDate")] > 1 days, "Time for voting haven't elapsed");
        TokenInterface tellorToken = TokenInterface(self.addressVars[keccak256("tellorToken")]);
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];
        disp.disputeUintVars[keccak256("paid")] = 1;
        if (disp.disputeVotePassed == true){
                //if reported miner stake has not been slashed yet, slash them and return the fee to reporting party
                if (stakes.currentStatus == 4) {
                    //Changing the currentStatus and startDate unstakes the reported miner and transfers the stakeAmount
                    self.uintVars[keccak256("stakerCount")] -= 1;
                    stakes.startDate = now - (now % 86400);
                    TellorStake.removeFromStakerArray(self, stakes.stakePosition[0],disp.reportedMiner);
                    //Decreases the stakerCount since the miner's stake is being slashed
                    TellorTransfer.doTransfer(self,disp.reportedMiner,address(0),self.uintVars[keccak256("minimumStake")]);
                    if (TellorTransfer.balanceOf(self,disp.reportedMiner) == 0){
                        stakes.currentStatus =0 ;
                        self.uintVars[keccak256("uniqueStakers")] -= 1;
                    }else{
                        stakes.currentStatus = 1;
                    }
                    self.uintVars[keccak256("totalStaked")] -= self.uintVars[keccak256("minimumStake")];
                    for(uint i = 1; i <= self.disputeIdsByDisputeHash[disp.hash].length;i++){
                        uint256 _id = self.disputeIdsByDisputeHash[_hash][i-1];
                        disp = self.disputesById[_id];
                        if(i == 1){
                            tellorToken.transfer(disp.reportingParty,self.uintVars[keccak256("minimumStake")] + disp.disputeUintVars[keccak256("fee")]);
                        }
                        else{
                            tellorToken.transfer(disp.reportingParty,disp.disputeUintVars[keccak256("fee")]);
                        }
                    }
                //if reported miner stake was already slashed, return the fee to other reporting paties
                } else {
                    for(uint i = 1; i <= self.disputeIdsByDisputeHash[disp.hash].length;i++){
                        uint256 _id = self.disputeIdsByDisputeHash[_hash][i-1];
                        disp = self.disputesById[_id];
                        tellorToken.transfer(disp.reportingParty,disp.disputeUintVars[keccak256("fee")]);
                    }
                }
            }
            else {
                if (stakes.currentStatus == 4){
                    stakes.currentStatus = 1;
                }
                TellorStorage.Request storage _request = self.requestDetails[disp.disputeUintVars[keccak256("requestId")]];
                if(disp.disputeUintVars[keccak256("minerSlot")] == 2) {
                    //note we still don't put timestamp back into array (is this an issue? (shouldn't be))
                  _request.finalValues[disp.disputeUintVars[keccak256("timestamp")]] = disp.disputeUintVars[keccak256("value")];
                }
                //tranfer the dispute fee to the miner
                if (_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true) {
                    _request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] = false;
                }
                for(uint i = 1; i <= self.disputeIdsByDisputeHash[disp.hash].length;i++){
                        uint256 _id = self.disputeIdsByDisputeHash[_hash][i-1];
                        disp = self.disputesById[_id];
                        tellorToken.transfer(disp.reportedMiner,disp.disputeUintVars[keccak256("fee")]);
                    }
            }
    }
}   


/**
* @title Tellor Getters
* @dev Oracle contract with all tellor getter functions. The logic for the functions on this contract
* is saved on the TellorGettersLibrary, TellorTransfer, TellorGettersLibrary, and TellorStake
*/

contract TellorGetters {
    using SafeMath for uint256;

    using TellorTransfer for TellorStorage.TellorStorageStruct;
    using TellorGettersLibrary for TellorStorage.TellorStorageStruct;
    using TellorStake for TellorStorage.TellorStorageStruct;
    using TellorDispute for TellorStorage.TellorStorageStruct;
    using TellorLibrary for TellorStorage.TellorStorageStruct;

    TellorStorage.TellorStorageStruct tellor;

    /**
    * @dev This function tells you if a given challenge has been completed by a given miner
    * @param _challenge the challenge to search for
    * @param _miner address that you want to know if they solved the challenge
    * @return true if the _miner address provided solved the
    */
    function didMine(bytes32 _challenge, address _miner) external view returns (bool) {
        return tellor.didMine(_challenge, _miner);
    }

    /**
    * @dev This function gets the balance of the specified user address
    * @param _user is the address to check the balance for
    */
    function balanceOf(address _user) external view returns(uint256){
        return tellor.balanceOf(_user);
    }

    /**
    * @dev This function gets the currently selected validators
    * @return an array of the currently selected validators
    */
    function getCurrentMiners() external view returns(address[] memory miners){
        return tellor.getCurrentMiners();
    }

    /**
    * @dev Checks if an address voted in a given dispute
    * @param _disputeId to look up
    * @param _address to look up
    * @return bool of whether or not party voted
    */
    function didVote(uint256 _disputeId, address _address) external view returns (bool) {
        return tellor.didVote(_disputeId, _address);
    }

    /**
    * @dev allows Tellor to read data from the addressVars mapping
    * @param _data is the keccak256("variable_name") of the variable that is being accessed.
    * These are examples of how the variables are saved within other functions:
    * addressVars[keccak256("_owner")]
    * addressVars[keccak256("tellorContract")]
    */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return tellor.getAddressVars(_data);
    }

    /**
    * @dev Gets all dispute variables
    * @param _disputeId to look up
    * @return bytes32 hash of dispute
    * @return bool executed where true if it has been voted on
    * @return bool disputeVotePassed
    * @return address of reportedMiner
    * @return address of reportingParty
    * @return uint of requestId
    * @return uint of timestamp
    * @return uint of value
    * @return uint of minExecutionDate
    * @return uint of numberOfVotes
    * @return uint of blocknumber
    * @return uint of minerSlot
    * @return uint of quorum
    * @return uint of fee
    * @return int count of the current tally
    */
    function getAllDisputeVars(uint256 _disputeId)
        public
        view
        returns (bytes32, bool, bool, address, address, uint256[9] memory, int256)
    {
        return tellor.getAllDisputeVars(_disputeId);
    }

    /**
    * @dev Getter function for variables for the requestId validators are currently providing data for
    * @return current challenge, curretnRequestId, total tip for the request
    */
    function getCurrentVariables() external view returns (bytes32, uint256, uint256) {
        return tellor.getCurrentVariables();
    }

    /**
    * @dev Checks if a given hash of validator,requestId has been disputed
    * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
    * @return uint array of disputeIds
    */
    function getDisputeIdsByDisputeHash(bytes32 _hash) external view returns (uint256[] memory) {
        return tellor.getDisputeIdsByDisputeHash(_hash);
    }

    /**
    * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
    * @param _disputeId is the dispute id;
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
    * the variables/strings used to save the data in the mapping. The variables names are
    * commented out under the disputeUintVars under the Dispute struct
    * @return uint value for the bytes32 data submitted
    */
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns (uint256) {
        return tellor.getDisputeUintVars(_disputeId, _data);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    * @return true if the is a timestamp for the lastNewValue
    */
    function getLastNewValue() external view returns (uint256, bool) {
        return tellor.getLastNewValue();
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @param _requestId being requested
    * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
    */
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool) {
        return tellor.getLastNewValueById(_requestId);
    }

    /**
    * @dev Gets blocknumber for mined timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up blocknumber
    * @return uint of the blocknumber which the dispute was mined
    */
    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp) external view returns (uint256) {
        return tellor.getMinedBlockNum(_requestId, _timestamp);
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return the 5 miners' addresses
    */
    function getMinersByRequestIdAndTimestamp(uint256 _requestId, uint256 _timestamp) external view returns (address[5] memory) {
        return tellor.getMinersByRequestIdAndTimestamp(_requestId, _timestamp);
    }

   /**
    * @dev Counts the number of values that have been submited for the request
    * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
    * request so far
    * @param _requestId the requestId to look up
    * @return uint count of the number of values received for the requestId
    */
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256) {
        return tellor.getNewValueCountbyRequestId(_requestId);
    }

    /**
    * @dev Getter function for the specified requestQ index
    * @param _index to look up in the requestQ array
    * @return uint of reqeuestId
    */
    function getRequestIdByRequestQIndex(uint256 _index) external view returns (uint256) {
        return tellor.getRequestIdByRequestQIndex(_index);
    }

    /**
    * @dev Getter function for requestId based on timestamp
    * @param _timestamp to check requestId
    * @return uint of reqeuestId
    */
    function getRequestIdByTimestamp(uint256 _timestamp) external view returns (uint256) {
        return tellor.getRequestIdByTimestamp(_timestamp);
    }

    /**
    * @dev Getter function for the requestQ array
    * @return the requestQ arrray
    */
    function getRequestQ() public view returns (uint256[51] memory) {
        return tellor.getRequestQ();
    }

    /**
    * @dev Allows access to the uint variables saved in the apiUintVars under the requestDetails struct
    * for the requestId specified
    * @param _requestId to look up
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
    * the variables/strings used to save the data in the mapping. The variables names are
    * commented out under the apiUintVars under the requestDetails struct
    * @return uint value of the apiUintVars specified in _data for the requestId specified
    */
    function getRequestUintVars(uint256 _requestId, bytes32 _data) external view returns (uint256) {
        return tellor.getRequestUintVars(_requestId, _data);
    }

    /**
    * @dev Gets the API struct variables that are not mappings
    * @param _requestId to look up
    * @return uint of index in requestQ array
    * @return uint of current payout/tip for this requestId
    */
    function getRequestVars(uint256 _requestId) external view returns (uint256, uint256) {
        return tellor.getRequestVars(_requestId);
    }

    /**
    * @dev This function allows users to retireve all information about a staker
    * @param _staker address of staker inquiring about
    * @return uint current state of staker
    * @return uint startDate of staking
    * @return uint stakePosition for the staker
    */
    function getStakerInfo(address _staker) external view returns (uint256, uint256,uint256) {
        return tellor.getStakerInfo(_staker);
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestampt to look up miners for
    * @return address[5] array of 5 addresses ofminers that mined the requestId
    */
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp) external view returns (uint256[5] memory) {
        return tellor.getSubmissionsByTimestamp(_requestId, _timestamp);
    }

    /**
    * @dev Gets the timestamp for the value based on their index
    * @param _requestID is the requestId to look up
    * @param _index is the value index to look up
    * @return uint timestamp
    */
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index) external view returns (uint256) {
        return tellor.getTimestampbyRequestIDandIndex(_requestID, _index);
    }

    /**
    * @dev Getter for the variables saved under the TellorStorageStruct uintVars variable
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
    * the variables/strings used to save the data in the mapping. The variables names are
    * commented out under the uintVars under the TellorStorageStruct struct
    * This is an example of how data is saved into the mapping within other functions:
    * self.uintVars[keccak256("stakerCount")]
    * @return uint of specified variable
    */
    function getUintVar(bytes32 _data) public view returns (uint256) {
        return tellor.getUintVar(_data);
    }

    /**
    * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
    * @return onDeck/info on request with highest payout-- RequestId, Totaltips
    */
    function getVariablesOnDeck() external view returns (uint256, uint256) {
        return tellor.getVariablesOnDeck();
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return bool true if requestId/timestamp is under dispute
    */
    function isInDispute(uint256 _requestId, uint256 _timestamp) external view returns (bool) {
        return tellor.isInDispute(_requestId, _timestamp);
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _requestId being requested
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256) {
        return tellor.retrieveData(_requestId, _timestamp);
    }

}



/**
 * @title Tellor Oracle System
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * The logic for this contract is in TellorLibrary.sol, TellorDispute.sol, TellorStake.sol,
 * and TellorTransfer.sol
 */
contract Tellor is TellorGetters{
    using SafeMath for uint256;

    event NewTellorToken(address _token);

    /*Functions*/
    constructor (address _tellorToken) public {
        tellor.uintVars[keccak256("decimals")] = 18;
        tellor.uintVars[keccak256("disputeFee")] = 10e18;
        tellor.uintVars[keccak256("minimumStake")] = 100e18;
        tellor.addressVars[keccak256("tellorToken")] = _tellorToken;
        emit NewTellorToken(_tellorToken);
    }
    /**
    * @dev Helps initialize a dispute by assigning it a disputeId
    * when a miner returns a false on the validate array(in Tellor.ProofOfWork) it sends the
    * invalidated value information to POS voting
    * @param _requestId being disputed
    * @param _timestamp being disputed
    * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
    * requires 5 miners to submit a value.
    */
    function beginDispute(uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) external {
        tellor.beginDispute(_requestId, _timestamp, _minerIndex);
    }

    /**
    * @dev Allows token holders to vote
    * @param _disputeId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(uint256 _disputeId, bool _supportsDispute) external {
        tellor.vote(_disputeId, _supportsDispute);
    }

    /**
    * @dev tallies the votes.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(uint256 _disputeId) external {
        tellor.tallyVotes(_disputeId);
    }
    /**
    * @dev Add tip to Request value from oracle
    * @param _requestId being requested to be mined
    * @param _tip amount the requester is willing to pay to be get on queue. Miners
    * mine the onDeckQueryHash, or the api with the highest payout pool
    */
    function addTip(uint256 _requestId, uint256 _tip) external {
        tellor.addTip(_requestId, _tip);
    }

    /**
    * @dev Proof of work is called by the miner when they submit the solution (proof of work and value)
    * @param _requestId the apiId being mined
    * @param _value of api query
    */
    function submitMiningSolution(uint256 _requestId, uint256 _value) external {
        tellor.submitMiningSolution(_requestId, _value);
    }

    /**
    * @dev This function allows miners to deposit their stake.
    * @param _amount is the amount the sender wants to stake
    */
    function depositStake(uint _amount) external {
        tellor.depositStake(_amount);
    }

    /**
    * @dev This function reselects validators if the originals did not complete the block
    */
    function reselectNewValidators() external{
        tellor.reselectNewValidators();
    }

    /**
    * @dev This function allows stakers to request to withdraw their stake (no longer stake)
    * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
    * can withdraw the stake
    * @param _amount to unstake
    */
    function requestStakingWithdraw(uint _amount) external {
        tellor.requestStakingWithdraw(_amount);
    }

    /**
    * @dev This function allows for the dispute fee to be unlocked after the dispute vote has elapsed
    * @param _disputeId is the disputeId to unlock the fee from
    */
    function  unlockDisputeFee (uint _disputeId) external{
        tellor.unlockDisputeFee(_disputeId);
    }

    /**
    * @dev This function allows users to withdraw their stake after a 7 day waiting period from request
    */
    function withdrawStake() external {
        tellor.withdrawStake();
    }

    /**
    * @dev Allows users to access the token's name
    */
    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }

    /**
    * @dev Allows users to access the token's symbol
    */
    function symbol() external pure returns (string memory) {
        return "TRB";
    }

    /**
    * @dev Allows users to access the number of decimals
    */
    function decimals() external pure returns (uint8) {
        return 18;
    }

}