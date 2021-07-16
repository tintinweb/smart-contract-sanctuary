pragma solidity >= 0.5.0 < 0.6.0;
import "./SafeMath.sol";
import "./strings.sol";
library SymbolsLib {
    using SafeMath for uint256;

	struct Symbols {
		uint count;
		mapping(uint => string) indexToSymbol;
		mapping(string => uint256) symbolToPrices; 
		mapping(address => string) addressToSymbol; 
		mapping(string => address) symbolToAddress;
		string ratesURL;
	}

	/** 
	 *  initializes the symbols structure
	 */
	function initialize(Symbols storage self, string memory ratesURL, string memory tokenNames, address[] memory tokenAddresses) public {
		strings.slice memory delim = strings.toSlice(",");
		strings.slice memory tokensList = strings.toSlice(tokenNames);

		self.count = strings.count(tokensList, delim) + 1;
		require(self.count == tokenAddresses.length);

		self.ratesURL = ratesURL;

		for(uint i = 0; i < self.count; i++) {
			strings.slice memory token;
			strings.split(tokensList, delim, token);

		 	address tokenAddress = tokenAddresses[i];
		 	string memory tokenName = strings.toString(token);

		 	self.indexToSymbol[i] = tokenName;
		 	self.addressToSymbol[tokenAddress] = tokenName;
		 	self.symbolToAddress[tokenName]  = tokenAddress;
		}
	}

	function getCoinLength(Symbols storage self) public view returns (uint length){ 
		return self.count; 
	} 

	function addressFromIndex(Symbols storage self, uint index) public view returns(address) {
		require(index < self.count, "coinIndex must be smaller than the coins length.");
		return self.symbolToAddress[self.indexToSymbol[index]];
	} 

	function priceFromIndex(Symbols storage self, uint index) public view returns(uint256) {
		require(index < self.count, "coinIndex must be smaller than the coins length.");
		return self.symbolToPrices[self.indexToSymbol[index]];
	} 

	function priceFromAddress(Symbols storage self, address tokenAddress) public view returns(uint256) {
		return self.symbolToPrices[self.addressToSymbol[tokenAddress]];
	} 

	function setPrice(Symbols storage self, uint index, uint256 price) public { 
		require(index < self.count, "coinIndex must be smaller than the coins length.");
		self.symbolToPrices[self.indexToSymbol[index]] = price;
	}
	
	function setPriceByList(Symbols storage self ,uint256[] memory priceList)public{
	    for(uint i=0;i<priceList.length;i++){
	        setPrice(self,i,priceList[i]);
	    }
	}

	function isEth(Symbols storage self, address tokenAddress) public view returns(bool) {
		return self.symbolToAddress["BNB"] == tokenAddress;
	}

	/** 
	 * Parse result from oracle, e.g. an example is [8110.44, 0.2189, 445.05, 1]. 
	 * The function will remove the '[' and ']' and split the string by ','. 
	 */
	function parseRates(Symbols storage self, string memory result,uint256 who) internal {
		strings.slice memory delim = strings.toSlice(",");
		strings.slice memory startChar = strings.toSlice("[");
		strings.slice memory endChar = strings.toSlice("]");
		strings.slice memory substring = strings.until(strings.beyond(strings.toSlice(result), startChar), endChar);
		uint count = strings.count(substring, delim) + 1;
		//ok 
		
		for(uint i = (who-1)*3; i < (who-1)*3+3; i++) {
			strings.slice memory token;
			strings.split(substring, delim, token);
			setPrice(self, i, stringToUint(strings.toString(token)));
		}
	}


// 	function parseRatesbyself(Symbols storage self, string memory result) internal {
// 		strings.slice memory delim = strings.toSlice(",");
// 		strings.slice memory startChar = strings.toSlice("[");
// 		strings.slice memory endChar = strings.toSlice("]");
// 		strings.slice memory substring = strings.until(strings.beyond(strings.toSlice(result), startChar), endChar);
// 		uint count = strings.count(substring, delim) + 1;
// 		//ok 
		
// 		for(uint i = 0; i < count; i++) {
// 			strings.slice memory token;
// 			strings.split(substring, delim, token);
// 			setPrice(self, i, stringToUint(strings.toString(token)));
// 		}
// 	}

	/** 
	 *  Helper function to convert string to number
	 */
	function stringToUint(string memory numString) private pure returns(uint256 number) {
		bytes memory numBytes = bytes(numString);
		bool isFloat = false;
		uint times = 6;
		number = 0;
		for(uint256 i = 0; i < numBytes.length; i ++) {
			if (numBytes[i] >= '0' && numBytes[i] <= '9' && times > 0) {
				number *= 10;
				number = number + uint8(numBytes[i]) - 48;
				if (isFloat) {
					times --;
				}
			} else if (numBytes[i] == '.') {
				isFloat = true;
				continue;
			}
		}
		while (times > 0) {
			number *= 10;
			times --;
		}
		return number;
	}
}