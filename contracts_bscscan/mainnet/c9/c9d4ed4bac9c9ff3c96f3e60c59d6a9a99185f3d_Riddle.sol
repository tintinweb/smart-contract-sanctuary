/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT

/*
 
   ▄████████ ███    █▄  ███▄▄▄▄      ▄████████                                                                        
  ███    ███ ███    ███ ███▀▀▀██▄   ███    ███                                                                        
  ███    ███ ███    ███ ███   ███   ███    █▀                                                                         
 ▄███▄▄▄▄██▀ ███    ███ ███   ███  ▄███▄▄▄                                                                            
▀▀███▀▀▀▀▀   ███    ███ ███   ███ ▀▀███▀▀▀                                                                            
▀███████████ ███    ███ ███   ███   ███    █▄                                                                         
  ███    ███ ███    ███ ███   ███   ███    ███                                                                        
  ███    ███ ████████▀   ▀█   █▀    ██████████                                                                        
  ███    ███                                                                                                          
   ▄▄▄▄███▄▄▄▄      ▄████████     ███        ▄████████  ▄█    █▄     ▄████████    ▄████████    ▄████████    ▄████████ 
 ▄██▀▀▀███▀▀▀██▄   ███    ███ ▀█████████▄   ███    ███ ███    ███   ███    ███   ███    ███   ███    ███   ███    ███ 
 ███   ███   ███   ███    █▀     ▀███▀▀██   ███    ███ ███    ███   ███    █▀    ███    ███   ███    █▀    ███    █▀  
 ███   ███   ███  ▄███▄▄▄         ███   ▀   ███    ███ ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀   ███         ▄███▄▄▄     
 ███   ███   ███ ▀▀███▀▀▀         ███     ▀███████████ ███    ███ ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ▀███████████ ▀▀███▀▀▀     
 ███   ███   ███   ███    █▄      ███       ███    ███ ███    ███   ███    █▄  ▀███████████          ███   ███    █▄  
 ███   ███   ███   ███    ███     ███       ███    ███ ███    ███   ███    ███   ███    ███    ▄█    ███   ███    ███ 
  ▀█   ███   █▀    ██████████    ▄████▀     ███    █▀   ▀██████▀    ██████████   ███    ███  ▄████████▀    ██████████ 
                                                                                 ███    ███                           
*/

pragma solidity =0.8.11;

contract Riddle {
    /*
     * Welcome
     * =======
     *
     * Welcome to another riddle from your friends at Rune Metaverse!
     *
     * This one is slightly... different from what you're used to. Instead of answering on Telegram, you answer directly
     * with the contract.
     *
     * There are a series of gates to pass, each containing its own challenge. Only by passing all the gates will you
     * gain the RXS and Runewords locked within.
     *
     * Prize Pot
     * =========
     *
     * The initial prize pot was funded with:
     * - 10,000 RXS from Matt
     * - 10,000 RXS from Spontaneous
     * -  5,000 RXS from Lazy
     * -  2,051 RXS from Scrooge McDucky
     * -  1,000 RXS from Monk
     * -  1,000 RXS from Riccardo
     * -  1,000 RXS from SamKouCaille
     * -  1,000 RXS from WingedSpawn
     * - A rare Elder (5% yield, 14% shard, 2% magic, 1% rune exchange) from Discomonk / Purrrrrrrrrrrrrrrrrrrrrrrrrfect
     * - A magical Guiding Light (80% yield, 6% burn) from FireLord
     * - A rare Mercy (5% yield, 15% pool, 1% avoid burns, 1% random runeword) from FireLord
     * - A rare Lorekeeper (2% yield, 1% burn) from Andrej
     * - A rare Balance (3% reduced fees, 4% hidden pool, 0% burn, 15% rune exchange targets Tal) from Hurricane
     * - A rare Instinct (3% yield, 2% reduced fees, 2% pool, 2% guild, 5% critical bonus, 0% burn) from Blackbeard
     * ...but, each time someone plays, the RXS prize pot increases! (Use BSCScan to see the realtime prize pot value.)
     *
     * Tolls
     * =====
     *
     * To discourage spamming answers, each time you attempt a gate, you'll pay a toll in RXS. The first attempt of a
     * gate will cost 10 RXS (about $0.20 at the time of writing) and each additional attempt will cost 10 RXS more than
     * the previous attempt. (E.G. if you make 5 attempts at a gate, you'll pay 150 RXS [about $3].)
     *
     * Sure you might want to spam the answers if you have RXS to spare, but otherwise it pays to do your research
     * before attempting a gate! When you move on to a new gate, the toll for the new gate will restart at 10 RXS.
     * You do *not* have to attempt the gates in order, but you might find later gates build on what you've learnt in
     * previous ones.
     *
     * The toll fees will go automatically into the prize pool, so the more wrong answers there are the better for the
     * eventual winner.
     *
     * How to Play
     * ===========
     *
     * This is quite a technical game and I'm not expecting it to appeal to everyone. That said, if you wanted to take
     * part, it will be a great way of learning something about coding and how the blockchain works - so should be fun
     * and educational. You'll interact with the contract using BSCScan. The Read tab of the contract interaction screen
     * will show you the progress of other players too.
     *
     * To be able to enter the challenge, make sure you've called approve() on RXS to this contract, remembering to
     * add 18 zeroes to the number of RXS you want to approve (you might say doing this is the 0th gate :-P).
     *
     * To reduce blockchain snooping, many gates will require you to submit your answer as a signature
     * (Matheus should be able to help with this). These gates will have a parameter 'bytes calldata signature'.
     * To get the signature, use the Rune.game signing service. E.G. if your answer is '1234', submit the signature from
     * https://rune.game/sign?message=1234
     *
     * The answers to all gates that require answers are whole numbers (integers), so you'd only be wasting gas
     * if you tried 'hello', '1.5' or '6%'.
     *
     * Hints
     * =====
     *
     * The gates are all Rune-related. They are purposely written in bad Solidity, so please don't use this as a
     * training resource if you're learning to code! They are purposely left with little instruction. If you get stuck
     * and want a hint on a gate, message @defimatt on TG with something like 'Hint gate 1'. If a hint is available, you
     * will be asked to send RXS or a runeword to the contract, further increasing the prize pool, before getting your
     * hint.
     *
     * There may be multiple hints per gate, but each hint you ask for will get progressively more expensive.
     *
     * If gates remain unpassed for a while, I might end up dropping hints in TG / Discord / Weekly Streams / Rune's
     * Twitter or Facebook accounts, but no promises!
     *
     * Warning
     * =======
     *
     * Make sure you pay attention to whether you've passed a gate - continuing to attempt a gate after solving it
     * will continue to charge a toll! You can view the gates you've passed on BSCScan or on the leaderboard (below).
     *
     * UI
     * ==
     *
     * Data from the game is made public (like who has attempted / passed which gates, how many attempts people have
     * had at each gate, etc.) so you can view people's progress directly on BSCScan. Also, just wanted to say a huge
     * thank you to SamKouCaille who has built an awesome leaderboard, which you can find at
     * https://runeriddle.netlify.app/
     *
     *
     * Have fun and may the best Raider win!
     *
     *
     */

    function attemptGate01() external {
        uint gate = 1;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        markGatePassed(gate);
    }

    function attemptGate02(bytes calldata signature) external {
        uint gate = 2;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        msg.sender == ms(
            rxs.balanceOf(0x2098fEf7eEae592038f4f3C4b008515fed0d5886)
        , signature) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate03(bytes calldata signature) external {
        uint gate = 3;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        (, bytes memory a) = 0xA9776B590bfc2f956711b3419910A5Ec1F63153E.call(abi.encodeWithSignature("totalSupply()"));
        (, bytes memory b) = address(967482580263510309931289294502318776486298064190).call(
            abi.encodeWithSelector(0x70a08231, 57_005)
        );
        msg.sender == ms(
            1e2 - ((((abi.decode(a, (uint)) - abi.decode(b, (uint))) / (.2 * 5 ether)) * 10**2) / (22_530 - 3_230))
        , signature) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate04(bytes calldata signature) external {
        uint gate = 4;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        address[35] memory a = [
            0x33bc7539D83C1ADB95119A255134e7B584cd5c59,
            0x1fC5bffCf855B9D7897F1921363547681F6847Aa,
            0x2098fEf7eEae592038f4f3C4b008515fed0d5886,
            0xa00672c2a70E4CD3919afc2043b4b46e95041425,
            0xBC996F2f6703cc13AA494F846A1c563A4A0f1A80,
            0x210C14fbeCC2BD9B6231199470DA12AD45F64D45,
            0x08fb6740Cc5170e48B2Ad8Cc07422d3302EF5e78,
            0x9449D198AB998388a577D4eBfDa4656D9fa3468a,
            0xe00B8109bcB70B1EDeb4cf87914efC2805020995,
            0xA9776B590bfc2f956711b3419910A5Ec1F63153E,
            0x7e8a6d548a68339481c500f2B56367698A9F7213,
            0x0D3877152BaaC86D42A4123ABBeCd1178d784cC7,
            0x56DeFe2310109624c20c2E985c3AEa63b9718319,
            0xFF0682D330C7a6381214fa541d8D288dD0D098ED,
            0x346C03fe8BE489baAAc5CE67e817Ff11fb580F98,
            0x2F25DbD430CdbD1a6eC184c79C56C18918fcc97D,
            0xD481F4eA902e207AAda9Fa093f80d50B19444253,
            0x90132915EbDe0CF93283D55AB3fBBA15449f95A9,
            0x3e151Ca82B3686f555c381530732df1cfc3c7890,
            0x5DE72A6fca2144Aa134650bbEA92Cc919244F05D,
            0x2a74b7d7d44025Bcc344E7dA80d542e7b0586330,
            0xfa3f14C55adaDDC2035083146c1cF768bD035E06,
            0x4FFd3B8Ba90F5430Cda7f4cc4C0A80dF3Cd0e495,
            0x919676B73a8d124597cBbA2E400f81Aa91Aa2450,
            0xeF4F66506AAaEeFf6D10775Ad6f994105D8f11b4,
            0x60E3538610e9f4974A36670842044CB4936e5232,
            0xdfFeB26FbaCF79823C50a4e7DCF69378667c9941,
            0x1656f8d69F2354a9989Fe705c0107190A4815287,
            0x098Afb73F809D8Fe145363F802113E3825d7490C,
            0x94F2E23c7422fa8c5A348a0E6D7C05b0a6C8a5b8,
            0x125a3E00a9A11317d4d95349E68Ba0bC744ADDc4,
            0xcd06c743a1628fB02C15946a56037CD7020F3Bd2,
            0xa89805AB2ca5B70c89B74b3B0346a88a5B8eAc85,
            0xfb134f1721bc602Eb14148f89e1225dC7C93D8d4,
            0x191472E8E899E98048AeB82faa1AE4Ec3801b936
        ];
        uint b;
        for (uint c; c < a.length; ++c) {
            (, bytes memory d) = a[c].call(abi.encodeWithSelector(bytes4(uint32(1889567281)), msg.sender));
            b += abi.decode(d, (uint)) >= 1e18 ? 1 : 1 / 1 - 1;
        }
        msg.sender == ms(
            b
        , signature) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate05(bytes calldata signature) external {
        uint gate = 5;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        uint8[18] memory a = [2, 1, 3, 5, 7, 8, 13, 4, 10, 17, 19, 20, 22, 14, 9, 12, 25, 21];
        address[33] memory b = [
            address(2 * 177214119904565425361218341727619176332701613128),
            address(3 * 99758782839603094778591252844355261651862684978 + a[0]),
            address(4 * 319767620414998917181998884799476973267515900517 + a[1]),
            address(5 * 15095219063565354588626531959767187526534670580 + a[2]),
            address(6 * 82657685029464546118828365860486970823916317486 + a[3]),
            address(7 * 130511760691490890946252451400976638605070547388 + a[1]),
            address(8 * 6409800978316216721310989577562022947709643727),
            address(9 * 6053369380083613799840661705566083841829832733 + a[4]),
            address(10 * 83115911514847712693555247361538639363656293691 + a[0]),
            address(11 * 77304283851627938253209830893630018648750999871 + a[2]),
            address(12 * 113851622159593472017475885602128716020819509625 + a[5]),
            address(13 * 90038020834493442842652666273151379363810807410 + a[5]),
            address(14 * 91341776798621089348972466033190525266471179286 + a[6]),
            address(15 * 56438456460013038098033833977762972049938069479 + a[1]),
            address(16 * 89586705461092592321516250253117639646106959245 + a[7]),
            address(17 * 63335997913188052129058166048293086213154210191 + a[1]),
            address(18 * 45695664678921078493527413356072400373369447618 + a[3]),
            address(19 * 5514436954205290262631870758423697640499083126 + a[0]),
            address(20 * 7159039711492599965054672866909203015569249807 + a[8]),
            address(21 * 8637556439405364085891981247500547710548231797 + a[9]),
            address(22 * 12234856527109915161430212118176913366883132991 + a[10]),
            address(23 * 24049246047791607099160737084125120849279845266 + a[11]),
            address(24 * 59527268710649131961067820764001453475283084266 + a[12]),
            address(25 * 5101493516962655984974093082113305227457245537 + a[13]),
            address(26 * 17563751791505756510144625434600964410623658186 + a[9]),
            address(27 * 19855233725315048351014677289671570162658217380 + a[9]),
            address(28 * 34375023449201520376460824444070973949255648809 + a[14]),
            address(29 * 41834626715888068080264719437898914423646029491 + a[15]),
            address(30 * 6288871078362358747328150331286748357960327281 + a[4]),
            address(31 * 46965737015898722379460404691519520676954007559 + a[11]),
            address(32 * 9230040038447307280301714847466804478239730402 + a[16]),
            address(33 * 7344864054811958179968100714298587583184571075 + a[6]),
            address(34 * 21247643057884144050972030901873235880642885647 + a[17])
        ];
        uint c;
        uint d;
        for (uint e; e < b.length; ++e) {
            (, bytes memory f) = b[e].call(
                abi.encodeWithSelector(bytes4(uint32(1882186159 + (1_889_567_281 >> 8))), msg.sender)
            );
            uint g = abi.decode(f, (uint));
            if (g >= c) {
                c = g;
                d = uint(uint160(b[e]));
            }
        }
        msg.sender == ms(
            d
        , signature) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate06(uint a) external {
        uint gate = 6;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        (, bytes memory b) = address(1_332_917_946_776_802_158_877_367_376_486_047_462_307_974_413_120).staticcall(
            abi.encodeWithSelector(0xb3dc00fe, a)
        );
        if (abi.decode(b, (uint)) == (1 + 2**800) - (2**800 + 1)) {
            markGateFailed(gate);
            return;
        }
        (, bytes memory c) = address((1102563883697759150083448 << 80) + 1159541255021426693438272).call(
            abi.encodeWithSelector(bytes4(uint32(1_666_326_814)), a)
        );
        msg.sender == abi.decode(c, (address)) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate07(bytes calldata signature) external {
        uint gate = 7;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        uint160 a = 182687704666362864775460604089535377456991567872 +
            45671926166590716193865151022383844364247891968 +
            22835963083295358096932575511191922182123945984 +
            1427247692705959881058285969449495136382746624 +
            356811923176489970264571492362373784095686656 +
            22300745198530623141535718272648361505980416 +
            11150372599265311570767859136324180752990208 +
            2787593149816327892691964784081045188247552 +
            1393796574908163946345982392040522594123776 +
            348449143727040986586495598010130648530944 +
            87112285931760246646623899502532662132736 +
            21778071482940061661655974875633165533184 +
            10889035741470030830827987437816582766592 +
            5444517870735015415413993718908291383296 +
            170141183460469231731687303715884105728 +
            42535295865117307932921825928971026432 +
            21267647932558653966460912964485513216 +
            1329227995784915872903807060280344576 +
            83076749736557242056487941267521536 +
            41538374868278621028243970633760768 +
            20769187434139310514121985316880384 +
            5192296858534827628530496329220096 +
            2596148429267413814265248164610048 +
            649037107316853453566312041152512 +
            81129638414606681695789005144064 +
            40564819207303340847894502572032 +
            10141204801825835211973625643008 +
            5070602400912917605986812821504 +
            39614081257132168796771975168 +
            1237940039285380274899124224 +
            309485009821345068724781056 +
            38685626227668133590597632 +
            9671406556917033397649408 +
            2417851639229258349412352 +
            604462909807314587353088 +
            151115727451828646838272 +
            37778931862957161709568 +
            18889465931478580854784 +
            4722366482869645213696 +
            2361183241434822606848 +
            1180591620717411303424 +
            295147905179352825856 +
            4611686018427387904 +
            1152921504606846976 +
            576460752303423488 +
            72057594037927936 +
            18014398509481984 +
            35184372088832 +
            8796093022208 +
            4398046511104 +
            2199023255552 +
            137438953472 +
            68719476736 +
            34359738368 +
            4294967296 +
            134217728 +
            33554432 +
            8388608 +
            1048576 +
            131072 +
            65536 +
            16384 +
            8192 +
            2048 +
            512 +
            256 +
            32 +
            16 +
            8 +
            1;
        (, bytes memory b) = address(a).call(abi.encodeWithSelector(0xbe4f9bd6, msg.sender, block.timestamp));
        msg.sender == ms(
            abi.decode(b, (uint))
        , signature) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate08() external {
        uint gate = 8;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        block.timestamp % 604800 >= 0x530E8 && block.timestamp % 0x93A80 <= 345_599
            ? markGatePassed(gate)
            : markGateFailed(gate);
    }

    function attemptGate09(bytes calldata signature) external {
        uint gate = 9;
        chargeTollForGate(gate);
        markGateAttempted(gate);
        uint a;
        {
            uint b = 38;
            uint c = 1524;
            uint d = 3548;
            uint e = (b % 10) - b / 10;
            uint f = c / 100 - (b % 10);
            uint g = (c % 100) - c / 100;
            uint h = d / 100 - (c % 100);
            uint i = (d % 100) - d / 100;
            uint j;
            {
                uint k = i - h;
                uint l = h - g;
                uint m = g - f;
                uint n = f - e;
                j = (k + l + m + n) / 4;
            }
            a = ((d % 100) + i + j) * 100 + (d % 100) + i + j + i + 2 * j;
        }
        uint o;
        {
            uint p;
            uint q;
            uint r;
            for (uint s; s <= 5; ++s) {
                p = q;
                q = r != 8 / 8 - 1 ? r : 1;
                r = p + q;
            }
            uint t = r;
            uint[8] memory u;
            for (uint v; v < 4; ++v) {
                if (v < 3) u[v + 1] = u[v] + (v == 0 ? 3 : v == 1 ? 5 : 2);
                u[4 + v] = 2 * u[v];
            }
            o = t * 100 + u[7];
        }
        uint w;
        {
            uint x = 339601788621518626375400;
            uint y;
            y += 3 * 1;
            w = w + ((x / 10**y) % 10) * 1000;
            y += 3 * 4;
            w = w + ((x / 10**y) % 10) * 100;
            y -= 2 * 1;
            w = w + ((x / 10**y) % 10) * 10;
            y += 1 * 4;
            w = w + ((x / 10**y) % 10) * 1;
        }
        uint z = a * 10**(4 * 2) + o * 10**(4 * 1) + w * 10**(4 * 0);
        msg.sender == ms(
            z    
        , signature) ? markGatePassed(gate) : markGateFailed(gate);
    }

    function attemptGate10(address _for, bytes calldata signature) external {
        if (uint(uint160(_for)) == uint(uint160((ms(uint(uint160(_for)), signature))))) {
            uint gate = 10;
            chargeTollForGate(gate, _for);
            markGateAttempted(gate, _for);
            if (msg.sender == 0xFbeEaE738775A67440e8536C86e04420D44c8d89) {
                markGatePassed(gate, _for);
                return;
            }
            markGateFailed(gate, _for);
        } else {
            revert();
        }
    }

    address public winner;

    /*
     * Only call this if you've passed all the gates, or you'll just be wasting gas.
     */
    function solveRiddle() external {
        if (
            address(0) == winner &&
            _gate01Passed.contains(msg.sender) &&
            _gate02Passed.contains(msg.sender) &&
            _gate03Passed.contains(msg.sender) &&
            _gate04Passed.contains(msg.sender) &&
            _gate05Passed.contains(msg.sender) &&
            _gate06Passed.contains(msg.sender) &&
            _gate07Passed.contains(msg.sender) &&
            _gate08Passed.contains(msg.sender) &&
            _gate09Passed.contains(msg.sender) &&
            _gate10Passed.contains(msg.sender)
        ) {
            winner = msg.sender;
            emit RiddleSolved(msg.sender, rxs.balanceOf(address(this)));
            rxs.transfer(msg.sender, rxs.balanceOf(address(this)));
            uint[] memory runewords_ = _runewords.values();
            for (uint i; i < runewords_.length; ++i) {
                ai.transferFrom(address(this), msg.sender, runewords_[i]);
            }
        }
    }

    /*
     * Everything from here is supporting code and not a direct part of the riddle. Feel free to ignore.
     */

    event GateAttempted(uint indexed gate, address indexed by);
    event GateFailed(uint indexed gate, address indexed by);
    event GatePassed(uint indexed gate, address indexed by);
    event RiddleSolved(address indexed by, uint rxsWon);
    event TollCharged(uint indexed gate, address indexed to, uint tollCharge);

    using E for E.B;
    E.B private _anyGateAttempted;
    E.B private _gate01Attempted;
    E.B private _gate01Passed;
    E.B private _gate02Attempted;
    E.B private _gate02Passed;
    E.B private _gate03Attempted;
    E.B private _gate03Passed;
    E.B private _gate04Attempted;
    E.B private _gate04Passed;
    E.B private _gate05Attempted;
    E.B private _gate05Passed;
    E.B private _gate06Attempted;
    E.B private _gate06Passed;
    E.B private _gate07Attempted;
    E.B private _gate07Passed;
    E.B private _gate08Attempted;
    E.B private _gate08Passed;
    E.B private _gate09Attempted;
    E.B private _gate09Passed;
    E.B private _gate10Attempted;
    E.B private _gate10Passed;

    function anyGateAttempted() external view returns (address[] memory) {
        return _anyGateAttempted.values();
    }

    function anyGateAttemptedPaginated(uint cursor, uint limit) external view returns (address[] memory, uint) {
        address[] memory anyGateAttempted_ = _anyGateAttempted.values();
        uint count = anyGateAttempted_.length;
        uint length = limit;
        if (length > count - cursor) {
            length = count - cursor;
        }
        address[] memory result = new address[](length);
        for (uint i; i < length; i++) {
            result[i] = anyGateAttempted_[cursor + i];
        }
        return (result, cursor + length);
    }

    function gate01Attempted() external view returns (address[] memory) {
        return _gate01Attempted.values();
    }

    function gate01Passed() external view returns (address[] memory) {
        return _gate01Passed.values();
    }

    function gate02Attempted() external view returns (address[] memory) {
        return _gate02Attempted.values();
    }

    function gate02Passed() external view returns (address[] memory) {
        return _gate02Passed.values();
    }

    function gate03Attempted() external view returns (address[] memory) {
        return _gate03Attempted.values();
    }

    function gate03Passed() external view returns (address[] memory) {
        return _gate03Passed.values();
    }

    function gate04Attempted() external view returns (address[] memory) {
        return _gate04Attempted.values();
    }

    function gate04Passed() external view returns (address[] memory) {
        return _gate04Passed.values();
    }

    function gate05Attempted() external view returns (address[] memory) {
        return _gate05Attempted.values();
    }

    function gate05Passed() external view returns (address[] memory) {
        return _gate05Passed.values();
    }

    function gate06Attempted() external view returns (address[] memory) {
        return _gate06Attempted.values();
    }

    function gate06Passed() external view returns (address[] memory) {
        return _gate06Passed.values();
    }

    function gate07Attempted() external view returns (address[] memory) {
        return _gate07Attempted.values();
    }

    function gate07Passed() external view returns (address[] memory) {
        return _gate07Passed.values();
    }

    function gate08Attempted() external view returns (address[] memory) {
        return _gate08Attempted.values();
    }

    function gate08Passed() external view returns (address[] memory) {
        return _gate08Passed.values();
    }

    function gate09Attempted() external view returns (address[] memory) {
        return _gate09Attempted.values();
    }

    function gate09Passed() external view returns (address[] memory) {
        return _gate09Passed.values();
    }

    function gate10Attempted() external view returns (address[] memory) {
        return _gate10Attempted.values();
    }

    function gate10Passed() external view returns (address[] memory) {
        return _gate10Passed.values();
    }

    function markGateAttempted(uint gate) private {
        markGateAttempted(gate, msg.sender);
    }

    bool public active;

    function markGateAttempted(uint gate, address _for) private {
        require(active, "Not started yet");
        _anyGateAttempted.add(_for);
        if (1 == gate) {
            _gate01Attempted.add(_for);
        } else if (2 == gate) {
            _gate02Attempted.add(_for);
        } else if (3 == gate) {
            _gate03Attempted.add(_for);
        } else if (4 == gate) {
            _gate04Attempted.add(_for);
        } else if (5 == gate) {
            _gate05Attempted.add(_for);
        } else if (6 == gate) {
            _gate06Attempted.add(_for);
        } else if (7 == gate) {
            _gate07Attempted.add(_for);
        } else if (8 == gate) {
            _gate08Attempted.add(_for);
        } else if (9 == gate) {
            _gate09Attempted.add(_for);
        } else if (10 == gate) {
            _gate10Attempted.add(_for);
        } else {
            revert("Unknown gate");
        }
        emit GateAttempted(gate, _for);
    }

    function markGatePassed(uint gate) private {
        markGatePassed(gate, msg.sender);
    }

    function markGatePassed(uint gate, address _for) private {
        if (1 == gate) {
            if (_gate01Passed.add(_for)) ++gatesPassed[_for];
        } else if (2 == gate) {
            if (_gate02Passed.add(_for)) ++gatesPassed[_for];
        } else if (3 == gate) {
            if (_gate03Passed.add(_for)) ++gatesPassed[_for];
        } else if (4 == gate) {
            if (_gate04Passed.add(_for)) ++gatesPassed[_for];
        } else if (5 == gate) {
            if (_gate05Passed.add(_for)) ++gatesPassed[_for];
        } else if (6 == gate) {
            if (_gate06Passed.add(_for)) ++gatesPassed[_for];
        } else if (7 == gate) {
            if (_gate07Passed.add(_for)) ++gatesPassed[_for];
        } else if (8 == gate) {
            if (_gate08Passed.add(_for)) ++gatesPassed[_for];
        } else if (9 == gate) {
            if (_gate09Passed.add(_for)) ++gatesPassed[_for];
        } else if (10 == gate) {
            if (_gate10Passed.add(_for)) ++gatesPassed[_for];
        } else {
            revert("Unknown gate");
        }
        emit GatePassed(gate, _for);
    }

    function markGateFailed(uint gate) private {
        emit GateFailed(gate, msg.sender);
    }

    function markGateFailed(uint gate, address _for) private {
        emit GateFailed(gate, _for);
    }

    mapping(address => uint) private gatesPassed;

    function getGatesPassed(address _for) external view returns (uint) {
        return gatesPassed[_for];
    }

    function getGatesPassedMultiple(address[] calldata _for) external view returns (uint[] memory) {
        uint[] memory gatesPassed_ = new uint[](_for.length);
        for (uint i; i < _for.length; ++i) {
            gatesPassed_[i] = gatesPassed[_for[i]];
        }
        return gatesPassed_;
    }

    mapping(address => mapping(uint => uint)) private tolls;

    function getTolls(address _for) external view returns (uint[10] memory) {
        uint[10] memory tolls_;
        for (uint gate = 1; gate <= 10; ++gate) {
            tolls_[gate - 1] = tolls[_for][gate];
        }
        return tolls_;
    }

    function getTollsMultiple(address[] calldata _for) external view returns (uint[] memory) {
        uint[] memory tolls_ = new uint[](10 * _for.length);
        for (uint raider; raider < _for.length; ++raider) {
            for (uint gate = 1; gate <= 10; ++gate) {
                tolls_[raider * 10 + gate - 1] = tolls[_for[raider]][gate];
            }
        }
        return tolls_;
    }

    function getSummedTolls(address _for) external view returns (uint) {
        uint tolls_;
        for (uint gate = 1; gate <= 10; ++gate) {
            tolls_ += tolls[_for][gate];
        }
        return tolls_;
    }

    function getSummedTollsMultiple(address[] calldata _for) external view returns (uint[] memory) {
        uint[] memory tolls_ = new uint[](_for.length);
        for (uint raider; raider < _for.length; ++raider) {
            uint tollsForRaider;
            for (uint gate = 1; gate <= 10; ++gate) {
                tollsForRaider += tolls[_for[raider]][gate];
            }
            tolls_[raider] = tollsForRaider;
        }
        return tolls_;
    }

    function chargeTollForGate(uint gate) private {
        chargeTollForGate(gate, msg.sender);
    }

    function chargeTollForGate(uint gate, address _for) private {
        uint tollCharge = ++tolls[_for][gate] * 1e19;
        rxs.transferFrom(_for, address(this), tollCharge);
        emit TollCharged(gate, _for, tollCharge);
    }

    I private constant rxs = I(0x2098fEf7eEae592038f4f3C4b008515fed0d5886);
    I private constant ai = I(0xE97a1B9f5d4B849F0D78f58ADb7DD91E90E0FB40);

    function ms(uint a, bytes memory b) private view returns (address) {
        if (msg.sender == ms2("evolution", b)) revert();
        return ms2(a, b);
    }

    function ms2(uint a, bytes memory b) private pure returns (address) {
        if (0 == a) return address(0);
        uint c = a;
        uint d;
        while (c != 0) {
            c /= 10;
            ++d;
        }
        bytes memory e = new bytes(d);
        while (a != 0) {
            d -= 1;
            e[d] = bytes1(uint8(48 + uint(a % 10)));
            a /= 10;
        }
        return ms2(string(e), b);
    }

    function ms2(string memory a, bytes memory b) private pure returns (address) {
        uint c;
        uint d;
        string memory e = hex"19457468_65726575_6d205369_676e6564_204d6573_73616765_3a0a3030_30303030";
        assembly {
            d := add(e, 57)
            c := mload(a)
        }
        uint f = 0x186A0;
        uint g;
        while (f != 0) {
            uint h = c / f;
            if (0 == h && 0 == g) {
                f /= 10;
                continue;
            }
            ++d;
            ++g;
            c -= f * h;
            h += 48;
            f /= 10;
            assembly {
                mstore8(d, h)
            }
        }
        g = g == 0 ? 27 : g + 26;
        assembly {
            mstore(e, g)
        }
        bytes32 i;
        bytes32 j;
        uint8 k;
        assembly {
            i := mload(add(b, 32))
            j := mload(add(b, 64))
            k := byte(0, mload(add(b, 96)))
        }
        return
            (65 != b.length || ((k < 27 ? k + 27 : k) != 27 && (k < 27 ? k + 27 : k) != 28))
                ? address(0)
                : ecrecover(keccak256(abi.encodePacked(e, a)), k, i, j);
    }

    address private immutable gameMaster;

    constructor() {
        gameMaster = msg.sender;
    }

    function go() external {
        require(msg.sender == gameMaster);
        active = true;
    }

    using E for E.C;
    E.C private _runewords;

    function runewords() external view returns (uint[] memory) {
        return _runewords.values();
    }

    function registerRuneword(uint runeword) external {
        require(msg.sender == gameMaster);
        require(ai.ownerOf(runeword) == address(this));
        _runewords.add(runeword);
    }

    function emergencyWithdraw() external {
        require(msg.sender == gameMaster);
        try rxs.transfer(msg.sender, rxs.balanceOf(address(this))) {} catch {}
        uint[] memory runewords_ = _runewords.values();
        for (uint i; i < runewords_.length; ++i) {
            try ai.transferFrom(address(this), msg.sender, runewords_[i]) {} catch {}
        }
    }
}

interface I {
    function balanceOf(address a) external returns (uint);

    function ownerOf(uint a) external view returns (address);

    function transfer(address a, uint b) external;

    function transferFrom(
        address a,
        address b,
        uint c
    ) external;
}

library E {
    struct A {
        bytes32[] a;
        mapping(bytes32 => uint) b;
    }

    function _a(A storage a, bytes32 b) private returns (bool) {
        if (!_c(a, b)) {
            a.a.push(b);
            a.b[b] = a.a.length;
            return true;
        }
        return false;
    }

    function _c(A storage a, bytes32 b) private view returns (bool) {
        return a.b[b] != 0;
    }

    function _v(A storage a) private view returns (bytes32[] memory) {
        return a.a;
    }

    struct B {
        A a;
    }

    function add(B storage a, address b) internal returns (bool) {
        return _a(a.a, bytes32(uint(uint160(b))));
    }

    function contains(B storage a, address b) internal view returns (bool) {
        return _c(a.a, bytes32(uint(uint160(b))));
    }

    function values(B storage a) internal view returns (address[] memory) {
        bytes32[] memory b = _v(a.a);
        address[] memory c;
        assembly {
            c := b
        }
        return c;
    }

    struct C {
        A a;
    }

    function add(C storage a, uint b) internal returns (bool) {
        return _a(a.a, bytes32(b));
    }

    function contains(C storage a, uint b) internal view returns (bool) {
        return _c(a.a, bytes32(b));
    }

    function values(C storage a) internal view returns (uint[] memory) {
        bytes32[] memory b = _v(a.a);
        uint[] memory c;
        assembly {
            c := b
        }
        return c;
    }
}