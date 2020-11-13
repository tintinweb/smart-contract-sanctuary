/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.5.17;

interface IArbitrableTCR {

    enum Party {
        None,      // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change an address status.
        Challenger // Party that challenges the request to change an address status.
    }

    function governor() external view returns(address);
    function arbitrator() external view returns(address);
    function arbitratorExtraData() external view returns(bytes memory);
    function requesterBaseDeposit() external view returns(uint);
    function challengerBaseDeposit() external view returns(uint);
    function challengePeriodDuration() external view returns(uint);
    function metaEvidenceUpdates() external view returns(uint);
    function winnerStakeMultiplier() external view returns(uint);
    function loserStakeMultiplier() external view returns(uint);
    function sharedStakeMultiplier() external view returns(uint);
    function MULTIPLIER_DIVISOR() external view returns(uint);
    function countByStatus()
        external
        view
        returns(
            uint absent,
            uint registered,
            uint registrationRequest,
            uint clearingRequest,
            uint challengedRegistrationRequest,
            uint challengedClearingRequest
        );
}

interface IArbitrableAddressTCR {
    enum AddressStatus {
        Absent, // The address is not in the registry.
        Registered, // The address is in the registry.
        RegistrationRequested, // The address has a request to be added to the registry.
        ClearingRequested // The address has a request to be removed from the registry.
    }

    function addressCount() external view returns(uint);
    function addressList(uint index) external view returns(address);
    function getAddressInfo(address _address)
        external
        view
        returns (
            AddressStatus status,
            uint numberOfRequests
        );

    function getRequestInfo(address _address, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address[3] memory parties,
            uint numberOfRounds,
            IArbitrableTCR.Party ruling,
            address arbitrator,
            bytes memory arbitratorExtraData
        );

    function getRoundInfo(address _address, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] memory paidFees,
            bool[3] memory hasPaid,
            uint feeRewards
        );
}

interface IArbitrableTokenTCR {

    enum TokenStatus {
        Absent, // The address is not in the registry.
        Registered, // The address is in the registry.
        RegistrationRequested, // The address has a request to be added to the registry.
        ClearingRequested // The address has a request to be removed from the registry.
    }

    function tokenCount() external view returns(uint);
    function tokensList(uint index) external view returns(bytes32);
    function getTokenInfo(bytes32 _tokenID)
        external
        view
        returns (
            string memory name,
            string memory ticker,
            address addr,
            string memory symbolMultihash,
            TokenStatus status,
            uint numberOfRequests
        );

    function getRequestInfo(bytes32 _tokenID, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address[3] memory parties,
            uint numberOfRounds,
            IArbitrableTCR.Party ruling,
            address arbitrator,
            bytes memory arbitratorExtraData
        );

    function getRoundInfo(bytes32 _tokenID, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] memory paidFees,
            bool[3] memory hasPaid,
            uint feeRewards
        );

    function addressToSubmissions(address _addr, uint _index) external view returns (bytes32);
}

interface IArbitrator {
    enum DisputeStatus {Waiting, Appealable, Solved}

    function createDispute(uint _choices, bytes calldata _extraData) external payable returns(uint disputeID);
    function arbitrationCost(bytes calldata _extraData) external view returns(uint cost);
    function appeal(uint _disputeID, bytes calldata _extraData) external payable;
    function appealCost(uint _disputeID, bytes calldata _extraData) external view returns(uint cost);
    function appealPeriod(uint _disputeID) external view returns(uint start, uint end);
    function disputeStatus(uint _disputeID) external view returns(DisputeStatus status);
    function currentRuling(uint _disputeID) external view returns(uint ruling);
}

pragma experimental ABIEncoderV2;


contract ArbitrableTCRView {

    struct CountByStatus {
        uint absent;
        uint registered;
        uint registrationRequest;
        uint clearingRequest;
        uint challengedRegistrationRequest;
        uint challengedClearingRequest;
    }

    struct ArbitrableTCRData {
        address governor;
        address arbitrator;
        bytes arbitratorExtraData;
        uint requesterBaseDeposit;
        uint challengerBaseDeposit;
        uint challengePeriodDuration;
        uint metaEvidenceUpdates;
        uint winnerStakeMultiplier;
        uint loserStakeMultiplier;
        uint sharedStakeMultiplier;
        uint MULTIPLIER_DIVISOR;
        CountByStatus countByStatus;
        uint arbitrationCost;
    }

    struct Token {
        bytes32 ID;
        string name;
        string ticker;
        address addr;
        string symbolMultihash;
        IArbitrableTokenTCR.TokenStatus status;
        uint decimals;
    }

    // Some arrays below have 3 elements to map with the Party enums for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Request {
        bool disputed;
        uint disputeID;
        uint submissionTime;
        bool resolved;
        address[3] parties;
        uint numberOfRounds;
        IArbitrableTCR.Party ruling;
        address arbitrator;
        bytes arbitratorExtraData;
        IArbitrator.DisputeStatus disputeStatus;
        uint currentRuling;
        uint appealCost;
        uint[3] requiredForSide;
        uint[2] appealPeriod;
        uint[3] paidFees;
        uint feeRewards;
        bool[3] hasPaid;
        bool appealed;
    }

    struct AppealableToken {
        uint disputeID;
        address arbitrator;
        bytes32 tokenID;
        bool inAppealPeriod;
    }

    struct AppealableAddress {
        uint disputeID;
        address arbitrator;
        address addr;
        bool inAppealPeriod;
    }

    /** @dev Fetch arbitrable TCR data in a single call.
     *  @param _address The address of the Generalized TCR to query.
     *  @return The latest data on an arbitrable TCR contract.
     */
    function fetchArbitrable(address _address) public view returns (ArbitrableTCRData memory result) {
        IArbitrableTCR tcr = IArbitrableTCR(_address);
        result.governor = tcr.governor();
        result.arbitrator = tcr.arbitrator();
        result.arbitratorExtraData = tcr.arbitratorExtraData();
        result.requesterBaseDeposit = tcr.requesterBaseDeposit();
        result.challengerBaseDeposit = tcr.challengerBaseDeposit();
        result.challengePeriodDuration = tcr.challengePeriodDuration();
        result.metaEvidenceUpdates = tcr.metaEvidenceUpdates();
        result.winnerStakeMultiplier = tcr.winnerStakeMultiplier();
        result.loserStakeMultiplier = tcr.loserStakeMultiplier();
        result.sharedStakeMultiplier = tcr.sharedStakeMultiplier();
        result.MULTIPLIER_DIVISOR = tcr.MULTIPLIER_DIVISOR();

        {
            (
                uint absent,
                uint registered,
                uint registrationRequest,
                uint clearingRequest,
                uint challengedRegistrationRequest,
                uint challengedClearingRequest
            ) = tcr.countByStatus();
            result.countByStatus = CountByStatus({
                absent: absent,
                registered: registered,
                registrationRequest: registrationRequest,
                clearingRequest: clearingRequest,
                challengedRegistrationRequest: challengedRegistrationRequest,
                challengedClearingRequest: challengedClearingRequest
            });
        }

        IArbitrator arbitrator = IArbitrator(result.arbitrator);
        result.arbitrationCost = arbitrator.arbitrationCost(result.arbitratorExtraData);
    }

    function fetchAppealableAddresses(address _addressTCR, uint _cursor, uint _count) external view returns (AppealableAddress[] memory results) {
        IArbitrableAddressTCR tcr = IArbitrableAddressTCR(_addressTCR);
        results = new AppealableAddress[]( tcr.addressCount() < _count ?  tcr.addressCount() : _count);

        for (uint i = _cursor; i < tcr.addressCount() && _count - i > 0; i++) {
            address itemAddr = tcr.addressList(i);
            (
                IArbitrableAddressTCR.AddressStatus status,
                uint numberOfRequests
            ) = tcr.getAddressInfo(itemAddr);

            if (status == IArbitrableAddressTCR.AddressStatus.Absent || status == IArbitrableAddressTCR.AddressStatus.Registered) continue;

            // Using arrays to get around stack limit.
            bool[] memory disputedResolved = new bool[](2);
            uint[] memory disputeIDNumberOfRounds = new uint[](2);
            address arbitrator;
            (
                disputedResolved[0],
                disputeIDNumberOfRounds[0],
                ,
                disputedResolved[1],
                ,
                disputeIDNumberOfRounds[1],
                ,
                arbitrator,
            ) = tcr.getRequestInfo(itemAddr, numberOfRequests - 1);

            if (!disputedResolved[0] || disputedResolved[1]) continue;

            IArbitrator arbitratorContract = IArbitrator(arbitrator);
            uint[] memory appealPeriod = new uint[](2);
            (appealPeriod[0], appealPeriod[1]) = arbitratorContract.appealPeriod(disputeIDNumberOfRounds[0]);
            if (appealPeriod[0] > 0 && appealPeriod[1] > 0) {
                results[i] = AppealableAddress({
                    disputeID: disputeIDNumberOfRounds[0],
                    arbitrator: arbitrator,
                    addr: itemAddr,
                    inAppealPeriod: now < appealPeriod[1]
                });

                // If the arbitrator gave a decisive ruling (i.e. did not rule for Party.None)
                // we must check if the loser fully funded and the dispute is in the second half
                // of the appeal period. If the dispute is in the second half, and the loser is not
                // funded the appeal period is over.
                IArbitrableTCR.Party currentRuling = IArbitrableTCR.Party(arbitratorContract.currentRuling(disputeIDNumberOfRounds[0]));
                if (
                    currentRuling != IArbitrableTCR.Party.None &&
                    now > (appealPeriod[1] - appealPeriod[0]) / 2 + appealPeriod[0]
                ) {
                    IArbitrableTCR.Party loser = currentRuling == IArbitrableTCR.Party.Requester
                        ? IArbitrableTCR.Party.Challenger
                        : IArbitrableTCR.Party.Requester;

                    (
                        ,
                        ,
                        bool[3] memory hasPaid,
                    ) = tcr.getRoundInfo(itemAddr, numberOfRequests - 1, disputeIDNumberOfRounds[1] - 1);

                    if(!hasPaid[uint(loser)]) results[i].inAppealPeriod = false;
                }
            }
        }
    }

    function fetchAppealableToken(address _addressTCR, uint _cursor, uint _count) external view returns (AppealableToken[] memory results) {
        IArbitrableTokenTCR tcr = IArbitrableTokenTCR(_addressTCR);
        results = new AppealableToken[](tcr.tokenCount() < _count ? tcr.tokenCount() : _count);

        for (uint i = _cursor; i < tcr.tokenCount() && _count - i > 0; i++) {
            bytes32 tokenID = tcr.tokensList(i);
            (
                ,
                ,
                ,
                ,
                IArbitrableTokenTCR.TokenStatus status,
                uint numberOfRequests
            ) = tcr.getTokenInfo(tokenID);

            if (status == IArbitrableTokenTCR.TokenStatus.Absent || status == IArbitrableTokenTCR.TokenStatus.Registered) continue;

            // Using arrays to get around stack limit.
            bool[] memory disputedResolved = new bool[](2);
            uint[] memory disputeIDNumberOfRounds = new uint[](2);
            address arbitrator;
            (
                disputedResolved[0],
                disputeIDNumberOfRounds[0],
                ,
                disputedResolved[1],
                ,
                disputeIDNumberOfRounds[1],
                ,
                arbitrator,
            ) = tcr.getRequestInfo(tokenID, numberOfRequests - 1);

            if (!disputedResolved[0] || disputedResolved[1]) continue;

            IArbitrator arbitratorContract = IArbitrator(arbitrator);
            uint[] memory appealPeriod = new uint[](2);
            (appealPeriod[0], appealPeriod[1]) = arbitratorContract.appealPeriod(disputeIDNumberOfRounds[0]);
            if (appealPeriod[0] > 0 && appealPeriod[1] > 0) {
                results[i] = AppealableToken({
                    disputeID: disputeIDNumberOfRounds[0],
                    arbitrator: arbitrator,
                    tokenID: tokenID,
                    inAppealPeriod: now < appealPeriod[1]
                });

                // If the arbitrator gave a decisive ruling (i.e. did not rule for Party.None)
                // we must check if the loser fully funded and the dispute is in the second half
                // of the appeal period. If the dispute is in the second half, and the loser is not
                // funded the appeal period is over.
                IArbitrableTCR.Party currentRuling = IArbitrableTCR.Party(arbitratorContract.currentRuling(disputeIDNumberOfRounds[0]));
                if (
                    currentRuling != IArbitrableTCR.Party.None &&
                    now > (appealPeriod[1] - appealPeriod[0]) / 2 + appealPeriod[0]
                ) {
                    IArbitrableTCR.Party loser = currentRuling == IArbitrableTCR.Party.Requester
                        ? IArbitrableTCR.Party.Challenger
                        : IArbitrableTCR.Party.Requester;

                    (
                        ,
                        ,
                        bool[3] memory hasPaid,
                    ) = tcr.getRoundInfo(tokenID, numberOfRequests - 1, disputeIDNumberOfRounds[1] - 1);

                    if(!hasPaid[uint(loser)]) results[i].inAppealPeriod = false;
                }
            }
        }
    }

    /** @dev Fetch token IDs of the first tokens present on the tcr for the addresses.
     *  @param _t2crAddress The address of the t2cr contract from where to fetch token information.
     *  @param _tokenAddresses The address of each token.
     */
    function getTokensIDsForAddresses(
        address _t2crAddress,
        address[] calldata _tokenAddresses
    ) external view returns (bytes32[] memory result) {
        IArbitrableTokenTCR t2cr = IArbitrableTokenTCR(_t2crAddress);
        result = new bytes32[](_tokenAddresses.length);
        for (uint i = 0; i < _tokenAddresses.length;  i++){
            // Count how many submissions were made for an address.
            address tokenAddr = _tokenAddresses[i];
            bool counting = true;
            bytes4 sig = bytes4(keccak256("addressToSubmissions(address,uint256)"));
            uint submissions = 0;
            while(counting) {
                assembly {
                    let x := mload(0x40)   // Find empty storage location using "free memory pointer"
                    mstore(x, sig)         // Set the signature to the first call parameter.
                    mstore(add(x, 0x04), tokenAddr)
                    mstore(add(x, 0x24), submissions)
                    counting := staticcall( // `counting` will be set to false if the call reverts (which will happen if we reached the end of the array.)
                        30000,              // 30k gas
                        _t2crAddress,       // The call target.
                        x,                  // Inputs are stored at location x
                        0x44,               // Input is 44 bytes long (signature (4B) + address (20B) + index(20B))
                        x,                  // Overwrite x with output
                        0x20                // The output length
                    )
                }

                if (counting) {
                    submissions++;
                }
            }

            // Search for the oldest submission currently in the registry.
            for(uint j = 0; j < submissions; j++) {
                bytes32 tokenID = t2cr.addressToSubmissions(tokenAddr, j);
                (,,,,IArbitrableTokenTCR.TokenStatus status,) = t2cr.getTokenInfo(tokenID);
                if (status == IArbitrableTokenTCR.TokenStatus.Registered || status == IArbitrableTokenTCR.TokenStatus.ClearingRequested)
                {
                    result[i] = tokenID;
                    break;
                }
            }
        }
    }

    /** @dev Fetch token information with token IDs. If a token contract does not implement the decimals() function, its decimals field will be 0.
     *  @param _t2crAddress The address of the t2cr contract from where to fetch token information.
     *  @param _tokenIDs The IDs of the tokens we want to query.
     *  @return tokens The tokens information.
     */
    function getTokens(address _t2crAddress, bytes32[] calldata _tokenIDs)
        external
        view
        returns (Token[] memory tokens)
    {
        IArbitrableTokenTCR t2cr = IArbitrableTokenTCR(_t2crAddress);
        tokens = new Token[](_tokenIDs.length);
        for (uint i = 0; i < _tokenIDs.length ; i++){
            string[] memory strings = new string[](3); // name, ticker and symbolMultihash respectively.
            address tokenAddress;
            IArbitrableTokenTCR.TokenStatus status;
            (
                strings[0],
                strings[1],
                tokenAddress,
                strings[2],
                status,
            ) = t2cr.getTokenInfo(_tokenIDs[i]);

            tokens[i] = Token(
                _tokenIDs[i],
                strings[0],
                strings[1],
                tokenAddress,
                strings[2],
                status,
                0
            );

            // Call the contract's decimals() function without reverting when
            // the contract does not implement it.
            //
            // Two things should be noted: if the contract does not implement the function
            // and does not implement the contract fallback function, `success` will be set to
            // false and decimals won't be set. However, in some cases (such as old contracts)
            // the fallback function is implemented, and so staticcall will return true
            // even though the value returned will not be correct (the number below):
            //
            // 22270923699561257074107342068491755213283769984150504402684791726686939079929
            //
            // We handle that edge case by also checking against this value.
            uint decimals;
            bool success;
            bytes4 sig = bytes4(keccak256("decimals()"));
            assembly {
                let x := mload(0x40)   // Find empty storage location using "free memory pointer"
                mstore(x, sig)          // Set the signature to the first call parameter. 0x313ce567 === bytes4(keccak256("decimals()")
                success := staticcall(
                    30000,              // 30k gas
                    tokenAddress,       // The call target.
                    x,                  // Inputs are stored at location x
                    0x04,               // Input is 4 bytes long
                    x,                  // Overwrite x with output
                    0x20                // The output length
                )

                decimals := mload(x)
            }
            if (success && decimals != 22270923699561257074107342068491755213283769984150504402684791726686939079929) {
                tokens[i].decimals = decimals;
            }
        }
    }

    /** @dev Fetch token information in batches
     *  @param _t2crAddress The address of the t2cr contract from where to fetch token information.
     *  @param _cursor The index from where to start iterating.
     *  @param _count The number of items to iterate. If 0 is given, defaults to t2cr.tokenCount().
     *  @param _filter The filter to use. Each element of the array in sequence means:
     *  - Include absent addresses in result.
     *  - Include registered addresses in result.
     *  - Include addresses with registration requests that are not disputed in result.
     *  - Include addresses with clearing requests that are not disputed in result.
     *  - Include disputed addresses with registration requests in result.
     *  - Include disputed addresses with clearing requests in result.
     *  @return tokens The tokens information.
     */
    function getTokensCursor(address _t2crAddress, uint _cursor, uint _count, bool[6] calldata _filter)
        external
        view
        returns (Token[] memory tokens, bool hasMore)
    {
        IArbitrableTokenTCR t2cr = IArbitrableTokenTCR(_t2crAddress);
        if (_count == 0) _count = t2cr.tokenCount();
        if (_cursor >= t2cr.tokenCount()) _cursor = t2cr.tokenCount() - 1;
        if (_cursor + _count > t2cr.tokenCount() - 1) _count = t2cr.tokenCount() - _cursor - 1;
        if (_cursor + _count < t2cr.tokenCount() - 1) hasMore = true;

        tokens = new Token[](_count);
        uint index = 0;


        for (uint i = _cursor; i < t2cr.tokenCount() && i < _cursor + _count ; i++){
            bytes32 tokenID = t2cr.tokensList(i);
            string[] memory strings = new string[](3); // name, ticker and symbolMultihash respectively.
            address tokenAddress;
            IArbitrableTokenTCR.TokenStatus status;
            uint numberOfRequests;
            (
                strings[0],
                strings[1],
                tokenAddress,
                strings[2],
                status,
                numberOfRequests
            ) = t2cr.getTokenInfo(tokenID);

            tokens[index] = Token(
                tokenID,
                strings[0],
                strings[1],
                tokenAddress,
                strings[2],
                status,
                0
            );

            (bool disputed,,,,,,,,) = t2cr.getRequestInfo(tokenID, numberOfRequests - 1);

            if (
                /* solium-disable operator-whitespace */
                (_filter[0] && status == IArbitrableTokenTCR.TokenStatus.Absent) ||
                (_filter[1] && status == IArbitrableTokenTCR.TokenStatus.Registered) ||
                (_filter[2] && status == IArbitrableTokenTCR.TokenStatus.RegistrationRequested && !disputed) ||
                (_filter[3] && status == IArbitrableTokenTCR.TokenStatus.ClearingRequested && !disputed) ||
                (_filter[4] && status == IArbitrableTokenTCR.TokenStatus.RegistrationRequested && disputed) ||
                (_filter[5] && status == IArbitrableTokenTCR.TokenStatus.ClearingRequested && disputed)
                /* solium-enable operator-whitespace */
            ) {
                if (index < _count) {
                    // Call the contract's decimals() function without reverting when
                    // the contract does not implement it.
                    //
                    // Two things should be noted: if the contract does not implement the function
                    // and does not implement the contract fallback function, `success` will be set to
                    // false and decimals won't be set. However, in some cases (such as old contracts)
                    // the fallback function is implemented, and so staticcall will return true
                    // even though the value returned will not be correct (the number below):
                    //
                    // 22270923699561257074107342068491755213283769984150504402684791726686939079929
                    //
                    // We handle that edge case by also checking against this value.
                    uint decimals;
                    bool success;
                    bytes4 sig = bytes4(keccak256("decimals()"));
                    assembly {
                        let x := mload(0x40)   // Find empty storage location using "free memory pointer"
                        mstore(x, sig)          // Set the signature to the first call parameter. 0x313ce567 === bytes4(keccak256("decimals()")
                        success := staticcall(
                            30000,              // 30k gas
                            tokenAddress,       // The call target.
                            x,                  // Inputs are stored at location x
                            0x04,               // Input is 4 bytes long
                            x,                  // Overwrite x with output
                            0x20                // The output length
                        )

                        decimals := mload(x)
                    }
                    if (success && decimals != 22270923699561257074107342068491755213283769984150504402684791726686939079929) {
                        tokens[index].decimals = decimals;
                    }
                    index++;
                } else {
                    hasMore = true;
                    break;
                }
            }
        }
    }

    function getRequestDetails(address _t2crAddress, bytes32 _tokenID, uint _requestID) public view returns (Request memory request) {
        // Making multiple block-scoped calls to avoid passing the stack limit.
        IArbitrableTokenTCR t2cr = IArbitrableTokenTCR(_t2crAddress);
        {
            (
                request.disputed,
                request.disputeID,
                request.submissionTime,
                request.resolved,
                request.parties,
                request.numberOfRounds,
                request.ruling,
                ,
            ) = t2cr.getRequestInfo(_tokenID, _requestID);
        }
        
        {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                request.arbitrator,
                request.arbitratorExtraData
            ) = t2cr.getRequestInfo(_tokenID, _requestID);
        }

        {
            (
                request.appealed,// appealed
                request.paidFees, // paidFees
                request.hasPaid, // hasPaid
                request.feeRewards // feeRewards
            ) = IArbitrableTokenTCR(_t2crAddress).getRoundInfo(_tokenID, _requestID, request.numberOfRounds - 1);    
        }
        
        if (request.disputed) {
            IArbitrator arbitrator = IArbitrator(request.arbitrator);
            request.disputeStatus = arbitrator.disputeStatus(request.disputeID);
            request.currentRuling = arbitrator.currentRuling(request.disputeID);

            if (request.disputeStatus == IArbitrator.DisputeStatus.Appealable) {
                request.appealCost = arbitrator.appealCost(request.disputeID, request.arbitratorExtraData);

                ArbitrableTCRData memory arbitrableTCRData = fetchArbitrable(_t2crAddress);

                if (request.ruling == IArbitrableTCR.Party.None) {
                    request.requiredForSide[1] = request.appealCost + request.appealCost * arbitrableTCRData.sharedStakeMultiplier / arbitrableTCRData.MULTIPLIER_DIVISOR;
                    request.requiredForSide[2] = request.appealCost + request.appealCost * arbitrableTCRData.sharedStakeMultiplier / arbitrableTCRData.MULTIPLIER_DIVISOR;
                } else if (request.ruling == IArbitrableTCR.Party.Requester) {
                    request.requiredForSide[1] = request.appealCost + request.appealCost * arbitrableTCRData.winnerStakeMultiplier / arbitrableTCRData.MULTIPLIER_DIVISOR;
                    request.requiredForSide[2] = request.appealCost + request.appealCost * arbitrableTCRData.loserStakeMultiplier / arbitrableTCRData.MULTIPLIER_DIVISOR;
                } else {
                    request.requiredForSide[1] = request.appealCost + request.appealCost * arbitrableTCRData.loserStakeMultiplier / arbitrableTCRData.MULTIPLIER_DIVISOR;
                    request.requiredForSide[2] = request.appealCost + request.appealCost * arbitrableTCRData.winnerStakeMultiplier / arbitrableTCRData.MULTIPLIER_DIVISOR;
                }

                (request.appealPeriod[0], request.appealPeriod[1]) = arbitrator.appealPeriod(request.disputeID);
            }
        }
    }

    function getRequestsDetails(address _t2crAddress, bytes32 _tokenID) public view returns (
       Request[10] memory requests // Ideally this should be resizable. In practice it is unlikely submissions will have more than 2 or 3 requests.
    ) {
        IArbitrableTokenTCR t2cr = IArbitrableTokenTCR(_t2crAddress);
        (,,,,, uint numberOfRequests) = t2cr.getTokenInfo(_tokenID);

        for (uint256 i = 0; i < numberOfRequests; i++) {
            requests[i] = getRequestDetails(_t2crAddress, _tokenID, i);
        }
    }
}