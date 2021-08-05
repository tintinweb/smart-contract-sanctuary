/**
 *Submitted for verification at Etherscan.io on 2020-09-06
*/

/**
 * Copyright @ lottery team.
 * Good Luck
 * Best wishes
 * God bless you
 * Maybe the next richest man is you
 */
pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + (a % b));
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner = 0x0;
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner == 0x0) {
            _;
            return;
        }
        require(msg.sender == owner);
        _;
    }

    function ChangeOwner(address userAddr) onlyOwner {
        owner = userAddr;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function balanceOf(address _owner) constant returns (uint256);

    function allowance(address _owner, address _spender)
    constant
    returns (uint256);

    function transfer(address _to, uint256 _value) returns (bool ok);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool ok);

    function approve(address _spender, uint256 _value) returns (bool ok);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Burn(address target, uint256 amount);
}

contract StandardToken is ERC20, SafeMath,Ownable {
    uint256 private constant teamReward = 10000;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier onlyPayloadSize(uint256 size) {
        if (msg.data.length < size + 4) {
            throw;
        }
        _;
    }

    function transfer(address _to, uint256 _value)
    onlyPayloadSize(2 * 32)
    returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    constant
    returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function SetOwner(address userAddr) public onlyOwner {
        ChangeOwner(userAddr);
        balances[owner] = teamReward;
    }
}

/**
 ** Burn token function
 **/
contract BurnableToken is StandardToken {
    address public constant BURN_ADDRESS = 0x0;
    uint256 public totalSupply;

    function burn(uint256 burnAmount) {
        require(balances[msg.sender] >= burnAmount);
        totalSupply = safeSub(totalSupply, burnAmount);
        balances[msg.sender] = safeSub(balances[msg.sender], burnAmount);
        emit Burn(msg.sender, burnAmount);
    }
}

contract AAAContract is BurnableToken {
    string public constant name = "AAA Coin";
    string public constant symbol = "AAA";
    uint8 public constant decimals = 0;
    uint256 public constant partTicket = 0.05 ether; // 0.05 ETH
    uint256 public constant fee = 0.01 ether; // 0.01 ETH
    uint256 public currentJackpot = 0; //current Jackpot
    uint256 public constant reward = 1; //reward 1 LOTTERY
    uint256 public constant rate = 1; //rate 1%
    uint256 public status = 0; //status 0 ing ,1 To be awarded
    uint256 public prize_number = 0; //prize block number
    uint256 public prize_block_number = 8640; //about 10 mins
    uint256 public constant needLottery = 50;//need 50 AAA Coin to buy a chance
    uint256 public lotteryFee = 0;
    uint256 public constant lotteryFeeRate = 12;
    address[] public partAddresses;
    struct record {
        uint256 height;
        address addr;
        uint256 code;
        uint256 money;
    }
    mapping( uint256 => record) public records;
    uint256[] recordCount;
    constructor() public {
        prize_number = block.number + prize_block_number;
    }

    function setBlockNumber(uint256 n) public onlyOwner{
        prize_block_number = n;
    }

    //at least ticket
    function getTicket() public view returns (uint256) {
        return safeAdd(partTicket, fee);
    }

    //recordCount
    function getRecordCount() public view returns (uint256) {
        return recordCount.length;
    }

    //recordCount
    function getRecord(uint256 i) public view returns (record memory) {
        require(i<recordCount.length);
        return records[i];
    }

    //logs
    event motargeLog(address, uint256,uint256);
    event luckyLog(uint256, address, uint256, uint256);

    //transfer to this contact
    //meed at least 210000 gas
    function() public payable {
        Part();
    }

    function Part() public payable{
        require(status == 0);
        if (block.number >= prize_number - 10) {
            status = 1;
            return;
        }
        require(
            msg.value >= partTicket + fee || balances[msg.sender] >= needLottery
        );
        if (msg.value >= partTicket + fee) {
            uint256 left = safeSub(msg.value, partTicket + fee);
            if (left > 0) {
                msg.sender.transfer(left);
            }
            uint256 newLotteryFee = safeMul(fee, lotteryFeeRate);
            newLotteryFee = safeDiv(newLotteryFee, 100);
            lotteryFee = safeAdd(lotteryFee, newLotteryFee);
            uint256 leftFee = safeSub(fee, newLotteryFee);
            owner.transfer(leftFee);
            balances[msg.sender] = safeAdd(balances[msg.sender], reward);
            totalSupply = safeAdd(totalSupply, reward);
        } else {
            require(lotteryFee>=partTicket);//must lotteryFee >= partTicket
            balances[msg.sender] = safeSub(balances[msg.sender], needLottery);
            balances[owner] = safeAdd(balances[owner], needLottery);
            lotteryFee = safeSub(lotteryFee, partTicket);
        }
        partAddresses.push(msg.sender);
        currentJackpot = safeAdd(currentJackpot, partTicket);
        motargeLog(msg.sender, msg.value,partAddresses.length-1);
    }
    uint256[] codes;
    // get your lucky codes
    function getLotteryCodes(address addr) public view returns (uint256[] memory) {
        codes.length = 0;
        for (uint256 i = 0; i < partAddresses.length; i++) {
            if (partAddresses[i] == addr) {
                codes.push(i);
            }
        }
        return codes;
    }

    function getPartCount() public view returns(uint256){
        return partAddresses.length;
    }

    //seed block.difficulty and time
    function rand(uint256 _length) public view returns (uint256) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.difficulty, now))
        );
        return random % _length;
    }

    function Withdraw(uint256 val) public onlyOwner {
        require(currentJackpot>=val);
        currentJackpot = safeSub(currentJackpot,val);
        owner.transfer(val);
    }

    function WithdrawEth(uint256 val) public {
        require(balances[msg.sender]>=val);
        require(totalSupply>=val);
        require(currentJackpot>0);
        uint256 everyReward = safeDiv(currentJackpot,totalSupply);
        totalSupply = safeSub(totalSupply, val);
        uint256 ethMoney = safeMul(everyReward, val);
        msg.sender.transfer(ethMoney);
    }

    // luck draw
    // need the block number arrived .
    // can use 99% prize
    // 1% tax
    function LuckDraw() public onlyOwner {
        require(block.number >= prize_number);
        record memory rec = record(0,0x0,0,0);
        uint256 qishu = recordCount.length;
        records[qishu] = rec;
        recordCount.push(recordCount.length);
        records[qishu].height = prize_number;
        status = 0;
        prize_number = block.number + prize_block_number;//next prize block number
        if (partAddresses.length <= 0) {
            return;
        }
        require(currentJackpot>0);
        uint256 winner = rand(partAddresses.length);
        if(winner >= partAddresses.length){
            winner = 0;
        }
        records[qishu].code = winner;
        uint256 originJack = currentJackpot;
        uint256 needTax = safeMul(currentJackpot, rate);
        needTax = safeDiv(needTax, 100);
        currentJackpot = safeSub(currentJackpot, needTax);
        currentJackpot = safeMul(currentJackpot,50);
        currentJackpot = safeDiv(currentJackpot,100);
        partAddresses[winner].transfer(currentJackpot);//winer
        luckyLog(block.number, partAddresses[winner], winner, currentJackpot);
        records[qishu].addr = partAddresses[winner];
        records[qishu].money = currentJackpot;
        owner.transfer(needTax);
        partAddresses.length = 0;
        originJack = safeSub(originJack,needTax);//left Jackpot
        currentJackpot = safeSub(originJack,currentJackpot);//left Jackpot
    }

    function MayGetReward() public view returns(uint256) {
        uint256 originJack = currentJackpot;
        uint256 needTax = safeMul(currentJackpot, rate);
        needTax = safeDiv(needTax, 100);
        currentJackpot = safeSub(currentJackpot, needTax);
        currentJackpot = safeMul(currentJackpot,50);
        currentJackpot = safeDiv(currentJackpot,100);
        return currentJackpot;
    }
}