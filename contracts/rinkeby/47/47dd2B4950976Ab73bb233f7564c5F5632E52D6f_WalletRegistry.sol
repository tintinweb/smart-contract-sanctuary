// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './InitOwner.sol';
// 注册
contract WalletRegistry is InitOwner{
    string public constant name = "Kabukicoin Wallet Registry";
    /* wallet => bool */
    mapping(address => bool) public proxies;
    /*允许调用这些用户交易。 */
    mapping(address => bool) public userPower;
    event UserWalletRegistry(address _user,uint _time);
    event ChangePower(address[] _proxy,bool _onoff);
    event Revoked(bool revoked);
    event OpenCurrency(address _coin,bool _open);
    //总开关
    bool public revoked;
    // 支持的ERC20代币列表
    mapping(address => bool) public TransactionCurrency;

    // constructor (address _owner,address _market,uint _fee,address _coin,address _wallet,address _nft)
    constructor (address _owner,address _coin)
    {   
        initializOwner(_owner);
        /* 默认开通ETH交易 */
        openCurrency(_coin,true);
    }
    // 开通交易代币
    function openCurrency(address _coin,bool _open) public onlyOwner {
        TransactionCurrency[_coin] = _open;
        emit OpenCurrency(_coin,_open);
    }
    function isOpen(address _coin) external view returns (bool _onoff) {
        return TransactionCurrency[_coin];
    }
    // 交易总开关
    function setRevoke(bool revoke) public onlyOwner
    {
        revoked = revoke;
        emit Revoked(revoke);
    }
    //  注册Proxy
    function registerProxy() public returns (address proxy)
    {
        // 一个地址只能注册一次
        require(!proxies[msg.sender]);
        proxies[msg.sender] = true;
        userPower[msg.sender] = true;
        emit UserWalletRegistry(msg.sender,block.timestamp);
        return proxy;
    }
    // 权限开关
    function setPower(address[] memory _user,bool _onoff) public onlyOwner {
        
        for(uint i = 0; i < _user.length; i++){
            userPower[_user[i]] = _onoff;
        }
        emit ChangePower(_user,_onoff);
    }

    function userPass(address _user) external view returns (bool _onoff) {
        _onoff = userPower[_user];
    }

    function isRevoked() external view returns (bool _onoff) {
        return revoked;
    }
    
}