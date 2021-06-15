/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.4.16;
contract ERC20Interface {  
    string public constant name = "Apollo";    //代币名称  
    string public constant symbol = "APO";      //代币符号  
    uint8 public constant decimals = 18;        //代币小数点位数  
  
    function totalSupply() public constant returns (uint);  //代币发行总量  
    function balanceOf(address tokenOwner) public constant returns (uint balance);  //查看对应账号代币余额  
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);   //返回授权花费的代币数  
    function transfer(address to, uint tokens) public returns (bool success);   //实现代币转账交易  
    function approve(address spender, uint tokens) public returns (bool success);   //授权用户可代表我们花费的代币数  
    function transferFrom(address from, address to, uint tokens) public returns (bool success);     //给被授权的用户使用  
  
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);  
}  

interface token {  
    function transfer(address receiver, uint amount);  
}  
  
contract Crowdsale {  
    address public beneficiary;  // 募资成功后的收款方  
    uint public fundingGoal;   // 募资额度  
    uint public amountRaised;   // 参与数量  
    uint public deadline;      // 募资截止期  
  
    uint public price = 0.0001 ether; //1 APO = 0.0001ETH or 1ETH = 10000APO;    //  token 与以太坊的汇率 , token卖多少钱  
    token public tokenReward;   // 要卖的token  
    
    mapping(address => uint256) public balanceOf;  
  
    bool fundingGoalReached = false;  // 众筹是否达到目标  
    bool crowdsaleClosed = false;   //  众筹是否结束  
  
    /** 
    * 事件可以用来跟踪信息 
    **/  
    event GoalReached(address recipient, uint totalAmountRaised);  
    event FundTransfer(address backer, uint amount, bool isContribution);  
  
    /** 
     * 构造函数, 设置相关属性 
     */  
    function Crowdsale(  
        address ifSuccessfulSendTo,  
        uint fundingGoalInEthers,  
        uint durationInMinutes,  
        uint finneyCostOfEachToken,  
        address addressOfTokenUsedAsReward) {  
            beneficiary = ifSuccessfulSendTo;  
            fundingGoal = fundingGoalInEthers * 1 ether;  
            deadline = now + durationInMinutes * 1 minutes;  
            price = finneyCostOfEachToken * 1 finney;  
            tokenReward = token(addressOfTokenUsedAsReward);   // 传入已发布的 token 合约的地址来创建实例  
    }  
  
    /** 
     * 无函数名的Fallback函数， 
     * 在向合约转账时，这个函数会被调用 
     */  
    function () payable {  
        require(!crowdsaleClosed);  
        uint amount = msg.value;  
        balanceOf[msg.sender] += amount;  
        amountRaised += amount;  
        tokenReward.transfer(msg.sender, amount / price);  
        FundTransfer(msg.sender, amount, true);  
    }  
  
    /** 
    *  定义函数修改器modifier（作用和Python的装饰器很相似） 
    * 用于在函数执行前检查某种前置条件（判断通过之后才会继续执行该方法） 
    * _ 表示继续执行之后的代码 
    **/  
    modifier afterDeadline() { if (now >= deadline) _; }  
  
    /** 
     * 判断众筹是否完成融资目标， 这个方法使用了afterDeadline函数修改器 
     * 
     */  
    function checkGoalReached() afterDeadline {  
        if (amountRaised >= fundingGoal) {  
            fundingGoalReached = true;  
            GoalReached(beneficiary, amountRaised);  
        }  
        crowdsaleClosed = true;  
    }  
  
  
    /** 
     * 完成融资目标时，融资款发送到收款方 
     * 未完成融资目标时，执行退款 
     * 
     */  
    function safeWithdrawal() afterDeadline {  
        if (!fundingGoalReached) {  
            uint amount = balanceOf[msg.sender];  
            balanceOf[msg.sender] = 0;  
            if (amount > 0) {  
                if (msg.sender.send(amount)) {  
                    FundTransfer(msg.sender, amount, false);  
                } else {  
                    balanceOf[msg.sender] = amount;  
                }  
            }  
        }  
  
        if (fundingGoalReached && beneficiary == msg.sender) {  
            if (beneficiary.send(amountRaised)) {  
                FundTransfer(beneficiary, amountRaised, false);  
            } else {  
                //If we fail to send the funds to beneficiary, unlock funders balance  
                fundingGoalReached = false;  
            }  
        }  
    }  
}  

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    string public name; //token的名字
    string public symbol;//token的简称
    uint8 public decimals = 18;  // decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值
    uint256 public totalSupply;//token的总数

    // 用mapping保存每个地址对应的余额
    mapping (address => uint256) public balanceOf;
    // 存储对账号的控制
    mapping (address => mapping (address => uint256)) public allowance;

    // 事件，用来通知客户端交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 事件，用来通知客户端代币被消费
    event Burn(address indexed from, uint256 value);

    /**
     * 初始化构造
     */
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        balanceOf[msg.sender] = totalSupply;                // 创建者拥有所有的代币
        name = tokenName;                                   // 代币名称
        symbol = tokenSymbol;                               // 代币符号
    }

    /**
     * 代币交易转移的内部实现
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 确保目标地址不为0x0，因为0x0地址代表销毁
        require(_to != 0x0);
        // 检查发送者余额
        require(balanceOf[_from] >= _value);
        // 确保转移为正数个
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // 以下用来检查交易，
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        // 用assert来检查代码逻辑。
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     *  代币交易转移
     * 从自己（创建交易者）账号发送`_value`个代币到 `_to`账号
     *
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * 账号之间代币交易转移
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * 设置某个地址（合约）可以创建交易者名义花费的代币数。
     *
     * 允许发送者`_spender` 花费不多于 `_value` 个代币
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置允许一个地址（合约）以我（创建交易者）的名义可最多花费的代币数。
     *
     * @param _spender 被授权的地址（合约）
     * @param _value 最大可花费代币数
     * @param _extraData 发送给合约的附加数据
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            // 通知合约
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 销毁我（创建交易者）账户中指定个代币
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * 销毁用户账户中指定个代币
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
        }
    }