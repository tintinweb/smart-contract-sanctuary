// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import "./Multisig.sol"; 

/// @notice Creates a multisig wallet
contract GenerateMultisig {
    event MultisigGeneration(address multisigAddress, address founder);

    //
    // Consider adding a constructor here to initilize the contract
    //

    uint8 m;  
    uint8 n;
    uint256 groupCounter;
    address[] allGroups; // tmp variable for testing - to be removed 

    function generateMultisig(
        address[] memory members_, 
        uint8 m_, 
        uint8 n_ 
    ) public {
        Multisig ms = new Multisig(members_, m_, n_);
        allGroups.push(address(ms));
        emit MultisigGeneration(address(ms), msg.sender);
    }

    function getAllGroups() 
        public view virtual returns (address[] memory groups) {
            groups = allGroups;
        }

    // function sign(uint256 proposal) public virtual {
    //     if (!signer[msg.sender]) revert NotSigner();
    //     if (signed[proposal][msg.sender]) revert Signed();
        
    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         proposals[proposal].sigs++;
    //     }

    //     signed[proposal][msg.sender] = true;

    //     emit Sign(msg.sender, proposal);
    // }

    // function execute(uint256 proposal) public virtual {
    //     Proposal storage prop = proposals[proposal];

    //     if (prop.sigs < sigsRequired) revert InsufficientSigs();

    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         for (uint256 i; i < prop.targets.length; i++) {
    //             (bool success, ) = prop.targets[i].call{value: prop.values[i]}(prop.payloads[i]);

    //             if (!success) revert ExecuteFailed();
    //         }
    //     }

    //     delete proposals[proposal];

    //     emit Execute(proposal);
    // }
}