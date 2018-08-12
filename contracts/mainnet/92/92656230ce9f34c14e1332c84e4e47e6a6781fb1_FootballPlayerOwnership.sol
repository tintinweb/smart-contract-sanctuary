pragma solidity ^0.4.24;


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

library AddressUtils {

    /**
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
        assembly {size := extcodesize(addr)}
        // solium-disable-line security/no-inline-assembly
        return size > 0;
    }

}

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

}

contract AccessControl is Ownable {

    address private MainAdmin;
    address private TechnicalAdmin;
    address private FinancialAdmin;
    address private MarketingAdmin;

    constructor() public {
        MainAdmin = owner;
    }

    modifier onlyMainAdmin() {
        require(msg.sender == MainAdmin);
        _;
    }

    modifier onlyFinancialAdmin() {
        require(msg.sender == FinancialAdmin);
        _;
    }

    modifier onlyMarketingAdmin() {
        require(msg.sender == MarketingAdmin);
        _;
    }

    modifier onlyTechnicalAdmin() {
        require(msg.sender == TechnicalAdmin);
        _;
    }

    modifier onlyAdmins() {
        require(msg.sender == TechnicalAdmin || msg.sender == MarketingAdmin
        || msg.sender == FinancialAdmin || msg.sender == MainAdmin);
        _;
    }

    function setMainAdmin(address _newMainAdmin) external onlyOwner {
        require(_newMainAdmin != address(0));
        MainAdmin = _newMainAdmin;
    }

    function setFinancialAdmin(address _newFinancialAdmin) external onlyMainAdmin {
        require(_newFinancialAdmin != address(0));
        FinancialAdmin = _newFinancialAdmin;
    }

    function setMarketingAdmin(address _newMarketingAdmin) external onlyMainAdmin {
        require(_newMarketingAdmin != address(0));
        MarketingAdmin = _newMarketingAdmin;
    }


    function setTechnicalAdmin(address _newTechnicalAdmin) external onlyMainAdmin {
        require(_newTechnicalAdmin != address(0));
        TechnicalAdmin = _newTechnicalAdmin;
    }

}


contract Pausable is AccessControl {
    event Pause();
    event Unpause();

    bool public paused;


    constructor() public {
        paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyAdmins whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyAdmins whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PullPayment is Pausable {
    using SafeMath for uint256;


    mapping(address => uint256) public payments;
    uint256 public totalPayments;

    /**
    * @dev Withdraw accumulated balance, called by payee.
    */
    function withdrawPayments() whenNotPaused public {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(address(this).balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        payee.transfer(payment);
    }

    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param dest The destination address of the funds.
    * @param amount The amount to transfer.
    */
    function asyncSend(address dest, uint256 amount) whenNotPaused internal {
        payments[dest] = payments[dest].add(amount);
        totalPayments = totalPayments.add(amount);
    }
}

contract FootballPlayerBase is PullPayment, ERC721 {


    struct FootballPlayer {
        bytes32 name;
        uint8 position;
        uint8 star;
        uint256 level;
        uint256 dna;
    }

    uint32[14] public maxStaminaForLevel = [
    uint32(50 minutes),
    uint32(80 minutes),
    uint32(110 minutes),
    uint32(130 minutes),
    uint32(150 minutes),
    uint32(160 minutes),
    uint32(170 minutes),
    uint32(185 minutes),
    uint32(190 minutes),
    uint32(210 minutes),
    uint32(230 minutes),
    uint32(235 minutes),
    uint32(245 minutes),
    uint32(250 minutes)
    ];

    FootballPlayer[] players;

    mapping(uint256 => address) playerIndexToOwner;

    mapping(address => uint256) addressToPlayerCount;

    mapping(uint256 => address) public playerIndexToApproved;

    mapping(uint256 => bool) dnaExists;

    mapping(uint256 => bool) tokenIsFreezed;

    function GetPlayer(uint256 _playerId) external view returns (bytes32, uint8, uint8, uint256, uint256) {
        require(_playerId < players.length);
        require(_playerId > 0);
        FootballPlayer memory _player = players[_playerId];
        return (_player.name, _player.position, _player.star, _player.level, _player.dna);
    }

    function ToggleFreezeToken(uint256 _tokenId) public returns (bool){
        require(_tokenId < players.length);
        require(_tokenId > 0);

        tokenIsFreezed[_tokenId] = !tokenIsFreezed[_tokenId];

        return tokenIsFreezed[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), "to address is invalid");
        require(tokenIsFreezed[_tokenId] == false, "token is freezed");

        addressToPlayerCount[_to]++;

        playerIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            addressToPlayerCount[_from]--;
            delete playerIndexToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function CreateSpecialPlayer(bytes32 _name, uint8 _position, uint8 _star, uint256 _dna, uint256 _level,
        address _owner) external whenNotPaused onlyMarketingAdmin returns (uint256)
    {
        require(dnaExists[_dna] == false, "DNA exists");

        FootballPlayer memory _player = FootballPlayer(
            _name,
            _position,
            _star,
            _level,
            _dna
        );

        dnaExists[_dna] = true;

        uint256 newPlayerId = players.push(_player) - 1;

        _transfer(0, _owner, newPlayerId);

        return newPlayerId;

    }

    function CreateDummyPlayer(bytes32 _name, uint8 _position, uint256 _dna,
        address _owner) external whenNotPaused onlyAdmins returns (uint256)
    {
        require(dnaExists[_dna] == false, "DNA exists!");

        FootballPlayer memory _player = FootballPlayer(
            _name,
            _position,
            uint8(1),
            uint256(1),
            _dna
        );

        dnaExists[_dna] = true;

        uint256 newPlayerId = players.push(_player) - 1;

        _transfer(0, _owner, newPlayerId);

        return newPlayerId;

    }


}


contract ERC721Metadata {

    function getMetadata(uint256 _tokenId, string) public pure returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello Football! :D";
            count = 18;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

contract FootballPlayerOwnership is FootballPlayerBase {

    string public constant name = "CryptoFantasyFootball";
    string public constant symbol = "CFF"; // Crypto Fantasy Football
    uint256 public version;

    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
    bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));


    constructor(uint256 _currentVersion) public {
        version = _currentVersion;
    }

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function setMetadataAddress(address _contractAddress) public onlyMainAdmin {
        require(_contractAddress != address(0));
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return playerIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return playerIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        playerIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return addressToPlayerCount[_owner];
    }


    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any players 
        require(_to != address(this), "you can not transfer player to this contract");

        // You can only send your own player.
        require(_owns(msg.sender, _tokenId), "You do not own this player");

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }


    function approve(address _to, uint256 _tokenId) external whenNotPaused
    {
        require(_to != address(0));
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    ///  Transfer a player owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any players.
        require(_to != address(this) , "You can not send players to this contract");
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId) , "You don&#39;t have permission to transfer this player");
        require(_owns(_from, _tokenId) , "from address doesn&#39;t have this player");

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return players.length - 1;
    }

    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = playerIndexToOwner[_tokenId];

        require(owner != address(0));
    }


    function tokensOfOwner(address _owner) external view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPlayers = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all players have IDs starting at 1 and increasing
            // sequentially up to the total players count.
            uint256 playerId;

            for (playerId = 1; playerId <= totalPlayers; playerId++) {
                if (playerIndexToOwner[playerId] == _owner) {
                    result[resultIndex] = playerId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}