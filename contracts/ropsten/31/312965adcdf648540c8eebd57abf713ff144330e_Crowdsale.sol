/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.4.17;


/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows
        @param _x   value 1
        @param _y   value 2
        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number
        @param _x   minuend
        @param _y   subtrahend
        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows
        @param _x   factor 1
        @param _y   factor 2
        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    Standard ISmartyToken interface
*/
contract ISmartToken {

    function issue(address _to, uint256 _value) public;
}

/**
 * 众筹合约
 */
contract Crowdsale is Utils {
    address public beneficiary = 0x0; //受益人地址，测试时为合约创建者
    uint256 public fundingGoal = 2 ether;  //众筹目标，单位是ether
    uint256 public amountRaised = 0; //已筹集金额数量， 单位是wei
    uint256 public deadline; //截止时间
    uint256 public price;  //代币价格
    bool public fundingGoalReached = false;  //达成众筹目标
    bool public crowdsaleClosed = false; //众筹关闭

    ISmartToken public token;   // smart token

    mapping(address => uint256) public balance; //保存众筹地址

    //记录已接收的ether通知
    event GoalReached(address _beneficiary, uint _amountRaised);

    //转帐通知
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

    /**
     * 初始化构造函数
     *
     * @param _beneficiary 受益人地址
     * @param _fundingGoalInEthers 众筹以太币总量
     * @param _durationInMinutes 众筹截止,单位是天
     * @param _token 众筹代币
     */
    function Crowdsale(
        address _beneficiary,
        uint _fundingGoalInEthers,
        uint _durationInMinutes,
        ISmartToken _token
    )
        public
        validAddress(_beneficiary)
    {
        token = _token;
        beneficiary = _beneficiary;
        fundingGoal = _fundingGoalInEthers * 1 ether;
        deadline = now + _durationInMinutes * 1 days;
        price = 5000 finney; //1个以太币可以买 20 个代币
    }


    /**
     * 默认函数
     *
     * 默认函数，可以向合约直接打款
     */
    function () payable public {

        //判断是否关闭众筹
        require(!crowdsaleClosed);
        uint amount = msg.value;

        //捐款人的金额累加
        balance[msg.sender] += amount;

        //捐款总额累加
        amountRaised += amount;

        //转帐操作，转多少代币给捐款人
        token.issue(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }

    /**
     * 判断是否已经过了众筹截止限期
     */
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * 检测众筹目标是否已经达到
     */
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            //达成众筹目标
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }

        //关闭众筹
        crowdsaleClosed = true;
    }


    /**
     * 收回资金
     *
     * 检查是否达到了目标或时间限制，如果有，并且达到了资金目标，
     * 将全部金额发送给受益人。如果没有达到目标，每个贡献者都可以退出
     * 他们贡献的金额
     */
    function safeWithdrawal() public afterDeadline {

        //如果没有达成众筹目标
        if (!fundingGoalReached) {
            //获取合约调用者已捐款余额
            uint amount = balance[msg.sender];

            if (amount > 0) {
                //返回合约发起者所有余额
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