/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

/**
               𝘿𝙊𝙉𝙏 𝙋𝘼𝙉𝙄𝘾,

     𝙎𝙉𝘼𝙋𝙎𝙃𝙊𝙏 𝙄𝙎 𝙏𝘼𝙆𝙀𝙉

𝘼𝙉𝘿 𝙔𝙊𝙐 WILL BE  𝙒�                                                                                                                                                                           
                                                      dddddddd                                                                                                      dddddddd
                   iiii                               d::::::d                                                                                                      d::::::d
                  i::::i                              d::::::d                                                                                                      d::::::d
                   iiii                               d::::::d                                                                                                      d::::::d
                                                      d:::::d                                                                                                       d:::::d 
  aaaaaaaaaaaaa  iiiiiirrrrr   rrrrrrrrr      ddddddddd:::::rrrrr   rrrrrrrrr     ooooooooooo  ppppp   ppppppppp  ppppp   ppppppppp      eeeeeeeeeeee       ddddddddd:::::d 
  a::::::::::::a i:::::r::::rrr:::::::::r   dd::::::::::::::r::::rrr:::::::::r  oo:::::::::::oop::::ppp:::::::::p p::::ppp:::::::::p   ee::::::::::::ee   dd::::::::::::::d 
  aaaaaaaaa:::::a i::::r:::::::::::::::::r d::::::::::::::::r:::::::::::::::::ro:::::::::::::::p:::::::::::::::::pp:::::::::::::::::p e::::::eeeee:::::eed::::::::::::::::d 
           a::::a i::::rr::::::rrrrr::::::d:::::::ddddd:::::rr::::::rrrrr::::::o:::::ooooo:::::pp::::::ppppp::::::pp::::::ppppp::::::e::::::e     e:::::d:::::::ddddd:::::d 
    aaaaaaa:::::a i::::ir:::::r     r:::::d::::::d    d:::::dr:::::r     r:::::o::::o     o::::op:::::p     p:::::pp:::::p     p:::::e:::::::eeeee::::::d::::::d    d:::::d 
  aa::::::::::::a i::::ir:::::r     rrrrrrd:::::d     d:::::dr:::::r     rrrrrro::::o     o::::op:::::p     p:::::pp:::::p     p:::::e:::::::::::::::::ed:::::d     d:::::d 
 a::::aaaa::::::a i::::ir:::::r           d:::::d     d:::::dr:::::r           o::::o     o::::op:::::p     p:::::pp:::::p     p:::::e::::::eeeeeeeeeee d:::::d     d:::::d 
a::::a    a:::::a i::::ir:::::r           d:::::d     d:::::dr:::::r           o::::o     o::::op:::::p    p::::::pp:::::p    p::::::e:::::::e          d:::::d     d:::::d 
a::::a    a:::::ai::::::r:::::r           d::::::ddddd::::::dr:::::r           o:::::ooooo:::::op:::::ppppp:::::::pp:::::ppppp:::::::e::::::::e         d::::::ddddd::::::dd
a:::::aaaa::::::ai::::::r:::::r            d:::::::::::::::::r:::::r           o:::::::::::::::op::::::::::::::::p p::::::::::::::::p e::::::::eeeeeeee  d:::::::::::::::::d
 a::::::::::aa:::i::::::r:::::r             d:::::::::ddd::::r:::::r            oo:::::::::::oo p::::::::::::::pp  p::::::::::::::pp   ee:::::::::::::e   d:::::::::ddd::::d
  aaaaaaaaaa  aaaiiiiiiirrrrrrr              ddddddddd   ddddrrrrrrr              ooooooooooo   p::::::pppppppp    p::::::pppppppp       eeeeeeeeeeeeee    ddddddddd   ddddd
                                                                                                p:::::p            p:::::p                                                  
                                                                                                p:::::p            p:::::p                                                  
                                                                                               p:::::::p          p:::::::p                                                 
                                                                                               p:::::::p          p:::::::p                                                 
                                                                                               p:::::::p          p:::::::p                                                 
                                                                                               ppppppppp          ppppppppp                                                 
*/        


pragma solidity ^0.5.13;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

contract sodiumbicarb {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private INITIAL_SUPPLY = 1e17; // 1B
	uint256 constant private BURN_RATE = 2; // 2% per tx
	uint256 constant private SUPPLY_FLOOR = 1; // 1% of 1M = 10K

	string constant public name = "Cardboard";
	string constant public symbol = "BOX";
	uint8 constant public decimals = 8;

	struct User {
		bool whitelisted;
		uint256 balance;
		uint256 frozen;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalFrozen;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Whitelist(address indexed user, bool status);
	event Burn(uint256 tokens);


	constructor() public {
		info.admin = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		whitelist(msg.sender, true);
	}


	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		uint256 _burnedAmount = _tokens;
		if (info.totalFrozen > 0) {
			_burnedAmount /= 2;
			info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
			emit Transfer(msg.sender, address(this), _burnedAmount);
		}
		info.totalSupply -= _burnedAmount;
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		emit Burn(_burnedAmount);
	}

	function distribute(uint256 _tokens) external {
		require(info.totalFrozen > 0);
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		info.scaledPayoutPerToken += _tokens * FLOAT_SCALAR / info.totalFrozen;
		emit Transfer(msg.sender, address(this), _tokens);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		uint256 _transferred = _transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _transferred, _data));
		}
		return true;
	}

	function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}

	function whitelist(address _user, bool _status) public {
		require(msg.sender == info.admin);
		info.users[_user].whitelisted = _status;
		emit Whitelist(_user, _status);
	}


	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalFrozen() public view returns (uint256) {
		return info.totalFrozen;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - frozenOf(_user);
	}

	function frozenOf(address _user) public view returns (uint256) {
		return info.users[_user].frozen;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken * info.users[_user].frozen) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function isWhitelisted(address _user) public view returns (bool) {
		return info.users[_user].whitelisted;
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensFrozen, uint256 userBalance, uint256 userFrozen, uint256 userDividends) {
		return (totalSupply(), totalFrozen(), balanceOf(_user), frozenOf(_user), dividendsOf(_user));
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _burnedAmount = _tokens * BURN_RATE / 100;
		if (totalSupply() - _burnedAmount < INITIAL_SUPPLY * SUPPLY_FLOOR / 100 || isWhitelisted(_from)) {
			_burnedAmount = 0;
		}
		uint256 _transferred = _tokens - _burnedAmount;
		info.users[_to].balance += _transferred;
		emit Transfer(_from, _to, _transferred);
		if (_burnedAmount > 0) {
			if (info.totalFrozen > 0) {
				_burnedAmount /= 2;
				info.scaledPayoutPerToken += _burnedAmount * FLOAT_SCALAR / info.totalFrozen;
				emit Transfer(_from, address(this), _burnedAmount);
			}
			info.totalSupply -= _burnedAmount;
			emit Transfer(_from, address(0x0), _burnedAmount);
			emit Burn(_burnedAmount);
		}
		return _transferred;
	}
}