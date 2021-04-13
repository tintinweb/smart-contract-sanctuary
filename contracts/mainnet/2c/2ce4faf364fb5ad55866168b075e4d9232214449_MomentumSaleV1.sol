/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.4;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Math {
    
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
		require(c / a == b, "multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

}

interface IERC20{
	
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface IMomentumSaleV1{

    function createSaleContract(uint256 _allocated, uint8 _source) external returns(bool);

    function increaseAllocation(uint256 _amount, uint256 _saleId) external returns(bool);

    function purchaseWithEth() external payable returns(bool);

    function adminPurchase(uint256 _amountToken, uint256 _usdPurchase, uint256 _pricePurchase) external returns(bool);

    function fetchTokenPrice() external returns(uint256);

    function claim(uint256 _saleId) external returns(bool);

    function resolveBonus(uint256 _saleId, address _user) external returns(uint256);

    function resolveBonusPercent(uint256 _saleId) external returns(bool);

    function updateNewEdgexSource(address _newSource, uint8 _index) external returns(bool);

    function revokeOwnership(address _newOwner) external returns(bool);

    function updateEthSource(address _newSource) external returns(bool);

    function updateEdgexTokenContract(address _newSource) external returns(bool);

    function updatePricePerToken(uint256 _price) external returns(bool);

}

interface IWhiteListOracle {

    function whitelist(address _user) external returns(bool);

    function blacklist(address _user) external returns(bool);

    function transferGovernor(address _newGovernor) external returns(bool);

    function whitelisted(address _user) external view returns(bool);

}

contract MomentumSaleV1 is ReentrancyGuard {
    
   address public admin;
   address public ethWallet;
   address public organisation;
   address public governor;
   address public whitelistOracle;
    
   uint256 public totalSaleContracts;
   uint256 public pricePerToken;
   address public ethPriceSource;
   address public edgexTokenContract;
   uint256 public lastCreated;
   uint256 public totalOracles = 15;

   struct Sale{
       uint256 usdPurchase;
       uint256 pricePurchase; // 8 decimal
       uint256 amountPurchased;
       uint256 timestamp;
       bool isAllocated;
       uint256 bonus;
       uint256 saleId;
   } 
   
   struct SaleInfo{
       uint256 start;
       uint256 end;
       uint256 allocated;
       uint256 totalPurchased;
       uint8 priceSource;
   }
   
   mapping(address => uint256) public totalPurchases;
   mapping(address => mapping(uint256 => Sale)) public sale;
   mapping(uint256 => SaleInfo) public info;
   mapping(uint256 => address) public oracle;

   event RevokeOwnership(address indexed _owner);
   event UpdatePrice(uint256 _newPrice);
   event UpdateGovernor(address indexed _governor);

   constructor(
       address _admin,
       address _organisation,
       address _ethWallet,
       address _governor,
       uint256 _pricePerToken,
       address _ethPriceSource,
       address _whitelistOracle,
       address _edgexTokenContract
    ) 
    {
       admin = _admin;
       organisation = _organisation;
       ethWallet = _ethWallet;
       governor = _governor;
       pricePerToken = _pricePerToken;
       whitelistOracle = _whitelistOracle;
       ethPriceSource = _ethPriceSource;
       edgexTokenContract = _edgexTokenContract;
   }
   
   modifier onlyAdmin(){
       require(msg.sender == admin, "Caller not admin");
       _;
   }
   
   modifier onlyGovernor(){
       require(msg.sender == governor, "Caller not governor");
       _;
   }

   modifier isZero(address _address){
       require(_address != address(0),"Invalid Address");
       _;
   }

   function isWhitelisted(address _user) public virtual view returns(bool){
        return IWhiteListOracle(whitelistOracle).whitelisted(_user);
   }
   
   function createSaleContract(uint256 _allocated, uint8 _source) public onlyGovernor returns(bool) {
       require(
           Math.add(lastCreated,2 hours) < block.timestamp,
           "Create After Sometime"
       );
       SaleInfo storage i = info[Math.add(totalSaleContracts,1)];
       i.start = block.timestamp;
       i.end = Math.add(block.timestamp,2 hours);
       i.allocated = Math.mul(_allocated,10 ** 18);
       i.priceSource = _source;
       lastCreated = block.timestamp;
       totalSaleContracts = Math.add(totalSaleContracts,1);
       return true;   
   }
   
   function increaseAllocation(uint256 _amount, uint256 _saleId) public onlyGovernor returns(bool){
       SaleInfo storage i = info[_saleId];
       require(
         block.timestamp < i.end,
         "Sale Ended"
       );
       i.allocated = Math.add(
                     i.allocated,
                     Math.mul(_amount,10**18)
                     );
       return true;
       
   }
   
   function purchaseWithEth() public payable nonReentrant returns(bool){
       SaleInfo storage i = info[totalSaleContracts];
       require(
            i.totalPurchased <= i.allocated, 
            "Sold Out"
        );
        require(
            block.timestamp < i.end,
            "Purchase Ended"
        );
        require(isWhitelisted(msg.sender),"Address not verified");
        (
            uint256 _amountToken,
            uint256 _pricePurchase,
            uint256 _usdPurchase
        )   = resolverEther(msg.value);
        Sale storage s = sale[msg.sender][Math.add(totalPurchases[msg.sender],1)];
        s.usdPurchase = _usdPurchase;
        s.amountPurchased = _amountToken;
        s.pricePurchase = _pricePurchase;
        s.timestamp = block.timestamp;
        s.saleId = totalSaleContracts;
        i.totalPurchased = Math.add(i.totalPurchased,_amountToken);
        totalPurchases[msg.sender] = Math.add(totalPurchases[msg.sender],1);
        payable(ethWallet).transfer(msg.value);
        return true;
   }
   
   function adminPurchase(
        uint256 _amountToken,
        uint256 _usdPurchase,
        uint256 _pricePurchase
        ) public onlyGovernor returns(bool){
        SaleInfo storage i = info[totalSaleContracts];
        require(
            i.totalPurchased <= i.allocated, 
            "Sold Out"
        );
        require(
            block.timestamp < i.end,
            "Purchase Ended"
        );
        Sale storage s = sale[msg.sender][Math.add(totalPurchases[msg.sender],1)];
        s.usdPurchase = _usdPurchase;
        s.amountPurchased = _amountToken;
        s.pricePurchase = _pricePurchase;
        s.timestamp = block.timestamp;
        s.saleId = totalSaleContracts;
        i.totalPurchased = Math.add(i.totalPurchased,_amountToken);
        totalPurchases[msg.sender] = Math.add(totalPurchases[msg.sender],1);
        return true;
   }
   
   function resolverEther(uint256 _amountEther) public view returns(uint256,uint256,uint256){
        uint256 ethPrice = uint256(fetchEthPrice());
                ethPrice = Math.mul(_amountEther,ethPrice);
        uint256 price = fetchTokenPrice();
        uint256 _tokenAmount = Math.div(ethPrice,price);
        return(_tokenAmount,price,ethPrice);
    }
    
    function fetchTokenPrice() public view returns(uint256){
        SaleInfo storage i = info[totalSaleContracts];
        if(i.priceSource == 0){
            return pricePerToken;
        }
        else{
            return uint256(fetchEdgexPrice());
        }
    }
   
   function fetchEthPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(ethPriceSource).latestRoundData();
        return price;
    }
    
    function fetchEdgexPrice() public view returns (uint256) {
        uint256 totalPrice;
        uint256 validOracles;
        for(uint256 i = 0; i < totalOracles ; i++){
        if(oracle[i] != address(0)){
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracle[i]).latestRoundData();
        totalPrice = Math.add(totalPrice,uint256(price));
        validOracles = Math.add(validOracles,1);
        }
        }
        return Math.div(totalPrice, validOracles);
    }
    
    function claim(uint256 _saleId) public nonReentrant returns(bool){
        Sale storage s = sale[msg.sender][_saleId];
        SaleInfo storage i = info[s.saleId];
        require(
            !s.isAllocated,
            "Already Settled"
        );
        require(
            block.timestamp > i.end,
            "Sale Not Yet Ended"
        );
        uint256 _bonusTokens = resolveBonus(_saleId,msg.sender);
        s.bonus = _bonusTokens;
        s.isAllocated = true;
        IERC20(edgexTokenContract)
        .transfer(
            msg.sender, 
            Math.add(s.amountPurchased,_bonusTokens)
            );
         IERC20(edgexTokenContract)
        .transfer(
            organisation, 
            Math.div(s.amountPurchased,100)
        );
        return true;
    }
    
    function resolveBonus(uint256 _saleId,address _user) public view returns(uint256){
        Sale storage s = sale[_user][_saleId];
        uint256 _bonusPercent = resolveBonusPercent(s.saleId);
        uint256 _bonusTokens = Math.mul(s.amountPurchased,_bonusPercent);
                _bonusTokens = Math.div(_bonusTokens,10**6);
        return _bonusTokens;
    }
    
    function resolveBonusPercent(uint256 _saleId) public view returns(uint256){
        SaleInfo storage i = info[_saleId];
        uint _salePercent = Math.div(
                            Math.mul(i.totalPurchased,10**6),
                            i.allocated);
        if(_salePercent < 30 * 10 ** 4) {
            return 0;
        }
        else if(_salePercent > 30 * 10 ** 4 && _salePercent < 40 * 10 ** 4){
            return 10000;
        }
        else if(_salePercent > 40 * 10 ** 4 && _salePercent < 50 * 10 ** 4){
            return 25000;
        }
        else if(_salePercent > 50 * 10 ** 4 && _salePercent < 60 * 10 ** 4){
            return 40000;
        }
        else if(_salePercent > 60 * 10 ** 4 && _salePercent < 70 * 10 ** 4){
            return 50000;
        }
        else if(_salePercent > 70 * 10 ** 4 && _salePercent < 80 * 10 ** 4){
            return 65000;
        }
        else if(_salePercent > 80 * 10 ** 4 && _salePercent < 90 * 10 ** 4){
            return 75000;
        }
        else{
            return 100000;
        }
    }
    
    function updateNewEdgexSource(address _newSource, uint8 index) public onlyAdmin isZero(_newSource) returns(bool){
        oracle[index] = _newSource;
        return true;
    }
    
    function revokeOwnership(address _newOwner) public onlyAdmin isZero(_newOwner) returns(bool){
        admin = payable(_newOwner);
        emit RevokeOwnership(_newOwner);
        return true;
    }
    
    function updateEthSource(address _newSource) public onlyAdmin isZero(_newSource) returns(bool){
        ethPriceSource = _newSource;
        return true;
    }
    
     function updateEdgexTokenContract(address _newSource) public onlyAdmin isZero(_newSource) returns(bool){
        edgexTokenContract = _newSource;
        return true;
    }
    
    function updatePricePerToken(uint256 _price) public onlyAdmin returns(bool){
        pricePerToken = _price;
        emit UpdatePrice(_price);
        return true;
    }    

    function drain(address _to, uint256 _amount) public onlyAdmin isZero(_to) returns(bool){
        IERC20(edgexTokenContract).transfer(_to,_amount);
        return true;
    }

    function updateWhiteListOracle(address _newOracle) public onlyAdmin isZero(_newOracle) returns(bool){
        whitelistOracle = _newOracle;
        return true;
    }

    function updateGovernor(address _newGovernor) public onlyGovernor isZero(_newGovernor) returns(bool){
        governor = _newGovernor;
        emit UpdateGovernor(_newGovernor);
        return true;
    }

}