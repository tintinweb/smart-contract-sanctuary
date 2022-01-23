/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

pragma solidity ^0.4.24;


interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}

// 문자열 처리 유틸리티
library StringUtil {
	
	// 두 문자열을 합칩니다.
	function concat(string a, string b) internal pure returns (string c) {
		
		bytes memory ba = bytes(a);
		bytes memory bb = bytes(b);
		bytes memory bc = bytes(new string(ba.length + bb.length));
		
		uint256 i = 0;
		uint256 j = 0;
		
		for (j = 0; j < ba.length; j += 1) {
			bc[i] = ba[j];
			i += 1;
		}
		
		for (j = 0; j < bb.length; j += 1) {
			bc[i] = bb[j];
			i += 1;
		}
		
		return string(bc);
    }
	
	// uint256를 문자열로 변경합니다.
	function uint256ToString(uint256 i) internal pure returns (string str) {
        if (i == 0) {
        	return "0";
        }
        
        uint256 j = i;
        uint256 length;
        while (j != 0){
            length += 1;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (i != 0){
            bstr[k] = byte(48 + i % 10);
            i /= 10;
            k -= 1;
        }
        
        return string(bstr);
    }
}

// Ether Fairy의 기본적인 내용을 담고있는 계약
contract EtherFairyBase is ERC721Metadata {
	
	// 토큰 정보
	string constant public NAME = "Ether Fairy";
	string constant public SYMBOL = "FAIRY";
	string public tokenMetadataBaseURI = "https://etherfairy.com/api/tokenmetadata/";
	
	// 요정 원본의 가격
	uint256 public fairyOriginPrice = 0.05 ether;
	
	// 임의 레벨업 가격
	uint256 public customLevelUpPrice = 0.01 ether;
	
	// 임의로 포인트를 증가시키는데 드는 포인트당 가격
	uint256 public increasePointPricePerPoint = 0.01 ether;
	
	// 요정 정보
	struct Fairy {
		
		// 회사 서버에 저장된 요정 원본의 ID
		string fairyOriginId;
		
		// 요정 디자이너의 지갑
		address designer;
		
		// 요정의 이름
		string name;
		
		// 탄생 시간
		uint256 birthTime;
		
		// 소유주에 의해 추가된 레벨
		uint256 appendedLevel;
		
		// 기본 속성에 대한 레벨 당 증가 포인트들
		uint256 hpPointPerLevel;
		uint256 attackPointPerLevel;
		uint256 defencePointPerLevel;
		uint256 agilityPointPerLevel;
		uint256 dexterityPointPerLevel;
		
		// 원소 속성에 대한 레벨 당 증가 포인트들
		uint256 firePointPerLevel;
		uint256 waterPointPerLevel;
		uint256 windPointPerLevel;
		uint256 earthPointPerLevel;
		uint256 lightPointPerLevel;
		uint256 darkPointPerLevel;
	}
	
	// 요정들의 저장소
	Fairy[] internal fairies;
	
	function getFairyCount() view public returns (uint256) {
		return fairies.length;
	}
	
	// 원본 ID에 해당하는 요정의 개수를 반환합니다.
	function getFairyCountByOriginId(string fairyOriginId) view public returns (uint256) {
		bytes32 hash = keccak256(bytes(fairyOriginId));
		
		uint256 fairyCount = 0;
		for (uint256 i = 0; i < fairies.length; i += 1) {
			if (keccak256(bytes(fairies[i].fairyOriginId)) == hash) {
				fairyCount += 1;
			}
		}
		
		return fairyCount;
	}
	
	// 원본 ID에 해당하는 요정의 ID 목록을 반환합니다.
	function getFairyIdsByOriginId(string fairyOriginId) view public returns (uint256[]) {
		bytes32 hash = keccak256(bytes(fairyOriginId));
		
		uint256[] memory fairyIds = new uint256[](getFairyCountByOriginId(fairyOriginId));
		uint256 j = 0;
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			if (keccak256(bytes(fairies[i].fairyOriginId)) == hash) {
				fairyIds[j] = i;
				j += 1;
			}
		}
		
		return fairyIds;
	}
	
	// 소유주들 주소
	address[] public masters;
	
	function getMasterCount() view public returns (uint256) {
		return masters.length;
	}
	
	// 소유주가 이미 존재하는지
	mapping(address => bool) internal masterToIsExisted;
	
	// 소유주가 차단되었는지
	mapping(address => bool) public masterToIsBlocked;
	
	// 요정이 차단되었는지
	mapping(uint256 => bool) public fairyIdToIsBlocked;
	
	// 회사의 지갑 주소
	address public company;
	
	// 공식 마켓 계약 주소
	address public officialMarket;
	
	constructor() public {
		// 계약 생성자를 초기 회사 및 공식 마켓 주소로 등록
		company = msg.sender;
		officialMarket = msg.sender;
	}
	
	// 서비스가 일시중지 상태인지
	bool public servicePaused = false;
	
	// 서비스가 구동중일때만
	modifier whenServiceRunning() {
		require(servicePaused != true);
		_;
	}
	
	// 서비스가 일시정지 상태일때만
	modifier whenServicePaused() {
		require(servicePaused == true);
		_;
	}
	
	// 차단된 소유주가 아닐 경우에만
	modifier whenNotBlocked() {
		// 회사는 차단 불가
		require(msg.sender == company || masterToIsBlocked[msg.sender] != true);
		_;
	}
	
	// 차단된 요정이 아닐 경우에만
	modifier whenNotBlockedFairy(uint256 fairyId) {
		// 회사는 차단 불가
		require(msg.sender == company || fairyIdToIsBlocked[fairyId] != true);
		_;
	}
	
	// 주소를 잘못 사용하는 것인지 체크
	function checkAddressMisused(address target) internal view returns (bool) {
		return
			target == address(0) ||
			target == address(this);
	}
	
	//ERC721Metadata: 토큰의 이름 반환
	function name() view external returns (string) {
		return NAME;
	}
	
	//ERC721Metadata: 토큰의 심볼 반환
	function symbol() view external returns (string) {
		return SYMBOL;
	}
	
	//ERC721Metadata: 요정 정보의 메타데이터를 가져오는 경로를 반환합니다.
	function tokenURI(uint256 fairyId) view external returns (string) {
		return StringUtil.concat(tokenMetadataBaseURI, StringUtil.uint256ToString(fairyId));
	}
}

// Ether Fairy를 운영하는 회사에서 사용하는 기능들
contract EtherFairyCompany is EtherFairyBase {
	
	// 소유권 이전 이벤트
	event TransferOwnership(address oldCompany, address newCompany);
	
	// 서비스를 일시중지하거나 재개하면 발생하는 이벤트
	event PauseService();
	event ResumeService();
	
	// 기타 이벤트
	event ChangeFairyOriginPrice(uint256 price);
	event ChangeCustomLevelUpPrice(uint256 price);
	event ChangeIncreasePointPricePerPoint(uint256 price);
	event ChangeTokenMetadataBaseURI(string tokenMetadataBaseURI);
	event ChangeOfficialMarket(address officialMarket);
	event BlockMaster(address masterToBlock);
	event BlockFairy(uint256 fairyIdToBlock);
	event UnblockMaster(address masterToUnlock);
	event UnblockFairy(uint256 fairyIdToUnblock);
	
	// 회사만 처리 가능
	modifier onlyCompany {
		require(msg.sender == company);
		_;
	}
	
	// 소유권을 이전합니다.
	function transferOwnership(address newCompany) onlyCompany public {
		address oldCompany = company;
		company = newCompany;
		emit TransferOwnership(oldCompany, newCompany);
	}
	
	// 서비스의 작동을 중지합니다.
	function pauseService() onlyCompany whenServiceRunning public {
		servicePaused = true;
		emit PauseService();
	}
	
	// 서비스를 재개합니다.
	function resumeService() onlyCompany whenServicePaused public {
		servicePaused = false;
		emit ResumeService();
	}
	
	// 요정 원본의 가격을 변경합니다.
	function changeFairyOriginPrice(uint256 newFairyOriginPrice) onlyCompany public {
		fairyOriginPrice = newFairyOriginPrice;
		emit ChangeFairyOriginPrice(newFairyOriginPrice);
	}
	
	// 임의 레벨업 가격을 변경합니다.
	function changeCustomLevelUpPrice(uint256 newCustomLevelUpPrice) onlyCompany public {
		customLevelUpPrice = newCustomLevelUpPrice;
		emit ChangeCustomLevelUpPrice(newCustomLevelUpPrice);
	}
	
	// 임의로 포인트를 증가시키는데 드는 포인트당 가격을 변경합니다.
	function changeIncreasePointPricePerPoint(uint256 newIncreasePointPricePerPoint) onlyCompany public {
		increasePointPricePerPoint = newIncreasePointPricePerPoint;
		emit ChangeIncreasePointPricePerPoint(newIncreasePointPricePerPoint);
	}
	
	// tokenMetadataBaseURI을 변경합니다.
	function changeTokenMetadataBaseURI(string newTokenMetadataBaseURI) onlyCompany public {
		tokenMetadataBaseURI = newTokenMetadataBaseURI;
		emit ChangeTokenMetadataBaseURI(newTokenMetadataBaseURI);
	}
	
	// 공식 마켓 계약을 변경합니다.
	function changeOfficialMarket(address newOfficialMarket) onlyCompany public {
		officialMarket = newOfficialMarket;
		emit ChangeOfficialMarket(newOfficialMarket);
	}
	
	// 특정 소유주를 차단합니다.
	function blockMaster(address masterToBlock) onlyCompany public {
		masterToIsBlocked[masterToBlock] = true;
		emit BlockMaster(masterToBlock);
	}
	
	// 특정 요정을 차단합니다.
	function blockFairy(uint256 fairyIdToBlock) onlyCompany public {
		fairyIdToIsBlocked[fairyIdToBlock] = true;
		emit BlockFairy(fairyIdToBlock);
	}
	
	// 소유주 차단을 해제합니다.
	function unblockMaster(address masterToUnlock) onlyCompany public {
		delete masterToIsBlocked[masterToUnlock];
		emit UnblockMaster(masterToUnlock);
	}
	
	// 요정 차단을 해제합니다.
	function unblockFairy(uint256 fairyIdToUnblock) onlyCompany public {
		delete fairyIdToIsBlocked[fairyIdToUnblock];
		emit UnblockFairy(fairyIdToUnblock);
	}
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

// 숫자 계산 시 오버플로우 문제를 방지하기 위한 라이브러리
library SafeMath {
	
	function add(uint256 a, uint256 b) pure internal returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	function sub(uint256 a, uint256 b) pure internal returns (uint256 c) {
		assert(b <= a);
		return a - b;
	}
	
	function mul(uint256 a, uint256 b) pure internal returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) pure internal returns (uint256 c) {
		return a / b;
	}
}

// 요정 소유권 관련 기능
contract FairyOwnership is EtherFairyBase, ERC721 {
	using SafeMath for uint256;
	
	// 요정의 소유주 정보
	mapping(uint256 => address) public fairyIdToMaster;
	
	// 소유주의 요정 ID 목록 정보
	mapping(address => uint256[]) public masterToFairyIds;
	
	// 요정의 요정 ID 목록에서의 index 정보
	mapping(uint256 => uint256) internal fairyIdToFairyIdsIndex;
	
	// 요정 거래 권한이 승인된 지갑 정보
	mapping(uint256 => address) private fairyIdToApproved;
	
	// 오퍼레이터가 승인되었는지에 대한 정보
	mapping(address => mapping(address => bool)) private masterToOperatorToIsApprovedForAll;
	
	// 요정 소유주만
	modifier onlyMasterOf(uint256 fairyId) {
		require(msg.sender == ownerOf(fairyId));
		_;
	}
	
	// 승인된 지갑만
	modifier onlyApprovedOf(uint256 fairyId) {
		require(
			msg.sender == ownerOf(fairyId) ||
			msg.sender == getApproved(fairyId) ||
			isApprovedForAll(ownerOf(fairyId), msg.sender) == true ||
			msg.sender == officialMarket
		);
		_;
	}
	
	//ERC721: 요정의 개수를 가져옵니다.
	function balanceOf(address master) view public returns (uint256) {
		// 주소 오용 차단
		require(checkAddressMisused(master) != true);
		return masterToFairyIds[master].length;
	}
	
	//ERC721: 요정의 소유주 지갑 주소를 가져옵니다.
	function ownerOf(uint256 fairyId) view public returns (address) {
		address master = fairyIdToMaster[fairyId];
		require(checkAddressMisused(master) != true);
		return master;
	}
	
	// 주어진 주소가 스마트 계약인지 확인합니다.
	function checkIsSmartContract(address addr) view private returns (bool) {
		uint32 size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}
	
	//ERC721: 요정을 받는 대상이 스마트 계약인 경우, onERC721Received 함수를 실행합니다.
	function safeTransferFrom(address from, address to, uint256 fairyId, bytes data) whenServiceRunning payable external {
		transferFrom(from, to, fairyId);
		if (checkIsSmartContract(to) == true) {
			// ERC721TokenReceiver
			require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, fairyId, data) == 0x150b7a02);
		}
	}
	
	//ERC721: 요정을 받는 대상이 스마트 계약인 경우, onERC721Received 함수를 실행합니다.
	function safeTransferFrom(address from, address to, uint256 fairyId) whenServiceRunning payable external {
		transferFrom(from, to, fairyId);
		if (checkIsSmartContract(to) == true) {
			// ERC721TokenReceiver
			require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, fairyId, "") == 0x150b7a02);
		}
	}
	
	//ERC721: 요정을 이전합니다.
	function transferFrom(address from, address to, uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyApprovedOf(fairyId) payable public {
		// 주소 오용 차단
		require(checkAddressMisused(to) != true);
		
		require(from == ownerOf(fairyId));
		require(to != ownerOf(fairyId));
		
		// 거래 권한 제거
		delete fairyIdToApproved[fairyId];
		emit Approval(from, 0, fairyId);
		
		// 기존 소유주로부터 요정 제거
		uint256 index = fairyIdToFairyIdsIndex[fairyId];
		uint256 lastIndex = balanceOf(from).sub(1);
		
		uint256 lastFairyId = masterToFairyIds[from][lastIndex];
		masterToFairyIds[from][index] = lastFairyId;
		
		delete masterToFairyIds[from][lastIndex];
		masterToFairyIds[from].length -= 1;
		
		fairyIdToFairyIdsIndex[lastFairyId] = index;
		
		// 요정 이전
		fairyIdToMaster[fairyId] = to;
		fairyIdToFairyIdsIndex[fairyId] = masterToFairyIds[to].push(fairyId).sub(1);
		
		emit Transfer(from, to, fairyId);
	}
	
	//ERC721: 특정 계약에 거래 권한을 부여합니다.
	function approve(address approved, uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable external {
		
		address master = ownerOf(fairyId);
		
		// 주소 오용 차단
		require(approved != master);
		require(checkAddressMisused(approved) != true);
		
		fairyIdToApproved[fairyId] = approved;
		emit Approval(master, approved, fairyId);
	}
	
	//ERC721: 오퍼레이터에게 거래 권한을 부여하거나 뺏습니다.
	function setApprovalForAll(address operator, bool isApproved) whenServiceRunning whenNotBlocked external {
		// 주소 오용 차단
		require(operator != msg.sender);
		require(checkAddressMisused(operator) != true);
		
		if (isApproved == true) {
			masterToOperatorToIsApprovedForAll[msg.sender][operator] = true;
		} else {
			delete masterToOperatorToIsApprovedForAll[msg.sender][operator];
		}
		
		emit ApprovalForAll(msg.sender, operator, isApproved);
	}
	
	//ERC721: 요정 거래 권한이 승인된 지갑 주소를 가져옵니다.
	function getApproved(uint256 fairyId) public view returns (address) {
		return fairyIdToApproved[fairyId];
	}
	
	//ERC721: 오퍼레이터가 거래 권한을 가지고 있는지 확인합니다.
	function isApprovedForAll(address master, address operator) view public returns (bool) {
		return masterToOperatorToIsApprovedForAll[master][operator] == true;
	}
}

// 돈을 지불하고 요정을 업그레이드 하는 기능들
contract FairyPayToUpgrade is FairyOwnership {
	
    event CustomLevelUp(uint256 indexed fairyId);
    event IncreaseHPPointPerLevel(uint256 indexed fairyId);
    event IncreaseAttackPointPerLevel(uint256 indexed fairyId);
    event IncreaseDefencePointPerLevel(uint256 indexed fairyId);
    event IncreaseAgilityPointPerLevel(uint256 indexed fairyId);
    event IncreaseDexterityPointPerLevel(uint256 indexed fairyId);
    event IncreaseFirePointPerLevel(uint256 indexed fairyId);
    event IncreaseWaterPointPerLevel(uint256 indexed fairyId);
    event IncreaseWindPointPerLevel(uint256 indexed fairyId);
    event IncreaseEarthPointPerLevel(uint256 indexed fairyId);
    event IncreaseLightPointPerLevel(uint256 indexed fairyId);
    event IncreaseDarkPointPerLevel(uint256 indexed fairyId);

	// 돈을 지불하고 레벨업 합니다.
	function levelUpFairy(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		// 임의 레벨업 가격과 비교합니다.
		require(msg.value == customLevelUpPrice);
		
		// 요정의 레벨을 올립니다.
		Fairy storage fairy = fairies[fairyId];
		fairy.appendedLevel = fairy.appendedLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit CustomLevelUp(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 HP 증가 포인트를 올립니다.
	function increaseHPPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.hpPointPerLevel);
		
		// 레벨 당 HP 증가 포인트를 올립니다.
		fairy.hpPointPerLevel = fairy.hpPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseHPPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 공격 증가 포인트를 올립니다.
	function increaseAttackPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.attackPointPerLevel);
		
		// 레벨 당 공격 증가 포인트를 올립니다.
		fairy.attackPointPerLevel = fairy.attackPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseAttackPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 방어 증가 포인트를 올립니다.
	function increaseDefencePointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.defencePointPerLevel);
		
		// 레벨 당 방어 증가 포인트를 올립니다.
		fairy.defencePointPerLevel = fairy.defencePointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseDefencePointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 민첩 증가 포인트를 올립니다.
	function increaseAgilityPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.agilityPointPerLevel);
		
		// 레벨 당 민첩 증가 포인트를 올립니다.
		fairy.agilityPointPerLevel = fairy.agilityPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseAgilityPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 재치 증가 포인트를 올립니다.
	function increaseDexterityPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.dexterityPointPerLevel);
		
		// 레벨 당 재치 증가 포인트를 올립니다.
		fairy.dexterityPointPerLevel = fairy.dexterityPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseDexterityPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 불 속성 증가 포인트를 올립니다.
	function increaseFirePointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.firePointPerLevel.add(1));
		
		// 레벨 당 불 속성 증가 포인트를 올립니다.
		fairy.firePointPerLevel = fairy.firePointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseFirePointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 물 속성 증가 포인트를 올립니다.
	function increaseWaterPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.waterPointPerLevel.add(1));
		
		// 레벨 당 물 속성 증가 포인트를 올립니다.
		fairy.waterPointPerLevel = fairy.waterPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseWaterPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 바람 속성 증가 포인트를 올립니다.
	function increaseWindPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.windPointPerLevel.add(1));
		
		// 레벨 당 바람 속성 증가 포인트를 올립니다.
		fairy.windPointPerLevel = fairy.windPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseWindPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 대지 속성 증가 포인트를 올립니다.
	function increaseEarthPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.earthPointPerLevel.add(1));
		
		// 레벨 당 대지 속성 증가 포인트를 올립니다.
		fairy.earthPointPerLevel = fairy.earthPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseEarthPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 빛 속성 증가 포인트를 올립니다.
	function increaseLightPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.lightPointPerLevel.add(1));
		
		// 레벨 당 빛 속성 증가 포인트를 올립니다.
		fairy.lightPointPerLevel = fairy.lightPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseLightPointPerLevel(fairyId);
	}
	
	// 돈을 지불하고 레벨 당 어둠 속성 증가 포인트를 올립니다.
	function increaseDarkPointPerLevel(uint256 fairyId) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) payable public {
		
		Fairy storage fairy = fairies[fairyId];
		
		// 임의로 포인트를 증가시키는데 드는 포인트당 가격과 비교합니다.
		require(msg.value == increasePointPricePerPoint * fairy.darkPointPerLevel.add(1));
		
		// 레벨 당 어둠 속성 증가 포인트를 올립니다.
		fairy.darkPointPerLevel = fairy.darkPointPerLevel.add(1);
		
        uint256 companyRevenue = msg.value.div(2);
        uint256 designerRevenue = msg.value.div(2);
        
        require(companyRevenue.add(designerRevenue) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(companyRevenue);
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		fairy.designer.transfer(designerRevenue);
		
		emit IncreaseDarkPointPerLevel(fairyId);
	}
}

// 요정 소유주가 사용하는 기능들
contract FairyMaster is FairyOwnership, FairyPayToUpgrade {
	using SafeMath for uint256;
	
	// 이벤트
    event BirthFairy(address indexed master, uint256 fairyId);
    event ChangeFairyName(uint256 indexed fairyId, string name);
	
	// 요정을 탄생시킵니다.
	function birthFairy(
		
		// 회사 서버에 저장된 요정 원본 ID
		string fairyOriginId,
		
		// 요정 디자이너의 지갑 주소
		address designer,
		
		// 요정의 이름
		string name,
		
		// 원소 속성에 대한 레벨 당 증가 포인트들
		uint256 firePointPerLevel,
		uint256 waterPointPerLevel,
		uint256 windPointPerLevel,
		uint256 earthPointPerLevel,
		uint256 lightPointPerLevel,
		uint256 darkPointPerLevel
		) whenServiceRunning whenNotBlocked payable public {
		
		// 주소 오용 차단
		require(checkAddressMisused(designer) != true);
		
		// 요정 원본의 가격과 비교합니다.
		require(msg.value == fairyOriginPrice);
		
		// 초기 속성 값들의 총합은 5가 되어야 합니다.
		uint256 totalPointPerLevel = firePointPerLevel;
		totalPointPerLevel = totalPointPerLevel.add(waterPointPerLevel);
		totalPointPerLevel = totalPointPerLevel.add(windPointPerLevel);
		totalPointPerLevel = totalPointPerLevel.add(earthPointPerLevel);
		totalPointPerLevel = totalPointPerLevel.add(lightPointPerLevel);
		totalPointPerLevel = totalPointPerLevel.add(darkPointPerLevel);
		require(totalPointPerLevel == 5);
		
		// 요정 데이터 생성
		uint256 fairyId = fairies.push(Fairy({
			
			fairyOriginId : fairyOriginId,
			designer : designer,
			name : name,
			birthTime : now,
			appendedLevel : 0,
			
			// EVM의 특성 상 너무 많은 변수를 한번에 할당 할 수 없으므로,
			// 기본 속성은 1로 통일하여 지정합니다.
			hpPointPerLevel : 1,
			attackPointPerLevel : 1,
			defencePointPerLevel : 1,
			agilityPointPerLevel : 1,
			dexterityPointPerLevel : 1,
			
			firePointPerLevel : firePointPerLevel,
			waterPointPerLevel : waterPointPerLevel,
			windPointPerLevel : windPointPerLevel,
			earthPointPerLevel : earthPointPerLevel,
			lightPointPerLevel : lightPointPerLevel,
			darkPointPerLevel : darkPointPerLevel
		})).sub(1);
		
		// msg.sender를 소유주로 등록
		fairyIdToMaster[fairyId] = msg.sender;
		fairyIdToFairyIdsIndex[fairyId] = masterToFairyIds[msg.sender].push(fairyId).sub(1);
		
		// 소유주 주소 등록
		if (masterToIsExisted[msg.sender] != true) {
			masters.push(msg.sender);
			masterToIsExisted[msg.sender] = true;
		}
		
		require(msg.value.div(2).mul(2) == msg.value);
		
		// 회사에게 금액의 50%를 지급합니다.
		company.transfer(msg.value.div(2));
		
		// 요정의 디자이너에게 금액의 50%를 지급합니다.
		designer.transfer(msg.value.div(2));
		
		// 이벤트 발생
		emit BirthFairy(msg.sender, fairyId);
		emit Transfer(0x0, msg.sender, fairyId);
	}

	// 요정의 이름을 변경합니다.
	function changeFairyName(uint256 fairyId, string newName) whenServiceRunning whenNotBlocked whenNotBlockedFairy(fairyId) onlyMasterOf(fairyId) public {
		fairies[fairyId].name = newName;
		
		emit ChangeFairyName(fairyId, newName);
	}
	
	// 요정을 많이 가진 순서대로 소유주의 ID 목록을 가져옵니다.
	function getMasterIdsByFairyCount() view public returns (uint256[]) {
		uint256[] memory masterIds = new uint256[](masters.length);
		
		for (uint256 i = 0; i < masters.length; i += 1) {
			
			uint256 fairyCount = balanceOf(masters[i]);
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (balanceOf(masters[masterIds[j - 1]]) < fairyCount) {
					masterIds[j] = masterIds[j - 1];
				} else {
					break;
				}
			}
			
			masterIds[j] = i;
		}
		
		return masterIds;
	}
}

// 요정 정보를 제공하는 계약
contract FairyInfo is EtherFairyBase {
	
	// 요정의 기본 정보를 반환합니다.
	function getFairyBasicInfo(uint256 fairyId) view public returns (
		string fairyOriginId,
		address designer,
		string name,
		uint256 birthTime,
		uint256 appendedLevel) {
		
		Fairy memory fairy = fairies[fairyId];
		
		return (
			fairy.fairyOriginId,
			fairy.designer,
			fairy.name,
			fairy.birthTime,
			fairy.appendedLevel
		);
	}
	
	// 요정의 기본 속성에 대한 레벨 당 증가 포인트들을 반환합니다.
	function getFairyBasicPointsPerLevel(uint256 fairyId) view public returns (
		uint256 hpPointPerLevel,
		uint256 attackPointPerLevel,
		uint256 defencePointPerLevel,
		uint256 agilityPointPerLevel,
		uint256 dexterityPointPerLevel) {
		
		Fairy memory fairy = fairies[fairyId];
		
		return (
			fairy.hpPointPerLevel,
			fairy.attackPointPerLevel,
			fairy.defencePointPerLevel,
			fairy.agilityPointPerLevel,
			fairy.dexterityPointPerLevel
		);
	}
	
	// 요정의 원소 속성에 대한 레벨 당 증가 포인트들을 반환합니다.
	function getFairyElementPointsPerLevel(uint256 fairyId) view public returns (
		uint256 firePointPerLevel,
		uint256 waterPointPerLevel,
		uint256 windPointPerLevel,
		uint256 earthPointPerLevel,
		uint256 lightPointPerLevel,
		uint256 darkPointPerLevel) {
		
		Fairy memory fairy = fairies[fairyId];
		
		return (
			fairy.firePointPerLevel,
			fairy.waterPointPerLevel,
			fairy.windPointPerLevel,
			fairy.earthPointPerLevel,
			fairy.lightPointPerLevel,
			fairy.darkPointPerLevel
		);
	}
}

// 요정의 랭킹을 제공하는 계약
contract FairyRank is EtherFairyBase {
	
	// 최근에 태어난 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByBirthTime() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 birthTime = fairies[i].birthTime;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].birthTime < birthTime) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 소유주에 의해 추가된 레벨이 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByAppendedLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 appendedLevel = fairies[i].appendedLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].appendedLevel < appendedLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 HP 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByHPPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 hpPointPerLevel = fairies[i].hpPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].hpPointPerLevel < hpPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 공격 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByAttackPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 attackPointPerLevel = fairies[i].attackPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].attackPointPerLevel < attackPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 방어 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByDefencePointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 defencePointPerLevel = fairies[i].defencePointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].defencePointPerLevel < defencePointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 민첩 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByAgilityPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 agilityPointPerLevel = fairies[i].agilityPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].agilityPointPerLevel < agilityPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 재치 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByDexterityPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 dexterityPointPerLevel = fairies[i].dexterityPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].dexterityPointPerLevel < dexterityPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 불 속성 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByFirePointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 firePointPerLevel = fairies[i].firePointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].firePointPerLevel < firePointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 물 속성 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByWaterPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 waterPointPerLevel = fairies[i].waterPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].waterPointPerLevel < waterPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 바람 속성 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByWindPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 windPointPerLevel = fairies[i].windPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].windPointPerLevel < windPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 대지 속성 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByEarthPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 earthPointPerLevel = fairies[i].earthPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].earthPointPerLevel < earthPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 빛 속성 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByLightPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 lightPointPerLevel = fairies[i].lightPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].lightPointPerLevel < lightPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
	
	// 레벨 당 어둠 속성 증가 포인트가 높은 순서대로 요정의 ID 목록을 가져옵니다.
	function getFairyIdsByDarkPointPerLevel() view public returns (uint256[]) {
		uint256[] memory fairyIds = new uint256[](fairies.length);
		
		for (uint256 i = 0; i < fairies.length; i += 1) {
			
			uint256 darkPointPerLevel = fairies[i].darkPointPerLevel;
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (fairies[fairyIds[j - 1]].darkPointPerLevel < darkPointPerLevel) {
					fairyIds[j] = fairyIds[j - 1];
				} else {
					break;
				}
			}
			
			fairyIds[j] = i;
		}
		
		return fairyIds;
	}
}

// Ether Fairy 스마트 계약
contract EtherFairy is EtherFairyCompany, FairyMaster, FairyInfo, FairyRank, ERC165 {
	
	//ERC165: 주어진 인터페이스가 구현되어 있는지 확인합니다.
	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		return
			// ERC165
			interfaceID == this.supportsInterface.selector ||
			// ERC721
			interfaceID == 0x80ac58cd ||
			// ERC721Metadata
			interfaceID == 0x5b5e139f ||
			// ERC721Enumerable
			interfaceID == 0x780e9d63;
	}
}