/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.4.24;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


/**
 * @title 获取token1
 */
contract GBT {
    /* 公共变量 */
    string public name; //代币名称
    string public symbol; //代币符号比如'$'
    uint8 public decimals = 4;  //代币单位，展示的小数点后面多少个0,后面是是4个0
    uint256 public totalSupply; //代币总量

    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* 在区块链上创建一个事件，用以通知客户端*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    event Burn(address indexed from, uint256 value);  //减去用户余额事件


    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param initialSupply 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
    constructor(
       uint256 initialSupply, string tokenName, string tokenSymbol
    ) public {
         //初始化总量
        totalSupply = initialSupply * 10 ** uint256(decimals);    //带着小数的精度

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
    function _transfer(address _from, address _to, uint256 _value) internal 
    {

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
      emit  Transfer(_from, _to, _value);

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
     *
     * 调用过程，会检查设置的允许最大交易额
     *
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);   // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     *
     * 一般在智能合约的时候，避免支付过多，造成风险
     *
     * @param _spender 帐户地址
     * @param _value 金额
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        //防止事务顺序依赖
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));

        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     *
     * 一般在智能合约的时候，避免支付过多，造成风险，加入时间参数，可以在 tokenRecipient 中做其他操作
     *
     * @param _spender 帐户地址
     * @param _value 金额
     * @param _extraData 操作的时间
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 减少代币调用者的余额
     *
     * 操作以后是不可逆的
     *
     * @param _value 要删除的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough

        //给指定帐户减去余额
        balanceOf[msg.sender] -= _value;

        //代币问题做相应扣除
        totalSupply -= _value;

        emit  Burn(msg.sender, _value);
        return true;
    }

    /**
     * 删除帐户的余额（含其他帐户）
     *
     * 删除以后是不可逆的
     *
     * @param _from 要操作的帐户地址
     * @param _value 要减去的数量
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        //检查帐户余额是否大于要减去的值
        require(balanceOf[_from] >= _value);

        //检查 其他帐户 的余额是否够使用
        require(_value <= allowance[_from][msg.sender]);

        //减掉代币
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        //更新总量
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}

contract DQGBT is IERC20 {
    address private addrA;
    address private addrB;

    address private addrToken;

    struct Permit {
        bool addrAYes;
        bool addrBYes;
    }
    
    
    mapping (address => mapping (uint => Permit)) private permits;
    
    mapping (address =>uint256) private _tokenWK;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint public totalSupply = 1000000000000;  //总数量
    uint8 constant public decimals = 18;       //
    string constant public name = "DQGBT1";
    string constant public symbol = "DQGBT1";
        


     function approve(address spender, uint256 value) external returns (bool){
         return false;
     }

    function transferFrom(address from, address to, uint256 value) external returns (bool){
          GBT token = GBT(addrToken);
          
          if( token.transferFrom(from,to,value)){
              _tokenWK[msg.sender] = _tokenWK[msg.sender]+value;
          }
          
          return true;
    }

    function totalSupply() external view returns (uint256){
          GBT token = GBT(addrToken);
          return token.totalSupply();
    }
    
    
    function allowance(address owner, address spender) external view returns (uint256){
        return 0;
    }
    

    constructor(address a,address tokenAddress) public{
        addrA = a;
        addrToken = tokenAddress;
    }
    
    function getAddrs() public view returns(address, address,address) {
      return (addrA, addrB,addrToken);
    }
    
    
    
    //交易
    
    function  transfer(address to,  uint amount)  public returns (bool){
        GBT token = GBT(addrToken);
        require(token.balanceOf(this) >= amount);
            
        _tokenWK[msg.sender] = amount;
        // emit Transfer(msg.sender, to, amount);
        return true;
    }
    
   
    function  withdrawWK(address to,  uint amount)  public returns (bool){
      GBT token = GBT(addrToken);
    
      if((_tokenWK[msg.sender]>0)&&(amount>0))
      {
        if(_tokenWK[msg.sender]>=amount){
            
            _tokenWK[msg.sender] = _tokenWK[msg.sender]-amount;
              token.transfer(to,amount); 
            emit Transfer(msg.sender, to, amount);
            return true;
        }    
      }
    }
     
    //余额
    function balanceOf(address _owner) public view returns (uint) {
        
        GBT token = GBT(addrToken);
        
        return token.balanceOf(this);
    }


    //WK余额
     function balanceOfWK(address _owner) public view returns (uint) {
        
        return  _tokenWK[msg.sender];
   
    }
}