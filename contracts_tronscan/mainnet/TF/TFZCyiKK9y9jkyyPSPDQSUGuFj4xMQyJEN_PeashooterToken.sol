//SourceUnit: pea_token.sol

pragma solidity ^0.5.9;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract TRC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TRC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Authority is Ownable {
    // 出账白名单
    mapping(address => bool) public whiteFromList;
    // 到账白名单
    mapping(address => bool) public whiteToList;
    // 黑名单
    mapping(address => bool) public blackList;

    function addBlackList(address _add) public onlyOwner {
        blackList[_add] = true;
    }

    function removeBlackList(address _add) public onlyOwner {
        blackList[_add] = false;
    }

    function addWhiteFromList(address _add) public onlyOwner {
        whiteFromList[_add] = true;
    }

    function removeWhiteFromList(address _add) public onlyOwner {
        whiteFromList[_add] = false;
    }

    function addWhiteToList(address _add) public onlyOwner {
        whiteToList[_add] = true;
    }

    function removeWhiteToList(address _add) public onlyOwner {
        whiteToList[_add] = false;
    }
}

contract PeashooterToken is TRC20, Authority {

    struct Prize {
        uint256 transferTime;
        address receiver;
    }

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    string public name;
    string public symbol;

    // 合约精度
    uint8 public decimals = 6;

    //分红池
    uint256 public divPool;
    //奖池
    uint256 public ewardPool;
    //开发者地址
    address public dev;

    //中奖者名单
    Prize[] public prizeList;

    //最后数据刷新时间
    uint256 public lastRefreshTime;

    //最早的尾盘地址下表
    uint256 public earlyIndex = 9;

    //开奖间隔
    uint256 public drawInterval;

    //当前参与尾盘博弈限额
    uint256 public campaignCurrent = uint256(100).mul(10 ** uint256(decimals));
    //尾盘博弈初始限额
    uint256 public campaignLimit = uint256(20000).mul(10 ** uint256(decimals));
    // 限额增长步长
    uint256 public campaignStep = uint256(100).mul(10 ** uint256(decimals));

    function setDrawInterval(uint256 _drawInterval) public onlyOwner {
        drawInterval = _drawInterval;
    }

    function setCampaignLimit(uint256 _campaignLimit) public onlyOwner {
        campaignLimit = _campaignLimit;
    }

    function _div(address _to, uint256 _value) public {
        require(!blackList[_to], "black address don't been allowed");
        require(msg.sender == dev, "!dev address");
        if (divPool >= _value) {
            balances[_to] = balances[_to].add(_value);
            divPool = divPool.sub(_value);
            emit Transfer(address(this), _to, _value);
        }
    }

    function mint(address _to, uint256 _value) public {
        require(msg.sender == dev, "!dev address");
        if (balances[address(this)] < _value) {
            _value = balances[address(this)];
        }
        balances[address(this)] = balances[address(this)].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(address(this), _to, _value);
    }

    //销毁并转账
    function _burnTransfer(address _from, address _to, uint256 _value) internal returns (uint256){
        balances[_from] = balances[_from].sub(_value);
        //检查尾盘博弈名单
        checkPrize(_from, _to, _value);
        uint256 burnAmount = 0;
        uint256 ewardAmount = 0;
        if (!whiteFromList[_from] && !whiteToList[_to]) {
            burnAmount = burnProp().mul(_value).div(100);
            totalSupply = totalSupply.sub(burnAmount);
            ewardAmount = ewardProp().mul(_value).div(100);
            ewardPool = ewardPool.add(ewardAmount);
        }
        //销毁burnAmount数量并进入分红池burnAmount数量
        uint256 realValue = _value.sub(ewardAmount).sub(burnAmount);
        balances[_to] = balances[_to].add(realValue);
        //lastRefreshTime
        lastRefreshTime = getNow();
        return _value;
    }


    function getNow() public view returns (uint256){
        return now;
    }

    //计算燃烧比例
    uint256 percentT1 = uint256(100000000).mul(10 ** uint256(decimals));
    uint256 percentT2 = uint256(50000000).mul(10 ** uint256(decimals));
    uint256 percentT3 = uint256(30000000).mul(10 ** uint256(decimals));
    uint256 percentT4 = uint256(10000000).mul(10 ** uint256(decimals));

    function burnProp() public view returns (uint256){
        uint256 prop = 1;
        if (totalSupply >= percentT1) {
            prop = 5;
        } else if (totalSupply >= percentT2) {
            prop = 4;
        } else if (totalSupply >= percentT3) {
            prop = 3;
        } else if (totalSupply >= percentT4) {
            prop = 2;
        }
        return prop;
    }

    // 入奖金池比例
    function ewardProp() public pure returns (uint256) {
        return uint256(5);
    }

    //检查尾盘博弈
    function checkPrize(address _sender, address _receiver, uint256 _value) internal {

        uint256 length = prizeList.length;
        address bounds = address(0);

        //查询有没有超过drawInterval 的人中奖
        uint256 _index = earlyIndex;

        Prize storage prize = prizeList[_index];
        if (prize.receiver != address(0)) {
            if (getNow() - prize.transferTime > drawInterval) {
                bounds = prize.receiver;
            }
        }

        //有人中奖
        if (bounds != address(0)) {
            //给头奖用户先发奖20%
            uint256 total = ewardPool.mul(20).div(100);
            balances[bounds] = balances[bounds].add(total);

            emit Transfer(address(this), bounds, total);

            //给所有人发奖3%不包括头奖用户
            for (uint256 i = 0; i < length; ++i) {
                if (i != _index && prizeList[i].receiver != address(0)) {
                    uint256 _amount = ewardPool.mul(3).div(100);
                    balances[prizeList[i].receiver] = balances[prizeList[i].receiver].add(_amount);
                    total = total.add(_amount);

                    emit Transfer(address(this), prizeList[i].receiver, _amount);
                }
                prizeList[i].receiver = address(0);
                prizeList[i].transferTime = 0;
            }
            //给分红池53%的令牌
            uint256 _divAmount = ewardPool.mul(53).div(100);
            divPool = divPool.add(_divAmount);
            total = total.add(_divAmount);

            ewardPool = ewardPool.sub(total);

            campaignCurrent = uint256(100).mul(10 ** uint256(decimals));
            earlyIndex = 9;
        }

        if (!blackList[_receiver] && !whiteFromList[_receiver] && !whiteToList[_sender] && _value >= campaignCurrent) {
            earlyIndex = (earlyIndex + 1) % 10;
            //替换入场最晚的人
            prizeList[earlyIndex].transferTime = getNow();
            prizeList[earlyIndex].receiver = _receiver;

            if (campaignCurrent < campaignLimit) {
                campaignCurrent = campaignCurrent.add(campaignStep);
            }
        }
    }

    function transferDev(address _dev) public {
        require(dev == msg.sender);
        require(_dev != address(0));
        dev = _dev;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!blackList[msg.sender] && !blackList[_to], "black address don't been allowed");
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        _burnTransfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyDev returns (bool) {
        require(_to != address(0), "address is null");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowed.");

        _burnTransfer(_from, _to, _value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public onlyDev returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public onlyDev returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public onlyDev returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    modifier onlyDev() {
        require(msg.sender == dev);
        _;
    }

    constructor(address _dev) public {
        name = "PeashooterToken";
        symbol = "PEA";
        dev = _dev;
        drawInterval = 3600;
        totalSupply = uint256(200000000).mul(10 ** uint256(decimals));
        for (uint256 i = 0; i < 10; ++i) {
            prizeList.push(Prize({
            transferTime : 0,
            receiver : address(0)
            }));
        }
        balances[dev] = totalSupply;
        emit Transfer(address(0), dev, totalSupply);
    }

}