pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;
pragma experimental "v0.5.0";

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
* https://github.com/OpenZeppelin/openzeppelin-solidity/blob/56515380452baad9fcd32c5d4502002af0183ce9/contracts/math/SafeMath.sol
*/
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}

}

/**
* @title Convenience and rounding functions when dealing with numbers already factored by 10**18 or 10**27
* @dev Math operations with safety checks that throw on error
* https://github.com/dapphub/ds-math/blob/87bef2f67b043819b7195ce6df3058bd3c321107/src/math.sol
*/
library SafeMathFixedPoint {
	using SafeMath for uint256;

	function mul27(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(y).add(5 * 10**26).div(10**27);
	}
	function mul18(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(y).add(5 * 10**17).div(10**18);
	}

	function div18(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(10**18).add(y.div(2)).div(y);
	}
	function div27(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(10**27).add(y.div(2)).div(y);
	}
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20Basic.sol
 */
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {
	address public owner;

	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	constructor() public {
		owner = msg.sender;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	/**
	 * @dev Allows the current owner to relinquish control of the contract.
	 */
	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(owner);
		owner = address(0);
	}
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Claimable.sol
 */
contract Claimable is Ownable {
	address public pendingOwner;

	/**
	 * @dev Modifier throws if called by any account other than the pendingOwner.
	 */
	modifier onlyPendingOwner() {
		require(msg.sender == pendingOwner);
		_;
	}

	/**
	 * @dev Allows the current owner to set the pendingOwner address.
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner) onlyOwner public {
		pendingOwner = newOwner;
	}

	/**
	 * @dev Allows the pendingOwner address to finalize the transfer.
	 */
	function claimOwnership() onlyPendingOwner public {
		emit OwnershipTransferred(owner, pendingOwner);
		owner = pendingOwner;
		pendingOwner = address(0);
	}
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/lifecycle/Pausable.sol
 */
contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;


	/**
	 * @dev Modifier to make a function callable only when the contract is not paused.
	 */
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is paused.
	 */
	modifier whenPaused() {
		require(paused);
		_;
	}

	/**
	 * @dev called by the owner to pause, triggers stopped state
	 */
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}

	/**
	 * @dev called by the owner to unpause, returns to normal state
	 */
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send or transfer.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/payment/PullPayment.sol
 */
contract PullPayment {
	using SafeMath for uint256;

	mapping(address => uint256) public payments;
	uint256 public totalPayments;

	/**
	* @dev Withdraw accumulated balance, called by payee.
	*/
	function withdrawPayments() public {
		address payee = msg.sender;
		uint256 payment = payments[payee];

		require(payment != 0);
		require(address(this).balance >= payment);

		totalPayments = totalPayments.sub(payment);
		payments[payee] = 0;

		payee.transfer(payment);
	}

	/**
	* @dev Called by the payer to store the sent amount as credit to be pulled.
	* @param dest The destination address of the funds.
	* @param amount The amount to transfer.
	*/
	function asyncSend(address dest, uint256 amount) internal {
		payments[dest] = payments[dest].add(amount);
		totalPayments = totalPayments.add(amount);
	}
}

contract Dai is ERC20 {

}

contract Weth is ERC20 {
	function deposit() public payable;
	function withdraw(uint wad) public;
}

contract Mkr is ERC20 {

}

contract Peth is ERC20 {

}

contract Oasis {
	function getBuyAmount(ERC20 tokenToBuy, ERC20 tokenToPay, uint256 amountToPay) external view returns(uint256 amountBought);
	function getPayAmount(ERC20 tokenToPay, ERC20 tokenToBuy, uint amountToBuy) public constant returns (uint amountPaid);
	function getBestOffer(ERC20 sell_gem, ERC20 buy_gem) public constant returns(uint offerId);
	function getWorseOffer(uint id) public constant returns(uint offerId);
	function getOffer(uint id) public constant returns (uint pay_amt, ERC20 pay_gem, uint buy_amt, ERC20 buy_gem);
	function sellAllAmount(ERC20 pay_gem, uint pay_amt, ERC20 buy_gem, uint min_fill_amount) public returns (uint fill_amt);
}

contract Medianizer {
	function read() external view returns(bytes32);
}

contract Maker {
	function sai() external view returns(Dai);
	function gem() external view returns(Weth);
	function gov() external view returns(Mkr);
	function skr() external view returns(Peth);
	function pip() external view returns(Medianizer);

	// Join-Exit Spread
	 uint256 public gap;

	struct Cup {
		// CDP owner
		address lad;
		// Locked collateral (in SKR)
		uint256 ink;
		// Outstanding normalised debt (tax only)
		uint256 art;
		// Outstanding normalised debt
		uint256 ire;
	}

	uint256 public cupi;
	mapping (bytes32 => Cup) public cups;

	function lad(bytes32 cup) public view returns (address);
	function per() public view returns (uint ray);
	function tab(bytes32 cup) public returns (uint);
	function ink(bytes32 cup) public returns (uint);
	function rap(bytes32 cup) public returns (uint);
	function chi() public returns (uint);

	function open() public returns (bytes32 cup);
	function give(bytes32 cup, address guy) public;
	function lock(bytes32 cup, uint wad) public;
	function draw(bytes32 cup, uint wad) public;
	function join(uint wad) public;
	function wipe(bytes32 cup, uint wad) public;
}

contract LiquidLong is Ownable, Claimable, Pausable, PullPayment {
	using SafeMath for uint256;
	using SafeMathFixedPoint for uint256;

	uint256 public providerFeePerEth;

	Oasis public oasis;
	Maker public maker;
	Dai public dai;
	Weth public weth;
	Peth public peth;
	Mkr public mkr;

	event NewCup(address user, bytes32 cup);

	constructor(Oasis _oasis, Maker _maker) public payable {
		providerFeePerEth = 0.01 ether;

		oasis = _oasis;
		maker = _maker;
		dai = maker.sai();
		weth = maker.gem();
		peth = maker.skr();
		mkr = maker.gov();

		// Oasis buy/sell
		dai.approve(address(_oasis), uint256(-1));
		// Wipe
		dai.approve(address(_maker), uint256(-1));
		mkr.approve(address(_maker), uint256(-1));
		// Join
		weth.approve(address(_maker), uint256(-1));
		// Lock
		peth.approve(address(_maker), uint256(-1));

		if (msg.value > 0) {
			weth.deposit.value(msg.value)();
		}
	}

	// Receive ETH from WETH withdraw
	function () external payable {
	}

	function wethDeposit() public payable {
		weth.deposit.value(msg.value)();
	}

	function wethWithdraw(uint256 _amount) public onlyOwner {
		weth.withdraw(_amount);
		owner.transfer(_amount);
	}

	function ethWithdraw() public onlyOwner {
		// Ensure enough ether is left for PullPayments
		uint256 _amount = address(this).balance.sub(totalPayments);
		owner.transfer(_amount);
	}

	// Affiliates and provider are only ever due raw ether, all tokens are due to owner
	function transferTokens(ERC20 _token) public onlyOwner {
		_token.transfer(owner, _token.balanceOf(this));
	}

	function ethPriceInUsd() public view returns (uint256 _attousd) {
		return uint256(maker.pip().read());
	}

	function estimateDaiSaleProceeds(uint256 _attodaiToSell) public view returns (uint256 _daiPaid, uint256 _wethBought) {
		return getPayPriceAndAmount(dai, weth, _attodaiToSell);
	}

	// buy/pay are from the perspective of the taker/caller (Oasis contracts use buy/pay terminology from perspective of the maker)
	function getPayPriceAndAmount(ERC20 _payGem, ERC20 _buyGem, uint256 _payDesiredAmount) public view returns (uint256 _paidAmount, uint256 _boughtAmount) {
		uint256 _offerId = oasis.getBestOffer(_buyGem, _payGem);
		while (_offerId != 0) {
			uint256 _payRemaining = _payDesiredAmount.sub(_paidAmount);
			(uint256 _buyAvailableInOffer, , uint256 _payAvailableInOffer,) = oasis.getOffer(_offerId);
			if (_payRemaining <= _payAvailableInOffer) {
				uint256 _buyRemaining = _payRemaining.mul(_buyAvailableInOffer).div(_payAvailableInOffer);
				_paidAmount = _paidAmount.add(_payRemaining);
				_boughtAmount = _boughtAmount.add(_buyRemaining);
				break;
			}
			_paidAmount = _paidAmount.add(_payAvailableInOffer);
			_boughtAmount = _boughtAmount.add(_buyAvailableInOffer);
			_offerId = oasis.getWorseOffer(_offerId);
		}
		return (_paidAmount, _boughtAmount);
	}

	function openCdp(uint256 _leverage, uint256 _leverageSizeInAttoeth, uint256 _allowedFeeInAttoeth, uint256 _affiliateFeeInAttoeth, address _affiliateAddress) public payable returns (bytes32 _cdpId) {
		require(_leverage >= 100 && _leverage <= 300);
		uint256 _lockedInCdpInAttoeth = _leverageSizeInAttoeth.mul(_leverage).div(100);
		uint256 _loanInAttoeth = _lockedInCdpInAttoeth.sub(_leverageSizeInAttoeth);
		uint256 _providerFeeInAttoeth = _loanInAttoeth.mul18(providerFeePerEth);
		require(_providerFeeInAttoeth <= _allowedFeeInAttoeth);
		uint256 _drawInAttodai = _loanInAttoeth.mul18(uint256(maker.pip().read()));
		uint256 _pethLockedInCdp = _lockedInCdpInAttoeth.div27(maker.per());

		// Convert ETH to WETH (only the value amount, excludes loan amount which is already WETH)
		weth.deposit.value(_leverageSizeInAttoeth)();
		// Open CDP
		_cdpId = maker.open();
		// Convert WETH into PETH
		maker.join(_pethLockedInCdp);
		// Store PETH in CDP
		maker.lock(_cdpId, _pethLockedInCdp);
		// Withdraw DAI from CDP
		maker.draw(_cdpId, _drawInAttodai);

		// Sell all drawn DAI
		uint256 _wethBoughtInAttoweth = oasis.sellAllAmount(dai, _drawInAttodai, weth, 0);
		// SafeMath failure below catches not enough eth provided
		uint256 _refundDue = msg.value.add(_wethBoughtInAttoweth).sub(_lockedInCdpInAttoeth).sub(_providerFeeInAttoeth).sub(_affiliateFeeInAttoeth);

		if (_loanInAttoeth > _wethBoughtInAttoweth) {
			weth.deposit.value(_loanInAttoeth - _wethBoughtInAttoweth)();
		}

		if (_providerFeeInAttoeth != 0) {
			asyncSend(owner, _providerFeeInAttoeth);
		}
		if (_affiliateFeeInAttoeth != 0) {
			asyncSend(_affiliateAddress, _affiliateFeeInAttoeth);
		}

		emit NewCup(msg.sender, _cdpId);
		// Send the CDP to the user
		maker.give(_cdpId, msg.sender);

		if (_refundDue > 0) {
			require(msg.sender.call.value(_refundDue)());
		}
	}
}