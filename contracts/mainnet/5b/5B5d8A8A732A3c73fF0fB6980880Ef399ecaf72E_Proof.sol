/*
This file is part of the PROOF Contract.

The PROOF Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The PROOF Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the PROOF Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <<span class="__cf_email__" data-cfemail="acc582dfdac5dec5c2ecc2c3dec8cddac5c2c882ded9">[email&#160;protected]</span>>
*/

pragma solidity ^0.4.0;

contract owned {
    address public owner;
    address public newOwner;

    function owned() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ManualMigration is owned, ERC20 {
    mapping (address => uint) internal balances;
    address public migrationHost;

    function ManualMigration(address _migrationHost) payable owned() {
        migrationHost = _migrationHost;
        //balances[this] = ERC20(migrationHost).balanceOf(migrationHost);
    }

    function migrateManual(address _tokensHolder) onlyOwner {
        require(migrationHost != 0);
        uint tokens = ERC20(migrationHost).balanceOf(_tokensHolder);
        tokens = tokens * 125 / 100;
        balances[_tokensHolder] = tokens;
        totalSupply += tokens;
        Transfer(migrationHost, _tokensHolder, tokens);
    }
    
    function sealManualMigration() onlyOwner {
        delete migrationHost;
    }
}

/**
 * @title Crowdsale implementation
 */
contract Crowdsale is ManualMigration {
    uint    public etherPrice;
    address public crowdsaleOwner;
    uint    public totalLimitUSD;
    uint    public minimalSuccessUSD;
    uint    public collectedUSD;

    enum State { Disabled, PreICO, CompletePreICO, Crowdsale, Enabled, Migration }
    event NewState(State state);
    State   public state = State.Disabled;
    uint    public crowdsaleStartTime;
    uint    public crowdsaleFinishTime;

    modifier enabledState {
        require(state == State.Enabled);
        _;
    }

    modifier enabledOrMigrationState {
        require(state == State.Enabled || state == State.Migration);
        _;
    }

    struct Investor {
        uint amountTokens;
        uint amountWei;
    }
    mapping (address => Investor) public investors;
    mapping (uint => address)     public investorsIter;
    uint                          public numberOfInvestors;

    function Crowdsale(address _migrationHost)
        payable ManualMigration(_migrationHost) {
    }
    
    function () payable {
        require(state == State.PreICO || state == State.Crowdsale);
        require(now < crowdsaleFinishTime);
        uint valueWei = msg.value;
        uint valueUSD = valueWei * etherPrice / 1000000000000000000;
        if (collectedUSD + valueUSD > totalLimitUSD) { // don&#39;t need so much ether
            valueUSD = totalLimitUSD - collectedUSD;
            valueWei = valueUSD * 1000000000000000000 / etherPrice;
            require(msg.sender.call.gas(3000000).value(msg.value - valueWei)());
            collectedUSD = totalLimitUSD; // to be sure!
        } else {
            collectedUSD += valueUSD;
        }
        mintTokens(msg.sender, valueUSD, valueWei);
    }

    function depositUSD(address _who, uint _valueUSD) public onlyOwner {
        require(state == State.PreICO || state == State.Crowdsale);
        require(now < crowdsaleFinishTime);
        require(collectedUSD + _valueUSD <= totalLimitUSD);
        collectedUSD += _valueUSD;
        mintTokens(_who, _valueUSD, 0);
    }

    function mintTokens(address _who, uint _valueUSD, uint _valueWei) internal {
        uint tokensPerUSD = 100;
        if (state == State.PreICO) {
            if (now < crowdsaleStartTime + 1 days && _valueUSD >= 50000) {
                tokensPerUSD = 150;
            } else {
                tokensPerUSD = 125;
            }
        } else if (state == State.Crowdsale) {
            if (now < crowdsaleStartTime + 1 days) {
                tokensPerUSD = 115;
            } else if (now < crowdsaleStartTime + 1 weeks) {
                tokensPerUSD = 110;
            }
        }
        uint tokens = tokensPerUSD * _valueUSD;
        require(balances[_who] + tokens > balances[_who]); // overflow
        require(tokens > 0);
        Investor storage inv = investors[_who];
        if (inv.amountTokens == 0) { // new investor
            investorsIter[numberOfInvestors++] = _who;
        }
        inv.amountTokens += tokens;
        inv.amountWei += _valueWei;
        balances[_who] += tokens;
        Transfer(this, _who, tokens);
        totalSupply += tokens;
    }
    
    function startTokensSale(
            address _crowdsaleOwner,
            uint    _crowdsaleDurationDays,
            uint    _totalLimitUSD,
            uint    _minimalSuccessUSD,
            uint    _etherPrice) public onlyOwner {
        require(state == State.Disabled || state == State.CompletePreICO);
        crowdsaleStartTime = now;
        crowdsaleOwner = _crowdsaleOwner;
        etherPrice = _etherPrice;
        delete numberOfInvestors;
        delete collectedUSD;
        crowdsaleFinishTime = now + _crowdsaleDurationDays * 1 days;
        totalLimitUSD = _totalLimitUSD;
        minimalSuccessUSD = _minimalSuccessUSD;
        if (state == State.Disabled) {
            state = State.PreICO;
        } else {
            state = State.Crowdsale;
        }
        NewState(state);
    }
    
    function timeToFinishTokensSale() public constant returns(uint t) {
        require(state == State.PreICO || state == State.Crowdsale);
        if (now > crowdsaleFinishTime) {
            t = 0;
        } else {
            t = crowdsaleFinishTime - now;
        }
    }
    
    function finishTokensSale(uint _investorsToProcess) public {
        require(state == State.PreICO || state == State.Crowdsale);
        require(now >= crowdsaleFinishTime || collectedUSD == totalLimitUSD ||
            (collectedUSD >= minimalSuccessUSD && msg.sender == owner));
        if (collectedUSD < minimalSuccessUSD) {
            // Investors can get their ether calling withdrawBack() function
            while (_investorsToProcess > 0 && numberOfInvestors > 0) {
                address addr = investorsIter[--numberOfInvestors];
                Investor memory inv = investors[addr];
                balances[addr] -= inv.amountTokens;
                totalSupply -= inv.amountTokens;
                Transfer(addr, this, inv.amountTokens);
                --_investorsToProcess;
                delete investorsIter[numberOfInvestors];
            }
            if (numberOfInvestors > 0) {
                return;
            }
            if (state == State.PreICO) {
                state = State.Disabled;
            } else {
                state = State.CompletePreICO;
            }
        } else {
            while (_investorsToProcess > 0 && numberOfInvestors > 0) {
                --numberOfInvestors;
                --_investorsToProcess;
                delete investors[investorsIter[numberOfInvestors]];
                delete investorsIter[numberOfInvestors];
            }
            if (numberOfInvestors > 0) {
                return;
            }
            if (state == State.PreICO) {
                require(crowdsaleOwner.call.gas(3000000).value(this.balance)());
                state = State.CompletePreICO;
            } else {
                require(crowdsaleOwner.call.gas(3000000).value(minimalSuccessUSD * 1000000000000000000 / etherPrice)());
                // Create additional tokens for owner (30% of complete totalSupply)
                uint tokens = 3 * totalSupply / 7;
                balances[owner] = tokens;
                totalSupply += tokens;
                Transfer(this, owner, tokens);
                state = State.Enabled;
            }
        }
        NewState(state);
    }
    
    // This function must be called by token holder in case of crowdsale failed
    function withdrawBack() public {
        require(state == State.Disabled || state == State.CompletePreICO);
        uint value = investors[msg.sender].amountWei;
        if (value > 0) {
            delete investors[msg.sender];
            require(msg.sender.call.gas(3000000).value(value)());
        }
    }
}

/**
 * @title Abstract interface for PROOF operating from registered external controllers
 */
contract Fund {
    function transferFund(address _to, uint _value);
}

/**
 * @title Token PROOF implementation
 */
contract Token is Crowdsale, Fund {
    
    string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;PROOF&#39;;
    string  public symbol      = "PF";
    uint8   public decimals    = 0;

    mapping (address => mapping (address => uint)) public allowed;
    mapping (address => bool) public externalControllers;

    modifier onlyTokenHolders {
        require(balances[msg.sender] != 0);
        _;
    }

    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier externalController {
        require(externalControllers[msg.sender]);
        _;
    }

    function Token(address _migrationHost)
        payable Crowdsale(_migrationHost) {}

    function balanceOf(address who) constant returns (uint) {
        return balances[who];
    }

    function transfer(address _to, uint _value)
        public enabledState onlyPayloadSize(2 * 32) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value)
        public enabledState onlyPayloadSize(3 * 32) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public enabledState {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant enabledState
        returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function transferFund(address _to, uint _value) public externalController {
        require(balances[this] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        balances[this] -= _value;
        balances[_to] += _value;
        Transfer(this, _to, _value);
    }
}

contract ProofVote is Token {

    function ProofVote(address _migrationHost)
        payable Token(_migrationHost) {}

    event VotingStarted(uint weiReqFund, VoteReason voteReason);
    event Voted(address indexed voter, bool inSupport);
    event VotingFinished(bool inSupport);

    enum Vote { NoVote, VoteYea, VoteNay }
    enum VoteReason { Nothing, ReqFund, Migration, UpdateContract }

    uint public weiReqFund;
    uint public votingDeadline;
    uint public numberOfVotes;
    uint public yea;
    uint public nay;
    VoteReason  voteReason;
    mapping (address => Vote) public votes;
    mapping (uint => address) public votesIter;

    address public migrationAgent;
    address public migrationAgentCandidate;
    address public externalControllerCandidate;

    function startVoting(uint _weiReqFund) public enabledOrMigrationState onlyOwner {
        require(_weiReqFund > 0);
        internalStartVoting(_weiReqFund, VoteReason.ReqFund, 7);
    }

    function internalStartVoting(uint _weiReqFund, VoteReason _voteReason, uint _votingDurationDays) internal {
        require(voteReason == VoteReason.Nothing && _weiReqFund <= this.balance);
        weiReqFund = _weiReqFund;
        votingDeadline = now + _votingDurationDays * 1 days;
        voteReason = _voteReason;
        delete yea;
        delete nay;
        VotingStarted(_weiReqFund, _voteReason);
    }
    
    function votingInfo() public constant
        returns(uint _weiReqFund, uint _timeToFinish, VoteReason _voteReason) {
        _weiReqFund = weiReqFund;
        _voteReason = voteReason;
        if (votingDeadline <= now) {
            _timeToFinish = 0;
        } else {
            _timeToFinish = votingDeadline - now;
        }
    }

    function vote(bool _inSupport) public onlyTokenHolders returns (uint voteId) {
        require(voteReason != VoteReason.Nothing);
        require(votes[msg.sender] == Vote.NoVote);
        require(votingDeadline > now);
        voteId = numberOfVotes++;
        votesIter[voteId] = msg.sender;
        if (_inSupport) {
            votes[msg.sender] = Vote.VoteYea;
        } else {
            votes[msg.sender] = Vote.VoteNay;
        }
        Voted(msg.sender, _inSupport);
        return voteId;
    }

    function finishVoting(uint _votesToProcess) public returns (bool _inSupport) {
        require(voteReason != VoteReason.Nothing);
        require(now >= votingDeadline);

        while (_votesToProcess > 0 && numberOfVotes > 0) {
            address voter = votesIter[--numberOfVotes];
            Vote v = votes[voter];
            uint voteWeight = balances[voter];
            if (v == Vote.VoteYea) {
                yea += voteWeight;
            } else if (v == Vote.VoteNay) {
                nay += voteWeight;
            }
            delete votes[voter];
            delete votesIter[numberOfVotes];
            --_votesToProcess;
        }
        if (numberOfVotes > 0) {
            _inSupport = false;
            return;
        }

        _inSupport = (yea > nay);
        uint weiForSend = weiReqFund;
        delete weiReqFund;
        delete votingDeadline;
        delete numberOfVotes;

        if (_inSupport) {
            if (voteReason == VoteReason.ReqFund) {
                require(owner.call.gas(3000000).value(weiForSend)());
            } else if (voteReason == VoteReason.Migration) {
                migrationAgent = migrationAgentCandidate;
                require(migrationAgent.call.gas(3000000).value(this.balance)());
                delete migrationAgentCandidate;
                state = State.Migration;
            } else if (voteReason == VoteReason.UpdateContract) {
                externalControllers[externalControllerCandidate] = true;
                delete externalControllerCandidate;
            }
        }

        delete voteReason;
        VotingFinished(_inSupport);
    }
}

/**
 * @title Migration agent intefrace for possibility of moving tokens
 *        to another contract
 */
contract MigrationAgent {
    function migrateFrom(address _from, uint _value);
}

/**
 * @title Migration functionality for possibility of moving tokens
 *        to another contract
 */
contract TokenMigration is ProofVote {
    
    uint public totalMigrated;

    event Migrate(address indexed from, address indexed to, uint value);

    function TokenMigration(address _migrationHost) payable ProofVote(_migrationHost) {}

    // Migrate _value of tokens to the new token contract
    function migrate() external {
        require(state == State.Migration);
        uint value = balances[msg.sender];
        balances[msg.sender] -= value;
        Transfer(msg.sender, this, value);
        totalSupply -= value;
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        Migrate(msg.sender, migrationAgent, value);
    }

    function setMigrationAgent(address _agent) external onlyOwner {
        require(migrationAgent == 0 && _agent != 0);
        migrationAgentCandidate = _agent;
        internalStartVoting(0, VoteReason.Migration, 2);
    }
}

contract ProofFund is TokenMigration {

    function ProofFund(address _migrationHost)
        payable TokenMigration(_migrationHost) {}

    function addExternalController(address _externalControllerCandidate) public onlyOwner {
        require(_externalControllerCandidate != 0);
        externalControllerCandidate = _externalControllerCandidate;
        internalStartVoting(0, VoteReason.UpdateContract, 2);
    }

    function removeExternalController(address _externalController) public onlyOwner {
        delete externalControllers[_externalController];
    }
}

/**
 * @title Proof interface
 */
contract ProofAbstract {
    function swypeCode(address _who) returns (uint16 _swype);
    function setHash(address _who, uint16 _swype, bytes32 _hash);
}

contract Proof is ProofFund {

    uint    public priceInTokens;
    uint    public teamFee;
    address public proofImpl;

    function Proof(address _migrationHost)
        payable ProofFund(_migrationHost) {}

    function setPrice(uint _priceInTokens) public onlyOwner {
        require(_priceInTokens >= 2);
        teamFee = _priceInTokens / 10;
        if (teamFee == 0) {
            teamFee = 1;
        }
        priceInTokens = _priceInTokens - teamFee;
    }

    function setProofImpl(address _proofImpl) public onlyOwner {
        proofImpl = _proofImpl;
    }

    function swypeCode() public returns (uint16 _swype) {
        require(proofImpl != 0);
        _swype = ProofAbstract(proofImpl).swypeCode(msg.sender);
    }
    
    function setHash(uint16 _swype, bytes32 _hash) public {
        require(proofImpl != 0);
        transfer(owner, teamFee);
        transfer(this, priceInTokens);
        ProofAbstract(proofImpl).setHash(msg.sender, _swype, _hash);
    }
}