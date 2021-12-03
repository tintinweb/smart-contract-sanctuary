/**
 *Submitted for verification at snowtrace.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

contract GovTransferToChief
{
    address constant MCD_GOV_ACTIONS = 0xEC2EbC6e5C53Def0bc3AF8d612bC75972CA401E8;
    address constant MCD_PAUSE = 0x194964F933be66736c55E672239b2A3c07B564BB;
    address constant MCD_ADM = 0x86fCF1b49372d98fA275cA916D6c1a08fE05A125;

    function params() public view returns (address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta)
    {
        return params(MCD_GOV_ACTIONS, MCD_PAUSE, MCD_ADM, 86400);
    }

    function params(address _actions, address _pause, address _auth, uint256 _delay) public view returns (address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta)
    {
        _usr = _actions;
        _tag = soul(_actions);
        _fax = abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", _pause, _auth, _delay);
        _eta = block.timestamp + 5 minutes;
    }

    function soul(address _contract) public view returns (bytes32 _tag)
    {
        assembly { _tag := extcodehash(_contract) }
    }
}