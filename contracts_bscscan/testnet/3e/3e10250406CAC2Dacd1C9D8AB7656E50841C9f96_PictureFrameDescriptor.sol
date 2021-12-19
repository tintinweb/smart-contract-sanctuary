// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PictureFrameDescriptor {

  function getSVG() public pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<linearGradient id="LG_PF_1" gradientUnits="userSpaceOnUse" x1="297.0556" y1="547.687" x2="279.3617" y2="238.0428"> ',
        '<stop offset="0" style="stop-color:#FCFCFC;stop-opacity:0.9865"/> ',
        '<stop offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop offset="1" style="stop-color:#FFFFFF;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#LG_PF_1);" d="M0,619.68l53.7-54.2h459.24',
        'l53.99-54.2V308.09l0-308.09C389.23,0,412.18,0,0,0L0,619.68z"/> ',
        '<linearGradient id="LG_PF_2" gradientUnits="userSpaceOnUse" ',
        'x1="283.4646" y1="935.433" x2="283.4646" y2="4.277267e-05"> ',
        '<stop offset="0.1902" style="stop-color:#000000"/> ',
        '<stop offset="0.3813" style="stop-color:#000000;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#LG_PF_2); opacity:0.5;" d="M525.58,0H41.35C18.51,0,0,18.51,0,41.35',
        'v852.74c0,22.83,18.51,41.35,41.35,41.35h484.24c22.83,0,41.35-18.51,41.35-41.35V596.75v-80.71V41.35',
        'C566.93,18.51,548.42,0,525.58,0z"/> ',
        '<linearGradient id="LG_PF_3" gradientUnits="userSpaceOnUse" ',
        'x1="283.4646" y1="935.433" x2="283.4646" y2="4.277267e-05"> ',
        '<stop offset="0.1902" style="stop-color:#000000"/> ',
        '<stop offset="1" style="stop-color:#000000;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#LG_PF_3); opacity:0.5;" d="M525.58,0H41.35C18.51,0,0,18.51,0,41.35',
        'v852.74c0,22.83,18.51,41.35,41.35,41.35h484.24c22.83,0,41.35-18.51,41.35-41.35V596.75v-80.71V41.35',
        'C566.93,18.51,548.42,0,525.58,0z M546.78,531.49l-34.26,33.93H54.26L20,599.68V54.56C20,35.47,35.47,20,54.56,20h115.64',
        'l27.88,18.25h171.68L397.64,20h112.68c9.75,0,19.07,3.99,25.79,11.05v0c6.3,6.61,9.82,15.39,9.84,24.52L546.78,531.49z"/> ',
        '<path style="fill:none;stroke:#FFFFFF;stroke-width:0.5;stroke-miterlimit:10;" d="M13.11,54.36v835.56',
        'c0,18.25,14.79,33.04,33.04,33.04h474.64c18.25,0,33.04-17.11,33.04-35.36V54.36',
        'c0-24.05-19.5-43.55-43.55-43.55H56.66C32.61,10.81,13.11,30.3,13.11,54.36z"/> ',
        '<polygon style="fill:#1D1D1B;stroke:#FFFFFF;stroke-width:0.5;stroke-miterlimit:10;" ',
        'points="227.76,10.41 227.76,0 340.86,0 340.86,10.41 326.65,19.45 241.58,19.45"/> ',
        '<linearGradient id="LG_PF_2" gradientUnits="userSpaceOnUse" x1="297.0556" y1="547.687" x2="279.3617" y2="238.0428"> ',
        '<stop  offset="0" style="stop-color:#FCFCFC;stop-opacity:0.9865"/> ',
        '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop  offset="1" style="stop-color:#FFFFFF;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.8;fill:url(#LG_PF_2);" d="M0,619.68l53.7-54.2h459.24',
        'l53.99-54.2V308.09l0-308.09C389.23,0,412.18,0,0,0L0,619.68z"/>'
    )
    );
  }
}