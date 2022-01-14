/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

pragma solidity ^0.4.16;
 
contract owned {
    address public owner;

    function owned () public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
 
/**
 * 基础代币合约
 */
contract TokenERC20 {
    string public name; //发行的代币名称
    string public symbol; //发行的代币符号
    uint8 public decimals = 18;  //代币单位，展示的小数点后面多少个0。
    uint256 public totalSupply; //发行的代币总量
 
    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);  
    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param initialSupply 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        //初始化总量
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        //给指定帐户初始化代币总量，初始化用于奖励合约创建者
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
 
 
    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
 
      //避免转帐的地址是0x0
      require(_to != 0x0);
 
      //检查发送者是否拥有足够余额
      require(balanceOf[_from] >= _value);
 
      //检查是否溢出
      require(balanceOf[_to] + _value > balanceOf[_to]);
 
      //保存数据用于后面的判断
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
 
      //从发送者减掉发送额
      balanceOf[_from] -= _value;
 
      //给接收者加上相同的量
      balanceOf[_to] += _value;
 
      //通知任何监听该交易的客户端
      Transfer(_from, _to, _value);
 
      //判断买、卖双方的数据是否和转换前一致
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
 
    }
 
    /**
     * 从主帐户合约调用者发送给别人代币
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
 
    /**
     * 从某个指定的帐户中，向另一个帐户发送代币
     * 调用过程，会检查设置的允许最大交易额
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
 
    /**
     * 设置帐户允许支付的最大金额
     * 一般在智能合约的时候，避免支付过多，造成风险
     * @param _spender 帐户地址
     * @param _value 金额
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}
 
/**
 * 代币增发、
 * 
 * 代币自动销售和购买、
 * 高级代币功能
 */
contract MyAdvancedToken is owned, TokenERC20 {
 
    uint256 public airdropRatio = 1000;  //空投比例 1:1000
    
    uint256 public cemeteryRatio = 500000; //公墓比例 1:500000
    
    uint256 public cemeteryStartTime = 1644768000; //公墓开始时间

    bool public cemeteryEndfalg;  //结束公墓开关

    uint256 public cemeteryTotal;  //公墓z总量
    
    uint256 public totalYuji; //
    
    uint256 public airdropYuji;
    
    uint256 public cemeteryYuji;
    
    uint256 public airdropShiji;
    
    uint256 public cemeteryShiji;
    
    mapping (address => uint256) public airdropAddress;  //参与空投地址 数量
    
    mapping (address => uint256) public cemeteryAddress;  //参与空投地址 数量

    mapping (address => bool) public airdropBool; //是否领取空投

    event Airdrop(address indexed adr, uint256 value , uint256 state);   //空投事件
    
    
    event Cmetery(address indexed adr, uint256 ethValue, uint256 value);  //参与公墓事件
 
 
    /*初始化合约，并且把初始的所有的令牌都给这合约的创建者
     * @param initialSupply 所有币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
        function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
 
    /**
     * 可以为指定帐户创造一些代币
     * @param  target address 帐户地址
     * @param  mintedAmount uint256 增加的金额(单位是wei)
     */
    function _mintToken(address target, uint256 mintedAmount) internal {
        //给指定地址增加代币，同时总量也相加
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(this, target, mintedAmount);
    }
    function setCemeteryStartTime(uint256 _cemeteryStartTime) onlyOwner public {
       cemeteryStartTime = _cemeteryStartTime;
    }
 
 
    function setCemeteryEndfalg(bool _cemeteryEndfalg) onlyOwner public {
       cemeteryEndfalg = _cemeteryEndfalg;
    }
    
    function joinAirdrop() public{
        require(block.timestamp < cemeteryStartTime);
        uint256  balance = address(msg.sender).balance / 10**18;
        require(balance >= 1);
        airdropAddress[msg.sender] = balance * airdropRatio * 10**18; 
        totalYuji += balance * airdropRatio * 10**18;
        airdropYuji += balance * airdropRatio * 10**18;
        Airdrop(msg.sender,airdropAddress[msg.sender],1);
    }

    function drawAirdrop() public {
        require(cemeteryEndfalg);
        require(airdropAddress[msg.sender]>0 || airdropAddress[msg.sender]>0);
        require(!airdropBool[msg.sender]);
        uint256 _value = cemeteryAddress[msg.sender] + airdropAddress[msg.sender];
        _mintToken(msg.sender,_value);
        airdropBool[msg.sender]= true;
        airdropShiji += airdropAddress[msg.sender];
        cemeteryShiji += cemeteryAddress[msg.sender];
        Airdrop(msg.sender,_value,2);
    }

    function joinCemetery() public payable{
        require(!cemeteryEndfalg);
        require(block.timestamp >= cemeteryStartTime);
        cemeteryAddress[msg.sender] += msg.value * cemeteryRatio;
        cemeteryTotal+= msg.value;
        totalYuji += msg.value * cemeteryRatio;
        cemeteryYuji += msg.value * cemeteryRatio;
        Cmetery(msg.sender,msg.value, msg.value * cemeteryRatio);
    }
   //平台提币
     function transferMetacode(address _to, uint256 _value) onlyOwner  public {
        address(_to).transfer(_value);
        return;
    }


 
}