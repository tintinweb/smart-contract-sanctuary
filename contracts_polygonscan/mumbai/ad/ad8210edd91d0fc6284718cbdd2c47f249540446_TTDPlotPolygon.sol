pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721.sol";
import "./PerlinNoise.sol";

contract TTDPlotPolygon is ERC721, Ownable {
    int256 public constant WORLD_SEED = 9000;
    int256 public constant COORDINATE_MULTIPLIER = (65536 / (64 / 2));

    constructor() ERC721("TTDPlot", "TTP") {}

    function tokenURI(uint256 id) override public view virtual returns (string memory) {
        return string(abi.encodePacked("https://api.google.com/metadata/", uintToString(id))); // TODO: Update URL
    }

    function getPlotCoordinatesForToken(uint256 id) public view virtual returns (uint256, uint256) {
        uint256 x = id >> 16;
        uint256 y = id - (x << 16);
        return (x, y);
    }

    function getTokenForPlotCoordinates(uint256 x, uint256 y) public view virtual returns (uint256) {
       return (x << 16) + y;
    }

    function getRandomnessAtCoord(uint256 x, uint256 y) public view virtual returns (int256) {
        require(x >= 0 && x < 8192, "x coordinate out of bounds");
        require(y >= 0 && y < 8192, "y coordinate out of bounds");

        int256 n3d = PerlinNoise.noise3d(int256(x) * COORDINATE_MULTIPLIER, int256(y) * COORDINATE_MULTIPLIER, WORLD_SEED);
        return n3d;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

/**
 * @notice An implementation of Perlin Noise that uses 16 bit fixed point arithmetic.
 */
library PerlinNoise {

    /**
     * @notice Computes the noise value for a 2D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise2d(int256 x, int256 y) public pure returns (int256) {
        int256 temp = ptable(x >> 16 & 0xff /* Unit square X */);

        int256 a = ptable((temp >> 8  ) + (y >> 16 & 0xff /* Unit square Y */));
        int256 b = ptable((temp & 0xff) + (y >> 16 & 0xff                    ));

        x &= 0xffff; // Square relative X
        y &= 0xffff; // Square relative Y

        int256 u = fade(x);

        int256 c = lerp(u, grad2(a >> 8  , x, y        ), grad2(b >> 8  , x-0x10000, y        ));
        int256 d = lerp(u, grad2(a & 0xff, x, y-0x10000), grad2(b & 0xff, x-0x10000, y-0x10000));

        return lerp(fade(y), c, d);
    }

    /**
     * @notice Computes the noise value for a 3D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     * @param z the z coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise3d(int256 x, int256 y, int256 z) public pure returns (int256) {
        int256[7] memory scratch = [
            x >> 16 & 0xff,  // Unit cube X
            y >> 16 & 0xff,  // Unit cube Y
            z >> 16 & 0xff,  // Unit cube Z
            0, 0, 0, 0
        ];

        x &= 0xffff; // Cube relative X
        y &= 0xffff; // Cube relative Y
        z &= 0xffff; // Cube relative Z

        // Temporary variables used for intermediate calculations.
        int256 u;
        int256 v;

        v = ptable(scratch[0]);

        u = ptable((v >> 8  ) + scratch[1]);
        v = ptable((v & 0xff) + scratch[1]);

        scratch[3] = ptable((u >> 8  ) + scratch[2]);
        scratch[4] = ptable((u & 0xff) + scratch[2]);
        scratch[5] = ptable((v >> 8  ) + scratch[2]);
        scratch[6] = ptable((v & 0xff) + scratch[2]);

        int256 a;
        int256 b;
        int256 c;

        u = fade(x);
        v = fade(y);

        a = lerp(u, grad3(scratch[3] >> 8, x, y        , z), grad3(scratch[5] >> 8, x-0x10000, y        , z));
        b = lerp(u, grad3(scratch[4] >> 8, x, y-0x10000, z), grad3(scratch[6] >> 8, x-0x10000, y-0x10000, z));
        c = lerp(v, a, b);

        a = lerp(u, grad3(scratch[3] & 0xff, x, y        , z-0x10000), grad3(scratch[5] & 0xff, x-0x10000, y        , z-0x10000));
        b = lerp(u, grad3(scratch[4] & 0xff, x, y-0x10000, z-0x10000), grad3(scratch[6] & 0xff, x-0x10000, y-0x10000, z-0x10000));

        return lerp(fade(z), c, lerp(v, a, b));
    }

    /**
     * @notice Computes the linear interpolation between two values, `a` and `b`, using fixed point arithmetic.
     *
     * @param t the time value of the equation.
     * @param a the lower point.
     * @param b the upper point.
     */
    function lerp(int256 t, int256 a, int256 b) internal pure returns (int256) {
        return a + (t * (b - a) >> 12);
    }

    /**
     * @notice Applies the fade function to a value.
     *
     * @param t the time value of the equation.
     *
     * @dev The polynomial for this function is: 6t^4-15t^4+10t^3.
     */
    function fade(int256 t) internal pure returns (int256) {
        int256 n = ftable(t >> 8);

        // Lerp between the two points grabbed from the fade table.
        (int256 lower, int256 upper) = (n >> 12, n & 0xfff);
        return lower + ((t & 0xff) * (upper - lower) >> 8);
    }

    /**
      * @notice Computes the gradient value for a 2D point.
      *
      * @param h the hash value to use for picking the vector.
      * @param x the x coordinate of the point.
      * @param y the y coordinate of the point.
      */
    function grad2(int256 h, int256 x, int256 y) internal pure returns (int256) {
        h &= 3;

        int256 u;
        if (h & 0x1 == 0) {
            u = x;
        } else {
            u = -x;
        }

        int256 v;
        if (h < 2) {
            v = y;
        } else {
            v = -y;
        }

        return u + v;
    }

    /**
     * @notice Computes the gradient value for a 3D point.
     *
     * @param h the hash value to use for picking the vector.
     * @param x the x coordinate of the point.
     * @param y the y coordinate of the point.
     * @param z the z coordinate of the point.
     */
    function grad3(int256 h, int256 x, int256 y, int256 z) internal pure returns (int256) {
        h &= 0xf;

        int256 u;
        if (h < 8) {
            u = x;
        } else {
            u = y;
        }

        int256 v;
        if (h < 4) {
            v = y;
        } else if (h == 12 || h == 14) {
            v = x;
        } else {
            v = z;
        }

        if ((h & 0x1) != 0) {
            u = -u;
        }

        if ((h & 0x2) != 0) {
            v = -v;
        }

        return u + v;
    }

    /**
     * @notice Gets a subsequent values in the permutation table at an index. The values are encoded
     *         into a single 24 bit integer with the  value at the specified index being the most
     *         significant 12 bits and the subsequent value being the least significant 12 bits.
     *
     * @param i the index in the permutation table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(255).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ptable' script.
     */
    function ptable(int256 i) internal pure returns (int256) {
        i &= 0xff;

        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 38816; } else { return 41097; }
                                } else {
                                    if (i == 2) { return 35163; } else { return 23386; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 23055; } else { return 3971; }
                                } else {
                                    if (i == 6) { return 33549; } else { return 3529; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 51551; } else { return 24416; }
                                } else {
                                    if (i == 10) { return 24629; } else { return 13762; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 49897; } else { return 59655; }
                                } else {
                                    if (i == 14) { return 2017; } else { return 57740; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 35876; } else { return 9319; }
                                } else {
                                    if (i == 18) { return 26398; } else { return 7749; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 17806; } else { return 36360; }
                                } else {
                                    if (i == 22) { return 2147; } else { return 25381; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 9712; } else { return 61461; }
                                } else {
                                    if (i == 26) { return 5386; } else { return 2583; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 6078; } else { return 48646; }
                                } else {
                                    if (i == 30) { return 1684; } else { return 38135; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 63352; } else { return 30954; }
                                } else {
                                    if (i == 34) { return 59979; } else { return 19200; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 26; } else { return 6853; }
                                } else {
                                    if (i == 38) { return 50494; } else { return 15966; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 24316; } else { return 64731; }
                                } else {
                                    if (i == 42) { return 56267; } else { return 52085; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 29987; } else { return 8971; }
                                } else {
                                    if (i == 46) { return 2848; } else { return 8249; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 14769; } else { return 45345; }
                                } else {
                                    if (i == 50) { return 8536; } else { return 22765; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 60821; } else { return 38200; }
                                } else {
                                    if (i == 54) { return 14423; } else { return 22446; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 44564; } else { return 5245; }
                                } else {
                                    if (i == 58) { return 32136; } else { return 34987; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 43944; } else { return 43076; }
                                } else {
                                    if (i == 62) { return 17583; } else { return 44874; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 19109; } else { return 42311; }
                                } else {
                                    if (i == 66) { return 18310; } else { return 34443; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 35632; } else { return 12315; }
                                } else {
                                    if (i == 70) { return 7078; } else { return 42573; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 19858; } else { return 37534; }
                                } else {
                                    if (i == 74) { return 40679; } else { return 59219; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 21359; } else { return 28645; }
                                } else {
                                    if (i == 78) { return 58746; } else { return 31292; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 15571; } else { return 54149; }
                                } else {
                                    if (i == 82) { return 34278; } else { return 59100; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 56425; } else { return 26972; }
                                } else {
                                    if (i == 86) { return 23593; } else { return 10551; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 14126; } else { return 12021; }
                                } else {
                                    if (i == 90) { return 62760; } else { return 10484; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 62566; } else { return 26255; }
                                } else {
                                    if (i == 94) { return 36662; } else { return 13889; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 16665; } else { return 6463; }
                                } else {
                                    if (i == 98) { return 16289; } else { return 41217; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 472; } else { return 55376; }
                                } else {
                                    if (i == 102) { return 20553; } else { return 18897; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 53580; } else { return 19588; }
                                } else {
                                    if (i == 106) { return 33979; } else { return 48080; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 53337; } else { return 22802; }
                                } else {
                                    if (i == 110) { return 4777; } else { return 43464; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 51396; } else { return 50311; }
                                } else {
                                    if (i == 114) { return 34690; } else { return 33396; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 29884; } else { return 48287; }
                                } else {
                                    if (i == 118) { return 40790; } else { return 22180; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 42084; } else { return 25709; }
                                } else {
                                    if (i == 122) { return 28102; } else { return 50861; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 44474; } else { return 47619; }
                                } else {
                                    if (i == 126) { return 832; } else { return 16436; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 13529; } else { return 55778; }
                                } else {
                                    if (i == 130) { return 58106; } else { return 64124; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 31867; } else { return 31493; }
                                } else {
                                    if (i == 134) { return 1482; } else { return 51750; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9875; } else { return 37750; }
                                } else {
                                    if (i == 138) { return 30334; } else { return 32511; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 65362; } else { return 21077; }
                                } else {
                                    if (i == 142) { return 21972; } else { return 54479; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 53198; } else { return 52795; }
                                } else {
                                    if (i == 146) { return 15331; } else { return 58159; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 12048; } else { return 4154; }
                                } else {
                                    if (i == 150) { return 14865; } else { return 4534; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 46781; } else { return 48412; }
                                } else {
                                    if (i == 154) { return 7210; } else { return 10975; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 57271; } else { return 47018; }
                                } else {
                                    if (i == 158) { return 43733; } else { return 54647; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 30712; } else { return 63640; }
                                } else {
                                    if (i == 162) { return 38914; } else { return 556; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 11418; } else { return 39587; }
                                } else {
                                    if (i == 166) { return 41798; } else { return 18141; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 56729; } else { return 39269; }
                                } else {
                                    if (i == 170) { return 26011; } else { return 39847; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 42795; } else { return 11180; }
                                } else {
                                    if (i == 174) { return 44041; } else { return 2433; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 33046; } else { return 5671; }
                                } else {
                                    if (i == 178) { return 10237; } else { return 64787; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 4962; } else { return 25196; }
                                } else {
                                    if (i == 182) { return 27758; } else { return 28239; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 20337; } else { return 29152; }
                                } else {
                                    if (i == 186) { return 57576; } else { return 59570; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 45753; } else { return 47472; }
                                } else {
                                    if (i == 190) { return 28776; } else { return 26842; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 56054; } else { return 63073; }
                                } else {
                                    if (i == 194) { return 25060; } else { return 58619; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 64290; } else { return 8946; }
                                } else {
                                    if (i == 198) { return 62145; } else { return 49646; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 61138; } else { return 53904; }
                                } else {
                                    if (i == 202) { return 36876; } else { return 3263; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 49075; } else { return 45986; }
                                } else {
                                    if (i == 206) { return 41713; } else { return 61777; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 20787; } else { return 13201; }
                                } else {
                                    if (i == 210) { return 37355; } else { return 60409; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 63758; } else { return 3823; }
                                } else {
                                    if (i == 214) { return 61291; } else { return 27441; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 12736; } else { return 49366; }
                                } else {
                                    if (i == 218) { return 54815; } else { return 8117; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 46535; } else { return 51050; }
                                } else {
                                    if (i == 222) { return 27293; } else { return 40376; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 47188; } else { return 21708; }
                                } else {
                                    if (i == 226) { return 52400; } else { return 45171; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 29561; } else { return 31026; }
                                } else {
                                    if (i == 230) { return 12845; } else { return 11647; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 32516; } else { return 1174; }
                                } else {
                                    if (i == 234) { return 38654; } else { return 65162; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 35564; } else { return 60621; }
                                } else {
                                    if (i == 238) { return 52573; } else { return 24030; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 56946; } else { return 29251; }
                                } else {
                                    if (i == 242) { return 17181; } else { return 7448; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 6216; } else { return 18675; }
                                } else {
                                    if (i == 246) { return 62349; } else { return 36224; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 32963; } else { return 49998; }
                                } else {
                                    if (i == 250) { return 20034; } else { return 17111; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 55101; } else { return 15772; }
                                } else {
                                    if (i == 254) { return 40116; } else { return 46231; }
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    /**
     * @notice Gets subsequent values in the fade table at an index. The values are encoded
     *         into a single 16 bit integer with the value at the specified index being the most
     *         significant 8 bits and the subsequent value being the least significant 8 bits.
     *
     * @param i the index in the fade table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(256).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ftable' script.
     */
    function ftable(int256 i) internal pure returns (int256) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 0; } else { return 0; }
                                } else {
                                    if (i == 2) { return 0; } else { return 0; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 0; } else { return 0; }
                                } else {
                                    if (i == 6) { return 0; } else { return 1; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 4097; } else { return 4098; }
                                } else {
                                    if (i == 10) { return 8195; } else { return 12291; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 12292; } else { return 16390; }
                                } else {
                                    if (i == 14) { return 24583; } else { return 28681; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 36874; } else { return 40972; }
                                } else {
                                    if (i == 18) { return 49166; } else { return 57361; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 69651; } else { return 77846; }
                                } else {
                                    if (i == 22) { return 90137; } else { return 102429; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 118816; } else { return 131108; }
                                } else {
                                    if (i == 26) { return 147496; } else { return 163885; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 184369; } else { return 200758; }
                                } else {
                                    if (i == 30) { return 221244; } else { return 245825; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 266311; } else { return 290893; }
                                } else {
                                    if (i == 34) { return 315476; } else { return 344155; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 372834; } else { return 401513; }
                                } else {
                                    if (i == 38) { return 430193; } else { return 462969; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 495746; } else { return 532619; }
                                } else {
                                    if (i == 42) { return 569492; } else { return 606366; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 647335; } else { return 684210; }
                                } else {
                                    if (i == 46) { return 729276; } else { return 770247; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 815315; } else { return 864478; }
                                } else {
                                    if (i == 50) { return 909546; } else { return 958711; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 1011971; } else { return 1061137; }
                                } else {
                                    if (i == 54) { return 1118494; } else { return 1171756; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 1229114; } else { return 1286473; }
                                } else {
                                    if (i == 58) { return 1347928; } else { return 1409383; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 1470838; } else { return 1532294; }
                                } else {
                                    if (i == 62) { return 1597847; } else { return 1667496; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 1737145; } else { return 1806794; }
                                } else {
                                    if (i == 66) { return 1876444; } else { return 1950190; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 2023936; } else { return 2097683; }
                                } else {
                                    if (i == 70) { return 2175526; } else { return 2253370; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 2335309; } else { return 2413153; }
                                } else {
                                    if (i == 74) { return 2495094; } else { return 2581131; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 2667168; } else { return 2753205; }
                                } else {
                                    if (i == 78) { return 2839243; } else { return 2929377; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 3019511; } else { return 3109646; }
                                } else {
                                    if (i == 82) { return 3203877; } else { return 3298108; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 3392339; } else { return 3486571; }
                                } else {
                                    if (i == 86) { return 3584899; } else { return 3683227; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 3781556; } else { return 3883981; }
                                } else {
                                    if (i == 90) { return 3986406; } else { return 4088831; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 4191257; } else { return 4297778; }
                                } else {
                                    if (i == 94) { return 4400204; } else { return 4506727; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 4617345; } else { return 4723868; }
                                } else {
                                    if (i == 98) { return 4834487; } else { return 4945106; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 5055725; } else { return 5166345; }
                                } else {
                                    if (i == 102) { return 5281060; } else { return 5391680; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 5506396; } else { return 5621112; }
                                } else {
                                    if (i == 106) { return 5735829; } else { return 5854641; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 5969358; } else { return 6088171; }
                                } else {
                                    if (i == 110) { return 6206983; } else { return 6321700; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 6440514; } else { return 6563423; }
                                } else {
                                    if (i == 114) { return 6682236; } else { return 6801050; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 6923959; } else { return 7042773; }
                                } else {
                                    if (i == 118) { return 7165682; } else { return 7284496; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 7407406; } else { return 7530316; }
                                } else {
                                    if (i == 122) { return 7653226; } else { return 7776136; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 7899046; } else { return 8021956; }
                                } else {
                                    if (i == 126) { return 8144866; } else { return 8267776; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 8390685; } else { return 8509499; }
                                } else {
                                    if (i == 130) { return 8632409; } else { return 8755319; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 8878229; } else { return 9001139; }
                                } else {
                                    if (i == 134) { return 9124049; } else { return 9246959; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9369869; } else { return 9492778; }
                                } else {
                                    if (i == 138) { return 9611592; } else { return 9734501; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 9853315; } else { return 9976224; }
                                } else {
                                    if (i == 142) { return 10095037; } else { return 10213851; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 10336760; } else { return 10455572; }
                                } else {
                                    if (i == 146) { return 10570289; } else { return 10689102; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 10807914; } else { return 10922631; }
                                } else {
                                    if (i == 150) { return 11041443; } else { return 11156159; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 11270875; } else { return 11385590; }
                                } else {
                                    if (i == 154) { return 11496210; } else { return 11610925; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 11721544; } else { return 11832163; }
                                } else {
                                    if (i == 158) { return 11942782; } else { return 12053400; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 12159923; } else { return 12270541; }
                                } else {
                                    if (i == 162) { return 12377062; } else { return 12479488; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 12586009; } else { return 12688434; }
                                } else {
                                    if (i == 166) { return 12790859; } else { return 12893284; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 12995708; } else { return 13094036; }
                                } else {
                                    if (i == 170) { return 13192364; } else { return 13290691; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 13384922; } else { return 13479153; }
                                } else {
                                    if (i == 174) { return 13573384; } else { return 13667614; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 13757748; } else { return 13847882; }
                                } else {
                                    if (i == 178) { return 13938015; } else { return 14024052; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 14110089; } else { return 14196126; }
                                } else {
                                    if (i == 182) { return 14282162; } else { return 14364101; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 14441945; } else { return 14523884; }
                                } else {
                                    if (i == 186) { return 14601727; } else { return 14679569; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 14753315; } else { return 14827061; }
                                } else {
                                    if (i == 190) { return 14900806; } else { return 14970456; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 15044200; } else { return 15109753; }
                                } else {
                                    if (i == 194) { return 15179401; } else { return 15244952; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 15306407; } else { return 15367862; }
                                } else {
                                    if (i == 198) { return 15429317; } else { return 15490771; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 15548129; } else { return 15605486; }
                                } else {
                                    if (i == 202) { return 15658748; } else { return 15716104; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 15765269; } else { return 15818529; }
                                } else {
                                    if (i == 206) { return 15867692; } else { return 15912760; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 15961923; } else { return 16006989; }
                                } else {
                                    if (i == 210) { return 16047960; } else { return 16093025; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 16129899; } else { return 16170868; }
                                } else {
                                    if (i == 214) { return 16207741; } else { return 16244614; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 16281486; } else { return 16314262; }
                                } else {
                                    if (i == 218) { return 16347037; } else { return 16375716; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 16404395; } else { return 16433074; }
                                } else {
                                    if (i == 222) { return 16461752; } else { return 16486334; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 16510915; } else { return 16531401; }
                                } else {
                                    if (i == 226) { return 16555982; } else { return 16576466; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 16592855; } else { return 16613339; }
                                } else {
                                    if (i == 230) { return 16629727; } else { return 16646114; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 16658406; } else { return 16674793; }
                                } else {
                                    if (i == 234) { return 16687084; } else { return 16699374; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 16707569; } else { return 16719859; }
                                } else {
                                    if (i == 238) { return 16728053; } else { return 16736246; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 16740344; } else { return 16748537; }
                                } else {
                                    if (i == 242) { return 16752635; } else { return 16760828; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 16764924; } else { return 16764925; }
                                } else {
                                    if (i == 246) { return 16769022; } else { return 16773118; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 16773119; } else { return 16777215; }
                                } else {
                                    if (i == 250) { return 16777215; } else { return 16777215; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 16777215; } else { return 16777215; }
                                } else {
                                    if (i == 254) { return 16777215; } else { return 16777215; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}