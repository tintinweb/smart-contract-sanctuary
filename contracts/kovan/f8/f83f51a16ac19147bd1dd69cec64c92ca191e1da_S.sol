/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.8.0;

contract S {
    function toString(uint256 value) internal pure returns (string memory) {
		if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
	
    function g(uint256 c) public view returns (string memory) {
        unchecked {
    		string memory s;
    		uint256 p = block.number * 112068002364947537014802701075021898324313602097276044616656536065636132166093;
    		p = p + c;
    		for (uint256 i = 0; i < c; i++) {
    			uint256 a = (p >> ((i % 64) * 4)) & 15;
    			a = p * 7919 * 7919 + i;
    			uint256 b = (a * 179) % 181;
    			a = (a * 173) % 181;
    			s = string(
    				abi.encodePacked(
    					s,
    					"<polygon points='",
    					toString(a), ",", toString(b), " ",
    					toString(a + 10), ",", toString(b), " "
    				)
    			);
    			s = string(
    				abi.encodePacked(
    					s,
    					toString(a + 10), ",", toString(b + 10), " ",
    					toString(a), ",", toString(b + 10),
    					"' class='p0'/>"
    				)
    			);
    			s = string(
    				abi.encodePacked(
    					s,
    					"<polygon points='",
    					toString(a + 6), ",", toString(b + 3), " ",
    					toString(a + 16), ",", toString(b + 3), " "
    				)
    			);
    			s = string(
    				abi.encodePacked(
    					s,
    					toString(a + 16), ",", toString(b + 13), " ",
    					toString(a + 6), ",", toString(b + 13),
    					"' class='p1'/>"
    				)
    			);
    			s = string(
    				abi.encodePacked(
    					s,
    					"<polygon points='",
    					toString(a + 3), ",", toString(b + 6), " ",
    					toString(a + 13), ",", toString(b + 6), " "
    				)
    			);
    			s = string(
    				abi.encodePacked(
    					s,
    					toString(a + 13), ",", toString(b + 16), " ",
    					toString(a + 3), ",", toString(b + 16),
    					"' class='p2'/>"
    				)
    			);
    		}
    
            s = string(
                abi.encodePacked(
                    "<svg width='200' height='200'> ",
                    s,
                    "<style> polygon.p0 {filter: brightness(100%); fill: red} polygon.p1 {filter: brightness(100%); fill: green} polygon.p2 {filter: brightness(100%); fill: blue} </style> </svg>"
                )
            );
    
            return s;
        }
    }
}