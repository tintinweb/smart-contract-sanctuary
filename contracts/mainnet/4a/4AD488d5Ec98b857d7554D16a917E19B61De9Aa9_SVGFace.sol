// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library SVGFace {
    function pickSVGFaceName(uint256 face) public pure returns (string memory) {
        string memory name = "";
        if (face <= 50) {
            name = "Happy";
        } else if (face <= 90) {
            name = "Joyful";
        } else if (face <= 120) {
            name = "Surprised";
        } else if (face <= 140) {
            name = "Tired";
        } else if (face <= 160) {
            name = "Angry";
        } else if (face <= 170) {
            name = "Uh-oh";
        } else if (face <= 180) {
            name = "Sad";
        } else if (face <= 190) {
            name = "Dead";
        } else if (face <= 198) {
            name = "Uwu";
        } else if (face == 199) {
            name = "BSOD";
        } else {
            // face == 200.
            name = "Off";
        }

        return string(abi.encodePacked(name));
    }

    function pickSVGFacePath(uint256 face) public pure returns (string memory) {
        string memory path = "";
        if (face <= 50) {
            // Face: :)
            path = '<path fill="#fff" d="M392 334h35v71h-35v-71zM534 334h35v71h-35v-71zM391.571 440.714H356v35.572h35.571v-35.572zM569 476H392v36h177v-36zM569.428 440.714h35.571v35.572h-35.571v-35.572z"/>';
        } else if (face <= 90) {
            // Face: ^_^
            path = '<path fill="#fff" d="M427.142 334H391.57v35.571h35.572V334zM391.571 369.572H356v35.571h35.571v-35.571zM427.142 369.571l35.572.001v35.571h-35.571l-.001-35.572zM533.857 369.572h-35.572v35.571h35.572v-35.571zM392 476h35v36h107v-36h35v-35H392v35zM569.427 334h-35.572v35.571h35.572V334zM604.999 369.572l-35.572-.001.001 35.572h35.571v-35.571z"/>';
        } else if (face <= 120) {
            // Face: :o
            path = '<path fill="#fff" d="M391 334h35.571v35.571H391V334zM427 405h106v107H427V405zM568.857 334h-35.572v35.571h35.572V334z"/>';
        } else if (face <= 140) {
            // Face: -_-
            path = '<path fill="#fff" d="M391 370h35.571v35.571H391V370zM426.857 440.857h106v36h-106v-36zM568.857 370h-35.572v35.571h35.572V370z"/>';
        } else if (face <= 160) {
            // Face: >_<
            path = '<path fill="#fff" d="M356 352h35.571v35.571h35.571v35.572h-35.571v35.571H356v-35.571h35.57v-35.572H356V352zM427 459h107v35H427v-35zM569.427 387.571h-35.572v35.572h35.572v-35.572zM569.428 352h35.571v35.571h-35.572l.001-35.571zM604.999 423.143h-35.572l.001 35.571h35.571v-35.571z"/>';
        } else if (face <= 170) {
            // Face: ._.
            path = '<path fill="#fff" d="M568.429 452h-35.572v35.571h35.572V452zM391 452.286h35.571v35.571H391v-35.571zM462.143 487.857h35.571v35.571h-35.571v-35.571z"/>';
        } else if (face <= 180) {
            // Face: :(
            path = '<path fill="#fff" d="M392 334h35v71h-35v-71zM356 476.286h35.571v35.571H356v-35.571zM569 334h-35v71h35v-71zM392 440h177v36H392v-36zM604.999 476.286h-35.571v35.571h35.571v-35.571z"/>';
        } else if (face <= 190) {
            // Face: x_x
            path = '<path fill="#fff" d="M356 334h35.571v35.571H356V334zM391.571 405.143h35.571v-35.571H391.57v35.571H356v35.571h35.571v-35.571z"/><path fill="#fff" d="M427.142 405.143h35.572v35.571h-35.571l-.001-35.571zM533.857 334h-35.572v35.571h35.572V334zM498.285 405.143h35.57v-35.571h35.572v35.571h-35.57v35.571h-35.572v-35.571zM534 476H427v36h107v-36zM604.999 334h-35.571l-.001 35.572 35.572-.001V334zM569.427 405.143h35.572v35.571h-35.571l-.001-35.571zM462.714 334h-35.571l-.001 35.572 35.572-.001V334z"/>';
        } else if (face <= 198) {
            // Face: :3
            path = '<path fill="#fff" d="M391 334h36v71h-36v-71zM533 334h36v71h-36v-71zM426.571 440.714H391v35.572h35.571v-35.572zM497.714 476.286h-35.57v35.571h-35.572l-.001-35.571h35.572v-35.572h35.571v35.572z"/><path fill="#fff" d="M568.857 476.286h-35.571v35.571h-35.571l-.001-35.571h35.571v-35.572h35.572v35.572z"/>';
        } else if (face == 199) {
            // Face: BSOD
            path = '<path fill="#0000A3" d="M668.671 278.105H291v283.254h377.671V278.105z" class="BG"/><path fill="#AAA" d="M420 357h120v27H420z" /><path fill="#fff" d="M322 407h120v9H322v-9zM322 423h196v9H322v-9zM592 439H322v9h270v-9zM322 455h70v9h-70v-9zM540 496H420v9h120v-9z"/>';
        }

        return string(abi.encodePacked(path));
    }
}