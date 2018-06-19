pragma solidity 0.4.19;


contract InterfaceDeusETH {
    bool public gameOver;
    bool public gameOverByUser;
    function totalSupply() public view returns (uint256);
    function livingSupply() public view returns (uint256);
    function getState(uint256 _id) public returns (uint256);
    function getHolder(uint256 _id) public returns (address);
}


contract FundsKeeper {
    using SafeMath for uint256;
    InterfaceDeusETH public deusETH = InterfaceDeusETH(0x0);
    bool public started = false;

    uint256 public weiReceived;

    // address of team
    address public owner;
    bool public salarySent = false;

    uint256 public totalPayments = 0;

    mapping(uint256 => bool) public payments;

    event Bank(uint256 indexed _sum, uint256 indexed _add);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function FundsKeeper(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
    }

    function () external payable {
        weiReceive();
    }

    function getGain(uint256 _id) public {
        require((deusETH.gameOver() && salarySent) || deusETH.gameOverByUser());
        require(deusETH.getHolder(_id) == msg.sender);
        require(deusETH.getState(_id) == 1); //living token only
        require(payments[_id] == false);

        address winner = msg.sender;

        uint256 gain = calcGain();

        require(gain != 0);
        require(this.balance >= gain);

        totalPayments = totalPayments.add(gain);
        payments[_id] = true;

        winner.transfer(gain);
    }

    function setLottery(address _deusETH) public onlyOwner {
        require(!started);
        deusETH = InterfaceDeusETH(_deusETH);
        started = true;
    }

    function getTeamSalary() public onlyOwner returns (bool) {
        require(!salarySent);
        require(deusETH.gameOver());
        require(!deusETH.gameOverByUser());
        salarySent = true;
        weiReceived = this.balance;
        uint256 salary = weiReceived/10;
        weiReceived = weiReceived.sub(salary);
        owner.transfer(salary);
        return true;
    }

    function changeLottery(address _deusETH) onlyOwner public {
        deusETH = InterfaceDeusETH(_deusETH);
    }

    function checkPayments(uint _id) public view returns (bool) {
        return payments[_id];
    }

    function changeOwner(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != address(0));
        owner = _newOwner;
        return true;
    }

    function weiReceive() internal {
        Bank(this.balance, msg.value);
    }

    function calcGain() internal returns (uint256) {
        if (deusETH.gameOverByUser() && (weiReceived == 0)) {
            weiReceived = this.balance;
        }
        return weiReceived/deusETH.livingSupply();
    }
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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