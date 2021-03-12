// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCX {
  function balanceOf(address owner) external view returns (uint);
  function balanceOf(address account, uint256 id) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external;
  function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function uri(uint256) external view returns (string memory);
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract Airdrop {

  enum ERC { ERC20, ERC721, ERC1155 }

  struct Data {
    address from;
    address token;
    ERC     erc;
    uint128 value;
    uint128 timestamp;
    uint    totalSupply;
  }

  struct ERCData {
    string name;
    string symbol;
    uint8 decimals;
    uint balanceFrom;
    string uri;
  }

	address public owner;
  uint16 public latestRef;

	mapping (uint16 => Data) public refData;
	mapping (uint16 => mapping (address => uint32)) public claimed;
	mapping (address => uint16[]) private drops;

	constructor() {
		owner = msg.sender;
	}

	modifier ensureOwner {
		require(owner == msg.sender); _;
	}

	event Dropped(uint16 ref, address indexed token);
	event Claimed(uint16 ref, address indexed token, address indexed to);

	function drop(ERC erc, uint16 ref, address from, address token, uint128 value, uint totalSupply, address[] calldata owners) ensureOwner external {
		require(refData[ref].timestamp == 0, 'ref');
    latestRef = ref;
		refData[ref] = Data({
			from: from,
			token: token,
      erc: erc,
			value: value,
      totalSupply: totalSupply,
			timestamp: uint128(block.timestamp)
		});
		for (uint i = 0; i < owners.length; i++) {
			drops[owners[i]].push(ref);
		}

		emit Dropped(ref, token);
	}

	function claim(uint16 ref) external {
    bool claimable;
    for (uint i = drops[msg.sender].length; i > 0; i--) {
  		if(drops[msg.sender][i - 1] == ref) {
        claimable = true;
        break;
      }
		}
		require(claimable == true && claimed[ref][msg.sender] == 0, 'claim');

    claimed[ref][msg.sender] = uint32(block.timestamp);

    if(refData[ref].erc != ERC.ERC1155) {
      IERCX(refData[ref].token).transferFrom(refData[ref].from, msg.sender, refData[ref].value);
    } else {
      IERCX(refData[ref].token).safeTransferFrom(refData[ref].from, msg.sender, refData[ref].value, 1, "");
    }

		emit Claimed(ref, refData[ref].token, msg.sender);
	}

	function setOwner(address _owner) ensureOwner external {
		owner = _owner;
	}

	function dropsOf(address _owner) external view returns (uint16[] memory, Data[] memory, ERCData[] memory, uint32[] memory) {
		Data[] memory _refDatas = new Data[](drops[_owner].length);
    ERCData[] memory _ercDatas = new ERCData[](drops[_owner].length);
		uint32[] memory _claims = new uint32[](drops[_owner].length);

		for (uint i = 0; i < drops[_owner].length; i++) {
      Data memory data = refData[drops[_owner][i]];
			_refDatas[i] = data;
      _ercDatas[i] = ERCData({
        name: data.erc != ERC.ERC1155 ? IERCX(data.token).name() : '',
        symbol: data.erc != ERC.ERC1155 ? IERCX(data.token).symbol() : '',
        decimals: data.erc == ERC.ERC20 ? IERCX(data.token).decimals() : 0,
        balanceFrom: data.erc != ERC.ERC1155 ? IERCX(data.token).balanceOf(data.from) : IERCX(data.token).balanceOf(data.from, data.value),
        uri: data.erc == ERC.ERC721 ? IERCX(data.token).tokenURI(data.value) : data.erc == ERC.ERC1155 ? IERCX(data.token).uri(data.value) : ''
      });
			_claims[i] = claimed[drops[_owner][i]][_owner];
		}

		return (drops[_owner], _refDatas, _ercDatas, _claims);
	}

	function balancesOf(address _owner, address[] calldata tokens) external view returns (uint[] memory) {
		uint[] memory b = new uint[](tokens.length);
		for (uint i = 0; i < b.length; i++) {
			b[i] = IERCX(tokens[i]).balanceOf(_owner);
		}
		return b;
	}
}