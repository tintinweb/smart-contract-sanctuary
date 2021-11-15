//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IOldMetaHolder
/// @author Simon Fremaux (@dievardump)
interface IOldMetaHolder {
    function get(uint256 tokenId)
        external
        pure
        returns (
            uint256,
            string memory,
            string memory
        );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IOldMetaHolder.sol';

/// @title IOldMetaHolder
/// @author Simon Fremaux (@dievardump)
contract OldMetaHolder is IOldMetaHolder {
    function get(uint256 tokenId)
        external
        pure
        override
        returns (
            uint256,
            string memory,
            string memory
        )
    {
        if (tokenId == 1) {
            return (
                1891779262497205,
                'Fana',
                'QmZQYVKggf3FHfF68C7qjMNqQYAgnYDa7UBe35Bqg1tKL9'
            );
        }
        if (tokenId == 2) {
            return (
                3019419497262163,
                'georgeboya',
                'Qma5UjjVVJfg3uzk4BHJrvn8REpahurgQCtRJPeju2wBe7'
            );
        }
        if (tokenId == 3) {
            return (
                7689739740778617,
                'SnaileXpress',
                'QmVGe3Hd6ggPR4uPfZ8iw2A3ZWDwNzFXbhUCkERMpywrvT'
            );
        }
        if (tokenId == 4) {
            return (
                6982555367698223,
                'studionouveau',
                'QmTSm5nCcFSL9GrWR8EJtPSraXJ6VE3KWJM5eqRhs1aScn'
            );
        }
        if (tokenId == 5) {
            return (
                1510385436526155,
                'DAIMALYAD',
                'QmPh8hgqTzmt7wzXcZofiDNAvoirefGu1yE2bz6btFmyBC'
            );
        }
        if (tokenId == 6) {
            return (
                5923251554066009,
                'ChaosC',
                'QmUBe17AqQBLRKkc6Ary5Vzfni7mv6yCKoSuUFP1ZCCeL4'
            );
        }
        if (tokenId == 7) {
            return (
                8791714849687747,
                'HODL',
                'QmZZjjkFRjPsDW3QBRiXToozk56Vk2yZB6MW23MHNCqkgV'
            );
        }
        if (tokenId == 8) {
            return (
                6988284344166647,
                'HisDudeness',
                'QmTaXXRmMZstDMaR7fqdXvViU2d4o3h6Z8w5fgXihxtpFF'
            );
        }
        if (tokenId == 9) {
            return (
                4520157963886749,
                'STUREC',
                'QmYYFDCPrCCV2Eie1kWTwmffka5gY4r8MLq5hfwuJwD7nC'
            );
        }
        if (tokenId == 10) {
            return (
                8687588643696989,
                'WMP',
                'Qmcqxn9vUwU1MRC4xA57jhGB2zaRHorKhWwYDdr4zmAFnK'
            );
        }
        if (tokenId == 11) {
            return (
                5948983295283979,
                'Evil',
                'QmXnv4Vmo6LH5AxHykx5czHMKC5pXAuHDv8c5xhqXTSqf5'
            );
        }
        if (tokenId == 12) {
            return (
                2557921492214273,
                'MehakJain',
                'QmedQq5eXWn8MtEmZLQDwdeqHJrVuZNYpwwKppubThBKMP'
            );
        }
        if (tokenId == 13) {
            return (
                4923016702189283,
                'TACO',
                'QmX8qekdJAu7HFFjRARBSWgrzNidtcb78or93pDGxnEwiJ'
            );
        }
        if (tokenId == 14) {
            return (
                503230352259835,
                'JJ',
                'QmWEykS91b1Sm2U169UWt6LEL7uNd1YswE2DsKUXgWq5sZ'
            );
        }
        if (tokenId == 15) {
            return (
                3393466007662535,
                'bluen1ne',
                'QmTUo524U8HYVH3Jj6Bs8BMPpEmBPJC2GWEVYQj71BFuPs'
            );
        }
        if (tokenId == 16) {
            return (
                5968451401041859,
                'everlasting',
                'QmV22YbH8VDbRSSrwp2rCxWb42i6TQjSQ9ovLSMS3Ancz4'
            );
        }
        if (tokenId == 17) {
            return (
                7755993193895255,
                'DragoNate',
                'Qmdx8RZUejp6CAfSc218bqFP45TA7jAe4Sz5JQbAQBkd8J'
            );
        }
        if (tokenId == 18) {
            return (
                4875848917732907,
                'BabyLion',
                'Qmf9RxknEmvnVfFXe9PnnFayzTwZUW6NZ2nLahs79fpbTL'
            );
        }
        if (tokenId == 19) {
            return (
                3456254112895985,
                'bergleeuw',
                'QmSQsQiAJHWNPekaL7NqDt8zcfRYCApKEMjainBMoZmB6H'
            );
        }
        if (tokenId == 20) {
            return (
                7098169906134027,
                'Enigma',
                'Qma69PAFnsgecw9sJzZRGc2yzMJY62ibJpwUcokuhzBref'
            );
        }
        if (tokenId == 21) {
            return (
                3457563018359027,
                'barthazian',
                'Qmea4eDirwcguSLSyyS86y2a3PwcWSmtT4cw8b1sLGETqf'
            );
        }
        if (tokenId == 22) {
            return (
                5816344603404167,
                'URBANA',
                'QmNaHjSvZUJqB1TZ3mVgD2JdeK6ctY9c2WGLNSywjpGpaB'
            );
        }
        if (tokenId == 23) {
            return (
                3174680349988913,
                'tea_eye',
                'QmfThzkWFgn4cb9wAJ3NPMP2mZACsvCx3tohVRrHFAGqCH'
            );
        }
        if (tokenId == 24) {
            return (
                8496431026892907,
                'Gotrilla',
                'QmPpMpqBgXGuNA3eFj1dvKND8rkQtabQgM3VDoLxPCcpV3'
            );
        }
        if (tokenId == 25) {
            return (
                413351762046683,
                'jims',
                'QmUNAwEM63YvnaZEaVhH9YBM5aA7qL9M8ey8x8CunHks9B'
            );
        }
        if (tokenId == 26) {
            return (
                1138136008402565,
                'Tomato',
                'Qmci3YFcU7VMao3z11BatFX9NypUbv6Acs8ZokQK4v3omr'
            );
        }
        if (tokenId == 27) {
            return (
                375537615587261,
                'Harambe',
                'QmdAsSbhfPg5XdS2AuuuUNQuVUoSU43XARN6ZX4Jh3L2Fy'
            );
        }
        if (tokenId == 28) {
            return (
                8090389347118167,
                'SP4CE',
                'QmProUnCGpmK5PoUiuzYoF4zw7DCxxiBo2zRXfDidmstQy'
            );
        }
        if (tokenId == 29) {
            return (
                5400266765307335,
                'cali',
                'Qme4KQU1W4jfYX5BHvNDEckRnzSTNTFefUyYqjbSgKieSd'
            );
        }
        if (tokenId == 30) {
            return (
                2597411029448361,
                'bryanbrinkman',
                'QmWbi8zvBvwzv8yrubtL83udFXXJ8d7BwacCAuMNz7b2F9'
            );
        }
        if (tokenId == 31) {
            return (
                3936824586365177,
                'CPyrc',
                'QmR2cdB8uFVKEM2x5B5d7vw21fYHwWEyUpsZTdirDWnAb4'
            );
        }
        if (tokenId == 32) {
            return (
                1885984200493465,
                'bitch',
                'QmfBiXPmaaKudKUgoqSJzqchiBvxc4yYUgyrpWR27qw2Fw'
            );
        }
        if (tokenId == 33) {
            return (
                4383631648904757,
                'redlioneye',
                'QmYhJhKZduPdwRUUbAHi8V2F51vKh6NnVSpQZUNkir1o5f'
            );
        }
        if (tokenId == 34) {
            return (
                2230863757095789,
                'AnnMarieAlanes',
                'QmRHPaU4or41Dbnb9t7nfe5j8r6rma6XUPQGUnZqM2FGRd'
            );
        }
        if (tokenId == 35) {
            return (
                418337872527845,
                'xray',
                'QmewNDHACH2GsC3TLcyZokeydEJN5EdHwnG7B3wwcFpyXp'
            );
        }
        if (tokenId == 36) {
            return (
                4080317775462397,
                'Twobadour',
                'QmSBRnpNxhZV8ji34QFfvZe2NQZJ8ovApw7YUZrjp4SkCk'
            );
        }
        if (tokenId == 37) {
            return (
                4298717361819411,
                'Space',
                'QmNkMEMSEqvjyt8hzMBHjYNRDvrpzuYX3QGLgcdLk65PKq'
            );
        }
        if (tokenId == 38) {
            return (
                8729027721952123,
                'Pablo',
                'QmWfSPSmFG6HZYV4u3uE14MtAt4Jq5yLcXTLe61LAZtnxq'
            );
        }
        if (tokenId == 39) {
            return (
                2388704601596245,
                'Desi',
                'QmeQvDa4knJ5dY9zcd9LvLzwRFm88SXGkFzTbzjbMekzXw'
            );
        }
        if (tokenId == 40) {
            return (
                8393750241199603,
                'Hunter_NFT',
                'QmVowT6nhZRdSMDRiVjs1m37N84BVR6uPREobBSTKCbrUW'
            );
        }
        if (tokenId == 41) {
            return (
                4562793198440239,
                'nftartcards',
                'QmWDNtC33SYPVnybZEUYfm4Kc9XV2U9CgZAgo45bhttjQ7'
            );
        }
        if (tokenId == 42) {
            return (
                153705409506349,
                'BruceTheGoose',
                'QmXfezn24ntPJgneUfUeP7mkvc9BUDekqxNZ5ahkmzgQFa'
            );
        }
        if (tokenId == 43) {
            return (
                142983777563647,
                'Silence',
                'Qmf4becQQJXWcnZB1Cv7r4bHG2dVdYKWRxeRvgmkmQ3tUG'
            );
        }
        if (tokenId == 44) {
            return (
                2806355914071487,
                '07.12.19',
                'QmcWhKd2X9hh5KBNbj8vQCDoGYBhZTdRLmvNSMR6WWW7nQ'
            );
        }
        if (tokenId == 45) {
            return (
                7737953903733737,
                'MantaXR',
                'QmQoHTabQQVYA9jHCRb39hQmDqTr2vhBbLyzcPEs67sNuw'
            );
        }
        if (tokenId == 46) {
            return (
                6802622488411019,
                'NGMI',
                'QmZTWu9TkgMguwmckThfcRpKGTtM76dLr2AnfQLYkHGMTF'
            );
        }
        if (tokenId == 47) {
            return (
                2453013391125737,
                'BitAndrew',
                'QmVTJJVh9x9P1wFifffFA39mzod6KGRKLHVFbyw1ontQ7s'
            );
        }
        if (tokenId == 48) {
            return (
                2465057794406231,
                'NFTValley',
                'QmNkT7KHcL4NvyrXhL4b98Lq5AnjFK85SELzcKZnhDj2J3'
            );
        }
        if (tokenId == 49) {
            return (
                4991684195400103,
                'Wallkanda',
                'QmbhFf7XF76HY7unRMoMT6NT5HpYhEMt8xyExX3YV9xbTv'
            );
        }
        if (tokenId == 50) {
            return (
                5433022144351547,
                'CaktuxFundsArtTheft',
                'QmezKk6sC6FEGcaF8vtEA4TiqCXcdTL7PyiFnnmSEkEdCT'
            );
        }
        if (tokenId == 51) {
            return (
                875032090208313,
                'Atlantis',
                'QmZF3MWmfDy22bggbSJYQshjysRvVWKJkCKNQX1PCESMCB'
            );
        }
        if (tokenId == 52) {
            return (
                8771349494261373,
                'Joff',
                'QmTXtz67BrmwxYy1coHWBkoT4fm4avMVhEoVgAcLQRsg3K'
            );
        }
        if (tokenId == 53) {
            return (
                5236512245990149,
                'SuperMassive',
                'QmVyXMRC6ex1p8RGGrwEsyXRSvU4ioKy9NqJJr34syww59'
            );
        }
        if (tokenId == 54) {
            return (
                8622795196955971,
                'ShinjiAkhirah',
                'QmXg23tciPqvH4a36PuYadWVbpnuXhGP7UEqgmT4sUK83Z'
            );
        }
        if (tokenId == 55) {
            return (
                5591623809830205,
                'GREEKDX',
                'QmQqojVETod2yZNTTVNojhdNySPZ56R3uXy4XrE28Xe7uL'
            );
        }
        if (tokenId == 56) {
            return (
                4590813225046495,
                'APEDEV',
                'QmeV97pf42tzt9b4f4J4jpvBfER1BEi2zonw6HBXJvuEVq'
            );
        }
        if (tokenId == 57) {
            return (
                4745774527000625,
                'Ebbo',
                'QmUhiA7c8E8WTKppz85YqBFMxjssJhkbtwJhGLRv31CbtZ'
            );
        }
        if (tokenId == 58) {
            return (
                4862399629459103,
                'SuperTopSecret',
                'QmXiFnUV6QNhfbx7ACkcWdyPvkt6gpeEE83xKTLWHMX155'
            );
        }
        if (tokenId == 59) {
            return (
                4381414138919363,
                'WHYNOTME',
                'Qmc6b56YNrgTfavzx1c47pt1J1LFUXkg7dYv6wg8knmuXy'
            );
        }
        if (tokenId == 60) {
            return (
                7391300037459061,
                'ElonMusk',
                'QmQAuq1a9jm2Dr6sG3HtwGH4xRmTkn5AWE74pPrCAU641t'
            );
        }
        if (tokenId == 62) {
            return (
                115990660039927,
                'WGMeets',
                'QmXTJabgMuhGi5etbKj6jnEKwS4pN8qJHHipAsTjC76J3T'
            );
        }
        if (tokenId == 63) {
            return (
                5079846608831287,
                'HumptyDigital',
                'QmaWCeSutLtNJ6DXvsMtkZvwM8isVx1Z3r8R7YC6wcGDyJ'
            );
        }
        if (tokenId == 64) {
            return (
                5570565631105865,
                'orty',
                'QmcYg3FetydSsgU2usHtAdWEMrmYveDgLsCpcNMo2pMntk'
            );
        }
        if (tokenId == 65) {
            return (
                5977411952183263,
                'SysAdmInCrypto',
                'Qme8dBkZjG1iTkjG86a7KxwjMBxsjUe2e5eLSgKW1HgcTn'
            );
        }
        if (tokenId == 66) {
            return (
                7973704714097377,
                'RFC',
                'QmRBiK1eqgFWDxKCMRP9CcfZHE4QMqmVnnycq6SgFPVhRR'
            );
        }
        if (tokenId == 67) {
            return (
                8304996682849101,
                '555',
                'QmUPbEg9uQ4vRgt4qSw5X9R9NwvZNFKbGuimQe4cdRLPrk'
            );
        }
        if (tokenId == 68) {
            return (
                7185966646180013,
                'guido',
                'QmeyVk7NAYpZFqwyfNZktoLhC93hMDKGeYUqWGVm7vcqjX'
            );
        }
        if (tokenId == 69) {
            return (
                3645940995873561,
                'Tazposts',
                'QmPexfrP6H9Jf11AWP92qKYMaoh7gA4yoBAuese6aqkA8n'
            );
        }
        if (tokenId == 70) {
            return (
                181688662956301,
                'FRAMBOR-BREWERY',
                'QmUMMu1np9wx1UNdZcTCsRMzwsopNEu3UYC4cz7D77Ntum'
            );
        }
        if (tokenId == 71) {
            return (
                8117363819514271,
                'Chiara',
                'QmbVFTNmER4ETHuvL4nPSftYuaSkgRuWhT6rAvjkRZ8aGP'
            );
        }
        if (tokenId == 72) {
            return (
                8454038579543797,
                'm00se',
                'Qmc6EB3BU73fBmx6FANTb4RenZ4us4vwT145tsY9JTnzRU'
            );
        }
        if (tokenId == 73) {
            return (
                5818393290185465,
                'DAAN',
                'QmVfPcZvbFtQ4EeyzZouuZ84rJDaSb5vb8h9PwHULsW5b8'
            );
        }
        if (tokenId == 74) {
            return (
                4473354115576139,
                'STIJN',
                'QmPnNMgHhGSzbHSQpvbc3gMb3xMuEca3Ha2vipvDzcAoKZ'
            );
        }
        if (tokenId == 75) {
            return (
                196038521084569,
                'EMMA',
                'QmRpHVLftC9Z5DiEUtRJrcsqS7BTE5j9TzcgqRHLNxXqUJ'
            );
        }
        if (tokenId == 76) {
            return (
                4636829616986687,
                'simulation',
                'QmfSQp9H9U1LeKmguhBt6p8m3euaAXUeo6J2F7BiP2Kgxs'
            );
        }
        if (tokenId == 77) {
            return (
                1234385732989531,
                'Jazz',
                'QmQbCq1dmQVL4q6jpTw5YYDPT5mG2FkLJdbvksawviFRtc'
            );
        }
        if (tokenId == 78) {
            return (
                2124383117365177,
                'Internaut',
                'QmZSsCtQHb9E2q6dHy7uMpDHERNNxUGz76jbTogyx5ijSc'
            );
        }
        if (tokenId == 79) {
            return (
                3965933145713547,
                'bootoo',
                'QmQU7t5xopVHo494KAm9c9QM9o6GenvxnGw4NrLnA6UE4B'
            );
        }
        if (tokenId == 80) {
            return (
                3937211439401641,
                'Jivinci',
                'QmS5dCwUPrsKEZSg7pHqAezibKWSywKUuCTgf3mGznj1uS'
            );
        }
        if (tokenId == 81) {
            return (
                8590927387405867,
                'Aires',
                'QmSBKFRdr1FHBTACe6QUvsjTZ84mdR4E5fXgiRpZPj7kCW'
            );
        }
        if (tokenId == 82) {
            return (
                8730501088474769,
                'ZMM',
                'QmVuR564BKiQsP96SU3bQrZf9Dazp8mFZQfU3RUTE1ZnY6'
            );
        }

        if (tokenId == 83) {
            return (
                941601682289385,
                'Zorro',
                'QmNvNHcSZbmTXG6tHvb11zZirixQkxunUQdYX69yRmiPf3'
            );
        }

        if (tokenId == 84) {
            return (
                6736220662735793,
                'Utopia',
                'QmNMfh86tTgxqf9vPctdAeYAeELyCfUYNiGqPte41aPwkt'
            );
        }

        revert('Unknow tokenId');
    }
}

