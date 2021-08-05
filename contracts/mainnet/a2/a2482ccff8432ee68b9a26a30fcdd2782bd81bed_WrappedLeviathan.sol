/**
 *Submitted for verification at Etherscan.io on 2020-11-20
*/

pragma solidity ^0.6.12;

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

	constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
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

contract Ownable {
	address public owner;

	constructor () public {
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
	
	constructor () public {
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

interface ILeviathanClaim {
    function release(uint256 payID) external;
    function totalReleased() external view returns (uint256);
    function released(uint256 payID) external view returns (uint256);
}

contract WrappedLeviathan is ERC20("Wrapped Leviathan", "WLEV", 18), Pausable {
	using SafeMath for uint256;

	IERC721 public constant LEVIATHAN = IERC721(0xeE52c053e091e8382902E7788Ac27f19bBdFeeDc);
    address private _leviathanClaim = 0xb4345a489e4aF3a33F81df5FB26E88fFeCEd6489;
    address private _surf = 0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c;

	uint256[] public leviathans;

	event LeviathanWrapped(uint256 leviathanID);
	event LeviathanUnwrapped(uint256 leviathanID);

    function _getSeed(uint256 _seed, address _sender) internal view returns (uint256) {
		if (_seed == 0)
			return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _sender)));
		else
			return uint256(keccak256(abi.encodePacked(_seed)));
	}

    function checkClaim(uint ID)
    public view returns (uint256) {
        uint256 totalReleased = ILeviathanClaim(_leviathanClaim).totalReleased();
        uint256 released = ILeviathanClaim(_leviathanClaim).released(ID);
        uint256 totalReceived = IERC20(_surf).balanceOf(_leviathanClaim).add(totalReleased);
        return totalReceived.mul(1).div(333).sub(released);
    }

	function wrap(uint256[] calldata _leviathansToWrap) public notPaused {
		for (uint256 i = 0; i < _leviathansToWrap.length; i++) {
			require(_leviathansToWrap[i] >= 1 && _leviathansToWrap[i] <= 333, "WrappedLeviathan: Invalid ID.");
			leviathans.push(_leviathansToWrap[i]);
			LEVIATHAN.transferFrom(msg.sender, address(this), _leviathansToWrap[i]);

            if(checkClaim(_leviathansToWrap[i]) > 0 )
                ILeviathanClaim(_leviathanClaim).release(_leviathansToWrap[i]);
            
			emit LeviathanWrapped(_leviathansToWrap[i]);
		}
		_mint(msg.sender, _leviathansToWrap.length * (10**uint256(decimals)));

        uint surfBalance = IERC20(_surf).balanceOf(address(this));
        if(surfBalance > 0)
            IERC20(_surf).transfer(_leviathanClaim, surfBalance);
	}

	function unwrap(uint256 _amount) public notPaused{
		unwrapFor(_amount, msg.sender);
	}

	function unwrapFor(uint256 _amount, address _recipient) public notPaused {
		require(_recipient != address(0), "WrappedLeviathan: Cannot send to void address.");

		_burn(msg.sender, _amount * (10**uint256(decimals)));
		uint256 _seed = 0;
		for (uint256 i = 0; i < _amount; i++) {
			_seed = _getSeed(_seed, msg.sender);
			uint256 _index = _seed % leviathans.length;
			uint256 _tokenId = leviathans[_index];

			leviathans[_index] = leviathans[leviathans.length - 1];
			leviathans.pop();

            if(checkClaim(_tokenId) > 0)
                ILeviathanClaim(_leviathanClaim).release(_tokenId);

			LEVIATHAN.transferFrom(address(this), _recipient, _tokenId);

			emit LeviathanUnwrapped(_tokenId);
		}

        uint surfBalance = IERC20(_surf).balanceOf(address(this));
        if(surfBalance > 0)
            IERC20(_surf).transfer(_leviathanClaim, surfBalance);
	}

	function onERC721Received(address _from, uint256 _tokenId, bytes calldata _data) external view returns (bytes4) {
		require(msg.sender == address(LEVIATHAN), "Not Leviathan NFT");
		return WrappedLeviathan.onERC721Received.selector;
	}
}