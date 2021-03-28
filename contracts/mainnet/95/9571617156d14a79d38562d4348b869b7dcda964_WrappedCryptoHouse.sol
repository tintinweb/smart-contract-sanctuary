/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity 0.7.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ICryptoHouse {
	function transfer(address to, uint houseIndex) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
}

contract WrappedCryptoHouse is IERC20{

    address author;
    uint256 _totalSupply;
    
	ICryptoHouse public token;

	string constant public name = "WrappedCryptoHouse";
	string constant public symbol = "WHOUSE";
	uint8 constant public decimals = 6;
	uint256 constant private token_precision = 1e6;
	uint256 constant private initial_supply = 0;
	uint256 constant private wrap_amount =  100 * token_precision;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    event WrapToken(uint256 indexed houseIndex, address indexed fromAddress);
    event UnWrapToken(uint256 indexed houseIndex, address indexed toAddress);
    
    uint[] public nftTokens;
    
    function getAllNFTTokens() public view returns (uint[] memory _allNftTokens) {
        uint[] memory allNftTokens = new uint[](nftTokens.length);
         
        for(uint i = 0; i < nftTokens.length; i++) {
            allNftTokens[i] = nftTokens[i];
        }
        
        return (allNftTokens);
    }

	function refundWrongSendCryptoHouses(uint houseIndex) public{
		require(msg.sender == author);
		token.transfer(author, houseIndex);
	}

	function wrapCryptoHouse(uint houseIndex) public {
	    token.transferFrom(msg.sender, address(this), houseIndex);
	    
		_totalSupply += wrap_amount;
		_balances[msg.sender] += wrap_amount;
		
		nftTokens.push(houseIndex);
		
		emit WrapToken(houseIndex, msg.sender);
		emit Transfer(address(0), msg.sender, wrap_amount);
	}

	function unWrapCryptoHouses() public{
	    require(_balances[msg.sender] >= wrap_amount);
	    
		_balances[msg.sender] -= wrap_amount;
		_totalSupply -= wrap_amount;
        
        uint houseIndex = swapAndDeleteElement(randomElement());
		token.transfer(msg.sender, houseIndex);
		
		emit UnWrapToken(houseIndex, msg.sender);
		emit Transfer(msg.sender, address(0), wrap_amount);
	}

	function randomElement()  private view returns(uint){
		return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nftTokens))) % nftTokens.length;
	}

	function swapAndDeleteElement(uint index) private returns(uint _element){
		uint element = nftTokens[index];
		nftTokens[index] = nftTokens[nftTokens.length - 1];
		delete nftTokens[nftTokens.length - 1];
	    nftTokens.pop();
		return element;
	}
	
	constructor() {
		token = ICryptoHouse(0x3d184e68Cf7D1aCFD78A8bDf656EAc20b8352988);
		author = msg.sender;
		_totalSupply = initial_supply;
	}

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue);
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0));
        require(recipient != address(0));

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}