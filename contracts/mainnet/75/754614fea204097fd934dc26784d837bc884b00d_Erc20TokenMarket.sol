// This is ERC 2.0 Token&#39;s Trading Market, Decentralized Exchange. 
// by he.guanjun, email: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="99f1fcb7fdb7fdb7eaf1f8f7d9f1f6edf4f8f0f5b7faf6f4">[email&#160;protected]</a>
// 2017-09-27
// TODO：
//  1,每一个function，都应该写日志（事件），而且最好不要公用事件。暂不处理。
//  2,Token白名单，更安全，但是需要owner维护，更麻烦。暂不处理。


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
         _userRefund(msg.sender, msg.sender);
    }

    function userRefundTo(address _to) public   {
        _userRefund(msg.sender, _to);
    }

    function _userRefund(address _from,  address _to) private {
        require (_to != 0x0);  
        uint256 amount = userEtherOf[_from];
        if(amount > 0){
            userEtherOf[_from] -= amount;
            _to.transfer(amount);               //防范外部调用，特别是和支付（买Token）联合调用就有风险， 2017-09-27
        }
    }

}

//执行 interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract  Erc20TokenMarket is Base         //for exchange token
{
    function Erc20TokenMarket()  Base ()  {
    }

    mapping (address => uint) public BadTokenOf;      //Token 黑名单！

    function addBadToken(address _tokenAddress) public onlyOwner{
        BadTokenOf[_tokenAddress] += 1;
    }

    function removeBadToken(address _tokenAddress) public onlyOwner{
        BadTokenOf[_tokenAddress] = 0;
    }

    function isBadToken(address _tokenAddress) private returns(bool _result) {
        return BadTokenOf[_tokenAddress] > 0;        
    }

    bool public hasSellerGuarantee = false;
    
    uint256 public sellerGuaranteeEther = 0 ether;      //保证金，最大惩罚金额。

    function setSellerGuarantee(bool _has, uint256 _gurateeEther) public onlyOwner {
        require(now - createTime > 1 years);    //至少一年后才启用保证金
        require(_gurateeEther < 0.1 ether);     //不能太高，表示一下，能够拒绝恶意者就好。
        hasSellerGuarantee = _has;
        sellerGuaranteeEther = _gurateeEther;        
    }    

    function checkSellerGuarantee(address _seller) private returns (bool _result){
        if (hasSellerGuarantee){
            return userEtherOf[_seller] >= sellerGuaranteeEther;            //保证金不强制冻结，如果保证金不足，将无法完成交易（买和卖）。
        }
        return true;
    }

    function userRefundWithoutGuaranteeEther() public   {       //退款，但是保留保证金
        if (userEtherOf[msg.sender] >= sellerGuaranteeEther){
            uint256 amount = userEtherOf[msg.sender] - sellerGuaranteeEther;
            userEtherOf[msg.sender] -= amount;
            msg.sender.transfer(amount); 
        }
    }

    struct SellingToken{                //TokenInfo，包括：当前金额，已卖总金额，出售价格，是否出售，出售时间限制，转入总金额，转入总金额， TODO：
        uint256    thisAmount;          //currentAmount，当前金额，可以出售的金额,转入到 this 地址的金额。
        uint256    soldoutAmount;       //有可能溢出，恶意合同能做到这点，但不影响合约执行，暂不处理。 2017-09-27
        uint256    price;      
        bool       cancel;              //正在出售，是否出售
        uint       lineTime;            //出售时间限制
    }    

    mapping (address => mapping(address => SellingToken)) public userSellingTokenOf;    //销售者，代币地址，销售信息

    event OnSetSellingToken(address indexed _tokenAddress, address _seller, uint indexed _sellingAmount, uint256 indexed _price, uint _lineTime, bool _cancel);

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        _extraData;
        _value;
        require(_from != 0x0);
        require(_token != 0x0);
        //require(_value > 0);              //no
        require(_token == msg.sender && msg.sender != tx.origin);   //防范攻击，防止被发送大量的垃圾信息！就算攻击，也要写一个智能合约来攻击！
        require(!isBadToken(msg.sender));                           //黑名单判断，主要防范垃圾信息，

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
    }
      
    function setSellingToken(address _tokenAddress,  uint256 _price, uint _lineTime) public returns(uint256  _sellingAmount) {
        require(_tokenAddress != 0x0);
        require(_price > 0);
        require(_lineTime > now);
        require(!isBadToken(msg.sender));              //黑名单
        require(checkSellerGuarantee(msg.sender));     //保证金，

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
    }   

    function cancelSellingToken(address _tokenAddress)  public{ // returns(bool _result) delete , 2017-09-27
        require(_tokenAddress != 0x0);    
        //_result = false;       

        var st = userSellingTokenOf[msg.sender][_tokenAddress];
        st.cancel = true;
        
        Erc20Token token = Erc20Token(_tokenAddress);
        var sellingAmount = token.allowance(msg.sender,this);   //防范外部调用， 2017-09-27
        st.thisAmount = sellingAmount;
        
        OnSetSellingToken(_tokenAddress, msg.sender, sellingAmount, st.price, st.lineTime, st.cancel);
    }    

    event OnBuyToken(uint __ramianBuyerEtherAmount, address _buyer, address indexed _seller, address indexed _tokenAddress, uint256  _transAmount, uint256 indexed _tokenPrice, uint256 _ramianTokenAmount);

    bool public _isBuying = false;              //lock 

    function setIsBuying()  public onlyOwner{   //sometime, _isBuying always is true???
        _isBuying = false;        
    }

    function buyTokenFrom(address _seller, address _tokenAddress, uint256 _buyerTokenPrice) public payable returns(bool _result) {   
        require(_seller != 0x0);
        require(_tokenAddress != 0x0);
        require(_buyerTokenPrice > 0);

        require(!_isBuying);            //拒绝二次进入！   //防范外部调用，某些特殊合约可能无法成功执行此方法，但为了安全就这么简单处理。 2017-09-27
        _isBuying = true;               //加锁

        userEtherOf[msg.sender] += msg.value;
        if (userEtherOf[msg.sender] == 0){
            _isBuying = false;
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
                OnBuyToken(userEtherOf[msg.sender], msg.sender, _seller, _tokenAddress, 0, _buyerTokenPrice, sellingAmount);
                _result = false;
                _isBuying = false;
                return;
            }

            uint256 canTokenAmount =  userEtherOf[msg.sender]  / st.price;      
            if(canTokenAmount > 0 && canTokenAmount *  st.price >  userEtherOf[msg.sender]){
                 canTokenAmount -= 1;
            }
            if(canTokenAmount == 0){
                OnBuyToken(userEtherOf[msg.sender], msg.sender, _seller, _tokenAddress, 0, st.price, sellingAmount);
                _result = false;
                _isBuying = false;
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

            OnBuyToken(userEtherOf[msg.sender], msg.sender, _seller, _tokenAddress, canTokenAmount, st.price, st.thisAmount);     
            _result = true;
        }
        else{
            _result = false;
            OnBuyToken(userEtherOf[msg.sender], msg.sender, _seller, _tokenAddress, 0, _buyerTokenPrice, sellingAmount);
        }

        if (bigger && sellerGuaranteeEther > 0){                                  //虚报可出售Token，要惩罚卖家
            if(checkSellerGuarantee(_seller)) {          //虚报可出售Token，把此用户的保证金分了, owner 和 buyer 均分，然后继续处理；否则不能交易。
                userEtherOf[owner] +=  sellerGuaranteeEther / 2; 
                userEtherOf[msg.sender] +=   sellerGuaranteeEther - sellerGuaranteeEther / 2;   //防止不能被2整除的情况。  2017-09-27
                userEtherOf[_seller] -= sellerGuaranteeEther;
            }
            else if (userEtherOf[_seller] > 0)     //Buyer可以恶意攻击，明知卖家保证金不足，就每次小金额的购买代币，让卖家账上始终小于保证金金额，这种情况其实买家也不划算，毕竟gas蛮贵,而保证金最高才0.1 ether，暂不处理！
            {
                userEtherOf[owner] +=  userEtherOf[_seller] / 2; 
                userEtherOf[msg.sender] +=   userEtherOf[_seller] - userEtherOf[_seller] / 2;
                userEtherOf[_seller] = 0;
            }
        }
        
        _isBuying = false;          //解锁
        return;
    }

    function () public payable {
        if(msg.value > 0){          //来者不拒，比抛出异常或许更合适。
            userEtherOf[msg.sender] += msg.value;
        }
    }

    bool private isDisTokening = false;     //add 2017-09-27

    function disToken(address _token) public {          //处理捡到的各种Token，也就是别人误操作，直接给 this 发送了 token 。由调用者和Owner平分。因为这种误操作导致的丢失过去一年的损失达到几十万美元。
        require(!isDisTokening);            //拒绝二次进入！ 2017-09-27
        isDisTokening = true;               //加锁 2017-09-27

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
        isDisTokening = false;
    }

}