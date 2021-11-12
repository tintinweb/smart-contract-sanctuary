// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './InitOwner.sol';
import './Proxy.sol';
import './IERC20.sol';
import "./Address.sol";
interface Register {
    function userPass(address _user) external view returns (bool);
}

contract Model is InitOwner,Proxy{
    string public constant name = "Kabukicoin Model";
    /* 授权表 */
    mapping(address => bool) internal grantAuthorization;
    address public register;
    /* 是否已撤消访问权限。 */
    bool internal revoked;
    /* 代理方式 */
    enum HowToCall { Call, DelegateCall }
    event Revoked(bool revoked);
    event Authorization(address _tool,bool _open);
    /* 预留 */
    bool[] internal boolGather;
    uint[] internal uintGather;
    address[] internal addressGather;
    bytes[] internal bytesGather;
    mapping(uint => mapping(address => mapping(address => uint))) public mappingGather;

    /* Market合约状态变量*/
            uint internal decimals = 10 ** 18;
            // 支持的ERC20代币列表
            mapping(address => bool) public TransactionCurrency;
            // 注销的消息签名
            mapping(bytes => bool) public forbidSignature;
            // 交易平台收取的手续费
            uint internal fee;
            uint internal publishFee;
            uint internal recommendFee;
            // 平台币(NFT)地址
            address internal OwnerERC1155;
            // Kabukicoin钱包地址
            address internal KabukicoinWallte;
            // NFT交易
            struct NFTExchange{
                address creator;
                address belong;
                uint nonce;
            }
            // 索引NFT
            mapping(address => mapping(uint => NFTExchange)) public TradeRecord;


    
    
    constructor (address _owner,address _market,uint _fee,address _coin,address _wallet,address _nft)
    {   
        // 初始化合约所有者
        initializOwner(_owner);
        // 初始化授权Market代理权限
        authorizationTool(_market,true);
        // 初始化Market合约的状态
        initMarket(_fee,_coin,_wallet,_nft);
    }
    // 提币
    function withdraw(address _coin,address _to,uint _amount) public onlyOwner {
      if(_coin != address(0)){
        IERC20 erc20Coin = IERC20(_coin);
        require(erc20Coin.transfer(_to,_amount), "withdrawal fail");
      }else{
        Address.sendValue(payable(_to),_amount);
      }
    }
    function initMarket(uint _fee,address _coin,address _wallet,address _nft) internal {
        // 设置平台收取的手续费
        fee = _fee;
        // Market开通交易币种
        TransactionCurrency[_coin] = true;
        // Market收款钱包
        KabukicoinWallte = _wallet;
        // Market平台NFT
        OwnerERC1155 = _nft;
    } 
    function authorizationTool(address _tool,bool _open) public onlyOwner {
        grantAuthorization[_tool] = _open;
        emit Authorization(_tool,_open);
    }
    // 设置注册地址
    function setRegister(address _newRegister) public onlyOwner {
        require(_newRegister != register,'New != Old');
        register = _newRegister;
    }
    // 开启对代理的访问
    function setRevoke(bool revoke) public onlyOwner
    {
        revoked = revoke;
        emit Revoked(revoke);
    }
    //  接收消息的合约地址，发送方式，消息
    function proxy(address dest, HowToCall howToCall, bytes memory _calldata) public payable returns (bool result,bytes memory returndata)
    {
        // 只有授权过的合约才能调用代理
        require(grantAuthorization[dest],"ERROR 403");
        Register curRegistry = Register(register);
        require(msg.sender == owner || (!revoked && curRegistry.userPass(msg.sender)));
        if (howToCall == HowToCall.Call) {
            (result,returndata) = dest.call(_calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result,returndata) = dest.delegatecall(_calldata);
        }else {
            revert();
        }
    }
    
}