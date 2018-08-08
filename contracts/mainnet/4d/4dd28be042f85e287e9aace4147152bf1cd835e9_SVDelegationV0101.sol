pragma solidity ^0.4.19;

// DELEGATION SC v1.1
// (c) SecureVote 2018
// Author: Max Kaye <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5b363a231b283e382e293e752d342f3e">[email&#160;protected]</a>>
// Released under MIT licence

// the most up-to-date version of the contract lives at delegate.secvote.eth


// Main delegation contract v1.1
contract SVDelegationV0101 {

    address public owner;

    // in the last version we didn&#39;t include enough data - this makes it trivial to traverse off-chain
    struct Delegation {
        uint64 thisDelegationId;
        uint64 prevDelegationId;
        uint64 setAtBlock;
        address delegatee;
        address delegator;
        address tokenContract;
    }

    // easy lookups
    mapping (address => mapping (address => Delegation)) tokenDlgts;
    mapping (address => Delegation) globalDlgts;

    // track which token contracts we know about for easy traversal + backwards compatibility
    mapping (address => bool) knownTokenContracts;
    address[] logTokenContracts;

    // track all delegations via an indexed map
    mapping (uint64 => Delegation) historicalDelegations;
    uint64 public totalDelegations = 0;

    // reference to v1.0 of contract
    SVDelegation prevSVDelegation;

    // pretty straight forward - events
    event SetGlobalDelegation(address voter, address delegate);
    event SetTokenDelegation(address voter, address tokenContract, address delegate);

    // main constructor - requires the prevDelegationSC address
    function SVDelegationV0101(address prevDelegationSC) public {
        owner = msg.sender;

        prevSVDelegation = SVDelegation(prevDelegationSC);

        // commit the genesis historical delegation to history (like genesis block) - somewhere to point back to
        createDelegation(address(0), 0, address(0));
    }

    // internal function to handle inserting delegates into state
    function createDelegation(address dlgtAddress, uint64 prevDelegationId, address tokenContract) internal returns(Delegation) {
        // use this to log known tokenContracts
        if (!knownTokenContracts[tokenContract]) {
            logTokenContracts.push(tokenContract);
            knownTokenContracts[tokenContract] = true;
        }

        uint64 myDelegationId = totalDelegations;
        historicalDelegations[myDelegationId] = Delegation(myDelegationId, prevDelegationId, uint64(block.number), dlgtAddress, msg.sender, tokenContract);
        totalDelegations += 1;

        return historicalDelegations[myDelegationId];
    }

    // get previous delegation, create new delegation via function and then commit to globalDlgts
    function setGlobalDelegation(address dlgtAddress) public {
        uint64 prevDelegationId = globalDlgts[msg.sender].thisDelegationId;
        globalDlgts[msg.sender] = createDelegation(dlgtAddress, prevDelegationId, address(0));
        SetGlobalDelegation(msg.sender, dlgtAddress);
    }

    // get previous delegation, create new delegation via function and then commit to tokenDlgts
    function setTokenDelegation(address tokenContract, address dlgtAddress) public {
        uint64 prevDelegationId = tokenDlgts[tokenContract][msg.sender].thisDelegationId;
        tokenDlgts[tokenContract][msg.sender] = createDelegation(dlgtAddress, prevDelegationId, tokenContract);
        SetTokenDelegation(msg.sender, tokenContract, dlgtAddress);
    }

    // given some voter and token address, get the delegation id - failover to global on 0 address
    function getDelegationID(address voter, address tokenContract) public constant returns(uint64) {
        // default to token resolution but use global if no delegation
        Delegation memory _tokenDlgt = tokenDlgts[tokenContract][voter];
        if (tokenContract == address(0)) {
            _tokenDlgt = globalDlgts[voter];
        }

        // default to 0 if we don&#39;t have a valid delegation
        if (_validDelegation(_tokenDlgt)) {
            return _tokenDlgt.thisDelegationId;
        }
        return 0;
    }

    function resolveDelegation(address voter, address tokenContract) public constant returns(uint64, uint64, uint64, address, address, address) {
        Delegation memory _tokenDlgt = tokenDlgts[tokenContract][voter];

        // if we have a delegation in this contract return it
        if (_validDelegation(_tokenDlgt)) {
            return _dlgtRet(_tokenDlgt);
        }

        // otherwise try the global delegation
        Delegation memory _globalDlgt = globalDlgts[voter];
        if (_validDelegation(_globalDlgt)) {
            return _dlgtRet(_globalDlgt);
        }

        // but if we don&#39;t have a delegation in this contract then resolve according the prev contract
        address _dlgt;
        uint256 meh;
        (meh, _dlgt, meh, meh) = prevSVDelegation.resolveDelegation(voter, tokenContract);
        return (0, 0, 0, _dlgt, voter, tokenContract);
    }

    // returns 2 lists: first of voter addresses, second of token contracts
    function findPossibleDelegatorsOf(address delegate) public view returns(address[] memory, address[] memory) {
        // not meant to be run on-chain, but off-chain via API, mostly convenience
        address[] memory voters;
        address[] memory tokenContracts;
        Delegation memory _delegation;

        // all the senders who participated in v1.0 of the contract prior to block 5203500
        address[43] memory oldSenders =
            [ 0xE8193Bc3D5F3F482406706F843A5f161563F37Bf
            , 0x7A933c8a0Eb99e8Bdb07E1b42Aa10872845394B7
            , 0x88341191EfA40Cd031F46138817830A5D3545Ba9
            , 0xB6dc48E8583C8C6e320DaF918CAdef65f2d85B46
            , 0xF02d417c8c6736Dbc7Eb089DC6738b950c2F444e
            , 0xF66fE29Ad1E87104A8816AD1A8427976d83CB033
            , 0xfd5955bf412B7537873CBB77eB1E39871e20e142
            , 0xe83Efc57d9C487ACc55a7B62896dA43928E64C3E
            , 0xd0c41588b27E64576ddA4e6a08452c59F5A2B2dD
            , 0x640370126072f6B890d4Ca2E893103e9363DbE8B
            , 0x887dbaCD9a0e58B46065F93cc1f82a52DEfDb979
            , 0xe223771699665bCB0AAf7930277C35d3deC573aF
            , 0x364B503B0e86b20B7aC1484c247DE50f10DfD8cf
            , 0x4512F5867d91D6B0131427b89Bdb7b460fF30397
            , 0xF5fBff477F5Bf5a950F661B70F6b5364875A1bD7
            , 0x9EbB758483Da174DC3d411386B75afd093CEfCf1
            , 0x499B36A6B92F91524A6B5b8Ff321740e84a2B57e
            , 0x05D6e87fd6326F977a2d8c67b9F3EcC030527261
            , 0x7f679053a1679dE7913885F0Db1278e91e8927Ca
            , 0xF9CD08d36e972Bb070bBD2C1598D21045259AB0D
            , 0xa5617800B8FD754fB81F47A65dc49A60acCc3432
            , 0xa9F6238B83fcb65EcA3c3189a0dce8689e275D57
            , 0xa30F92F9cc478562e0dde73665f1B7ADddDC2dCd
            , 0x70278C15A29f0Ef62A845e1ac31AE41988F24C10
            , 0xd42622471946CCFf9F7b9246e8D786c74410bFcC
            , 0xd65955EF0f8890D7996f5a7b7b5b05B80605C06a
            , 0xB46F4eBDD6404686D785EDACE37D66f815ED7cF8
            , 0xf4d3aa8091D23f97706177CDD94b8dF4c7e4C2FB
            , 0x4Fe584FFc9C755BF6Aa9354323e97166958475c9
            , 0xB4802f497Bf6238A29e043103EE6eeae1331BFde
            , 0x3EeE0f8Fadc1C29bFB782E70067a8D91B4ddeD56
            , 0x46381F606014C5D68B38aD5C7e8f9401149FAa75
            , 0xC81Be3496d053364255f9cb052F81Ca9e84A9cF3
            , 0xa632837B095d8fa2ef46a22099F91Fe10B3F0538
            , 0x19FA94aEbD4bC694802B566Ae65aEd8F07B992f7
            , 0xE9Ef7664d36191Ad7aB001b9BB0aAfAcD260277F
            , 0x17DAB6BB606f32447aff568c1D0eEDC3649C101C
            , 0xaBA96c77E3dd7EEa16cc5EbdAAA05483CDD0FF89
            , 0x57d36B0B5f5E333818b1ce072A6D84218E734deC
            , 0x59E7612706DFB1105220CcB97aaF3cBF304cD608
            , 0xCf7EC4dcA84b5c8Dc7896c38b4834DC6379BB73D
            , 0x5Ed1Da246EA52F302FFf9391e56ec64b9c14cce1
            , 0x4CabFD1796Ec9EAd77457768e5cA782a1A9e576F
            ];

        // there were no global delegations in v1.0 of contract
        address oldToken = 0x9e88613418cF03dCa54D6a2cf6Ad934A78C7A17A;

        // first loop through delegations in this contract
        uint64 i;
        // start at 1 because the first delegation is a "genesis" delegation in constructor
        for (i = 1; i < totalDelegations; i++) {
            _delegation = historicalDelegations[i];
            if (_delegation.delegatee == delegate) {
                // since `.push` isn&#39;t available on memory arrays, use their length as the next index location
                voters = _appendMemArray(voters, _delegation.delegator);
                tokenContracts = _appendMemArray(tokenContracts, _delegation.tokenContract);
            }
        }

        // then loop through delegations in the previous contract
        for (i = 0; i < oldSenders.length; i++) {
            uint256 _oldId;
            address _oldDlgt;
            uint256 _oldSetAtBlock;
            uint256 _oldPrevId;
            (_oldId, _oldDlgt, _oldSetAtBlock, _oldPrevId) = prevSVDelegation.resolveDelegation(oldSenders[i], oldToken);
            if (_oldDlgt == delegate && _oldSetAtBlock != 0) {
                voters = _appendMemArray(voters, oldSenders[i]);
                tokenContracts = _appendMemArray(tokenContracts, oldToken);
            }
        }

        return (voters, tokenContracts);
    }

    // give access to historicalDelegations
    function getHistoricalDelegation(uint64 delegationId) public constant returns(uint64, uint64, uint64, address, address, address) {
        return _dlgtRet(historicalDelegations[delegationId]);
    }

    // access the globalDelegation map
    function _rawGetGlobalDelegation(address _voter) public constant returns(uint64, uint64, uint64, address, address, address) {
        return _dlgtRet(globalDlgts[_voter]);
    }

    // access the tokenDelegation map
    function _rawGetTokenDelegation(address _voter, address _tokenContract) public constant returns(uint64, uint64, uint64, address, address, address) {
        return _dlgtRet(tokenDlgts[_tokenContract][_voter]);
    }

    // access our log list of token contracts
    function _getLogTokenContract(uint256 i) public constant returns(address) {
        return logTokenContracts[i];
    }

    // convenience function to turn Delegations into a returnable structure
    function _dlgtRet(Delegation d) internal pure returns(uint64, uint64, uint64, address, address, address) {
        return (d.thisDelegationId, d.prevDelegationId, d.setAtBlock, d.delegatee, d.delegator, d.tokenContract);
    }

    // internal function to test if a delegation is valid or revoked / nonexistent
    function _validDelegation(Delegation d) internal pure returns(bool) {
        // probs simplest test to check if we have a valid delegation - important to check if delegation is set to 0x00
        // to avoid counting a revocation (which is done by delegating to 0x00)
        return d.setAtBlock > 0 && d.delegatee != address(0);
    }

    function _appendMemArray(address[] memory arr, address toAppend) internal pure returns(address[] memory arr2) {
        arr2 = new address[](arr.length + 1);

        for (uint k = 0; k < arr.length; k++) {
            arr2[k] = arr[k];
        }

        arr2[arr.length] = toAppend;
    }
}



// Minimal interface for delegation needs
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant public returns (uint256 balance);
}



// Include previous contract in this one so we can access the various components. Not all things needed are accessible
// through functions - e.g. `historicalDelegations` mapping.
contract SVDelegation {

    address public owner;

    struct Delegation {
        uint256 thisDelegationId;
        address dlgt;
        uint256 setAtBlock;
        uint256 prevDelegation;
    }

    mapping (address => mapping (address => Delegation)) tokenDlgts;
    mapping (address => Delegation) globalDlgts;

    mapping (uint256 => Delegation) public historicalDelegations;
    uint256 public totalDelegations = 0;

    event SetGlobalDelegation(address voter, address delegate);
    event SetTokenDelegation(address voter, address tokenContract, address delegate);

    function SVDelegation() public {
        owner = msg.sender;

        // commit the genesis historical delegation to history (like genesis block)
        createDelegation(address(0), 0);
    }

    function createDelegation(address dlgtAddress, uint256 prevDelegationId) internal returns(Delegation) {
        uint256 myDelegationId = totalDelegations;
        historicalDelegations[myDelegationId] = Delegation(myDelegationId, dlgtAddress, block.number, prevDelegationId);
        totalDelegations += 1;

        return historicalDelegations[myDelegationId];
    }

    // get previous delegation, create new delegation via function and then commit to globalDlgts
    function setGlobalDelegation(address dlgtAddress) public {
        uint256 prevDelegationId = globalDlgts[msg.sender].thisDelegationId;
        globalDlgts[msg.sender] = createDelegation(dlgtAddress, prevDelegationId);
        SetGlobalDelegation(msg.sender, dlgtAddress);
    }

    // get previous delegation, create new delegation via function and then commit to tokenDlgts
    function setTokenDelegation(address tokenContract, address dlgtAddress) public {
        uint256 prevDelegationId = tokenDlgts[tokenContract][msg.sender].thisDelegationId;
        tokenDlgts[tokenContract][msg.sender] = createDelegation(dlgtAddress, prevDelegationId);
        SetTokenDelegation(msg.sender, tokenContract, dlgtAddress);
    }

    function resolveDelegation(address voter, address tokenContract) public constant returns(uint256, address, uint256, uint256) {
        Delegation memory _tokenDlgt = tokenDlgts[tokenContract][voter];

        // probs simplest test to check if we have a valid delegation
        if (_tokenDlgt.setAtBlock > 0) {
            return _dlgtRet(_tokenDlgt);
        } else {
            return _dlgtRet(globalDlgts[voter]);
        }
    }

    function _rawGetGlobalDelegation(address _voter) public constant returns(uint256, address, uint256, uint256) {
        return _dlgtRet(globalDlgts[_voter]);
    }

    function _rawGetTokenDelegation(address _voter, address _tokenContract) public constant returns(uint256, address, uint256, uint256) {
        return _dlgtRet(tokenDlgts[_tokenContract][_voter]);
    }

    function _dlgtRet(Delegation d) internal pure returns(uint256, address, uint256, uint256) {
        return (d.thisDelegationId, d.dlgt, d.setAtBlock, d.prevDelegation);
    }
}