// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs14 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_212(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Rasterlines Bend Sinister',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M98.482 73.875 160.046 72v3.655l-3.127.095 3.127.1v3.459l-6.255.191 6.255.2v3.264l-9.383.286 9.383.3v3.068L147.535 87l12.511.4v2.872l-15.639.477 15.639.5v2.676l-18.767.572 18.767.6v2.481l-21.895.667 21.895.7v2.285l-25.023.77-58.436-1.875 61.564-1.875-58.436-1.874L141.28 94.5l-58.436-1.874 61.564-1.876-58.437-1.874L147.534 87 89.1 85.126l61.564-1.876-58.438-1.874L153.79 79.5l-58.436-1.874 61.564-1.876-58.436-1.875Zm-38.435 60.373 46.825 1.5-46.825 1.427v.921l43.7 1.4-43.7 1.331v1.118l40.569 1.3-40.569 1.236v1.319l37.441 1.2-37.413 1.14c.012.505.016 1.011.042 1.512l34.243 1.1-34.08 1.038c.055.579.128 1.153.2 1.726l30.75.986-30.465.928c.111.656.23 1.31.366 1.957l26.97.865-26.584.81c.184.743.387 1.478.6 2.207l22.86.731 61.564-1.875-58.436-1.875 61.564-1.876-58.436-1.874 61.564-1.876-58.436-1.874 61.564-1.876L97.489 147l61.564-1.876-58.437-1.874 59.43-1.811v-.133l-56.3-1.806 56.3-1.715v-.329l-53.174-1.706 53.174-1.619v-.525L110 132l-49.953 1.521v.727Zm3.415 30.912 18.387.59-17.939.55c.394.939.816 1.863 1.266 2.77l13.545.434-13.118.4a50.451 50.451 0 0 0 1.72 3.085l8.27.265-7.945.242a49.66 49.66 0 0 0 2.336 3.429l2.481.079-2.362.072a53.122 53.122 0 0 0 2.95 3.565l57.849-1.763L72.465 177l61.565-1.876-58.437-1.874 61.565-1.876-58.437-1.874 61.564-1.876-58.436-1.874 61.564-1.875L84.977 162l-22.407.682c.276.837.574 1.663.892 2.478Zm68.438-59.41-61.564 1.876 58.436 1.874-61.572 1.876 58.436 1.874-61.564 1.876 58.44 1.874-61.565 1.876 58.437 1.874-59.337 1.808v.139l56.209 1.8-56.209 1.712v.335l53.081 1.7-53.08 1.617v.53L110 132l50.046-1.524v-.721l-46.918-1.5 46.918-1.429v-.916l-43.79-1.405 43.79-1.334v-1.112l-40.662-1.3 40.662-1.239v-1.32l-37.534-1.2 37.534-1.144v-1.5l-34.406-1.1 34.406-1.048v-1.7l-31.278-1 31.278-.953v-1.894l-28.15-.9 28.15-.857V102.8l-25.023-.8-61.564 1.875 58.441 1.875Zm-58.619 75.126a50.5 50.5 0 0 0 3.345 3.306l51.148-1.558-54.493-1.748Zm4.126 3.983c1.161 1 2.368 1.948 3.62 2.844l43.619-1.329-47.239-1.515Zm40.982 9.017-28.013-.9a48.579 48.579 0 0 0 4.342 1.619l23.671-.719Zm-35.642-5a50.677 50.677 0 0 0 3.9 2.306l34.87-1.062-38.77-1.244Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_213(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Rasterlines Pale Horizon',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi213-a" viewBox="-1.56 -60 3.12 120"><path d="M0 60-1.56 0 0-60 1.56 0z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi213-b" viewBox="-4.69 -60 9.38 120"><use height="120" overflow="visible" transform="translate(3.125)" width="3.12" x="-1.56" xlink:href="#fi213-a" y="-60"/><use height="120" overflow="visible" width="3.12" x="-1.56" xlink:href="#fi213-a" y="-60"/><use height="120" overflow="visible" transform="translate(-3.125)" width="3.12" x="-1.56" xlink:href="#fi213-a" y="-60"/></symbol><symbol id="fi213-e" viewBox="-28.12 -60 56.25 120"><use height="120" overflow="visible" transform="translate(23.438)" width="9.38" x="-4.69" xlink:href="#fi213-b" y="-60"/><use height="120" overflow="visible" transform="translate(14.063)" width="9.38" x="-4.69" xlink:href="#fi213-b" y="-60"/><use height="120" overflow="visible" transform="translate(4.688)" width="9.38" x="-4.69" xlink:href="#fi213-b" y="-60"/><use height="120" overflow="visible" transform="translate(-4.688)" width="9.38" x="-4.69" xlink:href="#fi213-b" y="-60"/><use height="120" overflow="visible" transform="translate(-14.063)" width="9.38" x="-4.69" xlink:href="#fi213-b" y="-60"/><use height="120" overflow="visible" transform="translate(-23.438)" width="9.38" x="-4.69" xlink:href="#fi213-b" y="-60"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60.05 72v75c0 27.61 22.38 50 50 50 27.61 0 50-22.38 50-49.99V72h-100z" id="fi213-c"/></defs><clipPath id="fi213-d"><use overflow="visible" xlink:href="#fi213-c"/></clipPath><g clip-path="url(#fi213-d)"><use height="120" overflow="visible" transform="matrix(1 0 0 -1 85 132)" width="56.25" x="-28.12" xlink:href="#fi213-e" y="-60"/><use height="120" overflow="visible" transform="matrix(1 0 0 -1 141.25 132)" width="56.25" x="-28.12" xlink:href="#fi213-e" y="-60"/></g>'
                    )
                )
            );
    }

    function field_214(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Rasterlines Barry and Bendy Sinister',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi214-c" viewBox="-28.5 -6 56.9 12"><use height="12" transform="translate(-12.518)" width="31.9" x="-15.9" xlink:href="#fi214-a" y="-6"/><use height="12" transform="matrix(-1 0 -.2607 -1 10.945 0)" width="31.9" x="-15.9" xlink:href="#fi214-a" y="-6"/></symbol><symbol id="fi214-b" viewBox="-5 -6 10 12"><path d="M5 6H1.9L-5-6 5 6z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi214-a" viewBox="-15.9 -6 31.9 12"><use height="12" transform="translate(-10.941)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(-7.815)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(-4.689)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(-1.563)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(1.563)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(4.689)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(7.815)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/><use height="12" transform="translate(10.941)" width="10" x="-5" xlink:href="#fi214-b" y="-6"/></symbol><symbol id="fi214-d" viewBox="-103.5 -6 207 12"><use height="12" transform="translate(-25.015)" width="56.9" x="-28.5" xlink:href="#fi214-c" y="-6"/><use height="12" transform="translate(-75.053)" width="56.9" x="-28.5" xlink:href="#fi214-c" y="-6"/><use height="12" transform="translate(25.023)" width="56.9" x="-28.5" xlink:href="#fi214-c" y="-6"/><use height="12" transform="translate(75.061)" width="56.9" x="-28.5" xlink:href="#fi214-c" y="-6"/></symbol><symbol id="fi214-g" viewBox="-123.5 -42 247.1 72"><use height="12" transform="translate(20.014 24)" width="207" x="-103.5" xlink:href="#fi214-d" y="-6"/><use height="12" transform="translate(20.014 -36)" width="207" x="-103.5" xlink:href="#fi214-d" y="-6"/><use height="12" transform="translate(10.007 12)" width="207" x="-103.5" xlink:href="#fi214-d" y="-6"/><use height="12" width="207" x="-103.5" xlink:href="#fi214-d" y="-6"/><use height="12" transform="translate(-10.007 -12)" width="207" x="-103.5" xlink:href="#fi214-d" y="-6"/><use height="12" transform="translate(-20.014 -24)" width="207" x="-103.5" xlink:href="#fi214-d" y="-6"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" id="fi214-e"/></defs><clipPath id="fi214-f"><use xlink:href="#fi214-e"/></clipPath><g clip-path="url(#fi214-f)"><use height="72" transform="matrix(1 0 0 -1 111.563 102)" width="247.1" x="-123.5" xlink:href="#fi214-g" y="-42"/><use height="72" transform="matrix(1 0 0 -1 111.563 162)" width="247.1" x="-123.5" xlink:href="#fi214-g" y="-42"/></g>'
                    )
                )
            );
    }

    function field_215(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Rasterlines Barry-X',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi215-d"><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="none"/></clipPath><clipPath id="fi215-e"><path d="M60 70.847 84.931 72l1 .272L110 72.271V144H60V70.847z" fill="none"/></clipPath><clipPath id="fi215-g"><path d="M160 70.847 135.069 72l-1 .272L110 72.271V144h50V70.847z" fill="none"/></clipPath><clipPath id="fi215-h"><path d="M110 120h50v92h-50z" fill="none"/></clipPath><clipPath id="fi215-i"><path d="M60 120h50v92H60z" fill="none" transform="rotate(180 85 166)"/></clipPath><symbol id="fi215-a" viewBox="0 0 10.009 12"><path d="M0 12h3.128l6.881-12L0 12z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi215-b" viewBox="0 0 31.905 12"><use height="12" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(3.128)" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(6.256)" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(9.384)" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(12.512)" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(15.64)" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(18.768)" width="10.009" xlink:href="#fi215-a"/><use height="12" transform="translate(21.896)" width="10.009" xlink:href="#fi215-a"/></symbol><symbol id="fi215-c" viewBox="0 0 60.056 12"><use height="12" width="31.905" xlink:href="#fi215-b"/><use height="12" transform="matrix(-1 0 .261 -1 56.928 12)" width="31.905" xlink:href="#fi215-b"/></symbol><symbol id="fi215-f" viewBox="0 0 110.102 73.09"><path d="M10.009 60 2.5 73.09 0 72ZM3.128 72l2.5 1.09L13.137 60Zm3.128 0 2.5 1.09L16.265 60Zm3.128 0 2.5 1.09L19.393 60Zm3.128 0 2.5 1.09L22.521 60Zm3.128 0 2.5 1.09L25.649 60Zm3.128 0 2.5 1.09L28.777 60Zm3.132 0 2.5 1.09L31.905 60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><use height="12" transform="translate(10.009 48)" width="60.056" xlink:href="#fi215-c"/><use height="12" transform="translate(20.018 36)" width="60.056" xlink:href="#fi215-c"/><use height="12" transform="translate(30.028 24)" width="60.056" xlink:href="#fi215-c"/><use height="12" transform="translate(40.037 12)" width="60.056" xlink:href="#fi215-c"/><use height="12" transform="translate(50.046)" width="60.056" xlink:href="#fi215-c"/><use height="12" transform="matrix(-1 0 .261 -1 56.928 72)" width="31.905" xlink:href="#fi215-b"/></symbol><symbol id="fi215-j" viewBox="0 0 18.86 57.185"><path d="m9.43 26.306.845-.686-.845 1.734-.845-1.734Zm0-4.485 2.784-5.377-2.784 2.361-2.784-2.361ZM18.86 0 9.43 11.305 0 0l9.43 12ZM1.251 24 9.43 34.328 17.609 24 9.43 33.805Zm8.179 7.471L14.481 24 9.43 30.055 4.379 24Zm0 8.571L10.727 36l-1.3 1.555L8.133 36ZM1.877 36l7.553 9.756L16.983 36 9.43 45.055Zm8.285 0H8.7l.732 1.185Zm-.732 6.9 4.425-6.9-4.425 5.305L5.005 36Zm1.5-29.314-1.5 1.47-1.5-1.47 1.5 2.859Zm-.171-10.555-1.329.774-1.33-.774 1.329 2.5Zm2.049 1.346L9.43 7.555 6.052 4.377 9.43 10.99ZM9.43 51.471 10.1 48l-.672.806-.67-.806ZM9.78 48h-.7l.35.614Zm-.35 6.328L13.23 48l-3.8 4.556L5.63 48ZM2.5 48l6.93 9.185L16.358 48 9.43 56.306Zm6.976-24 3.724-4.357-3.77 2.912-3.774-2.912Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol></defs><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi215-d)"><g clip-path="url(#fi215-e)"><use height="73.09" transform="matrix(-1 0 0 1 110 60.001)" width="110.102" xlink:href="#fi215-f"/><use height="73.09" transform="matrix(-1 0 0 1 160 60.001)" width="110.102" xlink:href="#fi215-f"/></g><g clip-path="url(#fi215-g)"><use height="73.09" transform="translate(110 60.001)" width="110.102" xlink:href="#fi215-f"/><use height="73.09" transform="translate(60 60.001)" width="110.102" xlink:href="#fi215-f"/></g><g clip-path="url(#fi215-h)"><use height="73.09" transform="matrix(1 0 0 -1 110 203.999)" width="110.102" xlink:href="#fi215-f"/><use height="73.09" transform="matrix(1 0 0 -1 60 203.999)" width="110.102" xlink:href="#fi215-f"/></g><g clip-path="url(#fi215-i)"><use height="73.09" transform="rotate(180 55 102)" width="110.102" xlink:href="#fi215-f"/><use height="73.09" transform="rotate(180 80 102)" width="110.102" xlink:href="#fi215-f"/></g></g><use height="57.185" transform="translate(100.57 72)" width="18.86" xlink:href="#fi215-j"/><use height="57.185" transform="matrix(1 0 0 -1 100.57 192)" width="18.86" xlink:href="#fi215-j"/>'
                    )
                )
            );
    }

    function field_216(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny Wavy II',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi216-a" viewBox="-43.78 -28.69 67.05 68.02"><path d="M23.26-28.26c-2.21-.08-4.42-.15-6.03 1.76-3.21 3.83 1.83 8.65-1.38 12.48s-8.84-.3-12.05 3.53S5.64-1.85 2.43 1.98c-3.22 3.83-8.84-.3-12.05 3.53s1.83 8.65-1.38 12.48-9.96-3.67-12.05 3.53c-14.55 50.21-36.38-23.08-3.68-9.84 2.69 1.09 5.72 1.77 8.22-.33 3.83-3.21-.3-8.84 3.53-12.05 3.83-3.21 8.65 1.83 12.48-1.38s-.3-8.84 3.53-12.05 8.65 1.83 12.48-1.38-.3-8.84 3.53-12.05c1.9-1.62 4.06-1.16 6.22-.7" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi216-b" viewBox="-48.26 -30.89 82.02 69.36"><use height="68.02" overflow="visible" transform="translate(10.49 -.852)" width="67.05" x="-43.78" xlink:href="#fi216-a" y="-28.69"/><use height="68.02" overflow="visible" transform="rotate(19.999 30.923 1.061)" width="67.05" x="-43.78" xlink:href="#fi216-a" y="-28.69"/></symbol><symbol id="fi216-e" viewBox="-51.33 -53.38 89.81 102.63"><use height="69.36" overflow="visible" transform="translate(4.726 10.777)" width="82.02" x="-48.26" xlink:href="#fi216-b" y="-30.89"/><use height="69.36" overflow="visible" transform="rotate(40.002 21.31 -17.23)" width="82.02" x="-48.26" xlink:href="#fi216-b" y="-30.89"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi216-c"/></defs><clipPath id="fi216-d"><use overflow="visible" xlink:href="#fi216-c"/></clipPath><g clip-path="url(#fi216-d)"><use height="102.63" overflow="visible" transform="matrix(1 0 0 -1 71.522 113.667)" width="89.81" x="-51.33" xlink:href="#fi216-e" y="-53.38"/><use height="102.63" overflow="visible" transform="scale(1 -1) rotate(80.003 141.968 -32.551)" width="89.81" x="-51.33" xlink:href="#fi216-e" y="-53.38"/><use height="102.63" overflow="visible" transform="scale(-1 1) rotate(-19.999 390.56 477.889)" width="89.81" x="-51.33" xlink:href="#fi216-e" y="-53.38"/><use height="102.63" overflow="visible" transform="scale(-1 1) rotate(60 -165.958 -71.756)" width="89.81" x="-51.33" xlink:href="#fi216-e" y="-53.38"/><use height="102.63" overflow="visible" transform="scale(1 -1) rotate(-40.002 -81.904 -173.416)" width="89.81" x="-51.33" xlink:href="#fi216-e" y="-53.38"/></g>'
                    )
                )
            );
    }

    function field_217(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Hypno',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi217-a"><path d="M60 72v75a50 50 0 0 0 49.99 50h.01a50 50 0 0 0 50-49.99V76.03L156.46 72Z" fill="none"/></clipPath><symbol id="fi217-b" viewBox="0 0 141.29 180.93"><path d="M75.48 1.84c27.38 11.64 48 33.91 57.5 58.67s7.85 51.6-2.09 72.65-27.93 36.1-47.02 42.31-38.95 3.67-53.68-4.58-24.18-21.95-27.13-35.37.52-26.3 7.08-34.7 15.97-12.29 23.72-11.95 13.65 4.7 15.74 9.58.37 10-3.24 12.07" fill="none" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke-width="4"/></symbol></defs><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi217-a)"><use height="180.93" transform="translate(63.24 36.31) scale(1.009)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(-29.99 146.13 10.83) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(-60 109.82 74.08) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(-90 96.54 97.23) scale(1.009)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(-120 88.86 110.59) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(-150.01 83.24 120.37) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(180 78.38 128.84) scale(1.009)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(150.01 73.52 137.32) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(120 67.9 147.1) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(90 60.23 160.46) scale(1.009)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(60 46.93 183.6) scale(1.008)" width="141.29" xlink:href="#fi217-b"/><use height="180.93" transform="rotate(29.99 10.61 246.85) scale(1.008)" width="141.29" xlink:href="#fi217-b"/></g>'
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