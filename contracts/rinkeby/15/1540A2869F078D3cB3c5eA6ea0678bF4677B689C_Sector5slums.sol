// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
interface ERC165 {
	function supportsInterface(bytes4 interfaceID) external view returns(bool);
}
interface ERC721 is ERC165 {
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	function balanceOf(address _owner) external view returns(uint256);
	function ownerOf(uint256 _tokenId) external view returns(address);
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
	function transferFrom(address _from, address _to, uint256 _tokenId) external;
	function approve(address _approved, uint256 _tokenId) external;
	function setApprovedForAll(address _operator, bool _approved) external;
	function isApprovedForAll(address _owner, address _operator) external view returns(bool);
}
interface ERC721TokenReceiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
interface ERC721Metadata is ERC721 {
	function name() external view returns(string memory);
	function symbol() external view returns (string memory);
	function tokenURI(uint256 _tokenId) external view returns(string memory);
}
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}
	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
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
library Address {
	function isContract(address account) internal view returns(bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, 'Address: Insufficient balance');
		(bool success, ) = recipient.call{value:amount}('');
		require(success, 'Address: Unable to send value');
	}
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
		require(address(this). balance >= value, 'Address: Insufficient balance for call');
		require(isContract(target),'Address: Call to non-contract');
		(bool success, bytes memory returndata) = target.call{value:value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	} 
	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
		require(isContract(target), 'Address: Static to non-contract');
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}
	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		require(isContract(target), 'Address: Delegate call to non-contract');
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata,errorMessage);
	}
	function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
		if(success) {
			return returndata;
		} else {
			if(returndata.length > 0) {
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
library Strings {
	bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';
	function toString(uint256 value) internal pure returns(string memory) {
		if(value == 0) {
			return '0';
		}
		uint256 temp = value;
		uint256 digits;
		while(temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while(value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
	function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for(uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[1] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, 'Strings: Hex length insufficient');
		return string(buffer);
	}
}
abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() {
		_setOwner(_msgSender());
	}
	function owner() public view virtual returns(address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), 'Error: not the owner');
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), 'Error: new owner is zero address');
		_setOwner(newOwner);
	}
	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}
contract Sector5slums is VRFConsumerBase, ERC165, ERC721, ERC721TokenReceiver, ERC721Metadata, Context, Ownable {
	using SafeMath for uint256;
	using Address for address;
	using Strings for string;

	string private _name = 'AERITH';
	string private _symbol = 'AERIS';
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

	bytes32 internal _keyHash;
    uint256 internal _fee = 0.1 * 10**18;
    uint256 public randomResult;
    address public _VRFCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;  // rinkeby
    address public _LinkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // rinkeby

    struct Aerith {uint256 Strength; uint256 Magic;  uint256 Vitality; 
    uint256 Spirit; uint256 Luck; uint256 Speed; uint256 Level; string name;}

    Aerith[] public aeriths;

    mapping(bytes32 => string) requestToAerithName;
    mapping(bytes32 => address) requestToSender;
    mapping(bytes32 => uint256) requestTo_tokenId;
	
	mapping(uint256 => string) private _tokenURIs;
	mapping(uint256 => address) private _owners;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => bool)) private _operatorApprovals;
	
	constructor() VRFConsumerBase(_VRFCoordinator, _LinkToken) {
    }
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
		return interfaceId == type(ERC721).interfaceId ||
		interfaceId == type(ERC721TokenReceiver).interfaceId ||
		interfaceId == type(ERC721Metadata).interfaceId ||
		supportsInterface(interfaceId);
	}
	function balanceOf(address _owner) public view virtual override returns(uint256) {
		return _balances[_owner];
	}
	function ownerOf(uint256 _tokenId) public view virtual override returns(address) {
		address _owner = _owners[_tokenId];
		return _owner;
	}
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
		transferFrom(_from, _to, _tokenId);
	}
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public virtual override {
		safeTransferFrom(_from, _to, _tokenId, _data);
	}
	function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
		require(ownerOf(_tokenId) == _from, 'Error: only owner can transfer');
		require(_to != address(0), 'Error: Tranfering to none existing address');
		approve(address(0), _tokenId);
		_balances[_from] -= 1;
		_balances[_to] += 1;
		_owners[_tokenId] = _to;
		emit Transfer(_from, _to, _tokenId);
	}
	function approve(address _to, uint256 _tokenId) public virtual override {
		address _owner = ownerOf(_tokenId);
		require(_to != _owner, 'Error: you are already approved');
		require(_msgSender() == _owner || isApprovedForAll(_owner, _msgSender()), 'Error: not approved');
		_tokenApprovals[_tokenId] = _to;
		emit Approval(ownerOf(_tokenId), _to, _tokenId);
	}
	function setApprovedForAll(address _operator, bool _approved) public virtual override {
		require(_operator != _msgSender(), 'Error: caller is approved');
		_operatorApprovals[_msgSender()][_operator] = _approved;
		emit ApprovalForAll(_msgSender(), _operator, _approved);
	}
	function isApprovedForAll(address _owner, address _operator) public view virtual override returns(bool) {
		return _operatorApprovals[_owner][_operator];
	}
	function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
		return bytes4(keccak256("onERC721Received(address,address,uint256,bytes calldata)"));
	}
	function name() public view virtual override returns(string memory) {
		return _name;
	}
	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}
	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		string memory _tokenURI = _tokenURIs[_tokenId];
		string memory base = baseURI();
		if (bytes(base).length == 0) {
		return _tokenURI;
	}
		if (bytes(_tokenURI).length > 0) {
		return string(abi.encodePacked(base, _tokenURI));
	}
		return tokenURI(_tokenId);
	}
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public {
		baseTokenURI(_tokenId, _tokenURI);
	}
	function baseTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
		_tokenURIs[_tokenId] = _tokenURI;
	}
	function baseURI() internal view virtual returns (string memory) {
    	return "";
    }    
	function mint(address _to, uint256 _tokenId) internal virtual {
	  require(_to != address(0), 'Error: address does not exist');
	  _balances[_to] += 1;
	  _owners[_tokenId] = _to;
	  emit Transfer(address(0), _to, _tokenId);
	}
	function burn(uint256 _tokenId) internal {
	address _owner = ownerOf(_tokenId);
	  approve(address(0), _tokenId);
	  _balances[_owner] -= 1;
	  delete _owners[_tokenId];
	  emit Transfer(_owner, address(0), _tokenId);
	}


	function requestNewRandomAerith(string memory aerith) public returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= _fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(_keyHash, _fee);
        requestToAerithName[requestId] = aerith;
        requestToSender[requestId] = msg.sender;
        return requestId;
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        uint256 newId = aeriths.length; uint256 Strength = (randomNumber % 999); uint256 Magic = ((randomNumber % 10000) / 100 ); uint256 Vitality = ((randomNumber % 1000000) / 10000 ); 
        uint256 Spirit = ((randomNumber % 100000000) / 1000000 ); uint256 Luck = ((randomNumber % 10000000000) / 100000000 ); uint256 Speed = ((randomNumber % 1000000000000) / 10000000000);
        uint256 Level = (randomNumber % 50); aeriths.push(Aerith(Strength, Magic, Vitality, Spirit, Luck, Speed, Level, requestToAerithName[requestId]));
        mint(requestToSender[requestId], newId);
    }
    function getLevel(uint256 _tokenId) public view returns (uint256) {
        return sqrt(aeriths[_tokenId].Level);
    }
    function getNumberOfAeriths() public view returns (uint256) {
        return aeriths.length; 
    }
    function getAerithsOverView(uint256 _tokenId) public view returns (string memory, uint256, uint256, uint256) {
        return (aeriths[_tokenId].name, aeriths[_tokenId].Strength + aeriths[_tokenId].Magic + aeriths[_tokenId].Vitality + 
        aeriths[_tokenId].Spirit + aeriths[_tokenId].Luck + aeriths[_tokenId].Speed, getLevel(_tokenId), aeriths[_tokenId].Level);
    }
    function getAerithsStats(uint256 _tokenId) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (aeriths[_tokenId].Strength, aeriths[_tokenId].Magic, aeriths[_tokenId].Vitality, aeriths[_tokenId].Spirit,
        aeriths[_tokenId].Luck,  aeriths[_tokenId].Speed,aeriths[_tokenId].Level  );
    }
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

