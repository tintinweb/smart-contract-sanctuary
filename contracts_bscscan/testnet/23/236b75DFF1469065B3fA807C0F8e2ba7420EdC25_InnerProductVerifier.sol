// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

contract InnerProductVerifier {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    struct InnerProductStatement {
        Utils.G1Point[] hs; // "overridden" parameters.
        Utils.G1Point u;
        Utils.G1Point P;
    }

    struct InnerProductProof {
        Utils.G1Point[] L;
        Utils.G1Point[] R;
        uint256 a;
        uint256 b;
    }

    function verifyInnerProduct(Utils.G1Point[] memory hs, Utils.G1Point memory u, Utils.G1Point memory P, InnerProductProof memory proof, uint256 salt) public view returns (bool) {
        InnerProductStatement memory statement;
        statement.hs = hs;
        statement.u = u;
        statement.P = P;

        return verify(statement, proof, salt);
    }

    function gs(uint256 i) public pure returns (Utils.G1Point memory) {
        if (i == 0) return Utils.G1Point(0x0d1fff31f8dfb29333568b00628a0f92a752e8dee420dfede1be731810a807b9, 0x06c3001c74387dae9deddc75b76959ef5f98f1be48b0d9fc8ff6d7d76106b41b);
        if (i == 1) return Utils.G1Point(0x06e1b58cb1420e3d12020c5be2c4e48955efc64310ab10002164d0e2a767018e, 0x229facdebea78bd67f5b332bcdab7d692d0c4b18d77e92a8b3ffaee450c797c7);
        if (i == 2) return Utils.G1Point(0x22f32c65b43f3e770b793ea6e31c85d1aea2c41ea3204fc08a036004e5adef3a, 0x1d63e3737f864f05f62e2be0a6b7528b76cdabcda9703edc304c015480fb5543);
        if (i == 3) return Utils.G1Point(0x01df5e3e2818cfce850bd5d5f57872abc34b1315748e0280c4f0d3d6a40f94a9, 0x0d622581880ddba6a3911aa0df64f4fd816800c6dee483f07aa542a6e61534d5);
        if (i == 4) return Utils.G1Point(0x18d7f2117b1144f5035218384d817c6d1b4359497489a52bcf9d16c44624c1d0, 0x115f00d2f27917b5a3e8e6754451a4e990931516cf47e742949b8cbdda0e2c20);
        if (i == 5) return Utils.G1Point(0x093a9e9ba588d1b8eae48cf96b97def1fb8dccd519678520314e96d289ad1d11, 0x0f94a152edd0254ece896bc7e56708ba623c1ed3a27e4fd4c449f8e98fee1b5e);
        if (i == 6) return Utils.G1Point(0x0a7e8bc3cecaff1d9ec3e7d9c1fab7b5397bd6b6739c99bfe4bcb21d08d25934, 0x18d0114fa64774f712044e9a05b818fea4734db2b91fc7f049e120ce01c096be);
        if (i == 7) return Utils.G1Point(0x2095c16aea6e127aa3394d0124b545a45323708ae1c227575270d99b9900673a, 0x24c5a6afc36ef443197217591e084cdd69820401447163b5ab5f015801551a03);
        if (i == 8) return Utils.G1Point(0x041ee7d5aa6e191ba063876fda64b87728fa3ed39531400118b83372cbb5af75, 0x2dc2abc7d618ae4e1522f90d294c23627b6bc4f60093e8f07a7cd3869dac9836);
        if (i == 9) return Utils.G1Point(0x16dc75831b780dc5806dd5b8973f57f2f4ce8ad2a6bb152fbd9ccb58534115b4, 0x17b434c3b65a2f754c99f7bacf2f20bdcd7517a38e5eb301d2d88fe7735ebc9c);
        if (i == 10) return Utils.G1Point(0x18f1393a76e0af102ffeb380787ed950dc35b04b0cc6de1a6d806d4007b30dba, 0x1d640e43bab253bf176b69dffdb3ffc02640c591c392f400596155c8c3f668ef);
        if (i == 11) return Utils.G1Point(0x2bf3f58b4c957a8ae697aa57eb3f7428527fcb0c7e8d099efae80b97bde600e0, 0x14072f8bfdbe285b203cd0a2ebc1aed9ad1de309794226aee63c89397b187abf);
        if (i == 12) return Utils.G1Point(0x028eb6852c2827302aeb09def685b57bef74ff1a3ff72eda972e32b9ea80c32f, 0x1ba2dfb85a585de4b8a189f7b764f87c6f8e06c10d68d4493fc469504888837d);
        if (i == 13) return Utils.G1Point(0x19003e6b8f14f3583435527eac51a460c705dc6a042a2b7dd56b4f598af50886, 0x10e755ac3373f769e7e092f9eca276d911cd31833e82c70b8af09787e2c02d20);
        if (i == 14) return Utils.G1Point(0x0d493d4d49aa1a4fdf3bc3ba6d969b3e203741b3d570dbc511dd3171baf96f85, 0x1d103731795bcc57ddb8514e0e232446bfd9834f6a8ae9ff5235330d2a9e5ffa);
        if (i == 15) return Utils.G1Point(0x0ce438e766aae8c59b4006ee1749f40370fe5ec9fe29edce6b98e945915db97f, 0x02dba20dff83b373d2b47282e08d2c7883254a56701f2dbeea7ccc167ffb49a5);
        if (i == 16) return Utils.G1Point(0x05092110319650610a94fa0f9d50536404ba526380fc31b99ce95fbc1423a26f, 0x18a40146a4e79c2830d6d6e56314c538b0da4a2a72b7533e63f7d0a7e5ab2d22);
        if (i == 17) return Utils.G1Point(0x25b9ad9c4235b0a2e9f1b2ed20a5ca63814e1fb0eb95540c6f4f163c1a9fc2bd, 0x0a726ff7b655ad45468bcfd2d77f8aa0786ff3012d4edb77b5118f863dcdcbc0);
        if (i == 18) return Utils.G1Point(0x291ff28fa0a9840e230de0f0da725900bd18ce31d2369ffc80abbc4a77c1aff3, 0x1ffed5e9dffcd885ac867e2279836a11225548a8c253c47efe24f7d95a4bdd61);
        if (i == 19) return Utils.G1Point(0x0a01c96340d6bb4c94e028a522f74bef899d8f9d1a6d0b0d832f83275efa68de, 0x119c6a17ecb14721ac9eb331abccf2748868855fae43392391c37037d1b150a1);
        if (i == 20) return Utils.G1Point(0x2c846ad384d3ea063001f34fd60f0b8dc12b3b3ab7a5757f1d394f19850d8309, 0x1ff69942134c51e7315ccf1431e66fb5f70c24148c668f4fbe3861fbe535e39c);
        if (i == 21) return Utils.G1Point(0x0dafb5ae6accb6048e6dbc52f455c262dd2876b565792d68189618a3e630ade0, 0x236e97c592c19a2f2244f2938021671045787501e5a4a26de3580628ce37eb3b);
        if (i == 22) return Utils.G1Point(0x10df3e10a8d613058eae3278e2c80c3366c482354260f501447d15797de7378a, 0x10b25f7e075c93203ceba523afc44e0d5cd9e45a60b6dc11d2034180c40a004d);
        if (i == 23) return Utils.G1Point(0x1437b718d075d54da65adccdd3b6f758a5b76a9e5c5c7a13bf897a92e23fcde2, 0x0f0b988d70298608d02c73c410dc8b8bb6b95f0dde0dedcd5ea5692f0c07f3ed);
        if (i == 24) return Utils.G1Point(0x2705c71a95661231956d10845933f43cd973f4626e3a31dbf6287e01a00beb70, 0x27d09bd21d44269e2e7c85e1555fd351698eca14686d5aa969cb08e33db6691b);
        if (i == 25) return Utils.G1Point(0x1614dabf48099c315f244f8763f4b99ca2cef559781bf55e8e4d912d952edb4a, 0x16bf2f8fb1021b47be88ceb6fce08bf3b3a17026509cf9756c1a3fbf3b9d70bd);
        if (i == 26) return Utils.G1Point(0x21c448cfdcf007959812b2c5977cd4a808fa25408547e660c3fc12ed47501eb3, 0x14495c361cf9dc10222549bc258a76a20058f4795c2e65cd27f013c940b7dc7b);
        if (i == 27) return Utils.G1Point(0x1ac35f37ee0bfcb173d513ea7ac1daf5b46c6f70ce5f82a0396e7afac270ff35, 0x2f5f4480260b838ffcba9d34396fc116f75d1d5c24396ed4f7e01fd010ab9970);
        if (i == 28) return Utils.G1Point(0x0caaa12a18563703797d9be6ef74cbfb9e532cd027a1021f34ad337ce231e074, 0x2281c11389906c02bb15e995ffd6db136c3cdb4ec0829b88aec6db8dda05d5af);
        if (i == 29) return Utils.G1Point(0x1f3d91f1dfbbf01002a7e339ff6754b4ad2290493757475a062a75ec44bc3d50, 0x207b99884d9f7ca1e2f04457b90982ec6f8fb0a5b2ffd5b50d9cf4b2d850a920);
        if (i == 30) return Utils.G1Point(0x1fe58e4e4b1d155fb0a97dc9bae46f401edb2828dc4f96dafb86124cba424455, 0x01ad0a57feb7eeda4319a70ea56ded5e9fef71c78ff84413399d51f647d55113);
        if (i == 31) return Utils.G1Point(0x044e80195798557e870554d7025a8bc6b2ee9a05fa6ae016c3ab3b9e97af5769, 0x2c141a12135c4d14352fc60d851cdde147270f76405291b7c5d01da8f5dfed4d);
        if (i == 32) return Utils.G1Point(0x2883d31d84e605c858cf52260183f09d18bd55dc330f8bf12785e7a2563f8da4, 0x0e681e5c997f0bb609af7a95f920f23c4be78ded534832b514510518ede888b2);
        if (i == 33) return Utils.G1Point(0x2cdf5738c2690b263dfdc2b4235620d781bbff534d3363c4f3cfe5d1c67767c1, 0x15f4fb05e5facfd1988d61fd174a14b20e1dbe6ac37946e1527261be8742f5cf);
        if (i == 34) return Utils.G1Point(0x05542337765c24871e053bb8ec4e1baaca722f58b834426431c6d773788e9c66, 0x00e64d379c28d138d394f2cf9f0cc0b5a71e93a055bad23a2c6de74b217f3fac);
        if (i == 35) return Utils.G1Point(0x2efe9c1359531adb8a104242559a320593803c89a6ff0c6c493d7da5832603ab, 0x295898b3b86cf9e09e99d7f80e539078d3b5455bba60a5aa138b2995b75f0409);
        if (i == 36) return Utils.G1Point(0x2a3740ca39e35d23a5107fdae38209eaebdcd70ae740c873caf8b0b64d92db31, 0x05bab66121bccf807b1f776dc487057a5adf5f5791019996a2b7a2dbe1488797);
        if (i == 37) return Utils.G1Point(0x11ef5ef35b895540be39974ac6ad6697ef4337377f06092b6a668062bf0d8019, 0x1a42e3b4b73119a4be1dde36a8eaf553e88717cecb3fdfdc65ed2e728fda0782);
        if (i == 38) return Utils.G1Point(0x245aac96c5353f38ae92c6c17120e123c223b7eaca134658ebf584a8580ec096, 0x25ec55531155156663f8ba825a78f41f158def7b9d082e80259958277369ed08);
        if (i == 39) return Utils.G1Point(0x0fb13a72db572b1727954bb77d014894e972d7872678200a088febe8bd949986, 0x151af2ae374e02dec2b8c5dbde722ae7838d70ab4fd0857597b616a96a1db57c);
        if (i == 40) return Utils.G1Point(0x155fa64e4c8bf5f5aa53c1f5e44d961f688132c8545323d3bdc6c43a83220f89, 0x188507b59213816846bc9c763a93b52fb7ae8e8c8cc7549ce3358728415338a4);
        if (i == 41) return Utils.G1Point(0x28631525d5192140fd4fb04efbad8dcfddd5b8d0f5dc54442e5530989ef5b7fe, 0x0ad3a3d4845b4bc6a92563e72db2bc836168a295c56987c7bb1eea131a3760ac);
        if (i == 42) return Utils.G1Point(0x043b2963b1c5af8e2e77dfb89db7a0d907a40180929f3fd630a4a37811030b6d, 0x0721a4b292b41a3d948237bf076aabeedba377c43a10f78f368042ad155a3c91);
        if (i == 43) return Utils.G1Point(0x14bfb894e332921cf925f726f7c242a70dbd9366b68b50e14b618a86ecd45bd6, 0x09b1c50016fff7018a9483ce00b8ec3b6a0df36db21ae3b8282ca0b4be2e283c);
        if (i == 44) return Utils.G1Point(0x2758e65c03fdb27e58eb300bde8ada18372aa268b393ad5414e4db097ce9492d, 0x041f685536314ddd11441a3d7e01157f7ea7e474aae449dbba70c2edc70cd573);
        if (i == 45) return Utils.G1Point(0x191365dba9df566e0e6403fb9bcd6847c0964ea516c403fd88543a6a9b3fa1f2, 0x0ae815170115c7ce78323cbd9399735847552b379c2651af6fc29184e95eef7f);
        if (i == 46) return Utils.G1Point(0x027a2a874ba2ab278be899fe96528b6d39f9d090ef4511e68a3e4979bc18a526, 0x2272820981fe8a9f0f7c4910dd601cea6dd7045aa4d91843d3cf2afa959fbe68);
        if (i == 47) return Utils.G1Point(0x13feec071e0834433193b7be17ce48dec58d7610865d9876a08f91ea79c7e28d, 0x26325544133c7ec915c317ac358273eb2bf2e6b6119922d7f0ab0727e5eb9e64);
        if (i == 48) return Utils.G1Point(0x08e6096c8425c13b79e6fa38dffcc92c930d1d0bff9671303dbc0445e73c77bc, 0x03e884c8dc85f0d80baf968ae0516c1a7927808f83b4615665c67c59389db606);
        if (i == 49) return Utils.G1Point(0x1217ff3c630396cd92aa13aa6fee99880afc00f47162625274090278f09cbed3, 0x270b44f96accb061e9cad4a3341d72986677ed56157f3ba02520fdf484bb740d);
        if (i == 50) return Utils.G1Point(0x239128d2e007217328aae4e510c3d9fe1a3ef2b23212dfaf6f2dcb75ef08ed04, 0x2d5495372c759fdba858b7f6fa89a948eb4fd277bae9aebf9785c86ea3f9c07d);
        if (i == 51) return Utils.G1Point(0x305747313ea4d7d17bd14b69527094fa79bdc05c3cc837a668a97eb81cffd3d4, 0x0aa43bd7ad9090012e12f78ac3cb416903c2e1aabb61161ca261892465b3555d);
        if (i == 52) return Utils.G1Point(0x267742bd96caad20a76073d5060085103b7d29c88f0a0d842ef610472a1764ef, 0x0086485faeedd1ea8f6595b2edaf5f99044864271a178bd33e6d5b73b6d240a0);
        if (i == 53) return Utils.G1Point(0x00aed2e1ac448b854a44c7aa43cabb93d92316460c8f5eacb038f4cf554dfa01, 0x1b2ec095d370b234214a0c68fdfe8da1e06cbfdc5e889e2337ccb28c49089fcf);
        if (i == 54) return Utils.G1Point(0x06f37ac505236b2ed8c520ea36b0448229eb2f2536465b14e6e115dc810c6e39, 0x174db60e92b421e4d59c81e2c0666f7081067255c8e0d775e085278f34663490);
        if (i == 55) return Utils.G1Point(0x2af094e58a7961c4a1dba0685d8b01dacbb01f0fc0e7a648085a38aa380a7ab6, 0x108ade796501042dab10a83d878cf1deccf74e05edc92460b056d31f3e39fd53);
        if (i == 56) return Utils.G1Point(0x051ec23f1166a446caa4c8ff443470e98e753697fcceb4fbe5a49bf7a2db7199, 0x00f938707bf367e519d0c5efcdb61cc5a606901c0fbd4565abeeb5d020081d96);
        if (i == 57) return Utils.G1Point(0x1132459cf7287884b102467a71fad0992f1486178f7385ef159277b6e800239d, 0x257fedb1e126363af3fb3a80a4ad850d43041d64ef27cc5947730901f3019138);
        if (i == 58) return Utils.G1Point(0x14a571bbbb8d2a442855cde5fe6ed635d91668eded003d7698f9f744557887ea, 0x0f65f76e6fa6f6c7f765f947d905b015c3ad077219fc715c2ec40e37607c1041);
        if (i == 59) return Utils.G1Point(0x0e303c28b0649b95c624d01327a61fd144d29bfed6d3a1cf83216b45b78180cf, 0x229975c2e3aaba1d6203a5d94ea92605edb2af04f41e3783ec4e64755eeb1d1b);
        if (i == 60) return Utils.G1Point(0x05a62a2f1dfe368e81d9ae5fe150b9a57e0f85572194de27f48fec1c5f3b0dad, 0x200eb8097c91fe825adb0e3920e6bdff2e40114bd388298b85a0094a9a5bc654);
        if (i == 61) return Utils.G1Point(0x06545efc18dfc2f444e147c77ed572decd2b58d0668bbaaf0d31f1297cde6b99, 0x29ecbbeb81fe6c14279e9e46637ad286ba71e4c4e5da1416d8501e691f9e5bed);
        if (i == 62) return Utils.G1Point(0x045ce430f0713c29748e30d024cd703a5672633faebe1fd4d210b5af56a50e70, 0x0e3ec93722610f4599ffaac0db0c1b2bb446ff5aea5117710c271d1e64348844);
        if (i == 63) return Utils.G1Point(0x243de1ee802dd7a3ca9a991ec228fbbfb4973260f905b5106e5f738183d5cacd, 0x133d25bb8dc9f54932b9d6ee98e0432676f5278e9878967fbbd8f5dfc46df4f8);
    }

    function hs(uint256 i) public pure returns (Utils.G1Point memory) {
        if (i == 0) return Utils.G1Point(0x01d39aef1308fae84642befcdb6c07f655cc4d092f6a66f464cb9c959bff743a, 0x277420423ebed18174bd2730d4387b06c10958e564af6444333ac5b30767c59c);
        if (i == 1) return Utils.G1Point(0x2f1a6e72cf51c976df65f69457491bd852b4cf8a172183537dc413d0801bef0a, 0x0fc8845b156f86c3018d7a193c089c8d02ea38ba2cec11b1b6118a3b37f4cb08);
        if (i == 2) return Utils.G1Point(0x00f698cd9c34ea5fc62bd7d91c3a8b7f70bb12596d3c6d99b9be4d7acf2e72ea, 0x23abea6d9096d3c23f3aee1447570211efc5d2add2f310a2acaf3afc1faa0ed1);
        if (i == 3) return Utils.G1Point(0x06e93364d8080a84ab1dac7fa743b3f3f139f84c602cc67a899e3739abf11cc0, 0x2246590e06850a6f55b3e9bb81d7316fe7b08bef9f9a06d43b30226d626a979d);
        if (i == 4) return Utils.G1Point(0x1fb8f0bbb173c6d8f7ae2e1fa1e3770aa8c66fbed8d459d8e6fa972c990e0e22, 0x23d30ccd0b4747679bbd29620c3efb39ee1d7018b0281c448ad1501a5e04dc1a);
        if (i == 5) return Utils.G1Point(0x1b5f7c9fa9f3ef4adbed1f09bc6e151ba5e7c1d098c2d94e2dbe95897e6675cd, 0x23ff89ca0d326bd98629bf7ccf343ababdb330821a495b7624d8720fd1ead1e3);
        if (i == 6) return Utils.G1Point(0x2ffd2415cb4cd71a9f3cf4ed64d4a85d4d3eb06bfa10f98cb8a2ab7e2d96797c, 0x1d770c3d19238753457dd36280bd6685f6f214461a81aa95962f1c80a6c4168d);
        if (i == 7) return Utils.G1Point(0x2d344a9de673000e4108f8b6eb21b8cf39e223fad81cef47cd599b5e548a092b, 0x1abe37b046f84fa46b7629e432e298ae7dda657d2cdde851775431cab1d34402);
        if (i == 8) return Utils.G1Point(0x131bea29a212d81278492c44179c04f2a3f7e72151a0a4870b01e2fa96cdf84a, 0x0e5a783a7d6e044761fa10b801de33a1c4de8d4569f132b86a5be6aa13726127);
        if (i == 9) return Utils.G1Point(0x2e9de6196c9d4be4d765078245515d02b18ee6073ca0afb1afe98dcca2378d76, 0x1a5be81d26e9261e5072bb86f5cbd1dd8075316c8fec769ac839819a17ec3841);
        if (i == 10) return Utils.G1Point(0x21ccb04d241aa8108e9e5f2487fffe82debc69e4cff3a7ee292609fbe49cb6ad, 0x14d2e86d8bea6af2ad1cde303c9b2993a37c5b7bf0567278854ca666e61f2e80);
        if (i == 11) return Utils.G1Point(0x164314a3b09437cc1cd0f7726b8291be0bd293876093e51f989feab3238cfd85, 0x043bb4c392fbf35b9991d01ffaf6c59d7e72559ed7f338f85beebdf74ed3132f);
        if (i == 12) return Utils.G1Point(0x08a85c13ee191db8c043a21db38c016e27376d82063a93f8a6ff603b0f396433, 0x19be7f870a4bbd255c61ca01588bc3be2632c015753a3320309915e600d78a0a);
        if (i == 13) return Utils.G1Point(0x2090c3ab526ff54497f984b860682c77c0a89842f6612928cf4188c5c0f1ee20, 0x151a9c9fcdc438b3197d85ab51317d969d66e03fe26e05f6be466058cb8b7e65);
        if (i == 14) return Utils.G1Point(0x220b0c31ba1c84a2c1235d987e79d8fb1854fb59cce44719a13e4b83331da63b, 0x19a161498b4d63a027670174b424260b2180ccb02e05e4e061363ac3a87642da);
        if (i == 15) return Utils.G1Point(0x018eb881dd184f8abff3b91b50676a12945e205f200fdaf25ffb7e8c97385334, 0x1dea48b102351f75ce4977a6c3c908455a9e269aab69c3f66e642791052d0cfb);
        if (i == 16) return Utils.G1Point(0x07b0183a2450ccb5a001554ac3fe1a763bb69a0222316c1a553124a915cd0720, 0x282216c8c2711780ed3b24281fdd358d0e3d2e05e9cd1ab6842432f818a4a40c);
        if (i == 17) return Utils.G1Point(0x2b3f257e1258a3c2bda28be60fdc4cf2a74a19bb17d61783a91ec478d379e1a5, 0x1a8ddf17a83d7b89a6c7ae59601b736c4c7022f29c74700bd5d51cbd70b5051d);
        if (i == 18) return Utils.G1Point(0x0485fd181e30eef43c4356c6cdfb8957267795c838e6e64c52fd81a697dd8505, 0x17105695b4bfc555a55c8449182a6335584f971a0058172bd2b5441db3129843);
        if (i == 19) return Utils.G1Point(0x2008a80d7c60d7dc6e069b174efd31984a0933da7f89a574aae52e8805b40095, 0x052398552fb4706758b6eafb50bed493568670961058586735bca016e875e6ef);
        if (i == 20) return Utils.G1Point(0x119ff93e1bce3d5c7c57d1fea845e9335e04c729ec7a62ca2283d6c5dc0acc7c, 0x2042b68991a4d4c959df76947ef2594afb6735d760c3629825db8451b4830a3c);
        if (i == 21) return Utils.G1Point(0x0ed374dfa5daee92868812764c47ffd9c0c832abe09124f6f55283869d639eb7, 0x267767cb5017979990d9fa6db5f741de043afb70ee8a5e29045e926486f00858);
        if (i == 22) return Utils.G1Point(0x1c3786f37ee4f7eb9493551cea3c2a4e8ddcdd3c86e9f9ea2a41199efa1da476, 0x147d40e13345ec2f38975b09989d2c01954122796f83bfc19974ab647f754a32);
        if (i == 23) return Utils.G1Point(0x0040bf79ad3c473ffd4d7e15dbe0fa0a9b06e765a6d5adb372f98b8ea107f2c6, 0x17bf761b14f52da007532fcdf1bbdec180750af1b7b3804e29d6d45af62042f8);
        if (i == 24) return Utils.G1Point(0x01a9c26d59a9962250ce2b20b477884d11ce2c2404b749ceee59c51c2dcc0918, 0x1603d5448eb9b7528b247c0cdf8b0d9275322975bc7e4b13b8d0312cf032c467);
        if (i == 25) return Utils.G1Point(0x215ecf3e09641d5a38d4f510ed72e2ee586d4fbfc7e46411e1a3396f07b1e276, 0x28ece25edfb8c48631b861e838641f8e61e58afcf4e6c8f336c86fe5b7c0dfc9);
        if (i == 26) return Utils.G1Point(0x0beda6c3cbaec7226ed3bd6e0a27a626e0022b1afa820ac509e21b646f23dc60, 0x212f09e343da69ec34d90491282e69499c779973c0352126a38aabbf5783b288);
        if (i == 27) return Utils.G1Point(0x27f5c2199a6cebc34e3b5376b4db3ac6db08d2f302aa9b99f808e20a95e9ef8c, 0x0ccc4c0723e2a255e9b649eae9c16d72f4ddb97d088d7b3154c00e9a1dd94fe8);
        if (i == 28) return Utils.G1Point(0x2af5191d45c6ca76563c6f936f0cd2dcaa4311719675c2bb5f65d3df2270f636, 0x1252aca114b1fda7f43c06d1f2b60718e7bc99b8544138f9c67aad8dfca863d7);
        if (i == 29) return Utils.G1Point(0x13bdce5de7cf1c2250bac0be0d23d3be0140ce3838c8966ea2870e64b87adaee, 0x2f3770a6b5a9babcc5fa7cae8ffbb2a63ff312f2d3352e4fe8c173b12ff847e0);
        if (i == 30) return Utils.G1Point(0x18d1242b7bee604de29b4511814b02c8fd1519a4fc6daf9dbc95f8bb64ee097b, 0x0f828debef5bd4115c91f419718bdb59464bd8bb78fd0dc250d1efb1a51366df);
        if (i == 31) return Utils.G1Point(0x04b4102e8d3a2d3ba330257de8d18861db5652d685efb297d9c116eb1a7b1299, 0x08a3fd325f19ddebb53063d60fccdb8f0321fe41d4d93d98c65e05c9b4101aa0);
        if (i == 32) return Utils.G1Point(0x20f38c332b7117550a2462637fd38dfa08eb063e5bbc1838de2d8a933b052a5d, 0x0de3339a34e84bc8d57daf4fe55855a02df1c6fe4ce1cd07ca3060f67e1d75b2);
        if (i == 33) return Utils.G1Point(0x02f501714aa467e8b06ec808af8a3278f58faa7b87b678a1e36ee779adb01def, 0x1b8f1369d47a1d7b4da91b777bbcd7a2a4bde8ad09cc2eeeb9e8c0036ef5df47);
        if (i == 34) return Utils.G1Point(0x059c89b0e337c65e8132ac7c78f29d1a016edbff65da6663ef114f85bc414f20, 0x0b6e3d301ca62d0946299c6b79f2207479351ac27478901cdf5be144cf77435f);
        if (i == 35) return Utils.G1Point(0x02f51c34b66cd01304c185bcc087b9430beb0e6738e97491550740e18c262948, 0x27e42ced0bf3356a10e9685f1365a2ac3fdb3f3e89b9cd2f0309cd9ffcd6dfc0);
        if (i == 36) return Utils.G1Point(0x28c0affe0178e407e8196e3d0af3674aecc46a94342a97fec96d1eaa0e24ce3a, 0x1056737f11d45d9de7ff2d6de4ae31af9aa6a3ca2a0d56e5748059c7c39a02e7);
        if (i == 37) return Utils.G1Point(0x0100b2eb3ec56d3c557be418c4aabf0229ba4fb58c0bbb0756802e9f1573e245, 0x10a6e05da67b0cab1b2ded1f6e29f2c55279c738e18bbb91687fb046bac7789c);
        if (i == 38) return Utils.G1Point(0x0fe1fdb40a1c4b49772635241e37196fdca6a3cbd8ac2c550e1a48c90ec30029, 0x064ac2c20c146923131bab9ff316498a29fdce765a06c4a891f5b36993f52dba);
        if (i == 39) return Utils.G1Point(0x0c0aadc1d96e9b0b609e9f455c85ecf9506bbb7972f4adf58a3731f40cfd5d77, 0x1f3941c16c4c9da3c169c71abb9557d8b7b54d4b0998410d91d1b4a759f15028);
        if (i == 40) return Utils.G1Point(0x0a46308afef5a8af8f3b822aaa413d2961845a361f05cab5524144e74699cdec, 0x1035f4f2bf0b1ae6d0524d1309829c6d997cd7010650ca05a1bf585206e1aa3b);
        if (i == 41) return Utils.G1Point(0x1ccf854703b8608e10416032eaeadcc7ef236f2d1d33fec289d6db28db10b517, 0x1dbd7e3ed44a0fc339078bcb420b2641210a930a95eecc2aec0147a1abcbbb1a);
        if (i == 42) return Utils.G1Point(0x1408a19ef2793b8af811e95ffbdf901671a3b76bdc2203be5fde5475de4c54bc, 0x26431b0fbb7fb432a0edc0b247fee08d8f44a2abb0cb9b4b8a8a040bdea3cbf8);
        if (i == 43) return Utils.G1Point(0x2eb3aa4eb2234e4de8d30bcfeca595e758bc542da4ee111722fd6be47defd7e8, 0x1a7d7ab203974731e8f33dbbc7af481bbb64e47407e998d2d26dfa90a9dc321b);
        if (i == 44) return Utils.G1Point(0x1b6c0f4b954626f03f4fe59bc83ecc9ac2279d7d20746829583b66735cbb4830, 0x2eb200acc2138afec4e5f53438273760ca4d46bd0ebfa0155ae62a8055fee316);
        if (i == 45) return Utils.G1Point(0x0241820580d821b485c5d3f905cfc4a407881bbc7e041b4e50e2f628f88afc49, 0x2ee28fcaecd349babc91cb6fc9d65ed51dac6e2dd118898e3a0ee1bf0e94793d);
        if (i == 46) return Utils.G1Point(0x0b7b54391ce78ebf1aa3b4b2a75958f1702100aef8163810f89d0ad81c04ed78, 0x129075ea4b1ab58683019ab79340b2b090b9720721046332d8e0e80b2039406e);
        if (i == 47) return Utils.G1Point(0x18c8880c588c4dd3d657439a3357ff3bf0f44b9074d5d7aebb384fbac7e58090, 0x305de2ed95fe36ca48642098d98180b4ab92a03978fa6a038d80e546da989e6a);
        if (i == 48) return Utils.G1Point(0x00f185128b4341f79c914ef9739c830294df8da311891416babcc53e364ef245, 0x0a1ee67a755420fe0835770271142c883ebe3721140075a1677f2d57c6cec4b3);
        if (i == 49) return Utils.G1Point(0x2cf787f4957c6af6a6431d4a1577df0c71b6b44cca9771d8dee49ed83b024008, 0x25dfce7a0c6515b610f0b602d4083adfa436cbf1cce0e3dbec14338bee6ef501);
        if (i == 50) return Utils.G1Point(0x19934b0990d3b31864dcd3a9a7fe8ea20c87ef0abc3980c81035234b961b6c20, 0x2b8ca35cc74606b825937545131cb3c9248ec880b8df7c5eeac6d2be85aff646);
        if (i == 51) return Utils.G1Point(0x2adbdb8197cd82851b706df9c38a53950b1ba5953c8e7fcf3a037e4af817f706, 0x0cd2df6ffbde434614d0288d75ef6afd5d8f0c1b831d38b7de57785658b4bfe9);
        if (i == 52) return Utils.G1Point(0x1ee70de811fe6abb48823d75549e97bb81e3e98aea57e03b03164601b45a8889, 0x18ff1b711d742b30520fb8aeb174940d0e78ad926e0747cd3cf6cd9fdac1eb83);
        if (i == 53) return Utils.G1Point(0x2d831e2ba4c03354502c9ec8569eb4f1b7617b92e90e6bd2df617273793af02e, 0x1d838e04c75622032862a0ad64e997f99b64f9dce9dfd71b25214dc75371ef53);
        if (i == 54) return Utils.G1Point(0x0816128c1a69aacf266b28efd029bd12998f9abbfaa42c6b175d13452e81ec74, 0x084f00999de16016819beea6c19bade38d1802ac9ea2a59c70a94ab43676423f);
        if (i == 55) return Utils.G1Point(0x19fbf07d90fb1fc051cf76bc3ca6fb551463834456cac5a40a7e50dc492b6e07, 0x136cccfcd75ba252a946fc7e8d323ed9afdba4990600f97c8ea69ed72759c756);
        if (i == 56) return Utils.G1Point(0x2c0dca3a80d643d69ac2ccff2c16e727aa5eb81839a0b46e9b9f351941100e86, 0x0d90cee7e881d7484d76b29524af629358dc9795a2a789606fdec6d73e161435);
        if (i == 57) return Utils.G1Point(0x134b5d77b0c39945e9c8a7701bf5058183c5dc2010ab6ab6061243b2d748c4fa, 0x0d6297624431107091b2ccfc7c4f6964a14521ebecc4ca4687ad11ac439c9bc1);
        if (i == 58) return Utils.G1Point(0x1eff41015f3733fb8a295ff8a513d992d8723a159a294b5c444919ba22beb549, 0x0006941da956684261258a79a72fcf1b10e23e3f5844f808749fe10818cade97);
        if (i == 59) return Utils.G1Point(0x05d6227f2a9650a4b35412a9369f96155487d28e0f1827bce5fe2748e2b39c4f, 0x1640729260ba5f06592f23e8d2cf9b0a40ba5d090539b3d3f03e9a9bf8f6aad3);
        if (i == 60) return Utils.G1Point(0x166793ff28c5d31cf3c50fe736340af6cc6d6c80749bbcfd66db78ed80408e50, 0x2015c5c83fb2bb673aeb63e79928fa4c3a8ac6eb758b643e6bb9ff416ec6f3a5);
        if (i == 61) return Utils.G1Point(0x09ea2a4226678267f88c933e6f947fa16648a7710d169e715048e336d1b4129d, 0x26bb40f1b5f88a0a63acebd040aba0bbf85b03e04760bf5be723bd42d0f7d0ae);
        if (i == 62) return Utils.G1Point(0x0fe50825f829d35375a488cff7df34638241bce1a5b2f48c39635651e24c470d, 0x049b06661bb12c19ba643933a06d93035ecec6f53c61b8d4d2b39cc5c0459e68);
        if (i == 63) return Utils.G1Point(0x0b8871057f2a8bf0f794c099fba2481b9f39457d55d7e472e5dc994d69f0fbb8, 0x072c9e81fc2e118414a9fb6d9fff6e5b615f07fa980e3ce692a09bce95cc54f2);
    }

    struct IPAuxiliaries {
        uint256 o;
        uint256[] challenges;
        uint256[] s;
    }

    function verify(InnerProductStatement memory statement, InnerProductProof memory proof, uint256 salt) internal view returns (bool) {
        uint256 log_n = proof.L.length;
        uint256 n = 1 << log_n;

        IPAuxiliaries memory ipAuxiliaries; // for stacktoodeep
        ipAuxiliaries.o = salt; // could probably just access / overwrite the parameter directly.
        ipAuxiliaries.challenges = new uint256[](log_n);
        for (uint256 i = 0; i < log_n; i++) {
            ipAuxiliaries.o = uint256(keccak256(abi.encode(ipAuxiliaries.o, proof.L[i], proof.R[i]))).mod(); // overwrites
            ipAuxiliaries.challenges[i] = ipAuxiliaries.o;
            uint256 inverse = ipAuxiliaries.o.inv();
            statement.P = statement.P.add(proof.L[i].mul(ipAuxiliaries.o.mul(ipAuxiliaries.o)).add(proof.R[i].mul(inverse.mul(inverse))));
        }

        ipAuxiliaries.s = new uint256[](n);
        ipAuxiliaries.s[0] = 1;
        // credit to https://github.com/leanderdulac/BulletProofLib/blob/master/truffle/contracts/EfficientInnerProductVerifier.sol for the below block.
        // it is an unusual and clever variant of what we already do in ZetherVerifier.sol:234-249, but with the special property that it requires only 1 inversion.
        // indeed, that algorithm computes the same function as this, yet its use here would require log(N) modular inversions. inversions turn out to be expensive.
        // of course in that case don't have to invert, but rather to do x minus, etc., so in that case we might as well just use the simpler algorithm.
        for (uint256 i = 0; i < log_n; i++) ipAuxiliaries.s[0] = ipAuxiliaries.s[0].mul(ipAuxiliaries.challenges[i]);
        ipAuxiliaries.s[0] = ipAuxiliaries.s[0].inv(); // here.
        bool[] memory bitSet = new bool[](n);
        for (uint256 i = 0; i < n / 2; i++) {
            for (uint256 j = 0; (1 << j) + i < n; j++) {
                uint256 k = i + (1 << j);
                if (!bitSet[k]) {
                    ipAuxiliaries.s[k] = ipAuxiliaries.s[i].mul(ipAuxiliaries.challenges[log_n - 1 - j]).mul(ipAuxiliaries.challenges[log_n - 1 - j]);
                    bitSet[k] = true;
                }
            }
        }

        Utils.G1Point memory temp = statement.u.mul(proof.a.mul(proof.b));
        for (uint256 i = 0; i < n; i++) {
            temp = temp.add(gs(i).mul(ipAuxiliaries.s[i].mul(proof.a)));
            temp = temp.add(statement.hs[i].mul(ipAuxiliaries.s[n - 1 - i].mul(proof.b)));
        }
        require(temp.eq(statement.P), "Inner product equality check failure.");

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library Utils {

    uint256 constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        return addmod(x, y, GROUP_ORDER);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulmod(x, y, GROUP_ORDER);
    }

    function inv(uint256 x) internal view returns (uint256) {
        return exp(x, GROUP_ORDER - 2);
    }

    function mod(uint256 x) internal pure returns (uint256) {
        return x % GROUP_ORDER;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x - y : GROUP_ORDER - y + x;
    }

    function neg(uint256 x) internal pure returns (uint256) {
        return GROUP_ORDER - x;
    }

    function exp(uint256 base, uint256 exponent) internal view returns (uint256 output) {
        uint256 order = GROUP_ORDER;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), 0x20)
            mstore(add(m, 0x60), base)
            mstore(add(m, 0x80), exponent)
            mstore(add(m, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, m, 0xc0, m, 0x20)) { // staticcall or call?
                revert(0, 0)
            }
            output := mload(m)
        }
    }

    function fieldExp(uint256 base, uint256 exponent) internal view returns (uint256 output) { // warning: mod p, not q
        uint256 order = FIELD_ORDER;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), 0x20)
            mstore(add(m, 0x60), base)
            mstore(add(m, 0x80), exponent)
            mstore(add(m, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, m, 0xc0, m, 0x20)) { // staticcall or call?
                revert(0, 0)
            }
            output := mload(m)
        }
    }

    struct G1Point {
        bytes32 x;
        bytes32 y;
    }

    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        assembly {
            let m := mload(0x40)
            mstore(m, mload(p1))
            mstore(add(m, 0x20), mload(add(p1, 0x20)))
            mstore(add(m, 0x40), mload(p2))
            mstore(add(m, 0x60), mload(add(p2, 0x20)))
            if iszero(staticcall(gas(), 0x06, m, 0x80, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        assembly {
            let m := mload(0x40)
            mstore(m, mload(p))
            mstore(add(m, 0x20), mload(add(p, 0x20)))
            mstore(add(m, 0x40), s)
            if iszero(staticcall(gas(), 0x07, m, 0x60, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function neg(G1Point memory p) internal pure returns (G1Point memory) {
        return G1Point(p.x, bytes32(FIELD_ORDER - uint256(p.y))); // p.y should already be reduced mod P?
    }

    function eq(G1Point memory p1, G1Point memory p2) internal pure returns (bool) {
        return p1.x == p2.x && p1.y == p2.y;
    }

    function g() internal pure returns (G1Point memory) {
        return G1Point(0x077da99d806abd13c9f15ece5398525119d11e11e9836b2ee7d23f6159ad87d4, 0x01485efa927f2ad41bff567eec88f32fb0a0f706588b4e41a8d587d008b7f875);
    }

    function h() internal pure returns (G1Point memory) {
        return G1Point(0x01b7de3dcf359928dd19f643d54dc487478b68a5b2634f9f1903c9fb78331aef, 0x2bda7d3ae6a557c716477c108be0d0f94abc6c4dc6b1bd93caccbcceaaa71d6b);
    }

    function mapInto(uint256 seed) internal view returns (G1Point memory) {
        uint256 y;
        while (true) {
            uint256 ySquared = fieldExp(seed, 3) + 3; // addmod instead of add: waste of gas, plus function overhead cost
            y = fieldExp(ySquared, (FIELD_ORDER + 1) / 4);
            if (fieldExp(y, 2) == ySquared) {
                break;
            }
            seed += 1;
        }
        return G1Point(bytes32(seed), bytes32(y));
    }

    function mapInto(string memory input) internal view returns (G1Point memory) {
        return mapInto(uint256(keccak256(abi.encodePacked(input))) % FIELD_ORDER);
    }

    function mapInto(string memory input, uint256 i) internal view returns (G1Point memory) {
        return mapInto(uint256(keccak256(abi.encodePacked(input, i))) % FIELD_ORDER);
    }

    function slice(bytes memory input, uint256 start) internal pure returns (bytes32 result) {
        assembly {
            let m := mload(0x40)
            mstore(m, mload(add(add(input, 0x20), start))) // why only 0x20?
            result := mload(m)
        }
    }
}

