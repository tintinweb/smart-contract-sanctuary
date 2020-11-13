// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address public owner;
    address public newowner;
    address public admin;
    address public dev;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNewOwner {
        require(msg.sender == newowner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newowner = _newOwner;
    }
    
    function takeOwnership() public onlyNewOwner {
        owner = newowner;
    }    
    
    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }
    
    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    modifier onlyDev {
        require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
        _;
    }    
}

abstract contract ContractConn{
    function transfer(address _to, uint _value) virtual public;
    function transferFrom(address _from, address _to, uint _value) virtual public;
    function balanceOf(address who) virtual public view returns (uint);
}


contract Deposit is Ownable{

    using SafeMath for uint256;
    
    struct DepositInfo {
        uint256 id;
        address depositor;
        string coinType;
        uint256 amount;
        uint256 depositTime;
        uint256 depositBlock;
        uint256 ExpireBlock;
    }
    
    ContractConn public usdt;
    ContractConn public zild;
    

    uint256 public depositBlock = 78000;
    uint256 public depositBlockChange;
    uint256 public changeDepositTime;
    bool    public needChangeTime = false;
    
    mapping(address => DepositInfo[]) public eth_deposit;
    mapping(address => DepositInfo[]) public usdt_deposit;
    mapping(address => DepositInfo[]) public zild_deposit;
    
    mapping(address => uint256) public user_ethdeposit_amount;
    mapping(address => uint256) public user_usdtdeposit_amount;
    mapping(address => uint256) public user_zilddeposit_amount;

    uint256 public ethTotalDeposit;
    uint256 public usdtTotalDeposit;
    uint256 public zildTotalDeposit;

    event SetDepositBlock(uint256 dblock,address indexed who,uint256 time);
    event EffectDepositBlock(uint256 dblock,address indexed who,uint256 time);
    event DepositETH(address indexed from,uint256 depid,uint256 damount,uint256 bblock,uint256 eblock,uint256 time);
    event DepositUSDT(address indexed from,uint256 depid,uint256 damount,uint256 bblock,uint256 eblock,uint256 time);
    event DepositZILD(address indexed from,uint256 depid,uint256 damount,uint256 bblock,uint256 eblock,uint256 time);
    event WithdrawETH(address indexed to,uint256 damount,uint256 time);
    event WithdrawUSDT(address indexed to,uint256 damount,uint256 time);
    event WithdrawZILD(address indexed to,uint256 damount,uint256 time);
    
    constructor(address _usdt,address _zild) public {
        usdt = ContractConn(_usdt);
        zild = ContractConn(_zild);
    }
    
    function setdepositblock(uint256 _block) public onlyAdmin {
        require(_block > 0,"Desposit: New deposit time must be greater than 0");
        depositBlockChange = _block;
        changeDepositTime = block.number;
        needChangeTime = true;
        emit SetDepositBlock(_block,msg.sender,now);
    }
    
    function effectblockchange() public onlyAdmin {
        require(needChangeTime,"Deposit: No new deposit time are set");
        uint256 currentTime = block.number;
        uint256 effectTime = changeDepositTime.add(depositBlock);
        if (currentTime < effectTime) return;
        depositBlock = depositBlockChange;
        needChangeTime = false;
        emit SetDepositBlock(depositBlockChange,msg.sender,now);
    }    

    function DepositETHCount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Deposit: Only check your own deposit records");
        return eth_deposit[_user].length;
    }
    
    function DepositUSDTCount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Deposit: Only check your own deposit records");
        return usdt_deposit[_user].length;
    }
    
    function DepositZILDCount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Deposit: Only check your own deposit records");
        return zild_deposit[_user].length;
    }   

    function DepositETHAmount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Deposit: Only check your own deposit records");
        return user_ethdeposit_amount[_user];
    }
    
    function DepositUSDTAmount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Deposit: Only check your own deposit records");
        return user_usdtdeposit_amount[_user];
    }
    
    function DepositZILDAmount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Deposit: Only check your own deposit records");
        return user_zilddeposit_amount[_user];
    } 

    function depositETH() public payable returns(uint256){
        uint256 length = eth_deposit[msg.sender].length;
        uint256 deposit_id;
        eth_deposit[msg.sender].push(
            DepositInfo({
                id: length,
                depositor: msg.sender,
                coinType: "eth",
                amount: msg.value,
                depositTime: now,
                depositBlock: block.number,
                ExpireBlock: block.number.add(depositBlock)
            })
        );
        deposit_id = eth_deposit[msg.sender].length;
        user_ethdeposit_amount[msg.sender] = user_ethdeposit_amount[msg.sender].add(msg.value);
        ethTotalDeposit = ethTotalDeposit.add(msg.value);
        emit DepositETH(msg.sender,length,msg.value,block.number,block.number.add(depositBlock),now);
        return length;
    }
    
    function depositUSDT(uint256 _amount) public returns(uint256){
        usdt.transferFrom(address(msg.sender), address(this), _amount);
        uint256 length = usdt_deposit[msg.sender].length;
        usdt_deposit[msg.sender].push(
            DepositInfo({
                id: length,
                depositor: msg.sender,
                coinType: "usdt",
                amount: _amount,
                depositTime: now,
                depositBlock: block.number,
                ExpireBlock: block.number.add(depositBlock)
            })
        );
        user_usdtdeposit_amount[msg.sender] = user_usdtdeposit_amount[msg.sender].add(_amount);
        usdtTotalDeposit = usdtTotalDeposit.add(_amount);
        emit DepositUSDT(msg.sender,length,_amount,block.number,block.number.add(depositBlock),now);
        return length;
    }

    function depositZILD(uint256 _amount) public returns(uint256){
        zild.transferFrom(address(msg.sender), address(this), _amount);
        uint256 length = zild_deposit[msg.sender].length;
        zild_deposit[msg.sender].push(
            DepositInfo({
                id: length,
                depositor: msg.sender,
                coinType: "zild",
                amount: _amount,
                depositTime: now,
                depositBlock: block.number,
                ExpireBlock: block.number.add(depositBlock)
            })
        );
        user_zilddeposit_amount[msg.sender] = user_zilddeposit_amount[msg.sender].add(_amount);
        zildTotalDeposit = zildTotalDeposit.add(_amount);
        emit DepositZILD(msg.sender,length,_amount,block.number,block.number.add(depositBlock),now);
        return length;
    }

    function withdrawEth(uint256 _deposit_id) public returns(bool){
        require(block.number > eth_deposit[msg.sender][_deposit_id].ExpireBlock, "The withdrawal block has not arrived!");
        require(eth_deposit[msg.sender][_deposit_id].amount > 0, "There is no deposit available!");
        msg.sender.transfer(eth_deposit[msg.sender][_deposit_id].amount);
        user_ethdeposit_amount[msg.sender] = user_ethdeposit_amount[msg.sender].sub(eth_deposit[msg.sender][_deposit_id].amount);
        ethTotalDeposit = ethTotalDeposit.sub(eth_deposit[msg.sender][_deposit_id].amount);
        eth_deposit[msg.sender][_deposit_id].amount =  0;
        emit WithdrawETH(msg.sender,eth_deposit[msg.sender][_deposit_id].amount,now);
        return true;
    }
    
    function withdrawUSDT(uint256 _deposit_id) public returns(bool){
        require(block.number > usdt_deposit[msg.sender][_deposit_id].ExpireBlock, "The withdrawal block has not arrived!");
        require(usdt_deposit[msg.sender][_deposit_id].amount > 0, "There is no deposit available!");
        usdt.transfer(msg.sender, usdt_deposit[msg.sender][_deposit_id].amount);
        user_usdtdeposit_amount[msg.sender] = user_usdtdeposit_amount[msg.sender].sub(usdt_deposit[msg.sender][_deposit_id].amount);
        usdtTotalDeposit = usdtTotalDeposit.sub(usdt_deposit[msg.sender][_deposit_id].amount);
        usdt_deposit[msg.sender][_deposit_id].amount =  0;
        emit WithdrawUSDT(msg.sender,usdt_deposit[msg.sender][_deposit_id].amount,now);
        return true;
    }

    function withdrawZILD(uint256 _deposit_id) public returns(bool){
        require(block.number > zild_deposit[msg.sender][_deposit_id].ExpireBlock, "The withdrawal block has not arrived!");
        require(zild_deposit[msg.sender][_deposit_id].amount > 0, "There is no deposit available!");
        zild.transfer(msg.sender,zild_deposit[msg.sender][_deposit_id].amount);
        user_zilddeposit_amount[msg.sender] = user_zilddeposit_amount[msg.sender].sub(zild_deposit[msg.sender][_deposit_id].amount);
        zildTotalDeposit = zildTotalDeposit.sub(zild_deposit[msg.sender][_deposit_id].amount);
        zild_deposit[msg.sender][_deposit_id].amount =  0;
        emit WithdrawZILD(msg.sender,zild_deposit[msg.sender][_deposit_id].amount,now);
        return true;
    }
}