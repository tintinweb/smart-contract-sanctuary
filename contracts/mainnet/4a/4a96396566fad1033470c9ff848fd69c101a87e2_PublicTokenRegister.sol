/// @title Public Token Register - Allows to register coins and get it from another contract.
/// @author Global Group - <globalinvestplace@gmail.com>
pragma solidity ^0.4.24;

contract IPublicTokenRegister {
	function securityReg(address _securityWallet) public;
	function registerCoin(string _name,string _symbol, address coinTokenContract) public;
	function getSymbol(string _coin) public view returns(string _symbol);
	function getCoinAddress(string _coin) public view returns(address _coinTokenContract);
	function getHexSymbol(string _coin) public view returns(bytes4 _hexSymbol);
	function getIsCoinReg(string _coin) public view returns(bool _isReg);
	function getCoinInfo(string _coin) public view returns(string _symbol, address coinAddress, bytes4 _hexSymbol, bool _isReg);
	function getIsSecurityWalletReg(address _wallet) public view returns(bool _isReg);

	event RegisterCoin(string _coin, string _name, string _symbol, address _coinTokenContract);
	event SecurityReg(address _securityWallet, bool isRegistered);
}

contract Ownable {
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

contract PublicTokenRegister is IPublicTokenRegister, Ownable {
	mapping(string => Coin) internal coin;
	mapping(address => bool) internal registeredSecurity;
	address[] internal registeredCoins;
	
	modifier onlySecurity {
		require(registeredSecurity[msg.sender] == true);
		_;
	}
    
    // STRUCTS
	struct Coin {
		string symbol;
		address coinTokenContract;
		bytes4 hexSymbol;
		bool isReg;
	}

    function() public payable {
		revert();
    }
    
    constructor() public {
    }
    
    function registerCoin(string _name, string _symbol, address _coinTokenContract) public onlySecurity {
		require(coin[_name].isReg == false);
		bytes4 _hexSymbol = convertStringToBytes(_name);
        coin[_name] = Coin ({
            symbol: _symbol,
            coinTokenContract: _coinTokenContract,
            hexSymbol: _hexSymbol,
            isReg: true
        });
        registeredCoins.push(_coinTokenContract);
		
		emit RegisterCoin(_name, _name, _symbol, _coinTokenContract);
    }
	
	function removeCoin(string _name) public onlyOwner {
		require(coin[_name].isReg == true);
		coin[_name] = Coin({
			symbol: "",
			coinTokenContract: 0x0,
			hexSymbol: 0x0,
			isReg: false
		});
	}
	
	function securityReg(address _securityWallet) public onlyOwner {
		require(registeredSecurity[_securityWallet] == false);
		registeredSecurity[_securityWallet] = true;
		emit SecurityReg(_securityWallet, true);
	}
	
	function getSymbol(string _coinName) public view returns(string _symbol) {
		return coin[_coinName].symbol;
	}
	
	function getHexSymbol(string _coinName) public view returns(bytes4 _hexSymbol) {
		return coin[_coinName].hexSymbol;
	}
	
   	function getCoinAddress(string _coinName) public view returns(address _coinTokenContract) {
		return coin[_coinName].coinTokenContract;
	}
	
	function getIsCoinReg(string _coinName) public view returns(bool _isCoinReg) {
		return coin[_coinName].isReg;
	}
	
	function getCoinInfo(string _coinName) public view returns(string _symbol, address coinAddress, bytes4 _hexSymbol, bool _isReg) {
		return (getSymbol(_coinName),getCoinAddress(_coinName),getHexSymbol(_coinName),getIsCoinReg(_coinName));
	}
	
	function getIsSecurityWalletReg(address _wallet) public view returns(bool _isReg) {
		return registeredSecurity[_wallet];
	}
	
    function convertStringToBytes(string memory source) internal pure returns (bytes4 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}