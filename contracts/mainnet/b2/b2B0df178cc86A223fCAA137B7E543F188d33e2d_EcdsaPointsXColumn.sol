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

contract EcdsaPointsXColumn {
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
                add(0x5d4c38bd21ee4c36da189b6114280570d274811852ed6788ba0570f2414a914, mulmod(
                add(0x324182d53af0aa949e3b5ef1cda6d56bed021853be8bcef83bf87df8b308b5a, mulmod(
                add(0x4e1b2bc38487c21db3fcea13aaf850884b9aafee1e3a9e045f204f24f4ed900, mulmod(
                add(0x5febf85978de1a675512012a9a5d5c89590284d93ae486a94b7bd8df0032421, mulmod(
                add(0xf685b119593168b5dc2b7887e7f1720165a1bd180b86185590ba3393987935, mulmod(
                add(0x2bc4092c868bab2802fe0ba3cffdb1eed98b88a2a35d8c9b94a75f695bd3323, mulmod(
                add(0x22aac295d2c9dd7e94269a4a72b2fb3c3af04a0cb42ed1f66cfd446fc505ee2, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x44a14e5af0c3454a97df201eb3e4c91b5925d06da6741c055504c10ea8a534d, mulmod(
                add(0x749e86688f11d3d0ef67e4f55535c715a475ceec08547c81d11de8884436d8d, mulmod(
                add(0x703dcca99c0a4f2b2b7f1b653dbbf907dd1958c248de5dcb35be82031f7d170, mulmod(
                add(0xb0e39f10e5433b2341ecef312e79ed95d5c8fe5a2e571490dd789dad41a2b9, mulmod(
                add(0x52e5e75be2c96802a958af156a9e171dc7d5cfa7f586d90ed45027e57c5fe92, mulmod(
                add(0x66d15398bbd83688bda1d5372e048536a27d011f0f54a6311971822f55f9c07, mulmod(
                add(0x529414d56e9f6bf4ce8be38c8f79ffab78b185da61d606c411098f981f139a, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7fdc637318ea00385719f9ce50848d13cc955eef9f36a90b87e646dac85e3aa, mulmod(
                add(0x39d9d83e0ac884a5ee0f2d227f9eda71724a55002a41938458e45251e121308, mulmod(
                add(0x785dc572a88712cb4eddcc8a167bb1b62f9a79282f21ee92a0374af76169344, mulmod(
                add(0x1d0f94ce5d9d3beaa42ebed05a2f172aa2227e9a9fee0bf43a3fb068c1ac345, mulmod(
                add(0x51170abac6896de6a5b478741dd56f52b1d2a1feea59b1f26d060e09ed98b32, mulmod(
                add(0x5e2909b1136e1d6608663e5cbabb616b28d2fd6f5dfb7cd03c4a7e719b7c53f, mulmod(
                add(0x6cd537aebc479350e63acbcf7b9da84f4b06c6c26a571d3a7dd416a94a956ca, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2d626ebcfae2d3618e350c190fc636495fbb04dd4a4e563680fb961a3d30d8, mulmod(
                add(0x6f4ab1f3bccea47669a4c93da36db05bd6f5197945b5ab29191a703312ed3a8, mulmod(
                add(0x3ca8d84242dd2bd2a5d6e644fa1dc9f5082ee6131b6f0db8fd7d4f87109098b, mulmod(
                add(0x5b0343972ee9e17afaf76adc54e6797d54e6e47a7ea1167654ce076e3c6c360, mulmod(
                add(0x62773dee1773834dbb324c4c0d48dcdf9bbf0511547feb1b2ab0f7af7fa2dc2, mulmod(
                add(0x4c484b2cc04747d8d812180ec716f779302231983fa17971b575274c0a9c378, mulmod(
                add(0x72d82458ba49cd6c638f89d2e3a68e49944f486cdfb7d2848e51aa9f99292a4, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7850ac1ef437d1b99c026a910b2437c1b877242e605c8f31a456f10e2f78743, mulmod(
                add(0x58a6d8229d82c192f190e55d28489f621cbcc64e4ef10c1ec5663c5384e60f, mulmod(
                add(0x98ad9c2080ba0663fb302025e6224cff41d1d30c5c9101ad77a48a71d8ac, mulmod(
                add(0x4f8cecab5f743c7227a63fa7f320930ffa7cc52b0fff6c351d3e9d4c22f9f9a, mulmod(
                add(0x150c633a21f3cfa157978e9561161f3953e180b9588347a0c819e4173afcfa8, mulmod(
                add(0x34b7ebee71c5876183407c57610a0a8a33d3138ccd6ae416651cd505e5761d9, mulmod(
                add(0x42f0a74ce045e8194b7a5cac4e882b1f1a9face49c38fb3383cfd3d960806c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x70af32c484244d3435bb65b0ed076f48d06abb45b7765de9c6f26c1c8e9156d, mulmod(
                add(0x75275c33b919425b271966642fabd9ea7c917e70e96eda669040935b1d49db6, mulmod(
                add(0x7122e4b28d4ee35902b7f7b8ad5f525b6c70a2f2bb6b4ee4b9f0008845ffacf, mulmod(
                add(0xc1bbae3cf2d414dc12119a0c746e3c10e148f8b522d574eff757d44d8b3a14, mulmod(
                add(0x38ada3df52cd03154d66b7da4a8a01835a461e61a76ac9576649d8c00013610, mulmod(
                add(0x95fd265a2a87c42af5a20a199e6730ee3f0e3352a38a5e7e84ef46c621903d, mulmod(
                add(0x337092590652e19c23b48de3629ae0bd4157a5a72ecd3fcd17bb93f05814716, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5643c5a69044bb8e86d10d3248ea3f50f8598732b0c517b256fe108294e09f3, mulmod(
                add(0x552e18bfefab6c3362cec587f0a7433a914f1359e5767b4fe883f1ad902dd13, mulmod(
                add(0x3a2a902a0e43ab33c19459984fe116fb215796cb40c48e254de6126b55e9c3, mulmod(
                add(0x6925415cd4dbae0ea5e9f41edcb503ff6f668da1cb13ec73eab6a99cd96752a, mulmod(
                add(0x412fcd2551c0516392f685a62b54fb82b9a73bcffd42abecea4482b65aeea47, mulmod(
                add(0x55713c4cc9f91e9f158f70683238853d0bb7cbd8358ff72b01fb60808b5c1de, mulmod(
                add(0x47c78a993a13204796a2fca3b20c0f02c0601e7cc59f84570fa026c65796dc9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1f7d548c5a6f2bc70ff6f8ee47f38221ae25dcb4f9b068054ee66227494f87, mulmod(
                add(0x224fe4f546c8f999947a5864ed0dbcd64fcac6f774ebce11667c2bbb7d8603, mulmod(
                add(0x6dfc1fb08b981f73911dc43811caa0ed99749c2f0903f87f389c9a0e2a88126, mulmod(
                add(0x1a4393bce3924d765902469c715fedeea69adca566859b4c8c412b7d7cb566d, mulmod(
                add(0x57d53073d66a528c88f24e40011321f74ce5bdbecd6ca319e5e770ae29b21da, mulmod(
                add(0x2a2811098d68a747bebe9ca2eae06b604bb307e5f51a9bdac1636f380feabb5, mulmod(
                add(0x542f931640d9010e906b7e1e375cd0481740157eb51500ea1e10afe77f26265, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x268c1e10f6f9969291b1d2f54289371a2f40a14cc67b3736e04eb891c1824ed, mulmod(
                add(0x352b933e5d853527d2a4317db613d07117fad8115948957515bc07d72e161f5, mulmod(
                add(0x44e3645cc1b135410b2a52a5b92bcb454985033615453a51ac46377885c4309, mulmod(
                add(0x27092905558602aec9af09947b70bb974caa3dd7cb1cb991810e15d75194aa6, mulmod(
                add(0x14ac38a4b82b4c65e4993726b58f32c74988997b8e8f7729fe9032cf187896d, mulmod(
                add(0x66ec70c796374a71b6aec5520467ebed547f645d1670b990dfa680a1b415cd, mulmod(
                add(0x735f4476c2b51acb4f0dd9dbc4306108e37543538b2cd3cd2327ae5377a2e5d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6b86f825e41b2c9934f71cc2cb08787d1bd4f2eefd2be9c44e37bf387b35940, mulmod(
                add(0x699e679a8f38a1ecb14c6695a2848c6abbab8a05003e43aa5cf4a9c6e6058f2, mulmod(
                add(0x40a3ea8c4059a1b9138884234381d6d383e66dd48eac1bf05f5fcddd593c881, mulmod(
                add(0x356591a80d5c2e14c3d8a180c030a9529a8580a4f3be00a5a9eea83d0d585f0, mulmod(
                add(0x106911de08ef437acabf58d178db7c81ff4d7de25f3ef5cd2582f44176d449e, mulmod(
                add(0x67dec5ad6ddb1761ec61d2820533f7a2bb56d66f2fb8ecff9cbe28218990061, mulmod(
                add(0xaa81707e389769aeb31cc8b45276af0370dd702ac79461bae0a4078cefb5df, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x164344bae5b9dca8f384612e7351fecde28adee3d245c98dc2f65509b181d8e, mulmod(
                add(0xe5e89fde76daa211fadf1178785f0c25a94d47a468cda257a895b871a928c2, mulmod(
                add(0x20ffc2b4c6c318bee0cdfdca40b2c10f2c629d3b52472b17c1bfd909cb7b85a, mulmod(
                add(0x781cf0ea1c0ba9cf908656aa2c5a9403d54c26c8ece401a2c13be8d3090f9c1, mulmod(
                add(0x367ea925556a875faedf4d61bd2a95a31067bde6e682c50035bb3310cc54b03, mulmod(
                add(0x7b0ed28b968689517aaa216c0203e57f1cf56b22ff1213561499ae140d37fa2, mulmod(
                add(0x4eb2786b11bc602bbf773564eb9b057d7dc02daaf4359c015295d97b74e72bb, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5dd4b3dd252fa7eda7b46674369a2f8c5b00a891cf01ada0ea5aada8bfbf6d4, mulmod(
                add(0x62334e7d6094be4431aeebefc420f7e656459d6fc2cb10455123ede054f4cdf, mulmod(
                add(0x64c71feb673d2655bb1865f9c4bdfb16b1bcd0f278a911363056674dacb812f, mulmod(
                add(0x7a5d11f284ee7db72bed2338784d6467e05cae85f333e05c5610c018a57c2a7, mulmod(
                add(0x72c11bd84cd54152607e4c6e558a28e480a6487e374b865682c167484f8c29b, mulmod(
                add(0x546f65cf3367a004f10e9a4e47d71f6ec80086cb2be19d7b225825e01eb323, mulmod(
                add(0x4063a6202df9488fe5384aaf7be7610b3e88a9c01486c1b88767ca36355340, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x741b0f4e1bf8ed4d6318f5dc5ebba8529089f5ef4a84cd727564c60cc11a96f, mulmod(
                add(0x767d8839373a2e97b7e3de1be6f4c18df648806920e92fcc4da9ab6bd8525ce, mulmod(
                add(0x45ba7e524d75c65ab27b57a6e0b90458c9b0eb651935f84898a5d3cd0db9b8e, mulmod(
                add(0x24327b5849aaae0d313870c10e8010a115b70a99cf6b92925f51d2f05686287, mulmod(
                add(0x16f35b8d34d425a85fe48e66632d3e4af27d5d65cb180cb99047fdc2b908ea6, mulmod(
                add(0x42a6c571001e263b1ec8168805bf4d6cb65935cd0687c696ae3a6968fd28378, mulmod(
                add(0x3373dcd7d0f0f8bb31ec396e1ec67e1f121121356dba549bce9fd4d3bbfbaad, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3a967c407600baaac716275b8fa16a08c22e928d895c762b2843d00496b3390, mulmod(
                add(0xac01d3129d24fe9b9209df8bfeb2526bc27e9c27d78f69eac16ce151b13540, mulmod(
                add(0x29a66c93ef1fa5ac4b6f96ed329810085b294a7ab8e16c61b1e225fd7406236, mulmod(
                add(0x327bd35b3ec38fb121c039f777669426d3d60df3922e688a408a06d4e7ee3a1, mulmod(
                add(0x5d6575134d1b37e610f25e65bc8b0b1ad7fd0cdcaa56fe573142a09707640b5, mulmod(
                add(0x68edfc809bfa6534b583624db421a2cb885d2ce888e6f95eae85ad9cb38249d, mulmod(
                add(0x68682814e1b4dd639cf396a9f60efe5ca035c6ccd75054b8911e8a15230efa7, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2c82b2a99d198138ca2c4229a1929d044b113c1b0f693659712318ca7e7f804, mulmod(
                add(0x21df6648e6f783b7361a20191b8d399a4373dcbcc83f6b4a9a40bf11956219c, mulmod(
                add(0x7a615360e826e937db0c91cc1c9196086a3fd608cb01d20186ba1ce856904ed, mulmod(
                add(0x580bd7107af3afc93d0cfd1f0bd39f78f06ebe3a900f5d79943c25e980e5653, mulmod(
                add(0x3abd943152451107f59aa81194e7bbbe37c4a86a6b41e20a02f8145dd32fa87, mulmod(
                add(0xa8a00bb9874fbb44ee3411814dfb9d4d6048f5e3af6f7f09fff4e9f0263901, mulmod(
                add(0x4d111629c799fb16f602183ae372aee382e0b401312951eefe77a1674575242, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x51f4698c121db3db4a5244334c5180cfba256dc80a59689e2c0f1f8d946e6c, mulmod(
                add(0x5ae517bdefe7b6785680842685de0b5cd972a22dae9ceb50a6ea3665feb06f0, mulmod(
                add(0x46efbcd0bd7f06d59a430ddeb9f239d66a24ce1fa72f5dbcc2bab48b707b2dd, mulmod(
                add(0x164d44fb88efb41e301934bf2c61a20e41c9bcb3f8e784ac5857063b4fc3d5a, mulmod(
                add(0x3360af40b57c0a951da3219025643a76516f85119dfbb05f61874eb3b56b130, mulmod(
                add(0x1e54c3a5a3beca7932090ff58784aa43261075950feaab0e2a840f3801b81b9, mulmod(
                add(0x6dd74321080cc46d816a963c8a6f5dac42cb11e66c79831efba77433cce0d23, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6f682eebabbcbfa3e7084b47b2a01acb693865749df222b4b8dee0ec41903cb, mulmod(
                add(0x5fa6f7f2a7a527880a5b58911dd7f3a491fc702f481cee30e67c4980092f851, mulmod(
                add(0x1a36f20817da4dc0c2e8b62fa08ce15cd3cb50419acf5211d6948bd6b28c8ce, mulmod(
                add(0xdb0ad3bd8a33b8daf1d53ff8604bbe5259b6620e3b547d5c6f392dbc10ccd5, mulmod(
                add(0x44be18892438118a0b3fc099da7489a89cffd4206678abfd37b1e649ad19178, mulmod(
                add(0x3dab30754623b91aec7a165cc167e9003269ebab3e551781e4c8cfb73402de7, mulmod(
                add(0x67d2681fae96c0b4bf22d10a73a1882c5bf4a5440f8d0458394d514ff7bd18b, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4182bea2ea16dcacb0194876cd5fe8c79e1a55836aff8aa6074d235af5f7b29, mulmod(
                add(0x2300892e3f3c180333d091901ba99ab9e23c7947309b9e88ad47025847ec3a0, mulmod(
                add(0x23f0124cd1c3f3605fa1ec36dc4d6cb6e229f8ba8998b138a44595f96f3bf21, mulmod(
                add(0x3054d35b59baf5b0a2078c23322de031b383033837cd6b978b6c060120b7fb3, mulmod(
                add(0x34369f479f013d44dd5bb0d79d8a9effdb2ca36ce8b3d7e759bf707233c5bbe, mulmod(
                add(0x7172b43d0c88348e5453b0b26d54d4a7ad7e99e6b0c4b787341c8d89936197e, mulmod(
                add(0x1fd7088411b30cb5762147b1d6749942485b36c68ea32f60ab83fdcbe987d83, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x22a7b1c897f54da39a1db61b345b234969e36ef6ba0ea02f8d8b3e83b5c6242, mulmod(
                add(0x734438bc30566591da45df9366f936415d29eaeaeab392488bcccb9acf0edcf, mulmod(
                add(0x17626d3869adf0fdd3fedd48e9fe1266bb33419bfe9046df43c6409b440980e, mulmod(
                add(0x2bebc90c59dc0e37e28c7c7d8254520ce08894637bf1a089aed26012690d119, mulmod(
                add(0x2693f31fd4bb5a1ef9cacdc4f2b33c3d6d965b76e7bf289020ab1b6c6660d70, mulmod(
                add(0xc37f91c81a7006d6681cb511dab2e4d83928ccb78d1dc72c4c556e4cd72db8, mulmod(
                add(0x50f3e383aaf3533fc91b9633386542798abd69b79af893f47f6603d3cc35ea4, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x17f2709d2719458a9bf72a2b04463f0a6529fd9368a47715c628ba4e006cea, mulmod(
                add(0x4b540d0085be455b24f014bf51dc7d0eceb8c93bb644a5208fa02dc58c718ae, mulmod(
                add(0x1b1c82e5c561dc42f8c9c2a9f7db6bacd729b2646892a8ecfae9ead9a338aa6, mulmod(
                add(0x375ce3766894524209e2043a150f10ad0bf4f726e3dc5453c3c757e56943a51, mulmod(
                add(0xb10494024548b14df121b738abc7babe56c12acc0490699443426a52f3a4f9, mulmod(
                add(0x193185be6e02dc0a07c0dced4ed031bf0a406219cce325e76408123406c318b, mulmod(
                add(0x22eef827b9d0b57649233c5d527b4641decab31df78347a20da21c705df093b, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x56017977a273ad0e91c7c26a702ae4508343e97968295b08447b3cc7f20522f, mulmod(
                add(0x4efcba706a8b7868e32f363efac2696ad0625d046a3ef97917c710515016386, mulmod(
                add(0x31d335bd885c9cdf2adc68ab45b8eecd2d3588cf85b93206896b2626eb1e369, mulmod(
                add(0x7ba5194da963f8224987db2720f16baa604ff62351e66a63c0c9dba00fbc7c4, mulmod(
                add(0x4d3b0654fd74862a92aa716af33b5ad5ac20dc0460c724d95ca94fe6d8a9d7e, mulmod(
                add(0x29cc816e6be353f6ad5e2c390f37ed3940b0dd67610a7eeb0bcded94bdcf920, mulmod(
                add(0x20e468bb2828fb774d5ab538ff7f93ada201c2e392936e05cec29cd5a7a462d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6e1143b147dd1bcc56dd43e6a3616c9a4016d6887cf0009ebf9f9796efc944a, mulmod(
                add(0x4f9e975176d3aacd79c322d013c854c4b8829d1e469c9b242461f35e8dc6fed, mulmod(
                add(0x88f6e5a835dfda9fa2e2ff248d9378352f4a89b6bf5935700da390baebadb7, mulmod(
                add(0x62fc206aa283139f7451e54cdac873fe86b6e7e89214a3c0318fbcaf6016fa4, mulmod(
                add(0x1b389d976c22a3bfb42424896c9b135a3794048724c729968f81e04ce414194, mulmod(
                add(0x4237c41364975eb79919303fc0a381b934befe871fdbd72c18f97627292923e, mulmod(
                add(0x16416cc193a5ced6ff213fc18c86bd6f08d17c576f26b9ebd00d2653bbd6444, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x58f2e18613b3b25529935a623e7d5c8318ca9ff3fb180f16f7454ca9e348e35, mulmod(
                add(0x2830a6edb344b7fa86506557a0b2b0bd900429218fb35e7990951fe4fe869c6, mulmod(
                add(0x1f573af6e3ad146eeaa582f540de6a8db237ff2f28423660de998a4275bf4d0, mulmod(
                add(0xdaf5a68420fa7ad811f6dc75c5b4e92173a5d89255dc75accb8cec80a9cd91, mulmod(
                add(0x59cd87f8751437900e984a009c63fdf7461b177067760f30d4f648ab271660a, mulmod(
                add(0x60c327ef73c8468805ecace45a33ccc375fc91ffbf01b4b10a01ffd4b7aaefe, mulmod(
                add(0x284c547c04ca83fdb01020cfc797eb362838317f09e5d25e1e4eef353ab7a7f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x16617a52bfe5d2fd0eedb0d6411f5fafeb14a4ac17da0cc828c914acb500ce9, mulmod(
                add(0x3030332e9cf430f72159914e59ab9af532bdfdafedc1be39691256c8084954e, mulmod(
                add(0x2b2a0768e9a5f59e7f33ea449690794c8b409bacd1c808f7ee8065ed9d8648c, mulmod(
                add(0x13fe84c8ecc2e3fd289560c0ada7a251fdd5fba24c076be4be465feec4262e6, mulmod(
                add(0x413fda31150aa8462deae8a6043fc5624599fb7f638c4d5c5f89472e1223c28, mulmod(
                add(0x50d603bf9c2a456b828ae476092affde072ecd878877ec3f99ba8f574d263a2, mulmod(
                add(0x42c8f0b5507417eb48ffeb1a7df8808633f193c27df8e2f44ee7bd62cb2c3bf, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x511c0ad7c0bfdcfcfaf925895a8ef5e8c5e0d147e29c9cdae45fbc998fce346, mulmod(
                add(0x62d6874b6dcb1c4dc8ed797b9158da4359c6c49f27af4851a12908ecad2092e, mulmod(
                add(0xbffb0e4f7ccfff0cee519edd1004eefbc47024f92c4409bbdf688c133ad285, mulmod(
                add(0x3f3ae3871460ac578f5030d925e91c138f3290f8f3cb6d4b560b4b16fbacd64, mulmod(
                add(0x520b18e79de342aa7095ffe56be6222b0d2e44fc3c676a5c994f24e427b45e2, mulmod(
                add(0x3939ef0e572dcc3b67f0cb819fffc521df26e50814281621fa6982b1465f786, mulmod(
                add(0x553f8ab49053432bab53835480b6f4c416eeffb3470fb6bcf122741cac3d71d, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x508243aa19e23cdb8ca0154055c05130462908c6a2691ae522e37ab9d6168f2, mulmod(
                add(0x28f86fe2d71f9410e14c17195ae19c2c5e623c525c979f4f74dec3ef8848eb5, mulmod(
                add(0x475f8af086f7aa4ec3739f754f7dd291dc50decc7c7fb03de8aee3cf06824f, mulmod(
                add(0x1cd528d070930aef19e0f928fc744e79ff57e227b6aa1bbfce15a79166aefd8, mulmod(
                add(0x19cf240d04f4859941f9b6af4a7088729aa10307cd08aa75f01cb22e872543d, mulmod(
                add(0x3cf3b95ba351a72019ed1bcadab32116adcf079e72800a9d88f15244e7743e0, mulmod(
                add(0x25199c11f7193e07191cd9b9108aa8b440ce1972dd1cbe5f0cc33b7783203a8, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4acd125e74056ca611a1b07369166eb5c02af7a4cbf387b2bd584a362fa9e60, mulmod(
                add(0x4d8d9b92b38a45147bc9c87c071672edd93cbf5bdc8d85e608f26f1d82d172b, mulmod(
                add(0x1d6cb5a655919a581078aa2f8a21d300425026ccd7d047302443d78dbc67abd, mulmod(
                add(0x44147236daf669f8a94b7ea353c3dd7e64312ece01ccc1d4dad67916591d50b, mulmod(
                add(0x19a0ff21908842e412addb744b0ca384a54bdde819f6337c4c672f682fea9cb, mulmod(
                add(0x66336e2e2eeb939818f861fa4aa9b2576936470f511786f8fa3417850a6c2d, mulmod(
                add(0x37cf9640e321e7bccf1926d5fea92918d6888c5805e27193722995233a4adc5, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x589a2e11637d0c90fe91bb9f4d55a80cd1a2df7f3431e8b8bdce8fe7d35126c, mulmod(
                add(0x3e09706cb43c83143c9dc46f97e0e1ab4327de19ced69badaa8b2c80f68fb9b, mulmod(
                add(0x24adf288d61c113e28d9a298d2642eb67586019adcb952abf274ebe1d30e24a, mulmod(
                add(0x1c1216fe648d287c2645dfc5152e171f25483df5ef112b745c2e59b5d9ee07c, mulmod(
                add(0x4758304a75f149e24563c2b22459151389b86d36108f5dfe11ea1fc7a64fd7, mulmod(
                add(0x1f27c20f47daaf01d4627d5e9bee0e9bd2aa5b75807064cd60ed87e307f677a, mulmod(
                add(0x3b4fdc8d965de1761e445ee88cb406f707f9d0b1ea3c069d12084c0ccba9b44, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xab2147a23a826d5f7c6fea5bf889eaafb5531721f31ee0a9f02fd58f09f65c, mulmod(
                add(0x2cc90219912af16cf9a39f57f8b8c514f797dd5d49dfed5eabdc278e31106a2, mulmod(
                add(0xe0b21e37008355c35f7aee295a8b2b72465866b2bd68e72d36f032c34b38a0, mulmod(
                add(0x1fdb038204ac50e87e3e7239d8c1c0572893ba98e031c982e545e6de64cb8e0, mulmod(
                add(0xc3e0400cbde1da659381240d9c84b977eef3cd70e3e4a1a8763a05e682eb3b, mulmod(
                add(0x3f64b3a307276c6a7169c54297bb12aaeebadec98df6ba1184492a82effe353, mulmod(
                add(0x5f506aaae7ce6d94712c9e0ab02bd2a4ae09600608d54a8ca381b8e96222cf7, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3e3aa48bb5db9e2b0dc6d294009ecd5d4ff6255dfcdde3f5b4e545032ea9b68, mulmod(
                add(0x18f9cfeaf2c33e21d7c6fd9e15a3601a2fb3905588868167566e8c1f1dd30fa, mulmod(
                add(0x20096a7aa30c6c42f1d5f1ed88de275d1d1610f2548711a75fbbd72d373a50e, mulmod(
                add(0x13d322a0ecbe1e785921a7aa6f4d1135e0798e72f4c055226205314b8348144, mulmod(
                add(0x40fb948f8a4a10d2b2e928a5d77b481f8d3068b47fa388a3ee65609aade1a41, mulmod(
                add(0xfc76b77f717a5b3ecafafadf29e7f886c8ae67a3a2bb30467c440472349953, mulmod(
                add(0xa5d4606609371577b0d17fadcd85ce659885b00245a67b038f902176d99a7c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1bc1186238f0d39e1c56185a8d2bf00c90c9c89647917d60a5b762932856524, mulmod(
                add(0x7736291268c775a82caea06004d53edb829be2566fc7c4053b1d850a8116cac, mulmod(
                add(0xe08853aabc9eb934b4470bb4ae1dbbe90c61d2093516df998ca7adc98afe10, mulmod(
                add(0xf19faf3accc43b56369dccdec35dc7b49c5b8f8976764886bd16dd2e155f92, mulmod(
                add(0x18b8b8d0f393950c9a2e674052150a328d214618049c7e2f58cbad76adbfbd5, mulmod(
                add(0x7cdb723061223f33289237c7476e737ef0bbc5e2c1ed9a70566511fc2036ba5, mulmod(
                add(0x425b03b0356b92e66ca816869a76110d68862a0d8ad76f950fdb1d5c03279d1, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3ab2d353537697d4de9c5c4c0bc31e5e776cb93181029144f6c6d4b5ea4317b, mulmod(
                add(0xac068a1aae938e26e125b35c88a87130044bf3637bf1acd797103e7388b33a, mulmod(
                add(0x2d5447623584d3a19e9993814622d6369248bc61813f067c4825c9b0a81551f, mulmod(
                add(0x60db5bf6f060d82c169a1c4ed6c548d5e8cdb6cfd2e3257c155bf11f48ca609, mulmod(
                add(0x66e1e25d1bcea87acd136f2c33498e3223fbf78bc6cc816ad6aaf68e961da0d, mulmod(
                add(0x7417da24519b4c55ec0d698ecaceeb49711aa1e7f7d907102351e73388a0fa5, mulmod(
                add(0x6cf772fa8050ad8eb87bc8f0c8fc511622b416fdb084cbc93b79501c96b0bda, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x68d729620eca6b4d904198a0e6d241953b9b8c874a10b5ede5596146d560979, mulmod(
                add(0x63d4964faab567e795024a17032ec564ff221a421bd2e42632d3770c73dbba1, mulmod(
                add(0x195f98a85cfe403a7d229a6eb4533a1fea641c331db75a5807711fdf1e27dac, mulmod(
                add(0x36f446f7e5a51114cbdd3b460431bacb5a42cd61f4690cf5e9d9f13e488318d, mulmod(
                add(0x50ee695deb5a4e63c5dd6de35621d1c0c5a496bf41fecbaa929b2b3e23f174a, mulmod(
                add(0x1ec5264a5287f1c6de79b3df3adbfa157e8430e594078c3fba7002a077db447, mulmod(
                add(0x6ca2dd473297a2852e68ea2b83faf8f71e5cb471adcc74a858132c6a823f0c0, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x364889e46da58b66c827835a0c2807338eeb4431f2099f490d13bbad0777a01, mulmod(
                add(0x6afb39d46d5a846e9d58a6ae27e6cdd83bee29c72754cd4cd3d3cae423f5c9d, mulmod(
                add(0xd62eb553de83e5d51f78ddd9480d65870dc426f61153e732eb6cd62cee09cd, mulmod(
                add(0x22cf65c6bbbf76765555748cc1ae91c83ea93ca2c8b34a59332567b5b3b0cd2, mulmod(
                add(0x2322f8d96071356feee538e0c53d857b1924134b94377af20ed5d0e8b3925b, mulmod(
                add(0xf639bcd7777c1ffd41a693ac9f5a051bd124b7edce3d568f14304c9fd90a67, mulmod(
                add(0x1137975bab819ce0cbc73714305030fcd4a185f71d46c169908460390d56d18, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x26701dfe3cc76754a4ab893fef59886a43013ea6ba648efd82fd03941fa2910, mulmod(
                add(0x2aa45ec320ea12beb804e35af3684dc981324dc9bd044592d1c408c052a4322, mulmod(
                add(0x50be25e516e30f96d8b420a7c494506d2cd21d64f4d5ecb67d58c2ae99bf5e0, mulmod(
                add(0x4de47e973af27fde9ad29f812de8a04855110118eb73fcdb46865390486a287, mulmod(
                add(0x1ab93f16e576b6a54598582eff5e2cfc33baeeb607826579680636b05046d16, mulmod(
                add(0x5c180e2fbb2b51e053941d0e1611424fe60ced6d439115dd98530c8d79cca4a, mulmod(
                add(0xaea6f7f915e4aec612029a9d02316baa3f6297ea4cfd38897f4c9859ec485e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5626d2ae9581d1d335bfc3863a4eaf3568ec8e70fcdae93f50a15b0cf601b6b, mulmod(
                add(0x7e84842d5fff1666e01505f62661bcc822dd3fa530ebd1e4089230a4045a04f, mulmod(
                add(0x596f89b6ca79194eb6a87c17692aa491f5b014da3cc7e5f05caf4fc1779c2dc, mulmod(
                add(0x3e2dbef5f162784e13b5ff4c33bcbc444ad1546922b293d6783b5de5c5aba78, mulmod(
                add(0x580f9d95c2bd746c9210a87b0f9ed275afee1dde7a41d9ad5e69861ec0e43f6, mulmod(
                add(0x4e92d5f575fcaac9adedb4e0c3549dc18f61bc40e3752e3506f3761c32c6e3, mulmod(
                add(0x1773ba95dbeaab6e5e9fc79ac153d46be1e57828e92287d698a3f4f87ef4984, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x679061e5f453c8bb1855dce8f7d61f2cb64b15d2c4e70b969ec4ead3fc6a226, mulmod(
                add(0x421fac0e48da8e6355c07f6a64bcea96384848e8ea9a7113ab45f15b1dd15aa, mulmod(
                add(0x4d215dd42f87632a9cce2cb95081dc731e36796c3d2847dc96a3554231c6aef, mulmod(
                add(0x68371fc7cb3e0670a73eb3a7e773ddb63f231c26bf25bb1fc1fe6e93a7e3bd0, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))


        }
        return result % PRIME;
    }
}