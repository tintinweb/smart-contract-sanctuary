/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Interfaces
interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _to, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address operator);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// Abstract Contracts
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        owner = _newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// Contract
contract Yoji is Ownable, ReentrancyGuard {
    // ERC721
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // ERC721Metadata
    string public name = 'Yoji Kanji'; // ToDo: To be set
    string public symbol = 'YOJI'; // ToDo: To be set
    string public baseURI = 'https://yoji.link/metadata/'; // ToDo: To be set

    // ERC721Enumerable
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    
    // Customized
    uint256 public tokenPrice = 30000000000000000; // 0.03 ETH ToDo: To be set
    uint256 private limitedSold = 0;
    uint256 private nonce;
    address private uniswapV2Pair = 0x0000000000000000000000000000000000000000; // ToDo: To be set
    uint256 private constant MASK = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;
    uint256 private constant NUM_CHARS = 2136;
    uint256 private constant NUM_LIMITED_SALE = 1000; // ToDo: To be set
    string private chars = '\u4e9c\u54c0\u6328\u611b\u66d6\u60aa\u63e1\u5727\u6271\u5b9b\u5d50\u5b89\u6848\u6697\u4ee5\u8863\u4f4d\u56f2\u533b\u4f9d\u59d4\u5a01\u70ba\u754f\u80c3\u5c09\u7570\u79fb\u840e\u5049\u6905\u5f59\u610f\u9055\u7dad\u6170\u907a\u7def\u57df\u80b2\u4e00\u58f1\u9038\u8328\u828b\u5f15\u5370\u56e0\u54bd\u59fb\u54e1\u9662\u6deb\u9670\u98f2\u96a0\u97fb\u53f3\u5b87\u7fbd\u96e8\u5504\u9b31\u755d\u6d66\u904b\u96f2\u6c38\u6cf3\u82f1\u6620\u6804\u55b6\u8a60\u5f71\u92ed\u885b\u6613\u75ab\u76ca\u6db2\u99c5\u60a6\u8d8a\u8b01\u95b2\u5186\u5ef6\u6cbf\u708e\u6028\u5bb4\u5a9b\u63f4\u5712\u7159\u733f\u9060\u925b\u5869\u6f14\u7e01\u8276\u6c5a\u738b\u51f9\u592e\u5fdc\u5f80\u62bc\u65fa\u6b27\u6bb4\u685c\u7fc1\u5965\u6a2a\u5ca1\u5c4b\u5104\u61b6\u81c6\u865e\u4e59\u4ffa\u5378\u97f3\u6069\u6e29\u7a4f\u4e0b\u5316\u706b\u52a0\u53ef\u4eee\u4f55\u82b1\u4f73\u4fa1\u679c\u6cb3\u82db\u79d1\u67b6\u590f\u5bb6\u8377\u83ef\u83d3\u8ca8\u6e26\u904e\u5ac1\u6687\u798d\u9774\u5be1\u6b4c\u7b87\u7a3c\u8ab2\u868a\u7259\u74e6\u6211\u753b\u82bd\u8cc0\u96c5\u9913\u4ecb\u56de\u7070\u4f1a\u5feb\u6212\u6539\u602a\u62d0\u6094\u6d77\u754c\u7686\u68b0\u7d75\u958b\u968e\u584a\u6977\u89e3\u6f70\u58ca\u61d0\u8ae7\u8c9d\u5916\u52be\u5bb3\u5d16\u6daf\u8857\u6168\u84cb\u8a72\u6982\u9ab8\u57a3\u67ff\u5404\u89d2\u62e1\u9769\u683c\u6838\u6bbb\u90ed\u899a\u8f03\u9694\u95a3\u78ba\u7372\u5687\u7a6b\u5b66\u5cb3\u697d\u984d\u984e\u639b\u6f5f\u62ec\u6d3b\u559d\u6e07\u5272\u845b\u6ed1\u8910\u8f44\u4e14\u682a\u91dc\u938c\u5208\u5e72\u520a\u7518\u6c57\u7f36\u5b8c\u809d\u5b98\u51a0\u5dfb\u770b\u9665\u4e7e\u52d8\u60a3\u8cab\u5bd2\u559a\u582a\u63db\u6562\u68fa\u6b3e\u9593\u9591\u52e7\u5bdb\u5e79\u611f\u6f22\u6163\u7ba1\u95a2\u6b53\u76e3\u7de9\u61be\u9084\u9928\u74b0\u7c21\u89b3\u97d3\u8266\u9451\u4e38\u542b\u5cb8\u5ca9\u73a9\u773c\u9811\u9854\u9858\u4f01\u4f0e\u5371\u673a\u6c17\u5c90\u5e0c\u5fcc\u6c7d\u5947\u7948\u5b63\u7d00\u8ecc\u65e2\u8a18\u8d77\u98e2\u9b3c\u5e30\u57fa\u5bc4\u898f\u4e80\u559c\u5e7e\u63ee\u671f\u68cb\u8cb4\u68c4\u6bc0\u65d7\u5668\u757f\u8f1d\u6a5f\u9a0e\u6280\u5b9c\u507d\u6b3a\u7fa9\u7591\u5100\u622f\u64ec\u72a0\u8b70\u83ca\u5409\u55ab\u8a70\u5374\u5ba2\u811a\u9006\u8650\u4e5d\u4e45\u53ca\u5f13\u4e18\u65e7\u4f11\u5438\u673d\u81fc\u6c42\u7a76\u6ce3\u6025\u7d1a\u7cfe\u5bae\u6551\u7403\u7d66\u55c5\u7aae\u725b\u53bb\u5de8\u5c45\u62d2\u62e0\u6319\u865a\u8a31\u8ddd\u9b5a\u5fa1\u6f01\u51f6\u5171\u53eb\u72c2\u4eac\u4eab\u4f9b\u5354\u6cc1\u5ce1\u631f\u72ed\u6050\u606d\u80f8\u8105\u5f37\u6559\u90f7\u5883\u6a4b\u77ef\u93e1\u7af6\u97ff\u9a5a\u4ef0\u6681\u696d\u51dd\u66f2\u5c40\u6975\u7389\u5dfe\u65a4\u5747\u8fd1\u91d1\u83cc\u52e4\u7434\u7b4b\u50c5\u7981\u7dca\u9326\u8b39\u895f\u541f\u9280\u533a\u53e5\u82e6\u99c6\u5177\u60e7\u611a\u7a7a\u5076\u9047\u9685\u4e32\u5c48\u6398\u7a9f\u718a\u7e70\u541b\u8a13\u52f2\u85ab\u8ecd\u90e1\u7fa4\u5144\u5211\u5f62\u7cfb\u5f84\u830e\u4fc2\u578b\u5951\u8a08\u6075\u5553\u63b2\u6e13\u7d4c\u86cd\u656c\u666f\u8efd\u50be\u643a\u7d99\u8a63\u6176\u61ac\u7a3d\u61a9\u8b66\u9d8f\u82b8\u8fce\u9be8\u9699\u5287\u6483\u6fc0\u6841\u6b20\u7a74\u8840\u6c7a\u7d50\u5091\u6f54\u6708\u72ac\u4ef6\u898b\u5238\u80a9\u5efa\u7814\u770c\u5039\u517c\u5263\u62f3\u8ed2\u5065\u967a\u570f\u5805\u691c\u5acc\u732e\u7d79\u9063\u6a29\u61b2\u8ce2\u8b19\u9375\u7e6d\u9855\u9a13\u61f8\u5143\u5e7b\u7384\u8a00\u5f26\u9650\u539f\u73fe\u8237\u6e1b\u6e90\u53b3\u5df1\u6238\u53e4\u547c\u56fa\u80a1\u864e\u5b64\u5f27\u6545\u67af\u500b\u5eab\u6e56\u96c7\u8a87\u9f13\u932e\u9867\u4e94\u4e92\u5348\u5449\u5f8c\u5a2f\u609f\u7881\u8a9e\u8aa4\u8b77\u53e3\u5de5\u516c\u52fe\u5b54\u529f\u5de7\u5e83\u7532\u4ea4\u5149\u5411\u540e\u597d\u6c5f\u8003\u884c\u5751\u5b5d\u6297\u653b\u66f4\u52b9\u5e78\u62d8\u80af\u4faf\u539a\u6052\u6d2a\u7687\u7d05\u8352\u90ca\u9999\u5019\u6821\u8015\u822a\u8ca2\u964d\u9ad8\u5eb7\u63a7\u6897\u9ec4\u5589\u614c\u6e2f\u786c\u7d5e\u9805\u6e9d\u9271\u69cb\u7db1\u9175\u7a3f\u8208\u8861\u92fc\u8b1b\u8cfc\u4e5e\u53f7\u5408\u62f7\u525b\u50b2\u8c6a\u514b\u544a\u8c37\u523b\u56fd\u9ed2\u7a40\u9177\u7344\u9aa8\u99d2\u8fbc\u9803\u4eca\u56f0\u6606\u6068\u6839\u5a5a\u6df7\u75d5\u7d3a\u9b42\u58be\u61c7\u5de6\u4f50\u6c99\u67fb\u7802\u5506\u5dee\u8a50\u9396\u5ea7\u632b\u624d\u518d\u707d\u59bb\u91c7\u7815\u5bb0\u683d\u5f69\u63a1\u6e08\u796d\u658e\u7d30\u83dc\u6700\u88c1\u50b5\u50ac\u585e\u6b73\u8f09\u969b\u57fc\u5728\u6750\u5264\u8ca1\u7f6a\u5d0e\u4f5c\u524a\u6628\u67f5\u7d22\u7b56\u9162\u643e\u932f\u54b2\u518a\u672d\u5237\u5239\u62f6\u6bba\u5bdf\u64ae\u64e6\u96d1\u76bf\u4e09\u5c71\u53c2\u685f\u8695\u60e8\u7523\u5098\u6563\u7b97\u9178\u8cdb\u6b8b\u65ac\u66ab\u58eb\u5b50\u652f\u6b62\u6c0f\u4ed5\u53f2\u53f8\u56db\u5e02\u77e2\u65e8\u6b7b\u7cf8\u81f3\u4f3a\u5fd7\u79c1\u4f7f\u523a\u59cb\u59c9\u679d\u7949\u80a2\u59ff\u601d\u6307\u65bd\u5e2b\u6063\u7d19\u8102\u8996\u7d2b\u8a5e\u6b6f\u55e3\u8a66\u8a69\u8cc7\u98fc\u8a8c\u96cc\u646f\u8cdc\u8aee\u793a\u5b57\u5bfa\u6b21\u8033\u81ea\u4f3c\u5150\u4e8b\u4f8d\u6cbb\u6301\u6642\u6ecb\u6148\u8f9e\u78c1\u990c\u74bd\u9e7f\u5f0f\u8b58\u8ef8\u4e03\u0b9f\u5931\u5ba4\u75be\u57f7\u6e7f\u5ac9\u6f06\u8cea\u5b9f\u829d\u5199\u793e\u8eca\u820e\u8005\u5c04\u6368\u8d66\u659c\u716e\u906e\u8b1d\u90aa\u86c7\u5c3a\u501f\u914c\u91c8\u7235\u82e5\u5f31\u5bc2\u624b\u4e3b\u5b88\u6731\u53d6\u72e9\u9996\u6b8a\u73e0\u9152\u816b\u7a2e\u8da3\u5bff\u53d7\u546a\u6388\u9700\u5112\u6a39\u53ce\u56da\u5dde\u821f\u79c0\u5468\u5b97\u62fe\u79cb\u81ed\u4fee\u8896\u7d42\u7f9e\u7fd2\u9031\u5c31\u8846\u96c6\u6101\u916c\u919c\u8e74\u8972\u5341\u6c41\u5145\u4f4f\u67d4\u91cd\u5f93\u6e0b\u9283\u7363\u7e26\u53d4\u795d\u5bbf\u6dd1\u7c9b\u7e2e\u587e\u719f\u51fa\u8ff0\u8853\u4fca\u6625\u77ac\u65ec\u5de1\u76fe\u51c6\u6b89\u7d14\u5faa\u9806\u6e96\u6f64\u9075\u51e6\u521d\u6240\u66f8\u5eb6\u6691\u7f72\u7dd2\u8af8\u5973\u5982\u52a9\u5e8f\u53d9\u5f90\u9664\u5c0f\u5347\u5c11\u53ec\u5320\u5e8a\u6284\u8096\u5c1a\u62db\u627f\u6607\u677e\u6cbc\u662d\u5bb5\u5c06\u6d88\u75c7\u7965\u79f0\u7b11\u5531\u5546\u6e09\u7ae0\u7d39\u8a1f\u52dd\u638c\u6676\u713c\u7126\u785d\u7ca7\u8a54\u8a3c\u8c61\u50b7\u5968\u7167\u8a73\u5f70\u969c\u61a7\u885d\u8cde\u511f\u7901\u9418\u4e0a\u4e08\u5197\u6761\u72b6\u4e57\u57ce\u6d44\u5270\u5e38\u60c5\u5834\u7573\u84b8\u7e04\u58cc\u5b22\u9320\u8b72\u91b8\u8272\u62ed\u98df\u690d\u6b96\u98fe\u89e6\u5631\u7e54\u8077\u8fb1\u5c3b\u5fc3\u7533\u4f38\u81e3\u82af\u8eab\u8f9b\u4fb5\u4fe1\u6d25\u795e\u5507\u5a20\u632f\u6d78\u771f\u91dd\u6df1\u7d33\u9032\u68ee\u8a3a\u5bdd\u614e\u65b0\u5be9\u9707\u85aa\u89aa\u4eba\u5203\u4ec1\u5c3d\u8fc5\u751a\u9663\u5c0b\u814e\u9808\u56f3\u6c34\u5439\u5782\u708a\u5e25\u7c8b\u8870\u63a8\u9154\u9042\u7761\u7a42\u968f\u9ac4\u67a2\u5d07\u6570\u636e\u6749\u88fe\u5bf8\u702c\u662f\u4e95\u4e16\u6b63\u751f\u6210\u897f\u58f0\u5236\u59d3\u5f81\u6027\u9752\u6589\u653f\u661f\u7272\u7701\u51c4\u901d\u6e05\u76db\u5a7f\u6674\u52e2\u8056\u8aa0\u7cbe\u88fd\u8a93\u9759\u8acb\u6574\u9192\u7a0e\u5915\u65a5\u77f3\u8d64\u6614\u6790\u5e2d\u810a\u96bb\u60dc\u621a\u8cac\u8de1\u7a4d\u7e3e\u7c4d\u5207\u6298\u62d9\u7a83\u63a5\u8a2d\u96ea\u6442\u7bc0\u8aac\u820c\u7d76\u5343\u5ddd\u4ed9\u5360\u5148\u5ba3\u5c02\u6cc9\u6d45\u6d17\u67d3\u6247\u6813\u65cb\u8239\u6226\u714e\u7fa8\u817a\u8a6e\u8df5\u7b8b\u92ad\u6f5c\u7dda\u9077\u9078\u85a6\u7e4a\u9bae\u5168\u524d\u5584\u7136\u7985\u6f38\u81b3\u7e55\u72d9\u963b\u7956\u79df\u7d20\u63aa\u7c97\u7d44\u758e\u8a34\u5851\u9061\u790e\u53cc\u58ee\u65e9\u4e89\u8d70\u594f\u76f8\u8358\u8349\u9001\u5009\u635c\u633f\u6851\u5de3\u6383\u66f9\u66fd\u723d\u7a93\u5275\u55aa\u75e9\u846c\u88c5\u50e7\u60f3\u5c64\u7dcf\u906d\u69fd\u8e2a\u64cd\u71e5\u971c\u9a12\u85fb\u9020\u50cf\u5897\u618e\u8535\u8d08\u81d3\u5373\u675f\u8db3\u4fc3\u5247\u606f\u6349\u901f\u5074\u6e2c\u4fd7\u65cf\u5c5e\u8cca\u7d9a\u5352\u7387\u5b58\u6751\u5b6b\u5c0a\u640d\u905c\u4ed6\u591a\u6c70\u6253\u59a5\u553e\u5815\u60f0\u99c4\u592a\u5bfe\u4f53\u8010\u5f85\u6020\u80ce\u9000\u5e2f\u6cf0\u5806\u888b\u902e\u66ff\u8cb8\u968a\u6ede\u614b\u6234\u5927\u4ee3\u53f0\u7b2c\u984c\u6edd\u5b85\u629e\u6ca2\u5353\u62d3\u8a17\u6fef\u8afe\u6fc1\u4f46\u9054\u8131\u596a\u68da\u8ab0\u4e39\u65e6\u62c5\u5358\u70ad\u80c6\u63a2\u6de1\u77ed\u5606\u7aef\u7dbb\u8a95\u935b\u56e3\u7537\u6bb5\u65ad\u5f3e\u6696\u8ac7\u58c7\u5730\u6c60\u77e5\u5024\u6065\u81f4\u9045\u75f4\u7a1a\u7f6e\u7dfb\u7af9\u755c\u9010\u84c4\u7bc9\u79e9\u7a92\u8336\u7740\u5ae1\u4e2d\u4ef2\u866b\u6c96\u5b99\u5fe0\u62bd\u6ce8\u663c\u67f1\u8877\u914e\u92f3\u99d0\u8457\u8caf\u4e01\u5f14\u5e81\u5146\u753a\u9577\u6311\u5e33\u5f35\u5f6b\u773a\u91e3\u9802\u9ce5\u671d\u8cbc\u8d85\u8178\u8df3\u5fb4\u5632\u6f6e\u6f84\u8abf\u8074\u61f2\u76f4\u52c5\u6357\u6c88\u73cd\u6715\u9673\u8cc3\u93ae\u8ffd\u690e\u589c\u901a\u75db\u585a\u6f2c\u576a\u722a\u9db4\u4f4e\u5448\u5ef7\u5f1f\u5b9a\u5e95\u62b5\u90b8\u4ead\u8c9e\u5e1d\u8a02\u5ead\u9013\u505c\u5075\u5824\u63d0\u7a0b\u8247\u7de0\u8ae6\u6ce5\u7684\u7b1b\u6458\u6ef4\u9069\u6575\u6eba\u8fed\u54f2\u9244\u5fb9\u64a4\u5929\u5178\u5e97\u70b9\u5c55\u6dfb\u8ee2\u5861\u7530\u4f1d\u6bbf\u96fb\u6597\u5410\u59ac\u5f92\u9014\u90fd\u6e21\u5857\u8ced\u571f\u5974\u52aa\u5ea6\u6012\u5200\u51ac\u706f\u5f53\u6295\u8c46\u6771\u5230\u9003\u5012\u51cd\u5510\u5cf6\u6843\u8a0e\u900f\u515a\u60bc\u76d7\u9676\u5854\u642d\u68df\u6e6f\u75d8\u767b\u7b54\u7b49\u7b52\u7d71\u7a32\u8e0f\u7cd6\u982d\u8b04\u85e4\u95d8\u9a30\u540c\u6d1e\u80f4\u52d5\u5802\u7ae5\u9053\u50cd\u9285\u5c0e\u77b3\u5ce0\u533f\u7279\u5f97\u7763\u5fb3\u7be4\u6bd2\u72ec\u8aad\u6803\u51f8\u7a81\u5c4a\u5c6f\u8c5a\u9813\u8caa\u920d\u66c7\u4e3c\u90a3\u5948\u5185\u68a8\u8b0e\u934b\u5357\u8edf\u96e3\u4e8c\u5c3c\u5f10\u5302\u8089\u8679\u65e5\u5165\u4e73\u5c3f\u4efb\u598a\u5fcd\u8a8d\u5be7\u71b1\u5e74\u5ff5\u637b\u7c98\u71c3\u60a9\u7d0d\u80fd\u8133\u8fb2\u6fc3\u628a\u6ce2\u6d3e\u7834\u8987\u99ac\u5a46\u7f75\u62dd\u676f\u80cc\u80ba\u4ff3\u914d\u6392\u6557\u5ec3\u8f29\u58f2\u500d\u6885\u57f9\u966a\u5a92\u8cb7\u8ce0\u767d\u4f2f\u62cd\u6cca\u8feb\u525d\u8236\u535a\u8584\u9ea6\u6f20\u7e1b\u7206\u7bb1\u7bb8\u7551\u808c\u516b\u9262\u767a\u9aea\u4f10\u629c\u7f70\u95a5\u53cd\u534a\u6c3e\u72af\u5e06\u6c4e\u4f34\u5224\u5742\u962a\u677f\u7248\u73ed\u7554\u822c\u8ca9\u6591\u98ef\u642c\u7169\u9812\u7bc4\u7e41\u85e9\u6669\u756a\u86ee\u76e4\u6bd4\u76ae\u5983\u5426\u6279\u5f7c\u62ab\u80a5\u975e\u5351\u98db\u75b2\u79d8\u88ab\u60b2\u6249\u8cbb\u7891\u7f77\u907f\u5c3e\u7709\u7f8e\u5099\u5fae\u9f3b\u819d\u8098\u5339\u5fc5\u6ccc\u7b46\u59eb\u767e\u6c37\u8868\u4ff5\u7968\u8a55\u6f02\u6a19\u82d7\u79d2\u75c5\u63cf\u732b\u54c1\u6d5c\u8ca7\u8cd3\u983b\u654f\u74f6\u4e0d\u592b\u7236\u4ed8\u5e03\u6276\u5e9c\u6016\u961c\u9644\u8a03\u8ca0\u8d74\u6d6e\u5a66\u7b26\u5bcc\u666e\u8150\u6577\u819a\u8ce6\u8b5c\u4fae\u6b66\u90e8\u821e\u5c01\u98a8\u4f0f\u670d\u526f\u5e45\u5fa9\u798f\u8179\u8907\u8986\u6255\u6cb8\u4ecf\u7269\u7c89\u7d1b\u96f0\u5674\u58b3\u61a4\u596e\u5206\u6587\u805e\u4e19\u5e73\u5175\u4f75\u4e26\u67c4\u965b\u9589\u5840\u5e63\u5f0a\u853d\u9905\u7c73\u58c1\u74a7\u7656\u5225\u8511\u7247\u8fba\u8fd4\u5909\u504f\u904d\u7de8\u5f01\u4fbf\u52c9\u6b69\u4fdd\u54fa\u6355\u88dc\u8217\u6bcd\u52df\u5893\u6155\u66ae\u7c3f\u65b9\u5305\u82b3\u90a6\u5949\u5b9d\u62b1\u653e\u6cd5\u6ce1\u80de\u4ff8\u5023\u5cf0\u7832\u5d29\u8a2a\u5831\u8702\u8c4a\u98fd\u8912\u7e2b\u4ea1\u4e4f\u5fd9\u574a\u59a8\u5fd8\u9632\u623f\u80aa\u67d0\u5192\u5256\u7d21\u671b\u508d\u5e3d\u68d2\u8cbf\u8c8c\u66b4\u81a8\u8b00\u9830\u5317\u6728\u6734\u7267\u7766\u50d5\u58a8\u64b2\u6ca1\u52c3\u5800\u672c\u5954\u7ffb\u51e1\u76c6\u9ebb\u6469\u78e8\u9b54\u6bce\u59b9\u679a\u6627\u57cb\u5e55\u819c\u6795\u53c8\u672b\u62b9\u4e07\u6e80\u6162\u6f2b\u672a\u5473\u9b45\u5cac\u5bc6\u871c\u8108\u5999\u6c11\u7720\u77db\u52d9\u7121\u5922\u9727\u5a18\u540d\u547d\u660e\u8ff7\u51a5\u76df\u9298\u9cf4\u6ec5\u514d\u9762\u7dbf\u9eba\u8302\u6a21\u6bdb\u5984\u76f2\u8017\u731b\u7db2\u76ee\u9ed9\u9580\u7d0b\u554f\u51b6\u591c\u91ce\u5f25\u5384\u5f79\u7d04\u8a33\u85ac\u8e8d\u95c7\u7531\u6cb9\u55a9\u6109\u8aed\u8f38\u7652\u552f\u53cb\u6709\u52c7\u5e7d\u60a0\u90f5\u6e67\u7336\u88d5\u904a\u96c4\u8a98\u6182\u878d\u512a\u4e0e\u4e88\u4f59\u8a89\u9810\u5e7c\u7528\u7f8a\u5996\u6d0b\u8981\u5bb9\u5eb8\u63da\u63fa\u8449\u967d\u6eb6\u8170\u69d8\u760d\u8e0a\u7aaf\u990a\u64c1\u8b21\u66dc\u6291\u6c83\u6d74\u6b32\u7fcc\u7ffc\u62c9\u88f8\u7f85\u6765\u96f7\u983c\u7d61\u843d\u916a\u8fa3\u4e71\u5375\u89a7\u6feb\u85cd\u6b04\u540f\u5229\u91cc\u7406\u75e2\u88cf\u5c65\u7483\u96e2\u9678\u7acb\u5f8b\u6144\u7565\u67f3\u6d41\u7559\u7adc\u7c92\u9686\u786b\u4fb6\u65c5\u865c\u616e\u4e86\u4e21\u826f\u6599\u6dbc\u731f\u9675\u91cf\u50da\u9818\u5bee\u7642\u77ad\u7ce7\u529b\u7dd1\u6797\u5398\u502b\u8f2a\u96a3\u81e8\u7460\u6d99\u7d2f\u5841\u985e\u4ee4\u793c\u51b7\u52b1\u623b\u4f8b\u9234\u96f6\u970a\u96b7\u9f62\u9e97\u66a6\u6b74\u5217\u52a3\u70c8\u88c2\u604b\u9023\u5ec9\u7df4\u932c\u5442\u7089\u8cc2\u8def\u9732\u8001\u52b4\u5f04\u90ce\u6717\u6d6a\u5eca\u697c\u6f0f\u7c60\u516d\u9332\u9e93\u8ad6\u548c\u8a71\u8cc4\u8107\u60d1\u67a0\u6e7e\u8155';

    // Constructor
    constructor() {}

    // ERC165
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Customized (public)
    modifier limitedSaleable {
        require(limitedSold < NUM_LIMITED_SALE, "LimitedSale: limited sale is over");
        _;
    }

    function setTokenPrice(uint256 _price) public onlyOwner returns (bool) {
        tokenPrice = _price;
        return true;
    }

    function setUniswapV2Pair(address _pair) public onlyOwner returns (bool) {
        uniswapV2Pair = _pair;
        return true;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner returns (bool) {
        baseURI = _baseURI;
        return true;
    }

    function buy() public payable nonReentrant returns (bool) {
        require(msg.value >= tokenPrice, 'Customized: msg.value is less than tokenPrice');
        uint256 tokenId = random();
        _mint(msg.sender, tokenId);
        nonce = nonce + 1;
        
        // refund
        if(msg.value > tokenPrice) {
            payable(msg.sender).transfer(msg.value - tokenPrice);
        }

        return true;
    }

    function buy(uint256 _tokenId) public payable nonReentrant limitedSaleable returns (bool) {
        require(msg.value >= tokenPrice, 'Customized: msg.value is less than tokenPrice');
        _mint(msg.sender, _tokenId);
        
        // refund
        if(msg.value > tokenPrice) {
            payable(msg.sender).transfer(msg.value - tokenPrice);
        }

        return true;
    } 

    // Customized (private)
    function random() private view returns (uint256) { // ToDo: make it private
        return uint256(keccak256(abi.encodePacked(msg.sender, nonce, blockhash(block.number), externalSeeds())));
    }

    function externalSeeds() private view returns (bytes32) { // ToDo: make it private
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        return keccak256(abi.encodePacked(reserve0, reserve1, blockTimestampLast));
    }
    
    // ERC721 (public)
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public returns (bool) {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
        return true;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public returns (bool) {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
        return true;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public returns (bool) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        return true;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public returns (bool) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        return true;
    }

    // ERC721 (private)
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) private {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) private {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) private {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) private {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // ERC721Metadata
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        //require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }

    function tokenIdToUnicode(uint256 _tokenId) public view returns (string memory) {
        uint256 char4 = (_tokenId & MASK) % NUM_CHARS;
        uint256 char3 = ((_tokenId / 0x0000000000000000000000000000000000000000000000010000000000000000) & MASK) % NUM_CHARS;
        uint256 char2 = ((_tokenId / 0x0000000000000000000000000000000100000000000000000000000000000000) & MASK) % NUM_CHARS;
        uint256 char1 = ((_tokenId / 0x0000000000000001000000000000000000000000000000000000000000000000) & MASK) % NUM_CHARS;
        return string(abi.encodePacked(charAt(char1), charAt(char2), charAt(char3), charAt(char4)));
    }

    function charAt(uint256 i) private view returns (string memory) {
        bytes memory strBytes = bytes(chars);
        return string(abi.encodePacked(strBytes[i*3], strBytes[i*3+1], strBytes[i*3+2]));
    }

    // ERC721Enumerable (public)
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    // ERC721Enumerable (private)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    // Utils
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function adminWithdraw(uint256 _amount) public onlyOwner returns (bool) {
        payable(msg.sender).transfer(_amount);
        return true;
    }
}