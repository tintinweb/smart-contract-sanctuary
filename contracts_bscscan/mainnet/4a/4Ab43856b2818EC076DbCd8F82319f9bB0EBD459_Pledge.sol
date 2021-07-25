/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


// Math operations with safety checks that throw on error
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }
}


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    function balanceOf(address _address) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract SOLO {
    function pools(uint256 pid) external view returns (
        address token,              // Address of token contract
        uint256 depositCap,         // Max deposit amount
        uint256 depositClosed,      // Deposit closed
        uint256 lastRewardBlock,    // Last block number that reward distributed
        uint256 accRewardPerShare,  // Accumulated rewards per share
        uint256 accShare,           // Accumulated Share
        uint256 apy,                // APY, times 10000
        uint256 used                // How many tokens used for farming
    );
    function pidOfToken(address token) external view returns (uint256 pid);
    function users(uint256 pid, address user) external view returns (uint256 amount,uint256 rewardDebt);
    function unclaimedReward(uint256 pid, address user) external view returns (uint256 reward);
    function userStatistics(address user) external view returns (uint256 claimedReward);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
}


// Pledge contract
contract Pledge {
    using SafeMath for uint256;
    // 管理员地址
    address public owner;

    // 存入的币种的信息
    struct tokenMsg {
        // token地址
        address token;
        // 是否关闭; true=直接前端不显示, 也不可以玩了
        bool isClosed;
        // 是否可存入; true=可以存入币
        bool isDeposit;
        // 是否可提取; true=可以提取币
        bool isWithdraw;
        // 存入的总量
        uint256 depositTotal;
        // 提取的总量
        uint256 withdrawTotal;
        // 存入的ntfi总量
        uint256 depositTotalNtfi;
        // 提取的ntfi总量
        uint256 withdrawTotalNtfi;
        // 是否需要存入到solo合约; true=存入到solo
        bool isSolo;
    }
    // token地址对应token存入币种信息
    mapping(address => tokenMsg) public token;
    // 所有的token地址
    address[] public allToken;
    // NTFI合约地址
    address public constant ntfiAddress = 0xafde2C02d3b19e25dd63fe6356674e1B1f43D9df;
    // solo合约地址
    address public soloAddress;
    // 后台可操作地址
    address public operationAddress;
    // 是否把币存入到solo合约
    bool public allIsSolo = true;
    // 接受mdx代币的地址
    address public leaderAddress;

    // 用户存入的订单信息
    struct order {
        // 区块高度
        uint256 block;
        // token的合约地址
        address tokenAddress;
        // token数量
        uint256 tokenValue;
        // ntfi数量
        uint256 ntfiValue;
        // 是否已经提取
        bool isFetch;
        // 这个订单的id
        uint256 orderId;
    }
    // 用户=>orderId=>order
    mapping(address => mapping(uint256 => order)) public userOrder;
    // 用户=>orderIds
    mapping(address => uint256[]) public userOrderIds;

    // 质押和提取
    bytes4 private constant DEPOSIT = bytes4(
        keccak256(bytes("deposit(uint256,uint256)"))
    );
    bytes4 private constant WITHDRAW = bytes4(
        keccak256(bytes("withdraw(uint256,uint256)"))
    );
    bytes4 private constant APPROVE = bytes4(
        keccak256(bytes("approve(address,uint256)"))
    );
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );

    // 存入, 取出
    event Deposit(address indexed _userAddress, address indexed _tokenAddress, uint256 _tokenValue, uint256 _ntfiValue, uint256 _orderId);
    event Withdraw(address indexed _userAddress, address indexed _tokenAddress, uint256 _tokenValue, uint256 _ntfiValue, uint256 _orderId);
    // 其它事件
    event SetOwner(address _owner);
    event SetOperationAddress(address _operationAddress);
    event SetSoloAddress(address _soloAddress);
    event SetLeaderAddress(address _leaderAddress);
    event SetAllIsSolo(bool _allIsSolo);
    event SetToken(address _tokenAddress);
    event SetClosed(address _tokenAddress, bool _isClosed);
    event SetDeposit(address _tokenAddress, bool _isDeposit);
    event SetWithdraw(address _tokenAddress, bool _isWithdraw);

    // 参数1: 操作者地址
    // 参数2: solo合约地址
    // 参数3: 接受mdx币的地址
    constructor(address _operationAddress, address _soloAddress, address _leaderAddress) public {
        owner = msg.sender;
        operationAddress = _operationAddress;
        soloAddress = _soloAddress;
        leaderAddress = _leaderAddress;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    modifier onlyOperation {
        require(msg.sender == operationAddress, "You are not operation");
        _;
    }

    // 设置新的管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "Zero address");
        owner = _owner;
        emit SetOwner(_owner);
        success = true;
    }

    // 修改新的后台可操作地址
    function setOperationAddress(address _operationAddress) public onlyOwner returns (bool success) {
        require(_operationAddress != address(0), "Zero address");
        operationAddress = _operationAddress;
        emit SetOperationAddress(_operationAddress);
        success = true;
    }

    // 设置新的solo合约地址
    function setSoloAddress(address _soloAddress) public onlyOperation returns (bool success) {
        require(_soloAddress != address(0), "Zero address");
        soloAddress = _soloAddress;
        emit SetSoloAddress(_soloAddress);
        success = true;
    }

    // 设置新的接受币的地址
    function setLeaderAddress(address _leaderAddress) public onlyOperation returns (bool success) {
        require(_leaderAddress != address(0), "Zero address");
        leaderAddress = _leaderAddress;
        emit SetLeaderAddress(_leaderAddress);
        success = true;
    }

    // 修改是否存入到solo合约
    function setAllIsSolo() public onlyOperation returns (bool success) {
        allIsSolo = !allIsSolo;
        emit SetAllIsSolo(allIsSolo);
        success = true;
    }

    // 添加质押的币种
    // 参数1: token的合约地址
    // 参数2: 代币是否存入到solo合约
    function setToken(address _tokenAddress, bool _isSolo) public onlyOperation returns (bool success) {
        require(_tokenAddress != address(0), "Zero address");
        // 地址必须不存在
        for(uint256 i = 0; i < allToken.length; i++) {
            require(allToken[i] != _tokenAddress, "Address exist");
        }
        // 添加到token列表
        allToken.push(_tokenAddress);
        // 添加token信息
        token[_tokenAddress] = tokenMsg(_tokenAddress, false, true, true, 0, 0, 0, 0, _isSolo);
        emit SetToken(_tokenAddress);
        success = true;
    }

    // 设置某个币种 关闭或开启; 如果关闭时调用就是开启, 如果是开启时调用就是关闭
    function setClosed(address _tokenAddress) public onlyOperation returns (bool success) {
        // 必须有token
        require(allToken.length > 0, "Not address");
        tokenMsg storage t = token[_tokenAddress];
        require(t.token != address(0), "Zero address");
        t.isClosed = !t.isClosed;
        emit SetClosed(_tokenAddress, t.isClosed);
        success = true;
    }

    // 设置某个币种 可存入或不可存入;
    function setDeposit(address _tokenAddress) public onlyOperation returns (bool success) {
        // 必须有token
        require(allToken.length > 0, "Not address");
        tokenMsg storage t = token[_tokenAddress];
        require(t.token != address(0), "Zero address");
        t.isDeposit = !t.isDeposit;
        emit SetDeposit(_tokenAddress, t.isDeposit);
        success = true;
    }

    // 设置某个币种 可提取或不可提取;
    function setWithdraw(address _tokenAddress) public onlyOperation returns (bool success) {
        // 必须有token
        require(allToken.length > 0, "Not address");
        tokenMsg storage t = token[_tokenAddress];
        require(t.token != address(0), "Zero address");
        t.isWithdraw = !t.isWithdraw;
        emit SetWithdraw(_tokenAddress, t.isWithdraw);
        success = true;
    }

    // 设置某个币种 是否存入到solo合约;
    function setIsSolo(address _tokenAddress) public onlyOperation returns (bool success) {
        // 必须有token
        require(allToken.length > 0, "Not address");
        tokenMsg storage t = token[_tokenAddress];
        require(t.token != address(0), "Zero address");
        t.isSolo = !t.isSolo;
        success = true;
    }

    // 查询全部的币种
    function getAllToken() public view returns (address[] memory r) {
        uint256 tl = allToken.length;
        r = new address[](tl);
        for(uint256 i = 0; i < tl; i++) {
            r[i] = allToken[i];
        }
    }

    // 获取token的详细信息
    function getTokenMsg(address _tokenAddress) public view returns (tokenMsg memory r) {
        r = token[_tokenAddress];
    }

    // 查询全部质押币种详细信息
    function getAllTokenMsg() public view returns (tokenMsg[] memory r) {
        uint256 tl = allToken.length;
        r = new tokenMsg[](tl);
        for(uint256 i = 0; i < tl; i++) {
            r[i] = token[allToken[i]];
        }
    }

    // 查询id对应的信息
    function pools2(uint256 _id) external view returns (
        address _token,
        uint256 _depositCap,
        uint256 _depositClosed,
        uint256 _lastRewardBlock,
        uint256 _accRewardPerShare,
        uint256 _accShare,
        uint256 _apy,
        uint256 _used) {
        (_token, _depositCap, _depositClosed, _lastRewardBlock, _accRewardPerShare, _accShare, _apy, _used) = SOLO(soloAddress).pools(_id);
    }
    // 查询id对应的token地址
    function pidOfToken2(address _token) external view returns (uint256 id) {
        id = SOLO(soloAddress).pidOfToken(_token);
    }
    // 合约用户质押了多少币, 和可获得的收益
    function users2(uint256 _id, address _user) external view returns (uint256 amount, uint256 rewardDebt) {
        (amount, rewardDebt) = SOLO(soloAddress).users(_id, _user);
    }
    // 获取用户未领取的奖励
    function unclaimedReward2(uint256 _id, address _user) external view returns (uint256 reward) {
        reward = SOLO(soloAddress).unclaimedReward(_id, _user);
    }
    // 所有池子的总收益
    function userStatistics2(address _user) external view returns (uint256 claimedReward) {
        claimedReward = SOLO(soloAddress).userStatistics(_user);
    }

    // 合约授权代币给solo合约
    // 参数1: token代币合约地址
    function approveToSolo(address _tokenAddress) public onlyOperation returns (bool success) {
        (bool success1, ) = address(_tokenAddress).call(
            abi.encodeWithSelector(APPROVE, soloAddress, 10000000000 * 10**18)
        );
        if(!success1) {
            revert("transfer fail");
        }
        success = true;
    }

    // 用户存入
    // 参数1: 存入币的币合约地址
    // 参数2: 币的数量
    // 参数3: ntfi的数量
    // 参数4: 订单号
    function userDeposit(address _tokenAddress, uint256 _tokenValue, uint256 _ntfiValue, uint256 _orderId) public returns (bool success) {
        // 金额必须大于0
        require(_tokenValue > 0 && _ntfiValue > 0, "Money is zero");
        // 判断这个token地址是否是已经添加的
        tokenMsg storage d = token[_tokenAddress];
        // 地址默认值是0, 所以不能是0地址
        require(d.token != address(0), "Address not exist");
        // 判断是否已经关闭
        require(!d.isClosed, "Already closed");
        // 判断是否可以充值
        require(d.isDeposit, "Not deposit");

        // 如果solo合约可以存入的话就把币存入到solo合约, 如果solo合约不能存入的话就存到本合约里面;
        // 判断solo合约是否可以存入这个代币; true=可以, false=不可以存入
        (bool s_, uint256 id_) = tokenIsExist(_tokenAddress);
        // 用户先把币转给本合约
        (bool success1, ) = address(_tokenAddress).call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _tokenValue)
        );
        if(!success1) {
            revert("transfer fail");
        }
        if(s_) {
            // 可以存入到solo合约
            // 先判断有木有授权给代币给solo合约, 如果有就不用授权, 没有就授权
            uint256 value_ = ERC20(_tokenAddress).allowance(address(this), soloAddress);
            if(value_ < _tokenValue) {
                // 没有授权币给solo合约
                // 本合约授权代币给solo合约
                (bool success2, ) = address(_tokenAddress).call(
                    abi.encodeWithSelector(APPROVE, soloAddress, 10000000000 * 10**18)
                );
                if(!success2) {
                    revert("transfer fail");
                }
            }
            // 授权了足够的币给solo合约
            // 本合约把币给到solo合约
            (bool success3, ) = address(soloAddress).call(
                abi.encodeWithSelector(DEPOSIT, id_, _tokenValue)
            );
            if(!success3) {
                revert("transfer fail");
            }
        }
        // 把ntfi转入到本合约
        (bool success5, ) = address(ntfiAddress).call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _ntfiValue)
        );
        if(!success5) {
            revert("transfer fail");
        }

        // 到了这里; 说明币已经存入好了
        // 增加总存入金额
        d.depositTotal = d.depositTotal.add(_tokenValue);
        d.depositTotalNtfi = d.depositTotalNtfi.add(_ntfiValue);
        // 添加用户的已经存入;
        order memory o = order(block.number, _tokenAddress, _tokenValue, _ntfiValue, false, _orderId);
        userOrder[msg.sender][_orderId] = o;
        userOrderIds[msg.sender].push(_orderId);
        // 触发充值事件
        emit Deposit(msg.sender, _tokenAddress, _tokenValue, _ntfiValue, _orderId);
        success = true;
    }

    // 判断token是可以存入到solo合约
    function tokenIsExist(address _tokenAddress) private view returns (bool success, uint256 id) {
        // 如果全部不让存入到solo合约就返回false
        // 如果这个币种不然存入到solo合约, 也返回false
        if(allIsSolo == false || token[_tokenAddress].isSolo == false) {
            success = false;
        }else {
            // 这个币是要存入到solo合约的
            success = true;
            id = SOLO(soloAddress).pidOfToken(_tokenAddress);
        }
    }

    // 用户提取
    // 参数1: 提取订单; 订单号
    function userWithdraw(uint256 _orderId) public returns (bool success4) {
        // 判断订单是否存在或是否是未提取的
        order storage o = userOrder[msg.sender][_orderId];
        // 地址默认值是0, 所以不能是0地址
        require(o.tokenAddress != address(0), "Zero address");
        require(o.isFetch == false, "The order does not exist or has been collected");
        tokenMsg storage d = token[o.tokenAddress];
        // 判断是否已经关闭
        require(d.isClosed == false, "Already closed");
        // 判断是否可以提现
        require(d.isWithdraw, "Not withdraw");

        // 开始提取;
        // 判断是从solo合约提取还是从本合约提取; 和存入的判断一样
        (bool s_, uint256 id_) = tokenIsExist(o.tokenAddress);
        if(s_) {
            // 先从solo提取到本合约
            (bool success1, ) = address(soloAddress).call(
                abi.encodeWithSelector(WITHDRAW, id_, o.tokenValue)
            );
            if(!success1) {
                revert("transfer fail");
            }
        }
        // 从本合约给到用户
        (bool success2, ) = address(o.tokenAddress).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, o.tokenValue)
        );
        if(!success2) {
            revert("transfer fail");
        }
        // 在把ntfi给到用户
        (bool success3, ) = address(ntfiAddress).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, o.ntfiValue)
        );
        if(!success3) {
            revert("transfer fail");
        }

        // 到了这; 里说明提取转账给到了
        // 增加总提取金额
        d.withdrawTotal = d.withdrawTotal.add(o.tokenValue);
        d.withdrawTotalNtfi = d.withdrawTotalNtfi.add(o.ntfiValue);
        // 订单修改成已经提取;
        o.isFetch = true;
        // 触发提取事件
        emit Withdraw(msg.sender, o.tokenAddress, o.tokenValue, o.ntfiValue, o.orderId);
        success4 = true;
    }

    // 查询用户的单笔订单详细
    // 参数1: 用户的地址
    // 参数2: 查询的订单
    function getUserOrderId(address _userAddress, uint256 _orderId) public view returns (order memory r) {
        r = userOrder[_userAddress][_orderId];
    }

    // 查询用户的全部订单
    // 参数1: 用户的地址
    function getUserOrders(address _userAddress) public view returns (uint256[] memory r) {
        uint256 a = userOrderIds[_userAddress].length;
        // 创建定长结构体数组对象
        r = new uint256[](a);
        for(uint256 i = 0; i < a; i++) {
            r[i] = userOrderIds[_userAddress][i];
        }
    }

    // 取出solo收益的代币
    function fetchToken(address _erc20Address) public onlyOperation returns (bool success) {
        // 这个erc20的币不能是可以存入的币种;
        require(token[_erc20Address].token == address(0), "The token not fetch");
        ERC20 erc20 = ERC20(_erc20Address);
        uint256 _value = erc20.balanceOf(address(this));
        (bool success1, ) = address(_erc20Address).call(
            abi.encodeWithSelector(TRANSFER, leaderAddress, _value)
        );
        if(!success1) {
            revert("transfer fail");
        }
        success = true;
    }

    // 提取solo合约的mdx收益; 存入数量0就可以
    // 参数1: token地址
    function fetchSoloEarn(address _tokenAddress) public onlyOperation returns (bool success) {
        uint256 id_ = SOLO(soloAddress).pidOfToken(_tokenAddress);
        (bool success1, ) = address(soloAddress).call(
            abi.encodeWithSelector(DEPOSIT, id_, 0)
        );
        if(!success1) {
            revert("transfer fail");
        }
        success = true;
    }


}