pragma solidity ^0.4.8;

//代币合约
 contract token {
     string public name = "cao token"; //代币名称
     string public symbol = "CAO"; //代币符号比如&#39;$&#39;
     uint8 public decimals = 18;  //代币单位，展示的小数点后面多少个0,和以太币一样后面是是18个0
     uint256 public totalSupply; //代币总量,这里没有做限制,你也可以限定

    //地址对应的余额
     mapping (address => uint256) public balanceOf;

     event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件

     /* 初始化合约，并且把初始的所有代币都给这合约的创建者
      * @param _owned 合约的管理者
      * @param tokenName 代币名称
      * @param tokenSymbol 代币符号
      */

     function token(address _owned, string tokenName, string tokenSymbol) public {
         //合约的创建者获得的所有代币
         balanceOf[_owned] = totalSupply;
         name = tokenName;
         symbol = tokenSymbol;
     }

     /**
      * 转帐，具体可以根据自己的需求来实现
      * @param  _to address 接受代币的地址
      * @param  _value uint256 接受代币的数量
      */
     function transfer(address _to, uint256 _value) public{
       //从发送者减掉发送额
       balanceOf[msg.sender] -= _value;

       //给接收者加上相同的量
       balanceOf[_to] += _value;

       //通知任何监听该交易的客户端
       Transfer(msg.sender, _to, _value);
     }

     /**
      * 增加代币，并将代币发送给捐赠新用户,即所谓的增发,本文固定总量,
      * @param  _to address 接受代币的地址
      * @param  _amount uint256 接受代币的数量
      */
     function issue(address _to, uint256 _amount) public{
         totalSupply = totalSupply + _amount;
         balanceOf[_to] += _amount;

         //通知任何监听该交易的客户端
         Transfer(this, _to, _amount);
     }
  }

/**
 * 众筹合约
 */
contract CAOsale is token {
    address public beneficiary = msg.sender; //受益人地址，测试时为合约创建者,自己发自己
    uint public fundingGoal;  //众筹目标，单位是ether
    uint public amountRaised; //已筹集金额数量， 单位是wei
    uint public deadline; //截止时间
    uint public price;  //代币价格
    bool public fundingGoalReached = false;  //达成众筹目标,默认未完成
    bool public crowdsaleClosed = false; //众筹关闭,默认不关闭


    mapping(address => uint256) public balance; //保存众筹地址

    //记录已接收的eth通知
    event GoalReached(address _beneficiary, uint _amountRaised);

    //转帐时事件
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

    /**
     * 初始化构造函数
     * @param fundingGoalInEthers 众筹以太币总量
     * @param durationInMinutes 众筹截止,单位是分钟
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */

    //  在初始化众筹合约构造函数的时候，我们会将众筹合约的帐户地址，
    //  传递给代币做为管理地址，这里使用的是关键字this表示当前合约的地址，
    //  也可以传递给某个人，初始创建时奖励给这个人指定量的代币。
    function CAOsale(
        uint fundingGoalInEthers,
        uint durationInMinutes,
        string tokenName,
        string tokenSymbol
    ) public token(this, tokenName, tokenSymbol){
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 0.00001 ether; //1个以太币可以买 1 个代币
    }

    // 在众筹合约中，用于设置众筹以太币总量、众筹截止时间、以太币和代币的兑换比例,
    // 如果不使用单位进行声明换算，默认在以太坊中，所有的单位都是wei，1 ether=10^18 wei：

    /**
     * 默认函数
     *
     * 默认函数，可以向合约直接打款
     */
    function () payable public{
        //判断是否关闭众筹
        //如果关闭,则禁止打款.
        require(!crowdsaleClosed);
        // if (!crowdsaleClosed) throw; 这个是老写法,版本大坑啊!
        uint amount = msg.value;

        //捐款人的金额累加
        balance[msg.sender] += amount;

        //捐款总额累加
        amountRaised += amount;

        //转帐操作，转多少代币给捐款人
        issue(msg.sender, amount / price * 10 ** uint256(decimals));
        FundTransfer(msg.sender, amount, true);
    }

    /**
     * 判断是否已经过了众筹截止限期
     */
    modifier afterDeadline() {
        // if (this == msg.sender && now >= deadline) _; 并且该方法只能被创建者调用,严格一点
        if (now >= deadline) _;
        }

    /**
     * 检测众筹目标是否完成
     */
    function checkGoalReached() afterDeadline public{
        if (amountRaised >= fundingGoal){
            //达成众筹目标
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        //关闭众筹,禁止打款
        crowdsaleClosed = true;
    }

    /**
     * 收回资金
     * 检查是否达到了目标或时间限制，如果有，并且达到了资金目标，
     * 将全部金额发送给受益人。如果没有达到目标，每个贡献者都可以退出
     * 他们贡献的金额
     */
    function safeWithdrawal() afterDeadline public{

        //如果没有达成众筹目标,清空代币
        if (!fundingGoalReached) {
            //获取合约调用者已捐款余额
            uint amount = balance[msg.sender];

            if (amount > 0) {
                //返回合约发起者所有余额
                //transfer是自带的方法,就是朝msg.sender转入数量的意思.类似方法还有 send
                //文档具体地址:http://solidity.readthedocs.io/en/develop/types.html#members-of-addresses
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
                balance[msg.sender] = 0;
            }
        }

        //如果达成众筹目标，并且合约调用者是受益人
        if (fundingGoalReached && beneficiary == msg.sender) {

            //将所有捐款从合约中给受益人
            beneficiary.transfer(amountRaised);

            FundTransfer(beneficiary, amount, false);
        }
    }
}