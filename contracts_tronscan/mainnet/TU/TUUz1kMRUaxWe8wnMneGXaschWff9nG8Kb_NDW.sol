//SourceUnit: new_ndw.sol

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

contract NDW is TRC20 {
    using SafeMath for uint256;
    using Address for address;
    using SafeTRC20 for TRC20;
    address public owner;
    address private team;
    uint8 private deadline = 10; //期限10年
    uint256 public issureTime = block.timestamp; //发布时间
    uint256 private currentYear = 1; //当前年度
    uint256 public currentYearIssure = formatDecimals(1); //当前发行量
    uint256 public circSupply = formatDecimals(0); //已发行量
    bool isPledge = true; //质押合约功能状态，true才可以进行质押
    bool isIssure = true; //是否定时释放
    uint256 public size; //质押用户数量
    uint256 public totalPledgeAmount; //质押总额度
    uint256 public totalProfixAmount; //收益总额度
    address private profitor; //收益分配者账户地址，仅该地址有权分配收益
    KeyFlag[] public keys; //用于标记用户地址的质押状态
    uint256 public scale = 50000;
    uint256 public minPledge = 100000;

    mapping(address => PledgeOrder) public orders; //质押用户
    mapping(address => uint256) public takeProfitTime;

    TRC20 private pnToken;
    TRC20 private usdtToken;

    uint8 public constant decimals = 8;
    string public constant name = "NDW";
    string public constant symbol = "ndw";

    struct PledgeOrder {
        //标记质押用户的各类状态
        bool isExist; //质押状态
        uint256 token; //质押额度
        uint256 profitToken; //收益额度
        uint256 pnProfitToken; //pn收益额度
        uint256 time; //最后一次提取收益时间
        uint256 index; //质押地址序号
    }

    struct KeyFlag {
        address key; //用户地址
        bool isExist; //质押状态
    }

    uint256 public currentExtensionIndex = 0;
    uint256 public totalExtensionAmount = 0;
    struct extension {
        bool isPledge; //是否质押
        bool isExtension; //是否已经被推广
        uint256 pledgeMount; //自己质押量
        uint256 totalChildPledgeAmount; //子节点总质押量
        uint256 maxChildPledgeAmount; //最大子质押量
        uint256 count; //推广人数
        address currentnode; //当前节点
        address parentnode; //父节点
        address[] childnodes; //下级节点
        uint256 index;
    }

    mapping(address => extension) public extensionInfoByAddress;
    mapping(uint256 => extension) public extensionInfoByIndex;
    mapping(address => address[]) public extensionUser;

    event Extension(address _parent, address _node, uint256 happenTime);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    event Issure(uint256 _value);
    event Pledge(address _user, uint256 _value);
    event TakeProfit(address _user, uint256 _value);
    event Taketoken(address _user, uint256 _value);

    modifier onlyProfitor {
        require(profitor == msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor(
        uint256 _initialSupply,
        address _team,
        address pn,
        address usdt
    ) public {
        owner = msg.sender;
        team = _team;
        _totalSupply = formatDecimals(_initialSupply);
        pnToken = TRC20(pn);
        usdtToken = TRC20(usdt);
    }

    function changeIssure(bool _isIssure) public onlyOwner {
        isIssure = _isIssure;
    }

    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function createOrder(uint256 amount, uint256 index) private {
        orders[msg.sender] = PledgeOrder(
            true,
            amount,
            0,
            0,
            block.timestamp,
            index
        );
    }

    function changeScale(uint256 _scale) public onlyOwner {
        scale = _scale;
    }
    function changeMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge;
    }

    //质押
    function pledge(uint256 usdtMount) public {
        require(
            address(msg.sender) == address(tx.origin) &&
                msg.sender != address(0x0),
            "invalid address"
        );
        require(isPledge, "is disable");
        require(_totalSupply > circSupply, "less ndw");
        require(usdtMount >= minPledge, "less pledge");
        if (orders[msg.sender].isExist == false) {
            keys.push(KeyFlag(msg.sender, true));
            size++;
            createOrder(usdtMount, SafeMath.safeSub(keys.length, 1));
        } else {
            PledgeOrder storage order = orders[msg.sender];
            order.token = SafeMath.safeAdd(order.token, usdtMount);
            keys[order.index].isExist = true;
        }

        pnToken.safeTransferFrom(
            msg.sender,
            address(this),
            SafeMath.safeDiv(SafeMath.safeMul(usdtMount, 1000000), scale)
        );
        usdtToken.safeTransferFrom(msg.sender, address(this), usdtMount);

        totalPledgeAmount = SafeMath.safeAdd(totalPledgeAmount, usdtMount);
        totalProfixAmount = SafeMath.safeAdd(
            totalProfixAmount,
            SafeMath.safeDiv(SafeMath.safeMul(usdtMount, 1000000), scale)
        );

        extensionInfoByAddress[msg.sender].isPledge = true;
        extensionInfoByAddress[msg.sender].pledgeMount = SafeMath.safeAdd(
            extensionInfoByAddress[msg.sender].pledgeMount,
            usdtMount
        );

        if (extensionInfoByAddress[msg.sender].isExtension == true) {
            extension storage etx =
                extensionInfoByAddress[
                    extensionInfoByAddress[msg.sender].parentnode
                ];
            
        etx.count = SafeMath.safeAdd(
            etx.count,
            1
        );
         extensionInfoByIndex[etx.index].count = SafeMath.safeAdd(
            extensionInfoByIndex[etx.index].count,
            1
        );
        
            dgByAddress(msg.sender, usdtMount);
            totalExtensionAmount = SafeMath.safeAdd(totalExtensionAmount, usdtMount);
        }

        extensionInfoByIndex[extensionInfoByAddress[msg.sender].index]
            .isPledge = true;
        extensionInfoByIndex[extensionInfoByAddress[msg.sender].index]
            .pledgeMount = SafeMath.safeAdd(
            extensionInfoByIndex[extensionInfoByAddress[msg.sender].index]
                .pledgeMount,
            usdtMount
        );

        if (
            extensionInfoByAddress[msg.sender].isExtension == true
        ) {
            dgByIndex(msg.sender, usdtMount);
        }

        emit Pledge(msg.sender, usdtMount);
    }
    
    function dgByAddress(address _addr, uint256 _value) internal {
        if (extensionInfoByAddress[_addr].parentnode != address(0x0)) {
            extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].totalChildPledgeAmount = SafeMath.safeAdd(
                extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].totalChildPledgeAmount, _value);
            uint256 maxValue = extensionInfoByAddress[_addr].pledgeMount + extensionInfoByAddress[_addr].totalChildPledgeAmount;
            if (extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].maxChildPledgeAmount< maxValue ) {
                extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].maxChildPledgeAmount = maxValue ;
            }
            dgByAddress(extensionInfoByAddress[_addr].parentnode, _value);
        }
    }
    
    function dgByIndex(address _addr, uint256 _value) internal {
        if (extensionInfoByAddress[_addr].parentnode != address(0x0)) {
             extensionInfoByIndex[extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].index].totalChildPledgeAmount = SafeMath.safeAdd(
                extensionInfoByIndex[extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].index].totalChildPledgeAmount, _value);
            uint256 maxValue = extensionInfoByAddress[_addr].pledgeMount + extensionInfoByAddress[_addr].totalChildPledgeAmount;
            if (extensionInfoByIndex[extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].index].maxChildPledgeAmount< maxValue ) {
                extensionInfoByIndex[extensionInfoByAddress[extensionInfoByAddress[_addr].parentnode].index].maxChildPledgeAmount = maxValue ;
            }
            dgByIndex(extensionInfoByAddress[_addr].parentnode, _value);
        }
    }

    //收益分配
    function profit() public onlyOwner {
        require(totalPledgeAmount > 0, "no pledge");
        require(isIssure, "no issure");
        require(circSupply < _totalSupply, "less token");
        require(currentYear <= 10, "the deadline is come");
        require(totalProfixAmount > formatDecimals(0), "no pn gas");
        SafeTRC20.safeTransfer(
            address(pnToken),
            address(0x0),
            SafeMath.safeDiv(totalProfixAmount, 4)
        );
        SafeTRC20.safeTransfer(address(pnToken), team, SafeMath.safeDiv(totalProfixAmount, 4));
        uint256 yearTimestamp = 60 * 60 * 24 * 365; //一年时间戳
        uint256 currentYearTimestamp =
            SafeMath.safeDiv(
                SafeMath.safeAdd(
                    block.timestamp - issureTime,
                    yearTimestamp - 1
                ),
                yearTimestamp
            );
        if (currentYear != currentYearTimestamp) {
            currentYearIssure = SafeMath.safeDiv(
                SafeMath.safeMul(currentYearIssure, 3),
                2
            );
        }
        circSupply = SafeMath.safeAdd(circSupply, currentYearIssure);
        uint256 half = SafeMath.safeDiv(currentYearIssure, 2);
        //质押收益
        for (uint256 i = 0; i < keys.length; i++) {
            if (keys[i].isExist == true) {
                PledgeOrder storage order = orders[keys[i].key];
                order.profitToken = SafeMath.safeAdd(
                    order.profitToken,
                    SafeMath.safeDiv(
                        SafeMath.safeMul(half, order.token),
                        totalPledgeAmount
                    )
                );
            }
        }
        if (totalExtensionAmount != 0) {
            uint256 curr = 0;
            uint256 tot = 0;
            for (uint256 i=1; i<= currentExtensionIndex; i++) {
                if (extensionInfoByIndex[i].count >= 2) {
                    curr += extensionInfoByIndex[i].count;
                    tot += SafeMath.safeAdd(extensionInfoByIndex[i].pledgeMount,
                                SafeMath.safeSub(
                                    extensionInfoByIndex[i].totalChildPledgeAmount,
                                    extensionInfoByIndex[i].maxChildPledgeAmount
                                    )
                                );
                }
            }
            if (curr > 0 && tot > 0 ) {
                //推广收益  |  pn收益
            for (uint256 j = 1; j <= currentExtensionIndex; j++) {
                uint256 extensionToken =
                    SafeMath.safeDiv(
                        SafeMath.safeMul(
                            half,
                            SafeMath.safeAdd(extensionInfoByIndex[j].pledgeMount,
                                SafeMath.safeSub(
                                    extensionInfoByIndex[j].totalChildPledgeAmount,
                                    extensionInfoByIndex[j].maxChildPledgeAmount
                                )
                            )
                        ),
                        tot
                    );
                uint256 value =
                    SafeMath.safeDiv(
                        SafeMath.safeMul(
                            SafeMath.safeDiv(totalProfixAmount, 2),
                            extensionInfoByIndex[j].count
                        ),
                        curr
                    );

                if (extensionInfoByIndex[j].count == 2) {
                    extensionToken = extensionToken;
                    value = value;
                    
                } else if (extensionInfoByIndex[j].count == 3) {
                    if (extensionInfoByIndex[j].totalChildPledgeAmount >= 10000000000) {
                        extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(3, 2)
                       );
                        value = SafeMath.safeMul(value, SafeMath.safeDiv(3, 2));
                    } else {
                        extensionToken = extensionToken;
                        value = value;
                    }
                   
                } else if (extensionInfoByIndex[j].count == 4) {
                    if (extensionInfoByIndex[j].totalChildPledgeAmount >= 50000000000) {
                        extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(9, 5)
                       );
                        value = SafeMath.safeMul(value, SafeMath.safeDiv(9, 5));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 10000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 50000000000) {
                        extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(3, 2)
                        );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(3, 2));
                    } else {
                         extensionToken = extensionToken;
                    value = value;
                    }
                    
                } else if (extensionInfoByIndex[j].count == 5) {
                    if (extensionInfoByIndex[j].totalChildPledgeAmount >= 250000000000) {
                         extensionToken = SafeMath.safeMul(extensionToken, 2);
                    value = SafeMath.safeMul(value, 2);
                    } else  if (extensionInfoByIndex[j].totalChildPledgeAmount >= 50000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 250000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(9, 5)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(9, 5));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 10000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 50000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(3, 2)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(3, 2));
                    } else {
                         extensionToken = extensionToken;
                    value = value;
                    }
                    
                } else if (extensionInfoByIndex[j].count == 6) {
                    if (extensionInfoByIndex[j].totalChildPledgeAmount >= 1500000000000) {
                        extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(23, 10)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(23, 10));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 250000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 1500000000000) {
                         extensionToken = SafeMath.safeMul(extensionToken, 2);
                    value = SafeMath.safeMul(value, 2);
                    } else  if (extensionInfoByIndex[j].totalChildPledgeAmount >= 50000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 250000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(9, 5)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(9, 5));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 10000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 50000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(3, 2)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(3, 2));
                    } else {
                         extensionToken = extensionToken;
                    value = value;
                    }
                    
                } else if (extensionInfoByIndex[j].count >= 7) {
                    if (extensionInfoByIndex[j].totalChildPledgeAmount >= 5000000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(5, 2)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(5, 2));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 1500000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 5000000000000) {
                        extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(23, 10)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(23, 10));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 250000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 1500000000000) {
                         extensionToken = SafeMath.safeMul(extensionToken, 2);
                    value = SafeMath.safeMul(value, 2);
                    } else  if (extensionInfoByIndex[j].totalChildPledgeAmount >= 50000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 250000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(9, 5)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(9, 5));
                    } else if (extensionInfoByIndex[j].totalChildPledgeAmount >= 10000000000 && extensionInfoByIndex[j].totalChildPledgeAmount < 50000000000) {
                         extensionToken = SafeMath.safeMul(
                        extensionToken,
                        SafeMath.safeDiv(3, 2)
                    );
                    value = SafeMath.safeMul(value, SafeMath.safeDiv(3, 2));
                    } else {
                         extensionToken = extensionToken;
                    value = value;
                    }
                    
                } else {
                    extensionToken = 0;
                    value = 0;
                }
                
                orders[extensionInfoByIndex[j].currentnode].profitToken = SafeMath
                    .safeAdd(
                        orders[extensionInfoByIndex[j].currentnode].profitToken,
                        extensionToken
                    );
                orders[extensionInfoByIndex[j].currentnode].pnProfitToken = SafeMath
                    .safeAdd(
                        orders[extensionInfoByIndex[j].currentnode].pnProfitToken,
                        value
                );
            }
            }
             
        }
        totalProfixAmount = 0;
        emit Issure(currentYearIssure);
    }

    //提取燃料
    function takePnGas() public {
        require(
            orders[msg.sender]
                .pnProfitToken > 0,
            "no pn token"
        );
        SafeTRC20.safeTransfer(
            address(pnToken),
            msg.sender,
            orders[msg.sender]
                .pnProfitToken
        );
        orders[msg.sender]
                .pnProfitToken = 0;
    }

    //收益提取
    function takeProfit() public {
        require(
            address(msg.sender) == address(tx.origin) &&
                msg.sender != address(0x0),
            "no contract"
        );
        require(orders[msg.sender].profitToken > 0, "less token");
        PledgeOrder storage order = orders[msg.sender];
        takeProfitTime[msg.sender] = block.timestamp;

        uint256 previousBalance =
            SafeMath.safeAdd(order.profitToken, _balances[address(msg.sender)]); //校验
        _balances[address(msg.sender)] = SafeMath.safeAdd(
            _balances[address(msg.sender)],
            order.profitToken
        );

        emit TakeProfit(msg.sender, order.profitToken);
        order.profitToken = 0;

        assert(
            SafeMath.safeAdd(
                order.profitToken,
                _balances[address(msg.sender)]
            ) == previousBalance
        );
    }

    //本金提取函数
    function taketoken() public {
        require(
            address(msg.sender) == address(tx.origin) &&
                msg.sender != address(0x0),
            "invalid address"
        );
        PledgeOrder storage order = orders[msg.sender];
        require(order.token > 0, "no order");
        totalPledgeAmount = SafeMath.safeSub(totalPledgeAmount, order.token);
        // SafeTRC20.safeTransfer(address(usdtToken), msg.sender, order.token);
        usdtToken.transfer(msg.sender, order.token);
        emit Taketoken(msg.sender, order.token);
        order.token = formatDecimals(0);
        extensionInfoByAddress[msg.sender].pledgeMount = formatDecimals(0);
        extensionInfoByIndex[extensionInfoByAddress[msg.sender].index].pledgeMount = formatDecimals(0);  
    }

    //推广
    function extensionToken(address _parent, address _children) public {
        require(_parent != address(0x0), "invalid address");
        require(_children != address(0x0), "invalid address");
        require(_children != _parent, "equail address");
        //判断子节点是否已经被推广
        require(
            extensionInfoByAddress[_children].isExtension == false,
            "has been extension"
        );
        require(
            extensionInfoByAddress[_children].isPledge == false,
            "has been pledge"
        );
        require(extensionInfoByAddress[_parent].isPledge == true, "no pledge");
        if (extensionInfoByAddress[_parent].childnodes.length == 0) {
            extensionInfoByAddress[_parent].index = SafeMath.safeAdd(
                currentExtensionIndex,
                1
            );
            extensionInfoByIndex[
                SafeMath.safeAdd(currentExtensionIndex, 1)
            ] = extensionInfoByAddress[_parent];
            extensionInfoByAddress[_parent].currentnode = _parent;
            extensionInfoByIndex[SafeMath.safeAdd(currentExtensionIndex, 1)]
                .currentnode = _parent;
        }
        currentExtensionIndex++;
        
        extensionInfoByAddress[_parent].childnodes.push(address(_children));
        extensionInfoByAddress[_children].parentnode = address(_parent);
        extensionInfoByAddress[_children].isExtension = true;

        extensionInfoByIndex[extensionInfoByAddress[_parent].index].childnodes.push(address(_children));
        extensionUser[_parent].push(address(_children));
        emit Extension(_parent, _children, block.timestamp);
    }
    
    //格式化(_value * 10 ** uint256(decimals))
    function formatDecimals(uint256 _value) internal pure returns (uint256) {
        return _value * 10**uint256(decimals);
    }
}