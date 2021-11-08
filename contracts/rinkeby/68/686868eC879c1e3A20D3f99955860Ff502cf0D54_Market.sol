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
        require(_rate + _publishFee <= decimals, "set fail !");
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
    function getMsgHash(address[] memory addressGather,uint[] memory uintGather,string memory tradeType,string memory nftType) public view returns (bytes32){
      return keccak256(abi.encodePacked(
        addressGather[0],
        addressGather[1],
        addressGather[2],
        uintGather[0],
        uintGather[1],
        uintGather[2],
        tradeType,
        nftType,
        TradeRecord[addressGather[1]][uintGather[0]].creator,
        TradeRecord[addressGather[1]][uintGather[0]].nonce));
    }
    function _safeEnter(address _in,uint _amount) private {
        IERC20 formPlay = IERC20(_in);
        uint oldFromBalance = formPlay.balanceOf(address(this));
        uint oldSenderFromBalance = formPlay.balanceOf(msg.sender);
        require(formPlay.transferFrom(msg.sender,address(this),_amount), "fail");
        uint newFromBalance = formPlay.balanceOf(address(this));
        uint newSenderFromBalance = formPlay.balanceOf(msg.sender);
        require(newFromBalance == oldFromBalance + _amount,'get fail');
        require(oldSenderFromBalance == newSenderFromBalance + _amount,'get fail');
    }
    function _safeOut(address _target,address _out,uint _amount) private {
        IERC20 toPlay = IERC20(_out);
        uint _toAmount = _amount;
        uint oldToBalance = toPlay.balanceOf(address(this));
        uint oldSenderToBalance = toPlay.balanceOf(_target);
        toPlay.transfer(_target,_toAmount);
        uint newSenderToBalance = toPlay.balanceOf(_target);
        uint newToBalance = toPlay.balanceOf(address(this));
        require(oldToBalance == newToBalance + _toAmount,'extraction fail');
        require(newSenderToBalance == oldSenderToBalance + _toAmount,'extraction fail');
    }
    // [0x18ce6e87a1f8b87ae6b55f47651744295d25a55c,0x3E5d410cf8Ad70F4F44C3F2a6D3217e6d3B569AE,0x3E5d410cf8Ad70F4F44C3F2a6D3217e6d3B569AE]
    // [1,20,124324,234234]
    // Buy
    // 0xdb40d4d05bd54de0e38de4e38367483ed37bc32e852bf624a33b1db6a9f42608
    /** 
     * @param addressGather[0] 卖家地址
     * @param addressGather[1] NFT合约地址
     * @param addressGather[2] 购买使用的ERC20代币地址，如果是使用ETH交易地址为0x0
     * @param addressGather[3] 推荐者地址
     * @param uintGather[0]  NFT的tokenID
     * @param uintGather[1]  卖家设置的NFT出售价格
     * @param uintGather[2]  卖家设置出售价格的时间戳
     * @param uintGather[3]  卖家登录的时间戳
     * @param uintGather[4]  创建者创建的时间戳
     * @param tradeType[0]      交易类型 Buy,Sell
     * @param tradeType[1]      交易类型 ERC721,ERC1155
     * @param signatureGather[0]    卖家的消息签名
     * @param signatureGather[1]    创建者的签名
     */
    function Buy(
        address[] memory addressGather,
        uint[] memory uintGather,
        bytes[] memory signatureGather,
        string memory tradeType,
        string memory nftType
    ) public payable returns (bool result){
      require(Address.isContract(addressGather[2]), "Is not contract !");
      require(Address.isContract(addressGather[1]), "Is not contract !");
      // 过滤签名的时间戳小于当前时间戳
      require(uintGather[2]/1000 < block.timestamp , "Illegal parameter !");
      require(uintGather[4]/1000 < block.timestamp , "Illegal parameter !");
      // 过滤交易类型是否为Buy或Sell
      require(keccak256(abi.encodePacked(tradeType)) == keccak256(abi.encodePacked("Buy")), "Illegal parameter !");
      // 过滤NFT类型是否为ERC721或ERC1155
      require(keccak256(abi.encodePacked(nftType)) == keccak256(abi.encodePacked("ERC721")) || keccak256(abi.encodePacked(nftType)) == keccak256(abi.encodePacked("ERC1155")), "Illegal parameter !");
      // 过滤签名是否已经过期
      require(!forbidSignature[signatureGather[0]], "Forbid of signature !");

      // 过滤签名是否是卖家钱包地址进行的签名
      bytes32 messageHash = getMsgHash(addressGather,uintGather,tradeType,nftType);
      address signer = ECDSA.recover(getEthSignedMessageHash(messageHash), signatureGather[0]);
      address createSigner = ECDSA.recover(getEthSignedMessageHash(keccak256(abi.encodePacked(uintGather[0],uintGather[4]))), signatureGather[1]);

      // 判断NFT是否在当前平台交易过
      if(TradeRecord[addressGather[1]][uintGather[0]].nonce > 0){
        require(signer == TradeRecord[addressGather[1]][uintGather[0]].belong, "You are not the owner !");
        require(createSigner == TradeRecord[addressGather[1]][uintGather[0]].creator, "are not the creator !");
      }else{
        require(signer == createSigner,"Illegal parameter !");
        // TradeRecord[addressGather[1]][uintGather[0]]
        
      }

      // 判断NFT
      if(keccak256(abi.encodePacked(nftType)) == keccak256(abi.encodePacked("ERC721"))){
        IERC721 nft721Coin = IERC721(addressGather[1]);
        // 如果卖家钱包，NFT余额为0
        if(nft721Coin.ownerOf(uintGather[0]) != addressGather[0]){
          revert("You don't have this NFT !");
        }else{
          // 如果之前没有交易过当前买家就是创建者
          if(TradeRecord[addressGather[1]][uintGather[0]].nonce == 0){
              TradeRecord[addressGather[1]][uintGather[0]].creator = addressGather[0];
          }
          
        }
      }
      if(keccak256(abi.encodePacked(nftType)) == keccak256(abi.encodePacked("ERC1155"))){
        IERC1155 nft1155Coin = IERC1155(addressGather[1]);
        // 如果卖家钱包，NFT余额为0
        if(nft1155Coin.balanceOf(addressGather[0],uintGather[0]) < 1){
          // 如果NFT为平台NFT,且当前卖家余额为0，tokeniD为0，自动进行铸币
          if(OwnerERC1155 == addressGather[1]){
            require(!nft1155Coin.exist(uintGather[0]),"Already exists !");
            require(nft1155Coin.mint(addressGather[0],uintGather[0],bytes("")),"mint fail !");
            TradeRecord[addressGather[1]][uintGather[0]].creator = addressGather[0];
          }else{
            revert("You don't have this NFT !");
          }
        }else{
          // 如果之前没有交易过当前买家就是创建者
          if(TradeRecord[addressGather[1]][uintGather[0]].nonce == 0){
              TradeRecord[addressGather[1]][uintGather[0]].creator = addressGather[0];
          }
        }
      }
      
      // 判断ETH还是ERC20购买
      if(addressGather[2] != address(0)){
        // 是否开通交易的ERC20代币
        require(TransactionCurrency[addressGather[2]], "ERC20 Not opened");
        // 如果是ERC20判断余额是否足够
        IERC20 erc20Coin = IERC20(addressGather[2]);
        require(erc20Coin.balanceOf(msg.sender) < uintGather[1], "Insufficient Balance !");
        _safeEnter(addressGather[2],uintGather[1]);
        if(publishFee > 0){
          _safeOut(TradeRecord[addressGather[1]][uintGather[0]].creator,addressGather[2],publishFee*uintGather[1]/decimals);
        }
        if(fee > 0){
          _safeOut(addressGather[0],addressGather[2],fee*uintGather[1]/decimals);
        }
        if(recommendFee > 0){
          _safeOut(addressGather[3],addressGather[2],recommendFee*uintGather[1]/decimals);
        }
      }else{
        if(publishFee > 0){
          Address.sendValue(payable(TradeRecord[addressGather[1]][uintGather[0]].creator),publishFee*uintGather[1]/decimals);
        }
        if(fee > 0){
          Address.sendValue(payable(addressGather[0]),publishFee*uintGather[1]/decimals);
        }
        if(recommendFee > 0){
          Address.sendValue(payable(addressGather[3]),recommendFee*uintGather[1]/decimals);
        }
      }
      if(keccak256(abi.encodePacked(nftType)) == keccak256(abi.encodePacked("ERC1155"))){
        IERC1155 nft1155CoinEnd = IERC1155(addressGather[1]);
        nft1155CoinEnd.safeTransferFrom(addressGather[0],msg.sender,uintGather[0],1,bytes("0x0"));
        require(nft1155CoinEnd.balanceOf(msg.sender,uintGather[0]) > 0,"fail !");

      }
      if(keccak256(abi.encodePacked(nftType)) == keccak256(abi.encodePacked("ERC721"))){
        IERC721 nft721CoinEnd = IERC721(addressGather[1]);
        nft721CoinEnd.transferFrom(addressGather[0],msg.sender,uintGather[0]);
        require(nft721CoinEnd.ownerOf(uintGather[0]) == msg.sender,"fail!");
      }
      return true;
    }
    /** 
     * @param artToken   NFT合约地址
     * @param tokenID    NFT ID
     * @param buyer      买家地址
     * @param token      付款代币地址ERC20
     * @param _msg       买家出价签名的消息
     * @param signature  签名
     */
    /* function Sell(
        address artToken,
        uint tokenID,
        address buyer,
        address token,
        string memory _msg,
        bytes memory signature
    ) public payable returns (bool result){
       
    } */
    

}