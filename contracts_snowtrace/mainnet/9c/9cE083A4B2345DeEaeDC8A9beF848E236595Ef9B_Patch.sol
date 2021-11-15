/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

interface DssPsm
{
    function donor(address usr, bool flag) external;
}

// Deploy Patch contract and call plot/exec from the multisig
// tag = PATCH.soul(); // 0xa38ca46b144ae33993b6144595428e760a61cee1d0ff13ff4654a822e55d8ffd
// fax = 0xc0406226; // run()
// eta = Math.floor(Date.now() / 1000) + 5 * 60;
// DSPause.plot(PATCH, tag, fax, eta)
// DSPause.exec(PATCH, tag, fax, eta)
contract Patch
{
    address constant MCD_PSM_STKUSDC_A = 0xd86f2618e32235969EA700FE605ACF0fb10129e3;
	address constant MULTISIG = 0x1d64CeAF2cDBC9b6d41eB0f2f7CDA8F04c47d1Ac;
	address constant PSM_INJECTOR = 0x5622C4A8F6B245aFdddA6c32748055837A2616Cc;

	function soul() external view returns (bytes32 _tag)
	{
		address _usr = address(this);
		assembly { _tag := extcodehash(_usr) }
	}

	// executed in the contact of the MCD_PAUSE_PROXY
	function run() external
	{
        DssPsm(MCD_PSM_STKUSDC_A).donor(MULTISIG, true);
        DssPsm(MCD_PSM_STKUSDC_A).donor(PSM_INJECTOR, true);
	}
}