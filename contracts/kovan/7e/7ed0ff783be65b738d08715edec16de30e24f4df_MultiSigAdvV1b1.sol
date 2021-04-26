/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

contract MultiSigAdvV1b1 {
    uint256 private _currentRequestId;
    uint256 private _currentRequestTimestamp;
    mapping(uint256 => mapping(address => bool)) _currentVotes;
    uint256 private _currentVoteTotal;
    address[] private _owners;
    mapping(uint256 => Request) private _requests;
    uint256 private _requestCount;
    mapping (address => uint256) private _votingPowers;
    uint256 private _votingPowerTotal;
    uint256 private _votingRate;
    
    constructor(address[] memory owners_, uint256 votingRate_) {
        if (owners_.length == 0) {
            _owners.push(msg.sender);
            _votingPowers[msg.sender] = 1;
        }
        else {
            uint256 i;
            for (i = 0; i < owners_.length; i++) {
                address owner = owners_[i];
                if (_votingPowers[owner] == 0) {
                    _owners.push(owner);
                    _votingPowers[owner] = 1;
                }                
            }
        }
        if (votingRate_ == 0 || votingRate_ > _owners.length) {
            _votingRate = _owners.length;
        }
        else {
            _votingRate = votingRate_;
        }
        _votingPowerTotal = _owners.length;
    }
    
    struct Request {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    
    event Executed(string);
    event OwnerAdded(address owner, uint256 vRate, uint256 vTotal);
    event OwnerChanged(address owner, uint256 vRate, uint256 vTotal);
    event OwnerRemoved(address owner, uint256 vRate, uint256 vTotal);
    event OwnersChanged(address[] owners, uint256 vRate, uint256 vTotal);
    event Requested(uint256 requestId, string message);
    event Revoked(address owner, uint256 vProgress, uint256 vRate);
    event Voted(address owner, uint256 vProgress, uint256 vRate);
    event VotingRateChanged(uint256 vRate, uint256 vTotal);

    modifier selfOnly() {
        //require(msg.sender == address(this) || _votingPowers[msg.sender] > 0, "MultiSig: Only wallet can perform this operation");
        require(msg.sender == address(this), "MultiSig: Only wallet can perform this operation");
        _;
    }

    modifier isOwner(address owner) {
        require(_votingPowers[owner] > 0, "MultiSig: Address is not owner");
        _;
    }

    modifier notOwner(address owner) {
        require(_votingPowers[owner] == 0, "MultiSig: Address is already owner");
        _;
    }

    modifier existRequest() {
        require(_currentRequestId != 0, "MultiSig: NO pending request");
        _;
    }

    modifier noRequest() {
        require(_currentRequestId == 0, "MultiSig: There is pending request");
        _;
    }

    modifier validVotingPower(uint256 vPower) {
        require(vPower > 0, "MultiSig: Invalid voting power");
        _;
    }

    modifier voted(address owner) {
        require(_currentVotes[_currentRequestId][owner], "MultiSig: Owner not voted");
        _;
    }

    modifier notVoted(address owner) {
        require(!_currentVotes[_currentRequestId][owner], "MultiSig: Owner voted");
        _;
    }
    
    function currentRequestId() public view returns (uint256) {
        return _currentRequestId;
    }
    
    function currentRequestTimestamp() public view returns (uint256) {
        return _currentRequestTimestamp;
    }

    function ownerPowers() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory values = new uint256[](_owners.length);
        uint256 i;
        for (i = 0; i < _owners.length; i++) {
            values[i] = (_votingPowers[_owners[i]]);
        }
        return (_owners, values);
    }
    
    function requestInfo(uint256 requestId) public view returns (Request memory) {
        return _requests[requestId];
    }

    function votingPower() public view returns (uint256,uint256) {
        return (_votingRate,_votingPowerTotal);
    }

    function votingProgress() public view returns (uint256,uint256) {
        return (_currentVoteTotal, _votingRate);
    }

    function createRequest(address destination, uint256 value, bytes memory data)
        isOwner(msg.sender)
        noRequest()
        public returns (bool) {
        _requestCount++;
        _currentRequestTimestamp = block.timestamp;
        _requests[_requestCount] = Request({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        _currentRequestId = _requestCount;
        emit Requested(_currentRequestId, "Request submitted");
        return true;
    }
    
    function cancelRequest()
        isOwner(msg.sender)
        existRequest()
        public returns (bool) {
        require(_currentRequestTimestamp < block.timestamp, "MultiSig: Request cannot be cancelled within specified time");
        _resetVotingState();
        emit Requested(_currentRequestId, "Request cancelled");
        return true;
    }

    function addOwner(address nOwner, uint256 vPower, uint256 vRate)
        selfOnly()
        notOwner(nOwner)
        validVotingPower(vPower)
        public returns (bool) {
        uint256 nPower = _votingPowerTotal + vPower;
        require(vRate <= nPower, "MultiSig: Invalid voting rate");
        _owners.push(nOwner);
        _votingPowers[nOwner] = vPower;
        if (vRate > 0) {
            _votingRate = vRate;
        }
        _votingPowerTotal = nPower;
        emit OwnerAdded(nOwner, _votingRate, _votingPowerTotal);
        return true;
    }
    
    function changeOwners(address[] memory nOwners, uint256[] memory vPowers, uint256 vRate)
        selfOnly()
        public returns (bool) {
        uint256 i;
        for (i = 0; i < nOwners.length; i++) {
            address nOwner = nOwners[i];
            uint256 cPower = _votingPowers[nOwner];
            uint256 vPower = vPowers[i];
            if (cPower > 0) {
                if (vPower == 0) {
                    _removeOwner(nOwner);
                }
                _votingPowerTotal -= cPower;
            }
            else {
                if (vPower > 0) { 
                    _owners.push(nOwner);
                }
            }

            _votingPowers[nOwner] = vPower;
            _votingPowerTotal += vPower;
        }
        if (vRate > 0) {
            _votingRate = vRate;
        }
        require(_votingRate > 0 && _votingRate <= _votingPowerTotal, "MultiSig: Invalid voting rate");
        OwnersChanged(nOwners, _votingRate, _votingPowerTotal);
        return true;
    }

    function changeVotingRate(uint256 vRate)
        selfOnly()
        public returns (bool) {
        require(vRate > 0 && vRate <= _votingPowerTotal, "MultiSig: Invalid voting rate");
        _votingRate = vRate;
        emit VotingRateChanged(_votingRate, _votingPowerTotal);
        return true;
    }

    function removeOwner(address nOwner, uint256 vRate)
        selfOnly()
        isOwner(nOwner)
        public returns (bool) {
        require(_owners.length > 1, "MultiSig: Cannot remove last owner");
        uint256 nPower = _votingPowerTotal - _votingPowers[nOwner];
        require(vRate <= nPower, "MultiSig: Invalid voting rate");
        _removeOwner(nOwner);
        _votingPowerTotal = nPower; 
        _votingPowers[nOwner] = 0;
        if (vRate > 0) {
            _votingRate = vRate;
        }
        emit OwnerRemoved(nOwner, _votingRate, _votingPowerTotal);
        return true;
    }

    function updateOwnerVotingPower(address nOwner, uint256 vPower, uint256 vRate)
        selfOnly()
        isOwner(nOwner)
        validVotingPower(vPower)
        public returns (bool) {
        uint256 nPower = _votingPowerTotal + vPower - _votingPowers[nOwner];
        require(vRate <= nPower, "MultiSig: Invalid voting rate");
        _votingPowerTotal = nPower;
        _votingPowers[nOwner] = vPower;
        if (vRate > 0) {
            _votingRate = vRate;
        }
        OwnerChanged(nOwner, _votingRate, _votingPowerTotal);
        return true;
    }

    function vote()
        isOwner(msg.sender)
        existRequest()
        notVoted(msg.sender)
        public returns (bool) {
        _currentVotes[_currentRequestId][msg.sender] = true;
        _currentVoteTotal += _votingPowers[msg.sender];
        if (_currentVoteTotal >= _votingRate) {
            Request memory req = _requests[_currentRequestId];
            (bool success,) = req.destination.call{value: req.value}(req.data);
            if (success) {
                _requests[_currentRequestId].executed = true;
                Executed("MultiSig: Transaction executed");
            }
            else {
                _requests[_currentRequestId].executed = false;
                Executed("MultiSig: Transaction failed");
            }
            _resetVotingState();
        }
        else {
            emit Voted(msg.sender, _currentVoteTotal, _votingRate);
        }
        return true;
    }

    function revoke()
        isOwner(msg.sender)
        existRequest()
        voted(msg.sender)
        public returns (bool) {
        _currentVotes[_currentRequestId][msg.sender] = false;
        _currentVoteTotal -= _votingPowers[msg.sender];
        emit Revoked(msg.sender, _currentVoteTotal, _votingRate);
        return true;
    }

    function _removeOwner(address owner) internal {
        uint256 i;
        for(i = 0; i < _owners.length; i++) {
            if (_owners[i] == owner) {
                _owners[i] = _owners[_owners.length - 1];
                _owners.pop();
                break;
            }
        }
    }

    function _resetVotingState() internal {
        _currentRequestId = 0;
        _currentVoteTotal = 0;
        _currentRequestTimestamp = block.timestamp;
    }
}