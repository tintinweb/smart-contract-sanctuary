/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract TKR {

    struct RakePayout {
        address addressOfTeamMember;
        uint256 percentRake;
    }

    // stateVariables
    // balances, indexed by addresses
    mapping (address => uint256) private _balances;

   // player locked funds into game escrow
    uint256 public totalEscrow;

    // minDeposit for game
    uint256 public minDeposit;

    // contract owner set during deployment
    address public owner;

    // payout from rake
    // array of addresses
    RakePayout[] public rakes;

    // contract statebool
    bool public isContractRunning;

    event DepositEvent(
        address indexed _from,
        uint _value
    );

    event WithdrawEvent(
        address indexed _from,
        address indexed _to,
        uint _value
    );

    event InsertCreditsEvent(
        address indexed _from,
        uint _value
    );

    event RedistributeEvent(
        address indexed _winnerAddress,
        uint _winnerPayout,
        address indexed _runnerupAddress,
        uint _runnerupPayout,
        address indexed _thirdplaceAddress,
        uint _thirdplacePayout
    );

    //modifier set during contract deployment
    modifier onlyOwner () {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }

    modifier onlyRunning () {
        require(isContractRunning, "Contract is paused");
        _;
    }

    constructor(
        address teamaddress1,
        address teamaddress2,
        address teamaddress3,
        address teamaddress4,
        address teamaddress5,
        address teamaddress6) {
        owner = msg.sender;
        minDeposit = 100000;
        totalEscrow = 0;
        isContractRunning = true;
        rakes.push(RakePayout(teamaddress1, 20));
        rakes.push(RakePayout(teamaddress2, 20));
        rakes.push(RakePayout(teamaddress3, 20));
        rakes.push(RakePayout(teamaddress4, 17));
        rakes.push(RakePayout(teamaddress5, 10));
        rakes.push(RakePayout(teamaddress6, 3));
    }

    // function called during the start of the game
    // subtract wager from balance to prevent double spend attack
    // limit array size for gas cost
    // await for success/event before continuing initializing game
    function insertCredits(uint256 _wager, address _address)
    public
    onlyOwner
    onlyRunning
    returns(bool success) {
        require(_balances[_address] >= _wager, "Insufficient Balance");
        _balances[_address] = _balances[_address] - _wager;
        totalEscrow = totalEscrow + _wager;
        emit InsertCreditsEvent(_address, _wager);
        return true;
    }

    //refund players during dapp failure
    //subtract escrow balance to maintain house's value
    function refundCredits(uint256 _individualRefundAmount, address[] memory _addresses)
    public
    onlyOwner
    returns(bool success) {
        require(totalEscrow >= 0);
        require(_addresses.length <= 5, "Array cannot be larger than max total players");
        require(totalEscrow >= (_individualRefundAmount * _addresses.length), "Insufficient Balance");
        for (uint i = 0; i < _addresses.length; i++) {
            _balances[_addresses[i]] = _balances[_addresses[i]] + _individualRefundAmount;
            totalEscrow = totalEscrow - _individualRefundAmount;
        }
        return true;
    }

    // distribute winnings once game is complete
    // verify totalpayout is smaller than totalescrow to prevent overpayment
    // limit array size for gas cost
    // redistibute escrow balance to winner/runner up/third place
    function redistribute(
        address payable _winnerAddress,
        uint256 _winnerPayout,
        address payable _runnerupAddress,
        uint256 _runnerupPayout,
        address payable _thirdplaceAddress,
        uint256 _thirdplacePayout,
        uint256 _rakeAmount)
    public
    onlyOwner
    onlyRunning
    returns(bool success) {
        uint256 checkPayout = _winnerPayout + _runnerupPayout + _thirdplacePayout + _rakeAmount;
        require(totalEscrow >= checkPayout, "Not enough funds in escrow to payout");
        rakeCredits(_rakeAmount);
        _balances[_winnerAddress] = _balances[_winnerAddress] + _winnerPayout;
        _balances[_runnerupAddress] = _balances[_runnerupAddress] + _runnerupPayout;
        if (_thirdplacePayout > 0) {
            _balances[_thirdplaceAddress] = _balances[_thirdplaceAddress] + _thirdplacePayout;
        }
        totalEscrow = totalEscrow - checkPayout;
        emit RedistributeEvent(_winnerAddress, _winnerPayout, _runnerupAddress, _runnerupPayout, _thirdplaceAddress, _thirdplacePayout);
        return true;
    }

    // Deposit BNB to contract
    // revert incorrect amount/too small of a deposit
    // update mapping/balance
    function deposit(uint256 _amount)
    public
    payable
    onlyRunning {
        if (msg.sender == owner) {
            require(msg.value >= 0);
            totalEscrow = totalEscrow + msg.value;
        } else {
            require(msg.value >= minDeposit, "You must send more than the minimum deposit");
            require(msg.value == _amount, "You must send the same amount as you intended");
            _balances[msg.sender] += msg.value;
        }

        emit DepositEvent(msg.sender, msg.value);
    }

    //withdraw BNB from contract
    //revert overwithdraw
    //revert 0x0 address
    //revert negative withdraw amount
    //update mapping/balance
    //transfer amount to sender's address
    function withdraw(address payable _toAddress, uint256 _amount)
    public
    onlyRunning {
        require(_toAddress != 0x0000000000000000000000000000000000000000, "You cannot send to 0x0 address");
        require(_amount > 0, "withdraw amount must be greater than 0");
        require(_amount <= _balances[msg.sender], "Insufficient Balance");
        _balances[msg.sender] = _balances[msg.sender] - _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed.");

        emit WithdrawEvent(msg.sender, _toAddress, _amount);
    }

    //helper functions
    //balanceOf
    function balanceOf(address _address)
    public
    view returns (uint256) {
        return _balances[_address];
    }

    //update minDeposit
    function updateMinDeposit(uint256 _depositUpdate)
    public
    onlyOwner
    onlyRunning {
        require(_depositUpdate >= 0);
        minDeposit = _depositUpdate;
    }

    //contract state function
    function pause()
    public
    onlyOwner
    onlyRunning {
        isContractRunning = false;
    }

    function unpause()
    public
    onlyOwner {
        require(!isContractRunning, "Contract is already running");
        isContractRunning = true;
    }

    //distribute rake amount
    function rakeCredits(uint256 _amount) private {
        for (uint8 i = 0; i < rakes.length; i++) {
            uint256 _individualRakeAmount = (_amount * rakes[i].percentRake) / 100;
            _balances[rakes[i].addressOfTeamMember] = _balances[rakes[i].addressOfTeamMember] + _individualRakeAmount;
        }
    }
}