// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './IERC20.sol';
import './IERC721.sol';
import './IERC1155.sol';
import './InitOwner.sol';
import "./ECDSA.sol";
import "./Address.sol";
// Available Accounts
// ==================
// (0) 0x18Ce6E87a1F8b87aE6b55F47651744295d25a55c (100 ETH)
// (1) 0x0a19Eb3f8dE28F58e0f4213C9ce74Bbf5B01cF9C (100 ETH)
// (2) 0x5C719Aa292513985B05dC71b0b08159cbB4184D7 (100 ETH)
// (3) 0x3F19A5d5C65bEE7Ee202Cf22825EbD7C5590102c (100 ETH)
// (4) 0xB7602a5Bd5949CE8abc9Dc704A53DAe8F469c42B (100 ETH)
// (5) 0xaA2b74779d16a9b639EB9bf8daDFEB5df21437d2 (100 ETH)
// (6) 0xf1d794B321617f89FAE3c00A1B2b06c581E9E847 (100 ETH)
// (7) 0x5dd50aA452748AE3084f861bd9A78e5070c4f6e8 (100 ETH)
// (8) 0x2315c87ebC800d669438Cd5aF3D803C522aad3b0 (100 ETH)
// (9) 0x4AC296fC938E65dD7f4f91E748bAF3303acBB21b (100 ETH)

// Private Keys
// ==================
// (0) 0x6d4ede492747e4e6701d3e20c82de9d30d532caf0c0c81f6a25303a526ca43ce
// (1) 0x7da882e7ddcbcab4a4a723aaa530e61d1cbec1fefc3089483ef88acb8b3f30e6
// (2) 0xf89972686b71529569fd91cac0c68e40ca07a0c7ecb4b8caccb3ab0a9573722c
// (3) 0x517573fe18ab65ac11e7217894aec4fac3c0badaae4c97095cedbdea8f107b30
// (4) 0x909b64dc4ab569d0ad0fae94ee0e9a02bfdfd5cc7484dd7ce9402ec44b0e721c
// (5) 0x406bdcc598918e4c1a7580aa81ba251008274160143a42e525f1f8b5d9b1b541
// (6) 0xbc6436bce96f9fb3d3435fe942b3cc86c034d1905928b1fed950eb28357d6433
// (7) 0x1be073a553a8a2f89e95ddf509dc16aaeb4c78912c22025f620aa13e0d066728
// (8) 0x0393f4facd9bb5594736a7b45118949f7e58bbd3f9387610c7d6a428866daa7e
// (9) 0x380af5423b463ff9e3bace9705e2162aae23d92eafc89a5e9d9431539a32e14e
contract Market is InitOwner{
    uint decimals = 10 ** 18;
    string public constant name = "Kabukicoin Market";
    // 可访问的,代理合约地址
    address public model;
    // market 合约地址
    address public market;
    // 平台币(NFT)地址
    address public OwnerERC1155;
    // Kabukicoin钱包地址
    address KabukicoinWallte;
    // 过期的签名列表
    mapping(bytes => bool) public forbidSignature;
    // 支持的ERC20代币列表
    mapping(address => bool) public TransactionCurrency;
    address[] public CurrencyList;
    // 交易平台收取的手续费
    uint private fee = 25 * 10 ** 15;
    uint private publishFee;
    uint private recommendFee;
    // NFT交易
    struct NFTExchange{
        address creator;
        address belong;
        uint nonce;
    }
    /** 
     * @param addressGather[0] 买家地址
     * @param addressGather[1] NFT合约地址
     * @param addressGather[2] 购买使用的ERC20代币地址，如果是使用ETH交易地址为0x0
     * @param addressGather[3] 推荐者地址
     * @param uintGather[0]  NFT的tokenID
     * @param uintGather[1]  买家设置的NFT出售价格
     * @param uintGather[2]  买家设置出售价格的时间戳
     * @param uintGather[3]  卖家登录的时间戳
     * @param uintGather[4]  创建者创建的时间戳
     * @param uintGather[5]     交易类型 Buy1,Sell2
     * @param uintGather[6]     交易类型 ERC721,ERC1155
     * @param signatureGather[0]    卖家的消息签名
     * @param signatureGather[1]    创建者的签名
     */
    struct Order {
      address doer;//钱包地址
      address art;//NFT合约地址
      address token;//购买使用的ERC20代币地址，如果是使用ETH交易地址为0x0
      address gooder;//推荐者地址
      uint id;//NFT的tokenID
      uint price;//买家设置的NFT出售价格
      uint sale;//买家设置出售价格的时间戳
      uint create;//创建者创建的时间戳
      uint trade; //Buy:1 Sell:2
      uint nft; //erc721:721 erc1155:1155
      bytes createrSign; // 创建者的签名
    }
    // 索引NFT
    mapping(address => mapping(uint => NFTExchange)) public TradeRecord;

    event Trade(address _buyer,address _seller,address _artToken,uint _tokenID,address _tradeToken,uint _price);
    event SetProxy(address _oldProxy,address _newProxy);
    event SetWallet(address _oldWallet,address _newWallet);
    event OpenCurrency(address _coin);
    event SetFee(uint _fee,uint _publishFee,uint _recommendFee);

    constructor (address _owner)
    {   
        initOwner(_owner);
    }
    // 设置代理中心地址
    function setProxyModel(address _proxyModel) public onlyOwner {
        emit SetProxy(model,_proxyModel);
        model = _proxyModel;
    }
    // 设置Kabukicoin钱包地址
    function setWallet(address _wallet) public onlyOwner {
        emit SetWallet(KabukicoinWallte,_wallet);
        KabukicoinWallte = _wallet;
    }
    // 开通交易代币
    function openCurrency(address _coin,bool _open) public onlyOwner {
        TransactionCurrency[_coin] = _open;
        CurrencyList.push(_coin);
        emit OpenCurrency(_coin);
    }
    // 设置交易中需要的费用
    function setFee(uint _rate,uint _publishFee,uint _recommendFee) public onlyOwner {
        require(_rate + _publishFee + _recommendFee <= decimals, "set fail !");
        fee = _rate;
        publishFee = _publishFee;
        recommendFee = _recommendFee;
        emit SetFee(_rate,_publishFee,_recommendFee);
    }
    // 以太坊对消息Hash进行签名
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }
    
    // 消息哈希
    function getMsgHash(Order memory order) public view returns (bytes32){
      return keccak256(abi.encodePacked(
        order.doer,
        order.art,
        order.token,
        order.id,
        order.price,
        order.sale,
        order.trade,
        TradeRecord[order.art][order.id].creator,
        TradeRecord[order.art][order.id].nonce));
    }
    function trade(
        address[] memory ads,
        uint[] memory us,
        bytes[] memory ss,
        bytes memory cs
    ) public payable{
      require(us[5] == 721 || us[5] == 1155, "Illegal parameter !");
      Order memory o = Order(ads[0],ads[1],ads[2],ads[3],us[0],us[1],us[2],us[3],us[4],us[5],cs);
      if(us[4] == 1){
        Buy(o,ss);
      }else if (us[4] == 2){

      }else{
        revert("not have trade type !");
      }
    }
    function trade2(
        address[] memory ads,
        uint[] memory us,
        bytes[] memory ss,
        bytes memory cs
    ) public payable{
      require(us[5] == 721 || us[5] == 1155, "Illegal parameter !");
      Order memory o = Order(ads[0],ads[1],ads[2],ads[3],us[0],us[1],us[2],us[3],us[4],us[5],cs);
      if(us[4] == 1){
        _checkPass(o,ss);
        test2(o);
        test3(o);
        test4(o);
      }else if (us[4] == 2){

      }else{
        revert("not have trade type !");
      }
    }
    
    /* function trade1(
        address[] memory ads,
        uint[] memory us,
        bytes[] memory ss,
        bytes memory cs,
        uint num
    ) public payable{
      require(us[5] == 721 || us[5] == 1155, "Illegal parameter !");
      Order memory o = Order(ads[0],ads[1],ads[2],ads[3],us[0],us[1],us[2],us[3],us[4],us[5],cs);
      if(us[4] == 1){
        if(num == 1){
          test1(o,ss);
        }else if(num == 2){
          test2(o);
        }else if(num == 3){
          test3(o);
        }else if(num == 4){
          test4(o);
        }
        
      }else if (us[4] == 2){

      }else{
        revert("not have trade type !");
      }
    } */
    // nft类型 nft地址 nftid 签名者 交易次数
    function _nBalance(uint t,address a,uint i,address d,uint n) public {
      // 判断NFT
      if(t == 721){
        IERC721 nft721Coin = IERC721(a);
        // 如果卖家钱包，NFT余额为0
        if(nft721Coin.ownerOf(i) != d){
          revert("You don't have this NFT !");
        }else{
          // 如果之前没有交易过当前买家就是创建者
          if(n == 0){
              TradeRecord[a][i].creator = d;
          }
          
        }
      }
      if(t == 1155){
        IERC1155 nft1155Coin = IERC1155(a);
        // 如果卖家钱包，NFT余额为0
        if(nft1155Coin.balanceOf(d,i) < 1){
          // 如果NFT为平台NFT,且当前卖家余额为0，tokeniD为0，自动进行铸币
          if(OwnerERC1155 == a){
            require(!nft1155Coin.exist(i),"Already exists !");
            require(nft1155Coin.mint(d,i,bytes("")),"mint fail !");
            TradeRecord[a][i].creator = d;
          }else{
            revert("You don't have this NFT !");
          }
        }else{
          // 如果之前没有交易过当前买家就是创建者
          if(n == 0){
              TradeRecord[a][i].creator = d;
          }
        }
      }
    }
    // nft类型 nft地址 创建者地址 所有者地址 nftid 交易次数
    function _nTransfer(uint t,address s,address c,address b,uint i,uint n) public {
      if(t == 1155){
        IERC1155 nft1155CoinEnd = IERC1155(s);
        if(n == 0){
          nft1155CoinEnd.safeTransferFrom(c,msg.sender,i,1,bytes("0x0"));
        }else{
          nft1155CoinEnd.safeTransferFrom(b,msg.sender,i,1,bytes("0x0"));
        }
        
        require(nft1155CoinEnd.balanceOf(msg.sender,i) > 0,"fail !");

      }
      if(t == 721){
        IERC721 nft721CoinEnd = IERC721(s);
        if(n == 0){
          nft721CoinEnd.transferFrom(c,msg.sender,i);
        }else{
          nft721CoinEnd.transferFrom(b,msg.sender,i);
        }
        require(nft721CoinEnd.ownerOf(i) == msg.sender,"fail!");
      }
    }
    
    // erc20代币地址 价格 推荐地址 创建者 所属者 交易次数
    function _erc20Transfer(address e,uint p,address r,address c,address b,uint n) public {
      uint gainCount;
      if(e != address(0)){
        // 是否开通交易的ERC20代币
        require(TransactionCurrency[e], "ERC20 Not opened");
        // 如果是ERC20判断余额是否足够
        IERC20 erc20Coin = IERC20(e);
        require(erc20Coin.balanceOf(msg.sender) >= p, "Insufficient Balance !");
        // _safeEnter(e,p);
        require(erc20Coin.transferFrom(msg.sender,address(this),p), "fail");
        if(publishFee > 0){
          // _safeOut(c,e,publishFee*p/decimals);
          require(erc20Coin.transfer(c,publishFee*p/decimals), "fail");
          
        }
        if(fee > 0){
          // _safeOut(KabukicoinWallte,e,fee*p/decimals);
          require(erc20Coin.transfer(KabukicoinWallte,fee*p/decimals), "fail");
        }
        if(recommendFee > 0){
          // _safeOut(r,e,recommendFee*p/decimals);
          require(erc20Coin.transfer(r,recommendFee*p/decimals), "fail");
        }
        
        if(n == 0){
          // _safeOut(c,e,(decimals-fee-publishFee-recommendFee)*p/decimals);
          gainCount = decimals - fee - publishFee - recommendFee;
          require(erc20Coin.transfer(c,gainCount*p/decimals), "fail");
        }else{
          // _safeOut(b,e,(1-fee-publishFee-recommendFee)*p/decimals);
          gainCount = decimals - fee - publishFee - recommendFee;
          require(erc20Coin.transfer(b,gainCount*p/decimals), "fail");
        }
        
      }else{
        if(publishFee > 0){
          Address.sendValue(payable(c),publishFee*p/decimals);
        }
        if(fee > 0){
          Address.sendValue(payable(KabukicoinWallte),publishFee*p/decimals);
        }
        if(recommendFee > 0){
          Address.sendValue(payable(r),recommendFee*p/decimals);
        }
        if(n == 0){
          gainCount = decimals - fee - publishFee - recommendFee;
          Address.sendValue(payable(c),gainCount*p/decimals);
        }else{
          gainCount = decimals - fee - publishFee - recommendFee;
          Address.sendValue(payable(b),gainCount*p/decimals);
        }
      }
    }
    function _checkPass(Order memory order,bytes[] memory signs) public view returns(bool){
      require(Address.isContract(order.token) && Address.isContract(order.art) && order.create/1000 < block.timestamp && order.sale/1000 < block.timestamp && !forbidSignature[signs[0]], "Illegal parameter !");
      bytes32 messageHash = getMsgHash(order);

      address signer = ECDSA.recover(getEthSignedMessageHash(messageHash), signs[0]);
      address createSigner = ECDSA.recover(getEthSignedMessageHash(keccak256(abi.encodePacked(order.id,order.create))), order.createrSign);
      NFTExchange memory signID = TradeRecord[order.art][order.id];
      // 判断NFT是否在当前平台交易过
      if(signID.nonce > 0){
        require(signer == signID.belong && createSigner == signID.creator, "You are not the owner !");
      }else{
        require(signer == createSigner,"Illegal parameter !");
      }
      return true;
    }
    function test2(Order memory order) public returns(address){
      NFTExchange memory signID = TradeRecord[order.art][order.id];
      _nBalance(order.nft,order.art,order.id,order.doer,signID.nonce);
      return order.art;
    }
    function test3(Order memory order) public {
      NFTExchange memory signID = TradeRecord[order.art][order.id];
      _erc20Transfer(order.token,order.price,order.gooder,signID.creator,signID.belong,signID.nonce);
    }
    function test4(Order memory order) public {
      NFTExchange memory signID = TradeRecord[order.art][order.id];
      _nTransfer(order.nft,order.art,signID.creator,signID.belong,order.id,signID.nonce);
    }
    // 0x0000000000000000000000000000000000000000
    function Buy(Order memory order,bytes[] memory signs) public returns (bool result){
      require(_checkPass(order,signs),'ERROR 403 !');
      NFTExchange memory signID = TradeRecord[order.art][order.id];
      /* // 过滤签名的时间戳小于当前时间戳
      //  
      require(Address.isContract(order.token) && Address.isContract(order.art) && order.create/1000 < block.timestamp && order.sale/1000 < block.timestamp && !forbidSignature[signs[0]], "Illegal parameter !");
      // 过滤NFT类型是否为ERC721或ERC1155

      // 过滤签名是否是卖家钱包地址进行的签名
      bytes32 messageHash = getMsgHash(order);

      address signer = ECDSA.recover(getEthSignedMessageHash(messageHash), signs[0]);
      address createSigner = ECDSA.recover(getEthSignedMessageHash(keccak256(abi.encodePacked(order.id,order.create))), order.createrSign);
      NFTExchange memory signID = TradeRecord[order.art][order.id];
      // 判断NFT是否在当前平台交易过
      if(signID.nonce > 0){
        require(signer == signID.belong && createSigner == signID.creator, "You are not the owner !");
      }else{
        require(signer == createSigner,"Illegal parameter !");
      } */
      _nBalance(order.nft,order.art,order.id,order.doer,signID.nonce);
      // erc20代币地址 价格 推荐地址 创建者 所属者 交易次数
      // 判断ETH还是ERC20购买
      _erc20Transfer(order.token,order.price,order.gooder,signID.creator,signID.belong,signID.nonce);
      _nTransfer(order.nft,order.art,signID.creator,signID.belong,order.id,signID.nonce);
      TradeRecord[order.art][order.id].nonce++;
      TradeRecord[order.art][order.id].belong = msg.sender;
      return true;
    }

    /* function Sell(Order memory order,bytes[] memory signs) public payable returns (bool result){
      
      return true;
    } */
    

}