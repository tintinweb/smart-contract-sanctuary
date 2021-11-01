//SourceUnit: test-bull.sol

pragma solidity 0.6.0;

library SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // require(a == b * c + a / b, "SafeMath: division overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b, "SafeMath: addition overflow");
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // 空字符串hash值
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        //内联编译（inline assembly）语言，是用一种非常底层的方式来访问EVM
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface TRC20Interface {
    function totalSupply() external view returns (uint256 theTotalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

library SafeTRC20 {
    using SafeMath for uint256;
    using Address for address;
    
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        TRC20Interface token,
        address from,
        address to,
        uint256 value
    ) internal {
        //kou'chu扣除15%
        uint256 newValue=SafeMath.safeMul(85,value);
        value=SafeMath.safeDiv(newValue,100);
        
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        TRC20Interface token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        TRC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            SafeMath.safeAdd(token.allowance(address(this), spender), value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        TRC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            SafeMath.safeSub(token.allowance(address(this), spender), value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(TRC20Interface token, bytes memory data)
        private
    {
        //require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


contract TRC20 is TRC20Interface {
    using SafeMath for uint256;
    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowed[_owner][spender];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0x0), "address cannot be empty.");
        require(_balances[_to] + _value > _balances[_to], "_value too large");

        uint256 previousBalance =
            SafeMath.safeAdd(_balances[_from], _balances[_to]); //校验
        _balances[_from] = SafeMath.safeSub(_balances[_from], _value);
        _balances[_to] = SafeMath.safeAdd(_balances[_to], _value);
        emit Transfer(_from, _to, _value);

        assert(
            SafeMath.safeAdd(_balances[_from], _balances[_to]) ==
                previousBalance
        );
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        _allowed[_from][msg.sender] = SafeMath.safeSub(
            _allowed[_from][msg.sender],
            _value
        );
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _delegatee, uint256 _value)
        public
        override
        returns (bool)
    {
        require(_delegatee != address(0x0), "address cannot be empty.");
        _allowed[msg.sender][_delegatee] = _value;
        emit Approval(msg.sender, _delegatee, _value);
        return true;
    }
}

contract test_bull is TRC20 {
    using SafeMath for uint256;
    using Address for address;
    using SafeTRC20 for TRC20;
    
    TRC20 private pnToken;
    TRC20 private usdtToken;

    uint8 public constant decimals = 8;
    string public constant name = "test_bull";
    string public constant symbol = "test_bull";
    
    address public owner;
    address private team;
    uint8 private deadline = 10; //期限10年
    uint256 public issureTime = block.timestamp; //发布时间
    uint256 public currentYearIssure = formatDecimals(10000000); //当前发行量
    uint256 public circSupply = 0; //已发行量
    uint256 public size; //质押用户数量
    uint256 public totalPledgeAmount; //质押总额度
    uint256 public totalProfixAmount; //收益总额度
    KeyFlag[] public keys; //用于标记用户地址的质押状态
    uint256 public scale = 50000;
    uint256 public minPledge = 100000000000000000000;
    
    struct KeyFlag {
        address key; //用户地址
        bool isExist; //质押状态
    }

    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    constructor(
        uint256 _initialSupply
    ) public {
        owner = msg.sender;
        _totalSupply = formatDecimals(_initialSupply);
		_balances[owner] = currentYearIssure; //预释放200万
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }
    
    function changeScale(uint256 _scale) public onlyOwner {
        scale = _scale;
    }
    
    function changeMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge;
    }
    

    
    
     function formatDecimals(uint256 _value) internal pure returns (uint256) {
        return _value * 10 ** uint256(decimals);
    }
}