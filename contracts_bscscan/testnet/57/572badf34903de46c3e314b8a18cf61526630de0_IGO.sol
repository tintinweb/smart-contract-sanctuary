/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

pragma solidity =0.6.0;
pragma experimental ABIEncoderV2;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract IGO {
    struct Period {
        uint startTime;
        uint endTime;
        uint price;
        uint total;
        uint hold;
        uint min;
        uint max;
    }

    mapping(uint => Period) public periodMap;
    mapping(address => mapping(uint => uint)) public subscribePeriodMap;

    // address public USDTToken = 0x55d398326f99059fF775485246999027B3197955; //USDT
    address public USDTToken = 0xD2C6e5d5174BeF50017FB216DC66769baC34a12d; //Test
    address payable public  owner;
    address payable public  administrator;

    event Withdraw(address token, address user, uint amount, address to);


    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == administrator, "Permission denied");
        _;
    }
    constructor() public {
        owner = msg.sender;
        administrator = msg.sender;
    }

    function changeOwner(address payable _add) external onlyOwner {
        require(_add != address(0));
        owner = _add;
    }

    function changeAdministrator(address payable _add) external onlyOwner {
        require(_add != address(0));
        administrator = _add;
    }

    // [1640588954,1643267354,250000,100,0,1,10]
    function setPeriod(uint _id, Period memory _period) public onlyOwner {
        _period.min *= 10 ** 18;
        _period.max *= 10 ** 18;
        _period.total *= 10 ** 18;
        _period.hold *= 10 ** 18;
        periodMap[_id] = _period;
    }

    function subscribe(uint _qua, uint _period, address _inviter) external {
        require(_qua >= periodMap[_period].min && _qua <= periodMap[_period].max, "Wrong subscription quantity range.");
        require(msg.sender != _inviter, "Can't invite myself");
        require(subscribePeriodMap[msg.sender][_period] <= 0, "The address can only be subscribed once");
        require(periodMap[_period].total > periodMap[_period].hold, "Subscription completed");
        require(periodMap[_period].startTime < block.timestamp && block.timestamp < periodMap[_period].endTime, "Period range wrong");
        uint receive_num = _qua * 10 ** 6 / periodMap[_period].price;
        uint freed_num = 0;
        if (subscribePeriodMap[_inviter][_period] > 0) {
            freed_num = receive_num + (receive_num * 4 / 100);
            if ((periodMap[_period].total - periodMap[_period].hold) < freed_num) {
                freed_num = periodMap[_period].total - periodMap[_period].hold;
                receive_num = freed_num * 100 / 104;
                _qua = receive_num * periodMap[_period].price;
            }
            subscribePeriodMap[_inviter][_period] += (freed_num - receive_num);
        } else {
            if ((periodMap[_period].total - periodMap[_period].hold) < receive_num) {
                receive_num = periodMap[_period].total - periodMap[_period].hold;
                _qua = receive_num * periodMap[_period].price;
            }
            freed_num = receive_num;
        }
        periodMap[_period].hold += freed_num;
        subscribePeriodMap[msg.sender][_period] += receive_num;
        Token(USDTToken).transferFrom(msg.sender, address(this), _qua);
    }

    function withdrawToken(address _token, address _add, uint _amount) public onlyOwner {
        Token(_token).transfer(_add, _amount);
        emit Withdraw(_token, msg.sender, _amount, _add);
    }
   
}