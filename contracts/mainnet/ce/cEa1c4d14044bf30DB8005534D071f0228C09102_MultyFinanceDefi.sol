// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
	function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface OLDIERC20 {
    function transfer(address recipient, uint amount) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

interface Mtoken{
	function calcPoolValue() external view returns (uint);
}

interface IUniswapV2Pair {
	function getReserves() external view returns (uint reserve0, uint reserve1, uint blockTimestampLast);
}

interface AggregatorInterface {
	function latestAnswer() external view returns (uint);
}


library Address {
    function isContract(address account) internal view returns (bool) {
		uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

abstract contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function owner() public view returns (address payable) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
	
	function inCaseWrongTokenTransfer(address _TokenAddr) onlyOwner external {
		require(_TokenAddr != address(this), "MultiFinance: invalid address");
        uint qty = IERC20(_TokenAddr).balanceOf(address(this));
        IERC20(_TokenAddr).transfer(_msgSender(), qty);
    }
	
	function inCaseWrongTokenTransfer(address _tokenAddr,uint _type) onlyOwner external {
		require(_tokenAddr != address(this), "MFI: invalid address");
        uint qty = IERC20(_tokenAddr).balanceOf(address(this));
		if(_type == 1)
			IERC20(_tokenAddr).transfer(_msgSender(), qty);
		else
			OLDIERC20(_tokenAddr).transfer(_msgSender(), qty);
    }
	
    function inCaseWrongEthTransfer() onlyOwner external{
        (bool result, ) = _msgSender().call{value:address(this).balance}("");
        require(result, "MultiFinance: ETH Transfer Failed");
    }
	
}



contract MultyFinanceDefi is Ownable {
	 using SafeMath for uint;
	using Address for address;
	using SafeMath for uint;
	address private _refPool;
	string private _name;
	
	mapping (address => address) private _referral;
	mapping (address => uint) private _activeVault;
	mapping (address => uint) private _exp;
	mapping (address => uint) private _reftotal;
	address [] private _vault;
	address public ethprice;
	address public mfipair;
	
	constructor (address _oracle, address _uni) public {
		_name = 'Multy Finance Defi';
		_refPool = _msgSender();
		ethprice = _oracle;
		mfipair = _uni;

	}
	
	function name() external view returns (string memory) {
        return _name;
    }
	
	function getPrice() external view returns(uint){
		//18 decimals
		(uint reserve0, uint reserve1, uint blockTimestampLast) = IUniswapV2Pair(mfipair).getReserves();
		uint priceUsd = AggregatorInterface(ethprice).latestAnswer();
		return reserve1.mul(1e10).mul(priceUsd).div(reserve0);
	}
	
	modifier onlyVault() {
        require(_activeVault[_msgSender()] == 1 || owner() == _msgSender(), "MultiFinance: caller is not vault");
        _;
    }
	
	function setReferral(address addr, address referral) external onlyVault returns(bool) {
		require(addr != referral, "MultiFinance: Same address");
		require(_referral[addr] == address(0), "MultiFinance: Already registered");
		require(_referral[referral] != address(0) || referral == owner(), "MultiFinance: Unregistered referral");
		_referral[addr] = referral;
		_reftotal[referral] = _reftotal[referral].add(1);
		return true;
	}
	
	function setExp(address _addr, uint _newExp) external onlyVault{
		_exp[_addr] = _newExp;
	}
	
	function getExp(address _addr) external view returns(uint){
		return _exp[_addr];
	}
	
	function referralOf(address _addr) external view returns(address){
		return _referral[_addr];
	}
	
	function getRefTotal(address _addr) external view returns(uint){
		return _reftotal[_addr];
	}
	
	function getReferral(address _addr) external view returns(address){
		if(now > _exp[_addr])
			return _refPool;
		else{
			return _referral[_addr];
		}
	}
	
	function setRefPool(address _addr) external onlyOwner{
		require(_addr != address(0), "MultiFinance: Zero Address");
		_refPool = _addr;
		
	}
	function setPriceOracle(address _addr) external onlyOwner{
		require(_addr != address(0), "MultiFinance: Zero Address");
		ethprice = _addr;
	}
	function setPair(address _addr) external onlyOwner{
		require(_addr != address(0), "MultiFinance: Zero Address");
		mfipair = _addr;
	}
	
	function getRefPool() external view returns(address){
		return _refPool;
	}
	
	function activateVault(address vault) external onlyOwner{
		require(vault.isContract(), "MultiFinance: !Contract");
		require(_activeVault[vault] == 0 || _activeVault[vault] == 2, "MultiFinance: Duplicate Vault address");
		if(_activeVault[vault] != 2){
			_vault.push(vault);
		}
		_activeVault[vault] = 1;
		
	}
	
	function deactivateVault(address vault) external onlyOwner{
		require(_activeVault[vault] == 1, "MultiFinance: Invalid vault address");
		_activeVault[vault] = 2;
	}
	
	function tvl() external view returns(uint){
		uint sum;
		for(uint i = 0; i < _vault.length; i++){
			if(_activeVault[_vault[i]]==1){
				sum = sum.add(Mtoken(_vault[i]).calcPoolValue());
			}
		}
		return sum;
	}
	
	receive() external payable {
    }
	
}