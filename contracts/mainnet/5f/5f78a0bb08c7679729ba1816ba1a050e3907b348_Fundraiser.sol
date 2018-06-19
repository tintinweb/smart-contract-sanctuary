pragma solidity ^0.4.19;

/**
 * @title ERC20
 * @dev A standard interface for tokens.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
  
    /// @dev Returns the total token supply
    function totalSupply() public constant returns (uint256 supply);

    /// @dev Returns the account balance of the account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @dev Transfers _value number of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @dev Transfers _value number of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @dev Allows _spender to withdraw from the msg.sender&#39;s account up to the _value amount
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Fundraiser {

    event Beginning(
        bytes32 _causeSecret
    );

    event Participation(
        address _participant,
        bytes32 _message,
        uint256 _entries,
        uint256 _refund
    );

    event Raise(
        address _participant,
        uint256 _entries,
        uint256 _refund
    );

    event Revelation(
        bytes32 _causeMessage
    );

    event Selection(
        address _participant,
        bytes32 _participantMessage,
        bytes32 _causeMessage,
        bytes32 _ownerMessage
    );

    event Cancellation();

    event Withdrawal(
        address _address
    );

    struct Deployment {
        address _cause;
        address _causeWallet;
        uint256 _causeSplit;
        uint256 _participantSplit;
        address _owner;
        address _ownerWallet;
        uint256 _ownerSplit;
        bytes32 _ownerSecret;
        uint256 _valuePerEntry;
        uint256 _deployTime;
        uint256 _endTime;
        uint256 _expireTime;
        uint256 _destructTime;
        uint256 _entropy;
    }

    struct State {
        bytes32 _causeSecret;
        bytes32 _causeMessage;
        bool _causeWithdrawn;
        address _participant;
        bool _participantWithdrawn;
        bytes32 _ownerMessage;
        bool _ownerWithdrawn;
        bool _cancelled;
        uint256 _participants;
        uint256 _entries;
        uint256 _revealBlockNumber;
        uint256 _revealBlockHash;
    }

    struct Participant {
        bytes32 _message;
        uint256 _entries;
    }

    struct Fund {
        address _participant;
        uint256 _entries;
    }

    modifier onlyOwner() {
        require(msg.sender == deployment._owner);
        _;
    }

    modifier neverOwner() {
        require(msg.sender != deployment._owner);
        require(msg.sender != deployment._ownerWallet);
        _;
    }

    modifier onlyCause() {
        require(msg.sender == deployment._cause);
        _;
    }

    modifier neverCause() {
        require(msg.sender != deployment._cause);
        require(msg.sender != deployment._causeWallet);
        _;
    }

    modifier participationPhase() {
        require(now < deployment._endTime);
        _;
    }

    modifier recapPhase() {
        require((now >= deployment._endTime) && (now < deployment._expireTime));
        _;
    }

    modifier destructionPhase() {
        require(now >= deployment._destructTime);
        _;
    }
    
    Deployment public deployment;
    mapping(address => Participant) public participants;
    Fund[] private funds;
    State private _state;

    function Fundraiser(
        address _cause,
        address _causeWallet,
        uint256 _causeSplit,
        uint256 _participantSplit,
        address _ownerWallet,
        uint256 _ownerSplit,
        bytes32 _ownerSecret,
        uint256 _valuePerEntry,
        uint256 _endTime,
        uint256 _expireTime,
        uint256 _destructTime,
        uint256 _entropy
    ) public {
        require(_cause != 0x0);
        require(_causeWallet != 0x0);
        require(_causeSplit != 0);
        require(_participantSplit != 0);
        require(_ownerWallet != 0x0);
        require(_causeSplit + _participantSplit + _ownerSplit == 1000);
        require(_ownerSecret != 0x0);
        require(_valuePerEntry != 0);
        require(_endTime > now); // participation phase
        require(_expireTime > _endTime); // end phase
        require(_destructTime > _expireTime); // destruct phase
        require(_entropy > 0);

        // set the deployment
        deployment = Deployment(
            _cause,
            _causeWallet,
            _causeSplit,
            _participantSplit,
            msg.sender,
            _ownerWallet,
            _ownerSplit,
            _ownerSecret,
            _valuePerEntry,
            now,
            _endTime,
            _expireTime,
            _destructTime,
            _entropy
        );

    }

    // returns the post-deployment state of the contract
    function state() public view returns (
        bytes32 _causeSecret,
        bytes32 _causeMessage,
        bool _causeWithdrawn,
        address _participant,
        bytes32 _participantMessage,
        bool _participantWithdrawn,
        bytes32 _ownerMessage,
        bool _ownerWithdrawn,
        bool _cancelled,
        uint256 _participants,
        uint256 _entries
    ) {
        _causeSecret = _state._causeSecret;
        _causeMessage = _state._causeMessage;
        _causeWithdrawn = _state._causeWithdrawn;
        _participant = _state._participant;
        _participantMessage = participants[_participant]._message;
        _participantWithdrawn = _state._participantWithdrawn;
        _ownerMessage = _state._ownerMessage;
        _ownerWithdrawn = _state._ownerWithdrawn;
        _cancelled = _state._cancelled;
        _participants = _state._participants;
        _entries = _state._entries;
    }

    // returns the balance of a cause, selected participant, owner, or participant (refund)
    function balance() public view returns (uint256) {
        // check for fundraiser ended normally
        if (_state._participant != address(0)) {
            // selected, get split
            uint256 _split;
            // determine split based on sender
            if (msg.sender == deployment._cause) {
                if (_state._causeWithdrawn) {
                    return 0;
                }
                _split = deployment._causeSplit;
            } else if (msg.sender == _state._participant) {
                if (_state._participantWithdrawn) {
                    return 0;
                }
                _split = deployment._participantSplit;
            } else if (msg.sender == deployment._owner) {
                if (_state._ownerWithdrawn) {
                    return 0;
                }
                _split = deployment._ownerSplit;
            } else {
                return 0;
            }
            // multiply total entries by split % (non-revealed winnings are forfeited)
            return _state._entries * deployment._valuePerEntry * _split / 1000;
        } else if (_state._cancelled) {
            // value per entry times participant entries == balance
            Participant storage _participant = participants[msg.sender];
            return _participant._entries * deployment._valuePerEntry;
        }

        return 0;
    }

    // called by the cause to begin their fundraiser with their secret
    function begin(bytes32 _secret) public participationPhase onlyCause {
        require(!_state._cancelled); // fundraiser not cancelled
        require(_state._causeSecret == 0x0); // cause has not seeded secret
        require(_secret != 0x0); // secret cannot be zero

        // seed cause secret, starting the fundraiser
        _state._causeSecret = _secret;

        // broadcast event
        Beginning(_secret);
    }

    // participate in this fundraiser by contributing messages and ether for entries
    function participate(bytes32 _message) public participationPhase neverCause neverOwner payable {
        require(!_state._cancelled); // fundraiser not cancelled
        require(_state._causeSecret != 0x0); // cause has seeded secret
        require(_message != 0x0); // message cannot be zero

        // find and check for no existing participant
        Participant storage _participant = participants[msg.sender];
        require(_participant._message == 0x0);
        require(_participant._entries == 0);

        // add entries to participant
        var (_entries, _refund) = _raise(_participant);
        // save participant message, increment total participants
        _participant._message = _message;
        _state._participants++;

        // send out participation update
        Participation(msg.sender, _message, _entries, _refund);
    }

    // called by participate() and the fallback function for obtaining (additional) entries
    function _raise(Participant storage _participant) private returns (
        uint256 _entries,
        uint256 _refund
    ) {
        // calculate the number of entries from the wei sent
        _entries = msg.value / deployment._valuePerEntry;
        require(_entries >= 1); // ensure we have at least one entry
        // update participant totals
        _participant._entries += _entries;
        _state._entries += _entries;

        // get previous fund&#39;s entries
        uint256 _previousFundEntries = (funds.length > 0) ?
            funds[funds.length - 1]._entries : 0;
        // create and save new fund with cumulative entries
        Fund memory _fund = Fund(msg.sender, _previousFundEntries + _entries);
        funds.push(_fund);

        // calculate partial entry refund
        _refund = msg.value % deployment._valuePerEntry;
        // refund any excess wei immediately (partial entry)
        if (_refund > 0) {
            msg.sender.transfer(_refund);
        }
    }

    // fallback function that accepts ether for additional entries after an initial participation
    function () public participationPhase neverCause neverOwner payable {
        require(!_state._cancelled); // fundraiser not cancelled
        require(_state._causeSecret != 0x0); // cause has seeded secret

        // find existing participant
        Participant storage _participant = participants[msg.sender];
        require(_participant._message != 0x0); // make sure they participated
        // forward to raise
        var (_entries, _refund) = _raise(_participant);
        
        // send raise event
        Raise(msg.sender, _entries, _refund);
    }

    // called by the cause to reveal their message after the end time but before the end() function
    function reveal(bytes32 _message) public recapPhase onlyCause {
        require(!_state._cancelled); // fundraiser not cancelled
        require(_state._causeMessage == 0x0); // cannot have revealed already
        require(_state._revealBlockNumber == 0); // block number of reveal should not be set
        require(_decode(_state._causeSecret, _message)); // check for valid message

        // save revealed cause message
        _state._causeMessage = _message;
        // save reveal block number
        _state._revealBlockNumber = block.number;

        // send reveal event
        Revelation(_message);
    }

    // determines that validity of a message, given a secret
    function _decode(bytes32 _secret, bytes32 _message) private view returns (bool) {
        return _secret == keccak256(_message, msg.sender);
    }

    // ends this fundraiser, selects a participant to reward, and allocates funds for the cause, the
    // selected participant, and the contract owner
    function end(bytes32 _message) public recapPhase onlyOwner {
        require(!_state._cancelled); // fundraiser not cancelled
        require(_state._causeMessage != 0x0); // cause must have revealed
        require(_state._revealBlockNumber != 0); // reveal block number must be set
        require(_state._ownerMessage == 0x0); // cannot have ended already
        require(_decode(deployment._ownerSecret, _message)); // check for valid message
        require(block.number > _state._revealBlockNumber); // verify reveal has been mined

        // get the (cause) reveal blockhash and ensure within 256 blocks (non-zero)
        _state._revealBlockHash = uint256(block.blockhash(_state._revealBlockNumber));
        require(_state._revealBlockHash != 0);
        // save revealed owner message
        _state._ownerMessage = _message;

        bytes32 _randomNumber;
        address _participant;
        bytes32 _participantMessage;
        // add additional entropy to the random from participant messages
        for (uint256 i = 0; i < deployment._entropy; i++) {
            // calculate the next random
            _randomNumber = keccak256(
                _message,
                _state._causeMessage,
                _state._revealBlockHash,
                _participantMessage
            );
            // calculate next entry and grab corresponding participant
            uint256 _entry = uint256(_randomNumber) % _state._entries;
            _participant = _findParticipant(_entry);
            _participantMessage = participants[_participant]._message;
        }

        // the final participant receives the reward
        _state._participant = _participant;
        
        // send out select event
        Selection(
            _state._participant,
            _participantMessage,
            _state._causeMessage,
            _message
        );
    }

    // given an entry number, find the corresponding participant (address)
    function _findParticipant(uint256 _entry) private view returns (address)  {
        uint256 _leftFundIndex = 0;
        uint256 _rightFundIndex = funds.length - 1;
        // loop until participant found
        while (true) {
            // first or last fund (edge cases)
            if (_leftFundIndex == _rightFundIndex) {
                return funds[_leftFundIndex]._participant;
            }
            // get fund indexes for mid & next
            uint256 _midFundIndex =
                _leftFundIndex + ((_rightFundIndex - _leftFundIndex) / 2);
            uint256 _nextFundIndex = _midFundIndex + 1;
            // get mid and next funds
            Fund memory _midFund = funds[_midFundIndex];
            Fund memory _nextFund = funds[_nextFundIndex];
            // binary search
            if (_entry >= _midFund._entries) {
                if (_entry < _nextFund._entries) {
                    // we are in range, participant found
                    return _nextFund._participant;
                }
                // entry is greater, move right
                _leftFundIndex = _nextFundIndex;
            } else {
                // entry is less, move left
                _rightFundIndex = _midFundIndex;
            }
        }
    }

    // called by the cause or Seedom before the end time to cancel the fundraiser, refunding all
    // participants; this function is available to the entire community after the expire time
    function cancel() public {
        require(!_state._cancelled); // fundraiser not already cancelled
        require(_state._participant == address(0)); // selected must not have been chosen
        
        // open cancellation to community if past expire time (but before destruct time)
        if ((msg.sender != deployment._owner) && (msg.sender != deployment._cause)) {
            require((now >= deployment._expireTime) && (now < deployment._destructTime));
        }

        // immediately set us to cancelled
        _state._cancelled = true;

        // send out cancellation event
        Cancellation();
    }

    // used to withdraw funds from the contract from an ended fundraiser or refunds when the
    // fundraiser is cancelled
    function withdraw() public {
        // check for a balance
        uint256 _balance = balance();
        require (_balance > 0); // can only withdraw a balance

        address _wallet;
        // check for fundraiser ended normally
        if (_state._participant != address(0)) {

            // determine split based on sender
            if (msg.sender == deployment._cause) {
                _state._causeWithdrawn = true;
                _wallet = deployment._causeWallet;
            } else if (msg.sender == _state._participant) {
                _state._participantWithdrawn = true;
                _wallet = _state._participant;
            } else if (msg.sender == deployment._owner) {
                _state._ownerWithdrawn = true;
                _wallet = deployment._ownerWallet;
            } else {
                revert();
            }

        } else if (_state._cancelled) {

            // set participant entries to zero to prevent multiple refunds
            Participant storage _participant = participants[msg.sender];
            _participant._entries = 0;
            _wallet = msg.sender;

        } else {
            // no selected and not cancelled
            revert();
        }

        // execute the refund if we have one
        _wallet.transfer(_balance);
        // send withdrawal event
        Withdrawal(msg.sender);
    }

    // destroy() will be used to clean up old contracts from the network
    function destroy() public destructionPhase onlyOwner {
        // destroy this contract and send remaining funds to owner
        selfdestruct(msg.sender);
    }

    // recover() allows the owner to recover ERC20 tokens sent to this contract, for later
    // distribution back to their original holders, upon request
    function recover(address _token) public onlyOwner {
        ERC20 _erc20 = ERC20(_token);
        uint256 _balance = _erc20.balanceOf(this);
        require(_erc20.transfer(deployment._owner, _balance));
    }
}