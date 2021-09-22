// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface OpenStoreContract {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract DuckOwnerProxy {
    address public openStoreNFTAddress;
    uint256 public baseNumber = 81051682759312351887842295081699468782319279963069916326007376000000000000000;
    uint56[143] public ducks = [
        uint56(214849514110977),
        uint56(218148048994305),
        uint56(483130351288321),
        uint56(220347072249857),
        uint56(482030839660545),
        uint56(222546095505409),
        uint56(223645607133185),
        uint56(224745118760961),
        uint56(225844630388737),
        uint56(226944142016513),
        uint56(228043653644289),
        uint56(229143165272065),
        uint56(230242676899841),
        uint56(231342188527617),
        uint56(232441700155393),
        uint56(233541211783169),
        uint56(234640723410945),
        uint56(235740235038721),
        uint56(237939258294273),
        uint56(236839746666497),
        uint56(239038769922049),
        uint56(240138281549825),
        uint56(241237793177601),
        uint56(242337304805377),
        uint56(243436816433153),
        uint56(244536328060929),
        uint56(245635839688705),
        uint56(246735351316481),
        uint56(247834862944257),
        uint56(248934374572033),
        uint56(250033886199809),
        uint56(251133397827585),
        uint56(252232909455361),
        uint56(253332421083137),
        uint56(254431932710913),
        uint56(255531444338689),
        uint56(256630955966465),
        uint56(257730467594241),
        uint56(258829979222017),
        uint56(259929490849793),
        uint56(261029002477569),
        uint56(262128514105345),
        uint56(263228025733121),
        uint56(264327537360897),
        uint56(265427048988673),
        uint56(266526560616449),
        uint56(267626072244225),
        uint56(268725583872001),
        uint56(269825095499777),
        uint56(270924607127553),
        uint56(272024118755329),
        uint56(273123630383105),
        uint56(274223142010881),
        uint56(275322653638657),
        uint56(276422165266433),
        uint56(277521676894209),
        uint56(278621188521985),
        uint56(279720700149761),
        uint56(280820211777537),
        uint56(281919723405313),
        uint56(283019235033089),
        uint56(284118746660865),
        uint56(285218258288641),
        uint56(286317769916417),
        uint56(287417281544193),
        uint56(288516793171969),
        uint56(289616304799745),
        uint56(290715816427521),
        uint56(291815328055297),
        uint56(292914839683073),
        uint56(294014351310849),
        uint56(295113862938625),
        uint56(296213374566401),
        uint56(297312886194177),
        uint56(298412397821953),
        uint56(299511909449729),
        uint56(301710932705281),
        uint56(302810444333057),
        uint56(303909955960833),
        uint56(305009467588609),
        uint56(306108979216385),
        uint56(307208490844161),
        uint56(308308002471937),
        uint56(309407514099713),
        uint56(310507025727489),
        uint56(311606537355265),
        uint56(312706048983041),
        uint56(313805560610817),
        uint56(314905072238593),
        uint56(316004583866369),
        uint56(317104095494145),
        uint56(318203607121921),
        uint56(319303118749697),
        uint56(320402630377473),
        uint56(321502142005249),
        uint56(322601653633025),
        uint56(323701165260801),
        uint56(324800676888577),
        uint56(325900188516353),
        uint56(326999700144129),
        uint56(328099211771905),
        uint56(329198723399681),
        uint56(330298235027457),
        uint56(331397746655233),
        uint56(332497258283009),
        uint56(333596769910785),
        uint56(334696281538561),
        uint56(335795793166337),
        uint56(336895304794113),
        uint56(337994816421889),
        uint56(339094328049665),
        uint56(340193839677441),
        uint56(341293351305217),
        uint56(342392862932993),
        uint56(343492374560769),
        uint56(344591886188545),
        uint56(345691397816321),
        uint56(346790909444097),
        uint56(347890421071873),
        uint56(348989932699649),
        uint56(354487490838529),
        uint56(350089444327425),
        uint56(351188955955201),
        uint56(352288467582977),
        uint56(353387979210753),
        uint56(367681630371841),
        uint56(366582118744065),
        uint56(365482607116289),
        uint56(364383095488513),
        uint56(363283583860737),
        uint56(362184072232961),
        uint56(361084560605185),
        uint56(359985048977409),
        uint56(358885537349633),
        uint56(357786025721857),
        uint56(356686514094081),
        uint56(355587002466305),
        uint56(434751839666177),
        uint56(436950862921729),
        uint56(439149886177281),
        uint56(442448421060609),
        uint56(444647444316161),
        uint56(446846467571713)
    ];
    // uint48
    constructor(address _openStoreNFTAddress) {
        openStoreNFTAddress = _openStoreNFTAddress;
    }

    function checkIfDuckOwner(uint256 duckID) public view returns (bool) {
        require(duckID >= 1 && duckID <= 333, "Duck ID should be in range");
        uint56 offset = ducks[duckID - 1];
        uint256 tokenID = uint256(offset) + baseNumber;
        OpenStoreContract nft = OpenStoreContract(openStoreNFTAddress);
        return nft.balanceOf(msg.sender, tokenID) == 1;
    }
}

contract DuckOwnerProxyTests is DuckOwnerProxy {
    constructor(address _openStoreNFTAddress) DuckOwnerProxy(_openStoreNFTAddress) {
    }
    function openStoreBalanceForOwner(address owner, uint256 tokenID) public view returns (uint256) {
        OpenStoreContract nft = OpenStoreContract(openStoreNFTAddress);
        return nft.balanceOf(owner, tokenID);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}