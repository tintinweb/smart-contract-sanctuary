// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ERC20.sol';
import './WolMath.sol';
import './bonusInterface.sol';
import './authInterface.sol';

contract baseAirdrop {      
    using SafeMath for uint;      
    string public name = 'wolAirdrop';
    string public symbol = 'WA' ;
    uint8 public decimals = 8;
    uint  public totalSupply;    
    WERC20 hostAddress;
    WERC20 payContractAddress;
    bonusTokenRecipient bonusAddress;
    address owner;
    address inputAddress;
    address hostUserAddress;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    // 事件，用来通知客户端注册记录 
    event UserRegister(address indexed userAddress , address indexed parentAddress);
    struct User {
        address oneAddress;
        uint isUsed;
        uint airdrop;
        uint waitSettleAirdrop;
        uint waitReceiveWol;
        uint receiveDay;
    }
    struct authInfo {
        userTokenRecipient authAddress;
        uint isUsed;
    }
    authInfo[] authAddresss;
    mapping(address=>User) public users;         //用户数据
    modifier checkAuth() {
        uint8 isauth= 0;
        if(msg.sender == owner) {
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
            users[_userAddress] = User({oneAddress:_oneAddress,isUsed:1,airdrop:0,waitSettleAirdrop:0,waitReceiveWol:0,receiveDay:0});
        }           
        emit UserRegister(msg.sender,_oneAddress);    
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
        require(msg.sender == owner,'invalid operation');
        _;
    }
    modifier checkRegister() {
        require(users[msg.sender].isUsed == 1,'invalid operation' );
        _;
    }    
    function _transfer(address toAddress, uint256 _number) public payable {
        payable(address(toAddress)).transfer(_number);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address _sender, address _spender, uint _value) private {
        allowance[_sender][_spender] = _value;
        emit Approval(_sender, _spender, _value);
    }

    function _transfer(address _from, address _to, uint _value) private {
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != 0) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
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
    // 加权分红池第三方调用
    function _bonusAddressAdd(uint _number) internal {
        bytes memory returndata = _functionCall(address(bonusAddress),abi.encodeWithSelector(bonusAddress.addBonus.selector, _number ,2 ),0, "SafeERC20: low-level call failed");       
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
contract wolAirdrop is baseAirdrop{    
    using SafeMath for uint;    

    uint receiveRate = 95;     //提现wol到账比例
    uint baseRate = 100;       //提现基础比例
    uint airdropRate = 1;     // airdrop发放比例    
    uint old_date ;    
    uint public receiveDay = 0;
    uint airdropWithdrawRate = 10;  // airdrop 提现手续费
    // 事件，主币提现日志
    event WolWithdrawLog(address indexed userAddress,uint num);
    // 事件，用来通知客户端空投记录 
    event KongtouLog(address indexed userAddress, uint256 num,uint256 createtime );
    // 事件，用来通知客户端空投提现记录 
    event KongtouWithdrawLog(address indexed userAddress,uint num,uint createtime);
    // --------------------
    constructor(WERC20 _hostAddress,address _hostUserAddress,address _inputAddress) {
        totalSupply = 0 * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        balanceOf[msg.sender] = totalSupply;                // 创建者拥有所有的代币
        owner = msg.sender;                            //发币者
        _userRegister(msg.sender,address(0x0));   
        updateHostAddress(_hostAddress,_hostUserAddress,_inputAddress);
    }
    //修改加权分红池合约地址
    function updatebonusAddress(bonusTokenRecipient _contractAddress) checkOwner public {
        bonusAddress =  _contractAddress;
    }       
    //修改主币合约地址 和入金账号
    function updateHostAddress(WERC20 _hostAddress,address _hostUserAddress,address _inputAddress) checkOwner public {
        hostAddress = _hostAddress;
        hostUserAddress = _hostUserAddress;
        inputAddress = _inputAddress;
    }
    // 用户空投
    function userAirdrop(uint256 number) checkRegister public {  //放大
        _safeTransfer(hostAddress,msg.sender,hostUserAddress,number)    ;      
        uint userWolNumber = getUserReward();
        users[msg.sender].receiveDay = receiveDay; 
        users[msg.sender].waitReceiveWol = userWolNumber;
        users[msg.sender].airdrop += number;     
        users[msg.sender].waitSettleAirdrop += number;   
        emit KongtouLog(msg.sender,number,block.timestamp);
    }
    // 用户提出空投
    function userAirdropWithdraw() checkRegister public {
        uint256 number = users[msg.sender].airdrop;
        users[msg.sender].airdrop = 0;
        users[msg.sender].waitSettleAirdrop = 0;
        users[msg.sender].receiveDay = receiveDay;
        uint wolNumberReal =  number.mul((baseRate-airdropWithdrawRate)).div(baseRate);
        _safeTransfer(hostAddress,hostUserAddress,msg.sender,wolNumberReal);   
        _bonusAddressAdd(number.sub(wolNumberReal));          
        emit KongtouWithdrawLog(msg.sender,number,block.timestamp);
    }
    // 用户待领取wol
    function getUserReward() checkRegister public view returns (uint userWolNumber) {
        userWolNumber = users[msg.sender].waitReceiveWol;
        uint sur_day = receiveDay -  users[msg.sender].receiveDay;
        if(sur_day > 0 ) {
            userWolNumber += users[msg.sender].waitSettleAirdrop - users[msg.sender].waitSettleAirdrop * (( baseRate - airdropRate)) ** sur_day / baseRate ** sur_day;
        }              
    }
    // 添加分红次数
    function addReceiveDay(uint _date) checkOwner public {
        require(_date != old_date ,"time error");
        old_date = _date;
        receiveDay += 1;
    }
    // 用户领取wol奖励
    function receiveReward() checkRegister public {
        uint wolNumber = getUserReward();
        uint wolNumberReal = wolNumber.mul(receiveRate).div(baseRate);
        users[msg.sender].receiveDay = receiveDay;
        users[msg.sender].waitReceiveWol = 0;
        users[msg.sender].waitSettleAirdrop = users[msg.sender].waitSettleAirdrop.sub(wolNumber);
        emit WolWithdrawLog(msg.sender,wolNumber);
        _safeTransfer(hostAddress,hostUserAddress,msg.sender,wolNumberReal);
        _bonusAddressAdd(wolNumber.sub(wolNumberReal));
    }
    
    // 获取上级
    function getRecommender(address _address,uint _type) public view returns (address){
        if(isUserExists(_address)){
            if(_type == 1) {
                return users[_address].oneAddress;
            } else {
                if(isUserExists(_address)){
                    return users[users[_address].oneAddress].oneAddress;
                } else {
                    return address(0x0);
                }
            }
        } else{
            return address(0x0);
        }
        
    }
}