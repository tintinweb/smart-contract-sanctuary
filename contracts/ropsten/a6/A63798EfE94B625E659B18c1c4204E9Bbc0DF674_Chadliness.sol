// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Chadliness is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    // Mapping from token ID to chadhood
    mapping(uint256 => string) private _proofsOfChadliness;
    bytes internal constant PIXEL_CHAD =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 24 24" shape-rendering="crispEdges"><path stroke="#009688" d="M0 0h1M18 0h2M1 1h2M4 1h1M19 1h1M5 2h1M7 2h1M20 2h2M4 3h1M19 3h1M21 3h2M0 4h1M5 4h1M21 4h1M23 4h1M0 5h2M19 5h1M22 5h1M4 6h1M6 6h1M19 6h2M1 7h1M4 7h2M7 7h1M22 7h1M0 8h1M6 8h1M22 8h1M1 9h1M3 9h1M5 9h1M7 9h1M19 9h1M22 9h1M1 10h1M7 10h1M21 10h1M23 10h1M5 11h1M19 11h1M22 11h1M1 12h2M4 12h2M20 12h1M23 12h1M0 13h1M2 13h2M19 13h1M22 13h1M1 14h1M3 14h1M20 14h2M0 15h1M4 15h1M19 15h1M1 16h1M18 16h1M20 16h1M22 16h1M2 17h3M19 17h1M22 17h1M4 18h2M19 18h1M21 18h1M3 19h1M6 19h2M4 20h1M1 21h1M0 23h1" /><path stroke="#009788" d="M1 0h1M4 0h1M22 0h1M22 1h1M1 2h1M4 2h1M19 2h1M22 2h1M1 3h1M7 3h1M1 4h1M4 4h1M7 4h1M19 4h1M22 4h1M4 5h1M7 5h1M1 6h1M7 6h1M22 6h1M19 7h1M1 8h1M4 8h1M7 8h1M19 8h1M4 9h1M4 10h1M19 10h1M22 10h1M1 11h1M4 11h1M19 12h1M22 12h1M1 13h1M4 13h1M4 14h1M19 14h1M22 14h1M1 15h1M22 15h1M4 16h1M7 16h1M19 16h1M1 17h1M7 17h1M10 17h1M1 18h1M7 18h1M10 18h1M22 18h1M1 19h1M4 19h1M1 20h1" /><path stroke="#009689" d="M2 0h1M5 0h2M21 0h1M23 0h1M0 1h1M20 1h1M23 1h1M0 2h1M0 3h1M2 3h2M5 3h2M20 3h1M23 3h1M3 4h1M2 5h2M23 5h1M5 6h1M2 7h1M20 7h2M5 8h1M0 9h1M6 9h1M21 9h1M23 9h1M6 10h1M0 11h1M2 11h1M23 11h1M21 13h1M2 14h1M2 15h2M23 15h1M0 16h1M5 16h1M6 17h1M2 18h2M6 18h1M9 18h1M18 18h1M20 18h1M0 21h1M0 22h1" /><path stroke="#019689" d="M3 0h1M6 1h1M2 2h2M8 2h1M2 4h1M6 5h1M20 5h1M0 6h1M23 6h1M0 7h1M2 8h2M20 8h2M2 10h1M20 10h1M3 11h1M21 11h1M5 13h1M0 14h1M5 14h1M21 15h1M2 16h1M6 16h1M5 17h1M20 17h1M23 17h1M23 18h1M0 19h1M2 20h1M5 20h1" /><path stroke="#000000" d="M7 0h2M16 0h2M7 1h4M15 1h1M18 6h1M18 8h1M8 9h1M10 9h1M13 9h1M18 9h1M9 10h1M11 10h1M16 10h1M16 11h1M6 12h2M13 12h1M15 12h2M16 13h2M7 14h3M13 14h1M15 14h1M18 14h1M6 15h2M11 15h1M16 15h2M10 16h1M14 16h1M11 22h1" /><path stroke="#010000" d="M9 0h1M15 0h1M12 1h1M14 1h1M18 5h1M18 7h1M11 9h1M17 9h1M14 10h1M17 10h2M15 11h1M18 11h1M9 12h1M14 12h1M17 12h2M11 13h1M6 14h1M8 15h2M15 15h1M9 16h1M12 16h1M12 21h1M12 22h1" /><path stroke="#000100" d="M10 0h1M13 0h1M13 1h1M16 1h1M16 2h1M16 3h1M16 9h1M7 11h1M7 13h1M10 13h1M13 13h1M10 14h1M16 14h1M10 15h1M13 15h1M13 16h1M16 16h1" /><path stroke="#010001" d="M11 0h1M17 1h1M15 2h1M17 2h2M17 3h1M18 4h1M17 8h1M12 10h2M15 10h1M8 11h1M9 13h1M12 13h1M14 13h2M18 13h1M11 14h2M14 14h1M17 14h1M8 16h1M11 16h1M17 16h1" /><path stroke="#000001" d="M12 0h1M14 0h1M11 1h1M14 2h1M18 3h1M17 7h1M9 9h1M12 9h1M8 10h1M17 11h1M8 12h1M6 13h1M8 13h1M12 15h1M14 15h1M18 15h1M15 16h1M11 23h1" /><path stroke="#019688" d="M20 0h1M3 1h1M5 1h1M18 1h1M21 1h1M6 2h1M23 2h1M8 3h1M6 4h1M20 4h1M5 5h1M21 5h1M2 6h2M21 6h1M3 7h1M6 7h1M23 7h1M23 8h1M2 9h1M20 9h1M0 10h1M3 10h1M5 10h1M6 11h1M20 11h1M0 12h1M3 12h1M21 12h1M20 13h1M23 13h1M23 14h1M5 15h1M20 15h1M3 16h1M21 16h1M23 16h1M0 17h1M8 17h2M18 17h1M21 17h1M0 18h1M8 18h1M2 19h1M5 19h1M0 20h1M3 20h1" /><path stroke="#80d8ff" d="M9 2h2M12 3h2M15 3h1M11 4h1M8 5h1M11 5h3M17 5h1M9 6h1M11 6h1M13 6h1M15 6h3M10 7h2M16 7h1M8 8h1M13 8h2M12 17h1M15 17h1M14 18h2M9 19h1M15 19h1M6 20h1M11 20h1M14 20h1M17 20h1M8 21h2M11 21h1M15 21h1M18 21h1M20 21h1M23 21h1M14 22h2M23 22h1M12 23h1M15 23h1M20 23h1" /><path stroke="#80d8fe" d="M11 2h1M11 3h1M14 5h1M14 9h1M8 19h1M12 19h1M21 19h1M23 19h1M18 20h1M23 20h1M3 21h1M21 21h1M2 22h2M6 22h1M8 22h1M17 22h1M5 23h2M8 23h2M21 23h1" /><path stroke="#81d8ff" d="M12 2h1M9 3h1M14 3h1M12 4h1M14 4h1M17 4h1M12 6h1M14 6h1M8 7h2M14 7h1M15 8h1M15 9h1M13 17h2M16 17h1M11 18h1M17 18h1M11 19h1M14 19h1M16 19h1M18 19h1M7 20h4M13 20h1M19 20h3M7 21h1M10 21h1M13 21h1M19 21h1M5 22h1M7 22h1M9 22h1M20 22h1M2 23h1M13 23h1M17 23h1M22 23h1" /><path stroke="#80d9ff" d="M13 2h1M10 3h1M13 4h1M10 6h1M13 7h1M10 8h1M16 8h1" /><path stroke="#81d8fe" d="M8 4h1M8 6h1M15 7h1M9 8h1M11 17h1M17 17h1M12 18h1M17 19h1M20 19h1M12 20h1M15 20h1M2 21h1M5 21h2M14 21h1M17 21h1M18 22h1M21 22h1M3 23h1M14 23h1M18 23h1M23 23h1" /><path stroke="#02a9f4" d="M9 4h1M15 4h1" /><path stroke="#03a8f4" d="M10 4h1" /><path stroke="#03a9f4" d="M16 4h1" /><path stroke="#0c47a1" d="M9 5h1" /><path stroke="#82b1ff" d="M10 5h1M11 8h2" /><path stroke="#0d47a0" d="M15 5h1" /><path stroke="#82b0ff" d="M16 5h1" /><path stroke="#82b1fe" d="M12 7h1" /><path stroke="#010101" d="M10 10h1" /><path stroke="#fefffe" d="M9 11h1" /><path stroke="#fffeff" d="M10 11h1M13 11h1M10 12h1" /><path stroke="#feffff" d="M11 11h2M14 11h1M11 12h2" /><path stroke="#81d9ff" d="M13 18h1M16 18h1M10 19h1M13 19h1M19 19h1M22 19h1M16 20h1M22 20h1M4 21h1M16 21h1M22 21h1M1 22h1M4 22h1M10 22h1M13 22h1M16 22h1M19 22h1M22 22h1M1 23h1M4 23h1M7 23h1M10 23h1M16 23h1M19 23h1" /></svg>';
    bytes internal constant BASE64_PIXEL_CHAD =
        "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgLTAuNSAyNCAyNCIgc2hhcGUtcmVuZGVyaW5nPSJjcmlzcEVkZ2VzIj48bWV0YWRhdGE+TWFkZSB3aXRoIFBpeGVscyB0byBTdmcgaHR0cHM6Ly9jb2RlcGVuLmlvL3Noc2hhdy9wZW4vWGJ4dk5qPC9tZXRhZGF0YT48cGF0aCBzdHJva2U9IiMwMDk2ODgiIGQ9Ik0wIDBoMU0xOCAwaDJNMSAxaDJNNCAxaDFNMTkgMWgxTTUgMmgxTTcgMmgxTTIwIDJoMk00IDNoMU0xOSAzaDFNMjEgM2gyTTAgNGgxTTUgNGgxTTIxIDRoMU0yMyA0aDFNMCA1aDJNMTkgNWgxTTIyIDVoMU00IDZoMU02IDZoMU0xOSA2aDJNMSA3aDFNNCA3aDJNNyA3aDFNMjIgN2gxTTAgOGgxTTYgOGgxTTIyIDhoMU0xIDloMU0zIDloMU01IDloMU03IDloMU0xOSA5aDFNMjIgOWgxTTEgMTBoMU03IDEwaDFNMjEgMTBoMU0yMyAxMGgxTTUgMTFoMU0xOSAxMWgxTTIyIDExaDFNMSAxMmgyTTQgMTJoMk0yMCAxMmgxTTIzIDEyaDFNMCAxM2gxTTIgMTNoMk0xOSAxM2gxTTIyIDEzaDFNMSAxNGgxTTMgMTRoMU0yMCAxNGgyTTAgMTVoMU00IDE1aDFNMTkgMTVoMU0xIDE2aDFNMTggMTZoMU0yMCAxNmgxTTIyIDE2aDFNMiAxN2gzTTE5IDE3aDFNMjIgMTdoMU00IDE4aDJNMTkgMThoMU0yMSAxOGgxTTMgMTloMU02IDE5aDJNNCAyMGgxTTEgMjFoMU0wIDIzaDEiIC8+PHBhdGggc3Ryb2tlPSIjMDA5Nzg4IiBkPSJNMSAwaDFNNCAwaDFNMjIgMGgxTTIyIDFoMU0xIDJoMU00IDJoMU0xOSAyaDFNMjIgMmgxTTEgM2gxTTcgM2gxTTEgNGgxTTQgNGgxTTcgNGgxTTE5IDRoMU0yMiA0aDFNNCA1aDFNNyA1aDFNMSA2aDFNNyA2aDFNMjIgNmgxTTE5IDdoMU0xIDhoMU00IDhoMU03IDhoMU0xOSA4aDFNNCA5aDFNNCAxMGgxTTE5IDEwaDFNMjIgMTBoMU0xIDExaDFNNCAxMWgxTTE5IDEyaDFNMjIgMTJoMU0xIDEzaDFNNCAxM2gxTTQgMTRoMU0xOSAxNGgxTTIyIDE0aDFNMSAxNWgxTTIyIDE1aDFNNCAxNmgxTTcgMTZoMU0xOSAxNmgxTTEgMTdoMU03IDE3aDFNMTAgMTdoMU0xIDE4aDFNNyAxOGgxTTEwIDE4aDFNMjIgMThoMU0xIDE5aDFNNCAxOWgxTTEgMjBoMSIgLz48cGF0aCBzdHJva2U9IiMwMDk2ODkiIGQ9Ik0yIDBoMU01IDBoMk0yMSAwaDFNMjMgMGgxTTAgMWgxTTIwIDFoMU0yMyAxaDFNMCAyaDFNMCAzaDFNMiAzaDJNNSAzaDJNMjAgM2gxTTIzIDNoMU0zIDRoMU0yIDVoMk0yMyA1aDFNNSA2aDFNMiA3aDFNMjAgN2gyTTUgOGgxTTAgOWgxTTYgOWgxTTIxIDloMU0yMyA5aDFNNiAxMGgxTTAgMTFoMU0yIDExaDFNMjMgMTFoMU0yMSAxM2gxTTIgMTRoMU0yIDE1aDJNMjMgMTVoMU0wIDE2aDFNNSAxNmgxTTYgMTdoMU0yIDE4aDJNNiAxOGgxTTkgMThoMU0xOCAxOGgxTTIwIDE4aDFNMCAyMWgxTTAgMjJoMSIgLz48cGF0aCBzdHJva2U9IiMwMTk2ODkiIGQ9Ik0zIDBoMU02IDFoMU0yIDJoMk04IDJoMU0yIDRoMU02IDVoMU0yMCA1aDFNMCA2aDFNMjMgNmgxTTAgN2gxTTIgOGgyTTIwIDhoMk0yIDEwaDFNMjAgMTBoMU0zIDExaDFNMjEgMTFoMU01IDEzaDFNMCAxNGgxTTUgMTRoMU0yMSAxNWgxTTIgMTZoMU02IDE2aDFNNSAxN2gxTTIwIDE3aDFNMjMgMTdoMU0yMyAxOGgxTTAgMTloMU0yIDIwaDFNNSAyMGgxIiAvPjxwYXRoIHN0cm9rZT0iIzAwMDAwMCIgZD0iTTcgMGgyTTE2IDBoMk03IDFoNE0xNSAxaDFNMTggNmgxTTE4IDhoMU04IDloMU0xMCA5aDFNMTMgOWgxTTE4IDloMU05IDEwaDFNMTEgMTBoMU0xNiAxMGgxTTE2IDExaDFNNiAxMmgyTTEzIDEyaDFNMTUgMTJoMk0xNiAxM2gyTTcgMTRoM00xMyAxNGgxTTE1IDE0aDFNMTggMTRoMU02IDE1aDJNMTEgMTVoMU0xNiAxNWgyTTEwIDE2aDFNMTQgMTZoMU0xMSAyMmgxIiAvPjxwYXRoIHN0cm9rZT0iIzAxMDAwMCIgZD0iTTkgMGgxTTE1IDBoMU0xMiAxaDFNMTQgMWgxTTE4IDVoMU0xOCA3aDFNMTEgOWgxTTE3IDloMU0xNCAxMGgxTTE3IDEwaDJNMTUgMTFoMU0xOCAxMWgxTTkgMTJoMU0xNCAxMmgxTTE3IDEyaDJNMTEgMTNoMU02IDE0aDFNOCAxNWgyTTE1IDE1aDFNOSAxNmgxTTEyIDE2aDFNMTIgMjFoMU0xMiAyMmgxIiAvPjxwYXRoIHN0cm9rZT0iIzAwMDEwMCIgZD0iTTEwIDBoMU0xMyAwaDFNMTMgMWgxTTE2IDFoMU0xNiAyaDFNMTYgM2gxTTE2IDloMU03IDExaDFNNyAxM2gxTTEwIDEzaDFNMTMgMTNoMU0xMCAxNGgxTTE2IDE0aDFNMTAgMTVoMU0xMyAxNWgxTTEzIDE2aDFNMTYgMTZoMSIgLz48cGF0aCBzdHJva2U9IiMwMTAwMDEiIGQ9Ik0xMSAwaDFNMTcgMWgxTTE1IDJoMU0xNyAyaDJNMTcgM2gxTTE4IDRoMU0xNyA4aDFNMTIgMTBoMk0xNSAxMGgxTTggMTFoMU05IDEzaDFNMTIgMTNoMU0xNCAxM2gyTTE4IDEzaDFNMTEgMTRoMk0xNCAxNGgxTTE3IDE0aDFNOCAxNmgxTTExIDE2aDFNMTcgMTZoMSIgLz48cGF0aCBzdHJva2U9IiMwMDAwMDEiIGQ9Ik0xMiAwaDFNMTQgMGgxTTExIDFoMU0xNCAyaDFNMTggM2gxTTE3IDdoMU05IDloMU0xMiA5aDFNOCAxMGgxTTE3IDExaDFNOCAxMmgxTTYgMTNoMU04IDEzaDFNMTIgMTVoMU0xNCAxNWgxTTE4IDE1aDFNMTUgMTZoMU0xMSAyM2gxIiAvPjxwYXRoIHN0cm9rZT0iIzAxOTY4OCIgZD0iTTIwIDBoMU0zIDFoMU01IDFoMU0xOCAxaDFNMjEgMWgxTTYgMmgxTTIzIDJoMU04IDNoMU02IDRoMU0yMCA0aDFNNSA1aDFNMjEgNWgxTTIgNmgyTTIxIDZoMU0zIDdoMU02IDdoMU0yMyA3aDFNMjMgOGgxTTIgOWgxTTIwIDloMU0wIDEwaDFNMyAxMGgxTTUgMTBoMU02IDExaDFNMjAgMTFoMU0wIDEyaDFNMyAxMmgxTTIxIDEyaDFNMjAgMTNoMU0yMyAxM2gxTTIzIDE0aDFNNSAxNWgxTTIwIDE1aDFNMyAxNmgxTTIxIDE2aDFNMjMgMTZoMU0wIDE3aDFNOCAxN2gyTTE4IDE3aDFNMjEgMTdoMU0wIDE4aDFNOCAxOGgxTTIgMTloMU01IDE5aDFNMCAyMGgxTTMgMjBoMSIgLz48cGF0aCBzdHJva2U9IiM4MGQ4ZmYiIGQ9Ik05IDJoMk0xMiAzaDJNMTUgM2gxTTExIDRoMU04IDVoMU0xMSA1aDNNMTcgNWgxTTkgNmgxTTExIDZoMU0xMyA2aDFNMTUgNmgzTTEwIDdoMk0xNiA3aDFNOCA4aDFNMTMgOGgyTTEyIDE3aDFNMTUgMTdoMU0xNCAxOGgyTTkgMTloMU0xNSAxOWgxTTYgMjBoMU0xMSAyMGgxTTE0IDIwaDFNMTcgMjBoMU04IDIxaDJNMTEgMjFoMU0xNSAyMWgxTTE4IDIxaDFNMjAgMjFoMU0yMyAyMWgxTTE0IDIyaDJNMjMgMjJoMU0xMiAyM2gxTTE1IDIzaDFNMjAgMjNoMSIgLz48cGF0aCBzdHJva2U9IiM4MGQ4ZmUiIGQ9Ik0xMSAyaDFNMTEgM2gxTTE0IDVoMU0xNCA5aDFNOCAxOWgxTTEyIDE5aDFNMjEgMTloMU0yMyAxOWgxTTE4IDIwaDFNMjMgMjBoMU0zIDIxaDFNMjEgMjFoMU0yIDIyaDJNNiAyMmgxTTggMjJoMU0xNyAyMmgxTTUgMjNoMk04IDIzaDJNMjEgMjNoMSIgLz48cGF0aCBzdHJva2U9IiM4MWQ4ZmYiIGQ9Ik0xMiAyaDFNOSAzaDFNMTQgM2gxTTEyIDRoMU0xNCA0aDFNMTcgNGgxTTEyIDZoMU0xNCA2aDFNOCA3aDJNMTQgN2gxTTE1IDhoMU0xNSA5aDFNMTMgMTdoMk0xNiAxN2gxTTExIDE4aDFNMTcgMThoMU0xMSAxOWgxTTE0IDE5aDFNMTYgMTloMU0xOCAxOWgxTTcgMjBoNE0xMyAyMGgxTTE5IDIwaDNNNyAyMWgxTTEwIDIxaDFNMTMgMjFoMU0xOSAyMWgxTTUgMjJoMU03IDIyaDFNOSAyMmgxTTIwIDIyaDFNMiAyM2gxTTEzIDIzaDFNMTcgMjNoMU0yMiAyM2gxIiAvPjxwYXRoIHN0cm9rZT0iIzgwZDlmZiIgZD0iTTEzIDJoMU0xMCAzaDFNMTMgNGgxTTEwIDZoMU0xMyA3aDFNMTAgOGgxTTE2IDhoMSIgLz48cGF0aCBzdHJva2U9IiM4MWQ4ZmUiIGQ9Ik04IDRoMU04IDZoMU0xNSA3aDFNOSA4aDFNMTEgMTdoMU0xNyAxN2gxTTEyIDE4aDFNMTcgMTloMU0yMCAxOWgxTTEyIDIwaDFNMTUgMjBoMU0yIDIxaDFNNSAyMWgyTTE0IDIxaDFNMTcgMjFoMU0xOCAyMmgxTTIxIDIyaDFNMyAyM2gxTTE0IDIzaDFNMTggMjNoMU0yMyAyM2gxIiAvPjxwYXRoIHN0cm9rZT0iIzAyYTlmNCIgZD0iTTkgNGgxTTE1IDRoMSIgLz48cGF0aCBzdHJva2U9IiMwM2E4ZjQiIGQ9Ik0xMCA0aDEiIC8+PHBhdGggc3Ryb2tlPSIjMDNhOWY0IiBkPSJNMTYgNGgxIiAvPjxwYXRoIHN0cm9rZT0iIzBjNDdhMSIgZD0iTTkgNWgxIiAvPjxwYXRoIHN0cm9rZT0iIzgyYjFmZiIgZD0iTTEwIDVoMU0xMSA4aDIiIC8+PHBhdGggc3Ryb2tlPSIjMGQ0N2EwIiBkPSJNMTUgNWgxIiAvPjxwYXRoIHN0cm9rZT0iIzgyYjBmZiIgZD0iTTE2IDVoMSIgLz48cGF0aCBzdHJva2U9IiM4MmIxZmUiIGQ9Ik0xMiA3aDEiIC8+PHBhdGggc3Ryb2tlPSIjMDEwMTAxIiBkPSJNMTAgMTBoMSIgLz48cGF0aCBzdHJva2U9IiNmZWZmZmUiIGQ9Ik05IDExaDEiIC8+PHBhdGggc3Ryb2tlPSIjZmZmZWZmIiBkPSJNMTAgMTFoMU0xMyAxMWgxTTEwIDEyaDEiIC8+PHBhdGggc3Ryb2tlPSIjZmVmZmZmIiBkPSJNMTEgMTFoMk0xNCAxMWgxTTExIDEyaDIiIC8+PHBhdGggc3Ryb2tlPSIjODFkOWZmIiBkPSJNMTMgMThoMU0xNiAxOGgxTTEwIDE5aDFNMTMgMTloMU0xOSAxOWgxTTIyIDE5aDFNMTYgMjBoMU0yMiAyMGgxTTQgMjFoMU0xNiAyMWgxTTIyIDIxaDFNMSAyMmgxTTQgMjJoMU0xMCAyMmgxTTEzIDIyaDFNMTYgMjJoMU0xOSAyMmgxTTIyIDIyaDFNMSAyM2gxTTQgMjNoMU03IDIzaDFNMTAgMjNoMU0xNiAyM2gxTTE5IDIzaDEiIC8+PC9zdmc+";

    constructor()
        ERC721("Why yes, I did return the COMP. How could you tell ? ", "AGC")
    {}

    function mint(address receiver, string memory proofOfChadliness)
        external
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _proofsOfChadliness[newItemId] = proofOfChadliness;

        return newItemId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    "data:text/plain,",
                    string(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "proofOfChadliness":"',
                            _proofsOfChadliness[tokenId],
                            '", "image":"data:image/svg+xml:base64,',
                            BASE64_PIXEL_CHAD,
                            '"}'
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

