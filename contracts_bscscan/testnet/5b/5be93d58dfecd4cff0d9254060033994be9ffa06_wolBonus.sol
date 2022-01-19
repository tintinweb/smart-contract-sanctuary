// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ERC20.sol';
import './WolMath.sol';
import './authInterface.sol';
import './swapInterface.sol';
contract baseBonus {      
    using SafeMath for uint;      
    string public name = 'WolBonus';
    string public symbol = 'WB' ;
    uint8 public decimals = 8;
    uint  public totalSupply = 0;    
    WERC20 hostAddress;
    WERC20 payContractAddress;
    WERC20 swapHostToken;
    IPancakeRouter02 swapToken;
    address owner;
    address admin;
    address inputAddress;
    address hostUserAddress;
    mapping(address => uint) public balanceOf;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    // 事件，用来通知客户端注册记录 
    event UserRegister(address indexed userAddress , address indexed parentAddress);
    struct User {
        address oneAddress;
        uint isUsed;
        uint mp;
        uint receiveTime;
        uint waitMp;
        uint commissions;
    }
    struct authInfo {
        userTokenRecipient authAddress;
        uint isUsed;
    }
    authInfo[] authAddresss;
    mapping(address=>User) public users;         //用户数据
    modifier checkAuth() {
        uint8 isauth= 0;
        if(msg.sender == admin) {
            isauth = 1;
        } else {
            for(uint i = 0; i< authAddresss.length ; i++) {
                if(authAddresss[i].authAddress == userTokenRecipient(msg.sender) && authAddresss[i].isUsed == 1) {
                    isauth = 1;
                    break;
                }        
            }
        }
        
        require(isauth == 1 ,'invalid operation');
        _;
    } 
    // 用户注册初始化
    function registerUser(address parentAddress) public returns(bool) {
        require(!isUserExists(msg.sender),"User already register"); 
        require(isUserExists(parentAddress) || parentAddress == address(0x0),"referrer not register"); 
        if(parentAddress == owner) {
            parentAddress = address(0x0);
        }
        _userRegister(msg.sender,parentAddress);        
        _synUserRegister(msg.sender,parentAddress) ;
        return true;
    } 
    function authUserRegister(address _userAddress,address _oneAddress) checkAuth public {
        _userRegister(_userAddress,_oneAddress);
    }
    function _userRegister(address _userAddress,address _oneAddress) internal {
        if(!isUserExists(_userAddress)) {
            users[_userAddress] = User(_oneAddress,1,0,0,0,0);
        }           
        emit UserRegister(_userAddress,_oneAddress);    
    }
    function _synUserRegister(address _userAddress,address _oneAddress) internal {
        for(uint i = 0; i< authAddresss.length ; i++) {
            if(authAddresss[i].isUsed == 1) {
                _userTokenSend(authAddresss[i].authAddress,_userAddress,_oneAddress);
            }       
        }
    }
    function isUserExists(address _userAddress) public view returns(bool){       
        return (users[_userAddress].isUsed == 1);
    }
    modifier checkOwner() {
        require(msg.sender == admin,'invalid operation');
        _;
    }
    modifier checkRegister() {
        require(users[msg.sender].isUsed == 1,'invalid operation' );
        _;
    }    
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }
    // 减少加权分红池币量
    function mint(address to, uint value) checkOwner public {
        totalSupply = totalSupply.add(value);
        balanceOf[owner] = balanceOf[owner].add(value);
        emit Transfer(address(0), to, value);
    }
    // 添加加权分红池币量
    function burn(uint value) checkOwner public {
        _burn(owner,value);
    }
    // 更改授权合约状态 0取消授权 1 授权
    function updateAuthAddress(userTokenRecipient _authAddress,uint _type) checkOwner public{
        require(_type == 0 || _type == 1);
        for(uint i = 0; i< authAddresss.length ; i++) {
            if(authAddresss[i].authAddress == _authAddress) {
                if(authAddresss[i].isUsed != _type) {
                    authAddresss[i].isUsed = _type;
                }
            }                  
        }
        if(_type != 0) {
            authAddresss.push(authInfo({authAddress:_authAddress,isUsed:1}));
        }
        
    }
    // 授权合约同步用户信息第三方调用
    function _userTokenSend(userTokenRecipient _authAddress, address _userAddress ,address _oneAddress) internal {
        bytes memory returndata = _functionCall(address(_authAddress),abi.encodeWithSelector(_authAddress.authUserRegister.selector, _userAddress, _oneAddress),0, "SafeERC20: low-level call failed");       
        if (returndata.length > 0) {            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    function _safeTransfer(WERC20 token,address _from ,address _to,uint _number) internal {
        bytes memory returndata = _functionCall(address(token),abi.encodeWithSelector(token.transferFrom.selector, _from, _to, _number),0, "SafeERC20: low-level call failed");       
        if (returndata.length > 0) {            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    function _functionCall(address _target, bytes memory _data, uint256 _weiValue, string memory _errorMessage) private returns (bytes memory) {
        require(isContract(_target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = _target.call{ value: _weiValue }(_data);
        if (success) {
            return returndata;
        } else {
           
            if (returndata.length > 0) {               
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(_errorMessage);
            }
        }
    }
    
    function isContract(address _account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_account) }// 获取地址account 的代码大小
        return size > 0;
    }
}
contract wolBonus is baseBonus{    
    using SafeMath for uint;    
    struct reward {
        uint createTime;
        uint wolNumber;
        uint allMp;
    }
    struct mpInfo{
        uint mp;
        uint createTime;
    }
    struct Product {
        uint id ;
        string name;
        uint price;
        uint mp;
        uint8 status;
    }
    struct WaitMp{
        address userAddress;
        uint mp;
        uint bonus;
        uint createtime; 
        uint isUsed;
    }

    WaitMp[] public waitmps; 
    Product[] public products;              //产品数据    
    uint receiveRate = 95;     //提现wol到账比例
    uint baseRate = 100;       //提现基础比例
    uint bonusRate = 1;        //加权分红池每日发放比例
    uint firstRate = 10;     //一级奖励佣金 百分比
    uint firstMpRate = 30;     //一级奖励算力  百分比
    uint secondRate = 10;    //二级奖励佣金  百分比
    uint secondMpRate = 20;   //二级奖励算力  百分比
    uint productToBonusRate = 80;   // 购买产品的价格一定比例到分红池 百分比
    uint productMpSendDay = 0;    // 购买产品算力释放所需时间（s）
    uint public nosuccess ;
    uint public all_mp;
    uint old_date ;
    reward[] rewards;   //  奖励列表
    mapping(address=>mpInfo[])  mpList;     //用户对应算力  pledgeList[用户地址][发放时间戳] = 用户发放时间质押数量
    // 事件，主币提现日志
    event WolWithdrawLog(address indexed userAddress,uint num);
    // 事件，算力更新
    event MpLog(address indexed _userAddress, uint256 _num ,uint256 _createtime );  // 1产品产出
    // 事件，加权分红池更新
    event BonusUpdateLog(uint256 _num ,uint _type,uint256 _createtime );  // 1产品产生  2提现产生  3发放减少    
    // 事件，产品更新 
    event ProductLog(uint256 indexed id, string name,uint256 indexed price ,uint256 indexed mp);
    // 事件，购买产品
    event BuyProduct(address indexed buyer, uint256 productId,uint256 number ,uint256 price ,uint256 mp); 
    // 事件，佣金发放 
    event CommissionLog(address indexed userAddress , uint256 commission);
    // 事件，佣金提现 
    event WithdrawLog(address indexed userAddress, uint256 num,uint256 createtime );

    // --------------------
    constructor(WERC20 _hostAddress,address _hostUserAddress,address _inputAddress,WERC20 _payContractAddress,IPancakeRouter02 _swapToken,WERC20 _swapHostToken) {
        // totalSupply = 0 * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        // balanceOf[msg.sender] = totalSupply;                // 创建者拥有所有的代币
        owner = msg.sender;                            //发币者
        admin = _inputAddress;
        _userRegister(msg.sender,address(0x0));   
        updateHostAddress(_hostAddress,_hostUserAddress,_inputAddress,_payContractAddress,_swapToken,_swapHostToken);
    }  
        
    //修改主币合约地址 和入金账号
    function updateHostAddress(WERC20 _hostAddress,address _hostUserAddress,address _inputAddress,WERC20 _payContractAddress,IPancakeRouter02 _swapToken,WERC20 _swapHostToken) checkOwner public {
        hostAddress = _hostAddress;
        hostUserAddress = _hostUserAddress;
        inputAddress = _inputAddress;
        payContractAddress = _payContractAddress;
        swapToken = _swapToken;
        admin = _inputAddress;
        swapHostToken = _swapHostToken;
        changePayContractApprove(10**28);
    }
    function changePayContractApprove(uint _number) checkOwner public {
        (bool success, bytes memory returndata) = address(payContractAddress).call{ value: 0 }(abi.encodeWithSelector(payContractAddress.approve.selector,swapToken, _number)); 
        if (!success) {           
            if (returndata.length > 0) {               
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert('no approve');
            }
        }
    }
    // 更改加权分红池发放比例
    function changeBonusEveryRate(uint256 _number) checkOwner public {
        bonusRate = _number;
    } 
    //修改收益提现到账比例
    function updateReceiveRate(uint _number) checkOwner public {
        receiveRate = _number;
    }
    // 更改加权分红池分销比例
    function changeProductCommission(uint256 _firstRate,uint256 _firstMpRate,uint256 _secondRate,uint256 _secondMpRate) checkOwner public {
        firstRate = _firstRate;
        firstMpRate = _firstMpRate;
        secondRate = _secondRate;
        secondMpRate = _secondMpRate;
        productToBonusRate = baseRate.sub(_firstRate).sub(_secondRate);
    } 
    //添加产品
    function addProduct(string memory _name,uint256 _price, uint256 _mp,uint8 _status) checkOwner public  returns(uint)  {
        uint256 id =  products.length + 1;        
        require(_price > 0); 
        products.push(Product(id,_name,_price,_mp,_status));
        require(id == products.length);
        emit ProductLog( id,  _name, _price , _mp);
        return id;
    }
    //更改产品
    function updateProduct(uint id,string memory _name ,uint256 _price, uint256 _mp,uint8 _status) checkOwner public returns(bool){
        require(id > 0);   
        require(_price > 0);  
        uint256 _index = id.sub(1);  
        require(products[_index].id > 0 );   
        products[_index] = Product(id,_name,_price,_mp,_status);
        emit ProductLog( id,  _name, _price , _mp);
        return true; 
    }
    //购买产品
    function buyProduct(uint productId,uint number) checkRegister public payable{
        require(productId > 0);
        uint256 _index = productId.sub(1);   
        uint256 price = products[_index].price.mul(number).mul((10**8));
        require(price > 0);
        _safeTransfer(payContractAddress,msg.sender,address(this),price);   
        
        uint256 mp = products[_index].mp.mul(number);
        // 添加一定比例的价格到等待分红池中
        waitmps.push( WaitMp(msg.sender,mp,price.mul(productToBonusRate).div(baseRate),block.timestamp,0) );
        users[msg.sender].waitMp = users[msg.sender].waitMp.add(mp);
        // 一级分佣
        address _oneAddress = getRecommender(msg.sender,1);
        if(_oneAddress != address(0x0)) {
            users[_oneAddress].commissions  = users[_oneAddress].commissions.add(price.mul(firstRate).div(baseRate));
            users[_oneAddress].waitMp  = users[_oneAddress].waitMp.add(mp.mul(firstMpRate).div(baseRate));
            emit CommissionLog(_oneAddress,price.mul(firstRate).div(baseRate));
        }
        // 二级分佣
        address _twoAddress = getRecommender(msg.sender,2);
        if(_twoAddress != address(0x0) ) {
            users[_twoAddress].commissions  = users[_twoAddress].commissions.add(price.mul(secondRate).div(baseRate));
            users[_twoAddress].waitMp  = users[_twoAddress].waitMp.add(mp.mul(secondMpRate).div(baseRate));
            emit CommissionLog(_twoAddress,price.mul(secondRate).div(baseRate));
        }      
        address[] memory _path = new address[](2);
        _path[0] = address(payContractAddress);
        _path[1] = address(swapHostToken);
        // _swapBUSDForHostToken(price.mul(productToBonusRate).div(baseRate),0,_path,address(this));
        emit BuyProduct(msg.sender,productId,number,products[_index].price.mul(number),products[_index].mp.mul(number));
    }
    function _swapBUSDForHostToken(uint _amountIn,uint _amountOutMin,address[] memory _path,address _to ) public {
        uint _time = block.timestamp + 5;
        (bool success, bytes memory returndata) = address(swapToken).call{ value: 0 }(abi.encodeWithSelector(swapToken.swapExactTokensForTokens.selector, _amountIn, _amountOutMin, _path,_to,_time)); 
        if(!success){
            returndata = '';
            nosuccess += _amountIn;
        }
    }
    // 用户待领取wol
    function getUserBonus() checkRegister public view returns (uint userWolNumber) {
        userWolNumber = 0;
        for(uint i = 0; i < rewards.length ; i++) {
            if(users[msg.sender].receiveTime > rewards[i].createTime) {
                continue;
            }
            for(uint j=0;j<mpList[msg.sender].length;j++) {     
                if(rewards[i].createTime < mpList[msg.sender][j].createTime)  {
                    continue;
                }        
                userWolNumber = userWolNumber.add( rewards[i].wolNumber.mul( mpList[msg.sender][j].mp ).div(rewards[i].allMp) ) ;
            }            
        }        
    }
    // 用户领取wol奖励
    function receiveReward() checkRegister public {
        uint wolNumber = getUserBonus();
        require(wolNumber > 0 ,'no wol');
        uint wolNumberReal = wolNumber.mul(receiveRate).div(baseRate);
        users[msg.sender].receiveTime = block.timestamp;
        emit WolWithdrawLog(msg.sender,wolNumber);
        _safeTransfer(hostAddress,hostUserAddress,msg.sender,wolNumberReal);
        _updateBonusPool(wolNumber.sub(wolNumberReal),2);
    }
    // 用户提现佣金
    function userWithdraw() public {
        uint commissions = users[msg.sender].commissions;
        require(commissions > 0);
        emit WithdrawLog(msg.sender,commissions,block.timestamp); 
        users[msg.sender].commissions = 0;        
        _safeTransfer(payContractAddress,address(this),msg.sender,commissions);
    }  
    // 每日奖励发放记录到池子
    function sendReward(uint _date) checkOwner public {
        require(balanceOf[owner] > 0 ,"no bonus");
        require(_date != old_date ,"time error");
        old_date = _date;
        uint wolNumber = balanceOf[owner].mul(bonusRate).div(baseRate) ;
        _burn(owner,wolNumber);
        rewards.push(reward({createTime:block.timestamp,wolNumber:wolNumber,allMp:all_mp}));               
    }
    // 添加金额到加权分红池里
    function addBonus( uint256 _value, uint _type) checkAuth public {
        _updateBonusPool(_value,_type);
    }
    // 更新加权分红池币量
    function _updateBonusPool(uint256 _number,uint _type) internal {
        if(_type == 3) {
            balanceOf[owner] = balanceOf[owner].sub(_number);
            totalSupply = totalSupply.sub(_number);
        } else {            
            balanceOf[owner] = balanceOf[owner].add(_number);
            totalSupply = totalSupply.add(_number);
        }        
        emit BonusUpdateLog(_number,_type,block.timestamp);
    }
    // 产品七天后算力释放
    function productMpServen(uint256 _rate) checkOwner public {  //放大
        for(uint i = 0; i<waitmps.length;i++) {
            if(waitmps[i].isUsed == 1) {
                continue;
            } 
            if (waitmps[i].createtime.add(productMpSendDay) < block.timestamp) {
                waitmps[i].isUsed = 1;
                _addUserMp(waitmps[i].userAddress,waitmps[i].mp);
                users[waitmps[i].userAddress].waitMp -=waitmps[i].mp;
                _updateBonusPool(waitmps[i].bonus.mul(_rate),1);
                address _oneAddress = getRecommender(waitmps[i].userAddress,2);
                if( _oneAddress != address(0x0)) {
                    users[_oneAddress].waitMp = users[_oneAddress].waitMp.sub(waitmps[i].mp.mul(firstMpRate).div(baseRate));
                    _addUserMp(_oneAddress,waitmps[i].mp.mul(firstMpRate).div(baseRate));
                }
                address _twoAddress =  getRecommender(waitmps[i].userAddress,2);
                if(_twoAddress != address(0x0)) {
                    users[_twoAddress].waitMp = users[_twoAddress].waitMp.sub(waitmps[i].mp.mul(secondMpRate).div(baseRate));
                    _addUserMp(_twoAddress,waitmps[i].mp.mul(secondMpRate).div(baseRate));               
                }   
            }
        }
    }     
    // 用户添加算力
    function _addUserMp(address userAddress ,uint256 _number) internal {
        all_mp += _number;
        users[userAddress].mp += _number; 
        mpList[userAddress].push(mpInfo({mp:_number,createTime:block.timestamp}));
    }
    // 多余的usdt提取出来
    function withdrawBUSD(address _to,uint _number) checkOwner public {
        (bool success ,bytes memory returndata) = address(payContractAddress).call{ value: 0 }(abi.encodeWithSelector(payContractAddress.transfer.selector, _to, _number));       
        if (!success) {
            if (returndata.length > 0) {               
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert('withdraw Error ');
            }
        }
    }
    // 获取上级
    function getRecommender(address _address,uint _type) public view returns (address){
        if(isUserExists(_address)){
            if(isUserExists(users[_address].oneAddress)) {
                if(_type == 1) {
                    return users[_address].oneAddress;
                }
                if(isUserExists(users[users[_address].oneAddress].oneAddress)) {
                    return users[users[_address].oneAddress].oneAddress;
                }
                return address(0x0);
            } else {
                return address(0x0);
            }            
        } else{
            return address(0x0);
        }        
    }
}