// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs19 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_244(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierced Per Pale',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 147V72H93.33v122.143a50.373 50.373 0 0 0 5.573 1.606c.19.043.38.09.57.131.455.1.915.184 1.375.269a42.955 42.955 0 0 0 2.172.355c.393.055.788.106 1.184.151.36.042.72.083 1.082.117.487.046.976.08 1.466.112.288.018.575.042.864.056.79.037 1.584.06 2.384.06a49.997 49.997 0 0 0 50-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M126.67 194.143a50.007 50.007 0 0 0 24.154-18.277A50.009 50.009 0 0 0 160 147V72h-33.33v122.143Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_245(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierced per Fess',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147c0 1.688.083 3.355.25 5h99.5c.164-1.645.247-3.312.25-5v-35H60v35Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M159.751 152H60.25a50 50 0 0 0 99.5 0h.001Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_246(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierced per Bend Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M71.213 178.544a49.994 49.994 0 0 0 55.526 15.562A49.997 49.997 0 0 0 160 147V72L71.213 178.544Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m133.966 72-72.505 87.006a50.094 50.094 0 0 0 25.217 32.221L160 103.241V72h-26.034Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_247(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierced Per Pale and Per Fess I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 72h50v60h-50V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M60 132v15a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50v-15H60Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_248(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierced Per Pale and Per Fess II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147a49.997 49.997 0 0 0 50 50v-65H60v15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M160 147a49.997 49.997 0 0 1-50 50v-65h50v15Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_249(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pale Checky',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 197a49.84 49.84 0 0 0 18-3.353V72H92v121.647A49.841 49.841 0 0 0 110 197Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M116 196.629V180h12v13.647a49.647 49.647 0 0 1-12 2.982Zm-24-2.982a49.652 49.652 0 0 0 12 2.982V180H92v13.647ZM128 144v-12h-12v12h12Zm0-48V84h-12v12h12Zm-24 84h12v-12h-12v12Zm24-60v-12h-12v12h12Zm0 48v-12h-12v12h12Zm-36-60v12h12v-12H92Zm0-24v12h12V84H92Zm12-12v12h12V72h-12Zm0 36h12V96h-12v12Zm0 48h12v-12h-12v12Zm-12 0v12h12v-12H92Zm12-24h12v-12h-12v12Zm-12 0v12h12v-12H92Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_250(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bordure Compony',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75a50.002 50.002 0 0 0 49.99 50h.02A50 50 0 0 0 160 147V72H60Zm85 75a35.04 35.04 0 0 1-34.993 35 35.043 35.043 0 0 1-35-35V87h70L145 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M75 102H60V87h15v15Zm-.356 80.355A50.072 50.072 0 0 0 90.863 193.2l5.747-13.875a35.129 35.129 0 0 1-11.347-7.589l-10.619 10.619ZM75 117H60v15h15v-15Zm52.5-45H110v15h17.5V72Zm-35 0H75v15h17.5V72ZM75 147H60a49.842 49.842 0 0 0 3.8 19.134l13.874-5.746A34.795 34.795 0 0 1 75 147Zm70-75v15h15V72h-15Zm0 45h15v-15h-15v15Zm-34.993 65H110v15h.01a49.837 49.837 0 0 0 19.127-3.8l-5.746-13.874A34.798 34.798 0 0 1 110.007 182Zm24.731-10.265 10.619 10.619a50.073 50.073 0 0 0 10.843-16.22l-13.873-5.746a35.106 35.106 0 0 1-7.589 11.347ZM145 147h15v-15h-15v15Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_251(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bordure Parted Bordurewise',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75a50.002 50.002 0 0 0 49.99 50h.02A50 50 0 0 0 160 147V72H60Zm90 75a40.045 40.045 0 0 1-39.992 40 40.05 40.05 0 0 1-40-40V84h80L150 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M65 78v69a45.054 45.054 0 0 0 45.005 45A45.05 45.05 0 0 0 155 147V78H65Zm85 69a40.045 40.045 0 0 1-39.992 40 40.05 40.05 0 0 1-40-40V84h80L150 147Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_252(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bordure Counter-Compony',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75a50.002 50.002 0 0 0 49.99 50h.02A50 50 0 0 0 160 147V72H60Zm85 75a35.04 35.04 0 0 1-34.993 35 35.043 35.043 0 0 1-35-35V87h70L145 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75a50.002 50.002 0 0 0 49.99 50h.02A50 50 0 0 0 160 147V72H60Zm85 75a35.04 35.04 0 0 1-34.993 35 35.043 35.043 0 0 1-35-35V87h70L145 147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M145 87v-7.5h7.5V87H145Zm-35-15H92.5v7.5H110V72Zm35 0h-17.5v7.5H145V72Zm15 30V87h-7.5v15h7.5ZM60 132v15h7.5v-15H60Zm3.8 34.136a50.082 50.082 0 0 0 10.85 16.214l5.313-5.313a42.658 42.658 0 0 1-9.222-13.776l-6.941 2.875ZM160 132v-15h-7.5v15h7.5Zm-30.866 61.19a50.06 50.06 0 0 0 16.223-10.836l-5.318-5.318a42.647 42.647 0 0 1-13.776 9.223l2.871 6.931Zm-38.271.009a49.863 49.863 0 0 0 19.128 3.8H110v-7.5a42.273 42.273 0 0 1-16.261-3.244l-2.876 6.944ZM60 102v15h7.5v-15H60Zm89.26 61.261 6.94 2.874A49.824 49.824 0 0 0 160 147h-7.5a42.264 42.264 0 0 1-3.24 16.26v.001Zm-14.522 8.475 5.3 5.3a42.652 42.652 0 0 0 9.221-13.776l-6.933-2.872a35.13 35.13 0 0 1-7.588 11.347v.001ZM110.007 182H110v7.5h.008a42.26 42.26 0 0 0 16.255-3.241l-2.872-6.934A34.78 34.78 0 0 1 110.007 182ZM145 147h7.5v-15H145v15Zm0-45v15h7.5v-15H145Zm-59.737 69.735-5.3 5.3a42.653 42.653 0 0 0 13.776 9.221l2.871-6.932a35.128 35.128 0 0 1-11.347-7.589ZM127.5 87v-7.5H110V87h17.5ZM75 79.5V72H60v15h7.5v-7.5H75ZM92.5 87v-7.5H75V87h17.5ZM75 147h-7.5a42.244 42.244 0 0 0 3.241 16.259l6.933-2.871A34.793 34.793 0 0 1 75 147Zm0-60h-7.5v15H75V87Zm0 30h-7.5v15H75v-15Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_253(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross Cotised',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 117h-35V72H95v45H60v30h35v47.708A49.973 49.973 0 0 0 110 197a49.942 49.942 0 0 0 15-2.293V147h35v-30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M117.5 139H160v-14h-42.5V72h-15v53H60v14h42.5v57.438a50.348 50.348 0 0 0 15 0V139Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_254(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Saltire Cotised',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 102.32 84.731 72H60v29.68L85.266 132l-23.5 28.193a50.1 50.1 0 0 0 24.007 30.55L110 161.677l24.222 29.065a50.095 50.095 0 0 0 24.006-30.549l-23.5-28.2L160 101.678V72h-24.733L110 102.32Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m98.284 132-32.293 38.748a50.186 50.186 0 0 0 11.545 14.263L110 146.057l32.464 38.955a50.22 50.22 0 0 0 11.545-14.263L121.714 132 160 86.06V72h-11.716L110 117.941 71.714 72H60v14.06L98.284 132Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_255(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Orle on a Bordure',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75a49.997 49.997 0 0 0 50 50 49.997 49.997 0 0 0 50-50V72H60Zm75 75c0 6.63-2.634 12.989-7.322 17.678a25.004 25.004 0 0 1-35.356 0A25.003 25.003 0 0 1 85 147v-45.011h50V147Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M68.333 82v65a41.666 41.666 0 1 0 83.334 0V82H68.333Zm75 65a33.336 33.336 0 0 1-33.334 33.334 33.34 33.34 0 0 1-23.57-9.763A33.337 33.337 0 0 1 76.664 147V91.993h66.668V147Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_256(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pall Cotised',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 102.321 84.732 72H60v29.68l31 37.2v54.373a50.045 50.045 0 0 0 38 0v-54.374l31-37.2V72h-24.734L110 102.321Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110 117.941 71.714 72H60v14.06l41 49.2v60.918a49.592 49.592 0 0 0 18 0v-60.92l41-49.2V72h-11.716L110 117.941Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_257(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pall Inverted Cotised',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M158.228 160.2 129 125.121V72H91v53.121l-29.227 35.073a50.095 50.095 0 0 0 24.006 30.548L110 161.679l24.219 29.064a50.1 50.1 0 0 0 24.009-30.543Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M119 128.742V72h-18v56.741L65.992 170.75a50.192 50.192 0 0 0 11.545 14.262L110 146.059l32.461 38.955a50.162 50.162 0 0 0 11.546-14.263L119 128.742Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_258(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Fretty Parted',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi258-a" viewBox="-13.13 -15.63 26.22 31.79"><path d="m2.6-15 9.9 11.87v6.25L2.06 15.64-2.6 15l-9.9-11.88v-6.25l10.43-12.51L2.6-15zM0 11.88 9.9 0 0-11.87-9.9 0 0 11.88z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><g fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"><path d="M12.5 0 1.3-13.44 2.6-15 13.1-2.41z"/><path d="m.26-15.32-1.03 1.24L-11.2-1.56-9.9 0 0 11.88 9.9 0l1.3 1.56-12.16 14.6L-2.6 15l1.3-1.56L-13.13-.75l.63-2.37 10.43-12.51z"/></g></symbol><symbol id="fi258-b" viewBox="-25.63 -15.63 51.22 31.79"><use height="31.79" overflow="visible" transform="translate(-12.5)" width="26.22" x="-13.13" xlink:href="#fi258-a" y="-15.63"/><use height="31.79" overflow="visible" transform="translate(12.5)" width="26.22" x="-13.13" xlink:href="#fi258-a" y="-15.63"/></symbol><symbol id="fi258-c" viewBox="-50.63 -15.63 101.22 31.79"><use height="31.79" overflow="visible" transform="translate(-25)" width="51.22" x="-25.63" xlink:href="#fi258-b" y="-15.63"/><use height="31.79" overflow="visible" transform="translate(25)" width="51.22" x="-25.63" xlink:href="#fi258-b" y="-15.63"/></symbol><symbol id="fi258-f" viewBox="-50.63 -30.63 101.22 61.79"><use height="31.79" overflow="visible" transform="translate(0 15)" width="101.22" x="-50.63" xlink:href="#fi258-c" y="-15.63"/><use height="31.79" overflow="visible" transform="translate(0 -15)" width="101.22" x="-50.63" xlink:href="#fi258-c" y="-15.63"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi258-d"/></defs><clipPath id="fi258-e"><use overflow="visible" xlink:href="#fi258-d"/></clipPath><g clip-path="url(#fi258-e)"><use height="61.79" overflow="visible" transform="matrix(1 0 0 -1 110 102)" width="101.22" x="-50.63" xlink:href="#fi258-f" y="-30.63"/><use height="61.79" overflow="visible" transform="matrix(1 0 0 -1 110 162)" width="101.22" x="-50.63" xlink:href="#fi258-f" y="-30.63"/><use height="31.79" overflow="visible" transform="matrix(1 0 0 -1 110 207)" width="101.22" x="-50.63" xlink:href="#fi258-c" y="-15.63"/></g>'
                    )
                )
            );
    }

    function field_259(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Party of Eight',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132h50v15a49.972 49.972 0 0 1-2.292 15H110v-30Zm0-30h50V72h-50v30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110 132.053H60v-30h50v30ZM62.293 162A50.02 50.02 0 0 0 110 197v-35H62.293Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_260(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Three Quatrefoils on a Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h100v30H60V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M82.7 97.3c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Zm25 0c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Zm25 0c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_261(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross on a Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h100v30H60V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M160 84h-47V72h-6v12H60v6h47v12h6V90h47v-6Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_262(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Saltire on a Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h100v30H60V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M120.4 87 160 75.1V72h-10.4L110 83.9 70.4 72H60v3.1L99.6 87 60 98.9v3.1h10.4L110 90.1l39.6 11.9H160v-3.1L120.4 87Z" fill="#',
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