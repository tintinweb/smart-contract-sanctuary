// This is ERC 2.0 Token&#39;s Trading Market, Decentralized Exchange Contract. 这是一个ERC20Token的去中心化交易所合同。
// 支持使用以太币买卖任意满足ERC20标准的Token。其具体使用流程请参见对应文档。
// by he.guanjun, email: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="533b367d377d377d203b323d133b3c273e323a3f7d303c3e">[email&#160;protected]</a>
// 2017-09-28 update
// TODO：
//  1,每一个function，都应该写日志（事件），而且最好不要共用事件。暂不处理。
//  2,Token白名单，更安全，但是需要owner维护，更麻烦。暂不处理。
// 强调：在任何时候调用外部合约的function，都要仔细检查外部合约再调用本合约的任意function是否产生异常后果！预防The DAO事件的错误！作为一种编码习惯，所有的调用外部合约function的地方都要标记出来！
// 处理的方式包括：减少先记账，后转钱；增加先转钱，后记账；输入检查；msg.sender,tx.origin检查；锁定；等。暂时采用锁定，可以极大简化测试路径。


pragma solidity ^0.4.11; 

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
interface Erc20Token {
      function totalSupply() constant returns (uint256 totalSupply);
      function balanceOf(address _owner) constant returns (uint256 balance);

      function transfer(address _to, uint256 _value) returns (bool success);

      function allowance(address _owner, address _spender) constant returns (uint256 remaining);
      function approve(address _spender, uint256 _value) returns (bool success);
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);

      function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
}

contract Base { 
    uint createTime = now;

    address public owner;
    
    function Base() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner)  public  onlyOwner {
        owner = _newOwner;
    }

    mapping (address => uint256) public userEtherOf;   

    function userRefund() public   {
        //require(msg.sender == tx.origin);     //TODO：
         _userRefund(msg.sender, msg.sender);
    }

    function userRefundTo(address _to) public   {
        //require(msg.sender == tx.origin);     //TODO：
        _userRefund(msg.sender, _to);
    }

    function _userRefund(address _from,  address _to) private {
        require (_to != 0x0);  
        lock();
        uint256 amount = userEtherOf[_from];
        if(amount > 0){
            userEtherOf[_from] -= amount;
            _to.transfer(amount);               //防范外部调用，特别是和支付（买Token）联合调用就有风险， 2017-09-27
        }
        unLock();
    }

    bool public globalLocked = false;      //锁定，全局，外部智能调用一个方法！ 2017-10-02

    function lock() internal {              //在 lock 和 unLock 之间，最好不要写有 require 之类会抛出异常的语句，而是在 lock 之前全面检查。
        require(!globalLocked);
        globalLocked = true;
    }

    function unLock() internal {
        require(globalLocked);
        globalLocked = false;
    }    

    //event OnSetLock(bool indexed _oldGlobalLocked, bool indexed _newGlobalLocked);

    function setLock()  public onlyOwner{       //sometime, globalLocked always is true???
        //bool _oldGlobalLocked = globalLocked;
        globalLocked = false;     
        //OnSetLock(_oldGlobalLocked, false);   
    }
}

//执行 interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract  Erc20TokenMarket is Base         //for exchange token
{
    function Erc20TokenMarket()  Base ()  {
    }

    mapping (address => uint) public badTokenOf;      //Token 黑名单！

    event OnBadTokenChanged(address indexed _tokenAddress, uint indexed _badNum);

    function addBadToken(address _tokenAddress) public onlyOwner{
        badTokenOf[_tokenAddress] += 1;
        OnBadTokenChanged(_tokenAddress, badTokenOf[_tokenAddress]);
    }

    function removeBadToken(address _tokenAddress) public onlyOwner{
        badTokenOf[_tokenAddress] = 0;
        OnBadTokenChanged(_tokenAddress, badTokenOf[_tokenAddress]);
    }

    function isBadToken(address _tokenAddress) private returns(bool _result) {
        return badTokenOf[_tokenAddress] > 0;        
    }

    uint256 public sellerGuaranteeEther = 0 ether;      //保证金，最大惩罚金额。

    function setSellerGuarantee(uint256 _gurateeEther) public onlyOwner {
        require(now - createTime > 1 years);        //至少一年后才启用保证金
        require(_gurateeEther <= 0.1 ether);        //不能太高，表示一下，能够拒绝恶意者就好。
        sellerGuaranteeEther = _gurateeEther;        
    }    

    function checkSellerGuarantee(address _seller) private returns (bool _result){
        return userEtherOf[_seller] >= sellerGuaranteeEther;            //保证金不强制冻结，如果保证金不足，将无法完成交易（买和卖）。
    }

    function userRefundWithoutGuaranteeEther() public   {       //退款，但是保留保证金
        lock();

        if (userEtherOf[msg.sender] > 0 && userEtherOf[msg.sender] >= sellerGuaranteeEther){
            uint256 amount = userEtherOf[msg.sender] - sellerGuaranteeEther;
            userEtherOf[msg.sender] -= amount;
            msg.sender.transfer(amount);            //防范外部调用 2017-09-28
        }

        unLock();
    }

    struct SellingToken{                //TokenInfo，包括：当前金额，已卖总金额，出售价格，是否出售，出售时间限制，转入总金额，转入总金额， TODO：
        uint256    thisAmount;          //currentAmount，当前金额，可以出售的金额,转入到 this 地址的金额。
        uint256    soldoutAmount;       //有可能溢出，恶意合同能做到这点，但不影响合约执行，暂不处理。 2017-09-27
        uint256    price;      
        bool       cancel;              //正在出售，是否出售
        uint       lineTime;            //出售时间限制
    }    

    mapping (address => mapping(address => SellingToken)) public userSellingTokenOf;    //销售者，代币地址，销售信息

    //event OnReceiveApproval(address indexed _tokenAddress, address _seller, uint indexed _sellingAmount, uint256 indexed _price, uint _lineTime, bool _cancel);
    event OnSetSellingToken(address indexed _tokenAddress, address _seller, uint indexed _sellingAmount, uint256 indexed _price, uint _lineTime, bool _cancel);
    //event OnCancelSellingToken(address indexed _tokenAddress, address _seller, uint indexed _sellingAmount, uint256 indexed _price, uint _lineTime, bool _cancel);

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        _extraData;
        _value;
        require(_from != 0x0);
        require(_token != 0x0);
        //require(_value > 0);              //no
        require(_token == msg.sender && msg.sender != tx.origin);   //防范攻击，防止被发送大量的垃圾信息！就算攻击，也要写一个智能合约来攻击！
        require(!isBadToken(msg.sender));                           //黑名单判断，主要防范垃圾信息，

        lock();

        Erc20Token token = Erc20Token(msg.sender);
        var sellingAmount = token.allowance(_from, this);   //_from == tx.origin != msg.sender = _token , _from == tx.origin 不一定，但一般如此，多重签名钱包就不是。

        //var sa = token.balanceOf(_from);        //检查用户实际拥有的Token，但用户拥有的Token随时可能变化，所以还是无法检查，只能在购买的时候检查。
        //if (sa < sellingAmount){
        //    sellingAmount = sa;
        //}

        //require(sellingAmount > 0);       //no 

        var st = userSellingTokenOf[_from][_token];                 //用户(卖家)地址， Token地址，
        st.thisAmount = sellingAmount;
        //st.price = 0;
        //st.lineTime = 0;
        //st.cancel = true;      
        OnSetSellingToken(_token, _from, sellingAmount, st.price, st.lineTime, st.cancel);
        unLock();
    }
      
    function setSellingToken(address _tokenAddress,  uint256 _price, uint _lineTime) public returns(uint256  _sellingAmount) {
        require(_tokenAddress != 0x0);
        require(_price > 0);
        require(_lineTime > now);
        require(!isBadToken(_tokenAddress));                //黑名单
        require(checkSellerGuarantee(msg.sender));          //保证金，
        lock();

        Erc20Token token = Erc20Token(_tokenAddress);
        _sellingAmount = token.allowance(msg.sender,this);      //防范外部调用， 2017-09-27

        //var sa = token.balanceOf(_from);        //检查用户实际拥有的Token
        //if (sa < _sellingAmount){
        //    _sellingAmount = sa;
        //}

        var st = userSellingTokenOf[msg.sender][_tokenAddress];
        st.thisAmount = _sellingAmount;
        st.price = _price;
        st.lineTime = _lineTime;
        st.cancel = false;

        OnSetSellingToken(_tokenAddress, msg.sender, _sellingAmount, _price, _lineTime, st.cancel);
        unLock();
    }   

    function cancelSellingToken(address _tokenAddress)  public{     // returns(bool _result) delete , 2017-09-27
        require(_tokenAddress != 0x0);    
        
        lock();

        var st = userSellingTokenOf[msg.sender][_tokenAddress];
        st.cancel = true;
        
        Erc20Token token = Erc20Token(_tokenAddress);
        var sellingAmount = token.allowance(msg.sender,this);   //防范外部调用， 2017-09-27
        st.thisAmount = sellingAmount;
        
        OnSetSellingToken(_tokenAddress, msg.sender, sellingAmount, st.price, st.lineTime, st.cancel);

        unLock();
    }    

    event OnBuyToken(address _buyer, uint _buyerRamianEtherAmount, address indexed _seller, address indexed _tokenAddress, uint256  _transTokenAmount, uint256 indexed _tokenPrice, uint256 _sellerRamianTokenAmount);
    //event OnBuyToken(address _buyer, address indexed _seller, address indexed _tokenAddress, uint256  _transTokenAmount, uint256 indexed _tokenPrice, uint256 _sellerRamianTokenAmount);

    function buyTokenFrom(address _seller, address _tokenAddress, uint256 _buyerTokenPrice) public payable returns(bool _result) {   
        require(_seller != 0x0);
        require(_tokenAddress != 0x0);
        require(_buyerTokenPrice > 0);

        lock();              //加锁  //拒绝二次进入！   //防范外部调用，某些特殊合约可能无法成功执行此方法，但为了安全就这么简单处理。 2017-09-27
        
        _result = false;

        userEtherOf[msg.sender] += msg.value;
        if (userEtherOf[msg.sender] == 0){
            unLock();
            return; 
        }

        Erc20Token token = Erc20Token(_tokenAddress);
        var sellingAmount = token.allowance(_seller, this);     //卖家， _spender   
        var st = userSellingTokenOf[_seller][_tokenAddress];    //卖家，Token

        var sa = token.balanceOf(_seller);        //检查用户实际拥有的Token，但用户拥有的Token随时可能变化，只能在购买的时候检查。
        bool bigger = false;
        if (sa < sellingAmount){                  //一种策略，卖家交定金，如果发现出现这种情况，定金没收，owner 和 买家平分定金。
            sellingAmount = sa;
            bigger = true;
        }

        if (st.price > 0 && st.lineTime > now && sellingAmount > 0 && !st.cancel){
            if(_buyerTokenPrice < st.price){                                                //price maybe be changed!
                OnBuyToken(msg.sender, userEtherOf[msg.sender], _seller, _tokenAddress, 0, st.price, sellingAmount);
                unLock();
                return;
            }

            uint256 canTokenAmount =  userEtherOf[msg.sender]  / st.price;      
            if(canTokenAmount > 0 && canTokenAmount *  st.price >  userEtherOf[msg.sender]){
                 canTokenAmount -= 1;
            }
            if(canTokenAmount == 0){
                OnBuyToken(msg.sender, userEtherOf[msg.sender], _seller, _tokenAddress, 0, st.price, sellingAmount);
                unLock();
                return;
            }
            if (canTokenAmount > sellingAmount){
                canTokenAmount = sellingAmount; 
            }
            
            var etherAmount =  canTokenAmount *  st.price;      //这里不存在溢出，因为 canTokenAmount =  userEtherOf[msg.sender]  / st.price;      2017-09-27
            userEtherOf[msg.sender] -= etherAmount;                     //减少记账金额
            //require(userEtherOf[msg.sender] >= 0);                      //冗余判断: 必然，uint数据类型。2017-09-27 delete

            token.transferFrom(_seller, msg.sender, canTokenAmount);    //转代币, ，预防类似 the dao 潜在的风险       
            if(userEtherOf[_seller]  >= sellerGuaranteeEther){          //大于等于最低保证金，这样鼓励卖家存留一点保证金。            
                _seller.transfer(etherAmount);                          //转以太币，预防类似 the dao 潜在的风险      
            }   
            else{                                                       //小于最低保证金
                userEtherOf[_seller] +=  etherAmount;                   //由推改为拖，更安全！ //这里不存在溢出，2017-09-27
            }      
            st.soldoutAmount += canTokenAmount;                         //更新销售额     //可能溢出，只有恶意调用才可能出现溢出，溢出也不影响交易，不处理。 2017-09-27
            st.thisAmount = token.allowance(_seller, this);             //更新可销售代币数量

            OnBuyToken(msg.sender, userEtherOf[msg.sender], _seller, _tokenAddress, canTokenAmount, st.price, st.thisAmount);     
            _result = true;
        }
        else{
            _result = false;
            OnBuyToken(msg.sender, userEtherOf[msg.sender], _seller, _tokenAddress, 0, st.price, sellingAmount);
        }

        if (bigger && sellerGuaranteeEther > 0){                                  //虚报可出售Token，要惩罚卖家：只要卖家账上有钱就被扣保证金。
            var pf = sellerGuaranteeEther;
            if (pf > userEtherOf[_seller]){
                pf = userEtherOf[_seller];
            }
            if(pf > 0){
                userEtherOf[owner] +=  pf / 2;           
                userEtherOf[msg.sender] +=   pf - pf / 2;
                userEtherOf[_seller] -= pf;
            }
        }
        
        unLock();
        return;
    }

    function () public payable {
        if(msg.value > 0){          //来者不拒，比抛出异常或许更合适。
            userEtherOf[msg.sender] += msg.value;
        }
    }

    function disToken(address _token) public {          //处理捡到的各种Token，也就是别人误操作，直接给 this 发送了 token 。由调用者和Owner平分。因为这种误操作导致的丢失过去一年的损失达到几十万美元。
        lock();

        Erc20Token token = Erc20Token(_token);  //目前只处理 ERC20 Token，那些非标准Token就会永久丢失！
        var amount = token.balanceOf(this);     //有一定风险，2017-09-27
        if (amount > 0){
            var a1 = amount / 2;
            if (a1 > 0){
                token.transfer(msg.sender, a1); //有一定风险，2017-09-27
            }
            var a2 = amount - a1;
            if (a2 > 0){
                token.transfer(owner, a2);      //有一定风险，2017-09-27
            }
        }

        unLock();
    }
}