/**
 *Submitted for verification at Etherscan.io on 2021-03-17
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

contract WrappedNFT is ERC20 {
    using SafeMath for uint256;

    IERC721 public nftAddress=IERC721(0xd37a7CDeF58597dE177FdD8B6d5154A79dC49807);
    address public foundry = address(0x5B50fb8281CB679A3102d3de22DD05A1aD895E8F);
    uint256[] public depositedNftTokenIds;

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

    function wrap(uint256[] calldata _IdsToWrap) public {
        for (uint256 i = 0; i < _IdsToWrap.length; i++) {
            depositedNftTokenIds.push(_IdsToWrap[i]);
            nftAddress.safeTransferFrom(msg.sender, address(this), _IdsToWrap[i]);
            emit NftWrapped(_IdsToWrap[i]);
        }
        _mint(msg.sender, _IdsToWrap.length * (10**decimals));
    }

    function unwrap(uint256 _amount) public {
        require(msg.sender == address(foundry) || !isContract(msg.sender), "WrappedNFT: Address must not be a contract.");
        unwrapFor(_amount, msg.sender);
    }

    function unwrapFor(uint256 _amount, address _recipient) public {
        require(msg.sender == address(foundry) || !isContract(_recipient), "WrappedNFT: Recipient must not be a contract.");
        require(_recipient != address(0), "WrappedNFT: Cannot send to void address.");
        _burn(msg.sender, _amount * (10**decimals));
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = depositedNftTokenIds[depositedNftTokenIds.length - 1];
            depositedNftTokenIds.pop();
            nftAddress.safeTransferFrom(address(this), _recipient, _tokenId);
            emit NftUnwrapped(_tokenId);
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