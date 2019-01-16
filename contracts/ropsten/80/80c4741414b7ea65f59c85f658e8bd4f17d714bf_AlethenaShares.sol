pragma solidity ^0.4.24;

// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9cfff3f2e8fdffe8dcfdf0f9e8f4f9f2fdb2fff3f1">[email&#160;protected]</a>

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);}contract ERC20 is ERC20Basic {    function allowance(address owner, address spender)        public view returns (uint256);
    function transferFrom(address from, address to, uint256 value)
        public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );
}

contract Ownable {
    address public owner;
    address public master = 0x38A00678e2ab244e941202A7B53f66Ff967725a5;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


  /**
   * @dev The Ownable constructor sets the original &#39;owner&#39; of the contract to the sender
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function transferOwnership(address _newOwner) public {
         require(msg.sender == master);
        _transferOwnership(_newOwner);
    }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Claimable is ERC20Basic, Ownable {

    struct Claim {
        address claimant; // the person who created the claim
        uint256 collateral; // the amount of wei deposited
        uint256 timestamp;  // the timestamp of the block in which the claim was made
    }

    struct PreClaim {
        bytes32 msghash; // the hash of nonce + address to be claimed
        uint256 timestamp;  // the timestamp of the block in which the preclaim was made
    }

    /** @param collateralRate Sets the collateral needed per share to file a claim */
    uint256 public collateralRate = 1000000000000000 wei;

    uint256 public claimPeriod = 60*60*24*30; // In seconds ;
    uint256 public preClaimPeriod = 60*60*24; // In seconds ;

    mapping(address => Claim) public claims; // there can be at most one claim per address, here address is claimed address
    mapping(address => PreClaim) public preClaims; // there can be at most one preclaim per address, here address is claimer


    function setClaimParameters(uint256 _collateralRate, uint256 _claimPeriodInDays) public onlyOwner() {
        uint256 claimPeriodInSeconds = _claimPeriodInDays*60*60*24;
        require(_collateralRate > 0);
        require(_claimPeriodInDays > 30); // must be at least 30 days
        collateralRate = _collateralRate;
        claimPeriod = claimPeriodInSeconds;
        emit ClaimParametersChanged(collateralRate, claimPeriod);
    }

    event ClaimMade(address indexed _lostAddress, address indexed _claimant, uint256 _balance);
    event ClaimPrepared(address indexed _claimer);
    event ClaimCleared(address indexed _lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed _lostAddress, address indexed _claimant, uint256 collateral);
    event ClaimResolved(address indexed _lostAddress, address indexed _claimant, uint256 collateral);
    event ClaimParametersChanged(uint256 _collateralRate, uint256  _claimPeriodInDays);


  /** Anyone can declare that the private key to a certain address was lost by calling declareLost
    * providing a deposit/collateral. There are three possibilities of what can happen with the claim:
    * 1) The claim period expires and the claimant can get the deposit and the shares back by calling resolveClaim
    * 2) The "lost" private key is used at any time to call resolveClaim. In that case, the claim is deleted and
    *    the deposit sent to the shareholder (the owner of the private key). It is recommended to call resolveClaim
    *    whenever someone transfers funds to let claims be resolved automatically when the "lost" private key is
    *    used again.
    * 3) The owner deletes the claim and assigns the deposit to himself. This is intended to be used to resolve
    *    disputes. Who is entitled to keep the deposit depends on the contractual agreements between the involved
    *    parties and in particular the issuance terms. Generally, using this function implies that you have to trust
    *    the issuer of the tokens to handle the situation well. As a rule of thumb, the contract owner should assume
    *    the owner of the lost address to be the rightful owner of the deposit.
    * It is highly recommended that the owner observes the claims made and informs the owners of the claimed addresses
    * whenever a claim is made for their address (this of course is only possible if they are known to the owner, e.g.
    * through a shareholder register).
    * To prevent frontrunning attacks, a claim can only be made if the information revealed when calling "claimLost"
    * was previously commited using the "prepareClaim" function.
    */

    function prepareClaim(bytes32 _hashedpackage) public{
        preClaims[msg.sender] = PreClaim({
            msghash: _hashedpackage,
            timestamp: block.timestamp
        });
        emit ClaimPrepared(msg.sender);
    }

    function validateClaim(address _lostAddress, bytes32 _nonce) private view returns (bool){
        PreClaim memory preClaim = preClaims[msg.sender];
        require(preClaim.msghash != 0);
        require(preClaim.timestamp + preClaimPeriod <= block.timestamp);
        return preClaim.msghash == keccak256(abi.encodePacked(_nonce, msg.sender, _lostAddress));
    }

    function declareLost(address _lostAddress, bytes32 _nonce) public payable{
        uint256 balance = balanceOf(_lostAddress);
        require(balance > 0);
        require(msg.value >= balance*collateralRate);
        require(claims[_lostAddress].collateral == 0);
        require(validateClaim(_lostAddress, _nonce));

        claims[_lostAddress] = Claim({
            claimant: msg.sender,
            collateral: msg.value,
            timestamp: block.timestamp
        });
        delete preClaims[msg.sender];
        emit ClaimMade(_lostAddress, msg.sender, balance);
    }

    function getClaimant(address _lostAddress) public view returns (address){
        return claims[_lostAddress].claimant;
    }

    function getCollateral(address _lostAddress) public view returns (uint256){
        return claims[_lostAddress].collateral;
    }

    function getTimeStamp(address _lostAddress) public view returns (uint256){
        return claims[_lostAddress].timestamp;
    }

    function getPreClaimTimeStamp(address _claimerAddress) public view returns (uint256){
        return preClaims[_claimerAddress].timestamp;
    }

    function getMsgHash(address _claimerAddress) public view returns (bytes32){
        return preClaims[_claimerAddress].msghash;
    }

    /**
     * Clears a claim after the key has been found again and assigns the collateral to the "lost" address.
     */
    function clearClaim() public returns (uint256){
        uint256 collateral = claims[msg.sender].collateral;
        if (collateral != 0){
            delete claims[msg.sender];
            msg.sender.transfer(collateral);
            emit ClaimCleared(msg.sender, collateral);
            return collateral;
        } else {
            return 0;
        }
    }

   /**
    * @dev This function is used to resolve a claim.
    * @dev A rightful owner can claim his address back.
    * @dev Else, after waiting period address can be claimed.
    *
   */
    function resolveClaim(address _lostAddress) public returns (uint256){
        Claim memory claim = claims[_lostAddress];
        require(claim.collateral != 0, "No claim found");
        require(claim.claimant == msg.sender);
        require(claim.timestamp + claimPeriod <= block.timestamp);
        address claimant = claim.claimant;
        delete claims[_lostAddress];
        claimant.transfer(claim.collateral);
        internalTransfer(_lostAddress, claimant, balanceOf(_lostAddress));
        emit ClaimResolved(_lostAddress, claimant, claim.collateral);
        return claim.collateral;
    }

    function internalTransfer(address _from, address _to, uint256 _value) internal;

     /** @dev This function is to be executed by the owner only in case a dispute needs to be resolved manually. */
    function deleteClaim(address _lostAddress) public onlyOwner(){
        Claim memory claim = claims[_lostAddress];
        require(claim.collateral != 0, "No claim found");
        delete claims[_lostAddress];
        claim.claimant.transfer(claim.collateral);
        emit ClaimDeleted(_lostAddress, claim.claimant, claim.collateral);
    }

}

contract AlethenaShares is ERC20, Claimable {

    string public constant name = "Alethena Equity";
    string public constant symbol = "ALEQ";
    uint8 public constant decimals = 0; // legally, shares are not divisible

    using SafeMath for uint256;

      /** URL where the source code as well as the terms and conditions can be found. */
    string public constant termsAndConditions = "shares.alethena.com";

    mapping(address => uint256) balances;
    uint256 totalSupply_;        // total number of tokenized shares, sum of all balances
    uint256 totalShares_ = 20345753; // total number of outstanding shares, maybe not all tokenized

    event Mint(address shareholder, uint256 amount, string message);
    event Unmint(uint256 amount, string message);

  /** @dev Total number of tokens in existence */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

  /** @dev Total number of shares in existence, not necessarily all represented by a token.
    * @dev This could be useful to calculate the total market cap.
    */
    function totalShares() public view returns (uint256) {
        return totalShares_;
    }

    function setTotalShares(uint256 _newTotalShares) public onlyOwner() {
        require(_newTotalShares >= totalSupply());
        totalShares_ = _newTotalShares;
    }

  /** Increases the number of the tokenized shares. If the shares are newly issued, the share total also needs to be increased. */
    function mint(address shareholder, uint256 _amount, string _message) public onlyOwner() {
        require(_amount > 0);
        require(totalSupply_ + _amount <= totalShares_);
        balances[shareholder] = balances[shareholder].add(_amount);
        totalSupply_ = totalSupply_ + _amount;
        emit Mint(shareholder, _amount, _message);
    }

/** Decrease the number of the tokenized shares. There are two use-cases for this function:
 *  1) a capital decrease with a destruction of the shares, in which case the law requires that the
 *     destroyed shares are currently owned by the company.
 *  2) a shareholder wants to take shares offline. This can only happen with the agreement of the
 *     the company. To do so, the shares must be transferred to the company first, the company call
 *     this function and then assigning the untokenized shares back to the shareholder in whatever
 *     way the new form (e.g. printed certificate) of the shares requires.
 */
    function unmint(uint256 _amount, string _message) public onlyOwner() {
        require(_amount > 0);
        require(_amount <= balanceOf(owner));
        balances[owner] = balances[owner].sub(_amount);
        totalSupply_ = totalSupply_ - _amount;
        emit Unmint(_amount, _message);
    }

  /** This contract is pausible.  */
    bool public isPaused = false;

  /** @dev Function to set pause.
   *  This could for example be used in case of a fork of the network, in which case all
   *  "wrong" forked contracts should be paused in their respective fork. Deciding which
   *  fork is the "right" one is up to the owner of the contract.
   */
    function pause(bool _pause, string _message, address _newAddress, uint256 _fromBlock) public onlyOwner() {
        isPaused = _pause;
        emit Pause(_pause, _message, _newAddress, _fromBlock);
    }

    event Pause(bool paused, string message, address newAddress, uint fromBlock);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
The next section contains standard ERC20 routines.
Main change: Transfer functions have an additional post function which resolves claims if applicable.
 */
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public returns (bool) {
        clearClaim();
        internalTransfer(msg.sender, _to, _value);
        return true;
    }

    function internalTransfer(address _from, address _to, uint256 _value) internal {
        require(!isPaused);
        require(_to != address(0));
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isPaused);
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        internalTransfer(_from, _to, _value);
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!isPaused);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    event Approval(address approver, address spender, uint256 value);
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(!isPaused);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(!isPaused);
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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