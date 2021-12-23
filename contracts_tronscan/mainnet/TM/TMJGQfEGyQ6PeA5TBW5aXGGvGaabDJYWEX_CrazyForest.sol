//SourceUnit: CF.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./VRFConsumerBase.sol";
import "./Owned.sol";

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface TRC721TokenReceiver {
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

contract TRC721Holder is TRC721TokenReceiver {
    function onTRC721Received(address, address, uint256, bytes memory) external virtual override returns (bytes4) {
        return this.onTRC721Received.selector;
    }
}

contract CrazyForest is TRC721Holder, VRFConsumerBase, Owned {
    // solidity 0.8.0 以上版本已默认检查溢出，可以不使用SafeMath
    // 开启编译优化，共占用256的空间，节省gas开销
    struct Tree {
        uint8 magicNum; //神奇果树的数量
        uint8 isNFT;
        uint8 isOpen;
        uint8 treeIndex;
        uint32 timestamp;
        uint32 num;
        uint32 cont;
        uint64 totalCont;
        uint64 price;
    }

    struct TreeInfo {
        uint64 treeIndex;
        uint64 cont;
        uint128 totalCont;
    }

    struct Income {
        uint32 dividendDay; //分红起始日
        uint32 minIndex; //最小有效树下标
        uint64 ref; //推荐
        uint64 lottery; //抽奖
        uint64 bonus; //大奖
    }

    struct DividendCheck {
        uint32 treeIndex; //树坐标
        uint32 minIndex; //本次分红最小树坐标
        uint64 value; //分红金额
        uint64 totalShare; //单个贡献值累计分红金额
        uint64 sumCont; //本次分红总贡献值
    }

    struct CheckPoint {
        uint64  treeIndex; // 最大树坐标
        uint64  minIndex; // 最小树坐标
        uint128  value; 
    }

     struct BackGround {
        uint128 index;
        uint128 price;
        string url;
    }

    struct Request {
        uint64 requestType;
        uint64 valid;
        uint128 value;
    }
    
    // 占用一个256位存储槽
    struct GameCondition {
        uint8  flag; // released(4) | start(2) | preBuy(1)
        uint16 dayOffset;
        uint16 currentDay;
        uint16 minDay;
        uint24 roundOffset;
        uint24 currentRound;
        uint24 remainTime;
        uint32 minIndex; // 最小的有效的树下标
        uint32 treeNum; // 当前下标
        uint32 currentMagic;
        uint32 currentNFT;
    }

    // 占用一个256位存储槽
    struct GameState {
        uint32 timestamp;
        uint48 totalContributes;
        uint56 ecology;
        uint56 community;
        uint64 bonus;
    }

    GameCondition private _gCondition = GameCondition(1, 0, 0, 0, 0, 0, 86400, 0, 0, 0, 0);
    GameState private _gState = GameState(0, 0, 0, 0, 0);

    mapping(uint256 => DividendCheck) private _dividendCheck;
    mapping(uint256 => CheckPoint) private _lotteryCheck;
    mapping(uint256 => CheckPoint) private _magicCheck;
    mapping(address => Income) private _userIncome;
    mapping(address => TreeInfo[]) private _userTrees;
    mapping(address => uint256) private _bonusTaken;
    mapping(uint256 => Tree)  private _treeList;
    mapping(uint256 => address) private _treeOwners;
    uint256[] private _magicTrees;
    uint256[] private _nftTrees;
    mapping(uint256 => uint256) private _nftTokens;
    mapping(address => address) _super;
    mapping(address => uint256) _userBox;
    address[] _boxUsers;
    BackGround[] _bgs;
    mapping(address => uint256[]) _userBgs;
    mapping(bytes32 => Request) _requests;
    mapping(bytes32 => uint256) _rands;

    mapping(address => uint256) private _admins;
    TRC20Interface internal usdt;
    address private _first;
    address private _nft;
    uint256 private _tokenId = 1;

    bytes32 private s_keyHash;
    uint256 private s_fee;
    

    constructor(address _usdt, address _f, address _n, address vrfCoordinator, address win, address winkMid, bytes32 keyHashValue, uint256 feeValue)
    VRFConsumerBase(vrfCoordinator, win, winkMid){
        _admins[msg.sender] = 1;
        usdt = TRC20Interface(_usdt);
        _first = _f;
        _nft = _n;
        s_keyHash = keyHashValue;
        s_fee = feeValue;
        _super[_f] = _f;
        // 数据迁移，盲盒中奖记录
        initAddTree(address(uint160(uint256(0x4189DAA0B2EC6C67A4204A0358258A6EA1DAEDFF50))), 0, 1, 158000000);
        initAddTree(address(uint160(uint256(0x41346669BB6AFD7CF09372FEF10715D6C9CA0D81FE))), 1, 1, 158000000);
        initAddTree(address(uint160(uint256(0x410CAD25F64FC050E87A7C88095F87F082DF8E5B11))), 2, 1, 158000000);
        initAddTree(address(uint160(uint256(0x41CEE9843831A57C39982A2381F686560B44613802))), 3, 1, 158000000);
        _gState.totalContributes = 4;
        _gCondition.treeNum = 4;
        // 推荐关系
        _super[address(uint160(uint256(0x41549d30c47c0b0fd5777438cae648d75d70955ad1)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x4105e3fadfdedaefe0bc15352d7e876ffc12325bdf)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41a8bf57a3e7cb28b0c17e998b9ba975db4a1e38d2)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41337a85a12041712260bae256904cebbfae9dfe42)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x419423065602c92f7d5b3d03bcd4de817fe8b66d4b)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41e94e07cc3c7e22767a77f7e3082a83b536557f7c)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x415e8134061a89aa8d774924ea7b152e5fb23965d4)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41784544ab17bad1d94053ad37bbc35afa46e9a696)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)))]=address(uint160(uint256(0x41549d30c47c0b0fd5777438cae648d75d70955ad1)));
        _super[address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)))]=address(uint160(uint256(0x41a8bf57a3e7cb28b0c17e998b9ba975db4a1e38d2)));
        _super[address(uint160(uint256(0x4124d603aba7b5d61c0a0e1e7107ef939eae80dcce)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x4168fb73ab0400ef3119392b6692b305a56dc3d030)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x4109e40564adb31327a4624d8427ee1c6b01a0b8bf)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x417a65e3e956984677015513c289e6652fda2cb413)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41d1e33a2c82db53c1bbb9bc1986dcf88cbd3d9345)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x412f265d12fc345fd2cff5045ae2ebcbd48c86e1fd)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41e74b53b04c1056e5f4fb2025dda494c1d810cd28)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41971d5e407e710943f96cee2d36e941b42d352dbb)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x418195d0e4a1f8e6654396c6015ebb4c36962d7c20)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41fe4083148a0bdf8443a11d472d899847a47a5a84)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41a720bb3fb8179ce8744beffe9332a7ec09bde76c)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41cf98b7bba1d93abb894ac3e94b771d2909e6056e)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41ac7dc7af5af2b0bc820a31210737efce8a37c64f)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x410cad25f64fc050e87a7c88095f87f082df8e5b11)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x4121563c735ee233e6cb05b3150b7412e84bb2659f)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x4172be2cc88b48511d859e6700d3211dc61707342e)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x413b7e31fcfea9bdc73657066201e9deef609cabae)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x41f81be89a86b7c0b596ff9b61d60d7a5036bdbd12)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x416618a1a2cda289e8dc45d16dffa1ac2fc0ba6b9d)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x4137d0bbb93f30b7461ee3cf69c7702b3bca2658eb)))]=address(uint160(uint256(0x41337a85a12041712260bae256904cebbfae9dfe42)));
        _super[address(uint160(uint256(0x414633e381b027b5b3aae48d9aa929c2f8d42d5c6d)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x4129ab83fbdf0b45d3e88e6772aa3527e1d0d5ce5d)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x41173a4e64ebad3c7256d22c441f983faf029893be)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x410a75c4a0ab905bc5547dfadfe02be707cdf9db45)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x4142d5b6ef60601b5883f5489c2802b08799d2c6da)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x416256f727ffbdbedc1e202a1457ca83911125a09d)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x4111720c907ba0517d206ab1455076cf0166f4eb96)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x41f7c878d118f6cb54626b9e1248ec762d31415c04)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x4129648db101318b6cff6c9d3757a17936f0879590)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x4197441dff87cb100f77a37cbb54ce4f9c084868f4)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4151fbc6cf507720873f120d639ef909f19b2cd209)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x41567592d338f5e9fdae924c7053f714f2b74e1325)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x41a596df15e649581f81f985794118022b8df4a402)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4107b43c019a0963fdb2042deeb5116233d8657707)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4118df0c8c0864cf1c11405bfc83b27b210890b7c2)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4143053f5dbf25a26ce3e0f983615878297880ff79)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x41e5c7d8ab7dbc48a30219d021ef36cee127124edc)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x415ee8854b2d68fc805283d9278767dedbfbd97397)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x41500fe72173f7b42fdbd93ead6b23a0fe72ac079d)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x418d3af534f7ab5a68385eb4d2fd66e6eeb4dd8ad3)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x41e5e07ed93998dc07267712f6c8ee975f5d9c6114)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x410660db1ec145908edd083922e140be009a2f078f)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41da0cbcc99628121c0df3294f75b3b25642228003)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x413207f5338c157393d9f119bce51c464e4e522e6f)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x4145ea2ae8c4e80e67493a2048cfa748f52a1ed59a)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41b676bae6ce42ab0dbdb0e959e36f9e52ee60dd78)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x414c1f6ca23ce0c295e227493ff87db1de06206233)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41adf09ee93dd1ba7d1514f24cdd6ac2c6cba56386)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41df2f72999afe6b75d1681bfe11ef91bc2243c2a7)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x417bfaf7c4176692ac3894732d2dbbb638b979655b)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41e9e807b4931158e2440b67830740f3b34428a2c0)))]=address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)));
        _super[address(uint160(uint256(0x41c19e4694d8753e1d751a977212c9cec02a5758f4)))]=address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)));
        _super[address(uint160(uint256(0x4115bc6a9f2e69c5283df21bc1ba046de4543ff8ad)))]=address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)));
        _super[address(uint160(uint256(0x41065f2f493703fe862d786e7fb6d4743d2156231e)))]=address(uint160(uint256(0x414633e381b027b5b3aae48d9aa929c2f8d42d5c6d)));
        _super[address(uint160(uint256(0x4157dc9457843a3f1ebbd9b9c3de9ac9cdddbb7798)))]=address(uint160(uint256(0x414633e381b027b5b3aae48d9aa929c2f8d42d5c6d)));
        _super[address(uint160(uint256(0x41abeeed6bb6fb2b326cc346a41e0957b677797d53)))]=address(uint160(uint256(0x41a720bb3fb8179ce8744beffe9332a7ec09bde76c)));
        _super[address(uint160(uint256(0x41fe7e11b818ee027c86c401301e726353d7892d90)))]=address(uint160(uint256(0x410660db1ec145908edd083922e140be009a2f078f)));
        _super[address(uint160(uint256(0x41bf0ab828b782e1e3e7b5d0156b6936a422a29098)))]=address(uint160(uint256(0x410660db1ec145908edd083922e140be009a2f078f)));
        _super[address(uint160(uint256(0x411fdc31d675afd448ebbd3adfb92677e2db122528)))]=address(uint160(uint256(0x41173a4e64ebad3c7256d22c441f983faf029893be)));
        _super[address(uint160(uint256(0x4119614991185da0afaf9537fb472c8efffd890431)))]=address(uint160(uint256(0x41e5c7d8ab7dbc48a30219d021ef36cee127124edc)));
        _super[address(uint160(uint256(0x4135809f0eb38252717699b3a45704f39517e317ec)))]=address(uint160(uint256(0x41cf98b7bba1d93abb894ac3e94b771d2909e6056e)));
        _super[address(uint160(uint256(0x4189daa0b2ec6c67a4204a0358258a6ea1daedff50)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x410f4825e58bfa2a8954170b75b86f127aabebc38b)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41fe28f338da67acb950987625d83a7582754216d6)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41e1f571ed7b63e44de72eb90720906b2baae94ea8)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x416142581ba277c9f07c8d8b4eb4511de963cd31fd)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41e404e5f7a46eb6b0e0fe8266a272e3fa2535e35c)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41ab46af6e3c6fba5814983a64f49b0c5b89601056)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41a89ccdaa58ee554cc95953d4e508cb03d98ff247)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41baf463f0151295de117d13b5fcadcef7f165d582)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x415dc1734cb33552c413ce8e20c9e0512c25d7c68c)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x418273db80c2a0030d79db39eeb0a5ee1333f7dc11)))]=address(uint160(uint256(0x4189daa0b2ec6c67a4204a0358258a6ea1daedff50)));
        _super[address(uint160(uint256(0x41175810fcab3244685cd5058b6d30351a708cf353)))]=address(uint160(uint256(0x41e9e807b4931158e2440b67830740f3b34428a2c0)));
        _super[address(uint160(uint256(0x41d029da0832580cc8ec15bc421053e1e9ad910228)))]=address(uint160(uint256(0x41e9e807b4931158e2440b67830740f3b34428a2c0)));
        _super[address(uint160(uint256(0x41039ab281a8c27f995d2afb16b274c7d9f81fec6d)))]=address(uint160(uint256(0x41065f2f493703fe862d786e7fb6d4743d2156231e)));
        _super[address(uint160(uint256(0x416b4d417084f2cc1716bd369eb83bc0087b1262f3)))]=address(uint160(uint256(0x41065f2f493703fe862d786e7fb6d4743d2156231e)));
        _super[address(uint160(uint256(0x414357e4ca4a717fa7ba569f1c07e707b6e00e7e87)))]=address(uint160(uint256(0x41175810fcab3244685cd5058b6d30351a708cf353)));
        _super[address(uint160(uint256(0x413ffd7990c3168c189b47c8549660d9c40eba63c5)))]=address(uint160(uint256(0x41175810fcab3244685cd5058b6d30351a708cf353)));
        _super[address(uint160(uint256(0x411c7da51d63b5fcf48c32dd443389116344f5ee4d)))]=address(uint160(uint256(0x410f4825e58bfa2a8954170b75b86f127aabebc38b)));
        _super[address(uint160(uint256(0x41894fb3b02f23aa70cef1db6bf84b96304f152efb)))]=address(uint160(uint256(0x4151fbc6cf507720873f120d639ef909f19b2cd209)));
        _super[address(uint160(uint256(0x4113c9f720f5a1bbced0e6be4409b252bab81a1aa7)))]=address(uint160(uint256(0x41894fb3b02f23aa70cef1db6bf84b96304f152efb)));
        _super[address(uint160(uint256(0x4150d911618988d64e67e0777e4800b029b755097c)))]=address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)));
        _super[address(uint160(uint256(0x41352c1973e25b7fd8d66488c3c8eccf09f1acf1d8)))]=address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)));
        _super[address(uint160(uint256(0x417c99871fd0b9f7168e8a00f1247afdceb2bb2ea5)))]=address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)));
        _super[address(uint160(uint256(0x41412f6d2a314d8513c859edd71ba2ed63e8c41d08)))]=address(uint160(uint256(0x411c7da51d63b5fcf48c32dd443389116344f5ee4d)));
        _super[address(uint160(uint256(0x41f57d8920e5fa49ea543122ab1a2682ee202e855b)))]=address(uint160(uint256(0x41fe7e11b818ee027c86c401301e726353d7892d90)));
        _super[address(uint160(uint256(0x417ebdc74bae5fbd70f446c45ac47afa1ed533b15d)))]=address(uint160(uint256(0x413207f5338c157393d9f119bce51c464e4e522e6f)));
        _super[address(uint160(uint256(0x412fb1551a89f9061044d5d88aee3637f1f5eca12c)))]=address(uint160(uint256(0x41c19e4694d8753e1d751a977212c9cec02a5758f4)));
        _super[address(uint160(uint256(0x4125156545f67aa2d1b375e0d3c3b96db45fbcc320)))]=address(uint160(uint256(0x416142581ba277c9f07c8d8b4eb4511de963cd31fd)));
        _super[address(uint160(uint256(0x419e11f2072af805162339dc01431d22fac59e00a2)))]=address(uint160(uint256(0x41e404e5f7a46eb6b0e0fe8266a272e3fa2535e35c)));
        _super[address(uint160(uint256(0x418b5ef2af68f6bf2e71acfe8ef313214011130bd8)))]=address(uint160(uint256(0x41e404e5f7a46eb6b0e0fe8266a272e3fa2535e35c)));
        _super[address(uint160(uint256(0x41b25f75d8fa068655a62a01455841b35d934ca533)))]=address(uint160(uint256(0x4135809f0eb38252717699b3a45704f39517e317ec)));
        _super[address(uint160(uint256(0x411837990dd2f82810e9a211ced2228d8942066b54)))]=address(uint160(uint256(0x419e11f2072af805162339dc01431d22fac59e00a2)));
        _super[address(uint160(uint256(0x41ef33fcfe5cd1a7be38d24072a76630bdb0fbd721)))]=address(uint160(uint256(0x41ac7dc7af5af2b0bc820a31210737efce8a37c64f)));
        _super[address(uint160(uint256(0x412dd0f5d4903fddb603cb6c341bd104e5175a951f)))]=address(uint160(uint256(0x41ab46af6e3c6fba5814983a64f49b0c5b89601056)));
        _super[address(uint160(uint256(0x41346669bb6afd7cf09372fef10715d6c9ca0d81fe)))]=address(uint160(uint256(0x41ab46af6e3c6fba5814983a64f49b0c5b89601056)));
        _super[address(uint160(uint256(0x419845526498da5eb08f9c6dc63ef3c4799d0b284d)))]=address(uint160(uint256(0x41baf463f0151295de117d13b5fcadcef7f165d582)));
        _super[address(uint160(uint256(0x4126a3685ccb4f77c548297ca819b3156ee12acfca)))]=address(uint160(uint256(0x419845526498da5eb08f9c6dc63ef3c4799d0b284d)));
        _super[address(uint160(uint256(0x418ef28542e3ed0bf8066ec6fead6d4975c24d8589)))]=address(uint160(uint256(0x41784544ab17bad1d94053ad37bbc35afa46e9a696)));
        _super[address(uint160(uint256(0x4106763cc3fb68b5e4e08c7a48b4e9c6de8a45786a)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41e9c02e87fef2b727618047e1dcb0bd61fa60af78)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x4187f206bcda42a4a5183280a6b740a04ee91f8844)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x4113d73065b25e5472f3eca2e349080b52824cf434)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41f4a33dda7e5ca8b569880c5c417755e169d95a77)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41eab783a940d4a18fb86bdcde2aab54e800238115)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41e7a4c7d5c732f411971b81c969cff6145a6c89c6)))]=address(uint160(uint256(0x417a65e3e956984677015513c289e6652fda2cb413)));
        _super[address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)))]=address(uint160(uint256(0x4106763cc3fb68b5e4e08c7a48b4e9c6de8a45786a)));
        _super[address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)))]=address(uint160(uint256(0x4106763cc3fb68b5e4e08c7a48b4e9c6de8a45786a)));
        _super[address(uint160(uint256(0x4151d8413603240b7c85531b771c3c0faa236e8104)))]=address(uint160(uint256(0x413ffd7990c3168c189b47c8549660d9c40eba63c5)));
        _super[address(uint160(uint256(0x416d2edd0156155d34544660424309bc0f298e8557)))]=address(uint160(uint256(0x413ffd7990c3168c189b47c8549660d9c40eba63c5)));
        _super[address(uint160(uint256(0x4192aa2e0f36bb2e30a7cb20112ee64db4a584ef49)))]=address(uint160(uint256(0x4126a3685ccb4f77c548297ca819b3156ee12acfca)));
        _super[address(uint160(uint256(0x417506f5169eb8ffa30991d9390518907e470a3c16)))]=address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)));
        _super[address(uint160(uint256(0x419b1178d57879de425e3c8b4f18619cbbfbe0d607)))]=address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)));
        _super[address(uint160(uint256(0x415b745a7cddd3ed78976382bd0ea73dccc979c05b)))]=address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)));
        _super[address(uint160(uint256(0x41acf859f122f7a3585c761a2f3ab9b768893db804)))]=address(uint160(uint256(0x411fdc31d675afd448ebbd3adfb92677e2db122528)));
        _super[address(uint160(uint256(0x4110e624ebb451c83099763c745b1a5b362d2929b8)))]=address(uint160(uint256(0x41acf859f122f7a3585c761a2f3ab9b768893db804)));
        _super[address(uint160(uint256(0x41fcb38cae41643aab9c5437c8395ac45c1d774ec3)))]=address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)));
        _super[address(uint160(uint256(0x41f477cc57e6d0a47d5641d40e1013dd2ea0b5c141)))]=address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)));
        _super[address(uint160(uint256(0x41868026465f3150c4bb0c30f47ffe7c2661be46b7)))]=address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)));
        _super[address(uint160(uint256(0x4173596ada43a75360b34e4be18654ec5c3f0bf049)))]=address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)));
        _super[address(uint160(uint256(0x41cee9843831a57c39982a2381f686560b44613802)))]=address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)));
        _super[address(uint160(uint256(0x415ec62c6a4816c30fa33b79952403e65987cc4704)))]=address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)));
        _super[address(uint160(uint256(0x41cdb6c3ca7448f2d727a096f783bb5870635cd293)))]=address(uint160(uint256(0x410cad25f64fc050e87a7c88095f87f082df8e5b11)));
        _super[address(uint160(uint256(0x411eaf66d36e5d34827a334cc4b5528ac691f76bbd)))]=address(uint160(uint256(0x4197441dff87cb100f77a37cbb54ce4f9c084868f4)));
        _super[address(uint160(uint256(0x41d0581124c99bf944654b709f16e042c463d4c9b3)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x41bdbea2421189b6e90ed945286d357ab67792da86)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x412e04d720b33343e04238ac90db946f6a700f3b33)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x41f18a0138280c5f38a1b5a5a26118eeea2ebca1f6)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x417aa2473927e5fc8f68013c7804c3104834a15190)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x4131676d2eeda264bc64aea136e226859511589409)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x41a6efd2604e2bf73c263582231225c5edfb78b514)))]=address(uint160(uint256(0x411eaf66d36e5d34827a334cc4b5528ac691f76bbd)));
        _super[address(uint160(uint256(0x411620bf806fa9f8253ca14beb1439370e541f4d6b)))]=address(uint160(uint256(0x411eaf66d36e5d34827a334cc4b5528ac691f76bbd)));
        _super[address(uint160(uint256(0x41570beb3559dfe952ae86fbd102a38efa9f674d2a)))]=address(uint160(uint256(0x41a6efd2604e2bf73c263582231225c5edfb78b514)));
        _super[address(uint160(uint256(0x41525b39c7ab4b600f7dc1f82b4ca25ebd12134c47)))]=address(uint160(uint256(0x411620bf806fa9f8253ca14beb1439370e541f4d6b)));
        _super[address(uint160(uint256(0x410c4821fd2f88267e6010d7accb24187bd6abe12e)))]=address(uint160(uint256(0x411620bf806fa9f8253ca14beb1439370e541f4d6b)));
        _super[address(uint160(uint256(0x41fb9e28b2fae6fcde5af0d9502d9c28b267f87a53)))]=address(uint160(uint256(0x416b4d417084f2cc1716bd369eb83bc0087b1262f3)));
        _super[address(uint160(uint256(0x416d8a98edd0ac1330890a658142c48c764241cd5d)))]=address(uint160(uint256(0x416b4d417084f2cc1716bd369eb83bc0087b1262f3)));
        _super[address(uint160(uint256(0x41dc149f096e9c8e97e720d6cf65638fe8e4b8f3f7)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x4139164db44f38c284bb74e57872120d29b8218a51)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x4104caa1f25303515bfe58024bf21d0319665d7603)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x41c21215171413eb7c0f81331a3d5fb8c326cd5f75)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x411701d3199ef291513fb17e3fa459943211ac6ef8)))]=address(uint160(uint256(0x41dc149f096e9c8e97e720d6cf65638fe8e4b8f3f7)));
        _super[address(uint160(uint256(0x41bea78e7943f20ba361eba2d1959f91d4903a61c1)))]=address(uint160(uint256(0x41dc149f096e9c8e97e720d6cf65638fe8e4b8f3f7)));
        _super[address(uint160(uint256(0x413187bca83ea5b6e004815587563f32f20ad7570a)))]=address(uint160(uint256(0x419b1178d57879de425e3c8b4f18619cbbfbe0d607)));
        _super[address(uint160(uint256(0x414b34e3387365a6d206bd856962f8490de6d78fcd)))]=address(uint160(uint256(0x413187bca83ea5b6e004815587563f32f20ad7570a)));
        _super[address(uint160(uint256(0x413cc19ffcfcd546955de7de6e55820f8b16441766)))]=address(uint160(uint256(0x416618a1a2cda289e8dc45d16dffa1ac2fc0ba6b9d)));
        _super[address(uint160(uint256(0x41483d6a02f3402198bbc74cf4969578a76e2e8149)))]=address(uint160(uint256(0x41c21215171413eb7c0f81331a3d5fb8c326cd5f75)));
        _super[address(uint160(uint256(0x41d17f544e3138452ee34db8d8cea3a5eed2562794)))]=address(uint160(uint256(0x41c21215171413eb7c0f81331a3d5fb8c326cd5f75)));
        _super[address(uint160(uint256(0x41291422d26444dafb1f0e2f2d87621aadc32e9f2e)))]=address(uint160(uint256(0x41525b39c7ab4b600f7dc1f82b4ca25ebd12134c47)));
        _super[address(uint160(uint256(0x416fe6aa087400bc8750b9b198d5452eedd54708df)))]=address(uint160(uint256(0x41291422d26444dafb1f0e2f2d87621aadc32e9f2e)));
        _super[address(uint160(uint256(0x41aa595192d7ac0148678d0f11d934de8c190aea53)))]=address(uint160(uint256(0x41abeeed6bb6fb2b326cc346a41e0957b677797d53)));
        _super[address(uint160(uint256(0x41046e82c213e91aa82e584e4785c1c33ada0cfceb)))]=address(uint160(uint256(0x410c4821fd2f88267e6010d7accb24187bd6abe12e)));
    }

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Direct(address indexed user, address superUser, uint256 amount);
    event InDirect(address indexed user, address inSuper, uint256 amount);
    event BuyTree(address indexed user, uint256 price);
    event Lottery(address indexed user, uint256 amount);
    event DividendTake(address indexed user, uint256 amount);
    event PoolTake(address indexed user, uint256 amount);
    event RefTake(address indexed user, uint256 amount);
    event NftUse(uint256 tokenId);
    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event ReciveRand(bytes32 indexed requestId, uint256 randomness);
    event MagicCheck(uint64 cIndex, uint64 treeIndex, uint64 minIndex, uint64 magicNum);
    event AdminSet(address admin);
    event AdminUnset(address admin);
    event FirstUpdate(address first);
    event GenMaigic(address user);
    event GenNFT(address user);
    event DoDividend(uint256 day, uint256 minIndex, uint256 minDay, uint256 value);
    event ReleasePool(address last, uint256 value);

    modifier activated() {
        require(_super[msg.sender] != address(0), "Must activate first");
        _;
    }

    modifier started() {
        require((_gCondition.flag & 2) == 2, "Not started");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender] == 1, "Only admin can change items");
        _;
    }

    function _rollDice(uint256 userProvidedSeed, address roller) private returns (bytes32 requestId)
    {
        require(winkMid.balanceOf(address(this)) >= s_fee, "Not enough WIN to pay fee");
        requestId = requestRandomness(s_keyHash, s_fee, userProvidedSeed);
        emit DiceRolled(requestId, roller);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (_rands[requestId] == 0) {
            _rands[requestId] = randomness;
            emit ReciveRand(requestId, randomness);
        }
    }

    function initAddTree(address user, uint256 tIndex, uint256 num, uint256 price) internal {
        _treeList[tIndex] = Tree(0, 0, 0, 0, 1640013803, uint32(num), uint32(num), uint64(num), uint64(price / num));
        _treeOwners[tIndex] = user;
        _userTrees[user].push(TreeInfo(uint64(tIndex), uint64(num), uint64(num)));
    }

    function processRandomness(bytes32 requestId) external onlyAdmin {
        uint256 randomness =  _rands[requestId];
        Request storage r = _requests[requestId];
        require(r.valid == 1, "finished!");
        require(randomness != 0, "please wait!");
        if (r.requestType == 1) {
            // 抽取神奇果树
            uint256 currentMagic = r.value;
            require(_gCondition.currentMagic == currentMagic, "Duplicated!");
            CheckPoint memory mc = _magicCheck[currentMagic];
            uint256 mNum = mc.value;
            require(mNum > 0, "Not time!");
            uint256 beginIndex = 0;
            if (currentMagic > 0) {
                beginIndex = _magicCheck[currentMagic-1].treeIndex + 1;
            }
            beginIndex = Math.max(beginIndex, mc.minIndex);
            
            while(true) {
                uint256 index = _getRandTree(randomness, beginIndex, mc.treeIndex);
                if(_treeList[index].magicNum < _treeList[index].num) {
                    _treeList[index].magicNum += 1;
                    _magicTrees.push(index);
                    emit GenMaigic(_treeOwners[index]);
                    mNum -= 1;
                    if(mNum == 0) {
                        break;
                    }
                }
                randomness = uint256(keccak256(abi.encodePacked(randomness, uint256(mNum))));
            }
            _gCondition.currentMagic += uint32(mc.value);
            r.valid = 0;
        } else if (r.requestType == 2) {
            // 抽取NFT
            uint256 currentNFT = r.value;
            require(_gCondition.currentNFT == currentNFT, "Duplicated!");
            uint256 maxIndex = currentNFT * 20 + 20;
            uint256 minIndex = 0;
            uint256 gMinIndex = _gCondition.minIndex;
            uint256 sum = 0;
            while(minIndex < maxIndex && _magicTrees[minIndex] < gMinIndex) {
                ++minIndex;
            }
            uint256[] memory indexList = new uint256[](maxIndex - minIndex + 1);
            for(uint256 i = minIndex; i < maxIndex; ++i) {
                uint256 ti = _magicTrees[i];
                if (_treeList[ti].isNFT == 0) {
                    indexList[sum] = ti;
                    sum++;
                }
            }
            if (sum > 0) {
                uint256 nftTokenId = _getTokenId();
                require(nftTokenId != 0, "No NFT left!");
                uint256 rand = randomness % sum;
                uint256 tIndex = indexList[rand];
                _treeList[tIndex].isNFT = 1;
                _nftTrees.push(tIndex);
                _nftTokens[tIndex] = nftTokenId;
                emit GenNFT(_treeOwners[tIndex]);
            }
            _gCondition.currentNFT += 1;
            r.valid = 0;
        } else if(r.requestType == 3){
            // 抽奖
            require(_gCondition.currentRound == r.value, "Duplicated!");
            CheckPoint memory lCheck = _lotteryCheck[r.value];
            uint256 index = _getRandTree(randomness, lCheck.minIndex, lCheck.treeIndex);
            address user = _treeOwners[index];
            usdt.transfer(user, lCheck.value);
            // _userIncome[user].lottery += r.v2;
            _gCondition.currentRound += 1;
            r.valid = 0;
            emit Lottery(user, lCheck.value);
        } else {
            require((_gCondition.flag & 2) == 0, "Duplicated!");
            uint256 len = _boxUsers.length;
            if (len > 0) {
                uint256 num = (len + 29) / 30;
                uint256 rand = randomness % len;
                uint256 tCont = _gState.totalContributes;
                uint256 tIndex = _gCondition.treeNum;
                for(uint256 i = 0; i < num; ++i) {
                    address user = _boxUsers[rand];
                    tCont += 1;
                    _treeList[tIndex] = Tree(0, 0, 0, 0, uint32(_userBox[user]), 1, 1, uint64(tCont), uint64(_treePrice(0)));
                    _treeOwners[tIndex] = user;
                    _userTrees[user].push(TreeInfo(uint64(tIndex), 1, 1));
                    //add magic check
                    if(tCont % 500 == 0) {
                        _magicCheck[tCont / 500 - 1] = CheckPoint(uint64(tIndex), 0, 1);
                        emit MagicCheck(uint64(tCont / 500 - 1), uint64(tIndex), 0, 1);
                    }
                    tIndex += 1;
                    rand += 30;
                    if(rand >= len) {
                        rand -= len;
                    }
                }
                _gState.totalContributes += uint48(tCont);
                _gCondition.treeNum = uint32(tIndex);
            }
            _startGame();
        }
        emit DiceLanded(requestId, 0);
    }

    function _startGame() private {
        _gState.timestamp = uint32(block.timestamp);
        _gCondition.dayOffset = uint16((block.timestamp + 28800) / 86400);
        _gCondition.roundOffset = uint24(block.timestamp / 7200);
        _gCondition.flag |= 2; // start
    }

    function _getRandTree(uint256 r, uint256 minIndex, uint256 maxIndex) private view returns (uint256) {
        uint256 baseCont = 0;
        if (minIndex > 0) {
            baseCont = _treeList[minIndex-1].totalCont;
        }
        uint256 totalCont = _treeList[maxIndex].totalCont - baseCont;
        r = (r % totalCont) + baseCont;
        while(minIndex + 1 < maxIndex) {
            uint256 midIndex = (minIndex + maxIndex) >> 1;
            if(_treeList[midIndex].totalCont <= r) {
                minIndex = midIndex;
            } else {
                maxIndex = midIndex;
            }
        }
        if(_treeList[minIndex].totalCont > r) {
            return minIndex;
        } else {
            return maxIndex;
        }
    }

    function withdrawWIN(address to, uint256 value) external onlyAdmin {
        token.approve(winkMidAddress(), value);
        require(winkMid.transferFrom(address(this), to, value), "Not enough WIN");
    }

    function setKeyHash(bytes32 keyHashValue) external onlyAdmin {
        s_keyHash = keyHashValue;
    }

    function setAdmin(address admin) external onlyAdmin {
        _admins[admin] = 1;
        emit AdminSet(admin);
    }

    function unsetAdmin(address admin) external onlyAdmin {
        _admins[admin] = 0;
        emit AdminUnset(admin);
    }

    function setFirst(address firstValue) external onlyAdmin {
        _first = firstValue;
        emit FirstUpdate(firstValue);
    }

    function keyHash() external view returns (bytes32) {
        return s_keyHash;
    }

    function setFee(uint256 feeValue) external onlyAdmin {
        s_fee = feeValue;
    }

    function fee() external view returns (uint256) {
        return s_fee;
    }

    function first() external view returns (address) {
        return _first;
    }

    function unprocessRound() external view returns (uint256) {
        return _getRound() - _gCondition.currentRound;
    }

    function unprocessDividend() external view returns (uint256) {
        return _getDay() - _gCondition.currentDay;
    }

    function lotteryInfo(uint256 _round) external view returns (uint256) {
        return _lotteryCheck[_round].value;
    }

    function dividendInfo(uint256 _day) external view returns (uint256) {
        return _dividendCheck[_day].value;
    }

    // 树的贡献值，树的类型在此修改，internal gas消耗更少
    function _treeCont(uint256 index) internal pure returns (uint256) {
        uint256[8] memory _treeContValue = [uint256(1), 2, 5, 10, 20, 50, 100, 200];
        require(index < _treeContValue.length, "Index error");
        return _treeContValue[index];
    }

    // 树的价格，树的单价在此修改，internal gas消耗更少
    function _treePrice(uint256 index) internal view returns (uint256) {
        uint256 _singlePrice = 158000000;
        return _treeCont(index) * _singlePrice * (_gState.totalContributes / 1000 * 5 + 1000) / 1000;
    }
    
    // 更新剩余时间，时间增加幅度值在此修改
    function _updateTime(uint256 cont, uint256 timeGap) private {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 200000) {
            cont *= 30;
        } else if (totalCont > 100000) {
            cont *= 60;
        } else if (totalCont > 50000) {
            cont *= 300;
        } else {
            cont *= 600;
        }
        _gCondition.remainTime = uint24(Math.min(_gCondition.remainTime + cont - timeGap, _getLimit()));
    }

    // 树的贡献值，供前端调用
    function treeCont(uint256 index) external pure returns (uint256) {
        return _treeCont(index);
    }
    // 树的价格，供前端调用
    function treePrice(uint256 index) external view returns (uint256) {
        return _treePrice(index);
    }

    // 推荐人
    function superAccount(address account) external view returns (address) {
        return _super[account];
    }

    // 背景列表
    function allBg() external view returns (BackGround[] memory){
        return _bgs;
    }

    // 游戏是否开始
    function isStart() external view returns (bool) {
        return (_gCondition.flag & 2) == 2;
    }

    // 游戏是否结束
    function isEnd() external view returns (bool) {
        return _ifEnd();
    }

    // 时间
    function checkPoint() external view returns (uint256) {
        return _gState.timestamp;
    }

    // 神奇果树数量
    function magicTreeNum() external view returns (uint256) {
        return _magicTrees.length;
    }

    // 神奇果树信息
    function magicTreeInfo(uint256 idx) external view returns (uint256) {
        return _magicTrees[idx];
    }

    // 剩余时间
    function remainTime() public view returns (uint256) {
        if((_gCondition.flag & 2) == 2) {
            uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
            if(timeGap > _gCondition.remainTime) {
                return 0;
            }
            return _gCondition.remainTime - timeGap;
        } else {
            return _gCondition.remainTime;
        }
    }
    
    // 返回订单数
    function orderNum() external view returns (uint32) {
        return _gCondition.treeNum;
    }

    // 返回订单信息
    function treeInfo(uint256 idx) external view returns (Tree memory) {
        return _treeList[idx];
    }

    // 返回订单owner
    function treeOwner(uint256 idx) external view returns (address) {
        return _treeOwners[idx];
    }

    // 用户是否激活
    function isActivate(address account) external view returns (bool){
        return _super[account] != address(0);
    }

    // 用户背景列表
    function bgOf(address account) external view returns (uint256[] memory){
        return _userBgs[account];
    }

    // 累计分红
    function totalDividend() external view returns (uint256){
        return _dividendCheck[_getDay()].value;
    }

    // 累计奖池
    function totalPool() external view returns (uint256){
        if ((_gCondition.flag & 4) == 4) {
            return _gState.bonus * 5;
        }
        return _gState.bonus;
    }

    // 累计生态基金
    function totalEcology() external view returns (uint256) {
        return _gState.ecology;
    }
    
    // 累计委员会基金
    function totalCommunity() external view returns (uint256) {
        return _gState.community;
    }

    // 抽奖奖池
    function totalLottery() external view returns (uint256){
        return _lotteryCheck[_getRound()].value;
    }

    // 累计贡献值
    function totalContribute() external view returns (uint256){
        return _gState.totalContributes;
    }

    // 用户的盲盒
    function boxOf(address account) external view returns (uint256){
        return _userBox[account];
    }

    // 返回用户所有的树，树里包含了树种信息，前端处理以提高效率
    function treeOf(address account) external view returns (Tree[] memory) {
        TreeInfo[] memory ut = _userTrees[account];
        Tree[] memory tl = new Tree[](ut.length);       
        for(uint i = 0; i < ut.length; ++i) {
            tl[i] = (_treeList[ut[i].treeIndex]);
        }
        return tl;
    }

    // 用户未领取的分红
    function dividendOf(address account) external view returns (uint256){
        Income memory uIncome = _userIncome[account];
        uint256 dDay = uIncome.dividendDay;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentDay = _gCondition.currentDay;
        TreeInfo[] memory ut =  _userTrees[account];
        for(; dDay < currentDay; ++dDay) {
            DividendCheck memory dc = _dividendCheck[dDay];
            uint256 minIndexCheck = dc.minIndex;
            uint256 maxIndexCheck = dc.treeIndex;
            uint256 cont = 0;
            while(ut[minIndex].treeIndex < minIndexCheck) {
                ++minIndex;
            }
            for(uint256 i = minIndex; i < ut.length; ++i) {
                if(ut[i].treeIndex <= maxIndexCheck) {
                    cont += ut[i].cont;
                } else {
                    break;
                }
            }
            sum += dc.value * cont / dc.sumCont;
        }
        return sum;
    }

    // 用户未领取的奖池
    function poolOf(address account) external view returns (uint256) {
        uint256 amount = _userIncome[account].bonus;
        if ((_gCondition.flag & 4) == 4) {
            if(_userTrees[account].length > 0 && _gState.totalContributes > 101) {
                uint256 cont = _userTrees[account][_userTrees[account].length - 1].totalCont;
                cont -= _bonusTaken[account];
                amount += uint64(_gState.bonus * cont / (_gState.totalContributes - 101));      
            }
        }
        return amount;
    }

    // 用户未领取的推荐奖励
    function refOf(address account) external view returns (uint256){
        return _userIncome[account].ref;
    }

    // 激活用户
    function activate(address superUser) external {
        require(_super[superUser] != address(0), "Super not activated");
        require(_super[msg.sender] == address(0), "Already activated");
        if ((_gCondition.flag & 2) == 2) {
            _userIncome[msg.sender].dividendDay = uint32(_getDay());
        } else {
            _userIncome[msg.sender].dividendDay = 0; // game not start
        }
        _super[msg.sender] = superUser;
    }

    // 购买背景
    function buyBg(uint256 index) external activated started {
        require(index < _bgs.length, "Bg index error");
        // require(_haveBg(msg.sender, index) == false, "Already have bg");
        usdt.transferFrom(msg.sender, _first, _bgs[index].price);
        _userBgs[msg.sender].push(index);
    }

    // 购买树苗
    function buyTree(uint256 index, uint256 num) external activated started {
        require(num > 0, "Must greater than zero");
        uint256 tIndex = _gCondition.treeNum;
        uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
        require(timeGap < _gCondition.remainTime, "Time is over!");
        uint256 price = _treePrice(index) * num;
        usdt.transferFrom(msg.sender, address(this), price);
        
        uint256 direct = price * 10 / 100;
        address superUser = _super[msg.sender];
        _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(direct);
        emit Direct(msg.sender, superUser, direct);
        uint256 indirect = price * 5 / 100;
        superUser = _super[superUser];
        _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(indirect);
        emit InDirect(msg.sender, superUser, indirect);

        //update trees
        uint256 cont = _treeCont(index) * num;
        uint256 preTotalCont = _gState.totalContributes;
        uint256 totalCont = preTotalCont + cont;
        _gState.totalContributes = uint48(totalCont);
        _treeList[tIndex] = Tree(0, 0, 0, uint8(index), uint32(block.timestamp), uint32(num), uint32(cont), uint64(totalCont), uint64(price / cont));
        _treeOwners[tIndex] = msg.sender;
        //add magic check
        uint256 mNum = totalCont / 500 - preTotalCont / 500;
        if(mNum > 0) {
            _magicCheck[preTotalCont / 500] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(mNum));
            emit MagicCheck(uint64(preTotalCont / 500), uint64(tIndex), uint64(_gCondition.minIndex), uint64(mNum));
        }

        uint256 idx = _getDay();
        _dividendCheck[idx] = DividendCheck(uint32(tIndex), 0, uint64(_dividendCheck[idx].value + price * 38 / 100), 0, uint64(totalCont));
        idx = _getRound();
        _lotteryCheck[idx] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(_lotteryCheck[idx].value + price * 5 / 100));

         // add users  tree
        TreeInfo[] storage ut = _userTrees[msg.sender];
        totalCont = cont; //user total cont
        if(ut.length > 0) {
            totalCont += ut[ut.length-1].totalCont;
        }
        ut.push(TreeInfo(uint64(tIndex), uint64(cont), uint128(totalCont)));

        _gState.bonus += uint64(price * 15 / 100);
        _gState.ecology += uint56(price * 12 / 100);
        _gState.community += uint56(price * 30 / 100 - direct - indirect);
        _gState.timestamp = uint32(block.timestamp);
        _gCondition.treeNum = uint32(tIndex + 1);

        _updateTime(cont, timeGap);

        emit BuyTree(msg.sender, price);
    }

    function _getDay() private view returns (uint256) {
        return (block.timestamp + 28800) / 86400 - _gCondition.dayOffset;
    }

    function _getRound() private view returns (uint256) {
        return block.timestamp / 7200 - _gCondition.roundOffset;
    }

    // 开启魔法树的NFT
    function openMagicTree(uint256 index) external {
        require(index < _userTrees[msg.sender].length, "Index error");
        uint256 tIndex = _userTrees[msg.sender][index].treeIndex;
        Tree storage t = _treeList[tIndex];
        require(t.isNFT == 1, "Not Magic tree!");
        require(t.isOpen == 0, "It is opened!");
        uint256 tokenId = _nftTokens[tIndex];
        IERC721(_nft).transferFrom(address(this), msg.sender, tokenId);
        t.isOpen = 1;
        emit NftUse(tokenId);
    }

    // 提取分红
    function dividendTake() external returns (uint256) {
        Income storage uIncome = _userIncome[msg.sender];
        uint256 dDay = uIncome.dividendDay;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentDay = _gCondition.currentDay;
        TreeInfo[] memory ut =  _userTrees[msg.sender];
        for(; dDay < currentDay; ++dDay) {
            DividendCheck memory dc = _dividendCheck[dDay];
            uint256 minIndexCheck = dc.minIndex;
            uint256 maxIndexCheck = dc.treeIndex;
            uint256 cont = 0;
            while(ut[minIndex].treeIndex < minIndexCheck) {
                ++minIndex;
            }
            for(uint256 i = minIndex; i < ut.length; ++i) {
                if(ut[i].treeIndex <= maxIndexCheck) {
                    cont += ut[i].cont;
                } else {
                    break;
                }
            }
            sum += dc.value * cont / dc.sumCont;
        }
        if (sum > 0) {
            usdt.transfer(msg.sender, sum);
        }
        uIncome.dividendDay = uint32(currentDay);
        uIncome.minIndex = uint32(minIndex);
        emit DividendTake(msg.sender, sum);
        return minIndex;
    }

    // 新增：提取推荐奖励，降低购买树苗的收费，合并转账，降低转账手续费
    function refTake() external {
        uint256 amount = _userIncome[msg.sender].ref;
        require(amount > 0, "No remain ref");
        usdt.transfer(msg.sender, amount);
        _userIncome[msg.sender].ref = 0;
        emit RefTake(msg.sender, amount);
    }

    // 提取奖池收益
     function poolTake() external {
        require((_gCondition.flag & 4) == 4, "It is not released!!");
        uint256 amount = _userIncome[msg.sender].bonus;
        if(_userTrees[msg.sender].length > 0 && _gState.totalContributes > 101) {
            uint256 cont = _userTrees[msg.sender][_userTrees[msg.sender].length - 1].totalCont;
            cont -= _bonusTaken[msg.sender];
            amount += uint64(_gState.bonus * cont / (_gState.totalContributes - 101));
            _bonusTaken[msg.sender] += cont;
        }
        
        require(amount > 0, "No remain bonus!");
        usdt.transfer(msg.sender, amount);
        _userIncome[msg.sender].bonus = 0;
        emit PoolTake(msg.sender, amount);
    }

    // 购买盲盒
    function buyBox() external activated {
        require(_userBox[msg.sender] == 0, "Only once");
        require((_gCondition.flag & 1) == 1, "Activity end");
        usdt.transferFrom(msg.sender, _first, 5000000);
        _userBox[msg.sender] = block.timestamp;
        _boxUsers.push(msg.sender);
    }

    // ---
    function openBox() external onlyAdmin {
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(4, 1, 0);
        _gCondition.flag ^= 1; //preBuy = 0
    }

    function addBg(uint256 _price, string memory _url) external onlyAdmin {
        _bgs.push(BackGround(uint128(_bgs.length), uint128(_price), _url));
    }
    
    // 抽奖
    function lottery() external onlyAdmin started {
        uint256 round = _getRound();
        uint256 currentRound = _gCondition.currentRound;
        require(round > currentRound, "It is not time yet!!");
        if (_lotteryCheck[currentRound].value > 0) {
            uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
            bytes32 requestId = _rollDice(seed, address(this));
            _requests[requestId] = Request(3, 1, uint128(currentRound));
        } else {
            _gCondition.currentRound += 1;
        }
    }
    
    // 抽神奇果树
    function genMagicTree() external onlyAdmin started {
        uint256 currentMagic = _gCondition.currentMagic;
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(1, 1, uint128(currentMagic));
    }
    
    // 抽取NFT
    function genNFT() external onlyAdmin {
        uint256 nftCount = _magicTrees.length / 20;
        require(_gCondition.currentNFT < nftCount, "It is not time yet!!");
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(2, 1, uint128(_gCondition.currentNFT));
    }

    function ecologyTake(address account) external onlyAdmin {
        if (_gState.ecology > 0) {
            usdt.transfer(account, _gState.ecology);
            _gState.ecology = 0;
        }
    }

    function communityTake(address account) external onlyAdmin {
        if (_gState.community > 0) {
            usdt.transfer(account, _gState.community);
            _gState.community = 0;
        }
    }

    function remainTake(address account, uint256 amount) external onlyAdmin {
        require((_gCondition.flag & 4) == 4, "It is not released!!");
        uint256 timePass = block.timestamp - _gState.timestamp;
        require(timePass > 31536000, "It is not time!");
        usdt.transfer(account, amount);
    }

    function dividend() external onlyAdmin {
        uint256 day = _getDay();
        uint256 currentDay = _gCondition.currentDay;
        require(day > currentDay, "It is not time yet!!");
        DividendCheck storage dCheck = _dividendCheck[currentDay];
        uint256 dValue = dCheck.value;
        uint256 maxIndex = dCheck.treeIndex;
        uint256 sumCont = dCheck.sumCont;
        uint256 minIndex = _gCondition.minIndex;
        uint256 minDay = _gCondition.minDay;
        if (minIndex > 0) {
            sumCont -= _treeList[minIndex - 1].totalCont;
        }
        uint256 totalShare = dValue / sumCont;
        if(currentDay > 0) {
            totalShare += _dividendCheck[currentDay-1].totalShare;
        }

        dCheck.minIndex = uint32(minIndex);
        dCheck.totalShare = uint32(totalShare);
        dCheck.sumCont = uint32(sumCont);

        // update minDay
        uint256 minShare = 0;
        if (minDay > 0) {
            minShare = _dividendCheck[minDay - 1].totalShare;
        }

        for(; minDay < currentDay; ++minDay) {
            DividendCheck memory dc = _dividendCheck[minDay];
            Tree memory t = _treeList[dc.treeIndex];
            if (totalShare - minShare < t.price * 3) {
                maxIndex = dc.treeIndex;
                break;
            }
            minShare = dc.totalShare;
            minIndex = dc.treeIndex + 1;
        }
        // update minIndex
        totalShare -= minShare;
        while(minIndex + 1 < maxIndex) {
            uint256 midIndex = (minIndex + maxIndex) >> 1;
            if (totalShare < _treeList[midIndex].price * 3) {
                maxIndex = midIndex;
            } else {
                minIndex = midIndex;
            }
        }
        if (totalShare >= _treeList[minIndex].price * 3) {
            minIndex += 1;
        }

        _gCondition.minIndex = uint32(minIndex);
        _gCondition.minDay = uint16(minDay);
        _gCondition.currentDay += 1;
        emit DoDividend(day, minIndex, minDay, dValue);
    }

    function poolRelease() external onlyAdmin {
        require(_ifEnd(), "It is not time yet!!");
        require((_gCondition.flag & 4) == 0, "It is released!!");
        uint256 reward = _gState.bonus * 40 / 100;
        uint256 secondContribute = Math.min(100, _gState.totalContributes - 1);
        uint256 leftCont = secondContribute;
        if (reward > 0) {
            uint256 idx = _gCondition.treeNum - 1;
            Tree memory t = _treeList[idx];
            address user = _treeOwners[idx];
            _userIncome[user].bonus += uint64(reward);
             _bonusTaken[user] += 1;
            if (t.cont > 1) {
                uint256 cont = Math.min(t.cont-1, 100);
                uint256 b = reward * cont / secondContribute;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
                _bonusTaken[user] += cont;
            }
            emit ReleasePool(user, _userIncome[user].bonus);
            while(leftCont > 0) {
                idx -= 1;
                t = _treeList[idx];
                user = _treeOwners[idx];
                uint256 cont = Math.min(t.cont, leftCont);
                uint256 b = reward * cont / secondContribute;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
                _bonusTaken[user] += cont;
            }
            _gState.bonus -= uint64(reward << 1);
        }
        _gCondition.flag ^= 4; //released
    }

    function _isSleep(uint256 blockTime) private pure returns (bool) {
        return (blockTime + 25200) % 86400 < 21600;
    }

    function _timeGap(uint256 begin, uint256 end) private pure returns (uint256) {
        if(!_isSleep(begin) && !_isSleep(end)) {
            if ((begin + 25200) % 86400 <= (end + 25200) % 86400) {
                return (end - begin) - (end - begin) / 86400 * 21600;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600 - 21600;
            }
        } else {
            if(_isSleep(begin)) {
                begin = (begin + 25200) / 86400 * 86400 - 3600;
            }
            if(_isSleep(end)) {
                end = (end + 25200) / 86400 * 86400 - 25200;
            }
            if(begin >= end) {
                return 0;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600;
            }

        }
    }
    
    // private 消耗gas更少
    function _ifEnd() private view returns (bool){
        uint256 dura = _timeGap(_gState.timestamp, block.timestamp);
        return dura >= _gCondition.remainTime;
    }

    function minValidTree() external view returns (uint256) {
        return _gCondition.minIndex;
    }

    function userTotalCont(address account) external view returns (uint256) {
        return _userTrees[account][_userTrees[account].length - 1].totalCont;
    }

    function ifEnd() external view returns (bool){
        return _ifEnd();
    }

    function _getLimit() private view returns (uint256) {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 50000) {
            return 86400;
        } else if (totalCont > 20000) {
            return 172800;
        } else if (totalCont > 10000) {
            return 345600;
        } else {
            return 691200;
        }
    }

    function _getTokenId() internal returns (uint256) {
        IERC721Enumerable nf = IERC721Enumerable(_nft);
        uint256 balance = nf.balanceOf(address(this));
        for (uint256 i = 0; i < balance; i++) {
            uint256 tId = nf.tokenOfOwnerByIndex(address(this), i);
            if (tId > _tokenId) {
                _tokenId = tId;
                return tId;
            }
        }
        return 0; //0表示没有剩余的nft，不要使用0作为nft tokenid
    }

    function setNftAddress(address nft) external onlyAdmin {
        _nft = nft;
    }
}

//SourceUnit: Owned.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}


//SourceUnit: TRC20Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract TRC20Interface {

    function totalSupply() public view virtual returns (uint);

    function balanceOf(address guy) public view virtual returns (uint);

    function allowance(address src, address guy) public view virtual returns (uint);

    function approve(address guy, uint wad) public  virtual returns (bool);

    function transfer(address dst, uint wad) public virtual returns (bool);

    function transferFrom(address src, address dst, uint wad) public virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract WinkMid {

    function setToken(address tokenAddress) public virtual;

    function transferAndCall(address from, address to, uint tokens, bytes memory _data) public virtual returns (bool success);

    function balanceOf(address guy) public view virtual returns (uint);

    function transferFrom(address src, address dst, uint wad) public virtual returns (bool);

    function allowance(address src, address guy) public view virtual returns (uint);

}

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns (uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The start offset to write to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Length of existing buffer data
            let buflen := mload(bufptr)
        // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
        // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
    * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write the byte at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns (buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Length of existing buffer data
            let buflen := mload(bufptr)
        // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
        // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
    * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        // Right-align data
        data = data >> (8 * (32 - len));
        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
    * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
    * @dev Writes an integer to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (right-aligned).
    * @return The original buffer, for chaining.
    */
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns (buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
        if (value <= 23) {
            buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.appendUint8(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.appendUint8(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if (value <= 0xFFFFFFFFFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
        buf.appendUint8(uint8((major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal pure {
        if (value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(- 1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/**
 * @title Library for common Winklink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Winklink {
    uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

    using Buffer for Buffer.buffer;
    using CBOR for Buffer.buffer;

    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunctionId;
        uint256 nonce;
        Buffer.buffer buf;
    }

    /**
     * @notice Initializes a Winklink request
     * @dev Sets the ID, callback address, and callback function signature on the request
     * @param self The uninitialized request
     * @param _id The Job Specification ID
     * @param _callbackAddress The callback address
     * @param _callbackFunction The callback function signature
     * @return The initialized request
     */
    function initialize(
        Request memory self,
        bytes32 _id,
        address _callbackAddress,
        bytes4 _callbackFunction
    ) internal pure returns (Winklink.Request memory) {
        Buffer.init(self.buf, defaultBufferSize);
        self.id = _id;
        self.callbackAddress = _callbackAddress;
        self.callbackFunctionId = _callbackFunction;
        return self;
    }

    /**
     * @notice Sets the data for the buffer without encoding CBOR on-chain
     * @dev CBOR can be closed with curly-brackets {} or they can be left off
     * @param self The initialized request
     * @param _data The CBOR data
     */
    function setBuffer(Request memory self, bytes memory _data)
    internal pure
    {
        Buffer.init(self.buf, _data.length);
        Buffer.append(self.buf, _data);
    }

    /**
     * @notice Adds a string value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The string value to add
     */
    function add(Request memory self, string memory _key, string memory _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeString(_value);
    }

    /**
     * @notice Adds a bytes value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The bytes value to add
     */
    function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeBytes(_value);
    }

    /**
     * @notice Adds a int256 value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The int256 value to add
     */
    function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeInt(_value);
    }

    /**
     * @notice Adds a uint256 value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The uint256 value to add
     */
    function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeUInt(_value);
    }

    /**
     * @notice Adds an array of strings to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _values The array of string values to add
     */
    function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.startArray();
        for (uint256 i = 0; i < _values.length; i++) {
            self.buf.encodeString(_values[i]);
        }
        self.buf.endSequence();
    }
}

interface WinklinkRequestInterface {
    function vrfRequest(
        address sender,
        uint256 payment,
        bytes32 id,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 nonce,
        uint256 version,
        bytes calldata data
    ) external;
}

/**
 * @title The WinklinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Winklink network
 */
contract WinklinkClient {
    using Winklink for Winklink.Request;

    uint256 constant internal LINK = 10 ** 18;
    uint256 constant private AMOUNT_OVERRIDE = 0;
    address constant private SENDER_OVERRIDE = address(0);
    uint256 constant private ARGS_VERSION = 1;

    WinkMid internal winkMid;
    TRC20Interface internal token;
    WinklinkRequestInterface private oracle;

    /**
     * @notice Creates a request that can hold additional parameters
     * @param _specId The Job Specification ID that the request will be created for
     * @param _callbackAddress The callback address that the response will be sent to
     * @param _callbackFunctionSignature The callback function signature to use for the callback address
     * @return A Winklink Request struct in memory
     */
    function buildWinklinkRequest(
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (Winklink.Request memory) {
        Winklink.Request memory req;
        return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
    }

    /**
     * @notice Sets the LINK token address
     * @param _link The address of the LINK token contract
     */
    function setWinklinkToken(address _link) internal {
        token = TRC20Interface(_link);
    }

    function setWinkMid(address _winkMid) internal {
        winkMid = WinkMid(_winkMid);
    }

    /**
     * @notice Retrieves the stored address of the LINK token
     * @return The address of the LINK token
     */
    function winkMidAddress()
    public
    view
    returns (address)
    {
        return address(winkMid);
    }

    /**
     * @notice Encodes the request to be sent to the vrfCoordinator contract
     * @dev The Winklink node expects values to be in order for the request to be picked up. Order of types
     * will be validated in the VRFCoordinator contract.
     * @param _req The initialized Winklink Request
     * @return The bytes payload for the `transferAndCall` method
     */
    function encodeVRFRequest(Winklink.Request memory _req)
    internal
    view
    returns (bytes memory)
    {
        return abi.encodeWithSelector(
            oracle.vrfRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req.id,
            _req.callbackAddress,
            _req.callbackFunctionId,
            _req.nonce,
            ARGS_VERSION,
            _req.buf.buf);
    }
}




//SourceUnit: VRF.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/** ****************************************************************************
  * @notice Verification of verifiable-random-function (VRF) proofs, following
  * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.

  * @dev Bibliographic references:

  * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
  * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05

  * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
  * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
  * ****************************************************************************
  * @dev USAGE

  * @dev The main entry point is randomValueFromVRFProof. See its docstring.
  * ****************************************************************************
  * @dev PURPOSE

  * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
  * @dev to Vera the verifier in such a way that Vera can be sure he's not
  * @dev making his output up to suit himself. Reggie provides Vera a public key
  * @dev to which he knows the secret key. Each time Vera provides a seed to
  * @dev Reggie, he gives back a value which is computed completely
  * @dev deterministically from the seed and the secret key.

  * @dev Reggie provides a proof by which Vera can verify that the output was
  * @dev correctly computed once Reggie tells it to her, but without that proof,
  * @dev the output is computationally indistinguishable to her from a uniform
  * @dev random sample from the output space.

  * @dev The purpose of this contract is to perform that verification.
  * ****************************************************************************
  * @dev DESIGN NOTES

  * @dev The VRF algorithm verified here satisfies the full unqiqueness, full
  * @dev collision resistance, and full pseudorandomness security properties.
  * @dev See "SECURITY PROPERTIES" below, and
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3

  * @dev An elliptic curve point is generally represented in the solidity code
  * @dev as a uint256[2], corresponding to its affine coordinates in
  * @dev GF(FIELD_SIZE).

  * @dev For the sake of efficiency, this implementation deviates from the spec
  * @dev in some minor ways:

  * @dev - Keccak hash rather than the SHA256 hash recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   Keccak costs much less gas on the EVM, and provides similar security.

  * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER

  * @dev - hashToCurve recursively hashes until it finds a curve x-ordinate. On
  * @dev   the EVM, this is slightly more efficient than the recommendation in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
  * @dev   nonce updated until a valid x-ordinate is found.

  * @dev - hashToCurve does not include a cipher version string or the byte 0x1
  * @dev   in the hash message, as recommended in step 5.B of the draft
  * @dev   standard. They are unnecessary here because no variation in the
  * @dev   cipher suite is allowed.

  * @dev - Similarly, the hash input in scalarFromCurvePoints does not include a
  * @dev   commitment to the cipher suite, either, which differs from step 2 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  * @dev   . Also, the hash input is the concatenation of the uncompressed
  * @dev   points, not the compressed points as recommended in step 3.

  * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
  * @dev   the value computed by Reggie as the nonce times the secp256k1
  * @dev   generator point, see steps 5 and 7 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
  * @dev   keccak hash of the original u. This is because we only verify the
  * @dev   calculation of u up to its address, by abusing ECRECOVER.
  * ****************************************************************************
  * @dev   SECURITY PROPERTIES

  * @dev Here are the security properties for this VRF:

  * @dev Full uniqueness: For any seed and valid VRF public key, there is
  * @dev   exactly one VRF output which can be proved to come from that seed, in
  * @dev   the sense that the proof will pass verifyVRFProof.

  * @dev Full collision resistance: It's cryptographically infeasible to find
  * @dev   two seeds with same VRF output from a fixed, valid VRF key

  * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
  * @dev   derived from a given seed, the outputs are computationally
  * @dev   indistinguishable from randomness.

  * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
  * @dev for these properties.

  * @dev For secp256k1, the key validation described in section
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
  * @dev is unnecessary, because secp256k1 has cofactor 1, and the
  * @dev representation of the public key used here (affine x- and y-ordinates
  * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
  * @dev the point at infinity.
  * ****************************************************************************
  * @dev OTHER SECURITY CONSIDERATIONS
  *
  * @dev The seed input to the VRF could in principle force an arbitrary amount
  * @dev of work in hashToCurve, by requiring extra rounds of hashing and
  * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
  * @dev However, under the Random Oracle Model the probability of choosing a
  * @dev point which forces n extra rounds in hashToCurve is 2⁻ⁿ. The base cost
  * @dev for calling hashToCurve is about 25,000 gas, and each round of checking
  * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
  * @dev which hashToCurve would cost more than 2,017,000 gas, one would have to
  * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
  * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)

  * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
  * @dev this means it is infeasible for an adversary to prevent correct
  * @dev operation of this contract by choosing an adverse seed.

  * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
  * @dev hashToCurve.)

  * @dev It may be possible to make a secure constant-time hashToCurve function.
  * @dev See notes in hashToCurve docstring.
*/
contract VRF {

  // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
  uint256 constant private GROUP_ORDER = // Number of points in Secp256k1
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  // Prime characteristic of the galois field over which Secp256k1 is defined
  uint256 constant private FIELD_SIZE =
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 constant private WORD_LENGTH_BYTES = 0x20;

  // (base^exponent) % FIELD_SIZE
  // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
  function bigModExp(uint256 base, uint256 exponent)
    internal view returns (uint256 exponentiation) {
      uint256 callResult;
      uint256[6] memory bigModExpContractInputs;
      bigModExpContractInputs[0] = WORD_LENGTH_BYTES;  // Length of base
      bigModExpContractInputs[1] = WORD_LENGTH_BYTES;  // Length of exponent
      bigModExpContractInputs[2] = WORD_LENGTH_BYTES;  // Length of modulus
      bigModExpContractInputs[3] = base;
      bigModExpContractInputs[4] = exponent;
      bigModExpContractInputs[5] = FIELD_SIZE;
      uint256[1] memory output;
      assembly { // solhint-disable-line no-inline-assembly
      callResult := staticcall(
        not(0),                   // Gas cost: no limit
        0x05,                     // Bigmodexp contract address
        bigModExpContractInputs,
        0xc0,                     // Length of input segment: 6*0x20-bytes
        output,
        0x20                      // Length of output segment
      )
      }
      if (callResult == 0) {revert("bigModExp failure!");}
      return output[0];
    }

  // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
  // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
  uint256 constant private SQRT_POWER = (FIELD_SIZE + 1) >> 2;

  // Computes a s.t. a^2 = x in the field. Assumes a exists
  function squareRoot(uint256 x) internal view returns (uint256) {
    return bigModExp(x, SQRT_POWER);
  }

  // The value of y^2 given that (x,y) is on secp256k1.
  function ySquared(uint256 x) internal pure returns (uint256) {
    // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
    uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
    return addmod(xCubed, 7, FIELD_SIZE);
  }

  // True iff p is on secp256k1
  function isOnCurve(uint256[2] memory p) internal pure returns (bool) {
    return ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
  }

  // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
  function fieldHash(bytes memory b) internal pure returns (uint256 x_) {
    x_ = uint256(keccak256(b));
    // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
    // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
    // string_to_point in the IETF draft
    while (x_ >= FIELD_SIZE) {
      x_ = uint256(keccak256(abi.encodePacked(x_)));
    }
  }

  // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
  // is always even, due to
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  // step 5.C, which references arbitrary_string_to_point, defined in
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
  // returning the point with given x ordinate, and even y ordinate.
  function newCandidateSecp256k1Point(bytes memory b)
    internal view returns (uint256[2] memory p) {
      p[0] = fieldHash(b);
      p[1] = squareRoot(ySquared(p[0]));
      if (p[1] % 2 == 1) {
        p[1] = FIELD_SIZE - p[1];
      }
    }

  // Domain-separation tag for initial hash in hashToCurve. Corresponds to
  // vrf.go/hashToCurveHashPrefix
  uint256 constant HASH_TO_CURVE_HASH_PREFIX = 1;

  // Cryptographic hash function onto the curve.
  //
  // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
  // DESIGN NOTES above for slight differences.)
  //
  // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
  // "Construction of Rational Points on Elliptic Curves over Finite Fields"
  // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
  // and suggested by
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
  // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
  //
  // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
  // https://www.pivotaltracker.com/story/show/171120900
  function hashToCurve(uint256[2] memory pk, uint256 input)
    internal view returns (uint256[2] memory rv) {
      rv = newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX,
                                                       pk, input));
      while (!isOnCurve(rv)) {
        rv = newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
      }
    }

  /** *********************************************************************
   * @notice Check that product==scalar*multiplicand
   *
   * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
   *
   * @param multiplicand: secp256k1 point
   * @param scalar: non-zero GF(GROUP_ORDER) scalar
   * @param product: secp256k1 expected to be multiplier * multiplicand
   * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
   */
  function ecmulVerify(uint256[2] memory multiplicand, uint256 scalar,
    uint256[2] memory product) internal pure returns(bool verifies)
  {
    require(scalar != 0); // Rules out an ecrecover failure case
    uint256 x = multiplicand[0]; // x ordinate of multiplicand
    uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
    // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
    // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
    bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
    address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
    // Explicit conversion to address takes bottom 160 bits
    address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
    return (actual == expected);
  }

  // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
  function projectiveSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
    internal pure returns(uint256 x3, uint256 z3) {
      uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
      uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
      (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

  // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
  function projectiveMul(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
    internal pure returns(uint256 x3, uint256 z3) {
      (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

  /** **************************************************************************
      @notice Computes elliptic-curve sum, in projective co-ordinates

      @dev Using projective coordinates avoids costly divisions

      @dev To use this with p and q in affine coordinates, call
      @dev projectiveECAdd(px, py, qx, qy). This will return
      @dev the addition of (px, py, 1) and (qx, qy, 1), in the
      @dev secp256k1 group.

      @dev This can be used to calculate the z which is the inverse to zInv
      @dev in isValidVRFOutput. But consider using a faster
      @dev re-implementation such as ProjectiveECAdd in the golang vrf package.

      @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
           coordinates of secp256k1 points. That is safe in this contract,
           because this method is only used by linearCombination, which checks
           points are on the curve via ecrecover.
      **************************************************************************
      @param px The first affine coordinate of the first summand
      @param py The second affine coordinate of the first summand
      @param qx The first affine coordinate of the second summand
      @param qy The second affine coordinate of the second summand

      (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
      **************************************************************************
      Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
      on secp256k1, in P²(𝔽ₙ)
      @return sx 
      @return sy
      @return sz
  */
  function projectiveECAdd(uint256 px, uint256 py, uint256 qx, uint256 qy)
    internal pure returns(uint256 sx, uint256 sy, uint256 sz) {
      // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
      // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
      // We take the equations there for (sx,sy), and homogenize them to
      // projective coordinates. That way, no inverses are required, here, and we
      // only need the one inverse in affineECAdd.

      // We only need the "point addition" equations from Hankerson et al. Can
      // skip the "point doubling" equations because p1 == p2 is cryptographically
      // impossible, and require'd not to be the case in linearCombination.

      // Add extra "projective coordinate" to the two points
      (uint256 z1, uint256 z2) = (1, 1);

      // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
      uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
      uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

      uint256 dx; // Accumulates denominator from sx calculation
      // sx=((qy-py)/(qx-px))^2-px-qx
      (sx, dx) = projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
      (sx, dx) = projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
      (sx, dx) = projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

      uint256 dy; // Accumulates denominator from sy calculation
      // sy=((qy-py)/(qx-px))(px-sx)-py
      (sy, dy) = projectiveSub(px, z1, sx, dx); // px-sx
      (sy, dy) = projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
      (sy, dy) = projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

      if (dx != dy) { // Cross-multiply to put everything over a common denominator
        sx = mulmod(sx, dy, FIELD_SIZE);
        sy = mulmod(sy, dx, FIELD_SIZE);
        sz = mulmod(dx, dy, FIELD_SIZE);
      } else { // Already over a common denominator, use that for z ordinate
        sz = dx;
      }
    }

  // p1+p2, as affine points on secp256k1.
  //
  // invZ must be the inverse of the z returned by projectiveECAdd(p1, p2).
  // It is computed off-chain to save gas.
  //
  // p1 and p2 must be distinct, because projectiveECAdd doesn't handle
  // point doubling.
  function affineECAdd(
    uint256[2] memory p1, uint256[2] memory p2,
    uint256 invZ) internal pure returns (uint256[2] memory) {
    uint256 x;
    uint256 y;
    uint256 z;
    (x, y, z) = projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
    require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
    // Clear the z ordinate of the projective representation by dividing through
    // by it, to obtain the affine representation
    return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
  }

  // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
  // cryptographically high probability.)
  function verifyLinearCombinationWithGenerator(
    uint256 c, uint256[2] memory p, uint256 s, address lcWitness)
    internal pure returns (bool) {
      // Rule out ecrecover failure modes which return address 0.
      require(lcWitness != address(0), "bad witness");
      uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
      bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
      bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
      // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
      // The point corresponding to the address returned by
      // ecrecover(-s*p[0],v,p[0],c*p[0]) is
      // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
      // See https://crypto.stackexchange.com/a/18106
      // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
      address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
      return computed == lcWitness;
    }

  // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
  // requires cp1Witness != sp2Witness (which is fine for this application,
  // since it is cryptographically impossible for them to be equal. In the
  // (cryptographically impossible) case that a prover accidentally derives
  // a proof with equal c*p1 and s*p2, they should retry with a different
  // proof nonce.) Assumes that all points are on secp256k1
  // (which is checked in verifyVRFProof below.)
  function linearCombination(
    uint256 c, uint256[2] memory p1, uint256[2] memory cp1Witness,
    uint256 s, uint256[2] memory p2, uint256[2] memory sp2Witness,
    uint256 zInv)
    internal pure returns (uint256[2] memory) {
      require((cp1Witness[0] - sp2Witness[0]) % FIELD_SIZE != 0,
              "points in sum must be distinct");
      require(ecmulVerify(p1, c, cp1Witness), "First multiplication check failed");
      require(ecmulVerify(p2, s, sp2Witness), "Second multiplication check failed");
      return affineECAdd(cp1Witness, sp2Witness, zInv);
    }

  // Domain-separation tag for the hash taken in scalarFromCurvePoints.
  // Corresponds to scalarFromCurveHashPrefix in vrf.go
  uint256 constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

  // Pseudo-random number from inputs. Matches vrf.go/scalarFromCurvePoints, and
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  // The draft calls (in step 7, via the definition of string_to_int, in
  // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
  // first hash without checking that it corresponds to a number less than the
  // group order, which will lead to a slight bias in the sample.
  //
  // TODO(alx): We could save a bit of gas by following the standard here and
  // using the compressed representation of the points, if we collated the y
  // parities into a single bytes32.
  // https://www.pivotaltracker.com/story/show/171120588
  function scalarFromCurvePoints(
    uint256[2] memory hash, uint256[2] memory pk, uint256[2] memory gamma,
    address uWitness, uint256[2] memory v)
    internal pure returns (uint256 s) {
      return uint256(
        keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX,
                                   hash, pk, gamma, v, uWitness)));
    }

  // True if (gamma, c, s) is a correctly constructed randomness proof from pk
  // and seed. zInv must be the inverse of the third ordinate from
  // projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
  // section 5.3 of the IETF draft.
  //
  // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
  // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
  // (which I could make a uint256 without using any extra space.) Would save
  // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
  function verifyVRFProof(
    uint256[2] memory pk, uint256[2] memory gamma, uint256 c, uint256 s,
    uint256 seed, address uWitness, uint256[2] memory cGammaWitness,
    uint256[2] memory sHashWitness, uint256 zInv)
    internal view {
      require(isOnCurve(pk), "public key is not on curve");
      require(isOnCurve(gamma), "gamma is not on curve");
      require(isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
      require(isOnCurve(sHashWitness), "sHashWitness is not on curve");
      // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
      // we use the address of u instead of u itself. Also, here we add the
      // terms instead of taking the difference, and in the proof consruction in
      // vrf.GenerateProof, we correspondingly take the difference instead of
      // taking the sum as they do in step 7 of section 5.1.)
      require(
        verifyLinearCombinationWithGenerator(c, pk, s, uWitness),
        "addr(c*pk+s*g) != _uWitness"
      );
      // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
      uint256[2] memory hash = hashToCurve(pk, seed);
      // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
      uint256[2] memory v = linearCombination(
        c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
      // Steps 7. and 8. of IETF draft section 5.3
      uint256 derivedC = scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
      require(c == derivedC, "invalid proof");
    }

  // Domain-separation tag for the hash used as the final VRF output.
  // Corresponds to vrfRandomOutputHashPrefix in vrf.go
  uint256 constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

  // Length of proof marshaled to bytes array. Shows layout of proof
  uint public constant PROOF_LENGTH = 64 + // PublicKey (uncompressed format.)
    64 + // Gamma
    32 + // C
    32 + // S
    32 + // Seed
    0 + // Dummy entry: The following elements are included for gas efficiency:
    32 + // uWitness (gets padded to 256 bits, even though it's only 160)
    64 + // cGammaWitness
    64 + // sHashWitness
    32; // zInv  (Leave Output out, because that can be efficiently calculated)

  /* ***************************************************************************
   * @notice Returns proof's output, if proof is valid. Otherwise reverts

   * @param proof A binary-encoded proof, as output by vrf.Proof.MarshalForSolidityVerifier
   *
   * Throws if proof is invalid, otherwise:
   * @return output i.e., the random output implied by the proof
   * ***************************************************************************
   * @dev See the calculation of PROOF_LENGTH for the binary layout of proof.
   */
  function randomValueFromVRFProof(bytes memory proof)
    internal view returns (uint256 output) {
      require(proof.length == PROOF_LENGTH, "wrong proof length");

      uint256[2] memory pk; // parse proof contents into these variables
      uint256[2] memory gamma;
      // c, s and seed combined (prevents "stack too deep" compilation error)
      uint256[3] memory cSSeed;
      address uWitness;
      uint256[2] memory cGammaWitness;
      uint256[2] memory sHashWitness;
      uint256 zInv;
      (pk, gamma, cSSeed, uWitness, cGammaWitness, sHashWitness, zInv) = abi.decode(
        proof, (uint256[2], uint256[2], uint256[3], address, uint256[2],
                uint256[2], uint256));
      verifyVRFProof(
        pk,
        gamma,
        cSSeed[0], // c
        cSSeed[1], // s
        cSSeed[2], // seed
        uWitness,
        cGammaWitness,
        sHashWitness,
        zInv
      );
      output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, gamma)));
    }
}


//SourceUnit: VRFConsumerBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./TRC20Interface.sol";
import "./VRFRequestIDBase.sol";
// import "./Owned.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase, WinklinkClient {
    event VRFRequested(bytes32 indexed id);

    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    /**
    * @notice fulfillRandomness handles the VRF response. Your contract must
    * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
    * @notice principles to keep in mind when implementing your fulfillRandomness
    * @notice method.
    *
    * @dev VRFConsumerBase expects its subcontracts to have a method with this
    * @dev signature, and will call it once it has verified the proof
    * @dev associated with the randomness. (It is triggered via a call to
    * @dev rawFulfillRandomness, below.)
    *
    * @param requestId The Id initially returned by requestRandomness
    * @param randomness the VRF output
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal virtual;
    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of WIN to send with the request
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
      internal returns (bytes32 requestId)
    {
        Winklink.Request memory _req;
        _req = buildWinklinkRequest(_keyHash, address(this), this.rawFulfillRandomness.selector);
        _req.nonce = nonces[_keyHash];
        _req.buf.buf = abi.encode(_keyHash, _seed);
        token.approve(winkMidAddress(), _fee);
        require(winkMid.transferAndCall(address(this), vrfCoordinator, _fee, encodeVRFRequest(_req)), "unable to transferAndCall to vrfCoordinator");

        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful winkMid.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;

        return makeRequestId(_keyHash, vRFSeed);
    }

    /**
     * @param _win The address of the WIN token
     * @param _winkMid The address of the WinkMid token
     * @param _vrfCoordinator The address of the VRFCoordinator contract
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _win, address _winkMid) {
        setWinklinkToken(_win);
        setWinkMid(_winkMid);
        vrfCoordinator = _vrfCoordinator;
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}


//SourceUnit: VRFRequestIDBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}