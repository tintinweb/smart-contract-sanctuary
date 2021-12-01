//SourceUnit: CF_SHOW.sol

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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
    function onTRC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onTRC721Received.selector;
    }
}

contract CrazyForest is TRC721Holder {
    using SafeMath for uint256;

    struct Tree {
        uint8 index;
        uint256 buyTime;
        uint256 num;
    }

    struct MagicTree {
        bool status;
        uint256 buyTime;
        uint256 tokenId;
    }

    struct BackGround {
        uint256 index;
        uint256 price;
        string url;
    }

    struct MagicIndex {
        uint256 index;
        address user;
    }

    struct Order {
        uint256 contribute;
        address user;
    }

    bool public desert = true;
    uint256 public current = 1;
    uint256 public remainTime;
    uint256 private _singlePrice = 1000000;
    uint256 private _magic;
    uint256 private _magicNft;
    uint256 private _magicTree;
    uint256 private _waterEpoch;
    uint256 private _dividend;
    uint256 private _pool;
    uint256 private _lottery;
    uint256 private _tokenId = 1;
    address public stakeToken;
    address private _first;
    address private _admin;
    address private _nft;

    uint256[] _trees = [1, 2, 5, 10, 20, 50, 100, 200];
    uint256[] _increase = [600, 300, 60, 60, 30];
    BackGround[] _bgs;


    mapping(uint256 => uint256) _totalContributes;
    mapping(uint256 => uint256) _checkPoints;
    mapping(address => address) _super;
    mapping(address => uint256) _userDividends;
    mapping(address => uint256) _userPool;
    mapping(uint256 => MagicIndex) _magicIndexes;
    mapping(uint256 => mapping(address => bool)) _userOut;
    mapping(uint256 => mapping(uint256 => bool)) _magicGetNft;
    mapping(uint256 => mapping(address => uint256)) _userContribute;
    mapping(uint256 => mapping(address => uint256)) _userWater;
    mapping(uint256 => mapping(address => uint256)) _userTotalDividends;
    mapping(uint256 => mapping(address => uint256)) _userTotalInvest;
    mapping(uint256 => mapping(address => mapping(uint256 => Tree[]))) _userTree;
    mapping(uint256 => mapping(address => MagicTree[])) _userMagicTree;
    mapping(uint256 => address[]) _contributeUsers;
    mapping(uint256 => address[]) _waterUsers;
    mapping(uint256 => Order[]) _orders;
    mapping(address => uint256[]) _userBgs;

    constructor(address _stakeToken, address _f, address _n) {
        _admin = msg.sender;
        stakeToken = _stakeToken;
        _first = _f;
        _nft = _n;
    }

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Direct(address indexed user, address superUser, uint256 amount);
    event InDirect(address indexed user, address inSuper, uint256 amount);
    event BuyTree(address indexed user, uint256 price);
    event Lottery(address indexed user, uint256 amount);
    event DividendTake(address indexed user, uint256 amount);
    event PoolTake(address indexed user, uint256 amount);
    event NftUse(uint256 tokenId);

    modifier activated(){
        require(_super[msg.sender] != address(0) || msg.sender == _first, "Must activate first");
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == _admin, "Only admin can change items");
        _;
    }


    function allBg() public view returns (BackGround[] memory){
        return _bgs;
    }


    function treePrice(uint8 index) public view returns (uint256){
        require(index < _trees.length, "Index error");
        return _trees[index].mul(_singlePrice).mul(_totalContributes[current].div(1000).mul(5).add(1000)).div(1000);
    }


    function checkPoint() public view returns (uint256){
        return _checkPoints[current];
    }


    function isActivate(address account) public view returns (bool){
        return account == _first || _super[account] != address(0);
    }


    function bgOf(address account) public view returns (uint256[] memory){
        return _userBgs[account];
    }


    function totalDividend() public view returns (uint256){
        return _dividend;
    }


    function totalPool() public view returns (uint256){
        return _pool;
    }


    function totalLottery() public view returns (uint256){
        return _lottery;
    }


    function totalContribute() public view returns (uint256){
        return _totalContributes[current];
    }


    function treeOf(address account, uint256 index) public view returns (Tree[] memory){
        return _userTree[current][account][index];
    }


    function magicTreeOf(address account) public view returns (MagicTree[] memory){
        return _userMagicTree[current][account];
    }


    function dividendOf(address account) public view returns (uint256){
        return _userDividends[account];
    }


    function poolOf(address account) public view returns (uint256){
        return _userPool[account];
    }


    function userC(address account) public view returns (uint256){
        return _userContribute[current][account];
    }


    function waterCountOf(address account) public view returns (uint256){
        return _userWater[_waterEpoch][account];
    }


    function activate(address superUser) public {
        require(isActivate(superUser) == true, "Super not activated");
        require(isActivate(msg.sender) == false, "Already activated");
        require(superUser != msg.sender, "Can not active self");
        _super[msg.sender] = superUser;
    }


    function buyBg(uint256 index) public activated {
        require(index < _bgs.length, "Bg index error");
        require(haveBg(msg.sender, index) == false, "Already have bg");
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, _first, _bgs[index].price);
        _userBgs[msg.sender].push(index);
    }


    function buyTree(uint8 index, uint256 num) public activated {
        require(index < _trees.length, "Index error");
        require(num > 0, "Must greater than zero");
        uint256 price = treePrice(index).mul(num);
        uint256 direct = 0;
        address superUser = _super[msg.sender];
        if (superUser != address(0)) {
            direct = price.mul(10).div(100);
            TransferHelper.safeTransferFrom(stakeToken, msg.sender, superUser, direct);
            emit Direct(msg.sender, superUser, direct);
        }
        uint256 indirect = 0;
        address inSuper = _super[superUser];
        if (inSuper != address(0)) {
            indirect = price.mul(5).div(100);
            TransferHelper.safeTransferFrom(stakeToken, msg.sender, inSuper, indirect);
            emit InDirect(msg.sender, inSuper, indirect);
        }

        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), price.mul(58).div(100));
        _dividend = _dividend.add(price.mul(38).div(100));
        _pool = _pool.add(price.mul(15).div(100));
        _lottery = _lottery.add(price.mul(5).div(100));

        uint256 remain = price.sub(direct).sub(indirect).sub(price.mul(58).div(100));
        TransferHelper.safeTransferFrom(stakeToken, msg.sender,_first,remain);

        _addContribute(msg.sender, index, num);
        _updateTime(index, num);
        _addTree(msg.sender, index, num);
        _addMagicTree();
        desert = false;
        _userOut[current][msg.sender] = false;
        _userTotalInvest[current][msg.sender] = _userTotalInvest[current][msg.sender].add(price);

        emit BuyTree(msg.sender, price);
    }


    function water() public activated {
        require(_userContribute[current][msg.sender] > 0, "Can't do that");
        require(_userWater[_waterEpoch][msg.sender] < 1, "Already watered");
        _userWater[_waterEpoch][msg.sender] = 1;
        _waterUsers[_waterEpoch].push(msg.sender);
    }


    function openMagicTree(uint256 index) public activated {
        require(index < _userMagicTree[current][msg.sender].length, "Index error");
        MagicTree memory mt = _userMagicTree[current][msg.sender][index];
        require(mt.status == false, "Already opened");
        IERC721(_nft).transferFrom(address(this), msg.sender, mt.tokenId);
        _userMagicTree[current][msg.sender][index].status = true;
        emit NftUse(mt.tokenId);
    }


    function dividendTake() public activated {
        uint256 amount = _userDividends[msg.sender];
        require(amount > 0, "No remain dividend");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userDividends[msg.sender] = 0;
        emit DividendTake(msg.sender, amount);
    }


    function poolTake() public activated {
        uint256 amount = _userPool[msg.sender];
        require(amount > 0, "No remain pool");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userPool[msg.sender] = 0;
        emit PoolTake(msg.sender, amount);
    }


    function addBg(uint256 _price, string memory _url) public onlyAdmin {
        _bgs.push(BackGround(_bgs.length, _price, _url));
    }

    function lottery() public onlyAdmin {
        if (_lottery > 0) {
            address user = _randUser(1);
            TransferHelper.safeTransfer(stakeToken, user, _lottery);
            emit Lottery(user, _lottery);
            _lottery = 0;
        }
    }

    function dividend() public onlyAdmin {
        if (_waterUsers[_waterEpoch].length > 0 && _dividend > 0 && _totalContributes[current] > 0) {
            address[] memory users = _waterUsers[_waterEpoch];
            uint256 totalCont = 0;
            for (uint256 i = 0; i < users.length; i++) {
                if (_userOut[current][users[i]] == false) {
                    totalCont = totalCont.add(_userContribute[current][users[i]]);
                }
            }
            if (totalCont > 0) {
                for (uint256 i = 0; i < users.length; i++) {
                    if (_userOut[current][users[i]] == false) {
                        uint256 amount = _userContribute[current][users[i]].mul(_dividend).div(totalCont);
                        if (amount > 0) {
                            _userDividends[users[i]] = _userDividends[users[i]].add(amount);
                            _userTotalDividends[current][users[i]] = _userTotalDividends[current][users[i]].add(amount);
                            if (_userTotalDividends[current][users[i]] >= _userTotalInvest[current][users[i]].mul(3)) {
                                _userOut[current][users[i]] = true;
                            }
                        }
                    }
                }
            }
            _dividend = 0;
        }
        _waterEpoch = _waterEpoch + 1;
    }

    function poolRelease() public onlyAdmin {
        uint256 ct = 0;
        uint256 reward = _pool.mul(40).div(100);
        uint256 rewardThird = _pool.mul(20).div(100);
        uint256 secondContribute = Math.min(100, _totalContributes[current].sub(1));

        if (_orders[current].length > 0) {
            for (uint256 i = 0; i < _orders[current].length; i++) {
                Order memory order = _orders[current][_orders[current].length - 1 - i];
                if (i == 0) {
                    _userPool[order.user] = _userPool[order.user].add(reward);
                    if (order.contribute > 1 && order.contribute <= 101) {
                        _userPool[order.user] = _userPool[order.user].add(reward.mul(order.contribute - 1).div(secondContribute));
                        ct = order.contribute - 1;
                    } else if (order.contribute > 101) {
                        _userPool[order.user] = _userPool[order.user].add(reward);
                        ct = 100;
                        uint256 lastContribute = _totalContributes[current].sub(101);
                        _userPool[order.user] = _userPool[order.user].add(rewardThird.mul(order.contribute.sub(101)).div(lastContribute));
                    }
                } else {
                    if (ct < 100) {
                        if (order.contribute <= 100 - ct) {
                            _userPool[order.user] = _userPool[order.user].add(reward.mul(order.contribute).div(secondContribute));
                            ct = ct.add(order.contribute);
                        } else {
                            _userPool[order.user] = _userPool[order.user].add(reward.mul(100 - ct).div(secondContribute));
                            uint256 lastContribute = _totalContributes[current].sub(101);
                            _userPool[order.user] = _userPool[order.user].add(rewardThird.mul(order.contribute.sub(100 - ct)).div(lastContribute));
                            ct = 100;
                        }
                    } else {
                        uint256 lastContribute = _totalContributes[current].sub(101);
                        _userPool[order.user] = _userPool[order.user].add(rewardThird.mul(order.contribute).div(lastContribute));
                    }
                }
            }
        }
        current = current + 1;
        desert = true;
        _magic = 0;
        _magicNft = 0;
        _magicTree = 0;
    }

    function haveBg(address account, uint256 index) private view returns (bool){
        for (uint256 i = 0; i < _userBgs[account].length; i++) {
            if (_userBgs[account][i] == index) {
                return true;
            }
        }
        return false;
    }

    function _updateTime(uint8 index, uint256 num) private {
        uint256 _increaseIndex = Math.min(_totalContributes[current].div(50000), 4);
        uint256 _inc = _increase[_increaseIndex].mul(_trees[index].mul(num));
        if (desert) {
            remainTime = 86400;
        } else {
            remainTime = Math.min(remainTime.add(_inc), _getLimit());
        }
    }

    function _getLimit() private view returns (uint256){
        uint256 tc = _totalContributes[current];
        if (tc <= 10000) {
            return 691200;
        } else if (tc > 10000 && tc <= 20000) {
            return 345600;
        } else if (tc > 20000 && tc <= 50000) {
            return 172800;
        } else {
            return 86400;
        }
    }

    function _addContribute(address account, uint8 index, uint256 num) private {
        _contributeUsers[current].push(account);
        _totalContributes[current] = _totalContributes[current].add(_trees[index].mul(num));
        _userContribute[current][account] = _userContribute[current][account].add(_trees[index].mul(num));
        _orders[current].push(Order(_trees[index].mul(num), account));
    }


    function _addTree(address account, uint8 index, uint256 num) private {
        _userTree[current][account][index].push(Tree(index, block.timestamp, num));
    }

    function _addMagicTree() private {
        uint256 m = _totalContributes[current].div(500).sub(_magic);
        if (m > 0) {
            address user;
            for (uint256 i = 0; i < m; i++) {
                user = _randUser(i);
                _userMagicTree[current][user].push(MagicTree(false, block.timestamp, 0));
                _magicIndexes[_magicTree] = MagicIndex(_userMagicTree[current][user].length - 1, user);
                _magicTree = _magicTree + 1;
            }
            _magic = _magic.add(m);
        }
        uint256 n = _totalContributes[current].div(10000).sub(_magicNft);
        uint256 balance = IERC721Enumerable(_nft).balanceOf(address(this));
        if (n > 0 && balance > 0) {
            uint256 rand;
            n = Math.min(n, balance);
            for (uint256 j = 0; j < n; j++) {
                uint256 k = 0;
                rand = _rand(k).mod(_magicTree);
                while (_magicGetNft[current][rand]) {
                    k = k + 1;
                    rand = _rand(k).mod(_magicTree);
                }
                _magicGetNft[current][rand] = true;
                MagicIndex memory mi = _magicIndexes[rand];
                _userMagicTree[current][mi.user][mi.index].tokenId = _getTokenId();
            }
            _magicNft = _magicNft.add(n);
        }
    }

    function _getTokenId() internal returns (uint256) {
        IERC721Enumerable nf = IERC721Enumerable(_nft);
        uint256 tId = Math.max(_tokenId, nf.tokenOfOwnerByIndex(address(this), 0));
        if (nf.ownerOf(tId) == address(this)) {
            _tokenId = tId + 1;
            return tId;
        } else {
            for (uint256 i = 0; i < nf.balanceOf(address(this)); i++) {
                tId = nf.tokenOfOwnerByIndex(address(this), i);
                if (tId >= _tokenId) {
                    _tokenId = tId + 1;
                    return tId;
                }
            }
        }
        return 0;
    }

    function _randUser(uint256 num) private view returns (address){
        uint256 random = _rand(num);
        return _contributeUsers[current][random.mod(_contributeUsers[current].length)];
    }

    function _rand(uint256 k) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, k, _tokenId, _totalContributes[current])));
    }


}