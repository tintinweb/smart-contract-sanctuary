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

contract PedersenHashPointsYColumn {
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
                add(0x7e08f9d222cc0764fb5ca69e51ad4cdb7f1b612058568a142bc7a4cdd0e39c4, mulmod(
                add(0x29f6aa5fc92eab8b8b9871c8449c1f617b808ea9860717f3e5e1678672ec565, mulmod(
                add(0x5115ade709c058be5dc6f406794062642086e431bab03c9a86d53c79aa83db4, mulmod(
                add(0x2d6129632b4fc43e4142abf55fe2d1f3e79dfa01c73d8fb56a465dbd07a9682, mulmod(
                add(0x14f3359ce0d2891d1bc2b6f4d2d6dd71fe22925b8a09f66147db095a9d4983, mulmod(
                add(0x75a127d817aee244517479bab5c4bfc2a0035d43d673badaf64d8adf94353bd, mulmod(
                add(0x62b07622f501888a668440d9b856be4b0c3bf12a401fc2bebaeab4a7e1684ad, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x55e928ba557ed7fe0ecde6d1fbb83d112e6b06a087b4013b9c425fa36eb0415, mulmod(
                add(0x7492aa940f34a027f8fb3700f29cf628c1d05d1675cb7865509f20617a90b2f, mulmod(
                add(0x2cd9a093ece61e554b2bdde3ec474900e4412775ad25456e5be6e11df7b9fff, mulmod(
                add(0x707c572424682b685a1ba90dfd7e56f86254862d86e20b5a2d3ca85fe0017ad, mulmod(
                add(0x68e1d50b4d0570e357eac7bc742ec26dac1edc5b179989c7ae8d31791639103, mulmod(
                add(0x2b7d501bedc4e7c604b0e55dd2d8166fa39a541efc24d81d8464fabfef3fa37, mulmod(
                add(0x54c5dff0aed23c07edcd958ee3690e617011b87a5fec541725237d4ebf34382, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xd21afb1901f1b3ad66587a7fb97ee06662edc3bc8c8d32b48625a135ba23a9, mulmod(
                add(0x7b056cb6f172b25e3555d6b1422ff769fd4c07258fa16b03609f0e374012ed4, mulmod(
                add(0x60ac57e328ff6938a17d43e6137a55399b95459be60fe980ed8960edaeee10d, mulmod(
                add(0x2d2d27711772cafff2cad828dd78d8b213e317e8939cf79164ae64dea577d61, mulmod(
                add(0x133b6505a6afd2e5fada0e53ea51c012e4935ea6d2d02caaa15ffc50a45079b, mulmod(
                add(0xfd48fb35400aaaf57d130b6143b241db8af174cada72ede8f2fac4ec6688d2, mulmod(
                add(0x3cdb28a913a41d597915de055aecc59f2b13079d3d8b33ab0a075eeddb1bf8e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x58ccfd44df4e339c65e1423eaad47210f2e16aa6530d3d51f38b70e5eb3a623, mulmod(
                add(0x47275cd67ff3b7637ed55ced299a6142a821ab466a897f1eecfc8bca557269, mulmod(
                add(0x709be747b0a69a9523680ff69e6bfea4637bd570ce5c45256b39ff695557da6, mulmod(
                add(0x6aebd7a9279eba43cb1c0b14bb723dde464a86cac92518ca16ae27a8684d9cf, mulmod(
                add(0x491c2243a95c44528b86167a4418ff9d93a04bde8dd7a5d2b19ea579d295312, mulmod(
                add(0x7c1667b8d44d288c4f5150d01c5206d4d5868497630745b6916466c8a5b1228, mulmod(
                add(0x7784c2e140072fd26e95911df38f9a337107750a72b9ce05a21a0f781b92dba, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xe4d1f1f1f9b379bea473f76bc8f3c4d530335e2d6bd782b42324872767b628, mulmod(
                add(0x66c5222dc133e37dfa0566c49d107852d978eb7454489d3b2ada8de022125d8, mulmod(
                add(0x62ad4d764ed0072a7649425270e2b210421c77d3ce98e2587ea5440a591ecc0, mulmod(
                add(0x8509234000e130c8828328ae4997d5116117716cca9490e6e63f30b7df699, mulmod(
                add(0x4dd38543d129d0a71b1836c6e2eae47fde5d572e32ee9a5791f7ee823eab4db, mulmod(
                add(0x660bd8049bd301d093aab9ae530bedc37467d4ff0a12c89d689d61ef9b9546a, mulmod(
                add(0x28218a1bc7586b71ec1989082b8f7ab0efba14569c6f6e5d7aeee1964ab6d70, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x31eb3b57e6844e3efc1e3975ea393476d8aace5f43ca62b09314c90b8ae9688, mulmod(
                add(0x539cd2c1a28df263709cf0eadef73a600f563ab3d82c27692b1424814cc3e15, mulmod(
                add(0x45970c86c25bc9a68f2e2a34969faa2134c95b19230fcfe7436c98f537539eb, mulmod(
                add(0x2dd27ce7910e44ee00ec3335bd79429846a70d92d482adf81b36a9ff1aaa30a, mulmod(
                add(0x166b26359c51d067955874f5612eb70806d7b8d5de4d8e0a75e0d57b39b1846, mulmod(
                add(0x59d753a23735a336c50466f5ccaab3671230fbdaf55101530e5f562a5efcaf5, mulmod(
                add(0x6ac2f92bc4c04fd50ebd3e336b53b866e790ace39838aa96a4b791011455b29, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x75971517855ffbc9657dab30657ed1e3797307bbec1ffe136cb0d8a64ed6eea, mulmod(
                add(0x5b02adb78afd4e219642a1fc38b2ef9f63926841ccfda072ac17326d3d50f3c, mulmod(
                add(0x3132d42e4a928c08a972e17b2c3b500dbcadbe6190b2e7f5b58300a0c8a38c6, mulmod(
                add(0x559548517b1025ad61020be3e252b6ddbf1d5d53043231f8850c0da52b8268a, mulmod(
                add(0x4538fc863186b4babe3b424b4111251bb1e20ba5516be54160cd560ec0d5a3, mulmod(
                add(0x2d8ae7b28c8c3acc8bef3d4c2a9f5ef1323748de693a9a1ad3ff8601116b165, mulmod(
                add(0x47359c8dd2b86e4f634a9a50950abde25942877bc5db93d62bf43d2886692e4, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x628226c46fe0bfa8aa36074ed0785cb16461ee2945ecee9deaa6399bba2742c, mulmod(
                add(0x78c7b0512cae47833eb6bf01c1075aafca19eef9b32e37f4f9a9eff315637c7, mulmod(
                add(0x218da336adf8608530fdf8320c4edc00631d36c8726430732038a369548cf56, mulmod(
                add(0x7e9e1c3d4bd3231686c235a495f737a9ec3d633331a95d85e17e90f99a08af5, mulmod(
                add(0x2037a7d08a1c4fa4d5d4f53436a252302840007c09163026637e9cdddc958f0, mulmod(
                add(0x295fb60eec46a40a33b1a9532427b42e224c0ac6c50e3c1c5d17c2c16651a25, mulmod(
                add(0x174a4710688db61da7559255caebf641a268b4df53d45de5e8156d36b4b2ab0, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x76ea16625d0cf0c04f096ac7d6eacafd00809ef1d1a3cf5e37dc2a13a02d303, mulmod(
                add(0x21706619a453a544bee0ccaceda9fe69f860c894b36bc9cb7ea4455dd88a9ca, mulmod(
                add(0x55ee57d4096ccf0260baa2a1a2639978d965a786e4fc917cb2426f8a99591d2, mulmod(
                add(0x1d5fc46deed0eb9b56cba1d2bf8075227504aaf6ab1330b346cc3cb84a07cc8, mulmod(
                add(0x4221572cf29651f508bab9eb82545b17cf6f9efd0416b65262e5491ad408e39, mulmod(
                add(0xdf82eebd6cde9b50958606c6ff83c855c43ce9613fec366c7792cb456ea913, mulmod(
                add(0x2eb6bd70a00ec26418d347df1a444f7ba0972416103f00c771e0f3d50bd8e5, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x27e3cfc87448bc0392a0d6c1b1aa06626636fc703bbcf3717fbe6f0759c4855, mulmod(
                add(0x2a45de0b79a4e9c53d47f6126d35b1d050775d5fb17f3c3dc22c7b6476608c0, mulmod(
                add(0x519de0df91b17442a8f60b512297d69a1b516f70f67d76eb9c287f06e37c55c, mulmod(
                add(0x2ef7f1dfebad70ef549da1a143c838cea27749807efcb1a0a29cfab16420928, mulmod(
                add(0x12b9157240a237f319beefb6019bf0de1897b9e2d8e5536e3a21d8f9fd689e7, mulmod(
                add(0x471bb97187c83c0e7b51ab70022147e8d8ebe25d4081907e7d1bee8d6c6581f, mulmod(
                add(0x6d0d885e8d2530c7a324f7b2ef47db35aa8162289a4420a54f13a82b871d850, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7ce49a9b8d374e1174ae6ccea7cae8d743404552253f7ec854317722a5efffe, mulmod(
                add(0x2c11fa8c0ba68518942f1c686dafd32aa26545886d28cdedae00071360df674, mulmod(
                add(0x6a39a27be962632e0bfb245f65a4d70912d1572e39003d63def5f45bbcc8f7, mulmod(
                add(0x13eb9f5362c087af5ee758bf0b589c0e34af337b3c06c788573534e96de30b7, mulmod(
                add(0x25dd21ff92e6f1075df6b5ddb2b774ff963b1b84a985261b1e94ca9eedaa49d, mulmod(
                add(0x3139ae970d95891aa70cbbf6f172223e07eb521a5149b7e0c9202793f6dbdb, mulmod(
                add(0x77a45066995089dbd4072d6817397ce0c7e92b53d19338e9bd7549e954bd961, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x154a5ad294d41caedd8d927eac226dea1e2b78f6ed0a6901a00e45ae0ad78f6, mulmod(
                add(0x1cc7ec07c4e1e6626b5263044071687d0ad34ad4d08996a213380e9b728585b, mulmod(
                add(0x648c35904fdb8bbf9c0bc9288319c248e17974fbb6616a70acdac004878bb9, mulmod(
                add(0x76914b565dab13e76053b7a74c24c005b0930011e48ab26db44b6b49a1e7ae5, mulmod(
                add(0x2c29d0056cfe7325567a9f2d09d917b37a45aa3cefe20b78c4bda2942af59bd, mulmod(
                add(0x6123efb57144c151864b4f717a44cecc667fb2ebc47bf24bda4f7d0ef8f550f, mulmod(
                add(0x6bf518769635f9fa39c1258844d4f62e5fc00b70792944da0a939990492313b, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x61b210c04a0899fe2a3dc53348507d6f53d4cd3831644e4630eb40564ee5b47, mulmod(
                add(0x6dbd918c7623bb07b05ca515146ddd7193373250e0836062fd1c430e2b7894a, mulmod(
                add(0xe2acacfba8f832e4e3cffb6ecf4675df678403610fe91363172229444ac0c0, mulmod(
                add(0x79c11c262fc2efc9aceafe4a5886713151352e60c4db45826e0e343cc5919a9, mulmod(
                add(0x5e48cfc304417473eb4e587942a76921fb007d8b11ce648d36828e8cbb5d595, mulmod(
                add(0x2b2b08bfc4c3d5941538b2eda43b3cd009656cf83b6b23be56b3041df3dbb0b, mulmod(
                add(0xbd5fd7dcc1ce2bcd7f7415a22115f0c846d16ac7458e6c531e7e44dc664962, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1f3e3e61713ab64544b28dfcaf4da25b64e625048ca55cc783dff614f5796d0, mulmod(
                add(0x2b6a2e9d453e19e3d766f24cb7c6753f84adca0f75f7a871092688bb5ba0d37, mulmod(
                add(0x43aeb91e6f453d372353d9814a85c21617e6c934c694a0b06100e1e9aec4087, mulmod(
                add(0x10382fdec78a18047041629179e18ec7dd067bed125bf5fe83f13d637a8ff67, mulmod(
                add(0x567205f3e5ec69ce7962918c41ed0309c3ddfd85fc92702ce1c207b282f17c2, mulmod(
                add(0x3c99839cb11fecd878ab9efd1d2ed2a718f6e0df4caac1a070de06ddf1a6091, mulmod(
                add(0x1e3816f2a6a4900b65d140d144225a8a81cb3ea22f56de3cbcfe3944fc0e898, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x787a6c80d5a23f91cb91d2508633cce6125da76e797ed460256933a4e6a24b7, mulmod(
                add(0x3085800be446839854dfb7bd9ea67ff139267fb5268faaf153db26b00368630, mulmod(
                add(0x4e28bfd662fc5e09399fc49a49a622a7e845631244b9472df8c91c4a703321a, mulmod(
                add(0x8981cc99962f20f8814162568d9d7edb7fcc637fc6907a98b1d1eece9811c6, mulmod(
                add(0x78e4cf312ec50466bfea965b655e9514d9d69bf0bae566fc88187fe730f70, mulmod(
                add(0xf9762bf5620ec90d711f12cbe600f29906fcdcdea4f17cf51ffad2e07887e2, mulmod(
                add(0x364cf25e248a3f2fc2106025945389328c0ef37848a59ff2afdc685c0854822, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x41052d90f803f015bee5bd1a5f6e2f78f30439ecbe39861cdaebaa8f7c56371, mulmod(
                add(0x1e836012f5509ea2f3dfdd474e9e4a96f6924e6619924ee4c6870a5294e26a9, mulmod(
                add(0x43fa3aa05db6331941265719fc1ee057d9f3dc81704f81c2ce7faece0fe86c6, mulmod(
                add(0x5ffa0d51bff335ad53cfe99165aa64f5ac1b01c360bd0101856537fb03da5ed, mulmod(
                add(0x4f62f4d968964e4908d16fb9412f8d10eb82e14e83f3e094a02470f27eae006, mulmod(
                add(0x58afefb8e3180356e33794e20db869aba4bd4e5dfc795f8089d6f123025179b, mulmod(
                add(0x5ad768a2e70b4018e505bb5f6f44d249d9f5ba5f126106cde9be7726cf5c0a3, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7e31ce22d2a3d776ad90e008ce82c594dab9ff2c42708f4f0676000cd86891a, mulmod(
                add(0x64fecb621f4dc18fa1b66152f28bdd15b7b12d495c496e77016bf3b979e4b1b, mulmod(
                add(0x17a1bf17777a3b56a76df412810d05c9e222027aca604791694d3b020ea40cc, mulmod(
                add(0x5b553a6606a3f01d862af22a3309a6df0aadec753fd1e0321b0eb08504c1f12, mulmod(
                add(0x6620ec871e8a2c03933d0621b13e7f357b7349ea16bb549e7e15e2652692252, mulmod(
                add(0x4b7236fb7f8b72b2d369effbee5b4bebe7d2205ed72f9831b41c711680cbbf2, mulmod(
                add(0x16f6ec82023f48ea80196121afab584b9bce7f01e9515d0a3b489d68df3e2a9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x14714592154025f15704e279d2db4c70f545137269ccbd82c11fba275bacc85, mulmod(
                add(0x22cf3cd9fc0103158f7de369046ac0cff77c44c3f9c6ca942616fe7d59d6231, mulmod(
                add(0x51443fc9bbe11d787df4afc59f4366629cfb3a14c80cda1caa1ce6107fd063f, mulmod(
                add(0xf8bd8807280892ca46c092b74f845d90f3a6b61b197a0594fa30686ca41a5f, mulmod(
                add(0x4509575b94136d744c8679c3028b0db514688db5338c4bcc9f50ccd7d15c95f, mulmod(
                add(0x35fea15e2101714f172da73da6ddc2077ebd42ada067e7879bba8c2ee1d9db1, mulmod(
                add(0x43530eaa364a9df353dcfc154bae168e0fa9b51a3362c6cb351d47bb7f6b829, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x203ddf8cbfae2898d2d2f183cd0efd1c3f7db1b84b8e96e38f2b87b4bdad1bb, mulmod(
                add(0x4ce9244cd3966ce1a6fd7f8b85fb1c8751e35aa53032f8063535665ac3a69f6, mulmod(
                add(0x20d846afc1a11dae8646d542770f294b9c9f21f1196fba567f2f74d058ebc25, mulmod(
                add(0x2cf1eefdbf254a549ddf4069288ea075d9aae074aac7853005b57c37c2039e5, mulmod(
                add(0x64ff5a81d9e22197bb59e8cb340a0f44e22e226fed168f8b125d850bd727b7b, mulmod(
                add(0x2d9f309e84716b322c26aa86a3fe3cb6ff230e0968dfc58b869268c751e510d, mulmod(
                add(0x1d44a3f67a1142e7922f4329f775fec5f8bd2d32ef8ab41a00821e76fbaa89f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xa6117e45c1c561307d63895569d34fd7e3f2b2ea088dec37dc3a5527deffd4, mulmod(
                add(0x41d785e118be2d27a159ed5216de66a84873e1f62088726d9607c6443a14090, mulmod(
                add(0x5486125e0ed23fdc42a4f8c96cb08d934b6f3b429c4af5f8396618e978e9811, mulmod(
                add(0x66af1f51f840c438b502c2a5ab689f9b38c2c96df36988710951bf185cb8501, mulmod(
                add(0x619cb05e71db22ca1ef274bd0a7cdaf4fb79b3015b96f44814b490f048d2af0, mulmod(
                add(0x8554877281326c1c7e1f3a2f5e81341554ecea862c2677fa67ab2f88b3b03f, mulmod(
                add(0x37b40695420e59161b338e413a72daa6909f0e4f6f85426f8eeb6bd0dc3a1b5, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4e1cdd107e3116b4ff22720938a201eed2ea0b499bfde301562f5e39a42b066, mulmod(
                add(0x77bdb42e999e93273fa3cbb7ae7160522231680eccc4d38c1b8a83d2a0420a7, mulmod(
                add(0x4f4cd7f9fd5b694cc5ea6154d0738cdbac3978ce74a7314bcafea3dbc1da61d, mulmod(
                add(0x5cc1da57cf1059231e195a26b1323599c95f98e4b302d6e6f4bd41180b56d35, mulmod(
                add(0x3678ebeaffc3e64d76141f41be973ff36e8398a6aa0385eddaa0c4183e3646, mulmod(
                add(0x3daea06a4a96480c4f7fff1082d95836964b63c14281ef942fa9a9890d8754c, mulmod(
                add(0x3bfe2f1e8df44829fa27a78c46c223c7e64bda85be60d8a3a5d0e7d36c20e29, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x11a9029a5c07557ec347592ba7181acafbaf0f0c5c9e81d7e995a4de57fe566, mulmod(
                add(0x7ea13011e0dce5c917be4cd36c8931f5969852109a16d7c5142e8fb3c8b7650, mulmod(
                add(0x2bc791bd7e68342116218ed9bb657b8b54e550022e39af11ce55b29ae49218b, mulmod(
                add(0x4d0db05514a8c0f152a8664579c004fb738cd3790214984bc3f21f31d494361, mulmod(
                add(0x1ec8c3c39ec4705944ffa8b3b9b61f73c9ad759cb79a107dd93a125685f5119, mulmod(
                add(0x23d7ed01587af3b9aefeae8a627c6401d36245cafa9367631036d2bd7c47e26, mulmod(
                add(0x513bd3eda9403f4167249972ce4947f3ac9e9da03a7b9ef557a65645b9616be, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0xb04ac19a9f1483b8ee3b763be73814c9621fb3d23e6d874d9093d999d3d4eb, mulmod(
                add(0x2b7f9df93ba787a9a5a7a0a3b5daba02e2ce65df16ada37575735697eda6c1d, mulmod(
                add(0x3ab952be650de0c679ddc0a35bac2907a6e58303059d4edb914e74c67d05226, mulmod(
                add(0x2f7d26f183c54146bd83514f5459bfd95ac635649d74225c2168a8e7baec082, mulmod(
                add(0x7a42c4e98f014e50dba6b25fc32401b7695fadb7bf271fe0a763712ee545c2, mulmod(
                add(0x491899cb7600abb42ac8cd91f2c775ec410469573f57c1030ed1582327eedb8, mulmod(
                add(0x359506efbff0e2b81d91cd6a5f808a6c65255e1bf06cc03dbaba94758b3acfd, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6ae2e00f7827692b0d20f483d3c71594f61d50846b52abfee39f6697513c0d0, mulmod(
                add(0x625a1fce22a9fb7717107b137a0f5ea4ca059008f5cc6fdfb5cb5bb1734bd17, mulmod(
                add(0x309bca858a0f9fc5a468a57981c9c6b7c79636b1f31284938d1c6a21f006a33, mulmod(
                add(0x4db70c63a1dac4e5ddde15e3626d009683aa8ea14face2c3fdb6ec97c8a86a, mulmod(
                add(0xb489643a1aa2c181b4739d45582e2576a6f9bd51c81d300ebdc3a58b79bb2, mulmod(
                add(0x1522043741ba933948d7298114b71322258a3d4e7cf2496590c35683dbe2a7c, mulmod(
                add(0x4f4df07e55d3ebf0ed955bd9f7c34de001f09a92c1ead17b0c1a485d48a4329, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5c01501e6a113ccca7cc9c723b1fad6ba60ec5b0a85b7d09c72120d3f733bd5, mulmod(
                add(0x411556b9c89186a2f9f79e55d045295790b28af97fab64e77777e3828532be5, mulmod(
                add(0x67801dffe217a1a64e0b12f405157af52025266fcc391fddaebf3b6c7ab79a9, mulmod(
                add(0x588747248358bf8bdbd990996cb43468c89909cad0f8230cc939538b9b331df, mulmod(
                add(0x55351e9d60f58241736330de978242e4e40c4209a7879d7ae3823c148abd82a, mulmod(
                add(0x66a63b8ed2255586855fb30333ce0e2ff4eb2b4cd5d2125d8d20cd3fcfc1d04, mulmod(
                add(0x4b5acbaa0f7e360885677439654649256829cdd6d4a6c7ffa904a0683fb5fe7, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1c867fa9ae031469be012c4f201ed3ad56573a22891351012ad1f7d300361f0, mulmod(
                add(0x6caac68bec6ce4eff4f74c1f33dbc027165cc02cec8f69e9470ff99c0b132c3, mulmod(
                add(0x4e0a6e0c26f85c74373782bd2924f3bc0f6b4a2914c4f7f8850a79eab580566, mulmod(
                add(0x4f6e24500755d20ec5f28480a41a0cf23baa1aa24202382e9f4ec8ec6d7596, mulmod(
                add(0x7d9c679179dfab605ca04e1993b37ddff490c440665005698a47c442a1cc10c, mulmod(
                add(0x3013a9c6094ab0086b1397621f93ac07bf45574ea26b09d3e4587afffe995ca, mulmod(
                add(0x5b0d578cb7aa59ba02b0bb894848b745440c0cf562c2e635312c9bfc305e169, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x65c04013accf25a2cd1d9eb98689d71694ffb20dced009df5b9af167602b4c2, mulmod(
                add(0x7352e8793ed3f6283e492544b2944d6fea715980d8884f6821574d36868b0c7, mulmod(
                add(0x9be8b219ca1684dfbef720a3e9f034b319e2d233aed85063924fc60aedf20e, mulmod(
                add(0x65c14f7de75359a40c5f244f78b2920b61087fdbbf59aa507644d94f5bd210, mulmod(
                add(0x6a4efc048a81614dede6c4f6181253e84f20d4a4f95f973147ee3fcd72077fa, mulmod(
                add(0x4a35c4582c91999a39b553248bf2a39ae5825204085a9e98bd6ddab3bfcc0a4, mulmod(
                add(0x1761abb092f6c4e3eda770480fb4ab095e786bc3f1b1f960bc4c95232308b3a, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x400330fb079fb4cc8671ea9a996de8f5442f20b9b9a3bc9df8b81e01506c5ad, mulmod(
                add(0x2512f776d1b3d212be7c2adce1cfa083d1b2b9af1c6f3cc424b266bfa19aa06, mulmod(
                add(0x6f6131c193cd7b3fdb4d0848df70474ba9e80529097311cd7c13e322205a1c0, mulmod(
                add(0x711628cee8d673863e18f058cf82551ca8351486b9b210873b4e18447e11408, mulmod(
                add(0xd9da926adbb5ffa493c54223f97fa1b0d141129d8736bc4f5768426c7e82a2, mulmod(
                add(0x162e6e8431b7280f8401ca08922c5452c7237132efe3a481a71b5c97183e9d0, mulmod(
                add(0x679bf3101f8b2112eefab47d7372f0297507511c7cceb4478f2baf0541740f5, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x152c16cce8c1c782287b8908a790014fe3c51c57cefaef63e2c8dae5a7a5daa, mulmod(
                add(0x74a39339d1d708a9ea407f03d8b0e5ab103c3251596258b78be1bd97ad06915, mulmod(
                add(0x37f1342e071f8a087c1405692443305d28d4c11b84d92bd7dedc563fc3ad329, mulmod(
                add(0xfe9d827d7e6387c7228d92f78574add4ceddddac1fbe71dec1258220c08402, mulmod(
                add(0x4adf53e64235d5327822ee3e584674af053e496c5d92a6c8c43e1e8e7d327fb, mulmod(
                add(0x59786091e2d824242c7aa5dde34ffbac99f6a9a1aa5ecc8a395aa13e8aa55af, mulmod(
                add(0x40cfb729788e16fa80b7d937f0088157d18ff2cf7c79b748d0e150c896d348f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4f847058896f8e2727ef3b4577e62d5f6a729696b8705fe217b97c73fd1afee, mulmod(
                add(0x614509129cebd380f416c4c9c7127ee7b53d878860905f047ad722a82147236, mulmod(
                add(0x6235547369b594514d2fa1ca9b06fd25f9d2764fe8b099c7d9671f542a01d46, mulmod(
                add(0x5609324fa7ef5213591c8d36c59dd42df8f5f26f84468bb84f843707a5c9c48, mulmod(
                add(0x44041800e20fa7a15dd9274ea8283b09c30a0d900d9c165217004e669b39d99, mulmod(
                add(0x3b4b0f9b88e16446a2de79c1d8c34865d5d6e581f08bbbc652ce67d8ac1d952, mulmod(
                add(0x5b32dadeb15d554f39f227de4ad20600eea4b763fa4c90ffa1a41812ae43479, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x75f781602ada44803c0ca4bc8c1bd5064700762d18c309a2b9059dcd8c3dcca, mulmod(
                add(0x1e149d42cd477212ab7f01fe40f76858f09ce2bdfc397df635ed8a453714e7e, mulmod(
                add(0x528d041bf152aa3a0205430412a196619b68c81d7a706fea0fc090e0cc6a105, mulmod(
                add(0x45fb29b3ac673e9f525332c8bad73d76521985406fc09398078b30339c857b5, mulmod(
                add(0x1fb19890707fa2e617de7dcea9ad35ce9960009f1e38aa2629c66fa5b8d5d19, mulmod(
                add(0x5897638208b8e9509d1128c29af87cf30c57942d47016819435b373c0a309d7, mulmod(
                add(0xfee20b19c4437f06eeffccb05b88c4e236d18f8e3518ba124ab4eec844c496, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4cbae4979c7a1313c2d0f68b21f5734ec83f9e1a88c78b3976a6ef84a1b6dbd, mulmod(
                add(0x76594f29261e2aa9cf4a90b58b0f79c2aaa99d63c4ff64b4806cb8cfb0df316, mulmod(
                add(0x43e371660fff35e52cd5dc08c9c347d8f7c64a116375d0e6e3ad3512d85a99a, mulmod(
                add(0x52a36a173c7ebc96cfc55bda4bbc73bc349657d39ebe096725e9cc4bff01def, mulmod(
                add(0x2849ac77a2f5398eef51aeb8312dcef8b347b690728d4eb835bf4670301e6e7, mulmod(
                add(0x304103a8d35f43cf87d50682e86e473fffd71d13e0c783e596a59a62b06402d, mulmod(
                add(0x1571843ced13a8d342b63c63abc4b83d357eb286af04380edd1eaefcef3f1f8, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x719df2a50d9c3f2eb3f0336665f2980e432191e21fc49f488854b8352fd94fe, mulmod(
                add(0x19412ccd078bf5665579cbd16035a251e08f40722eca4452eedb31732488468, mulmod(
                add(0xb3dd17f46d6b12bf4e5db184d6962c156bef94f9f73861e34d88503fbc517a, mulmod(
                add(0x66e2651e6f5758c334d1c1451d563b2df07b424b5d0125c739ada959479890e, mulmod(
                add(0x2ef5951aae064a7357b1e4ed49f05f17f778f2e8735f8d17b5cfb82faf3b848, mulmod(
                add(0x64f8c462b308a1337bca235add2482fdc3607507b2c9c0f91b9187f5676303, mulmod(
                add(0x76702a08064b5768ae2979aca07322782191172276f1bcfbc14cbaa3e758dc, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2b51d7f94ec71f3a8e3e20d766a4a7f13d08d758a686ff86dbda48026c7ec3d, mulmod(
                add(0x6232d26f420f9b4f119e64762927b5e8a21192575b200081b0545ad4e9a2c25, mulmod(
                add(0x298215f335fb63a11d31958d950d95c909bb94e144c113cc4ecc08488469097, mulmod(
                add(0xd49f196e60ebea0eb13d85f05cffedff32477e83129bad30bd9dd555755429, mulmod(
                add(0x74e503d57e49daf6939077c0b4a4d68e66bc2425ce53b01b48f146295476401, mulmod(
                add(0xdef6a0b2b71d97a59c674c052fe23f7d000a334e180b0793b6974fe29a64c3, mulmod(
                add(0x459f095ba3b70f76e493c6afe2d4b6eebd21343f74bfe3390868612fc250fdc, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x65f4a97d2b1c90582859966540e839ac2d62ad2ea960aa2af36776b2d07ce34, mulmod(
                add(0x184ee38f80fa532983fa248c14c0220c2a5691836e899a5c9b83c975b03608f, mulmod(
                add(0x13ed29a84c4875ac188521bc40e9258e03d83c9ceb8716c6fbeed065a5df73b, mulmod(
                add(0x6a81925732161d4e5dc61ed6a10726027fa66d892aabbf46a477f4455072c02, mulmod(
                add(0x1b16d94e84ffd3ad61286f5a79d5a6f7b5b5dd6442aea9013ad21467bf1281d, mulmod(
                add(0x70c0f7da90cd889d8df06f9774de8a9a20c88e86753506c7afd0e1f6ef15e76, mulmod(
                add(0x45fb08bc21969d5ca9b1ec473cc92a4ad911de8b0607ddc12b9ee98c286d37f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3c835256339330b1c94cad78cfefda36a949b9c8553d918f3d8547cd1805ac5, mulmod(
                add(0x325f10662fc8bd38e591b0e8caa47b3fff46703656b2c5863d39c150d298fc8, mulmod(
                add(0x77434256511acfd027b41e03a571a9f56b0442dc675c139a2e1476fe716102c, mulmod(
                add(0x73eba0e9e52c3a93ab6dce26d5858b2d699d8401b2c43253616b5701aa803c5, mulmod(
                add(0x61c61341c83517cb7d112a76864271492473e04130ce4ce23331f7300bd8c89, mulmod(
                add(0x96935be4e41797417259166181bb646a619ef95cc8978ffeca81d141d062f7, mulmod(
                add(0xe00ac968fe5a147fef45fbd626c540a194ec3dfb2c1cca7938e037349d4f34, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7caaf4f7b073af26c036d8bab5c74fc3f752f9ecc01041787e9ddf773596189, mulmod(
                add(0x6321e76192ba31cc63bf7c526c8ebbf4df5b705f01e4151068ee3dd658aa674, mulmod(
                add(0x72bafd4641e6928ca65cb48e8001ee077944201f70d5bed524c69b709410d3e, mulmod(
                add(0x60c93d3dac2628ad796e1dc80bc0796d054c991ea23094d699bffb43a630add, mulmod(
                add(0x78562cbfb984ebea085472a1b004dbf86e7d99f4809a5020969246a84a9d165, mulmod(
                add(0x17d8ab17e403b1925b40206c11f8a6a29ed08217e1ef303906ecb354fdda1f3, mulmod(
                add(0x7340540d0c9f9dd2c1142f03f408ab977afc7371934c62259fdd29f0652f8d0, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2f2f5447e274a20d9d60615f83a18b2a4db300d5e199d7c8c6c6cfb754e8cbf, mulmod(
                add(0x687aac173963fe1e01f9e0d50eba0e95e1e8783eb21c0f6c1f45cd42408198d, mulmod(
                add(0x1c933d3449f6241d0f9d547db9e708fc2ee3e0598be5f87b675fb6736a15c39, mulmod(
                add(0x7ce96f5a3261a977f04ff70ef416a3d5c165100d19f551a6ac514e4d00fb18e, mulmod(
                add(0x35c99bed31baaf7833ca759a9bea792965a87b42171259ac51b00d872d581fb, mulmod(
                add(0x5b6477413bac2f0d370c0cdcdec4cea10fd322fbcd7b202d4ccbeb0581fd34f, mulmod(
                add(0x66ada08fe725f364ca32c1055e1ab1216967856d6cd8762dd4ea915c2ed40e9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4fefb86cfccbbea031f15d85033f10f92f2b6b689153e305bfa8821935979c3, mulmod(
                add(0x3cbf28927ecbda443555c9d51f40c294fb6688a17812cb0c85fb6501cdc0709, mulmod(
                add(0x33d4fbf9dae7a87cc13db3c95ed3976b50113f072e56a13e675e4af241bb864, mulmod(
                add(0x2fcabf82bfd2529eac169a520cbdb2a0f8c205c5a9b1f1ac69bd3a44b25faa9, mulmod(
                add(0x5455d2de2d7570fbeeb431a9a21187ecc049874b64a227bb543aab4af16e27b, mulmod(
                add(0x282ad11848887c771898b5a32ac6ca14cc2510830454aa8e194975e308fe042, mulmod(
                add(0x91cd6c3b8ddd8954a44e8a9cf6f7f183af8e6226849f05e6e6ebda2409e042, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x160d7d587f3a17673bf04189e0062c7bab764fb54ebd0f042fec72f953a91da, mulmod(
                add(0x25446fd382a1b0f5350b91290b2dc35a6dabaf215d53cbb32d1732fc6ebfffb, mulmod(
                add(0x123f50f65a68168d6b43c464270479801376ff6979b94f60252a47d9d7d34d2, mulmod(
                add(0x11243de8b4214dc3220693acfaa6b626cfc3b8c812140779af9b72dfb1b92f1, mulmod(
                add(0x45a5b88744e83d901f33da0d0de869381e7a125a6d8bd104cf72ded013ea4c6, mulmod(
                add(0x6c74e3b74559e12949b8c3b55369b2d275b2920b4442c536d63f91debd61499, mulmod(
                add(0x63f4ad31c4d59ee741b1b0ac99e022959df079b5b033ec7a1ecd3b4797f94d9, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3d368784067d457e43cb63b3f526e721fab153949b090a99a128c5744fab4a2, mulmod(
                add(0x6da4d6fb1e6b2f1b42910a9dcc4702912002d7d36ac7100e19c7f298c7948a8, mulmod(
                add(0x31563499de399383464854a8679e0b073513c5bc46cdcc2a2107f00677e6356, mulmod(
                add(0x6c2a98464d6eb4038d55b57632bb283ab091eac255fd6797df41612cfe3ea1b, mulmod(
                add(0x2848af5bb20ab624881dc9244ea18b1d6939e14270714253a896e57cb0f63ea, mulmod(
                add(0x1925470cee5111eb991ccc8b0412be603c0b8df342d7b186a3aaeddae103bf3, mulmod(
                add(0x1e0fcefcc1d1c5a69e81c4fdfe7de04d95b53c162a3b64b5956df8e59e1b93b, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1fefe6ebd886640df863e5f5c25e9b42fbc10adfa7ef07d1fda0eabafa60a6e, mulmod(
                add(0x3129daa367a01a45fe3f0ccde215371f59c5643bfad33f4269a6478c8c8b7f8, mulmod(
                add(0x41d1ca4f756c80f197ba1635314a3dc756f9d8d9406af16538643d3e1021bd7, mulmod(
                add(0x6ebb7c4ee2d4212e6d7cea8c16f97c935f3bbbc2f400c9a738f1ebd37eec6ee, mulmod(
                add(0x1118c09adef545b07e209d88b0a645673a103c9e71e8f671e74c84abf1a2a2d, mulmod(
                add(0x179f2a40de3db251b95a60431e7cfe2dfa48dc8654bbf81add938e9f2f6725c, mulmod(
                add(0x266b63657dbde655f034c014a8fb73b77138b52eb0e17eacbf402bb90305f10, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x41354bad5cbef57b0e7eacebef8f0176f3b70992ea5a418f502242acbc4a1ff, mulmod(
                add(0x690c8328ca161c48f3f8f37570e42095d1a0d9e101b3ec0ddc91426fc22facb, mulmod(
                add(0x7393709fd08807a84ca44526a2b8ec97bce5aad1adf00560d04110de6d9eda8, mulmod(
                add(0x43e46c5f1cf3b5cac9722eeee991cbcf53af25a4a355a91ea9b8a4d4754d908, mulmod(
                add(0x6508b5fcc13191197f91407d5b1b21d321b7f311e55ede9ab8a6975308dcee, mulmod(
                add(0x24eb6fb4dbac687e35d4168b970db6e7dc76c4c886dce0d4bad2e6544b8e6c6, mulmod(
                add(0x37e79bd72d714d3de7ed2b1ba79e345f75646bf67efd8ea3050ddb357802a3c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x5f4fd7854cf7b89a3983da1a39839d85c7331c3353b0a8cd218f7f4e1f780c, mulmod(
                add(0x378113f110b2404e7d185e920249519ded728cb1027fa8cc2843a588886a7ed, mulmod(
                add(0x64028a3945aa2866db68b304dd0d83d75ed0ba5c2f9d0b47e80d11d8da6526d, mulmod(
                add(0x5526001b8a8c2c6209e40b5d380836bcf63db4ef85c25fd5b72d749b0bd36de, mulmod(
                add(0x33e7ba5f7e56065e3f8b091578e8e7a7b118116de47237fa5a97e44e97b7f69, mulmod(
                add(0x33cfe02e240929353f193c6d3387f1117d04f116889f38d9a196abdf986e48a, mulmod(
                add(0x3475f32b5bea9dbd19ec199ef34e531b696cac0461e644ffb41a5e99d0735fb, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4dc27c76881bb820eb74814d1b69825e9048b1a3b064e603cca4bd4814b2243, mulmod(
                add(0x5761ff2e0a250691a66dc36d372afbd6a8016726efe0c418d7899d60d26bde6, mulmod(
                add(0x62dae59d425684ef78c1829e0454cd5e76f5d322ea8cb5ae5e911f545beeee1, mulmod(
                add(0xe3f2bdc2de2b623c56390eb0044adb980766ae1a58d775e003c39724d1d6f7, mulmod(
                add(0x684a30c1084e8edf34a77bf8848fd2098459f5461bdf3352faf9c8801435b6, mulmod(
                add(0x1e4bf5029043367487394808d7ee7df5ad1ad1da2c4710a1b2444ffde106f2a, mulmod(
                add(0x6467afeee167ea95feb4a85c48fabb2c7067de57acd5098692855189e21c57e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3348152349370ec1c4d753735ef255b50e54aa9a432f48a121c39b8887827e0, mulmod(
                add(0x66d91bcc591c880303ee4695475e8a8e402926f0c01ade8880c7b03c76998ee, mulmod(
                add(0x43394095e27ddb7825c0671833a6ac9784f31626914c902c225f05ce42bbd9f, mulmod(
                add(0x5a347e7937c7a178952905f499babbeda500a820ccfdf7f3a99589687a623e7, mulmod(
                add(0x4d6c233f7bf3ade219a8e3a89e12d05beb7faccbfa811ebd930c391523f7b4, mulmod(
                add(0x23cf69cfd7730dd096fd485b2d8bdfcd89ca6004689bcbcacbeff288f18ff9b, mulmod(
                add(0x5a15d718a45959d16dd6e0b98badbb086e2a9741ac04086f078bc6951506e05, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x72fb3298da88c470a2f93a391063810be01078c8375183b57a024c223f2f428, mulmod(
                add(0x2850977abc89355540e8abb804da7805ef88b12f40cbd9158ef330b767901eb, mulmod(
                add(0x3e35aebb590266ea1fdd8198cf3c23c77731dddd95d488a9d9f9837e3bd0f6f, mulmod(
                add(0x58281d625ddb432caef06e485bc2b74cc077aea9ba5072198e76542f0c69dd0, mulmod(
                add(0x37f5f6b25ee428e91e886127b961856d9ebc52740ceb763baa7e71371b84364, mulmod(
                add(0x45ffc1ad229bf52b2531afadd1c5ba120c57b34def87149880d1e5cb6c5391c, mulmod(
                add(0xfa17235a82497674de45bfa59e61a329b2d0e63eb18ab9b74aa46783e04c81, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x208f0c2f5a114b2342f51e919e4fe44c2a42cd06382d9edc4ef58939b249bab, mulmod(
                add(0x414215fbcef7f5af60f320e67a845e4a17b0a0eca39b4e18ba89fbe8a189491, mulmod(
                add(0x287fed27ab81e5f721d2bd5aab0e69f53e94ce5dccc35c2dcc88e12465fadc2, mulmod(
                add(0x4a048ce90e3a1eeedd4932ff37760fd8b1dc995aff7107bd66318652efd1032, mulmod(
                add(0x26601a459facdd83458b56099975d2b7dbbc431d41b53f5dd6ca2901dfaacfe, mulmod(
                add(0xa7da81afc9f3c93366b6e161b1fc7a497d6c770fb140bf4b64e5fc707cd3d3, mulmod(
                add(0x53f792c81d26c122898d70ed7fcfd8f02a8f5a9ec8b9868fc4490d3a46b4e8e, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2adfa41f72ba3b61b9dfa6f017b19682b0b0f8cd86be3d37374aba3ce990a55, mulmod(
                add(0x75e9c821cdd2e754759306283aa4af8bdbb0ed31f4e978dc550141fd10da6be, mulmod(
                add(0x709a47e72cda4fdf428bb9784f02f77c700086755d4bdb5b229d1b80a2ea4e5, mulmod(
                add(0x5b6b3213744858ad659c4c07c9220380d63c01f680986191c8776eb703661c3, mulmod(
                add(0x2a60396cf912573be2837653283a23702037f614e33e1c6fe2834eee9a1c7a6, mulmod(
                add(0x6fa8562db8de26797e9c9905aa769e4881304b4f20cb64d718d271c182f44fc, mulmod(
                add(0x5726e3dee7bbc5e5b4f3ad65f0fb17699efb5936d50ad380785f2b10fe8953b, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x46cbc37eff4616daaa86160d5690f5473e24171441e29705ae564223a351c23, mulmod(
                add(0x78f890541865c12169233143f47a056a91dbd18222c5d31bfb2db19162c204c, mulmod(
                add(0x7c84837e6872bea4f0448183cecd6bb24a8574456ab91173b04b9423be8a64b, mulmod(
                add(0x287ef69d6f69ab853e4f0d24b22e4c15169d12c41706dbeede9fb49c61179c4, mulmod(
                add(0x3b8cca1c3fb2b26b7e206802d52d2ed1c725b8f95407e3ef295a7dd9ee0d45e, mulmod(
                add(0x78516acc9d32f4e54f8925865c91f70b210f4ebc7533fc624685b3d5daa7b18, mulmod(
                add(0x6e313bf82c34d3af1e7fc14d811dde163ca6e57accbe476875e4a967da00b8, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x38cb4f77410e9a33306f8a4b92b6f76bf239ba44e0ef45dab0bfcb75dfe4141, mulmod(
                add(0x7239c3b89513196e3cae91f8df8bd79f08033061ba63c089bd764644907479e, mulmod(
                add(0x57f7a737e643bd859d8a53e1b621c09be89fcca7b96f8e42333e46426f26a20, mulmod(
                add(0x2762878a5f6665bee609c26e750cd886e239c31caf1508d5a2a185b58576b77, mulmod(
                add(0x10699899068f86fa3843b06693288630b9ac4b87be7b3726fdba32b41caac2b, mulmod(
                add(0x1a2cd41155bbb7ceee94dbd01bd876140b1698f03b2ff8f8de3ba45b4ea14e, mulmod(
                add(0x309f9698e38823c05e56d073d83ea551bfa80ace08e749aa4c83031a22360c2, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x2103ea7ff918748c4325a992c561b551b70fa9d97e48a52b3c157799d213693, mulmod(
                add(0x1b3104591a23f262051182209c0f73caa30e8631fc4413a5bf97c9d51a70abb, mulmod(
                add(0x4640cb2cbc73d7c9fd2a1783122cb5ee8c68e7c04b0b647d43a35cd4961e4ca, mulmod(
                add(0x2d9af4ef0d50851ae1b0cdab3587a71728eaaa4e56e67803c5ff9126e722696, mulmod(
                add(0x4f6b918e40f8022d2bda8d53214e8fd84743bc2280231d3ae772844bbcd1aac, mulmod(
                add(0x51ceb130c1908fdcfa6896756241fca8f74ab172d98c76facb7b8b931fa8812, mulmod(
                add(0x382114ce9d712af864a253d29471a436b83ee4f7b8ae3fe19ec3ab315e18d8a, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3dee84f905f6a06940783bc3f322a0fc22a984dd244d00a85ea3a4295558377, mulmod(
                add(0x9b419422a2083bf174263351640e009b56d6e2278552f9e7ee6a6004d45524, mulmod(
                add(0x6f2a9f716b1fa27c35675a57273feb79ffce02286bcb1e253a8e126c2cea357, mulmod(
                add(0x5d72a87fe662c05530c3ec822f925a10c121a44c4adecf24850fa2442cb4abb, mulmod(
                add(0xe051fab79733dd773d13f5bec04b1c20252df512d937f6b7352e4c4fa49cb, mulmod(
                add(0x375e99f4993200342e6f6ad713711052d518e5dac24681b3999878bbad627d, mulmod(
                add(0x69fb58adef701279dddeff71e1832aea01ae10a5128a9f744a5a945b5fff200, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3e44a162d501fc521774c75994f4b55eb85878f5e867cacb75c7ff0b7efe941, mulmod(
                add(0x64035ce25716c9c7675ecce40d3cfb65ce3121439e10367fe29f2742cc02d85, mulmod(
                add(0x6d5a755e91ed732dcf8afd32eac3b4875843bb116430a966ef88f17aad54c16, mulmod(
                add(0x6d8f39b47e79d44503aa87a3fdf101b055f89c663bd7ec377d175280f3f8db9, mulmod(
                add(0x107c8fc81a96a3c13d1ddf04b8bcce0450610c2ee6c127e0f47ce2ed2fa0613, mulmod(
                add(0x7d52bb08c1d72a66c3e5c60f6742675ac788ec8b4f2178ff9990a04d22c076e, mulmod(
                add(0x3dbd68c7c5945f48515d975002a1caf1c491c6743f151df31f95c5870c90fb3, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x77f62cb2f9db71ba7a9913be0a434ca045a26704681af5353b7c7860be6e774, mulmod(
                add(0x6ba0329f670df105c31eb665f3b6f243ab5de7ed8aa59ce9b0683e6bdfd9019, mulmod(
                add(0x6a226b1dabca8ff2fbb52f0adcf4267a47e0eed089774157f318b507361a0b8, mulmod(
                add(0x4ea62ac09b98dcc34b5437f6bdb4fb9a681dac12d1ca7090011c73259dcef4b, mulmod(
                add(0x338c001d0c722d793cc14219415d61c52de28d33ab8bfe5dd31674784f2b568, mulmod(
                add(0x8b54ed775cf8f3dd5b54fcdea07e2bcefae323f6212b8f54877a60e1f8026f, mulmod(
                add(0x1b2441db55dbd9b87c45b1afba238ed28d1f2dfe9725d9a4cae3a45e3d59b63, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4ab0da9c66ca2588350bdb85cc745b4c5e7226cf7c4fb69708cddf6e8145f29, mulmod(
                add(0x209866f9b8d946508db2df8eb9d30f65ede2c99ec8deb2e5a1b7093e9a62416, mulmod(
                add(0x79708fbce6bbe1c862e988648dd25347d60c9e0981540dd81ccaf78054a12f8, mulmod(
                add(0x15296a7d071a85f1358bb157d5e62b18a11e189415c16f594a18be7276ed2c7, mulmod(
                add(0x4dabf5afe371cde17b9fa6c54c1b38d603f345c58d4f66e06fedd8948b402b0, mulmod(
                add(0x4279b49402fada9fcb602f909bc138c3547baf384dfef9594e2fa488cfdf8b8, mulmod(
                add(0x770018fe3435297b82b391a3bd2d09151dd3949545d0ef111cdf9fece9f389c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x6337d741eb226911e37cc48087126cdd89f00941523cda2fa5e965dc4fa25e4, mulmod(
                add(0x40e394412097f7c06183ae2997707604273b0a4ec1add0030bd7e115c20ca70, mulmod(
                add(0x43e49d0d9bfd165776eeab9118ea672c24a055a700e35a04426abe1b236506b, mulmod(
                add(0x5919f2392a53f9b230145d1b5e6da28165dd1d8cc7d28d3310a805ebee721fd, mulmod(
                add(0x5889b4a99416f2f954450c60492129c5f7a36f875a56dde5188318e88d6032a, mulmod(
                add(0x55c9e37b0208bfbbb61e5e0e05c72111421b24b45ea53d3ddfad1cdfd243ff0, mulmod(
                add(0x54578b117a58f5beb0d511ba42110c4696f4fec165acfbbde208a4705045fc0, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x4835c753d4b5059c1b4186516851f562e63e348f8810714cc393be9810a1de8, mulmod(
                add(0x62cea6c83442875da8b98083d8bb18bce5d3d431a3301afc635600578b33506, mulmod(
                add(0x3fa0ff20cc486bd0b43f96826c66b070a6f6e3df3359ebd2970661f9c679e2e, mulmod(
                add(0x3b5f2338d066753b2507a39884bddc2d0c5bef88e4bc3e79288331afe9a6234, mulmod(
                add(0x333793406d06dad0406a859ea2c203aff33e3cd906d6f04aabb0dffbabbc9c, mulmod(
                add(0x1d608ffab983d8aa17db9385433abb0025c77e27357285448c4ff6a8438570a, mulmod(
                add(0x64592b7d9a6a922f5cf5f74c56e167ec000436a6b3caec299bcefea25e5fdd1, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x54600ac31d014f7241c14e5aedefdc72b839cb0e98b84aa13f031316af48648, mulmod(
                add(0xead9e7eac2f6c388de28561955e6009f9f1ed098f70516f2bda28597c9ee03, mulmod(
                add(0x59daeadc724e9c227258a56b000c6a613db617da41bbeb694521c86323c93b, mulmod(
                add(0x6c6dbd58b8657f8588bae8a4d990e6f9b0525af4eabe87512c5f6a655c92028, mulmod(
                add(0x13c6580dce66b35fd24183e1635fb6008a6deb6cb507bf48d531273d5b4c2e9, mulmod(
                add(0x1917c10cc63bc9f43116c3688542cd867e1a84ce0d3e58dfb0c11c4b0828748, mulmod(
                add(0xc230c4af49117fa614b1d4d74ef462211a5d55537ac71564ace080dd4b325, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x51778c6b175ce13e994dc1604dac3b901990cbae0246b2cec2aecbe96dd2006, mulmod(
                add(0x3f1908469233dcf5c433790cb3574261ed6debca41fb55b912be7cf34adc187, mulmod(
                add(0x4dbc9ceabbf1c8d5c679cf80d9bfc26ab696135792e83061e98b9c36ae6a4a0, mulmod(
                add(0x30c7ab8fe6b61574f49c3d76b3173f76816f31beb33097d425a94beab6caaa2, mulmod(
                add(0x5952b292edb661874ff2d3482fb968149f09982bd7a194d2b502ee3dd32927b, mulmod(
                add(0x23ae2f35a2da5ff92426d59ce066e29a525ee1207de1c370023975b4403ac6d, mulmod(
                add(0x5370b38ea84ca67c75ab50a4cb8f23f4017175a98b23df9e1c92f92c279e169, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x39007630deec4a6eaf806518c109f4aff9cbfb8826d86f301e562ec560ff89, mulmod(
                add(0x3d7587a79c4ae9c24934a10a9c1398c04f3915fb6889b72b361505a85db2b69, mulmod(
                add(0x6d4bd8c4aa4a530d965180c18062d6bc440e6e70cbf0836d6af11235c7fde2d, mulmod(
                add(0x1793fa490096ddd67530e29cb3e8e9632d1885815be3f9d96375aa5946f511, mulmod(
                add(0x5099f832fdec91fd27af0d221e009ed6770227d63bcee6e1802cdd122751260, mulmod(
                add(0x3cfdc71122fdfc7807b2efe35fb6c7691985d2727401eb8a8132d0e0df3cdd6, mulmod(
                add(0x6a91b3677713dc15cd110c71cb8e174c8ebd8d7df1a1b4120bb4b6b1683ad5c, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x53bad76d22e1525dcec248b73438d6f444caf75794c26144e26803fe2bc7736, mulmod(
                add(0x373a1f2fbe36dae9a5f2c2b35febe59b53869e1678c8da23bd9e92c3c2ac0a7, mulmod(
                add(0x4b5e107dbcd02c0dbef4d3a77d66386a864d31109d0d0392847c8919d926fbe, mulmod(
                add(0x755d64434e4e4233388c34a90438764c568353cfde4311021b45e0f369b0db3, mulmod(
                add(0x42cdd4f6ecbfd891fedb9ecb6d320f6adafdb274ee15cc11ef4c0436a4e9afb, mulmod(
                add(0x7f921548c686f600b302290f692a66e9ececa142f691f9129c7d8bd2a06803f, mulmod(
                add(0x51e4a728ecd68dc30e4a1b5867a1022af5808edafc3cb12d26d43b495528f18, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3c3ea2cbc8ce544c6c98ad9053cb2c35326f4e502214e5f72c7951474b5a84c, mulmod(
                add(0xcb3220da969b95193a25d1d4d76d1cd1ec596040a7b31da7f64164809bdc4, mulmod(
                add(0x929eaf221c110efdaa57970581428d66d5866fb9547aab76e89e8971efc91b, mulmod(
                add(0x1426a2050d240104b5c07a9cdaf7fce03c2accadb0ce98344ecb4942c434db, mulmod(
                add(0x5fb8d87e82c3547e32ce316e4439d1aaf3723e4a906c91533ba8dd9631f1661, mulmod(
                add(0x111d440a13cab69043e1072b61c1736cf3901941b4c57d7602b8effa7e74b3c, mulmod(
                add(0xaeb135e456ad66bb5bb2b91a4aa429915f6f9951aa15bba78576744a698016, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x57ad5370b26ea1478f3fa0346d2e390e90feda8022c9820813d9ddd0f36e7ba, mulmod(
                add(0x1489d6012d4c9701b63f3610034fb5bfca185c7b01222907781eb104e031097, mulmod(
                add(0x1668b919fcdf512b5683880ed048853e00f456adde728427fcde63ac9f59611, mulmod(
                add(0x65d167bcce20a40b78583e4dcf7e3f44663e0c595e18f48f83ea4230b207047, mulmod(
                add(0x1e0c96f0b836d1e2df4e4063d56b78f38f2ad16040d61855b0f664c066d130c, mulmod(
                add(0x2a652d2592f5cc1197a206db79d06e3b74a55b1d4ec03c516a6957e87345cbf, mulmod(
                add(0x68892b41018bc73b541800d91f0bb2a8cd9fcfee8be13bacbaf7dff7aecdcd4, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x73e8c35fa646fce6bf10c33168dcf3d2e40af17ced70b1929826d0ca4ba2e99, mulmod(
                add(0x243a084aa8c82348102320b0ad19ede41b6bd7ffb3a7041339a13f34f6b5671, mulmod(
                add(0x614a280377b9dc732773d969da5ddd8cc125262313eb7b2bd38b7668cdf00b4, mulmod(
                add(0x2039c72c1c7c134fb300e82b104394f54a5b7ffe6f7f00e7c3e4ca6640841a9, mulmod(
                add(0x6fb8324456f1dc4b423220d18d40de524a27dc4f35e4c780a042f6edc95f97d, mulmod(
                add(0xb6bca44a12ba7914e575f83cf8b9b8bcd4780622806901dcb9530ff9a454f8, mulmod(
                add(0x522f83a59f717f37b235c05338a02630ad83c3ed307838f6e795f9705cbc849, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x575b929bc0caa43939bfae95a6d5cd8d4082be7fe0934be4c08f7fd3cbe89c5, mulmod(
                add(0x3b74f537f03a28e72bae3bf1810f1a2fde1711eacd6bc64bf55f37b3bd9940b, mulmod(
                add(0x2d32dd179cf74693057ede607e0054fbc3e4194efd6415156f3ec909c37ead2, mulmod(
                add(0x25ea89f2d7ad620296fda2be181b5a6be626eade8974facd81e53df842c125b, mulmod(
                add(0x24a083b7cf164138ea0c468f33317d89c97b69378c906d918123f3ed5a02cf7, mulmod(
                add(0x1365aaaf8c72d7e9b250bd91ee2c2264362e87679abcf2df2b7a4e1eda1575f, mulmod(
                add(0x64f6f50e51b19d5a90e6d2c9cfc3486dbf2b37c7f949cc4f8ac4dd988e5bdff, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x1b18b73effab8a483156d16e87be4dfce1250333eafc784d76c6ee145978c48, mulmod(
                add(0x3f22422d66d77bda123b47b7f5bffe5527f95d331346f6a545c66887ad75ab9, mulmod(
                add(0x653405343098520984b06f707cee84ea765ecc932783cca87058b88d0f2bbe9, mulmod(
                add(0x547ddf1021a2cbacc8081cbe3a5c89b8ae808942513cd6f6ad166b0306cee66, mulmod(
                add(0x6475aad2a1631a6103b238548fe8a03934779ecadeaead2bc20a677c0c71c, mulmod(
                add(0x7a7d5ce80c8498175cdd4408e08cea457517e37dcba08d0a6cd2a4defcce34d, mulmod(
                add(0x7ab2a5ce120c251b658bfe532880535e93cbf88aa60a1b384017195e6715706, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x422c03b47f25f698d3dfbb02556367c97b7d8e2657af2e45ebc61845aa2c52b, mulmod(
                add(0x3a2c1769a49e0632c149dc9d3f30306f9d9cc00cdb426d58b2741c804c51af4, mulmod(
                add(0x43b4be816239e45b4d22123c840717fe3e8f6ce53238fad4ad56e27c85f3e9, mulmod(
                add(0x405f9011670f0f202814795cdf0251b665e8f39991dfe2282a1dd2acdbaccb1, mulmod(
                add(0x4c35c95cf7170d2ab6b9b6e3c1be66dba2de170638f27975fb5ec12c36a45d, mulmod(
                add(0x592d2fbca1f86935e587f6cfdacd0a221237bd378e2d1cbadc3d168c7a1756c, mulmod(
                add(0x2843bf3d789d84faebdd6ceb0eed3ec0acd959732178b00b4242eb5cff0ef3a, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x48876d457eaebe03383add02eb4c0c49a09923757428595a4f3ad6299d69cba, mulmod(
                add(0x4de104ea20937d5d6cb02c4ab4d7c4d03ab2eb16d1b837ccf0c2a05ea2873b1, mulmod(
                add(0x4245e03d0378593b2d4230b945a2a147b36ebfdf368f0dd5fc22e3b31ac1186, mulmod(
                add(0x3c05c93a63aad66725d8d25e62f76199a1e9f5743577777caa05832f4e79acc, mulmod(
                add(0x6b735de6be3ab4aa1425c328c838ba09dec586718729f1e172554cac036483b, mulmod(
                add(0x2059b2385d435959cedebbb68ab5c484441832a20d67889ff9974057cdbf874, mulmod(
                add(0x5a47f80b2d6e8c8e89f08c23e4eee09ae23882290a4dbdc5d0b09e713297124, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x40cbcae9364d8af8b767a72b260793922cf1ba2a03fedfc60d4eab1d5f00042, mulmod(
                add(0x771fefe011becb392f5c379dc9e902c41be8f1069ae3c5e0bf6016b7b1b3f55, mulmod(
                add(0x6d9c76938c974418e62166285ade6564712e6a263357e11d70f3e1f2ae531e8, mulmod(
                add(0x1706af2f962881d86f167571fcbb909b6f1e4fa386fca8d87b674335196f44b, mulmod(
                add(0x416057baac3a1780d7d25b192188b9b3981bdcab0e2dffb2fd95456a5313201, mulmod(
                add(0x1da9b14257c5c5cbc1a97aff87690dfa51e82af9a11eaf5cb2538f595ea2105, mulmod(
                add(0x6d6ed610ff1347a9252bf835af9666acc415b28796d968ab76353cdc1181733, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x754535ea8702292678b57fbde36c97454994bed59e0d0e13cf8a6c3ef7a0324, mulmod(
                add(0x6581a70ec64b4268a4741b4f7de866050d31b69005c782630f4bdc51a1650b2, mulmod(
                add(0x4195cb2f46ca4e1ef5d93ab3a5decbdc9e74d0bb81d56abcf59304ecf79863c, mulmod(
                add(0x3410d8b91297b00cf8d438bea18b9ebd55ae441a2f6bac6623a15e43ad64d4d, mulmod(
                add(0x4dbe5188f23eedad88bab99323be5ac9bf747525c23d4c0665334dafd1f0c6, mulmod(
                add(0x77273f7030b86a46aee79ed44f0968feb0ffccfa0964ffff141e693fd0fb6d1, mulmod(
                add(0x274b54e6342ced28b28c62edbc8a6cdb44d1530e0fba56e4940e55d806f437f, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x7fe75f49544ac3cf237a17e58179851f5b3e7420330e5861ec505291d9a0380, mulmod(
                add(0x3b591c6de6700576abbe4b4544de71cd3266a5dbb70740762d0c16a863bead8, mulmod(
                add(0x5bdc50def36283e003e9ccf2f1bed188326bec8bed554815f9e49062ed6da4a, mulmod(
                add(0x5b0a8465067d8f43cac5dbc1145110e1e79e0f32ba1d59d2514405a0a806860, mulmod(
                add(0x446d7e2595a1940ab7f6dec4c9f78953de9c0f4c67a130b55f1894779e73ac3, mulmod(
                add(0x297d52739d69b228b057588496920930df6ada28e5e2a431b65502750a5bad7, mulmod(
                add(0x71034c062fdc1b61e812617b037c5dd1e80d158a92bdae7ccaec162fff4edd3, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x688dbf5c443560c219afd8c54a0b26bdc9284925f2cc0adc889c1de024d6ecd, mulmod(
                add(0x6c647f1e5e8e93fda4bc0ae5d513cb60558e2b44bf885484161bbfb5e093969, mulmod(
                add(0x3fdf21da099da6c005b076001c5a95f2fe26aeff47e2cb9e8e52166a22b643e, mulmod(
                add(0x46ebc0bdf94c2f85023a0c1b29d229ef7a23e173d310b814f72c73904f6a5f9, mulmod(
                add(0x630cb6b8bcbe79e58025a699d489116a875f287fef6f1677b497b8702c3777d, mulmod(
                add(0x66bb11e034bb55410211b7cd410cf076db77f008bd93f0dc938f089e853f0ee, mulmod(
                add(0xe09e3870dab755cabbeac23076891b510207da569b75bf32d3f63c8ce08460, mulmod(
                    result,
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME)),
                x, PRIME))

            result :=
                add(0x3c782f4a1a6d94adf1448fd7feef975f47af9c79bbf7e2d74940673704b828a, mulmod(
                    result,
                x, PRIME))


        }
        return result % PRIME;
    }
}