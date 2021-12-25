// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./ERC721.sol";
import "./MerkleProof.sol";

contract Coal is ERC721 {
    error InvalidClaim();
    error NonExistentToken();
    error NotSanta();

    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private claimed;

    bytes32 internal list;

    /// @notice Santa is one and only
    address internal santa = msg.sender;
    modifier onlySanta() {
        if (msg.sender != santa)
            revert NotSanta();
        _;
    }

    /// @dev emitted when coal is given out
    event Gifted(
        address indexed to,
        string indexed tokenURI,
        uint256 indexed index
    );

    constructor() ERC721("Coal", "COAL") {}

    function set(bytes32 root) external onlySanta {
        list = root;
    }

    function check(bytes32[] calldata proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        (bool valid,) = MerkleProof.verify(proof, list, leaf);
        return valid;
    }
    function naughty(bytes32[] calldata proof) external view returns (bool) {
        return check(proof);
    }

    function nice(bytes32[] calldata proof) external view returns (bool) {
        return !check(proof);
    }

    uint16 public supply = 0;
    function publicMint() external {
        supply++;
        _safeMint(msg.sender, supply);
    }

    function gift(address receiver, bytes32[] calldata proof) external onlySanta {
        bytes32 leaf = keccak256(abi.encodePacked(receiver));
        (bool valid, uint256 index) = MerkleProof.verify(proof, list, leaf);
        if (!valid || claimed.get(index)) revert InvalidClaim();

        claimed.set(index);

        _safeMint(receiver, index);

        emit Gifted(
            receiver,
            tokenURI(index),
            index
        );
    }
    
    /// @dev you can always burn coal but should you?
    function burn (uint256 tokenId) external {
        _burn(tokenId);
    }

    /// @dev releases the balance of the contract to the owner
    function release() external onlySanta {
        payable(santa).transfer(address(this).balance);
    }

    function random(
        uint256 min,
        uint256 max,
        uint256 index
    ) internal view  returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.difficulty,
                    block.timestamp,
                    index
                )
            )
        );

        return min + (seed % (max - min + 1));
    }

    function christmasMagic(uint256 index) internal view returns (bytes memory) {

        bytes[3] memory coals = [
           bytes("VFRJd01DQXlNREF1TVdFdU1EazNMakE1TnlBd0lEQWdNUzB1TURNNExTNHdNakl1TURrM0xqQTVOeUF3SURBZ01TMHVNREl5TFM0d016aHNMVFU1TGpneExURTBOQzR6WVM0eE1ERXVNVEF4SURBZ01DQXhMUzR3TVRFdExqQTBOUzR4TGpFZ01DQXdJREVnTGpBeE1TMHVNRFExTGpFeUxqRXlJREFnTUNBeElDNHdOeUF3YkRnMkxqVTRMVEUwTGpReklEa3lMamcxSURnMkxqWXhZUzR4TVM0eE1TQXdJREFnTVNBd0lDNHdPQzR4TURNdU1UQXpJREFnTUNBeExTNHdOUzR3T0d3dE1URTVMalV6SURjeUxqRklNakF3ZGk0d01Wb2lJR1pwYkd3OUlpTXpNak16TXpVaUx6NDhjR0YwYUNCa1BTSk5NVFF3TGpJeUlEVTFMamNnTWpBd0lESXdNR3d4TVRrdU5UWXROekl1TVRVdE9USXVOell0T0RZdU5UZ3RPRFl1TlRnZ01UUXVORE5hSWlCbWFXeHNQU0lqTXpJek16TTFJaTgrUEhCaGRHZ2daRDBpVFRFMU5DNDJOU0F5T0RrdU5ETm9MUzR3Tmt3ME1TNHlNU0F5TURBdU1EaGhMakV4TGpFeElEQWdNQ0F4SURBdExqRTBiRGs0TGpreUxURTBOQzR5T1dFdU1USXVNVElnTUNBd0lERWdMakE1SURBZ0xqQTRPQzR3T0RnZ01DQXdJREVnTGpBME9TNHdNVGhqTGpBeE5DNHdNUzR3TWpVdU1ESTFMakF6TVM0d05ESk1NakF3TGpBNUlESXdNR3d0TkRVdU16VWdPRGt1TkRGaExqRXpMakV6SURBZ01DQXhMUzR3Tnk0d05td3RMakF5TFM0d05Gb2lJR1pwYkd3OUlpTTBRVFJHTlRJaUx6NDhjR0YwYUNCa1BTSnRNakF3SURJd01DMDBOUzR6TlNBNE9TNHpNMHcwTVM0eU55QXlNREJzT1RndU9UVXRNVFEwTGpOTU1qQXdJREl3TUZvaUlHWnBiR3c5SWlNMFFUUkdOVElpTHo0OGNHRjBhQ0JrUFNKTk9UUXVPRFFnTXpNMExqQTVZUzR4TXpFdU1UTXhJREFnTUNBeExTNHdOeTB1TURaTU5ERXVNVGdnTWpBd1lTNHhNVEV1TVRFeElEQWdNQ0F4SURBdExqRXlhQzR4TW13eE1UTXVNemdnT0RrdU16TmhMakE1TGpBNUlEQWdNQ0F4SUM0d01qa3VNRE0xTGpFdU1TQXdJREFnTVMwdU1ESTVMakV5Tld3dE5Ua3VOelVnTkRRdU4yZ3RMakEyYkMwdU1ETXVNREphSWlCbWFXeHNQU0lqTWpJeU56SkJJaTgrUEhCaGRHZ2daRDBpYlRrMExqZzNJRE16TXk0NU9TQTFPUzQzT0MwME5DNDJOa3cwTVM0eU55QXlNREJzTlRNdU5pQXhNek11T1RsYUlpQm1hV3hzUFNJak1qSXlOekpCSWk4K1BIQmhkR2dnWkQwaVRUSTVPU0F6TlRndU9ETmhMakV4TWk0eE1USWdNQ0F3SURFdExqQTVMUzR3Tld3dE9UZ3VPVGt0TVRVNExqY3pZUzR3T0RrdU1EZzVJREFnTUNBeExTNHdNVFV0TGpBMVl6QXRMakF4T0M0d01EVXRMakF6TlM0d01UVXRMakExWVM0eE1UUXVNVEUwSURBZ01DQXhJQzR3TkRVdExqQXhZeTR3TVRVZ01DQXVNRE14TGpBd05DNHdORFV1TURGSU1qZzRZUzR3T1RJdU1Ea3lJREFnTUNBeElDNHdPVEl1TURVekxqQTVOUzR3T1RVZ01DQXdJREVnTGpBd09DNHdNemRzTVRFZ01UVTRMamN6WVM0d09UZ3VNRGs0SURBZ01DQXhMUzR3TVRndU1EWXlMakV3TkM0eE1EUWdNQ0F3SURFdExqQTFNaTR3TXpoc0xTNHdNeTB1TURSYUlpQm1hV3hzUFNJak5UYzJNalkySWk4K1BIQmhkR2dnWkQwaWJUSTVPQzQ1TlNBek5UZ3VOek10TVRFdE1UVTRMamN6U0RJd01HdzVPQzQ1TlNBeE5UZ3VOek5hSWlCbWFXeHNQU0lqTlRjMk1qWTJJaTgrUEhCaGRHZ2daRDBpVFRJNU9TQXpOVGd1T0ROb0xTNHdOV0V1TURnMUxqQTROU0F3SURBZ01TMHVNREE0TFM0d016VmpNQzB1TURFeUxqQXdNeTB1TURJMExqQXdPQzB1TURNMVRESTROeTQ0TlNBeU1EQnNNekV1TmpJdE56SXVNbUV1TURrMUxqQTVOU0F3SURBZ01TQXVNRE0yTFM0d05ETXVNRGsyTGpBNU5pQXdJREFnTVNBdU1EVTBMUzR3TVRjdU1UQTFMakV3TlNBd0lEQWdNU0F1TURVM0xqQXlOeTR4TURrdU1UQTVJREFnTUNBeElDNHdNek11TURVell6RXVOaUE0TGpFMElETTVMakUzSURFNU9TNHpJRE01TGpFM0lESXdNUzR6TlNBd0lESXVNRFV0TlRNdU56RWdNall1T0RNdE5Ua3VPRElnTWprdU5qVjJMakF4V2lJZ1ptbHNiRDBpSXpSQk5FWTFNaUl2UGp4d1lYUm9JR1E5SWsweU9Ua2dNelU0TGpjemN6VTVMamM0TFRJM0xqUTVJRFU1TGpjNExUSTVMalUxWXpBdE1pNHdOaTB6T1M0eE55MHlNREV1TXpNdE16a3VNVGN0TWpBeExqTXpUREk0T0NBeU1EQnNNVEVnTVRVNExqY3pXaUlnWm1sc2JEMGlJelJCTkVZMU1pSXZQanh3WVhSb0lHUTlJazB5TURBZ01qQXdMakZoTGpFek1TNHhNekVnTUNBd0lERXRMakEyTFM0d01qRXVNVEk0TGpFeU9DQXdJREFnTVMwdU1EUXRMakEwT1M0eE1EZ3VNVEE0SURBZ01DQXhJREF0TGpFeWJERXhPUzQxTmkwM01pNHhOV2d1TURWaExqQTROQzR3T0RRZ01DQXdJREVnTGpBek5TMHVNREEzWXk0d01USWdNQ0F1TURJMExqQXdNaTR3TXpVdU1EQTNZUzR3T1RJdU1Ea3lJREFnTUNBeElDNHdNVGt1TURVMVl6QWdMakF5TFM0d01EY3VNRE01TFM0d01Ua3VNRFUxVERJNE9DNHdOU0F5TURCaExqRXdPUzR4TURrZ01DQXdJREV0TGpFdU1EWnNMVGczTGprMUxqQTBXaUlnWm1sc2JEMGlJek13TTBFelF5SXZQanh3WVhSb0lHUTlJbTB5T0RjdU9UVWdNakF3SURNeExqWXhMVGN5TGpFMVRESXdNQ0F5TURCb09EY3VPVFZhSWlCbWFXeHNQU0lqTXpBelFUTkRJaTgrUEhCaGRHZ2daRDBpVFRrMExqZzJJRE16TkM0d09XRXVNRGcyTGpBNE5pQXdJREFnTVMwdU1EVTRMUzR3TVRrdU1Ea3hMakE1TVNBd0lEQWdNUzB1TURNeUxTNHdOVEV1TURrNUxqQTVPU0F3SURBZ01TQXdMUzR4TVd3MU9TNDNPQzAwTkM0Mk5rd3hPVGt1T1RFZ01qQXdZUzR4TVRndU1URTRJREFnTUNBeElDNHdORFV0TGpBeFl5NHdNVFlnTUNBdU1ETXhMakF3TkM0d05EVXVNREZoTGpFeE55NHhNVGNnTUNBd0lERWdMakE1SURCTU1qazVJRE0xT0M0Mk9HTXVNREV1TURFMUxqQXhOUzR3TXpJdU1ERTFMakExWVM0d09Ea3VNRGc1SURBZ01DQXhMUzR3TVRVdU1EVXVNVEF6TGpFd015QXdJREFnTVMwdU1EZ3VNRFZNT1RRdU9EWWdNek0wTGpBNVdpSWdabWxzYkQwaUl6TkNNME16UlNJdlBqeHdZWFJvSUdROUltMDVOQzQ0TnlBek16TXVPVGtnTlRrdU56Z3RORFF1TmpaTU1qQXdJREl3TUd3NU9DNDVOU0F4TlRndU56TXRNakEwTGpBNExUSTBMamMwV2lJZ1ptbHNiRDBpSXpOQ00wTXpSU0l2UGp3dmMzWm5QZz09"),
           bytes("YlRJME1TNDNNeUF4TlRBdU5qTXROalV1TkRZdE56SXVNMkV1TURreExqQTVNU0F3SURBZ01TMHVNREU1TFM0d05UVmpNQzB1TURJdU1EQTNMUzR3TkM0d01Ua3RMakExTldFdU1URXhMakV4TVNBd0lEQWdNU0F1TURrdExqQTJhRGcyTGpnNVlTNHhNUzR4TVNBd0lEQWdNU0F1TURZMUxqQXlPQzR4TURrdU1UQTVJREFnTUNBeElDNHdNelV1TURZeWJERXpMamMzSURjeUxqSTJZeTR3TURVdU1ETXVNREExTGpBMklEQWdMakE1WVM0eE1TNHhNU0F3SURBZ01TMHVNRGdnTUd3dE16VXVNekV1TUROYUlpQm1hV3hzUFNJak5FRTBSalV5SWk4K1BIQmhkR2dnWkQwaWJURTNOaTR6TkNBM09DNHlOeUEyTlM0ek9TQTNNaTR5TmtneU56ZHNMVEV6TGpjM0xUY3lMakkyYUMwNE5pNDRPVm9pSUdacGJHdzlJaU0wUVRSR05USWlMejQ4Y0dGMGFDQmtQU0pOTXpVNExqY3pJREl5T0M0d05tRXVNRGcwTGpBNE5DQXdJREFnTVMwdU1ETTFMakF3Tnk0d09EUXVNRGcwSURBZ01DQXhMUzR3TXpVdExqQXdOMnd0T0RFdU56TXROemN1TkRZdE1UTXVPQzAzTWk0ek1tTXdMUzR3TWpNdU1EQTJMUzR3TkRZdU1ERTVMUzR3TmpWaExqRXhOaTR4TVRZZ01DQXdJREVnTGpBMU1TMHVNRFExTGpFd09DNHhNRGdnTUNBd0lERWdMakE1SURCc09UVXVORGtnTVRRNUxqZGhMakV3TWk0eE1ESWdNQ0F3SURFZ0xqQXlOQzR3TmpVdU1UQXlMakV3TWlBd0lEQWdNUzB1TURJMExqQTJOV3d0TGpBMUxqQTJXaUlnWm1sc2JEMGlJek13TTBFelF5SXZQanh3WVhSb0lHUTlJbTB5TnpjZ01UVXdMalV6SURneExqY3pJRGMzTGpRekxUazFMalV0TVRRNUxqWTVUREkzTnlBeE5UQXVOVE5hSWlCbWFXeHNQU0lqTXpBelFUTkRJaTgrUEhCaGRHZ2daRDBpVFRJMk5pNDJPQ0F6TWpFdU9ETm9MUzR3TldFdU1URTFMakV4TlNBd0lEQWdNUzB1TURVdExqQTNUREl6TlM0Mk1TQXlNREJzTmkwME9TNDFZUzR3T1RNdU1Ea3pJREFnTUNBeElDNHdNek10TGpBMk5DNHdPVGN1TURrM0lEQWdNQ0F4SUM0d05qY3RMakF5TmtneU56ZGpMakF4T1NBd0lDNHdNemd1TURBMkxqQTFOQzR3TVRjdU1ERTJMakF4TGpBeU9DNHdNalV1TURNMkxqQTBNMHd6TkRFdU5qRWdNamc1ZGk0d04yRXVNRGszTGpBNU55QXdJREFnTVMwdU1ESXlMakF6T0M0d09UY3VNRGszSURBZ01DQXhMUzR3TXpndU1ESXliQzAzTkM0NE5DQXpNaTQzYUMwdU1ETmFJaUJtYVd4c1BTSWpNekl6TXpNMUlpOCtQSEJoZEdnZ1pEMGlUVEkwTVM0M015QXhOVEF1TlRNZ01qTTFMamNnTWpBd2JETXdMams0SURFeU1TNDNOQ0EzTkM0NE5DMHpNaTQzVERJM055QXhOVEF1TlROb0xUTTFMakkzV2lJZ1ptbHNiRDBpSXpNeU16TXpOU0l2UGp4d1lYUm9JR1E5SWswek5ERXVOVE1nTWpnNUxqRTBZUzR4TVRFdU1URXhJREFnTUNBeExTNHhMUzR3Tm13dE5qUXVOVEl0TVRNNExqVXhZUzR3T1RndU1EazRJREFnTUNBeExTNHdNaTB1TURaak1DMHVNREl5TGpBd055MHVNRFF6TGpBeUxTNHdObWd1TURaaExqRXdOUzR4TURVZ01DQXdJREVnTGpBM0lEQnNPREV1TnpNZ056Y3VORE5oTGpFd09DNHhNRGdnTUNBd0lERWdNQ0F1TVd3dE1UY3VNakVnTmpFdU1EaGhMakV3TWk0eE1ESWdNQ0F3SURFdExqQXpMakE0V2lJZ1ptbHNiRDBpSXpNNU0wRXpReUl2UGp4d1lYUm9JR1E5SW0wek5ERXVOVElnTWpnNUxqQTBJREUzTGpJeExUWXhMakE0VERJM055QXhOVEF1TlROc05qUXVOVElnTVRNNExqVXhXaUlnWm1sc2JEMGlJek01TTBFelF5SXZQanh3WVhSb0lHUTlJazB4TVRBdU1TQXlOREV1T0ROaExqRXlNaTR4TWpJZ01DQXdJREV0TGpBNElEQnNMVFExTGpZdE5qRXVNVE5oTGpBNUxqQTVJREFnTUNBeElEQXRMakV6VERFM05pNHlOeUEzT0M0eE9XRXVNVEV1TVRFZ01DQXdJREVnTGpBM0lEQWdMakl1TWlBd0lEQWdNU0F1TURnZ01HdzJOUzR6T0NBM01pNHlOaTAySURRNUxqVTFZekFnTGpBeUxTNHdNRGN1TURNNUxTNHdNaTR3TlROaExqQTNPQzR3TnpnZ01DQXdJREV0TGpBMUxqQXlOMnd0TVRJMUxqWWdOREV1TnpNdExqQXpMakF5V2lJZ1ptbHNiRDBpSXpNMk0wSXpSU0l2UGp4d1lYUm9JR1E5SWsweE56WXVNelFnTnpndU1qY2dOalF1TlNBeE9EQXVOalJzTkRVdU5pQTJNUzR3T1V3eU16VXVOeUF5TURCc05pNHdNeTAwT1M0ME55MDJOUzR6T1MwM01pNHlObG9pSUdacGJHdzlJaU16TmpOQ00wVWlMejQ4Y0dGMGFDQmtQU0pOT0RZZ016QTJMak0xWVM0d09UWXVNRGsySURBZ01DQXhMUzR3TkRZdExqQXhOUzR4TURVdU1UQTFJREFnTUNBeExTNHdNelF0TGpBek5Xd3RORFF1TnpNdE5qWXVNalFnTWpNdU1qSXROVGt1TkRWaExqRXdOUzR4TURVZ01DQXdJREVnTGpBekxTNHdORGN1TVRBekxqRXdNeUF3SURBZ01TQXVNRFV0TGpBeU15NHhNakl1TVRJeUlEQWdNQ0F4SUM0d09DQXdiRFExTGpZZ05qRXVNRGt0TWpRdU1EY2dOalF1TmpaaExqRXdOUzR4TURVZ01DQXdJREV0TGpBek1pNHdOREV1TVRBMExqRXdOQ0F3SURBZ01TMHVNRFE0TGpBeE9VZzRObG9pSUdacGJHdzlJaU15TWpJM01rRWlMejQ4Y0dGMGFDQmtQU0pOTmpRdU5TQXhPREF1TmpRZ05ERXVNamNnTWpRd2JEUTBMamMwSURZMkxqSTFJREkwTGpBNUxUWTBMalV5TFRRMUxqWXROakV1TURsYUlpQm1hV3hzUFNJak1qSXlOekpCSWk4K1BIQmhkR2dnWkQwaVRUZzJJRE13Tmk0ek5XRXVNRGsxTGpBNU5TQXdJREFnTVMwdU1EUTJMUzR3TVRVdU1UQTFMakV3TlNBd0lEQWdNUzB1TURNMExTNHdNelV1TVRNdU1UTWdNQ0F3SURFZ01DMHVNRGxNTVRFd0lESTBNUzQyT1d3eE1qVXVOamN0TkRFdU56aG9MakE0WVM0eE1UVXVNVEUxSURBZ01DQXhJQzR3TlM0d04yd3pNU0F4TWpFdU56TmhMakV1TVNBd0lEQWdNU0F3SUM0d09TNHhNRFV1TVRBMUlEQWdNQ0F4TFM0d055QXdURGcySURNd05pNHpOVm9pSUdacGJHdzlJaU15TWpJM01rRWlMejQ4Y0dGMGFDQmtQU0p0T0RZdU1ERWdNekEyTGpJMUlERTRNQzQyTnlBeE5TNDBPVXd5TXpVdU55QXlNREJzTFRFeU5TNDJJRFF4TGpjekxUSTBMakE1SURZMExqVXlXaUlnWm1sc2JEMGlJekl5TWpjeVFTSXZQand2YzNablBn"),
           bytes("YlRFMk9DNDFOU0F4TlRndU1EVXRPRFl1TVRJdE1qTXVNamhoTGpBNE55NHdPRGNnTUNBd0lERXRMakExTnkwdU1ETXVNRGc1TGpBNE9TQXdJREFnTVMwdU1ESXpMUzR3Tm1Nd0xTNHdNakV1TURBMUxTNHdOREV1TURFMkxTNHdOVGxoTGpFeE1pNHhNVElnTUNBd0lERWdMakEwTkMwdU1EUXhiRGMxTGpZMUxUTXdMakkyYURRMExqSTNUREk1TlM0ME5DQTRNV0V1TVRFdU1URWdNQ0F3SURFZ0xqQTNJREFnTGpBNU9DNHdPVGdnTUNBd0lERWdMakF4TXk0d05TNHdPVGN1TURrM0lEQWdNQ0F4TFM0d01UTXVNRFZzTFRFNUxqYzVJRFV6TGpVMExURXdOeTR4TkNBeU15NDBNV2d0TGpBeldpSWdabWxzYkQwaUl6UTJORUkwUlNJdlBqeHdZWFJvSUdROUltMDRNaTQwTlNBeE16UXVOamdnT0RZdU1UTWdNak11TWpjZ01UQTNMakEzTFRJekxqSTNJREU1TGpjNUxUVXpMalUwTFRrekxqRXhJREl6TGpJNFNERTFPQzR4YkMwM05TNDJOU0F6TUM0eU5sb2lJR1pwYkd3OUlpTTBOalJDTkVVaUx6NDhjR0YwYUNCa1BTSk5Nemd1TWpNZ01qYzFMalpoTGpBNE5TNHdPRFVnTUNBd0lERXRMakF6TlM0d01EY3VNRGcxTGpBNE5TQXdJREFnTVMwdU1ETTFMUzR3TURjdU1EZ3VNRGdnTUNBd0lERWdNQzB1TURkMkxUWTFMakpzTkRRdU1qUXROelV1TjJFdU1EY3lMakEzTWlBd0lEQWdNU0F1TURRdExqQXhNMk11TURFMElEQWdMakF5T0M0d01EVXVNRFF1TURFemJEZzJMakV5SURJekxqSTRhQzR3TjJNdU1ERXVNREk1TGpBeExqQTJNU0F3SUM0d09Vd3hNVFFnTWpjeExqUTNZUzR4TVRVdU1URTFJREFnTUNBeExTNHdNemN1TURReUxqRXhNaTR4TVRJZ01DQXdJREV0TGpBMU15NHdNVGhzTFRjMUxqWTRJRFF1TURkYUlpQm1hV3hzUFNJak5FRTBSalV5SWk4K1BIQmhkR2dnWkQwaWJUZ3lMalExSURFek5DNDJPQzAwTkM0eU1pQTNOUzQyTlhZMk5TNHhOMnczTlM0Mk5TMDBMakEzSURVMExqY3RNVEV6TGpRNExUZzJMakV6TFRJekxqSTNXaUlnWm1sc2JEMGlJelJCTkVZMU1pSXZQanh3WVhSb0lHUTlJazB4TkRJdU9UUWdNekE0TGpFNUlETTRMaklnTWpjMUxqWmhMakV3TVM0eE1ERWdNQ0F3SURFdExqQTNMUzR4TVM0d09Ea3VNRGc1SURBZ01DQXhJQzR3T1MwdU1EbHNOelV1TmpVdE5DNHdOMHd4TkRNdU1EVWdNekE0WVM0d09TNHdPU0F3SURBZ01TQXdJQzR4TWk0d09USXVNRGt5SURBZ01DQXhMUzR3TkM0d01EZ3VNRGt5TGpBNU1pQXdJREFnTVMwdU1EUXRMakF3T0d3dExqQXpMakEzV2lJZ1ptbHNiRDBpSXpJeU1qY3lRU0l2UGp4d1lYUm9JR1E5SW0weE1UTXVPRGdnTWpjeExqUXpJREk1TGpBNUlETTJMalkyVERNNExqSXpJREkzTlM0MWJEYzFMalkxTFRRdU1EZGFJaUJtYVd4c1BTSWpNakl5TnpKQklpOCtQSEJoZEdnZ1pEMGliVEUwTXlBek1EZ3VNVGt0TWprdU1UY3RNell1TjJFdU1EZ3pMakE0TXlBd0lEQWdNUzB1TURFNExTNHdOV013TFM0d01UZ3VNREEzTFM0d016WXVNREU0TFM0d05XdzFOQzQzTFRFeE15NDBPQ0F4TURjdU1UWXRNak11TXpOaExqQTVMakE1SURBZ01DQXhJQzR3T1M0d05tdzBNQzQzTkNBeE1UZ3VOekl0TWpNdU16SWdOVFF1TnpkaExqQTVOUzR3T1RVZ01DQXdJREV0TGpBek5pNHdORE11TURrMkxqQTVOaUF3SURBZ01TMHVNRFUwTGpBeE4wZ3hORE5hSWlCbWFXeHNQU0lqTXpZelFqTkZJaTgrUEhCaGRHZ2daRDBpVFRFME1pNDVOeUF6TURndU1EbG9NVFV3TGpFMGJESXpMakkzTFRVMExqY3ROREF1TnpNdE1URTRMamN4TFRFd055NHdOeUF5TXk0eU55MDFOQzQzSURFeE15NDBPQ0F5T1M0d09TQXpOaTQyTmxvaUlHWnBiR3c5SWlNek5qTkNNMFVpTHo0OGNHRjBhQ0JrUFNKTk1qa3pMakV4SURNd09DNHhPV0V1TURrNExqQTVPQ0F3SURBZ01TMHVNRFEzTFM0d01UTXVNRGt6TGpBNU15QXdJREFnTVMwdU1ETTFMUzR3TXpNdU1EazRMakE1T0NBd0lEQWdNUzB1TURBNExTNHdPVFJzTWpNdU1qY3ROVFF1TjJFdU1EZzVMakE0T1NBd0lEQWdNU0F1TURZdExqQTJhQzR3T0d3ME5TNHpPU0F5TWk0eE1XRXVNVEV5TGpFeE1pQXdJREFnTVNBdU1EVXVNRGt1TURrdU1Ea2dNQ0F3SURFdExqQTFMakE1YkMwMk9DNDJOeUF6TWk0MU9TMHVNRFF1TURKYUlpQm1hV3hzUFNJak16SXpNek0xSWk4K1BIQmhkR2dnWkQwaWJUSTVNeTR4TVNBek1EZ3VNRGtnTmpndU5qWXRNekl1TlRrdE5EVXVNemt0TWpJdU1URXRNak11TWpjZ05UUXVOMW9pSUdacGJHdzlJaU16TWpNek16VWlMejQ4Y0dGMGFDQmtQU0p0TXpZeExqYzNJREkzTlM0MkxUUTFMak01TFRJeUxqRXhMVFF3TGpnekxURXhPQzQzT0NBeE9TNDNPUzAxTXk0Mk1XRXVNRGs0TGpBNU9DQXdJREFnTVNBdU1EUXRMakEwTmk0eE1ESXVNVEF5SURBZ01DQXhJQzR3TmkwdU1ERTBMakV1TVNBd0lEQWdNU0F1TURrdU1EZHNOall1TXpRZ01UazBMak0yWVM0eE1EZ3VNVEE0SURBZ01DQXhJREFnTGpFeGJDMHVNUzR3TWxvaUlHWnBiR3c5SWlNeU9USkZNekVpTHo0OGNHRjBhQ0JrUFNKTk16WXhMamMzSURJM05TNDFJREk1TlM0ME5DQTRNUzR4Tkd3dE1Ua3VOemtnTlRNdU5UUWdOREF1TnpNZ01URTRMamN4SURRMUxqTTVJREl5TGpFeFdpSWdabWxzYkQwaUl6STVNa1V6TVNJdlBqd3ZjM1puUGc9")
        ];

        return coals[random(1, coals.length, index) - 1];
    }

    /// @notice Receives json from constructTokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override (ERC721)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentToken();

        return
            string(
                abi.encodePacked(
                    bytes("data:application/json;base64,"),
                    bytes("eyJkZXNjcmlwdGlvbiI6ICJDb2FsIGZyb20gU2FudGEiLCAibmFtZSI6ICJDT0FMIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQs"),
                    bytes("UEhOMlp5QjNhV1IwYUQwaU5EQXdJaUJvWldsbmFIUTlJalF3TUNJZ2RtbGxkMEp2ZUQwaU1DQXdJRFF3TUNBME1EQWlJR1pwYkd3OUltNXZibVVpSUhodGJHNXpQU0pvZEhSd09pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUkrUEhCaGRHZ2daRDBp"),
                    christmasMagic(tokenId),
                    bytes("In0=")
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

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
        revert NotImplementedError();
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
        _setApprovalForAll(_msgSender(), operator, approved);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    error NotImplementedError();

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
        revert NotImplementedError();
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// Taken from https://etherscan.io/address/0xc18360217d8f7ab5e7c516566761ea12ce7f9d72#code#F16#L1
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol
// Borrowed from https://etherscan.io/address/0xc18360217d8f7ab5e7c516566761ea12ce7f9d72#code

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool, uint256) {
        bytes32 computedHash = leaf;
        uint256 index = 0;

        for (uint256 i = 0; i < proof.length; i++) {
            index *= 2;
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
                index += 1;
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return (computedHash == root, index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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