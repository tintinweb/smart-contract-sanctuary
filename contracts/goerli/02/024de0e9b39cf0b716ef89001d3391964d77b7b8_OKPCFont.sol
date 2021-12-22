//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCFont {
    function getChar(string memory char) external view returns (string memory);
}

contract OKPCFont is IOKPCFont {
    mapping(string => string) public alphanum;

    constructor() {
        alphanum["a"] = "M2 0H1V1H0V2V3H1V2H2V3H3V2V1H2V0Z";
        alphanum["b"] = "M2 0V1H3V2V3H2H1H0V2V1V0H1H2Z";
        alphanum["c"] = "M2 1H1V2H2H3V3H2H1H0V2V1V0H1H2H3V1H2Z";
        alphanum["d"] = "M2 1H1V2H2V3H1H0V2V1V0H1H2V1ZM2 1V2H3V1H2Z";
        alphanum["e"] = "M1 0H2H3V1H2V2H3V3H2H1H0V2V1V0H1Z";
        alphanum["f"] = "M1 0H2H3V1H2V2H1V3H0V2V1V0H1Z";
        alphanum["g"] = "M2 1H1V2H2V1ZM3 2V1H2V0H1H0V1V2V3H1H2H3V2Z";
        alphanum["h"] = "M3 0V1V2V3H2V2H1V3H0V2V1V0H1V1H2V0H3Z";
        alphanum["i"] = "M3 1H2V2H3V3H2H1H0V2H1V1H0V0H1H2H3V1Z";
        alphanum["j"] = "M3 0V1V2V3H2H1H0V2V1H1V2H2V1V0H3Z";
        alphanum["k"] = "M1 0V1H2V2H1V3H0V2V1V0H1ZM2 2V3H3V2H2ZM2 1V0H3V1H2Z";
        alphanum["l"] = "M1 0V1V2H2H3V3H2H1H0V2V1V0H1Z";
        alphanum["m"] = "M0 0H1H2H3V1V2V3H2V2H1V3H0V2V1V0Z";
        alphanum["n"] = "M0 0H1H2H3V1V2V3H2V2V1H1V2V3H0V2V1V0Z";
        alphanum["o"] = "M0 0H1H2H3V1V2V3H2H1H0V2V1V0ZM1 1V2H2V1H1Z";
        alphanum["p"] = "M0 0H1H2H3V1V2H2H1V3H0V2V1V0Z";
        alphanum["q"] = "M0 0H1H2H3V1V2V3H2V2H1H0V1V0Z";
        alphanum["r"] = "M0 0H1H2H3V1H2H1V2V3H0V2V1V0Z";
        alphanum["s"] = "M3 1H2V2V3H1H0V2H1V1V0H2H3V1Z";
        alphanum["t"] = "M1 0H2H3V1H2V2V3H1V2V1H0V0H1Z";
        alphanum["u"] = "M1 0V1V2H2V1V0H3V1V2V3H2H1H0V2V1V0H1Z";
        alphanum["v"] = "M1 0V1V2H0V1V0H1ZM2 2H1V3H2V2ZM2 2V1V0H3V1V2H2Z";
        alphanum["w"] = "M1 0V1H2V0H3V1V2V3H2H1H0V2V1V0H1Z";
        alphanum[
            "x"
        ] = "M1 1H0V0H1V1ZM2 1H1V2H0V3H1V2H2V3H3V2H2V1ZM2 1V0H3V1H2Z";
        alphanum["y"] = "M1 1H0V0H1V1ZM2 1H1V2V3H2V2V1ZM2 1V0H3V1H2Z";
        alphanum["z"] = "M1 1H0V0H1H2V1V2H3V3H2H1V2V1Z";
        alphanum["1"] = "M1 1H0V0H1H2V1V2H3V3H2H1H0V2H1V1Z";
        alphanum["2"] = "M1 1H0V0H1H2V1V2H3V3H2H1V2V1Z";
        alphanum["3"] = "M1 1H0V0H1H2H3V1V2V3H2H1H0V2H1V1Z";
        alphanum["4"] = "M1 0V1H2V0H3V1V2V3H2V2H1H0V1V0H1Z";
        alphanum["5"] = "M3 1H2V2V3H1H0V2H1V1V0H2H3V1Z";
        alphanum["6"] = "M1 0V1H2H3V2V3H2H1H0V2V1V0H1Z";
        alphanum["7"] = "M1 1H0V0H1H2H3V1V2V3H2V2V1H1Z";
        alphanum["8"] = "M3 0V1V2V3H2H1H0V2V1H1V0H2H3Z";
        alphanum["9"] = "M0 0H1H2H3V1V2V3H2V2H1H0V1V0Z";
        alphanum["0"] = "M0 0H1H2H3V1V2V3H2H1H0V2V1V0ZM1 1V2H2V1H1Z";
    }

    function getChar(string memory char)
        public
        view
        override
        returns (string memory)
    {
        require(bytes(char).length == 1, "input is not a single char");
        require(bytes(alphanum[char]).length != 0, "char not found");
        return alphanum[char];
    }
}