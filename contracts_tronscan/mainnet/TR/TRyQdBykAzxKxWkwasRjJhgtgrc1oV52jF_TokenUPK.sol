//SourceUnit: UPK.sol


pragma solidity >=0.5.12;

contract TokenUPK {
    string public name = "UPK token";
    string public symbol = "UPK";
    uint8 public constant decimals = 18;  
    uint256 public totalSupply;
	
	uint256 private constant INITIAL_SUPPLY = 50000000 * (10 ** uint256(decimals));
	uint256 private constant MIN_SUPPLY = 25000000 * (10 ** uint256(decimals));

    mapping (address => uint256) public balanceOf;  // 
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => address) public referrers;
	
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
	
	event Approval(address indexed owner, address indexed spender, uint256 value);

	address public feeTo;

	constructor(address _receiver, address _feeTo) public {
		require(_receiver != address(0), "_receiver can't be zero");
		require(_feeTo != address(0), "_feeTo can't be zero");
		totalSupply = INITIAL_SUPPLY;
        balanceOf[_receiver] = totalSupply;
        feeTo = _feeTo;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint refFee = _value / 10;   // 10%
        uint burnFee = _value / 40;  // 2.5%
        balanceOf[_from] -= _value;

        if(referrers[_from] != address(0)) {
        	balanceOf[referrers[_from]] += refFee;
    	} else {
    		balanceOf[feeTo] += refFee;
    	}

    	if (totalSupply >= burnFee + MIN_SUPPLY) {
    		balanceOf[_to] += (_value - refFee - burnFee);
    		totalSupply -= burnFee;
		} else if (totalSupply > MIN_SUPPLY) {
			burnFee = totalSupply - MIN_SUPPLY;
			balanceOf[_to] += (_value - refFee - burnFee);
    		totalSupply -= burnFee;
		} else {
			balanceOf[_to] += (_value - refFee);
		}

    	if(referrers[_to] == address(0)) {
    		referrers[_to] = _from;
    	}

        emit Transfer(_from, _to, _value);
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
}