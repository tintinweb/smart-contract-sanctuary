// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs21 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_276(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly, Perfect and a Saltire',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132.002h50v-60h-50v60Zm0 65a50 50 0 0 1-50-49.908v-15.092h50v65Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m110 78.25 19.794 23.752L110 125.756v6.246h5.21l19.79-23.75 19.793 23.75H160v-6.248l-19.792-23.752L160 78.25v-6.248h-5.207L135 95.754l-19.791-23.752H110v6.248Zm-44.788 53.752L85 155.757l19.795-23.755H110v6.249l-19.79 23.751L110 185.758v11.244c-.357 0-.71-.02-1.065-.027L85 168.254l-11.1 13.324a50.192 50.192 0 0 1-5.148-6.319L79.8 162.002 60 138.253v-6.251h5.212Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_277(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale, Perfect and Barry of Eight',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197V72h50v75a49.997 49.997 0 0 1-50 50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M160 87v15h-49.995V87H160Zm-49.995 110a49.937 49.937 0 0 0 22.365-5.27A49.932 49.932 0 0 0 150.005 177h-40v20Zm0-35h47.7A50.01 50.01 0 0 0 160 147.01V147h-49.995v15Zm0-30h50v-15h-50v15Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_278(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale, Semy of Ten Four-pointed Stars and Barry of Eight',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197V72h50v75a49.997 49.997 0 0 1-50 50Zm-25-71.478 1.393 4.807L91.478 132l-5.085 1.671L85 138.479l-1.394-4.807L78.521 132l5.085-1.672L85 125.522Zm12.5-15 1.393 4.807 5.085 1.671-5.085 1.671-1.393 4.808-1.394-4.807L91.021 117l5.085-1.672 1.394-4.806Zm-25 0 1.393 4.807L78.978 117l-5.085 1.671-1.393 4.808-1.394-4.807L66.021 117l5.085-1.672 1.394-4.806Zm12.5-15 1.393 4.807L91.478 102l-5.085 1.671L85 108.479l-1.394-4.807L78.521 102l5.085-1.672L85 95.522Zm-12.5-15 1.393 4.807L78.978 87l-5.085 1.671-1.393 4.808-1.394-4.807L66.021 87l5.085-1.672 1.394-4.806Zm25 0 1.393 4.807L103.978 87l-5.085 1.671-1.393 4.808-1.394-4.807L91.021 87l5.085-1.672 1.394-4.806Zm-1.394 68.15L91.021 147l5.085-1.671 1.394-4.807 1.393 4.807 5.085 1.671-5.085 1.672-1.393 4.807-1.394-4.807Zm-25 0L66.021 147l5.085-1.671 1.394-4.807 1.393 4.807L78.978 147l-5.085 1.672-1.393 4.807-1.394-4.807Zm12.5 15L78.521 162l5.085-1.671L85 155.522l1.393 4.807L91.478 162l-5.085 1.672L85 168.479l-1.394-4.807Zm12.5 15L91.021 177l5.085-1.671 1.394-4.807 1.393 4.807 5.085 1.671-5.085 1.672-1.393 4.807-1.394-4.807Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M160 87v15h-49.995V87H160Zm-49.995 110a49.937 49.937 0 0 0 22.365-5.27A49.932 49.932 0 0 0 150.005 177h-40v20Zm0-35h47.7A50.01 50.01 0 0 0 160 147.01V147h-49.995v15Zm0-30h50v-15h-50v15Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_279(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale, Paly of Eight and Perfect',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197V72h50v75a49.997 49.997 0 0 1-50 50Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M91.25 72h6.25v123.405a50.089 50.089 0 0 1-6.25-2.063V72Zm-12.5 114.018a50.097 50.097 0 0 0 6.25 4.268V72h-6.25v114.018ZM103.75 72v124.593c2.073.266 4.16.402 6.25.407V72h-6.25Zm-37.5 99.181a49.984 49.984 0 0 0 6.25 8.873V72h-6.25v99.181Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_280(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Semy of Sixteen Quatrefoils and a Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi280-a" viewBox="-4.9 -4.9 9.8 9.8"><path d="M1.6 2.9c0-.6-.3-.9-.7-1.3-.3-.3.3-1.1.7-.7.5.4.7.7 1.3.7C4.1 1.6 4 .4 4.9 0c-.8-.3-.9-1.6-2-1.6-.6 0-.9.3-1.3.7-.3.3-1.1-.3-.7-.7.4-.5.7-.7.7-1.3C1.6-4.1.4-4 0-4.9c-.3.8-1.6.9-1.6 2 0 .6.3.9.7 1.3.3.3-.3 1.1-.7.7-.5-.4-.7-.7-1.3-.7-1.2 0-1.1 1.2-2 1.6.8.3.9 1.6 2 1.6.6 0 .9-.3 1.3-.7.3-.3 1.1.3.7.7-.4.5-.7.7-.7 1.3 0 1.2 1.2 1.1 1.6 2 .3-.8 1.6-.9 1.6-2z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi280-b" viewBox="-17.4 -12.4 34.8 24.8"><use height="9.8" overflow="visible" transform="translate(-12.5 7.5)" width="9.8" x="-4.9" xlink:href="#fi280-a" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(12.5 7.5)" width="9.8" x="-4.9" xlink:href="#fi280-a" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(0 -7.5)" width="9.8" x="-4.9" xlink:href="#fi280-a" y="-4.9"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h100v30H60V72z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><use height="24.8" overflow="visible" transform="matrix(1 0 0 -1 85 124.4)" width="34.8" x="-17.4" xlink:href="#fi280-b" y="-12.4"/><use height="24.8" overflow="visible" transform="matrix(1 0 0 -1 85 154.4)" width="34.8" x="-17.4" xlink:href="#fi280-b" y="-12.4"/><use height="24.8" overflow="visible" transform="matrix(1 0 0 -1 135 124.4)" width="34.8" x="-17.4" xlink:href="#fi280-b" y="-12.4"/><use height="24.8" overflow="visible" transform="matrix(1 0 0 -1 135 154.4)" width="34.8" x="-17.4" xlink:href="#fi280-b" y="-12.4"/><use height="24.8" overflow="visible" transform="translate(110 169.4)" width="34.8" x="-17.4" xlink:href="#fi280-b" y="-12.4"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 131.9)" width="9.8" x="-4.9" xlink:href="#fi280-a" y="-4.9"/>'
                    )
                )
            );
    }

    function field_281(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Semy of Eighteen Four-pointed Stars and a Base',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 125.521 1.393 4.807 5.085 1.671-5.085 1.671-1.393 4.808-1.394-4.807-5.085-1.672 5.085-1.672 1.394-4.806Zm-26.394 4.807-5.084 1.671 5.084 1.671 1.395 4.808 1.392-4.807 5.085-1.672-5.084-1.672L85 125.521l-1.394 4.807Zm50 0-5.085 1.671 5.085 1.671 1.394 4.808 1.393-4.807 5.085-1.672-5.085-1.672-1.393-4.806-1.394 4.807Zm-37.5-15-5.084 1.671 5.084 1.671 1.395 4.807 1.392-4.807 5.085-1.671-5.084-1.672-1.394-4.806-1.394 4.807Zm-25 0-5.084 1.671 5.084 1.671 1.395 4.807 1.392-4.807 5.085-1.671-5.084-1.672-1.394-4.806-1.394 4.807Zm50 0-5.085 1.671 5.085 1.671 1.394 4.807 1.393-4.807 5.085-1.671-5.085-1.672-1.393-4.807-1.394 4.808Zm25 0-5.085 1.671 5.085 1.671 1.394 4.807 1.393-4.807 5.085-1.671-5.085-1.672-1.393-4.807-1.394 4.808Zm-62.5-15-5.084 1.671 5.084 1.671 1.395 4.808 1.392-4.807 5.085-1.672-5.084-1.672L85 95.522l-1.394 4.806Zm25 0-5.085 1.671 5.085 1.671 1.394 4.808 1.393-4.807 5.085-1.672-5.085-1.672L110 95.522l-1.394 4.806Zm25 0-5.085 1.671 5.085 1.671 1.394 4.808 1.393-4.807 5.085-1.672-5.085-1.672L135 95.522l-1.394 4.806Zm-62.5-15L66.022 87l5.084 1.672 1.395 4.807 1.392-4.806L78.978 87l-5.084-1.672-1.394-4.806-1.394 4.806Zm25 0L91.022 87l5.084 1.672 1.395 4.807 1.392-4.806L103.978 87l-5.084-1.672-1.394-4.806-1.394 4.806Zm25 0L116.021 87l5.085 1.672 1.394 4.806 1.393-4.806 5.085-1.672-5.085-1.671-1.393-4.806-1.394 4.806Zm25 0L141.021 87l5.085 1.672 1.394 4.806 1.393-4.806 5.085-1.672-5.085-1.671-1.393-4.806-1.394 4.806Zm-48.605 68.15 1.392-4.807 5.085-1.672-5.084-1.671-1.394-4.807-1.394 4.807-5.084 1.671 5.084 1.672 1.395 4.807Zm-25 0 1.392-4.807 5.085-1.672-5.084-1.671-1.394-4.807-1.394 4.807-5.084 1.671 5.084 1.672 1.395 4.807Zm49.999 0 1.393-4.807 5.085-1.672-5.085-1.671-1.393-4.807-1.394 4.807-5.085 1.671 5.085 1.672 1.394 4.807Zm25 0 1.393-4.807 5.085-1.672-5.085-1.671-1.393-4.807-1.394 4.807-5.085 1.671 5.085 1.672 1.394 4.807Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M157.708 162H62.293a50.013 50.013 0 0 0 77.292 25.312A50.011 50.011 0 0 0 157.708 162Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_282(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fixture',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M112 156.608v-19.216l3.392-3.392h14.216l3.392 3.392v19.216L129.608 160h-14.216L112 156.608ZM90.391 160h14.217l3.392-3.392v-19.216L104.608 134H90.391L87 137.392v19.216L90.391 160Zm39.217-56h-14.216L112 107.392v19.216l3.392 3.392h14.216l3.392-3.392v-19.216L129.608 104Zm-25 0H90.391L87 107.392v19.216L90.391 130h14.217l3.392-3.392v-19.216L104.608 104Zm35.784-4h16.216L160 96.608V75.392L156.608 72h-16.216L137 75.392v21.216l3.392 3.392ZM137 137.392v19.216l3.392 3.392H155.6l3.327-2.69A50.022 50.022 0 0 0 160 147v-9.608L156.608 134h-16.216L137 137.392ZM79.608 104H63.392L60 107.392v19.216L63.392 130h16.216L83 126.608v-19.216L79.608 104Zm0 30H63.392L60 137.392V147c0 3.465.36 6.92 1.073 10.31L64.4 160h15.208L83 156.608v-19.216L79.608 134Zm50 30h-14.216L112 167.392v25.9l3.714 3.376a49.642 49.642 0 0 0 15.3-4.295l1.99-3.095v-21.886L129.608 164Zm-50 0H68.086l-3.073 4.836a50.165 50.165 0 0 0 12.414 16.082l5.573-2.6v-14.926L79.608 164ZM137 167.392v14.924l5.573 2.6a50.165 50.165 0 0 0 12.414-16.082L151.914 164h-11.522L137 167.392ZM83 96.608V75.392L79.608 72H63.392L60 75.392v21.216L63.392 100h16.216L83 96.608Zm54 10.784v19.216l3.392 3.392h16.216l3.392-3.392v-19.216L156.608 104h-16.216L137 107.392ZM104.608 72H90.391L87 75.392v21.216L90.391 100h14.217L108 96.608V75.392L104.608 72ZM108 193.289v-25.9L104.608 164H90.391L87 167.392v21.883l1.99 3.094a49.622 49.622 0 0 0 15.3 4.3l3.71-3.38Zm4-117.9v21.219l3.392 3.392h14.216L133 96.608V75.392L129.608 72h-14.216L112 75.389Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M88 102a3.004 3.004 0 0 1-1.852 2.772 2.998 2.998 0 0 1-3.27-.651 2.998 2.998 0 0 1 .455-4.615A3 3 0 0 1 88 102Zm22-3a3.003 3.003 0 0 0-2.772 1.852 2.997 2.997 0 0 0 .651 3.269A2.997 2.997 0 0 0 113 102a2.997 2.997 0 0 0-3-3Zm-25 30a2.998 2.998 0 0 0-2.772 1.852A2.999 2.999 0 1 0 85 129Zm25 0a3 3 0 1 0 .001 6.002A3 3 0 0 0 110 129Zm-25 30a2.998 2.998 0 0 0-2.772 1.852A2.999 2.999 0 1 0 85 159Zm47-57a3 3 0 1 0 6.002-.001A3 3 0 0 0 132 102Zm0 30a3 3 0 1 0 6.002-.001A3 3 0 0 0 132 132Zm0 30a3 3 0 1 0 6.002-.001A3 3 0 0 0 132 162Zm-22-3a3 3 0 1 0 .001 6.002A3 3 0 0 0 110 159Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_283(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Net',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><symbol id="fi283-a" viewBox="0 0 19.822 23.787"><path d="M0 15h7.322v8.787H0zM12.5 0h7.322v8.787H12.5z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi283-d" viewBox="0 0 119.822 23.787"><use height="23.787" width="19.822" xlink:href="#fi283-a"/><use height="23.787" transform="translate(25)" width="19.822" xlink:href="#fi283-a"/><use height="23.787" transform="translate(50)" width="19.822" xlink:href="#fi283-a"/><use height="23.787" transform="translate(75)" width="19.822" xlink:href="#fi283-a"/><use height="23.787" transform="translate(100)" width="19.822" xlink:href="#fi283-a"/></symbol><symbol id="fi283-b" viewBox="0 0 27 32"><path d="M10.839 32v-4.394h5.322V32l2-1v-4.031l4.647-5.576H26l1-2h-3.661v-6.787H27l-1-2h-3.192l-4.647-5.575V1l-2-1v4.393h-5.322V0l-2 1v4.031l-4.646 5.575H1l-1 2h3.661v6.787H0l1 2h3.193l4.646 5.576V31ZM5.661 20.031v-8.062l4.647-5.576h6.385l4.646 5.576v8.062l-4.646 5.575h-6.385Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi283-e" viewBox="0 0 102 32"><use height="32" width="27" xlink:href="#fi283-b"/><use height="32" transform="translate(25)" width="27" xlink:href="#fi283-b"/><use height="32" transform="translate(50)" width="27" xlink:href="#fi283-b"/><use height="32" transform="translate(75)" width="27" xlink:href="#fi283-b"/></symbol><clipPath id="fi283-c"><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="none"/></clipPath></defs><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi283-c)"><use height="23.787" transform="translate(56.339 67.607)" width="119.822" xlink:href="#fi283-d"/><use height="23.787" transform="translate(56.339 97.607)" width="119.822" xlink:href="#fi283-d"/><use height="23.787" transform="translate(56.339 127.607)" width="119.822" xlink:href="#fi283-d"/><use height="23.787" transform="translate(56.339 157.607)" width="119.822" xlink:href="#fi283-d"/><use height="23.787" transform="translate(56.339 187.607)" width="119.822" xlink:href="#fi283-d"/><use height="32" transform="translate(59 71)" width="102" xlink:href="#fi283-e"/><use height="32" transform="translate(59 101)" width="102" xlink:href="#fi283-e"/><use height="32" transform="translate(59 131)" width="102" xlink:href="#fi283-e"/><use height="32" transform="translate(59 161)" width="102" xlink:href="#fi283-e"/><use height="32" transform="translate(59 191)" width="102" xlink:href="#fi283-e"/></g>'
                    )
                )
            );
    }

    function field_284(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Reticle',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M109 166.953V163h-3.953v-2H109v-3.953h2V161h3.953v2H111v3.953h-2ZM114.952 101H111v-3.953h-2V101h-3.953v2H109v3.953h2V103h3.953l-.001-2Zm23.406 55.406-3.358 4.03-3.359-4.03-1.537 1.28L133.7 162l-3.594 4.312 1.537 1.28 3.359-4.03 3.359 4.03 1.537-1.28L136.3 162l3.594-4.313-1.536-1.281Zm-6.718-48.815 3.359-4.03 3.359 4.03 1.537-1.28L136.3 102l3.594-4.313-1.537-1.28-3.357 4.029-3.359-4.03-1.537 1.28L133.7 102l-3.594 4.312 1.534 1.279ZM139.953 131H136v-3.953h-2V131h-3.953v2H134v3.953h2V133h3.953v-2Zm-51.595 25.406L85 160.436l-3.36-4.03-1.536 1.28L83.7 162l-3.6 4.311 1.537 1.28 3.363-4.03 3.359 4.03 1.537-1.28L86.3 162l3.594-4.313-1.536-1.281Zm-6.718-48.815 3.36-4.03 3.359 4.03 1.537-1.28L86.3 102l3.6-4.314-1.537-1.28-3.363 4.03-3.36-4.03-1.54 1.28L83.7 102l-3.6 4.311 1.54 1.28ZM89.952 131H86v-3.953h-2V131h-3.955v2H84v3.953h2V133h3.954l-.002-2Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m117.6 142.685 8.254 9.905 1.537-1.28-8.254-9.906-1.537 1.281Zm8.254-31.279-8.254 9.906 1.537 1.28 8.254-9.905-1.537-1.281ZM114.952 72h-9.906v2H109v13.953h2V74h3.953l-.001-2Zm29.19 20.594 8.255-9.905-1.537-1.281-8.26 9.906 1.542 1.28ZM114.952 195H111v-13.953h-2V195h-3.953v1.751c1.645.163 3.313.249 5 .249 1.656 0 3.291-.085 4.905-.242V195Zm-54.9-67.953v9.906H62V133h13.952v-2H62v-3.953h-1.948Zm17.346 45.636-1.537-1.28-5.254 6.3c.418.537.846 1.065 1.284 1.585l5.507-6.605Zm72.052 5.084-5.3-6.364-1.537 1.28 5.554 6.665c.433-.518.859-1.048 1.278-1.581h.005Zm-55.311-66.361-1.539 1.281 8.255 9.905 1.537-1.28-8.253-9.906ZM75.856 92.594l1.537-1.28-8.255-9.906-1.538 1.281 8.256 9.905ZM160.046 131H160v-3.953h-2V131h-13.954v2H158v3.953h2V133h.047l-.001-2ZM92.6 151.31l1.537 1.28 8.255-9.905-1.537-1.281-8.255 9.906Zm16.4-23.723v-10.54h2v10.54h-2ZM105.587 131h-10.54v2h10.54v-2Zm8.826 0v2h10.54v-2h-10.54ZM109 136.413v10.54h2v-10.54h-2Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
        string svgString;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}