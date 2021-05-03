/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.4.23;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 *
 * @dev ERC20, ERC721 등의 특정 Interface 를 따르고 있는지를 체크하는 규약
 */
interface ERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * @dev  uses less than 30,000 gas.
     *
     * @dev 인터페이스ID 를 입력 받아서 지원 여부를 체크하는 함수.
     * @dev 규약상 30,000 gas 이하로 호출 가능해야 한다.
     * @dev (인터페이스 ID = Interface 규약에 정해진 모든 함수의 selector 를 xor 연산한 결과값)
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 * @dev ERC165 규약에 따라 ERC165 의 supportsInterface 를 지원함을 등록
 */
contract SupportsInterfaceWithLookup is ERC165 {

    bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *   bytes4(keccak256('supportsInterface(bytes4)'))
     */

    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * @dev  implement ERC165 itself
     */
    constructor()
    public
    {
        _registerInterface(InterfaceId_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     * @dev 30,000 gas 이하로 동작해야 함. 현재 이 함수의 gas estimated 는 616.
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
    {
        return supportedInterfaces[_interfaceId];
    }

    /**
     * @dev private method for registering an interface
     */
    function _registerInterface(bytes4 _interfaceId)
    internal
    {
        require(_interfaceId != 0xffffffff); // ERC165 규약에 0xffffffff 는 예외처리하라고 되어 있음
        supportedInterfaces[_interfaceId] = true;
    }

}




/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 *
 * @dev 대체 불가능한 (Non-Fungible) 토큰 규약 ERC721 에 따른 인터페이스 선언
 */
contract ERC721Basic is SupportsInterfaceWithLookup {

    // Transfer, Approval, ApprovalForAll 이벤트
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    // ERC721 인터페이스 ID - 각 함수 selector 의 xor 로 미리 계산된 값임.
    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *   bytes4(keccak256('balanceOf(address)')) ^
     *   bytes4(keccak256('ownerOf(uint256)')) ^
     *   bytes4(keccak256('approve(address,uint256)')) ^
     *   bytes4(keccak256('getApproved(uint256)')) ^
     *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    // exists 함수는 규약과 별도로 추가된 함수라 인터페이스 ID 를 별도로 제공하였음
    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
    /*
     * 0x4f558e79 ===
     *   bytes4(keccak256('exists(uint256)'))
     */

    // 추상화 콘트랙트이지만 ERC165 를 위해 생성자는 구현해둔 상태
    constructor ()
    public
    {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }

    // _owner 가 가진 NFT 의 개수를 return. 없는 주소면 0을 return. _owner 가 0 이면 오류.
    function balanceOf(address _owner) public view returns (uint256 _balance);

    // _tokenId 의 주인 계정을 return. owner 값이 0 이면 오류를 발생시킴.
    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    // _tokenId 가 존재하는지 여부를 return. ERC721 규약에 없는 추가된 함수.
    function exists(uint256 _tokenId) public view returns (bool _exists);

    // 내가 소유한 _tokenId 토큰의 접근 권한을 _to 에게 넘김. _to 를 0으로 설정하면 권한 소멸.
    function approve(address _to, uint256 _tokenId) public;

    // _tokenId 의 권한이 누구에게 있는지를 return.
    function getApproved(uint256 _tokenId)
    public view returns (address _operator);

    // 나의 모든 토큰에 대한 접근 권한을 _operator 에게 넘기거나 빼았음
    function setApprovalForAll(address _operator, bool _approved) public;

    // _owner 의 모든 토큰에 대한 접근 권한이 _operator 에게 있는지를 체크
    function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

    // 본인의 혹은 접근 가능한 _tokenId 토큰을 _from 에서 _to 로 넘김
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // _to 가 콘트랙트 주소인 경우에는 ERC721Receiver 의 onERC721Received 함수가 존재하는지를 체크한 후에 토큰을 넘김.
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

    // 위와 같은 함수에 옵셔널하게 체크 가능한 _data 가 첨부됨. (function overloading)
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
    public;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 *
 * @dev ERC721 토큰을 다루려는(=수신할 수 있으려면) 토큰은 반드시 이 규약을 구현해줘야 함.
 */
contract ERC721Receiver {
    /**
     * @dev Magic value to be returned upon successful reception of an NFT
     *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
     *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
     *
     * @dev 미리 계산해둔 정해진 return 값
     */
    bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `safetransfer`. This function MAY throw to revert and reject the
     *  transfer. This function MUST use 50,000 gas or less. Return of other
     *  than the magic value MUST result in the transaction being reverted.
     *  Note: the contract address is always the message sender.
     *
     * @dev 규약상 반드시 50,000 gas 이하로 동작해야 함.
     *
     * @param _from The sending address
     * @param _tokenId The NFT identifier which is being transfered
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
     */
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes _data
    )
    public
    returns(bytes4);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * addr 가 콘트랙트의 주소인지 아닌지를 check 함.
     *
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256; // uint256 에 SafeMath 적용
    using AddressUtils for address; // address 가 콘트랙트인지를 체크할 수 있게 AddressUtils 적용

    // ERC721Receiver 의 ERC721_RECEIVED 값을 저장해둠.
    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0xf0b9e5ba;

    // 토큰 owner 를 저장해두기 위한 변수
    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // 토큰의 접근 권한을 가지고 있는 계정을 저장해두기 위한 변수
    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // owner 가 가지고 있는 토큰의 개수를 ownedTokensCount 에 저장해둠
    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    // owner 가 operator 에게 setApprovalForAll 함수로 부여한 전체 접근 권한 여부를 저장하는 변수
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender); // owner 인지 체크
        _;
    }

    /**
     * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
     * @param _tokenId uint256 ID of the token to validate
     */
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId)); // owner 혹은 접근 권한이 있는지 체크
        _;
    }

    /**
     * @dev Gets the balance of the specified address
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner]; // 저장해둔(미리 계산된) _owner 소유의 토큰 개수를 return
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId]; // 토큰의 주인 계정 값
        require(owner != address(0)); // 규약에 따라 owner 값이 0 이면(존재하지 않으면) 오류 발생
        return owner;
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0); // 토큰 존재 여부 return. ownerOf 는 아예 오류를 발생시키기 때문에 미리 체크할 수 있도록 이 함수를 추가해준 듯 함.
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _tokenId uint256 ID of the token to be approved
     */
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner); // 본인에게 권한 부여 금지
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender)); // 소유자이거나 접근 권한이 있는지 체크

        if (getApproved(_tokenId) != address(0) || _to != address(0)) { // _tokenId 가 0 이 아니거나 _to 가 0 이 아님을 체크 (_tokenId 가 0 인 경우에는 _to 에 0 을 입력하여 초기화할 수 있음)
            tokenApprovals[_tokenId] = _to; // tokenApprovals 값 업데이트
            emit Approval(owner, _to, _tokenId); // 이벤트 발생
        }
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId]; // 접근 권한 여부를 return
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * @dev An operator is allowed to transfer all tokens of the sender on their behalf
     * @param _to operator address to set the approval
     * @param _approved representing the status of the approval to be set
     */
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender); // 본인에게 권한 부여 금지
        operatorApprovals[msg.sender][_to] = _approved; // operatorApprovals 값 업데이트
        emit ApprovalForAll(msg.sender, _to, _approved); // 이벤트 발생
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param _owner owner address which you want to query the approval of
     * @param _operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
    public
    view
    returns (bool)
    {
        return operatorApprovals[_owner][_operator]; // _operator 가 _owner 의 모든 토큰에 접근 권한이 있는지를 return
    }



    /**
     * @dev Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    public
    canTransfer(_tokenId) // transfer 권한이 있는지를 체크
    {
        require(_from != address(0)); // zero address 예외처리
        require(_to != address(0)); // zero address 예외처리

        clearApproval(_from, _tokenId); // Approval 값 초기화
        removeTokenFrom(_from, _tokenId); // owner 의 값 초기화
        addTokenTo(_to, _tokenId); // to 에게 token 이동

        emit Transfer(_from, _to, _tokenId); // 이벤트 발생
    }



    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    public
    canTransfer(_tokenId) // transfer 권한이 있는지를 체크
    {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, ""); // data 파라미터가 있는 safeTransferFrom 함수로 호출
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
    public
    canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId); // 토큰 이동
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data)); // 단, _to 가 콘트랙트인 경우에는 ERC721 을 받을 준비(=onERC721Received 함수를 구현)가 되어 있는지를 체크
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *  is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
    internal
    view
    returns (bool)
    {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
        _spender == owner || // owner 이거나
        getApproved(_tokenId) == _spender || // approve 받은 계정이거나
        isApprovedForAll(owner, _spender) // owner 의 전체 토큰에 접근 권한이 있는지
        );
    }

    /**
     * 새 토큰을 생성하기 위한 함수. 내부에서만 호출 가능하기 때문에 ERC721 을 상속 받아서 내부 알고리즘을 구현할 때 호출하면 됨. (ERC721 규약에 있는 함수는 아님.)
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0)); // zero address 예외처리
        addTokenTo(_to, _tokenId); // 토큰 생성
        emit Transfer(address(0), _to, _tokenId); // 이벤트 호출 - ERC721 규약에 따르면 토큰이 생성될 때는 Transfer 이벤트의 _from 값으로 0 을 넘겨줘야 함.
    }

    /**
     * 토큰을 소멸시키기 위한 함수. 내부에서만 호출 가능하기 때문에 ERC721 을 상속 받아서 내부 알고리즘을 구현할 때 호출하면 됨. (ERC721 규약에 있는 함수는 아님.)
     * @dev Internal function to burn a specific token
     * @dev Reverts if the token does not exist
     * @param _tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId); // approval 값 초기화
        removeTokenFrom(_owner, _tokenId); // 토큰 소멸
        emit Transfer(_owner, address(0), _tokenId); // 이벤트 호출 - ERC721 규약에 따르면 토큰이 소멸될 때는 Transfer 이벤트의 _to 값으로 0 을 넘겨줘야 함.
    }

    /**
     * @dev Internal function to clear current approval of a given token ID
     * @dev Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function clearApproval(address _owner, uint256 _tokenId) internal { // 내부에서만 호출 가능
        require(ownerOf(_tokenId) == _owner); // 토큰의 주인이 _owner 가 맞는지 체크
        if (tokenApprovals[_tokenId] != address(0)) { // Approval 값이 이미 존재할 때만
            tokenApprovals[_tokenId] = address(0); // 초기화
            emit Approval(_owner, address(0), _tokenId); // 초기화 되었음을 이벤트 발생
        }
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal { // 내부에서만 호출 가능
        require(tokenOwner[_tokenId] == address(0)); // 토큰의 주인이 없을 때만 (transferFrom 에서는 미리 지우고 호출됨)
        tokenOwner[_tokenId] = _to; // _to 를 주인으로 토큰 생성 혹은 이동
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1); // _to 가 소유한 토큰 개수에 +1
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal { // 내부에서만 호출 가능
        require(ownerOf(_tokenId) == _from); // 토큰 주인이 _from 이 맞는지 check
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1); // _from 이 소유한 토큰 개수에 -1
        tokenOwner[_tokenId] = address(0); // 토큰 소멸
    }



    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * @dev The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
    internal // 내부에서만 호출 가능
    returns (bool)
    {
        if (!_to.isContract()) { // 콘트랙트가 아니면 그냥 return true
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            _from, _tokenId, _data); // address 변수인 _to 를 ERC721Receiver 로 강제 형변환한 후 onERC721Received 함수를 호출해 봄
        return (retval == ERC721_RECEIVED); // ERC721_RECEIVED(=ERC721 의 인터페이스ID) 이면 ERC165 에 따라 성공!
    }
}




/**
 * ERC721 규약에 따른 NFT 토큰의 수량을 관리할 수 있는 확장 선언
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {

    // ERC721Enumerable 인터페이스 ID (함수 3개)
    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
    /**
     * 0x780e9d63 ===
     *   bytes4(keccak256('totalSupply()')) ^
     *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
     *   bytes4(keccak256('tokenByIndex(uint256)'))
     */

    constructor()
    public
    {
        _registerInterface(InterfaceId_ERC721Enumerable);
    }

    // 전체 토큰 개수
    function totalSupply() public view returns (uint256);

    // _owner 의 _index 번째 token 을 return
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
    public
    view
    returns (uint256 _tokenId);

    // 전체 토큰의 _index 번째 token 을 return
    function tokenByIndex(uint256 _index) public view returns (uint256);
}



/**
 * ERC721 규약에 따른 이름, 심볼 등의 메타 데이타에 대한 확장 선언
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {

    // ERC721Metatdata 의 인터페이스 ID (함수 3개)
    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *   bytes4(keccak256('name()')) ^
     *   bytes4(keccak256('symbol()')) ^
     *   bytes4(keccak256('tokenURI(uint256)'))
     */

    constructor()
    public
    {
        _registerInterface(InterfaceId_ERC721Metadata);
    }

    function name() external view returns (string _name); // 이름
    function symbol() external view returns (string _symbol); // 심볼
    function tokenURI(uint256 _tokenId) public view returns (string); // URI

    // The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema". This is the "ERC721 Metadata JSON Schema" referenced above.
    // {
    //     "title": "Asset Metadata",
    //     "type": "object",
    //     "properties": {
    //         "name": {
    //             "type": "string",
    //             "description": "Identifies the asset to which this NFT represents",
    //         },
    //         "description": {
    //             "type": "string",
    //             "description": "Describes the asset to which this NFT represents",
    //         },
    //         "image": {
    //             "type": "string",
    //             "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive.",
    //         }
    //     }
    // }

}



/**
 * 확장 옵션까지 포함한 ERC721 전체 규약 선언
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}



/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
    // Token name
    string internal name_; // 토큰 이름. ERC721Metadata 에 이미 함수가 선언되어 있으므로 public 으로 선언하지는 않음.

    // Token symbol
    string internal symbol_; // 토큰 심볼. ERC721Metadata 에 이미 함수가 선언되어 있으므로 public 으로 선언하지는 않음.



    // owner 가 보유한 토큰의 순서에 따라 token ID 를 저장하기 위한 변수
    // 매핑의 두번째 인자가 array 이기 때문에 ownedTokens[ownerID][index] 로 사용
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;

    // tokenID 가 owner 의 토큰에서 몇 번째인지를 저장하는 변수
    // ownedTokensIndex[tokenId] 는 index of owner’s tokens 임. (index of all tokens 가 아님)
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // 전체 토큰을 순서대로 저장한 array
    // allTokens[index of all tokens] = tokenId 임.
    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // tokenId 가 전체 토큰에서 몇번째인지를 저장하는 변수
    // allTokendsIndex[tokenId] = index of all tokens 임
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // 토큰 이름, 설명, 이미지 경로 정보를 가지고 있는 JSON 파일을 가리키는 URI 를 저장하기 위한 변수
    // tokenURIs[tokenID] = URI 로 사용.
    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;



    /**
     * @dev Constructor function
     */
    constructor(string _name, string _symbol) public { // 생성자
        name_ = _name;
        symbol_ = _symbol;
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string) { // name 함수
        return name_;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string) { // 심볼 함수
        return symbol_;
    }

    /**
     * @dev Returns an URI for a given token ID
     * @dev Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId)); // 존재하지 않을 때에는 예외처리
        return tokenURIs[_tokenId]; // tokenURI 리턴
    }




    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
    public
    view
    returns (uint256)
    {
        require(_index < balanceOf(_owner)); // _owner 가 소유한 개수 내인지 체크
        return ownedTokens[_owner][_index]; // _owner 의 _index 번째 토큰ID 를 return
    }




    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return allTokens.length; // 전체 토큰의 개수 (참고 : ERC721Basic 에는 balanceOf 만 존재)
    }





    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * @dev Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply()); // index 에 대한 overflow 체크
        return allTokens[_index]; // 전체 토큰의 _index 번째 토큰ID 를 return
    }





    /**
     * @dev Internal function to set the token URI for a given token
     * @dev Reverts if the token ID does not exist
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId)); // _tokenId 가 존재할 때만 pass
        tokenURIs[_tokenId] = _uri; // tokenURI 값 업데이트
    }





    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId); // 베이스 콘트랙트의 addtokenTo 호출

        // 추가 구현 부분
        uint256 length = ownedTokens[_to].length; // _to 가 기존에 가지고 있던 토큰의 개수
        ownedTokens[_to].push(_tokenId); // _to 의 토큰 array 에 _tokenId 추가
        ownedTokensIndex[_tokenId] = length; // ownedTokensIndex 에 새로 추가된 index 인 length 저장 (현재의 length 보다는 1이 작을 것임)

        // 참고 : 새로 token 이 생기는 경우에는 _mint 에서 allTokens 정보를 다루기 때문에 이 함수에서는 처리하지 않아도 됨.
    }





    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId); // 베이스 콘트랙트의 removeTokenFrom 호출

        uint256 tokenIndex = ownedTokensIndex[_tokenId]; // _from 의 토큰 중 몇번째인가
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1); // 마지막 토큰의 index
        uint256 lastToken = ownedTokens[_from][lastTokenIndex]; // 마지막 토큰ID 를 get

        ownedTokens[_from][tokenIndex] = lastToken; // _tokenId 의 자리에 마지막 토큰을 덮어씀.
        ownedTokens[_from][lastTokenIndex] = 0; // 마지막 토큰 자리는 0으로 초기화
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokens[_from].length--; // 토큰 개수를 하나 줄임
        ownedTokensIndex[_tokenId] = 0; // 지워진 _tokenId 의 토큰 인덱스를 초기화
        ownedTokensIndex[lastToken] = tokenIndex; // 마지막 토큰이었던 토큰에 바뀐 index 를 저장
    }




    /**
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to address the beneficiary that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId); // 베이스 콘트랙트의 _mint 함수 호출 (여기에서 addTokenTo 가 호출된다)

        allTokensIndex[_tokenId] = allTokens.length; // 새 토큰에 마지막 index (현재 array의 길이)를 부여
        allTokens.push(_tokenId); // allTokens 에 _tokenId 추가
    }




    /**
     * @dev Internal function to burn a specific token
     * @dev Reverts if the token does not exist
     * @param _owner owner of the token to burn
     * @param _tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId); // 베이스 콘트랙트의 _burn 함수 호출 (여기에서 removeTokenFrom 가 호출된다)

        // Clear metadata (if any)
        if (bytes(tokenURIs[_tokenId]).length != 0) { // string 은 bytes 로 형변환하여 길이를 체크할 수 있음.
            delete tokenURIs[_tokenId]; // tokenURI 값이 있으면 초기화
        }

        // [ 참고 ] (예전 강의 내용인 솔리디티 A-Z 에서 발췌)
        // bytes : 임의의 길이를 가진 bytes 를 저장할 수 있는 변수 타입
        // string : 임의의 길이를 가진 UTF-8-encoded 문자열을 저장할 수 있는 변수 타입
        // bytes 와 string 은 special arrays 이다. bytes 는 byte[] 와 유사하지만 더 공간을 타이트하게 사용한다. string 은 (아직까지는) array 의 기능인 .length 멤버 변수와 [ ] 인덱스 참조 기능이 지원되지 않는다.

        // 전체 토큰의 순서를 재조정 (removeTokenFrom 의 순서 재조정 방식과 완전히 동일)
        // Reorg all tokens array
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

}




// ERC721 을 다룰 콘트랙트는 다음과 같이 ERC721Receiver 를 상속 받아 사용하세요.
contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED; // 현재는 단순히 ERC721_RECEIVED 를 리턴하지만 디테일한 예외처리 등을 포함하여 구현해도 됨.
    }
}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract Token721 is ERC721Token, Ownable {
    constructor() ERC721Token("721Token", "M721") public {
    }

    function mint(uint256 tokenId) onlyOwner public {
        require(!exists(tokenId));
        _mint(owner, tokenId);
    }

    function burn(uint256 tokenId) onlyOwnerOf(tokenId) public {
        _burn(ownerOf(tokenId), tokenId);
    }

    function setTokenURI(uint256 tokenId, string uri) onlyOwner public {
        _setTokenURI(tokenId, uri);
    }
}