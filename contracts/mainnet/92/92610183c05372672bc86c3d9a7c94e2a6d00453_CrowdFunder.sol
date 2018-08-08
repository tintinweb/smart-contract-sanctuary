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
//File: contracts/common/SafeMath.sol
pragma solidity ^0.4.21;

contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

//File: ./contracts/CrowdFunder.sol
pragma solidity ^0.4.21;





contract CrowdFunder is Controlled, SafeMath {
    address public creator;
    address public fundRecipient;
    address public reserveTeamRecipient;
    address public reserveBountyRecipient;
    address public developersRecipient;
    address public marketingRecipient;

    bool public isReserveGenerated;

    uint investorCount;
    uint public currentBalance;
    uint public tokensIssued;
    uint public capTokenAmount;
    uint public startBlockNumber;
    uint public endBlockNumber;
    uint public tokenExchangeRate;

    address[] fiatInvestors;

    Token public exchangeToken;

    enum State {
        Wait,
        Fundraising,
        Successful,
        Closed
    }
    State public state = State.Wait;

    event GoalReached(address fundRecipient, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FrozenFunds(address target, bool frozen);
    event LogFundingReceived(address addr, uint amount, uint currentTotal);

    mapping (address => uint256) private balanceOf;
    mapping (address => uint) public fiatInvestorShare;
    mapping (address => bool) private frozenAccount;

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

    function CrowdFunder(
        address _fundRecipient,
        address _reserveTeamRecipient,
        address _reserveBountyRecipient,
        address _developersRecipient,
        address _marketingRecipient,
        Token _addressOfExchangeToken
    ) public {
        creator = msg.sender;

        fundRecipient = _fundRecipient;
        reserveTeamRecipient = _reserveTeamRecipient;
        reserveBountyRecipient = _reserveBountyRecipient;
        developersRecipient = _developersRecipient;
        marketingRecipient = _marketingRecipient;

        isReserveGenerated = false;

        capTokenAmount = 10000000 * 10 ** 9;

        state = State.Wait;

        exchangeToken = Token(_addressOfExchangeToken);

        currentBalance = 0;
        tokensIssued = 0;
        tokenExchangeRate = 0;
    }

    function startFundraising() public inState(State.Wait) onlyController {
        startBlockNumber = block.number;
        endBlockNumber = startBlockNumber + ((31 * 24 * 3600) / 15); // 31 days
        state = State.Fundraising;
        tokensIssued = exchangeToken.totalSupply();
        updateExchangeRate();
    }

    function changeReserveBountyRecipient(address _reserveBountyRecipient) public onlyController {
        reserveBountyRecipient = _reserveBountyRecipient;
    }

    function changeDevelopersRecipient(address _developersRecipient) public onlyController {
        developersRecipient = _developersRecipient;
    }

    function changeMarketingRecipient(address _marketingRecipient) public onlyController {
        marketingRecipient = _marketingRecipient;
    }

    function addInvestor(address target, uint share) public onlyController {
        if (fiatInvestorShare[target] == uint(0x0)) { // new address
            fiatInvestorShare[target] = share;
            fiatInvestors.push(target);
        } else { // address already exists
            if (share > 0) {
                uint prevShare = fiatInvestorShare[target];
                uint newShare = prevShare + share;

                fiatInvestorShare[target] = newShare;
            }
        }
    }

    function freezeAccount(address target, bool freeze) public onlyController {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function updateExchangeRate() public {
        if (tokensIssued >= 0 && tokensIssued < (1000000 * 10 ** 9)) {
            tokenExchangeRate = 1000 * 10 ** 9;
        }
        if (tokensIssued >= (1000000 * 10 ** 9) && tokensIssued < (2000000 * 10 ** 9)) {
            tokenExchangeRate = 600 * 10 ** 9;
        }
        if (tokensIssued >= (2000000 * 10 ** 9) && tokensIssued < (3500000 * 10 ** 9)) {
            tokenExchangeRate = 500 * 10 ** 9;
        }
        if (tokensIssued >= (3500000 * 10 ** 9) && tokensIssued < (6000000 * 10 ** 9)) {
            tokenExchangeRate = 400 * 10 ** 9;
        }
        if (tokensIssued >= (6000000 * 10 ** 9)) {
            tokenExchangeRate = 300 * 10 ** 9;
        }
    }

    function getExchangeRate(uint amount) public constant returns (uint) {
        return tokenExchangeRate * amount / 1 ether;
    }

    function investment() public inState(State.Fundraising) accountNotFrozen minInvestment payable returns (uint)  {
        uint amount = msg.value;

        balanceOf[msg.sender] += amount;
        currentBalance += amount;

        updateExchangeRate();
        uint tokenAmount = getExchangeRate(amount);
        exchangeToken.generateTokens(msg.sender, tokenAmount);
        tokensIssued += tokenAmount;
        updateExchangeRate();

        emit FundTransfer(msg.sender, amount, true);
        emit LogFundingReceived(msg.sender, tokenAmount, tokensIssued);

        checkIfFundingCompleteOrExpired();

        return balanceOf[msg.sender];
    }

    function checkIfFundingCompleteOrExpired() private {
        if (block.number > endBlockNumber || tokensIssued >= capTokenAmount) {
            state = State.Successful;
            emit GoalReached(fundRecipient, currentBalance);
        }
    }

    function endFundraising() public inState(State.Successful) onlyController() {
        uint amount = currentBalance;
        uint balance = currentBalance;

        for (uint i = 0; i < fiatInvestors.length; i++) {
            address investorAddress = fiatInvestors[i];
            uint investorShare = fiatInvestorShare[investorAddress];
            uint investorAmount = div(mul(balance, investorShare), 1000000);
            investorAddress.transfer(investorAmount);
            amount -= investorAmount;
        }

        uint percentDevelopers = 5;
        uint percentMarketing = 5;
        uint amountDevelopers = div(mul(balance, percentDevelopers), 100);
        uint amountMarketing = div(mul(balance, percentMarketing), 100);

        developersRecipient.transfer(amountDevelopers);
        marketingRecipient.transfer(amountMarketing);

        amount -= (amountDevelopers + amountMarketing);

        fundRecipient.transfer(amount);

        generateReserve();

        currentBalance = 0;
        state = State.Closed;

        exchangeToken.changeController(controller);
    }

    function generateReserve() private {
        require(isReserveGenerated == false);

        uint issued = tokensIssued;
        uint percentTeam = 15;
        uint percentBounty = 1;
        uint reserveAmountTeam = div(mul(issued, percentTeam), 85);
        uint reserveAmountBounty = div(mul(issued, percentBounty), 99);

        exchangeToken.generateTokens(reserveTeamRecipient, reserveAmountTeam);
        exchangeToken.generateTokens(reserveBountyRecipient, reserveAmountBounty);

        isReserveGenerated = true;
    }

    function removeContract() public inState(State.Closed) onlyController {
        selfdestruct(msg.sender);
    }

    function() inState(State.Fundraising) public accountNotFrozen minInvestment payable {
        investment();
    }

}