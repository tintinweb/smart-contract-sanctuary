// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

library FROSvg {
    using Strings for uint256;

    function weaponSvg(uint8 weapon) external pure returns(string memory){

        if(weapon == 1){ // axe
            return '<style>.w1{fill:#333;}.w2{fill:#999;}.w3{fill:#000;}</style><rect x="20" y="60" class="s w2"/><rect x="30" y="60" class="s w2"/><rect x="50" y="60" class="s w2"/><rect x="60" y="60" class="s w2"/><rect x="70" y="60" class="s w2"/><rect x="80" y="60" class="s w2"/><rect x="20" y="70" class="s w2"/><rect x="30" y="70" class="s w1"/><rect x="40" y="70" class="s w1"/><rect x="50" y="70" class="s w1"/><rect x="60" y="70" class="s w1"/><rect x="70" y="70" class="s w1"/><rect x="80" y="70" class="s w1"/><rect x="90" y="70" class="s w2"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="70" y="80" class="s w1"/><rect x="80" y="80" class="s w1"/><rect x="90" y="80" class="s w2"/><rect x="20" y="90" class="s w2"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w1"/><rect x="50" y="90" class="s w1"/><rect x="60" y="90" class="s w1"/><rect x="80" y="90" class="s w1"/><rect x="90" y="90" class="s w2"/><rect x="20" y="100" class="s w2"/><rect x="30" y="100" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w1"/><rect x="70" y="100" class="s w1"/><rect x="90" y="100" class="s w2"/><rect x="20" y="110" class="s w2"/><rect x="30" y="110" class="s w1"/><rect x="40" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w1"/><rect x="80" y="110" class="s w1"/><rect x="20" y="120" class="s w2"/><rect x="30" y="120" class="s w1"/><rect x="40" y="120" class="s w1"/><rect x="50" y="120" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w1"/><rect x="90" y="120" class="s w1"/><rect x="30" y="130" class="s w2"/><rect x="40" y="130" class="s w2"/><rect x="50" y="130" class="s w2"/><rect x="60" y="130" class="s w2"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w1"/><rect x="110" y="140" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w1"/><rect x="120" y="150" class="s w1"/><rect x="130" y="150" class="s w3"/><rect x="140" y="150" class="s w3"/><rect x="110" y="160" class="s w1"/><rect x="120" y="160" class="s w1"/><rect x="110" y="170" class="s w3"/>';

        }else if(weapon == 2){ // glove
            return '<style>.w1{fill:#000;}.w2{fill:#43A;}.w3{fill:#53C;}</style><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w1"/><rect x="110" y="130" class="s w1"/><rect x="70" y="140" class="s w1"/><rect x="80" y="140" class="s w2"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w2"/><rect x="120" y="140" class="s w1"/><rect x="130" y="140" class="s w1"/><rect x="70" y="150" class="s w1"/><rect x="80" y="150" class="s w2"/><rect x="90" y="150" class="s w2"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w2"/><rect x="140" y="150" class="s w1"/><rect x="70" y="160" class="s w1"/><rect x="80" y="160" class="s w2"/><rect x="90" y="160" class="s w2"/><rect x="100" y="160" class="s w3"/><rect x="110" y="160" class="s w3"/><rect x="120" y="160" class="s w2"/><rect x="130" y="160" class="s w2"/><rect x="140" y="160" class="s w2"/><rect x="70" y="170" class="s w1"/><rect x="80" y="170" class="s w2"/><rect x="90" y="170" class="s w2"/><rect x="100" y="170" class="s w3"/><rect x="110" y="170" class="s w2"/><rect x="120" y="170" class="s w2"/><rect x="130" y="170" class="s w2"/><rect x="140" y="170" class="s w2"/><rect x="70" y="180" class="s w1"/><rect x="80" y="180" class="s w2"/><rect x="90" y="180" class="s w2"/><rect x="100" y="180" class="s w2"/><rect x="110" y="180" class="s w2"/><rect x="120" y="180" class="s w2"/><rect x="130" y="180" class="s w2"/><rect x="140" y="180" class="s w2"/><rect x="70" y="190" class="s w1"/><rect x="80" y="190" class="s w1"/><rect x="90" y="190" class="s w2"/><rect x="100" y="190" class="s w2"/><rect x="110" y="190" class="s w2"/><rect x="120" y="190" class="s w2"/><rect x="130" y="190" class="s w1"/><rect x="140" y="190" class="s w1"/><rect x="90" y="200" class="s w1"/><rect x="100" y="200" class="s w1"/><rect x="110" y="200" class="s w1"/><rect x="120" y="200" class="s w1"/>';

        }else if(weapon == 3){// sword
            return '<style>.w1{fill:#000;}.w2{fill:#36C;}</style><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="40" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w2"/><rect x="40" y="70" class="s w1"/><rect x="50" y="70" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w2"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w1"/><rect x="50" y="90" class="s w2"/><rect x="60" y="90" class="s w1"/><rect x="70" y="90" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w2"/><rect x="70" y="100" class="s w1"/><rect x="80" y="100" class="s w1"/><rect x="50" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w2"/><rect x="80" y="110" class="s w1"/><rect x="90" y="110" class="s w1"/><rect x="60" y="120" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w2"/><rect x="90" y="120" class="s w1"/><rect x="100" y="120" class="s w1"/><rect x="70" y="130" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w1"/><rect x="110" y="130" class="s w1"/><rect x="130" y="130" class="s w1"/><rect x="140" y="130" class="s w1"/><rect x="80" y="140" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w1"/><rect x="120" y="140" class="s w1"/><rect x="130" y="140" class="s w2"/><rect x="140" y="140" class="s w1"/><rect x="90" y="150" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w1"/><rect x="100" y="160" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="90" y="170" class="s w1"/><rect x="100" y="170" class="s w2"/><rect x="110" y="170" class="s w1"/><rect x="90" y="180" class="s w1"/><rect x="100" y="180" class="s w1"/>';

        }else if(weapon == 4){// katana
            return '<style>.w1{fill:#000;}.w2{fill:#BCC;}.w3{fill:#677;}</style><rect x="20" y="50" class="s w2"/><rect x="20" y="60" class="s w2"/><rect x="30" y="60" class="s w3"/><rect x="20" y="70" class="s w2"/><rect x="30" y="70" class="s w3"/><rect x="40" y="70" class="s w3"/><rect x="30" y="80" class="s w2"/><rect x="40" y="80" class="s w3"/><rect x="50" y="80" class="s w3"/><rect x="40" y="90" class="s w2"/><rect x="50" y="90" class="s w3"/><rect x="60" y="90" class="s w3"/><rect x="50" y="100" class="s w2"/><rect x="60" y="100" class="s w3"/><rect x="70" y="100" class="s w3"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w3"/><rect x="80" y="110" class="s w3"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w3"/><rect x="90" y="120" class="s w3"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w3"/><rect x="100" y="130" class="s w3"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w3"/><rect x="110" y="140" class="s w3"/><rect x="130" y="140" class="s w1"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w3"/><rect x="120" y="150" class="s w3"/><rect x="130" y="150" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="100" y="170" class="s w1"/><rect x="110" y="170" class="s w1"/>';

        }else if(weapon == 5){// blade
            return '<style>.w1{fill:#000;}.w2{fill:#812;}</style><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="40" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w2"/><rect x="40" y="70" class="s w2"/><rect x="50" y="70" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w2"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w2"/><rect x="60" y="80" class="s w1"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w2"/><rect x="50" y="90" class="s w1"/><rect x="60" y="90" class="s w2"/><rect x="70" y="90" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w2"/><rect x="60" y="100" class="s w1"/><rect x="70" y="100" class="s w2"/><rect x="80" y="100" class="s w1"/><rect x="50" y="110" class="s w1"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w1"/><rect x="80" y="110" class="s w2"/><rect x="90" y="110" class="s w1"/><rect x="60" y="120" class="s w1"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w1"/><rect x="90" y="120" class="s w2"/><rect x="100" y="120" class="s w1"/><rect x="70" y="130" class="s w1"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w2"/><rect x="110" y="130" class="s w1"/><rect x="130" y="130" class="s w1"/><rect x="140" y="130" class="s w1"/><rect x="80" y="140" class="s w1"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w1"/><rect x="110" y="140" class="s w2"/><rect x="120" y="140" class="s w1"/><rect x="130" y="140" class="s w2"/><rect x="140" y="140" class="s w1"/><rect x="90" y="150" class="s w1"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w1"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w1"/><rect x="100" y="160" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="90" y="170" class="s w1"/><rect x="100" y="170" class="s w2"/><rect x="110" y="170" class="s w1"/><rect x="90" y="180" class="s w1"/><rect x="100" y="180" class="s w1"/>';

        }else if(weapon == 6){// lance
            return '<style>.w1{fill:#034;}.w2{fill:#000;}.w3{fill:#C22;}</style><rect x="10" y="50" class="s w1"/><rect x="20" y="50" class="s w1"/><rect x="40" y="50" class="s w1"/><rect x="50" y="50" class="s w1"/><rect x="10" y="60" class="s w1"/><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="50" y="60" class="s w1"/><rect x="60" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w1"/><rect x="40" y="70" class="s w1"/><rect x="60" y="70" class="s w1"/><rect x="70" y="70" class="s w1"/><rect x="10" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="10" y="90" class="s w1"/><rect x="20" y="90" class="s w1"/><rect x="40" y="90" class="s w1"/><rect x="50" y="90" class="s w3"/><rect x="60" y="90" class="s w1"/><rect x="20" y="100" class="s w1"/><rect x="30" y="100" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w1"/><rect x="70" y="100" class="s w1"/><rect x="30" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w1"/><rect x="80" y="110" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w1"/><rect x="90" y="120" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w1"/><rect x="110" y="140" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w1"/><rect x="120" y="150" class="s w1"/><rect x="130" y="150" class="s w2"/><rect x="140" y="150" class="s w2"/><rect x="110" y="160" class="s w1"/><rect x="120" y="160" class="s w2"/><rect x="110" y="170" class="s w2"/>';

        }else if(weapon == 7){// wand
            return '<style>.w1{fill:#520;}.w2{fill:#C2E}</style><rect x="10" y="80" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="10" y="90" class="s w1"/><rect x="60" y="90" class="s w1"/><rect x="10" y="100" class="s w1"/><rect x="30" y="100" class="s w2"/><rect x="40" y="100" class="s w1"/><rect x="60" y="100" class="s w1"/><rect x="10" y="110" class="s w1"/><rect x="40" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w1"/><rect x="10" y="120" class="s w1"/><rect x="20" y="120" class="s w1"/><rect x="30" y="120" class="s w1"/><rect x="40" y="120" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w1"/><rect x="130" y="150" class="s" fill="#000"/><rect x="140" y="150" class="s" fill="#000"/><rect x="110" y="160" class="s w1"/><rect x="120" y="160" class="s" fill="#000"/><rect x="110" y="170" class="s" fill="#000"/>';
    
        }else if(weapon == 8){// rod
            return '<style>.w1{fill:#C22;}.w2{fill:#114;}.w3{fill:#000;}</style><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="40" y="60" class="s w1"/><rect x="50" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w1"/><rect x="40" y="70" class="s w1"/><rect x="50" y="70" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w2"/><rect x="50" y="80" class="s w2"/><rect x="20" y="90" class="s w1"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w2"/><rect x="50" y="90" class="s w2"/><rect x="60" y="90" class="s w2"/><rect x="50" y="100" class="s w2"/><rect x="60" y="100" class="s w2"/><rect x="70" y="100" class="s w2"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w2"/><rect x="80" y="110" class="s w2"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w2"/><rect x="90" y="120" class="s w2"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w2"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w2"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w3"/><rect x="140" y="150" class="s w3"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w3"/><rect x="110" y="170" class="s w3"/>';

        }else if(weapon == 9){// dagger
            return '<style>.w1{fill:#000;}.w2{fill:#E72;}</style><rect x="50" y="90" class="s w1"/><rect x="60" y="90" class="s w1"/><rect x="70" y="90" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w2"/><rect x="70" y="100" class="s w2"/><rect x="80" y="100" class="s w1"/><rect x="50" y="110" class="s w1"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w2"/><rect x="80" y="110" class="s w2"/><rect x="90" y="110" class="s w1"/><rect x="60" y="120" class="s w1"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w2"/><rect x="90" y="120" class="s w2"/><rect x="100" y="120" class="s w1"/><rect x="70" y="130" class="s w1"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w2"/><rect x="110" y="130" class="s w1"/><rect x="80" y="140" class="s w1"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w2"/><rect x="120" y="140" class="s w1"/><rect x="90" y="150" class="s w1"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w1"/><rect x="140" y="150" class="s w1"/><rect x="100" y="160" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="110" y="170" class="s w1"/>';

        }else if(weapon == 10){// shuriken
            return '<style>.w1{fill:#000;}.w2{fill:#19A;}</style><rect x="20" y="110" class="s w1"/><rect x="30" y="110" class="s w1"/><rect x="40" y="110" class="s w1"/><rect x="100" y="110" class="s w1"/><rect x="110" y="110" class="s w1"/><rect x="120" y="110" class="s w1"/><rect x="20" y="120" class="s w1"/><rect x="30" y="120" class="s w2"/><rect x="40" y="120" class="s w2"/><rect x="50" y="120" class="s w1"/><rect x="90" y="120" class="s w1"/><rect x="100" y="120" class="s w2"/><rect x="110" y="120" class="s w2"/><rect x="120" y="120" class="s w1"/><rect x="20" y="130" class="s w1"/><rect x="30" y="130" class="s w2"/><rect x="40" y="130" class="s w2"/><rect x="50" y="130" class="s w2"/><rect x="60" y="130" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w2"/><rect x="110" y="130" class="s w2"/><rect x="120" y="130" class="s w1"/><rect x="30" y="140" class="s w1"/><rect x="40" y="140" class="s w2"/><rect x="50" y="140" class="s w2"/><rect x="60" y="140" class="s w2"/><rect x="70" y="140" class="s w1"/><rect x="80" y="140" class="s w2"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w1"/><rect x="40" y="150" class="s w1"/><rect x="50" y="150" class="s w2"/><rect x="60" y="150" class="s w2"/><rect x="70" y="150" class="s w2"/><rect x="80" y="150" class="s w2"/><rect x="90" y="150" class="s w2"/><rect x="100" y="150" class="s w1"/><rect x="130" y="150" class="s w1"/><rect x="140" y="150" class="s w1"/><rect x="50" y="160" class="s w1"/><rect x="60" y="160" class="s w2"/><rect x="70" y="160" class="s w1"/><rect x="80" y="160" class="s w2"/><rect x="90" y="160" class="s w1"/><rect x="120" y="160" class="s w1"/><rect x="40" y="170" class="s w1"/><rect x="50" y="170" class="s w2"/><rect x="60" y="170" class="s w2"/><rect x="70" y="170" class="s w2"/><rect x="80" y="170" class="s w2"/><rect x="90" y="170" class="s w2"/><rect x="100" y="170" class="s w1"/><rect x="110" y="170" class="s w1"/><rect x="30" y="180" class="s w1"/><rect x="40" y="180" class="s w2"/><rect x="50" y="180" class="s w2"/><rect x="60" y="180" class="s w2"/><rect x="70" y="180" class="s w1"/><rect x="80" y="180" class="s w2"/><rect x="90" y="180" class="s w2"/><rect x="100" y="180" class="s w2"/><rect x="110" y="180" class="s w1"/><rect x="20" y="190" class="s w1"/><rect x="30" y="190" class="s w2"/><rect x="40" y="190" class="s w2"/><rect x="50" y="190" class="s w2"/><rect x="60" y="190" class="s w1"/><rect x="80" y="190" class="s w1"/><rect x="90" y="190" class="s w2"/><rect x="100" y="190" class="s w2"/><rect x="110" y="190" class="s w2"/><rect x="120" y="190" class="s w1"/><rect x="20" y="200" class="s w1"/><rect x="30" y="200" class="s w2"/><rect x="40" y="200" class="s w2"/><rect x="50" y="200" class="s w1"/><rect x="90" y="200" class="s w1"/><rect x="100" y="200" class="s w2"/><rect x="110" y="200" class="s w2"/><rect x="120" y="200" class="s w1"/><rect x="20" y="210" class="s w1"/><rect x="30" y="210" class="s w1"/><rect x="40" y="210" class="s w1"/><rect x="100" y="210" class="s w1"/><rect x="110" y="210" class="s w1"/><rect x="120" y="210" class="s w1"/>';
        }
        
        return "";
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