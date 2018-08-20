/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;


}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
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
        assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
        return size > 0;
    }

}

// File: contracts/acl.sol

/**
* This is the first version of a simple ACL / Permission Management System
* It might differentiate from other Permission Management Systems and therefore be more restrictive in the following points:
* Every User can just have one Role
* No new Roles "Positions" can be generated
* Therefore all possible Roles must be defined at the beginning
 */


contract acl{

    enum Role {
        USER,
        ORACLE,
        ADMIN
    }

    mapping (address=> Role) permissions;

    constructor() public {
        permissions[msg.sender] = Role(2);
    }

    function setRole(uint8 rolevalue,address entity)external check(2){
        permissions[entity] = Role(rolevalue);
    }

    function getRole(address entity)public view returns(Role){
        return permissions[entity];
    }

    modifier check(uint8 role) {
        require(uint8(getRole(msg.sender)) == role);
        _;
    }
}

// File: contracts/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev edited verison of Open Zepplin implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * @dev edited _mint & isApprovedOrOwner modifiers
 */
contract ERC721BasicToken is ERC721Basic, acl {
    using SafeMath for uint256;
    using AddressUtils for address;

    uint public numTokensTotal;

  // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
     /* require(owner != address(0)); */
        return owner;
    }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
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
        address owner = tokenOwner[_tokenId];

        tokenApprovals[_tokenId] = _to;

        require(_to != ownerOf(_tokenId));
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }



  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
    function isApprovedOrOwner(address _spender, uint256 _tokenId) public view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   * @dev _check(2) checks msg.sender == ADMIN
   */
    function _mint(address _to, uint256 _tokenId) external check(2) {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        numTokensTotal = numTokensTotal.add(1);
        emit Transfer(address(0), _to, _tokenId);
    }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
    function _burn(address _owner, uint256 _tokenId) external check(2) {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        numTokensTotal = numTokensTotal.sub(1);
        emit Transfer(_owner, address(0), _tokenId);
    }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }
}

// File: contracts/testreg.sol

contract testreg is ERC721BasicToken  {

	// @param

    struct TokenStruct {
        string token_uri;
    }

    mapping (uint256 => TokenStruct) TokenId;

}

// File: contracts/update.sol

contract update is testreg {

    event UpdateToken(uint256 _tokenId, string new_uri);

    function updatetoken(uint256 _tokenId, string new_uri) external check(1){
        TokenId[_tokenId].token_uri = new_uri;

        emit UpdateToken(_tokenId, new_uri);
    }

    function _mint_with_uri(address _to, uint256 _tokenId, string new_uri) external check(2) {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        numTokensTotal = numTokensTotal.add(1);
        TokenId[_tokenId].token_uri = new_uri;
        emit Transfer(address(0), _to, _tokenId);
    }
}

// File: contracts/bloomingPool.sol

/// @dev altered version of Open Zepplin&#39;s &#39;SplitPayment&#39; contract

contract bloomingPool is update {

    using SafeMath for uint256;

    uint256 public totalShares = 0;
    uint256 public totalReleased = 0;
    bool public freeze;

    mapping(address => uint256) public shares;

    constructor() public {
        freeze = false;
    }

    function() public payable { }


    function calculate_total_shares(uint256 _shares,uint256 unique_id )internal{
        shares[tokenOwner[unique_id]] = shares[tokenOwner[unique_id]].add(_shares);
        totalShares = totalShares.add(_shares);
    }

    function oracle_call(uint256 unique_id) external check(1){
        calculate_total_shares(1,unique_id);
    }

    function get_shares() external view returns(uint256 individual_shares){
        return shares[msg.sender];
    }

    function freeze_pool(bool _freeze) external check(2){
        freeze = _freeze;
    }

    function reset_individual_shares(address payee)internal {
        shares[payee] = 0;
    }

    function substract_individual_shares(uint256 _shares)internal {
        totalShares = totalShares - _shares;
    }

    function claim()public{
        payout(msg.sender);
    }

    function payout(address to) internal returns(bool){
        require(freeze == false);
        address payee = to;
        require(shares[payee] > 0);

        uint256 volume = address(this).balance;
        uint256 payment = volume.mul(shares[payee]).div(totalShares);

        require(payment != 0);
        require(address(this).balance >= payment);

        totalReleased = totalReleased.add(payment);
        payee.transfer(payment);
        substract_individual_shares(shares[payee]);
        reset_individual_shares(payee);
    }

    function emergency_withdraw(uint amount) external check(2) {
        require(amount <= this.balance);
        msg.sender.transfer(amount);
    }

}

// File: contracts/buyable.sol

contract buyable is bloomingPool {

    address INFRASTRUCTURE_POOL_ADDRESS;
    mapping (uint256 => uint256) TokenIdtosetprice;
    mapping (uint256 => uint256) TokenIdtoprice;

    event Set_price_and_sell(uint256 tokenId, uint256 Price);
    event Stop_sell(uint256 tokenId);

    constructor() public {}

    function initialisation(address _infrastructure_address) public check(2){
        INFRASTRUCTURE_POOL_ADDRESS = _infrastructure_address;
    }

    function set_price_and_sell(uint256 UniqueID,uint256 Price) external {
        approve(address(this), UniqueID);
        TokenIdtosetprice[UniqueID] = Price;
        emit Set_price_and_sell(UniqueID, Price);
    }

    function stop_sell(uint256 UniqueID) external payable{
        require(tokenOwner[UniqueID] == msg.sender);
        clearApproval(tokenOwner[UniqueID],UniqueID);
        emit Stop_sell(UniqueID);
    }

    function buy(uint256 UniqueID) external payable {
        address _to = msg.sender;
        require(TokenIdtosetprice[UniqueID] == msg.value);
        TokenIdtoprice[UniqueID] = msg.value;
        uint _blooming = msg.value.div(20);
        uint _infrastructure = msg.value.div(20);
        uint _combined = _blooming.add(_infrastructure);
        uint _amount_for_seller = msg.value.sub(_combined);
        require(tokenOwner[UniqueID].call.gas(99999).value(_amount_for_seller)());
        this.transferFrom(tokenOwner[UniqueID], _to, UniqueID);
        if(!INFRASTRUCTURE_POOL_ADDRESS.call.gas(99999).value(_infrastructure)()){
            revert("transfer to infrastructurePool failed");
		}
    }

    function get_token_data(uint256 _tokenId) external view returns(uint256 _price, uint256 _setprice, bool _buyable){
        _price = TokenIdtoprice[_tokenId];
        _setprice = TokenIdtosetprice[_tokenId];
        if (tokenApprovals[_tokenId] != address(0)){
            _buyable = true;
        }
    }

    function get_token_data_buyable(uint256 _tokenId) external view returns(bool _buyable) {
        if (tokenApprovals[_tokenId] != address(0)){
            _buyable = true;
        }
    }

    function get_all_sellable_token()external view returns(bool[101] list_of_available){
        uint i;
        for(i = 0;i<101;i++) {
            if (tokenApprovals[i] != address(0)){
                list_of_available[i] = true;
          }else{
                list_of_available[i] = false;
          }
        }
    }
    function get_my_tokens()external view returns(bool[101] list_of_my_tokens){
        uint i;
        address _owner = msg.sender;
        for(i = 0;i<101;i++) {
            if (tokenOwner[i] == _owner){
                list_of_my_tokens[i] = true;
          }else{
                list_of_my_tokens[i] = false;
          }
        }
    }

}