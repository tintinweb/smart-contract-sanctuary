/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}
contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
    }
}
interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    // function mint(address owner, uint value) external returns(bool);
    // function burn(uint value) external returns(bool);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint amount, address token, bytes calldata extraData) external;
}

contract TRC20 is ITRC20, Ownable {
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "insufficient allowance!");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function burn(uint amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    // approveAndCall
    function approveAndCall(address spender, uint amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        require(_balances[sender] >= amount, "insufficient balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0));
        require(_balances[account] >= amount, "insufficient balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TRC20Detailed is ITRC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
contract Dao is TRC20Detailed, TRC20 {
    using Address for address;
    using SafeMath for uint;
    using Address for address;
    uint public BURN_PERCENT = 30;//���ٱ���
    uint256 public ecology = 10;//��̬
    uint256 public fund = 10;//����
    uint256 public node = 50;//�ڵ�
    uint public decimalVal = 1e18;
   
    uint public FOMO_MAX_LIMIT = 210000 * decimalVal;//ֹͣͨ��
    uint public FomoRewardPool;
     
    address public ecologyAddr;//DAO��̬��ַ
    address public fundAddr;//DAO�����ַ
    address public nodeAddr;//DAO��֯��ַ
    mapping (address => bool) public specialAddress;
    mapping (address => bool) public receiveAddress;
    uint public transferNum = 100 * decimalVal;//ת�˵ø���
    mapping (address => uint) public transferTime;//ת��ʱ��
    mapping (address => uint) public transferNumber;//24ת������
    uint public dayTarnsferTime = 86400;
    uint public dayNumber = 500* decimalVal;//һ���������
    function setMaxLimit(uint val) public onlyOwner {
        FOMO_MAX_LIMIT = val;
    }
    function setTransferNum(uint val) public onlyOwner {
        transferNum = val;
    }
    function setDayTarnsferTime(uint val) public onlyOwner {
        dayTarnsferTime = val;
    }
    function setDayNumber(uint val) public onlyOwner {
        dayNumber = val;
    }
    constructor (address addr_,address ecologyAddr_,address fundAddr_,address nodeAddr_, address storageAddress1, address storageAddress2, address storageAddress3) public TRC20Detailed("DarkHorse DAO", "DH", 18) {
        _mint(addr_, 4151314 * decimalVal); 
        _mint(storageAddress1, 350000 * decimalVal); 
        _mint(storageAddress2, 350000 * decimalVal); 
        _mint(storageAddress3, 350000 * decimalVal); 
        specialAddress[storageAddress1] = true;
        specialAddress[storageAddress2] = true;
        specialAddress[storageAddress3] = true;
        ecologyAddr = ecologyAddr_;
        fundAddr = fundAddr_;
        nodeAddr = nodeAddr_;
    }
    
    function setSpecialAddress(address addr) public onlyOwner{
        require(address(0) != addr);
        specialAddress[addr] = true;
    }

    function delSpecialAddress(address addr) public onlyOwner{
        require(address(0) != addr);
        specialAddress[addr] = false;
    }
    //���͵�ַ������
    function getSpecialAddress(address addr) public view returns(bool) {
        require(address(0) != addr);
        return specialAddress[addr];
    }
    function setReceiveAddress(address addr) public onlyOwner{
        require(address(0) != addr);
        receiveAddress[addr] = true;
    }

    function delReceiveAddress(address addr) public onlyOwner{
        require(address(0) != addr);
        receiveAddress[addr] = false;
    }

    //���յ�ַ������
    function getReceiveAddress(address addr) public view returns(bool) {
        require(address(0) != addr);
        return receiveAddress[addr];
    }
    
    function _transferBurn(address from, uint amount) internal {
        require(from != address(0));
        // burn
        _burn(from, amount);
        // fomo reward pool
        FomoRewardPool = FomoRewardPool.add(amount);
    }
    function burn(uint amount) public returns (bool)  {
        super._burn(msg.sender, amount);
    }
    function _transferFrom(address from, address to, uint value) internal returns (bool) {
        if (getSpecialAddress(from) || getReceiveAddress(to)) {
            super.transfer(to, value);
            return true;
        }
        require(value<=transferNum,'Exceeding the maximum quantity of a single transaction');
        if(!address(from).isContract()){//�ж��Ƿ��Ǻ�Լ��ַ
            if(transferTime[from]== 0 || (transferTime[from]>0 && block.timestamp.sub(transferTime[from]) > dayTarnsferTime)){
                transferNumber[from] = value;
                transferTime[from] = block.timestamp;
            }else{
                require((block.timestamp.sub(transferTime[from])<dayTarnsferTime && transferNumber[from].add(value)<=dayNumber),'day over transfer number');
                transferNumber[from] = transferNumber[from].add(value);
            }
        }
        uint transferAmount = value;
        uint proportion = transferFee(balanceOf(from));//�����ѱ���
        uint feeAmount = value.mul(proportion).div(100);
        transferAmount = transferAmount.sub(feeAmount);
        uint BURN_PERCENTAmount = feeAmount.mul(BURN_PERCENT).div(100);//���������ѱ���30 
        uint ecologyAmount = feeAmount.mul(ecology).div(100);//�����ѱ���10 
        uint fundAmount = feeAmount.mul(fund).div(100);//�����ѱ���10 
        uint nodeAmount = feeAmount.mul(node).div(100);//�����ѱ���50
            uint totalSupply = totalSupply();
        if (totalSupply>FOMO_MAX_LIMIT) {
            _transferBurn(from, BURN_PERCENTAmount);
        }else{
            ecologyAmount = ecologyAmount.add(BURN_PERCENTAmount);
        }
        super.transfer(ecologyAddr, ecologyAmount);
        super.transfer(fundAddr, fundAmount);
        super.transfer(nodeAddr, nodeAmount);
        return true;
    }

    function transfer(address to, uint value) public returns (bool) {
        return _transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        super._approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        return _transferFrom(from, to, value);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(address(this).balance >= amount, "insufficient balance");

        to.transfer(amount);
    }

    function rescue(address to, ITRC20 token, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(token.balanceOf(address(this)) >= amount, "insufficent token balance");

        token.transfer(to, amount);
    }

    struct Fee{
        uint8 proportion;
        uint256 start_num;
        uint256 end_num;
    }
    Fee[] private fees;
    mapping (uint8=>bool) private isFee;
    function editFee(uint8 proportion_, uint256 start_num_ , uint256 end_num_ ) public onlyOwner{
        if (!isFee[proportion_]) {
            fees.push(Fee({proportion:proportion_,start_num:start_num_,end_num:end_num_}));
            isFee[proportion_] = true;
            return;
        }
        for(uint256 i=0;i<fees.length;i++){
            if (fees[i].proportion == proportion_) {
                fees[i] = Fee({proportion:proportion_,start_num:start_num_,end_num:end_num_});
            }
        }
    }
    //�鿴������
    function transferFee(uint256 num)public view returns(uint256){
         uint fee = 0;
         for(uint256 i=0;i<fees.length;i++){
             if(num>= fees[i].start_num){
                  fee = fees[i].proportion;
             }else if(num>= fees[i].start_num && fees[i].end_num == 0){
                  fee = fees[i].proportion;
             }
        }
         return fee;
    }
}