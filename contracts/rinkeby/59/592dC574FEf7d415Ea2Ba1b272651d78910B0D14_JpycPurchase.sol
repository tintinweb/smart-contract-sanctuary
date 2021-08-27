/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.6.2;

interface IERC20 {
	function decimals() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);
}

contract JpycPurchase {

	using SafeMath for uint256;

	address payable jpyc_supplier;
	address public jpyc_address;
	uint256 internal jpyc_decimals;
	uint256 internal minimumPurchaseAmount;
	uint256 internal maximumPurchaseAmount;
	AggregatorInterface internal priceFeedEthUsd;
	AggregatorInterface internal priceFeedJpyUsd;
	IERC20 internal jpycInterface;

	mapping(address => AggregatorInterface) private priceFeedERC20Usd;

	constructor(address _jpyc_address) public {
		jpyc_supplier = msg.sender;
		jpyc_address = _jpyc_address;
		jpycInterface = IERC20(_jpyc_address);
		jpyc_decimals = IERC20(_jpyc_address).decimals();
		minimumPurchaseAmount = 1000e18;
		maximumPurchaseAmount = 200000e18;
		priceFeedJpyUsd = AggregatorInterface(0x3Ae2F46a2D84e3D5590ee6Ee5116B80caF77DeCA); //Mainnet 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3, Ropsten 0x795122664E4D4A3F7e66E8674953C97ADc60B17C
		priceFeedEthUsd = AggregatorInterface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //Mainnet 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, Ropsten 0x6B927dc8cF91c69d9dBFbf630D8951709cB0885D
	}

	// ================= 最低購入額の表示 =================
	function showMinimumPurchaseAmount() external view returns (uint256 _minimumPurchaseAmount)  {
		return minimumPurchaseAmount;
	}

	// ================= 購入上限額の表示 =================
	function showMaximumPurchaseAmount() external view returns (uint256 _maximumPurchaseAmount)  {
		return maximumPurchaseAmount;
	}

	// ================= 購入上限額の変更 =================
	function updateMinimumPurchaseAmount(uint _newMinimumPurchaseAmount) external onlyOwner {
		minimumPurchaseAmount = _newMinimumPurchaseAmount;
	}

	// ================= 購入上限額の変更 =================
	function updateMaximumPurchaseAmount(uint _newMaximumPurchaseAmount) external onlyOwner {
		maximumPurchaseAmount = _newMaximumPurchaseAmount;
	}

	// ================= pricefeedの取得 =================
	function getPriceFeedContract(address _tokenAddress) external view returns (AggregatorInterface contractAddress) {
		return priceFeedERC20Usd[_tokenAddress];
	}

	// ================= pricefeed を追加する =================
	function addPriceFeed(address _tokenAddress, address _chainlinkPriceFeed) external onlyOwner {
		priceFeedERC20Usd[_tokenAddress] = AggregatorInterface(_chainlinkPriceFeed);
	}

	// ================= jpyc supplyerを変更する =================
	function changeJpycSupplyer(address payable _jpycSupplyer) public onlyOwner {
		require(_jpycSupplyer != address(0), "_jpycSupplyer is the zero address");
		jpyc_supplier = _jpycSupplyer;
	}

    // ================= ETHでJPYCを購入する　=================

	function getLatestEthUsdPrice() public view returns (int256) {
		return priceFeedEthUsd.latestAnswer();
	}

	function getLatestJpyUsdPrice() public view returns (int256) {
		return priceFeedJpyUsd.latestAnswer();
	}

    // 欲しいJPYCの量に対して必要なETHを返す =================
	function getETHAmountFromJpyc (uint256 _jpycAmount) public view returns (uint256 ethAmount) {
		uint256 usdAmount = uint256(getLatestJpyUsdPrice()).mul(_jpycAmount);
		return ethAmount = usdAmount.div(uint256(getLatestEthUsdPrice()));
	}

    // 支払いたいETHからJPYCの量を返す =================
	function getJpycAmountFromETH (uint256 _ethAmount) public view returns (uint256 jpycAmount) {
		uint256 usdAmount = uint256(getLatestEthUsdPrice()).mul(_ethAmount);
		return jpycAmount = usdAmount.div(uint256(getLatestJpyUsdPrice()));
	}

    // 欲しいJPYCの量を指定して、それに必要なETHを払い購入する =================
	function purchaseExactJpycWithETH(uint256 _jpycAmount, uint256 _amountOutMax) payable external {
		require(minimumPurchaseAmount <= _jpycAmount && _jpycAmount <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(_jpycAmount <= jpycInterface.allowance(jpyc_supplier, address(this)), "insufficient allowance of JPYC");

		uint256 ethAmount = getETHAmountFromJpyc(_jpycAmount);
		require(ethAmount <= _amountOutMax, 'excessive slippage amount');
		require(msg.value >= ethAmount, "msg.value must greater than calculated ether amount");

		jpyc_supplier.transfer(ethAmount);
		jpycInterface.transferFrom(jpyc_supplier, msg.sender, _jpycAmount);

		if (msg.value > ethAmount) msg.sender.transfer(msg.value - ethAmount);
	}

    // 支払うETHの量を指定して、それに対応するJPYCを購入する =================
	function purchaseJpycWithExactETH(uint256 _amountInMin) payable external {
    uint256 jpycAmountFromEth = getJpycAmountFromETH(msg.value);
		require(minimumPurchaseAmount <= jpycAmountFromEth && jpycAmountFromEth <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(jpycAmountFromEth <= jpycInterface.allowance(jpyc_supplier, address(this)), "insufficient allowance of JPYC");
		require(jpycAmountFromEth >= _amountInMin, 'excessive slippage amount');

		jpyc_supplier.transfer(msg.value);
		jpycInterface.transferFrom(jpyc_supplier, msg.sender, jpycAmountFromEth);
    }


	// ================= ERC20でJPYCを購入する　=================

	function getLatestERC20UsdPrice(address _tokenAddress) public view returns (int) {
		return priceFeedERC20Usd[_tokenAddress].latestAnswer();
	}

    // 欲しいJPYCの量に対して必要なERC20を返す =================
	function getERC20AmountFromJpyc (uint256 _jpycAmount, address _tokenAddress) public view returns (uint256 erc20Amount) {
		uint256 usdAmount = uint256(getLatestJpyUsdPrice()).mul(_jpycAmount).div(10 ** (jpyc_decimals.sub(IERC20(_tokenAddress).decimals())));
		return erc20Amount = usdAmount.div(uint256(getLatestERC20UsdPrice(_tokenAddress)));
	}

    // 支払いたいERC20からJPYCの量を返す =================
	function getJpycAmountFromERC20 (uint _erc20Amount, address _tokenAddress) public view returns (uint256 jpycAmount) {
		uint256 usdAmount = uint256(getLatestERC20UsdPrice(_tokenAddress)).mul(_erc20Amount).mul(10 ** (jpyc_decimals.sub(IERC20(_tokenAddress).decimals())));
		return jpycAmount = usdAmount.div(uint256(getLatestJpyUsdPrice()));
	}

    // 欲しいJPYCの量を指定して、それに必要なERC20を払い購入する =================
	function purchaseExactJpycWithERC20(uint256 _jpycAmount, uint256 _amountOutMax, address _tokenAddress) external {
		require(minimumPurchaseAmount <= _jpycAmount && _jpycAmount <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(_jpycAmount <= jpycInterface.allowance(jpyc_supplier, address(this)), "insufficient allowance of JPYC");

		uint256 erc20Amount = getERC20AmountFromJpyc(_jpycAmount, _tokenAddress);
		require(erc20Amount <= _amountOutMax, 'excessive slippage amount');
		require(IERC20(_tokenAddress).balanceOf(msg.sender) >= erc20Amount, "insufficient balance of ERC20 token");

		IERC20(_tokenAddress).transferFrom(msg.sender, jpyc_supplier, erc20Amount);
		jpycInterface.transferFrom(jpyc_supplier, msg.sender, _jpycAmount);
	}

    // 支払うERC20の量を指定して、それに対応するJPYCを購入する =================
	function purchaseJpycWithExactERC20(uint256 _erc20Amount, uint256 _amountInMin, address _tokenAddress) external {
		uint256 jpycAmountFromERC20 = getJpycAmountFromERC20(_erc20Amount, _tokenAddress);
		require(minimumPurchaseAmount <= jpycAmountFromERC20 && jpycAmountFromERC20 <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(jpycAmountFromERC20 <= jpycInterface.allowance(jpyc_supplier, address(this)), "insufficient allowance of JPYC");
		require(jpycAmountFromERC20 >= _amountInMin, 'excessive slippage amount');

		require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _erc20Amount, "insufficient balance of ERC20 token");

		IERC20(_tokenAddress).transferFrom(msg.sender, jpyc_supplier, _erc20Amount);
		jpycInterface.transferFrom(jpyc_supplier, msg.sender, jpycAmountFromERC20);
	}

	modifier onlyOwner {
		require(
			msg.sender == jpyc_supplier,
			"msg.sender must be jpyc supplier."
		);
		_;
	}

}