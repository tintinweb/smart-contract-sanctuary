/**
 *Submitted for verification at polygonscan.com on 2021-10-03
*/

pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.6.0 <0.8.0;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    
    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    
    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity >=0.6.0;

interface IPools {
    function sptNotify(uint256) external;
}

contract SPT is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    uint256 public totalSupply;
    string public constant name = "Sparta Token";
    string public constant symbol = "SPT";
    uint8 public constant decimals = 18;
    EnumerableSet.AddressSet private senderSet;
    EnumerableSet.AddressSet private recepientSet;
    uint256 public constant MAX_FEERATE = 100;
    uint256 public constant FEE_BASE = 1000;
    uint256 public constant maxSupply = 3e25;
    struct FeeInfo {
        address account;
        uint256 feerate;
        bool notify;
    }
    FeeInfo[] public feeInfo;
    EnumerableSet.AddressSet private minterSet;
    uint256 public holders;
    
    modifier n0Addr(address addr) {
        require(addr != address(0), "SPT:zero address");
        _;
    }
    
    modifier invalidIndex(EnumerableSet.AddressSet storage set, uint256 index) {
        require(set.length() > index, "SPT:index overflow");
        _;
    }
    
    modifier inSet(EnumerableSet.AddressSet storage set, address account) {
        require(set.contains(account), "SPT:not in set");
        _;
    }
    
    modifier notInSet(EnumerableSet.AddressSet storage set, address account) {
        require(!set.contains(account), "SPT:in set");
        _;
    }
    
    constructor(address swap, address market, address blackhole, address fund, address supernode) public {
        addMinter(msg.sender);
        mint(swap, maxSupply*2/100);
        mint(market, maxSupply*3/100);
        addWhiteList(swap);
        addWhiteList(market);
        addWhiteList(blackhole);
        addWhiteList(fund);
        addWhiteList(supernode);
    }
    
    function _addBalance(address account, uint256 amount) internal {
        if (amount > 0) {
            if (balanceOf[account] == 0) {
                holders = holders.add(1);
            }
            balanceOf[account] = balanceOf[account].add(amount);
        }
    }
    
    function _subBalance(address account, uint256 amount) internal {
        if (amount > 0) {
            balanceOf[account] = balanceOf[account].sub(amount);
            if (balanceOf[account] == 0) {
                holders = holders.sub(1);
            }
        }
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal n0Addr(sender) n0Addr(recipient) {
        _subBalance(sender, amount);
        uint256 leftAmount = amount;
        if (!isWhiteSender(sender) && !isWhiteRecipient(recipient)) {
            for (uint256 i = 0; i < feeInfo.length; i++) {
                uint256 fee = amount.mul(feeInfo[i].feerate).div(FEE_BASE);
                if (fee > 0) {
                    _addBalance(feeInfo[i].account, fee);
                    leftAmount = leftAmount.sub(fee);
                    if (feeInfo[i].notify) {
                        IPools(feeInfo[i].account).sptNotify(fee);
                    }
                    emit Transfer(sender, feeInfo[i].account, fee);
                }
            }
        }
        _addBalance(recipient, leftAmount);
        emit Transfer(sender, recipient, leftAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal n0Addr(owner) n0Addr(spender) {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address account, uint256 amount) public n0Addr(account) returns(bool) {
        require(isMinter(msg.sender), "SPT:not minter");
        totalSupply = totalSupply.add(amount);
        require(totalSupply <= maxSupply, "SPT:totalSupply overflow");
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance[sender][_msgSender()].sub(amount, "SPT:transfer amount exceeds allowance"));
        return true;
    }
    
    function setFee(address[] memory account, uint256[] memory feerate, bool[] memory notify) public onlyOwner {
        require(account.length == feerate.length, "SPT:array length error");
        delete feeInfo;
        uint256 sum = 0;
        for (uint256 i = 0; i < account.length; i++) {
            feeInfo.push(FeeInfo({account:account[i], feerate:feerate[i], notify:notify[i]}));
            sum = sum.add(feerate[i]);
        }
        require(sum <= MAX_FEERATE, "SPT:sum of feerate is overflow");
    }
    
    function isMinter(address account) view public returns(bool) {
        return minterSet.contains(account);
    }
    
    function lengthMinter() view external returns(uint256) {
        return minterSet.length();
    }
    
    function getMinter(uint256 index) view external invalidIndex(minterSet, index) returns(address) {
        return minterSet.at(index);
    }
    
    function addMinter(address account) public onlyOwner notInSet(minterSet, account) {
        minterSet.add(account);
    }
    
    function removeMinter(address account) external onlyOwner inSet(minterSet, account) {
        minterSet.remove(account);
    }
    
    function isWhiteSender(address account) view public returns(bool) {
        return senderSet.contains(account);
    }
    
    function lengthWhiteSender() view external returns(uint256) {
        return senderSet.length();
    }
    
    function getWhiteSender(uint256 index) view external invalidIndex(senderSet, index) returns(address) {
        return senderSet.at(index);
    }
    
    function addWhiteSender(address account) external onlyOwner notInSet(senderSet, account) {
        senderSet.add(account);
    }
    
    function removeWhiteSender(address account) external onlyOwner inSet(senderSet, account) {
        senderSet.remove(account);
    }
    
    function isWhiteRecipient(address account) view public returns(bool) {
        return recepientSet.contains(account);
    }
    
    function lengthWhiteRecipient() view external returns(uint256) {
        return recepientSet.length();
    }
    
    function getWhiteRecipient(uint256 index) view external invalidIndex(recepientSet, index) returns(address) {
        return recepientSet.at(index);
    }
    
    function addWhiteRecipient(address account) external onlyOwner notInSet(recepientSet, account) {
        recepientSet.add(account);
    }
    
    function removeWhiteRecipient(address account) external onlyOwner inSet(recepientSet, account) {
        recepientSet.remove(account);
    }
    
    function addWhiteList(address account) public onlyOwner {
        require(!senderSet.contains(account) || !recepientSet.contains(account), "SPT:already in list");
        if (!senderSet.contains(account)) {
            senderSet.add(account);
        }
        if (!recepientSet.contains(account)) {
            recepientSet.add(account);
        }
    }
    
    function removeWhiteList(address account) external onlyOwner {
        require(senderSet.contains(account) || recepientSet.contains(account), "SPT:not in list");
        if (senderSet.contains(account)) {
            senderSet.remove(account);
        }
        if (recepientSet.contains(account)) {
            recepientSet.remove(account);
        }
    }
}