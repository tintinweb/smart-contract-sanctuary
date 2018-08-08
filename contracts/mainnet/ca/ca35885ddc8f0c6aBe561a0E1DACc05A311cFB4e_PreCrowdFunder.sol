//File: contracts/common/Controlled.sol
pragma solidity ^0.4.21;

contract Controlled {
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

//File: contracts/common/TokenController.sol
pragma solidity ^0.4.21;

contract TokenController {
    function proxyPayment(address _owner) public payable returns(bool);

    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}

//File: contracts/common/ApproveAndCallFallBack.sol
pragma solidity ^0.4.21;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

//File: contracts/Token.sol
pragma solidity ^0.4.21;






contract Token is Controlled {

    string public name = "ShineCoin";
    uint8 public decimals = 9;
    string public symbol = "SHINE";

    struct  Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

    uint public creationBlock;

    mapping (address => Checkpoint[]) balances;

    mapping (address => mapping (address => uint256)) allowed;

    Checkpoint[] totalSupplyHistory;

    bool public transfersEnabled = true;

    address public frozenReserveTeamWallet;

    uint public unfreezeTeamWalletBlock;

    function Token(address _frozenReserveTeamWallet) public {
        creationBlock = block.number;
        frozenReserveTeamWallet = _frozenReserveTeamWallet;
        unfreezeTeamWalletBlock = block.number + ((365 * 24 * 3600) / 15); // ~ 396 days
    }


///////////////////
// ERC20 Methods
///////////////////

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        if (address(msg.sender) == frozenReserveTeamWallet) {
            require(block.number > unfreezeTeamWalletBlock);
        }

        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (msg.sender != controller) {
            require(transfersEnabled);

            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }


    function doTransfer(address _from, address _to, uint _amount) internal {

           if (_amount <= 0) {
               emit Transfer(_from, _to, _amount);
               return;
           }

           require((_to != 0) && (_to != address(this)));

           uint256 previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           uint256 previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           emit Transfer(_from, _to, _amount);

    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }

    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {

        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;

        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

    function generateTokens(address _owner, uint _amount) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }

    function destroyTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }


    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}
//File: ./contracts/PreCrowdFunder.sol
pragma solidity ^0.4.21;




contract PreCrowdFunder is Controlled {
    address public creator;
    address public fundRecipient;
    uint public currentBalance;
    uint public tokensIssued;
    uint public capTokenAmount;
    uint public tokenExchangeRate;
    Token public exchangeToken;
    enum State {
        Wait,
        Fundraising,
        Successful,
        Closed
    }
    State public state = State.Wait;

    // Events
    event GoalReached(address fundRecipient, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FrozenFunds(address target, bool frozen);
    event LogFundingReceived(address addr, uint amount, uint currentTotal);

    // Maps
    mapping (address => uint256) private balanceOf;
    mapping (address => bool) private frozenAccount;

    // Modifiers
    modifier inState(State _state) {
        require(state == _state);
        _;
    }
    modifier accountNotFrozen() {
        require(!(frozenAccount[msg.sender] == true));
        _;
    }
    modifier minInvestment() {
        // User has to send at least 0.01 Eth
        require(msg.value >= 10 ** 16);
        _;
    }

    // Constructor
    function PreCrowdFunder(address _fundRecipient, Token _addressOfExchangeToken) public {
        creator = msg.sender;
        fundRecipient = _fundRecipient;
        capTokenAmount = 10000000 * 10 ** 9;
        state = State.Wait;
        currentBalance = 0;
        tokensIssued = 0;
        tokenExchangeRate = 1000 * 10 ** 9;
        exchangeToken = Token(_addressOfExchangeToken);
    }

    function startFundraising() public inState(State.Wait) onlyController {
        state = State.Fundraising;
        tokensIssued = exchangeToken.totalSupply();
    }

    function endFundraising() public onlyController {
        require(state == State.Fundraising || state == State.Successful);
        fundRecipient.transfer(currentBalance);
        currentBalance = 0;
        state = State.Closed;
        exchangeToken.changeController(controller);
    }

    function freezeAccount(address target, bool freeze) public onlyController {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function getExchangeRate(uint amount) public constant returns (uint) {
        return tokenExchangeRate * amount / 1 ether;
    }

    function investment() public inState(State.Fundraising) accountNotFrozen minInvestment payable returns (uint)  {
        uint amount = msg.value;

        balanceOf[msg.sender] += amount;
        currentBalance += amount;

        uint tokenAmount = getExchangeRate(amount);
        exchangeToken.generateTokens(msg.sender, tokenAmount);
        tokensIssued += tokenAmount;

        emit FundTransfer(msg.sender, amount, true);
        emit LogFundingReceived(msg.sender, tokenAmount, tokensIssued);

        if (tokensIssued >= capTokenAmount) {
            state = State.Successful;
            emit GoalReached(fundRecipient, currentBalance);
        }

        return balanceOf[msg.sender];
    }

    function removeContract() public inState(State.Closed) onlyController {
        selfdestruct(msg.sender);
    }

    function() inState(State.Fundraising) public accountNotFrozen minInvestment payable {
        investment();
    }

}