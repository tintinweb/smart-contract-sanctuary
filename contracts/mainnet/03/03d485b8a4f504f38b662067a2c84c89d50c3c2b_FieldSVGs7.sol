// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs7 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_133(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Barry Dancetty',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m143.333 152 9 21.6a49.834 49.834 0 0 1-5.381 7.082L143.333 172l-7.4 17.762c-.493.3-1 .581-1.5.864L126.667 172l-8.334 20L110 172l-8.333 20-8.334-20-7.762 18.627c-.5-.283-1.009-.565-1.5-.864L76.667 172l-3.619 8.683a49.853 49.853 0 0 1-5.384-7.086l9-21.6L85 172l8.333-20 8.334 20L110 152l8.333 20 8.334-20L135 172l8.333-20ZM76.667 92 85 112l8.333-20 8.334 20L110 92l8.333 20 8.334-20L135 112l8.333-20 8.334 20L160 92V72l-8.333 20-8.334-20L135 92l-8.333-20-8.334 20L110 72l-8.333 20-8.334-20L85 92l-8.333-20-8.334 20L60 72.005V92l8.333 20 8.334-20Zm-8.334 60 8.334-20L85 152l8.333-20 8.334 20L110 132l8.333 20 8.334-20L135 152l8.333-20 8.334 20L160 132v-20l-8.333 20-8.334-20L135 132l-8.333-20-8.334 20L110 112l-8.333 20-8.334-20L85 132l-8.333-20-8.334 20L60 112v20l8.333 20Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_134(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Barry Embattled',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 81.608v26.667h3.572V102h7.142v6.275h7.143V102H85v6.275h7.143V102h7.143v6.275h7.143V102h7.142v6.275h7.143V102h7.143v6.275H135V102h7.143v6.275h7.143V102h7.143v6.275H160V81.608h-3.571v6.274h-7.143v-6.274h-7.143v6.274H135v-6.274h-7.143v6.274h-7.143v-6.274h-7.143v6.274h-7.142v-6.274h-7.143v6.274h-7.143v-6.274H85v6.274h-7.143v-6.274h-7.143v6.274h-7.142v-6.274H60Zm96.429 37.059v6.274h-7.143v-6.274h-7.143v6.274H135v-6.274h-7.143v6.274h-7.143v-6.274h-7.143v6.274h-7.142v-6.274h-7.143v6.274h-7.143v-6.274H85v6.274h-7.143v-6.274h-7.143v6.274h-7.142v-6.274H60v26.666h3.572v-6.274h7.142v6.274h7.143v-6.274H85v6.274h7.143v-6.274h7.143v6.274h7.143v-6.274h7.142v6.274h7.143v-6.274h7.143v6.274H135v-6.274h7.143v6.274h7.143v-6.274h7.143v6.274H160v-26.666h-3.571Zm0 37.058V162h-7.143v-6.275h-7.143V162H135v-6.275h-7.143V162h-7.143v-6.275h-7.143V162h-7.142v-6.275h-7.143V162h-7.143v-6.275H85V162h-7.143v-6.275h-7.143V162h-7.142v-6.275h-2.8a49.722 49.722 0 0 0 8.592 20.393h1.348v1.792a50.365 50.365 0 0 0 3.969 4.482h3.174v-6.274H85v6.274h7.143v-6.274h7.143v6.274h7.143v-6.274h7.142v6.274h7.143v-6.274h7.143v6.274H135v-6.274h7.143v6.274h3.174a50.38 50.38 0 0 0 3.969-4.482v-1.792h1.348a49.731 49.731 0 0 0 8.592-20.393h-2.797Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_135(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Barry Wavy I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi135-a" viewBox="-5.17 -10 10.33 20"><path d="m-4.17 3.33-1-7 1-6.33c3.99 0 4.34 6.67 8.33 6.67l1 6.33-1 7C.18 10-.18 3.33-4.17 3.33z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi135-b" viewBox="-9.33 -10 18.67 20"><use height="20" overflow="visible" transform="translate(-4.167)" width="10.33" x="-5.17" xlink:href="#fi135-a" y="-10"/><use height="20" overflow="visible" transform="matrix(-1 0 0 1 4.167 0)" width="10.33" x="-5.17" xlink:href="#fi135-a" y="-10"/></symbol><symbol id="fi135-c" viewBox="-51 -10 102 20"><use height="20" overflow="visible" transform="translate(-41.666)" width="18.67" x="-9.33" xlink:href="#fi135-b" y="-10"/><use height="20" overflow="visible" transform="translate(-25)" width="18.67" x="-9.33" xlink:href="#fi135-b" y="-10"/><use height="20" overflow="visible" transform="translate(-8.333)" width="18.67" x="-9.33" xlink:href="#fi135-b" y="-10"/><use height="20" overflow="visible" transform="translate(8.333)" width="18.67" x="-9.33" xlink:href="#fi135-b" y="-10"/><use height="20" overflow="visible" transform="translate(25)" width="18.67" x="-9.33" xlink:href="#fi135-b" y="-10"/><use height="20" overflow="visible" transform="translate(41.666)" width="18.67" x="-9.33" xlink:href="#fi135-b" y="-10"/></symbol><symbol id="fi135-f" viewBox="-51 -36.67 102 73.33"><use height="20" overflow="visible" width="102" x="-51" xlink:href="#fi135-c" y="-10"/><use height="20" overflow="visible" transform="translate(0 -26.666)" width="102" x="-51" xlink:href="#fi135-c" y="-10"/><use height="20" overflow="visible" transform="translate(0 26.666)" width="102" x="-51" xlink:href="#fi135-c" y="-10"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M160 147c0 27.61-22.38 50-49.99 50H110c-27.61 0-50-22.39-50-50V72h100v75z" id="fi135-d"/></defs><clipPath id="fi135-e"><use overflow="visible" xlink:href="#fi135-d"/></clipPath><g clip-path="url(#fi135-e)"><use height="73.33" overflow="visible" transform="matrix(1 0 0 -1 110 102)" width="102" x="-51" xlink:href="#fi135-f" y="-36.67"/><use height="73.33" overflow="visible" transform="matrix(1 0 0 -1 110 182)" width="102" x="-51" xlink:href="#fi135-f" y="-36.67"/></g>'
                    )
                )
            );
    }

    function field_136(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Barry Wavy II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 122a10.001 10.001 0 0 1-20 0v-10a10.001 10.001 0 0 0-20 0v10a10.001 10.001 0 0 1-20 0v-10a10 10 0 1 0-20 0v10a10 10 0 1 1-20 0V92a10 10 0 0 0 20 0V82a10 10 0 0 1 20 0v10a10.002 10.002 0 0 0 17.071 7.071A10.002 10.002 0 0 0 120 92V82a10.002 10.002 0 0 1 17.071-7.071A10.002 10.002 0 0 1 140 82v10a10.002 10.002 0 0 0 17.071 7.071A10.002 10.002 0 0 0 160 92v30Zm-.817 33.955a10.003 10.003 0 0 1-11.202 5.835A9.998 9.998 0 0 1 140 152v-10a10.001 10.001 0 0 0-20 0v10a10.001 10.001 0 0 1-20 0v-10a10 10 0 1 0-20 0v10a10 10 0 0 1-19.185 3.952 49.952 49.952 0 0 0 18.228 30.3A9.933 9.933 0 0 0 80 182v-10a10 10 0 1 1 20 0v10a10.001 10.001 0 0 0 20 0v-10a10.001 10.001 0 0 1 20 0v10a9.942 9.942 0 0 0 .958 4.248 49.948 49.948 0 0 0 18.226-30.293h-.001Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_137(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Checky I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60.25 152a49.569 49.569 0 0 1-.25-5v-35h33.333v40H60.25Zm33.083 42.144A49.909 49.909 0 0 0 110 197a49.91 49.91 0 0 0 16.667-2.856V152H93.333v42.144ZM126.667 72H93.333v40h33.334V72Zm33.083 80c.164-1.645.247-3.312.25-5v-35h-33.333v40h33.083Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_138(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Checky II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M85 102v30H60v-30h25Zm72.708 60A49.972 49.972 0 0 0 160 147v-15h-25v30h22.708ZM85 162h25v-30H85v30Zm25-90H85v30h25V72Zm0 60h25v-30h-25v30Zm25-30h25V72h-25v30Zm-25 94.977h.922A49.725 49.725 0 0 0 135 190.294V162h-25v34.977Zm-25-6.683V162H62.292A50.12 50.12 0 0 0 85 190.294Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_139(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Checky III',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M80 168h20v28a49.775 49.775 0 0 1-20-9v-19Zm40 28a49.757 49.757 0 0 0 20-9v-19h-20v28Zm40-100h-20V72h-20v24h20v24h20V96Zm-40 24v24h20v-24h-20Zm-60 27a49.803 49.803 0 0 0 4.624 21H80v-24H60v3Zm95.376 21A49.81 49.81 0 0 0 160 147v-3h-20v24h15.376ZM60 96v24h20V96H60Zm20 24v24h20v-24H80Zm40-24h-20v24h20V96Zm-20 0V72H80v24h20Zm0 72h20v-24h-20v24Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_140(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Checky IV',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M102.857 89.143H88.571V72h14.286v17.143Zm-14.286 103.03a50.005 50.005 0 0 0 14.286 4.309v-21.625H88.571v17.316Zm14.286-51.6h14.286v-17.145h-14.286v17.145Zm55.967 17.143A49.897 49.897 0 0 0 160 147v-6.429h-14.286v17.143l13.11.002ZM131.429 72h-14.286v17.143h14.286V72ZM160 123.428v-17.142h-14.286v17.142H160Zm-85.714 58.55v-7.121h-5.8a49.96 49.96 0 0 0 5.8 7.121ZM60 140.571V147a49.935 49.935 0 0 0 1.176 10.714h13.11v-17.143H60ZM60 72v17.143h14.286V72H60Zm57.143 124.482a50.005 50.005 0 0 0 14.286-4.309v-17.316h-14.286v21.625Zm34.374-21.625h-5.8v7.121a49.988 49.988 0 0 0 5.8-7.121ZM60 106.286v17.142h14.286v-17.142H60Zm71.429-17.143v17.143h14.285V89.143h-14.285Zm-42.858 34.285H74.286v17.143h14.285v-17.143Zm42.858 51.429h14.285v-17.143h-14.285v17.143Zm-57.143-17.143v17.143h14.285v-17.143H74.286Zm28.571 0v17.143h14.286v-17.143h-14.286Zm28.572-17.143h14.285v-17.143h-14.285v17.143ZM160 72h-14.286v17.143H160V72ZM88.571 89.143H74.286v17.143h14.285V89.143Zm14.286 17.143H88.571v17.142h14.286v-17.142Zm-14.286 34.285v17.143h14.286v-17.143H88.571Zm28.572 17.143h14.286v-17.143h-14.286v17.143Zm0-51.428V89.143h-14.286v17.143h14.286Zm0 17.142h14.286v-17.142h-14.286v17.142Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_141(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Checky V',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M93.333 112H82.222V98.667h11.111V112Zm-33.081 40a49.984 49.984 0 0 0 3.248 13.333h7.614V152H60.252Zm96.248 13.333A50.018 50.018 0 0 0 159.748 152h-10.859v13.333h7.611ZM93.333 72H82.222v13.333h11.111V72ZM60 98.667V112h11.111V98.667H60ZM60 72v13.333h11.111V72H60Zm100 66.667v-13.334h-11.111v13.334H160ZM160 72h-11.111v13.333H160V72Zm0 40V98.667h-11.111V112H160Zm-77.778 76.573a50.007 50.007 0 0 0 11.111 5.563v-15.469H82.222v9.906Zm22.222-89.906V112H93.333v13.333h11.111v13.334H93.333V152h11.111v13.333H93.333v13.334h11.111v18.012c3.692.428 7.42.428 11.112 0v-18.012h-11.112v-13.334h11.112V152h-11.112v-13.333h11.112v-13.334h-11.112V112h11.112V98.667h-11.112V85.333h11.112V72h-11.112v13.333H93.333v13.334h11.111ZM82.222 85.333H71.111v13.334h11.111V85.333Zm44.445 13.334V112h-11.111v13.333h11.111v13.334h-11.111V152h11.111v13.333h-11.111v13.334h11.111v15.469a50.057 50.057 0 0 0 11.111-5.563v-9.906h-11.111v-13.334h11.111V152h-11.111v-13.333h11.111v-13.334h-11.111V112h11.111V98.667h-11.111V85.333h11.111V72h-11.111v13.333h-11.111v13.334h11.111Zm-55.556 26.666H60v13.334h11.111v-13.334Zm77.778-26.666V85.333h-11.111v13.334h11.111ZM82.222 112H71.111v13.333h11.111V112Zm-11.111 53.333v13.083c.067.082.128.168.2.251h10.911v-13.334H71.111Zm11.111-26.666H71.111V152h11.111v-13.333Zm0 26.666h11.111V152H82.222v13.333Zm55.556-40h11.111V112h-11.111v13.333Zm-44.445 0H82.222v13.334h11.111v-13.334Zm44.445 53.334h10.915c.067-.083.129-.169.2-.252v-13.082h-11.115v13.334Zm0-26.667h11.111v-13.333h-11.111V152Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_142(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bendy Sinister I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M71.212 178.543 160 72.008V72h-49.992l-50 60v15.265a49.778 49.778 0 0 0 11.204 31.278ZM160 131.994V147a50 50 0 0 1-49.942 50h-.116c-1.341 0-2.666-.07-3.98-.175L160 132v-.006Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_143(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bendy Sinister II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60.01 72v40.014L93.347 72H60.01Zm83.325 60.009L91.981 193.64a49.865 49.865 0 0 0 17.954 3.36h.13a49.992 49.992 0 0 0 14.17-2.066l35.476-42.576c.191-1.78.287-3.568.289-5.358v-34.991l-16.665 20Zm16.665-60V72h-33.323L60.23 151.745a49.762 49.762 0 0 0 10.991 26.81L160 72.009Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_144(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bendy Sinister III',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M61.708 159.965a49.82 49.82 0 0 0 9.511 18.587L160 72.013V72h-24.989l-73.303 87.965ZM110.011 72 60 132.009v-30L86.142 72h23.869ZM160 102.013v30l-54.009 64.813a49.675 49.675 0 0 1-20.022-5.975L160 102.013Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_145(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bendy Sinister IV',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M63.082 164.314a49.929 49.929 0 0 0 8.134 14.235L160 72.015V72h-19.987l-76.931 92.314ZM60 96.021V72h20.022L60 96.021ZM120.016 72 60 144.013v-24L100.019 72h19.997ZM160 144v3.062a49.998 49.998 0 0 1-43.851 49.547L160 144Zm-77.369 44.837L160 96.01v24l-62.793 75.331a49.72 49.72 0 0 1-14.576-6.504Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_146(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevronny I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 132 38.79 46.543a50.113 50.113 0 0 1-20.756 15.092L110 172l-18.035 21.634a50.125 50.125 0 0 1-20.755-15.093L110 132Zm16.664-60h-33.33L60 112.005v35c0 1.6.083 3.173.229 4.731L110 92.005l49.773 59.73c.146-1.56.229-3.137.229-4.735v-34.99L126.664 72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_147(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevronny II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M97.205 195.341 110 179.991l12.793 15.351a50.173 50.173 0 0 1-25.585 0l-.003-.001ZM100.018 72h-20L60 96.021v23.993L100.018 72Zm9.979 36-46.919 56.3A49.913 49.913 0 0 1 60 147v-3l49.975-59.967h.045L160 144.01V147a49.898 49.898 0 0 1-3.08 17.309L109.997 108Zm27.37 80.833L110 156l-27.368 32.84a50.263 50.263 0 0 1-11.418-10.294L110 132l38.789 46.545a50.248 50.248 0 0 1-11.422 10.293v-.005ZM139.973 72 160 96.027v23.994L119.976 72h19.997Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_148(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevronny Inverted I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 132.01V147a49.806 49.806 0 0 1-4.19 20.038l-17.848 21.418a50.03 50.03 0 0 1-55.934-.007l-17.834-21.4A49.808 49.808 0 0 1 60 147v-14.985l50 60 50-60.005ZM160 72l-50 60-50-60v30l50 60 50-60V72Zm-75 0 25 30 25-30H85Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_149(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Chevronny Inverted II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 147v-3.014l43.861 52.625A49.998 49.998 0 0 1 60 147Zm39.989-75L110 84.009 120.005 72H99.989Zm16.143 124.612L160 143.979V147a50 50 0 0 1-43.868 49.612ZM110 156l50-60v23.99l-49.98 59.974h-.045L60 120V96l50 60Zm0-48 30-36h20l-50 60-50-59.994V72h19.992L110 108Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_150(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Lozengy I',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m159.99 132-25-30-25 30 24.992 29.989L159.99 132Zm-54.034 64.825a49.903 49.903 0 0 1-34.747-18.284L85 161.987l25 29.987-4.044 4.851ZM110 132l-25 29.987L60.006 132l25-30 25 30H110Zm38.793 46.543a49.891 49.891 0 0 1-34.749 18.282L110 191.974l24.995-29.987 13.798 16.556ZM60.006 72.008V72h49.988L85 102 60.006 72.008ZM110 72h49.99v.008L135 102l-25-30Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
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