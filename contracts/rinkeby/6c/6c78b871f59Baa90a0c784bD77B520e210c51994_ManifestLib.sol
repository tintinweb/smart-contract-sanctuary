// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: None
// Copyright (c) 2021 the nova.lol authors

pragma solidity >=0.8.0 <0.9.0;


import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/Shuffler.sol";

library ManifestLib {
    using Shuffler for Shuffler.State;

    struct Seed {
        uint256 seed;
    }

    function chooseRandom(
        Seed memory s,
        string[2] memory choices,
        uint256[] memory weights
    ) internal pure returns (string memory) {
        string[] memory c = new string[](2);
        for (uint256 idx; idx < 2; ++idx) {
            c[idx] = choices[idx];
        }
        return chooseRandom(s, c, weights);
    }

    function chooseRandom(
        Seed memory s,
        string[3] memory choices,
        uint256[] memory weights
    ) internal pure returns (string memory) {
        string[] memory c = new string[](3);
        for (uint256 idx; idx < 3; ++idx) {
            c[idx] = choices[idx];
        }
        return chooseRandom(s, c, weights);
    }

    function chooseRandom(
        Seed memory s,
        string[4] memory choices,
        uint256[] memory weights
    ) internal pure returns (string memory) {
        string[] memory c = new string[](4);
        for (uint256 idx; idx < 4; ++idx) {
            c[idx] = choices[idx];
        }
        return chooseRandom(s, c, weights);
    }

    function chooseRandom(
        Seed memory s,
        string[5] memory choices,
        uint256[] memory weights
    ) internal pure returns (string memory) {
        string[] memory c = new string[](5);
        for (uint256 idx; idx < 5; ++idx) {
            c[idx] = choices[idx];
        }
        return chooseRandom(s, c, weights);
    }

    function chooseRandom(
        Seed memory s,
        string[7] memory choices,
        uint256[] memory weights
    ) internal pure returns (string memory) {
        string[] memory c = new string[](7);
        for (uint256 idx; idx < 7; ++idx) {
            c[idx] = choices[idx];
        }
        return chooseRandom(s, c, weights);
    }

    function chooseRandom(
        Seed memory s,
        string[] memory choices,
        uint256[] memory weights
    ) internal pure returns (string memory) {
        // assert(choices.length == weights.length);
        require(
            choices.length == weights.length,
            string(
                abi.encodePacked(
                    Strings.toString(choices.length),
                    " ",
                    Strings.toString(weights.length),
                    " -> ",
                    abi.encode(choices)
                )
            )
        );

        uint256 sum = 0;
        for (uint256 idx; idx < choices.length; ++idx) {
            sum += weights[idx];
        }

        s.seed = uint256(keccak256(abi.encode(s)));
        uint256 randIdx = s.seed % sum;

        for (uint256 idx; idx < choices.length - 1; ++idx) {
            if (randIdx < weights[idx]) {
                return choices[idx];
            } else {
                randIdx -= weights[idx];
            }
        }

        return choices[choices.length - 1];
    }

    uint256 internal constant NUM_RANDOM = 67;

    function getNumChoices() public pure returns (uint8[NUM_RANDOM] memory) {
        uint8[NUM_RANDOM] memory choices = [
            3,
            4,
            3,
            3,
            5,
            3,
            4,
            3,
            3,
            5,
            5,
            3,
            2,
            5,
            7,
            3,
            3,
            3,
            3,
            3,
            4,
            4,
            3,
            3,
            3,
            4,
            3,
            3,
            3,
            3,
            3,
            4,
            3,
            3,
            3,
            4,
            3,
            3,
            3,
            3,
            3,
            4,
            3,
            4,
            3,
            3,
            3,
            3,
            3,
            3,
            4,
            3,
            4,
            3,
            4,
            3,
            3,
            3,
            3,
            4,
            3,
            3,
            3,
            3,
            3,
            2,
            3
        ];
        return choices;
    }

    function shuffle(string[] memory sorted, uint256 seed)
        external
        pure
        returns (string[] memory)
    {
        uint256 len = sorted.length;
        string[] memory shuffled = new string[](len);

        Shuffler.State memory shuffler = Shuffler.allocate(
            len,
            keccak256(abi.encodePacked(seed, abi.encode(sorted)))
        );

        for (uint256 idx = 0; idx < len; ++idx) {
            shuffled[idx] = sorted[shuffler.next()];
        }

        return shuffled;
    }

    function shuffle(uint256[] memory sorted, uint256 seed)
        external
        pure
        returns (uint256[] memory)
    {
        uint256 len = sorted.length;
        uint256[] memory shuffled = new uint256[](len);

        Shuffler.State memory shuffler = Shuffler.allocate(
            len,
            keccak256(abi.encodePacked(seed, abi.encode(sorted)))
        );

        for (uint256 idx = 0; idx < len; ++idx) {
            shuffled[idx] = sorted[shuffler.next()];
        }

        return shuffled;
    }

    function getUniformWeights()
        external
        pure
        returns (uint256[][NUM_RANDOM] memory)
    {
        uint256[][NUM_RANDOM] memory weights;
        uint8[NUM_RANDOM] memory choices = getNumChoices();
        for (uint256 idx; idx < NUM_RANDOM; ++idx) {
            uint256[] memory tmp = new uint256[](choices[idx]);

            for (uint256 jdx; jdx < choices[idx]; ++jdx) {
                tmp[jdx] = 1;
            }
            weights[idx] = tmp;
        }
        return weights;
    }

    uint256 internal constant NUM_LINES = 43;

    function getLines(uint256 seed, uint256[][NUM_RANDOM] memory weights)
        external
        pure
        returns (string[] memory)
    {
        Seed memory s = Seed({seed: seed});
        string[] memory lines = new string[](NUM_LINES);

        uint256 lineIdx;
        uint256 weightIdx;

        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["We are all", "Are we all", "All we are is"],
                    weights[weightIdx++]
                ),
                " transactions in sequence now ",
                chooseRandom(
                    s,
                    ["?", "%26%23x1F9FE;", "...", " :("],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "In ",
                chooseRandom(s, ["this", "our", "a"], weights[weightIdx++]),
                " ",
                chooseRandom(
                    s,
                    ["time", "epoch", "chapter"],
                    weights[weightIdx++]
                ),
                " teh social contract is ",
                chooseRandom(
                    s,
                    [
                        "bearish",
                        "postponed",
                        "decaying",
                        "%26%23x1F9F8;",
                        "%26%23x1F43B;"
                    ],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "We are compensating ",
                chooseRandom(
                    s,
                    ["a lack of", "an absence of", "lost"],
                    weights[weightIdx++]
                ),
                " aura with ",
                chooseRandom(
                    s,
                    ["power", "energy", "electricity", "%26%23x26A1;"],
                    weights[weightIdx++]
                )
            )
        );

        lines[lineIdx++] = string(
            abi.encodePacked(
                "and a consensually ",
                chooseRandom(
                    s,
                    ["witnessed", "shared", "synchronised"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["record", "ledger", "archive"],
                    weights[weightIdx++]
                )
            )
        );

        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    [
                        "ploughing",
                        "leading",
                        "loading",
                        "stumbling",
                        "cowering"
                    ],
                    weights[weightIdx++]
                ),
                " the ",
                chooseRandom(
                    s,
                    [
                        "ornamental",
                        "decorative",
                        "pfp idols",
                        "apis %26%23x1F402;",
                        "embellished"
                    ],
                    weights[weightIdx++]
                ),
                " into ",
                chooseRandom(
                    s,
                    ["bourgeois", "hoarded", "commodified"],
                    weights[weightIdx++]
                ),
                " relevance"
            )
        );

        lines[lineIdx++] = string(
            abi.encodePacked(
                "immutability ",
                chooseRandom(
                    s,
                    ["is", "is not actually"],
                    weights[weightIdx++]
                ),
                ", ",
                chooseRandom(
                    s,
                    [
                        "death",
                        "abiding",
                        "constant?",
                        "%26%23x2620;",
                        "for ever never ever"
                    ],
                    weights[weightIdx++]
                )
            )
        );

        lines[lineIdx++] = string(
            abi.encodePacked(
                "just like a museum is a ",
                chooseRandom(
                    s,
                    [
                        "graveyard",
                        "mortuary",
                        "storage of irrelevance",
                        "%26%23x26B0;",
                        "terminus",
                        "used Tupperware container",
                        "mausoleum"
                    ],
                    weights[weightIdx++]
                )
            )
        );

        lines[lineIdx++] = string(
            abi.encodePacked(
                "the ",
                chooseRandom(
                    s,
                    ["only", "one", "single"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["thing", "fact", "truth"],
                    weights[weightIdx++]
                ),
                " that's ",
                chooseRandom(
                    s,
                    ["certain", "secure", "guaranteed"],
                    weights[weightIdx++]
                ),
                " in life /s"
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "is a ",
                chooseRandom(
                    s,
                    ["utility", "solution", "service"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["peddled ", "offered", "sold"],
                    weights[weightIdx++]
                ),
                " in many ",
                chooseRandom(
                    s,
                    ["chains", "ways", "blocks", "hashes"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["an artwork", "an expression", "a gesture", "%26%23x1F381;"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["referenced", "noted", "alluded to"],
                    weights[weightIdx++]
                ),
                " within the ",
                chooseRandom(
                    s,
                    ["ledger", "archive", "record"],
                    weights[weightIdx++]
                )
            )
        );

        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["validated ", "verified", "acknowledged"],
                    weights[weightIdx++]
                ),
                " by ",
                chooseRandom(
                    s,
                    [
                        "computers guessing",
                        "a metric",
                        "a buyer",
                        "a speculator"
                    ],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "cognate the ",
                chooseRandom(
                    s,
                    ["wrapped", "packaged", "incorporated"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["derivative", "reference", "token"],
                    weights[weightIdx++]
                ),
                " or ",
                chooseRandom(
                    s,
                    ["whatever", "pretence", "ornament"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["always", "predominantly", "principally"],
                    weights[weightIdx++]
                ),
                " the ",
                chooseRandom(
                    s,
                    ["bridesmaid", "question", "problem"],
                    weights[weightIdx++]
                ),
                " never the nonce"
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "We ",
                chooseRandom(
                    s,
                    ["%26%23x1F48E; %26%23x1F64C;", "grasp", "hold", "provide"],
                    weights[weightIdx++]
                ),
                " in ",
                chooseRandom(
                    s,
                    ["ambition", "desire", "hope"],
                    weights[weightIdx++]
                ),
                ", as another ",
                chooseRandom(
                    s,
                    ["rehash", "illustration", "derivative"],
                    weights[weightIdx++]
                ),
                " of unicity ",
                chooseRandom(
                    s,
                    ["depreciates", "appreciates", "crabs"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "towards the ",
                chooseRandom(
                    s,
                    ["conjuncture", "crash", "%26%23x1F4A5;", "failure"],
                    weights[weightIdx++]
                ),
                " of falsified ",
                chooseRandom(
                    s,
                    ["opulence", "abundance", "wealth"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "a stimulated ",
                chooseRandom(
                    s,
                    ["accumulation", "exposure", "stacking"],
                    weights[weightIdx++]
                ),
                " of ",
                chooseRandom(
                    s,
                    ["assets", "value", "speculation"],
                    weights[weightIdx++]
                ),
                " to keep from others"
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "what was ",
                chooseRandom(
                    s,
                    ["built", "developed", "coded"],
                    weights[weightIdx++]
                ),
                " on ",
                chooseRandom(
                    s,
                    ["potential's", "technology's", "the network's"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["potential", "possibilities", "promise", "%26%23x1F4C8;"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "what hoomans really need we ",
                chooseRandom(
                    s,
                    ["no longer", "can not", "shouldn't"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["hoard", "own", "hold", "hodl"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["Embracing", "Inciting", "Praising"],
                    weights[weightIdx++]
                ),
                " the value of the ",
                chooseRandom(
                    s,
                    ["fuelled", "emphasised", "powered"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "transaction, in",
                chooseRandom(
                    s,
                    ["lieu of", "exchange for", "stead of"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["bibelot", "novelty", "bauble"],
                    weights[weightIdx++]
                ),
                " identity"
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["A pedestal", "Context", "A plinth"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    [
                        "always requires",
                        "should not require",
                        "desires and requires"
                    ],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["expense", "cost", "effort", "SACRIFICE"],
                    weights[weightIdx++]
                ),
                " to ",
                chooseRandom(
                    s,
                    ["exclude", "lift", "separate"],
                    weights[weightIdx++]
                ),
                " from the ",
                chooseRandom(
                    s,
                    ["mundane", "ordinary", "common", "daily grind"],
                    weights[weightIdx++]
                )
            )
        );

        lines[
            lineIdx++
        ] = "semantics to own and trade, both significance and referent made";

        lines[lineIdx++] = string(
            abi.encodePacked(
                "Right clickable by y'all, ",
                chooseRandom(s, ["but", "and", "yet"], weights[weightIdx++]),
                " ",
                chooseRandom(
                    s,
                    ["sanctioned", "acknowledged", "%26%23x1F510;", "authorized"],
                    weights[weightIdx++]
                ),
                " by protocol"
            )
        );

        lines[lineIdx++] = "will u hedge expression with a put or call";

        lines[lineIdx++] = string(
            abi.encodePacked(
                "Culture is ",
                chooseRandom(
                    s,
                    ["behaviour", "habits", "customs"],
                    weights[weightIdx++]
                ),
                ", not ",
                chooseRandom(
                    s,
                    ["transactions", "records", "archive entries"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "This is ",
                chooseRandom(s, ["a", "my", "your"], weights[weightIdx++]),
                " trust",
                chooseRandom(
                    s,
                    ["ful", "ing", " exercise"],
                    weights[weightIdx++]
                ),
                " endeavour within trustless ",
                chooseRandom(
                    s,
                    ["ambitions", "chains", "networks", "%26%23x26D3;"],
                    weights[weightIdx++]
                )
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "Every ",
                chooseRandom(
                    s,
                    ["creation", "reaction", "gesture"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["does not equal", "equals", "isn't"],
                    weights[weightIdx++]
                ),
                " a transaction"
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                chooseRandom(
                    s,
                    ["Distanced", "Separated", "Removed"],
                    weights[weightIdx++]
                ),
                " from ",
                chooseRandom(
                    s,
                    ["ideology", "politics", "faith"],
                    weights[weightIdx++]
                ),
                " alone"
            )
        );
        lines[lineIdx++] = string(
            abi.encodePacked(
                "The ",
                chooseRandom(
                    s,
                    ["real", "object", "noumenon"],
                    weights[weightIdx++]
                ),
                " on a ",
                chooseRandom(
                    s,
                    ["uncomfortable", "comfortable"],
                    weights[weightIdx++]
                ),
                " ",
                chooseRandom(
                    s,
                    ["costly", "powered", "heated"],
                    weights[weightIdx++]
                ),
                " throne"
            )
        );

        lines[lineIdx++] = "%26%23x1F5DD;hodl me close %26%23x1F511;";

        lines[lineIdx++] = "two dozen words ready to grow this contract";

        lines[lineIdx++] = "anticipation";

        lines[lineIdx++] = "cognition";

        lines[lineIdx++] = "fascination";

        lines[lineIdx++] = "dedication";

        lines[lineIdx++] = "obsession";

        lines[lineIdx++] = "comprehension";

        lines[lineIdx++] = "%26%23x1F62D; acceptance %26%23x1F62D;";

        lines[lineIdx++] = "(...)";

        lines[lineIdx++] = "%26%23x1F62D;";

        lines[lineIdx++] = "%26%23x1F510;";

        lines[lineIdx++] = "%26%23x1F512;";

        lines[lineIdx++] = "%26%23x1F513;";

        return lines;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.9 <0.9.0;

/**
@notice Computes the values in a shuffled list [0,n).
@dev The library has been heavily modified to allow in-memory shuffling.
 */
library Shuffler {
    struct State {
        uint256[] permutation;
        bytes32 entropy;
        uint256 shuffled;
        uint256 numToShuffle;
    }

    /// @notice Allocates the internal state of the shuffler.
    function allocate(uint256 numToShuffle, bytes32 entropy)
        internal
        pure
        returns (State memory)
    {
        return
            State({
                permutation: new uint256[](numToShuffle),
                entropy: entropy,
                shuffled: 0,
                numToShuffle: numToShuffle
            });
    }

    /**
    @notice Returns the current value stored in list index `i`, accounting for
    all historical shuffling.
     */
    function get(State memory state, uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 val = state.permutation[i];
        return val == 0 ? i : val - 1;
    }

    /**
    @notice Sets the list index `i` to `val`, equivalent `arr[i] = val` in a
    standard Fisher–Yates shuffle.
     */
    function set(
        State memory state,
        uint256 i,
        uint256 val
    ) internal pure {
        state.permutation[i] = val + 1;
    }

    /**
    @notice Returns the next value in the shuffle list in O(1) time and memory.
    @dev NB: See the `dev` documentation of this contract re security (or lack
    thereof) of deterministic shuffling.
     */
    function next(State memory state) internal pure returns (uint256) {
        require(state.shuffled < state.numToShuffle, "NextShuffler: finished");

        uint256 j = (_getRandom(state) %
            (state.numToShuffle - state.shuffled)) + state.shuffled;

        uint256 chosen = get(state, j);
        set(state, j, get(state, state.shuffled));
        state.shuffled++;
        return chosen;
    }

    /**
    @notice Generate a random number form the seed.
     */
    function _getRandom(State memory state) internal pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(state.entropy, state.shuffled)));
    }
}