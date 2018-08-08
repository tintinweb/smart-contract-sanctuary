pragma solidity ^0.4.14;

contract Totalizeum {
    enum MarketState { Initial, Resolving, Resolved, Unresolved }

    struct Market {
        MarketState state;
        uint256 balance;
        Resolve resolve;
        Settings settings;
        mapping (uint256 => Outcome) outcomes;
    }

    struct Outcome {
        uint256 balance;
        bool won;
        mapping (address => uint256) bets;
    }

    struct Resolve {
        uint256 remainingBalance;
        uint256 winningBalance;
        uint256 winningOutcomes;
    }

    struct Settings {
        uint256 refundDelay;
        uint256 share;
    }

    string public constant symbol = "TOT";

    string public constant name = "Totalizeum";

    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = (uint256(10) ** 6) *
        (uint256(10) ** decimals);

    Settings private defaultSettings = Settings(1 days, 980);

    uint256 private constant sub = 1000000;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    mapping (address => mapping(uint256 => Market)) markets;

    mapping (address => Settings) oracleSettings;

    mapping (address => mapping (address => bool)) public successor;

    uint256 public sellable = totalSupply;

    address public owner;

    function Totalizeum() {
        owner = msg.sender;
    }

    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (bool) {
        require(msg.data.length >= (2 * 32) + 4);

        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;

            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from, address _to, uint256 _amount
    ) returns (bool) {
        require(msg.data.length >= (3 * 32) + 4);

        if (balances[_from] >= _amount &&
            _amount > 0 &&
            allowed[_from][msg.sender] >= _amount &&
            balances[_to] + _amount > balances[_to]) {

            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;

            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;

        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(
        address _owner, address _spender
    ) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function bet(
        address _oracle, uint256 _timestamp, uint256 _outcome, uint256 _amount
    ) returns (bool) {
        Market storage market = markets[_oracle][_timestamp];
        Outcome storage outcome = market.outcomes[_outcome];

        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            now < _timestamp &&
            market.state == MarketState.Initial &&
            market.balance + _amount > market.balance &&
            (market.balance + _amount) * sub / sub
                == (market.balance + _amount) &&
            outcome.balance + _amount > outcome.balance &&
            outcome.bets[msg.sender] + _amount > outcome.bets[msg.sender]) {

            if (market.balance == 0) {
                Settings storage settings = oracleSettings[_oracle];

                if (settings.refundDelay > 0) {

                    market.settings = settings;
                } else {
                    market.settings = defaultSettings;
                }
            }

            balances[msg.sender] -= _amount;
            market.balance += _amount;
            outcome.balance += _amount;
            outcome.bets[msg.sender] += _amount;

            Bet(msg.sender, _oracle, _timestamp, _outcome, _amount);
            return true;
        } else {
            return false;
        }
    }

    function resolve(
        uint256 _timestamp, uint256 _outcome, bool _final
    ) returns (bool) {
        Market storage market = markets[msg.sender][_timestamp];
        Outcome storage outcome = market.outcomes[_outcome];
        Resolve storage _resolve = market.resolve;
        Settings storage settings = market.settings;

        if (market.state == MarketState.Initial) {

            market.state = MarketState.Resolving;
            _resolve.remainingBalance = market.balance;
        }

        if (market.state == MarketState.Resolving &&
            now >= _timestamp &&
            market.balance > 0) {

            if (!outcome.won &&
                outcome.balance > 0) {

                outcome.won = true;
                _resolve.winningBalance += outcome.balance;
                _resolve.winningOutcomes += 1;
            }

            if (_final &&
                _resolve.winningOutcomes > 0) {

                uint256 share = market.balance - market.balance / 1000
                    * settings.share;
                
                market.state = MarketState.Resolved;
                _resolve.remainingBalance -= share;
                balances[msg.sender] += share;
            }

            Resolved(msg.sender, _timestamp, _outcome, _final);
            return true;
        } else {
            return false;
        }
    }

    function withdraw(
        address _oracle, uint256 _timestamp, uint256 _outcome
    ) returns (bool) {
        Market storage market = markets[_oracle][_timestamp];
        Outcome storage outcome = market.outcomes[_outcome];
        Resolve storage _resolve = market.resolve;
        Settings storage settings = market.settings;

        if (outcome.bets[msg.sender] > 0) {
            uint256 amount = outcome.bets[msg.sender];

            if (market.state == MarketState.Resolved &&
                outcome.won) {

                uint256 share = market.balance * sub / 1000 * settings.share
                    / _resolve.winningOutcomes / outcome.balance * amount
                    / sub;

                delete outcome.bets[msg.sender];
                _resolve.winningBalance -= amount;
                _resolve.remainingBalance -= share;
                balances[msg.sender] += share;

                Withdrawal(msg.sender, _oracle, _timestamp, _outcome, share);

                if (_resolve.winningBalance == 0) {
                    balances[_oracle] += _resolve.remainingBalance;
                    delete _resolve.remainingBalance;
                }

                return true;
            } else if ((market.state == MarketState.Initial ||
                    market.state == MarketState.Resolving ||
                    market.state == MarketState.Unresolved) &&
                now >= _timestamp + settings.refundDelay) {

                market.state = MarketState.Unresolved;

                delete outcome.bets[msg.sender];
                balances[msg.sender] += amount;

                Withdrawal(msg.sender, _oracle, _timestamp, _outcome, amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function marketState(
        address _oracle, uint256 _timestamp
    ) constant returns (MarketState, uint256, uint256, uint256) {
        Market storage market = markets[_oracle][_timestamp];
        Resolve storage _resolve = market.resolve;

        return (market.state, market.balance, _resolve.winningOutcomes,
            _resolve.remainingBalance);
    }

    function outcomeState(
        address _oracle, uint256 _timestamp, uint256 _outcome
    ) constant returns (bool, uint256) {
        Outcome storage outcome = markets[_oracle][_timestamp]
            .outcomes[_outcome];

        return (outcome.won, outcome.balance);
    }

    function setSettings(
        uint256 _refundDelay, uint256 _share
    ) returns (bool) {

        if (_refundDelay > 0 &&
            _refundDelay <= 28 days &&
            _share <= 250) {

            oracleSettings[msg.sender] = Settings(_refundDelay,
                1000 - _share);
            
            SettingsSet(msg.sender, _refundDelay, _share);
            return true;
        } else {
            return false;
        }
    }

    function setSuccessor(address _successor) {
        successor[_successor][msg.sender] = true;
    }

    function () payable {
        uint256 amount = msg.value * 1000;

        if (amount / 1000 == msg.value &&
            amount <= sellable) {

            owner.transfer(msg.value);
            sellable -= amount;
            balances[msg.sender] += amount;

            Sale(msg.sender, amount);
        } else {
            revert();
        }
    }

    function setOwner(address _owner) {
        if (msg.sender == owner) {
            owner = _owner;
        }
    }

    event Transfer(address indexed _from, address indexed _to,
        uint256 _amount);

    event Approval(address indexed _owner, address indexed _spender,
        uint256 _amount);

    event Bet(address indexed _bettor, address indexed _oracle,
        uint256 indexed _timestamp, uint256 _outcome, uint256 _amount);

    event Resolved(address indexed _oracle, uint256 indexed _timestamp,
        uint256 indexed _outcome, bool _final);

    event Withdrawal(address indexed _bettor, address indexed _oracle,
        uint256 indexed _timestamp, uint256 _outcome, uint256 _amount);

    event Successor(address indexed _oracle, address indexed _successor);

    event SettingsSet(address indexed _oracle, uint256 _refundDelay,
        uint256 _share);

    event Sale(address indexed _buyer, uint256 _amount);
}