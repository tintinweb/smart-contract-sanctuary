pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract MultiOwner {
	event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping (address => bool) public isOwner;
	address[] owners;
	
    //@抛出::如果是空地址
	modifier validAddress(address _address) {
        assert(0x0 != _address);
        _;
    }
	
    //@抛出::如果不是所有者调用
    modifier onlyOwner {
		require(isOwner[msg.sender]);
        _;
    }
	
	//@抛出::所有者不存在
	modifier ownerDoesNotExist(address owner) {
		require(!isOwner[owner]);
        _;
    }

	//@抛出::所有者存在
    modifier ownerExists(address owner) {
		require(isOwner[owner]);
        _;
    }
	
    //@返回::所有者
    constructor() public{
		isOwner[msg.sender] = true;
        owners.push(msg.sender);
    }

	//@返回::所有者数量
	function numberOwners() public constant returns (uint256 NumberOwners){
	    NumberOwners = owners.length;
	}
	
	//添加所有者
	function addOwner(address owner) onlyOwner validAddress(owner) ownerDoesNotExist(owner) external{
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAdded(owner);
    }
	
	//移除所有者
	function removeOwner(address owner) onlyOwner ownerExists(owner) external{
		require(owners.length > 1);
        isOwner[owner] = false;
        for (uint256 i=0; i<owners.length - 1; i++){
            if (owners[i] == owner) {
				owners[i] = owners[owners.length - 1];
                break;
            }
		}
		owners.length -= 1;
        emit OwnerRemoved(owner);
    }
	
	//@清除合约只限所有者
	function kill() public onlyOwner(){
		selfdestruct(msg.sender);
    }
}

//@标题:: ERC20 端口
//@开发参考:: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    function balanceOf(address _who) public view returns (uint256);
	function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
	function approve(address _spender, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AsiaPacific is ERC20, MultiOwner{
	using SafeMath for uint256;
	
	event SingleTransact(address owner, uint value, address to, bytes data);
	event Burn(address indexed _account, uint256 _value);
	event FrozenFunds(address target, bool frozen);
	
	string public name = "Asia Pacific Cipher Chain";
	string public symbol = "APCC";
	uint8 public decimals = 8;
	uint256 public decimalFactor = 10 ** uint256(decimals);
	uint256 public totalSupply = 2000000000 * decimalFactor;

	mapping(address => uint256) private balances;
	mapping (address => mapping (address => uint256)) private allowed;
	mapping(address => bool) public frozenAccount;
	
	//开始设置
	constructor() MultiOwner() public {
		balances[msg.sender] = totalSupply;                    
    }
	
	//@抛出::不接收ETH
	function() public payable{
        revert();
    }
	
	//@所有者可以使用ETH
	function execute(address _to, uint _value, bytes _data) external onlyOwner {
		emit SingleTransact(msg.sender, _value, _to, _data);
		require(_to.call.value(_value)(_data));
    }

	//外部检查余额
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
	
	//外部检查宽限
	function allowance(address _owner, address _spender) public view returns (uint256){
		return allowed[_owner][_spender];
	}
  
	//内部转移，只能由本合同调用
	function _transfer(address _from, address _to, uint256 _value) validAddress(_from) validAddress(_to) internal{
		require (!frozenAccount[_from]); 						// Check if sender is frozen
        require (balances[_from] >= _value);                	// Check if the sender has enough
        require (balances[_to] + _value >= balances[_to]); 	// Check for overflows
                            
        balances[_from] = balances[_from].sub(_value);        // Subtract from the sender
        balances[_to] = balances[_to].add(_value);            // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
	
	//转移令牌到指定的地址
	function transfer(address _to, uint256 _value) validAddress(_to) public returns (bool) {
		_transfer(msg.sender, _to, _value);
		return true;
	}
	
	//批准指定的地址代表msg.sender花费指定数量的令牌
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
  
	//将令牌从一个地址转移到另一个地址
	function transferFrom(address _from, address _to, uint256 _value) validAddress(_from) validAddress(_to) public returns (bool success) {
		require(_value <= allowed[_from][msg.sender]);
		_transfer(_from, _to, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		return true;
    }

	// ------------------------------------------------------------------------
    // 所有者可以转出任何意外发送的ERC20令牌
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }
	
	//回收指定地址的令牌
	function burn(address _account, uint256 _value) validAddress(_account) onlyOwner internal{
		require(balances[_account] >= _value);
		balances[_account] = balances[_account].sub(_value);
		balances[msg.sender] = balances[msg.sender].add(_value);
		emit Burn(_account, _value);
	}

	//冻结帐户
	function freezeAccount(address target, bool freeze) onlyOwner internal {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

	//检查签名和数据一致回返回地址
	//https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/master/contracts/BTTSTokenFactory.sol#L365-L395
	function EcRecover(bytes32 hash, bytes _signature) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) return address(0);
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
		
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }
	
	//加密数据
	function getTransferHash(address _contract, address _to, uint _value, uint _fee, uint _nonce) public pure returns(bytes32 txHash){
        txHash = keccak256(abi.encodePacked(_contract, _to, _value, _fee, _nonce));
    }

	//签名和发送
	function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) validAddress(_to) public returns (bool){
        bytes32 hashedTx = getTransferHash(address(this), _to, _value, _fee, _nonce);

        address _from = EcRecover(hashedTx, _signature);
		require(0x0 != _from);
		require (balances[_from] >= _value.add(_fee));
		
        balances[_from] = balances[_from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		
		if(_fee > 0){
			balances[msg.sender] = balances[msg.sender].add(_fee);
			emit Transfer(_from, msg.sender, _fee);
		}
        return true;
    }

	//检查是不是合约地址
	function isContract(address addr) public view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}
}