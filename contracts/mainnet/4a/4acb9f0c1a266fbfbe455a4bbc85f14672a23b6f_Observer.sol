/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// File: contracts/interfaces/oracleInterface.sol

pragma solidity 0.6.12;

/**
 * @title BiFi's oracle interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface oracleInterface {
    function latestAnswer() external view returns (int256);
}

// File: contracts/SafeMath.sol

pragma solidity ^0.6.12;

// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

/**
 * @title BiFi's safe-math Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
library SafeMath {
  uint256 internal constant unifiedPoint = 10 ** 18;
	/******************** Safe Math********************/
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "a");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "s");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "d");
	}

	function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a* b;
		require((c / a) == b, "m");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "d");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "m");
	}
}

// File: contracts/observer/observer.sol

pragma solidity 0.6.12;

/**
 * @title Bifi's observer contract
 * @notice Implement business logic and manage handlers
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract Observer {
	using SafeMath for uint256;

	address payable public owner;
	mapping(address => bool) operators;
	bool public emergency = false;

	ChainInfo[] interchains;

	struct ChainInfo {
		uint256 chainDeposit;
		uint256 chainBorrow;
		uint256 globalRewardPerBlocks;

		uint256 weight;
		uint256 alphaRate;

		address priceOracleAddr;
	}

	modifier onlyOwner {
		require(msg.sender == owner, "onlyOwner");
		_;
	}

	modifier onlyOperators {
		address payable sender = msg.sender;
		require(operators[sender] || sender == owner, "onlyOperators");
		_;
	}

	constructor() public {
		address payable sender = msg.sender;
		owner = sender;
		operators[sender] = true;
	}

	function ownershipTransfer(address payable _owner) onlyOwner external returns (bool) {
		owner = _owner;
		return true;
	}

	function setOperator(address payable addr, bool flag) onlyOwner external returns (bool) {
		operators[addr] = flag;
		return flag;
	}

	function getAlphaBaseAsset() external view returns (uint256[] memory) {
		ChainInfo[] memory chains = interchains;
		uint256[] memory alphBaseAsset = new uint256[](chains.length);
		for(uint256 i = 0; i < chains.length; i++) {
			ChainInfo memory chain = chains[i];
			alphBaseAsset[i] = chain.chainDeposit
			.unifiedMul( chain.alphaRate )
			.add(
				SafeMath.unifiedPoint
				.sub( chain.alphaRate )
				.unifiedMul( chain.chainBorrow )
			)
			.unifiedMul( uint256( oracleInterface(chain.priceOracleAddr).latestAnswer() ) )
			.unifiedMul( chain.weight );
		}
		return alphBaseAsset;
	}

	function updateChainMarketInfo(uint256 _idx, uint256 chainDeposit, uint256 chainBorrow) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.chainDeposit = chainDeposit;
		chain.chainBorrow = chainBorrow;

		interchains[_idx] = chain;
		return true;
	}

	function newChainInfo(
		uint256 chainDeposit,
		uint256 chainBorrow,

		uint256 weight,
		uint256 alphaRate,

		address priceOracleAddr
	) external onlyOperators returns (bool) {
		ChainInfo memory chain;
		chain.chainDeposit = chainDeposit;
		chain.chainBorrow = chainBorrow;

		chain.weight = weight;
		chain.alphaRate = alphaRate;

		chain.priceOracleAddr = priceOracleAddr;

		interchains.push(chain);
		return true;
	}

	function updateChainInfo(
		uint256 _idx,
		uint256 chainDeposit,
		uint256 chainBorrow,

		uint256 weight,
		uint256 alphaRate,

		address priceOracleAddr
	) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];
		chain.chainDeposit = chainDeposit;
		chain.chainBorrow = chainBorrow;

		chain.weight = weight;
		chain.alphaRate = alphaRate;

		chain.priceOracleAddr = priceOracleAddr;

		interchains[_idx] = chain;
		return true;
	}

	function getChainLength() external view returns (uint256) {
		return interchains.length;
	}

	function getChainInfo(
		uint256 _idx
	) external view returns (uint256, uint256, uint256, uint256, uint256, address) {

		ChainInfo memory chain = interchains[_idx];

		return (
			chain.chainDeposit,
			chain.chainBorrow,

			chain.globalRewardPerBlocks,

			chain.weight,
			chain.alphaRate,

			chain.priceOracleAddr
		);
	}

	function setChainDeposit(uint256 _idx, uint256 deposit) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.chainDeposit = deposit;

		interchains[_idx] = chain;
		return true;
	}

	function setChainBorrow(uint256 _idx, uint256 borrow) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.chainBorrow = borrow;

		interchains[_idx] = chain;
		return true;
	}

	function setChainGlobalRewardPerblock(uint256 _idx, uint256 globalRewardPerBlocks) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.globalRewardPerBlocks = globalRewardPerBlocks;

		interchains[_idx] = chain;
		return true;
	}

	function setChainWeight(uint256 _idx, uint256 weight) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.weight = weight;

		interchains[_idx] = chain;
		return true;
	}

	function setChainAlphaRate(uint256 _idx, uint256 alphaRate) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.alphaRate = alphaRate;

		interchains[_idx] = chain;
		return true;
	}

	function setChainPriceOracleAddr(uint256 _idx, address priceOracleAddr) external onlyOperators returns (bool) {
		ChainInfo memory chain = interchains[_idx];

		chain.priceOracleAddr = priceOracleAddr;

		interchains[_idx] = chain;
		return true;
	}
}