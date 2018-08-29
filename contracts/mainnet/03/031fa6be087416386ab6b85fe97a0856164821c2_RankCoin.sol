pragma solidity ^0.4.24;

interface ERC20 {
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	function name() external view returns (string);
	function symbol() external view returns (string);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address _owner) external view returns (uint256 balance);
	function transfer(address _to, uint256 _value) external payable returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) external payable returns (bool success);
	function approve(address _spender, uint256 _value) external payable returns (bool success);
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// 숫자 계산 시 오버플로우 문제를 방지하기 위한 라이브러리
library SafeMath {
	
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	function sub(uint256 a, uint256 b) pure internal returns (uint256 c) {
		assert(b <= a);
		return a - b;
	}
	
	function mul(uint256 a, uint256 b) pure internal returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) pure internal returns (uint256 c) {
		return a / b;
	}
}

contract RankCoin is ERC20, ERC165 {
	using SafeMath for uint256;
	
	event ChangeName(address indexed user, string name);
	event ChangeMessage(address indexed user, string message);
	
	// 토큰 정보
	string constant public NAME = "RankCoin";
	string constant public SYMBOL = "RC";
	uint8 constant public DECIMALS = 18;
	uint256 constant public TOTAL_SUPPLY = 100000000000 * (10 ** uint256(DECIMALS));
	
	address public author;
	
	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowed;
	
	// 사용자들 주소
	address[] public users;
	mapping(address => string) public names;
	mapping(address => string) public messages;
	
	function getUserCount() view public returns (uint256) {
		return users.length;
	}
	
	// 유저가 이미 존재하는지
	mapping(address => bool) internal userToIsExisted;
	
	constructor() public {
		
		author = msg.sender;
		
		balances[author] = TOTAL_SUPPLY;
		
		emit Transfer(0x0, author, TOTAL_SUPPLY);
	}
	
	// 주소를 잘못 사용하는 것인지 체크
	function checkAddressMisused(address target) internal view returns (bool) {
		return
			target == address(0) ||
			target == address(this);
	}
	
	//ERC20: 토큰의 이름 반환
	function name() external view returns (string) {
		return NAME;
	}
	
	//ERC20: 토큰의 심볼 반환
	function symbol() external view returns (string) {
		return SYMBOL;
	}
	
	//ERC20: 토큰의 소수점 반환
	function decimals() external view returns (uint8) {
		return DECIMALS;
	}
	
	//ERC20: 전체 토큰 수 반환
	function totalSupply() external view returns (uint256) {
		return TOTAL_SUPPLY;
	}
	
	//ERC20: 특정 유저의 토큰 수를 반환합니다.
	function balanceOf(address user) external view returns (uint256 balance) {
		return balances[user];
	}
	
	//ERC20: 특정 유저에게 토큰을 전송합니다.
	function transfer(address to, uint256 amount) external payable returns (bool success) {
		
		// 주소 오용 차단
		require(checkAddressMisused(to) != true);
		
		require(amount <= balances[msg.sender]);
		
		balances[msg.sender] = balances[msg.sender].sub(amount);
		balances[to] = balances[to].add(amount);
		
		// 유저 주소 등록
		if (to != author && userToIsExisted[to] != true) {
			users.push(to);
			userToIsExisted[to] = true;
		}
		
		emit Transfer(msg.sender, to, amount);
		
		return true;
	}
	
	//ERC20: spender에 amount만큼의 토큰을 보낼 권리를 부여합니다.
	function approve(address spender, uint256 amount) external payable returns (bool success) {
		
		allowed[msg.sender][spender] = amount;
		
		emit Approval(msg.sender, spender, amount);
		
		return true;
	}
	
	//ERC20: spender에 인출을 허락한 토큰의 양을 반환합니다.
	function allowance(address user, address spender) external view returns (uint256 remaining) {
		return allowed[user][spender];
	}
	
	//ERC20: 허락된 spender가 from으로부터 amount만큼의 토큰을 to에게 전송합니다.
	function transferFrom(address from, address to, uint256 amount) external payable returns (bool success) {
		
		// 주소 오용 차단
		require(checkAddressMisused(to) != true);
		
		require(amount <= balances[from]);
		require(amount <= allowed[from][msg.sender]);
		
		balances[from] = balances[from].sub(amount);
		balances[to] = balances[to].add(amount);
		
		// 유저 주소 등록
		if (to != author && userToIsExisted[to] != true) {
			users.push(to);
			userToIsExisted[to] = true;
		}
		
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
		
		emit Transfer(from, to, amount);
		
		return true;
	}
	
	// 토큰을 많이 가진 순서대로 유저 목록을 가져옵니다.
	function getUsersByBalance() view public returns (address[]) {
		address[] memory _users = new address[](users.length);
		
		for (uint256 i = 0; i < users.length; i += 1) {
			
			uint256 balance = balances[users[i]];
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (balances[_users[j - 1]] < balance) {
					_users[j] = _users[j - 1];
				} else {
					break;
				}
			}
			
			_users[j] = users[i];
		}
		
		return _users;
	}
	
	// 특정 유저의 랭킹을 가져옵니다.
	function getRank(address user) view public returns (uint256) {
		
		uint256 rank = 1;
		uint256 balance = balances[user];
		
		for (uint256 i = 0; i < users.length; i += 1) {
			if (balances[users[i]] > balance) {
				rank += 1;
			}
		}
		
		return rank;
	}
	
	// 이름을 지정합니다.
	function setName(string _name) public {
		
		names[msg.sender] = _name;
		
		emit ChangeName(msg.sender, _name);
	}
	
	// 메시지를 지정합니다.
	function setMessage(string message) public {
		
		messages[msg.sender] = message;
		
		emit ChangeMessage(msg.sender, message);
	}
	
	//ERC165: 주어진 인터페이스가 구현되어 있는지 확인합니다.
	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		return
			// ERC165
			interfaceID == this.supportsInterface.selector ||
			// ERC20
			interfaceID == 0x942e8b22 ||
			interfaceID == 0x36372b07;
	}
}