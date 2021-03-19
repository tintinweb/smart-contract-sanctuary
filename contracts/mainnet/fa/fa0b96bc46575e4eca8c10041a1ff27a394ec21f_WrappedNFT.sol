/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.7.6;

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow.");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow.");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow.");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero.");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero.");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    mapping (address => uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) public _allowance;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address _spender, uint256 _value) public override returns (bool _success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool _success) {
        require(_to != address(0), "ERC20: Recipient address is null.");
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool _success) {
        require(_to != address(0), "ERC20: Recipient address is null.");
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal {
        _totalSupply = _totalSupply.add(_amount);
        _balanceOf[_to] = _balanceOf[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal {
        require(_from != address(0), "ERC20: Burning from address 0.");
        _balanceOf[_from] = _balanceOf[_from].sub(_amount, "ERC20: burn amount exceeds balance.");
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_from, address(0), _amount);
    }
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

contract WrappedNFT is ERC20, ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public nftAddress=IERC721(0x50f5474724e0Ee42D9a4e711ccFB275809Fd6d4a);
    uint256[] public depositedNftTokenIds;
    mapping (uint256 => bool) private tokenIdIsDeposited;
    
    event NftWrapped(uint256 axieId);
    event NftUnwrapped(uint256 axieId);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
    }

    function isContract(address _addr) internal view returns (bool) {
        uint32 _size;
        assembly {
            _size:= extcodesize(_addr)
        }
        return (_size > 0);
    }

    function wrap(uint256[] calldata _IdsToWrap) external nonReentrant {
        for (uint256 i = 0; i < _IdsToWrap.length; i++) {
            depositedNftTokenIds.push(_IdsToWrap[i]);
            tokenIdIsDeposited[_IdsToWrap[i]] = true;
            nftAddress.safeTransferFrom(msg.sender, address(this), _IdsToWrap[i]);
            emit NftWrapped(_IdsToWrap[i]);
        }
        _mint(msg.sender, _IdsToWrap.length * (10**decimals));
    }

    function _popNft() internal returns(uint256){
        require(depositedNftTokenIds.length > 0, 'there are no NFTs in the array');
        uint256 tokenId = depositedNftTokenIds[depositedNftTokenIds.length -1];
        depositedNftTokenIds.pop();
        while(tokenIdIsDeposited[tokenId] == false){
            tokenId = depositedNftTokenIds[depositedNftTokenIds.length - 1];
            depositedNftTokenIds.pop();
        }
        tokenIdIsDeposited[tokenId] = false;
        return tokenId;
    }
    
    function unwrap(uint256 _amount) external nonReentrant {
        _burn(msg.sender, _amount * (10**decimals));
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = _popNft();
            nftAddress.safeTransferFrom(address(this), msg.sender, _tokenId);
            emit NftUnwrapped(_tokenId);
        }
    }

    function unwrapFor(uint256 _amount, address _recipient) external nonReentrant {
        require(_recipient != address(0), "WrappedNFT: Cannot send to void address.");
        _burn(msg.sender, _amount * (10**decimals));
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = _popNft();
            nftAddress.safeTransferFrom(address(this), _recipient, _tokenId);
            emit NftUnwrapped(_tokenId);
        }
    }

    function unwrapFor(uint256[] calldata _tokenIds, address _recipient) external nonReentrant {
        require(_recipient != address(0), "WrappedNFT: Cannot send to void address.");
        uint256 numTokensToBurn = _tokenIds.length;
        _burn(msg.sender, numTokensToBurn * (10**decimals));
        for (uint256 i = 0; i < numTokensToBurn; i++) {
            uint256 _tokenIdToWithdraw = _tokenIds[i];
            require(tokenIdIsDeposited[_tokenIdToWithdraw] == true, 'this NFT has already been withdrawn');
            tokenIdIsDeposited[_tokenIdToWithdraw] = false;
            nftAddress.safeTransferFrom(address(this), _recipient, _tokenIdToWithdraw);
            emit NftUnwrapped(_tokenIdToWithdraw);
        }
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        require(msg.sender == address(nftAddress), "Not proper NFT");
        return this.onERC721Received.selector;
    }
}