pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Statable {
    uint8 public state; // { 0 = pre event , 1 = during event, 2 = post event, 3 = refunding
    modifier requireState(uint8 _state) {
        require(state == _state);
        _;
    }
}

contract Fighter is Ownable, Statable {
    using SafeMath for uint256;
    uint256 public minBetAmount = 0;

    string name;

    constructor(string contractName, uint256 _minBetAmount) public {
        name = contractName;
        minBetAmount = _minBetAmount;
        state = 0;
    }

    function changeState(uint8 _state) public onlyOwner {
        state = _state;
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function() public payable requireState(0) {
        require(msg.value >= minBetAmount);
        MasterFighter(address(owner)).addBet(msg.value, msg.sender);
    }

    function transferMoneyToOwner() public onlyOwner requireState(1) {
        if (address(this).balance > 0) {
            MasterFighter(address(owner)).deposit.value(address(this).balance)();
        }
    }

}

contract MasterFighter is Ownable, Statable {
    using SafeMath for uint256;

    uint256 public percentRake = 5;
    uint256 public constant minBetAmount = 0.01 ether;

    bool public hasWithdrawnRake = false;

    address winningFighter;

    address[] public fighterAddressess;

    struct Bet {
        uint256 stake;
        bool withdrawn;
    }

    mapping(address => mapping(address => Bet)) public bets;
    mapping(address => address[]) public bettersForFighter;
    mapping(address => uint256) public totalForFighter;

    uint256 public amount;

    event StateChanged(uint8 _state);
    event ReceivedMoney(address _betterAddress, address _fighterAddress, uint256 _stake);

    function deposit() public payable requireState(1) {
    }

    constructor() public {
        state = 0;
        addFighter(new Fighter("Khabib", minBetAmount));
        addFighter(new Fighter("McGregor", minBetAmount));
    }

    function getTotalBettersForFighter(address _address) external view returns (uint256) {
        return bettersForFighter[_address].length;
    }

    function startEvent() external onlyOwner requireState(0) {
        state = 1;
        for (uint8 i = 0; i < fighterAddressess.length; i++) {
            Fighter(fighterAddressess[i]).changeState(state);
            Fighter(fighterAddressess[i]).transferMoneyToOwner();
        }
        emit StateChanged(state);
    }

    function refundEverybody() external onlyOwner requireState(1) {
        state = 3;
        emit StateChanged(state);
    }

    function addFighter(address _address) private requireState(0) {
        fighterAddressess.push(Fighter(_address));
    }

    function checkValidFighter(address _address) private view returns (bool) {
        for (uint8 i = 0; i < fighterAddressess.length; i++) {
            if (_address == fighterAddressess[i]) {
                return true;
            }
        }
        return false;
    }

    function addBet(uint256 _stake, address _betterAddress) external {
        require(checkValidFighter(msg.sender));
        if (bets[msg.sender][_betterAddress].stake > 0) {
            bets[msg.sender][_betterAddress].stake = bets[msg.sender][_betterAddress].stake.add(_stake);
        } else {
            bettersForFighter[msg.sender].push(_betterAddress);
            bets[msg.sender][_betterAddress] = Bet(_stake, false);
        }
        amount = amount.add(_stake);
        totalForFighter[msg.sender] = totalForFighter[msg.sender].add(_stake);
        emit ReceivedMoney(_betterAddress, msg.sender, _stake);
    }

    function totalWagered() public constant returns (uint256) {
        return amount;
    }

    function totalRake() public constant returns (uint256) {
        return totalWagered().mul(percentRake).div(100);
    }

    function totalPrizePool() public constant returns (uint256) {
        return totalWagered().sub(totalRake());
    }

    function declareWininingFighter(address _fighterAddress) external onlyOwner requireState(1) {
        require(checkValidFighter(_fighterAddress));
        state = 2;
        winningFighter = _fighterAddress;
        emit StateChanged(state);
    }

    function withdrawRake() external onlyOwner requireState(2) {
        require(!hasWithdrawnRake);
        hasWithdrawnRake = true;
        owner.transfer(totalRake());
    }

    function withdraw(address _betterAddress) public requireState(2) {
        require(bets[winningFighter][_betterAddress].stake > 0);
        require(!bets[winningFighter][_betterAddress].withdrawn);
        address(_betterAddress).transfer(totalPrizePool().mul(bets[winningFighter][_betterAddress].stake).div(totalForFighter[winningFighter]));
        bets[winningFighter][_betterAddress].withdrawn = true;
    }

    function refund(address _betterAddress) external requireState(3) {
        uint256 stake = 0;
        for (uint8 i = 0; i < fighterAddressess.length; i++) {
            if (bets[fighterAddressess[i]][_betterAddress].stake > 0 && !bets[fighterAddressess[i]][_betterAddress].withdrawn) {
                bets[fighterAddressess[i]][_betterAddress].withdrawn = true;
                stake = stake.add(bets[fighterAddressess[i]][_betterAddress].stake);
            }
        }
        if (stake > 0) {
            address(_betterAddress).transfer(stake);
        }
    }

}