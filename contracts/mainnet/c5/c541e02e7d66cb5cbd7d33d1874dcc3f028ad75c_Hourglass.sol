pragma solidity ^0.4.20;

/*
* LastHero团队.
* -> 这是什么?
* 改进的自主金字塔资金模型:
* [x] 该合约是目前最稳定的智能合约，经受过所有的攻击测试!
* [x] 由ARC等多名安全专家审核测试。
* [X] 新功能：可部分卖出，而不必将你的所有资产全部卖出!
* [x] 新功能：可以在钱包之间传输代币。可以在智能合约中进行交易!
* [x] 新特性：世界首创POS节点以太坊职能合约，让V神疯狂的新功能。
* [x] 主节点：持有100个代币即可拥有自己的主节点，主节点是唯一的智能合约入口!
* [x] 主节点：所有通过你的主节点进入合约的玩家，你可以获得10%的分红!
*
* -> 关于项目?
* 我们的团队成员拥有超强的创建安全智能合约的能力。
* 新的开发团队由经验丰富的专业开发人员组成，并由资深合约安全专家审核。
* 另外，我们公开进行过数百次的模拟攻击，该合约从来没有被攻破过。
* 
* -> 这个项目的成员有哪些?
* - PonziBot (math/memes/main site/master)数学
* - Mantso (lead solidity dev/lead web3 dev)主程
* - swagg (concept design/feedback/management)概念设计/反馈/管理
* - Anonymous#1 (main site/web3/test cases)网站/web3/测试
* - Anonymous#2 (math formulae/whitepaper)数学推导/白皮书
*
* -> 该项目的安全审核人员:
* - Arc
* - tocisck
* - sumpunk
*/

contract Hourglass {
    /*=================================
    =            MODIFIERS  全局       =
    =================================*/
    // 只限持币用户
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
    // 只限收益用户
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
    // 管理员权限:
    // -> 更改合约名称
    // -> 更改代币名称
    // -> 改变POS的难度（确保维持一个主节点需要多少代币，以避免滥发）
    // 管理员没有权限做以下事宜:
    // -> 动用资金
    // -> 禁止用户取款
    // -> 自毁合约
    // -> 改变代币价格
    modifier onlyAdministrator(){ // 用来确定是管理员
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]); // 在管理员列表中存在
        _; // 表示在modifier的函数执行完后，开始执行其它函数
    }
    
    
    // 确保合约中第一批代币均等的分配
    // 这意味着，不公平的优势成本是不可能存在的
    // 这将为基金的健康成长打下坚实的基础。
    modifier antiEarlyWhale(uint256 _amountOfEthereum){ // 判断状态
        address _customerAddress = msg.sender;
        
        // 我们还是处于不利的投资地位吗?
        // 既然如此，我们将禁止早期的大额投资 
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // 这个用户在代表名单吗？
                ambassadors_[_customerAddress] == true &&
                
                // 用户购买量是否超过代表的最大配额？
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
                
            );
            
            // 更新累计配额  
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
            // 执行
            _;
        } else {
            // 如果基金中以太币数量下降到创世值，代表阶段也不会重新启动。
            onlyAmbassadors = false;
            _;    
        }
        
    }
    
    
    /*==============================
    =            EVENTS  事件      =
    ==============================*/
    event onTokenPurchase( // 购买代币
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell( // 出售代币
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment( // 再投资
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw( // 提取资金
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    // ERC20标准
    event Transfer( // 一次交易
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES  配置       =
    =====================================*/
    string public name = "LastHero3D"; // 名字
    string public symbol = "Keys"; // 符号
    uint8 constant public decimals = 18; // 小数位
    uint8 constant internal dividendFee_ = 10; // 交易分红比例
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether; // 代币初始价格
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether; // 代币递增价格
    uint256 constant internal magnitude = 2**64;
    
    // 股份证明（默认值为100代币）
    uint256 public stakingRequirement = 100e18;
    
    // 代表计划
    mapping(address => bool) internal ambassadors_; // 代表集合
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether; // 最大购买
    uint256 constant internal ambassadorQuota_ = 20 ether; // 购买限额
    
    
    
   /*================================
    =            DATASETS   数据     =
    ================================*/
    // 每个地址的股份数量（按比例编号）
    mapping(address => uint256) internal tokenBalanceLedger_; // 保存地址的代币数量
    mapping(address => uint256) internal referralBalance_; // 保存地址的推荐分红
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    // 管理员列表（管理员权限见上述）
    mapping(bytes32 => bool) public administrators; // 管理者地址列表
    
    // 当代表制度成立，只有代表可以购买代币（这确保了完美的金字塔分布，以防持币比例不均）
    bool public onlyAmbassadors = true; // 限制只有代表能够购买代币
    


    /*=======================================
    =            PUBLIC FUNCTIONS 公开函数   =
    =======================================*/
    /*
    * -- 应用入口 --  
    */
    function Hourglass()
        public
    {
        // 在这里添加管理员
        administrators[0x4d947d5487ba694cc3c03fbaae7a63f0aec61e26bf7284baa1e36f8cbdbfe7e1] = true;
        administrators[0xdacb12a29ec52e618a1dbe39a3317833066e94371856cc2013565dab2ae6fa62] = true;
        
        // 在这里添加代表。
        // mantso - lead solidity dev & lead web dev. 
        ambassadors_[0xdD9eaEbc859051A801e2044636204271B5D6821A] = true;
        
        // ponzibot - mathematics & website, and undisputed meme god.
        ambassadors_[0xd47671aA1c42cF274697C8Fdf77470509B296d09] = true;

        ambassadors_[0x8948e4b00deb0a5adb909f4dc5789d20d0851d71] = true;
        

    }
    
     
    /**
     * 将所有以太坊网络传入转换为代币调用，并向下传递（如果有下层拓扑）
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
    /**
     * 回调函数来处理直接发送到合约的以太坊参数。
     * 我们不能通过这种方式来指定一个地址。
     */
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
    /**
     * 将所有的分红请求转换为代币。
     */
    function reinvest()
        onlyStronghands()
        public
    {
        // 提取股息
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // 实际支付的股息
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // 检索参考奖金
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // 发送一个购买订单通过虚拟化的“撤回股息”
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        
        // 重大事件
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * 退出流程，卖掉并且提取资金
     */
    function exit()
        public
    {
        // 通过调用获取代币数量并将其全部出售
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
        // 取款服务
        withdraw();
    }

    /**
     * 取走请求者的所有收益。
     */
    function withdraw()
        onlyStronghands()
        public
    {
        // 设置数据
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // 从代码中获得参考奖金
        
        // 更新股息系统
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // 添加参考奖金
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // 获取服务
        _customerAddress.transfer(_dividends);
        
        // 重大事件
        onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * 以太坊代币。
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // 设置数据
        address _customerAddress = msg.sender;
        // 来自俄罗斯的BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
        // 销毁已出售的代币
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // 更新股息系统
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // 禁止除以0
        if (tokenSupply_ > 0) {
            // 更新代币的股息金额
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        // 重大事件
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
    /**
     * 从请求者账户转移代币新持有者账户。
     * 记住，这里还有10%的费用。
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // 设置
        address _customerAddress = msg.sender;
        
        // 取保拥有足够的代币
        // 代币禁止转移，直到代表阶段结束。
        // （我们不想捕鲸）
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // 取走所有未付的股息
        if(myDividends(true) > 0) withdraw();
        
        // 被转移代币的十分之一
        // 这些都将平分给个股东
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
  
        // 销毁费用代币
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // 代币交换
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        // 更新股息系统
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
        // 分发股息给持有者
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        
        // 重大事件
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // ERC20标准
        return true;
       
    }
    
    /*----------  管理员功能  ----------*/
    /**
     * 如果没有满足配额，管理员可以提前结束代表阶段。
     */
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }
    
    /**
     * 在特殊情况，可以更换管理员账户。
     */
    function setAdministrator(bytes32 _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }
    
    /**
     * 作为预防措施，管理员可以调整主节点的费率。
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
    /**
     * 管理员可以重新定义品牌（代币名称）。
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    /**
     * 管理员可以重新定义品牌（代币符号）。
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    
    /*----------  帮助者和计数器  ----------*/
    /**
     * 在合约中查看当前以太坊状态的方法
     * 例如 totalEthereumBalance()
     */
    function totalEthereumBalance() // 查看余额
        public
        view
        returns(uint)
    {
        return this.balance;
    }
    
    /**
     * 检索代币供应总量。
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
    /**
     * 检索请求者的代币余额。
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender; // 获得发送者的地址
        return balanceOf(_customerAddress);
    }
    
    /**
     * 取回请求者拥有的股息。
     * 如果`_includeReferralBonus` 的值为1，那么推荐奖金将被计算在内。
     * 其原因是，在网页的前端，我们希望得到全局汇总。
     * 但在内部计算中，我们希望分开计算。
     */ 
    function myDividends(bool _includeReferralBonus) // 返回分红数，传入的参数用来指示是否考虑推荐分红
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
    /**
     * 检索任意地址的代币余额。
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    /**
     * 检索任意地址的股息余额。
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    /**
     * 返回代币买入的价格。
     */
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // 我们的计算依赖于代币供应，所以我们需要知道供应量。
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    /**
     * 返回代币卖出的价格。
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        // 我们的计算依赖于代币供应，所以我们需要知道供应量。
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    /**
     * 前端功能，动态获取买入订单价格。
     */
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    
    /**
     * 前端功能，动态获取卖出订单价格。
     */
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS  内部函数   =
    ==========================================*/
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        // 数据设置
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
        // 禁止恶意执行
        // 防止溢出
        // (防止黑客入侵)
        // 定义SAFEMATH保证数据安全。
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        // 用户是否被主节点引用？
        if(
            // 是否有推荐者？
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // 禁止作弊!
            _referredBy != _customerAddress && // 不能自己推荐自己
            
            // 推荐人是否有足够的代币？
            // 确保推荐人是诚实的主节点
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // 财富再分配
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // 无需购买
            // 添加推荐奖励到全局分红
            _dividends = SafeMath.add(_dividends, _referralBonus); // 把推荐奖励还给分红
            _fee = _dividends * magnitude;
        }
        
        // 我们不能给予无尽的以太坊
        if(tokenSupply_ > 0){
            
            // 添加代币到代币池
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // 获取这笔交易所获得的股息，并将平均分配给所有股东
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // 计算用户通过购买获得的代币数量。 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // 添加代币到代币池
            tokenSupply_ = _amountOfTokens;
        }
        
        // 更新代币供应总量及用户地址
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        // 告诉买卖双方在拥有代币前不会获得分红；
        // 我知道你认为你做了，但是你没有做。
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        // 重大事件
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    /**
     * 通过以太坊传入数量计算代币价格；
     * 这是一个算法，在白皮书中能找到它的科学算法；
     * 做了一些修改，以防止十进制错误和代码的上下溢出。
     */
    function ethereumToTokens_(uint256 _ethereum) // 计算ETH兑换代币的汇率
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // 向下溢出尝试
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    /**
     * 计算代币出售的价格。
     * 这是一个算法，在白皮书中能找到它的科学算法；
     * 做了一些修改，以防止十进制错误和代码的上下溢出。
     */
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }
    
    
    //这里会消耗Gas
    //你大概会多消耗1gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @title SafeMath函数
 * @dev 安全的数学运算
 */
library SafeMath {

    /**
    * @dev 两个数字乘法，抛出溢出。
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev 两个数字的整数除法。
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // 值为0时自动抛出
        uint256 c = a / b;
        // assert(a == b * c + a % b); // 否则不成立
        return c;
    }

    /**
    * @dev 两个数字的减法，如果减数大于被减数，则溢出抛出。
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev 两个数字的加法，向上溢出抛出
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}