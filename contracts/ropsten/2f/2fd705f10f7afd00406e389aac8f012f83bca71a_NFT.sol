/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.3.0/contracts/utils/Address.sol
/**
 * @dev 주소 타입과 관련된 함수의 모음,
 */
library Address
{
    /**
     * @dev 만일 `account` 가 컨트랙트라면 참(true)를 반환합니다.
     *
     * 이 테스트는 불완전하며, false-negatives가 있을 수 있습니다:
     * 컨트랙트의 생성자를 실행하는 중, 주소는 컨트랙트를 포함하지
     * 않은 것으로 보고될 것입니다.
     *
     * > 이 함수가 거짓(false)을 반환하는 주소가 외부 소유 계정(EOA)
     * 이며 컨트랙트가 아니라고 가정하는 것은 확실하지 않습니다.
     */
    function isContract(address account) internal view returns (bool)
	{
        // 코드는 생성자 실행이 완료되고 나서 저장되므로, 생성 중인
        // 컨트랙트에 대해 0을 반환하는 extcodesize에
        // 의존합니다.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.3.0/contracts/math/SafeMath.sol
/**
 * @dev 오버플로우 검사를 포함한 솔리디티의 산술 연산에 대한
 * 래퍼입니다.
 *
 * 솔리디티의 산술 연산은 오버플로우됩니다. 프로그래머는 일반적으로
 * 고수준 프로그래밍 언어의 일반적인 동작인 오버플로우가 에러를 발생시키는 것
 * 으로 가정하기 때문에, 이는 버그의 결과일 수 있습니다.
 * `SafeMath`는 연산이 오버플로우될 때 트랜잭션을 되돌려
 * 직관적으로 복원합니다.
 *
 * 확인되지 않은 연산 대신에 이 라이브러리를 사용하면 
 * 버그가 제거되므로, 항상 사용하는 것이 좋습니다.
 */
library SafeMath
{
    /**
     * @dev 부호 없는 정수 두 개를 더한 값을 반환하고, 오버플로우를
     * 예외처리합니다.
     *
     * 솔리디티의 `+` 연산자를 대체합니다.
     *
     * 요구사항:
     * - 덧셈은 오버플로우될 수 없습니다.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 차를 반환합니다.
     * 결과가 음수일 경우 오버플로우입니다.
     *
     * 솔리디티의 `-` 연산자를 대체합니다.
     *
     * 요구사항:
     * - 뺄셈은 오버플로우될 수 없습니다.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 곱을 반환합니다.
     * 오버플로우 발생 시 예외처리합니다.
     *
     * 솔리디티의 `*` 연산자를 대체합니다.
     *
     * 요구사항:
     * - 곱셈은 오버플로우될 수 없습니다.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
        // 가스 최적화: 이는 'a'가 0이 아님을 요구하는 것보다 저렴하지만,
        // 'b'도 테스트할 경우 이점이 없어집니다.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0)
		{
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 몫을 반환합니다. 0으로 나누기를 시도할 경우
     * 예외처리합니다. 결과는 0의 자리에서 반올림됩니다.
     *
     * 솔리디티의 `/` 연산자를 대체합니다. 참고: 이 함수는
     * `revert` 명령코드(잔여 가스를 건들지 않음)를 사용하는 반면, 솔리디티는
     * 유효하지 않은 명령코드를 사용해 복귀합니다(남은 모든 가스를 소비).
     *
     * 요구사항:
     * - 0으로 나눌 수 없습니다.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
        // 솔리디티는 0으로 나누기를 자동으로 검출하고 중단합니다.
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // 이를 만족시키지 않는 경우가 없어야 합니다.

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 나머지를 반환합니다. (부호 없는 정수 모듈로 연산),
     * 0으로 나눌 경우 예외처리합니다.
     *
     * 솔리디티의 `%` 연산자를 대체합니다. 이 함수는 `revert`
     * 명령코드(잔여 가스를 건들지 않음)를 사용하는 반면, 솔리디티는
     * 유효하지 않은 명령코드를 사용해 복귀합니다(남은 모든 가스를 소비).
     *
     * 요구사항:
     * - 0으로 나눌 수 없습니다.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256)
	{
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.3.0/contracts/drafts/Counters.sol
/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev 오직 1씩만 증가 또는 감소할 수 있는 카운터(counter)를 제공합니다. 이는 가령 매핑의 원소 수 추적,
 * ERC721 ID 발행, 또는 요청 ID 개수를 세는 데 사용할 수 있습니다.
 *
 * `using Counters for Counters.Counter;`으로 포함시킵니다.
 * 1씩 증가시키는 것으로 256 bit 정수를 오버플로우 시킬 수 없으므로, `increment`는 SafeMath
 * 오버플로우 체크를 스킵하고, 가스를 절약할 수 있습니다. 그러나 이는 기본적으로 `_value`가 직접 액세스되지 않는다는 가정하에 올바른 사용을 상정하고 있습니다.
 */
library Counters
{
    using SafeMath for uint256;

    struct Counter
	{
        // 이 변수는 라이브러리의 사용자로부터 직접 액세스되어서는 안 됩니다: 상호작용은 라이브러리의 함수들로만
        // 제한되어져야 합니다. 솔리디티 v0.5.2부터, 비록 이 기능을 추가하는 제안이 있지만, 이는 강제될 수 없습니다:
        // https://github.com/ethereum/solidity/issues/4637를 참조하세요.
        uint256 _value; // 기본값: 0
    }

    function current(Counter storage counter) internal view returns (uint256)
	{
        return counter._value;
    }

    function increment(Counter storage counter) internal
	{
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal
	{
        counter._value = counter._value.sub(1);
    }
}

/**
 * @dev [EIP](https://eips.ethereum.org/EIPS/eip-165)에 정의된
 * ERC165 표준의 인터페이스입니다.
 *
 * 구현체는 지원하는 컨트랙트 인터페이스를 선언할 수 있으며, 
 * 외부에서 (`ERC165Checker`) 이 함수를 호출해 지원 여부를 조회할 수 있습니다.
 *
 * 구현에 대해서는 `ERC165`를 참조하세요.
 */
interface IERC165
{
    /**
     * @dev 만일 컨트랙트가 `interfaceId`로 정의된 인터페이스를 구현했으면,
     * 참(true)을 반환합니다. ID 생성 방법에 대한 자세한 내용은 해당
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * 을 참조하세요.
     *
     * 이 함수 호출은 30000 가스보다 적게 사용할 것입니다.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev `IERC165` 인터페이스의 구현체.
 *
 * 컨트랙트는 이를 상속받을 수 있으며 `_registerInterface`를 호출해 인터페이스 지원을
 * 선언할 수 있습니다.
 */
contract ERC165 is IERC165
{
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev 지원 여부에 대한 인터페이스 ID의 매핑
Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal
	{
        // 파생된 컨트랙트는 고유한 인터페이스에 대한 지원만 등록하면 됩니다.
        // ERC165 자체에 대한 지원만 여기에서 등록합니다.
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev `IERC165.supportsInterface`를 참조하세요.
     *
     * 시간 복잡도는 O(1)이며, 항상 30000 가스 미만을 사용하도록 보장합니다.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool)
	{
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev 컨트랙트가 `interfaceId`로 정의한 인터페이스를 구현했음을
     * 등록합니다. 실제 ERC165 인터페이스의 지원은 자동으로 되며
     * 이 인터페이스 ID의 등록은 필요하지 않습니다.
     *
     * `IERC165.supportsInterface`를 참조하세요.
     *
     * 요구사항:
     *
     * - `interfaceId`는 ERC165 유효하지 않은 인터페이스(`0xffffffff`)일 수 없습니다.
     */
    function _registerInterface(bytes4 interfaceId) internal
	{
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @dev ERC721 호환 컨트랙트의 필수 인터페이스
 */
contract IERC721 is IERC165
{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev `owner` 계정의 NFT의 개수를 반환합니다.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev `tokenId`에 의해 명시된 NFT의 소유자를 반환합니다.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev 특정 NFT (`tokenId`)를 한 계정(`from`)에서
     * 다른 계정(`to`)으로 전송합니다.
     *
     * 
     *
     * 요구사항:
     * - `from`, `to`는 0일 수 없습니다.
     * - `tokenId`는 `from`이 소유하고 있어야 합니다.
     * - 만일 호출자가 `from`이 아니라면, `approve` 또는
     * `setApproveForAll`를 통해 이 NFT의 전송을 허가받았어야 합니다.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev 특정 NFT (`tokenId`)를 한 계정 (`from`)에서
     * 다른 계정(`to`)으로 전송합니다.
     *
     * 요구사항:
     * - 만일 호출자가 `from`이 아니라면, `approve` 또는
     * `setApproveForAll`를 통해 이 NFT를 전송을 허가받았어야 합니다.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
    
} 


contract IERC721Receiver 
{
    /**
     * @notice NFT 수신 처리
     * @dev ERC721 스마트 컨트랙트는 `safeTransfer` 후 수신자가 구현한
     * 이 함수를 호출합니다. 이 함수는 반드시 함수 선택자를 반환해야 하며,
     * 그렇지 않을 경우 호출자는 트랜잭션을 번복할 것입니다. 반환될 선택자는
     * `this.onERC721Received.selector`로 얻을 수 있습니다. 이 함수는
     * 전송을 번복하거나 거절하기 위해 예외를 발생시킬 수도 있습니다.
     * 참고: ERC721 컨트랙트 주소는 항상 메시지 발신자입니다.
     * @param operator `safeTransferFrom` 함수를 호출한 주소
     * @param from 이전에 토큰을 소유한 주소
     * @param tokenId 전송하고자 하는 NFT 식별자
     * @param data 특별한 형식이 없는 추가적인 데이터
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.3.0/contracts/token/ERC721/ERC721.sol
contract ERC721 is ERC165, IERC721
{
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`와 동일
    // `IERC721Receiver(0).onERC721Received.selector`로부터 얻을 수도 있습니다
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // 토큰 ID에서 소유자로의 매핑
    mapping (uint256 => address) private _tokenOwner;

    // 토큰 ID에서 승인된 주소로의 매핑
    mapping (uint256 => address) private _tokenApprovals;

    // 소유자에서 소유한 토큰 개수로의 매핑
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // 소유자에서 운영자(operator) 승인 여부로의 매핑
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    
    constructor() public
	{
        // ERC165를 통해 ERC721을 준수하도록 지원되는 인터페이스를 등록
        _registerInterface(_INTERFACE_ID_ERC721);
    }


    /**
     * @dev 명시한 주소의 잔액을 얻습니다.
     * @param owner 잔액을 요청하는 주소
     * @return uint256 전달받은 주소가 보유한 수량
     */
    function balanceOf(address owner) public view returns (uint256)
	{
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev 명시된 토큰 ID의 소유자를 얻습니다.
     * @param tokenId uint256 소유자를 요청하는 토큰의 ID
     * @return address 주어진 토큰 ID의 현재 표시된 소유자
     */
    function ownerOf(uint256 tokenId) public view returns (address)
	{
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev 주어진 토큰 ID의 전송을 다른 주소에게 허가합니다.
     * 영(zero) 주소는 승인된 주소가 없음을 나타냅니다.
     * 한 번에 하나의 승인된 주소만 있을 수 있습니다.
     * 토큰 소유자나 승인된 운영자만이 호출할 수 있습니다.
     * @param to address 주어진 토큰 ID에 대해 승인할 주소
     * @param tokenId uint256 승인하고자 하는 토큰 ID
     */
    function approve(address to, uint256 tokenId) public
	{
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev 토큰 ID에 대해 승인된 주소를, 만일 설정된 주소가 없으면 0을 얻습니다.
     * 만일 토큰 ID가 존재하지 않는 경우 되돌려집니다.
     * @param tokenId uint256 승인된 주소를 요청하는 토큰의 ID
     * @return address 주어진 토큰 ID에 대해 현재 승인된 주소
     */
    function getApproved(uint256 tokenId) public view returns (address)
	{
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev 주어진 운영자의 승인을 설정 또는 해제합니다.
     * 운영자는 발신자를 대신해 모든 토큰을 전송할 수 있도록 허가되었습니다.
     * @param to 승인을 설정하고자 하는 운영자의 주소
     * @param approved 설정하고자 하는 승인의 상태를 나타냅니다
     */
    function setApprovalForAll(address to, bool approved) public
	{
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev 주어진 소유자에 대해 운영자가 승인되었는지 여부를 말해줍니다.
     * @param owner 승인을 조회하고자 하는 소유자 주소
     * @param operator 승인을 조회하고자 하는 운영자 주소
     * @return bool 주어진 운영자가 주어진 소유자로부터 승인되었는지 여부
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool)
	{
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev 주어진 토큰 ID의 소유권을 다른 주소로 전송합니다.
     * 이 메소드는 사용하지 않는 것이 좋습니다. 가능하다면 `safeTransferFrom`을 사용하세요.
     * msg.sender는 소유자, 승인된 주소, 또는 운영자여야 합니다.
     * @param from 토큰의 현재 소유자
     * @param to 주어진 토큰 ID의 소유권을 받을 주소
     * @param tokenId 전송할 토큰의 uint256 ID
     */
    function transferFrom(address from, address to, uint256 tokenId) public
	{
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev 주어진 토큰 ID의 소유권을 다른 주소로 안전하게 전송합니다.
     * 만일 목표 주소가 컨트랙트라면, 컨트랙트는 `onERC721Received`를 구현했어야만 합니다.
     * 이는 안전한 전송으로부터 호출되며 마법의 값
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`를 반환합니다;
     * 만일 다른 경우에는 전송이 되돌려집니다.
     * msg.sender는 소유자, 승인된 주소, 운영자여야 합니다
     * @param from 토큰의 현재 소유자
     * @param to 주어진 토큰 ID의 소유권을 받을 주소
     * @param tokenId 전송할 토큰의 uint256 ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public
	{
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev 주어진 토큰 ID의 소유권을 다른 주소로 안전하게 전송합니다.
     * 만일 목표 주소가 컨트랙트라면, 컨트랙트는 `onERC721Received`를 구현했어야만 합니다.
     * 이는 안전한 전송으로부터 호출되며 마법의 값
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`를 반환합니다;
     * 만일 다른 경우에는 전송이 되돌려집니다.
     * msg.sender는 소유자, 승인된 주소, 운영자여야 합니다
     * @param from 토큰의 현재 소유자
     * @param to 주어진 토큰 ID의 소유권을 받을 주소
     * @param tokenId 전송할 토큰의 uint256 ID
     * @param _data 안전한 전송 검사와 함께 전송하고자 하는 바이트 데이터
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public
	{
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev 지정한 토큰이 존재하는지 여부를 반환합니다.
     * @param tokenId uint256 존재를 조회하고자 하는 토큰의 ID
     * @return bool 토큰의 존재 여부
     */
    function _exists(uint256 tokenId) internal view returns (bool)
	{
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev 지정된 납부자가 주어진 토큰 ID를 전송할 수 있는지 여부를 반환합니다.
     * @param spender 조회하고자 하는 납부자의 주소
     * @param tokenId uint256 전송하고자 하는 토큰 ID
     * @return bool msg.sender가 주어진 토큰 ID에 대해 승인되었는지,
     * 운영자인지, 또는 토큰의 소유자인지 여부
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool)
	{
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev 새 토큰을 발행하기 위한 내부 함수.
     * 주어진 토큰 ID가 이미 존재하면 되돌립니다.
     * @param to 발행된 토큰을 소유할 주소
     * @param tokenId uint256 발행될 토큰의 ID
     */
    function _mint(address to, uint256 tokenId) internal
	{
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev 특정 토큰을 소각하기 위한 내부 함수.
     * 토큰이 존재하지 않으면 되돌립니다.
     * 더 이상 사용되지 않으며, _burn(uint256)을 대신 사용하세요.
     * @param owner 소각할 토큰의 소유자
     * @param tokenId uint256 소각할 토큰의 ID
     */
    function _burn(address owner, uint256 tokenId) internal
	{
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev 특정 토큰을 소각하기 위한 내부 함수.
     * 토큰이 존재하지 않으면 되돌립니다.
     * @param tokenId uint256 소각할 토큰의 ID
     */
    function _burn(uint256 tokenId) internal
	{
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev 주어진 토큰 ID의 소유권을 다른 주소로 전송하기 위한 내부 함수.
     * transferFrom과 달리, msg.sender에 제한이 없습니다.
     * @param from 토큰의 현재 소유자
     * @param to 주어진 토큰 ID의 소유권을 받고자 하는 주소
     * @param tokenId uint256 전송될 토큰의 ID
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal
	{
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev 목표 주소에서 `onERC721Received`를 호출할 내부 함수.
     * 대상 주소가 컨트랙트가 아닌 경우 호출이 실행되지 않습니다.
     *
     * 이 기능은 더 이상 사용되지 않습니다.
     * @param from 주어진 토큰 ID의 이전 소유자를 나타내는 주소
     * @param to 토큰을 받을 목표 주소
     * @param tokenId uint256 전송될 토큰의 ID
     * @param _data bytes 호출과 함께 전송할 추가 데이터
     * @return bool 호출이 예상한 값(magic value)을 반환했는지 여부
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool)
    {
        if (!to.isContract())
		{
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev 주어진 토큰 ID의 현재 승인을 지우는 개인 함수.
     * @param tokenId uint256 전송할 토큰의 ID
     */
    function _clearApproval(uint256 tokenId) private
	{
        if (_tokenApprovals[tokenId] != address(0))
		{
            _tokenApprovals[tokenId] = address(0);
        }
    }
    
}

contract NFT is ERC721 
{
	string public name; // NFT 이름
    string public symbol; // NFT 심볼

	string public title; // 제목
	string public desc; // 설명
	string public image; // 이미지 URL

	uint public total_supply = 0; // 총 토큰 발행 개수

    uint[] public tokens; // tokens의 index는 0부터 시작
    address public owner; // 컨트랙트의 소유자

    constructor(string memory _name, string memory _symbol, string memory _title, string memory _desc, string memory _image) public
	{
		name = _name;
		symbol = _symbol;
		title = _title;
		desc = _desc;
		image = _image;
        owner = msg.sender; // 새 token을 생성할 수 있는 NFT 컨트랙트의 소유자
    }

    function mint(address account) public
	{
        require(owner == msg.sender); // 소유자만이 token을 생성할 수 있습니다
        uint256 tokenId = tokens.length; // 유일한 token ID
		total_supply++; // 총 토큰 발행 개수 + 1
        _mint(account, tokenId); // 새 token을 발행
    }

}