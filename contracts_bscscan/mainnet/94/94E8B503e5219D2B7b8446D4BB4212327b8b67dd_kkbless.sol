pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT
//https://t.me/karola96
//█▓█▓███████████████████████▓█▓███▓███████████▓███████▓███████████▓████████████████████████
//██████████▓█████████████████▓███████████████████████████▓█████████████████████▓███████████
//█▓█████▓███████████▓█▓█▓███████████████████████████████████████████████████████████████▓█▓
//██████████████████████████████████████████▓▒▒▒░▒▒▒▒▓██████████▓███▓███████████████████▓███
//█▓███▓███████▓███████▓███████████████▓░            ░█████████████████████████▓█████████▓██
//██████████████▓█▓█████████▓███████▓               ▒█████▓ ▓███████▓█████▓█████████████▓███
//█▓██████████████████████████████▒      ▒▓███████▓▓█████▓    ▒████████████████▓█▓█████████▓
//████████████████▓█████████████▓     ▓████████▓░ ██████▓       ▓█████▓█▓█████▓█████████████
//███████▓█████████████████████▒    ███████▒     ▒█████▓         ▒███████████████████████▓██
//████████████████████████████░   ▒██████       ▓█████▓            █████████████▓█▓█████████
//█▓█████████████████████████▒   ▓█████░       ▓█████▓             ░█████▓█▓█████████████▓██
//██████████████████▓███████▓   ▓█████        ▓█████▒     ▓███▒     ▓█████▓█▓███████████▓███
//█▓███████████████▓███▓████    █████        ▓█████▒   ▒███████      ██████████▓███████████▓
//█████████████████████████▓   ▓████░       ▓█████▒  ▒████████       ▓████████████▓█▓███▓███
//█▓███████▓███████▓███████▒   █████       ▓█████  ▒██▒    ▓▓        ░█████████████████████▓
//█████████████████████████░   ████▓      ▓█████▓░██                  ██▓███████████████████
//█▓███▓███████████████████░   ▓███▓     ▓█████████▓▓▓░               █████████████▓███████▓
//██████████▓█▓████████████▒   ░███▓    ▓██████▒  ▓████▓       █▒    ▒██████████████▓███▓███
//█████████████▓███████▓████    ████   ▓█████▒     █████░     ██     ▓███████████████████▓██
//████████▓█████████████████     ███  ▓█████░     ▓█████    ░██      ███████████████▓███████
//█▓█▓█████████████████▓█████     ██▓▒█████▒     ▓█████    ▒█▓      ███████████████████████▓
//███████████████████████████▓     ▒██████▒     ██████    ▓█▒      ▓████▓█▓███████▓█████████
//█▓█████████▓████████████████▓    ▓█████▒     █████▓    ██       ▒████████▓███████▓███████▓
//████▓█████████▓█▓████████████▓  ██████▒     ██████░ ░██▒       ▓██████████████▓███████████
//█████████▓███████████████████████████▒      █████████▓       ░███████▓█████▓██████████████
//██████████████▓███▓█▓█▓█████████████░        ▓████▓░        ▓█████▓█████████▓█████████████
//███████████████████████▓███▓███████▓                     ▒█████████████████▓███▓█████████▓
//████████████████████▓█████████████████▓░             ░▒███████████████▓█▓█████████████████
//█▓█████████████████████████████████████████▓▓▓▓▓▓▓█████████████████████████████████▓█████▓
//██████▓█████████████████████████████████████████████████████████████████████████▓█████████
//█▓███▓████████▓▓███▓▓▓█▓▓▓▓▓███████▓▓████▓▓████▓▓████▓▓▓███▓▓████▓██▓█████▓▓█████████████▓
//████████▓█████  ██▒  ▓█      ▒████   ▓███  ▓█▓  ▒██      ▒█  ▓██  ▓▒ ▒███░  ▒███▓█████████
//█████████▓████  █▒  ███  ███  ███▒ █▒ ███  █▓  ███  ▓███░ ▓█  ██  █░ ▓██▓ ▓▒ ████████████▓
//██████████████     ████      ▓███  █▓  ██     ████  █████  █  █░ ██░ ▓██  ██  ██████▓█████
//██████████████      ███  █░ ░███       ░█   ░  ▓██  ░██▓  ▓██    ██░ ▓█        ████████▓█▓
//████████▓█████  ██▒  ▓█  ██▒  █  █████░ ▓░ ▓██  ▒██▒     ▓███▒  ███░ ▓▒ ▓████▒ ▒██████████
//█▓███▓███████████████████████████████████████████████████████████████████████████████████▓
//████████▓███████████████████████████████████████████████████████████████████████████▓█████
//█▓███████▓███████████████████████████████████████████████████████████████▓█████████▓█████▓

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.6;
//SPDX-License-Identifier: MIT
import "./AA.sol";
import "./Context.sol";

contract kkbless is Context {
    using SafeMath for uint256;

    string public constant name = unicode"✨Krakovia Blessing o/";
    string public constant symbol = unicode"✨KKBLESS";
    string public constant description = unicode"✨A kiss of benediction from Karola96 o/";
    uint8 public constant decimals = 0;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event BlessingCreated(uint amount);
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
	address payable owner_;
    uint256 totalSupply_ = 100000;

   constructor() {
		owner_ = _msgSender();
		balances[owner_] = totalSupply_;
    }  

    modifier onlyOwner() {
        require(owner_ == msg.sender, "owner only");
        _;
    }

    function totalSupply() external view returns (uint256) {
		return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) external view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender],"insufficent tokens");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) external returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address _owner, address _delegate) external view returns (uint) {
        return allowed[_owner][_delegate];
    }

    function transferFrom(address _owner, address _buyer, uint _numTokens) public returns (bool) {
        require(_numTokens <= balances[_owner]);    
        require(_numTokens <= allowed[_owner][msg.sender]);
        balances[_owner] = balances[_owner].sub(_numTokens);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_numTokens);
        balances[_buyer] = balances[_buyer].add(_numTokens);
        emit Transfer(_owner, _buyer, _numTokens);
        return true;
    }
	
    function owner() public view returns (address) {
        return owner_;
    }
    
    function createBlessing(uint amount) external onlyOwner {
        require(amount > 0,"need at least 1");
        totalSupply_ = totalSupply_.add(amount);
        balances[owner_] = balances[owner_].add(amount);
        emit BlessingCreated(amount);
    }
    
    function sendBlessings(address[] calldata blessedAddresses) external onlyOwner {
        require(blessedAddresses.length > 0,"Addresses list empty");
        for (uint i = 0;i < blessedAddresses.length; i++) {
            transferFrom(msg.sender, blessedAddresses[i], 1);
        }
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

