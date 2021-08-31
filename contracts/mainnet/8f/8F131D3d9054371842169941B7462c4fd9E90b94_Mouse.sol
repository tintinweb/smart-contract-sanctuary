// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;
import './IAnimalSVG.sol';

contract Mouse is IAnimalSVG {
    function svg(string memory eyes) external override pure returns (string memory){
        return string(
            abi.encodePacked(
                	'<rect x="0" y="0" class="c4 s"/>',
                    '<rect x="1" y="0" class="c1 s"/>',
                    '<rect x="2" y="0" class="c1 s"/>',
                    '<rect x="3" y="0" class="c4 s"/>',
                    '<rect x="4" y="0" class="c4 s"/>',
                    '<rect x="5" y="0" class="c4 s"/>',
                    '<rect x="6" y="0" class="c4 s"/>',
                    '<rect x="7" y="0" class="c1 s"/>',
                    '<rect x="8" y="0" class="c1 s"/>',
                    '<rect x="9" y="0" class="c4 s"/>',

                    '<rect x="0" y="1" class="c1 s"/>',
                    '<rect x="1" y="1" class="c1 s"/>',
                    '<rect x="2" y="1" class="c1 s"/>',
                    '<rect x="3" y="1" class="c1 s"/>',
                    '<rect x="4" y="1" class="c4 s"/>',
                    '<rect x="5" y="1" class="c4 s"/>',
                    '<rect x="6" y="1" class="c1 s"/>',
                    '<rect x="7" y="1" class="c1 s"/>',
                    '<rect x="8" y="1" class="c1 s"/>',
                    '<rect x="9" y="1" class="c1 s"/>',

                    '<rect x="0" y="2" class="c1 s"/>',
                    '<rect x="1" y="2" class="c1 s"/>',
                    '<rect x="2" y="2" class="c1 s"/>',
                    '<rect x="3" y="2" class="c1 s"/>',
                    '<rect x="4" y="2" class="c4 s"/>',
                    '<rect x="5" y="2" class="c4 s"/>',
                    '<rect x="6" y="2" class="c1 s"/>',
                    '<rect x="7" y="2" class="c1 s"/>',
                    '<rect x="8" y="2" class="c1 s"/>',
                    '<rect x="9" y="2" class="c1 s"/>',

                    '<rect x="0" y="3" class="c1 s"/>',
                    '<rect x="1" y="3" class="c1 s"/>',
                    '<rect x="2" y="3" class="c1 s"/>',
                    '<rect x="3" y="3" class="c1 s"/>',
                    '<rect x="4" y="3" class="c1 s"/>',
                    '<rect x="5" y="3" class="c1 s"/>',
                    '<rect x="6" y="3" class="c1 s"/>',
                    '<rect x="7" y="3" class="c1 s"/>',
                    '<rect x="8" y="3" class="c1 s"/>',
                    '<rect x="9" y="3" class="c4 s"/>',

                    '<rect x="0" y="4" class="c4 s"/>',
                    '<rect x="1" y="4" class="c5 s"/>',
                    '<rect x="2" y="4" class="c5 s"/>',
                    '<rect x="3" y="4" class="c1 s"/>',
                    '<rect x="4" y="4" class="c1 s"/>',
                    '<rect x="5" y="4" class="c1 s"/>',
                    '<rect x="6" y="4" class="c5 s"/>',
                    '<rect x="7" y="4" class="c5 s"/>',
                    '<rect x="8" y="4" class="c4 s"/>',
                    '<rect x="9" y="4" class="c4 s"/>',

                    '<rect x="0" y="5" class="c4 s"/>',
                    '<rect x="1" y="5" class="c5 s"/>',
                    '<rect x="2" y="5" class="c5 s"/>',
                    '<rect x="3" y="5" class="c1 s"/>',
                    '<rect x="4" y="5" class="c1 s"/>',
                    '<rect x="5" y="5" class="c1 s"/>',
                    '<rect x="6" y="5" class="c5 s"/>',
                    '<rect x="7" y="5" class="c5 s"/>',
                    '<rect x="8" y="5" class="c1 s"/>',
                    '<rect x="9" y="5" class="c4 s"/>',

                    '<rect x="0" y="6" class="c4 s"/>',
                    '<rect x="1" y="6" class="c1 s"/>',
                    '<rect x="2" y="6" class="c1 s"/>',
                    '<rect x="3" y="6" class="c2 s"/>',
                    '<rect x="4" y="6" class="c1 s"/>',
                    '<rect x="5" y="6" class="c1 s"/>',
                    '<rect x="6" y="6" class="c1 s"/>',
                    '<rect x="7" y="6" class="c1 s"/>',
                    '<rect x="8" y="6" class="c1 s"/>',
                    '<rect x="9" y="6" class="c4 s"/>',

                    '<rect x="0" y="7" class="c4 s"/>',
                    '<rect x="1" y="7" class="c1 s"/>',
                    '<rect x="2" y="7" class="c1 s"/>',
                    '<rect x="3" y="7" class="c1 s"/>',
                    '<rect x="4" y="7" class="c1 s"/>',
                    '<rect x="5" y="7" class="c1 s"/>',
                    '<rect x="6" y="7" class="c1 s"/>',
                    '<rect x="7" y="7" class="c1 s"/>',
                    '<rect x="8" y="7" class="c1 s"/>',
                    '<rect x="9" y="7" class="c4 s"/>',

                    '<rect x="0" y="8" class="c4 s"/>',
                    '<rect x="1" y="8" class="c4 s"/>',
                    '<rect x="2" y="8" class="c1 s"/>',
                    '<rect x="3" y="8" class="c2 s"/>',
                    '<rect x="4" y="8" class="c2 s"/>',
                    '<rect x="5" y="8" class="c1 s"/>',
                    '<rect x="6" y="8" class="c1 s"/>',
                    '<rect x="7" y="8" class="c1 s"/>',
                    '<rect x="8" y="8" class="c4 s"/>',
                    '<rect x="9" y="8" class="c4 s"/>',

                    '<rect x="0" y="9" class="c4 s"/>',
                    '<rect x="1" y="9" class="c4 s"/>',
                    '<rect x="2" y="9" class="c4 s"/>',
                    '<rect x="3" y="9" class="c1 s"/>',
                    '<rect x="4" y="9" class="c1 s"/>',
                    '<rect x="5" y="9" class="c1 s"/>',
                    '<rect x="6" y="9" class="c1 s"/>',
                    '<rect x="7" y="9" class="c4 s"/>',
                    '<rect x="8" y="9" class="c4 s"/>',
                    '<rect x="9" y="9" class="c4 s"/>',

                    '<g id="eye-location" transform="translate(1,4)">',
                    eyes,
                    '</g>'
            )
        );
    }
}

pragma solidity 0.8.6;

interface IAnimalSVG {
    function svg(string memory eyes) external pure returns(string memory);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}