/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: true

pragma solidity >=0.8.0;


// 
contract Factory {

	// Kovan
	address private constant owner  = 0x67F6e2A7139979AF993aC0E4745b67d91c308317;
	address private constant bVaultAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
	bytes32 private constant bPoolMainId = 0x3a19030ed746bd1c3f2b0f996ff9479af04c5f0a000200000000000000000004; // USDC - WETH
	address private constant bPoolMainAddress = 0x3A19030Ed746bD1C3f2B0f996FF9479aF04C5F0A;

	bytes32 private constant bPoolOneId = 0x61d5dc44849c9c87b0856a2a311536205c96c7fd000200000000000000000000; // BAL-WEHT
	bytes32 private constant bPoolTwoId = 0x3a19030ed746bd1c3f2b0f996ff9479af04c5f0a000200000000000000000004; // USDC - WETH
	address private constant bIntermediateTokenAddress = 0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1; // WETH

	address private constant usdcAddress = 0xc2569dd7d0fd715B054fBf16E75B001E5c0C1115;
	uint8 private constant usdcDecimals = 6;
	address private constant balAddress = 0x41286Bb1D3E870f3F750eB7E1C25d7E48c8A1Ac7;

	address private constant emFeeAddress = 0x67F6e2A7139979AF993aC0E4745b67d91c308317;

	uint64 private constant epFeeCoefficient = 10000;
	uint64 private constant epLossCoefficient = 500000;
	uint64 private constant epProfitCoefficient = 800000;
	uint64 private constant epHoldDays = 1;
	struct Params {
		uint64 feeCoefficient;			// Fee from profit coefficient in ppm cannot be higher 20 000 (2%)
		uint64 lossCoefficient;			// Max loss coefficient contract will compensate to user in ppm, cannot be lower 100 000 (10%)
		uint64 profitCoefficient;		// Max profit coefficient contract will pay to user in ppm, cannot be lower 100 000 (10%)
		uint64 holdTime;						// Hold time for withdrawal in seconds
	}
	
	uint256 private constant vpCoefficient = 1500000;
	uint256 private constant vpsPeriodDays = 1;

	// function trap() external{
	// 	revert();
	// }

	function _deploy(bytes memory byteCode_, address targetAddress_) private
	{
			address addr;
			assembly {
				addr := create(0, add(byteCode_, 0x20), mload(byteCode_))
				if iszero(extcodesize(addr)) {
					revert(0, 0)
				}
			}
			require(addr == targetAddress_, "different address");
	}

	function deploy(
		bytes calldata elasticPoolBytecode_, address elasticPoolAddress_,
		bytes calldata volatilePoolBytecode_, address volatilePoolAddress_,
		bytes calldata reservePoolBytecode_, address reservePoolAddress_,
		bytes calldata vpStorageBytecode_, address vpStorageAddress_) 
		external

	{
		bytes memory _bytecode;
		bytes memory _params = abi.encode(
			owner, 
			usdcDecimals, 
			usdcAddress, 
			bVaultAddress,
			bPoolMainId,
			balAddress,
			emFeeAddress,
			reservePoolAddress_,
			vpStorageAddress_,
			Params(epFeeCoefficient, epLossCoefficient, epProfitCoefficient, epHoldDays)
		);
		_bytecode = abi.encodePacked(elasticPoolBytecode_, _params);
		_deploy(_bytecode, elasticPoolAddress_);

		_params = abi.encode(owner, usdcDecimals, usdcAddress, reservePoolAddress_, vpStorageAddress_, vpCoefficient);
		_bytecode = abi.encodePacked(volatilePoolBytecode_, _params);
		_deploy(_bytecode, volatilePoolAddress_);

		_params = abi.encode(usdcAddress, elasticPoolAddress_, volatilePoolAddress_);
		_bytecode = abi.encodePacked(reservePoolBytecode_, _params);
		_deploy(_bytecode, reservePoolAddress_);

		_params = abi.encode(usdcAddress, volatilePoolAddress_, vpsPeriodDays);
		_bytecode = abi.encodePacked(vpStorageBytecode_, _params);
		_deploy(_bytecode, vpStorageAddress_);

		(bool _success, ) = elasticPoolAddress_.call(
			abi.encodeWithSelector(
				bytes4(keccak256(bytes('initialize(bytes32,bytes32,address)'))), 
				bPoolOneId, bPoolTwoId, bIntermediateTokenAddress)
		);
		require(_success, 'elastic init failed');
		// selfdestruct(payable(msg.sender));
	}

}