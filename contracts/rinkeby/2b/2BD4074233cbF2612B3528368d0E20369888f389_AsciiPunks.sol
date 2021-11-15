// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC165 {
  mapping(bytes4 => bool) private _supportedInterfaces;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }
}

library AsciiPunkFactory {
  uint256 private constant TOP_COUNT = 55;
  uint256 private constant EYE_COUNT = 48;
  uint256 private constant NOSE_COUNT = 9;
  uint256 private constant MOUTH_COUNT = 32;

  function draw(uint256 seed) internal pure returns (string memory) {
    uint256 rand = uint256(keccak256(abi.encodePacked(seed)));

    string memory top = _chooseTop(rand);
    string memory eyes = _chooseEyes(rand);
    string memory mouth = _chooseMouth(rand);

    string memory chin = unicode"   │    │   \n" unicode"   └──┘ │   \n";
    string memory neck = unicode"     │  │   \n" unicode"     │  │   \n";

    return string(abi.encodePacked(top, eyes, mouth, chin, neck));
  }

  function _chooseTop(uint256 rand) internal pure returns (string memory) {
    string[TOP_COUNT] memory tops =
      [
        unicode"   ┌───┐    \n"
        unicode"   │   ┼┐   \n"
        unicode"   ├────┼┼  \n",
        unicode"   ┌┬┬┬┬┐   \n"
        unicode"   ╓┬┬┬┬╖   \n"
        unicode"   ╙┴┴┴┴╜   \n",
        unicode"   ╒════╕   \n"
        unicode"  ┌┴────┴┐  \n"
        unicode"  └┬────┬┘  \n",
        unicode"   ╒════╕   \n"
        unicode"   │□□□□│   \n"
        unicode"  └┬────┬┘  \n",
        unicode"   ╒════╕   \n"
        unicode"   │    │   \n"
        unicode" └─┬────┬─┘ \n",
        unicode"    ◙◙◙◙    \n"
        unicode"   ▄████▄   \n"
        unicode"   ┌────┐   \n",
        unicode"   ┌───┐    \n"
        unicode"┌──┤   └┐   \n"
        unicode"└──┼────┤   \n",
        unicode"    ┌───┐   \n"
        unicode"   ┌┘   ├──┐\n"
        unicode"   ├────┼──┘\n",
        unicode"   ┌────┐/  \n"
        unicode"┌──┴────┴──┐\n"
        unicode"└──┬────┬──┘\n",
        unicode"   ╒════╕   \n"
        unicode" ┌─┴────┴─┐ \n"
        unicode" └─┬────┬─┘ \n",
        unicode"  ┌──────┐  \n"
        unicode"  │▲▲▲▲▲▲│  \n"
        unicode"  └┬────┬┘  \n",
        unicode"  ┌┌────┐┐  \n"
        unicode"  ││┌──┐││  \n"
        unicode"  └┼┴──┴┼┘  \n",
        unicode"   ┌────┐   \n"
        unicode"  ┌┘─   │   \n"
        unicode"  └┌────┐   \n",
        unicode"            \n"
        unicode"   ┌┬┬┬┬┐   \n"
        unicode"   ├┴┴┴┴┤   \n",
        unicode"            \n"
        unicode"    ╓┬╥┐    \n"
        unicode"   ┌╨┴╨┴┐   \n",
        unicode"            \n"
        unicode"   ╒╦╦╦╦╕   \n"
        unicode"   ╞╩╩╩╩╡   \n",
        unicode"            \n"
        unicode"            \n"
        unicode"   ┌┼┼┼┼┐   \n",
        unicode"            \n"
        unicode"    ││││    \n"
        unicode"   ┌┼┼┼┼┐   \n",
        unicode"      ╔     \n"
        unicode"     ╔║     \n"
        unicode"   ┌─╫╫─┐   \n",
        unicode"            \n"
        unicode"    ║║║║    \n"
        unicode"   ┌╨╨╨╨┐   \n",
        unicode"            \n"
        unicode"   ▐▐▐▌▌▌   \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"   \\/////   \n"
        unicode"   ┌────┐   \n",
        unicode"    ┐ ┌     \n"
        unicode"   ┐││││┌   \n"
        unicode"   ┌────┐   \n",
        unicode"  ┌┐ ┐┌┐┌┐  \n"
        unicode"  └└┐││┌┘   \n"
        unicode"   ┌┴┴┴┴┐   \n",
        unicode"  ┐┐┐┐┐     \n"
        unicode"  └└└└└┐    \n"
        unicode"   └└└└└┐   \n",
        unicode"            \n"
        unicode"   ││││││   \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"    ╓╓╓╓    \n"
        unicode"   ┌╨╨╨╨┐   \n",
        unicode"    ╔╔╗╗╗   \n"
        unicode"   ╔╔╔╗╗╗╗  \n"
        unicode"  ╔╝╝║ ╚╚╗  \n",
        unicode"   ╔╔╔╔╔╗   \n"
        unicode"  ╔╔╔╔╔╗║╗  \n"
        unicode"  ╝║╨╨╨╨║╚  \n",
        unicode"   ╔╔═╔═╔   \n"
        unicode"   ╔╩╔╩╔╝   \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"     ///    \n"
        unicode"   ┌────┐   \n",
        unicode"     ╔╗╔╗   \n"
        unicode"    ╔╗╔╗╝   \n"
        unicode"   ┌╔╝╔╝┐   \n",
        unicode"     ╔╔╔╔╝  \n"
        unicode"    ╔╝╔╝    \n"
        unicode"   ┌╨╨╨─┐   \n",
        unicode"       ╔╗   \n"
        unicode"    ╔╔╔╗╝   \n"
        unicode"   ┌╚╚╝╝┐   \n",
        unicode"   ╔════╗   \n"
        unicode"  ╔╚╚╚╝╝╝╗  \n"
        unicode"  ╟┌────┐╢  \n",
        unicode"    ╔═╗     \n"
        unicode"    ╚╚╚╗    \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"            \n"
        unicode"   ┌╨╨╨╨┐   \n",
        unicode"            \n"
        unicode"    ⌂⌂⌂⌂    \n"
        unicode"   ┌────┐   \n",
        unicode"   ┌────┐   \n"
        unicode"   │   /└┐  \n"
        unicode"   ├────┐/  \n",
        unicode"            \n"
        unicode"   ((((((   \n"
        unicode"   ┌────┐   \n",
        unicode"   ┌┌┌┌┌┐   \n"
        unicode"   ├┘┘┘┘┘   \n"
        unicode"   ┌────┐   \n",
        unicode"   «°┐      \n"
        unicode"    │╪╕     \n"
        unicode"   ┌└┼──┐   \n",
        unicode"  <° °>   § \n"
        unicode"   \\'/   /  \n"
        unicode"   {())}}   \n",
        unicode"   ██████   \n"
        unicode"  ██ ██ ██  \n"
        unicode" █ ██████ █ \n",
        unicode"    ████    \n"
        unicode"   ██◙◙██   \n"
        unicode"   ┌─▼▼─┐   \n",
        unicode"   ╓╖  ╓╖   \n"
        unicode"  °╜╚╗╔╝╙°  \n"
        unicode"   ┌─╨╨─┐   \n",
        unicode"   ± ±± ±   \n"
        unicode"   ◙◙◙◙◙◙   \n"
        unicode"   ┌────┐   \n",
        unicode"  ♫     ♪   \n"
        unicode"    ♪     ♫ \n"
        unicode" ♪ ┌────┐   \n",
        unicode"    /≡≡\\    \n"
        unicode"   /≡≡≡≡\\   \n"
        unicode"  /┌────┐\\  \n",
        unicode"            \n"
        unicode"   ♣♥♦♠♣♥   \n"
        unicode"   ┌────┐   \n",
        unicode"     [⌂]    \n"
        unicode"      │     \n"
        unicode"   ┌────┐   \n",
        unicode"  /\\/\\/\\/\\  \n"
        unicode"  \\\\/\\/\\//  \n"
        unicode"   ┌────┐   \n",
        unicode"    ↑↑↓↓    \n"
        unicode"   ←→←→AB   \n"
        unicode"   ┌────┐   \n",
        unicode"    ┌─┬┐    \n"
        unicode"   ┌┘┌┘└┐   \n"
        unicode"   ├─┴──┤   \n",
        unicode"    ☼  ☼    \n"
        unicode"     \\/     \n"
        unicode"   ┌────┐   \n"
      ];
    uint256 topId = rand % TOP_COUNT;
    return tops[topId];
  }

  function _chooseEyes(uint256 rand) internal pure returns (string memory) {
    string[EYE_COUNT] memory leftEyes =
      [
        unicode"◕",
        unicode"*",
        unicode"♥",
        unicode"X",
        unicode"⊙",
        unicode"˘",
        unicode"α",
        unicode"◉",
        unicode"☻",
        unicode"¬",
        unicode"^",
        unicode"═",
        unicode"┼",
        unicode"┬",
        unicode"■",
        unicode"─",
        unicode"û",
        unicode"╜",
        unicode"δ",
        unicode"│",
        unicode"┐",
        unicode"┌",
        unicode"┌",
        unicode"╤",
        unicode"/",
        unicode"\\",
        unicode"/",
        unicode"\\",
        unicode"╦",
        unicode"♥",
        unicode"♠",
        unicode"♦",
        unicode"╝",
        unicode"◄",
        unicode"►",
        unicode"◄",
        unicode"►",
        unicode"I",
        unicode"╚",
        unicode"╔",
        unicode"╙",
        unicode"╜",
        unicode"╓",
        unicode"╥",
        unicode"$",
        unicode"○",
        unicode"N",
        unicode"x"
      ];

    string[EYE_COUNT] memory rightEyes =
      [
        unicode"◕",
        unicode"*",
        unicode"♥",
        unicode"X",
        unicode"⊙",
        unicode"˘",
        unicode"α",
        unicode"◉",
        unicode"☻",
        unicode"¬",
        unicode"^",
        unicode"═",
        unicode"┼",
        unicode"┬",
        unicode"■",
        unicode"─",
        unicode"û",
        unicode"╜",
        unicode"δ",
        unicode"│",
        unicode"┐",
        unicode"┐",
        unicode"┌",
        unicode"╤",
        unicode"\\",
        unicode"/",
        unicode"/",
        unicode"\\",
        unicode"╦",
        unicode"♠",
        unicode"♣",
        unicode"♦",
        unicode"╝",
        unicode"►",
        unicode"◄",
        unicode"◄",
        unicode"◄",
        unicode"I",
        unicode"╚",
        unicode"╗",
        unicode"╜",
        unicode"╜",
        unicode"╓",
        unicode"╥",
        unicode"$",
        unicode"○",
        unicode"N",
        unicode"x"
      ];
    uint256 eyeId = rand % EYE_COUNT;

    string memory leftEye = leftEyes[eyeId];
    string memory rightEye = rightEyes[eyeId];
    string memory nose = _chooseNose(rand);

    string memory forehead = unicode"   │    ├┐  \n";
    string memory leftFace = unicode"   │";
    string memory rightFace = unicode" └│  \n";

    return
      string(
        abi.encodePacked(
          forehead,
          leftFace,
          leftEye,
          " ",
          rightEye,
          rightFace,
          nose
        )
      );
  }

  function _chooseMouth(uint256 rand) internal pure returns (string memory) {
    string[MOUTH_COUNT] memory mouths =
      [
        unicode"   │    │   \n"
        unicode"   │──  │   \n",
        unicode"   │    │   \n"
        unicode"   │δ   │   \n",
        unicode"   │    │   \n"
        unicode"   │─┬  │   \n",
        unicode"   │    │   \n"
        unicode"   │(─) │   \n",
        unicode"   │    │   \n"
        unicode"   │[─] │   \n",
        unicode"   │    │   \n"
        unicode"   │<─> │   \n",
        unicode"   │    │   \n"
        unicode"   │╙─  │   \n",
        unicode"   │    │   \n"
        unicode"   │─╜  │   \n",
        unicode"   │    │   \n"
        unicode"   │└─┘ │   \n",
        unicode"   │    │   \n"
        unicode"   │┌─┐ │   \n",
        unicode"   │    │   \n"
        unicode"   │╓─  │   \n",
        unicode"   │    │   \n"
        unicode"   │─╖  │   \n",
        unicode"   │    │   \n"
        unicode"   │┼─┼ │   \n",
        unicode"   │    │   \n"
        unicode"   │──┼ │   \n",
        unicode"   │    │   \n"
        unicode"   │«─» │   \n",
        unicode"   │    │   \n"
        unicode"   │──  │   \n",
        unicode" ∙ │    │   \n"
        unicode" ∙───   │   \n",
        unicode" ∙ │    │   \n"
        unicode" ∙───)  │   \n",
        unicode" ∙ │    │   \n"
        unicode" ∙───]  │   \n",
        unicode"   │⌐¬  │   \n"
        unicode" √────  │   \n",
        unicode"   │╓╖  │   \n"
        unicode"   │──  │   \n",
        unicode"   │~~  │   \n"
        unicode"   │/\\  │   \n",
        unicode"   │    │   \n"
        unicode"   │══  │   \n",
        unicode"   │    │   \n"
        unicode"   │▼▼  │   \n",
        unicode"   │⌐¬  │   \n"
        unicode"   │O   │   \n",
        unicode"   │    │   \n"
        unicode"   │O   │   \n",
        unicode" ∙ │⌐¬  │   \n"
        unicode" ∙───   │   \n",
        unicode" ∙ │⌐¬  │   \n"
        unicode" ∙───)  │   \n",
        unicode" ∙ │⌐¬  │   \n"
        unicode" ∙───]  │   \n",
        unicode"   │⌐¬  │   \n"
        unicode"   │──  │   \n",
        unicode"   │⌐-¬ │   \n"
        unicode"   │    │   \n",
        unicode"   │┌-┐ │   \n"
        unicode"   ││ │ │   \n"
      ];

    uint256 mouthId = rand % MOUTH_COUNT;

    return mouths[mouthId];
  }

  function _chooseNose(uint256 rand) internal pure returns (string memory) {
    string[NOSE_COUNT] memory noses =
      [
        unicode"└",
        unicode"╘",
        unicode"<",
        unicode"└",
        unicode"┌",
        unicode"^",
        unicode"└",
        unicode"┼",
        unicode"Γ"
      ];

    uint256 noseId = rand % NOSE_COUNT;
    string memory nose = noses[noseId];
    return string(abi.encodePacked(unicode"   │ ", nose, unicode"  └┘  \n"));
  }
}

contract ERC721Metadata is Ownable, ERC165 {
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  string private _baseTokenURI;
  string private _NFTName = "AsciiPunks";
  string private _NFTSymbol = "ASC";

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _baseTokenURI = "https://api.asciipunks.com/punks/";
  }

  function name() external view returns (string memory) {
    return _NFTName;
  }

  function symbol() external view returns (string memory) {
    return _NFTSymbol;
  }

  function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
    _baseTokenURI = newBaseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function _baseURI() internal view returns (string memory) {
    return _baseTokenURI;
  }
}

contract PaymentSplitter is Context {
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  constructor() {
    address[2] memory initialPayees =
      [
        address(0x9386efb02a55A1092dC19f0E68a9816DDaAbDb5b),
        address(0xF2353AD0930B9F7cf16b4b8300B843349581E817)
      ];
    uint256[2] memory initialShares = [uint256(7), uint256(3)];

    for (uint256 i = 0; i < initialPayees.length; i++) {
      _addPayee(initialPayees[i], initialShares[i]);
    }
  }

  receive() external payable {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  function release(address payable account) public virtual {
    require(_shares[account] > 0, "PaymentSplitter: account has no shares");

    uint256 totalReceived = address(this).balance + _totalReleased;
    uint256 payment =
      (totalReceived * _shares[account]) / _totalShares - _released[account];

    require(payment != 0, "PaymentSplitter: account is not due payment");

    _released[account] = _released[account] + payment;
    _totalReleased = _totalReleased + payment;

    Address.sendValue(account, payment);
    emit PaymentReleased(account, payment);
  }

  function _addPayee(address account, uint256 shares_) private {
    require(
      account != address(0),
      "PaymentSplitter: account is the zero address"
    );
    require(shares_ > 0, "PaymentSplitter: shares are 0");
    require(
      _shares[account] == 0,
      "PaymentSplitter: account already has shares"
    );

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit PayeeAdded(account, shares_);
  }
}

contract AsciiPunks is ERC721Metadata, PaymentSplitter {
  using Address for address;
  using Strings for uint256;

  // EVENTS
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  event Generated(uint256 indexed index, address indexed a, string value);

  mapping(uint256 => uint256) internal idToSeed;
  mapping(uint256 => uint256) internal seedToId;
  mapping(uint256 => address) internal idToOwner;
  mapping(address => uint256[]) internal ownerToIds;
  mapping(uint256 => uint256) internal idToOwnerIndex;
  mapping(address => mapping(address => bool)) internal ownerToOperators;
  mapping(uint256 => address) internal idToApproval;
  uint256 internal numTokens = 0;
  uint256 public constant TOKEN_LIMIT = 2048;
  bool public hasSaleStarted = false;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

  modifier validNFToken(uint256 tokenId) {
    require(
      idToOwner[tokenId] != address(0),
      "ERC721: query for nonexistent token"
    );
    _;
  }

  modifier canOperate(uint256 tokenId) {
    address owner = idToOwner[tokenId];

    require(
      owner == _msgSender() || ownerToOperators[owner][_msgSender()],
      "ERC721: approve caller is not owner nor approved for all"
    );
    _;
  }

  modifier canTransfer(uint256 tokenId) {
    address tokenOwner = idToOwner[tokenId];

    require(
      tokenOwner == _msgSender() ||
        idToApproval[tokenId] == _msgSender() ||
        ownerToOperators[tokenOwner][_msgSender()],
      "ERC721: transfer caller is not owner nor approved"
    );
    _;
  }

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  function createPunk(uint256 seed) external payable returns (string memory) {
    return _mint(_msgSender(), seed);
  }

  function calculatePrice() internal view returns (uint256) {
    uint256 price;
    if (numTokens < 256) {
      price = 50000000000000000;
    } else if (numTokens >= 256 && numTokens < 512) {
      price = 100000000000000000;
    } else if (numTokens >= 512 && numTokens < 1024) {
      price = 200000000000000000;
    } else if (numTokens >= 1024 && numTokens < 1536) {
      price = 300000000000000000;
    } else {
      price = 400000000000000000;
    }
    return price;
  }

  function _mint(address to, uint256 _seed) internal returns (string memory) {
    require(hasSaleStarted == true, "Sale hasn't started");
    require(to != address(0), "ERC721: mint to the zero address");
    require(
      numTokens < TOKEN_LIMIT,
      "ERC721: maximum number of tokens already minted"
    );
    require(msg.value >= calculatePrice(), "ERC721: insufficient ether");

    uint256 seed = uint256(
      keccak256(abi.encodePacked(_seed, block.timestamp, msg.sender, numTokens))
    );

    require(seedToId[seed] == 0, "ERC721: seed already used");

    uint256 id = numTokens + 1;

    idToSeed[id] = seed;
    seedToId[seed] = id;

    string memory punk = AsciiPunkFactory.draw(idToSeed[id]);
    emit Generated(id, to, punk);

    numTokens = numTokens + 1;
    _registerToken(to, id);

    emit Transfer(address(0), to, id);

    return punk;
  }

  function _registerToken(address to, uint256 tokenId) internal {
    require(idToOwner[tokenId] == address(0));
    idToOwner[tokenId] = to;

    ownerToIds[to].push(tokenId);
    uint256 length = ownerToIds[to].length;
    idToOwnerIndex[tokenId] = length - 1;
  }

  function draw(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (string memory)
  {
    string memory uri = AsciiPunkFactory.draw(idToSeed[tokenId]);
    return uri;
  }

  function totalSupply() public view returns (uint256) {
    return numTokens;
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < numTokens, "ERC721Enumerable: global index out of bounds");
    return index;
  }

  function tokenOfOwnerByIndex(address owner, uint256 _index)
    external
    view
    returns (uint256)
  {
    require(
      _index < ownerToIds[owner].length,
      "ERC721Enumerable: owner index out of bounds"
    );
    return ownerToIds[owner][_index];
  }

  function balanceOf(address owner) external view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return ownerToIds[owner].length;
  }

  function ownerOf(uint256 tokenId) external view returns (address) {
    return _ownerOf(tokenId);
  }

  function _ownerOf(uint256 tokenId)
    internal
    view
    validNFToken(tokenId)
    returns (address)
  {
    address owner = idToOwner[tokenId];
    require(owner != address(0), "ERC721: query for nonexistent token");
    return owner;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external validNFToken(tokenId) canTransfer(tokenId) {
    address tokenOwner = idToOwner[tokenId];
    require(tokenOwner == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");
    _transfer(to, tokenId);
  }

  function _transfer(address to, uint256 tokenId) internal {
    address from = idToOwner[tokenId];
    _clearApproval(tokenId);
    emit Approval(from, to, tokenId);

    _removeNFToken(from, tokenId);
    _registerToken(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  function _removeNFToken(address from, uint256 tokenId) internal {
    require(idToOwner[tokenId] == from);
    delete idToOwner[tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[tokenId];
    uint256 lastTokenIndex = ownerToIds[from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex) {
      uint256 lastToken = ownerToIds[from][lastTokenIndex];
      ownerToIds[from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[from].pop();
  }

  function approve(address approved, uint256 tokenId)
    external
    validNFToken(tokenId)
    canOperate(tokenId)
  {
    address owner = idToOwner[tokenId];
    require(approved != owner, "ERC721: approval to current owner");
    idToApproval[tokenId] = approved;
    emit Approval(owner, approved, tokenId);
  }

  function _clearApproval(uint256 tokenId) private {
    if (idToApproval[tokenId] != address(0)) {
      delete idToApproval[tokenId];
    }
  }

  function getApproved(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (address)
  {
    return idToApproval[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) external {
    require(operator != _msgSender(), "ERC721: approve to caller");
    ownerToOperators[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool)
  {
    return ownerToOperators[owner][operator];
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external {
    _safeTransferFrom(from, to, tokenId, data);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    _safeTransferFrom(from, to, tokenId, "");
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private validNFToken(tokenId) canTransfer(tokenId) {
    address tokenOwner = idToOwner[tokenId];
    require(tokenOwner == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _transfer(to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function tokenURI(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (string memory)
  {
    string memory uri = _baseURI();
    return
      bytes(uri).length > 0
        ? string(abi.encodePacked(uri, tokenId.toString()))
        : "";
  }

  function startSale() public onlyOwner {
    hasSaleStarted = true;
  }

  function pauseSale() public onlyOwner {
    hasSaleStarted = false;
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }
}

