// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract hashGenerator {

    /**
     * Each hash uses python hashLib to generate sha256 hash of each face of Mars Cube.
     * Resultant provenance hash is generated using keccak256 onchain.
     *
     * The order of the hash follows the naming order for tokenId. E,A,B,D,C,F. each face with 1024 plots.
     * token 0-1024 are in face E, the next 1024 face A, and so on.
     */

    string a = '7fdea2cc474b869ecb2282a7ecbf281aa83951ba921358d1eaef06ba49e1ce45';
    string b = '23eaf503065314271a4008e8eff08c543b3d2fa2eec15ec9629fe84b75e62232';
    string c = '5f1e04adb56035960c009b96d8651808ff5d91fb5ecc92634c3b1092ee7b5263';
    string d = '8ee7f810690e5e16dd7cb0b7ba2e4c6ef0350784a3662ea1a8a262cc94ae4124';
    string e = '62d39e9b5a2726cc0fdd44c6424b5af811e59e53441d28b2042c41c142ddaefc';
    string f = '1824f3f022aa2639052ba487215fc2837df18ccaad2e0382c58ceb85ac97d10a';

    function getHash() public view returns(bytes32) {
        return bytes32(
            keccak256(
                abi.encode(e,a,b,d,c,f)
                )
                );
    }
}

