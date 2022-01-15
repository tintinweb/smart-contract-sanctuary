// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './InitOwner.sol';
import './IERC20.sol';
import "./Address.sol";
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
    event Market(address _market);
    event Limit(uint _l);
    event OpenCurrency(address _coin,bool _open);
    event Grant(address[] _r,address[] _c,uint[] _a);
    //总开关
    bool public revoked;
    // 支持的ERC20代币列表
    mapping(address => bool) public TransactionCurrency;

    // 发放限制
    mapping(address => uint) public limit;
    // 发放累计
    mapping(address => mapping(address => uint)) sum;
    // 市场
    address public market;
    // NFT交易
    struct NFTExchange{
        address creator;
        uint nonce;
    }
    
    // 索引NFT
    mapping(address => mapping(uint => NFTExchange)) public TradeRecord;
    // 过期的签名列表
    mapping(bytes => bool) public forbidSignature;
    // constructor (address _owner,address _market,uint _fee,address _coin,address _wallet,address _nft)
    constructor (address _owner,address _coin)
    {   
        initializOwner(_owner);
        /* 默认开通ETH交易 */
        openCurrency(_coin,true);
    }
    // 积累
    function sumAmount(address _wallet,address _coin,uint _amount) external{
        require(msg.sender == market,'Is not market');
        sum[_wallet][_coin] += _amount;
    }
    // 设置限制
    function setlimit(address[] memory coins,uint[] memory limits) public onlyOwner{
        
        require(coins.length == limits.length,'lleg');
        for(uint i = 0; i < coins.length; i++){
            limit[coins[i]] = limits[i];
        }
        // Limit
    }
    function forbid(bytes memory _sign) external{
        require(msg.sender == market,'Is not market');
        forbidSignature[_sign] = true;
    }
    // 获取交易记录
    function getTrade(address _nft,uint _tokenId) external view returns(address _c,uint _n)
    {
        require(msg.sender == market,'Is not market');
        _c = TradeRecord[_nft][_tokenId].creator;
        _n = TradeRecord[_nft][_tokenId].nonce;
    }
    // 设置nft创建者
    function setTradeCreater(address _nft,uint _tokenId,address _creator) external
    {
        require(msg.sender == market,'Is not market');
        TradeRecord[_nft][_tokenId].creator = _creator;
    }
    // 设置nft交易次数
    function setTradeNonce(address _nft,uint _tokenId,uint _nonce) external
    {
        require(msg.sender == market,'Is not market');
        TradeRecord[_nft][_tokenId].nonce = _nonce;
    }
    // 设置市场地址
    function setMarket(address _market) public onlyOwner
    {
        market = _market;
        emit Market(_market);
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
    
    /* function CoinBatch(
        address[] memory recipients,
        address[] memory coins,
        uint[] memory amounts
    ) external payable {
        require(recipients.length == coins.length,"coins length llg");
        require(recipients.length == amounts.length,"amounts length llg");
        for(uint i = 0;i < coins.length;i++){
            if(coins[i] == address(0)){
                Address.sendValue(payable(recipients[i]),amounts[i]);
            }else{
                IERC20 erc20Coin = IERC20(coins[i]);
                require(erc20Coin.transferFrom(msg.sender,recipients[i],amounts[i]), "send fail");
            }
        }
        emit Grant(recipients,coins,amounts);
    } */

    function CoinBatch(
        address[] memory recipients,
        address[] memory coins,
        uint8[] memory coinIndexs,
        uint[] memory amounts
    ) external payable {
        require(recipients.length == coinIndexs.length,"coinIndexs length llg");
        require(recipients.length == amounts.length,"amounts length llg");
        for(uint i = 0;i < coinIndexs.length;i++){
            if(coins[coinIndexs[i]] == address(0)){
                Address.sendValue(payable(recipients[i]),amounts[i]);
            }else{
                IERC20 erc20Coin = IERC20(coins[coinIndexs[i]]);
                require(erc20Coin.transferFrom(msg.sender,recipients[i],amounts[i]), "send fail");
            }
        }
        emit Grant(recipients,coins,amounts);
    }
}