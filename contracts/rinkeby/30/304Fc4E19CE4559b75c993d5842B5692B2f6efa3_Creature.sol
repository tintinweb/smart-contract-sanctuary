// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
// contract Creature is ERC721Tradable {
//     constructor(address _proxyRegistryAddress)
//         ERC721Tradable("Poker Card", "POKER", _proxyRegistryAddress)
//     {}

contract Creature {
    // function baseTokenURI() override public pure returns (string memory) {
    //     return "http://54.226.30.196:4001/";
    // }

    bytes12 _tokenPayloadHash = '0x622b109227';

    function sliceBytes32To12(bytes32 inputBytes32) public pure returns (bytes12) {
        bytes12 output;
        assembly {
            for { let i := 0 } lt(i, 12) { i := add(i, 1) } { 
                output := add(output, byte(i, inputBytes32))
            }
        }
        return output;
    }

    function compareHash(string memory _tokenPayload) public view returns (string memory) {
        require(_tokenPayloadHash == sliceBytes32To12(keccak256(abi.encodePacked(_tokenPayload))), "not match");
        return "it is match!";
    }

    // string[] private _var1 = ["bc36789e7a","5fe7f977e7","f2ee15ea63","69c322e324","f343681465","dbb8d0f4c4","d0591206d9","ee2a4bc7db","d33e25809f","b2e7b7a21d","0ef9d8f880","60811857dd","4de0e96b0a","df829f8d49","7d74985e98","3d725c5ee5","967f2a2c7f","0552ab8dc5","5fa2358263","62af204a12","582aa85ad5","e9c02e9324","31072443cd","3d5dca32b0","f1ad5ac184","d13bb74f59","448f3cc8e0","24d6d73414","5e72dd4b52","b4b59f5ed2","eb675fc4bb","b1e3dca14f","681afa780d","3275a893b2","6e9f33448a","ace738c680","b104e6a8e5","43b2f7df8a","88a0fd9b2e","a111f47c43","484bf06f31","59d76dc3b3","04994f67dc","728b8dbbe7","3e7a35b970","d3b8281179","6f010af653","fba9715e47","044852b2a6","c89efdaa54","ad7c5bef02","2a80e1ef1d","13600b2941","ceebf77a83","e455bf8ea6","52f1a9b320","e4b1702d92","d2f8f61201","96d280011b","698f551e2a","8cb938a03d","f30c17f6c2","eff31f7855","5f179612d7","e724d40619","03783fac2e","1f675bff07","017e667f4b","6c3fd336b4","434b529473","e61d9a3d38","077da99d80","321c2cb0b0","8d61ecf6e1","90174c907f","91cb023ee0","8aa64f9370","7d61fdc86c","7c1e3133c5","c669aa98d5","7b2ab94bb7","fbf3cc6079","ef22bddd35","a9463b19d1","846b7b6deb","37bf2238b1","f0da850a6b","d2ec75cd00","550c64a150","9a2c5f9025","7d54a4ab60","9f50164828","731553fa98","b36bcf9cc1","d44aaa07e7","cd5edcba19","15a5de5d00","3ac225168d","b5553de315","0b42b6393c","f1918e8562","a8982c89d8","d1e8aeb795","14bcc435f4","a766932420","ea00237ef1","b31d742db5","f3d0adcb6a","6a0d259bd4","daba8c9843","4b4ecedb49","53a63b3ee4","2304e88f14","3ff269d376","414f72a4d5","60a73bfb12","cac1bb71f0","32cefdcd8e","a147871e98","01544badb2","7521d1cadb","83847cf31c","41e406698d","a91eddf639","f2736824a8","8e2ffa389f","a28a3f816f","5c179d3bfd","56e81f171b","1fed454f35","40e5b3ba79","cb17308d2a","cf50d641d7","22bd73c565","f01d372333","8c4e6ea42b","2d5de254dd","75dd4ce358","aa3fbc3e20","72349b72e9","36329cec8f","848cb72935","90c6b05600","0999795215","632315f5af","42c246a07c","313b2ea16b","2a78022ed0","9baa261c44","0f040e7390","99e4441ece","9e469b76a9","55ea88488b","897be06efb","f3224e9d7f","01474cfb7e","26ce63779c","b025b6a0ce","d32e767109","aea4fe7baf","fec18a9ddb","5581188931","5817a81728","9823c8dbb4","cb772e5c8f","644826e221","bc2cd47721","526fc8876e","3b644ef6f9","6c2e99637a","db81b4d585","468fc9c005","f7c2d8da7d","ec97e60fc3","65771ea6a6","f20a63a388","7309e659d3","6d073e12ab","6607382f6b","9dd2aee16b","d98227c7cf","1ea2933c42","00ecaf5ef2","5c2af9f8d7","e3f06c28b2","d961e7ee95","24e03926e2","9f1a1ebcae","61a9fef1bb","5a502f9fca","b98072845f","c027f87993","1dcc4de8de","2fe692f71c","7a5910a171","34b984bb8a","5f49d009d2","15bf36ff63","efae5b6ed4","671721786e","8b73219eaa","763a7e0ee7","e69f030215","6a076a720f","eead6dbfc7","115af72b77","3e60233d93","6463b0fdb4","0436957063","6ed3caa073","9ad263ae43","0b6a3d674c","d73fe508d9","7d8db9357f","dd23d0077c","8288a3cb94","440137efca","21e28bf11c","90b3da6407","123e7b7747","d1023f33bb","5302ff4014","aca4fee525","5e2aa544f4","9ce0cd77a6","f8a07a9dbe","c5ddba4a75","8410a52f97","4bbffc5b55","649a9ee4af","e2841c86ef","1e591f1c32","e61dbbe1d6","dc046d7585","2f20677459","27b23994a3","42990e245f","80074f25b0","7b0320bbb2","309b8896ee","e1a2e60e5e","d68811ac92","adeb8d94cb","2282254a46","8d93ac3615","3a394ed7c7","9b131f2e38","3213dd3dcd","8c38045bca","81ab3f47ed","1253499b3e","fa413b2b66","13a109c328","d03d757462","bcc90f2d6d","8b1a944cf1","628bf35967","4535a04e92","22ae6da6b4","e79122d721","2537f365db","dd4faffbe3","c827597a52","049c31cd40","5bac4ba02f","2742d5da45","cde0d57eaf","c858a54dce","3b54e21ac6","2ae0402972","4165a5774b","40d387eb78","bb3d3c553c","d15ec070eb","d550e36ad4","b3a57d97a7","682a85fe5e","a46ce7fb70","f713770ebf","897d2c8417","d08b1a67f2","910095ab05","4b7874a876","c8cd8ab87b","60802314f1","807c155a2f","15ff382c49","5a4aa512ff","11cb238fc9","52c0af2c97","525eac3646","667d361127","33bc2302bd","38cdb015bd","4cda07b6f8","57b83af9ff","e8158340c3","93de16e326","c404ccde16","0b680a5cc5","b7129957e0","77a9d42bda","64d0423c67","0be9424f40","41af536157","332b39cf64","78de04dcdd","f05cbb4514","77abd96770","12b89784ef","1728f9965a","cd415644e2","823896f065","407ee25700","6cb7aae81d","b3382caafb","2c9084f2e3","2acbc16d6b","5a07f22db0","0deea959f7","d75248f3d0","91d2ee71fb","0487d84203","df7c7e768b","6b787ac27f","5b21edc691","7ddcaaa6e2","36a8b3f4d5","a6a2465535","8c1ea5a51d","b7e1aa46e0","e4d68934c1","c0dbf2f8f0","0e1f2f50c7","84c0bf3205","dab3bf2483","eb8bb404c1","4c59d2aa86","c00c179418","5760916889","c59092486c","3e9f50ae5b","e0250271ae","34ffa3b88f","1b69786406","80013429bd","1275a3e5ac","fea1c9fb11","fb6df1d131","3e087e543c","9aee7b8e77","e053d58ac7","3badf1fb63","851ad2ccdf","987043760e","94c01703d7","7377043cd4","7e69308e33","b4459f14f0","6cc3c5a211","f48cf5b9a5","c363c75b0c","3d41f4e814","d2f2c5a7a0","3fe139984d","aa94ab7edf","984e9a4332","5b27e4352d","65febb122d","21fd46d248","bc57df1b6e","62d03cb458","7c04a92576","5dde868aba","de38815199","77bf7f5965","43d5704d34","63e640d2d4","0dd7da589a","72bf4b6b56","2ec06017c0","2dc75766cc","a46973d9ca","4521a21333","b0afdd4d2b","5dda3d670e","385ca8aeef","9e28193e86","d2e07fa1f7","fbf95f0528","88ac0b5c6f","cb08ac09d0","e42e70e59f","0c3a3e2e4b","66e21274d1","089267f642","488d6c83fe","4df5c1ceba","6506201899","d57271531a","49e407913d","86f77f03ad","3aed7f0f02","03d67b17f0","67d9d29564","68a02f583b","2080b1a994","8a85b9bd97","b1724f0a9b","bd2317590d","ef0dc4c43f","00d6f3076f","e9e8816a2c","8b4f32a329","69e5b7ec32","98041bad8a"];
}

