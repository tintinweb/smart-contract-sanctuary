// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
// TODO define a solutions struct that can hold an index & an address
// TODO define an array of the above struct
// TODO define a mapping to store unique solutions submitted
// TODO Create an event to emit when a solution is added
// TODO Create a function to add the solutions to the array and emit the event
// TODO Create a function to mint new NFT only after the solution has been verified
//  - make sure the solution is unique (has not been used before)
//  - make sure you handle metadata as well as tokenSuplly

import "./ERC721MintableComplete.sol";
import "./IVerifier.sol";

contract SolnSquareVerifier is ERC721MintableComplete {
    event SolutionSubmitted(uint256 index, address solutionOwner);

    struct Solution {
        uint256 index;
        address solutionOwner;
        bool isMinted;
    }

    mapping(uint256 => Solution) mapSolutions;

    Solution[] solutions;

    IVerifier private verifier;

    constructor(address squareVerifier) {
        verifier = IVerifier(squareVerifier);
    }

    function addSolution(
        address to,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory inputs
    ) external onlyOwner {
        IVerifier.Proof memory proof = _createtProofObject(a, b, c);
        require(
            verifier.verifyTx(proof, inputs),
            "Proof arguments and input provided can not be verified"
        );
        uint256 key = _getInputsKey(inputs);
        require(
            mapSolutions[key].index == 0,
            "This solution was already added"
        );
        require(
            !mapSolutions[key].isMinted,
            "This solution was already used to mint a token"
        );

        mapSolutions[key].index = key;
        mapSolutions[key].solutionOwner = to;
        mapSolutions[key].isMinted = false;

        solutions.push(mapSolutions[key]);

        emit SolutionSubmitted(
            mapSolutions[key].index,
            mapSolutions[key].solutionOwner
        );
    }

    function mintOwnershipProvedToken(
        address to,
        uint256 tokenId,
        uint256[2] memory inputs
    ) external onlyOwner {
        uint256 key = _getInputsKey(inputs);
        require(
            mapSolutions[key].index == key,
            "Proof arguments and input provided can not be verified"
        );
        require(
            !mapSolutions[key].isMinted,
            "This solution was already used before"
        );
        require(
            mapSolutions[key].solutionOwner == to,
            "The to/owner provided is different than wehn addSolution"
        );

        mapSolutions[key].isMinted = true;

        super.mint(to, tokenId); // emits Transfer
    }

    function _createtProofObject(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) private pure returns (IVerifier.Proof memory) {
        Pairing.G1Point memory point_a = Pairing.G1Point({X: a[0], Y: a[1]});
        Pairing.G2Point memory point_b = Pairing.G2Point({X: b[0], Y: b[1]});
        Pairing.G1Point memory point_c = Pairing.G1Point({X: c[0], Y: c[1]});
        IVerifier.Proof memory proof = IVerifier.Proof({
            a: point_a,
            b: point_b,
            c: point_c
        });
        return proof;
    }

    function _getInputsKey(uint256[2] memory inputs)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(inputs)));
    }
}