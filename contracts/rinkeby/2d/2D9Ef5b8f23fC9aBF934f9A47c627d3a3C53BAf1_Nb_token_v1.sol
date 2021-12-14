/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-12-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity  ^0.7.6;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Nb_token_v1 is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint public epoch_base = 86400;//挖矿周期基数，不变
    // uint public epoch = 86400;//挖矿周期，随着时间变化
    uint public start_time;//挖矿开始时间
    uint256 public totalSupply;
    uint256 public totalPower;//总算力
    address payable public owner;
    bool public is_airdrop = true;//是否开启空投，开启空投不能挖矿
    bool public is_upgrade = true;//是否开启老合约升级到新合约
    uint256 public totalUsersAmount;//总用户数
    

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public CoinBalanceOf;
    //      user             token        balance
    mapping (address => mapping(address => uint256)) public TokenBalanceOf;
    mapping (address => address) public invite;//邀请
    mapping (address => uint256) public power;//算力
    mapping (address => uint8) public st;//ST值
    mapping (address => uint8) public cs;//领取次数
    mapping (address => uint8) public activation_time;//从激活到上次领取的间隔天数
    mapping (address => uint256) public last_time;//用户上次挖矿时间
    mapping (address => uint256) public epoch;//用户上次挖矿时间
    mapping (address => bool) public nbcontributionv2;//首次达到V2登陆给上级增加50贡献值
    mapping (address => bool) public nbweightsv2;//首次上v2，上级+1权重值
    mapping (address => bool) public nbweightsv3;//首次上v3，上级+1权重值
    mapping (address => bool) public nbweightsv4;//首次上v4，上级+1权重值
    mapping (address => bool) public nbweightsv5;//首次上v5，上级+1权重值
    mapping (address => uint256) public freezeOf;
    mapping (address => uint256) public inviteCount;//邀请人好友数
    mapping (address => uint256) public rewardCount;//累计奖励
    mapping (address => uint8) public contribution;//贡献值
    mapping (address => uint256) public weights;//权重值
    mapping (address => mapping (address => uint256)) public allowance;//授权
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
    // 铸币事件
    event Minted(
        address indexed operator,
        address indexed to,
        uint256 amount
    );

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8  tokenDecimals
        ) {
        totalSupply = 0;// Update total supply
        name = tokenName;        // 设置合约的全称
        symbol = tokenSymbol;    // 设置合约的简称
        decimals = tokenDecimals;//设置精度
        owner = msg.sender;
        nbcontributionv2[msg.sender] = true;
        nbweightsv2[msg.sender] = true;
        nbweightsv3[msg.sender] = true;
        nbweightsv4[msg.sender] = true;
        nbweightsv5[msg.sender] = true;
    }

    //写入老合约的用户算力
    function wpower(uint256 pamount) public{
        require(power[msg.sender] == 0);//零算力账号才可以
        power[msg.sender] = pamount;
        totalPower += pamount;
        totalUsersAmount++;
    }
    
    //获取个人总算力
    function gettotalPower() public view returns (uint256) {
        return totalPower;
    }

    
    /* 转账操作  */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));// Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0);
        require(msg.sender != _to);//自己不能转给自己

        uint fee = transfer_fee(msg.sender,_value);
        uint sub_value = SafeMath.safeAdd(fee, _value);//扣除余额需要计算手续费

        require(balanceOf[msg.sender] >= sub_value);//需要计算加上手续费后是否够
        if (balanceOf[_to] + _value < balanceOf[_to]) revert("overflows");// Check for overflows

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], sub_value);// Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                        // Add the same to the recipient
        totalSupply -= fee;//总量减少手续费
        emit Transfer(msg.sender, _to, _value);               // Notify anyone listening that this transfer took place
        if(fee > 0)
        emit Burn(msg.sender, fee);
        return true;
    }
    
    function transfer_fee(address _from,uint256 _value) public view returns (uint256 fee) {
        uint8 scale = 20;// n/100
        //没有挖矿用户免手续费
        if(last_time[_from] == 0)
        {
            scale = 0;
            return 0;
        }
        else if(power[_from] >= 62500)
        {
            scale = 5;
        }
        else
        {
            scale = contribution[_from] / 50 ;
            if(scale >= 10)
            {
                scale = 10;
            }
            scale = 20 - scale;
        }
        
        uint256 _fee = _value * scale / (100-scale);//例如手续费20%，账号减少1个，到账0.8个，0.2手续费
        return _fee;
    }
    
    //空投,用户自己可以申请领取算力
    function airdrop() public{
        require(power[msg.sender] == 0);//零算力账号才可以
        require(is_airdrop);//需要开启空投
        power[msg.sender] = 200;
        totalPower += 200;
        totalUsersAmount++;
    }

    //设置新管理员
    function setOwner(address payable new_owner) public {
        require(msg.sender == owner);
        owner = new_owner;
    }

    //暂停空投
    function set_airdrop() public{
        require(msg.sender == owner);
        require(is_airdrop);
        is_airdrop = !is_airdrop;
    }
    
    //暂停升级
    function stop_upgrade() public{
        require(msg.sender == owner);
        require(is_upgrade);
        is_upgrade = false;
    }

    function getbalance() public view returns (uint256){
        return balanceOf[msg.sender];
    }

    function getinvite() public view returns (address){
        return invite[msg.sender];
    }
    
    //燃烧
    function burn(uint256 _value) public returns (bool success)  {
        require(balanceOf[msg.sender] >= _value);        // Check if the sender has enough
		require(_value > 0);

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value);                            
        if(power[msg.sender] == 0)
            totalUsersAmount++;
        power[msg.sender] += _value * 3;//燃烧加算力
        emit Burn(msg.sender, _value);
        totalPower += _value * 3;//加累计算力
        reward_upline(_value);//给上级释放奖励算力
        contribution_upline();
        return true;
    }

    //增加余额
    // function addbalance(uint256 _value) public returns (bool success) {
    //     emit Minted(msg.sender,msg.sender,_value);
    //     return true;
    // }
    
    //当用户第一次达到V2等级时，给予上级50贡献值
    function contribution_upline() private returns (bool success){
        //邀请人不能为空
        if(invite[msg.sender] != address(0) && nbcontributionv2[msg.sender])
        {
            address invite1 = invite[msg.sender];
            nbcontributionv2[msg.sender] = false;
            contribution[invite1] += 50;
            return true;
        }
        return true;
    }
    
    //给上级释放奖励算力方法
    function reward_upline(uint256 _value) private returns (bool success){
        //邀请人不能为空
        if(invite[msg.sender] != address(0))
        {
            address invite1 = invite[msg.sender];

            //零算力不奖励
            if(power[invite1] == 0)
                return true;
            uint8 scale = 2;
            if(power[invite1] < 500)
            {
                scale = 2;
            }
            else if(power[invite1] < 5000)
            {
                scale = 5;
            }
            else if(power[invite1] < 10000)
            {
                scale = 6;
            }
            else if(power[invite1] < 20000)
            {
                scale = 7;
            }
            else if(power[invite1] >= 20000)
            {
                scale = 8;
            }
            //小数支持不好，就先乘后除的方法
            uint256 reward = _value * scale / 100;
            //如果本次算力大于上级
            if(power[invite1] < reward)
            {
                reward = power[invite1];
            }

            power[invite1] = power[invite1] - reward;//减少邀请人算力
            totalPower = totalPower - reward;//减少总算力
            balanceOf[invite1] =  balanceOf[invite1] + reward;//增加邀请人余额
            totalSupply = totalSupply + reward;//增加总量
            rewardCount[invite1] += reward;//记录累计奖励
            emit Minted(msg.sender,invite1,reward);
            return true;
        }
        return true;
    }

    function mint() public returns (bool success){
        require(power[msg.sender] > 0);//算力不能为零
        require(st[msg.sender] > 0);//ST必须大于零
        //动态减产
        uint256 intervalcoe = activation_time[msg.sender] / epoch_base;
        uint256 intervals_time = last_time[msg.sender] + cs[msg.sender] * intervalcoe * 3 + 180 + epoch_base;
        require(block.timestamp >= intervals_time);//距离上次挖矿大于一个周期
        cs[msg.sender] ++;//增加一次领取次数
        st[msg.sender] --;//减少一颗ST

        //算力*比例*天数
        uint256 reward = power[msg.sender] ;
        power[msg.sender] = power[msg.sender] - reward;//算力减去本次转换的
        totalPower = totalPower - reward;//减少总算力
        balanceOf[msg.sender] =  balanceOf[msg.sender] + reward;//增加余额
        totalSupply = totalSupply + reward;//增加总量
        last_time[msg.sender] = block.timestamp;//记录本次挖矿时间
        emit Minted(msg.sender,msg.sender,reward);
        return true;
    }

    function registration(address invite_address) public returns (bool success){
        require(invite[msg.sender] == address(0));//现在没有邀请人
        require(msg.sender != invite_address);//不能是自己
        invite[msg.sender] = invite_address;//记录邀请人
        inviteCount[invite_address] += 1;//邀请人的下级数加一
        return true;
    }
}