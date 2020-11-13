/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

contract PedersenHashPointsXColumn {
    function compute(uint256 x) external pure returns(uint256 result) {
        uint256 PRIME = 0x800000000000011000000000000000000000000000000000000000000000001;

        assembly {
            // Use Horner's method to compute f(x).
            // The idea is that
            //   a_0 + a_1 * x + a_2 * x^2 + ... + a_n * x^n =
            //   (...(((a_n * x) + a_{n-1}) * x + a_{n-2}) * x + ...) + a_0.
            // Consequently we need to do deg(f) horner iterations that consist of:
            //   1. Multiply the last result by x
            //   2. Add the next coefficient (starting from the highest coefficient)
            //
            //  We slightly diverge from the algorithm above by updating the result only once
            //  every 7 horner iterations.
            //  We do this because variable assignment in solidity's functional-style assembly results in
            //  a swap followed by a pop.
            //  7 is the highest batch we can do due to the 16 slots limit in evm.
            result :=
                add(0x549a83d43c90aaf1a28c445c81abc883cb61e4353a84ea0fcb15ccee6d6482f, mulmod(
                add(0x6f753527f0dec9b713d52f08e4556a3963a2f7e5e282b2e97ffde3e12569b76, mulmod(
                add(0x233eff8cfcc744de79d412f724898d13c0e53b1132046ee45db7a101242a73f, mulmod(
                add(0x60105b3cb5aab151ce615173eaecbe94014ff5d72e884addcd4b9d973fed9fd, mulmod(
                add(0x295046a010dd6757176414b0fd144c1d2517fc463df01a12c0ab58bbbac26ea, mulmod(
                add(0x4cec4cd52fab6da76b4ab7a41ffd844aad8981917d2295273ff6ab2cce622d8, mulmod(
                add(0x43869b387c2d0eab20661ebdfaca58b4b23feac014e1e1d9413164312e77da, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4ccee6b6ecd4ea8733198e95935d13474d34cf54d7631fde59720e40378e1eb, mulmod(
                add(0x6fcf0e32e3e99f51d8cdac9c19cc25179eb97f2757844fa0c72e7c3bf453e4, mulmod(
                add(0x479c09d33c38f1c8f73247aace507da354ae87ca5cd4aa096bd3a6229e3006d, mulmod(
                add(0x70454f9541d96fc1552f984330389ff616cf80eaf699ba2e82b77f43fd163a, mulmod(
                add(0x19b7924c29a944ecb61165a663d76d84e5ce44b4617fdbca8ff02fbdea6deba, mulmod(
                add(0x71e67bd6a0b1b8518cb06837a78b92ab3dec98c4989f946285042655ffe516e, mulmod(
                add(0x4259be645aaf0a661e7877276fa5559ed7d04349f577595702efed3050402c5, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5975b93cee7a147a93cc98aabbb713f151924c4ede3306bb5e14e5e4d5d5c05, mulmod(
                add(0x52b5bdbcf28603ba60abcbf52bd4f7b4988ce0b4e2346e4875a3f117d4143b4, mulmod(
                add(0x394d0eed011068acc2f55f541c4d113a9c0afe7269cd7d9711aa7e8be661a60, mulmod(
                add(0x4d44944716e0e13728fa8b84fde421f0f66a120ed2b7cfcf59f5ff6718b8b6c, mulmod(
                add(0x1e2c5c3fb2b47ea8cf33099c610f6132a5dd7099d29b02f4a041fe5947ff53b, mulmod(
                add(0x4183c04ef7d778f11e57b44c1a7f354c4497f1e3d420d3fa9f9c27c4bb58759, mulmod(
                add(0x627cb37206e5ee9da20c04a92cc765e3bd3f3d4e42ad4de0d709f366d446d8e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1e3e1d970342085c482175cf60d93e1cc2cf96dec12f1d839b9b829cc957b7d, mulmod(
                add(0x1c7c40b6e4cd3d473e8f84b8fa63610ac6c7e3f4f0017f3ed84eae8f042bf15, mulmod(
                add(0x7f9850620a3435695ec7a6d9378cfe218ab0e5fa674cdc572fb9c197b0dbd25, mulmod(
                add(0x3485ad12aa365fac51a6296931abdcb54fa848c587cfbfe5bdbad2d6f6d3bd3, mulmod(
                add(0x32bd55700baf7283995407f470139326a670d60a5d5428904596584629a053d, mulmod(
                add(0x7cbef72611c8e1e08e52ca202382a8545bc7fe124ec080058988e45771e3b40, mulmod(
                add(0x787053fc3649b17965b9e6ef5e05e024cdc188e90aef1cbf13ba78542a0407d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x468b88ba32ca1eac6c8d3196eea0561e25770818221ed0da3ae749e2a302e, mulmod(
                add(0x6aacb14e31ebb5066e78eb597842812d7ad137880a6dd0d065c4acee231b7c3, mulmod(
                add(0x2a0c1eade4037c10729bdc8a8f38bb5bf359078eedba633047377a09b6cde4d, mulmod(
                add(0x724a3072c9f315cba63e5d99034b3218ff29a9bbf04155060ebdd6c848a652, mulmod(
                add(0x5efc7dfab3ad0b3f01e313c50ced95363d8dbaa9f91f801d6f1f00869467a16, mulmod(
                add(0x31b8dd40040d22aae383c1e628e427f7aa4a7b0c3a83f815fd7ae2b36864af0, mulmod(
                add(0x2d1547488e174e0a8662decd2cf020dd40718f070c84cf36bfa261aa90f814, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5e56f3654b68256095b54a7868763aa3ff60a98ea3508039def82d2098d8a6d, mulmod(
                add(0x751a8c7382e8fc0141b4ec5bf37fa457ab8301640b58cfc3b6a0b8d1a12bec2, mulmod(
                add(0xa8db86341624832893780e36fe1f60490da5768f9aeb2a5803240f29ec5a2, mulmod(
                add(0x126a03f3c5cbe523484111d915d6d7eab5edad02a327a383171be09597336b4, mulmod(
                add(0x41e1c8870eea4b7f4308e8173f97482d80afd055f07b1a058f182a775aef593, mulmod(
                add(0x2bec10dd6a541c12555ff040b5949407713b4227867f53a435e80847b7932f0, mulmod(
                add(0x5b52f487f8c3d78fb6ea4be227325a7386c7e95cd5f9b72710cfcc870cbba59, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5f4ed6b86202d76686a0b4c1efdfc93c46dce1b843c7181d1db1f8cd4d6dfb, mulmod(
                add(0x1ec66f3f326120e659b78867bdfd7dac4dd3f1a92ffeaf46d39725de341afd4, mulmod(
                add(0x2b783063fa1948abfa91d79d225d52ed2ddd11bf20fc388b1ec00fdb5867921, mulmod(
                add(0x538392c6ca2c04b5096aa69392b76ff109aabe165df488f3d1a8e5c4022db64, mulmod(
                add(0x40c43992a86359c71f5b8051d84d1fd6971eb36ab486f321a1fc50a52a02a44, mulmod(
                add(0x4efe82f8cacf9761cac9fefb6c13c1afdaed68ee650c37684bfce323070e480, mulmod(
                add(0x60a9a4ccb72bde44d8a6c5f1d7b9303cc32013ef621bce1b8af413f00e77ef2, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7775ec7b0ee9812c8df83957c5b46c316fdac82a2d736d4a6eea6124abc5849, mulmod(
                add(0x775ad15685181f15e34a6b0036c16fc8d1a9860ced1cc5ece39d19a6add939b, mulmod(
                add(0x3f6f9a9c3f6e175b59fd8e4268a6ae5734034fb1d7c43f97ef474b75ba80cc8, mulmod(
                add(0xa64b536ff29309d613af1c27c7229c3f6c583471c6b589b25026db08d3767a, mulmod(
                add(0x1c5110241881e087e201d211da338d8377dd228afbd84850b76f3e5dfeb9361, mulmod(
                add(0x4e57c6677d3bd56b425a3b3a92517344d4875e1710667e3dee1954395269af, mulmod(
                add(0x34b9f6e8d5debbb4aea334310dc8d8075f896e7eb9f1c09788c7ec62ccb6116, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x16b450dd2bb4712f6412b35603aaa02e7345124e5fd13e919c269f3874970f9, mulmod(
                add(0x6713ddde3f2da61b676f5e4c52177bfc8c1576bc97ab3c48f08ff02d26cc03e, mulmod(
                add(0x6dc0d996fc95036c8cfa408fb12793bf8a4773d698f55085c2ccbc906c6d2d0, mulmod(
                add(0x57f8ef270683ea78b167dcbe5bb122a79ba760c95f8103dc4c6e7788fb1ac9c, mulmod(
                add(0x7fd8c6108133b8109f4058192bd614b5de2c50afe7ac08a7bb0e0b12ef04e4f, mulmod(
                add(0x67649ac75ea692acb3aa4432d48de15aacfa347a37afdf489cc7e954e4ab100, mulmod(
                add(0x41f320f863037e381ff83f2c9f1a8ae2802fc22cfea674d9cfd10171da6dea8, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3394eac0b3787b323686cddaef3af972d7fbbd75940bf7f682b8fe3676cd46b, mulmod(
                add(0x218bc11c668ef7ae5f04a16dc9933c5bc41c194a439d0af802568e598c54630, mulmod(
                add(0x597cee65bc7c6f0faa3e0aa1958897acf7fd4e4e69569f5d18254b0b8c09aab, mulmod(
                add(0x9b478a0767cca2c6f9b4268bffc9e907eb69b32f8ff7b43fc24edd38a88ec2, mulmod(
                add(0x5d122cd95f43fb6fc2373ef7e66072140f0f20d552f186faff2622b55a3e063, mulmod(
                add(0x33f4151b710663772765df7f95b3710c3e8e81bacdbe3729b0a43b6d19e428c, mulmod(
                add(0x5f81b087ad750a0ebddd5239bb3682c84d88326b4679a24890f5fec98df45a, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5142430fc3f872dd6fefb7e9804e3e63714f71a2f43b155cebc53671f964af, mulmod(
                add(0xf78d4b72e0f5f55913884d0714674dd6f534b211ec5dcdba419347828c7c35, mulmod(
                add(0xf8ea3b2c0b72747301b2778cc071cb9d2e09bbdd7a386b7931582ab412dbd1, mulmod(
                add(0x22d4ed1a29943bc16343e01eab25e45adf74b6a7072e4e26aa8d141f2cac5ca, mulmod(
                add(0x63372394d373e7a2f2fa6405509da05fe9cb546ea2742ac0716bccf50ad9227, mulmod(
                add(0x5db68a5c4527fff0ebf61fe064888b0fb6e277cfecca6d206986293256f31f, mulmod(
                add(0x4aeb3836ccb2a9ebf9f1c5b6ee3c42f66c8059cc55188335a47a3583d986018, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x597cbefb648f47e763b9b1be8c3f815a0e8b65d0101e11b5bedc380c10e9f4, mulmod(
                add(0x5744178090cdd56ae12fdd51b74bc097f23f735b7ca16e415a1854597b1caf8, mulmod(
                add(0x3c62720cac42a262b58765d7c0588231c5c2c9ce9d48f0fd547575289ede8c8, mulmod(
                add(0x2dc12726f7f06ef1adfb10747e5d4ef8052e4e57bad9bb10529d7994ef91035, mulmod(
                add(0x4180556f79a47df725eca2c2f65389e27281443847a7d9e84640e6d589182f7, mulmod(
                add(0xfd959b09bb704fe63c73e2331f8e76dc1fbf85c2dc9dcaa0e8108664f7f988, mulmod(
                add(0x72fe5010e70102306b21cc388b7f2ab8b0324b84654cf98032b83a81099e72e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3f61241934753ca9c4f4210885b87863abdc8637d4dafe5da4bfa5e0206988e, mulmod(
                add(0x3241fcabfd99b666b151970558fb59fdfca47ded4caf2af4b15839767edb190, mulmod(
                add(0x3609fff81e15da2a88036d1c2d28814035ce829430fabcc3986c08acdc2d44, mulmod(
                add(0x6348748d43d48acafb8ce688f25a1245df86dd20c3a96c5c85cfc0960ca2fa7, mulmod(
                add(0x29d152196b7ea7446182efe778a2db796f5fab17286405953476ac97f94a96a, mulmod(
                add(0x3cb89319d8172da012c036c40116fd325d65af69f80a1df8f56ec890e920592, mulmod(
                add(0x78e66ae8b3ef57289d92561dbe4ef72f4ee551d5cad363720a78d104a89163, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5e51a00b7437caee2acdb81781212bc3d1c397b477ec784d1a7b304c9f8c687, mulmod(
                add(0x23e127bf290465acfb7500962d426be5241f0e8c6f844d25aa8e262df6e70cb, mulmod(
                add(0x2a390a6737563e9edc22b0b0cce94a67adc10db18d6f978c826f24b8848c6df, mulmod(
                add(0x49eac48d453d5de07fe3f4bdb5aac21e7fe69858afedfbeb0daf175459dd9d7, mulmod(
                add(0x1f6bf768424619cc2d34c01cbf4e137b6cc33a4a5a3db0bc704f790f86ad67c, mulmod(
                add(0x43ef0fbc56a0a46c7099f5e6d6550a77e1ac023e2201f01bde0a3f5fb0f16a5, mulmod(
                add(0x6a16c0b648c72c8d718d53099cb11725ee09fe1b49487d8f55f307a6a265920, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x12f2b0b280b64cb9f6bd77cd5103b7668ae42e5d40ae156607c69043b4da5a9, mulmod(
                add(0x2fd6fab5c4d0e6bd5bf5b950632e2dfc3be19c9a80e3bf8934e878003b0816a, mulmod(
                add(0x62c2fa993dee607ef195fb6620051b4df127d933de3a417d21de3b0c6dfdc95, mulmod(
                add(0x3ea018d81f9118cb5cf251d6c795b4ca4aeeb28d6ea5464fb4807d219453728, mulmod(
                add(0x1c02d3ffc30c7172a132ac604ad28e89466845c139dba509b896c997ee4ce8a, mulmod(
                add(0x7aa1d2348e13a031dc4fa20d453fcd59eead9adbccc3ea64997d09a0f58216b, mulmod(
                add(0x6e52308f62433fe92ca9064e06aa17d793d3ad7bedb9590c8bb9edd3272fbae, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1868ebbc59cb1c69b32ea2b3a7ce3f87b680731b96a42403878df0a0e4bb3e2, mulmod(
                add(0x11076126b67298371103d89e76ec2fbe30b28c5de422e61d3fade2e190450a4, mulmod(
                add(0x2120274511adcc680703d33146477a31c42684b5163a628eb3f84258ae78786, mulmod(
                add(0x2dd7ddf328b439b3047a93c6fff6ef901946438cbb55a4c1fa1848f80baf2ce, mulmod(
                add(0x362dd19b8207511079a352fad991df9582315ca2539ed4da5cbb5b82e414fc5, mulmod(
                add(0x56f19df91009289c7f5304026cf6d2c26541cd4caf867b2d2ea8a954560ed7b, mulmod(
                add(0x51a3ba83e3f68b2df85f3b9e770b5294312fd634fa48ace215a029fdb5593, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5fb45888a7861e18a320bff7b0baee50ef9cbe1b06c78a5a16a6fbda3c6b77f, mulmod(
                add(0x5fec9e8e9ad35ec1091706f4f39c0e8a610f58be6c987c2327ce0794af7cb7c, mulmod(
                add(0x596104fc8bded038e39f0de5e80a2f2b65fd39fa4ab7b3453bbe8a40e06a317, mulmod(
                add(0x3b2efe16624d8d0a1beeb037b02f0a4f7e11eb3859852cea1f83ab1752a4099, mulmod(
                add(0xbdcc31feec5ca8cfbf7227269d1e120132c51307ec03cc2d59c471e2510a24, mulmod(
                add(0x13df9c113e40f246d806089e437629de52f8a247ece912785004efcafd4ea94, mulmod(
                add(0x5b7abf66fda1917e0e1d44924cb73d713b5fc16b3a64bd4857d089adfd6a814, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xdf2e87cea7f46ab09a5011d8afca4e7cb962e008fc991ea16d85c472dcf3ef, mulmod(
                add(0x4c9b9f2c154c6a8cb1fbf50793787d215f2857d042b21c6f5e2740732cca567, mulmod(
                add(0x3a7ada56cb16708c6eee7af3688765728c706a16baf61d0582186a3717ef552, mulmod(
                add(0x4db0795b76ed3b5cf3cbc23bc47d20abe9b9f76a2731f2774e6dd5ecd6eea05, mulmod(
                add(0x7c537f749e37ed15d7e5d5d0f88686c5d02242b6c487ae2c5606d2c7de986b6, mulmod(
                add(0x1f90c3eb7ed36bec79f803ab1884e5455581110ab713139cdb5207561a89a34, mulmod(
                add(0x2c15afc87ef81cb58ec29c7dd81b4cfe291e5d33a7b36126289a8ebc1af4eb4, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5eb4774b76a39af609243ea0ca61eaf03255a02d90be9a83901debf64875f0b, mulmod(
                add(0x14e46f8471beb6479fadac1286dc86683c659bf1c77dc96bcb303d48c115d7e, mulmod(
                add(0x6c9568c4a9f64874e71c88cc80576e4083f6d0649f66929612a9bb99bd958e1, mulmod(
                add(0x554563c23e6ec8a4497d670e81940a92ddad53c27e7bbc18de74d2b3734d824, mulmod(
                add(0x6c8258350c092e7b5cf658a6bed95d620afe0563482911a1435a93bcb0d5beb, mulmod(
                add(0x17eb7ae4a950bce2abe1e7165594eaa60be7b75cefd8007425a735264a1371a, mulmod(
                add(0x4df83db997cffc8598b838a9c8373bfff5e109d71ee3bf2a18dc0e621e93d2d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xcfff274a78e56ec27e29d01f2e900bd226cdb493a83358f9b807235c9aa407, mulmod(
                add(0x19eec9d276c006f19cfa904a4e2ead857e99000d16e897dc8dc955c57615d54, mulmod(
                add(0x40d8fb43bbc7e5c35e4b57fef4e8351ffb118c9d92346f97ff7cb48b0170eff, mulmod(
                add(0x3f26981ddcd3549baf47e3f1242b0bb90d6b7f426ba71d2ce628ceb801f3734, mulmod(
                add(0x3b69a8579df2cea96435a07c81ae1d9f8a5e0e52433335c3e7ad81b76789788, mulmod(
                add(0x6cfe464b2a4d4e77c09e0beceb4e368bd93aae5efaddbb92e003afc508fcb33, mulmod(
                add(0x3317e8a32e8f82246423237d2a4039eba358a76adb8065751b6d7939fadb85c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5950e4370508dbfa764621025e9341994a3ac21848f3e39d02370b193ba6937, mulmod(
                add(0xa89bb9df4a46c56f2f40748d826d50285082118f8995f5e7638a05ec117c47, mulmod(
                add(0x5a5085cb551c472af264b5de50ebb7b4bb04539c9afac1339f903b943578eea, mulmod(
                add(0x40a9f47d93280a641e7f903b1e608cb443ed5d59f24cde6b92c6631cab1e009, mulmod(
                add(0x40508ab9b5b8d885f85750bb659071d6cc04639f43070b94a802d41723bd0f3, mulmod(
                add(0x2ea5039159478e68762063624b0f396cb7f1bbfe8c1a159f65f0f663f219136, mulmod(
                add(0x13d4454abb9515f00c3daa6034ed3759ea722a953679c4f857511141b87da93, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x46df5faa750270394a4253e63ba3e437550ee216ebf8ddbbd7304940c85ad02, mulmod(
                add(0xa9c2bf87d58d3f72d985b4b1129f0a1664caac1ee26a15675d1a5086de3a79, mulmod(
                add(0x6d49bd35b4e4aa46b7098d306632014b4fbfd84892d6997b58d9463a0ea2c05, mulmod(
                add(0x66490371a5dfa3fb85bf3f088b89614b5e56cafc263eec39dc4a1bb39e03433, mulmod(
                add(0x411f9def562556de87d47af60354512d9a1261152e7f4636038699d468fc2bb, mulmod(
                add(0x42271e06f205c1bfc9f9d9411bf835f43941c88aa3dc75f044a0143faa4d5cc, mulmod(
                add(0x6f20da2f1a25f1fab33e7856067226784ad992f8bb53249ee7bb17e86c82070, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5519091c464bab5646294ae41d087ddcef8bd0508a94a07890fa07220bdaad3, mulmod(
                add(0x2761e32194ddef695d1837c8a3f48a3773ae392b5633bfa0c1451e51e33b69b, mulmod(
                add(0x6fd73eabd21a86dd8094dd0ebb5924b1aab0753a0d251571ea93f83ab4bd519, mulmod(
                add(0x40ba0e2f504aa0e9972018d91be21f56bde16361282915563796c750f8936b7, mulmod(
                add(0x6933ce3f88628188f7a1b1be5b0506dedadd9559c4766be0e7db1ace3adb592, mulmod(
                add(0x5d9acf8582d4ccc017af36a8a9863e4383b63893d3fb5d81f7fabf4ba3d1023, mulmod(
                add(0x6e5bf767f3b0646dc16377f3bb7c17db6069555e100dd2215eb20c4d29fb1c3, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x20a06257ccfa90a74adf9bb1130a8385b8c91bc61e18acc30843463e5abaa2, mulmod(
                add(0x4a94669a4901cb5527124a2dc7ff6c278d540da41a95e819d0ca10269f7b380, mulmod(
                add(0x5f7da39edb0781ca1f96af191cf4c70fe0c121b7b2c92f09b49503bb070dc99, mulmod(
                add(0x591ad3fb7ab83f8d9fcf184ab793baf3db128cda0de1618932851108771cf0d, mulmod(
                add(0x3512eb8a3bbded6fad1c19190d857629efc56f93fb4aa527e2958dfcce12153, mulmod(
                add(0x7692b996dcfecd35db6aa22de10144724c478f85a328ab893c6fbadf43d7a9e, mulmod(
                add(0x3b160cef807b72e95938852093a3a633e72b61e0afad5099201885b54be4098, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x46d1e806178137e82ea97c54d8c15dd45c2a9a0082b18aeb9f849158ffc0ee5, mulmod(
                add(0x7991462c103abfc3bc31427227b1fb82f7fdf2be1b39316f46e3baef2fcf588, mulmod(
                add(0x525fee2e2cdb7a293f50f630a840d5cf5f29a158eadd6fa9d0159951712d19a, mulmod(
                add(0x8c2c75a2fe00432f77ef57e906f264ea76c439e0c4cb19e87867a6ebb34d0a, mulmod(
                add(0x796c9b073e2c56f55601eb1f6147d028553275e9fb792f0b76007c9710459c7, mulmod(
                add(0x578dfc700a95a564b41ba8f33b885ad04209bf5169a4046f603a3d84f792d6d, mulmod(
                add(0x7e3c052c620ef7fcf180898d28e39348e96e92ed0634dcae3f5fc64be5094a6, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2959a6947bc4eee0135bbd0a6f2053b62317a1718bcceecbd507417d31e8806, mulmod(
                add(0x4ffe8275d3344b4ae2f7d9992d68598e50f365c0b8a721d723841485fc25c0d, mulmod(
                add(0x8c5762a12210a7fdc96a7d3aa966476d3b28650e7c49fc90f95e49a80d4324, mulmod(
                add(0x48294f41052135cca94fcf88cf236437b8a55370c3de81fb0d781aa7b0f8eca, mulmod(
                add(0x25fc8ba8ab421b6dacf2ce03263e037374e4d61c6ce26422fbcb2e755c0d9c4, mulmod(
                add(0x1e3d7c65a8f40b6f8aab1635e3b78d0f798746532f08771267a9b6149632a5a, mulmod(
                add(0x25a127bbf961fe2b5bd9facbda706223206c40acff003152cbb3b28e9668030, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5fde2cdf0d23d5649e3aead1b2b90ca0309715a029654e8984e43de7bde7b06, mulmod(
                add(0x4159f8056bde7fd4f72615f7bdd0bb6408256b8b216ca52fee253113d9d007c, mulmod(
                add(0x703c768145191a10344e5ca400be8fd249e653d564015d46fcd7096cb723a0, mulmod(
                add(0x22b5eab11c9e1e6b8d64d5db4b12502fdf0899497f72ee1a27c8797b617f76d, mulmod(
                add(0x2d2e43c0ad60d4265774479258211274ae32b5e151aacf6f8ac1b7708076f09, mulmod(
                add(0x73796a0ce0fe851bc22b99faded48a24a21745bb62603e750f78b854d7c32c7, mulmod(
                add(0x77efd8893058f8e00863205582a5e274c344b9af63b9c40ddd92c97c33b52ea, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1d46036b736e06016c817d2b51a0918189881a4f1b7c71d556db583df762d37, mulmod(
                add(0x2edf44b1f59efb0f36c0fce5edbb7576c89cb9f191300fc5e0240def1b88b9d, mulmod(
                add(0x5c1e733995aad208f0697e4d2a6e28bec9fddc3e30bd033f2f50a83927baef1, mulmod(
                add(0x3481879ec47fc8cfabf38ffaa75311c787b7006e7f9def35e96454263bba4aa, mulmod(
                add(0x575fb11a4d7e3876ae4c86b80b4b9530e0d3e9db218f4d5644f612348f8f002, mulmod(
                add(0x3333c3d925d8c58b9e4e533531e93046039577cf0e57d011c7ce87c6ef1a835, mulmod(
                add(0x50372d2aff2ebc566505a564d971c6491095e009d9887899aee0b5017fcb877, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x566edfbe3c59cbd43838ee245edfebe292c7163f79b1454b03ef3cf8af23c10, mulmod(
                add(0x7fd44af0ef24f061aa7dd5bbde15098dfc3721790ee9bac2caa71cca714ebf0, mulmod(
                add(0x1765a9eca4f4551f177b35089f8befc808613bbcd971a47d485b1c220d0bbb4, mulmod(
                add(0x31abb6310a44d65ac8c308011d4afab938fdacfbaec14c62b808452310b799b, mulmod(
                add(0x18d0f552fd62f81b6076265c7a3a0b81f6bd37152a2f16c71210021ecf68468, mulmod(
                add(0x4219a0a13e09662f3ec712da51b36967947f6d5a09d8044e3005a7f0ab45915, mulmod(
                add(0x258ef77b90879282ccc2ffcea5052cad266d77b75db36b7996e5fe7638e9b00, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x75bd5b63008c2e005df64ca189ecce11c060f0df6903011a3d95cf9f7b48878, mulmod(
                add(0x20d2002cba899acc7d333031e0977d8df94557ca0749bef6c38b72dbcd462f, mulmod(
                add(0x7fb1cbd7a48f2d44a148bd4d17ccd47c438f4f1b45a02945cf4312afa0d6f95, mulmod(
                add(0x184f23c10c726d4a7036c39466db02c4fe7c3d40bade571fe07acaa282f4c07, mulmod(
                add(0x324db878e3842c25a78e94453c98434c54b41955db62234b0ec5ddde6641556, mulmod(
                add(0x38445d5f2de7993c48c9da8e77a87dbe289dc0428b1e4ca87e30b2376535543, mulmod(
                add(0x14d01a0c81aa61c5a238243e78afe80e5d0d7bf528c3d05a343d0f4470d2b0a, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x53774852c8f84d21eec107e1da7a2ab3f4b5ceba6479d1f902ad404e7dde329, mulmod(
                add(0x672717b74bc3dca9e53494681a5ffa02edbb0290de1c5209843a16964df7a3, mulmod(
                add(0xcc060a8b007b2dd0efa786afa5edcb512d83ddcba8ed69c27ccef5769deb23, mulmod(
                add(0x2593b010eb6fe0f64833e4f22f6854c063085e0dd393226e6b5fb20ea7f432d, mulmod(
                add(0x182e50e36b753ff5f95f2bc47a6aac8c6f2e5c3975476252a7c29250eefb056, mulmod(
                add(0x38441dfe93fd3133faf52208f3263d4ecaca0643bf9c9d4bc952c86cf280f7a, mulmod(
                add(0x548724b5683cd6427513b4c4f84a6d888b9a03843bc0dbdc501b8752d99ada1, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4f6ea70b9090971f8de7071f27b0d036b112211403e0547fb7b7903704f295b, mulmod(
                add(0x7384363b4495aacafd81d0a139a66afd3243309395e3444fb3f1496832240a9, mulmod(
                add(0x44090861421dbb6b4a325a6832e02986be80f7ea475313ae01a3215c3510346, mulmod(
                add(0x3dfab578cfc7a1581212074e0969db9accb619a043dd7194a253af67ef3698, mulmod(
                add(0x7bc4fea0ea687295d72735a62a19c1a160a1b9a19342717b527f94770aca77, mulmod(
                add(0x725601ed4fcfdaa392b91e8ea982fc57f1874378ab8d6b55301b3d4b6efd802, mulmod(
                add(0x96de7b9a7eac739df4d13902971804aaf40f5559d18593be0daac0ff86c636, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x100a89bccb889f183c2a6ced12bab8ef86403230ae6b23def0b784f73ff296f, mulmod(
                add(0x7351448e92ce6914278e73ceeb080e280c146dbcc21cb35af8d2c7e5560aa7d, mulmod(
                add(0x3236ab2e0e0b1b013c2100283e36fe75521bd50091f1c73deb165e86616d80a, mulmod(
                add(0x11b19b3abd2b297728768027b1370566bd845bfb6f49197a76255c1d8c661f, mulmod(
                add(0x2b2091e41b10140bea196a1cc28d7f6db6ae1b55d1f115d882c321221a32eb4, mulmod(
                add(0x6cc09dc2faf0903dbf5121b97ef058300b18efcc30c25f55de752d395b568a9, mulmod(
                add(0xd55dad93e837d31e8f120398e09b83ca68f160c16043e1c65d033a19adbc30, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5800bf15808a39f1acfbb193af1ab0c22f18d9738753bd3cd2aeea81982409e, mulmod(
                add(0x2dca037a615e8cf99f8614f437e953c5625b9b57d95f16c174f63346e31c5da, mulmod(
                add(0x2d88caa65f47db103fb1ca354bf50c93f24bca5001598f716b6c9e5c51d1d2, mulmod(
                add(0x6e3a0355459b8b7c35837f3f19f0d8954907326cb08d7d084f2ed0f4b2af8f5, mulmod(
                add(0x424396bedfddf4192963ef0f87b3989a99f277fe2c60756a4a60fae4d6dfa31, mulmod(
                add(0x273647256f95d2e5f98bd7830191abd89dc4ab241fc7fa12b27e16a6bd423c3, mulmod(
                add(0x31e49312e1d59acae36bf3562443259500039a7a77d9a57a44cbbb4a80932e3, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2f26fb29017b5ab80328de8488db547e47c44c0d56f30e330354d5b980e50ad, mulmod(
                add(0x40d1ae7e7bcddc520ed8c0fd736e9b5147d278ed1b720abf76439377023abea, mulmod(
                add(0x1bf01c19527dd1d9094c44e3acee4d1ec8c4192026b6f996776294cc9dbc4a8, mulmod(
                add(0x6da06ce868c140c8ff9ec1eb0323fe2c8b35b46c8d4f5a27727450e87ebd906, mulmod(
                add(0x959c7bf3885d75ab3ca9480101ff64d62c9f138d35f63c137009c1b3eb39f3, mulmod(
                add(0x5ba49d41f62b6d6903fc455bf02bca54becb6ee7f39650fcd0b717ac396159c, mulmod(
                add(0x4ad97a9b0ab95abc1b8fcff31a48e18fb2391ac95baaacc62125bd87fd75e13, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x70cc78b821b198e72f8feeb8f31d81e5a4854de3575a62909e0bb51cee921d0, mulmod(
                add(0x669bfada09faa64c005321d60752662598d69c517e9ffa462dc1b1af42228d1, mulmod(
                add(0x593df80dd238cbdc6398146502310a5cb459b0e7d79fa9bee5cc389385c95b3, mulmod(
                add(0x283c74c8066141911634401af10106c29dd77458d059ff3b2dd7aa796b2a559, mulmod(
                add(0x40ffb20c2a3dba0a0d8b6aa51ccaa1b690aa08670ceee556d76053cd671d522, mulmod(
                add(0x140ed138dfc5b5417b25a4512bb991f3fd04cf750e082fd4fb82cc15b645835, mulmod(
                add(0x72bcdfbdd09f13eeb0c01565dc6a79999a9642dbcb0c570e3e7621ca94df215, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x38cb4173a2b057da41d5d30b55f6d11f25effdc69c14843cc43a9ab269630f0, mulmod(
                add(0xaa17b17cdb757833dd4b1670371ef55345debfb2c1b6bdfae64d8759e04349, mulmod(
                add(0x7218f86344ea46cdcc372a22a14663105eef03bb0de9da9bfcd10818d36ba28, mulmod(
                add(0x6473d78fc37e48379ef8a9d57e3e92cf4fdad3a1bcc170dd177dbc51c4dc62c, mulmod(
                add(0x751a2c218f4feffc61e90939c4d2672a263d3b33528c7c6eb40042640f45146, mulmod(
                add(0xbb867c323532bde3d5b0e08b1b7531a95a2a1706132dcd8ebb7063cd1b1bbb, mulmod(
                add(0x68539d0ccd1737a8b2e540f9165638f86f6c4e44943455d311999b0b3684b7d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x9345d2e4fc86ae78c4879ecc3adf9e6c482044052bc3738618247b60f069ad, mulmod(
                add(0x259f8eeaf6cbdabd37b9de029661bdcb219245a7599207d3df08c7cc452a13d, mulmod(
                add(0x2782ab60e8e9c6cccd40f438a2d2814ef39f50f02bbeb790bc6df78d75af42b, mulmod(
                add(0x6e694d9385207d7cc8a7cdbf90eb4ed3be49cabc0e6b8d0e69172d73f4a5c11, mulmod(
                add(0x7f43f7128a1b46f8ab168a06df9d0cade82a3193eec2d51e2b83f4f0c7fabd9, mulmod(
                add(0x42518069a18922e90fa2fa8fe9bf5e2371a40ea88c25d247e6a73a007105dd9, mulmod(
                add(0x4350a29d7b4b242b20b68f6eabd75b758d8631c192b7da5032181b71740b96b, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x44094080f29bf84d3d5849f264713647289e9af1534ec38d1a7c3d2d2f1ab64, mulmod(
                add(0x6403910df189d75aca61c604de3b0802a4ec2ffadb0ff60f1a01f363d66ea67, mulmod(
                add(0x42ca1f8224d317275c78ca7762a78e6c51978afe1abcbf535da6d299c799c1, mulmod(
                add(0x2c4ffe18ae93ab53ff6d7d01a7b5bdc5b08dc8d144e0b917f47e60e3cf723f3, mulmod(
                add(0x37622de79f6252ff6bb76900db06504434856faf33c59a1b2e39a4fa60ed143, mulmod(
                add(0x581755fd25823d2f3b07ac5d8dd1bd5b26eab362cec3f9e03573a2b03f62ab9, mulmod(
                add(0x4419f27879dacd62144bde4f904890c6d5b312282335a57cf1b04b403bddbea, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3e2b9e4151827bb0d04858df547978536215dc06143674d0d2e788dcdc9c36, mulmod(
                add(0x55554f904554d2f262d1db49d7c515414870717c829b73d6c439260a8bba3da, mulmod(
                add(0x152b3265b01fa9ce0cdf58c17cd14c2cf3e3fafba140db9e27da4fdde7d3c0d, mulmod(
                add(0x4b135ec421e9138d09c709a5d92ba70e6944cd44a7eb7f705ab3612de315ac, mulmod(
                add(0x5ca2e5676dde96127ca85ff6ac82a8fb35b45651b88bcdbfab7ae5298d427c8, mulmod(
                add(0x5a612887264b1ff8e5239b3e04143dc30d0a80cef1c880fe52ee2d5009092b1, mulmod(
                add(0x3dd2900899d2219ea16fc41413af028057f0c2a674e1cc65032fe4dcb062d4d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6a1373cca7777e3cfacc6502ca9bc645678445d98acf3d6f5ca6c82cab53174, mulmod(
                add(0x5617f72f8d0da5d7cafeef9269395ee34f921f5cc8d1a4f4c0292a83cb0b9bb, mulmod(
                add(0x6785d833096c9d9d06034ba4d7f8d71481d4b680b63693d9fa24ea10d3511cf, mulmod(
                add(0x2d847968e995dcfcecc6ef98ab27f9f1db36b14ce3ba81b80cc92cf19750f88, mulmod(
                add(0x35b787fb9889163a9fb5ab831838f19092aa4ef8d8dabb299045740959573d4, mulmod(
                add(0x4e922a3c7df1c668f86b866cf0c07ee4658e7754f6fc0fb62cb297bb6960320, mulmod(
                add(0x2c30d5e07853079c9f11624e2431795e2bd8b4bebd8cac92f158306b45b0549, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x12e828f63839dc0dd62bc23385c0bdd5b11e7b6de2cddeccc47f85027c9862f, mulmod(
                add(0x6319176edd9fe726efbcc70108b516e26152cb56329b842a1e14adc2a3e47b2, mulmod(
                add(0x2233376db0eee71ed0bc6ec0de23782ca9e244a06b8e515b2855b522259eda4, mulmod(
                add(0x13102ce3fef387b552a6b8967f788cc8f8502ef0f2ec293d2b872328f78b6c9, mulmod(
                add(0x6a399f5bede4f507c7251a7ccd110e21173729f5f9a57eb16a27203d3c5e731, mulmod(
                add(0x74399a1effe3a13a8effe952dd57142c254ebe807a56f13521da38984a0b55d, mulmod(
                add(0x5b07a69abcc274ea09eb67f2f6036b492db1f9b7e0a3497d8f3920de22b3b4, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7fb8438581e1ae31877119b91ef1ea28181ba8c0a89eb356313c8a910295d7c, mulmod(
                add(0x43a4dbc140986d44a7099720e13ec46817f0131dd109a48fbbcf190671f35d6, mulmod(
                add(0xf7043785f78a94a68b669cb366c00538eafb8e87b5380c68518d4e23922d6f, mulmod(
                add(0xabbe74553aa10ee20ec6f0f49f73281124ca34d0b71c2e80160f37d3ae0345, mulmod(
                add(0x6856abcc37696eadf09ac823f589a05b034ef8f86e41d2c6222f039707017fb, mulmod(
                add(0x223b2c9fcd5a1d4b0f7decaab98bdf87e5083865ef9b6562a261fc75009e725, mulmod(
                add(0x1b5bfb21e549706eaf5c771448f91d1ce03498029ff4159d8cd11f4b6d523a8, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7febfa3ce41434e03eccb6be0099dc31d90e36558dfb6f9d21b3e0be41472b4, mulmod(
                add(0x76169700b631b19086b8b1737e23f1c59cf1428075904c80db724383d3c6b5e, mulmod(
                add(0x74a80f191573d77481059c14f56764dd2c11571b2736d355efa299c400f0377, mulmod(
                add(0x3e828a46091dc07cbbbb0dcbf390e4b5cc44d086b0ba74051fff237f7d6a74a, mulmod(
                add(0x253548b05c44cb4d8f2d97641773cf812f709663fe8f492f5a77bfbc8477d79, mulmod(
                add(0x3a3c97667e93fa5cc0531c8a2f6d9f84c4f683133b8941fe1382ca8f6f2fe0d, mulmod(
                add(0x125399adcf39aaf7962e3be41c6f9c7691e45c2c31b937e26257d94b5454985, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x65dbe95ea2b7d1894854b235f2cc66e910fd2791ff09b92366c7685c652a8c7, mulmod(
                add(0x50cdaac85b8d8bbf55a920bf8d213e333eba5f2bd92e92c61f3946617222ade, mulmod(
                add(0x40246dcd91afc0098ab9568a5c97d54e09065c551bc9d26ba0ab6a00089bec, mulmod(
                add(0x2449d2be3af1fcd8984a9f857309ab5e0e5c010680e33b03a194c6e902a553c, mulmod(
                add(0x203db741e5e80c19c2bea387e3091420b918fe1142bcf2bc13ae7e098282fda, mulmod(
                add(0x31cac8c51732d8aad5bc41c9a6440d482c2c4967e75a571c31b2d9aaaa64068, mulmod(
                add(0xaee16ac845b8bdb7d9c1c85ca7b0e749a7c47229ba24ba097b4b6b8151cc4d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x71d72b0c23e31d703f0210ecb2b28994ad828417531a15a17a1fd401daca2cf, mulmod(
                add(0xc8b65a737b5605606028a064d168ccf32d8d87fcb55c6c853fd95ae0961410, mulmod(
                add(0x2333165fa7f9414f082253b8451638fe1e9da3ba8c1246723dbf9995e49d017, mulmod(
                add(0xdcc0df28639fd96570d93a6d1df1cb1dcf6db8a259ab092b34cdb411895aa2, mulmod(
                add(0x4ded7eedcfca4ee336fa075aef6a017beab322cf7ddf83bccfba05f1c93cad, mulmod(
                add(0x69021f5cefc75ce473977c2ceae2e7c66a84bb3d734eebf4bf497e56eb69959, mulmod(
                add(0x18f3259c8451dc5007e94efcc6e90c6951543474925fd28ff35e56890bfb66, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7829c898e33552459e8fff13c01f1e0d9f5b098f0de7161cbf97da52914bc38, mulmod(
                add(0x168f97539fdebde7280f4d33f7d5b469cca77495efd4660f31b7d8018f7f89e, mulmod(
                add(0x453705ada0d5db6b0afb289b29db6c9acedb01e742cb0d68705d07f8dfcfaae, mulmod(
                add(0x5896811c73c991f479c7af6238b51252178dcf4371c297326bcceeb8ee454e2, mulmod(
                add(0x5ab65084f4ee8261bfd290e2d5608fde744be92da2eadd5f2fb909ac3d14818, mulmod(
                add(0x621692ad7ad27517f4de4e528e1271719cf5b344d463c86b9cd8424a4fc274f, mulmod(
                add(0x211c3e223a3c9c4a024b490a819254ee133ef9740a4026eb3a036bb9e5c6581, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2f5e865731de5068f289b616b39c2294284c111540abfdbb33a39780eb0bceb, mulmod(
                add(0x3e549a3d3849a09d8f1c50f84f7caa4aa0a5b8ef6f957dafcd13c7c90e4ea11, mulmod(
                add(0x33eb39eae1db6ea48126be6b300b31f6bbe275845822f9eb293e9f7ac38a777, mulmod(
                add(0x28aa32bfd8c8d7ffcb0b5dadfcfd1b6bbd69b02de9ac1bee786da98ce76c8e1, mulmod(
                add(0x2408fff139dae5eb756ea03ef15a2484f582f7ab27ccaa09fa8154f3bf0024b, mulmod(
                add(0x7b631dfaa76643b5f46a069b8c40038f77f088374320add0ac3c9924a12f153, mulmod(
                add(0x5b23dd8ead53bea28246af5a3a63daabf41e7987fe61255d97f2a57bb6d14eb, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2d511bed457c57d7354252189efd19e4f5c3496c1dbe1f1408ff79c8cb97025, mulmod(
                add(0x9f712ae0384a87901ad44f53eee9e7c39544893d10b891a92e87e4d78e8374, mulmod(
                add(0xc11cd155f0a514a5a419d10ffa72405817256ffc8d580b9d3ab002f596b2ff, mulmod(
                add(0x501f0235f18b49889497cf7c91fe0a1f81d74da8cb1e88bcfca9127392aabfd, mulmod(
                add(0xf0bd4817ef6ef818a35ca3678f88abb078678a1364539bd7886dad527cb28d, mulmod(
                add(0x42f46c19b87a82522476372ae65817f8d53f263674a040531bb37935b289893, mulmod(
                add(0x4e51def182a5bd5672ced3106f19ecd94b760dcfc68e66a3656d0b5db19165f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x781fe3d95c096c6df1c9ced110914917e26d0860da4bd769e4682a17540768b, mulmod(
                add(0x2ef1cb499e790f2de6129225457520b560c1c3120457e742957d1148bb934ca, mulmod(
                add(0x31587ae13086228663118a1fbfad6d65bb9741d5682abfb43c7524cc6c240e6, mulmod(
                add(0x7b851f4004fd9f20561e3755d7c89528ddefddbbbcbaa9293e416c0dfbb95d1, mulmod(
                add(0x21c86da8be11246b29f17d5f7f3566c20712711e03eba57f0ecace8c4355418, mulmod(
                add(0x46e747695d9d234e15781125d05b85ce3cb01d676ef8fc45a939d5e6d4e2e56, mulmod(
                add(0x6c8d7abe5c83db80647ff904bdbf25bd0e979607d2310ffbefaa1edb7ae1bb9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x70181ba88ba8d19c0220225ca0112845e23ed7609ffa4f2aea3cd40a40eef30, mulmod(
                add(0x25579cd0082839ce295d9bdb24140a8f2fe19f7d582a4993a88639a0347a522, mulmod(
                add(0x1e3df9ca8b80529441770e007a27cda52e54307e4f3370a83705e0f3ffc86fc, mulmod(
                add(0x6247162754e5af6a0efa837daba678811cd749e92d91acf35d732aaf4bfb4f3, mulmod(
                add(0x4d3987a0850d8159f9290a8ae8cf99a0ece9961d22135b584d8fc742d42c15f, mulmod(
                add(0x290b573a86b30d59fd1301b7985a68fd9bf9dfca5451179bcd13d10eee988aa, mulmod(
                add(0x7cf92bf7e933187b6ea01019ed1c2d9936e53a9ea89724e00e36672dca1e36, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x60de66fa4cc5d53fcd9d027cc06945a96de2f9b4f7d0c81c53a7567fde886dc, mulmod(
                add(0x57d63baf011722f5c5a9c4c60899bd918c3287302c97e91fc6f9f8ba089cb97, mulmod(
                add(0x4cb8044c471e8cdc896ac725744d1a6942bcb26d50b3641e2a95f57b0e7dddf, mulmod(
                add(0x62a78aa9e73bc6da0a8536da8dd43311ccfb52829e89e9e94f3b413efb8ff93, mulmod(
                add(0x5a87e6f4731da56e8b078bdea4cc3f1fa2059943de95ba404ab38addce3d6db, mulmod(
                add(0x1a758f2faad6702cac573f8ee11d83977ca75744f52d650a6dff79bd6c5caf3, mulmod(
                add(0x481c8091e40139c67f7e69737f83a6c868e582526afd50b548bcfa5ec2e83f9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x37edf969a82e9364a741858bfca74b30e86b1b69b4f33bb4a31666f4b2e7c10, mulmod(
                add(0x4fc4e265c8471510fe6f0dc99d7be1108eab6200b0845dab07c5a126c79919b, mulmod(
                add(0x55b74b3af769611aa4c4fc71b1abed4396b218a9d5884844c937bc38b30bf8e, mulmod(
                add(0x1ecd644cdd8b92b3c042932407033c073c7da5f3a8726210a443f10af466ff5, mulmod(
                add(0x7cf749a9a9177ecfa46b901ce91a8ebe103f8920d83713df80efb7fc8868346, mulmod(
                add(0x1dcd10514fdded828639c9c21d0c8064647947e9ced01014ba8943b1d81bd12, mulmod(
                add(0x794e6f83556e5ffee6d83daf40a067363b22e157cdd970366757d5d6a02dbc9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x18db208640b40e1acf69b256f0cf86c76f381ee79fa0bbea47fed2c95b5467c, mulmod(
                add(0x3a06f0e39b3afd46934c41a79a317f220c6321664cbe236ffe1c191ee0b2c85, mulmod(
                add(0x5007d334256950aba31d4bedb5decc0ba6ab62a09c41baa8ab8d0eb4cdc170d, mulmod(
                add(0x32124f76e477a3c6f5f4346f8abc19cd481b6f43088ccd1c3e8c634bd90cf, mulmod(
                add(0x1e2c3057002cdd12b80fb157887fc066b41436bbb71e328bf79ed2799947c49, mulmod(
                add(0x7e9f729b710f0fb173b36a6ee9611a9d309a9dc69a776c08dfe63c64c528a45, mulmod(
                add(0x2a3ca69d295e5e750b4db8367227f9cb347b3693251ba9761a22d411de1c41c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6931414c4f1e51dd287a8273a71ff946d1502d29539815c6652e6b71c95d013, mulmod(
                add(0x450e38572d5b45eba95a4368d52056640cc18213b3065bb7b373a05561cd44f, mulmod(
                add(0x28bb7956a08b64ed0ed089f0219b05b282eb25c107731d88867f7a78c3e387e, mulmod(
                add(0x2c489389378216a8f4a24999efae5d41af3bf123b10601d2efb419999f329e9, mulmod(
                add(0x5b3102b46125dd26f3ae75c22cb8be10a3c98f269a2e91ce7d595d25c77e6aa, mulmod(
                add(0x5dd2afd2e8b09f86360d183e2700f71a4fb5e458c61823ece1a4e60200b82f3, mulmod(
                add(0xa0c5ba0b916bdf79b70c0d23013443f65bd087aaca62088b0d1f7009dd2d70, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x29eeec3cf3ff9267792e170045fcbc1358ad5b9c28b97db6f4cb5a131dd1e57, mulmod(
                add(0x40f21a24062575a80e5a6b6fa209f04178fce24323888c3fc9a083c6cfffe71, mulmod(
                add(0x29f85ec8df7c753f09bd36309e6d7d65f5d5c327d4c80ca33eca932da5eea0c, mulmod(
                add(0x62796f07255aabe16df1ca5ebe7f7be4eb1e9b688defe3044b1fb8eb56765a3, mulmod(
                add(0x8955f2b26c2c91645402ea61e0b3bd091758afa740b4478e3fd2d97b7d5729, mulmod(
                add(0x680f30c7e737040028b548f49d2110d8889aa8dec6afe1de989e3f1f0c1c84b, mulmod(
                add(0x48fdfbe3980d1df8db00fd59b4b529abb0569c82a25c6b23186de11aee23a40, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6a60ae65aaae41d02d6ad44360c269051a870c66a87e430eabd1c2c5dd8261f, mulmod(
                add(0x7344cd22ecc8029fc605bc46e5f2f60c2910130290257210f9db71f26dfbdcf, mulmod(
                add(0x54730884e1c5c7ff5bff889e8e5846f7e552f07beedb27035c0eaebfe676023, mulmod(
                add(0x36d9f7e5746b465ccd284ac21d5cec14258587d22189b4f85ea87f9b4d7c2ef, mulmod(
                add(0x13f6d5bd19a25ef48bb5a89c64894e9351380c31e98fcb8404c490081665acf, mulmod(
                add(0x78ffe33137f03476882656c458a984b78bfe509d0ed005657860541fdd16506, mulmod(
                add(0x6d82291b429009057a7d89082c7c3ffeade1cbb4598b6bd1322c2e2d3c6819f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x14d1da51db79b82ff5fc48e18ad84a98b1390d8e61e1580ef5c6100d49da80a, mulmod(
                add(0x56e48833c5707aaa1e38a0d644765251c038ac3f89ed4d58fc3b24d03a83e77, mulmod(
                add(0x7b59c1f0252efd3b471c3047a2060ccb98cb86148c1b1893af4f86384821b04, mulmod(
                add(0x1b07576ead1fa791e38995e423ee788587adb512c1bda749fc0869ac6b40c6b, mulmod(
                add(0x527d59fcf4e21663d7e921cf93b705e95fca41d9d2f88720800586e03bdc283, mulmod(
                add(0x48a07a1f3adb4348f65ca07f7e1ad0b70a6024c4934df5724c35f1930befc90, mulmod(
                add(0x639a281c19217bb79dde39d86549ffeaa0694283fa876ab39fa6b663869ac9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4a5077d73c41429dcb66a5557cd392c5e8b64f4f93507e5e7b8f1cbe29a309a, mulmod(
                add(0x5669aa7f25c6cefb4a3e1f5491dc50af7c44ca9f8405864906b353c4c3529b6, mulmod(
                add(0x74d40da7c08b8fbd488137dcb60906f2004a26faf06e6ee4dbe1feceb94d98a, mulmod(
                add(0x297d16ecee6310efbcf8a2946e1f03e23ce1eaf88fa6279dced371db9dbc299, mulmod(
                add(0x937368e9df8289ef2d93e806914cc9ac730750d1ecc6ccf6c4aa6e6788d35c, mulmod(
                add(0x20268b11ea1f54c737a14073b8bd83a6151aa30b0d51182446adc72aa2bef83, mulmod(
                add(0x6ade2f8ff114a1c0a0f108286f0f0e820073e7fee989a85fe11a97b972f077e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x13b2e8b26fec1c97c5fac659532830270b08cc6861df86b3f3b4894175551d9, mulmod(
                add(0x13e7cbf6809b1c282b1716db08a549825b9e1f24479288cf615c6557249f675, mulmod(
                add(0x223dbf6f82e6f2b2dce8397a7a6d00c8fe38fdd8463fe7612c1a90bb76a16c9, mulmod(
                add(0x4b45d3cd223171c9e2e8030a3983c2e4b6ed61a560db3a8da8a2bf1da05ae2a, mulmod(
                add(0x4fe2139f7019584c7f395a18bfca2f5ea89a9300bf208b9dc73686c76e724d6, mulmod(
                add(0x6fb7a7f6c760b606b4f7cefa186540604099bd229b954096179a12ccd50e323, mulmod(
                add(0x5974550418ba46ba346cb87069b6c17f9a6d57ce7554827c8191072b4ff8357, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7cb9fc14dc4bbad427efdb3f5821fc9dd10fe8595577e39645ab9f62e6fa50, mulmod(
                add(0x7d2b1bf76ecca560b7409dee16ead5b2b3691ff75ef8fe5a844306a7e29b252, mulmod(
                add(0x1025bf3b6ef4dc8e3637f4dd1cda0ea30ebba8c30ce5638b5f9b5291faa0036, mulmod(
                add(0x5f25fb2b70ae9e334bd288d6768a7b3b6b2f4672cb671f6b0ebd781134609d3, mulmod(
                add(0x5d62087a11238dba183191a31e686ffea34bd393310e7a2b11c75d63ec340, mulmod(
                add(0x372a448e249504e459982c7d114b3c79270419467208096cfa6a96f3e5de755, mulmod(
                add(0x34a45f657061a57b808e337faed21f722e6298262a2df69d6bd34ecf2e29243, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xaeb2689fd195377c86c55bb52ba2ee27c7c5395d8163355a3c04135b43333a, mulmod(
                add(0x5dd26663ad2931b249bcf054211723be60b5b46de16a61928c0a9326874f3e0, mulmod(
                add(0x688bfd9b23436077dd139ccf0a7286444429f3a2457ce7e2cc939be2172921e, mulmod(
                add(0x45526e767c14a531fbc10f287b2a4203e18daad8a4883a1900a63dccc1a18f6, mulmod(
                add(0x354e8d015485a06adadbf43a6bad63e9330c4070fbf2a704c166e1d278c8d4c, mulmod(
                add(0x336d1ccaccbef10084bc4a18f8c86f699642878a2b5d5af3a3fbe7a773e6904, mulmod(
                add(0x6f61949d4cbc8298879b470d1fa9aec82261a8099c448dfa4379a597ab01d03, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1950cc259cc77027d5c86ea77f51a34cd30ad768676d77a0503f36f797eb4af, mulmod(
                add(0x7dd917167308b602914680880c9c8c8519f34be930ccafbaca3d126a30c4a45, mulmod(
                add(0x5dc73d8837d2fd0c754ecd371e94f0af344396efdb4337a8c7c2a0755838f46, mulmod(
                add(0x728595451b9c3918b04e7ce1637804c1df21495ad8f188eb46a5f1796e2e3c1, mulmod(
                add(0x1d60249bd6492637249efa94de232264fa23d62153d7a36e99aaede0be5d842, mulmod(
                add(0x73a3905fdf4a2f53d66ca4cb99ca729e776ce66d9a474fd71da35b3fa949d34, mulmod(
                add(0x73ce15dc2409ac614aba33d14c4ad294a3a8136eec69e8b34b0b14b92eb240f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xe00c78bcfc271dcc6556cb1cf6501e16d20b188c7412681c0b2ae0f2cbae05, mulmod(
                add(0x53b86dc3cb8ef3d5920ea35c40e2d05496e45245eca4e0d058e2a0e2d583dfb, mulmod(
                add(0x19c90daa3645b62f461545c7c38ce5bf8b5cdad399f417e0abbaf2b2df0ca64, mulmod(
                add(0x59a88072f92b384925c9091497269ba9f8226c24f740e928e410ae0bfb9350e, mulmod(
                add(0x7871f7217ff1c7b739678e28908c4222f492ebf866cbcc410148ad1d143de0f, mulmod(
                add(0x1d74577e412af12fd886706cdce3c238f2761d096043a084c20d2bd087ad4e6, mulmod(
                add(0x4d5df514fa9a8bd7515039e59bea7a1a1381a76f475a7dea23549106a7df8e2, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7c2468c14a7ea994c89e2e4ddd6d2d624b67a96e7ccec4f27a5e0122531291c, mulmod(
                add(0x2d51937feb119772693523625e23756d172e996d1cfb82a258580bd51c15e33, mulmod(
                add(0x4ee32b2ff29b0918618f173c4e5dc3b606a1ca2e0eb989257e0bf78dd2e9589, mulmod(
                add(0x217df85b26b6b3bfc67bec919866b6e146621c30685a31e8c93eaa27d5dbaf5, mulmod(
                add(0x38269de0c80a2d8f4bef1d5e76805d1e412fef7b18886279e98c57a0fe64627, mulmod(
                add(0x32cad92232ea7886b829887e6ca4ae084800803277076107b1078feb66e95bf, mulmod(
                add(0x36ac6cfd4f2ef6be5b1e83cf9e36e894b2575a8f4690c14484a17c222ec3c00, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7dcfd5001e21e030b006d54c7fe0f7ca97a2c18d4e00ba92c005705a4f0563d, mulmod(
                add(0x2781266a2070c9d3f045010a32c98ce3e0765446e3ee20eacd73a0dc0c7c2c2, mulmod(
                add(0x6d567c1dbb663fb2fd92140cf66ea33a19cda580d18c10fe56a62e5bd3f47b1, mulmod(
                add(0x3ba2c93d59d6a361b9ac28d93e54d775b040bd7fca9ac72339ea4388c533dda, mulmod(
                add(0x4fff8b45f7ede0580424c4e2c75213c4c42ec6c68266c8d5d750a2863bd474a, mulmod(
                add(0x39c92f0c55d99aa6b082d21129a9402e6b0fe38a639a8140d76ebee9dc45877, mulmod(
                add(0x602aca232b11ad63241b5f401c368acb1e9cfd4e5fc8ae699491d9c51b4db18, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xdf6c1013f3076e6044f0a7032e0bf80833f3c7d9eb0c3eb1f3c2a37314d19a, mulmod(
                add(0x5ebd9b268cc66bb85a5e67a6b9d5fdbeba8b3672491068ef43b688a3a043a33, mulmod(
                add(0x48ed57151b6dc68b039dc327f79bc2c26db62ff957809c5538360facc04d9c3, mulmod(
                add(0x4c5592288cc342232d76c80e858c08ecbfde64b747637ccc9a2734e90f85264, mulmod(
                add(0x72f959288185bd36ca4e23472ed7a2577f8e5f0ef0c0d5df6f63e60f40ba307, mulmod(
                add(0x2433d40f2b8f9461b5368cb396f7604999a735414d3537ed6f1451f1fe93cb3, mulmod(
                add(0x2fe4c112d7bfd4ad5f81ecdc4b30cf73aa51df4e4ba6d255a0e3eee283aff46, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x66a032c182ae70dd4487897d0c79dd860a25d21c61e3aeef8b9fa45349dee89, mulmod(
                add(0x31cdca47c96b32e99077a96aa5cd73ec9c4da04212667805c82dff3e498f4ed, mulmod(
                add(0x5f27bcacc10845ad41cb26244112faa8b91d46d97024445f50ced796ac5a93e, mulmod(
                add(0x7b86849a979796096f7d7b46eebaf00913a082c638c5b2bfdedbcd78c480272, mulmod(
                add(0x33381003a653f0327cbdd8a11252ffe714e1061ee214329cb99e667c835af97, mulmod(
                add(0x5d5fbd560f7bf1e97190f888fa43b32db1e8070f046d6016b536b94d1473a57, mulmod(
                add(0x5f0cb66613216a1339c1cd15239b7f03c1d4b9098a931f65ae50b877f861880, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x689fb22cd95d6f1868a4e3cd6ef1bba9f974931f76153e73038ff5ae7d09018, mulmod(
                add(0x777be5852ea7798899d4750e9decd1430bdad6a8b0d1827a7a89ce6f1afd89a, mulmod(
                add(0x506f990d7037060dea08ed53c5b17483ca8a7c58f94ba5e64fae258be4c78ed, mulmod(
                add(0x48b0cc6241c99407bb346db57db9cf82b2e66d1fcc1d756889a4f4b4bb8b396, mulmod(
                add(0x2c2c70075ac99cfe68a7354ed29842c5207bbdbd09dbbd225ea93d0c07fd9f6, mulmod(
                add(0x62ea67803c421a4bbdc672d556bca219fd24e7145cb3e9113a625eeb4459254, mulmod(
                add(0x148523eabde5554538a1114351f3d8730d4a4d003311c7b57ce9e709afeeca5, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xf09069dc6a2745587b447ae03ebd6524aa9757f1090a92dc5e7ce8db848195, mulmod(
                add(0x2cde734d2a82619ba69ca4f5ca5035f699a1e34b47560d761780546c9b04d44, mulmod(
                add(0x4e0f90743d3df3d3c4aeb80e7f6db457620430ff28475c6194c757f81927dc5, mulmod(
                add(0x44094c265809e3d5765071826547999dce8ba7058a7c1b1301294d8291949c, mulmod(
                add(0x4d62e1ef04cb039a58dd8cb8c37dceb78b10fd84bbec6302c964b899a957d02, mulmod(
                add(0x28c74f03f409c942d16a773fde01b3f0bec544b42c1d46944db6253561e1ac2, mulmod(
                add(0x560fef0ed77bc94e16b9d9a21bec0ceadf81b26fe683b9c74b31e2d72a4c92e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6d100d3db14939bb442e5f5ce6a05939f201837007331536440a57c2bf2b609, mulmod(
                add(0x21d59ca7451d83d78ab4d9d17a662367ac84b555866ae92d036d71de22872bf, mulmod(
                add(0x79c066efe4c22c6e9e097e84401e183d3c45c645d986ed640a8faf8fd4dd096, mulmod(
                add(0x6ade7c482d201c23145e3890086b22ab0d43495f5c83b1672316c10ca52af0b, mulmod(
                add(0x78e74ffaf944c363f3fc42cedaea8a9a450ebaac98bf1327590a11e064bd76a, mulmod(
                add(0x5b4be8af83915fd955ba32de729f6f2aef6c76501d82ee325d72d620bce8b7b, mulmod(
                add(0x5522f48902001bf41de34be900783ac957fd867cca0f35666ca491ea89d8fb3, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2c37f85ac7b1aab52ce3d28bfc65c65b7d4ffd000757c07fc493d183b7bb582, mulmod(
                add(0x58fa31f9a4a7e8b238898eb1296ec55e3e2000a48a2edc8e65d260d31bfd7bf, mulmod(
                add(0x4a4eb8f57c99e931a666de76c20173adcde82ff59fd8ecaf8b8c05e29b63fc9, mulmod(
                add(0x3c5581c15733dcc4d548aa0a6e648e075e9be412680a76a556f91ae5f01e44e, mulmod(
                add(0x2a7cd1fb12f896bff4d3db49ee74a51e970e3e386c2c8e7622412a6156a300d, mulmod(
                add(0x179e4b1e4817460085d47376a1971fdcb0287408cc7d11fb62cc3785772249c, mulmod(
                add(0x7e5bc177982061f124cbe521c713c24438aa021fe6928d82452e44f6cdcd631, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x533a5a2ebd098297604e96118f2007ddd12af50edd525e9e5a0b154e620b2e5, mulmod(
                add(0x38bff358ccfd92418537a9b9858df499d2c44404c1886b109edb14c897e74fa, mulmod(
                add(0x8940bc9dc45fd06ce4046337963c849324bbe5f82632b94972c0ccb205480d, mulmod(
                add(0x67c2a0e19b59921666716fe2b3f9c7f59c4da17d993956eb87eece7ef542269, mulmod(
                add(0xbece573771924d045b75bb992a87b26ab067a0f2dba4d1a9efbe5029963533, mulmod(
                add(0x47c3222376f8f18dc6e82eebaab03fcf4c425acd901a7bf9841a3aba54b82a6, mulmod(
                add(0x461b788a24347588e4f8d4f2d66640f31d6b580223a21919ccef9480987db1f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x312411292b7fe7eee015fcfaab65b611bc2b9f9498489fc3c1452862902bbf, mulmod(
                    result,
                x, PRIME))


        }
        return result % PRIME;
    }
}