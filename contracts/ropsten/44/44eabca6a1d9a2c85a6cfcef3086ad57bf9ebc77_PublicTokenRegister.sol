/// @title Public Token Register - Allows to register coins and get it from another contract.
/// @author Global Group - <globalinvestplace@gmail.com>
pragma solidity ^0.4.24;

contract IPublicTokenRegister {
	function securityReg(address _securityWallet) public;
	function registerCoin(bytes4 _coin,string _name,string _symbol, address coinTokenContract) public;

	function getName(string _coin) public view returns(string _name);
	function getSymbol(string _coin) public view returns(string _symbol);
	function getCoinAddress(bytes4 _coin) public view returns(address _coinTokenContract);
	function getHexSymbol(string _coin) public view returns(bytes4 _hexSymbol);
	function getIsCoinReg(bytes4 _coin) public view returns(bool _isReg);
	function getCoinInfo(string _coin) public view returns(string _name, string _symbol, address coinAddress, bytes4 _hexSymbol, bool _isReg);

	event RegisterCoin(bytes4 _coin, string _name, string _symbol, address _coinTokenContract);
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
    
	mapping(bytes4 => Coin) internal coin;
	mapping(address => bool) internal registeredSecurity;
	address[] internal registeredCoins;
	
	modifier onlySecurity {
		require(registeredSecurity[msg.sender] == true);
		_;
	}
    
    // STRUCTS
	struct Coin {
		string name;
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
    
    function registerCoin(bytes4 _coin, string _name, string _symbol, address _coinTokenContract) public onlySecurity {
		require(coin[_coin].isReg == false);
        coin[_coin] = Coin ({
            name: _name,
            symbol: _symbol,
            coinTokenContract: _coinTokenContract,
            hexSymbol: _coin,
            isReg: true
        });
        registeredCoins.push(_coinTokenContract);
		
		emit RegisterCoin(_coin, _name, _symbol, _coinTokenContract);
    }
	
	function securityReg(address _securityWallet) public onlyOwner {
		require(registeredSecurity[_securityWallet] == false);
		registeredSecurity[_securityWallet] = true;
		emit SecurityReg(_securityWallet, true);
	}
	
	function getName(string _coin) public view returns(string _name) {
		return coin[convertStringToBytes(_coin)].name;
	}
	
	function getSymbol(string _coin) public view returns(string _symbol) {
		return coin[convertStringToBytes(_coin)].symbol;
	}
	
	function getHexSymbol(string _coin) public view returns(bytes4 _hexSymbol) {
		return coin[convertStringToBytes(_coin)].hexSymbol;
	}
	
   	function getCoinAddress(bytes4 _coin) public view returns(address _coinTokenContract) {
		return coin[_coin].coinTokenContract;
	}
	
	function getIsCoinReg(bytes4 _coin) public view returns(bool _isReg) {
		return coin[_coin].isReg;
	}
	
	function getCoinInfo(string _coin) public view returns(string _name, string _symbol, address coinAddress, bytes4 _hexSymbol, bool _isReg) {
		return (getName(_coin),getSymbol(_coin),getCoinAddress(getHexSymbol(_coin)),getHexSymbol(_coin),getIsCoinReg(getHexSymbol(_coin)));
	}
	
    function convertStringToBytes(string memory source) public pure returns (bytes4 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}