pragma solidity ^0.4.21;

interface Token {
    function totalSupply() constant external returns (uint256 ts);
    function balanceOf(address _owner) constant external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface XPAAssetToken {
    function create(address user_, uint256 amount_) external returns(bool success);
    function burn(uint256 amount_) external returns(bool success);
    function burnFrom(address user_, uint256 amount_) external returns(bool success);
    function getDefaultExchangeRate() external returns(uint256);
    function getSymbol() external returns(bytes32);
}

interface Baliv {
    function getPrice(address fromToken_, address toToken_) external view returns(uint256);
}

interface FundAccount {
    function burn(address Token_, uint256 Amount_) external view returns(bool);
}

interface TokenFactory {
    function createToken(string symbol_, string name_, uint256 defaultExchangeRate_) external returns(address);
    function getPrice(address token_) external view returns(uint256);
    function getAssetLength() external view returns(uint256);
    function getAssetToken(uint256 index_) external view returns(address);
}

contract SafeMath {
    function safeAdd(uint x, uint y)
        internal
        pure
    returns(uint) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSub(uint x, uint y)
        internal
        pure
    returns(uint) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMul(uint x, uint y)
        internal
        pure
    returns(uint) {
      uint z = x * y;
      require((x == 0) || (z / x == y));
      return z;
    }
    
    function safeDiv(uint x, uint y)
        internal
        pure
    returns(uint) {
        require(y > 0);
        return x / y;
    }

    function random(uint N, uint salt)
        internal
        view
    returns(uint) {
      bytes32 hash = keccak256(block.number, msg.sender, salt);
      return uint(hash) % N;
    }
}

contract Authorization {
    mapping(address => address) public agentBooks;
    address public owner;
    address public operator;
    address public bank;
    bool public powerStatus = true;
    bool public forceOff = false;
    function Authorization()
        public
    {
        owner = msg.sender;
        operator = msg.sender;
        bank = msg.sender;
    }
    modifier onlyOwner
    {
        assert(msg.sender == owner);
        _;
    }
    modifier onlyOperator
    {
        assert(msg.sender == operator || msg.sender == owner);
        _;
    }
    modifier onlyActive
    {
        assert(powerStatus);
        _;
    }
    function powerSwitch(
        bool onOff_
    )
        public
        onlyOperator
    {
        if(forceOff) {
            powerStatus = false;
        } else {
            powerStatus = onOff_;
        }
    }
    function transferOwnership(address newOwner_)
        onlyOwner
        public
    {
        owner = newOwner_;
    }
    
    function assignOperator(address user_)
        public
        onlyOwner
    {
        operator = user_;
        agentBooks[bank] = user_;
    }
    
    function assignBank(address bank_)
        public
        onlyOwner
    {
        bank = bank_;
    }
    function assignAgent(
        address agent_
    )
        public
    {
        agentBooks[msg.sender] = agent_;
    }
    function isRepresentor(
        address representor_
    )
        public
        view
    returns(bool) {
        return agentBooks[representor_] == msg.sender;
    }
    function getUser(
        address representor_
    )
        internal
        view
    returns(address) {
        return isRepresentor(representor_) ? representor_ : msg.sender;
    }
}

contract XPAAssets is SafeMath, Authorization {
    string public version = "0.5.0";

    // contracts
    address public XPA = 0x0090528aeb3a2b736b780fd1b6c478bb7e1d643170;
    address public oldXPAAssets = 0x0002992af1dd8140193b87d2ab620ca22f6e19f26c;
    address public newXPAAssets = address(0);
    address public tokenFactory = 0x0036B86289ccCE0984251CCCA62871b589B0F52d68;
    // setting
    uint256 public maxForceOffsetAmount = 1000000 ether;
    uint256 public minForceOffsetAmount = 10000 ether;
    
    // events
    event eMortgage(address, uint256);
    event eWithdraw(address, address, uint256);
    event eRepayment(address, address, uint256);
    event eOffset(address, address, uint256);
    event eExecuteOffset(uint256, address, uint256);
    event eMigrate(address);
    event eMigrateAmount(address);

    //data
    mapping(address => uint256) public fromAmountBooks;
    mapping(address => mapping(address => uint256)) public toAmountBooks;
    mapping(address => uint256) public forceOffsetBooks;
    mapping(address => bool) public migrateBooks;
    address[] public xpaAsset;
    address public fundAccount;
    uint256 public profit = 0;
    mapping(address => uint256) public unPaidFundAccount;
    uint256 public initCanOffsetTime = 0;
    
    //fee
    uint256 public withdrawFeeRate = 0.02 ether; // 提領手續費
    uint256 public offsetFeeRate = 0.02 ether;   // 平倉手續費
    uint256 public forceOffsetBasicFeeRate = 0.02 ether; // 強制平倉基本費
    uint256 public forceOffsetExecuteFeeRate = 0.01 ether;// 強制平倉執行費
    uint256 public forceOffsetExtraFeeRate = 0.05 ether; // 強制平倉額外手續費
    uint256 public forceOffsetExecuteMaxFee = 1000 ether; 
    
    // constructor
    function XPAAssets(
        uint256 initCanOffsetTime_
    ) public {
        initCanOffsetTime = initCanOffsetTime_;
    }

    function setFundAccount(
        address fundAccount_
    )
        public
        onlyOperator
    {
        if(fundAccount_ != address(0)) {
            fundAccount = fundAccount_;
        }
    }

    function createToken(
        string symbol_,
        string name_,
        uint256 defaultExchangeRate_
    )
        public
        onlyOperator 
    {
        address newAsset = TokenFactory(tokenFactory).createToken(symbol_, name_, defaultExchangeRate_);
        for(uint256 i = 0; i < xpaAsset.length; i++) {
            if(xpaAsset[i] == newAsset){
                return;
            }
        }
        xpaAsset.push(newAsset);
    }

    //抵押 XPA
    function mortgage(
        address representor_
    )
        onlyActive
        public
    {
        address user = getUser(representor_);
        uint256 amount_ = Token(XPA).allowance(msg.sender, this); // get mortgage amount
        if(
            amount_ >= 100 ether && 
            Token(XPA).transferFrom(msg.sender, this, amount_) 
        ){
            fromAmountBooks[user] = safeAdd(fromAmountBooks[user], amount_); // update books
            emit eMortgage(user,amount_); // wirte event
        }
    }
    
    // 借出 XPA Assets, amount: 指定借出金額
    function withdraw(
        address token_,
        uint256 amount_,
        address representor_
    ) 
        onlyActive 
        public 
    {
        address user = getUser(representor_);
        if(
            token_ != XPA &&
            amount_ > 0 &&
            amount_ <= safeDiv(safeMul(safeDiv(safeMul(getUsableXPA(user), getPrice(token_)), 1 ether), getHighestMortgageRate()), 1 ether)
        ){
            toAmountBooks[user][token_] = safeAdd(toAmountBooks[user][token_],amount_);
            uint256 withdrawFee = safeDiv(safeMul(amount_,withdrawFeeRate),1 ether); // calculate withdraw fee
            XPAAssetToken(token_).create(user, safeSub(amount_, withdrawFee));
            XPAAssetToken(token_).create(this, withdrawFee);
            emit eWithdraw(user, token_, amount_); // write event
        }
    }
    
    // 領回 XPA, amount: 指定領回金額
    function withdrawXPA(
        uint256 amount_,
        address representor_
    )
        onlyActive
        public
    {
        address user = getUser(representor_);
        if(
            amount_ >= 100 ether && 
            amount_ <= getUsableXPA(user)
        ){
            fromAmountBooks[user] = safeSub(fromAmountBooks[user], amount_);
            require(Token(XPA).transfer(user, amount_));
            emit eWithdraw(user, XPA, amount_); // write event
        }    
    }
    
    // 檢查額度是否足夠借出 XPA Assets
    /*function checkWithdraw(
        address token_,
        uint256 amount_,
        address user_
    ) 
        internal  
        view
    returns(bool) {
        if(
            token_ != XPA && 
            amount_ <= safeDiv(safeMul(safeDiv(safeMul(getUsableXPA(user_), getPrice(token_)), 1 ether), getHighestMortgageRate()), 1 ether)
        ){
            return true;
        }else if(
            token_ == XPA && 
            amount_ <= getUsableXPA(user_)
        ){
            return true;
        }else{
            return false;
        }
    }*/

    // 還款 XPA Assets, amount: 指定還回金額
    function repayment(
        address token_,
        uint256 amount_,
        address representor_
    )
        onlyActive 
        public
    {
        address user = getUser(representor_);
        if(
            XPAAssetToken(token_).burnFrom(user, amount_)
        ) {
            toAmountBooks[user][token_] = safeSub(toAmountBooks[user][token_],amount_);
            emit eRepayment(user, token_, amount_);
        }
    }
    
    // 平倉 / 強行平倉, user: 指定平倉對象
    function offset(
        address user_,
        address token_
    )
        onlyActive
        public
    {
        uint256 userFromAmount = fromAmountBooks[user_] >= maxForceOffsetAmount ? maxForceOffsetAmount : fromAmountBooks[user_];
        require(block.timestamp > initCanOffsetTime);
        require(userFromAmount > 0);
        address user = getUser(user_);

        if(
            user_ == user &&
            getLoanAmount(user, token_) > 0
        ){
            emit eOffset(user, user_, userFromAmount);
            uint256 remainingXPA = executeOffset(user_, userFromAmount, token_, offsetFeeRate);
            
            require(Token(XPA).transfer(fundAccount, safeDiv(safeMul(safeSub(userFromAmount, remainingXPA), 1 ether), safeAdd(1 ether, offsetFeeRate)))); //轉帳至平倉基金
            fromAmountBooks[user_] = remainingXPA;
        }else if(
            user_ != user && 
            block.timestamp > (forceOffsetBooks[user_] + 28800) &&
            getMortgageRate(user_) >= getClosingLine()
        ){
            forceOffsetBooks[user_] = block.timestamp;
                
            uint256 punishXPA = getPunishXPA(user_); //get 10% xpa
            emit eOffset(user, user_, punishXPA);

            uint256[3] memory forceOffsetFee;
            forceOffsetFee[0] = safeDiv(safeMul(punishXPA, forceOffsetBasicFeeRate), 1 ether); //基本手續費(收益)
            forceOffsetFee[1] = safeDiv(safeMul(punishXPA, forceOffsetExtraFeeRate), 1 ether); //額外手續費(平倉基金)
            forceOffsetFee[2] = safeDiv(safeMul(punishXPA, forceOffsetExecuteFeeRate), 1 ether);//執行手續費(執行者)
            forceOffsetFee[2] = forceOffsetFee[2] > forceOffsetExecuteMaxFee ? forceOffsetExecuteMaxFee : forceOffsetFee[2];

            profit = safeAdd(profit, forceOffsetFee[0]);
            uint256 allFee = safeAdd(forceOffsetFee[2],safeAdd(forceOffsetFee[0], forceOffsetFee[1]));
            remainingXPA = safeSub(punishXPA,allFee);

            for(uint256 i = 0; i < xpaAsset.length; i++) {
                if(getLoanAmount(user_, xpaAsset[i]) > 0){
                    remainingXPA = executeOffset(user_, remainingXPA, xpaAsset[i],0);
                    if(remainingXPA == 0){
                        break;
                    }
                }
            }
                
            fromAmountBooks[user_] = safeSub(fromAmountBooks[user_], safeSub(punishXPA, remainingXPA));
            require(Token(XPA).transfer(fundAccount, safeAdd(forceOffsetFee[1],safeSub(safeSub(punishXPA, allFee), remainingXPA)))); //轉帳至平倉基金
            require(Token(XPA).transfer(msg.sender, forceOffsetFee[2])); //執行手續費轉給執行者
        }
    }
    
    function executeOffset(
        address user_,
        uint256 xpaAmount_,
        address xpaAssetToken,
        uint256 feeRate
    )
        internal
    returns(uint256){
        uint256 fromXPAAsset = safeDiv(safeMul(xpaAmount_,getPrice(xpaAssetToken)),1 ether);
        uint256 userToAmount = toAmountBooks[user_][xpaAssetToken];
        uint256 fee = safeDiv(safeMul(userToAmount, feeRate), 1 ether);
        uint256 burnXPA;
        uint256 burnXPAAsset;
        if(fromXPAAsset >= safeAdd(userToAmount, fee)){
            burnXPA = safeDiv(safeMul(safeAdd(userToAmount, fee), 1 ether), getPrice(xpaAssetToken));
            emit eExecuteOffset(burnXPA, xpaAssetToken, safeAdd(userToAmount, fee));
            xpaAmount_ = safeSub(xpaAmount_, burnXPA);
            toAmountBooks[user_][xpaAssetToken] = 0;
            profit = safeAdd(profit, safeDiv(safeMul(fee,1 ether), getPrice(xpaAssetToken)));
            if(
                !FundAccount(fundAccount).burn(xpaAssetToken, userToAmount)
            ){
                unPaidFundAccount[xpaAssetToken] = safeAdd(unPaidFundAccount[xpaAssetToken],userToAmount);
            }

        }else{
            
            fee = safeDiv(safeMul(xpaAmount_, feeRate), 1 ether);
            profit = safeAdd(profit, fee);
            burnXPAAsset = safeDiv(safeMul(safeSub(xpaAmount_, fee),getPrice(xpaAssetToken)),1 ether);
            toAmountBooks[user_][xpaAssetToken] = safeSub(userToAmount, burnXPAAsset);
            emit eExecuteOffset(xpaAmount_, xpaAssetToken, burnXPAAsset);
            
            xpaAmount_ = 0;
            if(
                !FundAccount(fundAccount).burn(xpaAssetToken, burnXPAAsset)
            ){
                unPaidFundAccount[xpaAssetToken] = safeAdd(unPaidFundAccount[xpaAssetToken], burnXPAAsset);
            }
            
        }
        return xpaAmount_;
    }
    
    function getPunishXPA(
        address user_
    )
        internal
        view 
    returns(uint256){
        uint256 userFromAmount = fromAmountBooks[user_];
        uint256 punishXPA = safeDiv(safeMul(userFromAmount, 0.1 ether),1 ether);
        if(userFromAmount <= safeAdd(minForceOffsetAmount, 100 ether)){
            return userFromAmount;
        }else if(punishXPA < minForceOffsetAmount){
            return minForceOffsetAmount;
        }else if(punishXPA > maxForceOffsetAmount){
            return maxForceOffsetAmount;
        }else{
            return punishXPA;
        }
    }
    
    // 取得用戶抵押率, user: 指定用戶
    function getMortgageRate(
        address user_
    ) 
        public
        view 
    returns(uint256){
        if(fromAmountBooks[user_] != 0){
            uint256 totalLoanXPA = 0;
            for(uint256 i = 0; i < xpaAsset.length; i++) {
                totalLoanXPA = safeAdd(totalLoanXPA, safeDiv(safeMul(getLoanAmount(user_,xpaAsset[i]), 1 ether), getPrice(xpaAsset[i])));
            }
            return safeDiv(safeMul(totalLoanXPA,1 ether),fromAmountBooks[user_]);
        }else{
            return 0;
        }
    }
        
    // 取得最高抵押率
    function getHighestMortgageRate() 
        public
        view 
    returns(uint256){
        uint256 totalXPA = Token(XPA).totalSupply();
        uint256 issueRate = safeDiv(safeMul(Token(XPA).balanceOf(this), 1 ether), totalXPA);
        if(issueRate >= 0.7 ether){
            return 0.7 ether;
        }else if(issueRate >= 0.6 ether){
            return 0.6 ether;
        }else if(issueRate >= 0.5 ether){
            return 0.5 ether;
        }else if(issueRate >= 0.3 ether){
            return 0.3 ether;
        }else{
            return 0.1 ether;
        }
    }
    
    // 取得平倉線
    function getClosingLine() 
        public
        view
    returns(uint256){
        uint256 highestMortgageRate = getHighestMortgageRate();
        if(highestMortgageRate >= 0.6 ether){
            return safeAdd(highestMortgageRate, 0.1 ether);
        }else{
            return 0.6 ether;
        }
    }
    
    // 取得 XPA Assets 匯率 
    function getPrice(
        address token_
    ) 
        public
        view
    returns(uint256){
        return TokenFactory(tokenFactory).getPrice(token_);
    }
    
    // 取得用戶可提領的XPA(扣掉最高抵押率後的XPA)
    function getUsableXPA(
        address user_
    )
        public
        view
    returns(uint256) {
        uint256 totalLoanXPA = 0;
        for(uint256 i = 0; i < xpaAsset.length; i++) {
            totalLoanXPA = safeAdd(totalLoanXPA, safeDiv(safeMul(getLoanAmount(user_,xpaAsset[i]), 1 ether), getPrice(xpaAsset[i])));
        }
        if(fromAmountBooks[user_] > safeDiv(safeMul(totalLoanXPA, 1 ether), getHighestMortgageRate())){
            return safeSub(fromAmountBooks[user_], safeDiv(safeMul(totalLoanXPA, 1 ether), getHighestMortgageRate()));
        }else{
            return 0;
        }
    }
    
    // 取得用戶可借貸 XPA Assets 最大額度, user: 指定用戶
    /*function getUsableAmount(
        address user_,
        address token_
    ) 
        public
        view
    returns(uint256) {
        uint256 amount = safeDiv(safeMul(fromAmountBooks[user_], getPrice(token_)), 1 ether);
        return safeDiv(safeMul(amount, getHighestMortgageRate()), 1 ether);
    }*/
    
    // 取得用戶已借貸 XPA Assets 數量, user: 指定用戶
    function getLoanAmount(
        address user_,
        address token_
    ) 
        public
        view
    returns(uint256) {
        return toAmountBooks[user_][token_];
    }
    
    // 取得用戶剩餘可借貸 XPA Assets 額度, user: 指定用戶
    function getRemainingAmount(
        address user_,
        address token_
    ) 
        public
        view
    returns(uint256) {
        uint256 amount = safeDiv(safeMul(getUsableXPA(user_), getPrice(token_)), 1 ether);
        return safeDiv(safeMul(amount, getHighestMortgageRate()), 1 ether);
    }
    
    function burnFundAccount(
        address token_,
        uint256 amount_
    )
        onlyOperator
        public
    {
        if(
            FundAccount(fundAccount).burn(token_, amount_)
        ){
            unPaidFundAccount[token_] = safeSub(unPaidFundAccount[token_], amount_);
        }
    }

    function transferProfit(
        uint256 token_,
        uint256 amount_
    )
        onlyOperator 
        public
    {
        if(amount_ > 0 && Token(token_).balanceOf(this) >= amount_){
            require(Token(token_).transfer(bank, amount_));
            profit = safeSub(profit,amount_);
        }
    }
        
    function setFeeRate(
        uint256 withDrawFeerate_,
        uint256 offsetFeerate_,
        uint256 forceOffsetBasicFeerate_,
        uint256 forceOffsetExecuteFeerate_,
        uint256 forceOffsetExtraFeerate_,
        uint256 forceOffsetExecuteMaxFee_
    )
        onlyOperator 
        public
    {
        require(withDrawFeerate_ < 0.05 ether);
        require(offsetFeerate_ < 0.05 ether);
        require(forceOffsetBasicFeerate_ < 0.05 ether);
        require(forceOffsetExecuteFeerate_ < 0.05 ether);
        require(forceOffsetExtraFeerate_ < 0.05 ether);
        withdrawFeeRate = withDrawFeerate_;
        offsetFeeRate = offsetFeerate_;
        forceOffsetBasicFeeRate = forceOffsetBasicFeerate_;
        forceOffsetExecuteFeeRate = forceOffsetExecuteFeerate_;
        forceOffsetExtraFeeRate = forceOffsetExtraFeerate_;
        forceOffsetExecuteMaxFee = forceOffsetExecuteMaxFee_;
    }

    function migrate(
        address newContract_
    )
        public
        onlyOwner
    {
        if(
            newXPAAssets == address(0) &&
            XPAAssets(newContract_).transferXPAAssetAndProfit(xpaAsset, profit) &&
            Token(XPA).transfer(newContract_, Token(XPA).balanceOf(this))
        ) {
            forceOff = true;
            powerStatus = false;
            newXPAAssets = newContract_;
            for(uint256 i = 0; i < xpaAsset.length; i++) {
                XPAAssets(newContract_).transferUnPaidFundAccount(xpaAsset[i], unPaidFundAccount[xpaAsset[i]]);
            }
            emit eMigrate(newContract_);
        }
    }
    
    function transferXPAAssetAndProfit(
        address[] xpaAsset_,
        uint256 profit_
    )
        public
        onlyOperator
    returns(bool) {
        xpaAsset = xpaAsset_;
        profit = profit_;
        return true;
    }
    
    function transferUnPaidFundAccount(
        address xpaAsset_,
        uint256 unPaidAmount_
    )
        public
        onlyOperator
    returns(bool) {
        unPaidFundAccount[xpaAsset_] = unPaidAmount_;
        return true;
    }
    
    function migratingAmountBooks(
        address user_,
        address newContract_
    )
        public
        onlyOperator
    {
        XPAAssets(newContract_).migrateAmountBooks(user_); 
    }
    
    function migrateAmountBooks(
        address user_
    )
        public
        onlyOperator 
    {
        require(msg.sender == oldXPAAssets);
        require(!migrateBooks[user_]);

        migrateBooks[user_] = true;
        fromAmountBooks[user_] = safeAdd(fromAmountBooks[user_],XPAAssets(oldXPAAssets).getFromAmountBooks(user_));
        forceOffsetBooks[user_] = XPAAssets(oldXPAAssets).getForceOffsetBooks(user_);
        for(uint256 i = 0; i < xpaAsset.length; i++) {
            toAmountBooks[user_][xpaAsset[i]] = safeAdd(toAmountBooks[user_][xpaAsset[i]], XPAAssets(oldXPAAssets).getLoanAmount(user_,xpaAsset[i]));
        }
        emit eMigrateAmount(user_);
    }
    
    function getFromAmountBooks(
        address user_
    )
        public
        view 
    returns(uint256) {
        return fromAmountBooks[user_];
    }
    
    function getForceOffsetBooks(
        address user_
    )
        public 
        view 
    returns(uint256) {
        return forceOffsetBooks[user_];
    }
}