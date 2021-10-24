// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IOneSyllableNouns.sol";
import "./ITwoSyllableNouns.sol";

contract Words {
    using Strings for uint256;

    IOneSyllableNouns public oneSyllableNouns;
    ITwoSyllableNouns public twoSyllableNouns;

    string[] private noun3 = ['artefact', 'abandon', 'accident', 'acoustic', 'alcohol', 'alien', 'amateur', 'analyst', 'animal', 'annual', 'antenna', 'area', 'arena', 'attitude', 'average', 'bachelor', 'balcony', 'banana', 'benefit', 'bicycle', 'broccoli', 'buffalo', 'camera', 'capital', 'casino', 'catalog', 'celery', 'century', 'cereal', 'champion', 'cinnamon', 'citizen', 'coconut', 'company', 'coyote', 'december', 'denial', 'deposit', 'deputy', 'diagram', 'diary', 'dignity', 'dilemma', 'dinosaur', 'disorder', 'document', 'dynamic', 'electric', 'element', 'elephant', 'emotion', 'enemy', 'energy', 'entire', 'envelope', 'episode', 'erosion', 'evidence', 'example', 'exercise', 'exhibit', 'faculty', 'family', 'fantasy', 'favorite', 'federal', 'festival', 'galaxy', 'gallery', 'general', 'gorilla', 'gravity', 'grocery', 'history', 'holiday', 'hospital', 'idea', 'industry', 'initial', 'injury', 'innocent', 'inquiry', 'ivory', 'kangaroo', 'liberty', 'library', 'lottery', 'luxury', 'manual', 'maximum', 'mechanic', 'media', 'melody', 'memory', 'minimum', 'miracle', 'misery', 'monitor', 'mosquito', 'museum', 'mystery', 'negative', 'nominee', 'notable', 'october', 'opinion', 'orient', 'oxygen', 'pelican', 'penalty', 'piano', 'pioneer', 'position', 'potato', 'pottery', 'poverty', 'primary', 'property', 'purity', 'pyramid', 'quality', 'radio', 'recipe', 'regular', 'reunion', 'ritual', 'scorpion', 'seminar', 'solution', 'stadium', 'stereo', 'strategy', 'tobacco', 'tomato', 'tomorrow', 'tornado', 'tuition', 'umbrella', 'uniform', 'universe', 'vehicle', 'veteran', 'victory', 'video', 'violin', 'volcano', 'warrior', 'satoshi'];
    string[] private noun4 = ['ability', 'anxiety', 'apology', 'avocado', 'biology', 'category', 'ecology', 'economy', 'elevator', 'february', 'material', 'ordinary', 'original', 'priority', 'security', 'utility'];

    string[] private verb1 = ['armed', 'ask', 'bless', 'bring', 'brisk', 'caught', 'choose', 'cram', 'earn', 'flee', 'grow', 'learn', 'lend', 'live', 'long', 'merge', 'mixed', 'near', 'off', 'own', 'please', 'quit', 'sing', 'slim', 'slow', 'solve', 'speak', 'spend', 'swear', 'thank', 'thrive', 'used', 'warm', 'write'];
    string[] private verb2 = ['absent', 'absorb', 'accuse', 'achieve', 'adapt', 'adjust', 'admit', 'afford', 'agree', 'allow', 'alter', 'amused', 'announce', 'appear', 'approve', 'argue', 'arrange', 'arrive', 'assume', 'attend', 'attract', 'avoid', 'awake', 'become', 'behave', 'believe', 'betray', 'borrow', 'broken', 'busy', 'confirm', 'connect', 'convince', 'correct', 'crumble', 'decide', 'define', 'defy', 'deny', 'depart', 'depend', 'derive', 'describe', 'destroy', 'detect', 'devote', 'differ', 'direct', 'dismiss', 'divert', 'dizzy', 'donate', 'edit', 'embark', 'emerge', 'enact', 'endorse', 'enforce', 'engage', 'enhance', 'enjoy', 'enlist', 'enrich', 'enroll', 'ensure', 'enter', 'equip', 'erase', 'erode', 'erupt', 'evoke', 'evolve', 'exact', 'excite', 'exclude', 'exist', 'expand', 'expect', 'expire', 'explain', 'extend', 'follow', 'forget', 'frequent', 'frozen', 'gentle', 'govern', 'hidden', 'hover', 'humble', 'ignore', 'impose', 'improve', 'include', 'inflict', 'inform', 'inhale', 'inject', 'inspire', 'install', 'invest', 'involve', 'manage', 'obey', 'oblige', 'obscure', 'observe', 'obtain', 'occur', 'omit', 'oppose', 'predict', 'prefer', 'prepare', 'prevent', 'promote', 'prosper', 'protect', 'provide', 'rebuild', 'receive', 'reduce', 'reflect', 'relax', 'rely', 'remain', 'remind', 'renew', 'replace', 'resist', 'retire', 'reveal', 'rotate', 'select', 'submit', 'suffer', 'suggest', 'sustain', 'tired', 'topple', 'undo', 'unfold', 'unlock', 'unveil', 'uphold', 'vanish'];
    string[] private verb3 = ['acquire', 'amazing', 'clarify', 'consider', 'decorate', 'deliver', 'develop', 'disagree', 'discover', 'educate', 'embody', 'empower', 'enable', 'execute', 'imitate', 'indicate', 'inherit', 'isolate', 'modify', 'multiply', 'recycle', 'remember', 'reopen', 'require', 'resemble', 'satisfy', 'situate', 'uncover', 'verify'];
    string[] private verb4 = ['identify'];

    string[] private adj1 = ['all', 'bright', 'cheap', 'false', 'fresh', 'hard', 'just', 'loud', 'proud', 'sad', 'soft', 'strong', 'sure', 'wide', 'bleak', 'cute', 'dumb', 'harsh', 'huge', 'mad', 'next', 'rare', 'rude', 'such', 'vague', 'vast'];
    string[] private adj2 = ['able', 'afraid', 'angry', 'aware', 'chronic', 'crucial', 'early', 'easy', 'fatal', 'fiscal', 'happy', 'hungry', 'indoor', 'insane', 'legal', 'loyal', 'lunar', 'naive', 'nasty', 'online', 'other', 'outdoor', 'outer', 'random', 'robust', 'rural', 'solar', 'sorry', 'spatial', 'sudden', 'ugly', 'unfair', 'urban', 'useful', 'useless', 'valid', 'about', 'ahead', 'alone', 'any', 'apart', 'away', 'awesome', 'awful', 'awkward', 'certain', 'civil', 'clever', 'cruel', 'drastic', 'endless', 'famous', 'fragile', 'immense', 'inner', 'intact', 'jealous', 'later', 'lazy', 'lonely', 'lucky', 'merry', 'neither', 'only', 'polar', 'pretty', 'rigid', 'silent', 'slender', 'sunny', 'supreme', 'tiny', 'tragic', 'under', 'unique', 'vacant', 'very', 'vibrant', 'vicious', 'vital', 'vivid'];
    string[] private adj3 = ['actual', 'aerobic', 'capable', 'digital', 'elegant', 'genuine', 'illegal', 'nuclear', 'obvious', 'olympic', 'physical', 'popular', 'possible', 'similar', 'typical', 'unable', 'unaware', 'unhappy', 'usual', 'visual', 'another', 'casual', 'curious', 'eternal', 'exotic', 'mutual', 'together', 'various', 'viable', 'virtual'];
    string[] private adj4 = ['unusual'];

    string[] private preposition1 = ['that', 'since'];
    string[] private preposition2 = ['among', 'because', 'during', 'into', 'toward', 'upon'];

    uint256 private constant TOTAL_NOUNS = 1662;
    uint256 private constant TOTAL_VERBS = 210;
    uint256 private constant TOTAL_ADJS = 138;
    uint256 private constant TOTAL_PREPS = 8;

    string private constant UNCOMMON = '#58d68d';
    string private constant RARE = '#5dade2';
    string private constant EPIC = '#9b59b6';
    string private constant LEGENDARY = '#dc7633';

    constructor() {
        oneSyllableNouns = IOneSyllableNouns(0x1DA290ad77B8B458Fa4Cd708b7a7A1823D8Dc8CB);
        twoSyllableNouns = ITwoSyllableNouns(0x56b76BFf091653AFD25d0d68D98E769Ac1bE6721);
    }

    function getRandomWord(
        uint256 tokenId, 
        uint256 seedNum, 
        string memory keyPrefix, 
        string[] memory sourceArray) private pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(tokenId.toString(), keyPrefix, seedNum.toString())));
        string memory output = sourceArray[rand % sourceArray.length];
        return string(abi.encodePacked(output));
    }

    function getFiveSyllableLine(uint256 tokenId, uint256 lineNum) private view returns (string memory, string memory, uint256, uint256) {
        string[2] memory line;
        uint256[2] memory wordSyllables;
        uint256 numSyllablesLeft = 5;
        uint256 rand = random(string(abi.encodePacked(tokenId.toString(), 'FIVE', lineNum.toString()))) % TOTAL_ADJS;

        // adj noun
        if (rand < adj1.length) {
            line[0] = getRandomWord(tokenId, lineNum, "ADJ1", adj1);
            numSyllablesLeft--;
        } else if (rand < adj1.length + adj2.length) {
            line[0] = getRandomWord(tokenId, lineNum, "ADJ2", adj2);
            numSyllablesLeft -= 2;
        } else if (rand < adj1.length + adj2.length + adj3.length) {
            line[0] = getRandomWord(tokenId, lineNum, "ADJ3", adj3);
            numSyllablesLeft -= 3;
        } else {
            line[0] = getRandomWord(tokenId, lineNum, "ADJ4", adj4);
            numSyllablesLeft -= 4;
        }
        wordSyllables[0] = 5 - numSyllablesLeft;
        wordSyllables[1] = numSyllablesLeft;

        if (numSyllablesLeft == 1) {
            line[1] = oneSyllableNouns.getRandomNoun(tokenId, 1);
        } else if (numSyllablesLeft == 2) {
            line[1] = twoSyllableNouns.getRandomNoun(tokenId, 1);
        } else if (numSyllablesLeft == 3) {
            line[1] = getRandomWord(tokenId, lineNum, "NOUN3", noun3);
        } else {
            line[1] = getRandomWord(tokenId, lineNum, "NOUN4", noun4);
        }

        return (string(abi.encodePacked(line[0])), string(abi.encodePacked(line[1])), wordSyllables[0], wordSyllables[1]);
    }

    function getVerbForSevenLine(uint256 tokenId, uint256 lineNum) private view returns (string memory, uint256) {
        string memory verb;
        uint256 numSyllables;
        uint256 randVerbIdx = random(string(abi.encodePacked(tokenId.toString(), 'SEVEN', lineNum.toString(), 'VERB'))) % TOTAL_VERBS;

        if (randVerbIdx < verb1.length) {
            verb = getRandomWord(tokenId, lineNum, "VERB1", verb1);
            numSyllables = 1;
        } else if (randVerbIdx < verb1.length + verb2.length) {
            verb = getRandomWord(tokenId, lineNum, "VERB2", verb2);
            numSyllables = 2;
        } else if (randVerbIdx < verb1.length + verb2.length + verb3.length) {
            verb = getRandomWord(tokenId, lineNum, "VERB3", verb3);
            numSyllables = 3;
        } else {
            verb = getRandomWord(tokenId, lineNum, "VERB4", verb4);
            numSyllables = 4;
        }

        return (string(abi.encodePacked(verb)), numSyllables);
    }

    function getPrepositionForSevenLine(uint256 tokenId, uint256 lineNum) private view returns (string memory, uint256) {
        string memory preposition;
        uint256 numSyllables;
        uint256 randPrepIdx = random(string(abi.encodePacked(tokenId.toString(), 'SEVEN', lineNum.toString(), 'PREP'))) % TOTAL_PREPS;

        if (randPrepIdx < preposition1.length) {
            preposition = getRandomWord(tokenId, lineNum, "PREP1", preposition1);
            numSyllables = 1;
        } else {
            preposition = getRandomWord(tokenId, lineNum, "PREP2", preposition2);
            numSyllables = 2;
        }

        return (string(abi.encodePacked(preposition)), numSyllables);
    }

    function getAdjectiveForSevenLine(uint256 tokenId, uint256 lineNum, uint256 numSyllablesLeft) private view returns (string memory, uint256) {
        string memory adjective = '';
        uint256 numSyllables = 0;
        uint256 randAdjIdx = random(string(abi.encodePacked(tokenId.toString(), 'SEVEN', lineNum.toString(), 'ADJ'))) % TOTAL_ADJS;

        if (numSyllablesLeft >= 4) {
            if (randAdjIdx < adj1.length) {
                adjective = getRandomWord(tokenId, lineNum, "ADJ1", adj1);
                numSyllables = 1;
            } else if (randAdjIdx < adj1.length + adj2.length) {
                adjective = getRandomWord(tokenId, lineNum, "ADJ2", adj2);
                numSyllables = 2;
            } else if (randAdjIdx < adj1.length + adj2.length + adj3.length) {
                adjective = getRandomWord(tokenId, lineNum, "ADJ3", adj3);
                numSyllables = 3;
            } else if (numSyllablesLeft == 5) {
                adjective = getRandomWord(tokenId, lineNum, "ADJ4", adj4);
                numSyllables = 4;
            }
        }

        return (string(abi.encodePacked(adjective)), numSyllables);
    }

    function getSevenSyllableLine(uint256 tokenId, uint256 lineNum) private view returns (string memory, string memory, string memory, string memory, uint256, uint256, uint256, uint256) {
        string[4] memory line;
        uint256[4] memory wordSyllables;
        uint256 numSyllablesLeft = 7;

        (line[0], wordSyllables[0]) = getVerbForSevenLine(tokenId, lineNum);
        numSyllablesLeft -= wordSyllables[0];
        (line[1], wordSyllables[1]) = getPrepositionForSevenLine(tokenId, lineNum);
        numSyllablesLeft -= wordSyllables[1];
        (line[2], wordSyllables[2]) = getAdjectiveForSevenLine(tokenId, lineNum, numSyllablesLeft);
        numSyllablesLeft -= wordSyllables[2];
        
        if (numSyllablesLeft == 1) {
            line[3] = oneSyllableNouns.getRandomNoun(tokenId, 1);
        } else if (numSyllablesLeft == 2) {
            line[3] = twoSyllableNouns.getRandomNoun(tokenId, 1);
        } else if (numSyllablesLeft == 3) {
            line[3] = getRandomWord(tokenId, lineNum, "NOUN3", noun3);
        } else {
            line[3] = getRandomWord(tokenId, lineNum, "NOUN4", noun4);
        }
        wordSyllables[3] = numSyllablesLeft;

        return (string(abi.encodePacked(line[0])), string(abi.encodePacked(line[1])), string(abi.encodePacked(line[2])), string(abi.encodePacked(line[3])), wordSyllables[0], wordSyllables[1], wordSyllables[2], wordSyllables[3]);
    }

        function getWordSVG(string memory word, string memory rarity) private pure returns (string memory) {
        return string(abi.encodePacked('<tspan fill="', rarity, '">', word, '</tspan>'));
    }

    function getLine(uint256 tokenId, uint256 lineNum) external view returns (string memory, string memory) {
        if (lineNum == 1 || lineNum == 3) {
            string[2] memory lineParts;
            uint256[2] memory wordSyllables;
            (lineParts[0], lineParts[1], wordSyllables[0], wordSyllables[1]) = getFiveSyllableLine(tokenId, lineNum);

            if (wordSyllables[0] == 1) {
                lineParts[0] = getWordSVG(lineParts[0], EPIC);
            } else if (wordSyllables[0] == 3) {
                lineParts[0] = getWordSVG(lineParts[0], RARE);
            } else if (wordSyllables[0] == 4) {
                lineParts[0] = getWordSVG(lineParts[0], LEGENDARY);
            } else {
                lineParts[0] = string(abi.encodePacked(lineParts[0]));
            }

            if (wordSyllables[1] == 3) {
                lineParts[1] = getWordSVG(lineParts[1], UNCOMMON);
            } else if (wordSyllables[1] == 4) {
                lineParts[1] = getWordSVG(lineParts[1], EPIC);
            } else {
                lineParts[1] = string(abi.encodePacked(lineParts[1]));
            }
                
            string[9] memory traits;
            traits[0] = '{ "trait_type": "Line ';
            traits[1] = lineNum.toString();
            traits[2] = ' Adjective", "value": "';
            traits[3] = wordSyllables[0].toString();
            traits[4] = '" }, { "trait_type": "Line ';
            traits[5] = lineNum.toString();
            traits[6] = ' Noun", "value": "';
            traits[7] = wordSyllables[1].toString();
            traits[8] = '" }';

            string memory startTraitsStr = string(abi.encodePacked(traits[0], traits[1], traits[2], traits[3], traits[4]));
            string memory traitsStr = string(abi.encodePacked(startTraitsStr, traits[5], traits[6], traits[7], traits[8]));
            string memory line = string(abi.encodePacked(lineParts[0], ' ', lineParts[1]));
            
            return (line, traitsStr);
        } else {
            string[4] memory lineParts;
            uint256[4] memory wordSyllables;
            (lineParts[0], lineParts[1], lineParts[2], lineParts[3], wordSyllables[0], wordSyllables[1], wordSyllables[2], wordSyllables[3]) = getSevenSyllableLine(tokenId, 2);

            if (wordSyllables[0] == 1) {
                lineParts[0] = getWordSVG(lineParts[0], UNCOMMON);
            } else if (wordSyllables[0] == 3) {
                lineParts[0] = getWordSVG(lineParts[0], RARE);
            } else if (wordSyllables[0] == 4) {
                lineParts[0] = getWordSVG(lineParts[0], LEGENDARY);
            } else {
                lineParts[0] = string(abi.encodePacked(lineParts[0]));
            }

            if (wordSyllables[2] == 1) {
                lineParts[2] = getWordSVG(lineParts[2], EPIC);
            } else if (wordSyllables[2] == 2) {
                lineParts[2] = string(abi.encodePacked(lineParts[2]));
            } else if (wordSyllables[2] == 3) {
                lineParts[2] = getWordSVG(lineParts[2], RARE);
            } else if (wordSyllables[2] == 4) {
                lineParts[2] = getWordSVG(lineParts[2], LEGENDARY);
            }

            if (wordSyllables[3] == 3) {
                lineParts[3] = getWordSVG(lineParts[3], UNCOMMON);
            } else if (wordSyllables[3] == 4) {
                lineParts[3] = getWordSVG(lineParts[3], EPIC);
            } else {
                lineParts[3] = string(abi.encodePacked(lineParts[3]));
            }

            string[9] memory traits;
            traits[0] = '{ "trait_type": "Line 2 Verb", "value": "';
            traits[1] = wordSyllables[0].toString();
            traits[2] = '" }, { "trait_type": "Line 2 Preposition", "value": "';
            traits[3] = wordSyllables[1].toString();
            traits[4] = '" }, { "trait_type": "Line 2 Adjective", "value": "';
            traits[5] = wordSyllables[2].toString();
            traits[6] = '" }, { "trait_type": "Line 2 Noun", "value": "';
            traits[7] = wordSyllables[3].toString();
            traits[8] = '" }';

            string memory startTraitsStr = string(abi.encodePacked(traits[0], traits[1], traits[2], traits[3], traits[4]));
            string memory traitsStr = string(abi.encodePacked(startTraitsStr, traits[5], traits[6], traits[7], traits[8]));
            string memory line2 = string(abi.encodePacked(lineParts[0], ' ', lineParts[1], ' ', lineParts[2], ' ', lineParts[3]));
            
            return (line2, traitsStr);
        }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOneSyllableNouns {
  function getRandomNoun(uint256 tokenId, uint256 seedNum) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITwoSyllableNouns {
  function getRandomNoun(uint256 tokenId, uint256 seedNum) external view returns (string memory);
}