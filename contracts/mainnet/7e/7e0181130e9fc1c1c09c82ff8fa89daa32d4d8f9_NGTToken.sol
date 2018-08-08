pragma solidity ^0.4.23;

contract owned {
    address public owner;

    constructor() public {
        owner = 0x318d9e2fFEC1A7Cd217F77f799deBAd1e9064556;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

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

contract NGTToken is owned {
    using SafeMath for uint256;

    string public constant name = "NextGenToken";
    string public constant symbol = "NGT";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    uint256 public constant initialSupply = 2200000000 * (10 ** uint256(decimals));

    address public fundingReserve;
    address public bountyReserve;
    address public teamReserve;
    address public advisorReserve;

    uint256 fundingToken;
    uint256 bountyToken;
    uint256 teamToken;
    uint256 advisorToken;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Burn(address indexed _from,uint256 _value);
    event FrozenFunds(address _account, bool _frozen);
    event Transfer(address indexed _from,address indexed _to,uint256 _value);

    constructor() public {
        totalSupply = initialSupply;
        balanceOf[owner] = initialSupply;

        bountyTransfers();
    }

    function bountyTransfers() internal {
        fundingReserve = 0xb0F1D6798d943b9B58E3186390eeE71A57211678;
        bountyReserve = 0x45273112b7C14727D6080b5337300a81AC5c3255;
        teamReserve = 0x53ec41c8356bD4AEb9Fde2829d57Ee2370DA5Dd7;
        advisorReserve = 0x28E1E401A0C7b09bfe6C2220f04236037Fd75454;

        fundingToken = ( totalSupply * 25 ) / 100;
        teamToken = ( totalSupply * 12 ) / 100;
        bountyToken = ( totalSupply * 15 ) / 1000;
        advisorToken = ( totalSupply * 15 ) / 1000;

        balanceOf[msg.sender] = totalSupply - fundingToken - teamToken - bountyToken - advisorToken;
        balanceOf[teamReserve] = teamToken;
        balanceOf[bountyReserve] = bountyToken;
        balanceOf[fundingReserve] = fundingToken;
        balanceOf[advisorReserve] = advisorToken;

        Transfer(msg.sender, fundingReserve, fundingToken);
        Transfer(msg.sender, bountyReserve, bountyToken);
        Transfer(msg.sender, teamReserve, teamToken);
        Transfer(msg.sender, advisorReserve, advisorToken);
    }

    function _transfer(address _from,address _to,uint256 _value) internal {
        require(balanceOf[_from] >= _value);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to,uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public onlyOwner returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function freezeAccount(address _account, bool _frozen) public onlyOwner {
        frozenAccount[_account] = _frozen;
        emit FrozenFunds(_account, _frozen);
    }

    function burnTokens(uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender,_value);
        return true;
    }

    function newTokens(address _owner, uint256 _value) public onlyOwner {
        balanceOf[_owner] = balanceOf[_owner].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(0, this, _value);
        emit Transfer(this, _owner, _value);
    }

    function escrowAmount(address _account, uint256 _value) public onlyOwner {
        _transfer(msg.sender, _account, _value);
        freezeAccount(_account, true);
    }

    function () public {
        revert();
    }

}