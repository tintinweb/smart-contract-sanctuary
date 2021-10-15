//SourceUnit: HOOH.sol

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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


contract NaToken is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    //基金会 TKsGcubwTHMRSnAMkNUpfovKibWRCPTVgp
    address public fundAddress = address(0x006c91c84424acf55c6542c7adcdbf49bacdbe05c3);
    //资金池的地址 DApp的地址 发币后修改
    address public poolAddress = address(0x00646882b1ff7a0fca1d249e93fc3599541ab4fae5);
    //黑洞
    address public blackHole = address(0x0);
    //真实拥有
    mapping(address => bool) public tAddress;
    //份额
    mapping(address => uint256) public sOwned;
    //真实拥有
    mapping(address => uint256) public tOwned;
    //总份额
    uint256 public sTotal;
    //总真实
    uint256 public tTotal;
    //空投地址
    address public airDropAddress;

    mapping(uint256 => uint256) public dailyAmount;

    mapping(address => address) public inviterAddressMap;

    mapping(address => uint256) public memberAmountMap;

    mapping(address => bool) public executorAddress;

    constructor (address _fundAddress, string memory __name, string memory __symbol, uint8 __decimals, uint256 __supply) public {
        fundAddress = _fundAddress;
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _totalSupply = __supply.mul(10 ** uint256(__decimals));
        address s = address(msg.sender);
        tAddress[s] = true;
        tAddress[blackHole] = true;
        tAddress[fundAddress] = true;
        tAddress[poolAddress] = true;
        airDropAddress = s;
        tTotal = _totalSupply;
        tOwned[s] = tTotal;

        //        _transfer(s, address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), 1000000000);
        //        _transfer(address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), address(0x004cb2bac50bcc37d67fc837f586a62b1ba631157e), 100000000);
        //        _transfer(address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), address(0x004cb2bac50bcc37d67fc837f586a62b1ba631157e), 100000000);
    }

    function updateInviter(address addr, address inviter) public returns (bool){
        require(addr != inviter, "cannot inviter your self");
        require(executorAddress[address(msg.sender)], "not executor");
        require(inviterAddressMap[addr] == address(0x0), "has inviter");
        inviterAddressMap[addr] = inviter;
        memberAmountMap[inviter] = memberAmountMap[inviter].add(1);
        return true;
    }

    function updateExecutor(address _executor, bool exec) public onlyOwner returns (bool){
        executorAddress[_executor] = exec;
        return true;
    }

    function setAirDropAddress(address _address) public onlyOwner returns (bool){
        require(tAddress[_address], "not t-adress");
        airDropAddress = _address;
        return true;
    }

    function doAirDrop(address account, uint256 amount) public returns (bool){
        address sender = address(msg.sender);
        require(sender == airDropAddress, "not air drop address");
        tOwned[sender] = tOwned[sender].sub(amount);
        if (isContract(account) || tAddress[account]) {
            tOwned[account] = tOwned[account].add(amount);
        } else {
            if (sTotal == 0) {
                sTotal = amount.div(100);
                sOwned[account] = sTotal;
            }else{
                uint256 sAmount = _totalSupply.sub(tTotal);
                uint256 add = amount.mul(sTotal).div(sAmount);
                sOwned[account] = sOwned[account].add(add);
                sTotal = sTotal.add(add);
            }
            tTotal = tTotal.sub(amount);
        }
        return true;
    }


    function getMemberInviter(address account) public view returns (address){
        return inviterAddressMap[account];
    }

    function getMemberAmount(address account) public view returns (uint256){
        return memberAmountMap[account];
    }

    function updateFundAddress(address _fundAddress) public onlyOwner returns (bool){
        fundAddress = _fundAddress;
        return true;
    }

    function transferIERC20(address _contract, address to, uint256 amount) public onlyOwner returns (bool){
        IERC20(_contract).transfer(to, amount);
        return true;
    }

    function transferTRX(address payable to, uint256 amount) public onlyOwner returns (bool){
        to.transfer(amount);
        return true;
    }

    function updatePoolAddress(address _poolAddress) public onlyOwner returns (bool){
        poolAddress = _poolAddress;
        return true;
    }

    function updateExclude(address addr, bool exclude) public onlyOwner returns (bool){
        tAddress[addr] = exclude;
        return true;
    }

    function isExclude(address addr) public view returns (bool){
        return tAddress[addr];
    }


    function isContract(address account) public view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
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

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (tAddress[account] || isContract(account)) {
            return tOwned[account];
        }
        uint256 sAmount = sOwned[account];
        if (sAmount <= 0) {
            return 0;
        }
        uint256 temp = _totalSupply.sub(tTotal);
        return temp.mul(sAmount).div(sTotal);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function getOwnerData(address account) public view returns (uint256 t, uint256 s){
        t = tOwned[account];
        s = sOwned[account];
    }


    function getDailyAmount(uint256 _second) public view returns (uint256){
        uint256 df = _second.div(86400);
        return dailyAmount[df];
    }

    function _addDailyAmount(uint256 amount) internal {
        uint256 df = now.div(86400);
        dailyAmount[df] = dailyAmount[df].add(amount);
    }

    function _transferAA(address sender, address recipient, uint256 amount) internal {
        tOwned[sender] = tOwned[sender].sub(amount);
        tOwned[recipient] = tOwned[recipient].add(amount);
    }

    function _transferAB(address sender, address recipient, uint256 amount) internal {
        tOwned[sender] = tOwned[sender].sub(amount);
        if (sTotal == 0) {
            sTotal = amount.div(100);
            sOwned[recipient] = sTotal;
            tTotal = tTotal.sub(amount);
        } else {
            uint256 sAmount = _totalSupply.sub(tTotal);
            uint256 temp = amount.div(100);
            tOwned[blackHole] = tOwned[blackHole].add(temp);
            tOwned[fundAddress] = tOwned[fundAddress].add(temp);
            uint256 sAdd = temp.mul(6);
            tOwned[poolAddress] = tOwned[poolAddress].add(sAdd);
            _addDailyAmount(sAdd);
            sAdd = 0;
            uint256 tuijianren = temp.mul(3);
            uint256 tAdd = temp.mul(8);
            sAdd = 0;
            address inviter = inviterAddressMap[recipient];
            if (inviter == address(0x0)) {
                tOwned[fundAddress] = tOwned[fundAddress].add(tuijianren);
                tAdd = tAdd.add(tuijianren);
            } else {
                //邀请人
                if (tAddress[inviter] || isContract(inviter)) {
                    tOwned[inviter] = tOwned[inviter].add(tAdd);
                    tAdd = tAdd.add(tuijianren);
                } else {
                    //占份额
                    sAdd = sTotal.mul(tuijianren).div(sAmount);
                    sOwned[inviter] = sOwned[inviter].add(sAdd);
                }
            }

            uint256 left = amount.sub(temp.mul(12));
            uint256 tt88 = sTotal.mul(left).div(sAmount);
            sOwned[recipient] = sOwned[recipient].add(tt88);
            sTotal = sTotal.add(tt88).add(sAdd);
            tTotal = tTotal.sub(amount).add(tAdd);
            _updateTotalSupply(temp);
        }
    }

    function _transferBB(address sender, address recipient, uint256 amount) internal {
        uint256 pOne = amount.div(100);
        tOwned[blackHole] = tOwned[blackHole].add(pOne);
        tOwned[fundAddress] = tOwned[fundAddress].add(pOne);
        uint256 temp = pOne.mul(6);
        tOwned[poolAddress] = tOwned[poolAddress].add(temp);
        _addDailyAmount(temp);
        address inviter = inviterAddressMap[recipient];
        uint256 tAdd = pOne.mul(8);
        //推荐人奖励
        temp = pOne.mul(3);
        uint256 sAmount = _totalSupply.sub(tTotal);
        uint256 tt = sTotal.mul(amount).div(sAmount);
        if (inviter == address(0x0)) {
            tOwned[fundAddress] = tOwned[fundAddress].add(temp);
            tAdd = tAdd.add(temp);
            temp = 3;
        } else {
            //邀请人
            if (tAddress[inviter] || isContract(inviter)) {
                tOwned[inviter] = tOwned[inviter].add(temp);
                tAdd = tAdd.add(temp);
                temp = 3;
            } else {
                //占份额
                sOwned[inviter] = sOwned[inviter].add(tt.mul(3).div(100));
                temp = 0;
            }
        }
        if (sOwned[sender] > tt) {
            sOwned[sender] = sOwned[sender].sub(tt);
        } else {
            tt = sOwned[sender];
            sOwned[sender] = 0;
        }
        sOwned[recipient] = sOwned[recipient].add(tt.mul(88).div(100));
        temp = temp.add(9);
        temp = tt.mul(temp).div(100);
        sTotal = sTotal.sub(temp);
        tTotal = tTotal.add(tAdd);
        _updateTotalSupply(pOne);
    }

    function _updateTotalSupply(uint256 blackAmount) internal {
        _totalSupply = _totalSupply.sub(blackAmount);
        tTotal = tTotal.sub(blackAmount);
    }

    function _transferBA(address sender, address recipient, uint256 amount) internal {
        uint256 sAmount = _totalSupply.sub(tTotal);
        uint256 tt = sTotal.mul(amount).div(sAmount);
        tOwned[recipient] = tOwned[recipient].add(amount);
        sOwned[sender] = sOwned[sender].sub(tt);
        sTotal = sTotal.sub(tt);
        tTotal = tTotal.add(amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        bool senderStatus = tAddress[sender] || isContract(sender);
        bool recipientStatus = tAddress[recipient] || isContract(recipient);

        if (senderStatus) {
            if (recipientStatus) {
                _transferAA(sender, recipient, amount);
            } else {
                _transferAB(sender, recipient, amount);
            }
        } else {
            if (recipientStatus) {
                _transferBA(sender, recipient, amount);
            } else {
                _transferBB(sender, recipient, amount);
            }
        }
        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract HOOH is NaToken {
    constructor(address _fundAddress) public NaToken(_fundAddress,"Leonard Coin", "HOOH", 6, uint256(20210422)){

    }
}