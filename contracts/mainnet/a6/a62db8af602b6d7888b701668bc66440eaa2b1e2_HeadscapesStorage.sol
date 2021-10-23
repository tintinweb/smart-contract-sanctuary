/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract HeadscapesStorage {
    constructor() {}

    function getPalettes(uint256 index) public pure returns (string memory) {
        return
            [
                "b: #281C2D; --s: #695E93; --a: #8155BA; --m: #BEAFC2",
                "b: #738FA7; --s: #0C4160; --a: #C3CEDA; --m: #071330",
                "b: #1A5653; --s: #107869; --a: #5CD85A; --m: #08313A",
                "b: #E95670; --s: #713770; --a: #B34270; --m: #432F70",
                "b: #E1A140; --s: #532200; --a: #EFCFA0; --m: #914110",
                "b: #0B0909; --s: #44444C; --a: #8C8C8C; --m: #D6D6D6",
                "b: #F1D26C; --s: #2B1200; --a: #CF5C00; --m: #8D1E00",
                "b: #8C9B88; --s: #F5E8DA; --a: #735E93; --m: #EFF1EF",
                "b: #676E7F; --s: #0F0D12; --a: #F9F6F0; --m: #B6737C"
            ][index];
    }

    function getPatterns(uint256 index) public pure returns (string memory) {
        return
            [
                'x="-7.25" y="142.5" patternUnits="userSpaceOnUse" width="126" height="200" viewBox="0 0 10 16"><g id="cube"><path fill="var(--a)" d="M0 0l5 3v5l-5 -3z"></path><path d="M10 0l-5 3v5l5 -3"></path></g><use x="5" y="8" href="#cube"></use><use x="-5" y="8" href="#cube"></use>',
                'x="12" y="-5" width="375" height="62.5" patternUnits="userSpaceOnUse"><linearGradient id="g1"><stop offset="5%" stop-color="var(--s)"/><stop offset="50%" stop-color="var(--m)"/><stop offset="95%" stop-color="var(--s)"/></linearGradient><radialGradient id="g2"><stop offset="10%" stop-color="var(--s)"/><stop offset="50%" stop-color="var(--a)"/></radialGradient><rect fill="url(#g1)" height="10" width="375" x="0" y="0"/><g fill-opacity="0.5" stroke="var(--s)" fill="url(#g2)"><circle cx="20" cy="40" r="5" stroke-width="1"/><circle cx="82.5" cy="40" r="7" stroke-width="3" /><circle cx="145" cy="40" r="4" stroke-width="3"/><circle cx="207.5" cy="40" r="8" stroke-width="2"/><circle cx="270" cy="40" r="2" stroke-width="3"/><circle cx="332.5" cy="40" r="3.5" stroke-width="1"/></g>',
                'x="-12.5" y="15.625" width="150" height="62.5" patternUnits="userSpaceOnUse" stroke-width="4"><path d="M0 0 L0 0 25 25 M25 0 L25 0 0 25" stroke="var(--a)"/><path d="M12.5 25 v50" stroke="var(--m)"/><path d="M25 12.5 h45" stroke="var(--m)"/><path d="M87 29.25 v30" stroke="var(--a)"/><circle cx="87" cy="13" r="11.5" fill="transparent" stroke="var(--s)" fill-opacity="0.5"/><path d="M103 12.5 h45" stroke="var(--m)"/>',
                'x="-12.5" y="15.625" width="150" height="62.5" patternUnits="userSpaceOnUse"><linearGradient id="g1" gradientTransform="rotate(90)"><stop offset="5%" stop-color="var(--m)"/><stop offset="95%" stop-color="var(--s)"/></linearGradient><path d="M0 0 v62.5 h150z" stroke="var(--a)" fill="url(#g1)" stroke-width="4"/>',
                'x="0" y="0" width="750" height="250" patternUnits="userSpaceOnUse"><radialGradient id="g1"><stop offset="10%" stop-color="var(--b)"/><stop offset="95%" stop-color="var(--m)"/></radialGradient><circle cx="0" cy="125" r="95" fill="transparent" stroke-width="2" stroke="var(--m)" /><circle cx="0" cy="125" r="45" fill="var(--s)"/><circle cx="750" cy="125" r="75" fill="var(--a)"/><circle cx="375" cy="250" r="80" fill="var(--s)"/><circle cx="375" cy="0" r="30" fill="transparent" stroke-width="2" stroke="var(--a)"/><circle cx="375" cy="250" r="30" fill="transparent" stroke-width="2" stroke="var(--a)"/><circle cx="375" cy="125" r="25" fill="var(--m)"/><circle cx="750" cy="250" r="31" fill="var(--s)"/><circle cx="750" cy="0" r="31" fill="var(--a)"/><circle cx="0" cy="0" r="22" fill="var(--m)"/><circle cx="750" cy="0" r="22" fill="var(--s)"/><circle cx="0" cy="250" r="22" fill="var(--a)"/><circle cx="750" cy="250" r="22" fill="url(#g1)"/>',
                'x="0" y="0" width="750" height="100" patternUnits="userSpaceOnUse" stroke-width="4"><radialGradient cx="10%" cy="10%" id="g1"><stop offset="5%" stop-color="var(--a)"/><stop offset="95%" stop-color="var(--m)"/></radialGradient><radialGradient cx="90%" cy="90%" id="g2"><stop offset="5%" stop-color="var(--m)"/><stop offset="95%" stop-color="var(--a)"/></radialGradient><path d="M0 0 v100 h375 z" stroke="var(--s)" fill="url(#g1)"/><path d="M375 100 h375 V0 z" stroke="var(--s)" fill="url(#g2)"/>',
                'x="0" y="0" width="300" height="125" patternUnits="userSpaceOnUse" stroke-width="4" fill="transparent"><path d="M20 0 Q-30 75, 100 20 T65 120 " stroke="var(--s)" /><path d="M 20 0 C -30 75, 65 10, 100 10 S -180 150, 280 20 S -100 200, -100 200" transform="scale(0.5) translate(200 10) rotate(180 150 75)" stroke="var(--a)" /><path d="M275 100 q-20 -30, -30 -40 t-20 30 t-20 -30 t20 -30" stroke="var(--m)" />',
                'x="-12.5" y="0" width="125" height="125" patternUnits="userSpaceOnUse" stroke-width="4" fill-opacity="0.75"><rect x="25" y="12.5" height="100" width="100" fill="var(--m)"/><rect x="50" y="37.5" height="50" width="50" fill="var(--m)"/><rect x="0" y="0" height="10" width="150" fill="var(--s)"/><rect x="0" y="115" height="10" width="150" fill="var(--s)"/><rect x="0" y="10" height="2.5" width="125" fill="var(--a)"/><rect x="0" y="112.5" height="2.5" width="125" fill="var(--a)"/><rect x="0" y="22.5" height="2.5" width="125" fill="var(--a)"/><rect x="0" y="100" height="2.5" width="125" fill="var(--a)"/><rect x="37.5" y="0" height="125" width="2.5" fill="var(--s)" /><rect x="110" y="0" height="125" width="2.5" fill="var(--s)"/><rect x="0" y="60" height="5" width="375" fill="var(--a)"/><rect x="72.5" y="0" height="375" width="5" fill="var(--a)"/>',
                ""
            ][index];
    }

    function getTurbs(uint256 index) public pure returns (string memory) {
        return
            [
                'type="fractalNoise" baseFrequency="0.0029, .0009" numOctaves="5"',
                'type="fractalNoise" baseFrequency="0.069, .0420" numOctaves="5"',
                'type="fractalNoise" baseFrequency="0.002, .029" numOctaves="50"',
                'type="fractalNoise" baseFrequency=".0420, .069" numOctaves="6.9"',
                'type="turbulence" baseFrequency="0.09, .06" numOctaves="1"',
                'type="fractalNoise" baseFrequency="0.2, .9" numOctaves="50"',
                'type="turbulence" baseFrequency=".00888, .0888" numOctaves="88"',
                'type="turbulence" baseFrequency="2, .029" numOctaves="10"',
                'type="fractalNoise" baseFrequency="0, 0" numOctaves="0"'
            ][index];
    }

    function getBlurs(uint256 index) public pure returns (string memory) {
        return
            ["0.0", "0.0", "0.0", "0.0", "0.04", "0.2", "0.7", "1.7", "7"][index];
    }

    function getGrads(uint256 index) public pure returns (string memory) {
        return
            [
                "var(--b)",
                "linear-gradient(var(--s), var(--b))",
                "radial-gradient(var(--s), var(--b))",
                "repeating-linear-gradient(var(--s), var(--b) 125px)",
                "repeating-radial-gradient(var(--s), var(--b) 1px)",
                "conic-gradient(var(--b), var(--s))",
                "repeating-linear-gradient(0.85turn, transparent, var(--s) 100px),repeating-linear-gradient(0.15turn, transparent, var(--b) 50px),repeating-linear-gradient(0.5turn, transparent, var(--a) 20px),repeating-linear-gradient(transparent, var(--m) 1px)",
                "repeating-conic-gradient(var(--b) 0 9deg, var(--s) 9deg 18deg)",
                "repeating-conic-gradient(from 0deg at 50% 50%, red, orange, yellow, green, blue, indigo, violet)"
            ][index];
    }

    function getLights(uint256 index) public pure returns (string memory) {
        return
            [
                "",
                "",
                "",
                "",
                "",
                'surfaceScale="100"><fePointLight x="750" y="250" z="200"/></feDiffuseLighting>',
                'surfaceScale="6"><feDistantLight azimuth="10" elevation="43"/></feDiffuseLighting>',
                'surfaceScale="10"><fePointLight x="750" y="250" z="200"/></feDiffuseLighting>',
                'surfaceScale="22"><feDistantLight azimuth="5" elevation="40"/></feDiffuseLighting>'
            ][index];
    }

    function getMaps(uint256 index) public pure returns (string memory) {
        return
            [
                'in="SourceGraphic" scale="10" xChannelSelector="A" yChannelSelector="B"',
                'in="SourceGraphic" scale="20" xChannelSelector="R" yChannelSelector="B"',
                'in="SourceGraphic" scale="100" xChannelSelector="B" yChannelSelector="G"',
                'in="SourceGraphic" scale="300" xChannelSelector="A" yChannelSelector="R"',
                'in="FillPaint" scale="600" xChannelSelector="R" yChannelSelector="R"',
                'in="SourceGraphic" scale="1000" xChannelSelector="G" yChannelSelector="R"',
                'in="SourceAlpha" scale="987" xChannelSelector="B" yChannelSelector="A"',
                'in="[redacted]" scale="69" xChannelSelector="A" yChannelSelector="R"',
                'in="[redacted]" scale="420" xChannelSelector="A" yChannelSelector="A"'
            ][index];
    }
}