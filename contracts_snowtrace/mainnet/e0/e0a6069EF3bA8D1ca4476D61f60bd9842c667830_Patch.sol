/**
 *Submitted for verification at snowtrace.io on 2021-11-12
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

interface Jug
{
    function file(bytes32 ilk, bytes32 what, uint data) external;
    function drip(bytes32 ilk) external returns (uint rate);
}

// Deploy Patch contract and call plot/exec from the multisig
// tag = PATCH.soul(); // 
// fax = 0xc0406226; // run()
// eta = Math.floor(Date.now() / 1000) + 5 * 60;
// DSPause.plot(PATCH, tag, fax, eta)
// DSPause.exec(PATCH, tag, fax, eta)
contract Patch
{
    address constant MCD_JUG = 0xb2d474EAAB89DD0134B8A98a9AB38aC41a537c6C;

	function soul() external view returns (bytes32 _tag)
	{
		address _usr = address(this);
		assembly { _tag := extcodehash(_usr) }
	}

	// executed in the contact of the MCD_PAUSE_PROXY
	function run() external
	{
	    dripAndFileDuty("STKTDJAVAXJOE-A", 999999992924164415875054601); // -20
	    dripAndFileDuty("STKTDJAVAXWETH-A", 999999998037943815809569514); // -6
	    dripAndFileDuty("STKTDJAVAXWBTC-A", 999999998037943815809569514); // -6
	    dripAndFileDuty("STKTDJAVAXDAI-A", 999999997355986547376005547); // -8
	    dripAndFileDuty("STKTDJAVAXUSDC-A", 999999997355986547376005547); // -8
	    dripAndFileDuty("STKTDJAVAXUSDT-A", 999999997355986547376005547); // -8
	    dripAndFileDuty("STKTDJAVAXLINK-A", 999999998373500287307535928); // -5
	    dripAndFileDuty("STKTDJAVAXMIM-A", 999999997355986547376005547); // -8
    }

    function dripAndFileDuty(bytes32 name, uint value) internal
    {
	    uint rate = Jug(MCD_JUG).drip(name);
	    Jug(MCD_JUG).file(name, "duty", value);
        emit Rate(name, rate);        
    }

    event Rate(bytes32 indexed name, uint rate);
}