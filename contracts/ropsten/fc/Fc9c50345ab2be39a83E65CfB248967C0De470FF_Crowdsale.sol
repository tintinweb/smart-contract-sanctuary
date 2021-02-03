/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.4.18;

contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Crowdsale {
	using SafeMath for uint256;

	ERC20 public token;
	address public wallet;
	uint256 public rate;
	uint256 public weiRaised;
	uint256 public releaseTime;

	mapping (address => uint) public ledger;

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	function Crowdsale(uint256 _rate, ERC20 _token, uint _releaseTime) public {
		require(_rate > 0);
		require(_token != address(0));

		rate = _rate;
		wallet = msg.sender;
		token = _token;
		releaseTime = _releaseTime;
	}

	// -----------------------------------------
	// Crowdsale external interface
	// -----------------------------------------

	function () external payable {
		buyTokens(msg.sender);
	}
	function buyTokens(address _beneficiary) public payable {
		uint256 weiAmount = msg.value * 10**18;
		_preValidatePurchase(_beneficiary, weiAmount);
		uint256 tokens = _getTokenAmount(weiAmount);
		weiRaised = weiRaised.add(weiAmount);
		_processPurchase(_beneficiary, tokens);
		TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
		_forwardFunds();
	}

	// -----------------------------------------
	// Internal interface (extensible)
	// -----------------------------------------

	/**
	 * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	/**
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
	 * @param _beneficiary Address performing the token purchase
	 * @param _tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
		// token.transfer(_beneficiary, _tokenAmount);
		ledger[_beneficiary] += _tokenAmount;

	}

	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Override to extend the way in which ether is converted to tokens.
	 * @param _weiAmount Value in wei to be converted into tokens
	 * @return Number of tokens that can be purchased with the specified _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		return _weiAmount.div(rate);
	}

	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	function release(address _beneficiary) public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime, "TokenTimelock: current time is before release time");

        // uint256 amount = token.balanceOf(address(this));
        uint amount = ledger[_beneficiary];
        require(amount > 0, "TokenTimelock: no tokens to release");

        token.transfer(address(this), amount);
    }
}