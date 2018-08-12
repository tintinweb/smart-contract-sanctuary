pragma solidity ^0.4.11;


contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
}

// contract ERC20 {
//     function totalSupply() constant returns (uint supply);
//     function balanceOf( address who ) constant returns (uint value);
//     function allowance( address owner, address spender ) constant returns (uint _allowance);

//     function transfer( address to, uint value) returns (bool ok);
//     function transferFrom( address from, address to, uint value) returns (bool ok);
//     function approve( address spender, uint value ) returns (bool ok);

//     event Transfer( address indexed from, address indexed to, uint value);
//     event Approval( address indexed owner, address indexed spender, uint value);
// }

//https://github.com/ethereum/ethereum-org/blob/master/solidity/token-erc20.sol
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
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
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

contract Erc20Dist is SafeMath {
    TokenERC20  public  _erc20token; //被操作的erc20代币

    address public _ownerDist;// 这个合约最高权限人，开始是创建者，可以移交给他人
    uint256 public _distDay;//发布时间
    uint256 public _mode = 0;//模型是1表示使用模式1，2表示使用模式2
    uint256 public _lockAllAmount;//锁仓的总量

    struct Detail{//发放情况详情结构体声明
        address founder;//创始人地址
        uint256 lockDay;//锁仓时间
        uint256 lockPercent;//锁仓百分比数（0到100之间）
        uint256 distAmount;//总分配数量
        uint256 lockAmount;//锁住的代币总量
        uint256 initAmount;//初始款的代币量
        uint256 distRate;//锁仓解锁后每天分配代币百分比数（按锁住的总额算，0到100之间）
        uint256 oneDayTransferAmount;//锁仓解锁后每天应发放的代币数量
        uint256 transferedAmount;//已转账代币数量
        uint256 lastTransferDay;//最后一笔代币分配的时间
        bool isFinish;// 是否本人都发放完成
        bool isCancelDist;//是否同意撤销发行
    }
    Detail private detail = Detail(address(0),0,0,0,0,0,0,0,0,0, false, false);//中间变量初始化，用来在函数中临时承接计算结果，以便传送给_details
    Detail[] public _details;//发放情况详情列表,并初始化为空值
	uint256 public _detailsLength = 0;//发放详情长度

    bool public _fDist = false;// 是否已经发布过的标识符号
    bool public _fConfig = false;// 是否已经配置过的标识符号
    bool public _fFinish = false;// 是否所有人都发放完成
    bool public _fCancelDist = false;// 是否撤销发行
    
    function Erc20Dist() public {
        _ownerDist = msg.sender; // 默认创建者为权限最高人
    }

    function () public{}//callback函数，由于合约没有eth价值传入，所以没有什么安全问题

    // 设置合约所有者
    function setOwner(address owner_) public {
        require (msg.sender == _ownerDist, "you must _ownerDist");// 必须原来所有者授权
        require(_fDist == false, "not dist"); // 必须还没开始发布
        require(_fConfig == false, "not config");// 必须还没配置过
        _ownerDist = owner_;
    }
    //设置操作代币函数
    function setErc20(TokenERC20  erc20Token) public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(address(_erc20token) == address(0),"you have set erc20Token");//必须之前没有设置过
        require(erc20Token.balanceOf(address(this)) > 0, "this contract must own tokens");
        _erc20token = erc20Token;//在全局设置erc20代币
        _lockAllAmount = erc20Token.balanceOf(address(this));
    }

    // 撤销发行，必须所有参与人同意，才能撤销发行
    function cancelDist() public {
        require(_fDist == true, "must dist"); // 必须发布
        require(_fCancelDist == false, "must not cancel dist");

        // 循环判断是否
        for(uint256 i=0;i<_details.length;i++){
            // 判断是否发行者
            if ( _details[i].founder == msg.sender ) {
                // 设置标志
                _details[i].isCancelDist = true;
                break;
            }
        }
        // 更新状态
        updateCancelDistFlag();
        if (_fCancelDist == true) {
            require(_erc20token.balanceOf(address(this)) > 0, "must have balance");
            // 返回所有代币给最高权限人
            _erc20token.transfer(
                _ownerDist, 
                _erc20token.balanceOf(address(this))
            );
        }
    }

    // 更新是否撤销发行标志
    function updateCancelDistFlag() private {
        bool allCancelDist = true;
        for(uint256 i=0; i<_details.length; i++){
            // 判断有没有人没撤销
            if (_details[i].isCancelDist == false) {
                allCancelDist = false;
                break;
            }
        }
        // 更新合约完成标志
        _fCancelDist = allCancelDist;
    }

    // 还没调用发行情况下，返还所有代币，到最高权限账号，并且清除配置
    function clearConfig() public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(_fDist == false, "not dist"); // 必须还没开始发布
        require(address(_erc20token) != address(0),"you must set erc20Token");//必须之前设置过
        require(_erc20token.balanceOf(address(this)) > 0, "must have balance");
        // 返回所有代币给最高权限人
        _erc20token.transfer(
            msg.sender, 
            _erc20token.balanceOf(address(this))
        );
        // 清空变量
        _lockAllAmount = 0;
        TokenERC20  nullErc20token;
        _erc20token = nullErc20token;
        Detail[] nullDetails;
        _details = nullDetails;
        _detailsLength = 0;
        _mode = 0;
        _fConfig = false;
    }

    // 客户之前多转到合约的币，可以通过这个接口，提取回最高权限人账号，但必须在合约执行完成之后
    function withDraw() public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(_fFinish == true, "dist must be finished"); // 合约必须执行完毕
        require(address(_erc20token) != address(0),"you must set erc20Token");//必须之前设置过
        require(_erc20token.balanceOf(address(this)) > 0, "must have balance");
        // 返回所有代币给最高权限人
        _erc20token.transfer(
            _ownerDist, 
            _erc20token.balanceOf(address(this))
        );
    }

    //配置相关创始人及代币发放、锁仓信息等相关情况的函数。auth认证，必须是合约持有人才能进行该操作
    function configContract(uint256 mode,address[] founders,uint256[] distWad18Amounts,uint256[] lockPercents,uint256[] lockDays,uint256[] distRates) public {
    //函数变量说明：founders（创始人地址列表），
    //distWad18Amounts（总发放数量列表（不输入18位小数位）），
    //lockPercents（锁仓百分比列表（值在0到100之间）），
    //lockDays（锁仓天数列表）,distRates（每天发放数占锁仓总数的万分比数列表（值在0到10000之间））
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(mode==1||mode==2,"there is only mode 1 or 2");//只有模式1和2两种申领余款方式
        _mode = mode;//将申领方式注册到全局
        require(_fConfig == false,"you have configured it already");//必须还未配置过
        require(address(_erc20token) != address(0), "you must setErc20 first");//必须已经设置好被操作erc20代币
        require(founders.length!=0,"array length can not be zero");//创始人列表不能为空
        require(founders.length==distWad18Amounts.length,"founders length dismatch distWad18Amounts length");//创始人列表长度必须等于发放数量列表长度
        require(distWad18Amounts.length==lockPercents.length,"distWad18Amounts length dismatch lockPercents length");//发放数量列表长度必须等于锁仓百分比列表长度
        require(lockPercents.length==lockDays.length,"lockPercents length dismatch lockDays length");//锁仓百分比列表长度必须等于锁仓天数列表长度
        require(lockDays.length==distRates.length,"lockDays length dismatch distRates length");//锁仓百分比列表长度必须等于每日发放比率列表长度

        //遍历
        for(uint256 i=0;i<founders.length;i++){
            require(distWad18Amounts[i]!=0,"dist token amount can not be zero");//确保发放数量不为0
            for(uint256 j=0;j<i;j++){
                require(founders[i]!=founders[j],"you could not give the same address of founders");//必须确保创始人中没有地址相同的
            }
        }
        

        //以下为循环中服务全局变量的中间临时变量
        uint256 totalAmount = 0;//发放代币总量
        uint256 distAmount = 0;//给当前创始人发放代币量（带18位精度）
        uint256 oneDayTransferAmount = 0;//解锁后每天应发放的数量（将在后续进行计算）
        uint256 lockAmount = 0;//当前创始人锁住的代币量
        uint256 initAmount = 0;//当前创始人初始款代币量

        //遍历
        for(uint256 k=0;k<lockPercents.length;k++){
            require(lockPercents[k]<=100,"lockPercents unit must <= 100");//锁仓百分比数必须小于等于100
            require(distRates[k]<=10000,"distRates unit must <= 10000");//发放万分比数必须小于等于10000
            distAmount = mul(distWad18Amounts[k],10**18);//给当前创始人发放代币量（带18位精度）
            totalAmount = add(totalAmount,distAmount);//发放总量累加
            lockAmount = div(mul(lockPercents[k],distAmount),100);//锁住的代币数量
            initAmount = sub(distAmount, lockAmount);//初始款的代币数量
            oneDayTransferAmount = div(mul(distRates[k],lockAmount),10000);//解锁后每天应发放的数量

            //下面为中间变量detail的9个成员赋值
            detail.founder = founders[k];
            detail.lockDay = lockDays[k];
            detail.lockPercent = lockPercents[k];
            detail.distRate = distRates[k];
            detail.distAmount = distAmount;
            detail.lockAmount = lockAmount;
            detail.initAmount = initAmount;
            detail.oneDayTransferAmount = oneDayTransferAmount;
            detail.transferedAmount = 0;//初始还未开始发放，所以已分配数量为0
            detail.lastTransferDay = 0;//初始还未开始发放，最后的发放日设为0
            detail.isFinish = false;
            detail.isCancelDist = false;
            //将赋好的中间信息压入全局信息列表_details
            _details.push(detail);
        }
        require(totalAmount <= _lockAllAmount, "distributed total amount should be equal lock amount");// 发行总量应该等于锁仓总量
        require(totalAmount <= _erc20token.totalSupply(),"distributed total amount should be less than token totalSupply");//发放的代币总量必须小于总代币量
		_detailsLength = _details.length;
        _fConfig = true;//配置完毕，将配置完成标识符设为真
        _fFinish = false;// 默认没发放完成
        _fCancelDist = false;// 撤销发行清空
    }

    //开始发放函数，将未锁仓头款发放给个创始人，如果有锁仓天数为0的，将锁款的解锁后的头天代币也一同发放。auth认证，必须是合约持有人才能进行该操作
    function startDistribute() public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(_fDist == false,"you have distributed erc20token already");//必须还未初始发放过
        require(_details.length != 0,"you have not configured");//必须还未配置过
        _distDay = today();//将当前区块链系统时间记录为发放时间
        uint256 initDistAmount=0;//以下循环中使用的当前创始人“初始发放代币量”临时变量

        for(uint256 i=0;i<_details.length;i++){
            initDistAmount = _details[i].initAmount;//首发量

            if(_details[i].lockDay==0){//如果当前创始人锁仓天数为0
                initDistAmount = add(initDistAmount, _details[i].oneDayTransferAmount);//初始发放代币量为首发量+一天的发放量
            }
            _erc20token.transfer(
                _details[i].founder,
               initDistAmount
            );
            _details[i].transferedAmount = initDistAmount;//已发放数量在全局细节中进行登记
            _details[i].lastTransferDay =_distDay;//最新一次发放日期在全局细节中进行登记
        }

        _fDist = true;//已初始发放标识符设为真
        updateFinishFlag();// 更新下完成标志
    }

    // 更新是否发行完成标志
    function updateFinishFlag() private {
        //
        bool allFinish = true;
        for(uint256 i=0; i<_details.length; i++){
            // 不需要锁仓的，直接设置完成
            if (_details[i].lockPercent == 0) {
                _details[i].isFinish = true;
                continue;
            }
            // 有锁仓的，发行数量等于解锁数量，也设置完成
            if (_details[i].distAmount == _details[i].transferedAmount) {
                _details[i].isFinish = true;
                continue;
            }
            allFinish = false;
        }
        // 更新合约完成标志
        _fFinish = allFinish;
    }

    //模式1：任意人可调用该函数申领当天应发放额
    function applyForTokenOneDay() public{
        require(_mode == 1,"this function can be called only when _mode==1");//模式1下可调用
        require(_distDay != 0,"you haven&#39;t distributed");//必须已经发布初始款了
        require(_fFinish == false, "not finish");//必须合约还没执行完
        require(_fCancelDist == false, "must not cancel dist");
        uint256 daysAfterDist;//距离初始金发放时间
        uint256 tday = today();//调用该函数时系统当前时间
      
        for(uint256 i=0;i<_details.length;i++){
            // 对于已经完成的可以pass
            if (_details[i].isFinish == true) {
                continue;
            }

            require(tday!=_details[i].lastTransferDay,"you have applied for todays token");//必须今天还未申领
            daysAfterDist = sub(tday,_distDay);//计算距离初始金发放时间天数
            if(daysAfterDist >= _details[i].lockDay){//距离发放日天数要大于等于锁仓天数
                if(add(_details[i].transferedAmount, _details[i].oneDayTransferAmount) <= _details[i].distAmount){
                //如果当前创始人剩余的发放数量大于等于每天应发放数量，则将当天应发放数量发给他
                    _erc20token.transfer(
                        _details[i].founder,
                        _details[i].oneDayTransferAmount
                    );
                    //已发放数量在全局细节中进行登记更新
                    _details[i].transferedAmount = add(_details[i].transferedAmount, _details[i].oneDayTransferAmount);
                }
                else if(_details[i].transferedAmount < _details[i].distAmount){
                //否则，如果已发放数量未达到锁仓应发总量，则将当前创始人剩余的应发放代币都发放给他
                    _erc20token.transfer(
                        _details[i].founder,
                        sub( _details[i].distAmount, _details[i].transferedAmount)
                    );
                    //已发放数量在全局细节中进行登记更新
                    _details[i].transferedAmount = _details[i].distAmount;
                }
                //最新一次发放日期在全局细节中进行登记更新
                _details[i].lastTransferDay = tday;
            }
        }   
        // 更新下完成标志
        updateFinishFlag();
    }

    ///模式2：任意人可调用该函数补领到当前时间应该拥有但未发的代币
    function applyForToken() public {
        require(_mode == 2,"this function can be called only when _mode==2");//模式2下可调用
        require(_distDay != 0,"you haven&#39;t distributed");//必须已经发布初始款了
        require(_fFinish == false, "not finish");//必须合约还没执行完
        require(_fCancelDist == false, "must not cancel dist");
        uint256 daysAfterDist;//距离初始金发放时间
        uint256 expectAmount;//下面循环中当前创始人到今天为止应该被发放的数量
        uint256 tday = today();//调用该函数时系统当前时间
        uint256 expectReleaseTimesNoLimit = 0;//解锁后到今天为止应该放的尾款次数(不考虑已放完款的情况)

        for(uint256 i=0;i<_details.length;i++){
            // 对于已经完成的可以pass
            if (_details[i].isFinish == true) {
                continue;
            }
            //必须今天还未申领
            require(tday!=_details[i].lastTransferDay,"you have applied for todays token");
            daysAfterDist = sub(tday,_distDay);//计算距离初始金发放时间天数
            if(daysAfterDist >= _details[i].lockDay){//距离发放日天数要大于等于锁仓天数
                expectReleaseTimesNoLimit = add(sub(daysAfterDist,_details[i].lockDay),1);//解锁后到今天为止应该放的尾款次数
                //到目前为止应该发放的总数=（（应该释放款的次数x每次应该释放的币数）+初始款数量）与 当前创始人应得总发放数量 中的较小值
                //因为释放款次数可能很大了，超过领完时间了
                expectAmount = min(add(mul(expectReleaseTimesNoLimit,_details[i].oneDayTransferAmount),_details[i].initAmount),_details[i].distAmount);

                //将欠下的代币统统发放给当前创始人
                _erc20token.transfer(
                    _details[i].founder,
                    sub(expectAmount, _details[i].transferedAmount)
                );
                //已发放数量在全局细节中进行登记更新
                _details[i].transferedAmount = expectAmount;
                //最新一次发放日期在全局细节中进行登记更新
                _details[i].lastTransferDay = tday;
            }
        }
        // 更新下完成标志
        updateFinishFlag();
    }

    //一天进行计算
    function today() public constant returns (uint256) {
        return div(time(), 24 hours);//24 hours 
    }
    
    //获取当前系统时间
    function time() public constant returns (uint256) {
        return block.timestamp;
    }
 
}