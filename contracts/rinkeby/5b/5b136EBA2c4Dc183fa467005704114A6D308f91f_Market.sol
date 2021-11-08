// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './IERC721.sol';
import './IERC1155.sol';
import './InitOwner.sol';
import "./ECDSA.sol";

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

    string public constant name = "Kabukicoin Market";
    // 可访问的,代理合约地址
    address public model;
    // 所属于的ERC1155合约地址
    address public OwnerERC1155;
    // Kabukicoin钱包地址
    address KabukicoinWallte;
    // 过期的签名列表
    mapping(bytes => bool) public forbidSignature;
    // NFT交易
    struct NFTExchange{
        address creator;
        address belong;
        uint nonce;
    }
    // 索引NFT
    mapping(address => mapping(uint => NFTExchange)) public TradeRecord;

    event Trade(address _buyer,address _seller,address _artToken,uint _tokenID,address _tradeToken,uint _price);
    constructor (address _owner)
    {   
        initOwner(_owner);
    }
    // 设置代理中心地址
    function setProxyModel(address _proxyModel) public onlyOwner {
        model = _proxyModel;
    }
    // 设置Kabukicoin钱包地址
    function setWallet(address _wallet) public onlyOwner {
        KabukicoinWallte = _wallet;
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
    function getMsgHash(address[] memory addressGather,uint[] memory uintGather,string memory tradeType) public view returns (bytes32){
      return keccak256(abi.encodePacked(
        addressGather[0],
        addressGather[1],
        addressGather[2],
        uintGather[0],
        uintGather[1],
        uintGather[2],
        tradeType,
        TradeRecord[addressGather[1]][uintGather[0]].creator,
        TradeRecord[addressGather[1]][uintGather[0]].nonce));
    }
    // [0x18ce6e87a1f8b87ae6b55f47651744295d25a55c,0x3E5d410cf8Ad70F4F44C3F2a6D3217e6d3B569AE,0x3E5d410cf8Ad70F4F44C3F2a6D3217e6d3B569AE]
    // [1,20,124324,234234]
    // Buy
    // 0xdb40d4d05bd54de0e38de4e38367483ed37bc32e852bf624a33b1db6a9f42608
    /** 
     * @param addressGather[0] 买家地址
     * @param addressGather[1] NFT合约地址
     * @param addressGather[2] 购买使用的ERC20代币地址，如果是使用ETH交易地址为0x0
     * @param uintGather[0]  NFT的tokenID
     * @param uintGather[1]  买家设置的NFT出售价格
     * @param uintGather[2]  买家设置出售价格的时间戳
     * @param uintGather[3]  买家登录的时间戳
     * @param tradeType      交易类型 Buy,Sell
     * @param signatureGather[0]    买家的消息签名
     * @param signatureGather[1]    买家的登录签名
     */
    function Buy(
        address[] memory addressGather,
        uint[] memory uintGather,
        bytes[] memory signatureGather,
        string memory tradeType,
        bytes32 clouTokenHash
    ) public payable returns (bool result){
      // 过滤签名的时间戳小于当前时间戳
      require(uintGather[2]/1000 < block.timestamp , "Illegal parameter !");
      // 过滤交易类型是否为Buy或Sell
      require(keccak256(abi.encodePacked(tradeType)) == keccak256(abi.encodePacked("Buy")), "Illegal parameter !");
      // 过滤签名是否已经过期
      require(!forbidSignature[signatureGather[0]], "Forbid of signature !");
      // 过滤签名是否是买家进行的签名
      bytes32 messageHash = getMsgHash(addressGather,uintGather,tradeType);
      address signer = ECDSA.recover(getEthSignedMessageHash(messageHash), signatureGather[0]);
      require(signer == addressGather[0], "You are not the owner !");
      if(TradeRecord[addressGather[1]][uintGather[0]].nonce > 0){
        require(signer == TradeRecord[addressGather[1]][uintGather[0]].belong, "You are not the owner !");
      }
      // 检查买家签名时是否为登录状态
      address signerLogin = ECDSA.recover(getEthSignedMessageHash(keccak256(abi.encodePacked(clouTokenHash,uintGather[3]))),signatureGather[1]);
      require(signerLogin == addressGather[0], "You are not the owner !");

      // 通过交易次数0,判断创建者
      // 交易前获取交易币种精度
      // 判断ETH还是ERC20购买
      if(addressGather[2] == address(0)){

      }else{

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