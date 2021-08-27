/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractHandshake
{
    address[] private signers;
    mapping(address=>bool) private signatures;

    string private agreement;

    event Signature (address _signer);

    constructor (
        address[] memory _signers,
        string memory _agreement
    ) {
        signers = _signers;
        agreement = _agreement;
    }

    function sign(
    ) external {
        if (signatures[msg.sender]) {
            revert("User already signed");
        }

        for(uint index = 0; index < signers.length; index++){
            if(signers[index]==msg.sender){
                signatures[msg.sender] = true;
                emit Signature(msg.sender);
                return;
            }
        }
        revert("Can only be called by whitelisted signers");
    }

    function hasSigned(address _signer) external view returns (bool) {
        return signatures[_signer];
    }

    function _signatureCount() internal view returns (uint) {
        uint _count = 0;
        for(uint index = 0; index < signers.length; index++){
            if(signatures[signers[index]]){
                _count++;
            }
        }
        return _count;
    }

    function allPartiesHaveSigned() external view returns (bool) {
        return _signatureCount() == signers.length;
    }

    function signatureCount() external view returns (uint) {
        return _signatureCount();
    }

    function getAgreement() external view returns (string memory) {
        return agreement;
    }

}