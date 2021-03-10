/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.7.0;

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

interface AxieCore is IERC721 {
	function getAxie(uint256 _axieId) external view returns (uint256 _genes, uint256 _bornAt);
}

interface AxieExtraData {
	function getExtra(uint256 _axieId) external view returns (uint256, uint256, uint256, uint256 /* breed count */);
}

contract Ownable {
	address public owner;

	constructor () {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Not owner");
		_;
	}
	
	function setOwnership(address _newOwner) external onlyOwner {
		owner = _newOwner;
	}
}

contract Pausable is Ownable {
	bool public isPaused;
	
	constructor () {
		isPaused = false;
	}
	
	modifier notPaused() {
		require(!isPaused, "paused");
		_;
	}
	
	function pause() external onlyOwner {
		isPaused = true;
	}
	
	function unpause() external onlyOwner {
		isPaused = false;
	}
}

contract WrappedOrigin is ERC20("Wrapped Origin Axie", "WOA", 18), Pausable {
	using SafeMath for uint256;

	AxieCore public constant AXIE_CORE = AxieCore(0xAC70c81405314455908451F429b5c4511b3dfd1A);

	uint256[] public axieIds;

	event AxieWrapped(uint256 axieId);
	event AxieUnwrapped(uint256 axieId);

	function isContract(address _addr) internal view returns (bool) {
		uint32 _size;
		assembly {
			_size:= extcodesize(_addr)
		}
		return (_size > 0);
	}

	function _getSeed(uint256 _seed, address _sender) internal view returns (uint256) {
		if (_seed == 0)
			return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _sender)));
		else
			return uint256(keccak256(abi.encodePacked(_seed)));
	}

	// beast 0000 aqua 0100 plant 0011 bug 0001 bird 0010 reptile 0101
	function isValidCommonOrigin(uint256 _axieId) public view returns(bool) {
		(uint256 _genes,) = AXIE_CORE.getAxie(_axieId);
		uint256 _originGene = (_genes >> 238) & 1;
		if (_originGene != 1)
			return false;
		uint256 _classGenes = (_genes >> 252);
		if (!isCommonClass(_classGenes))
			return false;
		return !isMystic(_genes);
	}

	function isCommonClass(uint256 _classGene) pure internal returns (bool) {
		if (_classGene == 0 || _classGene == 3 || _classGene == 4)
			return true;
		return false;
	}

	function isMystic(uint256 _genes) pure internal returns (bool) {
		uint256 _part;
		uint256 _mysticSelector = 0xc0000000;
		for (uint256 i = 0; i < 6 ; i++) {
			_part = _genes & 0xffffffff;
			if (_part & _mysticSelector == _mysticSelector)
				return true;
			_genes = _genes >> 32;
		}
		return false;
	}

	function wrap(uint256[] calldata _axieIdsToWrap) public notPaused {
		for (uint256 i = 0; i < _axieIdsToWrap.length; i++) {
			require(isValidCommonOrigin(_axieIdsToWrap[i]), "WrappedOrigin: Axie is not an Origin axie.");
			axieIds.push(_axieIdsToWrap[i]);
			AXIE_CORE.safeTransferFrom(msg.sender, address(this), _axieIdsToWrap[i]);
			emit AxieWrapped(_axieIdsToWrap[i]);
		}
		_mint(msg.sender, _axieIdsToWrap.length * (10**decimals));
	}

	function unwrap(uint256 _amount) public notPaused{
		require(!isContract(msg.sender), "WrappedOrigin: Address must not be a contract.");
		unwrapFor(_amount, msg.sender);
	}

	function unwrapFor(uint256 _amount, address _recipient) public notPaused {
		require(!isContract(_recipient), "WrappedOrigin: Recipient must not be a contract.");
		require(_recipient != address(0), "WrappedOrigin: Cannot send to void address.");

		_burn(msg.sender, _amount * (10**decimals));
		uint256 _seed = 0;
		for (uint256 i = 0; i < _amount; i++) {
			_seed = _getSeed(_seed, msg.sender);
			uint256 _index = _seed % axieIds.length;
			uint256 _tokenId = axieIds[_index];

			axieIds[_index] = axieIds[axieIds.length - 1];
			axieIds.pop();
			AXIE_CORE.safeTransferFrom(address(this), _recipient, _tokenId);
			emit AxieUnwrapped(_tokenId);
		}
	}

	function onERC721Received(address _from, uint256 _tokenId, bytes calldata _data) external view returns (bytes4) {
		require(msg.sender == address(AXIE_CORE), "Not Axie NFT");
		return WrappedOrigin.onERC721Received.selector;
	}
}