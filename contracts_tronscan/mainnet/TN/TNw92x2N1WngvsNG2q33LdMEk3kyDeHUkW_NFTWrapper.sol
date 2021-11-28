//SourceUnit: Wrapper.sol

pragma solidity >=0.5.1;

interface IToken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface INFT {
	function mint(address _to, uint256 _tokenId) external;
}

contract TokenERC20 {
    string public name = "BLESSING";
    string public symbol = "BLESS";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
	
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
	
	event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
		return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function mint(address _to, uint256 _value) internal returns (bool success) {
    	balanceOf[_to] += _value;
    	totalSupply += _value;
    	return true;
    }
}

contract NFTWrapper is TokenERC20{
	struct Pool{
		uint8 exists;
		uint256 lastTime;
		uint256 count;
	}

	struct User{
		uint8 exists;
		address referrer;
		uint8 downIndex;
		uint256 nftIndex;
		mapping(uint8 => address) downLines;
		mapping(address => Pool) pools;
		mapping(uint256 => uint256) nfts;
	}

	struct ErcToken{
		uint8 flag;      //0-close,1-usdt,2-other
		uint256 price;
	}

	uint256 public oneDay = 86400;
	uint256 public showDownCount = 6;
	uint256 public blessPrice = 300 * (10 ** uint256(decimals));
	uint256 public giftPrice = 100 * (10 ** uint256(decimals));

	mapping(address => User) public users;
	mapping(address => ErcToken) public tokens;
	address public dev;
	address public nft;
	uint256 public startTime;
	address public receiver;

	uint256 nftIndex;

	constructor(address _dev, address _nft, address _receiver, uint256 _startTime) public {
		require(_dev != address(0), "dev can't be zero");
		require(_nft != address(0), "nft can't be zero");
		require(_receiver != address(0), "receiver can't be zero");
		require(_startTime > now, "startTime must be greater than now");
		dev = _dev;
		nft = _nft;
		receiver = _receiver;
		startTime = _startTime;

		nftIndex = 15000;
	}

	modifier onlyDeveloper() {
	    require(msg.sender == dev);
	    _;
	}

	function setNft(address _nft) onlyDeveloper external {
		require(_nft != address(0), "nft can't be zero");
		nft = _nft;
	}

	function setReceiver(address _receiver) onlyDeveloper external {
		require(_receiver != address(0), "receiver can't be zero");
		receiver = _receiver;
	}

	function setDev(address _dev) onlyDeveloper external {
		require(_dev != address(0), "dev can't be zero");
		dev = _dev;
	}

	function setPrice(address _token, uint256 _price, uint8 _flag) onlyDeveloper external {
		require(_token != address(0), "token can't be zero");
		require(_price > 0, "price must greater than 0");
		if(tokens[_token].price > 0) {
			tokens[_token].flag = _flag;
			tokens[_token].price = _price;
		} else {
			ErcToken memory token = ErcToken({
				flag: _flag,
				price: _price
			});
			tokens[_token] = token;
		}
	}

	function bindRefer(address _refer) internal {
		users[msg.sender].referrer = _refer;
		if(users[_refer].exists > 0){
			if(users[_refer].downIndex < showDownCount) {
				users[_refer].downIndex++;
			} else {
				users[_refer].downIndex = 1;
			}
			users[_refer].downLines[users[_refer].downIndex] = msg.sender;
		}
	}

	function checkBuy(address _token) internal returns(bool) {
		uint256 _days = (now - startTime) / oneDay;
		if(startTime + _days * oneDay > users[msg.sender].pools[_token].lastTime) {
			users[msg.sender].pools[_token].lastTime = now;
			users[msg.sender].pools[_token].count = 1;
		} else {
			if(tokens[_token].flag == 2 && users[msg.sender].pools[_token].count >= 5) {
				if(balanceOf[msg.sender] < blessPrice) {
					return false;
				}
				super.burn(blessPrice);
			} 
			users[msg.sender].pools[_token].lastTime = now;
			users[msg.sender].pools[_token].count++;
			if(users[msg.sender].pools[_token].count == 5 && balanceOf[msg.sender] < blessPrice) {
				super.mint(msg.sender, giftPrice);
			}
		}
		return true;
	}

	function bytesToUint(bytes32 b) public view returns (uint256){
        uint256 number;
        for(uint i = 0; i < b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return  number;
    }

	function doBuy(address _token) internal {
		require(IToken(_token).transferFrom(msg.sender, receiver, tokens[_token].price), "transferFrom must executed");
		nftIndex++;
		uint256 tokenId = bytesToUint(keccak256(abi.encode(nftIndex)));
		INFT(nft).mint(msg.sender, tokenId);
		users[msg.sender].nfts[users[msg.sender].nftIndex] = tokenId;
		users[msg.sender].nftIndex++;
	}

	function buyNFT(address _token, address _refer) external {
		require(tokens[_token].price > 0, "token must exists");
		require(tokens[_token].flag > 0, "can't buy in closed");
		if(users[msg.sender].exists == 0) {
			User memory user = User({
				exists: 1,
				referrer: address(0),
				downIndex: 0,
				nftIndex: 0
			});
			users[msg.sender] = user;
		}
		if(users[msg.sender].referrer == address(0) && _refer != address(0)) {
			bindRefer(_refer);
		}
		if(users[msg.sender].pools[_token].exists == 0) {
			Pool memory pool = Pool({
				exists: 1,
				lastTime: 0,
				count: 0
			});
			users[msg.sender].pools[_token] = pool;
		}
		require(checkBuy(_token), "check buy failed");
		doBuy(_token);
	}

	function nftInfo(address addr, uint256 i) external view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
		if(users[addr].exists == 0) {
			return (0, 0, 0, 0, 0, 0);
		} else {
			return (users[addr].nfts[i], users[addr].nfts[i + 1], users[addr].nfts[i + 2], 
				users[addr].nfts[i + 3], users[addr].nfts[i + 4], users[addr].nfts[i + 5]);
		}
	}

	function poolInfo(address addr, address _token) external view returns(uint256, uint256, uint256) {
		return (users[addr].pools[_token].count, users[addr].pools[_token].lastTime, balanceOf[addr]);
	}

	function referInfo(address addr) external view returns(address, address, address, address, address, address) {
		return (users[addr].downLines[0], users[addr].downLines[1], users[addr].downLines[2], users[addr].downLines[3], users[addr].downLines[4], users[addr].downLines[5]);
	}
}