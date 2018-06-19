pragma solidity ^0.4.15;

// ERC20 Interface
contract ERC20 {
    function transfer(address _to, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
}

contract PresalePool {
    enum State { Open, Failed, Closed, Paid }
    State public state;

    address[] public admins;

    uint public minContribution;
    uint public maxContribution;
    uint public maxPoolTotal;

    address[] public participants;

    bool public whitelistAll;

    struct ParticipantState {
        uint contribution;
        uint remaining;
        bool whitelisted;
        bool exists;
    }
    mapping (address => ParticipantState) public balances;
    uint public poolTotal;

    address presaleAddress;
    bool refundable;
    uint gasFundTotal;

    ERC20 public token;

    event Deposit(
        address indexed _from,
        uint _value
    );
    event Payout(
        address indexed _to,
        uint _value
    );
    event Withdrawl(
        address indexed _to,
        uint _value
    );

    modifier onlyAdmins() {
        require(isAdmin(msg.sender));
        _;
    }

    modifier onState(State s) {
        require(state == s);
        _;
    }

    modifier stateAllowsConfiguration() {
        require(state == State.Open || state == State.Closed);
        _;
    }

    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function PresalePool(uint _minContribution, uint _maxContribution, uint _maxPoolTotal, address[] _admins) payable {
        state = State.Open;
        admins.push(msg.sender);

        setContributionSettings(_minContribution, _maxContribution, _maxPoolTotal);

        whitelistAll = true;

        for (uint i = 0; i < _admins.length; i++) {
            var admin = _admins[i];
            if (!isAdmin(admin)) {
                admins.push(admin);
            }
        }

        deposit();
    }

    function () payable {
        deposit();
    }

    function close() public onlyAdmins onState(State.Open) {
        state = State.Closed;
    }

    function open() public onlyAdmins onState(State.Closed) {
        state = State.Open;
    }

    function fail() public onlyAdmins stateAllowsConfiguration {
        state = State.Failed;
    }

    function payToPresale(address _presaleAddress) public onlyAdmins onState(State.Closed) {
        state = State.Paid;
        presaleAddress = _presaleAddress;
        refundable = true;
        presaleAddress.transfer(poolTotal);
    }

    function refundPresale() payable public onState(State.Paid) {
        require(refundable && msg.value >= poolTotal);
        require(msg.sender == presaleAddress || isAdmin(msg.sender));
        gasFundTotal = msg.value - poolTotal;
        state = State.Failed;
    }

    function setToken(address tokenAddress) public onlyAdmins {
        token = ERC20(tokenAddress);
    }

    function withdrawAll() public {
        uint total = balances[msg.sender].remaining;
        balances[msg.sender].remaining = 0;

        if (state == State.Open || state == State.Failed) {
            total += balances[msg.sender].contribution;
            if (gasFundTotal > 0) {
                uint gasRefund = (balances[msg.sender].contribution * gasFundTotal) / (poolTotal);
                gasFundTotal -= gasRefund;
                total += gasRefund;
            }
            poolTotal -= balances[msg.sender].contribution;
            balances[msg.sender].contribution = 0;
        } else {
            require(state == State.Paid);
        }

        msg.sender.transfer(total);
        Withdrawl(msg.sender, total);
    }

    function withdraw(uint amount) public onState(State.Open) {
        uint total = balances[msg.sender].remaining + balances[msg.sender].contribution;
        require(total >= amount);
        uint debit = min(balances[msg.sender].remaining, amount);
        balances[msg.sender].remaining -= debit;
        debit = amount - debit;
        balances[msg.sender].contribution -= debit;
        poolTotal -= debit;

        (balances[msg.sender].contribution, balances[msg.sender].remaining) = getContribution(msg.sender, 0);
        // must respect the minContribution limit
        require(balances[msg.sender].remaining == 0 || balances[msg.sender].contribution > 0);
        msg.sender.transfer(amount);
        Withdrawl(msg.sender, amount);
    }

    function transferMyTokens() public onState(State.Paid) noReentrancy {
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0);

        uint participantContribution = balances[msg.sender].contribution;
        uint participantShare = participantContribution * tokenBalance / poolTotal;

        poolTotal -= participantContribution;
        balances[msg.sender].contribution = 0;
        refundable = false;
        require(token.transfer(msg.sender, participantShare));

        Payout(msg.sender, participantShare);
    }

    address[] public failures;
    function transferAllTokens() public onlyAdmins onState(State.Paid) noReentrancy returns (address[]) {
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0);
        delete failures;

        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint participantContribution = balances[participant].contribution;

            if (participantContribution > 0) {
                uint participantShare = participantContribution * tokenBalance / poolTotal;

                poolTotal -= participantContribution;
                balances[participant].contribution = 0;

                if (token.transfer(participant, participantShare)) {
                    refundable = false;
                    Payout(participant, participantShare);
                    tokenBalance -= participantShare;
                    if (tokenBalance == 0) {
                        break;
                    }
                } else {
                    balances[participant].contribution = participantContribution;
                    poolTotal += participantContribution;
                    failures.push(participant);
                }
            }
        }

        return failures;
    }

    function modifyWhitelist(address[] toInclude, address[] toExclude) public onlyAdmins stateAllowsConfiguration {
        bool previous = whitelistAll;
        uint i;
        if (previous) {
            require(toExclude.length == 0);
            for (i = 0; i < participants.length; i++) {
                balances[participants[i]].whitelisted = false;
            }
            whitelistAll = false;
        }

        for (i = 0; i < toInclude.length; i++) {
            balances[toInclude[i]].whitelisted = true;
        }

        address excludedParticipant;
        uint contribution;
        if (previous) {
            for (i = 0; i < participants.length; i++) {
                excludedParticipant = participants[i];
                if (!balances[excludedParticipant].whitelisted) {
                    contribution = balances[excludedParticipant].contribution;
                    balances[excludedParticipant].contribution = 0;
                    balances[excludedParticipant].remaining += contribution;
                    poolTotal -= contribution;
                }
            }
        } else {
            for (i = 0; i < toExclude.length; i++) {
                excludedParticipant = toExclude[i];
                balances[excludedParticipant].whitelisted = false;
                contribution = balances[excludedParticipant].contribution;
                balances[excludedParticipant].contribution = 0;
                balances[excludedParticipant].remaining += contribution;
                poolTotal -= contribution;
            }
        }
    }

    function removeWhitelist() public onlyAdmins stateAllowsConfiguration {
        if (!whitelistAll) {
            whitelistAll = true;
            for (uint i = 0; i < participants.length; i++) {
                balances[participants[i]].whitelisted = true;
            }
        }
    }

    function setContributionSettings(uint _minContribution, uint _maxContribution, uint _maxPoolTotal) public onlyAdmins stateAllowsConfiguration {
        // we raised the minContribution threshold
        bool recompute = (minContribution < _minContribution);
        // we lowered the maxContribution threshold
        recompute = recompute || (maxContribution > _maxContribution);
        // we did not have a maxContribution threshold and now we do
        recompute = recompute || (maxContribution == 0 && _maxContribution > 0);
        // we want to make maxPoolTotal lower than the current pool total
        recompute = recompute || (poolTotal > _maxPoolTotal);

        minContribution = _minContribution;
        maxContribution = _maxContribution;
        maxPoolTotal = _maxPoolTotal;

        if (maxContribution > 0) {
            require(maxContribution >= minContribution);
        }
        if (maxPoolTotal > 0) {
            require(maxPoolTotal >= minContribution);
            require(maxPoolTotal >= maxContribution);
        }

        if (recompute) {
            poolTotal = 0;
            for (uint i = 0; i < participants.length; i++) {
                address participant = participants[i];
                var balance = balances[participant];
                (balance.contribution, balance.remaining) = getContribution(participant, 0);
                poolTotal += balance.contribution;
            }
        }
    }

    function getParticipantBalances() public returns(address[], uint[], uint[], bool[], bool[]) {
        uint[] memory contribution = new uint[](participants.length);
        uint[] memory remaining = new uint[](participants.length);
        bool[] memory whitelisted = new bool[](participants.length);
        bool[] memory exists = new bool[](participants.length);

        for (uint i = 0; i < participants.length; i++) {
            var balance = balances[participants[i]];
            contribution[i] = balance.contribution;
            remaining[i] = balance.remaining;
            whitelisted[i] = balance.whitelisted;
            exists[i] = balance.exists;
        }

        return (participants, contribution, remaining, whitelisted, exists);
    }

    function deposit() internal onState(State.Open) {
        if (msg.value > 0) {
            require(included(msg.sender));
            (balances[msg.sender].contribution, balances[msg.sender].remaining) = getContribution(msg.sender, msg.value);
            // must respect the maxContribution and maxPoolTotal limits
            require(balances[msg.sender].remaining == 0);
            balances[msg.sender].whitelisted = true;
            poolTotal += msg.value;
            if (!balances[msg.sender].exists) {
                balances[msg.sender].exists = true;
                participants.push(msg.sender);
            }
            Deposit(msg.sender, msg.value);
        }
    }

    function isAdmin(address addr) internal constant returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function included(address participant) internal constant returns (bool) {
        return whitelistAll || balances[participant].whitelisted || isAdmin(participant);
    }

    function getContribution(address participant, uint amount) internal constant returns (uint, uint) {
        var balance = balances[participant];
        uint total = balance.remaining + balance.contribution + amount;
        uint contribution = total;
        if (!included(participant)) {
            return (0, total);
        }
        if (maxContribution > 0) {
            contribution = min(maxContribution, contribution);
        }
        if (maxPoolTotal > 0) {
            contribution = min(maxPoolTotal - poolTotal, contribution);
        }
        if (contribution < minContribution) {
            return (0, total);
        }
        return (contribution, total - contribution);
    }

    function min(uint a, uint b) internal pure returns (uint _min) {
        if (a < b) {
            return a;
        }
        return b;
    }
}