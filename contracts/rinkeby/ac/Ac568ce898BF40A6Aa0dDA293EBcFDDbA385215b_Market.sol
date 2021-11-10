// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ECDSA.sol";
import "./Expend.sol";
contract Market is Expend {
    
    string public constant name = "Kabukicoin Market";
    // 可访问的,代理合约地址
    address public model;
    // market 合约地址
    address public market;
    // 过期的签名列表
    mapping(bytes => bool) public forbidSignature;
    
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
      uint end;
      bytes createrSign; // 创建者的签名
    }
    
    event Trade(address _buyer,address _seller,address _gooder,address _artToken,uint _tokenID,address _tradeToken,uint _price,uint _time,uint _trade);
    event SetProxy(address _oldProxy,address _newProxy);
    event CancelTrade(bytes[] signs);
    event TradeFinash(bytes[] signs);
    
    constructor (address _owner) Expend(_owner){}

    // 设置代理中心地址
    /* function setProxyModel(address _proxyModel) public onlyOwner {
        emit SetProxy(model,_proxyModel);
        model = _proxyModel;
    } */
    // 提币
    /* function withdraw(address _coin,address _to,uint _amount) public payable onlyOwner {
      if(_coin != address(0)){
        IERC20 erc20Coin = IERC20(_coin);
        require(erc20Coin.transfer(_to,_amount), "withdrawal fail");
      }else{
        Address.sendValue(payable(_to),_amount);
      }
    } */
    // 消息哈希  1:buyer 2:seller
    function getMsgHash(Order memory o,uint _who) public view returns (bytes32){
      bytes32 msghash;
      if(_who == 1){
        msghash = keccak256(abi.encodePacked(
        o.doer,
        o.art,
        o.token,
        o.gooder,
        o.id,
        o.price,
        o.sale,
        o.trade,
        o.end,
        TradeRecord[o.art][o.id].creator,
        TradeRecord[o.art][o.id].nonce));
      }else if(_who == 2){
        msghash = keccak256(abi.encodePacked(
        o.doer,
        o.art,
        o.token,
        o.id,
        o.price,
        o.sale,
        o.trade,
        o.end,
        TradeRecord[o.art][o.id].creator,
        TradeRecord[o.art][o.id].nonce));
      }else{
        revert('none !');
      }
      return msghash;
    }
    // 注销签名
    function cancelTrade(bytes[] memory signs,uint cancelType) public {
      for(uint i = 0;i < signs.length; i++){
        forbidSignature[signs[i]] = true;
      }
      if(cancelType == 1){
        emit CancelTrade(signs);
      }else if(cancelType == 2){
        emit TradeFinash(signs);
      }
    }
    /* 
    立即购买：
        参数一：[卖家地址,卖家签名的NFT合约,卖家签名的交易的代币或ETH,推荐者地址]
        参数二：[卖家签名的NFTID,卖家签名的价格,卖家签名的出售时间,创建者签名的NFT创建时间,卖家签名的交易类型,NFT类型,卖家签名的售卖结束时间]
        参数三：卖家设置价格的签名列表，第一个为最新的价格也是最低的 bytes[]
        参数四：创建者创建NFT的签名 bytes

        卖家签名内容：卖家地址,NFT合约,交易的代币或ETH,NFTID,价格,出售时间,交易类型,NFT类型,结束时间
        创建者签名内容：NFTID,创建时间


    竞拍出价:
        参数一: [出价者地址,NFT合约,交易的代币或ETH,出价者签名推荐地址]
        参数二: [NFTID,卖家签名的低价,卖家签名的出售时间,创建者签名的NFT创建时间,卖家签名的交易类型,NFT类型,卖家签名的售卖结束时间,出价者签名的报价,出价者签名的报价时间,出价者签名的报价结束时间]
        参数三: 卖家设置低价的签名列表，第一个为最新的价格也是最低的 bytes[]
        参数四: 创建者创建NFT的签名 bytes
        参数五: 出价签名列表，第一个为卖家选择的出价的签名 bytes[]

        卖家签名内容：卖家地址,NFT合约,交易的代币或ETH,NFTID,低价,出售时间,交易类型,NFT类型,结束时间
        出价者签名内容：出价地址,NFT合约,交易的代币或ETH,,NFTID,报价,报价时间,交易类型,NFT类型,报价结束时间,推荐地址
        创建者签名内容：NFTID,创建时间
        struct Order {
          address doer;      //参数一[0]
          address art;       //参数一[1]
          address token;     //参数一[2]  如果是使用ETH交易地址为0x0
          address gooder;    //参数一[3]
          uint id;           //参数二[0]
          uint price;        //参数二[1]
          uint sale;         //参数二[2]
          uint create;       //参数二[3]
          uint trade;        //参数二[4]  Buy:1 Sell:2
          uint nft;          //参数二[5]  erc721:721 erc1155:1155
          uint end;          //参数二[6]
          bytes createrSign; //参数四
        }
     */
    function trade(
        address[] memory ads,
        uint[] memory us,
        bytes[] memory ss,
        bytes memory cs,
        bytes[] memory bs
    ) public payable{
      require(us[5] == 721 || us[5] == 1155, "Illegal parameter !");
      if(us[4] == 1){
        // 立即购买
        Order memory o = Order(ads[0],ads[1],ads[2],ads[3],us[0],us[1],us[2],us[3],us[4],us[5],us[6],cs);
        // 签名检查
        _checkPass(o,ss,2);
        NFTExchange memory signID = TradeRecord[o.art][o.id];
        _nBalance(o.nft,o.art,o.id,o.doer,signID.nonce);
        _erc20Transfer(msg.sender,o.token,o.price,o.gooder,signID.creator,signID.belong,signID.nonce);
        _nTransfer(msg.sender,o.nft,o.art,signID.creator,signID.belong,o.id,signID.nonce);
        TradeRecord[o.art][o.id].nonce = signID.nonce + 1;
        TradeRecord[o.art][o.id].belong = msg.sender;
        cancelTrade(ss,2);
        emit Trade(msg.sender,o.doer,o.gooder,o.art,o.id,o.token,o.price,block.timestamp,1);
      }else if (us[4] == 2){
        /* // 出价竞拍
        Order memory b = Order(ads[0],ads[1],ads[2],ads[3],us[0],us[7],us[8],us[3],us[4],us[5],us[9],cs);
        Order memory o = Order(msg.sender,ads[1],ads[2],ads[3],us[0],us[1],us[2],us[3],us[4],us[5],us[6],cs);
        // 签名检查
        _checkPass(o,ss,2);
        _checkPass(b,bs,1);
        NFTExchange memory signID = TradeRecord[o.art][o.id];
        // 检查卖家是否有交易的nft,如果是平台nft，没有则自动铸造
        _nBalance(o.nft,o.art,o.id,o.doer,signID.nonce);
        // erc20或eth转账
        _erc20Transfer(b.doer,o.token,b.price,b.gooder,signID.creator,signID.belong,signID.nonce);
        // nft转账
        _nTransfer(b.doer,o.nft,o.art,signID.creator,signID.belong,o.id,signID.nonce);
        // 记录交易后的所属关系
        TradeRecord[o.art][o.id].nonce = signID.nonce + 1;
        TradeRecord[o.art][o.id].belong = b.doer;
        // 销毁这次交易中所有签名
        cancelTrade(bs,2);
        cancelTrade(ss,2);
        emit Trade(b.doer,msg.sender,o.gooder,o.art,o.id,o.token,o.price,block.timestamp,2); */
      }else{
        revert("not have trade type !");
      }
    }
    function _checkPass(Order memory order,bytes[] memory signs,uint _who) public view returns(bool){
      require(order.end/1000 <= block.timestamp && Address.isContract(order.token) && Address.isContract(order.art) && order.create/1000 < block.timestamp && order.sale/1000 < block.timestamp && !forbidSignature[signs[0]], "Illegal parameter !");
      bytes32 messageHash = getMsgHash(order,_who);
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
}